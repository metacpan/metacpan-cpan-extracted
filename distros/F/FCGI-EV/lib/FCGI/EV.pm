package FCGI::EV;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use Scalar::Util qw( weaken );
use IO::Stream;


use constant FCGI_HEADER_LEN        => 8;
use constant FCGI_VERSION_1         => 1;
use constant FCGI_BEGIN_REQUEST     => 1;
use constant FCGI_END_REQUEST       => 3;
use constant FCGI_PARAMS            => 4;
use constant FCGI_STDIN             => 5;
use constant FCGI_STDOUT            => 6;
use constant FCGI_RESPONDER         => 1;
use constant FCGI_REQUEST_COMPLETE  => 0;
use constant END_REQUEST_COMPLETE   =>
    pack 'N C CCC', 0, FCGI_REQUEST_COMPLETE, 0, 0, 0;
use constant MAX_CONTENT_LEN        => 0xFFFF;


sub new {
    my ($class, $sock, $handler_class) = @_;
    my $self = bless {
        io          => undef,
        req_id      => undef,
        params      => q{},
        stdin_eof   => undef,
        handler     => undef,
        handler_class=>$handler_class,
    }, $class;
    $self->{io} = IO::Stream->new({
        fh          => $sock,
        wait_for    => IN|EOF,
        cb          => $self,
        Wait_header => 1,
        Need_in     => FCGI_HEADER_LEN,
    });
    weaken($self->{io});
    # It MAY have sense to add timeout between read() calls and timeout for
    # overall time until EOF on STDIN will be received. First timeout
    # can be about 3 minutes for slow clients, second can be about 4 hours
    # for uploading huge files.
    return;
}

sub DESTROY {
    my ($self) = @_;
    $self->{handler} = undef;   # call handler's DESTROY while $self is alive
    return;
}

sub stdout {
    my ($self, $stdout, $is_eof) = @_;
    my $io = $self->{io};
    if (length $stdout) {
        $io->{out_buf} .= _pack_pkt(FCGI_STDOUT, $self->{req_id}, $stdout);
    }
    if ($is_eof) {
        $io->{out_buf} .= _pack_pkt(FCGI_STDOUT, $self->{req_id}, q{});
        $io->{out_buf} .= _pack_pkt(FCGI_END_REQUEST, $self->{req_id}, END_REQUEST_COMPLETE);
        $io->{wait_for} |= SENT;
    }
    $io->write();
    return;
}

sub IO {
    my ($self, $io, $e, $err) = @_;
    if ($err) {
        warn "FCGI::EV: IO: $err\n";
        return $io->close();
    }
    if ($e & EOF) {
        return $io->close();
    }
    if ($e & SENT) {
        return $io->close();
    }
    while (length $io->{in_buf} >= $io->{Need_in}) {
        if ($io->{Wait_header}) {
            $io->{Wait_header}  = 0;
            my ($content_len, $padding_len) = unpack 'x4 n C', $io->{in_buf};
            $io->{Need_in} += $content_len + $padding_len;
        }
        else {
            my $pkt = substr $io->{in_buf}, 0, $io->{Need_in}, q{};
            $io->{Wait_header}  = 1;
            $io->{Need_in}      = FCGI_HEADER_LEN;
            my $error = $self->_process($pkt);
            if ($error) {
                warn "FCGI::EV: $error\n";
                return $io->close();
            }
        }
    }
    return;
}

sub _process {
    my ($self, $pkt) = @_;
    my ($ver, $type, $req_id, $content_len) = unpack 'C C n n', $pkt;
    my $content = substr $pkt, FCGI_HEADER_LEN, $content_len;
    if ($ver != FCGI_VERSION_1) {
        return "unsupported version: $ver";
    }
    if (defined $self->{req_id} && $self->{req_id} != $req_id) {
        return "unknown request id: $req_id";
    }
    if ($type == FCGI_BEGIN_REQUEST) {
        my ($role) = unpack 'n', $content;
        if ($role != FCGI_RESPONDER) {
            return "role not supported: $role";
        }
        if (defined $self->{req_id}) {
            return 'duplicated BEGIN_REQUEST';
        }
        $self->{req_id} = $req_id;
    }
    elsif ($type == FCGI_PARAMS) {
        if ($self->{handler}) {
            return 'got PARAMS for existing handler';
        }
        if (length $content) {
            $self->{params} .= $content;
        }
        else {
            my ($env, $err) = _unpack_nv($self->{params});
            return $err if $err;
            $self->{handler} = $self->{handler_class}->new($self, $env);
        }
    }
    elsif ($type == FCGI_STDIN) {
        if (!$self->{handler}) {
            return 'got STDIN for non-existing handler';
        }
        if ($self->{stdin_eof}) {
            return 'got STDIN after STDIN EOF';
        }
        if (length $content) {
            $self->{handler}->stdin($content, 0);
        }
        else {
            $self->{handler}->stdin(q{}, 1);
            $self->{stdin_eof} = 1;
        }
    }
    else {
        return 'unknown type';
    }
    return;
}

