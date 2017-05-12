package Finnigan::Decoder;

use 5.010000;
use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Encode qw//;
use Carp qw/confess/;

sub read {
  my ($class, $stream, $fields, $any_arg) = @_;
  my $self = {size => 0};

  bless $self, $class;
  $self->decode($stream, $fields, $any_arg);
  return $self;
}

sub iterate_object {
  my ($self, $stream, $count, $name, $class, $any_arg) = @_;

  my $addr = tell $stream;

  my $current_element_number = keys(%{$self->{data}}) + 1;

  confess qq(key "$name" already exists) if $self->{data}->{$name};

  my $size = 0;
  foreach my $i ( 1 .. $count ) {
    my $value = $class->decode($stream, $any_arg);
    $size += $value->{size};
    push @{$self->{data}->{$name}->{value}}, $value;
  }

  $self->{data}->{$name}->{seq} = $current_element_number;
  $self->{data}->{$name}->{addr} = $addr,
  $self->{data}->{$name}->{size} = $size,
  $self->{data}->{$name}->{type} = "$class\[\]",

  $self->{size} += $size;
  $self->{current_element_number}++;

  return $self;
}

sub iterate_scalar {
  my ($self, $stream, $count, $name, $desc) = @_;
  my ($template, $type) = @$desc;

  my $addr = my $current_addr = tell $stream;

  my $current_element_number = keys(%{$self->{data}}) + 1;

  confess qq(key "$name" already exists) if $self->{data}->{$name};

  my $size = 0;
  my ($rec, $nbytes);
  my ($i, $bytes_to_read);

  if ( $template eq 'varstr' ) {
    if ( $type eq 'PascalStringWin32' ) {
      for ($i = 1; $i <= $count; $i++) {
        # read the prefix counter into $nchars
        my $bytes_to_read = 4;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $bytes_to_read bytes of the prefix counter in $name at $current_addr";
        my $nchars = unpack "V", $rec;

        # read the 2-byte characters
        $bytes_to_read = 2*$nchars;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $nchars 2-byte characters of $name at $current_addr";
        $nbytes += 4; # total string length

        $size += $nbytes;
        $current_addr += $nbytes;

        push @{$self->{data}->{$name}->{value}}, Encode::decode('UTF-16LE', (pack "C*", unpack "U0C*", $rec));
      }
    }
    else {
      confess "unknown varstr type $type";
    }
  }
  else {
    my $template_length = length(pack($template,()));
    if ( substr($template, 0, 3) eq 'U0C' ) {
      foreach $i ( 1 .. $count ) {
        $nbytes = CORE::read $stream, $rec, $template_length;
        $nbytes == $template_length
          or die "could not read all $template_length bytes of $name at $current_addr";

        $size += $nbytes;
        $current_addr += $nbytes;

        push @{$self->{data}->{$name}->{value}}, pack ( "C*", unpack $template, $rec );
      }
    }
    else {
      foreach $i ( 1 .. $count ) {
        $nbytes = CORE::read $stream, $rec, $template_length;
        $nbytes == $template_length
          or die "could not read all $template_length bytes of $name at $current_addr";

        $size += $nbytes;
        $current_addr += $nbytes;

        push @{$self->{data}->{$name}->{value}}, unpack ( $template, $rec );
      }
    }
  }

  $self->{data}->{$name}->{seq} = $current_element_number;
  $self->{data}->{$name}->{addr} = $addr,
  $self->{data}->{$name}->{size} = $size,
  $self->{data}->{$name}->{type} = $type,

  $self->{size} += $size;
  $self->{current_element_number}++;

  return $self;
}

