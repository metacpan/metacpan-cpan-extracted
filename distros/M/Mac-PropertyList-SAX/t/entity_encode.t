use Test::More tests => 5;

use Mac::PropertyList::SAX;

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

	# This is not a really robust test; it tests round-tripping, but doesn't
	# guarantee that the plist is actually valid in-between
    while (defined(my $input = shift @input)) {
        my $string = Mac::PropertyList::SAX::create_from_ref($input);
        my $parsed = Mac::PropertyList::SAX::parse_plist_string($string);

        is_deeply($parsed, $input, "XML entity encoding");
    }
}

{
    use Encode;
    my $parsed = Mac::PropertyList::SAX::parse_plist_file 'plists/test2.plist';
    is_deeply($parsed, { 'only' => [ '< & >', '< & >', '< & >', decode("utf-8",'☹') ] }, 'XML entity encoding from file');

    local $/;
    open $fh, 'plists/test3.plist';
    my $plist_str = <$fh>;
    is(Mac::PropertyList::SAX::plist_as_string($parsed), $plist_str, 'XML entity re-encoding to string');
}
