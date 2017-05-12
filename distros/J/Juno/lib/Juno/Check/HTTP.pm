use strict;
use warnings;
package Juno::Check::HTTP;
# ABSTRACT: An HTTP check for Juno
$Juno::Check::HTTP::VERSION = '0.010';
use AnyEvent::HTTP;
use Moo;
use MooX::Types::MooseLike::Base qw<Str HashRef>;
use namespace::sweep;

with 'Juno::Role::Check';

has path => (
    is      => 'ro',
    isa     => Str,
    default => sub {'/'},
);

has headers => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

sub check {
    my $self  = shift;
    my @hosts = @{ $self->hosts };
    my $path  = $self->path;

    foreach my $host (@hosts) {
        my $url = "http://$host" . $path;

        $self->has_on_before
            and $self->on_before->( $self, $host );

        http_get $url, $self->headers, sub {
            my ( $body, $headers ) = @_;

            $self->has_on_result
                and $self->on_result->( $self, $host, $body, $headers );

            if ( $headers->{'Status'} =~ /^2/ ) {
                $self->has_on_success
                    and $self->on_success->( $self, $host, $body, $headers );
            } else {
                $self->has_on_fail
                    and $self->on_fail->( $self, $host, $body, $headers );
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

Juno::Check::HTTP - An HTTP check for Juno

=head1 VERSION

version 0.010

=head1 DESCRIPTION

    my $juno = Juno->new(
        checks => {
            HTTP => {
                hosts => [ 'tom', 'jerry' ],
                path  => '/my/custom/path',
            },
        }
    );

=head1 ATTRIBUTES

=head2 path

The path that is checked.

Default: B</>.

=head2 headers

A hashref or additional headers to send to the server. This is useful if you
want to run a request to a server requesting a specific website
(i.e., VirtualHost).

=head2 hosts

An arrayref of hosts to check, overriding the default given to Juno.pm.

    my $juno = Juno->new(
        hosts  => [ 'Tom', 'Jerry' ],
        checks => {
            HTTP => {
                hosts => [ 'Micky', 'Mini' ], # this overrides tom and jerry
            },
        },
    );

Now the HTTP check will not check Tom and Jerry, but rather Micky and Mini.

This attribute derives from L<Juno::Role::Check>.

=head2 interval

An integer of seconds between each check (nor per-host).

This attribute derives from L<Juno::Role::Check>.

=head2 on_success

A coderef to run when making a successful request. This is done by checking the
HTTP response header has a status code starting with 200 (which is by HTTP RFC
a successful response).

This attribute derives from L<Juno::Role::Check>.

=head2 on_fail

A coderef to run when making an unsuccessful request. This is the opposite of
C<on_success> described above.

This attribute derives from L<Juno::Role::Check>.

=head2 on_result

A coderef to run when getting a response - any response. This is what you use
in case you want more control over what's going on.

This attribute derives from L<Juno::Role::Check>.

=head2 on_before

A coderef to run before making a request. A useful example of this is timing
the request.

    use Juno;
    use AnyEvent;

    my $cv   = AnyEvent->condvar;
    my %time = (
        tom => AnyEvent->now,
    );

    my $juno = Juno->new(
        checks => {
            HTTP => {
                on_before => sub {
                    my $host = $_[1];
                    $time{$host} = AnyEvent->now;
                },

                on_result => sub {
                    my $host = $_[1];
                    my $time = AnyEvent->now - $time{'tom'};
                    print "It took $time to run the request to $host\n";
                },
            },
        },
    );

=head2 watcher

Holds the watcher for the HTTP check timer.

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
