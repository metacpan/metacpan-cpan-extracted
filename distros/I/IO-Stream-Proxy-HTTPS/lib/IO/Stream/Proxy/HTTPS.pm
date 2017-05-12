package IO::Stream::Proxy::HTTPS;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.0';

use IO::Stream::const;
use MIME::Base64;
use Scalar::Util qw( weaken );

use constant HTTP_OK => 200;

sub new {
    my ($class, $opt) = @_;
    croak '{host}+{port} required'
        if !defined $opt->{host}
        || !defined $opt->{port}
        ;
    croak '{user}+{pass} required'
        if $opt->{user} xor $opt->{pass};
    my $self = bless {
        host        => undef,
        port        => undef,
        user        => undef,
        pass        => undef,
        %{$opt},
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
        _want_write => undef,
        }, $class;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    croak '{fh} already connected'
        if !defined $host;
    $self->{out_buf} = "CONNECT ${host}:${port} HTTP/1.0\r\n";
    if (defined $self->{user}) {
        $self->{out_buf} .= 'Proxy-Authorization: Basic '
            . encode_base64($self->{user}.q{:}.$self->{pass}, q{})
            . "\r\n"
            ;
    }
    $self->{out_buf} .= "\r\n";
    $self->{_slave}->PREPARE($fh, $self->{host}, $self->{port});
    $self->{_slave}->WRITE();
    return;
}

sub WRITE {
    my ($self) = @_;
    $self->{_want_write} = 1;
    return;
}

sub EVENT {
    my ($self, $e, $err) = @_;
    my $m = $self->{_master};
    if ($err) {
        $m->EVENT(0, $err);
    }
    if ($e & IN) {
        if ($self->{in_buf} =~ s{\A(HTTP/\d[.]\d\s(\d+)\s.*?)\r?\n\r?\n}{}xms) {
            my ($reply, $status) = ($1, $2);
            if ($status == HTTP_OK) {
                $e = CONNECTED;
                if (my $l = length $self->{in_buf}) {
                    $e |= IN;
                    $m->{in_buf}    .= $self->{in_buf};
                    $m->{in_bytes}  += $l;
                }
                $m->EVENT($e);
                $self->{_slave}->{_master} = $m;
                weaken($self->{_slave}->{_master});
                $m->{_slave} = $self->{_slave};
                if ($self->{_want_write}) {
                    $self->{_slave}->WRITE();
                }
            }
            else {
                $m->EVENT(0, 'https proxy: '.$reply);
            }
        }
    }
    if ($e & EOF) {
        $m->{is_eof} = $self->{is_eof};
        $m->EVENT(0, 'https proxy: unexpected EOF');
    }
    return;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

IO::Stream::Proxy::HTTPS - HTTPS proxy plugin for IO::Stream


=head1 VERSION

This document describes IO::Stream::Proxy::HTTPS version v2.0.0


=head1 SYNOPSIS

    use IO::Stream;
    use IO::Stream::Proxy::HTTPS;

    IO::Stream->new({
        ...
        plugin => [
            ...
            proxy   => IO::Stream::Proxy::HTTPS->new({
                host    => 'my.proxy.com',
                port    => 3128,
                user    => 'me',
                pass    => 'mypass',
            }),
            ...
        ],
    });


=head1 DESCRIPTION

This module is plugin for L<IO::Stream> which allow you to route stream
through HTTPS (also called CONNECT) proxy.

You may use several IO::Stream::Proxy::HTTPS plugins for single IO::Stream
object, effectively creating proxy chain (first proxy plugin will define
last proxy in a chain).

=head2 EVENTS

When using this plugin event RESOLVED will never be delivered to user because
target {host} which user provide to IO::Stream will never be resolved on
user side (it will be resolved by HTTPS proxy).

Event CONNECTED will be generated after HTTPS proxy successfully connects to
target {host} (and not when socket will connect to HTTPS proxy itself).

=head1 INTERFACE 

=over

=item new({ host=>$host, port=>$port })

=item new({ host=>$host, port=>$port, user=>$user, pass=>$pass })

Connect to proxy $host:$port, optionally using basic authorization.

=back


=head1 DIAGNOSTICS

=over

=item C<< {host}+{port} required >>

You must provide both {host} and {port} to IO::Stream::Proxy::HTTPS->new().

=item C<< {user}+{pass} required >>

You have provided either {user} or {pass} to IO::Stream::Proxy::HTTPS->new()
while you have to provide either both or none of them.

=item C<< {fh} already connected >>

You have provided {fh} to IO::Stream->new(), but this is not supported by
this plugin. Either don't use this plugin or provide {host}+{port} to
IO::Stream->new() instead.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-IO-Stream-Proxy-HTTPS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-IO-Stream-Proxy-HTTPS>

    git clone https://github.com/powerman/perl-IO-Stream-Proxy-HTTPS.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=IO-Stream-Proxy-HTTPS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/IO-Stream-Proxy-HTTPS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Stream-Proxy-HTTPS>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=IO-Stream-Proxy-HTTPS>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/IO-Stream-Proxy-HTTPS>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
