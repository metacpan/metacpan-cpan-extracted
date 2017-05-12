package Google::BigQuery::V2;
use 5.010001;
use strict;
use warnings;

use base qw(Google::BigQuery);

use HTTP::Request;
use JSON qw(decode_json encode_json);
use URI::Escape;

sub new {
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(
    %args,
    GOOGLE_BIGQUERY_REST_DESCRIPTION => 'https://www.googleapis.com/discovery/v1/apis/bigquery/v2/rest',
    GOOGLE_BIGQUERY_API_BASE_URL => 'https://www.googleapis.com/bigquery/v2'
  );

  bless $self, $class;
}

sub DESTROY {
}

sub request {
  my ($self, %args) = @_;

  my $resource = $args{resource} || die;
  my $method = $args{method} || die;
  my $project_id = defined $args{project_id} ? $args{project_id} : $self->{project_id};
  my $dataset_id = defined $args{dataset_id} ? $args{dataset_id} : $self->{dataset_id};
  my $table_id = $args{table_id} || '';
  my $job_id = $args{job_id} || '';

  my $header = HTTP::Headers->new(Authorization => "Bearer $self->{access_token}{access_token}");
  my $rest_description = $self->{rest_description}{resources}{$resource}{methods}{$method} || die;
  my $http_method = $rest_description->{httpMethod};
  my $path = join('/', $self->{GOOGLE_BIGQUERY_API_BASE_URL}, $rest_description->{path});
  $path =~ s/{projectId}/$project_id/;
  $path =~ s/{datasetId}/$dataset_id/;
  $path =~ s/{tableId}/$table_id/;
  $path =~ s/{jobId}/$job_id/;

  if ($self->{exp} < time + 60) {
    $self->_auth;
  }

  my $request;
  if ($resource eq 'jobs' && $method eq 'insert') {
    my $sub_method = (keys %{$args{content}->{configuration}})[0];

    if ($sub_method !~ /^load$/ || defined $args{content}->{configuration}{load}{sourceUris}) {
      $request = HTTP::Request->new($http_method, $path, $header);
      if ($http_method =~ /^(?:POST|PUT|PATCH)$/) {
        $request->header('Content-Type' => 'application/json');
        $request->content(encode_json($args{content}));
      }
    } else {
      my $upload_path = $rest_description->{mediaUpload}{protocols}{simple}{path};
      $upload_path = "https://www.googleapis.com" . $upload_path;
      $upload_path =~ s/{projectId}/$project_id/;
      $upload_path .= "?uploadType=multipart";

      $header->header('Content-Type' => 'multipart/related');
      $request = HTTP::Request->new($http_method, $upload_path, $header);

      $request->add_part(
        HTTP::Message->new(
          ['Content-Type' => 'application/json; charset=UTF-8'],
          encode_json($args{content})
        )
      );

      my $data;
      open my $in, "<", $args{data} or die "can't open $args{data} : $!";
      $data = join('', <$in>);
      close $in;

      $request->add_part(
        HTTP::Message->new(
          ['Content-Type' => 'application/octet-stream'],
          $data
        )
      );
    }

    my $response = $self->{ua}->request($request);
    if (defined $response->content) {
      my $content = decode_json($response->content);
      if (defined $content->{error}) {
        return { error => { message => $content->{error}{message} } };
      } elsif ($response->code == 200) {
        my $json_response = decode_json($response->decoded_content);

        # return if async is true
        return $json_response if $args{async};

        my $job_id = $json_response->{jobReference}{jobId};
        while (1) {
          my $json_response = $self->request(method => 'get', resource => 'jobs', job_id => $job_id);
          if ($json_response->{status}{state} eq 'DONE') {
            return $json_response;
          } else {
            print "Wating...(state: $json_response->{status}{state})\n" if defined $self->{verbose};
            sleep(1);
          }
        }
      } else {
        die;
      }
    } else {
      die;
    }
  } else {
    if (defined $args{query_string} && %{$args{query_string}}) {
      my @query_string;
      while (my ($key, $value) = each %{$args{query_string}}) {
        push @query_string, join('=', uri_escape($key), uri_escape($value));
      }
      $path = join('?', $path, join('&', @query_string));
    }

    my $request = HTTP::Request->new($http_method, $path, $header);
    if ($http_method =~ /^(?:POST|PUT|PATCH)$/) {
      $request->header('Content-Type' => 'application/json');
      $request->content(encode_json($args{content}));
    }
    my $response = $self->{ua}->request($request);

    if ($response->code == 204) {
      return {};
    } elsif (defined $response->content) {
      # easy json check
      if ($response->content =~ /^\s*[{\[]/) {
        return decode_json($response->decoded_content);
      } else {
        return { error => { message => $response->content }};
      }
    } else {
      return { error => { message => 'Unknown Error' }};
    }
  }
}

1;
