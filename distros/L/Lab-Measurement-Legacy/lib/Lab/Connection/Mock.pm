package Lab::Connection::Mock;
#ABSTRACT: ???
$Lab::Connection::Mock::VERSION = '3.899';
use v5.20;

use warnings;
use strict;

use Class::Method::Modifiers;
use YAML::XS qw/Dump LoadFile/;
use Data::Dumper;
use autodie;
use Carp;

use Lab::Connection::LogMethodCall qw/dump_method_call/;
use parent 'Lab::Connection';


our %fields = (
    logfile   => undef,
    log_index => 0,
    log_list  => undef,
);

around 'new' => sub {
    my $orig  = shift;
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;

    # getting fields and _permitted from parent class
    my $self = $class->$orig(@_);

    $self->_construct($class);

    # Open the log file.
    my $logfile = $self->logfile();
    if ( not defined $logfile ) {
        croak 'missing "logfile" parameter in connection';
    }

    my @logs = LoadFile($logfile);
    $self->log_list( [@logs] );

    return $self;
};

# If all values are scalars, we don't need stuff like Data::Compare.
sub compare_hashs {
    my $a = shift;
    my $b = shift;

    my @keys_a = keys %{$a};
    my @keys_b = keys %{$b};

    my $len_a = @keys_a;
    my $len_b = @keys_b;

    # compare size
    if ( $len_a != $len_b ) {
        return 1;
    }
    for my $key (@keys_a) {
        if ( ref $a->{$key} ) {
            die "expected scalar";
        }
        if ( not exists $b->{$key} ) {
            return 1;
        }
        if ( $a->{$key} ne $b->{$key} ) {
            return 1;
        }
    }
    return 0;
}

sub process_call {
    my $method = shift;
    my $self   = shift;

    my $index = $self->log_index();

    # Hack: $self->timeout is called early in Lab::Connection::configure.
    if ( not defined $self->log_list() and $method eq 'timeout' ) {
        return $self->{config}->{timeout};
    }

    my $received = dump_method_call( $index, $method, @_ );

    my $expected = $self->log_list()->[$index];

    my $retval = delete $expected->{retval};

    if ( compare_hashs( $received, $expected ) ) {
        croak "Mock connection:\nreceived:\n", Dump($received),
            "\nexpected:\n", Dump($expected);
    }

    $self->log_index( ++$index );
    return $retval;
}

for my $method (
    qw/Clear Write Read Query BrutalRead LongQuery BrutalQuery timeout
    block_connection unblock_connection is_blocked/
    ) {
    around $method => sub {
        my $orig = shift;
        return process_call( $method, @_ );
    };
}

sub _setbus {

    # No bus for this connection, so do nothing.
    return;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::Mock - ??? (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
