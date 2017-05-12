package IO::Stream::HTTP::Persistent;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v0.2.1';

use Scalar::Util qw( dualvar );
use Data::Alias 0.08;
use IO::Stream::const;

use constant HTTP_SENT      => 1<<16;
use constant HTTP_RECV      => 1<<17;

use constant HTTP_EREQINCOMPLETE => dualvar(-10000, 'incomplete HTTP request headers');
use constant HTTP_ERESINCOMPLETE => dualvar(-10001, 'incomplete HTTP response');


#
# Export constants.
#
# Usage: use IO::Stream::HTTP::Persistent qw( :ALL :DEFAULT :Event :Error HTTP_RECV ... )
#
my %TAGS = (
    Event   => [ qw( HTTP_SENT HTTP_RECV ) ],
    Error   => [ qw( HTTP_EREQINCOMPLETE HTTP_ERESINCOMPLETE ) ],
);
$TAGS{ALL} = $TAGS{DEFAULT} = [ map { @{$_} } values %TAGS ];
my %KNOWN = map { $_ => 1 } @{ $TAGS{ALL} };

sub import {
    my (undef, @p) = @_;
    if (!@p) {
        @p = (':DEFAULT');
    }
    @p = map { /\A:(\w+)\z/xms ? @{ $TAGS{$1} || [] } : $_ } @p;
    my $pkg = caller;
    no strict 'refs';
    for my $const (@p) {
        next if !$KNOWN{$const};
        *{"${pkg}::$const"} = \&{$const};
    }
    return;
}


sub new {
    my ($class) = @_;
    my $self = bless {
        out_buf     => q{},     # modified on: OUT
        out_pos     => undef,   # modified on: OUT
        out_bytes   => 0,       # modified on: OUT
        in_buf      => q{},     # modified on: IN
        in_bytes    => 0,       # modified on: IN
        ip          => undef,   # modified on: RESOLVED
        is_eof      => undef,   # modified on: EOF
        out_sizes   => [],      # modified on: HTTP_SENT
        in_sizes    => [],      # modified on: HTTP_RECV
        _out_len    => 0,       # current length of {out_buf}
                                #   used to detect how many bytes was added to
                                #   {out_buf} in write() and increase {_out_todo}
        _out_todo   => 0,       # size of incomplete request at end of {out_buf}
                                #   used to find complete requests appended to
                                #   {out_buf} and add their sizes to {_out_queue}
                                #   can be negative, if we detected size
                                #   of next request but it isn't appended to
                                #   {out_buf} completely yet
        _out_queue  => [],      # sizes of unsent complete requests in {out_buf}
                                #   will be moved to {out_sizes} after sending
        _out_sent   => 0,       # how many bytes of {_out_queue}[0] already sent
                                #   if it become >= {_out_queue}[0] then it's
                                #   time to move from {_out_queue} to {out_sizes}
        _out_broken => 0,       # if true, disable HTTP_SENT and {out_sizes} support
        _in_todo    => 0,       # size of incomplete response at end of {in_buf}
                                #   used to find complete responses appended to
                                #   {in_buf} and add their sizes to {in_sizes}
        _wait_eof   => 0,       # flag: response end expected on EOF
        _wait_length=> 0,       # expected response length
        _wait_chunk => 0,       # known partial response length before next
                                # chunk header (or end of response sign)
    }, $class;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    for (qw( out_buf out_pos in_buf ip is_eof )) {
        alias $self->{$_} = $self->{_master}->{$_};
    }
    $self->{_slave}->PREPARE($fh, $host, $port);
    return;
}

sub WRITE {
    my ($self) = @_;
    my $m = $self->{_master};

    my $l = length $self->{out_buf};
    $self->{_out_todo} += $l - $self->{_out_len};
    $self->{_out_len}   = $l;

    while (!$self->{_out_broken} && $self->{_out_todo} > 0) {
        pos $self->{out_buf} = $self->{_out_len} - $self->{_out_todo};
        if ($self->{out_buf} =~ /\G((?:[^\r\n]+\r?\n)+\r?\n)/xms) {
            my $h = $1;
            my $c_len = $h =~ /^Content-Length:\s*(\d+)\s*\n/ixms ? $1 : 0;
            my $size = length($h) + $c_len;
            push @{ $self->{_out_queue} }, $size;
            $self->{_out_todo} -= $size;
        }
        else {
            $self->{_out_broken} = 1;
            $m->EVENT(0, HTTP_EREQINCOMPLETE);
            last;
        }
    }

    $self->{_slave}->WRITE();
    return;
}

