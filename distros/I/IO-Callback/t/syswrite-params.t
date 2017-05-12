# IO::Callback 1.08 t/syswrite-params.t
# Check that IO::Callback's syswrite() accurately emulates Perl's syswrite(),
# particularly in terms of parameter validation.

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use IO::Callback;
use File::Slurp;
use File::Temp qw/tempdir/;
use Fatal qw/open close/;

our $test_nowarnings_hook = $SIG{__WARN__};
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $warning =~ /^Use of uninitialized value (?:\$(?:len|offset) )?in syswrite/i;
    $test_nowarnings_hook->($warning);
};

our $tmpfile = tempdir(CLEANUP => 1) . "/testfile";

my $input_data = 'qwerty';

my @input_len_values = (0, 1, 2, 3);
my @len_values = (-1, 0, 1, 2, 3, 10, undef);
my @offset_values = (-1, -2, -3, -10, 0, 1, 2, 3, 10, undef);

plan tests => 6 * @input_len_values * @len_values * @offset_values + 1;

foreach my $include_undef_params (0, 1) {
    foreach my $input_len (@input_len_values) {
        foreach my $len (@len_values) {
            foreach my $offset (@offset_values) {
                my $test_name = join ",", map {defined() ? $_ : 'undef'} ($include_undef_params, $input_len, $len, $offset);
                my $input = substr 'qwerty0987654321', 0, $input_len;
                my $save_input = $input;

                my $got_contents = '';
                open my $real_fh, ">", $tmpfile;
                my $iocode_fh = IO::Callback->new('>', sub {$got_contents .= shift});

                my @results;
                foreach my $fh ($iocode_fh, $real_fh) {
                    if ($fh eq $real_fh and $input_len == 0 and defined $offset and $offset > 0) {
                        # perl bug #67912
                        push @results, 'died';
                        next;
                    }
                    my $ret;
                    if ($include_undef_params or defined $offset) {
                        eval { $ret = syswrite $fh, $input, $len, $offset };
                    } elsif (defined $len) {
                        eval { $ret = syswrite $fh, $input, $len };
                    } else {
                        eval { $ret = syswrite $fh, $input };
                    }
                    if ($@) {
                        push @results, "died: $@";
                    } else {
                        defined $ret or $ret = '**undef**';
                        push @results, "returned: $ret";
                    }
                    if ($fh eq $iocode_fh) {
                        is( $input, $save_input, "$test_name left input unchanged" );
                    }
                }
                my ($got, $want) = @results;

                $want =~ s/\.$//;
                if ($want eq 'died' and $got =~ /^died/) {
                    $got = 'died';
                }
                if ($got =~ /\.$/ and $want !~ /\.$/) {
                    chomp $want;
                    $want .= ".\n";
                }
                is( $got, $want, "$test_name results same as real file" );

                my $want_contents = read_file $tmpfile;
                is( $got_contents, $want_contents, "$test_name data written same as real file" );
            }
        }
    }
}

