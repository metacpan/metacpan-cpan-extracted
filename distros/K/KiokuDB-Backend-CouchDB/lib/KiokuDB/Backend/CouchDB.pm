#!/usr/bin/perl

package KiokuDB::Backend::CouchDB;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Stream::Bulk::Util qw(bulk);

use AnyEvent::CouchDB;
use Carp 'confess';
use Try::Tiny;
use List::MoreUtils qw{ any };
use Time::HiRes qw/gettimeofday tv_interval/;

use KiokuDB::Backend::CouchDB::Exceptions;

use namespace::clean -except => 'meta';

our $VERSION = '0.16';

# TODO Read revision numbers into rev field and use for later conflict resolution

with qw(
    KiokuDB::Backend
    KiokuDB::Backend::Serialize::JSPON
    KiokuDB::Backend::Role::UnicodeSafe
    KiokuDB::Backend::Role::Clear
    KiokuDB::Backend::Role::Scan
    KiokuDB::Backend::Role::Query::Simple::Linear
    KiokuDB::Backend::Role::TXN::Memory
    KiokuDB::Backend::Role::Concurrency::POSIX
);

# TODO Remove TXN::Memory or ensure that it works as it should

has create => (
    isa => "Bool",
    is  => "ro",
    default => 0,
);

has conflicts => (
    is      => 'rw',
    isa     => enum([qw{ overwrite confess ignore throw }]),
    default => 'throw'
);
    

sub BUILD {
    my $self = shift;

    if ( $self->create ) {
        my $e = do {local $@; eval { $self->db->create->recv }; $@ };

        # Throw errors except if its because the database already exists
        if ( $e ) {
            if ( my($error) = grep { exists $_->{error} } @$e ) {
                if( $error->{error} ne 'file_exists' ) {
                    die "$error->{error}: $error->{reason}";
                }
            }
        }
    }
}

has db => (
    isa => "AnyEvent::CouchDB::Database",
    is  => "ro",
    handles => [qw(document)],
);

has '+id_field'    => ( default => "_id" );
has '+class_field' => ( default => "class" );
has '+class_meta_field' => ( default => "class_meta" );
has '+deleted_field' => ( default => "_deleted" );

our @couch_meta_fields = qw{ _rev _attachments _conflicts };


sub delete {
    my ( $self, @ids_or_entries ) = @_;
    
    my $db = $self->db;
    
    warn "Remove: ", join(', ', @ids_or_entries);
    
    for(@ids_or_entries) {
        if(blessed($_)) {
            my $meta = $self->find_meta($_);
            $db->remove_doc({
                _id  => $_->id,
                ($meta->{_rev} ? (_rev => $meta->{_rev}) : ())
            });
        } else {
            $db->remove_doc({_id => $_});
        }
    }
    
    return;
}

sub new_from_dsn_params {
    my ( $self, %args ) = @_;

    my $db = exists $args{db}
        ? couch($args{uri})->db($args{db})
        : couchdb($args{uri});
        
    $self->new(%args, db => $db);
}

# Collect metadata for a given entry
sub find_meta {
    my ( $self, $entry ) = @_;
    my $meta;

    my $prev = $entry;
    # Go backwards in history to collect metadata
    # TODO Consider whether this should be necessary - why not store this in every entry?
    while($prev and any {not exists $meta->{$_}} @couch_meta_fields) {
        if(my $backend_data = $prev->backend_data) {
            for(@couch_meta_fields) {
                $meta->{$_} = $backend_data->{$_}
                    if $backend_data->{$_} and not exists $meta->{$_};
            }
        }
        $prev = $prev->prev;
    }
    
    return $meta;
}

