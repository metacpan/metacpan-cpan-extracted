package Mail::SimpleList::Aliases;

use strict;
use base 'Mail::Action::Storage';

use File::Spec;

use Mail::SimpleList::Alias;

use vars qw( $VERSION );
$VERSION = '0.94';

sub new
{
    my ($class, $directory) = @_;
    $directory ||= File::Spec->catdir( $ENV{HOME}, '.aliases' );

    $class->SUPER::new( $directory );
}

sub stored_class
{
    'Mail::SimpleList::Alias';
}

sub storage_extension
{
    'sml'
}

sub create
{
    my ($self, $owner) = @_;

    return Mail::SimpleList::Alias->new(
        owner   => $owner,
        members => [$owner],
    );
}

1;

__END__

=head1 NAME

Mail::SimpleList::Aliases - manages Mail::SimpleList::Alias objects

=head1 SYNOPSIS

    use Mail::SimpleList::Aliases;
    my $aliases = Mail::SimpleList::Aliases->new( '.aliases' );

=head1 DESCRIPTION

Mail::SimpleList::Aliases manages the creation, loading, and saving of
Mail::SimpleList::Alias objects.  If you'd like to change how these objects are
managed on your system, subclass or reimplement this module.

=head1 METHODS

=over 4

=item * new( [ $alias_directory ] )

Creates a new Mail::SimpleList::Aliases object.  The single argument is
optional but highly recommended.  It should be the path to where Alias data
files are stored.  Beware that in filter mode, relative paths can be terribly
ambiguous.

If no argument is provided, this will default to C<~/.aliases> for the invoking
user.

=item * storage_dir()

Returns the directory where this object's Alias data files are stored.

=item * exists( $alias_name )

Returns true or false if an alias with this name exists.

=item * fetch( $alias_name )

Creates and returns a Mail::SimpleList::Alias object represented by this alias
name.  This can return nothing if the alias does not exist.

=item * create( $owner )

Creates and returns a new Mail::SimpleList::Alias object, setting the owner.
Note that you will need to C<save()> the object yourself, if that's important
to you.

=item * save( $alias, $alias_name )

Saves a Mail::SimpleList::Alias object provided as C<$alias> with the given
name in C<$alias_name>.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>, with helpful suggestions from friends, family,
and peers.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 SEE ALSO

L<Mail::Action::Storage>, the parent class.

=head1 COPYRIGHT

Copyright (c) 2016, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself.  Convenient for you!
