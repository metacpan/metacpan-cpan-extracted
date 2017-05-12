
package Directory::Scratch::Structured ;

use strict;
use warnings ;

BEGIN 
{
use Sub::Exporter -setup => { exports => [ qw(create_structured_tree), piggyback_directory_scratch => \&piggyback ] } ;
use Sub::Install ;

use vars qw ($VERSION);
$VERSION  = '0.04';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;
Readonly my $ROOT_DIRECTORY => q{.} ;

use Carp qw(carp croak confess) ;

use Directory::Scratch ;

#-------------------------------------------------------------------------------

=head1 NAME

 Directory::Scratch::Structured - creates temporary files and directories from a structured description

=head1 SYNOPSIS

  my %tree_structure =
		(
		dir_1 =>
			{
			subdir_1 =>{},
			file_1 =>[],
			file_a => [],
			},
		dir_2 =>
			{
			subdir_2 =>
				{
				file_22 =>[],
				file_2a =>[],
				},
			file_2 =>[],
			file_a =>['12345'],
			file_b =>[],
			},
			
		file_0 => [] ,
		) ;
		
  use Directory::Scratch::Structured qw(create_structured_tree) ;
  my $temporary_directory = create_structured_tree(%tree_structure) ;
  
  or 
  
  use Directory::Scratch ;
  use Directory::Scratch::Structured  qw(piggyback_directory_scratch) ;
 
  my $temporary_directory = Directory::Scratch->new;
  $temporary_directory->create_structured_tree(%tree_structure) ;


=head1 DESCRIPTION

This module adds a I<create_structured_tree> subroutine to the L<Directory::Scratch>.

=head1 DOCUMENTATION

I needed a subroutine to create a bunch of temporary directories and files while running tests. I used the excellent 
L<Directory::Scratch> to implement  such a functionality. I proposed the subroutine to the L<Directory::Scratch> author
but he preferred to implement a subroutine using an unstructured input data based on the fact that L<Directory::Scratch>
didn't use structured data. This is, IMHO, flawed design, though it may require slightly less typing.

I proposed a hybrid solution to reduce the amount of subroutines and integrate the subroutine using structured input into
L<Directory::Scratch> but we didn't reach an agreement on the API. Instead I decided that I would piggyback on L<Directory::Scratch>.

You can access I<create_structured_tree> through a subroutine or a method through a L<Directory::Scratch> object.

Whichever interface you choose, the argument to the I<create_structured_tree> consists of tuples (hash entries). The key represents
the name of the object to create in the directory.

If the value is of type:

=over 2 

=item ARRAY

A file will be created, it's contents are  the contents of the array (See L<Directory::Scratch>)

=item HASH

A directory will be created. the element of the hash will also be , recursively, created

=item OTHER

The subroutine will croak.

=back

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

sub create_structured_tree
{

=head2 create_structured_tree

  use Directory::Scratch::Structured qw(create_structured_tree) ;
  
  my $temporary_directory = create_structured_tree(%tree_structure) ;
  my $base = $temporary_directory->base() ;

Returns a default L<Directory::Scratch> object.

=cut

my (%directory_entries) = @_ ;

my $temporary_directory = new Directory::Scratch() ;

_create_structured_tree($temporary_directory, \%directory_entries, $ROOT_DIRECTORY) ;

return($temporary_directory ) ;
}

#-------------------------------------------------------------------------------

sub directory_scratch_create_structured_tree
{

=head2 directory_scratch_create_structured_tree

Adds I<create_structured_tree> to  L<Directory::Scratch> when you Load B<Directory::Scratch::Structured> 
with the B<piggyback_directory_scratch> option.

  use Directory::Scratch ;
  use Directory::Scratch::Structured qw(piggyback_directory_scratch) ;
 
  my $temporary_directory = Directory::Scratch->new;
  $temporary_directory->create_structured_tree(%tree_structure) ;

=cut

my ($temporary_directory, @directory_entries) = @_ ;

Directory::Scratch::Structured::_create_structured_tree($temporary_directory, {@directory_entries}, $ROOT_DIRECTORY) ; ## no critic

return($temporary_directory) ;
}

#-------------------------------------------------------------------------------

sub _create_structured_tree
{

=head2 _create_structured_tree

Used internally by both interfaces

=cut

my ($temporary_directory, $directory, $path) = @_ ;

while( my ($entry_name, $contents) = each %{$directory})
	{
	for($contents)
		{
		'ARRAY' eq ref $_ and do
			{
			my $file = $temporary_directory->touch("$path/$entry_name", @{$contents}) ;
			last ;
			} ;
			
		'HASH' eq ref $_ and do
			{
			$temporary_directory->mkdir("$path/$entry_name");
			_create_structured_tree($temporary_directory, $contents, "$path/$entry_name") ;
			last ;
			} ;
			
		croak "invalid element '$path/$entry_name' in tree structure\n" ;
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub piggyback
{

=head2 piggyback

Used internally to piggyback L<Directory::Scratch>.

=cut

Sub::Install::install_sub({
   code => \&directory_scratch_create_structured_tree,
   into => 'Directory::Scratch',
   as   => 'create_structured_tree',
  });

return('Directory::Scratch::create_structured_tree') ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Directory::Scratch::Structured

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Directory-Scratch-Structured>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-directory-scratch-structured@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Directory-Scratch-Structured>

=back

=head1 SEE ALSO

L<Directory::Scratch>

=cut
