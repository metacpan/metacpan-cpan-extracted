package Test::Unit::UriResponse;

# this started out as a (simple) way to match a uri/content request and
# simulate the json response from google. simple in concept, complex in
# implementation.
# there may be better ways to do this, it's escapted me thus far.

use Test::Unit::Setup;

use File::Slurp qw(read_file);
use Hash::Merge qw(merge);
use JSON::MaybeXS qw(JSON encode_json decode_json);
use List::Util qw(pairs);
use Text::Levenshtein::Flexible qw(levenshtein_lc);
use Try::Tiny;
use URI;
use YAML::Any qw(LoadFile);

sub new {
  my $class = shift;
  my $self = validate_named(\@_,
    request     => InstanceOf['HTTP::Request'],
    responses   => HashRef,
    cell_values => HashRef,
  );
  return bless $self, $class;
}

# intercept furl's call to the network and see if the uri and content match something
# that's already been registered previously. see etc/uri_responses.
sub response {
  my $self = shift;
  my $req = $self->{request};
  try {
    return $self->_response(@_);
  } catch {
    my $err = $_;
    die "Response processing failed: $err\n" . Dump($req);
  };
}

sub _response {
  my $self = shift;

  my $req = $self->{request};
  my $req_method = $req->method();
  my $req_uri = $req->uri();
  my $req_content_json = $req->content() ?
    JSON->new->ascii->pretty->canonical->encode(decode_json($req->content()))
    : '';

  my $matched_response = $self->find_response_by_uri($req_method, $req_uri);
  die "No response found for $req_method => $req_uri" if !defined $matched_response; # can be '' for deletes.

  # can be a simple response string, or a hash of content/response to match contents.
  my $response_item = $req_content_json ?
    $self->find_response_by_content($matched_response, $req_content_json) : $matched_response;
  my $response_json = $response_item->{response};
  die "No response/content found for $req_method => $req_uri"
    if !defined $response_json; # a response of '' is valid (e.g. for DELETE).

  my $response_file = fake_response_json_file($response_json);
  $response_json = read_file($response_file) if -f $response_file;

  my $tweaks = $response_item->{tweaks} || [];
  foreach my $tweak (@$tweaks) {
    my $method = "tweak_$tweak";
    $response_json = $self->$method($response_json, $req_uri, $req_content_json);
  }
  
  my $code = 200; my $message = 'ok';
  if ($response_json) {
    my $decoded = decode_json($response_json);
    $code = $decoded->{error}->{code} || $code;
    $message = $decoded->{error}->{message} || $message;
  }

  return ($response_json, $code, $message);
}

# see if the uri in the registered uris matches the one we're processing.
sub find_response_by_uri {
  my $self = shift;
  my ($method, $uri) = @_;

  # find the GET, POST etc hash of uri's.
  my $cmp_uris = $self->{responses}->{$method}
    or die "No matching method found for $method => $uri";

  my ($matched_uri) =
    map { $_->[0]; }
    sort { $a->[1] <=> $b->[1]; }
    grep { defined $_->[1]; }
    # max_distance, cost of insert, delete, substitution.
    # for the uri, if we have to insert or delete anything, reject it.
    # accept only substitutions.
    map { [ $_, levenshtein_lc($_, $uri, 999, 1000, 1000, 1) ]; }
    keys %$cmp_uris;
  $matched_uri or die "No matching uri found for $method => $uri";

  return $self->{responses}->{$method}->{$matched_uri}
}

# now that we have the correct uri, see if the content hash also has a match.
sub find_response_by_content {
  my $self = shift;
  my ($responses, $req_content_json) = @_;

  # there is no array of content to query in this case, we're responding with the same
  # thing no matter what is in the post content.
  return $responses if ref($responses) ne 'ARRAY';
  
  my ($response) =
    map { $_->[0] }
    sort { $a->[1] <=> $b->[1] }
    grep { defined $_->[1]; }
    map {
      my $cmp_content_json = $_->{content};
      my $cmp_content_file = fake_response_json_file($cmp_content_json);
      $cmp_content_json = read_file($cmp_content_file) if -f $cmp_content_file;
      $cmp_content_json = JSON->new->ascii->pretty->canonical->encode(decode_json($cmp_content_json));
      # max_distance, cost of insert, delete, substitution. inserting is ok for values
      # in the content. if we have to delete, reject it. substitution can occur for ranges.
      [ $_, levenshtein_lc($cmp_content_json, $req_content_json, 999, 1, 1000, 1) ]
    } @$responses;
  $response or die "No matching uri content found";
  
  return $response;
}

sub tweak_get_value {
  my $self = shift;
  my ($response_json, $uri) = @_;
  die "No response JSON found" if !$response_json;

  $uri = URI->new($uri);
  my ($sheet_range) = ($uri->path_segments())[-1];
  my ($sheet, $range) = _sheet_range($sheet_range);

  my $decoded = decode_json($response_json);
  my $value = $self->{cell_values}->{$sheet}->{$range};
  $decoded->{values} = $value if defined $value;

  return encode_json($decoded);
}

sub tweak_batch_get_values {
  my $self = shift;
  my ($response_json, $uri) = @_;
  die "No response JSON found" if !$response_json;

  my $decoded = decode_json($response_json);
  my $value_ranges = $decoded->{valueRanges}
    or die "No 'batch get' values found in json response";
  foreach my $value_range (@$value_ranges) {
    my ($sheet, $range) = _sheet_range($value_range->{range});
    my $value = $self->{cell_values}->{$sheet}->{$range};
    $value_range->{values} = $value if defined $value;
  }

  return encode_json($decoded);
}

sub tweak_batch_update_values {
  my $self = shift;
  my ($response_json, $uri, $content_json) = @_;
  die "No content JSON found" if !$content_json;

  my $content = decode_json($content_json);
  foreach my $value_range (@{ $content->{data}->[0] }) {
    my $values = $value_range->{values};
    my ($sheet, $range) = _sheet_range($value_range->{range});
    $self->{cell_values}->{$sheet}->{$range} = $values;

    # break column/row updates into individual cells.
    my ($start, $end) = split(':', $range);
    if ($start && $end && $start eq $end) {
      for my $i (0..$#{ $values->[0] }) {
        my $cell;
        $cell = $start . ($i + 1) if $start =~ m|^[A-Z]|;   # A:A for a column
        $cell = (('A'..'Z')[$i]) . $end if $start =~ m|^\d|; # 1:1 for a row
        $self->{cell_values}->{$sheet}->{$cell} = [[ $values->[0]->[$i] ]];
      }
    }
  }
  return $response_json;
}

sub tweak_dump_values {
  my $self = shift;
  my ($response_json) = @_;
  warn "Dump of saved cell values:\n" . Dump($self->{cell_values});
  return $response_json;
}

sub _sheet_range {
  my ($sheet_range) = @_;
  $sheet_range =~ s/\'//g;
  return split('!', $sheet_range);
}

1;
