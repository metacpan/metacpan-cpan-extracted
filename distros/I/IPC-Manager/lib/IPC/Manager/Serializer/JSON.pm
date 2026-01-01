package IPC::Manager::Serializer::JSON;
use strict;
use warnings;

our $VERSION = '0.000001';

use parent 'IPC::Manager::Serializer';

BEGIN {
    local $@;
    my $class;
    $class //= eval { require Cpanel::JSON::XS; 'Cpanel::JSON::XS' };
    $class //= eval { require JSON::XS;         'JSON::XS' };
    $class //= eval { require JSON::PP;         'JSON::PP' };

    die "Could not find 'Cpanel::JSON::XS', 'JSON::XS', or 'JSON::PP'" unless $class;

    my $json = $class->new->ascii(1)->convert_blessed(1)->allow_nonref(1);

    *JSON = sub() { $json };
}

sub serialize   { JSON()->encode($_[1]) }
sub deserialize { JSON()->decode($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Serializer::JSON - JSON Serializer for IPC::Manager.

=head1 DESCRIPTION

Serielize and deserialize message payloads using json.

=head1 SYNOPSIS

    use IPC::Manager;

    my $ipcm = ipcm_spawn(serializer => 'JSON');

    my $con = IPC::Manager::Client::PROTOCOL->connect($id, 'JSON');

=head1 METHODS

=over 4

=item $string = IPC::Manager::Serializer::JSON->serialize($obj)

Serialize an object.

=item $obj = IPC::Manager::Serializer::JSON->deserialize($string)

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
