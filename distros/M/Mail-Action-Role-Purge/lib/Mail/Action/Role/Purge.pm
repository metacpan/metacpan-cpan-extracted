=head1 NAME

Mail::Action::Role::Purge - purge expired objects from Mail::Action::Storage
collections.

=head1 SYNOPSIS

 use Mail::TempAddress::Addresses;
 use Mail::Action::Role::Purge;
 use Class::Roles
    apply => {
        role => 'Purge',
        to   => 'Mail::TempAddress::Addresses',
    };
 my $addrs = Mail::TempAddress::Addresses->new( '/foo' );
 for my $addr( $addrs->object_names ) {
     print "the address for ", $addr->owner, " expires at ",
           scalar localtime($addr->expires), "\n";
     if( $addr->expires < time() ) {
         $addrs->delete_from_storage($addr);
     }
 }

=head1 DESCRIPTION

Mail::Action::Role::Purge provides a role to allow subclasses of
Mail::Action::Storage to retrieve the names of all object in the collection
and remove the file on disk underlying a named object.

=cut

package Mail::Action::Role::Purge;

use strict;
use Carp 'croak';

use Mail::Action::Storage;
use Class::Roles
    multi => {
        'Purge' => [ qw|
            object_names
            num_objects
            delete_from_storage
            purge
        |],
    };
    
use vars '$VERSION';

$VERSION = '0.11';
 
use File::Basename;
use Fcntl ':flock';

sub object_names
{
    
    my $self = shift;
    my $dir = $self->storage_dir;
    my $extension = $self->storage_extension();
    my @files = map {
        scalar( s/\.$extension//, basename $_)
    } glob("$dir/*.$extension");
    return wantarray ? @files : \@files;
    
}

sub num_objects
{
    
    my $self = shift;
    return scalar @{ $self->object_names } || 0;
    
}

sub delete_from_storage
{
    
    my $self = shift;
    my $name = shift;
    my $file = $self->storage_file($name);
    unless( $file ) {
        $! = "no object by that name";
        return undef;
    }
    open( OUT, '+< ' . $file ) or croak "cannot open $file: $!";
    flock OUT, LOCK_EX or croak "cannot lock $file: $!";
    unlink($file) && return 1;
    return undef;
    
}

sub purge
{

    my $self = shift;

    my $min_ts;
    if( my $min_age = shift  ) {
        my $subtract = Mail::Action::Address->process_time( $min_age );
        $min_ts = time() - $subtract;
    }
    else {
        $min_ts = time();
    }

    my $purged = 0;
    for( $self->object_names ) {
        my $addy = $self->fetch($_);
        next unless $addy;
        my $expires = $addy->expires();
        if( $expires && $expires < $min_ts ) {
            $self->delete_from_storage($_) && $purged++;
        }
    }
    
    return $purged;

}

# keep require happy
1;


__END__


=head1 ROLES

=head2 B<Purge>

This role should be applied to a subclass of Mail::Action::Storage. It
allows an object of the class to iterate over all objects in the collection
and remove named object from the collection.

It adds several methods to the class to which it is applied:

=over 4

=item object_names()

This method returns all a list of names of the objects in the collection.
The objects are returned as a list in list context or a list reference in
scalar context.

=item num_objects()

This method returns the number of objects in the collection.  Similar to
using

 scalar @{ $storage->object_names }

But a bit quicker since the names themselves don't have to be passed from
the method back to the caller.

=item delete_from_storage($name)

This method removes the file on disk that represents the named object. A
true value is returned upon success and undef upon error. Inspect $! for
details as to what went wrong.

=item purge($min_age)

This method is a frontend to num_objects() and delete_from_storage(). It
gets the names of all objects in the collection, then in turn fetches each
object and checks if it has expired. If it has, it deletes that object from
the storage.  The method returns the number of purged objects.

By default each object need only be expired. Passing the $min_expired_age
requires that the object have been expired for at least that many seconds.
The minimum age may also be passed using a freeform expression like '1h30m'
or '2m1w'. See L<Mail::Action::Address/"address_expires"> for more details.

For example, if an address object is set to expire at C<Mon Oct 27 19:31:39
2003> and the purge() routine is run at C<19:33> with an argument of C<300>,
then the data file for the object will not be deleted. If the purge method
were to be called at C<19:36:40> or any time thereafter then the data file
will be deleted.

=back

=head1 BACKGROUND

This module began life as Mail::TempAddress::Addresses::Purgeable, which was
a simple subclass of Mail::TempAddress::Addresses designed to add purging
functionality.  At the time I wasn't aware of Mail::SimpleList.  

After a few mails back and forth with chromatic, the topic of refactoring
the common parts of Mail::TempAddress::Addresses and Mail::SimpleList came
up, at which point the functionality provided by the original module made
more sense to implement as a mixin.

About a week later chromatic re-factored those common parts out into
Mail::Action. A couple of weeks after that he re-factored the common parts
out into roles using his new Class::Roles module and suggested that I
implement my module as a role rather than a mixin.

=head1 ACKNOWLEDGEMENTS

chromatic for providing tons of feedback and for developing Mail::Action and
Class::Roles.

=head1 AUTHOR

James FitzGibbon E<lt>jfitz@CPAN.ORGE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  All rights reserved.  This module
is distributed under the same terms as Perl itself.

=cut

#
# EOF

