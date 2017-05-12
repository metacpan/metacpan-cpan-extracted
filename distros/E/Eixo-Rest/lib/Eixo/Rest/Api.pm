package Eixo::Rest::Api;

use strict;
use Eixo::Base::Clase;

use Data::Dumper;
use Attribute::Handlers;
use Eixo::Rest::Client;
use Carp;

use Eixo::Rest::Uri;

my $JOB_ID = 1;

has (

	client => undef,

	jobs=>[],

);

sub AUTOLOAD{
	my ($self, @args) = @_;

	my ($method) = our $AUTOLOAD =~ /\:\:(\w+)$/;

	if($method =~ /^get|^post|^patch|^delete|^update|^put|^head/){
		@args = $self->__analyzeRequest($method, @args);
	}
    else{
        die("Unknown REST method " . $method);
    }

	$self->client->$method(@args);
}


sub DESTROY {}

sub initialize{

    my ($self, $endpoint, %opts) = @_;

    $self->client(
        Eixo::Rest::Client->new($endpoint, %opts)
    );

    $self->SUPER::initialize(%opts);

    $self;
}

sub produce{
	my ($self, $class, %args) = @_;
	
	$self->__loadProduct($class);

	$class->new(

		api=>$self,

		%args

	)
}

sub newJob{
	my ($self, $request, $id) = @_;

	push @{$self->jobs}, $request;

	$self;
}

sub jobFinished{
	my ($self, $request) = @_;

	$self->jobs([ grep {

		$_ != $request

	} @{$self->jobs} ] );
}

sub waitForJob{
	my ($self, $job_id) = @_;

	$self->waitForJobs($job_id);
	
}

sub waitForJobs{
	my ($self, $id) = @_;

	while(scalar(@{$self->jobs})){

		if($id){
			return unless(scalar(grep { $_->job_id == $id } @{$self->jobs}));
		}

		foreach my $job (@{$self->jobs}){

			$job->process;

			select(undef, undef, undef, 0.05);

		}
	}
}

sub __analyzeRequest {
	my ($self, $method, %args) = @_;

	my $params = $args{args};

	# print "params:".Dumper($params);
	# if(exists $args{onError}){
	# 	$self->client->error_callback($args{onError});
	# }

	# check args needed
	if($args{needed}){

		foreach (@{$args{needed}}){

			&{$self->client->error_callback}(

				$method, 

				'PARAM_NEEDED', 

				$_ ) unless(defined($params->{$_}));

		}		

	}	

	# build GET_DATA & POST_DATA
	unless(exists($params->{GET_DATA})){
        $self->__buildGetParams($args{get_params}, $params);

	}

	unless(exists($params->{POST_DATA})){
        $self->__buildPostParams($args{post_params}, $params);
	}

    # build URI (if provided)
    if($args{uri_mask}){

        my ($uri, @implicit_params) = Eixo::Rest::Uri->new(

            args=>$params,

            uri_mask=>$args{uri_mask}

        )->build;

        # erase implicit params from the get_params and post_params arrays
        delete $params->{GET_DATA}->{$_} foreach(@implicit_params);
        delete $params->{POST_DATA}->{$_} foreach(@implicit_params);

        # we pass the newly created uri
        $params->{uri} = $uri;
    }

	delete($params->{$_}) foreach(@{$args{get_params}}, @{$args{post_params}});
	
	# default callback function
	#
	# identity function

	my $default_func = sub {

		(wantarray)? @_ : $_[0];

	};


	# needed, maybe must die if not provided
	$params->{__callback} = $args{__callback} || $default_func;



	# build PROCESS_DATA
	$params->{PROCESS_DATA} = {

		onSuccess=>$args{onSuccess} || $params->{onSuccess} || $default_func,
		
		onError=>$args{onError} || $params->{onError}, 

		onProgress=>$args{onProgress} || $params->{onProgress},

		onStart=>$args{onStart} || $params->{onStart}

	};
	delete($params->{$_}) foreach (qw(onStart onProgress onError onSuccess));

	# print "PARAMS_PARSEADOS:".Dumper($params);

	%$params;

}

    sub __buildGetParams{
        my ($self, $get_params, $params) = @_;

		$params->{GET_DATA} = {
			map {$_ => $params->{$_}} 
				grep {exists($params->{$_})} 
					@{$get_params}
		};
    }

    sub __buildPostParams{
        my ($self, $post_params, $params) = @_;

		$params->{POST_DATA} = {
			map {
				$_ => $params->{$_}
			} grep {exists($params->{$_})} @{$post_params}
		};

    }

sub async{
	my ($self, $product, $method, @args) = @_;
	
	my $on_end;

	if(scalar(@args) % 2 != 0){
		$on_end = pop(@args);
	}

	my %args = @args;

	$args{onSuccess} = $args{onSuccess} || $on_end || die(

			ref($product) . '::' . $method . 'Async: callback is needed'

	);

	$args{api} = $self;

	$args{__job_id} = $JOB_ID++;

	$product->$method(%args);

	return $args{__job_id};
}



sub __loadProduct{
	my ($self, $class) = @_;

	$class =~ s/\:\:/\//g;

	require $class . ".pm";
}

1;
