package FakeSh;
#This class imitates a shell class by setting up the basic methods a
#core class expects: _obj,Flag,setFlag

our $Pass = 1;
our %flag;

my $obj = bless {qw/blah blah/}, 'FakeSh';
sub _obj {$obj}
#sub _require { shift; eval "require $_[0]"; if ($@) {warn($@) } }

1;	
