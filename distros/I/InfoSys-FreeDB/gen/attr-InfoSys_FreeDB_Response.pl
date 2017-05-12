use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg = "${pkg_base}::Response";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB response',
        abstract => 'FreeDB response',
        synopsis => <<'EOF',
None. This is an abstract class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'code',
             short_description => 'the response code',
             mandatory =>1,
        },
        {
             method_factory_name => 'error',
             type => 'BOOLEAN',
             short_description => 'the response has an error',
        },
        {
             method_factory_name => 'result',
             short_description => 'the response result text',
             mandatory =>1,
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
    ],
    use_opt => [
    ],
    sym_opt => [
        {
            symbol_name => '$CODE_RX',
            export_tag => [ qw( line_parse ) ],
            description => <<EOF,
Regular expression to parse the return code and the remaining tail.
EOF
            assignment => <<'EOF',
'^\s*(\d{3})\s+(.*)';
EOF
        },
    ],
    tag_opt => [
        {
            export_tag_name => 'line_parse',
            description => <<EOF,
This tag contains variables useful to parse the messages from C<FreeDB> servers.
EOF
        },
    ],
} );
