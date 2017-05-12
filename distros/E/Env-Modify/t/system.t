use Test::More tests => 48;

use Env::Modify ':system';
use strict;
use warnings;
no warnings 'io';
no warnings 'once';


$? = 256;
$ENV{FOO} = 'bar';
my $c1 = system("echo \$FOO");
ok( $c1 == $?, '$? matches system return val');
ok( $? == 0, 'system status ok');

$c1 = CORE::system("export FOO=baz");
ok( $ENV{FOO} ne 'baz', 'env not modified in CORE::system' );

$? = -1;
$c1 = system("export FOO=baz");
ok($c1 == 0, 'system status ok');
ok( $? == 0, 'qx status ok' );
ok( $ENV{FOO} eq 'baz', 'env modified in system' );

$c1 = system("export FOO=123; echo \$FOO \$FOO \$FOO 1>&2");
ok($c1 == 0, 'system status ok');
ok( $ENV{FOO} eq '123', 'env modified in system');

$c1 = system("\"$^X\" -e \"exit 1\"");
ok($c1 == 1 << 8, 'return code makes sense');

$c1 = system("\"$^X\" -e \"exit 117\"");
ok($c1 == 117 << 8, 'return code makes sense');


# weird ==>
#   CORE::system("$^X -e 'kill q{TERM},\$\$'")  return 15
#   CORE::system("$^X -e 'kill q{TERM},\$\$' 2>/dev/null")  return 36608
#
#
# we will return 15 (or whatever SIGTERM corresponds to) but this
# test will accept (128 + 15) << 8 = 36608, too

my $c2 = CORE::system("'$^X' -e 'kill q{TERM},\$\$'");
my $c3 = system("'$^X' -e 'kill q{TERM},\$\$'");
ok($c2 == $c3 || $c2 == (128+$c3) << 8 || $c3 == (128+$c2) << 8,
   'signal behavior matches') or diag "$c2 $c3";

$c1 = system($^X,"-e","exit 1 if 0");
ok($c1 == 0, 'system LIST');

$c1 = system($^X,"-e","exit 1 if 1");
ok($c1 == 1 << 8, 'system LIST');

$c1 = system("lkjaslkdhewiuoy asdfqwer 2>/dev/null");
ok($c1 != 0, 'command not found ok');
$c2 = system("lkjaslkdhewiuoy", "asdfqwer");
ok($c2 != 0, 'command not found ok, LIST');
ok($c1 == $c2, 'LIST, EXPR have same status for command not found');



# if an external command from  system  writes to its
# standard output and standard error, they are channelled
# to file descriptors 1 and 2 in Perl, whether or not
# those file descriptors are still pointed to by
# STDOUT and STDERR. Want to make sure  Env::Modify::system
# has the same behavior.


use warnings 'io';
open DUPOUT,">&STDOUT" or die;
open DUPERR,">&STDERR" or die;
my $tf1 = tempfile();
my $tf2 = tempfile();
open STDOUT,">$tf1" or die;
open STDERR,">$tf2" or die;
ok(fileno(STDOUT) == 1, 'reopened STDOUT still fd 1');
ok(fileno(STDERR) == 2, 'reopened STDERR still fd 2');

$c1 = system("echo qqq");
$c2 = system("echo rrr 1>&2");
ok($c1==0 && $c2==0, 'system ok after redirect STDOUT,STDERR');

$c3 = system($^X,"-e",'print STDOUT qq{foo\n};',
             "-e",'print STDERR qq{bar\nbaz\n};');
ok($c3 == 0, 'system LIST ok after redirect STDOUT, STDERR');

open STDOUT,'>&DUPOUT' or die;
open STDERR,'>&DUPERR' or die;

open my $fh, '<', $tf1;
my $data1 = join '',<$fh>;
close $fh;
open $fh, '<', $tf2;
my $data2 = join '',<$fh>;
close $fh;

ok($data1 eq "qqq\nfoo\n", 'system wrote out to fd 1');
ok($data2 eq "rrr\nbar\nbaz\n", 'system wrote err to fd 2');
unlink $tf1,$tf2;



# exercise different shells

