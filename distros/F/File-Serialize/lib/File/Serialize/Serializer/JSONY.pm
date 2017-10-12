package File::Serialize::Serializer::JSONY;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: JSONY serializer for File::Serialize
$File::Serialize::Serializer::JSONY::VERSION = '1.2.0';
use strict;
use warnings;

use File::Serialize;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ jsony / };

sub serialize {
    my( $self, $data, $options ) = @_;
    serialize_file \my $output, $data, { format => 'json' };
    return $output;
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    JSONY->new->load($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::JSONY - JSONY serializer for File::Serialize

=head1 VERSION

version 1.2.0

=head1 DESCRIPTION

Serializer for L<JSONY>.

Registered against the extension C<jsony>.

This serializer actually only deserializes. Its serialization
is taken care of by any available JSON serializer.

=over

=item B<extensions>

C<jsony>

=item B<precedence>

100

=item B<module used>

L<JSONY>

=item B<supported options>

deserializer: none

serializer: depends on the JSON serializer used.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
