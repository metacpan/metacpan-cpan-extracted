HTML::AutoTag
=============
Just another HTML tag generator. [![CPAN Version](https://badge.fury.io/pl/HTML-AutoTag.svg)](https://metacpan.org/pod/HTML::AutoTag) [![Build Status](https://api.travis-ci.org/jeffa/HTML-AutoTag.svg?branch=master)](https://travis-ci.org/jeffa/HTML-AutoTag)

Synopsis
--------
```perl
use HTML::AutoTag;

my $auto = HTML::AutoTag->new( indent => '    ', encode => 1 );

my %attr = ( style => { color => [qw(red green)] } );
my @data = qw( one two three four five six seven eight );

print $auto->tag(
    tag   => 'ol', 
    attr  => {qw( reversed reversed )},
    cdata => [
        map { tag => 'li', attr => \%attr, cdata => $_ }, @data
    ]
);
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc HTML::AutoTag
```
You can also find documentation at [metaCPAN](https://metacpan.org/pod/HTML::AutoTag).

License and Copyright
---------------------
See [source POD](/lib/HTML/AutoTag.pm).
