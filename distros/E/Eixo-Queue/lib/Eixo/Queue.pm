package Eixo::Queue;

use strict;
use Eixo::Base::Clase;


our $VERSION = '0.5.5';

has(

	name => undef

);

sub init{

}

sub add :Abstract		{}

sub addAndWait :Abstract	{}

sub status :Abstract		{}

sub remove :Abstract		{}

sub wait :Abstract		{}

sub isInmediate{

	$_[0]->isa('Eixo::QueueInmediate')
}

sub isDirect{

	$_[0]->isa('Eixo::Queue::Direct');
}

1;


