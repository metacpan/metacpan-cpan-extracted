package Deeme::Backend::SQLite;

our $VERSION = '0.03';
use Deeme::Obj 'Deeme::Backend';
use DBI;
require DBD::SQLite;
use Deeme::Utils qw(_serialize _deserialize);
use Carp 'croak';
use Deeme::Backend::DBI;

has [qw(database _connection username password options)];

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    croak "No database string defined, database option missing"
        if ( !$self->database );
    return Deeme::Backend::DBI->new(
        database => [
            "dbi:SQLite:dbname=" . $self->database,
            $self->username, $self->password, $self->options
        ]
    );
}
1;

__END__

=encoding utf-8

=head1 NAME

Deeme::Backend::SQLite - SQLite Backend using DBI for Deeme

=head1 SYNOPSIS

  use Deeme::Backend::SQLite;
  my $e = Deeme->new( backend => Deeme::Backend::SQLite->new(
        database => "/var/tmp/deeme.db",
        username => "user",
        password => "something",
        options  => { RaiseError=> 1 }
    ) );

=head1 DESCRIPTION

Deeme::Backend::SQLite is a SQLite Backend using DBI for Deeme.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Deeme>

=cut
