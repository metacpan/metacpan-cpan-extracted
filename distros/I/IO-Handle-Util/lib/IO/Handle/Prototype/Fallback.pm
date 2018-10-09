package IO::Handle::Prototype::Fallback;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp ();

use parent qw(IO::Handle::Prototype);

sub new {
    my ( $class, @args ) = @_;

    $class->SUPER::new(
        $class->_process_callbacks(@args),
    );
}

sub __write { shift->_cb(__write => @_) }
sub __read  { shift->_cb(__read => @_)  }

sub _process_callbacks {
    my ( $class, %user_cb ) = @_;

    if ( keys %user_cb == 1 ) {
        # these callbacks require wrapping of the user's callback to add
        # buffering, so we short circuit the entire process
        foreach my $fallback (qw(__read read getline)) {
            if ( my $cb = $user_cb{$fallback} ) {
                my $method = "_default_${fallback}_callbacks";

                return $class->_process_callbacks(
                    $class->$method($cb),
                );
            }
        }
    }

    my @fallbacks = $class->_base_callbacks;

    # additional fallbacks based on explicitly provided callbacks

    foreach my $fallback (qw(__write print write syswrite)) {
        if ( exists $user_cb{$fallback} ) {
            push @fallbacks, $class->_default_write_callbacks($fallback);
            last;
        }
    }

    if ( exists $user_cb{getline} ) {
        push @fallbacks, $class->_simple_getline_callbacks;
    }

    if ( exists $user_cb{read} ) {
        push @fallbacks, $class->_simple_read_callbacks;
    }

    # merge everything
    my %cb = (
        @fallbacks,
        %user_cb,
    );

    return \%cb;
}

sub _base_callbacks {
    my $class = shift;

    return (
        fileno => sub { undef },
        stat => sub { undef },
        opened => sub { 1 },
        blocking => sub {
            my ( $self, @args ) = @_;

            Carp::croak("Can't set blocking mode on iterator") if @args;

            return 1;
        },
    );
}

sub _make_read_callbacks {
    my ( $class, $read ) = @_;

    no warnings 'uninitialized';

    return (
        # these fallbacks must wrap the underlying reading mechanism
        __read => sub {
            my $self = shift;
            if ( exists $self->{buf} ) {
                return delete $self->{buf};
            } else {
                my $ret = $self->$read;

                unless ( defined $ret ) {
                    $self->{eof}++;
                }

                return $ret;
            }
        },
        getline => sub {
            my $self = shift;

            return undef if $self->{eof};

            if ( ref $/ ) {
                $self->read(my $ret, ${$/});
                return $ret;
            } elsif ( defined $/ ) {
                getline: {
                    if ( defined $self->{buf} and (my $off = index($self->{buf}, $/)) > -1 ) {
                        return substr($self->{buf}, 0, $off + length($/), '');
                    } else {
                        if ( defined( my $chunk = $self->$read ) ) {
                            $self->{buf} .= $chunk;
                            redo getline;
                        } else {
                            $self->{eof}++;

                            if ( length( my $buf = delete $self->{buf} ) ) {
                                return $buf;
                            } else {
                                return undef;
                            }
                        }
                    }
                }
            } else {
                my $ret = delete $self->{buf};

                while ( defined( my $chunk = $self->$read ) ) {
                    $ret .= $chunk;
                }

                $self->{eof}++;

                return $ret;
            }
        },
        read => sub {
            my ( $self, undef, $length, $offset ) = @_;

            return 0 if $self->{eof};

            if ( $offset and length($_[1]) < $offset ) {
                $_[1] .= "\0" x ( $offset - length($_[1]) );
            }

            while (length($self->{buf}) < $length) {
                if ( defined(my $next = $self->$read) ) {
                    $self->{buf} .= $next;
                } else {
                    # data ended but still under $length, return all that remains and
                    # empty the buffer
                    my $ret = length($self->{buf});

                    if ( $offset ) {
                        substr($_[1], $offset) = delete $self->{buf};
                    } else {
                        $_[1] = delete $self->{buf};
                    }

                    $self->{eof}++;
                    return $ret;
                }
            }

            my $read;
            if ( $length > length($self->{buf}) ) {
                $read = delete $self->{buf};
            } else {
                $read = substr($self->{buf}, 0, $length, '');
            }

            if ( $offset ) {
                substr($_[1], $offset) = $read;
            } else {
                $_[1] = $read;
            }

            return length($read);
        },
        eof => sub {
            my $self = shift;
            $self->{eof};
        },
        ungetc => sub {
            my ( $self, $ord ) = @_;

            substr( $self->{buf}, 0, 0, chr($ord) );

            return;
        },
    );
}

sub _default___read_callbacks {
    my ( $class, $read ) = @_;

    $class->_make_read_callbacks($read);
}

