package Finnigan;

use 5.010000;
use strict;
use warnings;
use Module::Find qw/findsubmod/;

our $VERSION = '0.0206';

$Finnigan::activationMethod = 'cid';

my @modules = findsubmod __PACKAGE__;

map { eval "require $_" } @modules;

sub list_modules {
  say foreach (sort @modules);
}

1;

__END__

=head1 NAME

Finnigan - Thermo/Finnigan mass spec data decoder

=head1 SYNOPSIS

  use Finnigan;

  seek INPUT, $object_address, 0
  my $o = Finnigan::Object->decode(\*STREAM, $arg);
  $o->dump;

where 'Object' is a symbol for any of the specific decoder objects
(C<Finnigan::*>) and C<STREAM> is an open filehandle positioned at the
start of the structure to be decoded. Some decoders may require an
additional argument (file format version).

=head1 DESCRIPTION

C<Finnigan> is a non-functional package whose only purpose is to pull
in all other packages in the module into its namespace. It does no
work; all work is done in the sub-modules. Each submodule has its own
documentation; please see the L</SUBMODULES> section below or visit
L<the project's home page|http://code.google.com/p/unfinnigan> for a
more detailed descripion of the file format, data structures, decoders
and tools.

Each decoder submodule has a simple command-line interface. See the
L</TOOLS> section for a list of command-line tools that can be used to
examine the Finnigan file structures and dump their contents with
absolute or relative addresses. One of the tools, L<uf-mzxml>, can be
used to convert the entire data stream in a Finnigan file to the
L<mzXML|http://sashimi.sourceforge.net/software_glossolalia.html>
format.

=head2 METHODS

=over 4

=item list_modules

The only method defined in the top-level C<Finnigan> package is
C<list_modules>, which can be used to ascertain that all packages have
been successfully loaded:

  perl -MFinnigan -e 'Finnigan::list_modules'

=back

=head2 SUBMODULES

To simplify the decoder and allow it to accommodate a variety of file
versions, it has been subdivided into a set of submodules, each
representing a structural unit of the Finnigan file format. The
partitioning of the format into units is somewhat arbitrary; it was
done based on the comparative analysis of the structure of several
different formats. The structures common to all formats are viewed as
"basic" and merit a dedicated decoder; the same goes for the highly
repetitive structures, such as L<Finnigan::ScanIndexEntry>. Some
structures remain roughly similar, but keep acquiring new elements
with every new file version; the decoders for these structures are
parameterised with the version number (for example,
L<Finnigan::ScanEventPreamble>).

The notion of a I<preamble> (the term I made up, not knwoing better)
represents what seems to be a persistent idiom in Thermo structure
coding: collect the binary data in a fixed-size block followed by
variable-length objects (mostly text strings). The earlier Finnigan
formats contained little or no text and virtually no variable-length
data, so what I call a preamble today used to be the whole deal in the
past, and it makes sense to have a separate decoder for each such
rudimentary container. Keeping these decoders separate makes it
possible to go back and decode the historical data simply by
recombining the existing decoders.

=head3 Common submodule methods

=over 4

=item decode($stream, $arg)

Each C<Finnigan::*> object has a constructor method named C<decode()>,
whose first argument is a filehandle positioned at the start of the
object to be decoded. Some decoders require additional arguments, such
as the file version number. A single argument is passed as it is,
while multiple arguments can be passed as an array reference.

The constructor advances the handle to the start of the next object,
so seeking to the start of the object of interest is only necessary
when doing partial reads; in principle, the entire file can be read by
calling of object constructors in sequency. In reality, it is often
more efficient to seek ahead to fetch an index structure stored near
the end of the file, then go back to the data stream using the
pointers in the index.

The decoded data can be obtained by calling accessor methods on the
object or by de-referencing the object reference (since all Finnigan
objects are blessed hash references):

  $x = $object->element

or

  $x = $object->{element}

The accessor option is nicer, as it leads to less clutter in the code
and leaves the possibility for additional processing of the data by the
accessor routine, but it incurs a substantial performance penalty. For
this reason, hash dereference is preferred in performance-critical
code (inside loops).

This is an "instance" method; it must be defined in each non-trivial
decoder object.

=item dump(%args)

All Finnigan objects are the descendants of L<Finnigan::Decoder>. One
of the methods they inherit is C<dump>, which provides an easy way to
explore the contents of decoded objects. The C<dump> method prints out
the structure of the object it is called on in a few styles, with
relative or absolute addressess.

For example, many object dumps used in L<this
wiki|http://code.google.com/p/unfinnigan/wiki/WikiHome> were created
thus:

  $object->dump(style => 'wiki', relative => 1);

The C<style> argument can have the values of C<wiki>, C<html> or no
value at all (meaning plain text). The C<relative> argument is a
boolean indicating whether to use the absolute or relative file
addresses in the output. In this case, "relative" means "an offset
within the object", while "absolute" is the seek address within the
data file.

=item read($stream, $template_list, $arg)

This is the C<Finnigan::Decoder> constructor method. Some derived
decoders use it internally, but it can also be used to decode trivial
objects at a given location in a file without having to write a
dedicated decoder.

For example, to read a 32-bit stream length, use:

  my $object = Finnigan::Decoder->read(\*INPUT, ['length' => ['V', 'UInt32']]);

The C<$template_list> argument names all fields to decode (in this
case, just one: C<length>), the template to use for each field (in
this example, C<V>), and provides a human-readable symbol for the
template, which can be used in a number of ways; for example, when
inspecting the structures with the C<dump> method.

