package TestMLBridge;
use base 'TestML::Bridge';
use TestML::Util;

use JSYNC;

sub load_jsync {
    return str JSYNC::load(pop->value);
}

sub dump_jsync {
    return str JSYNC::dump(pop->value);
}

sub load_yaml {
    require YAML::XS;
    return str YAML::XS::Load(pop->value);
}

sub dump_yaml {
    require YAML::XS;
    return str YAML::XS::Dump(pop->value);
}

sub chomp {
    my $str = pop->value;
    chomp($str);
    return str $str;
}

sub eval {
    return str eval(pop->value);
}

1;
