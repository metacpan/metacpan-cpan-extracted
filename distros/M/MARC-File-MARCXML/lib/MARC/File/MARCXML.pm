#
# MARCXML implementation for MARC records
#
# Copyright (c) 2011-2014, 2016 University Of Helsinki (The National Library Of Finland)
#
# This file is part of marc-file-marcxml
#
# This project's source code is licensed under the terms of GNU General Public License Version 3.
#

package MARC::File::MARCXML;

=head1 NAME

MARC::File::MARCXML - MARCXML implementation for MARC records

=cut

use strict;
use integer;

use XML::DOM;
use XML::Writer;
use vars qw( $ERROR );
use MARC::File::Encode qw( marc_to_utf8 );

use MARC::File;
use vars qw( @ISA ); @ISA = qw( MARC::File );

use MARC::Record qw( LEADER_LEN );
use MARC::Field;
use constant SUBFIELD_INDICATOR     => "\x1F";
use constant END_OF_FIELD           => "\x1E";
use constant END_OF_RECORD          => "\x1D";
use constant DIRECTORY_ENTRY_LEN    => 12;

=head1 SYNOPSIS

use MARC::File::MARCXML;

my $file = MARC::File::MARCXML->in( $filename );

while ( my $marc = $file->next() ) {
# Do something
}
$file->close();
undef $file;

=head1 EXPORT

None.

=head1 METHODS

=cut

sub _next {
  my $self = shift;
  my $fh = $self->{fh};

  my $reclen;
  return if eof($fh);

  local $/ = END_OF_RECORD;
  my $MARCXML = <$fh>;

# remove illegal garbage that sometimes occurs between records
  $MARCXML =~ s/^[ \x00\x0a\x0d\x1a]+//;

  return $MARCXML;
}

sub _get_xml_text($)
{
  my ($node) = @_;

  return '' if (!$node);

  $node = $node->getFirstChild();
  return '' if (!$node);

  my $str = $node->getData();
  return $str;
#  return pack('C*', unpack('U0C*', $str));
}

=head2 decode( $string [, \&filter_func ] )

    Constructor for handling data from a MARCXML file.  This function takes care of
    all the tag directory parsing & mangling.

    Any warnings or coercions can be checked in the C<warnings()> function.

    The C<$filter_func> is an optional reference to a user-supplied function
    that determines on a tag-by-tag basis if you want the tag passed to it
    to be put into the MARC record.  The function is passed the tag number
    and the raw tag data, and must return a boolean.  The return of a true
    value tells MARC::File::MARCXML::decode that the tag should get put into
    the resulting MARC record.

    For example, if you only want title and subject tags in your MARC record,
    try this:

    sub filter {
      my ($tagno,$tagdata) = @_;

      return ($tagno == 245) || ($tagno >= 600 && $tagno <= 699);
}

my $marc = MARC::File::MARCXML->decode( $string, \&filter );

Why would you want to do such a thing?  The big reason is that creating
    fields is processor-intensive, and if your program is doing read-only
    data analysis and needs to be as fast as possible, you can save time by
    not creating fields that you'll be ignoring anyway.

    Another possible use is if you're only interested in printing certain
    tags from the record, then you can filter them when you read from disc
    and not have to delete unwanted tags yourself.

=cut

