package Etcd::Response;
$Etcd::Response::VERSION = '0.004';
use namespace::autoclean;

use Etcd::Node;

use JSON qw(decode_json);

use Moo;
use Type::Utils qw(class_type);
use Types::Standard qw(Str Int);

has action     => ( is => 'ro', isa => Str, required => 1 );
has etcd_index => ( is => 'ro', isa => Int, required => 1 );
has raft_index => ( is => 'ro', isa => Int, required => 1 );
has raft_term  => ( is => 'ro', isa => Int, required => 1 );

my $node_coercion = sub { ref $_[0] eq 'HASH' ? Etcd::Node->new(%{$_[0]}) : $_[0] };
has node       => ( is => 'ro', isa => class_type('Etcd::Node'), coerce => $node_coercion, required => 1 );
has prev_node  => ( is => 'ro', isa => class_type('Etcd::Node'), coerce => $node_coercion, init_arg => 'prevNode' );

sub new_from_http {
    my ($class, $res) = @_;
    my $data = decode_json($res->{content});
    my %headers;
    @headers{qw(etcd_index raft_index raft_term)} = @{$res->{headers}}{qw(x-etcd-index x-raft-index x-raft-term)};
    $class->new(%$data, %headers);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd::Response - response from key space API

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    my $response = $etcd->get("/message");
    say $response->node->value;

=head1 DESCRIPTION

L<Etcd::Response> objects encapsulate the details of responses from the key
space API.

The provided methods are simple accessors. This class provides no
functionality.

The API docs have more information about the meaning of each item. See
L<Etcd/SEE ALSO> for further reading.

=head1 METHODS

=over 4

=item *

C<action>

=item *

C<etcd_index>

=item *

C<raft_index>

=item *

C<raft_term>

=item *

C<node>

A L<Etcd::Node> object with the node data from this response.

=item *

C<prev_node>

A L<Etcd::Node> object with the previous state of the node data from this response. May be C<undef>.

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
