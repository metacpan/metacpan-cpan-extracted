package HTTP::MultiGet;

=head1 NAME

HTTP::MultiGet - Run many http requests at once! 

=head1 SYNOPSIS

  use Modern::Perl;
  use HTTP::MultiGet;
  use HTTP::Request;

  my $getter=new HTTP::MultiGet;

  my @requests=(map { HTTP::Request->new(GET=>"http://localhost$_") } (1 .. 1000));
  my @responses=$getter->run_requests(@requests);

  my $id=0;
  foreach my $response (@responses) {
    my $request=$requests[$id++];
    print "Results for: ".$request->uri."\n";
    if($response->is_success) {
      print $response->decoded_content;
    } else {
      print $response->status_line,"\n";
    }
  }


=head2 Handling Multiple Large Downloads

  use Modern::Perl;
  use HTTP::MultiGet;
  use HTTP::Request;

  my $req=HTTP::Request->new(GET=>'http://some.realy.big/file/to/download.gz');
  my $req_b=HTTP::Request->new(GET=>'http://some.realy.big/file/to/download2.gz');

  # create a callback 
  my $code=sub {
    my ($getter,$request,$headers,$chunk)=@_;
      # 0: Current HTTP::MultiGet instance
      # 1: HTTP::Request object
      # 2: HTTP::Headers object
      # 3: Chunk of data being downloaded
    if($headers->header('Status')==200) {
      # do something
    } else {
      # do something with $body
    }
  };
  my $getter=new HTTP::MultiGet;
  my ($result,$result_b)=$getter->run_requests([$req,on_body=>$code],[$req_b,on_body=>$code]);


The arguments: on_body=>$code are called called on each chunk downloaded.  $result is created when the download is completed, but $result->decoded_content is going to be empty

=head1 DESCRIPTION

Created a wrapper for: L<AnyEvent::HTTP>, but provides a more LWP like feel.

=cut

use Moo;
use Log::Log4perl;
use Data::Queue;
use Scalar::Util qw(looks_like_number);
Log::Log4perl->wrapper_register(__PACKAGE__);
use AnyEvent;
use Data::Dumper;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use Class::Method::Modifiers;
use AnyEvent::HTTP::Request;
use MooX::Types::MooseLike::Base qw(:all);
use AnyEvent::HTTP::Response;
use AnyEvent;
use Carp qw(croak);
use Ref::Util qw(is_plain_arrayref is_plain_hashref);
require AnyEvent::HTTP;
use namespace::clean;
BEGIN {
with 'Log::LogMethods';
with 'Data::Result::Moo';
}
our $VERSION='1.021';

sub BUILD {
  my ($self)=@_;

  $self->{stack}=new Data::Queue;
  $self->{que_count}=0;
  $self->{que_id}=0;
}

=head1 Moo Stuff

This is a Moo class the object constructor takes the following arguments, along with the following roles

Role List:

  Log::LogMethods
  Data:::Result::Moo

Arguemnts and object accessors:

  logger:          DOES(Log::Log4perl::Logger)
  request_opts:    See AnyEvent::HTTP params for details
  timeout:         Global timeout for everything ( default 300 )
  max_que_count:   How many requests to run at once ( default 20 )
  max_retry:       How many times to retry if we get a connection/negotiation error 

For internal use only: 

  in_control_loop: true when in the control loop
  stack:           Data::Queue object 
  que_count:       Total Number of elements active in the que
  retry:           Anonymous hash used to map ids to retry counts

=head2 UNIT TESTING

For Unit testing

  on_create_request_cb: Anonymous code ref to be called 
    when a new request object has been created
        sub { my ($id,$request)=@_ }

Arguments  for the call back

  id:  number for the object
  req: a new instance of $self->SENDER_CLASS

Interal blocking control variables

  loop_control: AnyEvent->condvar object
  false_id: internal false id tracker
  fake_jobs: Internal object for handling fake results

=cut 

has false_id=>(
  is=>'rw',
  isa=>Int,
  default=>-1,
  lazy=>1,
);

has fake_jobs=>(
  isa=>HashRef,
  is=>'rw',
  default=>sub { {}}
);

has loop_control=>(
  is=>'rw',
  required=>0.
);

has loop_id=>(
  is=>'rw',
  isa=>Num,
  default=>0,
);

has max_retry=>(
  is=>'rw',
  isa=>Num,
  default=>3,
);

has retry=>(
  is=>'rw',
  default=>sub { { } },
  lazy=>1,
);

has no_more_after =>(
  is=>'rw',
  isa=>Num,
  default=>0,

);

has on_create_request_cb=>(
  is=>'rw',
  isa=>CodeRef,
  default=>sub { sub { } },
  lazy=>1,
);

