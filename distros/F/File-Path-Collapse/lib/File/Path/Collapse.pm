
package File::Path::Collapse ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(CollapsePath) ],
	groups  => 
		{
		all  => [ qw(CollapsePath) ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.03';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;
Readonly my $UNIX_SEPARATOR => q{/} ;
Readonly my $DOT => q{.} ;
Readonly my $DOT_DOT => q{..} ;
Readonly my $ARRAY_LAST_ENTRY => -1 ;

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

File::Path::Collapse - Collapses a path as much as possible

=head1 SYNOPSIS


=head1 DESCRIPTION

This module implements ...

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub CollapsePath
{

=head2 CollapsePath($path_to_collapse )

Collapses the path by removing '.' and '..' from it. Trailing '/' is also removed.

I<Arguments>

=over 2 

=item * $path_to_collapse - 

=back

I<Returns> - the collapsed path or undef if undef was passed as argument.

=cut

my ($path_to_collapse, $path_separator) = @_ ;

return unless defined $path_to_collapse ;

$path_separator = $UNIX_SEPARATOR unless defined $path_separator ;

my $from_root = substr($path_to_collapse, 0, 1) eq $path_separator ? $path_separator : $EMPTY_STRING ;

my @uncollapsed_components = split(/\Q$path_separator/sxm, $path_to_collapse) ;
my @collapsed_components ;

for my $component(@uncollapsed_components)
	{
	if
		(
		$component eq $DOT_DOT
		&& @collapsed_components 
		&& $collapsed_components[$ARRAY_LAST_ENTRY] ne $DOT_DOT
		)
		{
		pop @collapsed_components ;
		}
	elsif($component eq $DOT || $component eq $EMPTY_STRING )
		{
		}
	else
		{
		push @collapsed_components, $component ;
		}
	}

my $collapsed_path = $from_root . join($path_separator, @collapsed_components) ;

return($collapsed_path, \@uncollapsed_components, \@collapsed_components) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Path::Collapse

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Path-Collapse>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-file-path-collapse@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/File-Path-Collapse>

=back

=head1 SEE ALSO


=cut
