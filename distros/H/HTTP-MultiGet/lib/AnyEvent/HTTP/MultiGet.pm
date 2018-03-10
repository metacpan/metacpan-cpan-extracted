package AnyEvent::HTTP::MultiGet;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Data::Dumper;
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;
Log::Log4perl->wrapper_register(__PACKAGE__);

BEGIN {
  extends 'HTTP::MultiGet';
}

our $VERSION=$HTTP::MultiGet::VERSION;

=head1 NAME

AnyEvent::HTTP::MultiGet - AnyEvent->condvar Control Freindly LWP Like agent

=head1 SYNOPSIS

  use Modern::Perl;
  use AnyEvent::HTTP::MultiGet;

  my $self=AnyEvent::HTTP::MultiGet->new();
  my $count=0;
  TEST_LOOP: {
    my $req=HTTP::Request->new(GET=>'http://google.com');
    my $req_b=HTTP::Request->new(GET=>'https://127.0.0.1:5888');
    my @todo=HTTP::Request->new(GET=>'http://yahoo.com');
    push @todo,HTTP::Request->new(GET=>'http://news.com');
    push @todo,HTTP::Request->new(GET=>'https://news.com');

    my $total=2 + scalar(@todo);
    my $cv=AnyEvent->condvar;

    my $code;
    $code=sub {
      my ($obj,$request,$result)=@_;
      printf 'HTTP Response code: %i'."\n",$result->code;
      ++$count;
      if(my $next=shift @todo) {
        $self->add_cb($req,$code);
        $self->run_next;
      }
      no warnings;
      $cv->send if $total==$count;
    };
    $self->add_cb($req,$code);
    $self->add_cb($req_b,$code);
    $self->run_next;
    $cv->recv;
  }

Handling Multiple large http requests at once

  use Modern::Perl;
  use AnyEvent::HTTP::MultiGet;

  my $self=AnyEvent::HTTP::MultiGet->new();
  my $chunks=0;
  my $count=0;


  my $req=HTTP::Request->new(GET=>'https://google.com');
  my $req_b=HTTP::Request->new(GET=>'https://yahoo.com');
  my $req_c=HTTP::Request->new(GET=>'https://news.com');
  $total=3;

  my @todo;
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5888');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5887');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5886');
  push @todo,HTTP::Request->new(GET=>'https://127.0.0.1:5885');
  $total +=scalar(@todo);

  TEST_LOOP: {
    my $on_body=sub {
      my ($getter,$request,$headers,$chunk)=@_;
      # 0: Our AnyEvent::HTTP::MultiGet instance
      # 1: the HTTP::Request object
      # 2: An HTTP::Headers object representing the current headers
      # 3: Current Data Chunk

      ++$chunks;
      printf 'request is %s'."\n",$request->uri;
      printf 'status code was: %i'."\n",$headers->header('Status');
      printf 'content length was: %i'."\n",length($body);
    };

    my $code;
    my $cb=AnyEvent->condvar;
    $code=sub {
       my ($obj,$request,$result)=@_;
      printf 'HTTP Response code: %i %s'."\n",$result->code,$request->url;
      ++$count;
      print "We are at response $count\n";
      if(my $next=shift @todo) {
        $self->add_cb([$next,on_body=>$on_body],$code);
        $self->run_next;
      }
      no warnings;
      $cv->send if $count==$total;
    };
    $self->add_cb([$req,on_body=>$on_body],$code);
    $self->add_cb([$req_b,on_body=>$on_body],$code);
    $self->add_cb([$req_c,on_body=>$on_body],$code);

    $self->run_next;
    $cv->recv;
  }



=head1 DESCRIPTION

This class provides an AnyEvent->condvar frienddly implementation of HTTP::MultiGet.

=head1 OO Arguments and accessors

Arguemnts and object accessors:

  logger:          DOES(Log::Log4perl::Logger)
  request_opts:    See AnyEvent::HTTP params for details
  timeout:         Global timeout for everything 
  max_que_count:   How many requests to run at once 
  max_retry:       How many times to retry if we get a connection/negotiation error 

For internal use only: 

  in_control_loop: true when in the control loop
  stack:           Data::Queue object 
  que_count:       Total Number of elements active in the que
  retry:           Anonymous hash used to map ids to retry counts
  cb_map:          Anonymous hash used to map ids to callbacks

=cut

has cb_map=>(
  is=>'ro',
  isa=>HashRef,
  default=>sub { {} },
  required=>1,
);

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};

=head1 OO Methods

=over 4

=item * my $id=$self->add_cb($request,$code)

Adds a request with a callback handler.

=item * my $id=$self->add_cb([$request,key=>value],$code);

Wrapping [$request] allows passing additional key value to L<AnyEvent::HTTP::Request>, with one exception, on_body=>$code is wrapped an additional callback.

=cut

sub add_cb {
  my ($self,$request,$code)=@_;
  my ($id)=$self->add($request);
  my $req=is_plain_arrayref($request) ? $request->[0] : $request;
  $self->cb_map->{$id}=[$code,$req];
  return $id;
}

sub que_function {
    my ($self,$req,$id)=@_;
    my $code=$self->SUPER::que_function($req,$id);

    return sub {
      $code->(@_);
      $self->_common_handle_callback($id);
      $self->run_next;
      $self->log_always("our que count is: ".$self->que_count);
    };
}

sub _common_handle_callback {
  my ($self,$id)=@_;
  if(exists $self->cb_map->{$id}) {
    if(exists $self->results->{$id}) {
      my ($code,$req)=@{delete $self->cb_map->{$id}};
      my $result=delete $self->results->{$id};
      my $response;
      if($result) {
        $response=$result->get_data;
      } else {
        $response=$self->RESPONSE_CLASS->new('',{Status=>500,Reason=>"Request Timed out"})->to_http_message;
      }
      $code->($self,$req,$response);
    }
  } else {
  }
}

sub block_for_ids {
  my ($self,@ids)=@_;
  my $result=$self->SUPER::block_for_ids(@ids);

  if($result) {
    foreach my $id (@ids) {
      $self->results->{$id}=$result->get_data->{$id};
      $self->_common_handle_callback($id);
      delete $self->results->{$id};
    }
  } else {
    foreach my $id (@ids) {
      $self->results->{$id}=$self->new_false("$result");
      $self->_common_handle_callback($id);
      delete $self->results->{$id};
    }
  }

  return $result;
}

=back

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
