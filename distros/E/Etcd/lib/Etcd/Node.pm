package Etcd::Node;
$Etcd::Node::VERSION = '0.004';
use namespace::autoclean;

use Moo;
use Type::Tiny;
use Types::Standard qw(Int Str Bool ArrayRef);
use Type::Utils qw(class_type);

# http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
my $ISO8601 = do {
    my $iso8601_re = qr{^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$};
    Type::Tiny->new(
        name       => "ISO8601",
        constraint => sub { m/$iso8601_re/ },
        inlined    => sub { "$_[1] =~ m/$iso8601_re/" },
    );
};

has key            => ( is => 'ro', isa => Str, required => 1 );
has value          => ( is => 'ro', isa => Str );
has created_index  => ( is => 'ro', isa => Int, init_arg => 'createdIndex'  );
has modified_index => ( is => 'ro', isa => Int, init_arg => 'modifiedIndex' );
has ttl            => ( is => 'ro', isa => Int );
has expiration     => ( is => 'ro', isa => $ISO8601 );
has dir            => ( is => 'ro', isa => Bool, coerce => sub { !! $_[0] } );

has nodes => (
    is => 'ro',
    isa => ArrayRef[class_type('Etcd::Node')],
    coerce => sub { ref $_[0] eq "ARRAY" ? [ map { Etcd::Node->new(%$_) } @{$_[0]} ] : $_[0] }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd::Node - key space node representation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    my $node = $etcd->get("/message")->node;

=head1 DESCRIPTION

L<Etcd::Node> objects encapsulate the details of nodes in the key space API.

The provided methods are simple accessors. This class provides no
functionality.

The API docs have more information about the meaning of each item. See
L<Etcd/SEE ALSO> for further reading.

=head1 METHODS

=over 4

=item *

C<key>

=item *

C<value>

Value of this key. Can be C<undef> (usually in directory nodes).

=item *

C<created_index>

=item *

C<modified_index>

=item *

C<ttl>

=item *

C<expiration>

ISO-8601 string indicating the moment that this node will be deleted.

=item *

C<dir>

True if the node is a directory. C<value> will undef in this case.

=item *

C<nodes>

Arrayref of zero or more sub-nodes. Only returned from appropriate
L<Etcd::Keys> calls with the C<recursive> parameter set to C<true>.

=back

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
