package Finnigan::OLE2Property;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'name');

sub decode {
  my ($class, $stream, $param) = @_;
  my ($bb_log, $charset) = @$param;

  # do a null read to initialize internal variables
  my $self = Finnigan::Decoder->read($stream, []);
  bless $self, $class;

  my $fields = [
                "name"        => ['string',       'UTF-16-LE:64'],
                "namelen"     => ['v',            'UInt16'],
                "type"        => ['c',            'UInt8'],
                "decorator"   => ['c',            'UInt8'],
                "left"        => ['V',            'UInt32'],
                "right"       => ['V',            'UInt32'],
                "child"       => ['V',            'UInt32'],   # child node (valid for storage and root types)
                "clsid"       => ['a16',          'RawBytes'], # CLSID of this storage (valid for storage and root types)
                "flags"       => ['a4',           'RawBytes'], # user flags
                "create time" => ['windows_time', 'TimestampWin64'],
                "mod time"    => ['windows_time', 'TimestampWin64'],
                "start"       => ['V',            'UInt32'],   # starting index of the stream (valid for stream and root types)
               ];

  if ( $bb_log == 9 ) {
    push @$fields, (
                    "data size" => ['V',  'UInt32'],   # size in bytes (valid for stream and root types)
                    "padding"   => ['a4', 'RawBytes'],
                   );
  }
  else {
    die "small block streams and Uint64 stream size are not implemented";
    push @$fields, (
                    "data size" => ['*',  'UInt64'],   # size in bytes (valid for stream and root types)
                   );
  }

  $self->SUPER::decode($stream, $fields);

  return $self;
}

sub name {
  shift->{data}->{name}->{value};
}

sub data_size {
  shift->{data}->{"data size"}->{value};
}

sub child {
  shift->{data}->{child}->{value};
}

sub left {
  shift->{data}->{left}->{value};
}

sub right {
  shift->{data}->{right}->{value};
}

sub start {
  shift->{data}->{start}->{value};
}

sub type {
  shift->{data}->{type}->{value};
}

1;
__END__

=head1 NAME

Finnigan::OLE2Property -- a decoder for the Property structure in Microsoft OLE2

=head1 SYNOPSIS

  use Finnigan;
  my $p = Finnigan::OLE2Property->decode(\*INPUT, [9, 'UTF-16-LE']);
  say $p->name;

=head1 DESCRIPTION

This is an auxiliary decoder used by Finnigan::OLE2File; it is of no use on its own.

The OLE2 Properties are roughly equivalent to index nodes in other filesystems.


=head2 METHODS

=over 4

=item decode($stream, [$big_block_log_size, $charset])

The constructor method

=item name

Get the property name (equivalent to file name in a regular
filesystem). This method overloads the double-quote operator.

=item type

=item data_size

=item child

=item left

Get the left child

=item right

Get the right child

=item start

Get the starting index of the stream

=back

=head1 SEE ALSO

Finnigan::OLE2File

L<Windows Compound Binary File Format Specification|http://download.microsoft.com/download/0/B/E/0BE8BDD7-E5E8-422A-ABFD-4342ED7AD886/WindowsCompoundBinaryFileFormatSpecification.pdf>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
