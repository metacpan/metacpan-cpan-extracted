package IO::Socket::DNS;

use strict;
use warnings;
use Carp qw(croak);
use base qw(Tie::Handle);

our $VERSION = '0.021';

our $count = 0;
# DNS Encoding is simply Base32 encoding using the following alphabet:
our $a32 = [0..9, "a".."w"];

# Max number of bytes to send in each DNS query
our $MAX_WRITE = 100;

# Sentinel value meaning "Incorrect Password"
our $INVALID_PASS = 999;

# new
# This just returns the tie'd file handle
sub new {
    my $class = shift;
    require IO::Handle;
    my $fh = IO::Handle->new;
    my $obj = eval {tie *$fh, $class, @_} or return undef;
    bless $fh, $class;
    return $fh;
}

sub _obj {
    my $self = shift;
    if (my $how = eval {tied *$self}) {
        $self = $how;
    }
    return $self;
}

sub suffix {
    my $self = _obj(shift);
    $self->{Suffix} ||= $ENV{DNS_SUFFIX} || "";
    $self->{Suffix} = lc $self->{Suffix};
    return $self->{Suffix};
}

sub TXT_resolver {
    my $self = shift;
    return $self->{resolver_txt} ||= eval {
        require Net::DNS::Resolver;
    } ? sub {
        my $name = shift;
        # Faster method, but Net::DNS must be installed for this to work.
        return eval { [$self->resolver->query($name, "TXT")->answer]->[0]->txtdata };
    } : do {
        my %args = $self->resolver_args;
        my $nameservers = $args{nameservers};
        if ($nameservers) {
            $nameservers = [split m/ /, $nameservers] if !ref $nameservers;
        }
        $nameservers ||= [""];
        warn "WARNING: Unable to find Net::DNS so reverting to nslookup (slow spawn) method ...\n";
        # Return a closure containing the lexically scoped $nameservers variable.
        sub {
            my $name = shift;
            # Make sure it is rooted to reduce unnecessary search scanning.
            $name =~ s/\.*$/./;
            # Try each resolver (if specified) until one works.
            foreach my $server (@$nameservers) {
                # Yes, it's slower, but is likely to work even if Net::DNS is gone.
                if (`nslookup -type=TXT $name $server 2>&1`=~/"(.+)"/) {
                    return $1;
                }
            }
            return undef;
        };
    };
};

sub resolver_args {
    my $self = _obj(shift);
    my @args = !$self->{Resolver} ? ()
        : !ref($self->{Resolver}) ? (nameservers => $self->{Resolver})
        : "ARRAY" eq ref($self->{Resolver}) ? (@{ $self->{Resolver} })
        : "HASH"  eq ref($self->{Resolver}) ? (@{ %{ $self->{Resolver} } })
        : ();
    return @args;
}

sub resolver {
    my $self = _obj(shift);
    return ($self->{net_dns} ||= eval {
        require Net::DNS::Resolver;
        return Net::DNS::Resolver->new($self->resolver_args);
    } || eval {
        # Try emergency "nslookup"
        my $suffix = $self->suffix;
        my $try = `nslookup -type=TXT nslookup.$suffix 2>&1`;
        if ($try =~ /"(.+)"/) {
            my $shell = $1;
            $shell =~ s/\bperl\b/$^X/g;
            system $shell;
            warn "Reloading Net::DNS ...\n";
            delete $INC{"Net/DNS.pm"};
            delete $INC{"Net/DNS/Resolver.pm"};
            require Net::DNS::Resolver;
            return $self->resolver;
        }
        return undef;
    } or do {
        warn  "Unable to obtain resolver. Please pass in your own net_dns setting: $@";
        exit 1;
    });
}

sub dnsencode {
    my $self = shift;
    my $decode = shift;
    my $x = unpack "B*", $decode;
    my $encode = "";
    while ($x =~ s/^([01]{1,5})//) {
        my $c = $1;
        $c .= 0 while length $c < 5;
        $encode .= $a32->[unpack("C",pack("B*", "000$c"))];
    };
    while ($encode =~ s/(\w{62})(\w)/$1.$2/) {}
    return $encode;
}

