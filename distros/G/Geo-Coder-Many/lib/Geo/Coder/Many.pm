package Geo::Coder::Many;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use List::MoreUtils qw(any);
use Sort::Versions;
use HTTP::Response;
use Time::HiRes;

our $VERSION = '0.47';

# note - also update lists far below in pod
use Geo::Coder::Many::Bing;
use Geo::Coder::Many::Googlev3;
use Geo::Coder::Many::Mapquest;
use Geo::Coder::Many::OpenCage;
use Geo::Coder::Many::OSM;

use Geo::Coder::Many::Util qw(
    min_precision_filter 
    max_precision_picker 
    consensus_picker 
    country_filter 
);

use Geo::Coder::Many::Scheduler::Selective;
use Geo::Coder::Many::Scheduler::OrderedList;
use Geo::Coder::Many::Scheduler::UniquenessScheduler::WRR;
use Geo::Coder::Many::Scheduler::UniquenessScheduler::WeightedRandom;

=head1 NAME

Geo::Coder::Many - Module to tie together multiple Geo::Coder::* modules.
NOTE: this module is DEPRECATED and no longer maintained.

=head1 DESCRIPTION

This module is no longer maintained and we advise not to use it.

Geo::Coder::Many provides a single interface to different remote 
(ie HTTP based) geocoding modules

Amongst other things, Geo::Coder::Many adds geocoder precision information,
alternative scheduling methods (weighted random, and ordered list), timeouts
for geocoders which are failing, and optional callbacks for result filtering
and picking.

=head1 SYNOPSIS

General steps for using Geo::Coder::Many:

=over

=item 1. Create Geo::Coder::* objects for the geocoders you want to use, using
their various individual setup procedures.

=item 2. Create the Geo::Coder::Many object with C<new>

=item 3. Call C<add_geocoder> for each of the geocoders you want to use

=item 4. Set any filter or picker callbacks you require (optional)

=item 5. Use the C<geocode> method to do all of your geocoding

=back

=head1 EXAMPLE

Suppose the geocoders we want to use are called 'Locatorize' and 'WhereIzIt'.

   use Geo::Coder::Locatorize;
   use Geo::Coder::WhereIzIt;
   use Geo::Coder::Many;
   use Geo::Coder::Many::Util qw( country_filter );
   
   # Create the Geo::Coder::Many object, telling it to use a 'weighted random'
   # scheduling method
   my $options = {
       cache   => $cache_object,
       scheduler_type => 'WRR',
   };
   my $geocoder_many = Geo::Coder::Many->new( $options );
   
   # Create and add a geocoder
   my $Locatorize = Geo::Coder::Locatorize->new( appid => 'mY_loCat0r1Ze_iD' );
   my $Locatorize_options = {
       geocoder    => $Locatorize,
       daily_limit => 2500,
   };
   $geocoder_many->add_geocoder( $Locatorize_options );
   
   # Create and add a second geocoder
   my $WhereIzIt = Geo::Coder::WhereIzIt->new( apikey => 'mY_WhERiz1t_kEy' );
   my $WhereIzIt_options = {
       geocoder    => $WhereIzIt,
       daily_limit => 4000,
   };
   $geocoder_many->add_geocoder( $WhereIzIt_options );
   
   # Use a filter callback from Geo::Coder::Many::Util
   $geocoder_many->set_filter_callback(country_filter('United Kingdom'));
   
   # Use a built-in picker callback
   $geocoder_many->set_picker_callback('max_precision');
   
   my $result = $geocoder_many->geocode( 
      {
          location => '82 Clerkenwell Road, London' 
      }
   );
   
   if (defined $result) {
       print "Country: ",       $result->{country},       "\n";
       print "Longitude: ",     $result->{longitude},     "\n";
       print "Latitude: ",      $result->{latitude},      "\n";
       print "Location: ",      $result->{location},      "\n";
       print "Response code: ", $result->{response_code}, "\n";
       print "Address: ",       $result->{address},       "\n";
       print "Precision: ",     $result->{precision},     "\n";
       print "Geocoder: ",      $result->{geocoder},      "\n";
   }
   else {
       print "Failed to geocode!\n";
   }
   
=head1 METHODS

=head2 new

