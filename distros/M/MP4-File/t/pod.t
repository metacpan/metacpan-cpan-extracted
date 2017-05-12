################################################################################
#
#  $Revision: 2 $
#  $Author: mhx $
#  $Date: 2008/04/08 08:03:54 +0200 $
#
################################################################################
# 
# Copyright (c) 2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use strict;
use IO::File;

my @pods;

# find all potential pod files
my $man = IO::File->new('MANIFEST');
if ($man) {
  chomp(my @files = <$man>);
  for my $f (@files) {
    my $fh = IO::File->new($f);
    if ($fh) {
      while (<$fh>) {
        if (/^=\w+/) {
          push @pods, $f;
          last;
        }
      }
    }
  }
}

# load Test::Pod if possible, otherwise load Test::More
eval {
  require Test::Pod;
  $Test::Pod::VERSION >= 0.95
      or die "Test::Pod version only $Test::Pod::VERSION";
  import Test::Pod tests => scalar @pods;
};

if ($@) {
  require Test::More;
  import Test::More skip_all => "testing pod requires Test::Pod";
}
else {
  for my $pod (@pods) {
    pod_file_ok($pod);
  }
}