sub decode {

  my $text;
  my $location = '';

## decode can be called in a variety of ways
## $object->decode( $string )
## MARC::File::MARCXML->decode( $string )
## MARC::File::MARCXML::decode( $string )
## this bit of code covers all three

  my $self = shift;
  if ( ref($self) =~ /^MARC::File/ ) {
    $location = 'in record '.$self->{recnum};
    $text = shift;
  } else {
    $location = 'in record 1';
    $text = $self=~/MARC::File/ ? shift : $self;
  }
  my $filter_func = shift;

  my $parser = new XML::DOM::Parser;

  my $doc = undef;
  eval { $doc = $parser->parse($text) };
  if ($@)
{
  die("could not parse xml: $!");

}


# ok this the empty shell we will fill
my $marc = MARC::Record->new();

my @leaders = $doc->getElementsByTagName('leader');
foreach my $leader (@leaders) {
  my $fielddata = _get_xml_text($leader);
  $marc->leader( $fielddata );
}

my @controlfields = $doc->getElementsByTagName('controlfield');
foreach my $controlfield (@controlfields)
{
  my $tag = $controlfield->getAttributeNode('tag')->getValue();

  my $fielddata = _get_xml_text($controlfield);
  $fielddata =~ s/\r\n/ /g;
  $fielddata =~ s/\r//g;
  $fielddata =~ s/\n/ /g;

  my $field = MARC::Field->new($tag, $fielddata);
  $marc->append_fields($field);

}

my @datafields = $doc->getElementsByTagName('datafield');
foreach my $datafield (@datafields)
{
  my $tag = $datafield->getAttributeNode('tag')->getValue();

  my $ind1 = $datafield->getAttributeNode('ind1')->getValue();
  my $ind2 = $datafield->getAttributeNode('ind2')->getValue();

  my $field;

  my @subfields = $datafield->getElementsByTagName('subfield');
  foreach my $subfield (@subfields)
{
  my $sub_code = $subfield->getAttributeNode('code')->getValue();
  my $sub_contents = _get_xml_text($subfield);
  $sub_contents =~ s/\r\n/ /g;
  $sub_contents =~ s/\r//g;
  $sub_contents =~ s/\n/ /g;

  if (!defined($field)) {
    $field = MARC::Field->new($tag, $ind1, $ind2,$sub_code => $sub_contents);
  } else {
    $field->add_subfields($sub_code => $sub_contents);
  }
}

$marc->append_fields($field);


}
$doc->dispose();


return $marc;
}

=head2 encode()

    Returns a string of characters suitable for writing out to a MARCXML file

=cut

sub encode() {
  my $marc = shift;
  $marc = shift if (ref($marc)||$marc) =~ /^MARC::File/;

  my $opts = shift;

  my $doc;
  my $writer = new XML::Writer(OUTPUT => \$doc, ENCODING => 'utf-8', DATA_INDENT => 2);
  if (defined($opts) && defined($opts->{'skipDeclaration'}) && $opts->{'skipDeclaration'}) {
# don't write xml declaration
  } else {
    $writer->xmlDecl("UTF-8");
  }


  $writer->startTag("record");


  $writer->startTag("leader");
  $writer->characters($marc->leader());
  $writer->endTag("leader");

  for my $field ($marc->fields()) {

    if ($field->is_control_field()) {

      $writer->startTag("controlfield", "tag" => $field->tag());

      $writer->characters($field->data());

      $writer->endTag("controlfield");

    } else {

      $writer->startTag("datafield", "tag" => $field->tag(), "ind1"=>$field->indicator(1), "ind2"=>$field->indicator(2));

      for my $subfield ($field->subfields) {


        $writer->startTag("subfield", "code" => $subfield->[0]);
        $writer->characters($subfield->[1]);
        $writer->endTag("subfield");

      }


      $writer->endTag("datafield");
    }


  }


  $writer->endTag("record");
  $writer->end();

  return $doc;

}
1;

__END__

=head1 RELATED MODULES

L<MARC::Record>

=head1 TODO

Make some sort of autodispatch so that you don't have to explicitly
specify the MARC::File::X subclass, sort of like how DBI knows to
use DBD::Oracle or DBD::Mysql.
 
Create a toggle-able option to check inside the field data for
end of field characters.  Presumably it would be good to have
it turned on all the time, but it's nice to be able to opt out
if you don't want to take the performance hit.
 
=head1 LICENSE

Copyright (c) 2011-2014, 2016 University Of Helsinki (The National Library Of Finland)
 
This project's source code is licensed under the terms of GNU General Public License Version 3.
 
=head1 AUTHOR
 
The National Library of Finland
 
=cut

