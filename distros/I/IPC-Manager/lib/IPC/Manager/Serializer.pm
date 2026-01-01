package IPC::Manager::Serializer;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

sub serialize   { croak "Not Implemented" }
sub deserialize { croak "Not Implemented" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Serializer - Serializer base class for IPC::Manager.

=head1 DESCRIPTION

Interface to Serielize and deserialize message payloads.

=head1 SYNOPSIS

    package IPC::Manager::Serializer::MySerializer;

    use parent 'IPC::Manager::Serializer';

    sub serialize   { ... }
    sub deserialize { ... }

    1;

=head1 METHODS

=over 4

=item $string = IPC::Manager::Serializer->serialize($obj)

Serialize an object.

=item $obj = IPC::Manager::Serializer->deserialize($string)

Deserialize an object.

=item

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
