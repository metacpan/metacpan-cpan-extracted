
# Try many combinations of read operations on an IO::Callback, checking that each
# gives exactly the same results as Perl does for a real file.

# This test is split into several .t files (one for each $seglen value), since the
# large number of tests uses too much memory if run as a single .t file.

use strict;
use warnings;

our $seglen;

use Test::More;
BEGIN {
    unless ($ENV{EXTENDED_TESTING}) {
        plan skip_all => "EXTENDED_TESTING environment variable not set",
    }

    plan tests => 99145;
}
use Test::NoWarnings;

use IO::Callback;
use IO::Handle;
use File::Temp qw/tempdir/;
use File::Slurp;
use Fatal qw/open close/;
use Fcntl 'SEEK_CUR';

our $testfile = tempdir(CLEANUP => 1) . "/testfile";

our %tell_result_sequence;
our %lno_result_sequence;

our $start_lineno = 999999;
if ($] >= 5.008000 and $] < 5.008009) {
    # $. sometimes gets 0ed at the tie() in IO::String::new() under
    # these perls, start with $. set to 0 to avoid test failures.
    $start_lineno = 0;
}

# the block size for the coderef to serve up data
my @test_block_sizes = (1, 2, 3, 10, 1_000_000);

my %data_strings = (
    empty    => '',
    0        => '0',
    1        => '1',
    newline  => "\n",
    newline2 => "\n\n",
    newline3 => "\n\n\n",
    null     => "\0",
    foo      => "foo",
    foon     => "foo\n",
    foobar   => "foo\nbar",
    foobarn  => "foo\nbar\n",
    para2    => "hello\n\n",
    para22   => "\n\nhello\n\n",
    para3    => "hello\n\n\n",
    para33   => "\n\n\nhello\n\n\n",
    para323  => "\n\n\nfoo\n\nbar\nbaz\n\n\n",
    allbytes => join('', map {chr} (0..255)),
);

our $use_sysread;
our $do_ungetc;
foreach $use_sysread (0, 1) {
    foreach $do_ungetc (0, 1) {
        next if $use_sysread and $do_ungetc;
        my @readcode = build_read_code($use_sysread, \@test_block_sizes);
        foreach my $str (keys %data_strings) {
            write_file $testfile, $data_strings{$str};
            foreach my $readcode1 (@readcode) {
                foreach my $readcode2 (@readcode) {
                    run_test($str, $testfile, $seglen, $readcode1, $readcode2);
                }
            }
        }
    }
}

sub run_test {
    my ($str, $file_holding_str, $seglen, @readcode) = @_;
    my $srccode = join "::", map {$_->{SrcCode}} @readcode;
    my $para_mode_used = grep {$_->{ParaMode}} @readcode;
    my $testname = "$srccode $str $seglen/$do_ungetc";

    my $segs = segment_input($data_strings{$str}, $seglen);
    $. = $start_lineno;
    my $fh = IO::Callback->new('<', \&readsub, $segs);
    my $got_via_io_coderef = do_test_reads($fh, 1, map {$_->{CodeRef}} @readcode);

    # Use a real file to determine what the results should be with this combination
    # of read ops.
    $. = $start_lineno;
    open my $real_fh, "<", $file_holding_str;
    my $got_via_realfile = do_test_reads($real_fh, 0, map {$_->{CodeRef}} @readcode);

    is $got_via_io_coderef, $got_via_realfile, "$testname matched real file results";

    is $tell_result_sequence{1}, $tell_result_sequence{0}, "$testname tell() matched real file results";
    is $lno_result_sequence{1},  $lno_result_sequence{0}, "$testname input_line_number() matched real file results";

    # In paragraph mode newlines can be discarded, otherwise the output should
    # match the input exactly.  
    unless (grep {$_->{ParaMode}} @readcode) {
        is $got_via_io_coderef, $data_strings{$str}, "$testname recreated input";
    }
}

