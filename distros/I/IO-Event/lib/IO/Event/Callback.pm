
package IO::Event::Callback;

# ABSTRACT: A closure based API for IO::Event
our $VERSION = '0.814'; # VERSION

use strict;
use warnings;

use IO::Event;

our @handlers;
BEGIN {
    @handlers = qw(input connection read_ready werror eof output
        outputdone connected connect_failed died timer exception
        outputoverflow);
}

sub new
{
    my ($pkg, $filehandle, %h) = @_;

    my $ro = $h{read_only};
    my $wo = $h{write_only};
    delete $h{read_only};
    delete $h{write_only};

    my $self = handler($pkg, %h);

    return IO::Event->new($filehandle, $self, read_only => $ro, write_only => $wo);
}

sub ie_input        { $_[0]->{'ie_input'}->(@_)     };
sub ie_connection   { $_[0]->{'ie_connection'}->(@_)    };
sub ie_read_ready   { $_[0]->{'ie_read_ready'}->(@_)    };
sub ie_werror       { $_[0]->{'ie_werror'}->(@_)        };
sub ie_eof      { $_[0]->{'ie_eof'}->(@_)       };
sub ie_output       { $_[0]->{'ie_output'}->(@_)        };
sub ie_outputdone   { $_[0]->{'ie_outputdone'}->(@_)    };
sub ie_connected    { $_[0]->{'ie_connected'}->(@_)     };
sub ie_connect_failed   { $_[0]->{'ie_connect_failed'}->(@_)    };
sub ie_died     { $_[0]->{'ie_died'}->(@_)      };
sub ie_timer        { $_[0]->{'ie_timer'}->(@_)     };
sub ie_exception    { $_[0]->{'ie_exception'}->(@_)     };
sub ie_outputoverflow   { $_[0]->{'ie_outputoverflow'}->(@_)    };

sub handler
{
    my ($pkg, %h) = @_;

    my $self = bless {}, $pkg;

    for my $h (@handlers) {
        my $key =
            exists($h{$h})      ? $h        :
            exists($h{"ie_$h"}) ? "ie_$h"   : undef;
        if ($key) {
            $self->{"ie_$h"} = $h{$key};
            delete $h{$key};
        } else {
            $self->{"ie_$h"} = sub {};
        }
    }
    my @k = keys %h;
    die "unexpected parameters: @k" if @k;
    return $self;
}

sub sock2handler
{
    my ($pkg, $sref) = @_;
    my %h;
    for my $h (@handlers) {
        next unless exists $sref->{$h};
        my $key =
            exists($sref->{$h})     ? $h        :
            exists($sref->{"ie_$h"})    ? "ie_$h"   : next;
        $h{$h} = $sref->{$key};
        delete $sref->{$key};
    }
    my $handler = handler($pkg,%h);
}

package IO::Event::INET::Callback;

use strict;
use warnings;

sub new
{
    my ($pkg, %sock) = @_;
    my $handler = IO::Event::Callback->sock2handler(\%sock);
    return IO::Event::INET->new(%sock, Handler => $handler);
}

package IO::Event::UNIX::Callback;

use strict;
use warnings;

sub new
{
    my ($pkg, %sock) = @_;
    my $handler = IO::Event::Callback->sock2handler(\%sock);
    return IO::Event::UNIX->new(%sock, Handler => $handler);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Event::Callback - A closure based API for IO::Event

=head1 VERSION

version 0.814

=head1 SYNOPSIS

 use IO::Event::Callback;

 IO::Event::Callback->new($filehanle, %callbacks);

 use IO::Event::INET::Callback;

 IO::Event::INET::Callback->new(%socket_info, %callbacks);

 use IO::Event::UNIX::Callback;

 IO::Event::UNIX::Callback->new(%socket_info, %callbacks);

=head1 DESCRIPTION

IO::Event::Callback is a wrapper around L<IO::Event>.  It
provides an alternative interface to using L<IO::Event>.

Instead of defining a class with methods like "ie_input", you
provide the callbacks as code references when you create
the object.

The keys for the callbacks are the same as the callbacks
for L<IO::Event> with the C<ie_> prefix removed.

=head1 CONSTRUCTORS

=head2 new

 my $ioe = IO::Event::Callback->new($filehandle, %callbacks);

Create an L<IO::Event> object for C<$filehandle> whose handler
invokes the given callbacks.  The keys of C<%callbacks> are the
L<IO::Event> handler names, with or without the C<ie_> prefix
(for example C<input> or C<ie_input>).  The C<read_only> and
C<write_only> options are passed through to L<IO::Event>.

=head1 EXAMPLE

 use IO::Event::Callback;

 my $remote = IO::Event::Callback::INET->new(
    peeraddr    => '10.20.10.3',
    peerport    => '23',
    input       => sub {
        # handle input
    },
    werror      => sub {
        # handdle error
    },
    eof     => sub {
        # handle end-of-file
    },
 );

=head1 SEE ALSO

See the source for L<RPC::ToWorker> for an example use of IO::Event::Callback.

=head1 AUTHORS

=over 4

=item *

David Muir Sharnoff <cpan@dave.sharnoff.org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2026 by David Muir Sharnoff <muir@idiom.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
