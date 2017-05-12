# NAME

List::Prefixed - Prefixed String List

# SYNOPSIS

    use List::Prefixed;

    # construct a new prefixed tree
    $folded = List::Prefixed->fold(qw( Fu Foo For Form Foot Food Ba Bar Baz ));

    # get all items sharing a common prefix
    @list = $folded->list('Fo'); # Foo, Food, Foot, For, Form

    # serialize as regular expression
    $regex = $folded->regex; # '(?:Ba(?:r|z)?|F(?:o(?:o(?:d|t)?|r(?:m)?)|u))'

    # de-serialize from regular expression
    $unfolded = List::Prefixed->unfold($regex);

# DESCRIPTION

The idea of a _Prefixed List_ comes from regular expressions determining a finite
list of words, like this:

    /(?:Ba(?:r|z)?|F(?:o(?:o(?:d|t)?|r(?:m)?)|u))/
    

The expression above matches exactly these strings:

    "Ba", "Bar", "Baz", "Foo", "Food", "Foot", "For", "Form", "Fu".

Representing a string list that way can have some advantages in certain situations:

- The regular expression provides efficient test methods on arbitrary strings
(e.g. whether or not a string is contained in the list or starts or ends with an element
from the list).
- The representaion is compressing, depending on how many shared prefixes appear in a list.
- Conversely, a prefixed list can be efficiently set up from such a regular expression.
Thus, the prefixed list leads to a natural way of serialization and de-serialization.
- Sub lists sharing a common prefix can be extracted efficently from a prefixed list. 
This leads to an efficient implementation of auto-completion.

For example, from Perl [package names](https://cpan.metacpan.org/modules/02packages.details.txt)
indexed on CPAN, one can get a list of about 82K module names that takes more than 2M data.
We can compress the list to a regular expression of about 900K that matches exactly all these names.

A _Prefixed List_ is a tree consisting of node triples, formally defined as follows:

    node: ( prefix [node-list] opt )
      where:
        prefix: String
        node-list: List of node
        opt: Boolean

The list elements are the prefix strings, each of them appended to the prefix of the parent node. 
The `opt` flag is true if the list of sub nodes is optional, i.e., if the node prefix appended 
together with the parent prefixes is also contained in the list itself.
      

Any string list has a trivial representation that way, if one takes each string as the prefix
of a node with empty node-list and collects all these nodes into a parent node with empty prefix.

A prefixed tree is called _folded_, if it's in minimal form, i.e. if there are no two
child nodes in a parent node sharing a common left part in their prefixes. Obviously, for 
each string list, there exists a unique folded _Prefixed Tree_ representation.
      

# METHODS

## new

    $prefixed = List::Prefixed->new( @list );

This is an alias of the [fold](#fold) method.

## fold

    $prefixed = List::Prefixed->fold( @list );

Constructs a new folded `List::Prefixed` tree from the given string list.

## unfold

    $prefixed = List::Prefixed->unfold( $regex );

Constructs a new `List::Prefixed` tree from a regular expression string.
The string argument shuld be obtained from the [regex](#regex) method.

## list

    @list = $prefixed->list;
    @list = $prefixed->list( $string );

Returns the list of list elements starting with the given string if a string argument
is present or the whole list otherwise. In scalar context an ARRAY reference is
returned.

## regex

    $regex = $prefixed->regex;

Returns a minimized regular expression (as string) matching exactly the strings
the object has been constructed with.

You can control the escaping style of the expression. The default behavior is
to apply Perl's [quotemeta](http://perldoc.perl.org/functions/quotemeta.html) function
and replace any non-ASCII character with `\x{FFFF}`, where `FFFF` is the hexadecimal
character code. This is the Perl-compatible or PCRE style. To obtain an expression
compatible with Java and the like, use

    use List::Prefixed uc_escape_style => 'Java'; # \uFFFF style

To skip Unicode escaping completely, use

    use List::Prefixed uc_escape_style => undef;  # do not escape

Alternatively, you can control the style at runtime by way of
[configuration variables](#CONFIGURATION VARIABLES).

# CONFIGURATION VARIABLES

- _$UC\_ESCAPE\_STYLE_

Controls the escaping style for Unicode (non-ASCII) characters.
The value can be one of the following:

    - `'PCRE'`

    Default style `\x{FFFF}`

    - `'Java'`

    Java etc. style `\uFFFF`

    - `undef`

    Do not escape Unicode characters at all. This may result in shorter expressions
    but may cause encoding issues under some circumstances.

- _$REGEX\_ESCAPE_, _$REGEX\_UNESCAPE_

By providing string functions one can customize the escaping behavior arbitrarily.
In this case, `$UC_ESCAPE_STYLE` has no effect.

# KNOWN BUGS

The term _prefix_ refers to the storage order of characters. That is, prefix
filtering with right-to-left written Unicode strings (such as Arabic or Hebrew)
goes to the wrong direction from the user's point of view.

Large lists may cause deep recursion within the [fold](#fold) method. To avoid a lot of [Deep recursion on anonymous subroutine](http://perldoc.perl.org/perldiag.html) warnings, there is a

    no warnings 'recursion'

directive in place. This is worth mentioning, though it's not actually a bug.

# EXPORT

Strictly OO, exports nothing.

# REPOSITORY

[https://github.com/boethin/List-Prefixed](https://github.com/boethin/List-Prefixed)

# AUTHOR

Sebastian Böthin, <boethin@xn--domain.net>

# COPYRIGHT AND LICENSE

Copyright (C) 2015 by Sebastian Böthin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
