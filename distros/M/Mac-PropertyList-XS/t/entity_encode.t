use strict;

use Test::More tests => 5;

use Mac::PropertyList::XS;

{
    my @input = (
        "<&>'",
        [ qw(& ' < > ") ],
        {
            c => [ '"', '"two"' ],
            f => {
                "'" => Mac::PropertyList::SAX::true->new,
                '&&&amp;' => 1,
                '><' => [ { a => ' foo & bar << 3 ' } ],
            },
        },
    );

    while (defined(my $input = shift @input)) {
        my $string = Mac::PropertyList::XS::create_from_ref($input);
        my $parsed = Mac::PropertyList::XS::parse_plist_string($string);

        is_deeply($parsed, $input, "XML entity encoding");
    }
}

{
    use Encode;
    my $parsed = Mac::PropertyList::XS::parse_plist_file 'plists/test2.plist';
    is_deeply($parsed, { 'only' => [ '< & >', '< & >', '< & >', decode("utf-8",'☹') ] }, 'XML entity encoding from file');

    local $/;
    open my $fh, 'plists/test3.plist';
    my $plist_str = <$fh>;
    is(Mac::PropertyList::XS::plist_as_string($parsed), $plist_str, 'XML entity re-encoding to string');
}
