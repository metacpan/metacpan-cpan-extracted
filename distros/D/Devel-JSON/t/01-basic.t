
use strict;
use warnings;

use Test::More tests => 2;
use IPC::Open3 qw<open3>;
use File::Spec ();
use IO::Handle ();
use Config;

$ENV{PERL5LIB} = join($Config{path_sep},
    defined($ENV{PERL5LIB})? ($ENV{PERL5LIB}) : (),
    'lib'
);

note "PERL5LIB=$ENV{PERL5LIB}";

open my $stdin, '<', File::Spec->devnull;
my $stdout = IO::Handle->new;
my $pid = open3 $stdin, $stdout, '>&STDOUT',
	    $^X, '-d:JSON=-pretty', '-e', '[1]';
binmode $stdout, ':crlf' if $^O eq 'MSWin32';

my $out = do { local $/; <$stdout> };
waitpid($pid, 0);
is($?, 0, "exit code: 0");
cmp_ok($out, 'eq', '[1]', 'output ok');

