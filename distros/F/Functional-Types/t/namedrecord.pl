use warnings;
use 5.016;
use Data::Dumper;
use Functional::Types;

sub ArgType { newtype String,@_ }
sub ArgMode { newtype String,@_ }
sub ArgPos { newtype Int,@_ }
sub ArgRec {typename}
sub MkArgRec { newtype ArgRec,Record('argmode'=>ArgMode,'argpos'=>ArgPos,'argtype'=>ArgType),@_ }
#say Dumper( MkArgRec);
my $ar= MkArgRec(ArgMode("Read"),ArgPos(3),ArgType('Double')) ;
#say Dumper($ar);
say show($ar);

type my $h = ArgRec;
#say Dumper($h);
# We use at() like in arrays.
# This is broken because there is no typecheck on the call to field()
# Also, when field() is called before bind() was called, the type constructor has not been called! This is why I thought we could use a lookup table from typename to type constructor
# The alternative is that the call to field would trigger type construction ...
# Problem is, there is no connection between the type name and the type constructor. 
# In Haskell, the type will be constructed when the typename is declared
# Can I have something like
# data ArgRec = MkArgRec ... ?
# So, in short, for now, $h *must* be constructed
#say '-' x 80;
bind $h, MkArgRec; # This is OK as it is not immutable anyway
#say Dumper($h);
$h->field('argmode','ReadWrite');
$h->field('argpos',0);
$h->field('argtype');
#$h->field(ArgMode,'ReadWrite');
#$h->field(ArgPos,0);
#$h->field(ArgType,'Integer');

type my $r = ArgRec;
bind $r, MkArgRec( ArgMode('Read'), ArgPos(1) , ArgType('Real') );
#die;
say show($r);
#say Dumper($h);
say untype $h->field('argpos');
say untype $h->field('argmode');
#say Dumper($r);

say untype $r->field('argpos');
say untype $r->field('argmode');
say untype $r->field('argtype');

