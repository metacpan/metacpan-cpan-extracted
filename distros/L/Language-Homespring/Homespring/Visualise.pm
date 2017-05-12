package Language::Homespring::Visualise;

$VERSION = 0.02;

use warnings;
use strict;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{interp}		= $options->{interp};

	return $self;
}

sub do {
	my ($self) = @_;
	my @lines;

	# initiate lines
	my $lines = $self->{interp}->{root_node}->get_depth();
	for(my $i=0; $i<$lines; $i++){
		$lines[$i] = '-> ';
	}

	# do stuff
	my %nodes = ( 0 => $self->{interp}->{root_node} );
	
	while (scalar(keys(%nodes))){

		# get longest name
		my $longest = 0;
		for (values %nodes){
			my $l = length($_->{node_name_safe});
			$longest = $l if ($l > $longest);
		}

		# add nodes and stems
		for (my $i=0; $i<$lines; $i++){
			my $line = $nodes{$i}->{node_name_safe};
			my $extra = $longest+1-(($line)?length($line):0);
			my $extra_char = ' ';
			$extra_char = '-' if ($line && scalar(@{$nodes{$i}->{child_nodes}}));
			$line .= $extra_char x $extra;
			$lines[$i] .= $line;
		}

		# calculate news nodes
		my %new_nodes;

		for (keys(%nodes)){
			my $node = $nodes{$_};
			my $index = $_;
			for my $child(@{$node->{child_nodes}}){
				#print "INSERTING AT $index -> $child->{node_name_safe} is child of $node->{node_name_safe}\n";
				$new_nodes{$index} = $child;
				$index += $child->get_depth();
			}
		}

		# add junctions
		my %junctions;
		for (keys %nodes){
			my $index = $_;
			my $node = $nodes{$_};
			my $child_count = scalar(@{$node->{child_nodes}});
			if ($child_count){
				$junctions{$index} = ($child_count==1)?'--':'+-';
				my @nodes = @{$node->{child_nodes}};
				pop @nodes;
				for (@nodes){
					for (my $j=0; $j<$_->get_depth()-1; $j++){
						$junctions{$index+$j+1} = '| ';
					}
					$junctions{$index+$_->get_depth()} = '+-';
					$index += $_->get_depth();
				}
			}
		}
		for (my $i=0; $i<$lines; $i++){
			$lines[$i] .= ($junctions{$i})?$junctions{$i}:'  ';
		}

		# assign for next round
		%nodes = %new_nodes;
	}

	# join lines

	return join("\n",@lines)."\n";
}

__END__

=head1 NAME

Language::Homespring::Visualise - An op-tree viewer for "Homespring"

=head1 SYNOPSIS

  use Language::Homespring;
  use Language::Homespring::Visualise;

  my $code = "bear hatchery Hello,. World ..\n powers";

  my $hs = new Language::Homespring();
  $hs->parse($code);

  my $vis = new Language::Homespring::Visualise({'interp' => $hs});
  print $vis->do();

=head1 DESCRIPTION

This module implements a fairly quick and dirty viewer
for Homespring op-trees. It's very useful for checking that
your programming is parsing correctly.

=head1 METHODS

=over 4

=item new({'interp' => $hs})

Creates a new Language::Homespring::Visualise object. The single 
hash argument contains initialisation info. The only key currently
supported (and required!) is 'interp', which should point to the
Language::Homespring object you wish to visualise.

=item do()

Returns a string containing a visualisation of the op-tree.

=back

=head1 AUTHOR

Copyright (C) 2003 Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<perl>

L<Language::Homespring>

=cut

