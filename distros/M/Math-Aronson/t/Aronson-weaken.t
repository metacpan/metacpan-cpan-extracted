#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 5;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Math::Aronson;

# version 2.002 for "ignore"
my $have_test_weaken = eval "use Test::Weaken 2.002; 1" || 0;
if (! $have_test_weaken) {
  MyTestHelpers::diag ("Test::Weaken 2.002 not available -- $@");
}
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits 1; 1" || 0;
if (! $have_test_weaken_extrabits) {
  MyTestHelpers::diag ("Test::Weaken::ExtraBits 1 not available -- $@");
}
my $skip = (! $have_test_weaken
            ? "due to Test::Weaken 2.002 not available"
            : ! $have_test_weaken_extrabits
            ? "due to Test::Weaken::ExtraBits 1 not available"
            : undef);

sub my_ordinal {
  return 'foo';
}

foreach my $options ([],
                     [ conjunctions => 0 ],
                     [ lang => 'fr' ],
                     [ lang => 'fr', conjunctions => 0 ],
                     [ ordinal_func => \&my_ordinal ],
                    ) {
  my $leaks = !$skip && Test::Weaken::leaks
    ({ constructor => sub {
         return Math::Aronson->new (@$options);
       },
       ignore => \&Test::Weaken::ExtraBits::ignore_global_functions,
     });
  skip ($skip,
        $leaks||0,
        0,
        'Test::Weaken deep garbage collection');
  if ($leaks) {
    MyTestHelpers::dump($leaks);

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      MyTestHelpers::diag ("  unfreed $proberef");
    }
    foreach my $proberef (@$unfreed) {
      MyTestHelpers::diag ("  search $proberef");
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
