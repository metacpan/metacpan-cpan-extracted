use Modern::Perl;
use MARC::Moose::Record;
use MARC::Moose::Field;
use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use MARC::Moose::Parser::Marcxml;
use C4::Context;
use Koha::Contrib::ARK;
use YAML;
use JSON;

use Test::More tests => 40;
use Test::Exit;
use Test::MockModule;


my $ark_conf = {
    ark => {
        "NMHA" => "myspecial.test.fr",
        "NAAN" => "12345",
        "ARK" => "http://{NMHA}/ark:/{NAAN}/catalog{id}",
        "koha" => {
          "id" => { "tag" => "001" },
          "ark" => { "tag" => "090", "letter" => "z" }
        }
    }
};


my $xml_chunk = <<EOS;
<record>
  <leader>01529    a2200217   4500</leader>
  <controlfield tag="001">1234</controlfield>
  <controlfield tag="005">20180505165105.0</controlfield>
  <controlfield tag="008">800108s1899    ilu           000 0 eng  </controlfield>
  <controlfield tag="009">132000601</controlfield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">0-19-877306-4</subfield>
  </datafield>
  <datafield tag="041" ind1=" " ind2=" ">
    <subfield code="a">eng</subfield>
  </datafield>
  <datafield tag="100" ind1=" " ind2=" ">
    <subfield code="a">Burda, Michael C.</subfield>
    <subfield code="u">Economics and Political Science</subfield>
  </datafield>
  <datafield tag="245" ind1=" " ind2=" ">
    <subfield code="a">Macroeconomics:</subfield>
    <subfield code="b">a European text</subfield>
  </datafield>
  <datafield tag="260" ind1=" " ind2=" ">
    <subfield code="b">Oxford University Press,</subfield>
    <subfield code="c">1993.</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">486 p. :</subfield>
    <subfield code="b">Graphs ;</subfield>
    <subfield code="c">25 cm.</subfield>
  </datafield>
  <datafield tag="690" ind1=" " ind2=" ">
    <subfield code="a">Economics</subfield>
  </datafield>
  <datafield tag="700" ind1=" " ind2=" ">
    <subfield code="a">Wyplosz, Charles</subfield>
  </datafield>
  <datafield tag="942" ind1=" " ind2=" ">
    <subfield code="a">bib777</subfield>
    <subfield code="c">BK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">DO</subfield>
    <subfield code="b">DO</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">000426795</subfield>
    <subfield code="y">BK</subfield>
  </datafield>
</record>
EOS

my $parser = MARC::Moose::Parser::Marcxml->new();
my $record = $parser->parse( $xml_chunk );

my $m = Test::MockModule->new('C4::Context');
$m->mock('preference', sub { return 0; });

my $ark = Koha::Contrib::ARK->new();
ok( $ark->explain->{error}->{err_pref_missing}, 'ARK_CONF missing detected' );

$m->mock('preference', sub { return to_json($ark_conf, {pretty => 1}); });

$ark_conf->{a} = $ark_conf->{ark};
delete $ark_conf->{ark};
$ark = Koha::Contrib::ARK->new();
ok( $ark->explain->{error}->{err_pref_ark_missing}, 'ark variable missing in ARK_CONF' );

$ark_conf->{ark} = $ark_conf->{a};
delete $ark_conf->{a};
$ark = Koha::Contrib::ARK->new();

is( $ark->cmd, 'check', "->cmd default value is 'check'" );
is( $ark->verbose, '0', "->verbose default value is '0'" );
is( $ark->doit, '0', "->doit default value is '0'" );
is( $ark->debug, '0', '->debug default value is 0');
is(
    $ark->field_query,
    "ExtractValue(metadata, '//datafield[\@tag=\"090\"]/subfield[\@code=\"z\"]')",
    "->field_query properly build" );
$ark->set_current(1234, $record);
is(
    $ark->current->{biblionumber},
    1234,
    "current->{biblionumber} = 1234");
is(
    $ark->current->{record},
    undef,
    'current->{record} undef');
$ark->debug(1);
$ark->set_current(1234, $record);
is(
    ref $ark->current->{record},
    'HASH',
    'current->{record} set to a HASH');
is(
    ref $ark->current->{record}->{fields},
    'ARRAY',
    'current->{record} has a valid structure');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated for ID 1234 by build_ark" );
