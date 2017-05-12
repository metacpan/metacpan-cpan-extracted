use Test::More tests => 13;

use Env::Modify ':backticks';

if ($] > 5.008009) {

    $? = 256;
    $ENV{FOO} = 'bar';
    my $foo = `echo \$FOO`;
    ok( $foo eq "bar\n", 'capture echo ok' ) or diag "\$foo=$foo";
    ok( $? == 0, 'qx status ok');

    $? = -1;
    $foo = qx(export FOO=baz; echo \$FOO);
    ok( $foo eq "baz\n", 'capture export + echo ok' );
    ok( $? == 0, 'qx status ok' );
    ok( $ENV{FOO} eq 'baz', 'env modified in qx' );

    $foo = qx(export FOO=123; echo \$FOO \$FOO \$FOO 1>&2);
    ok( !defined($foo), 'output redirected to fd 2 is not captured');

} else {

    # Perl <v5.8.9 cannot use CORE::GLOBAL::readpipe,
    # so we have to use  backticks()  and  &qx()

    # Perl v5.8.9, too:
    #     www.cpantesters.org/cpan/report/32fa54a2-5c4c-11e6-9451-9b92aab8e0c0

    $? = 256;
    $ENV{FOO} = 'bar';
    my $foo = backticks "echo \$FOO";
    ok( $foo eq "bar\n", 'capture echo ok' ) or diag "\$foo=$foo";
    ok( $? == 0, 'qx status ok');

    $? = -1;
    $foo = &qx("export FOO=baz; echo \$FOO");
    ok( $foo eq "baz\n", 'capture export + echo ok' );
    ok( $? == 0, 'qx status ok' );
    ok( $ENV{FOO} eq 'baz', 'env modified in qx' );

    $foo = &qx("export FOO=123; echo \$FOO \$FOO \$FOO 1>&2");
    ok( !defined($foo), 'output redirected to fd 2 is not captured');
}

# proceed with  Env::Modify::backticks, which works before and after Perl v5.8.9

open DUPOUT,">&STDOUT" or die;
open DUPERR,">&STDERR" or die;
my $tf1 = tempfile();
my $tf2 = tempfile();
open STDOUT,">$tf1" or die;
open STDERR,">$tf2" or die;
ok(fileno(STDOUT) == 1, 'reopened STDOUT still fd 1');
ok(fileno(STDERR) == 2, 'reopened STDERR still fd 2');

my $d1 = Env::Modify::backticks("echo qqq");
my $d2 = Env::Modify::backticks("echo rrr 1>&2");
ok($d1 eq "qqq\n", '`` works with STDOUT redirect');
ok($d2 eq '', 'no output with `... 1>&2`');

my $d3 = Env::Modify::backticks(
    Env::Modify::_sh_quote($^X,"-e",'print STDOUT qq{foo\n};',
                              "-e",'print STDERR qq{bar\nbaz\n};') );

ok($d3 eq "foo\n", '`` works with STDOUT redirect');

open STDOUT,'>&DUPOUT' or die;
open STDERR,'>&DUPERR' or die;

open my $fh, '<', $tf1;
my $data1 = join '',<$fh>;
close $fh;
open $fh, '<', $tf2;
my $data2 = join '',<$fh>;
close $fh;

ok($data1 eq "", '`` captures output, writes nothing to fd 1');
ok($data2 eq "rrr\nbar\nbaz\n", '`` wrote err to fd 2') or diag $data2;
unlink $tf1,$tf2;

my $tfn = 0;
sub tempfile {
    $tfn++;
    sprintf "tmpfile%d.%d", $$, $tfn;
}
