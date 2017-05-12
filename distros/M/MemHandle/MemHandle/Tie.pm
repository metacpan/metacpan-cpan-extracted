package MemHandle::Tie;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use IO::Seekable;

require Exporter;
use 5.000;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.06';


# Preloaded methods go here.
sub TIEHANDLE {
    my( $class, $mem ) = @_;
    $class = ref( $class ) || $class || 'MemHandle::Tie';
    my $self = {mem => $mem,
		pos => length($mem)};

    bless( $self, $class );
}

sub WRITE {
    my( $self, $buf, $len, $offset ) = @_;

    #$self->{mem} .= substr( $buf, $len, $offset );
    substr( $self->{mem}, $self->{pos}, $len ) = substr( $buf, $len, $offset );
    $self->{pos} += $len;

    $len;
}

sub READLINE {
    my $self = shift;

    if ( $self->{pos} >= length( $self->{mem} ) ) {
	return undef;
    }
    elsif ( wantarray() ) {
	my @lines = split( $/, substr( $self->{mem}, $self->{pos} ) );
	$self->{pos} = length( $self->{mem} );
	return map("$_$/",@lines);
    }
    else {
	my $i = index( substr( $self->{mem}, $self->{pos} ), $/, $self->{pos} );
	my $line;

	if ( $i != $[ - 1 ) {
	    $i++; # can't go off the deep end or $i would be $[ - 1
	    $line = substr( $self->{mem}, $self->{pos}, $i - $self->{pos} );
	    $self->{pos} = $i
	}
	else {
	    $line = substr( $self->{mem}, $self->{pos} );
	    $self->{pos} = length( $self->{mem} );
	}

	return $line;
    }
}

sub READ {
    my $self = shift;
    local *MemHandle::Tie::buf = \shift;
    my( $len, $offset ) = @_;
    my $leftlen = length( $self->{mem} ) - $self->{pos};
    if ( $len > $leftlen ) {
	$len = $leftlen;
    }
    substr( $MemHandle::Tie::buf, $offset, $len ) = substr( $self->{mem}, $self->{pos}, $len );
    $self->{pos} += $len;
    $len;
}

sub GETC {
    my $self = shift;
    if ( $self->{pos} < length( $self->{mem} ) ) {
	my $char = substr( $self->{mem}, $self->{pos}, 1 );
	$self->{pos}++;
	return $char;
    }
    return undef;
}

sub PRINT {
    my $self = shift;

    my $lines = join('', @_);
    my $len = length( $lines );
    substr( $self->{mem}, $self->{pos}, $len ) = $lines;
    $self->{pos} += $len;

    1;
}

sub PRINTF {
    my $self = shift;

    my $str = sprintf( shift, @_ );
    my $len = length( $str );
    substr( $self->{mem}, $self->{pos}, $len ) = $str;
    $self->{pos} += $len;

    1;
}

sub CLOSE {
    my $self = shift;
    untie $self;
    $self;
}

sub SEEK {
    my( $self, $pos, $whence ) = @_;

    if ( $whence == SEEK_SET ) {
    }
    elsif ( $whence == SEEK_CUR ) {
	$pos += $self->{$pos};
    }
    elsif ( $whence == SEEK_END ) {
	$pos += length( $self->{mem} );
    }
    else {
	return 0;
    }

    if ( $pos <= length( $self->{mem} ) ) {
	$self->{pos} = $pos;
	return 1;
    }

    return 0;
}

sub TELL {
    my( $self ) = @_;
    $self->{pos};
}

sub mem {
    my( $self, $mem ) = @_;

    if ( defined $mem ) {
	$self->{mem} = $mem;
	$self->{pos} = length( $mem );
    }

    $self->{mem};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

MemHandle::Tie - The package which ties the MemHandle to memory.

=head1 SYNOPSIS

=head1 DESCRIPTION

This should not be used except by MemHandle.  It provides functions
for tie-ing a FILEHANDLE.  See L<perltie/"Tying FileHandles"> for
more detail.

=head1 AUTHOR

"Sheridan C. Rawlins" <scr14@cornell.edu>

=head1 SEE ALSO

L<perl>.
L<perlfunc>.
L<perltie/"Tying FileHandles">.
perldoc MemHandle.

=cut
