# Copyright © 2009-2013 David Caldwell.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

use Test::More tests => 2;

BEGIN { use_ok("File::HashCache");
        use_ok("File::HashCache::JavaScript");
      }
