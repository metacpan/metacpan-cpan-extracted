package Google::RestApi::DriveApi3;

use strict;
use warnings;

our $VERSION = '0.1';

use 5.010_000;

use autodie;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str StrMatch HashRef HasMethods Any slurpy);

no autovivification;

use aliased 'Google::RestApi::DriveApi3::File';

use Google::RestApi::Utils qw(named_extra);

# TODO: switch to ReadOnly
use constant {
  Drive_File_Id => "[a-zA-Z0-9-_]+",
};

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;
  state $check = compile_named(
    api      => HasMethods['api'],
    endpoint => Str, { default => 'https://www.googleapis.com/drive/v3' },
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

sub filter_files {
  my $self = shift;
  state $check = compile(Str, HashRef, { default => {} });
  my ($filter, $params) = $check->(@_);
  $params->{'q'} = $filter;
  return $self->api(params => $params, uri => 'files');
}

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

Google::RestApi::DriveApi3 - Perl API to Google Drive API V3.

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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