has in_control_loop=>(
  is=>'rw',
  isa=>Bool,
  default=>0,
);

has running=>(
  is=>'ro',
  default=>sub { {}},
  lazy=>1,
);

has request_opts=>(
  is=>'rw',
  requires=>1,
  default=>sub { {cookie_jar=>{},persistent=>0} },
);

has stack=>( is=>'ro');

has results=>(
  is=>'ro',
  lazy=>1,
  default=>sub { {} },
);

has que_count=>(
  is=>'rw',
  isa=>Num,
);

has timeout =>(
  is=>'rw',
  isa=>sub {
    my $timeout=$_[0];
    croak 'timeout is a required option' unless looks_like_number($timeout);
    croak 'timeout must be greater than 0' if $timeout <=0;
    $timeout,
  },

  default=>300,
);


has max_que_count=> (
  is=>'rw',
  isa=>Num,
  default=>20,
);


around max_que_count=>sub {
  my ($org,$self,$count)=@_;
  if(looks_like_number($count)) {
    $AnyEvent::HTTP::MAX_PER_HOST=$count if $AnyEvent::HTTP::MAX_PER_HOST < $count;
    return $org->($self,$count);
  } else {
    shift;
    return $org->(@_);
  }
};

=head1 Class constants

=over 4

=item * my $class=$self->RESPONSE_CLASS

Returns the http response class, typically AnyEvent::HTTP::Response.

=cut

use constant RESPONSE_CLASS=>'AnyEvent::HTTP::Response';

=item * my $class=$self->HEADER_CLASS

Returns the header class, typically HTTP::Headers.

=back

=cut

use constant HEADER_CLASS=>'HTTP::Headers';


=head1 OO Methods

=over 4

=item * my $id=$self->next_que_id

Returns the next id.

=cut

sub next_que_id {
  return $_[0]->{que_id} +=1;
}

sub running_count {
  my ($self)=@_;
  return scalar(keys %{$self->running});
}

=item * my @ids=$self->add(@requests)

Adds @requests to the stack, @ids relates as id=>request

=item * my @ids=$self->add([$request,key=>value]);

Wrapping [$request] allows passing additional key value to L<AnyEvent::HTTP::Request>, with one exception, on_body=>$code is wrapped an additional callback.

=cut

sub add {
  my ($self,@list)=@_;
  my @ids;

  foreach my $req (@list) {
    my $id=$self->next_que_id;
    push @ids,$id;
    $self->add_by_id($id=>$req);
  }
  return @ids;
}

=item * my $id=$self->add_by_id($id=>$request);

Adds the request with an explicit id.

=cut

sub add_by_id {
  my ($self,$id,$request)=@_;
  my $req=$self->create_request($request,$id);
  $self->stack->add_by_id($id,$req);
  $self->retry->{$id}=$self->max_retry unless exists $self->retry->{$id};
  $self->on_create_request_cb->($id,$req);
  return $id;
}

=item * $self->run_fake_jobs

Runs all current fake jobs

=cut

sub run_fake_jobs {
  my ($self)=@_;
  
  while($self->has_fake_jobs) {
    my $fj=$self->fake_jobs;
    $self->fake_jobs({});
    while(my (undef,$job)=each (%{$fj})) {
      $job->();
    }
  }
}

=item * $self->run_next

Internal functoin, used to run the next request from the stack.

=cut

sub run_next {
  my ($self)=@_;

  $self->run_fake_jobs;
  return if $self->{que_count} >= $self->max_que_count;

  while($self->{que_count} < $self->max_que_count and $self->stack->has_next) {
    my ($id,$next)=$self->stack->get_next;
    $self->running->{$id}=$next;
    $next->send;
    ++$self->{que_count};
    $self->log_debug("Total of: $self->{que_count} running");
  }

  return 1;
}

=item * my $id=$self->add_result($cb)

Internal function, added for L<HTTP::MultiGet::Role>

=cut

sub add_result {
  my ($self,$cb)=@_;
  my $current=$self->false_id;
  $current -=1;
  $self->false_id($current);
  $self->fake_jobs->{$current}=$cb;
  return $current;
}

=item * if($self->has_fake_jobs) { ... }

Checks if any fake jobs exist 

=cut

sub has_fake_jobs {
  return 0 < keys %{$_[0]->fake_jobs}
}

=item * my $result=$self->has_request($id)

Returns a Charter::Result Object.

When true it contains a string showing where that id is in the list.

Values are:

  complete: Has finished running
  running:  The request has been sent, waiting on the response
  in_que:   The request has not been run yet

=cut

