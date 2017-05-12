package Mail::Action::Storage;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '0.46';

use YAML;

use Carp 'croak';
use Fcntl ':flock';

use File::Spec;

use Mail::Action::Address;

sub new
{
    my ($class, $directory) = @_;
    croak 'No storage directory given' unless $directory;

    bless { storage_dir => $directory }, $class;
}

sub stored_class
{
    '';
}

sub storage_dir
{
    my $self = shift;
    return $self->{storage_dir};
}

sub storage_extension
{
    'mas'
}

sub storage_file
{
    my ($self, $name) = @_;
    return File::Spec->catfile( $self->storage_dir(),
                                $name . '.' . $self->storage_extension() );
}

sub create
{
}

sub exists
{
    my ($self, $address) = @_;
    return -e $self->storage_file( $address );
}

sub save
{
    my ($self, $stored, $name) = @_;
    my $file = $self->storage_file( $name );
    delete $stored->{name};

    local *OUT;

    if (-e $file)
    {
        open( OUT, '+< ' . $file ) or croak "Cannot save data for '$file': $!";
        flock    OUT, LOCK_EX;
        seek     OUT, 0, 0;
        truncate OUT, 0;
    }
    else
    {
        open( OUT, '> ' . $file ) or croak "Cannot save data for '$file': $!";
    }

    print OUT Dump { %$stored };
}

sub fetch
{
    my ($self, $name) = @_;

    local *IN;
    open(  IN, $self->storage_file( $name ) ) or return;
    flock( IN, LOCK_SH );
    my $data = do { local $/; <IN> };
    close IN;

    return $self->stored_class->new(
        %{ Load( $data ) }, name => $name
    );
}

1;

__END__

=head1 NAME

Mail::Action::Storage - manages storage for Mail::Action and descendants

=head1 SYNOPSIS

    use base 'Mail::Action::Storage';

=head1 DESCRIPTION

Mail::Action::Storage is a parent class for Mail::Action users that need to
store data between invocations.  You B<must> subclass this module for your own
needs.  See L<Mail::SimpleList::Aliases> or L<Mail::TempAddress::Addresses> for
more ideas.

=head1 METHODS

=over 4

=item * new( [ $storage_dir ] )

Creates a new Mail::Action::Storage object.  The single argument is required;
without it, this will throw an exception. C<$storage_dir> should be a directory
where to store data files.  Beware that in filter mode, relative paths can be
terribly ambiguous.

=item * stored_class()

Returns the name of the class for which this class stores data.  For example,
L<Mail::TempAddress::Addresses> returns C<Mail::TempAddress::Address> here.

You B<must> override this, as this returns a blank string.  It may throw an
exception in the future, just to make sure.

=item * storage_dir()

Returns the storage directory set in the constructor.

=item * storage_extension()

Returns the extension of the generated address files.  By default, this is
C<mas>.  Note that the leading period is not part of the extension.  You'll
want to override this.

=item * storage_file( $name )

Given the name of a file (but not a filename), returns the path and full name
of the file as it will be saved on disk.  This is an internal method and you
probably don't need to override it unless you're doing something quite wacky.

=item * create()

Creates a new object of the class you're storing.  This is an empty method.
You B<must> override this in your subclass.

=item * exists( $name )

Returns whether a stored object of the given name exists.

=item * save( $object, $name )

Saves a stored object provided as C<$object> with the name given in C<$name>.

=item * fetch( $name )

Creates and returns a stored object represented by the given name.  This will
return nothing if the object does not exist.  

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>, with helpful suggestions from friends, family,
and peers.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 SEE ALSO

L<Mail::SimpleList::Addresses>, L<Mail::TempAddress::Addresses>, and James
FitzGibbon's L<Mail::TempAddress::Addresses::Purgeable> for examples of
subclassing and extending this class.

=head1 COPYRIGHT

Copyright (c) 2003 - 2009 chromatic.  Some rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.10 itself.
