package Google::BigQuery;
use 5.010001;
use strict;
use warnings;

our $VERSION = "1.02";

use Class::Load qw(load_class);
use Crypt::OpenSSL::PKCS12;
use JSON qw(decode_json encode_json);
use JSON::WebToken;
use LWP::UserAgent;

sub create {
  my (%args) = @_;

  my $version = $args{version} // 'v2';
  my $class = 'Google::BigQuery::' . ucfirst($version);

  if (load_class($class)) {
    return $class->new(%args);
  } else {
    die "Can't load class: $class";
  }
}

sub new {
  my ($class, %args) = @_;

  die "undefined client_eamil" if !defined $args{client_email};
  die "undefined private_key_file" if !defined $args{private_key_file};
  die "not found private_key_file" if !-f $args{private_key_file};

  my $self = bless { %args }, $class;

  $self->{GOOGLE_API_TOKEN_URI} = 'https://accounts.google.com/o/oauth2/token';
  $self->{GOOGLE_API_GRANT_TYPE} = 'urn:ietf:params:oauth:grant-type:jwt-bearer';

  if ($self->{private_key_file} =~ /\.json$/) {
    open my $in, "<", $self->{private_key_file} or die "can't open $self->{private_key_file} : $!";
    my $private_key_json = decode_json(join('', <$in>));
    close $in;
    $self->{private_key} = $private_key_json->{private_key};
  } elsif ($self->{private_key_file} =~ /\.p12$/) {
    my $password = "notasecret";
    my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file($self->{private_key_file});
    $self->{private_key} = $pkcs12->private_key($password);
  } else {
    die "invalid private_key_file format";
  }

  $self->_auth;
  $self->_set_rest_description;

  return $self;
}

sub DESTROY {
}

sub _auth {
  my ($self) = @_;

  $self->{scope} //= [qw(https://www.googleapis.com/auth/bigquery)];
  $self->{exp} = time + 3600;
  $self->{iat} = time;
  $self->{ua} = LWP::UserAgent->new;

  my $claim = {
    iss => $self->{client_email},
    scope => join(" ", @{$self->{scope}}),
    aud => $self->{GOOGLE_API_TOKEN_URI},
    exp => $self->{exp},
    iat => $self->{iat},
  };

  my $jwt = JSON::WebToken::encode_jwt($claim, $self->{private_key}, 'RS256', { type => 'JWT' });

  my $response = $self->{ua}->post(
    $self->{GOOGLE_API_TOKEN_URI},
    { grant_type => $self->{GOOGLE_API_GRANT_TYPE}, assertion => $jwt }
  );

  if ($response->is_success) {
    $self->{access_token} = decode_json($response->decoded_content);
  } else {
    my $error = decode_json($response->decoded_content);
    die $error->{error};
  }
}

sub _set_rest_description {
  my ($self) = @_;
  my $response = $self->{ua}->get($self->{GOOGLE_BIGQUERY_REST_DESCRIPTION});
  $self->{rest_description} = decode_json($response->decoded_content);
}

sub use_project {
  my ($self, $project_id) = @_;
  $self->{project_id} = $project_id // return;
}

sub use_dataset {
  my ($self, $dataset_id) = @_;
  $self->{dataset_id} = $dataset_id // return;
}

sub create_dataset {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }

  my $content = {
    datasetReference => {
      projectId => $project_id,
      datasetId => $dataset_id
    }
  };

  # option
  $content->{access} = $args{access} if defined $args{access};
  $content->{description} = $args{description} if defined $args{description};
  $content->{friendlyName} = $args{friendlyName} if defined $args{friendlyName};

  my $response = $self->request(
    resource => 'datasets',
    method => 'insert',
    project_id => $project_id,
    dataset_id => $dataset_id,
    content => $content,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } else {
    return 1;
  }
}

sub drop_dataset {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }

  # option
  my $query_string = {};
  if (defined $args{deleteContents}) {
    $query_string->{deleteContents} = $args{deleteContents} ? 'true' : 'false';
  }

  my $response = $self->request(
    resource => 'datasets',
    method => 'delete',
    project_id => $project_id,
    dataset_id => $dataset_id,
    query_string => $query_string,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } else {
    return 1;
  }
}