sub has_request {
  my ($self,$id)=@_;

  my $result=$self->new_false('request does not exist!');

  if(exists $self->results->{$id}) {
    $result=$self->new_true('complete');

  } elsif(exists $self->running->{$id}) {
    $result=$self->new_true('running');

  } elsif( $self->stack->has_id($id) ) {

    $result=$self->new_true('in_que');
  }
  
  return $result;
}

=item * if($self->has_running_or_pending) { ... }

Returns a Charter::Result object

  true:  it contains how many objects are not yet complete.
  false: no incomplete jobs exist

=cut

sub has_running_or_pending {
  my ($self)=@_;
  my $total=$self->stack->total;
  $total +=$self->running_count;
  return $self->new_true($total) if $total >0;
  return $self->new_false("there are no objects running");
}

=item * if($self->has_any) { ... }

Returns a Charter::Result object

  true: conains how many total jobs of any state there are
  false: there are no jobs in any state

=cut

sub has_any {
  my ($self)=@_;
  my $total=$self->stack->total;
  $total +=keys %{$self->running};
  $total +=keys %{$self->results};

  return $self->new_true($total) if $total >0;
  return $self->new_false("there are no objects running");
}

=item * my $result=$self->block_for_ids(@ids)

Returns a Charter::Result object

when true: some results were found

  while(my ($id,$result)=each %{$result->get_data}) {
    if($result) {
      my $response=$result->get_data;
      print "Got response: $id, code was: ",$response->code,"\n";
    } else {
      print "Failed to get: $id error was: $result\n";
    }
  }

=cut

sub block_for_ids {
  my ($self,@ids)=@_;

  $self->run_fake_jobs;
  my $results={};

  my @check;

  my $ok=0;
  foreach my $id (@ids) {
    if(exists $self->results->{$id}) {
      # the result is done
      $results->{$id}=$self->results->{$id};
      delete $self->results->{$id};
      ++$ok;

    } elsif(exists $self->running->{$id}) {

      push @check,$id;
      $results->{$id}=$self->new_false('Request Timed out');

    } elsif( $self->stack->has_id($id) ) {

      push @check,$id;
      $results->{$id}=$self->new_false('Request Never made it to the que');

    } else {

      push @check,$id;
      $results->{$id}=$self->new_false('request does not exist!');
    }
  }

  $self->block_loop;
  foreach my $id (@check) {
    next unless exists $self->results->{$id};

    ++$ok;

    $results->{$id}=$self->results->{$id};
    delete $self->results->{$id};
  }

  delete @{$self->retry}{@ids};
  return $self->new_true($results) if $ok!=0;
  return $self->new_false("Request(s) timed out");
}

=item * my $class=$self->SENDER_CLASS

$class is the class used to send requests.

=cut

sub SENDER_CLASS { 'AnyEvent::HTTP::Request' }

=item * my $req=$self->create_request($req,$id)

Internal method.  Returns a new instance of $self->SENDER_CLASS for Teh given $request and $id.

=cut 

sub create_request {
  my ($self,$obj,$id)=@_;
  
  my $req;
  my $opt={
      params=>{%{$self->request_opts}},
  };
  if(is_plain_arrayref($obj)) {
    my @args;
    ($req,@args)=@{$obj};
    my $code=$self->que_function($req,$id);
    while(my ($key,$value)=splice(@args,0,2)) {
      if($key eq 'on_body') {
        my $code=sub {
	   my ($body,$headers)=@_;
	   my $header=new HTTP::Headers( %{$headers});
	   $value->($self,$req,$header,$body);
	};
	$opt->{params}->{$key}=$code;
      } else {
        $opt->{params}->{$key}=$value;
      }
    }
    $opt->{cb}=$code;
  } else {
    $req=$obj;
    my $code=$self->que_function($req,$id);
    $opt->{cb}=$code;
  }
  foreach my $key (qw(keepalive persistent)) {
    $opt->{params}->{$key}=0 unless exists $opt->{params}->{$key};
  }
  my $request=$self->SENDER_CLASS->new(
    $req,
    $opt,
  );

  return $request;
}

=item * my $code=$self->que_function($req,$id);

Internal method.  Creates a code refrence for use in the que process.

=cut

