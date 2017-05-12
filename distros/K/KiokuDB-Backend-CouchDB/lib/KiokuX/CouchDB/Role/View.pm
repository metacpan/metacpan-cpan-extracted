package KiokuX::CouchDB::Role::View;

use Moose::Role;
use Data::Dmap 'cut', 'dmap';
use Carp 'croak';
use Scalar::Util 'blessed';

use namespace::clean -except => 'meta';

# TODO Merge into KiokuDB::Backend::CouchDB and change to comply with KiokuDB::Backend::Role::Query

# view() is a non-compliant method that can be called directly to query 
# couchdb views and have all KiokuDB objects instantiated when needed
# $name is a name of a CouchDB view that can contain complete KiokuDB
# entries or references (in serialized form, of course).
sub view {
    my($self, $name, $options) = @_;

    # Backend data fix hack
    # The real solution to this ugly way of recovering backend data is to
    # replace the JSPON expander/collapser with a version that doesn't throw
    # away revision numbers.
    my $backend_data;
    my($response) = $self->backend->db->view($name, $options)->recv;
    dmap {
        if(ref eq 'HASH' and exists $_->{_id}) {
            my $id = $_->{_id};
            $backend_data->{$id}               ||= { _id => $id };
            $backend_data->{$id}{_rev}         ||= $_->{_rev};
            $backend_data->{$id}{_attachments} ||= $_->{_attachments};
        }
        return $_;
    } $response;
    # End hack
    
    my($result) = dmap {
        if(ref eq 'HASH') {
            if($_->{key} and $_->{value} and blessed $_->{value}) {
                if($_->{value}->isa('KiokuDB::Entry')) {
                    my $entry = $_->{value};
                    # Patch backend data for later use
                    $entry->backend_data($backend_data->{$entry->id}) if $backend_data->{$entry->id};
                    my $object;
                    if(not $object = $self->live_objects->id_to_object($entry->id)) {
                        $object = $self->linker->expand_object($entry);
                    }
                    cut $object;
                }
            }
        } elsif(blessed $_ and $_->isa('KiokuDB::Reference')) {
            my $object = $self->live_objects->id_to_object($_->id);
            if(not $object) {
                my $ref_obj = $_;
                $_ = ['Unlinked KiokuDB::Reference'];
                $self->linker->queue_ref($ref_obj, \$_);
            } else {
                cut $object;
            }
        } elsif(blessed $_) {
            cut $_;
        }
        $_
    } $self->backend->deserialize($response);
    
    $self->linker->load_queue;

    return $result;
}

1;

__END__

=pod

=head1 NAME

KiokuX::CouchDB::Role::View - query CouchDB views and get back live KiokuDB objects

=head1 SYNOPSIS

    use KiokuX::CouchDB::Role::View;
    my $kioku = KiokuDB->connect( "couchdb:uri=http://127.0.0.1:5984/database" );
    apply_all_roles($kioku, 'KiokuX::CouchDB::Role::View');
    my $scope = $kioku->new_scope;
    my $result = $kioku->view('some/objects');

=head1 DESCRIPTION

This Moose role provides an extra method for a KiokuDB instance that enables
it to query CouchDB views and instantiate replace any KiokuDB specific data
with live objects wherever they are found.

Be warned: using this role will tie you to a non-standard interface that is
only supported by the CouchDB backend for KiokuDB.

=head1 METHODS

=over 4

=item C<view($view, $options)>

The parameters C<$view> and C<$options> are passed straight to the C<view> 
method of the underlying L<AnyEvent::CouchDB> object. If the results contains
KiokuDB entries or references, they are replaced with live objects that has
been registered in the current KiokuDB scope.

=back

=head1 SEE ALSO

L<KiokuDB::Backend::CouchDB>, L<AnyEvent::CouchDB.

=head1 VERSION CONTROL

L<http://github.com/mzedeler/kiokudb-backend-couchdb>

=head1 AUTHOR

Michael Zedeler E<lt>michael@zedeler.dkE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010 Leasingbørsen. All rights reserved. This program
    is free software; you can redistribute it and/or modify it under 
    the same terms as Perl itself.

=cut