sub decode {
  my ($self, $stream, $fields, $any_arg) = @_;
  my ( $rec, $nbytes );  

  my $current_addr = tell $stream;
  $self->{addr} ||= $current_addr; # assign the address only if called
                                   # the first time (because decoding
                                   # can be done in multiple chunks)

  my $current_element_number = keys %{$self->{data}};

  my $value;
  foreach my $i ( 0 .. @$fields/2 - 1 ) {
    my $name = $fields->[2*$i];
    unless ( $fields->[2*$i+1] ) {
      # it is a spacer in the human-readable generic record
      $self->{data}->{$name} = {
            seq => $current_element_number + $i,
            addr => $current_addr,
            size => 0,
            type => 'spacer',
            value => '',
           };

      $self->{current_element_number} = $i;
      next;
    }

    my ($template, $type) = @{$fields->[2*$i+1]};

    confess qq(key "$name" already exists) if $self->{data}->{$name};

    if ( $template eq 'object' ) {
      $value = $type->decode($stream, $any_arg);
      $nbytes = $value->{size};
    }
    elsif ( $template eq 'varstr' ) {
      if ( $type eq 'PascalStringWin32' ) {
        # read the prefix counter into $nchars
        my $bytes_to_read = 4;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $bytes_to_read bytes of the prefix counter in $name at $current_addr";
        my $nchars = unpack "V", $rec;

        # read the 2-byte characters
        $bytes_to_read = 2*$nchars;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $nchars 2-byte characters of $name at $current_addr";
        $rec =~ s/\xb0/\*/; # remove the degree sign
        #print(STDERR (ord > 127 ? sprintf("<%02X>", ord) : $_)) for(split //, $rec); print STDERR "\n";
        $value = Encode::decode('UTF-16LE', (pack "C*", unpack "U0C*", $rec));
        $nbytes += 4;
      }
      else {
        confess "unknown varstr type $type";
      }
    }
    elsif ( $template eq 'string' ) {
      if ( substr($type, 0, 6) eq 'ASCIIZ' ) {
        (undef, my $bytes_to_read) = split ":", $type;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $bytes_to_read bytes of the string in $name at $current_addr";
        $value = unpack "Z*", $rec;
      }
      elsif ( substr($type, 0, 9) eq 'UTF-16-LE' ) {
        (undef, my $bytes_to_read) = split ":", $type;
        $nbytes = CORE::read $stream, $rec, $bytes_to_read;
        $nbytes == $bytes_to_read
          or die "could not read all $bytes_to_read bytes of the string in $name at $current_addr";
        ($value) = split /\0/, Encode::decode('UTF-16LE', (pack "C*", unpack "U0C*", $rec)); # decode and truncate at 0
      }
      elsif ( substr($type, 0, 9) eq 'UTF-16-BE' ) {
        confess "UTF-16-BE not implemented";
      }
      else {
        confess "unknown string type";
      }
    }
    elsif ( $template eq 'windows_time' ) {
      my $bytes_to_read = 8;
      $nbytes = CORE::read $stream, $rec, $bytes_to_read;
      $nbytes == $bytes_to_read
        or die "could not read all $bytes_to_read bytes of $name at $current_addr";
      my ($w1, $w2) = unpack "VV", $rec;
      $value = scalar gmtime (($w2 * 4294967296 + $w1) / 10000000 - 11644473600); # Windows timestamp is 100s of ns since Jan 1 1601
    }
    else {
      my $bytes_to_read = length(pack($template,()));
      $nbytes = CORE::read $stream, $rec, $bytes_to_read;
      $nbytes == $bytes_to_read
        or die "could not read all $bytes_to_read bytes of $name at $current_addr";

      if ( substr($template, 0, 3) eq 'U0C' ) {
        $value = pack "C*", unpack $template, $rec;
      }
      else {
        $value = unpack $template, $rec;
      }
    }

    $self->{data}->{$name} = {
            seq => $current_element_number + $i,
            addr => $current_addr,
            size => $nbytes,
            type => $type,
            value => $value,
           };

    $current_addr = tell $stream;
    $self->{size} += $nbytes;
    $self->{current_element_number} = $i;
  }

  return $self;
}

sub size {
  shift->{size};
}

sub data {
  shift->{data};
}

sub addr {
  shift->{addr};
}

sub item {
  my ($self, $key) = @_;
  $self->{data}->{$key};
}

sub values {
  my ($self) = @_;
  return {map { $_ => $self->{data}->{$_}->{value} } keys %{$self->{data}}};
}

