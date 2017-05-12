#
# same as 02_write, except without the ->flush calls
#

use Test::More tests => 17;
use FlatFile;
ok(1); # If we made it this far, we're ok.
my $DATA_START = tell DATA;

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [qw(fruit color)],
                                  MODE => "+<",
                                  );
ok($f);

{
  my ($banana) = my @rec = $f->lookup(fruit => "banana");
  is(scalar(@rec), 1, "one record for banana");
  is($banana->color, "green", "unripe banana");
  $banana->set_color("yellow");   # banana is now ripe
  is($banana->color, "yellow", "unripe banana");
}
undef $f;  # close file

# now try again and make sure it is still ripe
$f = FlatFile->new(FILE => $FILE,
                   FIELDS => [qw(fruit color)],
                   MODE => "<",
                  );
ok($f);

{
  my ($banana) = my @rec = $f->lookup(fruit => "banana");
  is(scalar(@rec), 1, "one record for banana");
  is($banana->color, "yellow", "ripening was recorded");
  eval { $banana->set_color("blue") };
  ok($@, "read-only refuses set-color call");
}

#
# Now a test with different field and record separators
#
undef $f;
unlink $FILE;
open F, ">", $FILE or die "$FILE: $!";
seek DATA, $DATA_START, 0;
while (<DATA>) {
  chomp;
  s/\s+/:/g;
  print F $_, "---";
}
close F;

# now try again and make sure it is still ripe
$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                               FIELDSEP => ":",
                               RECSEP => "---",
                              );
ok($f);
is($f->field_separator_string, ":", "fieldsep string check");

{ 
  my ($banana) = my @rec = $f->lookup(fruit => "banana");
  is(scalar(@rec), 1, "one record for banana");
  is($banana->color, "green", "unripe banana");
  $banana->set_color("yellow");   # banana is now ripe
  is($banana->color, "yellow", "ripe banana");
}
undef $f;  # close file

$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                               FIELDSEP => ":",
                               RECSEP => "---",
                              );
ok($f);
{
  my ($banana) = my @rec = $f->lookup(fruit => "banana");
  is(scalar(@rec), 1, "one record for banana");
  is($banana->color, "yellow", "banana still ripe");
}



#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

__DATA__
apple  red
banana green
cherry red
kiwi brown