sub show_datasets {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};

  unless ($project_id) {
    warn "no project\n";
    return undef;
  }

  # option
  my $query_string = {};
  if (defined $args{all}) {
    $query_string->{all} = $args{all} ? 'true' : 'false';
  }
  $query_string->{maxResults} = $args{maxResults} if defined $args{maxResults};
  $query_string->{pageToken} = $args{pageToken} if defined $args{pageToken};

  my $response = $self->request(
    resource => 'datasets',
    method => 'list',
    project_id => $project_id,
    query_string => $query_string,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return undef;
  }

  my @ret = ();
  foreach my $dataset (@{$response->{datasets}}) {
    push @ret, $dataset->{datasetReference}{datasetId};
  }

  return @ret;
}

sub desc_dataset {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }

  my $response = $self->request(
    resource => 'datasets',
    method => 'get',
    project_id => $project_id,
    dataset_id => $dataset_id,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return undef;
  } else {
    return $response;
  }
}

sub create_table {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }

  my $content = {
    tableReference => {
      projectId => $project_id,
      datasetId => $dataset_id,
      tableId => $table_id
    },
  };

  # option
  $content->{description} = $args{description} if defined $args{description};
  $content->{expirationTime} = $args{expirationTime} if defined $args{expirationTime};
  $content->{friendlyName} = $args{friendlyName} if defined $args{friendlyName};
  $content->{schema}{fields} = $args{schema} if defined $args{schema};
  $content->{view}{query} = $args{view} if defined $args{view};

  my $response = $self->request(
    resource => 'tables',
    method => 'insert',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
    content => $content,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } elsif (defined $args{schema} && !defined $response->{schema}) {
    warn "no create schema";
    return 0;
  } else {
    return 1;
  }
}

sub drop_table {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }

  my $response = $self->request(
    resource => 'tables',
    method => 'delete',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } else {
    return 1;
  }
}

sub show_tables {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($project_id) {
    warn "no project\n";
    return undef;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return undef;
  }

  # option
  my $query_string = {};
  $query_string->{maxResults} = $args{maxResults} if defined $args{maxResults};
  $query_string->{pageToken} = $args{pageToken} if defined $args{pageToken};

  my $response = $self->request(
    resource => 'tables',
    method => 'list',
    project_id => $project_id,
    dataset_id => $dataset_id,
    query_string => $query_string,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return undef;
  }

  my @ret = ();
  foreach my $table (@{$response->{tables}}) {
    push @ret, $table->{tableReference}{tableId};
  }

  return @ret;
}

sub desc_table {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }

  my $response = $self->request(
    resource => 'tables',
    method => 'get',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return undef;
  } else {
    return $response;
  }
}

