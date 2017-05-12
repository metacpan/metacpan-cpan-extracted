use warnings;
use 5.016;

use Data::Dumper;
use Functional::Types;

#type my $u = Int;
#say Dumper($u);
type my $f = Int =>Int =>Int;
#say Dumper($f);

bind $f,  sub { (my $x, my $y)=@_; return $x*$y } ;
#say Dumper($f);
my $res = $f->(Int(4),Int(5) );
say show($res);
say untype $res;

type my $fa = Int => Array(Int);
#say Dumper($fa);
bind $fa,  sub { (my $n)=@_; return [map {$_*$_+1} (0 .. $n) ] } ;
#say Dumper($fa);

my $res2 = $fa->( Int(4) );
say show $res2;
my $res3 = $fa->( 4 );
say Dumper(untype $res3);
type my $fr = Array(a) => Array(a);
#say Dumper($fr);
bind $fr, sub { [ reverse(@{$_[0]}) ] };
my $res4 = $fr->($res3);
say Dumper( $res4 );
#say untype $res2->at(2);

sub VarDecl {typename};
sub MkVarDecl{ newtype VarDecl, Record(Int,String), @_ };

type my $fp = String => VarDecl;
say Dumper($fp);

