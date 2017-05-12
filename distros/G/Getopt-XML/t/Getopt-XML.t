# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Getopt-XML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Getopt::XML') };
use_ok('XML::TreePP');
use_ok('XML::TreePP::XMLPath');
use_ok('Getopt::Long');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tpp  = XML::TreePP->new();
my $tppx = XML::TreePP::XMLPath->new();
my $cfgx = Getopt::XML->new();

ok ( defined($cfgx) && ref $cfgx eq 'Getopt::XML', 'new()' );

my $xmldoc =<<XML_EOF;
<test>
    <apple>
        <color>red</color>
        <type>red delicious</type>
        <isAvailable/>
        <cityGrown>Macomb</cityGrown>
        <cityGrown>Peoria</cityGrown>
        <cityGrown>Galesburg</cityGrown>
    </apple>
</test>
XML_EOF

my $tree = $tpp->parse($xmldoc);
my ($path, %options, $result, $flag);

$path   = '/test/apple';

$cfgx->GetXMLOptions (
        xmldoc   => $tree,
        xmlpath  => $path,
        Getopt_Long     =>
        [
        \%options,
                'isAvailable',
                'color=s',
                'type=s',
                'cityGrown=s@'
        ]
);


# Test XML Document Parsing and filtering by XMLPath
ok ( join("",@{$options{'cityGrown'}}) eq join("",@{$tree->{'test'}->{'apple'}->{'cityGrown'}}), "GetXMLOptions() by XML node - test 1" ) || diag explain ( \%options, $tree );

$flag   = 0;
if (   ( $options{'color'} eq 'red' )
    && ( $options{'isAvailable'} == 1 )
    && ( $options{'type'} eq 'red delicious' ) )
    {
        $flag = 1;
    }
ok ( $flag == 1, "GetXMLOptions() by XML node - test 2" );
