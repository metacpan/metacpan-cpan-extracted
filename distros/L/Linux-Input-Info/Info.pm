package Linux::Input::Info;

use strict;
require DynaLoader;
require Exporter;

our @ISA     = qw(Exporter DynaLoader);
our $VERSION = '0.2';

use constant EV_SYN       => 0x00;
use constant EV_KEY       => 0x01;
use constant EV_REL       => 0x02;
use constant EV_ABS       => 0x03;
use constant EV_MSC       => 0x04;
use constant EV_LED       => 0x11;
use constant EV_SND       => 0x12;
use constant EV_REP       => 0x14;
use constant EV_FF        => 0x15;
use constant EV_PWR       => 0x16;
use constant EV_FF_STATUS => 0x17;
use constant EV_MAX       => 0x1f;

our %EV_NAME = (
     EV_SYN            , "EV_SYN",
     EV_KEY            , "EV_KEY",
     EV_REL            , "EV_REL",
     EV_ABS            , "EV_ABS",
     EV_MSC            , "EV_MSC",
     EV_LED            , "EV_LED",
     EV_SND            , "EV_SND",
     EV_REP            , "EV_REP",
     EV_FF             , "EV_FF",
     EV_PWR            , "EV_PWR",
     EV_FF_STATUS      , "EV_FF_STATUS",
);


our @EXPORT_OK   = qw(EV_SYN EV_KEY EV_REL EV_ABS 
                      EV_MSC EV_LED EV_SND EV_REP 
                      EV_FF  EV_PWR EV_FF_STATUS);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

=head1 NAME

Linux::Input::Info - get information about /dev/input/event* devices under Linux

=head1 SYNOPSIS

	use Linux::Input::Info qw(:all); # optionally export EV_* constants

    for (0..32) {
        my $i = Linux::Input::Info->new($_);
        printf "/dev/input/event%d\n", $_;

        printf "\tbustype  : %s\n",   $i->bustype;
        printf "\tvendor   : 0x%x\n", $i->vendor;
        printf "\tproduct  : 0x%x\n", $i->product;
        printf "\tversion  : %d\n",   $i->version;
        printf "\tname     : %s\n",   $i->name;
        printf "\tuniq     : %s\n",   $i->uniq;
        printf "\tphys     : %s\n",   $i->phys;
        printf "\tbits ev  :";
        printf " %s", $i->ev_name($_) for $i->bits;
        printf "\n";        
    }

=head1 DESCRIPTION

=head1 METHODS
    
=head2 new <event number>

Returns undef if the device does not exist.

=cut

sub new {
    my $class = shift;
    my $num   = shift;

    my $fd = device_open($num);
    return undef unless defined $fd;

    my $self = device_info($fd); 
    
    return bless $self, $class;
}



=head2 bustype

get the bus type

=cut

sub bustype {
    return $_[0]->{bustype};
}

=head2 vendor

get vendor id

=cut

sub vendor {
        return $_[0]->{vendor};
}

=head2 product

get the product id

=cut

sub product {
        return $_[0]->{product};
}

=head2 version

get driver version

=cut

sub version {
        return $_[0]->{version};
}


=head2 name

get device name

=cut

sub name {
        return $_[0]->{name};
}


=head2 uniq

get unique identifier

=cut

sub uniq {
        return $_[0]->{uniq};
}


=head2 phys

get physical location 

=cut

sub phys {
        return $_[0]->{phys};
}

=head2 bits

get event bits

=cut

sub bits {
    return @{$_[0]->{bits}};
}

=head2 ev_name

map event bit to event name 

=cut

sub ev_name {
    my ($self, $bit) = @_;
    return $EV_NAME{$bit};
}

=head1 BUGS

Make sure it doesn't leak memory.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

=head1 SEE ALSO

L<Linux::Input>

Gerd Knorr's input utils - http://dl.bytesex.org/cvs-snapshots/

=cut


bootstrap Linux::Input::Info $VERSION;

1;
__END__

