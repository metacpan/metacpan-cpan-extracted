# ABSTRACT: turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API

package Geo::What3Words;
$Geo::What3Words::VERSION = '3.0.3';
use strict;
use warnings;
use Cpanel::JSON::XS;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Encode qw( decode_utf8 );
use HTTP::Tiny;
use Net::Ping;
use Net::Ping::External;
use Ref::Util qw( is_hashref is_coderef );
use URI;
# DO NOT TRY TO USE URI::XS IT JUST LEADS TO PROBLEMS

my $JSONXS = Cpanel::JSON::XS->new->allow_nonref(1);




sub new {
    my ($class, %params) = @_;

    my $self = {};
    $self->{api_endpoint} = $params{api_endpoint} || 'https://api.what3words.com/v3/';
    $self->{key}          = $params{key}          || die "API key not set";
    $self->{language}     = $params{language};
    $self->{logging}      = $params{logging};

    ## _ua is used for testing. But could also be used to
    ## set proxies or such
    $self->{ua} = $params{ua} || HTTP::Tiny->new;

    my $version = $Geo::What3Words::VERSION || '';
    $self->{ua}->agent("Perl Geo::What3Words $version");

    return bless($self, $class);
}


sub ping {
    my $self = shift;

    ## http://example.com/some/path => example.com
    ## also works with IP addresses
    my $host = URI->new($self->{api_endpoint})->host;

    $self->_log("pinging $host...");

    my $netping = Net::Ping->new('external');
    my $res     = $netping->ping($host);

    $self->_log($res ? 'available' : 'unavailable');

    return $res;
}


sub words2pos {
    my ($self, @params) = @_;

    my $res = $self->words_to_position(@params);
    if ($res && is_hashref($res) && exists($res->{coordinates})) {
        return $res->{coordinates}->{lat} . ',' . $res->{coordinates}->{lng};
    }
    return;
}



sub pos2words {
    my ($self, @params) = @_;
    my $res = $self->position_to_words(@params);
    if ($res && is_hashref($res) && exists($res->{words})) {
        return $res->{words};
    }
    return;
}


sub valid_words_format {
    my $self  = shift;
    my $words = shift;

    ## Translating the PHP regular expression w3w uses in their
    ## documentation
    ## http://perldoc.perl.org/perlunicode.html#Unicode-Character-Properties
    ## http://php.net/manual/en/reference.pcre.pattern.differences.php
    return 0 unless $words;
    return 1 if ($words =~ m/^(\p{Lower}+)\.(\p{Lower}+)\.(\p{Lower}+)$/);
    return 0;
}


sub words_to_position {
    my $self  = shift;
    my $words = shift;

    return $self->_query_remote_api('convert-to-coordinates', {words => $words});

}


sub position_to_words {
    my $self     = shift;
    my $position = shift;
    my $language = shift || $self->{language};

    # https://developer.what3words.com/public-api/docs#convert-to-3wa
    return $self->_query_remote_api(
        'convert-to-3wa',
        {   coordinates => $position,
            language    => $language
        }
    );
}


sub get_languages {
    my $self     = shift;
    my $position = shift;
    return $self->_query_remote_api('available-languages');
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
        #a      => 1,
        key    => $self->{key},
        format => 'json',
        %$rh_params
    };

    foreach my $key (keys %$rh_fields) {
        delete $rh_fields->{$key} if (!defined($rh_fields->{$key}));
    }

    my $uri = URI->new($self->{api_endpoint} . $method_name);
    $uri->query_form($rh_fields);
    my $url = $uri->as_string;

    $self->_log("GET $url");
    my $response = $self->{ua}->get($url);

    if (!$response->{success}) {
        warn "got failed response from $url: " . $response->{status};
        $self->_log("got failed response from $url: " . $response->{status});
        return;
    }

    my $json = $response->{content};
    $json = decode_utf8($json);
    $self->_log($json);

    return $JSONXS->decode($json);
}

sub _log {
    my $self    = shift;
    my $message = shift;
    return unless $self->{logging};

    if (is_coderef($self->{logging})) {
        my $lc = $self->{logging};
        &$lc("Geo::What3Words -- " . $message);
    } else {
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

version 3.0.3

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

This module calls API version 3 (https://docs.what3words.com/public-api/) 
to convert coordinates into 3 word addresses (forward) and 3 
words into coordinates (reverse).

Versions 1 and 2 are deprecated and are no longer supported.

You need to sign up at http://what3words.com/login and then register for 
an API key at https://developer.what3words.com

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
  #        'coordinates' => {
  #                           'lat' => '51.484463',
  #                           'lng' => '-0.195405'
  #                         },
  #        'country' => 'GB',
  #        'language' => 'en',
  #        'map' => 'https://w3w.co/prom.cape.pump',
  #        'nearestPlace' => 'Kensington, London',
  #        'square' => {
  #                      'northeast' => {
  #                                       'lat' => '51.484476',
  #                                       'lng' => '-0.195383'
  #                                     },
  #                      'southwest' => {
  #                                       'lat' => '51.484449',
  #                                       'lng' => '-0.195426'
  #                                     }
  #                    },
  #        'words' => 'prom.cape.pump'
  #      };

=head2 position_to_words

Returns a more verbose response than pos2words.

  $w3w->position_to_words('51.484463,-0.195405')

  # {
  #        'coordinates' => {
  #                           'lat' => '51.484463',
  #                           'lng' => '-0.195405'
  #                         },
  #        'country' => 'GB',
  #        'language' => 'en',
  #        'map' => 'https://w3w.co/prom.cape.pump',
  #        'nearestPlace' => 'Kensington, London',
  #        'square' => {
  #                      'northeast' => {
  #                                       'lat' => '51.484476',
  #                                       'lng' => '-0.195383'
  #                                     },
  #                      'southwest' => {
  #                                       'lat' => '51.484449',
  #                                       'lng' => '-0.195426'
  #                                     }
  #                    },
  #        'words' => 'prom.cape.pump'
  #      };

=head2 get_languages

Retuns a list of language codes and names.

  $w3w->get_languages();
  # {
  #     'languages' => [
  #                      {
  #                        'name' => 'German',
  #                        'nativeName' => 'Deutsch',
  #                        'code' => 'de'
  #                      },
  #                      {
  #                        'name' => 'English',
  #                        'nativeName' => 'English',
  #                        'code' => 'en'
  #                      },
  #                      {
  #                        'name' => "Spanish",
  #                        'nativeName' => "Español",
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

This software is copyright (c) 2021 by OpenCage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
