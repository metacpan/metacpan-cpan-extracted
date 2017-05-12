package Language::MinCaml::Util;
use strict;
use base qw(Exporter);

our @EXPORT = qw(create_temp_ident_name);

my $ident_count = 0;

sub create_temp_ident_name {
    my $type = shift;
    return "$type->{kind}" . $ident_count++;
}

1;
