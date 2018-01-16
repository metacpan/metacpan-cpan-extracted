use strict;
use warnings;

package Footprintless::Plugin::Database::Command::db::copy_to;
$Footprintless::Plugin::Database::Command::db::copy_to::VERSION = '1.04';
# ABSTRACT: copy's the database to the specified destination
# PODNAME: Footprintless::Plugin::Database::Command::db::copy_to

use parent qw(Footprintless::App::Action);

use Carp;
use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing copy...');
    eval {
        $self->{db}->connect();
        $self->{destination_db}->connect();

        $self->{db}->backup(
            $self->{destination_db},
            %{ $self->{options} },
            post_restore => $self->{post_restore}
        );
    };
    my $error = $@;
    $self->{db}->disconnect();
    $self->{destination_db}->disconnect();
    die($error) if ($error);
    $logger->info('Done!');
}

sub opt_spec {
    return (
        [ 'clean',              'drop all data on the target before restoring' ],
        [ 'ignore-all-views',   'will ignore all views' ],
        [ 'ignore-deny',        'will allow running on denied coordinates' ],
        [ 'ignore-table=s@',    'will ignore the specified table' ],
        [ 'live',               'will backup live' ],
        [ 'only-table=s@',      'will only backup the specified table' ],
        [ 'single-transaction', 'perform the restore in a single transaction' ],
        [ 'where=s',            'a where clause' ],
    );
}

sub usage_desc {
    return 'fpl db DB_COORD copy-to DB_COORD %o';
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    my $command_helper = $self->{footprintless}->db_command_helper();
    my ($destination_coordinate) = @$args;
    $self->usage_error('destination coordinate required for copy')
        unless ($destination_coordinate);
    croak("destination [$destination_coordinate] not allowed")
        unless $opts->{ignore_deny}
        || $command_helper->allowed_destination($destination_coordinate);

    eval { $self->{db} = $self->{footprintless}->db( $self->{coordinate} ); };
    croak("invalid coordinate [$self->{coordinate}]: $@") if ($@);

    eval { $self->{destination_db} = $self->{footprintless}->db($destination_coordinate); };
    croak("invalid destination coordinate [$destination_coordinate]: $@") if ($@);

    $self->{options} = {
        clean            => $opts->{clean},
        ignore_all_views => $opts->{ignore_all_views},
        ( $opts->{ignore_table} ? ( ignore_tables => $opts->{ignore_table} ) : () ),
        live => $opts->{live},
        ( $opts->{only_table} ? ( only_tables => $opts->{only_table} ) : () ),
        single_transaction => $opts->{single_transaction},
        ( $opts->{where} ? ( where => $opts->{where} ) : () ),
    };

    $self->{post_restore} =
        $command_helper->post_restore( $self->{coordinate}, $destination_coordinate );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::Command::db::copy_to - copy's the database to the specified destination

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
