package IO::Handle::Iterator;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp ();

use parent qw(IO::Handle::Prototype);

# error, clearerr, new_from_fd, fdopen

sub new {
    my ( $class, $cb ) = @_;

    bless {
        cb => $cb,
    }, $class;
}

sub getline { shift->_cb }

sub _cb {
    my $self = shift;

    if ( my $cb = $self->{cb} ) {
        if ( defined(my $next = $cb->()) ) {
            return $next;
        } else {
            $self->close;
        }
    }

    return;
}

sub _rebless_and {
    my $self = shift;
    my $method = shift;

    bless $self, "IO::Handle::Iterator::Buffered";

    $self->$method(@_);
}

sub read    { shift->_rebless_and( read    => @_ ) }
sub sysread { shift->_rebless_and( sysread => @_ ) }
sub getc    { shift->_rebless_and( getc    => @_ ) }
sub ungetc  { shift->_rebless_and( ungetc  => @_ ) }

sub open         { Carp::croak("Can't open an iterator") }
sub print        { Carp::croak("Can't print to iterator") }
sub printflush   { Carp::croak("Can't print to iterator") }
sub printf       { Carp::croak("Can't print to iterator") }
sub say          { Carp::croak("Can't print to iterator") }
sub write        { Carp::croak("Can't write to iterator") }
sub syswrite     { Carp::croak("Can't write to iterator") }
sub format_write { Carp::croak("Can't write to iterator") }
sub ioctl        { Carp::croak("Can't ioctl on iterator") }
sub fcntl        { Carp::croak("Can't fcntl on iterator") }
sub truncate     { Carp::croak("Can't truncate iterator") }
sub sync         { Carp::croak("Can't sync an iterator") }
sub flush        { Carp::croak("Can't flush an iterator") }

sub autoflush { 1 }

sub opened { 1 }

sub blocking {
    my ( $self, @args ) = @_;

    Carp::croak("Can't set blocking mode on iterator") if @args;

    return 1;
}

sub stat { return undef }
sub fileno { return undef }

sub close { delete $_[0]{cb} }
sub eof { not exists $_[0]{cb} }

sub getlines {
    my $self = shift;

    my @accum;
    
    while ( defined(my $next = $self->getline) ) {
        push @accum, $next;
    }

    return @accum;
}

package IO::Handle::Iterator::Buffered; # FIXME IO::Handle::BufferMixin?
use parent qw(IO::Handle::Iterator);

no warnings 'uninitialized';

sub eof {
    my $self = shift;

    length($self->{buf}) == 0
        and
    $self->SUPER::eof;
}

sub getc {
    shift->read(my $c, 1);
    return $c;
}

sub ungetc {
    my ( $self, $ord ) = @_;
    substr($self->{buf}, 0, 0, chr($ord)); # yuck
    return;
}

sub sysread { shift->read(@_) }

sub read {
    my ( $self, undef, $length, $offset ) = @_;

    return 0 if $self->eof;

    if ( $offset and length($_[1]) < $offset ) {
        $_[1] .= "\0" x ( $offset - length($_[1]) );
    }

    while (length($self->{buf}) < $length) {
        if ( defined(my $next = $self->_cb) ) {
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
}

sub getline {
    my $self = shift;

    my $line = delete $self->{buf};

    bless $self, 'IO::Handle::Iterator';

    return $line;
}

__PACKAGE__

# ex: set sw=4 et:

__END__

=head1 NAME

IO::Handle::Iterator - Iterator based read handle

=head1 SYNOPSIS

    IO::Handle::Iterator->new(sub {
        return $next_line; # or undef on eof
    });

=head1 DESCRIPTION

This class lets you define a read handle with a few fallback methods (like
C<read>) using a single callback that behaves like C<getline>.

This is similar but much simpler than:

    IO::Handle::Prototype::Fallback->new(
        __read => sub { ... },
    );

The reason being that the L<IO::Handle::Prototype::Fallback> implementation
will try its very best to behave correctly (i.e. respect the value of C<$/>),
whereas this implementation assumes it's fine to return things that aren't
exactly lines from C<getline>, so the values are just passed through.

=head1 READ BUFFERING

When a method that requires buffering is invoked the handle is reblessed to a
subclass which handles buffering.

Calling C<getline> again on this object will return the value of the buffer and
return to the normal iterator class.

