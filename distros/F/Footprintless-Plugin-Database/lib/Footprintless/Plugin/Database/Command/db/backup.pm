use strict;
use warnings;

package Footprintless::Plugin::Database::Command::db::backup;
$Footprintless::Plugin::Database::Command::db::backup::VERSION = '1.04';
# ABSTRACT: creates a backup of the database
# PODNAME: Footprintless::Plugin::Database::Command::db::backup

use parent qw(Footprintless::App::Action);

use Carp;
use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub execute {
    my ( $self, $opts, $args ) = @_;

    $logger->info('Performing backup...');
    eval {
        $self->{db}->connect();
        $self->{db}->backup( $self->{file}, %{ $self->{options} } );
    };
    my $error = $@;
    $self->{db}->disconnect();
    die($error) if ($error);
    $logger->info('Done!');
}

sub opt_spec {
    return (
        [ 'file=s',           'the output file' ],
        [ 'ignore-all-views', 'will ignore all views' ],
        [ 'ignore-table=s@',  'will ignore the specified table' ],
        [ 'only-table=s@',    'will only backup the specified table' ],
        [ 'live',             'will backup live' ],
    );
}

sub usage_desc {
    return 'fpl db DB_COORD backup %o';
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    eval { $self->{db} = $self->{footprintless}->db( $self->{coordinate} ); };
    croak("invalid coordinate [$self->{coordinate}]: $@") if ($@);

    $self->{file} = $opts->{file} || \*STDOUT;

    $self->{options} = {
        ignore_all_views => $opts->{ignore_all_views},
        ( $opts->{ignore_table} ? ( ignore_tables => $opts->{ignore_table} ) : () ),
        live => $opts->{live},
        ( $opts->{only_table} ? ( only_tables => $opts->{only_table} ) : () ),
    };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::Command::db::backup - creates a backup of the database

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
