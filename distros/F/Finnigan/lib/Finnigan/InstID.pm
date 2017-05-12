package Finnigan::InstID;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

sub decode {
  my ($class, $stream) = @_;

  my $fields = [
                "unknown data"       => ['C8',     'RawBytes'],
                "unknown long[1]"    => ['V',      'UInt32'],
                "model[1]"           => ['varstr', 'PascalStringWin32'],
                "model[2]"           => ['varstr', 'PascalStringWin32'],
                "serial number"      => ['varstr', 'PascalStringWin32'],
                "software version"   => ['varstr', 'PascalStringWin32'],
                "tag[1]"             => ['varstr', 'PascalStringWin32'],
                "tag[2]"             => ['varstr', 'PascalStringWin32'],
                "tag[3]"             => ['varstr', 'PascalStringWin32'],
                "tag[4]"             => ['varstr', 'PascalStringWin32'],
         ];

  my $self = Finnigan::Decoder->read($stream, $fields);

  return bless $self, $class;
}

sub model {
  shift->{data}->{"model[1]"}->{value};
}

sub serial_number {
  shift->{data}->{"serial number"}->{value};
}

sub software_version {
  shift->{data}->{"software version"}->{value};
}

sub stringify {
  my $self = shift;
  return $self->model
    . ", S/N: " . $self->serial_number
      . "; software version " . $self->software_version;
}

1;
__END__

=head1 NAME

Finnigan::InstID -- a decoder for InstID, a set of instrument identifiers

=head1 SYNOPSIS

  use Finnigan;
  my $inst = Finnigan::InstID->decode(\*INPUT);
  say $inst->model;
  say $inst->serial_number;
  say $inst->software_version;
  $inst->dump;

=head1 DESCRIPTION

InstID is a static (fixed-size) structure containing several
instrument identifiers and some unknown data.

The identifiers include the model name, the serial number and the software version.

=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item model

Get the first copy of the model attribute (there always seem to be two of them)

=item serial_number

Get the instrument's serial number

=item software_version

Get the version of software that created the data file

=item stringify

Concatenate all IDs in a single line of text

=back

=head1 SEE ALSO

L<uf-instrument>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
