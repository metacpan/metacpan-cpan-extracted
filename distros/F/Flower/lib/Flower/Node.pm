package Flower::Node;

use strict;
use warnings;
use feature qw(say);
use Mojo::UserAgent;
use Mojo::ByteStream qw/b/;
use JSON::XS;

use AnyEvent;
use Scalar::Util qw/refaddr/;

use Carp qw/confess/;

use overload '""' => \&to_string;

use Data::UUID;

my $uuid    = Data::UUID->new();
my $timeout = 60;

my $json    = JSON::XS->new->allow_nonref;


#my $json    = JSON->new();

sub new {
  my $class = shift;
  confess "called as object method" if ref $class;

  my $args = shift || {};

  confess "no parent supplied" if ( !$args->{parent} );
  confess "no port supplied"   if ( !$args->{port} );
  confess "no ip supplied"     if ( !$args->{ip} );

  my $self = {
    uuid    => $args->{uuid},
    ip      => $args->{ip},
    port    => $args->{port},
    timeout => time() + ( $timeout / 2 ) - int( rand(20) ),
    parent  => $args->{parent},
    files   => $args->{files},
  };

  bless $self, __PACKAGE__;
  return $self;
}

# accessors

sub uuid {
  my $self = shift;
  return $self->{uuid};
}

sub ip {
  my $self = shift;
  return $self->{ip};
}

sub port {
  my $self = shift;
  return $self->{port};
}

sub parent {
  my $self = shift;
  return $self->{parent};
}

sub files {
  my $self = shift;
  confess "set_files was never called for $self"
    unless defined $self->{files};
  return $self->{files};
}

sub has_files_object {
  my $self = shift;
  return 1 if $self->{files};
  return 0;
}

# mutators

sub set_files {
  my $self  = shift;
  my $files = shift;
  $self->{files} = $files;
  return;
}

# checks

sub has_timed_out {
  my $self = shift;
  return 1 if ( $self->{timeout} < time() );
  return 0;
}

# action methods

sub ping_if_necessary {
  my $self      = shift;
  my $all_nodes = shift;

  if ( $self->{ping_cv} ) {
    return;
  }

  # ping if less than half of our timeout is left
  if ( $self->{timeout} - $timeout / 2 < time() ) {

    my $url = "https://" . $self->ip . ":" . $self->port . "/REST/1.0/ping?";
    my $nodedata = $json->encode($all_nodes);

    $self->{ping_ua} = Mojo::UserAgent->new;
    $self->{ping_cv} = AE::cv;

    # set up what we do when there is a response
    $self->{ping_cv}->cb(
      sub {
        my ( $node, $tx ) = ( shift->recv );
        $node->ping_received($tx);
      }
    );

    # do the ping (POST)
    $self->{ping_ua}->post(
      $url => { 'Content-Type' => 'application/json' } => $nodedata => sub {
        my ( $ua, $tx ) = @_;
        $self->{ping_cv}->send( $self, $tx );
      }
    );
  }
}

sub ping_received {
  my $self = shift;
  my $tx   = shift;

  if ( $tx && $tx->res && $tx->res->code && $tx->res->code == 200 ) {
    my $response;
    eval { $response = $tx->res->json; };
    if ( !$@ && $response->{result} eq 'ok' ) {

      # UUID better match too, if we know the uuid yet (we may not)
      if ( !$self->uuid || ( $response->{uuid} eq $self->uuid ) ) {

        # reset the timer and set the uuid
        $self->{timeout} = time() + $timeout;
        $self->{uuid}    = $response->{uuid};

        # schedule to update the file list
        $self->get_file_list();
      }

      else {
        warn "uuid does not match!\n";
        warn "expected " . $self->uuid . "\n";
        warn "got      " . $response->{uuid} . "\n";
      }
    }
    else {
      warn "something bad happened: $@\n";
    }
  }
  else {
    say " * $self - bad ping response";
    say "   body . " . $tx->res->body;
  }

  # whatever happened, we are done with the request, so kill
  # the event and ua.
  undef $self->{ping_cv};
  undef $self->{ping_ua};

}

sub get_file_list {
  my $self      = shift;
  my $all_nodes = shift;

  # don't do it to ourself
  if ( refaddr($self) eq refaddr( $self->parent->self ) ) {
    return;
  }

  if ( $self->{files_cv} ) {
    warn "get_file_list already in progress";
    return;
  }

  my $url = "https://" . $self->ip . ":" . $self->port . "/REST/1.0/files";

  $self->{files_ua} = Mojo::UserAgent->new;
  $self->{files_cv} = AE::cv;

  # set up what we do when there is a response
  $self->{files_cv}->cb(
    sub {
      my ( $node, $tx ) = ( shift->recv );
      $node->file_list_received($tx);
    }
  );

  # do the request
  $self->{files_ua}->get(
    $url => sub {
      my ( $ua, $tx ) = @_;
      $self->{files_cv}->send( $self, $tx );
    }
  );

}

sub file_list_received {
  my $self = shift;
  my $tx   = shift;

  if ( $tx && $tx->res && $tx->res->code && $tx->res->code == 200 ) {
    my $response;
    eval { $response = $tx->res->json; };
    if ( !$@ && $response->{result} eq 'ok' ) {

      # good stuff
      my $files_data = $response->{files};    # array of hashrefs
           # create an empty files object if we don't have one yet.
      if ( !$self->has_files_object ) {
        $self->set_files( Flower::Files->new() );
      }

      # update it
      $self->files->update_files_from_arrayref($files_data);
    }
    else {
      warn "something bad happened: $@\n";
    }
  }
  else {
    say " * $self - bad get_files response";
    say "   body . " . $tx->res->body;
  }

  # whatever happened, we are done with the request, so kill
  # the event and ua.
  undef $self->{files_cv};
  undef $self->{files_ua};
}

# helpers

sub to_string {
  my $self = shift;
  return sprintf(
    "%s | %s | %s (%s secs)",
    $self->{uuid} ? $self->{uuid} : "[undef]",
    $self->{ip}   ? $self->{ip}   : "[undef]",
    $self->{port} ? $self->{port} : "[undef]",
    $self->{timeout} - time(),
  );
}

1;
