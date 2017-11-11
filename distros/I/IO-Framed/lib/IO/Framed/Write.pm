package IO::Framed::Write;

use strict;
use warnings;

use IO::SigGuard ();

use IO::Framed::X ();

sub new {
    my ( $class, $out_fh ) = @_;

    my $self = {
        _out_fh => $out_fh,
        _writer => \&_write_now,
    };

    return bless $self, $class;
}

sub get_write_fh { return $_[0]->{'_out_fh'} }

sub disable_write_queue {
    if ( $_[0]->{'_write_queue'} && @{ $_[0]->{'_write_queue'} } ) {
        die 'Refuse to disable non-empty write queue!';
    }

    $_[0]->{'_writer'} = \&_write_now;
    return $_[0];
}

sub enable_write_queue {
    $_[0]->{'_write_queue'} ||= [];
    $_[0]->{'_writer'} = \&_enqueue_write;
    return $_[0];
}

sub write {
    $_[0]->{'_writer'}->(@_);
}

#======================================================================
#blocking
#======================================================================

sub _write_now {
    local $!;

    IO::SigGuard::syswrite( $_[0]->{'_out_fh'}, $_[1] ) or do {
        die IO::Framed::X->create('WriteError', $!);
    };

    $_[2]->() if $_[2];

    return;
}

#======================================================================
#non-blocking
#======================================================================

sub _enqueue_write {
    my $self = shift;

    push @{ $self->{'_write_queue'} }, \@_;

    return;
}

#----------------------------------------------------------------------

sub flush_write_queue {
    my ($self) = @_;

    while ( my $qi = $self->{'_write_queue'}[0] ) {
        return 0 if !$self->_write_now_then_callback( @$qi );

        shift @{ $self->{'_write_queue'} };
    }

    return 1;
}

sub get_write_queue_count {
    my ($self) = @_;

    return 0 + @{ $self->{'_write_queue'} };
}

sub forget_write_queue {
    my ($self) = @_;

    my $count = @{ $self->{'_write_queue'} };

    @{ $self->{'_write_queue'} } = ();

    return $count;
}

#----------------------------------------------------------------------

sub _write_now_then_callback {
    local $!;

    my $wrote = IO::SigGuard::syswrite( $_[0]->{'_out_fh'}, $_[1] ) || do {
        if ($! && !$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
            die IO::Framed::X->create('WriteError', $!);
        }

        return undef;
    };

    if ($wrote == length $_[1]) {
        $_[0]->{'_write_queue_partial'} = 0;
        $_[2]->() if $_[2];
        return 1;
    }

    #Trim the bytes that we did send.
    substr( $_[1], 0, $wrote ) = q<>;

    #This seems useful to track … ??
    $_[0]->{'_write_queue_partial'} = 1;

    return 0;
}

1;