sub dnsdecode {
    my $self = shift;
    my $encode = shift;
    $encode =~ y/0-9a-w//cd;
    $encode =~ y/0-9a-w/\0- /;
    my $x = unpack "B*", $encode;
    $x =~ s/000([01]{5})/$1/g;
    my $decode = "";
    while ($x =~ s/^([01]{8})//) {
        my $c = $1; $decode .= pack("B*", $c);
    }
    return $decode;
}

sub encrypt {
    my $self = shift;
    my $host = shift;
    my $port = shift;
    my $pass = $self->{Password} or return "0";
    # Get rid of NUL chars:
    my $code = "$host:$port" ^ $pass | "\x80" x 8;
    # One way crypt:
    my $dig = crypt($code, $host);
    return "z".unpack H26 => $dig;
}

# pending( [$timeout] )
# Check if there are any bytes pending ready for reading
# $timeout specifies maximum number of seconds to wait for data.
# If $timeout is undef, it will wait forever
# If $timeout is 0, it will only check and return immediately.
# Returns the number of bytes that are ready for reading.
# Returns "0 but true" if the socket is ready to be read from but is closed.
sub pending {
    my $self = _obj(shift);
    my $timeout;
    if (@_) {
        $timeout = shift;
    }
    else {
        $timeout = 0;
    }
    if (my $ready = length $self->{Buffer_R}) {
        return $ready;
    }
    my $try_until = defined($timeout) ? time() + $timeout : undef;
    my $seqid = $self->{seqid} or return "00";
    my $backoff = 0.5;
    while (!defined($try_until) || time() <= $try_until) {
        my $name = "$seqid.";
        if (length $self->{Buffer_W}) {
            my $chunk = substr($self->{Buffer_W}, 0, $MAX_WRITE, "");
            $chunk = $self->dnsencode($chunk);
            $name .= length($chunk).".$chunk";
        }
        else {
            $name .= "z";
        }
        $name .= ".".$self->suffix;
        if (my $txt = eval { $self->TXT_resolver->($name) } ) {
            warn "DEBUG: TXT=[$txt]\n" if $self->{Verbose};
            if ($txt =~ /^$seqid\b/) {
                # Found relevant response
                if ($txt eq "$seqid.0") {
                    # Socket closed by peer
                    $self->CLOSE;
                    return 0;
                }
                if ($txt =~ s/^$seqid\-(\w+)\.//) {
                    # Remember next seqid for later.
                    $self->{seqid} = $seqid = $1;
                    if ($txt eq "0") {
                        # Socket is still open, but no response yet.
                        if (defined $timeout && !$timeout) {
                            # Don't try again with timeout 0
                            return 0;
                        }

                        select(undef,undef,undef, $backoff);
                        $backoff *= 1.25;
                        # Probe again after a little delay.
                        next;
                    }
                    if ($txt =~ /^(\d+)\.(.+)$/ and $1 == length($2)) {
                        my $encoded = $2;
                        $self->{Buffer_R} .= $self->dnsdecode($encoded);
                        return length($self->{Buffer_R});
                    }
                    warn "READ: Length mismatch in response [$txt]\n";
                    return undef;
                }
                warn "READ: Unimplimented response [$txt]\n";
                return undef;
            }
            warn "READ: Insane response [$txt] does not begin with sequence [$seqid]?\n";
            return undef;
        }
        # Already have seqid but the server suddenly can't respond correctly.
        # Just wait a while and try again?
        if ($backoff > 120) {
            warn "pending: [$name] Got bored waiting for broken responses to stop.\n";
            return undef;
        }
        select(undef,undef,undef, $backoff);
        $backoff *= 1.3;
    }

    return 0;
}

