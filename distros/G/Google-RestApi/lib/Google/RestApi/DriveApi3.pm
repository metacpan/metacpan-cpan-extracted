package Google::RestApi::DriveApi3;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use Readonly;
use URI;

use aliased 'Google::RestApi::DriveApi3::File';

Readonly our $Drive_Endpoint => 'https://www.googleapis.com/drive/v3';
Readonly our $Drive_File_Id  => '[a-zA-Z0-9-_]+';

sub new {
  my $class = shift;
  state $check = compile_named(
    api      => HasApi,
    endpoint => Str, { default => $Drive_Endpoint },
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  my $uri = "$self->{endpoint}/";
  $uri .= delete $p->{uri} if defined $p->{uri};
  return $self->{api}->api(%$p, uri => $uri);
}

sub list {
  my $self = shift;
  state $check = compile(Str, HashRef, { default => {} });
  my ($filter, $params) = $check->(@_);

  $params->{q} = $filter;
  $params->{fields} = 'files(id, name)' unless $params->{fields};
  $params->{fields} = 'nextPageToken, ' . $params->{fields};

  my @list;
  my $next_page_token;
  do {
    $params->{pageToken} = $next_page_token if $next_page_token;
    my $result = $self->api(uri => 'files', params => $params);
    push(@list, $result->{files}->@*) if $result->{files};
    $next_page_token = $result->{nextPageToken};
  } until !$next_page_token;

  return @list;
}
# backward compatibility.
*filter_files = *list{CODE};

sub upload_endpoint {
  my $self = shift;
  my $upload = $self->{endpoint};
  $upload =~ s|googleapis.com/|googleapis.com/upload/|;
  return $upload;
}

sub file { File->new(drive => shift, @_); }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3 - API to Google Drive API V3.

=head1 DESCRIPTION

This API has been minimally developed to support the SheetsApi4 API in this
same package. Is it very incomplete and has no direct tests other than what
the SheetsApi4 package tests. It will be filled out and completed in due
course. Pull requests welcome.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
