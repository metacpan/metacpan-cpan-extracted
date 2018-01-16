use strict;
use warnings;

package Footprintless::Plugin::Database::CsvProvider;
$Footprintless::Plugin::Database::CsvProvider::VERSION = '1.04';
# ABSTRACT: A CSV file provider implementation
# PODNAME: Footprintless::Plugin::Database::CsvProvider

use parent qw(Footprintless::Plugin::Database::AbstractProvider);

use overload q{""} => 'to_string', fallback => 1;

use Footprintless::Util qw(dynamic_module_new);
use Log::Any;

my $logger = Log::Any->get_logger();

sub backup {
    die("not yet implemented");
}

sub _connection_string {
    my ($self) = @_;
    my ( $hostname, $port ) = $self->_hostname_port();
    return
        join( '', 'DBI:CSV:', 'f_dir=', $self->{f_dir}, ';', 'csv_eol=', $self->{csv_eol}, ';' );
}

sub _init {
    my ( $self, %options ) = @_;
    $self->Footprintless::Plugin::Database::AbstractProvider::_init(%options);

    my $entity = $self->_entity( $self->{coordinate} );

    $self->{f_dir} = $entity->{f_dir};
    $self->{csv_eol} = $entity->{csv_eol} || "\n";

    return $self;
}

sub restore {
    die("not yet implemented");
}

sub to_string {
    my ($self) = @_;
    return $self->_connection_string();
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::CsvProvider - A CSV file provider implementation

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

=cut
