package MarpaX::Languages::PowerBuilder::PBT;
use base qw(MarpaX::Languages::PowerBuilder::base);

#a PBT parser by Sébastien Kirche

sub syntax {
	#~ Format ProjectList AppName AppLib LibList Type
	my $ppa = shift;
	my ($fmt, $projects, $app, $applib, $libs, $type) = @_;

	my %attrs = ( format => $fmt, projects => $projects, appname => $app, applib => $applib, liblist => $libs, type => $type);
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

sub libList {
	my ($ppa, $liblist) = @_;
	my @libs = split ';', $liblist;
	return \@libs;
}

sub deploy {
	my ($ppa, $depproj) = @_;
	my @proj;
	foreach my $dp (@$depproj){
		my ($chk, $name, $lib) = split '&', $dp;
		push @proj, {name => $name, lib => $lib, checked => $chk};
	}
	return \@proj;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/\\\\/\\/g;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

