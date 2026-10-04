package Mail::DKIM2::HeaderParser;
use strict;
use warnings;

our $VERSION = '0.10';

# Thin base class for streaming message parsing.
# Replaces the deep Mail::DKIM::Common → Mail::DKIM::MessageParser
# inheritance chain with just what DKIM2 Signer/Verifier need.

use Carp;

# The constructor options a subclass accepts, as a list of CamelCase names.
# new() refuses anything else, so a misspelt option is an error at the call
# site and not a silently-ignored one.
sub known_options { return () }

sub new {
    my ($class, %args) = @_;
    my %known = map { $_ => 1 } $class->known_options;
    for my $k (sort keys %args) {
        croak "unknown option $k for $class" unless $known{$k};
    }
    my $self = bless \%args, $class;
    $self->init;
    return $self;
}

# tie *FH, 'Mail::DKIM2::Signer', %options;   -- constructs
# tie *FH, 'Mail::DKIM2::Signer', $signer;    -- wraps an existing object
sub TIEHANDLE {
    my ($class, @args) = @_;
    return $args[0] if @args == 1 && ref $args[0] && $args[0]->isa(__PACKAGE__);
    return $class->new(@args);
}

# One-shot: feed a whole message and finish. Takes the message as a string,
# a reference to one, a filehandle, or an Email::MIME. Line endings are
# normalised to CRLF, which is what every DKIM2 hash is defined over; PRINT
# itself never alters what it is given, since a streaming host has already
# got CRLF and may split a line ending across chunks.
sub load {
    my ($self, $input) = @_;
    my $text;
    if (ref $input eq 'SCALAR') {
        $text = $$input;
    }
    elsif (ref $input && eval { $input->can('as_string') }) {
        $text = $input->as_string;
    }
    elsif (ref $input eq 'GLOB' || ref \$input eq 'GLOB'
           || (ref $input && eval { $input->can('getline') })) {
        local $/;
        $text = readline($input);
    }
    elsif (ref $input) {
        croak "load: cannot read a message from a " . ref($input) . " reference";
    }
    else {
        $text = $input;
    }
    croak "load requires a message" unless defined $text;
    $text =~ s/\r?\n/\r\n/g;
    $self->PRINT($text);
    $self->CLOSE;
    return $self;
}

sub init {
    my $self = shift;
    $self->{_buf} = '';
    $self->{_in_header} = 1;
    $self->{headers} = [];
}

