package HealthCheck::Diagnostic::DBHPing;

# ABSTRACT: Ping a database handle to check its health
use version;
our $VERSION = 'v1.2.4'; # VERSION

use 5.010;
use strict;
use warnings;
use parent 'HealthCheck::Diagnostic';

use Carp;

sub new {
    my ($class, @params) = @_;

    # Allow either a hashref or even-sized list of params
    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        label => 'dbh_ping',
        %params
    );
}

sub check {
    my ( $self, %params ) = @_;

    my $dbh = $params{dbh};
    $dbh ||= $self->{dbh} if ref $self;
    $dbh = $dbh->(%params) if ref $dbh eq 'CODE';

    croak("Valid 'dbh' is required") unless $dbh and do {
        local $@; local $SIG{__DIE__}; eval { $dbh->can('ping') } };

    my $res = $self->SUPER::check( %params, dbh => $dbh );
    delete $res->{dbh};    # don't include the object in the result

    return $res;
}

sub run {
    my ( $self, %params ) = @_;
    my $dbh = $params{dbh};

    my $status     = $dbh->ping      ? "OK"         : "CRITICAL";
    my $successful = $status eq "OK" ? "Successful" : "Unsuccessful";

    my $driver = $dbh->{Driver}->{Name};
    my $info   = "$successful $driver ping of $dbh->{Name}";
    $info .= " as $dbh->{Username}" if $dbh->{Username};

    return { status => $status, info => $info };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::DBHPing - Ping a database handle to check its health

=head1 VERSION

version v1.2.4

=head1 SYNOPSIS

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::DBHPing->new( dbh => \&connect_to_db )
    ] );

    my $result = $health_check->check;
    $result->{status}; # OK on a successful ping or CRITICAL otherwise

=head1 DESCRIPTION

Determines if the database connection is available.
Sets the C<status> to "OK" or "CRITICAL" based on the
return value from C<< dbh->ping >>.

=head1 ATTRIBUTES

Those inherited from L<HealthCheck::Diagnostic/ATTRIBUTES> plus:

=head2 dbh

A coderef that returns a
L<DBI database handle object|DBI/DBI-DATABSE-HANDLE-OBJECTS>
or optionally the handle itself.

Can be passed either to C<new> or C<check>.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
