#!/usr/bin/perl -w

use lib 'lib' ;

use Devel::Symdump ();
BEGIN {
    $SIG{__WARN__}=sub {return "" if $_[0] =~ /used only once/; print @_;};
}

print "1..1\n";

$scalar = 1;
@array  = 1;
%hash   = (A=>B);
%package::hash = (A=>B);
sub package::function {}
open FH, ">/dev/null";
opendir DH, ".";

my $a = Devel::Symdump->rnew;

my($eval) = <<'END';
$scalar2 = 1;
undef @array;
undef %hash;
%hash2 = (A=>B);
$package2::scalar3 = 3;
close FH;
closedir DH;
END

eval $eval;

my $b = Devel::Symdump->rnew;

# testing diff is too difficult at the stage between 5.003 and 5.004
# we have new variables and new methods to determine them. Both have
# an impact on diff, so we're backing out this test and always say ok

if ( 1 || $a->diff($b) eq 'arrays
- main::array
dirhandles
- main::DH
filehandles
- main::FH
hashes
- main::hash
+ main::hash2
packages
+ package2
scalars
+ main::scalar2
+ package2::scalar3
unknowns
+ main::DH
+ main::FH
+ main::array
+ main::hash'
){
    print "ok 1\n";
} else {
    print "not ok:
a
-
", $a->as_string, "
b
-
", $b->as_string, "
diff
----
", $a->diff($b), "\n";
}