# Streaming interface: feed message data in chunks
sub PRINT {
    my $self = shift;
    return 1 if $self->{_stopped};
    # print FH LIST hands every item over; so does a direct PRINT($a, $b).
    my $data = @_ > 1 ? join('', map { $_ // '' } @_) : ($_[0] // '');
    $self->{_buf} .= $data;

    if ($self->{_in_header}) {
        # Look for end-of-headers (blank line), resuming where the last chunk's
        # search stopped: rescanning from the start each time costs the square
        # of the header size when they arrive in small pieces. Two bytes back,
        # in case the line ending was split across chunks.
        pos($self->{_buf}) = $self->{_header_scan} // 0;
        if ($self->{_buf} =~ /\n\r?\n/g) {
            my $end = pos($self->{_buf});
            my $header_block = substr($self->{_buf}, 0, $end, '');
            $header_block =~ s/\r?\n\z//;
            $self->_parse_headers($header_block);
            $self->{_in_header} = 0;
            $self->finish_header();
        }
        else {
            my $scanned = length($self->{_buf}) - 2;
            $self->{_header_scan} = $scanned > 0 ? $scanned : 0;
        }
    }
    # Body data accumulates in buffer until CLOSE
    return 1;
}

# The rest of the tied-handle output interface, so printf FH and syswrite FH
# feed the parser too.
sub PRINTF {
    my ($self, $fmt, @args) = @_;
    return $self->PRINT(sprintf($fmt, @args));
}

sub WRITE {
    my ($self, $buf, $len, $offset) = @_;
    $len    //= length($buf);
    $offset //= 0;
    $self->PRINT(substr($buf, $offset, $len));
    return $len;
}

sub CLOSE {
    my $self = shift;
    return 1 if $self->{_stopped};

    # If we never saw end-of-headers, parse what we have as headers
    if ($self->{_in_header}) {
        $self->_parse_headers($self->{_buf});
        $self->{_buf} = '';
        $self->{_in_header} = 0;
        $self->finish_header();
    }

    $self->finish_body() unless $self->{_stopped};
    return 1;
}

# A subclass that has reached its result from the headers alone calls this
# from finish_header: the rest of the message is discarded unread, and CLOSE
# does not call finish_body.
sub stop {
    my $self = shift;
    $self->{_stopped} = 1;
    $self->{_buf} = '';
    return;
}

sub stopped { return $_[0]->{_stopped} }

# Parse a block of header text into individual headers (handling continuation lines)
sub _parse_headers {
    my ($self, $block) = @_;

    # Split into lines, then recombine continuation lines
    my @lines = split /(?<=\n)/, $block;
    my $current = '';

    for my $line (@lines) {
        if ($line =~ /^\s/ && $current ne '') {
            # Continuation line: append to current header
            $current .= $line;
        } else {
            # New header — emit the previous one
            $self->_emit_header($current) if $current ne '';
            $current = $line;
        }
    }
    $self->_emit_header($current) if $current ne '';
}

sub _emit_header {
    my ($self, $raw) = @_;
    return unless $raw =~ /^([^\s:]+)\s*:\s*(.*)/s;
    my ($field_name, $contents) = ($1, $2);
    $contents =~ s/\r?\n$//s;

    push @{$self->{headers}}, $raw;
    $self->handle_header($field_name, $contents, $raw);
}

# Callbacks for subclasses to override
sub handle_header { }
sub finish_header { }
sub finish_body   { }

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::HeaderParser - Streaming message parser base for Signer and Verifier

=head1 SYNOPSIS

    # As a user of a Signer or Verifier:
    $obj->PRINT($chunk) for @chunks;    # CRLF line endings
    $obj->CLOSE;

    $obj->load($message);               # one shot; LF is normalised

    tie *FH, 'Mail::DKIM2::Verifier', SkipTimestampCheck => 1;
    print FH $message;
    close FH;
    my $verifier = tied *FH;

    # As a subclass:
    package My::Parser;
    use parent 'Mail::DKIM2::HeaderParser';
    sub known_options { qw(Thing) }
    sub handle_header { my ($self, $name, $value, $raw) = @_; ... }
    sub finish_header { my $self = shift; ... }
    sub finish_body   { my $self = shift; ... }

=head1 DESCRIPTION

Collects a message fed in pieces, splits it into header fields and body,
and calls the subclass at each stage. L<Mail::DKIM2::Signer> and
L<Mail::DKIM2::Verifier> are built on it; the conventions it implements are
described in L<Mail::DKIM2/CONVENTIONS>.

=head1 CONSTRUCTOR

=head2 new(%options)

Croaks on an option the class's C<known_options> does not list, then calls
C<init>.

=head2 TIEHANDLE

C<< tie *FH, $class, %options >> constructs an object; C<< tie *FH,
$class, $object >> uses an existing one. C<print FH>, C<printf FH>,
C<syswrite FH> and C<close FH> then call C<PRINT>, C<PRINTF>, C<WRITE> and
C<CLOSE>.

=head1 METHODS

=head2 PRINT(@bytes)

Feeds message data, in chunks of any size, with CRLF line endings exactly
as the message has them; several arguments are concatenated. When the blank line ending the headers has been
seen, the header fields are parsed and C<finish_header> is called. Body
data is kept until C<CLOSE> unless the subclass has called C<stop>.

=head2 CLOSE()

Ends the message. Parses the headers if no blank line was seen, then calls
C<finish_body> unless C<stop> was called.

=head2 load($input)

C<PRINT> and C<CLOSE> in one call. C<$input> is the message as a string,
a reference to one, a filehandle (read to the end), or an L<Email::MIME>;
any other reference croaks. Bare LF line endings are normalised to CRLF
first, since every DKIM2 hash is defined over CRLF. Returns the object.

=head2 stop()

For a subclass that has reached its result from the headers alone, called
from C<finish_header>: the rest of the message is discarded unread and
C<CLOSE> does not call C<finish_body>.

=head2 stopped()

True after C<stop>.

=head1 SUBCLASS INTERFACE

=head2 known_options()

The list of CamelCase option names C<new> accepts. Default none.

=head2 init()

Called by C<new> after the options are stored in the object hash. Sets up
the buffer and C<< $self->{headers} >>, the arrayref of raw header lines
in message order. A subclass that overrides it calls C<< $self->SUPER::init >>.

=head2 handle_header($name, $value, $raw)

Called for each header field: its name, its value without the trailing
line ending, and its complete raw text including any continuation lines.

=head2 finish_header()

Called once all header fields have been parsed.

=head2 finish_body()

Called from C<CLOSE>, with the body in C<< $self->{_buf} >>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