sub load {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};
  my $data = $args{data};
  my $async = $args{async} // 0;

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }
  unless ($data) {
    warn "no data\n";
    return 0;
  }

  my $content = {
    configuration => {
      load => {
        destinationTable => {
          projectId => $project_id,
          datasetId => $dataset_id,
          tableId => $table_id,
        }
      }
    }
  };

  if (ref($data) =~ /ARRAY/) {
    $content->{configuration}{load}{sourceUris} = $data;
  } elsif ($data =~ /^gs:\/\//) {
    $content->{configuration}{load}{sourceUris} = [($data)];
  }

  my $suffix;
  if (defined $content->{configuration}{load}{sourceUris}) {
    $suffix = $1 if $content->{configuration}{load}{sourceUris}[0] =~ /\.(tsv|csv|json)(?:\.gz)?$/i;
  } else {
    $suffix = $1 if $data =~ /\.(tsv|csv|json)(?:\.gz)?$/i;
  }

  if (defined $suffix) {
    my $source_format;
    my $field_delimiter;
    if ($suffix =~ /^tsv$/i) {
      $field_delimiter = "\t";
    } elsif ($suffix =~ /^json$/i) {
      $source_format = "NEWLINE_DELIMITED_JSON";
    }
    $content->{configuration}{load}{sourceFormat} = $source_format if defined $source_format;
    $content->{configuration}{load}{fieldDelimiter} = $field_delimiter if defined $field_delimiter;
  }

  # load options
  if (defined $args{allowJaggedRows}) {
    $content->{configuration}{load}{allowJaggedRows} = $args{allowJaggedRows} ? 'true' : 'false';
  }
  if (defined $args{allowQuotedNewlines}) {
    $content->{configuration}{load}{allowQuotedNewlines} = $args{allowQuotedNewlines} ? 'true' : 'false';
  }
  $content->{configuration}{load}{createDisposition} = $args{createDisposition} if defined $args{createDisposition};
  $content->{configuration}{load}{encoding} = $args{encoding} if defined $args{encoding};
  $content->{configuration}{load}{fieldDelimiter} = $args{fieldDelimiter} if defined $args{fieldDelimiter};
  if (defined $args{ignoreUnknownValues}) {
    $content->{configuration}{load}{ignoreUnknownValues} = $args{ignoreUnknownValues} ? 'true' : 'false';
  }
  $content->{configuration}{load}{maxBadRecords} = $args{maxBadRecords} if defined $args{maxBadRecords};
  $content->{configuration}{load}{quote} = $args{quote} if defined $args{quote};
  $content->{configuration}{load}{schema}{fields} = $args{schema} if defined $args{schema};
  $content->{configuration}{load}{skipLeadingRows} = $args{skipLeadingRows} if defined $args{skipLeadingRows};
  $content->{configuration}{load}{sourceFormat} = $args{sourceFormat} if defined $args{sourceFormat};
  $content->{configuration}{load}{sourceUris} = $args{sourceUris} if defined $args{sourceUris};
  $content->{configuration}{load}{writeDisposition} = $args{writeDisposition} if defined $args{writeDisposition};

  my $response = $self->request(
    resource => 'jobs',
    method => 'insert',
    project_id => $project_id,
    dataset_id => $dataset_id,
    talbe_id => $table_id,
    content => $content,
    data => $data,
    async => $async
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } elsif ($async) {
    # return job_id if async is true.
    return $response->{jobReference}{jobId};
  } elsif ($response->{status}{state} eq 'DONE') {
    if (defined $response->{status}{errors}) {
      foreach my $error (@{$response->{status}{errors}}) {
        warn encode_json($error), "\n";
      }
      return 0;
    } else {
      return 1;
    }
  } else {
    return 0;
  }
}

sub insert {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};
  my $values = $args{values};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }
  unless ($values) {
    warn "no values\n";
    return 0;
  }

  my $rows = [];
  foreach my $value (@$values) {
    push @$rows, { json => $value };
  }

  my $response = $self->request(
    resource => 'tabledata',
    method => 'insertAll',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
    content => {
      rows => $rows
    }
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } elsif (defined $response->{insertErrors}) {
    foreach my $error (@{$response->{insertErrors}}) {
      warn encode_json($error), "\n";
    }
    return 0;
  } else {
    return 1;
  }
}

sub selectrow_array {
  my ($self, %args) = @_;

  my $query = $args{query};
  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($query) {
    warn "no query\n";
    return 0;
  }
  unless ($project_id) {
    warn "no project\n";
    return 0;
  }

  my $content = {
    query => $query,
  };

  # option
  if (defined $dataset_id) {
    $content->{defaultDataset}{projectId} = $project_id;
    $content->{defaultDataset}{datasetId} = $dataset_id;
  }
  $content->{maxResults} = $args{maxResults} if defined $args{maxResults};
  $content->{timeoutMs} = $args{timeoutMs} if defined $args{timeoutMs};
  if (defined $args{dryRun}) {
    $content->{dryRun} = $args{dryRun} ? 'true' : 'false';
  }
  if (defined $args{useQueryCache}) {
    $content->{useQueryCache} = $args{useQueryCache} ? 'true' : 'false';
  }

  my $response = $self->request(
    resource => 'jobs',
    method => 'query',
    content => $content
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  }

  my @ret = ();
  foreach my $field (@{$response->{rows}[0]{f}}) {
    push @ret, $field->{v};
  }

  return @ret;
}