sub commit_entries {
    my ( $self, @entries ) = @_;
    
    my @docs;
    my $db = $self->db;
    
    my $start = [ gettimeofday ];

    foreach my $entry ( @entries ) {
        
        my $meta = $self->find_meta($entry);
        
        my $collapsed = $self->collapse_jspon($entry); 

        for(@couch_meta_fields) {
            $collapsed->{$_} = $meta->{$_}
                if $meta->{$_}
        }
        
        push @docs, $collapsed;

        $entry->backend_data($collapsed);

    }

    # TODO couchdb <= 0.8 (possibly 0.9 too) will return a hash ref here, which will fail. Detect and handle.
    my $data = $self->db->bulk_docs(\@docs)->recv;

    if ( my @errors = grep { exists $_->{error} } @$data ) {

        if($self->conflicts eq 'confess') {
            no warnings 'uninitialized';
            confess "Errors in update: " . join(", ", map { "$_->{error} (on ID $_->{id} ($_->{rev}, $_->{error}, $_->{reason}))" } @errors);
        } elsif($self->conflicts eq 'overwrite' or $self->conflicts eq 'throw') {
            my %conflicts;
            my @conflicts;
            my @other_errors;
            for(@errors) {
                if($_->{error} eq 'conflict') {
                    push @conflicts, $_->{id};
                } else {
                    push @other_errors, $_;
                }
            }
            if(@other_errors) {
                confess "Errors in update: " . join(", ", map { "$_->{error} (on ID $_->{id} ($_->{rev}))" } @other_errors);
            }
            
            # Updating resulted in conflicts that we handle by overwriting the change
            my $old_docs = $db->open_docs([@conflicts], {conflicts => 'true'})->recv;
            if(exists $old_docs->{error}) {
                confess "Updating ids ", join(', ', @conflicts), " failed during conflict resolution: $old_docs->{error}.";
            }
            my @old_docs = @{$old_docs->{rows}};

            if($self->conflicts eq 'overwrite') {
                my @re_update_docs;
                foreach my $old_doc (@old_docs) {
                    my($new_doc) = grep {$old_doc->{doc}{_id} eq $_->{_id}} @docs;
                    $new_doc->{_rev} = $old_doc->{doc}{_rev};
                    push @re_update_docs, $new_doc;
                }
                # Handle errors that has arised when trying the second update
                if(@errors = grep { exists $_->{error} } @{$self->db->bulk_docs(\@re_update_docs)->recv}) {
                    confess "Updating ids ", join(', ', @conflicts), " failed during conflict resolution: ",
                        join(', ', map { $_->{error} . ' on ' . $_->{id} } @errors);
                }
            } else { # throw
                my $conflicts = [];
                my %docs;
                for(@docs) {
                    $docs{$_->{_id}} = $_;
                }
                for(my $i=0; $i < @conflicts; $i++) {
                    push @$conflicts, {
                        new => $docs{$conflicts[$i]}->{data},
                        old => $old_docs[$i]->{doc}{data}
                    };
                }
                KiokuDB::Backend::CouchDB::Exception::Conflicts->throw(
                    conflicts => $conflicts,
                    error     => 'Conflict while storing objects'
                );
            }
        }
        # $self->conflicts eq 'ignore' here, so don't do anything
    }

    foreach my $rev ( map { $_->{rev} } @$data ) {
        ( shift @docs )->{_rev} = $rev;
    }

    if ($ENV{KIOKU_COUCH_TRACE}){
        my $end = [ gettimeofday ];
        warn "[KIOKU COUCH TRACE] KiokuDB::Backend::CouchDB::commit_entries() [", tv_interval($start, $end),"s]:\n";
        warn "[KIOKU COUCH TRACE]   ".$_->id.', ['.($_->class || '')."]\n" for @entries;
    }
}

