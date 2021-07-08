package Test::Mock::SheetsApi4;

use strict;
use warnings;

use feature 'state';

use FindBin;
use Type::Params qw(compile_named);
use Types::Standard qw(Str StrMatch ArrayRef HashRef);
use URI;
use URI::QueryParam;
use YAML::Any qw(Dump LoadFile);
use Test::MockObject::Extends;

use Test::Mock::Drive;
use Test::Mock::RestApi;
use Test::Mock::Spreadsheet;

use aliased 'Google::RestApi::SheetsApi4';

sub new {
  # TODO: need a way to load this from the parent script.
  my $config = LoadFile("$FindBin::RealBin/etc/config.yaml");

  my $self = SheetsApi4->new(
    api    => Test::Mock::RestApi->new(),
    config => $config,
  );

  $self = Test::MockObject::Extends->new($self);

  $self->mock(
    'drive', sub { Test::Mock::Drive->new(); }
  )->mock(
    'open_sheet', sub { Test::Mock::Spreadsheet->new() }
  )->mock(
    'api', sub { api(@_); }
  )->mock(
    '_get', sub { _get(@_); }
  )->mock(
    '_get_batch', sub { _get_batch(@_); }
  )->mock(
    '_post', sub { _post(@_); }
  )->mock(
    '_parse_uri', sub { _parse_uri(@_); }
  );

  return $self;
}

sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str,
    method  => StrMatch[qr/^(get|post)$/i], { default => 'get' },
    headers => ArrayRef[Str], { default => [] },
    params  => HashRef, { default => {} },
    content => HashRef, { optional => 1 },
  );
  my $p = $check->(@_);

  # looks redundant, but may as well test parsing the uri and ensure
  # params are processed correctly.
  my $uri = URI->new("$self->{endpoint}/$p->{uri}");
  $uri->query_form_hash($p->{params});
  my $params = $uri->query_form_hash();

  # TODO: add in clear, batchclear etc.
  my $method = $p->{method};
  return $self->_get_batch($uri, $params)
    if $method =~ qr/^get$/i && grep { /batch/; } $uri->path_segments();
  return $self->_get($uri, $params)
    if $method =~ qr/^get$/i;
  return $self->_post($uri, $params, $p->{content})
    if $method =~ qr/^post$/i;

  die "Unknown method '$method' for path '$p->{uri}' called";
}

sub _get {
  my $self = shift;
  my ($uri, $params) = @_;
  return {} if defined $params->{fields};

  my ($spreadsheet, $spreadsheet_id, $range, $worksheet, $addr) = $self->_parse_uri($uri);
  my $full_addr = "$worksheet!$addr";
  my $values = $spreadsheet->{$full_addr};
  return {
    range          => $range,
    majorDimension => 'rows',
    values         => [[$values]],
  };
}

sub _get_batch {
  my $self = shift;
  my ($uri, $params) = @_;

  my ($spreadsheet, $spreadsheet_id) = $self->_parse_uri($uri);
  my @ranges = @{ $params->{ranges} };
  my @values = map { $spreadsheet->{$_}; } @ranges;
  my @value_ranges = map {
    {
      majorDimension => "ROWS",
      range          => $ranges[$_],
      values         => [[$values[$_]]],
    }
  } (0..$#ranges);
  return {
    spreadsheetId => $spreadsheet_id,
    valueRanges   => \@value_ranges,
  };
}

sub _post {
  my $self = shift;

  my ($uri, $params, $content) = @_;
  my ($spreadsheet, $spreadsheet_id) = $self->_parse_uri($uri);

  my %response = (
    spreadsheetId  => $spreadsheet_id,
    updatedRange   => "A1",
    updatedRows    => 0,
    updatedColumns => 0,
    updatedCells   => 0,
  );

  my @segments = $uri->path_segments();
  if ($segments[-1] =~ /values:batchUpdate/i) {
    foreach my $value_range (@{ $content->{data} }) {
      if (ref($value_range) eq 'ARRAY') {
        foreach my $value_range2 (@$value_range) {
          _value_range($spreadsheet, $value_range2);
        }
        next;
      }
      _value_range($spreadsheet, $value_range);
    }
    return {responses => [\%response]};
  } elsif ($segments[-1] =~ /batchUpdate/i) {
    my @responses = map { {} } @{ $content->{requests} };
    return { replies => \@responses };
  }
  $spreadsheet->{ $segments[-1] } = $content->{values};
  return \%response;
}

sub _parse_uri {
  my $self = shift;

  my $uri = shift;
  my @segments = $uri->path_segments();

  my ($range, $worksheet, $addr);
  $range = $segments[-1];
  if ($range !~ /batch/i) {
    ($worksheet, $addr) = $range =~ /(.+)!(.+)/;
  } else {
    $range = undef;
  }

  my $spreadsheet_id = $segments[2];
  $self->{ss}->{$spreadsheet_id} ||= {};

  return ($self->{ss}->{$spreadsheet_id}, $spreadsheet_id, $range, $worksheet, $addr);
}

sub _value_range {
  my ($spreadsheet, $value_range) = @_;

  my $range = $value_range->{range};
  my $values = $value_range->{values};

  if (Google::RestApi::SheetsApi4::Range::is_cellA1($range)) {
    $spreadsheet->{$range} = $values->[0]->[0];
    return;
  }

  if (Google::RestApi::SheetsApi4::Range::is_colA1($range)) {
    my ($worksheet, $col) = $range =~ /^(.+)!([A-Z+])/;
    my $row = 1;
    foreach (@{ $values->[0] }) {
      $spreadsheet->{ "$worksheet!${col}${row}" } = $values->[0]->[ $row-1 ];
      ++$row;
    }
    return;
  }

  if (Google::RestApi::SheetsApi4::Range::is_rowA1($range)) {
    my ($worksheet, $row) = $range =~ /^(.+)!(\d+)/;
    my $col = 1;
    foreach (@{ $values->[0] }) {
      $spreadsheet->{ "$worksheet!${col}${row}" } = $values->[0]->[ $col-1 ]->[0];
      ++$col;
    }
    return;
  }

  return;
}

1;
