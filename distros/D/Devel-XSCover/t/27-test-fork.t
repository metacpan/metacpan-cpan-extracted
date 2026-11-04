use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();

my ($fork_fails, $exec_log);
BEGIN {
    *CORE::GLOBAL::fork = sub {
        return CORE::fork() unless $fork_fails;
        $! = 11;
        return undef;
    };
    *CORE::GLOBAL::exec = sub {
        return CORE::exec(@_) unless $exec_log;
        open my $fh, '>', $exec_log or die "$exec_log: $!";
        print $fh "@_\n", 'H=[', $ENV{HARNESS_PERL_SWITCHES} // '', "]\n", 'P=[', $ENV{PERL5OPT} // '', "]\n";
        close $fh;
        return 1;
    };
}
use Devel::XSCover::Test ();

plan skip_all => 'fork and process groups here' if $^O eq 'MSWin32';
delete local @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};

my $dir   = File::Temp->newdir;
my $quick = XSCoverTest::fake_script($dir, 'fake-quick', 'exit 0');

my $here = Cwd::getcwd();
$fork_fails = 1;
ok(!eval { Devel::XSCover::Test->new(dir => "$dir", make => $quick, silent => 1)->run; 1 }, 'the run dies when it cannot fork');
like($@, qr/^xs_cover: cannot fork: \S/, 'with the reason');
$fork_fails = 0;
chdir $here or die "$here: $!";

{
    local $SIG{__WARN__} = sub { };
    is(Devel::XSCover::Test->new(dir => "$dir", make => File::Spec->catfile($dir, 'no-such-make'), silent => 1)->run, 127, 'a command that cannot be run is 127');
}

$exec_log = File::Spec->catfile($dir, 'exec');
my $parent = $$;
my $t = Devel::XSCover::Test->new(dir => "$dir", make => 'make-stub', silent => 1);
my $status = $t->run;
exit 0 if $$ != $parent;
is($status, 0, 'the child handed the command exits 0 for the parent');
open my $fh, '<', $exec_log or die "$exec_log: $!";
my @seen = <$fh>;
close $fh;
chomp @seen;
my $sw = $t->switches;
is_deeply(\@seen, ['make-stub test', "H=[$sw]", "P=[$sw]"], 'and had the switches in its environment when it ran it');

done_testing;
