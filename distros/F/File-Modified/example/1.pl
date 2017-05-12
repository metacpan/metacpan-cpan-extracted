use lib '..';
use Dependencies;

my $d = Dependencies->new(Files=>['Import.cfg','Export.cfg']);

while (1) {
  my (@changes) = $d->changed;
  if (@changes) {
    print "$_ was changed\n" for @changes;
    $d->update();
  } else {
    print "No changes detected.\n";
  };
  sleep 5;
}; 
