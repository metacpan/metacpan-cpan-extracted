package TestMLBridge;
use TestML::Bridge;
use base 'TestML::Bridge';

use JSONY;
use JSON::PP;
use YAML::PP;

sub jsony_load {
    my ($self, $jsony) = @_;
    $jsony =~ s/\|\n\z//;
    return 'JSONY'->load($jsony);
}

sub json_decode {
    my ($self, $json) = @_;
    return decode_json $json;
}

sub yaml {
    my ($self, $object) = @_;
    my $yaml = YAML::PP->new(schema => [qw'Core Perl'])->dump($object);

    # Account for various JSONs
    $yaml =~
        s{!perl/scalar:JSON::(?:XS::|PP::|backportPP::|)Boolean}
        {!perl/scalar:boolean}g;

    # XXX Floating point discrepancy hack
    $yaml =~ s/\.000+1//g;

    return $yaml;
}

1;
