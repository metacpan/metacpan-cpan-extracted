use Test::More qw(no_plan);
use XML::LibXML;

use Games::Nintendo::Wii::Mii;

{
    my @mii_files = glob("./sample/*.mii");

    for my $mii_file (@mii_files) {
        my Games::Nintendo::Wii::Mii $mii = Games::Nintendo::Wii::Mii->new;

        $mii->parse_from_file($mii_file);
        my $xml_string = $mii->to_xml;

        my $parser = XML::LibXML->new;
        my $doc = $parser->parse_string($xml_string);
        my $ctx = XML::LibXML::XPathContext->new($doc);

        is($mii->to_hexdump, $ctx->findvalue(q|//mii-collection/mii[@value]/@value|));
        is($mii->profile->name, $ctx->findvalue(q|//mii-collection/mii[@value]/name/text()|));
        is($mii->profile->creator_name, $ctx->findvalue(q|//mii-collection/mii[@value]/creator/text()|));

        for my $key (grep { exists $Games::Nintendo::Wii::Mii::STRUCT{$_}->{name} } keys %Games::Nintendo::Wii::Mii::STRUCT) {
            my $accessor = $Games::Nintendo::Wii::Mii::STRUCT{$key}->{accessor};
            my $name = $Games::Nintendo::Wii::Mii::STRUCT{$key}->{name};

            is($mii->$accessor->$key, $ctx->findvalue(q|//mii-collection/mii[@value]/data[@name="| . $name . q|"]/@value|), $key);
        }
    }
}
