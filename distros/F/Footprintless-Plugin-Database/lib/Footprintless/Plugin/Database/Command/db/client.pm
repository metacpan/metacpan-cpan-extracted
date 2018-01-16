use strict;
use warnings;

package Footprintless::Plugin::Database::Command::db::client;
$Footprintless::Plugin::Database::Command::db::client::VERSION = '1.04';
# ABSTRACT: start a command line client
# PODNAME: Footprintless::Plugin::Database::Command::db::client

use parent qw(Footprintless::App::Action);

use Carp;
use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->{db}->client( in_file => $self->{in_file}, client_options => $args );
}

sub opt_spec {
    return ( [ 'in-file=s', 'a sql script to pipe as input to the client' ] );
}

sub usage_desc {
    return 'fpl db DB_COORD client %o';
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{db} = $self->{footprintless}->db( $self->{coordinate} ); };
    croak("invalid coordinate [$self->{coordinate}]: $@") if ($@);

    if ( $opts->{in_file} ) {
        my $command_helper = $self->{footprintless}->db_command_helper();
        $self->{in_file} = $command_helper->locate_file( $opts->{in_file} );
    }
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::Command::db::client - start a command line client

=head1 VERSION

version 1.04

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=back

=for Pod::Coverage execute opt_spec usage_desc validate_args

=cut
