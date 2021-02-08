# NAME

JavaScript::Minifier - Perl extension for minifying JavaScript code

# SYNOPSIS

To minify a JavaScript file and have the output written directly to another file

    use JavaScript::Minifier qw(minify);

    open(my $in, 'myScript.js') or die;
    open(my $out, '>', 'myScript-min.js') or die;

    minify(input => $in, outfile => $out);

    close($in);
    close($out);

To minify a JavaScript string literal. Note that by omitting the outfile parameter a the minified code is returned as a string.

    my $minifiedJavaScript = minify(input => 'var x = 2;');

To include a copyright comment at the top of the minified code.

    minify(input => 'var x = 2;', copyright => 'BSD License');

To treat ';;;' as '//' so that debugging code can be removed. This is a common JavaScript convention for minification.

    minify(input => 'var x = 2;', stripDebug => 1);

The "input" parameter is mandatory. The "output", "copyright", and "stripDebug" parameters are optional and can be used in any combination.

# DESCRIPTION

This module removes unnecessary whitespace from JavaScript code. The primary requirement developing this module is to not break working code: if working JavaScript is in input then working JavaScript is output. It is ok if the input has missing semi-colons, snips like '++ +' or '12 .toString()', for example. Internet Explorer conditional comments are copied to the output but the code inside these comments will not be minified.

The ECMAScript specifications allow for many different whitespace characters: space, horizontal tab, vertical tab, new line, carriage return, form feed, and paragraph separator. This module understands all of these as whitespace except for vertical tab and paragraph separator. These two types of whitespace are not minimized.

For static JavaScript files, it is recommended that you minify during the build stage of web deployment. If you minify on-the-fly then it might be a good idea to cache the minified file. Minifying static files on-the-fly repeatedly is wasteful.

## EXPORT

Exported by default: `minifiy()`

# SEE ALSO

This module is inspired by Douglas Crockford's JSMin:
[http://www.crockford.com/javascript/jsmin.html](http://www.crockford.com/javascript/jsmin.html)

You may also be interested in the [CSS::Minifier](https://metacpan.org/pod/CSS%3A%3AMinifier) module also
available on CPAN.

# REPOSITORY

You can obtain the latest source code and submit bug reports
on the github repository for this module:
[https://github.com/zoffixznet/JavaScript-Minifier](https://github.com/zoffixznet/JavaScript-Minifier)

# MAINTAINER

Zoffix Znet `<zoffix@cpan.org>` [https://metacpan.org/author/ZOFFIX](https://metacpan.org/author/ZOFFIX)

# AUTHORS

Peter Michaux, <petermichaux@gmail.com>

Eric Herrera, <herrera@10east.com>

# CONTRIBUTORS

Miller 'tmhall' Hall

Вячеслав 'vti' Тихановский

Fedor A. 'faf' Fetisov

# COPYRIGHT AND LICENSE

Copyright (C) 2007 by Peter Michaux

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
