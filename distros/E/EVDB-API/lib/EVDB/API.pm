package EVDB::API;

=head1 NAME

EVDB::API - Perl interface to EVDB public API

=head1 SYNOPSIS

  use EVDB::API;
  
  my $evdb = EVDB::API->new(app_key => $app_key);
  
  $evdb->login(user => 'harry', password => 'H0gwart$') 
    or die "Can't log in: $EVDB::API::errstr";
  
  # call() accepts either an array ref or a hash ref.
  my $event = $evdb->call('events/get', {id => 'E0-001-000218163-6'})
    or die "Can't retrieve event: $EVDB::API::errstr";
  
  print "Title: $event->{title}\n";

  my $venue = $evdb->call('venues/get', [id => $event->{venue_id}])
    or die "Can't retrieve venue: $EVDB::API::errstr";
  
  print "Venue: $venue->{name}\n";


=head1 DESCRIPTION

The EVDB API allows you to build tools and applications that interact with EVDB, the Events & Venues Database.  This module provides a Perl interface to that  API, including the digest-based authentication infrastructure.  

See http://api.evdb.com/ for details.

=head1 AUTHOR

Copyright 2006 Eventful, Inc. All rights reserved.

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

Special thanks to Daniel Westermann-Clark for adding support for "flavors" of 
plug-in parsers.  Visit Podbop.org to see other cool things made by Daniel.

=cut

require 5.6.0;

use strict;
use warnings;
no warnings qw(uninitialized);

use Carp;
use LWP::UserAgent;
use HTTP::Request::Common;
use Digest::MD5 qw(md5_hex);
use Module::Pluggable::Object;

=head1 VERSION

0.99 - August 2006

=cut

our $VERSION = 0.99;

our $VERBOSE = 0;
our $DEBUG = 0;

our $default_api_server = 'http://api.evdb.com';
our $default_flavor = 'rest';

our $errcode;
our $errstr;

=head1 CLASS METHODS

=head2 new
  
  $evdb = EVDB::API->new(app_key => $app_key);

Creates a new API object. Requires a valid app_key as provided by EVDB.

You can also specify an API "flavor", such as C<yaml>, to use a different format.

  $evdb = EVDB::API->new(app_key => $app_key, flavor => 'yaml');

Valid flavors are C<rest>, C<yaml>, and C<json>.

=cut

sub new
{
  my $thing = shift;
  my $class = ref($thing) || $thing;
  
  my %params = @_;
  my $self = 
  {
    'app_key'     => $params{app_key} || $params{app_token},
    'debug'       => $params{debug},
    'verbose'     => $params{verbose},
    'user_key'    => '',
    'api_root'    => $params{api_root} || $default_api_server,
  };
  
  $DEBUG   ||= $params{debug};
  $VERBOSE ||= $params{verbose};
  
  print "Creating object in class ($class)...\n" if $VERBOSE;
  
  bless $self, $class;
  
  my $flavor = $params{flavor} || $default_flavor;
  $self->{parser} = $self->_find_parser($flavor);
  croak "No parser found for flavor [$flavor]"
    unless $self->{parser};

  # Create an LWP user agent for later use.
  $self->{user_agent} = LWP::UserAgent->new(
    agent => "EVDB_API_Perl_Wrapper/$VERSION-$flavor",
  );
  
  return $self;
}

# Attempt to find a parser for the specified API flavor. 
# Returns the package name if one is found.
sub _find_parser
{
  my ($self, $requested_flavor) = @_;

  # Based on Catalyst::Plugin::ConfigLoader
  my $finder = Module::Pluggable::Object->new(
    search_path => [ __PACKAGE__ ],
    require     => 1,
  );

  my $parser;
  foreach my $plugin ($finder->plugins) {
    my $flavor = $plugin->flavor;
    if ($flavor eq $requested_flavor) {
      $parser = $plugin;
    }
  }

  return $parser;
}


=head1 OBJECT METHODS

=head2 login

  $evdb->login(user => $username, password => $password);
  $evdb->login(user => $username, password_md5 => $password_md5);

Retrieves an authentication token from the EVDB API server.

=cut

