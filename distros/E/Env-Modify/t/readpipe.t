use Test::More tests => 16;

use Env::Modify ':readpipe';

$? = 256;
$ENV{FOO} = 'bar';
my $foo = readpipe("echo \$FOO");
ok( $foo eq "bar\n", 'capture echo ok' ) or diag "\$foo=$foo";
ok( $? == 0, 'readpipe status ok');

$? = -1;
$foo = readpipe('export FOO=baz; echo $FOO');
ok( $foo eq "baz\n", 'capture export + echo ok' );
ok( $? == 0, 'readpipe status ok' );
ok( $ENV{FOO} eq 'baz', 'env modified in readpie' );

$foo = readpipe("export FOO=123; echo \$FOO \$FOO \$FOO 1>&2");
ok( !defined($foo), 'output redirected to fd 2 is not captured');

my $x3 = readpipe(
    Env::Modify::_sh_quote($^X,"-e",'print STDOUT qq{quux\n};'));

my $x4 = readpipe_list($^X, "-e", "print STDOUT qq{quux\\n};");
ok($x3 eq "quux\n", 'readpipe + private sh_quote function output ok');
ok($x4 eq $x3, 'readpipe_list output ok');
ok($? == 0, 'readpipe_list exit status ok');



open DUPOUT,">&STDOUT" or die;
open DUPERR,">&STDERR" or die;
my $tf1 = tempfile();
my $tf2 = tempfile();
open STDOUT,">$tf1" or die;
open STDERR,">$tf2" or die;
ok(fileno(STDOUT) == 1, 'reopened STDOUT still fd 1');
ok(fileno(STDERR) == 2, 'reopened STDERR still fd 2');

my $d1 = readpipe("echo qqq");
my $d2 = readpipe("echo rrr 1>&2");
ok($d1 eq "qqq\n", 'readpipe works with STDOUT redirect');
ok($d2 eq '', 'no output with readpipe("... 1>&2")');

my $d3 = readpipe(
    Env::Modify::_sh_quote($^X,"-e",'print STDOUT qq{foo\n};',
                              "-e",'print STDERR qq{bar\nbaz\n};') );

ok($d3 eq "foo\n", 'readpipe works with STDOUT redirect');

open STDOUT,'>&DUPOUT' or die;
open STDERR,'>&DUPERR' or die;

open my $fh, '<', $tf1;
my $data1 = join '',<$fh>;
close $fh;
open $fh, '<', $tf2;
my $data2 = join '',<$fh>;
close $fh;

ok($data1 eq "", 'readpipe captures output, writes nothing to fd 1');
ok($data2 eq "rrr\nbar\nbaz\n", 'readpipe wrote err to fd 2') or diag $data2;
unlink $tf1,$tf2;

my $tfn = 0;
sub tempfile {
    $tfn++;
    sprintf "tmpfile%d.%d", $$, $tfn;
}
