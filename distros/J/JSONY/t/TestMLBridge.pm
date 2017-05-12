package TestMLBridge;
use base 'TestML::Bridge';
use TestML::Util;

use JSONY;
use JSON;
use YAML;

sub jsony_load {
    my ($self, $jsony) = @_;
    $jsony = $jsony->value;
    $jsony =~ s/\|\n\z//;
    return native 'JSONY'->new->load($jsony);
}

sub json_decode {
    my ($self, $json) = @_;
    return native decode_json $json->value;
}

sub yaml {
    my ($self, $object) = @_;
    my $yaml = YAML::Dump $object->value;

    # Account for various JSONs
    $yaml =~
        s{!!perl/scalar:JSON::(?:XS::|PP::|backportPP::|)Boolean}
        {!!perl/scalar:boolean}g;

    # XXX Floating point discrepancy hack
    $yaml =~ s/\.000+1//g;

    return str $yaml;
}

1;
