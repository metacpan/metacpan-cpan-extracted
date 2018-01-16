package MarpaX::Languages::PowerBuilder::PBW;
use base qw(MarpaX::Languages::PowerBuilder::base);

#a PBW parser by Sébastien Kirche

sub syntax {
	my $ppa = shift;
	my ($fmt, $uncheck, $targets, $deftrg, $defrmt);
	($fmt, $uncheck, $targets, $deftrg, $defrmt) = @_ if (scalar @_ == 5);
	($fmt, $targets, $deftrg, $defrmt, $uncheck) = (@_, []) if (scalar @_ == 4); #no uncheck

	my %attrs = ( format => $fmt, unchecked => $uncheck, targets => $targets, defaulttarget => $deftrg, defaultremotetarget => $defrmt);
 	return \%attrs;
}

sub format {
	my ($ppa, $vers, $date) = @_;
    my %attrs = ( version => $vers,
    				date => $date);
	return \%attrs;
}

sub indexedItems {
	my ($ppa, @list) = @_;
	my @items = map {$_->[1]} @list;
	#~ map{$items{$_->[0]} = $_->[1]} @list;
	return \@items;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

