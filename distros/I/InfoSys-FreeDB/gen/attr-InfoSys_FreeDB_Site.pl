use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg = "${pkg_base}::Site";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB site',
        abstract => 'FreeDB site',
        synopsis => &::read_synopsis( 'syn-http-sites.pl', '.' ),
        description => <<EOF,
C<${pkg}> objects contain information on FreeDB sites.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'address',
             short_description => 'the additional addressing information needed to access the server',
             default_value => '-',
        },
        {
             method_factory_name => 'site',
             short_description => 'the Internet address of the remote site',
        },
        {
             method_factory_name => 'port',
             short_description => 'the port at which the server resides on that site',
        },
        {
             method_factory_name => 'protocol',
             short_description => 'the supported protocol',
        },
        {
             method_factory_name => 'latitude',
             short_description => 'the latitude of the server site',
        },
        {
             method_factory_name => 'longitude',
             short_description => 'the longitude of the server site',
        },
        {
             method_factory_name => 'description',
             short_description => 'the short description of the geographical location of the site',
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
    ],
    use_opt => [
    ],
} );
