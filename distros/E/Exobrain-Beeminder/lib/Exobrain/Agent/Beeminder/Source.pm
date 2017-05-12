package Exobrain::Agent::Beeminder::Source;
use Moose;
use Method::Signatures;
use Try::Tiny;
use Dancer qw(set post warning debug status error dance params param);
use Data::Dumper;

with 'Exobrain::Agent::Beeminder';
with 'Exobrain::Agent::Run';

# ABSTRACT: Turn Beeminder callbacks into exobrain measurements
our $VERSION = '1.06'; # VERSION


method run() {

    # This is all Dancer configuration, because we run a little
    # Dancer micro-instance.

    set port     => 3000;
    set logger   => 'console';
    set log      => 'core';
    set warnings => 1;

    post qr{.*} => sub {

        # If we see what could be a valid response, but it's not
        # an 'ADD', then ignore it.
        if( (param('action')||"") ne 'ADD') {
            warning("Non-add packet received");
            return "IGNORED";
        }

        my $pktdump = Dumper ({ params() });
        debug("Receieved packet: $pktdump");

        # Exobrain just accepts the packet whole.

        try {
            debug("About to send packet on exobrain bus...");
            $self->exobrain->measure( 'Beeminder', params(), raw => { params() } );
            debug("Packet sent on exobrain bus");
        }
        catch {
            error("Sending on exobrain bus failed: $_");
            status 'error';
            return "Invalid packet";
        };

        return "OK";
    };

    dance;
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Beeminder::Source - Turn Beeminder callbacks into exobrain measurements

=head1 VERSION

version 1.06

=begin example

This is what a set of params look like when they come in.

'params' => {
            'source' => 'pjf/test',
            'urtext' => '2013 09 14.5 1 "Testy test test"',
            'value' => '1.0',
            'splat' => $VAR1->{'_route_params'}{'splat'},
            'origin' => 'web',
            'created' => '1379125551',
            'comment' => 'Testy test test',
            'action' => 'ADD',      # Have also seen 'DEL'
            'id' => '5233c92fcc19310bb5000008',
            'daystamp' => '15962'
},

=end example

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
