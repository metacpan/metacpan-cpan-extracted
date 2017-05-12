package KiokuDB::Backend::MongoDB;
BEGIN {
  $KiokuDB::Backend::MongoDB::VERSION = '0.03';
}
use Moose;

use namespace::clean -except => 'meta';

with qw(
         KiokuDB::Backend
         KiokuDB::Backend::Serialize::JSPON
         KiokuDB::Backend::Role::Clear
         KiokuDB::Backend::Role::Scan
         KiokuDB::Backend::Role::Query::Simple
         KiokuDB::Backend::Role::Query
);

use MongoDB::Connection; # In case we are expected to create the connection
use Data::Stream::Bulk::Callback ();

has [qw/database_name database_host database_port collection_name/] => (
    is  => 'ro',
    isa => 'Str',
);

has collection => (
    isa => 'MongoDB::Collection',
    is  => 'ro',
    lazy => 1,
    builder => '_build_collection',
);

has '+id_field'    => ( default => "_id" );
has '+class_field' => ( default => "class" );
has '+class_meta_field' => ( default => "class_meta" );

sub _build_collection {
    my ($self) = @_;
    my $host = $self->database_host || 'localhost';
    my $port = $self->database_port || 27017;
    die "collection_name required" unless $self->collection_name;
    my $conn = MongoDB::Connection->new(host => $host, port => $port);
    return $conn->get_database($self->database_name)->get_collection($self->collection_name);
}

sub BUILD {
    my ($self) = @_;
    $self->collection;
}

sub clear {
    my $self = shift;
    $self->collection->drop;
}

sub all_entries {
    my $self = shift;
    return $self->_proto_search({});
}

sub insert {
    my ($self, @entries) = @_;

    my $coll = $self->collection;

    for my $entry (@entries) {
        my $collapsed = $self->serialize($entry); 
        if ($entry->prev) {
            $coll->update({ _id => $collapsed->{_id} }, $collapsed);
            my $err = $coll->_database->run_command({getlasterror => 1});
            die $err->{err} if $err->{err};
        }
        else {
            $coll->insert($collapsed);
            my $err = $coll->_database->run_command({getlasterror => 1});
            die $err->{err} if $err->{err};
        }
    }
    return;
}

sub get {
    my ($self, @ids) = @_;
    return map {
        $self->get_entry($_)
    } @ids;
}

sub get_entry {
    my ($self, $id) = @_;
    my $obj = eval { $self->collection->find_one({ _id => $id }); };
    return undef unless $obj;
    return $self->deserialize($obj);
}

sub delete {
    my ($self, @ids_or_entries) = @_;
    for my $id (map { $_->isa('KiokuDB::Entry') ? $_->id : $_ } @ids_or_entries)
    {
        $self->collection->remove({_id => $id});
    }
    return;
}

sub exists {
    my ($self, @ids) = @_;
    my $coll = $self->collection;
    return map { $coll->find_one({ _id => $_ }) } @ids;
    # $self->get(@ids);
}

sub simple_search {
    my ($self, $proto) = @_;
    return $self->search($proto);
}

sub search {
    my ($self, $proto, $args) = @_;

    for my $key (keys %$proto) {
        next if $key =~ m/^data\./;
		next if $key eq 'class';
        my $value = delete $proto->{$key};
        $proto->{"data.$key"} = $value;
    }

    return $self->_proto_search($proto, $args);
}

sub _proto_search {
    my ($self, $proto, $args) = @_;
    my $cursor = $self->collection->query($proto, $args);
    return Data::Stream::Bulk::Callback->new(
        callback => sub {
            if (my $obj = $cursor->next) {
				$obj->{_id} = $obj->{_id}->to_string if (ref $obj->{_id} eq 'MongoDB::OID');
                return [$self->deserialize($obj)];
            }
            return;
        }
    );
}


sub serialize {
    my $self = shift;
    return $self->collapse_jspon(@_);
}

sub deserialize {
    my ( $self, $doc, @args ) = @_;
    $self->expand_jspon( $doc, @args );
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

KiokuDB::Backend::MongoDB - MongoDB backend for KiokuDB

=head1 SYNOPSIS

    use KiokuDB::Backend::MongoDB;

    my $conn = MongoDB::Connection->new(host => 'localhost');
    my $mongodb    = $conn->get_database('somedb');
    my $collection = $mongodb->get_collection('kiokutest');
    my $mongo = KiokuDB::Backend::MongoDB->new('collection' => $collection);

    my $d = KiokuDB->new(
        backend => $mongo 
    );

    my $s = $d->new_scope;
    my $uuid = $d->store($some_object);
    ...


=head1 DESCRIPTION

This KiokuDB backend implements the C<Clear>, C<Scan> and the C<Query::Simple>
roles.

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kiokudb-backend-mongodb at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KiokuDB-Backend-MongoDB>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc KiokuDB::Backend::MongoDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=KiokuDB-Backend-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/KiokuDB-Backend-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/KiokuDB-Backend-MongoDB/>

=back


=head1 ACKNOWLEDGEMENTS

Yuval Kogman (KiokuDB::Backend::CouchDB) and Florian Ragwitz (MongoDB).

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Ask Bjørn Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