Constructs a new Geo::Coder::Many object and returns it. Options should be
provided as the entries of a hash reference, as follows:

  KEY                   VALUE
  -----------           --------------------
  cache                 Cache object reference  (optional)
  normalize_code_ref    A normalization code ref (optional)
  scheduler_type        Name of the scheduler type to use (default: WRR)
  use_timeouts          Whether to time out failing geocoders (default: false)

If no C<cache> option is specified, no caching will be done for the geocoding
results.

C<normalize_code_ref> is a code reference which is used to normalize location
strings to ensure that all cache keys are normalized for correct lookup.

C<scheduler_type> specifies how load balancing should be done.

Scheduling schemes currently available are:

=over

=item WRR (Weighted round-robin)

    Round-robin scheduling, weighted by the daily_limit values for the geocoders
    (The same behaviour as Geo::Coder::Multiple)

=item OrderedList

    A strict preferential ordering by daily_limit - the geocoder with the
    highest limit will always be used. If that fails, the next highest will be
    used, and so on.

=item WeightedRandom

    Geocoders will be picked at random, each with probability proportional to
    its specified daily_limit.

=back

Other scheduling schemes can be implemented by sub-classing
Geo::Coder::Many::Scheduler or Geo::Coder::Many::UniquenessScheduler.

If C<use_timeouts> is true, geocoders that are unsuccessful will not be queried
again for a set amount of time. The timeout period will increase exponentially
for every successive consecutive failure.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = {
        cache               => undef,
        geocoders           => {},
        scheduler           => undef,
        normalize_code_ref  => $args->{normalize_code_ref},
        filter_callback     => undef,
        picker_callback     => undef,
        scheduler_type      => $args->{scheduler_type},
        use_timeouts        => $args->{use_timeouts},
    };

    if ( !defined $args->{scheduler_type} ){ 
	$self->{scheduler_type} = 'WRR'; 
    }
    if ( $self->{scheduler_type} !~ /OrderedList|WRR|WeightedRandom/x ) {
        carp "Unsupported scheduler type: should be OrderedList or WRR or
              WeightedRandom.";
    }

    bless $self, $class;

    if ( $args->{cache} ) {
        $self->_set_caching_object( $args->{cache} );
    }
    return $self;
}

=head2 add_geocoder

This method adds a geocoder to the list of possibilities.

Before any geocoding can be performed, at least one geocoder must be added
to the list of available geocoders.

If the same geocoder is added twice, only the instance added first will be 
used. All other additions will be ignored.

  KEY                   VALUE
  -----------           --------------------
  geocoder              geocoder object reference (required)
  daily_limit           geocoder source limit per 24 hour period (required)

C<geocoder> should be a reference to a Geo::Coder::Something object, where
'Something' is a supported geocoder type. For a geocoder to be supported, it
needs to have a corresponding Geo::Coder::Many::Something adapter module.

Note that C<daily_limit> is just treated as guideline for the chosen scheduler,
and will not necessarily be strictly obeyed.

=cut

sub add_geocoder { 
    my ($self, $args) = @_;

    my $module = ref $args->{geocoder};
    (my $plugin = $module) =~ s/Geo::Coder::/Geo::Coder::Many::/x;

    # Check that the geocoder module is compatabible with our plugin.
    if (!$self->_geocoder_module_is_compatible_with_plugin($module, $plugin)) {
        carp "Can't add $module due to version incompatibility";
        return 0;
    }

    eval {
        my $geocoder = $plugin->new($args);
        if (exists $self->{geocoders}->{$geocoder->get_name()}) {
            carp "Warning: duplicate geocoder (" . $geocoder->get_name() .")";
        }
        $self->{geocoders}->{$geocoder->get_name()} = $geocoder;
    };
        
    if ($@) {
        carp "Geocoder not supported - $module\n";
        return 0;
    }

    $self->_recalculate_geocoder_stats();
    return 1;
}

=head2 set_filter_callback

Sets the callback used for filtering results. By default, all results are
passed through. If a callback is set, only results for which the callback
returns true are passed through. The callback takes one argument: a Response
object to be judged for fitness. It should return true or false, depending on
whether that Response is deemed suitable for consideration by the picker.

=cut

sub set_filter_callback {
    my ($self, $filter_callback) = @_;

    # If given a scalar, look up the name
    if (ref($filter_callback) eq '') {
        my %callback_names = (

            # Accepting all results is the default behaviour
            qr/(all)?/x => undef, 

        );
        $filter_callback = $self->_lookup_callback(
            $filter_callback,
            \%callback_names
        );
    }

    # We should now have a code reference
    if (defined $filter_callback && ref($filter_callback) ne 'CODE') {
        croak "set_filter_callback requires a scalar or a code reference\n";
    }

    $self->{filter_callback} = $filter_callback;
    return;
} 

=head2 set_picker_callback

Sets the callback used for result picking. This determines which single result
will actually be returned by the geocode method. By default, the first valid
result (that has passed the filter callback, if one was set) is returned.

As an alternative to passing a subroutine reference, you can pass a scalar with
a name that refers to one of the built-in callbacks. An empty string or 'first'
sets the behaviour back to the default: accept the first result that is
offered. 'max_precision' fetches all results and chooses the one with the
greatest precision value.

The picker callback has two arguments: a reference to an array of the valid
results that have been collected so far, and a value that is true if there are
more results available and false otherwise. The callback should return a single
result from the list, if one is acceptable. If none are acceptable, the
callback may return undef, indicating that more results to pick from are
desired. If these are available, the picker will be called again once they have
been added to the results array.

Note that since geocoders are not (currently) queried in parallel, a picker
that requires lots of results to make a decision may take longer to return a
value.

=cut

sub set_picker_callback {
    my ($self, $picker_callback) = @_;

    # If given a scalar, look up the name
    if (ref($picker_callback) eq '') {
        my %callback_names = (
            qr/(first)?/x      => undef,
            qr/max_precision/x => \&max_precision_picker,
        );
        $picker_callback = $self->_lookup_callback(
            $picker_callback, 
            \%callback_names,
        );
    }

    # We should now have a code reference
    if (defined $picker_callback && ref($picker_callback) ne 'CODE') {
        croak "set_picker_callback requires a scalar or a code reference\n";
    }

    $self->{picker_callback} = $picker_callback;
    return;
}

=head2 geocode

  my $options = {
      location        => $location,
      results_cache   => $cache,
  };

  my $found_location = $geocoder_many->geocode( $options );

Arguments should be provided in a hash reference with the following entries:

  KEY                   VALUE
  -----------           --------------------
  location              location string to pass to geocoder

  results_cache         reference to a cache object; will override the default

  no_cache              if set, the result will not be retrieved or set in
                        cache (off by default)

  wait_for_retries      if set, the method will wait until it's sure all
                        geocoders have been tried (off by default)

This method is the basis for the class, it will retrieve result from cache
first, and return if cache hit.

If the cache is missed, the C<geocode> method is called, with the location as 
the argument, on the next available geocoder object in the sequence.

If called in an array context all the matching results will be returned,
otherwise the first result will be returned.

A matching address will have the following keys in the hash reference.

  KEY                   VALUE
  -----------           --------------------
  response_code         integer response code (see below)

  address               matched address

  latitude              latitude of matched address

  longitude             longitude of matched address

  country               country of matched address (not available for all
                        geocoders)

  geocoder              source used to lookup address

  location              the original query string

  precision             scalar ranging from 0.0 to 1.0, denoting the
                        granularity of the result (undef if not known) 

The C<geocoder> key will contain a string denoting which geocoder returned the
results (eg, 'locatorize').

The C<response_code> key will contain the response code. The possible values
are:

  200   Success 
  210   Success (from cache)
  401   Unable to find location
  402   All geocoder limits reached (not yet implemented)

C<geocode> will return undef if none of the geocoders that were tried produced
a result that satisfied the filter and picker callbacks.

=cut

sub geocode {
    my ($self, $args) = @_;

    if ( !exists $args->{location} ) {
        croak "Geo::Coder::Many::geocode method requires a location!\n";
    }

    # If using cache, check that first
    if ( !$args->{no_cache} ){
        my $response = $self->_get_from_cache( 
            $args->{location}, 
            $args->{cache},
        );
        if ( defined $response ){
            return $response;
        }
    }

    if ( !keys %{$self->{geocoders}} ){
        carp "Warning: geocode called, but no geocoders have been added!\n";
        return;
    }

    my $previous_geocoder_name = '';
    my $ra_valid_results       = [];
    my $waiting_time           = 0;
    my $accepted_response      = undef;

    # We have not yet tried any geocoders for this query - tell the scheduler.
    $self->{scheduler}->reset_available();

    while ( !defined $accepted_response ) {

        # Check whether we have geocoders to try
        # (next_available gives us the minimum length of time until there may
        # be a working geocoder, or undef if this is infinite)
        $waiting_time = $self->{scheduler}->next_available();
        if (!defined $waiting_time) {
            # Run out of geocoders.
            last;
        }

        # If wait_for_retries is set, wait here until the time we were told 
        if ( $waiting_time > 0 && $args->{ wait_for_retries } ) {
            Time::HiRes::sleep($waiting_time);
        }

        my $geocoder = $self->_get_next_geocoder();

        # No more geocoders? We'll return undef later
        last if (!defined $geocoder);

        # Check the geocoder has an OK name
        my $geocoder_name = $geocoder->get_name();

        if ( $geocoder_name eq $previous_geocoder_name ) {
            carp "The scheduler is bad - it returned two geocoders with the "
                ."same name, between calls to reset_available!";
        }
        next if ( any { $geocoder_name eq $_ } @{$args->{geocoders_to_skip} || []} );

        # Use the current geocoder to geocode the requested location
        my $Response = $geocoder->geocode( $args->{location} );

        # Tell the scheduler about how successful the geocoder was
        if (defined $Response) {
            my $feedback = { 
                response_code => $Response->get_response_code(),
            };
            $self->{scheduler}->process_feedback($geocoder_name, $feedback);
        } 
        else {
            carp "Geocoder $geocoder_name returned undef.";
        }

        $previous_geocoder_name = $geocoder_name;

        # If our response has a valid code
        if ( $self->_response_valid($Response) ) {

            # Apply the filter callback to the response entries
            my @passed_responses = grep { 
                $self->_passes_filter($_)
            } $Response->get_responses();

            # If none passed, this whole response is no good.
            if (@passed_responses == 0) {
                next;
            }

            if ( defined ($self->{picker_callback}) ) {

                # Add any results that pass the filter to the array of valid
                # results to be picked from
                for my $result (@passed_responses) {
                    unshift (
                        @$ra_valid_results, 
                        $self->_form_response( $result, $Response )
                    );
                }

                # See whether this is good enough for the picker
                my $pc = $self->{picker_callback};

                my $more_available = 
                    defined $self->{scheduler}->next_available();

                my $picked = $pc->( $ra_valid_results, $more_available );

                # Found an agreeable response! Use that.
                if (defined $picked) {
                    $accepted_response = $picked;
                }
            } 
            else {
                # No picker? Just accept the first valid response.
                $accepted_response = $self->_form_response( 
                    $passed_responses[0], 
                    $Response 
                    );

            }

        }
    };

    # Definitely run out of geocoders - let's give the picker one last chance,
    # just in case.
    if (defined ($self->{picker_callback}) && !defined $accepted_response ) {
        $accepted_response = $self->{picker_callback}->( $ra_valid_results, 0 );
    }
    
    # If we're using a cache and we have a good response, let's cache it.
    if ( !$args->{no_cache} ) {
        $self->_set_in_cache(
            $args->{location}, 
            $accepted_response, 
            $args->{cache} 
        );
    }
    return $accepted_response;
}

=head2 get_geocoders

Returns a reference to a list of the geocoders that have been added to
the Many instance

=cut

sub get_geocoders { 
    my $self = shift;

    my $ra_geocoders = [];
    foreach my $key ( sort keys %{$self->{geocoders}} ) {
        push @{$ra_geocoders}, $self->{geocoders}->{$key};
    }
    return $ra_geocoders;
}


### INTERNAL METHODS

