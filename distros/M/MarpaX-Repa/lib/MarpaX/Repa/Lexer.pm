use 5.010;
use strict;
use warnings;

package MarpaX::Repa::Lexer;
our $VERSION = '0.01';

=head1 NAME

MarpaX::Repa::Lexer - simplify lexing for Marpa parser

=head1 DESCRIPTION

Most details are in L<MarpaX::Repa>.

=head1 METHODS

=head2 new

Returns a new lexer instance. Takes named arguments.

    my $lexer = MyLexer->new(
        tokens => {
            word => qr{\b\w+\b},
        },
        store => 'array',
        debug => 1,
    );

Possible arguments:

=over 4

=item tokens

Hash with names of terminals as keys and one of the
following as value:

=over 4

=item string

Just a string to match.

    'a token' => "matches this long string",

=item regular expression

A C<qr{}> compiled regexp.

    'a token' => qr{"[^"]+"},

Note that regexp MUST match at least one character. At this moment
look behind to look at chars before the current position is not
supported.

=item hash

With hash you can define token specific options. At this moment
'store' option only (see below). Use C<match> key to set what to
match (string or regular expression):

    'a token' => {
        match => "a string",
        store => 'hash',
    },

Per token options are:

=over 4

=item store

What to store (pass as value to Marpa's recognizer). The following variants
are supported:

=over 4

=item hash (default)

    { token => 'a token', value => 'a value' }

=item array

    [ 'a token', 'a value' ]

=item scalar

    'a value'

=item undef

undef is stored so later Repa's actions will skip it.

=item a callback

A function will be called with token name and reference to its value.
Should return a reference or undef that will be passed to recognizer.

=back

=item check

A callback that can check whether token is really match or not.

=back

=back

=item complete

If true then parse should complete in one go and consume whole input.

=item debug

If true then lexer prints debug log to STDERR.

=item min_buffer

Minimal size of the buffer (4*1024 by default).

=back

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref $proto || $proto;
    return $self->init;
}

=head2 init

Setups instance and returns C<$self>. No need to call, it's called
from the constructor.

=cut

sub init {
    my $self = shift;

    my $tokens = $self->{'tokens'};
    foreach my $token ( keys %$tokens ) {
        my ($match, @rest);
        if ( ref( $tokens->{ $token } ) eq 'HASH' ) {
            $match = $tokens->{ $token }{'match'};
            @rest = (@{ $tokens->{ $token } }{'store','check'});
        } else {
            $match = $tokens->{ $token };
        }
        $rest[0] ||= $self->{'store'} || 'hash';
        my $type =
            ref $match ? 'RE'
            : length $match == 1 ? 'CHAR'
            : 'STRING';
        $tokens->{ $token } = [ $type, $match, @rest ];
    }

    $self->{'min_buffer'} //= 4*1024;
    $self->{'buffer'} //= '';

    return $self;
}

=head2 recognize

Takes a recognizer and a file handle. Parses input. Dies on critical errors, but
not when parser lost its way. Returns recognizer that was passed.

=cut

