use IO::Infiles;
use Data::Dumper;


my @states = map {chomp;$_}  <SUN2> ;
my @fruits = split /\s+/, <FOO> ;

say Dumper \@fruits, \@states;
say <END>;



__END__ 
this 
is it!
__FOO__ 
apple orange
__SUN1__
__SUN2__
Florida
Oregon
Nevada
