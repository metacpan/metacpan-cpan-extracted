#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp ();
use MARC::Convert::Wikidata;
use MARC::File::XML;
use MARC::Record;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Print::Item;

my $marc_xml = decode_utf8(<<'END');
<?xml version="1.0" encoding="UTF-8"?>
<collection
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
  xmlns="http://www.loc.gov/MARC21/slim">
<record>
  <leader>01177nam a2200349 i 4500</leader>
  <controlfield tag="001">nkc20193102359</controlfield>
  <controlfield tag="003">CZ PrNK</controlfield>
  <controlfield tag="005">20190813103856.0</controlfield>
  <controlfield tag="007">ta</controlfield>
  <controlfield tag="008">190612s1917    xr af  b      000 f cze  </controlfield>
  <datafield tag="015" ind1=" " ind2=" ">
    <subfield code="a">cnb003102359</subfield>
  </datafield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="q">(Vázáno)</subfield>
  </datafield>
  <datafield tag="040" ind1=" " ind2=" ">
    <subfield code="a">ABA001</subfield>
    <subfield code="b">cze</subfield>
    <subfield code="e">rda</subfield>
  </datafield>
  <datafield tag="072" ind1=" " ind2="7">
    <subfield code="a">821.162.3-3</subfield>
    <subfield code="x">Česká próza</subfield>
    <subfield code="2">Konspekt</subfield>
    <subfield code="9">25</subfield>
  </datafield>
  <datafield tag="072" ind1=" " ind2="7">
    <subfield code="a">821-93</subfield>
    <subfield code="x">Literatura pro děti a mládež (beletrie)</subfield>
    <subfield code="2">Konspekt</subfield>
    <subfield code="9">26</subfield>
  </datafield>
  <datafield tag="080" ind1=" " ind2=" ">
    <subfield code="a">821.162.3-34</subfield>
    <subfield code="2">MRF</subfield>
  </datafield>
  <datafield tag="080" ind1=" " ind2=" ">
    <subfield code="a">821-93</subfield>
    <subfield code="2">MRF</subfield>
  </datafield>
  <datafield tag="080" ind1=" " ind2=" ">
    <subfield code="a">(0:82-34)</subfield>
    <subfield code="2">MRF</subfield>
  </datafield>
  <datafield tag="100" ind1="1" ind2=" ">
    <subfield code="a">Karafiát, Jan,</subfield>
    <subfield code="d">1846-1929</subfield>
    <subfield code="7">jk01052941</subfield>
    <subfield code="4">aut</subfield>
  </datafield>
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">Broučci :</subfield>
    <subfield code="b">pro malé i veliké děti /</subfield>
    <subfield code="c">Jan Karafiát</subfield>
  </datafield>
  <datafield tag="250" ind1=" " ind2=" ">
    <subfield code="a">IV. vydání</subfield>
  </datafield>
  <datafield tag="264" ind1=" " ind2="1">
    <subfield code="a">V Praze :</subfield>
    <subfield code="b">Alois Hynek,</subfield>
    <subfield code="c">[1917?]</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">85 stran, 5 nečíslovaných listů obrazových příloh :</subfield>
    <subfield code="b">ilustrace (některé barevné) ;</subfield>
    <subfield code="c">24 cm</subfield>
  </datafield>
  <datafield tag="336" ind1=" " ind2=" ">
    <subfield code="a">text</subfield>
    <subfield code="b">txt</subfield>
    <subfield code="2">rdacontent</subfield>
  </datafield>
  <datafield tag="337" ind1=" " ind2=" ">
    <subfield code="a">bez média</subfield>
    <subfield code="b">n</subfield>
    <subfield code="2">rdamedia</subfield>
  </datafield>
  <datafield tag="338" ind1=" " ind2=" ">
    <subfield code="a">svazek</subfield>
    <subfield code="b">nc</subfield>
    <subfield code="2">rdacarrier</subfield>
  </datafield>
  <datafield tag="655" ind1=" " ind2="7">
    <subfield code="a">české pohádky</subfield>
    <subfield code="7">fd133970</subfield>
    <subfield code="2">czenas</subfield>
  </datafield>
  <datafield tag="655" ind1=" " ind2="7">
    <subfield code="a">publikace pro děti</subfield>
    <subfield code="7">fd133156</subfield>
    <subfield code="2">czenas</subfield>
  </datafield>
  <datafield tag="655" ind1=" " ind2="9">
    <subfield code="a">Czech fairy tales</subfield>
    <subfield code="2">eczenas</subfield>
  </datafield>
  <datafield tag="655" ind1=" " ind2="9">
    <subfield code="a">children's literature</subfield>
    <subfield code="2">eczenas</subfield>
  </datafield>
  <datafield tag="910" ind1=" " ind2=" ">
    <subfield code="a">ABA001</subfield>
  </datafield>
  <datafield tag="998" ind1=" " ind2=" ">
    <subfield code="a">003102359</subfield>
  </datafield>
</record>
</collection>
END
my $marc_record = MARC::Record->new_from_xml($marc_xml, 'UTF-8');

# Object.
my $obj = MARC::Convert::Wikidata->new(
        'marc_record' => $marc_record,
);

# Convert MARC record to Wikibase object.
my $item = $obj->wikidata;

# Print out.
print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($item));

# Output like:
# TODO Add callbacks.
# No callback method for translation of people in 'authors' method.
# No callback method for translation of language.
# Label: Broučci: pro malé i veliké děti (en)
# Description: 1917 Czech book edition (en)
# Statements:
#   P31: Q3331189 (normal)
#   P3184: cnb003102359 (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }
#   P393: 4 (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }
#   P1104: 85 (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }
#   P577: 1917 (Q1985727) (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }
#   P1680: pro malé i veliké děti (cs) (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }
#   P1476: Broučci (cs) (normal)
#   References:
#     {
#       P248: Q86914821
#       P3184: cnb003102359
#       P813: 26 May 2023 (Q1985727)
#     }