sub recognize {
    my $self = shift;
    my $rec = shift;
    my $fh = shift;


    my $buffer = $self->buffer;
    my $buffer_can_grow = $self->grow_buffer( $fh );

    my $expected = $rec->terminals_expected;
    return $rec unless @$expected;

    while ( length $$buffer ) {
        say STDERR "Expect token(s): ". join(', ', map "'$_'", @$expected)
            if $self->{'debug'};

        say STDERR "Buffer start: ". $self->dump_buffer .'...'
            if $self->{'debug'};

        my $longest = 0;
        my @alternatives;
        my $first_char = substr $$buffer, 0, 1;
        foreach my $token ( @$expected ) {
            REDO:

            my ($matched, $match, $length);
            my ($type, $what, $how, $check) = @{ $self->{'tokens'}{ $token } || [] };

            unless ( $type ) {
                say STDERR "Unknown token: '$token'" if $self->{'debug'};
                next;
            }
            elsif ( $type eq 'RE' ) {
                if ( $$buffer =~ /^($what)/ ) {
                    ($matched, $match, $length) = (1, $1, length $1);
                    if ( $length == length $$buffer && $buffer_can_grow ) {
                        $buffer_can_grow = $self->grow_buffer( $fh );
                        goto REDO;
                    }
                }
            }
            elsif ( $type eq 'STRING' ) {
                $length = length $what;
                ($matched, $match) = (1, $what)
                    if $what eq substr $$buffer, 0, $length;
            }
            elsif ( $type eq 'CHAR' ) {
                ($matched, $match, $length) = (1, $first_char, 1)
                    if $what eq $first_char;
            }
            else {
                die "Unknown type $type";
            }

            unless ( $matched ) {
                say STDERR "No '$token' in ". $self->dump_buffer if $self->{'debug'};
                next;
            }

            unless ( $length ) {
                die "Token '$token' matched empty string. This is not supported.";
            }
            say STDERR "Token '$token' matched ". $self->dump_buffer( $length )
                if $self->{'debug'};

            if ( $check && !$check->( $self, $token, $match, $length ) ) {
                say STDERR "\tCheck failed for '$token', skipping"
                    if $self->{'debug'};
                next;
            }

            if ( $self->{longest_expected} ) {
                if ( $length > $longest ) {
                    say STDERR "New longest token of length $length" if $self->{'debug'};
                    @alternatives = (); $longest = $length;
                } elsif ( $length < $longest ) {
                    say STDERR "Skipping $token token as it's short" if $self->{'debug'};
                    next;
                }
            }
            push @alternatives, [$token, $how, $match, $length];
        }

        foreach my $e ( @alternatives ) {
            my ($token, $how, $match, $length) = @$e;
            say STDERR "Accepting $token of length $length" if $self->{'debug'};

            if ( ref $how ) {
                $match = $how->( $token, \"$match" );
            } elsif ( $how eq 'hash' ) {
                $match = \{ token => $token, value => $match };
            } elsif ( $how eq 'array' ) {
                $match = \[$token, $match];
            } elsif ( $how eq 'scalar' ) {
                $match = \"$match";
            } elsif ( $how eq 'undef' ) {
                $match = \undef;
            } else {
                die "Unknown store variant - '$how'";
            }

            $rec->alternative( $token, $match, $length );
        }

        my $skip = 0;
        while (1) {
            # XXX: we are done, no way to advance further, we would love this
            # to be improved in Marpa
            if ( $rec->current_earleme == $rec->thin->furthest_earleme ) {
                die "Failed to parse: parser reached furthest earleme, but buffer is not empty - '". $self->dump_buffer . "'"
                    if $self->{complete} && (length $$buffer || $buffer_can_grow);
                return $rec;
            }

            $skip++;
            local $@;
            if ( defined (my $events = eval { $rec->earleme_complete }) ) {
                if ( $events && $rec->exhausted ) {
                    substr $$buffer, 0, $skip, '';
                    die "Failed to parse: parser is exhausted, but buffer is not empty - '". $self->dump_buffer . "'"
                        if $self->{complete} && (length $$buffer || $buffer_can_grow);
                    return $rec;
                }
                $expected = $rec->terminals_expected;
                last if @$expected;
            } else {
                say STDERR "Failed to parse: $@" if $self->{'debug'};
                die "Failed to parse: $@" if $self->{complete};
                return $rec;
            }
        }
        substr $$buffer, 0, $skip, '';
        $buffer_can_grow = $self->grow_buffer( $fh )
            if $buffer_can_grow && $self->{'min_buffer'} > length $$buffer;

        say STDERR '' if $self->{'debug'};
    }
    return $rec;
}

=head2 buffer

Returns reference to the current buffer.

=cut

sub buffer { \$_[0]->{'buffer'} }

=head2 grow_buffer

Called when L</buffer> needs a re-fill with a file handle as argument.
Returns true if there is still data to come from the handle.

=cut

sub grow_buffer {
    my $self = shift;
    local $/ = $self->{'min_buffer'}? \($self->{'min_buffer'}*2) : undef;
    $self->{'buffer'} .= readline($_[0]) // return 0;
    return 1 && $self->{'min_buffer'};
}

=head2 dump_buffer

Returns first 20 chars of the buffer with everything besides ASCII encoded
with C<\x{####}>. Use argument to control size, zero to mean whole buffer.

=cut

sub dump_buffer {
    my $self = shift;
    my $show = shift // 20;
    my $str = $show? substr( $self->{'buffer'}, 0, $show ) : $self->{'buffer'};
    (my $res = $str) =~ s/([^\x20-\x7E])/'\\x{'. hex( ord $1 ) .'}' /ge;
    return $res;
}

1;