sub dump {
  my ( $self, %arg ) = @_;

  my $addr = $self->{addr};

  $arg{header}++ unless exists $arg{header}; # print the header by default

  my @keys = sort {
    $self->data->{$a}->{seq} <=> $self->data->{$b}->{seq}
  } keys %{$self->{data}};

  if ( $arg{filter} ) {
    my %filter = map {$_ => 1} @{$arg{filter}};
    @keys = grep {$filter{$_}} @keys;
  }

  if ($arg{style} and $arg{style} eq 'html') {
    say "<table>";
    say "  <tr> <td>offset</td> <td>size</td> <td>type</td> <td>key</td> <td>value</td> </tr>" if $arg{header};
    foreach my $key ( @keys ) {
      my $offset = $arg{relative} ? $self->item($key)->{addr} - $addr :  $self->item($key)->{addr};
      my $value = $self->item($key)->{value};
      my $type = $self->item($key)->{type};
      $type =~ s/^Finnigan:://;
      if ( ref $value eq 'ARRAY' ) {
        $value = join ", ", map {"$_"} @$value;
      }
      if ( $type eq 'RawBytes' ) {
        my $len = length($value);
        my @list = unpack('C*', substr($value, 0, 16));
        $_ = sprintf "%2.2x", $_ for @list;
        $value = join(" ", @list);
        $value .= " ..." if $len > 16;
      }
      say "  <tr>"
        . " <td>" . $offset . "</td>"
          . " <td>" . $self->item($key)->{size} . "</td>"
            . " <td>" . $type . "</td>"
              . " <td>" . $key . "</td>"
                . " <td>$value</td>"
                  . " </tr>"
                    ;
    }
    say "</table>";
  }
  elsif ($arg{style} and $arg{style} eq 'wiki') {
    say "|| " . join(" || ", qw/offset size type key value/) . " ||" if $arg{header};
    foreach my $key ( @keys ) {
      my $offset = $arg{relative} ? $self->item($key)->{addr} - $addr :  $self->item($key)->{addr};
      my $value = $self->item($key)->{value};
      my $type = $self->item($key)->{type};
      $type =~ s/^Finnigan:://;
      $type =~ s/\[\]/\`[]\`/;
      if ($self->item($key)->{type} eq 'UTF16LE'
          and substr($value, 0, 2) eq "\x00\x00") {
        $value =~ s/\x00/00 /g;
        if (length($value) > 20) {
          $value = substr($value, 0, 30) . "...";
        }
      }
      if ( ref $value eq 'ARRAY' ) {
        $value = join ", ", map {"$_"} @$value;
      }
      if ( $type eq 'RawBytes' ) {
        my $len = length($value);
        my @list = unpack('C*', substr($value, 0, 16));
        $_ = sprintf "%2.2x", $_ for @list;
        $value = join(" ", @list);
        $value .= " ..." if $len > 16;
      }
      say "|| " . join(" || ",
           $offset,
           $self->item($key)->{size},
           $type,
           "\`$key\`",
           "\`$value\`"
          ). " ||";
    }
  }
  else {
    foreach my $key ( @keys ) {
      my $offset = $arg{relative} ? $self->item($key)->{addr} - $addr :  $self->item($key)->{addr};
      my $value = $self->item($key)->{value};
      my $type = $self->item($key)->{type};
      $type =~ s/^Finnigan:://;
      if ( ref $value eq 'ARRAY' ) {
        $value = join ", ", map {"$_"} @$value;
      }
      if ( $type eq 'RawBytes' ) {
        my $len = length($value);
        my @list = unpack('C*', substr($value, 0, 16));
        $_ = sprintf "%2.2x", $_ for @list;
        $value = join(" ", @list);
        $value .= " ..." if $len > 16;
      }
      say join("\t",
         $offset,
         $self->item($key)->{size},
         $type,
         $key,
         "$value"
        );
    }
  }
}

sub purge_unused_data {
  my $self = shift;
  delete $self->{current_element_number};
  delete $self->{addr};
  delete $self->{size};
  foreach my $key (keys %{$self->{data}}) {
    if ( substr($key, 0, 4) eq 'unkn' ) {
      delete $self->{data}->{$key};
    }
    else {
      delete $self->{data}->{$key}->{type};
      delete $self->{data}->{$key}->{addr};
      delete $self->{data}->{$key}->{seq};
      delete $self->{data}->{$key}->{size};
    }
  }
  return $self;
}

1;
__END__
=head1 NAME

Finnigan::Decoder - a generic binary structure decoder

=head1 SYNOPSIS

  use Finnigan;

  my $fields = [
    short_int => 'v',
    long_int => 'V',
    ascii_string => 'C60',
    wide_string => 'U0C18',
    audit_tag => 'object=Finnigan::AuditTag',
    time => 'windows_time',
  ];

  my $data = Finnigan::Decoder->read(\*STREAM, $fields);


=head1 DESCRIPTION

This class is not inteded to be used directly; it is a parent class
for all Finnigan decoders. The fields to decode are passed to
the decoder's read() method in a list reference, where every even item
specifies the key the item will be known as in the resulting hash, and
every odd item specifies the unpack template.

Perl unpack templates are used to decode most fields. For some fields, non-perl templates are used, such as:

=over 2

=item * object: instructs the current decoder to call another Finnigan decoder at that location.

=item * windows_time: instructs Finingan::Decoder to call its own Windows timestamp routine.

=item * varstr: decoded as a Windows Pascal string in a special case in the Finnigan::Decoder::read() method.

=back

=head2 METHODS

=over 4

=item read($class, $stream, $fields, $any_arg)

Returns a new decoder blessed into class C<$class> and initialized
with the values read from C<$stream> and decoded according to a list
of templates specified in C<$fields>.

The fourth argument, C<$any_arg> is not used by the Decoder class, but
may be used by derived classes to pass parse context to their
component decoders. For example, this can be useful to parse
structures whose layout is governed by the data they contain; in that
case if the layout indicator is read by the top-level decoder, it can
be passed to lower-level decoders whose work depends on it. Also, this
argument is used by the user program to pass the Finnigan file version
to version-sensitive decoders.

Here is an example of the template list for a simple decoder:

  my $fields = [
    "mz"        => ['f<', 'Float32'],
    "abundance" => ['f<', 'Float32'],
  ];

=item decode($stream, $fields, $any_arg)

This method must be called on a blessed, instantiated Decoder. The
C<read()> method calls it internally, but it can also be used by the
user code in those cases where not all data can be decoded with a
plain list of templates. In some cases, it may be necessary to decode
one part of an object, analyse it, make decisions about the rest
(calculate sizes, layouts, etc.), and then grow the object under
construction by decoding more data from the stream.


=item iterate_scalar($stream, $count, $name, $desc)

This method is similar to the C<decode> metod, in that it does not
instantiate a Decoder, but rather adds data to an existing one. Its
purpose is to decode simple arrays whose elements have neither
structure, nor behaviour, and can be described by a simple list. The
list will consist of C<$count> elements read into the current
Decoder's attribute given in C<$name>, according to the template
specified in C<$desc>.  For example, to read a list of 4-byte
integers, the template description must be of the form:

  $desc = ['V', 'UInt32']


=item iterate_object($stream, $count, $name, $class, $any_arg)

Similarly to C<iterate_scalar()>, this method can be used to read a
list of structures into the current decoder's attribute specified in
the C<$name> argument, but in this case, the list elements can be
complex structures to be decoded with their own decoder specified in
C<$class>. The optional argument C<$any_arg> can be used to parse
context information to that decoder.

=item purge_unused_data

Delete the location, size and type data for all structure
elements. Calling this method will free some memory when no
introspection is needeed (the necessary measure in production-grade
code)

=back

=head2 METHODS

=over 4

=item addr

Get the seek address of the decoded object

=item size

Get object size

=item data

Get the object's data hash (equivalent to $obj->{data}). Every data hash element contains the decoded value as well as location and type data.

=item item($key)

Get an item by name (equivalent to $obj->{data}->{$key})

=item values

Extract the simple value hash (no location data, only the element names and values)

=item dump($param)

Dump the object's contents in three different styles, using absolute
or relative addresses. The attribute $param->{style} can be set to
wiki or html, or it can be absent or have any other value, it which
case the dump will have a simple tabular format. The attribute
$param->{relative}is a Boolean, requesting relative addresses when it
is set to a truthy value.

=back

=head1 SEE ALSO

Use this command to list all available Finnigan decoders:

 perl -MFinnigan -e 'Finnigan::list_modules'


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