sub login 
{
  my $self = shift;
  
  my %args = @_;
  
  $self->{user} = $args{user};
  
  # Call login to receive a nonce.
  # (The nonce is stored in an error structure.)
  $self->call('users/login');
  my $nonce = $self->{response_data}{nonce} or return;
  
  # Generate the digested password response.
  my $password_md5 = $args{password_md5} || md5_hex($args{password});
  my $response = md5_hex( $nonce . ":" . $password_md5 );
  
  # Send back the nonce and response.
  my $params = 
  {
    nonce => $nonce,
    response => $response,
  };
  
  my $r = $self->call('users/login', $params) or return;
  
  # Store the provided user_key.
  $self->{user_key} = $r->{user_key} || $r->{auth_token};
  
  return 1;
}

=head2 call

  $data = $evdb->call($method, \%arguments, [$force_array]);

Calls the specified method with the given arguments and any previous authentication information (including C<app_key>).  Returns a hash reference containing the results.

=cut

sub call 
{
  my $self = shift;
  
  my $method = shift;
  my $args = shift || [];
  my $force_array = shift;

  # Remove any leading slash from the method name.
  $method =~ s%^/%%;

  # If we have no force_array, see if we have one for this method.
  if ($self->{parser}->flavor eq 'rest' and !$force_array) {

    # The following code is automatically generated.  Edit 
    #   /main/trunk/evdb/public_api/force_array/force_array.conf 
    # and run 
    #   /main/trunk/evdb/public_api/force_array/enforcer
    # instead.
    # 
    # BEGIN REPLACE
    if($method eq 'calendars/latest/stickers') {
      $force_array = ['site'];
    }

    elsif($method eq 'calendars/tags/cloud') {
      $force_array = ['tag'];
    }

    elsif($method eq 'demands/get') {
      $force_array = ['link', 'comment', 'image', 'tag', 'event', 'member'];
    }

    elsif($method eq 'demands/latest/hottest') {
      $force_array = ['demand', 'event'];
    }

    elsif($method eq 'demands/search') {
      $force_array = ['demand', 'event'];
    }

    elsif($method eq 'events/get') {
      $force_array = ['link', 'comment', 'trackback', 'image', 'parent', 'child', 'tag', 'feed', 'calendar', 'group', 'user', 'relationship', 'performer', 'rrule', 'exrule', 'rdate', 'exdate', 'date', 'category'];
    }

    elsif($method eq 'events/recurrence/list') {
      $force_array = ['recurrence'];
    }

    elsif($method eq 'events/tags/cloud') {
      $force_array = ['tag'];
    }

    elsif($method eq 'events/validate/hcal') {
      $force_array = ['tag', 'event_url', 'venue_url', 'event'];
    }

    elsif($method eq 'groups/get') {
      $force_array = ['user', 'calendar', 'link', 'comment', 'trackback', 'image', 'tag'];
    }

    elsif($method eq 'groups/search') {
      $force_array = ['group'];
    }

    elsif($method eq 'groups/users/list') {
      $force_array = ['user'];
    }

    elsif($method eq 'internal/events/submissions/pending') {
      $force_array = ['submission'];
    }

    elsif($method eq 'internal/events/submissions/set_status') {
      $force_array = ['submission'];
    }

    elsif($method eq 'internal/events/submissions/status') {
      $force_array = ['target'];
    }

    elsif($method eq 'internal/submissions/targets') {
      $force_array = ['target'];
    }

    elsif($method eq 'performers/demands/list') {
      $force_array = ['demand'];
    }

    elsif($method eq 'performers/get') {
      $force_array = ['link', 'comment', 'image', 'tag', 'event', 'demand', 'trackback'];
    }

    elsif($method eq 'performers/search') {
      $force_array = ['performer'];
    }

    elsif($method eq 'users/calendars/get') {
      $force_array = ['rule', 'feed'];
    }

    elsif($method eq 'users/calendars/list') {
      $force_array = ['calendar'];
    }

    elsif($method eq 'users/comments/get') {
      $force_array = ['comment'];
    }

    elsif($method eq 'users/events/recent') {
      $force_array = ['event'];
    }

    elsif($method eq 'users/get') {
      $force_array = ['site', 'im_account', 'event', 'venue', 'performer', 'comment', 'trackback', 'calendar', 'locale', 'link', 'event'];
    }

    elsif($method eq 'users/groups/list') {
      $force_array = ['group'];
    }

    elsif($method eq 'users/search') {
      $force_array = ['user'];
    }

    elsif($method eq 'users/venues/get') {
      $force_array = ['user_venue'];
    }

    elsif($method eq 'venues/get') {
      $force_array = ['link', 'comment', 'trackback', 'image', 'parent', 'child', 'event', 'tag', 'feed', 'calendar', 'group'];
    }

    elsif($method eq 'venues/tags/cloud') {
      $force_array = ['tag'];
    }

    else {
      $force_array = ['event', 'venue', 'comment', 'trackback', 'calendar', 'group', 'user', 'performer', 'member'];
    }

    # END REPLACE

  }

  # Construct the method URL.
	my $url = join '/', $self->{api_root}, $self->{parser}->flavor, $method;
  print "Calling ($url)...\n" if $VERBOSE;
  
  # Pre-process the arguments into a hash (for searching) and an array ref
  # (to pass on to HTTP::Request::Common).
  my $arg_present = {};
  if (ref($args) eq 'ARRAY')
  {
    # Create a hash of the array values (assumes [foo => 'bar', baz => 1]).
    my %arg_present = @{$args};
    $arg_present = \%arg_present;
  }
  elsif (ref($args) eq 'HASH')
  {
    # Migrate the provided hash to an array ref.
    $arg_present = $args;
    my @args = %{$args};
    $args = \@args;
  }
  else
  {
    $errcode = 'Missing parameter';
    $errstr  = 'Missing parameters: The second argument to call() should be an array or hash reference.';
    return undef;
  }
  
  # Add the standard arguments to the list.
  foreach my $k ('app_key', 'user', 'user_key')
  {
    if ($self->{$k} and !$arg_present->{$k})
    {
      push @{$args}, $k, $self->{$k};
    }
  }
  
  # If one of the arguments is a file, set up the Common-friendly 
  # file indicator field and set the content-type.
  my $content_type = '';
  foreach my $this_field (keys %{$arg_present})
  {
    # Any argument with a name that ends in "_file" is a file.
    if ($this_field =~ /_file$/)
    {
      $content_type = 'form-data';
      next if ref($arg_present->{$this_field}) eq 'ARRAY'; 
      my $file = 
      [
        $arg_present->{$this_field},
      ];
      
      # Replace the original argument with the file indicator.
      $arg_present->{$this_field} = $file;
      my $last_arg = scalar(@{$args}) - 1;
      ARG: for my $i (0..$last_arg)
      {
        if ($args->[$i] eq $this_field)
        {
          # If this is the right arg, replace the item after it.
          splice(@{$args}, $i + 1, 1, $file);
          last ARG;
        }
      }
    }
  }
  
  # Fetch the data using the POST method.
  my $ua = $self->{user_agent};
  
  my $response = $ua->request(POST $url, 
    'Content-type' => $content_type, 
    'Content' => $args,
  );
  unless ($response->is_success) 
  {
    $errcode = $response->code;
    $errstr  = $response->code . ': ' . $response->message;
    return undef;
  }
  
  $self->{response_content} = $response->content();
  my $data;
  
  my $ctype = $self->{parser}->ctype;
  if ($response->header('Content-Type') =~ m/$ctype/i)
  {
    # Parse the response into a Perl data structure.
    if ($self->{parser}->flavor eq 'rest')
    {
      # Maintain backwards compatibility.
      $self->{response_xml} = $self->{response_content};
    }
    $data = $self->{response_data} = $self->{parser}->parse($self->{response_content}, $force_array);
    
    # Check for errors.
    if ($data->{string})
    {
      $errcode = $data->{string};
      $errstr  = $data->{string} . ": " .$data->{description};
      print "\n", $self->{response_content}, "\n" if $DEBUG;
      return undef;
    }
  }
  else
  {
    print "Content-type is: ", $response->header('Content-Type'), "\n";
    $data = $self->{response_content};
  }

  return $data;
}

# Copied shamelessly from CGI::Minimal.
sub url_encode 
{
  my $s = shift;
  return '' unless defined($s);
  
  # Filter out any URL-unfriendly characters.
  $s =~ s/([^-_.a-zA-Z0-9])/"\%".unpack("H",$1).unpack("h",$1)/egs;
  
  return $s;
}

1;

__END__


=cut
