package Eve::Json;

use parent qw(Eve::Class);

use strict;
use warnings;

use JSON::XS;

use Eve::Exception;

=head1 NAME

B<Eve::Json> - a JSON converter adapter.

=head1 SYNOPSIS

    use Eve::Json;

    my $json = Eve::Json->new();

    my $json_string = $json->encode(reference => $reference);
    my $decoded_reference = $json->decode(string => $json_string);

=head1 DESCRIPTION

The B<Eve::Json> class adapts the functionality of the JSON::XS
module to provide JSON encoding and decoding features service.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my $self = shift;

    $self->{'json'} = JSON::XS->new()->pretty(1);

    $self->json->utf8();
}

=head2 B<encode()>

Encodes a reference and returns its JSON string representation.

=head3 Arguments

=over 4

=item C<reference>

=back

=cut

sub encode {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $reference);

    my $result;
    eval {
        $result = $self->{'json'}->encode($reference);
    };

    my $e;
    if ($e = Eve::Exception::Die->caught()) {
        Eve::Error::Value->throw(message => $e->message);
    } elsif ($e = Exception::Class::Base->caught()) {
        $e->rethrow();
    }

    return $result;
}

=head2 B<decode()>

Decodes a JSON string and returns a reference to its decoded contents.

=head3 Arguments

=over 4

=item C<string>

=back

=cut

sub decode {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $string);

    my $result;
    eval {
        $result = $self->{'json'}->decode($string);
    };

    my $e;
    if ($e = Eve::Exception::Die->caught()) {
        Eve::Error::Value->throw(message => $e->message);
    } elsif ($e = Exception::Class::Base->caught()) {
        $e->rethrow();
    }

    return $result;
}

=head1 SEE ALSO

=over 4

=item C<JSON::XS>

=item C<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