sub selectall_arrayref {
  my ($self, %args) = @_;

  my $query = $args{query};
  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($query) {
    warn "no query\n";
    return 0;
  }
  unless ($project_id) {
    warn "no project\n";
    return 0;
  }

  my $content = {
    query => $query,
  };

  # option
  if (defined $dataset_id) {
    $content->{defaultDataset}{projectId} = $project_id;
    $content->{defaultDataset}{datasetId} = $dataset_id;
  }
  $content->{maxResults} = $args{maxResults} if defined $args{maxResults};
  $content->{timeoutMs} = $args{timeoutMs} if defined $args{timeoutMs};
  if (defined $args{dryRun}) {
    $content->{dryRun} = $args{dryRun} ? 'true' : 'false';
  }
  if (defined $args{useQueryCache}) {
    $content->{useQueryCache} = $args{useQueryCache} ? 'true' : 'false';
  }

  my $response = $self->request(
    resource => 'jobs',
    method => 'query',
    content => $content
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  }

  my $ret = [];
  foreach my $rows (@{$response->{rows}}) {
    my $row = [];
    foreach my $field (@{$rows->{f}}) {
      push @$row, $field->{v};
    }
    push @$ret, $row;
  }

  return $ret;
}

sub is_exists_dataset {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }

  my $response = $self->request(
    resource => 'datasets',
    method => 'get',
    project_id => $project_id,
    dataset_id => $dataset_id
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    #warn $response->{error}{message};
    return 0;
  } else {
    return 1;
  }
}

sub is_exists_table {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }

  my $response = $self->request(
    resource => 'tables',
    method => 'get',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    #warn $response->{error}{message};
    return 0;
  } else {
    return 1;
  }
}

sub extract {
  my ($self, %args) = @_;

  my $project_id = $args{project_id} // $self->{project_id};
  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $table_id = $args{table_id};
  my $data = $args{data};

  unless ($project_id) {
    warn "no project\n";
    return 0;
  }
  unless ($dataset_id) {
    warn "no dataset\n";
    return 0;
  }
  unless ($table_id) {
    warn "no table\n";
    return 0;
  }
  unless ($data) {
    warn "no data\n";
    return 0;
  }

  my $content = {
    configuration => {
      extract => {
        sourceTable => {
          projectId => $project_id,
          datasetId => $dataset_id,
          tableId => $table_id,
        }
      }
    }
  };

  if (ref($data) =~ /ARRAY/) {
    $content->{configuration}{extract}{destinationUris} = $data;
  } elsif ($data =~ /^gs:\/\//) {
    $content->{configuration}{extract}{destinationUris} = [($data)];
  } else {
    $content->{configuration}{extract}{destinationUris} = [('')];
  }

  my $suffix;
  my $compression;
  if (defined $content->{configuration}{extract}{destinationUris}) {
    $suffix = $1 if $content->{configuration}{extract}{destinationUris}[0] =~ /\.(tsv|csv|json|avro)(?:\.gz)?$/i;
    $compression = 'GZIP' if $content->{configuration}{extract}{destinationUris}[0] =~ /\.gz$/i;
  }

  if (defined $suffix) {
    my $destination_format;
    my $field_delimiter;
    if ($suffix =~ /^tsv$/i) {
      $field_delimiter = "\t";
    } elsif ($suffix =~ /^json$/i) {
      $destination_format = "NEWLINE_DELIMITED_JSON";
    } elsif ($suffix =~ /^avro$/) {
      $destination_format = "AVRO";
    }
    $content->{configuration}{extract}{destinationFormat} = $destination_format if defined $destination_format;
    $content->{configuration}{extract}{fieldDelimiter} = $field_delimiter if defined $field_delimiter;
  }
  $content->{configuration}{extract}{compression} = $compression if defined $compression;

  # extract options
  $content->{configuration}{extract}{compression} = $args{compression} if defined $args{compression};
  $content->{configuration}{extract}{destinationFormat} = $args{destinationFormat} if defined $args{destinationFormat};
  $content->{configuration}{extract}{destinationUris} = $args{destinationUris} if defined $args{destinationUris};
  $content->{configuration}{extract}{fieldDelimiter} = $args{fieldDelimiter} if defined $args{fieldDelimiter};
  if (defined $args{printHeader}) {
    $content->{configuration}{extract}{printHeader} = $args{printHeader} ? 'true' : 'false';
  }

  my $response = $self->request(
    resource => 'jobs',
    method => 'insert',
    project_id => $project_id,
    dataset_id => $dataset_id,
    talbe_id => $table_id,
    content => $content,
    data => $data
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return 0;
  } elsif ($response->{status}{state} eq 'DONE') {
    if (defined $response->{status}{errors}) {
      foreach my $error (@{$response->{status}{errors}}) {
        warn encode_json($error), "\n";
      }
      return 0;
    } else {
      return 1;
    }
  } else {
    return 0;
  }
}