# tie $fh, IO::Socket::DNS,
#   PeerAddr => "$host:$ip",
#   Suffix   => $dns_suffix,
# Returns a blessed object tying the filehandle
sub TIEHANDLE {
    my $class = shift;
    my @args = @_;
    if (@args == 1) {
        @args = (PeerAddr => @args);
    }
    if (@args % 2) {
        croak "Odd number of arguments is not supported";
    }
    my $self = { @args };
    bless $self, $class;
    $self->{PeerAddr} ||= $self->{PeerHost}
        or croak "PeerAddr is required";
    if (!$self->{PeerPort} and $self->{PeerAddr} =~ s/:(\d+)$//) {
        $self->{PeerPort} = $1;
    }
    $self->{PeerAddr} =~ s/([^.])\.$/$1/;
    #$self->{IdleTimeout} ||= 60;
    $self->{Buffer_R} = "";
    $self->{Buffer_W} = "";
    $self->{Password} = $ENV{DNS_PASSWORD} || $self->{Password};
    my $suffix = $self->suffix
        or croak "Suffix must be specified";

    # Choose a fairly random ephemeral ID
    srand($count++ + $$ + $self->{PeerPort} + time());
    my $id = "";
    for (1..6) {
        $id .= $a32->[rand @$a32];
    }

    # Send SYN packet
    my $peer = lc("$self->{PeerAddr}");
    my $code = $self->encrypt($peer, $self->{PeerPort});
    my $name = "$peer.T$self->{PeerPort}.$id.$code.$suffix.";
    warn "DEBUG: querying for [$name]\n" if $self->{Verbose};
    require POSIX;
    if (my $txt = eval { $self->TXT_resolver->($name) } ) {
        warn "DEBUG: SYN=[$txt]\n" if $self->{Verbose};
        if ($txt =~ s/^$id\.(\d+)//) {
            my $status = $1;
            if ($status) {
                if ($status == $INVALID_PASS) {
                    require POSIX;
                    warn "IO::Socket::DNS Password incorrect.\n";
                    $! = POSIX::EACCES();
                }
                else {
                    $! = $status;
                }
                return;
            }
            # Connected perfectly. Need to grab magic sequence ID
            if ($txt =~ s/^\.(\w+)//) {
                # Found seqid!
                $self->{seqid} = $1;
            }
            else {
                # Missing seqid?
                $! = POSIX::EINVAL();
                return;
            }
            # Check for optional content
            if ($txt =~ /^\.(\d+)\.(.*)/) {
                my $len = $1;
                my $content = $2;
                if ($len == length $content) {
                    # Sanity check passed
                    $self->{Buffer_R} .= $self->dnsdecode($content);
                }
                else {
                    # Broken response?
                    $! = POSIX::ERANGE();
                    return;
                }
            }
            else {
                # Connected, but just no content response yet
            }
        }
        else {
            # Failed response sanity check?
            $! = POSIX::ESRCH();
            return;
        }
    }
    else {
        $! = POSIX::EHOSTDOWN();
        warn "query: $@";
        return;
        #EHOSTUNREACH
        #ENETDOWN
    }

    return $self;
}

sub sysread {
    my $self = _obj(shift());
    my (undef,$length,$offset) = @_;
    $length or croak "READ: length is required";
    $offset ||= 0;
    my $chunk = "";
    my $backoff = 0.5;
    while (1) {
        if ($length <= length $self->{Buffer_R}) {
            $chunk = substr($self->{Buffer_R}, 0, $length, "");
            last;
        }
        if (length $self->{Buffer_R}) {
            $chunk = $self->{Buffer_R};
            $self->{Buffer_R} = "";
            last;
        }
        my $seqid = $self->{seqid} or return 0;
        my $sniff = $self->pending(undef);
        if (!defined $sniff) {
            return undef;
        }
        if (!$sniff) {
            return 0;
        }
        die "IMPLEMENTATION BUG: Yes pending but no Buffer_R?" if !length $self->{Buffer_R};
    }

    $_[0] = "" if !defined $_[0];
    substr($_[0], $offset, 0, $chunk);
    return length($chunk);
}