sub systell {
    my $ret = sysseek($_[0], 0, SEEK_CUR);
    return 0 if $ret eq "0 but true";
    return $ret;
}

sub do_test_reads {
    my ($fh, $is_io_coderef, @coderefs) = @_;

    # tell() won't work on the real file if I've used sysread on it, use sysseek to emulate it in that case.
    my $mytell = $use_sysread && ! $is_io_coderef ? \&systell : sub { tell $_[0] };

    # Use each read mechanism in turn, repeating the last until EOF.
    my $dest = '';
    my @lno = ($fh->input_line_number . "-" . $.);
    my @tell = ($mytell->($fh));
    push @lno, ($fh->input_line_number . "-" . $.); # verify tell-sets-$. behavior
    my $go = 1;
    while ($go and @coderefs > 1) {
        my $code = shift @coderefs;
        $code->($fh, \$dest) or $go = 0;
        push @lno, $fh->input_line_number . "-" . $.;
        push @tell, $mytell->($fh);
        if ($go and length $dest and $do_ungetc) {
            $fh->ungetc( ord(substr $dest, -1, 1, '') );
            push @lno, $fh->input_line_number . "-" . $.;
            push @tell, $mytell->($fh);
        }
    }
    while ($go and $coderefs[0]->($fh, \$dest)) {
        push @lno, $fh->input_line_number . "-" . $.;
        push @tell, $mytell->($fh);
    }
    push @lno, $fh->input_line_number . "-" . $.;
    push @tell, $mytell->($fh);
    push @lno, $fh->input_line_number . "-" . $.;

    $tell_result_sequence{$is_io_coderef} = join ",", @tell;
    $lno_result_sequence{$is_io_coderef} = join ",", @lno;
    return $dest;
}

sub readsub {
    my $segs = shift;

    return unless @$segs;
    return shift @$segs;
}

sub segment_input {
    my ($str, $seglen) = @_;

    my @seg;
    while (length $str) {
        push @seg, substr $str, 0, $seglen, '';
    }
    return \@seg;
}

sub build_read_code {
    my ($use_sysread, $block_sizes) = @_;
    my $read = $use_sysread ? 'sysread' : 'read';

    my @readcode;

    unless ($use_sysread) {
        my @linewise_readcode = (
            '$_ = <$fh>; return unless defined; $$dest .= $_',
            '$_ = $fh->getline; return unless defined; $$dest .= $_',
            '$$dest .= join "", <$fh>; return',
            '$$dest .= join "", $fh->getlines; return',
        );
        @readcode = map( { {SrcCode => $_} }
            @linewise_readcode,
            map ({'local $/; '.$_} @linewise_readcode),
            map ({'local $/="oo"; '.$_} @linewise_readcode),
            '$_ = $fh->getc; return unless defined; $$dest .= $_',
        );
        push @readcode, map { {SrcCode => "local \$/=''; $_", ParaMode => 1} } @linewise_readcode;
    }

    my $readcall_template = <<'ENDCODE';
       my $got = __READCALL__;
       unless (defined $got) {
           $$dest = "*** FAIL: __READ__ returned undef ***";
           return;
       }
       $got or return;
       $$dest .= $_;
ENDCODE
    $readcall_template =~ s/__READ__/$read/g;
    foreach my $blocksize (@$block_sizes) {
        foreach my $readcall ("$read \$fh, \$_, $blocksize", "\$fh->$read(\$_, $blocksize)") {
            my $fullcode = $readcall_template;
            $fullcode =~ s/__READCALL__/$readcall/g;
            push @readcode, {SrcCode => $readcall, FullSrcCode => $fullcode};
        }
    }

    foreach my $rc (@readcode) {
        $rc->{FullSrcCode} ||= $rc->{SrcCode};
        my $src = "sub { my (\$fh, \$dest) = \@_ ; $rc->{FullSrcCode} ; return 1 }";
        $rc->{CodeRef} = eval $src;
        die "eval [$src]: $@" if $@;
    }

    return @readcode;
}

1;

