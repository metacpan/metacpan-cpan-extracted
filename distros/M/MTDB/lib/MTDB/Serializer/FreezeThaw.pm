####################################################################
package MTDB::Serializer::FreezeThaw;
BEGIN { @MTDB::Serializer::FreezeThaw::ISA = qw(MTDB::Serializer) }

use FreezeThaw;

sub serialize {
    return FreezeThaw::freeze($_[1]);
}

sub deserialize {
    my ($obj) = FreezeThaw::thaw($_[1]);
    return $obj;
}

1;
