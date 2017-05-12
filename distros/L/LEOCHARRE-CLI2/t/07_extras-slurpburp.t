use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::CLI2 qw/:all/;

ok(1,'compiled');




my $r;

my $content = q{temp.tmp
ok 5 - quoted works
temp.tmp
ok 6 - unquoted fails
sh: -c: line 0: unexpected EOF while looking for matching `''
sh: -c: line 1: syntax error: unexpected end of file
ok 7 - unquoted fails
does it work? please type yes (y/n): y
ok 8 - yn()
ok 9 - del
ok 10
 # './t/anxample bad name tm,'\''p'
1..10
$ perl t/06_extras-sq-yml.t 
syntax error at t/06_extras-sq-yml.t line 17, near "'./t/temp.yml')"
Execution of t/06_extras-sq-yml.t aborted due to compilation errors.
# Looks like your test died before it could output anything.
$ perl t/06_extras-sq-yml.t 
ok 1 - compiled
ok 2
ok 3 - abs_path()
ok 4 - YAML::DumpFile()
ok 5 - sq()
 # quoted: '/home/leo/strangely stupidly named path'
temp.tmp
ok 6 - quoted works
};

my $abs = './t/testfile.tmp';
unlink $abs; # checking..



ok( burp($abs, $content),'burp()' );

ok -f $abs;
ok( $r = slurp($abs), 'slurp()' );
ok( length($r) > 60, 'slurp() length was more than 50');

my @r;
ok( @r = slurp($abs), 'slurp() in array context');

my  $c = scalar @r;
ok( $c > 10 , "got scalar $c lines");


unlink $abs;

