package Eixo::Queue::Mongo;

use strict;

use Eixo::Base::Clase qw(Eixo::Queue);
use Eixo::Queue::MongoDriver;

has(

	mongo_driver=>undef,

	db=>undef,

	collection => undef,

	host=>undef,

	port=>undef,

);

sub init{

	$_[0]->mongo_driver(

		Eixo::Queue::MongoDriver->new(

			db=>$_[0]->db,

			host=>$_[0]->host,

			port=>$_[0]->port,

			collection=>$_[0]->collection

		)

	) unless($_[0]->mongo_driver);	

}

sub add{

	$_[0]->mongo_driver->addJob($_[1]);
}

sub status{

	$_[0]->mongo_driver->getJob(@_[1..$#_]);

}


1;
