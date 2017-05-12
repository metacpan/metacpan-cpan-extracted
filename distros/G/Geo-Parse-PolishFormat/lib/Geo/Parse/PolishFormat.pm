package Geo::Parse::PolishFormat;

use 5.008008;
use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.02';

sub new {

	my $package = shift;
	
	my %options = @_;
	
	$options {get_split_depth} ||= sub {
	
		my ($name) = @_;
		
		return 2 if $name =~ /^Data/;
		return 1 if $name =~ /^Nod/;
		return 0;
		
	};
	
	return bless (\%options, $package);

}

sub parse {

	my ($self, $fn, $callback) = @_;
	
	open (F, $fn) or die "Can't read '$fn':$!\n";
	
	my $name;
	my @lines;
	my $attributes;
	my $collections;
	
	while (my $line = <F>) {
	
		$line =~ s{[\n\r]}{}gsm;
		
		if ($line =~ /^\[END/) {

			&$callback ({
				name  => $name,
				lines => \@lines,
				attributes => $attributes,
				collections => $collections,
			});
			
			undef $name;
			undef @lines;
			undef $attributes;
			undef $collections;
			
		}
		elsif ($line =~ /^\[([\w\s]+)\]$/) {
			
			$name = $1;
			
			next;
			
		}
		elsif (!$name) {
		
			next;
			
		}
		else {
		
			push @lines, $line;
		
			my ($key, $value) = split /\=/, $line;
				
			my $split_depth = &{$self -> {get_split_depth}} ($key);
				
			if ($split_depth == 1) {
			
				$value = [split /\,/, $value];
				
			}
			elsif ($split_depth == 2) {
				
				$value =~ s{^\(}{}; 
				$value =~ s{\)$}{};
				$value = [map {[split /\,/, $_]} split /\)\,\(/, $value];
				
			}
				
			$attributes -> {$key} = $value;
				
			if ($key =~ /([A-Za-z_]+)(\d+)$/) {
				$collections -> {$1} ||= [];
				$collections -> {$1} -> [$2] = $value;
			}

		}
	
	}

	close (F);

}

1;
__END__

=head1 NAME

Geo::Parse::PolishFormat - Perl extension for parsing maps in polish text format (*.mp).

=head1 SYNOPSIS

  use Geo::Parse::PolishFormat;
  use Data::Dumper;              # not required, just for demo

  my $p = Geo::Parse::PolishFormat -> new (); 
  
  $p -> parse ('my_map.mp', sub {warn Dumper ($_[0])});
  
### Source file (my_map.mp):

	[POLYLINE] 
	Type=0x6 
	Label=Some Street 
	CityIdx=1 
	RoadID=11111 
	RouteParam=3,0,0,0,0,0,0,0,0,0,0,0 
	Data0=(33.89400,33.40310),(33.89455,33.41477),(33.89458,33.41576) 
	Nod1=0,1604,0 
	Nod2=2,1673,0 
	[END] 

### Result:

$VAR1 = { 

	name => 'POLYLINE', 

	lines => [ 
		'Type=0x6', 
		'Label=Some Street', 
		'CityIdx=1', 
		'RoadID=118291', 
		'RouteParam=3,0,0,0,0,0,0,0,0,0,0,0', 
		'Data0=(33.89400,33.40310),(33.89455,33.41477),(33.89458,33.41576)', 
		'Nod1=0,1604,0', 
		'Nod2=2,1673,0', 
	], 

	attributes => { 
		Type => '0x6', 
		Label => 'Some Street', 
		CityIdx => '1', 
		RoadID => '118291', 
		RouteParam => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
		Data0 => [[33.89400, 33.40310], [33.89455, 33.41477], [33.89458,33.41576]]', 
		Nod1 => [0, 1604, 0], 
		Nod2 => [2, 1673, 0], 
	}, 

	collections => { 
		Data => [$VAR1 -> {Data0}], 
		Nod => [$VAR1 -> {Nod1}, $VAR1 -> {Nod2}], 
	}, 

} 

=head1 SEE ALSO

L<http://www.cgpsmapper.com/>.

=head1 AUTHOR

Dmitry Ovsyanko

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dmitry Ovsyanko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut