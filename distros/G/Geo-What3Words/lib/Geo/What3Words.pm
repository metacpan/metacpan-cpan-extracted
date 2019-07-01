# ABSTRACT: turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API


package Geo::What3Words;
$Geo::What3Words::VERSION = '2.1.2';
use strict;
use warnings;
use URI;
use LWP::UserAgent;
use LWP::Protocol::https;
use Cpanel::JSON::XS;
use Data::Dumper;
use Net::Ping;
use Net::Ping::External;
use Encode;
my $JSONXS = Cpanel::JSON::XS->new->allow_nonref(1);








sub new {
  my ($class, %params) = @_;

  my $self = {};
  $self->{api_endpoint}     = $params{api_endpoint} || 'https://api.what3words.com/v2/';
  $self->{key}              = $params{key}      || die "API key not set";
  $self->{language}         = $params{language};
  $self->{logging}          = $params{logging};

  ## _ua is used for testing. But could also be used to
  ## set proxies or such
  $self->{ua} = $params{ua} || LWP::UserAgent->new;

  my $version  = $Geo::What3Words::VERSION || '';
  $self->{ua}->agent("Perl Geo::What3Words $version");

  return bless($self,$class);
}







sub ping {
  my $self = shift;

  ## http://example.com/some/path => example.com
  ## also works with IP addresses
  my $host = URI->new($self->{api_endpoint})->host;

  $self->_log("pinging $host...");

  my $netping = Net::Ping->new('external');
  my $res = $netping->ping($host);

  $self->_log($res ? 'available' : 'unavailable');

  return $res;
}








sub words2pos {
  my ($self, @params) = @_;
  my $res = $self->words_to_position(@params);

  if ( $res && ref($res) eq 'HASH' && exists($res->{geometry}) ){
    return $res->{geometry}->{lat} . ',' . $res->{geometry}->{lng};
  }
  return;
}








sub pos2words {
  my ($self, @params) = @_;
  my $res = $self->position_to_words(@params);

  if ( $res && ref($res) eq 'HASH' && exists($res->{words}) ){
    return $res->{words};
  }
  return;
}









sub valid_words_format {
  my $self = shift;
  my $words = shift;

  ## Translating the PHP regular expression w3w uses in their
  ## documentation
  ## http://perldoc.perl.org/perlunicode.html#Unicode-Character-Properties
  ## http://php.net/manual/en/reference.pcre.pattern.differences.php
  return 0 unless $words;
  return 1 if ($words =~ m/^(\p{Lower}+)\.(\p{Lower}+)\.(\p{Lower}+)$/ );
  return 0;
}






sub words_to_position {
  my $self = shift;
  my $words = shift;
  my $language = shift || $self->{language};

  return $self->_query_remote_api('forward', {addr => $words, lang => $language });
}











sub position_to_words {
  my $self = shift;
  my $position = shift;
  my $language = shift || $self->{language};

  return $self->_query_remote_api('reverse', {coords => $position, lang => $language });
}


sub get_languages {
  my $self = shift;
  my $position = shift;

  return $self->_query_remote_api('languages');
}

sub oneword_available {
  warn 'deprecated method: oneword_available';
  return;
}

sub _query_remote_api {
  my $self        = shift;
  my $method_name = shift;
  my $rh_params   = shift || {};

  my $rh_fields = {
    a=> 1,
      key    => $self->{key},
      format => 'json',
      %$rh_params
  };
  foreach my $key (keys %$rh_fields){
    delete $rh_fields->{$key} if (!defined($rh_fields->{$key}));
  }

  my $uri = URI->new($self->{api_endpoint} . $method_name);
  $uri->query_form( $rh_fields );
  my $url = $uri->as_string;

  $self->_log("GET $url");
  my $response = $self->{ua}->get($url);

  if ( ! $response->is_success) {
    warn "got failed response from $url: " . $response->status_line;
    $self->_log("got failed response from $url: " . $response->status_line);
    return;
  }

  my $json = $response->decoded_content;
  $json = decode_utf8($json);
  $self->_log($json);

  return $JSONXS->decode($json);
}

