use strict;
use warnings;
package Juno::Check::FPing;
# ABSTRACT: An FPing check for Juno
$Juno::Check::FPing::VERSION = '0.010';
use Carp;
use AnyEvent::Util 'fork_call';
use Moo;
use MooX::Types::MooseLike::Base qw<Int>;
use namespace::sweep;

extends 'Juno::Check::RawCommand';

has '+cmd' => (
    is      => 'lazy',
    builder => '_build_cmd',
);

has count => (
    is      => 'ro',
    isa     => Int,
    default => sub {3},
);

sub _build_cmd {
    my $self  = shift;
    my $count = $self->count;
    return "fping -A -q -c $count \%h";
}

sub analyze_ping_result {
    my $self   = shift;
    my $timing = shift;
    my $regex1 = qr{
        # 1.1.1.1 : xmt/rcv/%loss = 5/5/0%, min/avg/max = 235/379/602
        ^                                        # start
        ( \d+ \. \d+ \. \d+ \. \d+ )             # host ip
        \s+ : \s+                                # results separator
        xmt/rcv/%loss \s = \s \d+/\d+/(\d+)%, \s # loss percentage
        min/avg/max \s = \s
        \d+(?:\.\d+)?/(\d+(?:\.\d+)?)/\d+(?:\.\d+)? # average
        $                                           # finish
    }x;

    if ( ! defined $timing or $timing eq '' ) {
        return;
    }

    if ( $timing =~ $regex1 ) {
        my ( $ip, $loss, $average ) = ( $1, $2, $3 );

        return ( $ip, $loss, $average );
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juno::Check::FPing - An FPing check for Juno

=head1 VERSION

version 0.010

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 hosts

An arrayref of hosts to check, overriding the default given to Juno.pm.

    my $juno = Juno->new(
        hosts  => [ 'Tom', 'Jerry' ],
        checks => {
            FPing => {
                hosts => [ 'Micky', 'Mini' ], # this overrides tom and jerry
            },
        },
    );

Now the FPing check will not check Tom and Jerry, but rather Micky and Mini.

This attribute derives from L<Juno::Role::Check>.

=head2 interval

An integer of seconds between each check (nor per-host).

This attribute derives from L<Juno::Role::Check>.

=head2 on_success

A coderef to run when making a successful request.

This attribute derives from L<Juno::Role::Check>.

=head2 on_fail

A coderef to run when making an unsuccessful request.

This attribute derives from L<Juno::Role::Check>.

=head2 on_result

A coderef to run when getting a response - any response. This is what you use
in case you want more control over what's going on.

This attribute derives from L<Juno::Role::Check>.

=head2 on_before

A coderef to run before making a request.

=head2 watcher

Holds the watcher for the FPing check timer.

This attribute derives from L<Juno::Role::Check>.

=head1 METHODS

=head2 analyze_fping(TIMING)

Analyzes the fping results, returns timing, packet loss and average.

=head2 check

L<Juno> will call this method for you. You should not call it yourself.

=head2 run

L<Juno> will call this method for you. You should not call it yourself.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Adam Balali <adamba@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