sub get_nextPageToken {
  my $self = shift;

  if (defined $self->{response}{nextPageToken}) {
    return $self->{response}{nextPageToken};
  } else {
    return undef;
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

Google::BigQuery - Google BigQuery Client Library for Perl

=head1 SYNOPSIS

    use Google::BigQuery;

    my $client_email = <YOUR CLIENT EMAIL ADDRESS>;
    my $private_key_file = <YOUR PRIVATE KEY FILE>;
    my $project_id = <YOUR PROJECT ID>;

    # create a instance
    my $bq = Google::BigQuery::create(
      client_email => $client_email,
      private_key_file => $private_key_file,
      project_id => $project_id,
    );

    # create a dataset
    my $dataset_id = <YOUR DATASET ID>;
    $bq->create_dataset(
      dataset_id => $dataset_id
    );
    $bq->use_dataset($dataset_id);

    # create a table
    my $table_id = 'sample_table';
    $bq->create_table(
      table_id => $table_id,
      schema => [
        { name => "id", type => "INTEGER", mode => "REQUIRED" },
        { name => "name", type => "STRING", mode => "NULLABLE" }
      ]
    );

    # load
    my $load_file = "load_file.tsv";
    open my $out, ">", $load_file or die;
    for (my $id = 1; $id <= 100; $id++) {
      if ($id % 10 == 0) {
        print $out join("\t", $id, undef), "\n";
      } else {
        print $out join("\t", $id, "name-${id}"), "\n";
      }
    }
    close $out;

    $bq->load(
      table_id => $table_id,
      data => $load_file,
    );
      
    unlink $load_file;

    # insert
    my $values = [];
    for (my $id = 101; $id <= 103; $id++) {
      push @$values, { id => $id, name => "name-${id}" };
    }
    $bq->insert(
      table_id => $table_id,
      values => $values,
    );

    # The first time a streaming insert occurs, the streamed data is inaccessible for a warm-up period of up to two minutes.
    sleep(120);

    # selectrow_array
    my ($count) = $bq->selectrow_array(query => "SELECT COUNT(*) FROM $table_id");
    print $count, "\n"; # 103

    # selectall_arrayref
    my $aref = $bq->selectall_arrayref(query => "SELECT * FROM $table_id ORDER BY id");
    foreach my $ref (@$aref) {
      print join("\t", @$ref), "\n";
    }

    # drop table
    $bq->drop_table(table_id => $table_id);

    # drop dataset
    $bq->drop_dataset(dataset_id => $dataset_id);

=head1 DESCRIPTION

Google::BigQuery - Google BigQuery Client Library for Perl

=head1 INSTALL

  cpanm Google::BigQuery

If such a following error occurrs,

  --> Working on Crypt::OpenSSL::PKCS12
  Fetching http://www.cpan.org/authors/id/D/DA/DANIEL/Crypt-OpenSSL-PKCS12-0.7.tar.gz ... OK
  Configuring Crypt-OpenSSL-PKCS12-0.6 ... N/A
  ! Configure failed for Crypt-OpenSSL-PKCS12-0.6. See /home/vagrant/.cpanm/work/1416208473.2527/build.log for details.

For now, you can work around it as below.

  # cd workdir
  cd /home/vagrant/.cpanm/work/1416208473.2527/Crypt-OpenSSL-PKCS12-0.7
  rm -fr inc
  cpanm Module::Install

  ### If you are a Mac user, you might also need the following steps.
  #
  # 1. Install new OpenSSL library and header.
  # brew install openssl
  #
  # 2. Add a lib_path and a includ_path to the Makefile.PL.
  # --- Makefile.PL.orig    2013-12-01 07:41:25.000000000 +0900
  # +++ Makefile.PL 2014-11-18 11:58:39.000000000 +0900
  # @@ -17,8 +17,8 @@
  #
  #  requires_external_cc();
  #
  # -cc_inc_paths('/usr/include/openssl', '/usr/local/include/ssl', '/usr/local/ssl/include');
  # -cc_lib_paths('/usr/lib', '/usr/local/lib', '/usr/local/ssl/lib');
  # +cc_inc_paths('/usr/local/opt/openssl/include', '/usr/include/openssl', '/usr/local/include/ssl', '/usr/local/ssl/include');
  # +cc_lib_paths('/usr/local/opt/openssl/lib', '/usr/lib', '/usr/local/lib', '/usr/local/ssl/lib');
  
  perl Makefile.PL
  make
  make test
  make install


=head1 METHODS

See details of option at https://cloud.google.com/bigquery/docs/reference/v2/.

=over 4

=item * create

Create a instance.

  my $bq = Google::BigQuery::create(
    client_email => $client_email,            # required
    private_key_file => $private_key_file,    # required
    project_id => $project_id,                # optional
    dataset_id => $dataset_id,                # optional
    scope => \@scope,                         # optional (default is 'https://www.googleapis.com/auth/bigquery')
    version => $version,                      # optional (only 'v2')
  );

=item * use_project

Set a default project.

  $bq->use_project($project_id);

=item * use_dataset

Set a default dataset.

  $bq->use_dataset($dataset_id);

=item * create_dataset

Create a dataset.

  $bq->create_dataset(              # return 1 (success) or 0 (error)
    project_id => $project_id,      # required if default project is not set
    dataset_id => $dataset_id,      # required if default dataset is not set
    access => \@access,             # optional
    description => $description,    # optional
    friendlyName => $friendlyName,  # optional
  );

=item * drop_dataset

Drop a dataset.

  $bq->drop_dataset(              # return 1 (success) or 0 (error)
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required
    deleteContents => $boolean,   # optional
  );

=item * show_datasets

List datasets.

  $bq->show_datasets(             # return array of dataset_id
    project_id => $project_id,    # required if default project is not set
    all => $boolean,              # optional
    maxResults => $maxResults,    # optional
    pageToken => $pageToken,      # optional
  );

Use get_nextPageToken() if you want to use pageToken.

  $bq->show_datasets(maxResults => 1);
  my $nextPageToken = $bq->get_nextPageToken;
  $bq->show_datasets(maxResults => 1, nextPageToken => $nextPageToken);

=item * desc_dataset

Describe a dataset.
This method returns a Datasets resource.
See datails of a Datasets resource at https://cloud.google.com/bigquery/docs/reference/v2/datasets#resource.

  $bq->desc_dataset(              # return hashref of datasets resource
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
  );

=item * create_table

Create a table.

  $bq->create_table(                    # return 1 (success) or 0 (error)
    project_id => $project_id,          # required if default project is not set
    dataset_id => $dataset_id,          # required if default project is not set
    table_id => $table_id,              # required
    description => $description,        # optional
    expirationTime => $expirationTime,  # optional
    friendlyName => $friendlyName,      # optional
    schema => \@schma,                  # optional
    view => $query,                     # optional
  );

=item * drop_table

Drop a table.

  $bq->drop_table(                # return 1 (success) or 0 (error)
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required
    table_id => $table_id,        # required
  );

=item * show_tables

List tables.

  $bq->show_tables(               # return array of table_id
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
    maxResults => $maxResults,    # optioanl
    pageToken => $pageToken,      # optional
  );

Use get_nextPageToken() if you want to use pageToken.

  $bq->show_tables(maxResults => 1);
  my $nextPageToken = $bq->get_nextPageToken;
  $bq->show_tables(maxResults => 1, nextPageToken => $nextPageToken);

=item * desc_table

Describe a table.
This method returns a Tables resource.
See datails of a Tables resource at https://cloud.google.com/bigquery/docs/reference/v2/tables#resource.

  $bq->desc_table(                # return hashref of tables resource
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
    table_id => $table_id,        # required
  );

=item * load

Load data from one of several formats into a table.

  $bq->load(                                  # return 1 (success) or 0 (error)
    project_id => $project_id,                # required if default project is not set
    dataset_id => $dataset_id,                # required if default project is not set
    table_id => $table_id,                    # required
    data => $data,                            # required (specify a local file or Google Cloud Storage URIs)
    allowJaggedRows => $boolean,              # optional
    allowQuotedNewlines => $boolean,          # optional
    createDisposition => $createDisposition,  # optional
    encoding => $encoding,                    # optional
    fieldDelimiter => $fieldDelimiter,        # optional
    ignoreUnknownValues => $boolean,          # optional
    maxBadRecords => $maxBadRecords,          # optional
    quote => $quote,                          # optional
    schema => $schema,                        # optional
    skipLeadingRows => $skipLeadingRows,      # optional
    sourceFormat => $sourceFormat,            # optional
    writeDisposition => $writeDisposition,    # optional
  );

=item * insert

Streams data into BigQuery one record at a time without needing to run a load job.
See details at https://cloud.google.com/bigquery/streaming-data-into-bigquery.

  $bq->insert(                    # return 1 (success) or 0 (error)
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
    table_id => $table_id,        # required
    values => \@values,           # required
  );

=item * selectrow_array

Select a row.

  $bq->selectrow_array(           # return array of a row
    project_id => $project_id,    # required if default project is not set
    query => $query,              # required
    dataset_id => $dataset_id,    # optional
    maxResults => $maxResults,    # optional
    timeoutMs => $timeoutMs,      # optional
    dryRun => $boolean,           # optional
    useQueryCache => $boolean,    # optional
  );

=item * selectall_arrayref

Select rows.

  $bq->selectrow_array(           # return arrayref of rows
    project_id => $project_id,    # required if default project is not set
    query => $query,              # required
    dataset_id => $dataset_id,    # optional
    maxResults => $maxResults,    # optional
    timeoutMs => $timeoutMs,      # optional
    dryRun => $boolean,           # optional
    useQueryCache => $boolean,    # optional
  );

=item * is_exists_dataset

Check a dataset exists or not.

  $bq->is_exists_dataset(         # return 1 (exists) or 0 (no exists)
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
  )

=item * is_exists_table

Check a table exists or not.

  $bq->is_exists_table(           # return 1 (exists) or 0 (no exists)
    project_id => $project_id,    # required if default project is not set
    dataset_id => $dataset_id,    # required if default project is not set
    table_id => $table_id,        # required
  )

=item * extract

Export a BigQuery table to Google Cloud Storage.

  $bq->extract(                               # return 1 (success) or 0 (error)
    project_id => $project_id,                # required if default project is not set
    dataset_id => $dataset_id,                # required if default project is not set
    table_id => $table_id,                    # required
    data => $data,                            # required (specify Google Cloud Storage URIs)
    compression => $compression,              # optional
    destinationFormat => $destinationFormat,  # optional
    fieldDelimiter => $fieldDelimiter,        # optional
    printHeader => $boolean,                  # optional
  );

=item * request

You can also directly request to Google BigQuery API using request() method.
See details of Google BigQuery API at https://cloud.google.com/bigquery/docs/reference/v2/.

  $bq->request(
    resource => $resource,            # BigQuery API resource
    method => $method,                # BigQuery API method
    project_id => $project_id,        # project_id
    dataset_id => $dataset_id,        # dataset_id
    table_id => $table_id,            # table_id
    job_id => $job_id,                # job_id
    content => \%content,             # content of POST
    query_string => \%query_string,   # query string
    data => $data,                    # source localfile path for upload
  );

e.g. Updates description in an existing table.

  $bq->request(
    resource => 'tables',
    method => 'update',
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
    content => {
      talbeReferece => {
        projectId => $project_id,
        datasetId => $dataset_id,
        tableId => $table_id,
      },
      description => 'Update!',
    },
  );

=back

=head1 LICENSE

Copyright (C) Shoji Kai.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoji Kai E<lt>sho2kai@gmail.comE<gt>

=cut

