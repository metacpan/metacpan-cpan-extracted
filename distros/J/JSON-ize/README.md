# NAME

    JSON::ize - Use JSON easily in one-liners

# SYNOPSIS

    $ perl -MJSON::ize -le '$j=jsonize("my.json"); print $j->{thingy};'

    $ perl -MJSON::ize -le 'J("my.json"); print J->{thingy};' # short

    $ perl -MJSON::ize -le 'print J("my.json")->{thingy};' # shorter


    $ cat my.json | perl -MJSON::ize -lne 'parsej; END{ print J->{thingy}}' # another way

    $ perl -MJSON::ize -le '$j="{\"this\":\"also\",\"works\":[1,2,3]}"; print jsonize($j)->{"this"};' # also

    $ perl -MJSON::ize -e 'pretty_json(); $j=jsonize("ugly.json"); print jsonize($j);' # pretty!

    $ perl -MJSON::ize -e 'ugly_json; print J(J("indented.json"));' # strip whsp

# DESCRIPTION

JSON::ize exports a function, `jsonize()`, that will do what you mean with the argument. 
If argument is a filename, it will try to read the file and decode it as JSON.
If argument is a string that looks like JSON, it will try to encode it.
If argument is a Perl hashref or arrayref, it will try to encode it.

The underlying [JSON](https://metacpan.org/pod/JSON) object is

    $JSON::ize::JOBJ

# METHODS

- jsonize($j), jsonise($j), J($j)

    Try to DWYM.
    If called without argument, return the last value returned. Use this to retrieve
    after ["parsej"](#parsej).

- parsej

    Parse a piped-in stream of json. Use jsonize() (without arg) to retrieve the object.
    (Uses ["incr\_parse" in JSON](https://metacpan.org/pod/JSON#incr_parse).)

- pretty\_json()

    Output pretty (indented) json.

- ugly\_json()

    Output json with no extra whitespace.

# SEE ALSO

[JSON](https://metacpan.org/pod/JSON), [JSON::XS](https://metacpan.org/pod/JSON::XS).

# AUTHOR

    Mark A. Jensen
    CPAN: MAJENSEN
    mark -dot- jensen -at- nih -dot- gov
