use strict;
use warnings;
package Juno::Check::RawCommand;
# ABSTRACT: A raw command check for Juno
$Juno::Check::RawCommand::VERSION = '0.010';
use JSON;
use Carp;
use Try::Tiny;
use AnyEvent::Util 'fork_call';
use System::Command;

use Moo;
use MooX::Types::MooseLike::Base qw<Str>;
use namespace::sweep;

with 'Juno::Role::Check';

has cmd => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub check {
    my $self    = shift;
    my $cmdattr = $self->cmd;
    my @hosts   = @{ $self->hosts };

    foreach my $host (@hosts) {
        $self->has_on_before and $self->on_before->( $self, $host );

        fork_call {
            my $run = $cmdattr;
            $run =~ s/%h/$host/g;

            my $cmd      = System::Command->new($run);
            my $stdoutfh = $cmd->stdout;
            my $stderrfh = $cmd->stderr;
            my $stdout   = do { local $/ = undef; <$stdoutfh>; };
            my $stderr   = do { local $/ = undef; <$stderrfh>; };

            chomp ( $stdout, $stderr );

            $cmd->close;

            # serialize
            my $data = {
                exit   => $cmd->exit,
                stdout => $stdout,
                stderr => $stderr,
            };

            return encode_json $data;
        } sub {
            # deserialize
            my $serialized = shift;
            my $data       = '';

            try   { $data = decode_json $serialized }
            catch {
                $self->on_fail
                    and $self->on_fail->( $self, $host, $serialized, $_ );
            };

            $self->has_on_result and $self->on_result->( $self, $host, $data );

            $data or return;

            if ( $data->{'exit'} == 0 ) {
                $self->has_on_success
                    and $self->on_success->( $self, $host, $data );
            } else {
                $self->has_on_fail
                    and $self->on_fail->( $self, $host, $data );
            }
        };
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juno::Check::RawCommand - A raw command check for Juno

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Allows you to run a raw command. The command will be run in a separate fork
using L<System::Command> so you can get full access to everything in the
command (stdout, stderr, exit code, etc.).

=head1 ATTRIBUTES

=head2 cmd

The command to run. This allows a B<very> simple template that allows you to
use C<%h> as the host.

=head2 hosts

An arrayref of hosts to check, overriding the default given to Juno.pm.

    my $juno = Juno->new(
        checks => {
            RawCommand => {
                hosts      => ['Jeff'],
                cmd        => 'grep %h %h.log', # %h will be the host
                on_success => sub {
                    my ( $check, $host, $cmd ) = @_;

                    print "Found $host in $host.log\n"
                        . $cmd->{'stdout'};
                },

                on_fail    => sub {
                    my ( $check, $host, $cmd, $msg ) = @_;

                    $msg and print "Deserialization failed, odd error: $msg\n";

                    print "Failed to find $host in log.txt:\n"
                        . $cmd->{'stderr'};
                },
            },
        },
    );

This attribute derives from L<Juno::Role::Check>.

=head2 interval

An integer of seconds between each check (nor per-host).

This attribute derives from L<Juno::Role::Check>.

=head2 on_success

A coderef to run when making a successful result, which is zero by default.

This attribute derives from L<Juno::Role::Check>.

=head2 on_fail

A coderef to run when making an unsuccessful request, which isn't zero by
default.

This attribute derives from L<Juno::Role::Check>.

=head2 on_result

A coderef to run on the result. This is what you use
in case you want more control over what's going on.

This attribute derives from L<Juno::Role::Check>.

=head2 on_before

A coderef to run before running the command.

=head2 watcher

Holds the watcher for the command check timer.

This attribute derives from L<Juno::Role::Check>.

=head1 METHODS

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
