File::HashCache
---------------

File::HashCache is an automatic versioning scheme for Javascript, CSS, or
any other kind of file based on the hash of the contents of the files
themselves. It aims to be painless for the developer and very fast.

For full documentation, run:

    perldoc lib/File/HashCache.pm

Installation
------------

To build, test and install:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

License
-------

Copyright © 2009-2013 David Caldwell <david@porkrind.org>
                  and Jim Radford <radford@blackbean.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
