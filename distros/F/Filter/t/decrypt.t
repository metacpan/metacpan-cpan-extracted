
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin"; # required to load filter-util.pl

require "filter-util.pl";

use Config;
use Cwd ;
my $here = getcwd ;

use vars qw( $Inc $Perl ) ;

my $script = <<'EOM' ;

print "testing, testing, 1, 2, 3\n" ;
require "./plain" ;
use Cwd ;
$cwd = getcwd ;
print <<EOT ;
some
more test
lines
EOT

print "a multi-line
 string
$cwd\n" ;

format STDOUT_TOP =
I'm a format top
.

format STDOUT =
@<<<<<<<<<
"I'm not"
.


write ;
EOM

my $expected_output = <<EOM ;
testing, testing, 1, 2, 3
This is plain text
some
more test
lines
a multi-line
 string
$here
I'm a format top
I'm not
EOM

my $filename = "decrypt$$.tst" ;

writeFile($filename, $script) ;
`$Perl $Inc decrypt/encrypt $filename` ;
writeFile('plain', 'print "This is plain text\n" ; 1 ;') ;

my $a = `$Perl $Inc $filename 2>&1` ;

print "1..7\n" ;

print "# running perl with $Perl\n";
print "# test 1: \$? $?\n" unless ($? >>8) == 0 ;

ok(1, ($? >>8) == 0) ;
ok(2, $a eq $expected_output) or diag("Got '$a'");

# try to catch error cases

# case 1 - Perl debugger
unless ($Config{usecperl}) {
  $ENV{'PERLDB_OPTS'} = 'noTTY' ;
  $a = `$Perl $Inc -d $filename 2>&1` ;
  ok(3, $a =~ /debugger disabled/)  or diag("Got '$a'");;
} else {
  ok(3, 1, "SKIP cperl -d");
}

# case 2 - Perl Compiler in use
$a = `$Perl $Inc -MCarp -MO=Deparse $filename 2>&1` ;
#print "[[$a]]\n" ;
my $skip = "" ;
$skip = "# skipped -- compiler not available"
    if $a =~ /^Can't locate O\.pm in/ ||
       $a =~ /^Can't load '/ ||
       $a =~ /^"my" variable \$len masks/ ;
print "# test 4: Got '$a'\n" unless $skip || $a =~ /Aborting, Compiler detected/;
ok(4, ($skip || $a =~ /Aborting, Compiler detected/), $skip) ;

# case 3 - unknown encryption
writeFile($filename, <<EOM) ;
use Filter::decrypt ;
mary had a little lamb
EOM

$a = `$Perl $Inc $filename 2>&1` ;
ok(5, $a =~ /bad encryption format/) or diag("Got '$a'");

# case 4 - extra source filter on the same line
writeFile($filename, <<EOM) ;
use Filter::decrypt ; use Filter::tee '/dev/null' ;
mary had a little lamb
EOM

$a = `$Perl $Inc $filename 2>&1` ;
ok(6, $a =~ /too many filters/)  or diag("Got '$a'");

# case 5 - ut8 encoding [cpan #110921]
writeFile($filename, <<'EOF') ;
use utf8;
my @hiragana =  map {chr} ord("ぁ")..ord("ん");
my $hiragana = join('' => @hiragana);
my $str = $hiragana;
$str =~ tr/ぁ-ん/ァ-ン/;
print $str;
EOF

if (   $^O eq 'MSWin32'
    or !($ENV{LC_ALL} or $ENV{LC_CTYPE})
    or ($ENV{LC_ALL} and $ENV{LC_ALL} !~ /UTF-8/)
    or ($ENV{LC_CTYPE} and $ENV{LC_CTYPE} !~ /UTF-8/) )
{
    print "ok 7 # skip no UTF8 locale\n";
} else {
    my $ori = `$Perl -C $Inc $filename` ;
    `$Perl $Inc decrypt/encrypt $filename` ;
    $a = `$Perl -C $Inc $filename 2>&1` ;
    if ($a eq $ori) {
        ok(7, $a eq $ori);
    } else {
        ok(7, 1, "TODO UTF-8 locale only. Got '$a'");
    }
}

unlink $filename ;
unlink 'plain' ;