is(
    ref $ark->current->{what},
    'HASH',
    '->current->{what} is an ARRAY');
ok( $ark->{current}->{what}->{generated}, '->{what}->{generated}' );
is(
    $ark->{current}->{what}->{generated}->{more},
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    'valid ARK in ->{what}->{more}');

$record->field('001')->value('4321');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog4321',
    "valid ARK generated for ID 4321 by build_ark" );
$record->delete('001');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated for ID 1234 (fallback to biblionumber without 001) by build_ark" );
ok( $ark->current->{what}->{use_biblionumber}, '->{what}->{use_biblionumber}');
$record->append( MARC::Moose::Field::Control->new( tag => '001', value => '1234' ) );

# Take the ID in 009 field rather than 001
$ark_conf->{ark}->{koha}->{id} = { tag => '009' };
$ark = Koha::Contrib::ARK->new();
$ark->set_current(1234, $record);
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog132000601',
    "valid ARK generated by build_ark - ID from 009" );
$record->delete('009');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated (fallback to biblionumber without 009) by build_ark" );

# Take the ID in 942$a
$ark_conf->{ark}->{koha}->{id} = { tag => '942', letter => 'a' };
$ark = Koha::Contrib::ARK->new();
$ark->set_current(1234, $record);
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalogbib777',
    "valid ARK generated by build_ark - ID from 942\$a" );

my $ark_field = $record->field('090');
is( $ark_field, undef, "ARK field 090 not present in the record" );
my $updater = Koha::Contrib::ARK::Update->new( ark => $ark );
$updater->action(1234, $record);
ok( $ark->current->{what}->{add}, 'Correct reporting "add" after update');
$ark_field = $record->field('090');
ok( $ark_field, "ARK field 090 present in the record after update" );
is(
    $ark_field->subfield('z'),
    "http://myspecial.test.fr/ark:/12345/catalogbib777",
    "ARK field properly populated in 090\$z" );
$updater->action(1234, $record);
ok( $ark->current->{what}->{remove_existing}, 'Remove existing field while adding ARK field');

my $clearer = Koha::Contrib::ARK::Clear->new( ark => $ark );
$clearer->action(1234, $record);
ok( !$record->field('090'), "ARK field 090 deleted" );
ok( $ark->current->{what}->{clear}, 'Correct reporting "clear" after clear');

$ark_conf->{ark}->{koha}->{ark} = { tag => '003' };
$ark = Koha::Contrib::ARK->new();
$ark->set_current(1234, $record);
$ark_field = $record->field('003');
is( $ark_field, undef, "ARK field 003 not present in the record" );
$updater = Koha::Contrib::ARK::Update->new( ark => $ark );
$updater->action(1234, $record);
ok( $ark->current->{what}->{add}, 'Correct reporting "add" after update in 003');
$ark_field = $record->field('003');
ok( $ark_field, "ARK field 003 present is the record" );
is(
    $ark_field->value,
    "http://myspecial.test.fr/ark:/12345/catalogbib777",
    "ARK field properly populated in 003" );
$ark->set_current(1234, $record);
$updater->action(1234, $record);
ok( $ark->current->{what}->{remove_existing}, 'Remove existing field while adding ARK field 003');

$clearer = Koha::Contrib::ARK::Clear->new( ark => $ark );
$clearer->action(1234, $record);
ok( !$record->field('003'), "ARK field 003 deleted" );
ok( $ark->current->{what}->{clear}, 'Correct reporting "clear" after clear 003');

$ark->set_current(1234, $record);
my $check = Koha::Contrib::ARK::Check->new( ark => $ark );
$check->action(1234, $record);
ok( $ark->current->{what}->{not_found}, 'check 003 ARK: reporting "not_found"');
$updater->action(1234, $record);
$ark->set_current(1234, $record);
$check->action(1234, $record);
ok( $ark->current->{what}->{found_right_field}, 'check 003 ARK: reporting "found_right_field"');
$record->field('003')->tag('009');
$ark->set_current(1234, $record);
$check->action(1234, $record);
ok( $ark->current->{what}->{not_found}, 'check 003 ARK: reporting "not_found" because in 009');
ok( $ark->current->{what}->{found_wrong_field}, 'check 003 ARK: reporting "found_wrong_field"');
is(
    $ark->current->{what}->{found_wrong_field}->{more},
    'Found in 009',
    'found_wrong_field but in 009');