# _geocoder_module_is_compatible_with_plugin
#
# Check that the installed Geo::Coder module is compatible
# with the Geo::Coder::Many plugin, based on a minimum version
sub _geocoder_module_is_compatible_with_plugin {
    my ($self, $module, $plugin) = @_;

    if ($plugin->can("_MIN_MODULE_VERSION")) {
        my ($have_version, $min_version) = (
            $module->VERSION,
            $plugin->_MIN_MODULE_VERSION,
        );

        if (versioncmp($have_version, $min_version) < 0) {
            carp "$plugin requires $module $min_version or above";
            return 0;
        }
    }

    return 1;
}


# _form_response
#
# Takes a result hash and a Response object and mashes them into a single flat
# hash, allowing results from different geocoders to be more easily assimilated
#
sub _form_response {
    my ($self, $rh_result, $response) = @_;
    $rh_result->{location}      = $response->{location};
    $rh_result->{geocoder}      = $response->{geocoder};
    $rh_result->{response_code} = $response->{response_code};
    return $rh_result;
}

# _lookup_callback
#
# Given a name and a list of mappings from names to code references, do a fuzzy
# lookup of the name and return the appropriate subroutine.
#
sub _lookup_callback {
    my ($self, $name, $rh_callbacks) = @_;
    
    ref($name) eq ''
        or croak( "Trying to look up something which isn't a name!\n" );

    while (my ($name_regex, $callback) = each %{$rh_callbacks}) {
        my $regex = qr/^\s*$name_regex\s*$/msx;

        if ($name =~ $regex) {
            return $callback;
        }
    }

    carp( "\'$name\' is not a built-in callback.\n" );
    return;
}

# _response_valid
#
# Checks that a response is defined and has a valid response code,
#
sub _response_valid {
    my $self = shift;
    my $response = shift;
    if ( !defined($response) ) {
        return 0;
    }
    return HTTP::Response->new( $response->get_response_code )->is_success;
}

# _passes_filter
#
# Check a response passes the filter callback (if one is set).  
#
sub _passes_filter {
    my ($self, $response) = @_;
    if ( !defined $self->{filter_callback} ) {
        return 1;
    }
    return $self->{filter_callback}->( $response );
}

# _get_next_geocoder
#
# Requests the next geocoder from the scheduler and looks it up in the geocoders
# hash.
#
sub _get_next_geocoder {
    my $self = shift;

    my $next = $self->{scheduler}->get_next_unique();
    return if ( (!defined $next) || $next eq '');

    return $self->{geocoders}{$next};
}

# _recalculate_geocoder_stats
#
# Assigns weights to the current geocoders, and initialises the scheduler as
# appropriate.
#
sub _recalculate_geocoder_stats {
    my $self = shift;
    
    my $ra_geocoders = $self->get_geocoders();
    my $ra_slim_geocoders = [];

    foreach my $geocoder ( @{$ra_geocoders} ) {

        my $tmp = {
            weight  => $geocoder->get_daily_limit() || 1,
            name    => $geocoder->get_name(),
	};
        push @{$ra_slim_geocoders}, $tmp;
    }
    $self->{scheduler} = $self->_new_scheduler($ra_slim_geocoders);
    return;
}

# _new_scheduler
#
# Returns an instance of the currently-set scheduler, with the specified
# geocoders.
#
sub _new_scheduler {
    my $self      = shift;
    my $geocoders = shift;

    my $base_scheduler_name = "Geo::Coder::Many::Scheduler::";
    if ($self->{scheduler_type} =~ m/^(WRR|WeightedRandom)$/msx) {
        $base_scheduler_name .= "UniquenessScheduler::";
    }
    $base_scheduler_name .= $self->{scheduler_type};
    if ($self->{use_timeouts}) {
        return Geo::Coder::Many::Scheduler::Selective->new(
            $geocoders,
            $base_scheduler_name
        );
    } 
    return $base_scheduler_name->new($geocoders);
}

# _set_caching_object
#
# Set the list of cache objects
#
sub _set_caching_object {
    my $self = shift;
    my $cache_obj = shift;

    $self->_test_cache_object( $cache_obj );
    $self->{cache} = $cache_obj;
    $self->{cache_enabled} = 1;
    return;
}

