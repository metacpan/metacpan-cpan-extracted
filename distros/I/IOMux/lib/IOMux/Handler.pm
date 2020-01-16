# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::Handler;
use vars '$VERSION';
$VERSION = '1.01';


use warnings;
use strict;

use Log::Report  'iomux';

use Scalar::Util     'weaken';
use Time::HiRes      'time';
use Socket;
use Fcntl;

my $start_time = time;


sub new(@)  {my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;
    return $self if $self->{IH_name}; # already initialized

    my $name = $self->{IH_name} = $args->{name} || "$self";
    if(my $fh = $self->{IH_fh} = $args->{fh})
    {   $self->{IH_fileno}   = $fh->fileno;
        $self->{IH_uses_ssl} = UNIVERSAL::isa($fh, 'IO::Socket::SSL');
    }
    $self;
}


sub open() {panic}

#-------------------------

sub name()   {shift->{IH_name}}
sub mux()    {shift->{IH_mux}}


sub fileno() {shift->{IH_fileno}}
sub fh()     {shift->{IH_fh}}
sub usesSSL(){shift->{IH_uses_ssl}}

#-----------------------

sub timeout(;$)
{   my $self  = shift;
    @_ or return $self->{IH_timeout};

    my $old   = $self->{IH_timeout};
    my $after = shift;
    my $when  = !$after      ? undef
      : $after > $start_time ? $after
      :                        ($after + time);

    $self->{IH_mux}->changeTimeout($self->{IH_fileno}, $old, $when);
    $self->{IH_timeout} = $when;
}


sub close(;$)
{   my ($self, $cb) = @_;
    if(my $fh = delete $self->{IH_fh})
    {   if(my $mux = $self->{IH_mux})
        {   $mux->remove($self->{IH_fileno});
        }
        $fh->close;
    }
    local $!;
    $cb->($self) if $cb;
}  

#-------------------------

sub muxInit($;$)
{   my ($self, $mux, $handler) = @_;

    $self->{IH_mux} = $mux;
    weaken($self->{IH_mux});

    my $fileno = $self->{IH_fileno};
    $mux->handler($fileno, $handler || $self);

    if(my $timeout = $self->{IH_timeout})
    {   $mux->changeTimeout($fileno, undef, $timeout);
    }

    trace "mux add #$fileno, $self->{IH_name}";
}


sub muxRemove()
{   my $self = shift;
    delete $self->{IH_mux};
#use Carp 'cluck';
#cluck "REMOVE";
    trace "mux remove #$self->{IH_fileno}, $self->{IH_name}";
}


sub muxTimeout()
{   my $self = shift;
    error __x"timeout set on {name} but not handled", name => $self->name;
}

#----------------------


#sub muxReadFlagged($)  { panic "no input expected on ". shift->name }


#sub muxExceptFlagged($)  { panic "exception arrived on ". shift->name }


#sub muxWriteFlagged($) { shift }  # simply ignore write offers


#-------------------------

sub show()
{   my $self = shift;
    my $name = $self->name;
    my $fh   = $self->fh
        or return "fileno=".$self->fileno." is closed; name=$name";

    my $mode = 'unknown';
    unless($^O eq 'Win32')
    {   my $flags = fcntl $fh, F_GETFL, 0       or fault "fcntl F_GETFL";
        $mode = ($flags & O_WRONLY) ? 'w'
              : ($flags & O_RDONLY) ? 'r'
              : ($flags & O_RDWR)   ? 'rw'
              :                       'p';
    }

    my @show = ("fileno=".$fh->fileno, "mode=$mode");
    if(my $sockopts  = getsockopt $fh, SOL_SOCKET, SO_TYPE)
    {   # socket
        my $type = unpack "i", $sockopts;
        my $kind = $type==SOCK_DGRAM ? 'UDP' : $type==SOCK_STREAM ? 'TCP'
          : 'unknown';
        push @show, "sock=$kind";
    }

    join ", ", @show, "name=$name";
}


sub fdset($$$$)
{   my $self = shift;
    $self->{IH_mux}->fdset($self->{IH_fileno}, @_);
}


sub extractSocket($)
{   my ($thing, $args) = @_;
    my $class    = ref $thing || $thing;

    my $socket   = delete $args->{socket};
    return $socket if $socket;

    my @sockopts = (Blocking => 0);
    push @sockopts, $_ => $args->{$_}
        for grep /^[A-Z]/, keys %$args;

    @sockopts
       or error __x"pass socket or provide parameters to create one for {pkg}"
          , pkg => $class;

    my $ssl  = delete $args->{use_ssl};

    # the extension will load these classes
    my $make = $ssl ? 'IO::Socket::SSL' : 'IO::Socket::INET';
    $socket  = $make->new(@sockopts)
        or fault __x"cannot create {pkg} socket", pkg => $class;

    $socket;
}

1;