sub que_function {
  my ($self,$req,$id)=@_;
  my $loop_id=$self->loop_id;

  my $code=sub {
    my $response=$self->RESPONSE_CLASS->new(@_)->to_http_message;
    $self->log_debug("Got Response for id: [$id] Status Line: ".$response->status_line);

    # work around for unit testing;
    --$self->{que_count} if $self->{que_count} > 0;

    if(exists $self->retry->{$id} and $response->code > 594 and $self->retry->{$id}-- > 0) {
      $self->log_info("Request negotiation error: ".$response->code." for id: $id retry count is: ".( 1 + $self->retry->{$id} )." will retry");
      $self->add_by_id($id=>$req);
      $self->run_next;
      return;
    }

    delete $self->retry->{$id};

    if(exists $self->running->{$id}) {
      delete $self->running->{$id};
    } else {
      $self->log_debug("$id never ran, but the cb is being used");
      $self->stack->remove($id);
    }
    
    $self->results->{$id}=$self->new_true($response);
    
    $self->run_next;
    if($self->in_control_loop) {
      if($self->que_count==0) {
        $self->loop_control->send if $self->loop_control;
      }
      return;
    }

    if($self->{que_count}==0) {
      $self->log_debug('Que Count has reached 0');
      if($loop_id!=$self->loop_id) {
        $self->log_info("A result outside of it's lifecycle has arived loop_id: $loop_id que_id: $id, but we are in loop_id: ".$self->loop_id);
        return;
      }
      $self->loop_control->send if $self->loop_control;
    } else {
      $self->log_debug("Que Count is at $self->{que_count}");
    }

  };
  return $code;
}

=item * $self->block_loop

Internal Function. Does a single timed pass against the current set of data, stops when the requests complete.  

=cut

sub block_loop : BENCHMARK_DEBUG {
  my ($self)=@_;
  my $timeout=$self->timeout;
  my $stack=$self->stack;
  my $count=$self->que_count;

  return $self->new_true("No http requests in que") if($stack->total==0 and $count==0);

  my $result=$self->new_true();
  $self->log_info("There are: $self->{que_count} jobs in the in the que");
  
  my $t;
  LOOP_CONTROL: {
    $self->in_control_loop(1);
    # make sure we don't run forever!
    $self->loop_control(AnyEvent->condvar);
    $t=AnyEvent->timer(after=>$self->timeout,cb=>sub { 
      $result=$self->new_false("Timed out before we got a response");
      $self->log_error("Request Que timed out, Que Count is: ".$self->que_count);
      $self->loop_control->send;
    });
    $self->run_next;
    $self->loop_control->send if $self->{que_count}<=0;

    $self->loop_control->recv;
  }
  $self->loop_control(undef);
  undef $t;
  $self->in_control_loop(0);
  $self->loop_id($self->loop_id + 1);
  return $result;
}

=item * my @responses=$self->run_requests(@requests);

Ques runs and blocks for all https requests, and returns the result objects

Arguments:

  @requests: list of HTTP::Request Objects

Responses

  @responses: list of HTTP::Result in order of the requests.

=cut

sub run_requests {
  my ($self,@requests)=@_;
  my @ids=$self->add(@requests);

  my $init_result=$self->block_for_ids(@ids);

  my @results;
  my $results=$init_result->get_data;
  if($init_result) {
    foreach my $id (@ids) {
      my $result=$results->{$id};
      if($result) {
        my $res=$result->get_data;
	$res->code;
        push @results,$res;
      } else {
        $self->log_debug("Failed to get response, error was: $init_result");
        push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
      }
    }
  } else {
    foreach my $id (@ids) {
      $self->log_debug("Failed to get response, error was: $init_result");
      push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
    }
  }
  return @results;
}

=item * $self->clean_results

Used to remove any results that are unclaimed ( Use to prevent memory leaks! ).

=cut

sub clean_results {
  %{$_[0]->results}=();
}

=item * my @responses=$self->block_for_results_by_id(@ids)

Blocks on the @ids lsit for list of HTTP::Response objects 

=cut

sub block_for_results_by_id {
  my ($self,@ids)=@_;

  my $result=$self->block_for_ids(@ids);

  my @results;
  if($result) {
    my $hash=$result->get_data;
    foreach my $id (@ids) {
      my $result=$hash->{$id};
      if($result) {
        push @results,$result->get_data;
      } else {
        push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
      }
    }

  } else {
    foreach my $id (@ids) {
      push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
    }
  }

  return @results;
}

=item * my @results=$self->get_results(@ids);

Does not block, just returns a list of HTTP::Response objects based on @ids

=cut

sub get_results {
  my ($self,@ids)=@_;

  my $result=$self->new_false('request does not exist!');

  my @results;
  my $ok=0;
  foreach my $id (@ids) {
    if(exists $self->results->{$id}) {
      ++$ok;
      my $result=$self->results->{$id};
      delete $self->results->{$id};
      if($result) {
        push @results,$result->get_data;
      } else {
        push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
      }
    } else {
      push @results,$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
    }
  }
  
  return @results;
}

=back

=head1 Using with AnyEvent

See L<AnyEvent::HTTP::MultiGet>

=head1 AUTHOR

Mike Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut

1
