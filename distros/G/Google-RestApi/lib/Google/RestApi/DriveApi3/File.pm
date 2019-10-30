package Google::RestApi::DriveApi3::File;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str StrMatch HasMethods Any slurpy);
use YAML::Any qw(Dump);

no autovivification;

use aliased 'Google::RestApi::DriveApi3';

use Google::RestApi::Utils qw(named_extra);

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;
  my $qr_id = DriveApi3->Drive_File_Id;
  state $check = compile_named(
    drive => HasMethods['api'],
    id    => StrMatch[qr/$qr_id/],
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = "files";
  $uri .= "/$p{uri}" if $p{uri};
  return $self->drive()->api(%p, uri => $uri);
}

sub copy {
  my $self = shift;

  state $check = compile_named(
    name    => Str, { optional => 1 },
    title   => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{name} ||= $p->{title};
  delete $p->{title};
  $p->{content}->{name} = delete $p->{name};

  my $file_id = $self->file_id();
  $p->{uri} = "$file_id/copy";
  $p->{method} = 'post';

  my $copy = $self->api(%$p);
  DEBUG(sprintf("Copied file '%s' to '$copy->{id}'", $self->file_id()));
  return ref($self)->new(
    drive => $self->drive(),
    id    => $copy->{id},
  );
}

sub delete {
  my $self = shift;
  DEBUG(sprintf("Deleting file '%s'", $self->file_id()));
  return $self->api(
    method => 'delete',
    uri    => $self->file_id(),
  );
}

sub file_id { shift->{id}; }
sub drive { shift->{drive}; }

1;

__END__

=head1 NAME

Google::RestApi::DriveApi3::File - File object for Google Drive.

=head1 DESCRIPTION

Represents a Drive file. You may currently copy and delete the file.
This needs further filling out.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