This may seem like a kludgy way of reading four bytes, but the upshot
is that the resulting C<$object> will have the size, type and location
information tucked into it, so it can be analysed and dumped in a way
consistent with other decoded objects. The advantage becomes even more
apparent when the structure is more complex than a single scalar object.

The inherited C<read> method provides the core functionality in all Finnigan
decoders.

If only the value of the object is sought, then this even more kludgy
code can be used:

  my $stream_length = Finnigan::Decoder->read(\*INPUT, ['length' => ['V', 'UInt32']])->{data}->{length}->{value};

Doing it this way is nonetheless easier than writing several lines of
code to read the data into a buffer, check for the I/O errors and
unpack the value.


=item stringify

A convenience method defined in some of the Finnigan objects. It
allows a concise representation of an object to be injected anywhere
Perl expects a string. For example,

  $scan_event = Finnigan::ScanEvent->decode( \*INPUT, $header->version);
  say "$scan_event";

=back

=head3 Submodule index

=over 4

=item L<Finnigan::AuditTag> (sample audit tag)

=item L<Finnigan::CASInfo> (autosampler info)

=item L<Finnigan::CASInfoPreamble> (numerical autosampler parameters)

=item L<Finnigan::Decoder> (the base class for all Finnigan decoders)

=item L<Finnigan::Error> (error log entry)

=item L<Finnigan::FileHeader>

=item L<Finnigan::FractionCollector> (M/z range decoder)

=item L<Finnigan::GenericDataDescriptor> (a self-decoding structure element)

=item L<Finnigan::GenericDataHeader> (self-decoding structure header)

=item L<Finnigan::GenericRecord> (self-decoding structure)

=item L<Finnigan::InjectionData> (sample injection parameters)

=item L<Finnigan::InstID> (instrument identifiers)

=item L<Finnigan::InstrumentLogRecord> (instrument log entry)

=item L<Finnigan::MethodFile> (an OLE2 container for instrument method files)

=item L<Finnigan::OLE2DIF> (Double-Indirect FAT decoder)

=item L<Finnigan::OLE2DirectoryEntry>

=item L<Finnigan::OLE2FAT> (FAT sector decoder)

=item L<Finnigan::OLE2File> (Microsoft OLE2/CDF file decoder)

=item L<Finnigan::OLE2Header> (OLE2 header decoder)

=item L<Finnigan::OLE2Property> (OLE2 index node decoder)

=item L<Finnigan::PacketHeader> (scan data header)

=item L<Finnigan::Peak> (an element of the peak centroid list)

=item L<Finnigan::Peaks> (the peak centroid list)

=item L<Finnigan::Profile> (scan profile)

=item L<Finnigan::ProfileChunk> (a single chunk of a filetered profile)

=item L<Finnigan::RawFileInfo> (primary index structure)

=item L<Finnigan::RawFileInfoPreamble> (the binary data part of C<RawFileInfo>)

=item L<Finnigan::Reaction> (precursor ion data)

=item L<Finnigan::RunHeader> (secondary index structure)

=item L<Finnigan::SampleInfo> (secondary index structure)

=item L<Finnigan::Scan> (a lightweight C<ScanDataPacket> decoder)

=item L<Finnigan::ScanEvent> (scan type descriptor)

=item L<Finnigan::ScanEventPreamble> (the byte array component of C<ScanEvent>)

=item L<Finnigan::ScanEventTemplate> (the prototype scan descriptor)

=item L<Finnigan::ScanIndexEntry> (scan data pointer)

=item L<Finnigan::ScanParameters> (scan meta-data)

=item L<Finnigan::SeqRow> (sequencer table row)

=back

=head2 TOOLS

The Unfinnigan tools extract data from the Finnigan files of several
known versions. They are listed roughly in the order in which the
structures they decode occur in the data file.

=head3 Query tools

=over 4

=item L<uf-header>

read the C<FileHeader> structure

=item L<uf-seqrow>

read the C<SeqRow> structure (Sequence Table Row)

=item L<uf-casinfo>

read the C<CASInfo> structure (autosampler info)

=item L<uf-rfi>

read C<RawFileInfo>, the primary index structure

=item L<uf-meth>

unravel the embedded C<MethodFile> container

=item L<uf-scan>

examine the scan profile and peak data in a single MS scan (C<ScanDataPacket>)

=item L<uf-runheader>

read C<RunHeader>), the secondary index structure

=item L<uf-instrument>

read the instrument IDs (the C<InstID> structure)

=item L<uf-log>

list or dump the instrument log stream (C<InstrumentLogRecord> structures)

=item L<uf-error>

list the error log (a steam of C<Error> structures)

=item L<uf-segments>

dump the C<ScanEventTemplate> structures in the order of segment hierarchy

=item L<uf-params>

print or dump the C<ScanParameters> stream

=item L<uf-tune>

print or dump the C<TuneFile> structure

=item L<uf-index>

read the stream of C<ScanIndexEntry> records (scan data pointers)

=item L<uf-trailer>

read the stream of C<ScanEvent> records

=back

=head3 Conversion tools

The following are the conversion tools, transcoding the entire raw
files into alternative representations.


=over 4

=item L<uf-mzxml>

convert a raw file to mzXML

=item L<mzxml-unpack>

unpack the base64-encoded scan data in an mzXML file

=back

All tools contain their own POD sections. To read the documentation for a tool, use

  man <tool>
  perldoc <tool>


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
