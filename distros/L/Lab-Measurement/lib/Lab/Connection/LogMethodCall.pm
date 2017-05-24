package Lab::Connection::LogMethodCall;
use warnings;
use strict;
use 5.010;

use Carp;
use Exporter qw(import);

our @EXPORT = qw(dump_method_call);

our $VERSION = '3.543';

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

