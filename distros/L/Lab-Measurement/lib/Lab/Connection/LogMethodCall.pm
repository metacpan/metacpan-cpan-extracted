package Lab::Connection::LogMethodCall;
#ABSTRACT: ???
$Lab::Connection::LogMethodCall::VERSION = '3.881';
use v5.20;

use warnings;
use strict;

use Carp;
use Exporter qw(import);

our @EXPORT = qw(dump_method_call);

# Return a hashref, which describes the method call. Does not include the
# methods's return value.
sub dump_method_call {
    my $id     = shift;
    my $method = shift;
    my @args   = @_;

    my $log = {
        id     => $id,
        method => $method,
    };

    if ( $method =~ /Clear|block_connection|unblock_connection|is_blocked/ ) {

        # These method take no arguments.
        return $log;
    }

    if ( $method eq 'timeout' ) {

        # timeout takes a single argument.
        $log->{timeout} = $args[0];
        return $log;
    }

    # The remaining methods get either a flat hash or a hashref.

    my $config;

    if ( ref $args[0] eq 'HASH' ) {
        $config = $args[0];
    }
    else {
        $config = {@args};
    }

    for my $param (qw/command read_length brutal wait_query/) {
        if ( defined $config->{$param} ) {
            my $key = $config->{$param};
            if ( ref $key ) {

                # Should never happen.
                croak "$param is a ref";
            }
            $log->{$param} = $key;
        }
    }

    return $log;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::LogMethodCall - ???

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
