use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More tests => 1;

require Ftree::Name;
my $family_tree = Ftree::Name->new(
          {first_name => "Nikolay",
           mid_name   => "Alekseevich",
           last_name  => "Mishin",});
isa_ok $family_tree, "Ftree::Name", "Ftree::Name->new";