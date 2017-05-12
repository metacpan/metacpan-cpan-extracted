package GraphViz::Zone; 

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use GraphViz;

sub new {
	my ($this, @args) = @_;
	my $class = shift; 
	my $self = bless { @_ }, $class;
	return $self->_init(@_);
}


sub _init {
	my $g = GraphViz->new(directed => 0, width => 7, height => 7); 

	my ($self, %params) = @_;;
	my ($host, $ip, $text, %host_info);
	
	# Caller can set:
	#  \- zonefile:		(mandatory)
	#  \- output: 		(default to 'zone.png')
    
	return undef unless exists($params{zonefile});
	$self->{output} 	||= 'zone.png';
	
	# Open the zone file for reading.
	open(ZONEFILE, $self->{zonefile});

	while(<ZONEFILE>) { 
		# If we have an A record.
		if (m/^(\w*)\s+IN\s+A\s+(.*)$/) {
			if (length($2) > 0) {
				# Create a hash entry for the host, add the IP.
				$host_info{$1}{ip} = $2;
			}
		}
	
		# If we have a TXT record.
		if (m/^(\w*)\s+IN\s+TXT\s+"(.*)"$/) {
			# Add the TXT entry to the host's hash key.
			my $text = $2;
			if (length($text) > 0 and exists($host_info{$1})) { 
				$host_info{$1}{text} = $text;
			}
		}
	}

	$g->add_node($self->{zonefile});
	for(keys %host_info) {
		my $string = "$_\n";
		$string .= "IP: $host_info{$_}{ip}\n" if (defined ($host_info{$_}{ip}));
		$string .= "Text: $host_info{$_}{text}" if (defined ($host_info{$_}{text}));
		$g->add_node($_, label => $string, minlen => 5, weight => 0.5);
		$g->add_edge($self->{zonefile} => $_);
	}

	$g->as_png($self->{output});

}


1;
__END__

=head1 NAME

GraphViz::Zone - Perl interface to graphing hosts in BIND zone files.

=head1 SYNOPSIS

  use GraphViz::Zone; 
  
  $obj = new GraphViz::Zone(zonefile => 'myzone.zone', output => 'zone.png'); 

=head1 DESCRIPTION

 Perl interface to graphing hosts in BIND zone files.

=head1 METHOD

B<new> - Creates a new GraphViz::Zone object.  Parameters:

  zonefile:  (mandatory) Filename for a valid BIND zone file. 
  output:    The filename to output to.  Output file type is png. 

=head1 NOTES

This works on my system.  It probably won't work on yours.  If it doesn't, send me your zone file; I'll either patch the regexps to get things working, or re-write to use a proper parser instead of regexps.  Also, GraphViz is prone to producing ugly graphs where a small number of nodes are involved.  In this case, try upping the 'length', 'width' and 'epsilon' parameters (sparingly) in the constructor.

=head1 TODO

Plenty.  Other tags (HINFO etc) as well as TXT.  An option of whether to graph TXT/A or not.  Organising by the IP, and into IP blocks.  Lots, lots more.

=head1 AUTHOR

Chris Ball <chris@cpan.org>

=head1 SEE ALSO

Leon Brocard's GraphViz.pm, http://www.research.att.com/sw/tools/graphviz/.

=cut
