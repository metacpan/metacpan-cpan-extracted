package Games::Sudoku::OO::Set::Column;
use Games::Sudoku::OO::Set;
@ISA = ("Games::Sudoku::OO::Set");

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    bless ($self, $class);          # reconsecrate
    return $self;
}



sub setBackReference {
    my $self = shift;
    my $cell = shift;
    $cell->setColumn($self);
}

sub toStr {
    my $self = shift;
    my $string = "";
    foreach my $cell (@{$self->{CELLS}}){
	$string .= $cell->toStr(). "\n";
    }
    return $string;
}
1;