sub _unpack_nv {
    my ($s) = @_;
    my %nv;
    while (length $s) {
        my ($nlen, $vlen);
        for my $len ($nlen, $vlen) {
            ## no critic (ProhibitMagicNumbers)
            return (undef, 'unpack_nv: not enough data') if length $s < 1;
            ($len) = unpack 'C', $s;
            if ($len & 0x80) {
                return (undef, 'unpack_nv: not enough data') if length $s < 4;
                ($len) = unpack 'N', $s;
                $len &= 0x7FFFFFFF;
                substr $s, 0, 4, q{};
            }
            else {
                substr $s, 0, 1, q{};
            }
            ## use critic
        }
        return (undef, 'unpack_nv: not enough data') if length $s < $nlen + $vlen;
        my $n = substr $s, 0, $nlen, q{};
        my $v = substr $s, 0, $vlen, q{};
        $nv{$n} = $v;
    }
    return (\%nv, undef);
}

sub _pack_pkt {
    my ($type, $req_id, $content) = @_;
    $content = pack 'a*', $content; # convert from Unicode to UTF-8, if any
    my $pkt = q{};
    while (1) {
        my $c = substr $content, 0, MAX_CONTENT_LEN, q{};
        my $padding = q{};
        $pkt .= pack 'CCnnCCa*a*',
            FCGI_VERSION_1,
            $type,
            $req_id,
            length $c,
            length $padding,
            0,                                      # reserved
            $c,
            $padding,
            ;
        last if !length $content;
    }
    return $pkt;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

FCGI::EV - Implement FastCGI protocol for use in EV-based applications


=head1 VERSION

This document describes FCGI::EV version v2.0.1


=head1 SYNOPSIS

 use FCGI::EV;
 use Some::FCGI::EV::Handler;

 # while in EV::loop, accept incoming connection from web server into
 # $sock, then start handling FastCGI protocol on that connection,
 # using Some::FCGI::EV::Handler for processing CGI requests:
 FCGI::EV->new($sock, 'Some::FCGI::EV::Handler');


 #
 # EXAMPLE: complete FastCGI server (without error handling code)
 #          use FCGI::EV::Std handler (download separately from CPAN)
 #

 use Socket;
 use Fcntl;
 use EV;
 use FCGI::EV;
 use FCGI::EV::Std;

 my $path = '/tmp/fastcgi.sock';

 socket my $srvsock, AF_UNIX, SOCK_STREAM, 0;
 unlink $path;
 my $umask = umask 0;   # ensure 0777 perms for unix socket
 bind $srvsock, sockaddr_un($path);
 umask $umask;
 listen $srvsock, SOMAXCONN;
 fcntl $srvsock, F_SETFL, O_NONBLOCK;

 my $w = EV::io $srvsock, EV::READ, sub {
    accept my($sock), $srvsock;
    fcntl $sock, F_SETFL, O_NONBLOCK;
    FCGI::EV->new($sock, 'FCGI::EV::Std');
 };

 EV::loop;


=head1 DESCRIPTION

This module implement FastCGI protocol for use in EV-based applications.
(That mean you have to run EV::loop in your application or this module
will not work.)

It receive and parse data from web server, pack and send data to web
server, but it doesn't process CGI requests received from web server -
instead it delegate this work to another module called 'handler'. For
one example of such handler, see L<FCGI::EV::Std>.

FCGI::EV work using non-blocking sockets and initially was designed to use
in event-based CGI applications (which able to handle multiple parallel
CGI requests in single process without threads/fork). This require from
CGI to avoid any operations which may block, like using SQL database -
instead CGI should delegate all such tasks to remote services and talk to
these services in non-blocking mode.

It also possible to use it to run usual CGI.pm-based applications. If you
will do this using FCGI::EV::Std handler, then only one CGI request will
be executed at a time (which is probably not what you expect from
FastCGI!), because FCGI::EV::Std doesn't implement any process-manager.
But it's possible to develop another handlers for FCGI::EV, which will
support process-management and so will handle multiple CGI request in
parallel.

This module doesn't require from user to use CGI.pm - any module for
parsing CGI params can be used in general (details depends on used
FCGI::EV handler module).


=head1 INTERFACE 

=head2 new

    FCGI::EV->new( $sock, $class );

Start talking FastCGI protocol on $sock (which should be socket open to
just-connected web server), and use $class to handle received CGI requests.

Module $class should implement "FCGI::EV handler" interface. You can use
either L<FCGI::EV::Std> from CPAN or develop your own.

Return nothing. (Created FCGI::EV object will work in background and will
be automatically destroyed after finishing I/O with web server.)


=head1 HANDLER CLASS INTERFACE

Handler class (which name provided in $class parameter to FCGI::EV->new())
must implement this interface:

=over

=item new( $server, \%env )

When FCGI::EV object receive initial part of CGI request (environment
variables) it will call $handler_class->new() to create handler object
which should process that CGI request.

Parameter $server is FCGI::EV object itself. It's required to send CGI
reply. WARNING! Handler may keep only weaken() reference to $server!

After calling new() FCGI::EV object ($server) will continue receiving
STDIN content from web server and will call $handler->stdin() each time it
get next part of STDIN.

=item stdin( $data, $is_eof )

The $data is next chunk of STDIN received from web server. Flag $is_eof will
be true if $data was last part of STDIN.

Usually handler shouldn't begin processing CGI request until all content
of STDIN will be received.

=item DESTROY

This method is optional. It will be called when connection to web server is
closed and FCGI::EV object going to die (but it's still exists when DESTROY
is called - except if DESTROY was called while global destruction stage).

Handler object may use DESTROY to interrupt current CGI request if web server
close connection before CGI send it reply.

=back

=head2 SENDING CGI REPLY

After handler got %env (in new()) and complete STDIN (in one or more calls
of stdin()) it may start handling this CGI request and prepare reply to send
to web server. To send this data it should use method $server->stdout(),
where $server is object given to new() while creating handler object
(it should keep weak reference to $server inside to be able to reply).

=over

=item stdout( $data, $is_eof )

CGI may send reply in one or more parts. Last part should have $is_eof set
to true. DESTROY method of handler object will be called shortly after
handler object will do $server->stdout( $data, 1 ).

=back

=head2 HANDLER EXAMPLE

This handler will process CGI requests one-by-one (i.e. in blocking mode).
On request function main::main() will be executed. That function may use
standard CGI.pm module to get request parameters and send it reply using
usual print to STDOUT.

There no error-handling code in this example, see L<FCGI::EV::Std> for
more details.

 package FCGI::EV::ExampleHandler;

 use Scalar::Util qw( weaken );
 use CGI::Stateless; # needed to re-init CGI.pm state between requests

 sub new {
    my ($class, $server, $env) = @_;
    my $self = bless {
        server  => $server,
        env     => $env,
        stdin   => q{},
    }, $class;
    weaken($self->{server});
    return $self;
 }

 sub stdin {
    my ($self, $stdin, $is_eof) = @_;
    $self->{stdin} .= $stdin;
    if ($is_eof) {
        local *STDIN;
        open STDIN, '<', \$self->{stdin};
        local %ENV = %{ $self->{env} };
        local $CGI::Q = CGI::Stateless->new();
        local *STDOUT;
        my $reply = q{};
        open STDOUT, '>', \$reply;
        main::main();
        $self->{server}->stdout($reply, 1);
    }
    return;
 }


=head1 DIAGNOSTICS

There no errors returned in any way by this module, but there few warning
messages may be printed:

=over

=item C<< FCGI::EV: IO: %s >>

While doing I/O with web server error %s happened and connection was closed.

=item C<< FCGI::EV: %s >>

While parsing data from web server error %s happened and connection was closed.
(That error probably mean bug either in web server or this module.)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-FCGI-EV/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-FCGI-EV>

    git clone https://github.com/powerman/perl-FCGI-EV.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=FCGI-EV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/FCGI-EV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FCGI-EV>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=FCGI-EV>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/FCGI-EV>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
