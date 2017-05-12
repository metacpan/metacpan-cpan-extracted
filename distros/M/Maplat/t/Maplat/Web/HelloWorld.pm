
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Web::HelloWorld;
use Maplat::Web::BaseModule;
@ISA = ('Maplat::Web::BaseModule');

our $VERSION = "1.0";

use strict;
use warnings;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
	
    return $self;
}

sub reload {
    my ($self) = shift;
	
    # Nothing to do.. in here, we only use the template and database module
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{webpath}, "get");
}


sub get {
    my ($self, $cgi) = @_;

	my %webdata = 
	(
		$self->{server}->get_defaultwebdata(),
	    PageTitle   =>  $self->{pagetitle},
	    webpath	=>  $self->{webpath},
        DynamicText => "Dynamic module text",
	);

    my $template = $self->{server}->{modules}->{templates}->get("helloworld", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


1;