sub _default_read_callbacks {
    my ( $class, $read ) = @_;

    $class->_make_read_callbacks(sub {
        my $self = shift;

        if ( $self->$read(my $buf, ref $/ ? ${ $/ } : 4096) ) {
            return $buf;
        } else {
            return undef;
        }
    });
}

sub _default_getline_callbacks {
    my ( $class, $getline ) = @_;

    $class->_make_read_callbacks(sub {
        local $/ = ref $/ ? $/ : \4096;
        $_[0]->$getline;
    });
}

sub _simple_read_callbacks {
    my $class = shift;

    return (
        # these are generic fallbacks defined in terms of the wrapping ones
        sysread => sub {
            shift->read(@_);
        },
        getc => sub {
            my $self = shift;

            if ( $self->read(my $str, 1) ) {
                return $str;
            } else {
                return undef;
            }
        },
    );
}

sub _simple_getline_callbacks {
    my $class = shift;

    return (
        getlines => sub {
            my $self = shift;

            my @accum;

            while ( defined(my $next = $self->getline) ) {
                push @accum, $next;
            }

            return @accum;
        }
    );
}

sub _default_write_callbacks {
    my ( $class, $canonical ) = @_;

    return (
        autoflush => sub { 1 },
        sync      => sub { },
        flush     => sub { },

        # these are defined in terms of a canonical print method, either write,
        # syswrite or print
        __write => sub {
            my ( $self, $str ) = @_;
            local $\;
            local $,;
            $self->$canonical($str);
        },
        print => sub {
            my $self = shift;
            my $ofs = defined $, ? $, : '';
            my $ors = defined $\ ? $\ : '';
            $self->__write( join($ofs, @_) . $ors );
        },

        (map { $_ => sub {
            my ( $self, $str, $len, $offset ) = @_;
            $len = length($str) unless defined $len;
            $offset ||= 0;
            $self->__write(substr($str, $offset, $len));
        } } qw(write syswrite)),

        # wrappers for print
        printf => sub {
            my ( $self, $f, @args ) = @_;
            $self->print(sprintf $f, @args);
        },
        say => sub {
            local $\ = "\n";
            shift->print(@_);
        },
        printflush => sub {
            my $self = shift;
            my $autoflush = $self->autoflush;
            my $ret = $self->print(@_);
            $self->autoflush($autoflush);
            return $ret;
        }
    );
}

__PACKAGE__

# ex: set sw=4 et:

__END__

=pod

=head1 NAME

IO::Handle::Prototype::Fallback - Create L<IO::Handle> like objects using a set
of callbacks.

=head1 SYNOPSIS

    my $fh = IO::Handle::Prototype::Fallback->new(
        getline => sub {
            my $fh = shift;

            ...
        },
    );

=head1 DESCRIPTION

This class provides a way to define a filehandle based on callbacks.

Fallback implementations are provided to the extent possible based on the
provided callbacks, for both writing and reading.

=head1 SPECIAL CALLBACKS

This class provides two additional methods on top of L<IO::Handle>, designed to
let you implement things with a minimal amount of baggage.

The fallback methods are all best implemented using these, though these can be
implemented in terms of Perl's standard methods too.

However, to provide the most consistent semantics, it's better to do this:

    IO::Handle::Prototype::Fallback->new(
        __read => sub {
            shift @array;
        },
    );

Than this:

    IO::Handle::Prototype::Fallback->new(
        getline => sub {
            shift @array;
        },
    );

Because the fallback implementation of C<getline> implements all of the extra
crap you'd need to handle to have a fully featured implementation.

=over 4

=item __read

Return a chunk of data of any size (could use C<$/> or not, it depends on you,
unlike C<getline> which probably I<should> respect the value of C<$/>).

This avoids the annoying C<substr> stuff you need to do with C<read>.

=item __write $string

Write out a string.

This is like a simplified C<print>, which can disregard C<$,> and C<$\> as well
as multiple argument forms, and does not have the extra C<substr> annoyance of
C<write> or C<syswrite>.

=back

=head1 WRAPPING

If you provide a B<single> reading related callback (C<__read>, C<getline> or
C<read>) then your callback will be used to implement all of the other reading
primitives using a string buffer.

These implementations handle C<$/> in all forms (C<undef>, ref to number and
string), all the funny calling conventions for C<read>, etc.

=head1 FALLBACKS

Any callback that can be defined purely in terms of other callbacks in a way
will be added. For instance C<getc> can be implemented in terms of C<read>,
C<say> can be implemented in terms of C<print>, C<print> can be implemented in
terms of C<write>, C<write> can be implemented in terms of C<print>, etc.

None of these require special wrapping and will always be added if their
dependencies are present.

=head1 GLOB OVERLOADING

When overloaded as a glob a tied handle will be returned. This allows you to
use the handle in Perl's IO builtins. For instance:

    my $line = <$fh>

will not call the C<getline> method natively, but the tied interface arranges
for that to happen.

=cut
