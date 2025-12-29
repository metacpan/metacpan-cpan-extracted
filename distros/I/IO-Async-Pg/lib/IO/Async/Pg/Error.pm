package IO::Async::Pg::Error;

use strict;
use warnings;

use overload
    '""'   => sub { shift->message },
    'bool' => sub { 1 },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub message { shift->{message} }

sub throw {
    my $self = shift;
    die ref $self ? $self : $self->new(@_);
}

# SQLSTATE code to human-readable state name mapping
my %STATE_MAP = (
    '23505' => 'unique_violation',
    '23503' => 'foreign_key_violation',
    '23502' => 'not_null_violation',
    '23514' => 'check_violation',
    '23P01' => 'exclusion_violation',
    '42601' => 'syntax_error',
    '42501' => 'insufficient_privilege',
    '42P01' => 'undefined_table',
    '42703' => 'undefined_column',
    '42883' => 'undefined_function',
    '40001' => 'serialization_failure',
    '40P01' => 'deadlock_detected',
    '57014' => 'query_canceled',
    '08000' => 'connection_exception',
    '08003' => 'connection_does_not_exist',
    '08006' => 'connection_failure',
);

sub _state_from_code {
    my ($code) = @_;
    return $STATE_MAP{$code} // 'unknown';
}


package IO::Async::Pg::Error::Query;

use parent -norequire, 'IO::Async::Pg::Error';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub code       { shift->{code} }
sub constraint { shift->{constraint} }
sub detail     { shift->{detail} }
sub hint       { shift->{hint} }
sub position   { shift->{position} }

sub state {
    my $self = shift;
    return IO::Async::Pg::Error::_state_from_code($self->{code});
}


package IO::Async::Pg::Error::Connection;

use parent -norequire, 'IO::Async::Pg::Error';

sub dsn { shift->{dsn} }


package IO::Async::Pg::Error::PoolExhausted;

use parent -norequire, 'IO::Async::Pg::Error';

sub pool_size { shift->{pool_size} }


package IO::Async::Pg::Error::Timeout;

use parent -norequire, 'IO::Async::Pg::Error';

sub timeout { shift->{timeout} }


1;

__END__

=head1 NAME

IO::Async::Pg::Error - Error classes for IO::Async::Pg

=head1 SYNOPSIS

    use IO::Async::Pg::Error;

    eval { await $conn->query('BAD SQL') };
    if (my $err = $@) {
        if ($err->isa('IO::Async::Pg::Error::Query')) {
            warn "Query failed: " . $err->message;
            warn "SQLSTATE: " . $err->code;
        }
    }

=head1 DESCRIPTION

This module provides a hierarchy of error classes for IO::Async::Pg:

=over 4

=item * L<IO::Async::Pg::Error> - Base error class

=item * L<IO::Async::Pg::Error::Query> - SQL execution errors

=item * L<IO::Async::Pg::Error::Connection> - Connection errors

=item * L<IO::Async::Pg::Error::PoolExhausted> - Pool exhaustion errors

=item * L<IO::Async::Pg::Error::Timeout> - Timeout errors

=back

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=cut
