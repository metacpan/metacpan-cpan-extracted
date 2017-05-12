package File::Find::Rule::PPI;

=pod

=head1 NAME

File::Find::Rule::PPI - Add support for PPI queries to File::Find::Rule

=head1 SYNOPSIS

  use File::Find::Rule      ();
  use File::Find::Rule::PPI ();

  # Find all perl modules that use here-docs
  my $Find = File::Find::Rule->file
                             ->name('*.pm')
                             ->ppi_find_any('Token::HereDoc');
  my @heredoc = $Find->in( $dir );

=head1 DESCRIPTION

File::Find::Rule::PPI allows you to integrate PPI content queries
into your L<File::Find::Rule> searches.

Initially, it provides the one additional method C<ppi_find_any>,
which takes an argument identical to the L<PPI::Node> method C<find_any>
and checks each file as a perl document to see if matches the query.

=head1 METHODS

=cut

use 5.005;
use strict;
use Params::Util      0.10 '_INSTANCE';
use File::Find::Rule  0.20 ();
use PPI              1.000 ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'File::Find::Rule';
	@EXPORT  = @File::Find::Rule::EXPORT;

	# Preload PPI::Find module if needed and possible
	eval "use prefork => 'PPI::Find';";
}





#####################################################################
# Add the methods to File::Find::Rule

=pod

=head2 ppi_find_any $condition | $PPI::Find

The C<ppi_find_any> method causes a query identical to (and implemented
using) L<PPI::Node>'s C<find_any> method.

It takes as argument any condition that would also be valid for the above
method.

In addition, it can also take as argument an instantiated L<PPI::Find>
object, and will use that object's C<any_matches> method to achieve the
same effect.

If you provide no or an illegal condition to ppi_find_any, the check will
always fail, and B<no> files will be returned when you execute the search.

=cut

sub File::Find::Rule::ppi_find_any {
	require PPI;
	my $self = shift()->_force_object;

	# Is this a PPI::Find object
	if ( _INSTANCE($_[0], 'PPI::Find') ) {
		require PPI::Find;
		my $Find = shift;
		return $self->exec( sub {
				my $Document = PPI::Document->new($_) or return;
				$Find->any_matches                    or return;
				1;
			} );
	}

	# Normal Document->find_any test
	my $condition = PPI::Node->_wanted(shift);

	# If you want to find crap, you never will
	return $self->discard unless $condition;

	# Add the query for a valid condition
	$self->exec( sub {
			my $Document = PPI::Document->new($_) or return;
			$Document->find_any( $condition )      or return;
			1;
		} );
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-PPI>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

Funding provided by The Perl Foundation

=head1 SEE ALSO

L<http://ali.as/>, L<File::Find::Rule>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