# _test_cache_object
#
# Test the cache to ensure it has 'get', 'set' and 'remove' methods
#
sub _test_cache_object {
    my $self = shift;
    my $cache_object = shift;

    # Test to ensure the cache works
    {
        my $result = eval {
            $cache_object->set( '1234', 'test' );
            croak unless( $cache_object->get('1234') eq 'test' );
            1;
        };
        if ( (!$result) || $@ ) {
            croak "Unable to use user provided cache object: ". ref($cache_object);
        }
    }

    # Test to ensure the cache supports references
    {
        my $result = eval {
            $cache_object->set( 'abc', { a => 1, b => 2, c => 3 });
            croak unless ( $cache_object->get('abc')->{'b'} == 2 );
            1;
        };
        if ( (!$result) || $@ ) {
            croak "Unable to use user provided cache object "
                . "(references not stored safely): ", ref($cache_object);
        }
    }

    return;
}

# _set_in_cache
#
# Store the result in the cache
#
sub _set_in_cache {
    my $self     = shift;
    my $location = shift;
    my $Response = shift;
    my $cache    = shift || $self->{cache};

    if ($location && $cache){
	my $key = $self->_normalize_cache_key( $location ) || $location;
        $cache->set( $key, $Response );
        return 1;
    }
    return 0;
}

# _get_from_cache
#
# Check the cache to see if the data is available
#
sub _get_from_cache {
    my $self     = shift;
    my $location = shift;
    my $cache = shift || $self->{cache};

    if ( $cache && $location ) {
        my $key = $self->_normalize_cache_key($location) || $location;
        my $Response = $cache->get( $key );
        if ( $Response ) {
            $Response->{response_code} = 210;
            return $Response;
        }
    }
    return;
}

# _normalize_cache_key
#
# Use the provided normalize_code_ref callback (if one is set) to return a
# normalized string to use as a cache key.
#
sub _normalize_cache_key {
    my $self     = shift;
    my $location = shift;

    if ( $self->{normalize_code_ref} ) {
        my $code_ref = $self->{normalize_code_ref};
        return $code_ref->( $location ); 
    }
    return $location;
}

1;

__END__

=head1 NOTES

All cache objects used must support 'get', 'set' and 'remove' methods.
Additionally they must correctly deal with references by serializing them in
some way. We recommend using L<CHI|CHI> for this purpose.

The input (location) string is expected to be in utf-8. Incorrectly encoded
strings will make for unreliable geocoding results. All strings returned will
be in utf-8. returned latitude and longitude co-ordinates will be in WGS84
format.

In the case of an error, this module will print a warning and then may call
die().

=head1 Geo::Coder Interface

The Geo::Coder::* modules added to the geocoding source list must have a 
C<geocode> method which takes a single location string as an argument.

Currently supported Geo::Coder::* modules are:

  Geo::Coder::Bing
  Geo::Coder::Googlev3
  Geo::Coder::Mapquest
  Geo::Coder::OpenCage
  Geo::Coder::OSM

=head1 SEE ALSO

  Geo::Coder::Bing
  Geo::Coder::Googlev3
  Geo::Coder::Mapquest
  Geo::Coder::OpenCage
  Geo::Coder::OSM

Ed Freyfogle delivered a talk about Remote Geocoding and the
motivation for Geo::Coder::Many at the 2010 London Perl
Workshop. Slides are available
http://www.slideshare.net/lokku/remote-geocoding

=head1 AUTHOR

Originally Dan Horgan (http://search.cpan.org/~danhgn/) 

This module is no longer maintained by the team members of OpenCage Data Ltd
Ltd. (http://www.opencagedata.com)

Geo::Coder::Many was originally based on Geo::Coder::Multiple, which
unfortunately seems to no longer be maintained, by Alistair Francis
http://search.cpan.org/~friffin/

=head1 FEEDBACK

Please get in touch if you'd like to takeover ownership of this module

=head1 ACKNOWLEDGEMENTS

A number of the feature ideas are taken directly from Tim Bunce's blog:

http://blog.timbunce.org/2010/06/09/high-quality-multi-source-geocoding-in-perl/

Needless to say, neither he nor anybody else should be held responsible for
any deficiencies in the implementation!

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Opencage Data Ltd <cpan@opencagedata.com>

Please check out all our open source work over at 
https://github.com/opencagedata

Thanks!

Parts taken from Geo::Coder::Multiple are copyright 2009 Alistair Francis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut

