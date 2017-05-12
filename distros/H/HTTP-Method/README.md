HTTP-Method
===========
HTTP Request Method and Common Properties according to RFC 7231

SYNOPSIS
--------

`
    use HTTP::Method;
    
    # prefered instantiation
    my $get_mth = HTTP::Method->GET;
    
    # or from string
    my $str_mth = HTTP::Method->new(uc 'get');
    
    # testing
    if ( $mth->is_GET ) { ... }
    
    # introspection
    $mth->is_method_safe;
`

DESCRIPTION
-----------

There is a lot to say about HTTP Methods in [RFC 7231 Section 4. Request Methods]
(https://tools.ietf.org/html/rfc7231#section-4).
Most of the developers make the wrong assumption that it is just a 'uppercase
string'. This module will help writing better code as it does validation and
ensures right capitalization for the HTTP Method names.

As one could read in [RFC 7231 Section 4.2 Common Method Properties]
(|https://tools.ietf.org/html/rfc7231#section-4.2)
HTTP Methods do have properties and can be divided in: _Safe Methods_,
_Idempotent Methods_ and _Cacheable Methods_. These properties are just
predicate methods on a `HTTP::Method` object