sub readline {
    my $self = _obj(shift());
    my $EOL = $/ || "\n";
    my $buffer = "";
    while (1) {
        # Look for EOL
        if ($buffer =~ s/^(.*\Q$EOL\E)//) {
            # Found EOL. Return everything up to it.
            my $line = $1;
            # If there is anything left,
            # stuff it onto the beginning for the next read.
            $self->{Buffer_R} = "$buffer$self->{Buffer_R}";
            return $line;
        }
        if (!$self->READ($buffer, 8192, length $buffer)) {
            # Reached EOF or error
            if (defined $buffer and length $buffer) {
                # Just return the whole buffer even though there is no newline
                return $buffer;
            }
            else {
                # Probably EOF
                return undef;
            }
        }
    }
    # Impossible to get here
    return undef;
}

sub syswrite {
    my $self = _obj(shift());
    my $buffer = shift;
    my $bytes = shift;
    $bytes = length($buffer) if !defined $bytes;
    $self->{Buffer_W} .= substr($buffer, 0, $bytes);
    $self->{seqid} or return undef;
    my $Temp_Buffer_R = "";
    while ($self->{seqid} && length $self->{Buffer_W}) {
        if ($self->pending) {
            # Try to clear out Buffer_R so the new Buffer_W bytes can be processed
            $self->READ($Temp_Buffer_R, 8192, length $Temp_Buffer_R) or last;
        }
    }
    # Stuff read bytes back into the buffer
    $self->{Buffer_R} = "$Temp_Buffer_R$self->{Buffer_R}";
    return length($buffer);
}

sub close {
    my $self = _obj(shift);
    my $suffix = $self->suffix;
    if (my $seqid = delete $self->{seqid}) {
        my $name = "$seqid.x.$suffix";
        eval {
            require Net::DNS::Resolver;
            $self->resolver->bgsend($name, "TXT");
            1;
        } or eval {
            $self->TXT_resolver->($name);
        };
        return 1;
    }
    return 0;
}

sub READ     { shift()->sysread(@_) }
sub READLINE { shift()->readline(@_) }
sub WRITE    { shift()->syswrite(@_) }
sub CLOSE    { shift()->close(@_) }

sub UNTIE {
    my $self = shift;
    $self->CLOSE;
}

sub DESTROY {
    my $self = shift;
    $self->CLOSE;
}

1;
__END__

=head1 NAME

IO::Socket::DNS - IO::Socket like interface using DNS to access an IO::Socket::DNS::Server backend.

=head1 SYNOPSIS

  use IO::Socket::DNS;

  my $sock = new IO::Socket::DNS
    PeerAddr => $ip,
    PeerPort => $port,
    Suffix   => $dns_suffix,
    Password => $secret,
    Verbose  => 1,
      or die "Unable to connect to $ip:$port";

=head1 DESCRIPTION

I originally used this module for my own purposes and never
intended to show anyone, but there have been so many requests
that I've decided to release it to the public.

Have you ever been away from your home with your computer and
needed to use the Internet, but all you can find is a crippled
WiFi Access Point that doesn't give full Internet? When you
try to visit a website, it asks for an annoying login or asks
you to pay money or some other silly thing in order to be
able to use the Internet. However, usually if you actually try
a dig or nslookup, you'll notice that DNS is working perfectly
fine. If so, then this is exactly what you need!

It translates TCP connection packets into DNS queries. So now
you can finally reach that external SSH server you've been
needing to reach, even though your Internet connection is too
crippled to connect to it directly. Actually, you can connect
to any TCP server, such as a Web server or an SMTP server or
a Squid proxy or even a remote SOCKS server.
This client module IO::Socket::DNS communicates with the
server module IO::Socket::DNS::Server to tunnel the connection
for the client using only DNS queries as its transport.
The only thing that the Internet Service Provider will see is
a bunch of DNS queries.

Be aware that this is much slower than full Internet access.
This is only intended for proof of concept or emergency use.

=head1 SOCKS

SOCKS is a popular protocol used for proxying connections
which works very well in conjuction with this module.
Here is one simple way to utilize SOCKS using "dnsc",
which comes with this distribution.

=head2 1. Start SSH proxy

