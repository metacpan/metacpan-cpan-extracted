package FloorWaxDessertTopping;

use strict;
use warnings;
use Lexical::Attributes;

use FloorWax;
use DessertTopping;

our @ISA = qw /FloorWax DessertTopping/;

my $destruct_count;

method init {
    $self -> FloorWax::init ($_ [0])
          -> DessertTopping::init ($_ [1]);
}

method colour {
    sprintf "%s and %s" => $self -> FloorWax::colour,
                           $self -> DessertTopping::colour;
}

method DESTRUCT {
    $destruct_count ++;
}

sub destruct_count {
    $destruct_count;
}


1;

__END__
