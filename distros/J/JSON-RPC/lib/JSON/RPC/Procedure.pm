package JSON::RPC::Procedure;
use strict;
use Carp ();
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        id
        method
        params
        has_id
        jsonrpc
    ) ]
;

1;

__END__

=head1 NAME

JSON::RPC::Procedure - A JSON::RPC Procedure

=head1 SYNOPSIS

    use JSON::RPC::Procedure;

    my $procedure = JSON::RPC::Procedure->new(
        id => ...,
        method => ...
        params => ...
        jsonrpc => ...
        has_id => ... (a flag that signals that a procedure appears to be a notification when not set)
    );

=head1 DESCRIPTION

A container for JSON RPC procedure information

=cut
