# NAME

List::ToHumanString - write lists in strings like a human would

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use List::ToHumanString;

    print to_human_string "Report{|s} for |list|\n", qw/March May July/;
    ## Prints "Reports for March, May, and July";

    print to_human_string "Report{|s} for |list|\n", qw/March July/;
    ## Prints "Reports for March and July";

    print to_human_string "Report{|s} {is|are} needed for |list|\n", qw/March/;
    ## Prints "Report is needed for March";

<div>
    </div></div>
</div>

# DESCRIPTION

Provides a way to make it easy to prepare a string containing
a list of items, where that string is meant to be read by a human.

# SEE ALSO

[Lingua::Conjunction](https://metacpan.org/pod/Lingua::Conjunction) -- You might find [Lingua::Conjunction](https://metacpan.org/pod/Lingua::Conjunction)
more apt at joining the list of things, if that's the only
thing that you're after.

# EXPORTS BY DEFAULT

## `to_human_string`

    print to_human_string "Report{|s} for |list|\n", qw/March May July/;
    ## Prints "Reports for March, May, and July";

    print to_human_string "Report{|s} for |list|\n", qw/March July/;
    ## Prints "Reports for March and July";

    print to_human_string "Report{|s} {is|are} needed for |list|\n", qw/March/;
    ## Prints "Report is needed for March";

    print to_human_string '|list|', qw/March May July/;
    ## Prints "March, May, and July";

    $List::ToHumanString::Separator   = '*SEP*';
    $List::ToHumanString::Extra_Comma = 0;
    print to_human_string "I have {one item*SEP*many items}: *SEP*list*SEP*", qw/Foo Bar Baz/;
    ## Prints "I have many items: Foo, Bar and Baz" (note the missing comma before "and")

**Exported by default**. **Takes** a string to "humanize" as the first argument
and a list of items to use.
**Removes all undefs and empty and blank strings** before counting the
number of items in the list. If the list contains one item, chooses the
"singular" variation in the first argument's format (see below). If the list
contains any other number of items, chooses "plural" variation in the format.
Once all the substitutions have been done, **returns** the resultant string.

### first argument format

    "I have {one item|many items}"

    "I have {one item that is|many items that are} |list|"

    "I have item{|s}: |list|"

    "I have {a|} thing{|s}"

    $List::ToHumanString::Separator = '::SEP::';
    "I have {one item::SEP::many items}: ::SEP::list::SEP::",

### singular/plural

`to_human_string()` will replace any occurence of `{singularSEPARATORplural}`
with either the `"singular"` or `"plural"` texts, depending on the number of
items in the list given to it. The `"singular"` and `"plural"` texts can
be any text (even empty string) that doesn't have a `SEPARATOR` in it.
The `SEPARATOR`
is the value of `$List::ToHumanString::Separator`, which **by default**
is a pipe character (`|`). Regex special characters in the `SEPARATOR`
have no effect.

### humanized list

    "I have item{|s}: |list|"

    "I have {one item::SEP::many items}: ::SEP::list::SEP::",

You can automatically insert a "humanized" list of items into your string
by using word `list` set off be `SEPARATOR` string on each side.
That string will be replaced by a "humanized" way to write the
list of items you provided, which is as follows:

#### empty list of items

    to_human_string('|list|',);
    # returns ''

Humanized string will be: empty string.

#### 1-item list of items

    to_human_string('|list|', 'foo');
    # returns 'foo'

    to_human_string('|list|', URI->new("http://example.com") );
    # returns 'http://example.com'

Humanized string will be: the item itself (stringified).

#### 2-item list of items

    to_human_string('|list|', 'foo', 'bar');
    # returns 'foo and bar'

Humanized string will be: the two items joined with `' and '`

#### list with 3 or more items

    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber, and baz'

    $List::ToHumanString::Extra_Comma = 0;
    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber and baz'

Humanized string will be: the list of items in the list you provided
joined with `', '` (comma and space).
The last element is also preceded by word `'and '`. **Note:** depending
on your stylistic preference, you might wish not to have a comma before
the last element. You can accomplish that by setting
`$List::ToHumanString::Extra_Comma` to zero.

# VARIABLES

## `$List::ToHumanString::Separator`

    my @items = ( 1..10 );
    $List::ToHumanString::Separator = '::SEP::';
    print to_human_string "I have {one item::SEP::many items} {foo|bar}\n", @items;
    ## Prints "I have many items {foo|bar}"

**Takes** any non-empty string as a value.
**Specifies** what separator to use between the "singular" and "plural" texts
in the string given to `to_human_string()`.
**Defaults to:** `|` (a pipe character)

## `$List::ToHumanString::Extra_Comma`

    $List::ToHumanString::Extra_Comma = 0;
    to_human_string('|list|', 'foo', 'bar', 'ber', 'baz');
    # returns 'foo, bar, ber and baz'

**Takes** true or false values as a value.
**Specifies** whether to use a comma after the penultimate element in the
list when using `to_human_string()` to insert humanized list into the
string. If set to a true value, the comma
will be used. **Defaults to:** `1` (true value).

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/List-ToHumanString](https://github.com/zoffixznet/List-ToHumanString)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/List-ToHumanString/issues](https://github.com/zoffixznet/List-ToHumanString/issues)

If you can't access GitHub, you can email your request
to `bug-list-tohumanstring at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
