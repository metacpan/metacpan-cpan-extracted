use warnings;
use 5.016;
use Data::Dumper;
use Functional::Types;

sub ArgType { newtype String,@_ }
sub ArgMode { newtype String,@_ }
sub ArgPos { newtype Int,@_ }
sub ArgRec {typename}
sub MkArgRec { newtype ArgRec,Record(ArgMode,ArgPos,ArgType),@_ }
#say Dumper( MkArgRec);
my $ar= MkArgRec(ArgMode("Read"),ArgPos(3),ArgType('Double')) ;
#say Dumper($ar);
say show($ar);

type my $h = ArgRec;
# We use at() like in arrays.
# This is broken because there is no typecheck on the call to at()
$h->at(0,'ReadWrite');
$h->at(1,0);
$h->at(2,'Integer');
#$h->field(ArgMode,'ReadWrite');
#$h->field(ArgPos,0);
#$h->field(ArgType,'Integer');

type my $r = ArgRec;
bind $r, MkArgRec( ArgMode('Read'), ArgPos(1) , ArgType('Real') );
#die;
say show($r);
say Dumper($h);
say untype $h->at(1);
say untype $h->at(0);
#say Dumper($r);

say untype $r->at(1);
say untype $r->at(0);
say untype $r->at(2);