sub EVENT { ## no critic (ProhibitExcessComplexity)
    my ($self, $e, $err) = @_;
    my $m = $self->{_master};

    if ($e & OUT) {
        $self->{_out_len}   = length $self->{out_buf};

        $m->{out_bytes}    += $self->{out_bytes};
        $self->{_out_sent} += $self->{out_bytes};
        $self->{out_bytes}  = 0;

        while (@{ $self->{_out_queue} } && $self->{_out_sent} >= $self->{_out_queue}[0]) {
            $e |= HTTP_SENT;
            $self->{_out_sent} -= $self->{_out_queue}[0];
            push @{ $self->{out_sizes} }, shift @{ $self->{_out_queue} };
        }
    }

    if ($e & IN) {
        $m->{in_bytes}     += $self->{in_bytes};
        $self->{_in_todo}  += $self->{in_bytes};
        $self->{in_bytes}   = 0;
    }

    while ($self->{_in_todo} > 0) {
        if ($e & IN) {
            if (!$self->{_wait_eof} && !$self->{_wait_length} && !$self->{_wait_chunk}) {
                pos $self->{in_buf} = length($self->{in_buf}) - $self->{_in_todo};
                if ($self->{in_buf} =~ /\G((?:[^\r\n]+\r?\n)+\r?\n)/xms) {
                    my $h = $1;
                    if ($h =~ /^Content-Length:\s*(\d+)\s*\n/ixms) {
                        $self->{_wait_length} = length($h) + $1;
                    }
                    elsif ($h =~ /^Transfer-Encoding:\s*chunked\s*\n/ixms) {
                        $self->{_wait_chunk} = length $h;
                    }
                    else {
                        $self->{_wait_eof} = 1;
                    }
                }
            }
            while ($self->{_wait_chunk} && $self->{_in_todo} > $self->{_wait_chunk}) {
                pos $self->{in_buf} = length($self->{in_buf}) - $self->{_in_todo} + $self->{_wait_chunk};
                if ($self->{in_buf} =~ /\G((?:\r?\n)?([\dA-Fa-f]+)[ \t]*\r?\n)/xms) {
                    my $chunk = hex $2;
                    $self->{_wait_chunk} += length($1) + $chunk;
                  next if $chunk > 0;
                    $self->{_wait_length} = $self->{_wait_chunk};
                    $self->{_wait_chunk}  = 0;
                }
                last;
            }
        }
        if ($e & EOF) {
            if ($self->{_wait_eof}) {
                $self->{_wait_length} = $self->{_in_todo};
                $self->{_wait_eof} = 0;
            }
        }
        if ($self->{_wait_length} && $self->{_in_todo} >= $self->{_wait_length}) {
            $self->{_in_todo} -= $self->{_wait_length};
            push @{ $self->{in_sizes} }, $self->{_wait_length};
            $self->{_wait_length} = 0;
            $e |= HTTP_RECV;
            next;
        }
        last;
    }

    if ($e & EOF) {
        if ($self->{_in_todo}) {
            $err ||= HTTP_ERESINCOMPLETE;
        }
    }

    $m->EVENT($e, $err);
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

IO::Stream::HTTP::Persistent - HTTP persistent connections plugin


=head1 VERSION

This document describes IO::Stream::HTTP::Persistent version v0.2.1


=head1 SYNOPSIS

    use IO::Stream;
    use IO::Stream::HTTP::Persistent;

    IO::Stream->new({
        ...
        wait_for => EOF|HTTP_SENT|HTTP_RECV,
        cb => \&io,
        out_buf => join(q{}, @http_requests),
        ...
        plugin => [
            ...
            http    => IO::Stream::HTTP::Persistent->new(),
            ...
        ],
    });

    sub io {
        my ($io, $e, $err) = @_;
        my $http = $io->{plugin}{http};
        if ($e & HTTP_SENT) {
            printf "%d requests was sent\n", 0+@{ $http->{out_sizes} };
            $http->{out_sizes} = [];
        }
        if ($e & HTTP_RECV) {
            while (my $size = shift @{ $http->{in_sizes} }) {
                my $http_reply = substr $io->{in_buf}, 0, $size, q{};
                ...
            }
        }
        ...
    }

=head1 DESCRIPTION

This module is plugin for L<IO::Stream> which allow you to process
complete HTTP requests and responses read/written by this stream.
It's useful only for persistent HTTP connections (HTTP/1.0 with Keep-Alive
and HTTP/1.1).

