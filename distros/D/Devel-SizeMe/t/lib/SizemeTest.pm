package SizemeTest;

use strict;
use warnings;

use Carp;
use Config;
use Getopt::Long;
use Data::Dumper;
use File::Spec;
use File::Temp qw(tempfile);
use Scalar::Util qw(looks_like_number);
use List::Util qw(shuffle);

use Test::More;

use base qw(Exporter);
our @EXPORT = qw(
    run_test_group
    run_command
    run_perl_command
);

use ExtUtils::testlib;
use Devel::SizeMe::Core; # for Devel::SizeMe::TestWrite

#use Devel::NYTProf::Data;
#use Devel::NYTProf::Reader;
#use Devel::NYTProf::Util qw(strip_prefix_from_paths html_safe_filename);
#use Devel::NYTProf::Run qw(perl_command_words);

my $diff_opts = ($Config{osname} eq 'MSWin32') ? '-c' : '-u';

chdir('t') if -d 't';

my $bindir = (grep {-d} qw(./blib/script ../blib/script))[0] || do {
    my $bin = (grep {-d} qw(./bin ../bin))[0]
        or die "Can't find scripts";
    warn "Couldn't find blib/script directory, so using $bin";
    $bin;
};
my $sizeme_store   = File::Spec->catfile($bindir, "sizeme_store.pl");

my $this_perl = $^X;
$this_perl .= $Config{_exe} if $^O ne 'VMS' and $this_perl !~ m/$Config{_exe}$/i;
# turn ./perl into ../perl, because of chdir(t) above.
$this_perl = ".$this_perl" if $this_perl =~ m|^\./|;


=pod
foo.t
    look for foo-*.tst
    perform to generate foo-*.smt_new and compare with foo-*.smt
    generate .dot_new
=cut

# execute a group of tests (t/testFoo.*) - calls plan()
sub run_test_group {
    my (%opts) = @_;

    # split lines on commas and skip comments
    my @steps;
    for my $line (@{$opts{lines}}) {
        chomp $line;
        next if $line =~ m/^\s*(#|$)/;
        my ($action, @args) = split /,/, $line, -1;
        for my $arg (@args) {
            if (looks_like_number($arg)) {
                next;
            }
            elsif ($arg =~ /^'(.*)'$/) {
                $arg = $1;
            }
            elsif (1) {
                my $fullname = "Devel::SizeMe::Core::$arg";
                no strict 'refs';
                my $value = &$fullname();
                $arg = $value;
            }
        }
        push @steps, [ $action, @args ];
    }

    # obtain group from file name
    my $group = ((caller)[1] =~ /([^\/\\]+)\.t$/) ? $1
        : croak "Can't determine test group";

    # .smt is "SizeMe Token" file
    my $smt_file_old = "$group.smt";
    my $smt_file_new = "$smt_file_old\-new.smt";
    unlink <$group.*new*>; # delete all _new files for this group
    is -s $smt_file_new, undef, "$smt_file_new should not exist";

    # perform the steps
    local $ENV{SIZEME} = $smt_file_new;
    Devel::SizeMe::TestWrite::perform(\@steps);

    # check the raw token output
    ok -s $smt_file_new, "$smt_file_new should not be empty";
    is_file_content_same($smt_file_new, $smt_file_old, 'tokens should match');

    # find all the output formats, generate and compare them
    my @outputs = grep { !m/\.(t|smt)$/ && !m/\bnew\b/ } <$group.*>;
    note "Testing outputs: @outputs";
    for my $output_old (@outputs) {
        my $type = (split /\./, $output_old)[-1];
        my $output_new = $output_old."-new.$type";
        if ($type eq 'dot') {
            run_perl_command("$sizeme_store --$type $output_new $smt_file_new");
        }
        elsif ($type eq 'gexf') {
            run_perl_command("$sizeme_store --$type $output_new $smt_file_new");
        }
        else {
            warn "$output_old ignored - unknown type '$type'";
            next;
        }
        ok -s $output_new, "$output_new should not be empty";
        is_file_content_same($output_new, $output_old, "$output_new should match $output_old");
    }


}


sub is_file_content_same {
    my ($got_file, $exp_file, $testname) = @_;

    my @got = slurp_file($got_file); chomp @got;
    my @exp = slurp_file($exp_file); chomp @exp;

    is_deeply(\@got, \@exp, $testname)
        or diff_files($exp_file, $got_file, $got_file."_patch");
}


sub diff_files {
    my ($old_file, $new_file, $newp_file) = @_;

    # we don't care if this fails, it's just an aid to debug test failures
    my @opts = split / /, $ENV{NYTPROF_DIFF_OPTS} || $diff_opts;    # e.g. '-y'
    system("cmp -s $new_file $newp_file || diff @opts $old_file $new_file 1>&2");
}


sub slurp_file {    # individual lines in list context, entire file in scalar context
    my ($file) = @_;
    open my $fh, "<", $file or croak "Can't open $file: $!";
    return <$fh> if wantarray;
    local $/ = undef;    # slurp;
    return <$fh>;
}


sub run_command {
    my ($cmd, $show_stdout) = @_;
    local $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
    print "$cmd\n";
    local *RV;
    open(RV, "$cmd |") or die "Can't execute $cmd: $!\n";
    my @results = <RV>;
    my $ok = close RV;
    if (not $ok) {
        warn "Error status $? from $cmd!\n";
        $show_stdout = 1;
        sleep 2;
    }
    if ($show_stdout) { warn $_ for @results }
    return $ok;
}


sub run_perl_command {
    my ($cmd, $show_stdout) = @_;
    my @perl = ($this_perl);
    run_command("@perl $cmd", $show_stdout);
}

1;
