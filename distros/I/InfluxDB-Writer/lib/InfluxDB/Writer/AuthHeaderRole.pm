package InfluxDB::Writer::AuthHeaderRole;

# ABSTRACT: Helper role

use Moose::Role;
use MIME::Base64 qw/encode_base64/;
use Log::Any qw($log);

has 'influx_username' => ( is => 'ro', isa => 'Str', required => 0 );
has 'influx_password' => ( is => 'ro', isa => 'Str', required => 0 );

has '_with_auth' => ( is => 'rw', isa => 'Bool', lazy => 1, default => sub { return shift->_auth_header ? 1 : 0 } );
has '_auth_header' => ( is => 'ro', isa => 'Str', lazy_build => 1, builder => '_build__auth_header', required => 1 );

sub _build__auth_header {
    my $self = shift;

    if ( $self->influx_username && $self->influx_password ) {
        my $base64 = encode_base64(
            join( ":", $self->influx_username, $self->influx_password ) );
        chomp($base64);

        return "Basic $base64";
    } else {
        return "";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

InfluxDB::Writer::AuthHeaderRole - Helper role

=head1 VERSION

version 1.002

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
