use Lego::Ldraw;
use strict;

my ($edit, $file) = @ARGV;
my $l = Lego::Ldraw->new_from_file($file);

for (@$l) {
  $_->eval($edit);
}

print $l;