sub get_from_storage {
    my ( $self, @ids ) = @_;

    my @result;

    my $error_count = 0;
    my $max_errors = 2;
    my $retry_delay = 5;
    my $data;
    my $error;
    my $start = [ gettimeofday ];
    while(not $data and $error_count <= $max_errors) {
        $error = undef;
        try   { $data = $self->db->open_docs(\@ids)->recv }
        catch { $error_count++; $error = $_ };
        
        # Always retry immediately after first failed connect, then apply delay
        sleep $retry_delay if $error_count > 1;
        
    	if(not $error and not $data) {
    	    die "Call to CouchDB returned false ($data)";
    	}
    }
    die $error->[0]{Reason} if ref $error eq 'ARRAY' and ref $error->[0] eq 'HASH' and $error->[0]{Reason};
    die $error if $error;

    die('Invalid response from CouchDB (rows missing or not array)', $data)
        unless $data->{rows} and ref $data->{rows} eq 'ARRAY';

    my @deleted;
    my @not_found;
    my @unknown;
    my @errors;
    my @docs;
    for(@{ $data->{rows} }) {
        if($_->{doc} ) {
            # TODO We may have to check if $_->{doc} has a valid value and treat as error otherwise
            push @docs, $_->{doc};
        } elsif($_->{value}{deleted}) {
            push @deleted, $_;
        } elsif(my $error = $_->{error}) {
            if($error eq 'not_found') {
                push @not_found, $_;
            } else {
                push @errors, $_;
            }
        } else {
            push @unknown, $_; 
        }
    }
    if(@errors) {
        use Data::Dump 'pp';
        die 'Error on fetch from CouchDB.', pp @errors;
    }
    if(@unknown) {
        use Data::Dump 'pp';
        die 'Unknown response from CouchDB.', pp @unknown;
    }

    # TODO What to do with deleted entries?
    # TODO What to do with entries not found?
    
    if ($ENV{KIOKU_COUCH_TRACE}){
        my $end = [ gettimeofday ];
        warn "[KIOKU COUCH TRACE] KiokuDB::Backend::CouchDB::get_from_storage() [", tv_interval($start, $end),"s]:\n";
        warn "[KIOKU COUCH TRACE]   ".$_->{_id}.', ['.($_->{class} || '')."]\n" for @docs;
        warn "[KIOKU COUCH TRACE]   (not found) ".$_->{key}."\n" for @not_found;
    }
    
    return map { $self->deserialize($_) } @docs;
}

sub deserialize {
    my ( $self, $doc ) = @_;

    my %doc = %{ $doc };

    return $self->expand_jspon(\%doc, backend_data => $doc );
}

sub clear {
    my $self = shift;

    # FIXME TXN

    $self->db->drop->recv;
    $self->db->create->recv;
}

sub all_entries {
    my ( $self, %args ) = @_;

    # FIXME pagination
    my @ids = map { $_->{id} } @{ $self->db->all_docs->recv->{rows} };

    if ( my $l = $args{live_objects} ) {
        my %entries;
        @entries{@ids} = $l->ids_to_entries(@ids);

        my @missing = grep { not $entries{$_} } @ids;

        @entries{@missing} = $self->get(@missing);

        return bulk(values %entries);
    } else {
        return bulk($self->get(@ids));
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

KiokuDB::Backend::CouchDB - CouchDB backend for L<KiokuDB>

=head1 SYNOPSIS

    KiokuDB->connect( "couchdb:uri=http://127.0.0.1:5984/database" );

=head1 DESCRIPTION

This backend provides L<KiokuDB> support for CouchDB using L<AnyEvent::CouchDB>.

=head1 DEBUGGING

Set the environment variable KIOKU_COUCH_TRACE if you want debug output
describing what CouchDB bound requests are being processed.

=head1 TRANSACTION SUPPORT

This backend does not currently support transactions.

=head1 ATTRIBUTES

=over 4

=item db

An L<AnyEvent::CouchDB::Database> instance.

Required.

=item create

Whether or not to try and create the database on instantiaton.

Defaults to false.

=back

=head1 SEE ALSO

L<KiokuX::CouchDB::Role::View>.

=head1 VERSION CONTROL

L<http://github.com/mzedeler/kiokudb-backend-couchdb>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 CONTRIBUTORS

Michael Zedeler E<lt>michael@zedeler.dk<gt>, Anders Bruun Borch E<lt>cyborch@deck.dk<gt>,
Martin Parm E<lt>parmus@parmus.dk<gt>.

=head1 COPYRIGHT

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

    Copyright (c) 2010 Leasingbørsen. All rights reserved. This program
    is free software; you can redistribute it and/or modify it under 
    the same terms as Perl itself.

=cut