SKIP:
{
     local $Env::Modify::SHELL = 'dash';
     $ENV{why} = "I don't know";
     my $c0 = eval { system("export why=because") };
     if ($@ && $@ =~ /error (opening|closing) pipe/) {
         skip "dash shell not available for test", 4;
     }
     ok($ENV{why} eq 'because', 'dash shell - export');
     ok($c0 == 0, 'dash returned true');
     my $c1 = system("setenv why tomorrow");
     ok($ENV{why} ne 'tomorrow', 'dash shell does not recognize setenv');
     ok($c1 != 0, 'dash returned false');
}

 SKIP:
{
    local $Env::Modify::SHELL = 'csh';
    $ENV{cat} = 'dog';
    $ENV{turtle} = 'frog';

    # this can fail on csh that require you to say "setenv foo $status"
    # instead of "setenv foo $?". Fix needed in Shell::GetEnv
    my $c0 = eval { system("setenv cat fish") };
    if ($@ && $@ =~ /error (opening|closing) pipe/) {
        skip "csh shell not available for test", 4;
    }
    my $c1 = system("export turtle=dove");  # not valid in csh
    ok($ENV{cat} eq 'fish', 'csh - setenv');
    ok($c0 == 0, 'csh return true');
    ok($ENV{turtle} eq 'frog', 'csh does not recognize export');
    ok($c1 != 0, 'csh returned false');
}

 SKIP:
{
    local $Env::Modify::SHELL = 'tcsh';
    $ENV{meaning} = '19';
    my $c0 = eval { system("setenv meaning 42") };
    if ($@ && $@ =~ /error (opening|closing) pipe/) {
        skip "tcsh shell not available for test", 4;
    }
    ok($ENV{meaning} eq '42', 'tcsh');
    ok($c0 == 0, 'tcsh returned true');
    my $c1 = system("export meaning=75");
    ok($ENV{meaning} ne '75', 'tcsh does not recognize export');
    ok($c1 != 0, 'tcsh returned false');
}

{
    local $Env::Modify::SHELL = 'bogush';
    $ENV{abc} = "def";
    eval {
        system("export abc=123");
        system("setenv abc 123");               
    };
    ok($@ && $@ =~ /unsupported shell/, 'unsupported shell exception');
    ok($ENV{abc} eq 'def', 'no change for bogus shell');
}

SKIP:
{
    local $Env::Modify::SHELL = "ksh";
    $ENV{when} = "later";
    $ENV{where} = "over there";
    my $c0 = eval { system("export when=now") };
    if ($@ && $@ =~ /error (opening|closing) pipe/) {
        skip "ksh shell not available for test", 4;
    }
    ok($ENV{when} eq 'now', 'ksh - export');
    ok($c0 == 0, 'ksh returned true');
    my $c1 = system("setenv where here 2>/dev/null");
    ok($ENV{where} ne 'here', 'ksh does not recognize setenv');
    ok($c1 != 0, 'ksh returned false');
}

 SKIP:
{
    local $Env::Modify::SHELL = "bash";
    $ENV{when} = "later";
    $ENV{where} = "over there";
    my $c0 = eval { system("export when=now") };
    if ($@ && $@ =~ /error (opening|closing) pipe/) {
        skip "bash shell not available for test", 4;
    }
    ok($ENV{when} eq 'now', 'bash - export');
    ok($c0 == 0, 'bash returned true');
    my $c1 = system("setenv where here 2>/dev/null");
    ok($ENV{where} ne 'here', 'bash does not recognize setenv');
    ok($c1 != 0, 'bash returned false');
}

 SKIP:
{
    local $Env::Modify::SHELL = "zsh";
    $ENV{when} = "later";
    $ENV{where} = "over there";
    my $c0 = eval { system("export when=now") };
    if ($@ && $@ =~ /error (opening|closing) pipe/) {
        skip "zsh shell not available for test", 4;
    }
    ok($ENV{when} eq 'now', 'zsh - export');
    ok($c0 == 0, 'zsh returned true');
    my $c1 = system("setenv where here 2>/dev/null");
    ok($ENV{where} ne 'here', 'zsh does not recognize setenv');
    ok($c1 != 0, 'zsh returned false');
}

my $tfn = 0;
sub tempfile {
    $tfn++;
    sprintf "tmpfile%d.%d", $$, $tfn;
}










