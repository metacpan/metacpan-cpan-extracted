use strict; use warnings;

use Test::More tests => 4;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

{open  my($f), ">", $FILE or die "$FILE: $!" }

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [],
                                  FIELDSEP => ":",
                                 ) or die;
ok($f);

is($f->field_separator_string, ":", "field separator");
is($f->record_separator, "\n", "record separator");
