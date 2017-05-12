use strict;
use warnings;

use MARC::Record;
use MARC::File::XML;
use File::Temp;
use Test::More tests => 2;

# we'll allow internal parsed entities
my $xml_ent = q(<?xml version="1.0" standalone="no" ?>
<!DOCTYPE subfield [
    <!ENTITY avram "Henriette Avram">
]>
<record>
    <datafield tag="245" ind1="0" ind2="0">
         <subfield code="a">The original MARC format /</subfield>
         <subfield code="c">&avram;</subfield>
    </datafield>
</record>);

my $marc_ent = MARC::Record->new_from_xml($xml_ent);
is($marc_ent->subfield('245', 'c'), 'Henriette Avram', 'can expand normal entity');

# external entities, however, will not be allowed unless a client
# passes an XML::LibXML::Parser via ->set_parser() that doesn't
# disable fetching external entities.
my $xml_ext_ent = q(<?xml version="1.0" standalone="no" ?>
<!DOCTYPE subfield [
    <!ENTITY questionable SYSTEM "XXX">
]>
<record>
    <datafield tag="245" ind1="0" ind2="0">
         <subfield code="a">I was run on &questionable; /</subfield>
    </datafield>
</record>);

# the following is meant to provide a platform-independent
# external file that could be successfully retrieved if the
# parser were allowed fetch external entities; hopefully this
# will catch any changes to XML::LibXML or libxml2 that somehow
# cause ext_ent_handler to be ignored.
my $tmp = File::Temp->new();
print $tmp 'boo!';
my $filename = $tmp->filename;
if ($^O eq 'MSWin32') {
    # normalize filename so that it works as
    # part of a file URI, without having to require URI::file
    $filename =~ s!\\!/!g;
    $filename = "/$filename";
}
$xml_ext_ent =~ s!XXX!file://$filename!g;

my $marc_ext_ent;
eval {
    $marc_ext_ent = MARC::Record->new_from_xml($xml_ext_ent);
};
if ($@) {
    like(
        $@,
        qr/External entities are not supported/,
        'refused to parse MARCXML record containing external entitities'
    );
} else {
    fail('should have refused to parse MARCXML record containing external entitities, but did not');
}
