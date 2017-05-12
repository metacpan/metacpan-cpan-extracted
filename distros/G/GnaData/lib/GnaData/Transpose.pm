package GnaData::Transpose;
use strict;

sub transpose {
    my ($inh, $outh) = @_;
    my ($row) = 0;
    my ($maxcol) = 0;
    my ($line) = 0;
    my ($store) = [[]];
    
    while ($line = <>) {
	chop $line;
	my (@items) = split (/\t/, $line);
	my ($col, $item);
	$col = 0;
	foreach  $item (@items) {
	    $store->[$row]->[$col] = $item;
	    $col++;
	}
	if ($col > $maxcol) {
	    $maxcol = $col;
	}
	$row++;
    }
    
    my ($i,$j);
    for ($i=0; $i < $maxcol; $i++) {
	my (@items) = ();
	for ($j=0; $j < $row; $j++) {
	    push (@items, $store->[$j]->[$i]);
	}
	$outh->print(join("\t", @items), "\n");
    }   
}
1;