sub _log {
  my $self    = shift;
  my $message = shift;
  return unless $self->{logging};

  if ( ref($self->{logging}) eq 'CODE' ){
    my $lc = $self->{logging};
    &$lc("Geo::What3Words -- " . $message);
  }
  else {
    print "Geo::What3Words -- " . $message . "\n";
  }
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::What3Words - turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API

=head1 VERSION

version 2.1.2

=head1 SYNOPSIS

  my $w3w = Geo::What3Words->new();

  $w3w->pos2words('51.484463,-0.195405');
  # returns 'three.example.words'

  $w3w->pos2words('51.484463,-0.195405', 'ru');
  # returns 'три.пример.слова'

  $w3w->words2pos('three.example.words');
  # returns '51.484463,-0.195405' (latitude,longitude)

=head1 DESCRIPTION

what3words (http://what3words.com/) divides the world into 57 trillion squares
of 3 metres x 3 metres. Each square has been given a 3 word address comprised
of 3 words from the dictionary.

This module calls API version 2 (https://docs.what3words.com/api/v2/) to convert
coordinates into those 3 word addresses (forward) and 3 words into coordinates
(reverse).

Version 1 is deprecated and will stop working December 2016.

You need to sign up at http://what3words.com/login and then register for an API key
at https://what3words.com/get-api-key/

=head1 METHODS

=head2 new

Creates a new instance. The api key is required.

  my $w3w = Geo::What3Words->new( key => 'your-api-key' );
  my $w3w = Geo::What3Words->new( key => 'your-api-key', language => 'ru' );

For debugging you can either set logging or provide a callback.

  my $w3w = Geo::What3Words->new( key => 'your-api-key', logging => 1 );
  # will print debugging output to STDOUT

  my $callback = sub { my $msg = shift; $my_log4perl_logger->info($msg) };
  my $w3w = Geo::What3Words->new( key => 'your-api-key', logging => $callback );
  # will log with log4perl.

=head2 ping

Check if the remote server is available. This is helpful for debugging or
testing, but too slow to run for every conversion.

  $w3w->ping();

=head2 words2pos

Tiny wrapper around words_to_position.

  $w3w->words2pos('three.example.words');
  # returns '51.484463,-0.195405' (latitude,longitude)

  $w3w->words2pos('does.not.exist');
  # returns undef

=head2 pos2words

Tiny wrapper around position_to_words.

  $w3w->pos2words('51.484463,-0.195405'); # latitude,longitude
  # returns 'three.example.words'

  $w3w->pos2words('51.484463,-0.195405', 'ru');
  # returns 'три.пример.слова'

  $w3w->pos2words('invalid,coords');
  # returns undef

=head2 valid_words_format

Returns 1 if the string looks like three words, 0 otherwise. Does
not call the remote API.

  $w3w->valid_words_format('one.two.three');
  # returns 1

=head2 words_to_position

Returns a more verbose response than words2pos.

  $w3w->words_to_position('prom.cape.pump');
  # {
  #   "crs": {
  #     "type": "link",
  #     "properties": {
  #       "href": "http://spatialreference.org/ref/epsg/4326/ogcwkt/",
  #       "type": "ogcwkt"
  #     }
  #   },
  #   "words": "prom.cape.pump",
  #   "bounds": {
  #     "southwest": {
  #       "lng": "-0.195426",
  #       "lat":"51.484449"
  #     },
  #     "northeast": {
  #       "lng": "-0.195383",
  #       "lat": "51.484476"
  #     }
  #   },
  #   "geometry": {
  #     "lng": "-0.195405",
  #     "lat": "51.484463"
  #   },
  #   "language": "en",
  #   "map": "http://w3w.co/prom.cape.pump",
  #   "status": {
  #     "status": 200,
  #     "reason": "OK"
  #   },
  #   "thanks": "Thanks from all of us at index.home.raft for using a what3words API"
  # }

=head2 position_to_words

Returns a more verbose response than pos2words.

  $w3w->position_to_words('51.484463,-0.195405')
  # {
  #   "crs": {
  #     "type": "link",
  #     "properties": {
  #       "href": "http://spatialreference.org/ref/epsg/4326/ogcwkt/",
  #       "type": "ogcwkt"
  #     }
  #   },
  #   "words": "prom.cape.pump",
  #   "bounds": {
  #     "southwest": {
  #       "lng": "-0.195426",
  #       "lat": "51.484449"
  #     },
  #     "northeast": {
  #       "lng": "-0.195383",
  #       "lat": "51.484476"
  #     }
  #   },
  #   "geometry": {
  #     "lng": "-0.195405",
  #     "lat": "51.484463"
  #   },
  #   "language": "en",
  #   "map": "http://w3w.co/prom.cape.pump",
  #   "status": {
  #     "status": 200,
  #     "reason": "OK"
  #   },
  #   "thanks": "Thanks from all of us at index.home.raft for using a what3words API"
  # }

=head2 get_languages

Retuns a list of language codes and names.

  $w3w->get_languages();
  # {
  #     'languages' => [
  #                      {
  #                        'name' => 'German',
  #                        'name_native' => 'Deutsch',
  #                        'code' => 'de'
  #                      },
  #                      {
  #                        'name' => 'English',
  #                        'name_native' => 'English',
  #                        'code' => 'en'
  #                      },
  #                      {
  #                        'name' => "Spanish",
  #                        'name_native' => "Español",
  #                        'code' => 'es'
  #                      },
  # ...

=head1 INSTALLATION

The test suite will use pre-recorded API responses. If you suspect something
changed in the API you can force the test suite to use live requests with
your API key

    PERLLIB=./lib W3W_RECORD_REQUESTS=1 W3W_API_KEY=<your key> perl t/base.t

=head1 AUTHOR

mtmail <mtmail-cpan@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by OpenCage Data Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
