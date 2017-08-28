package MYDan::Agent;

=head1 NAME

Agent - A plugin execution platform

=head1 SYNOPSIS

 use MYDan::Agent;

 my $agent = MYDan::Agent->new( '/path/file' );

 $agent->run();

=cut
use strict;
use warnings;

use MYDan::Agent::Path;
use MYDan::Agent::Query;

sub new 
{
    my $class = shift;
    bless { path => MYDan::Agent::Path->new( @_ )->make() }, ref $class || $class;
}

=head1 METHODS

=head3 run()

Loads I<query> from STDIN, runs query, and dumps result in YAML to STDOUT.

See MYDan::Agent::Query.

=cut
sub run
{
    local $| = 1;
    local $/ = undef;

    my $self = shift;
    warn sprintf "%s:%s\n", @ENV{ qw( TCPREMOTEIP TCPREMOTEPORT ) };

    my $query = MYDan::Agent::Query->load( <> );
    warn $query->yaml();

    $query->run( %{ $self->{path}->path() } );
}

1;
