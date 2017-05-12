use ExtUtils::TBone;
use strict;  

my @Expect = 
(
 {
     Func   =>'catdir',
     Args   =>[qw(. testout)],
     OnMac  =>':testout:',
     OnUnix =>'./testout',
 }, 
 {
     Func   =>'catdir',
     Args   =>[qw(etc)],
     OnMac  =>'etc:',
     OnUnix =>'/etc',
 }, 
 {
     Func   =>'catdir',
     Args   =>[qw(etc passwd)],
     OnMac  =>'etc:passwd:',
     OnUnix =>'/etc/passwd',
 }, 
 {
     Func   =>'catfile',
     Args   =>[qw(. testout foo.tlog)],
     OnMac  =>':testout:foo.tlog',
     OnUnix =>'./testout/foo.tlog',
 }, 
 {
     Func   =>'catfile',
     Args   =>[qw(etc passwd)],
     OnMac  =>'etc:passwd',
     OnUnix =>'/etc/passwd',
 }, 
 );

### START REAL TEST:
my $T = typical ExtUtils::TBone;
$T->begin(2 * int(@Expect));
foreach my $e (@Expect) {
    my $m = $e->{Func};
    foreach my $os (map {/^On(.*)/ ? $1 : ()} keys %$e) {
	local($^O) = ($os);
	my $result = $T->$m(@{$e->{Args}});
	$T->ok_eq($result, $e->{"On$os"},
		  "Test of $m on $os",
		  OS     => $os,
		  Want   => $e->{"On$os"},
		  Got    => $result);
    }
}
$T->end;
1;
