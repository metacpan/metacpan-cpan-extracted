package IO::Handle::Prototype;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp ();

use parent qw(IO::Handle::Util::Overloading);

sub new {
    my ( $class, @args ) = @_;

    my $cb = @args == 1 ? $args[0] : {@args};

    bless {
        cb => $cb,
    }, $class;
}

sub _cb {
    my $self = shift;
    my $name = shift;

    if ( my $cb = $self->{cb}{$name} ) {
        return $self->$cb(@_);
    } else {
        Carp::croak("No implementation of '$name' provided for $self");
    }
}

sub open { shift->_cb(open => @_) }

sub getline { shift->_cb(getline => @_) }
sub getlines { shift->_cb(getlines => @_) }
sub read { shift->_cb(read => @_) }
sub sysread { shift->_cb(sysread => @_) }
sub getc { shift->_cb(getc => @_) }
sub ungetc { shift->_cb(ungetc => @_) }

sub say { shift->_cb(say => @_) }
sub print { shift->_cb(print => @_) }
sub printf { shift->_cb(printf => @_) }

sub format_write { shift->_cb(format_write => @_) }
sub write { shift->_cb(write => @_) }
sub syswrite { shift->_cb(syswrite => @_) }

sub ioctl { shift->_cb(ioctl => @_) }
sub fcntl { shift->_cb(fcntl => @_) }

sub truncate { shift->_cb(truncate => @_) }

sub stat { shift->_cb(stat => @_) }
sub fileno { shift->_cb(fileno => @_) }

sub eof { shift->_cb(eof => @_) }

sub close { shift->_cb(close => @_) }

__PACKAGE__

# ex: set sw=4 et:

__END__

=pod

=head1 NAME

IO::Handle::Prototype - base class for callback based handles.

=head1 SYNOPSIS

    my $fh = IO::Handle::Prototype->new(
        getline => sub {
            my $fh = shift;

            ...
        },
    );

=head1 DESCRIPTION

You probably want L<IO::Handle::Prototype::Fallback> instead.

=cut