Note that you need an SSH account somewhere, say $USER@server.com

  dnsc --suffix=d.example.com --listen_port=2222 server.com:22

But if you have SSH access directly to d.example.com,
the DNS authority, it is recommended to connect to "127.0.0.1"
for better performance, i.e.:

  dnsc --suffix=d.example.com --listen_port=2222 127.0.0.1:22

=head2 2. Start SOCKS tunnelling server

The ssh option "-D" implements a tunnelled SOCKS server. Make
sure that $USER is a valid SSH account whatever destination you
chose in step 1, then connect:

  ssh -D127.0.0.1:1080 -p2222 $USER@127.0.0.1

Or if you have lots of other people on your client network that
don't like the crippled Internet and also want to use your SOCKS
server, then you'll need to know the IP address of your computer
and bind to that instead of the 127.0.0.1 default, i.e.:

  ssh -D192.168.0.101:1080 -p2222 $USER@127.0.0.1

=head2 3. Configure Network Settings on browser

On Firefox:

  => Options
  => Advanced
  => Network
  => Settings
  => [X] Manual proxy configuration
  => SOCKS Host: 192.168.0.101 Port: 1080 (or whatever IP:Port used for -D in step 2)
  => [OK]

Then surf away.

=head1 CONSTRUCTOR

The "new" constructor takes arguments in key-value pairs:

  PeerAddr     Remote host address      <hostname>[:<port>]
  PeerHost     Synonym for PeerAddr     <hostname>[:<port>]
  PeerPort     Remote port              <port>
  Suffix       Proxy DNS Suffix         <domain>
  Password     Access password          <password>
  Verbose      Used for debugging       <level>

If only one argument is passed, it is considered to be "PeerAddr".
The "PeerAddr" can be a hostname or IP-Address.

The "PeerPort" specification can also be embedded in the "PeerAddr" by preceding it with a ":".
The "PeerPort" must be in numeric form.

The "Password" setting is to prove to the server that you are authorized to use it.
The environment variable DNS_PASSWORD may also be used to define this setting.
Default is no password.

If "Verbose" is specified, additional diagnostic information will be sent to STDERR.

The "Suffix" argument must be a real domain name or subdomain
that is delegated to an IP running the IO::Socket::DNS::Server instance.
The environment variable DNS_SUFFIX may also be used to define this setting.
This is required.

=head1 EXAMPLES

  my $sock = IO::Socket::DNS->new(
    PeerAddr => "www.perl.org",
    PeerPort => 80,
    Verbose  => 1,
    Suffix   => "d.example.com",
  ) or die "connect: $!";

  $ENV{DNS_SUFFIX} = "d.example.com";
  my $sock = new IO::Socket::DNS "www.perl.org:80";


=head1 KNOWN ISSUES

It is still very slow. There are several optimizations that can be
done in order to improve the performance to make it faster, but none
of these have been implemented yet.

The Password setting is not implemented yet. So anyone can use your
server without your permission fairly easily and you could be blamed
for any malicious traffic tunnelled through it.

Sockets idle for more than 120 are automatically closed on the
server side. You have to keep probing to keep the connection alive.

Since DNS, for the most part, is UDP, which is a "connectionless"
protocol, IO::Socket::DNS does not implement the FILENO hook for
its TIEHANDLE, so things like IO::Select won't work as expected.

Only TCP protocol is supported at this time.

Patches are welcome, or if you have other ideas for improvements,
let me know.

=head1 DISCLAIMER

This software is provided AS-IS for proof of concept purposes only.
I can not be held liable for any loss or damages due to misuse or
illegal or unlawful violations in conjunction with this software.
Use at your own risk of punishing condemnation of all types of
ISPs and law enforcement everywhere.
If you do get in trouble, just DON'T BLAME ME!
And please don't abuse this too much or else hotspot admins
everywhere will wise up and start locking out all DNS queries!

=head1 SEE ALSO

Net::DNS, IO::Socket, dnsc, iodine

=head1 AUTHOR

Rob Brown, E<lt>bbb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Rob Brown

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
