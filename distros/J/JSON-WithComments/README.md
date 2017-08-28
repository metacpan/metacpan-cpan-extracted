# JSON::WithComments - Parse JSON content with comments

## What Is It

JSON::WithComments is a simple sub-classing of the JSON module that
pre-processes the input text to remove any comments. The scrubbed text is
then passed to the `decode` method of the JSON class.

Where the JSON module itself can handle comments in the style of Perl/shell
(comments starting with a `#`) by use of the `relaxed` method, this module
also supports the JavaScript/C++ style of comments, as well.

## Using JSON::WithComments

JSON::WithComments is simple to use:

```perl
use JSON::WithComments;

my $content = <<JSON;
/*
 * This is a block-comment in the JavaScript style, the default.
 */
{
    // Line comments are also recognized
    "username" : "rjray",  // As are side-comments
    // This should probably be hashed:
    "password" : "C0mputer!"
}
JSON

my $json = JSON::WithComments->new;
my $hashref = $json->decode($json);
```

## Building and Installing

This module builds and installs in the typical Perl fashion:

```
perl Makefile.PL
make && make test
```

If all tests pass, you install with:

```
make install
```

You may need super-user privileges to install.

## Problems and Bug Reports

Please report any problems or bugs to either the Perl RT or GitHub Issues:

* [Perl RT queue for YASF](http://rt.cpan.org/Public/Dist/Display.html?Queue=JSON-WithComments)
* [GitHub Issues for YASF](https://github.com/rjray/json-withcomments/issues)
