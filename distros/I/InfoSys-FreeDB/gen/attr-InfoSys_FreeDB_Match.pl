use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg = "${pkg_base}::Match";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB query match',
        abstract => 'FreeDB query match',
        synopsis => &::read_synopsis( 'syn-http.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information on FreeDB query match.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'categ',
             short_description => 'the match category',
        },
        {
             method_factory_name => 'discid',
             short_description => 'the match discid',
        },
        {
             method_factory_name => 'dtitle',
             short_description => 'the match disk title',
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
    ],
    use_opt => [
    ],
} );
