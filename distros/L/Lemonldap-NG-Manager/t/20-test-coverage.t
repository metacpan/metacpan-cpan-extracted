# Verify that all attributes owns a test

use Test::More;
use strict;
use Lemonldap::NG::Common::Conf::ReConstants;

use_ok('Lemonldap::NG::Manager::Build::Attributes');
my $count = 1;

my ( $attrs, $types );
ok( $attrs = Lemonldap::NG::Manager::Build::Attributes::attributes(),
    'Get attributes' );
ok( $types = Lemonldap::NG::Manager::Build::Attributes::types(), 'Get types' );
$count += 2;

foreach my $attr ( keys %$attrs ) {
    next if ( $attr =~ /^virtualHosts|.*MetaDataNodes|applicationList$/ );
    ok( (
                 ref( $attrs->{$attr}->{test} )
              or ref( $types->{ $attrs->{$attr}->{type} }->{test} )
        ),
        "Test exists for $attr"
    );
    $count++;
    if ( $attr =~ qr/^$simpleHashKeys$/o ) {
        ok( (
                     ref $attrs->{$attr}->{keyTest}
                  or ref $types->{ $attrs->{$attr}->{type} }->{keyTest}
            ),
            "Key test for $attr"
        );
        $count++;
    }
    if (   $attr =~ qr/^$simpleHashKeys$/o
        or $attrs->{$attr}->{type} =~ /Container$/ )
    {
        if ( $attrs->{$attr}->{default} ) {
            ok(
                ref( $attrs->{$attr}->{default} ) eq 'HASH',
                "$attr default value is a hash ref"
            );
            $count++;
        }
    }
}

done_testing($count);
