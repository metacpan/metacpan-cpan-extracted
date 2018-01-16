package MarpaX::Languages::PowerBuilder::PBG;
use base qw(MarpaX::Languages::PowerBuilder::base);

#a PBG parser by Sébastien Kirche

sub syntax {
	my ($ppa, $fmt, $libs, $objs) = @_;
    my %attrs = ( format => $fmt, libraries => $libs, objects => $objs);
 	return \%attrs;
}

sub format {
	my ($ppa, $vers, $date) = @_;
    my %attrs = ( version => $vers,
    				date => $date);
	return \%attrs;
}

sub libraries {
	my ($ppa, @objs) = @_;
	my @libs = map{ $_->[0] } @{$objs[0]}; # LibraryList -> ObjectLocationList -> ObjectLocation+
    return \@libs;
} 

sub objects {
	my ($ppa, @objs) = @_;
	my %objects;
	map{$objects{$_->[0]} = $_->[1]} @{$objs[0]}; # ObjectList -> ObjectLocationList -> ObjectLocation+
	return \%objects;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