On usual HTTP/1.0 non-persistent connections it's ease to detect sent HTTP
request using SENT event and received HTTP response using EOF event.
But on persistent connections that's become much more complicated: to
detect end of single received HTTP response (or boundaries between several
received responses) you have to parse HTTP protocol, and when HTTP/1.1
Pipelining is used it's not easy to find out how many complete requests
was already sent.

This module will parse HTTP protocol for sent and received data, and will
generate non-standard events HTTP_SENT and HTTP_RECV when one or more
complete HTTP requests will be sent or HTTP responses received.
It will provide you with list of sizes for each sent request and received
response, which make it ease to find how many requests was sent or get
separate responses from {in_buf}.


=head1 EXPORTS

This modules doesn't export any functions/methods/variables, but it exports
some constants. There two groups of constants: events and errors
(which can be imported using tags ':Event' and ':Error').
By default all constants are exported.

Events:

    HTTP_SENT HTTP_RECV

Errors:

    HTTP_EREQINCOMPLETE HTTP_ERESINCOMPLETE

Errors are similar to $! - they're dualvars, having both textual and numeric
values.


=head1 INTERFACE 

=head2 new

    $plugin = IO::Stream::HTTP::Persistent->new();

Create and return new IO::Stream plugin object.


=head1 PUBLIC FIELDS

=over

=item in_sizes =[]

=item out_sizes =[]

Size of each complete sent HTTP request or received HTTP response
will be pushed into these fields.

You can remove elements from these arrays if you need, but you should
keep these fields in ARRAYREF format.

=back


=head1 EVENTS

=over

=item HTTP_SENT

=item HTTP_RECV

These non-standard events will be generated when one or more complete HTTP
requests will be sent or one or more HTTP responses will be received.
Their sizes will be push()ed into fields {out_sizes} and {in_sizes} before
generating events.

Instead of using these events you can use standard IN and OUT events and
check is new items was added to {out_sizes} and {in_sizes}.

=back


=head1 ERRORS

=over

=item HTTP_EREQINCOMPLETE

All HTTP headers of one request MUST be appended to {out_buf} using
single $io->write(), otherwise you'll get HTTP_EREQINCOMPLETE.
It's safe to add request body after that using any amount of $io->write().

You can safely continue I/O after receiving HTTP_EREQINCOMPLETE, but after
that error you'll not get HTTP_SENT event and {out_sizes} won't be updated
anymore.

=item HTTP_ERESINCOMPLETE

Unexpected EOF happens while receiving HTTP response.

=back


=head1 LIMITATIONS

=over

=item

This plugin usually should be first (top) plugin in IO::Stream object's
plugin chain, because if upper plugins will somehow modify {in_buf} or
{out_buf} then values in {in_sizes} and {out_sizes} may become wrong.

=item

{out_buf} MUST NOT be modified in any way except by appending new data.

=item

Partial HTTP response in {in_buf} MUST NOT be modified.
It's safe to cut from start of {in_buf} complete HTTP responses.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-IO-Stream-HTTP-Persistent/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-IO-Stream-HTTP-Persistent>

    git clone https://github.com/powerman/perl-IO-Stream-HTTP-Persistent.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=IO-Stream-HTTP-Persistent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/IO-Stream-HTTP-Persistent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Stream-HTTP-Persistent>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=IO-Stream-HTTP-Persistent>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/IO-Stream-HTTP-Persistent>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
