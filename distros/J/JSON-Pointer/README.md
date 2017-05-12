# NAME

JSON::Pointer - A Perl implementation of JSON Pointer (RFC6901)

# VERSION

This document describes JSON::Pointer version 0.07.

# SYNOPSIS

    use JSON::Pointer;

    my $obj = {
      foo => 1,
      bar => [ { qux => "hello" }, 3 ],
      baz => { boo => [ 1, 3, 5, 7 ] }
    };

    JSON::Pointer->get($obj, "/foo");       ### $obj->{foo}
    JSON::Pointer->get($obj, "/bar/0");     ### $obj->{bar}[0]
    JSON::Pointer->get($obj, "/bar/0/qux"); ### $obj->{bar}[0]{qux}
    JSON::Pointer->get($obj, "/bar/1");     ### $obj->{bar}[1]
    JSON::Pointer->get($obj, "/baz/boo/2"); ### $obj->{baz}{boo}[2]

# DESCRIPTION

This library is implemented JSON Pointer ([http://tools.ietf.org/html/rfc6901](http://tools.ietf.org/html/rfc6901)) and 
some useful operator from JSON Patch ([http://tools.ietf.org/html/rfc6902](http://tools.ietf.org/html/rfc6902)).

JSON Pointer is available to identify a specified value in JSON document, and it is simillar to XPath.
Please read the both of specifications for details.

# METHODS

## get($document :HashRef/ArrayRef/Scalar, $pointer :Str, $strict :Int) :Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

- $strict :Int

    Strict mode. When this value equals true value, this method may throw exception on error.
    When this value equals false value, this method return undef value on error.

Get specified value identified by _$pointer_ from _$document_.
For example,

    use JSON::Pointer;
    print JSON::Pointer->get({ foo => 1, bar => { "qux" => "hello" } }, "/bar/qux"); ### hello

## get\_relative($document :HashRef/ArrayRef/Scalar, $current\_pointer :Str, $relative\_pointer :Str, $strict :Int) :Scalar

**This method is highly EXPERIMENTAL**. Because this method depends on [http://tools.ietf.org/html/draft-luff-relative-json-pointer-00](http://tools.ietf.org/html/draft-luff-relative-json-pointer-00) draft spec.

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $current\_pointer : Str

    JSON Pointer string to identify specified current position in the document.

- $relative\_pointer : Str

    JSON Relative Pointer string to identify specified value from current position in the document

- $strict :Int

    Strict mode. When this value equals true value, this method may throw exception on error.
    When this value equals false value, this method return undef value on error.

## contains($document :HashRef/ArrayRef/Scalar, $pointer :Str) :Int

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to present by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

Return which the target location identified by _$pointer_ exists or not in the _$document_.

    use JSON::Pointer;

    my $document = { foo => 1 };
    if (JSON::Pointer->contains($document, "/foo")) {
      print "/foo exists";
    }

## add($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :HashRef/ArrayRef/Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

- $value :HashRef/ArrayRef/Scalar

    The perl data structure that is able to be presented by JSON format.

Add specified _$value_ on target location identified by _$pointer_ in the _$document_.
For example, 

    use JSON::Pointer;

    my $document = +{ foo => 1, };
    my $value = +{ qux => "hello" };

    my $patched_document = JSON::Pointer->add($document, "/bar", $value);
    print $patched_document->{bar}{qux}; ### hello

## remove($document, $pointer) :Array/Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

Remove target location identified by _$pointer_ in the _$document_.

    use JSON::Pointer;

    my $document = { foo => 1 };
    my $patched_document = JSON::Pointer->remove($document, "/foo");
    unless (exists $patched_document->{foo}) {
      print "removed /foo";
    }

This method is contextial return value. When the return value of _wantarray_ equals true,
return _$patched\_document_ and _$removed\_value_, or not return _$patched\_document_ only.

## replace($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Array/HashRef/ArrayRef/Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

- $value :HashRef/ArrayRef/Scalar

    The perl data structure that is able to be presented by JSON format.

Replace the value of target location specified by _$pointer_ to the _$value_ in the _$document_.

    use JSON::Pointer;

    my $document = { foo => 1 };
    my $patched_document = JSON::Pointer->replace($document, "/foo", 2);
    print $patched_document->{foo}; ## 2

This method is contextial return value. When the return value of _wantarray_ equals true,
return _$patched\_document_ and _$replaced\_value_, or not return _$patched\_document_ only.

## set($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Array/HashRef/ArrayRef/Scalar

This method is alias of replace method.

## copy($document :HashRef/ArrayRef/Scalar, $from\_pointer :Str, $to\_pointer :Str) :HashRef/ArrayRef/Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $from\_pointer :Str

    JSON Pointer string to identify specified value in the document.

- $to\_pointer :Str

    JSON Pointer string to identify specified value in the document.

Copy the value identified by _$from\_pointer_ to target location identified by _$to\_pointer_.
For example,

    use JSON::Pointer;

    my $document = +{ foo => [ { qux => "hello" } ], bar => [ 1 ] };
    my $patched_document = JSON::Pointer->copy($document, "/foo/0/qux", "/bar/-");
    print $patched_document->{bar}[1]; ## hello

Note that "-" notation means next of last element in the array.
In this example, "-" means 1.

## move($document :HashRef/ArrayRef/Scalar, $from\_pointer :Str, $to\_pointer :Str) :HashRef/ArrayRef/Scalar

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $from\_pointer :Str

    JSON Pointer string to identify specified value in the document.

- $to\_pointer :Str

    JSON Pointer string to identify specified value in the document.

Move the value identified by _$from\_pointer_ to target location identified by _$to\_pointer_.
For example,

    use JSON;
    use JSON::Pointer;

    my $document = +{ foo => [ { qux => "hello" } ], bar => [ 1 ] };
    my $patched_document = JSON::Pointer->move($document, "/foo/0/qux", "/bar/-");
    print encode_json($patched_document); ## {"bar":[1,"hello"],"foo":[{}]}

## test($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Int

- $document :HashRef/ArrayRef/Scalar

    Target perl data structure that is able to be presented by JSON format.

- $pointer :Str

    JSON Pointer string to identify specified value in the document.

- $value :HashRef/ArrayRef/Scalar

    The perl data structure that is able to be presented by JSON format.

Return which the value identified by _$pointer_ equals _$value_ or not in the _$document_.
This method distinguish type of each values.

    use JSON::Pointer;

    my $document = { foo => 1 };

    print JSON::Pointer->test($document, "/foo", 1); ### 1
    print JSON::Pointer->test($document, "/foo", "1"); ### 0

## traverse($document, $pointer, $opts) : JSON::Pointer::Context

This method is used as internal implementation only.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

- [perl](https://metacpan.org/pod/perl)
- [Mojo::JSON::Pointer](https://metacpan.org/pod/Mojo::JSON::Pointer)

    Many codes in this module is inspired by the module.

- [http://tools.ietf.org/html/rfc6901](http://tools.ietf.org/html/rfc6901)
- [http://tools.ietf.org/html/rfc6902](http://tools.ietf.org/html/rfc6902)
- [http://tools.ietf.org/html/draft-luff-relative-json-pointer-00](http://tools.ietf.org/html/draft-luff-relative-json-pointer-00)

# AUTHOR

Toru Yamaguchi <zigorou at cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Toru Yamaguchi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
