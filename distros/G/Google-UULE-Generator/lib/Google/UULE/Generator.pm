package Google::UULE::Generator;

use strict;
use 5.008_005;
use base 'Exporter';
use MIME::Base64 qw/encode_base64/;

our $VERSION = '0.01';
our @EXPORT_OK = qw/generate_uule/;

our @_CS = ('A' .. 'Z', 'a' .. 'z', 0 .. 9, '-', '_');
sub generate_uule {
  my ($name) = @_;

  my $sec = @_CS[length($name) % scalar(@_CS)];
  my $hashed = encode_base64($name, '');
  $hashed =~ s/[\=]+$//g;
  return 'w+CAIQICI' . $sec . $hashed;
}

1;
__END__

=encoding utf-8

=head1 NAME

Google::UULE::Generator - Generate Google UULE param

=head1 SYNOPSIS

  use Google::UULE::Generator qw/generate_uule/;

  print generate_uule("Lezigne,Pays de la Loire,France"); # w+CAIQICIfTGV6aWduZSxQYXlzIGRlIGxhIExvaXJlLEZyYW5jZQ

=head1 DESCRIPTION

Google::UULE::Generator is to convert UULE name into uule= URI part.

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2021- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
