# E2::Search
# Jose M. Weeks <jose@joseweeks.com>
# 05 June 2003
#
# See bottom for pod documentation.

package E2::Search;

use 5.006;
use strict;
use warnings;
use Carp;

use E2::Ticker;

our $VERSION = "0.32";
our @ISA = qw(E2::Ticker);
our $DEBUG; *DEBUG = *E2::Interface::DEBUG;

sub new { 
	my $arg   = shift;
	my $class = ref( $arg ) || $arg;
	my $self  = $class->SUPER::new();

	bless ($self, $class);

	return $self;
}

sub search {
	my $self = shift or croak "Usage: search E2SEARCH, KEYWORDS [, NODETYPE ] [, MAX_RESULTS ]";
	my $keywords = shift or croak "Usage: search E2SEARCH, KEYWORDS [, NODETYPE ] [, MAX_RESULTS ]";
	my $nodetype = shift || 'e2node';
	my $max_results = shift;

	my @results;

	warn "E2::Search::search\n"	if $DEBUG > 1;

	my %opt = (
		keywords => $keywords,
		nodetype => $nodetype
	);
	
	my $handlers = {
		'searchinfo/keywords' => sub {
			(my $a, my $b) = @_;
			$self->{keywords} = $b->text;
		},
		'searchinfo/search_nodetype' => sub {
			(my $a, my $b) = @_;
			$self->{searchtype} = $b->text;
		},
		'searchresults/e2link' => sub {
			(my $a, my $b) = @_;
			if( !$self->{max_results} || 
			    !$self->{results} || 
			    $self->{max_results} > @results ) {

				push @results, {
					title => $b->text, 
					node_id =>$b->{att}->{node_id}
				};
			}
		}
	};


	$self->{keywords} = undef;
	$self->{searchtype} = undef;
	
	return $self->parse( 'search', $handlers, \@results, %opt );
}

1;
__END__

=head1 NAME

E2::Search - A module for searching for nodes on L<http://everything2.com>

=head1 SYNOPSIS

	use E2::Search;

	my $search = new E2::Search;

	# Fetch 10 results for a keyword search on "William Shatner"

	my @results = $search->search( "William Shatner", 'e2node', 10 );

	foreach my $r ( @results ) {
		print $r->{title};
	}

=head1 DESCRIPTION

This module provides an interface to everything2.com's search interface. It inherits L<E2::Ticker|E2::Ticker>.

=head1 CONSTRUCTOR

=over

=item new [ USERNAME ]

C<new> creates an C<E2::Search> object.

=back

=head1 METHODS

=over

=item $search->search KEYWORDS [, NODETYPE ] [, MAX_RESULTS ]

C<search> performs a title search and returns a list of hashrefs to the titles found (with "title" and "node_id" as keys to each hash). NODETYPE is the type of node intended ("e2node" is default; other possibilities include "user", "group", "room", "document", "superdoc", and possible others). MAX_RESULTS (if set) is the maximum number of results to return.

=back

=head1 SEE ALSO

L<E2::Interface>,
L<E2::Ticker>,
L<E2::UserSearch>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
