package Games::Sudoku::OO::Set::Square;
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
    $cell->setSquare($self);
}


sub toStr{
    my $self = shift;
    my $string = shift;
    my $size = sqrt @{$self->{CELLS}};
    for (my $row =0 ; $row < $size; $row++){
	for (my $col=0; $col < $size; $col++){
	    my $square = $col + $row*$size;
	    my $cell = ${$self->{CELLS}}[$square];
	    $string .= $cell->toStr();
	}
	$string .="\n";   
    }
    return $string;
}
1;
