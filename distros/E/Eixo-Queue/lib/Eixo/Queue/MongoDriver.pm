package Eixo::Queue::MongoDriver;

use strict;
use MongoDB;
use Eixo::Base::Clase;
use Eixo::Queue::Job;

has(

	db=>undef,

	collection=>undef,

	host=>'localhost',

	port=>27017,

	__connection=>undef,
);

sub addJob{
	my ($self, $job) = @_;

	unless($job->isa('Eixo::Queue::Job')){
	
		die(ref($self) . '::addJob: an Eixo::Queue::Job was expected');

	}

	$self->getCollection->insert_one({
        _id => $job->id,
        %{$job->to_hash}
    });

}

sub updateJob{
	my ($self, $job) = @_;

	$self->getCollection->update(
        {_id=>$job->id} ,

        $job->to_hash
    );
}

sub getJob{
	my ($self, $id) = @_;

	$self->__format(

		$self->getCollection->find({
		
			_id=>$id

		})->next

	);
}

sub find{
    my ($self, $query, $sort) = @_;

    $self->__format(

        $self->getCollection
        
            ->find($query)
     
            ->sort($sort)

            ->all
    );
}

sub getPendingJob{
	my ($self, %args) = @_;

    my $query = {

        status=>"WAITING"
    };  

    $query->{queue} = $args{queue} if(defined $args{queue});

	$self->__format(

		$self->getCollection->find_and_modify({

			query =>$query,
			sort => {creation_timestamp => 1},
			update => {
				'$set' => {
					status => 'PROCESSING', 
					start_timestamp => time
				}
			},
			new => 1,
		})

	);

}


sub __format{
	my ($self, @jobs) = @_;

	@jobs = map {

		Eixo::Queue::Job->new(%$_);

	} grep { ref($_) } @jobs;

	wantarray ? @jobs : (@jobs < 2) ? $jobs[0] : \@jobs;
}


sub getCollection{
	my ($self, $collection) = @_;

	$collection = $collection || $self->collection;

	$self->getDb->get_collection($collection);

}

sub getDb{
	my ($self, $db) = @_;

	$db = $db || $self->db;

	$self->getConnection->get_database($db);
	

}

sub getConnection{

	return $_[0]->__connection if($_[0]->__connection);

	my $c;

	$_[0]->__connection(


		$c = MongoDB::MongoClient->new(

			host=>$_[0]->host,

			port=>$_[0]->port

		)	

	);

	$_[0]->__connection;
}

#__PACKAGE__->new->getConexion;

1;
