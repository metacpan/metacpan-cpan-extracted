BEGIN {
  $| = 1;

  $is_a_mac=$^O =~ /Mac/i;

  # Try to work on a Mac but ignore problems 
  if ($is_a_mac) {
    $time_offset=2_082_844_800;

    warn "I think I am running on a Mac which has a different time Epoch.\n" .
         "I have tried to compensate by running the problematic tests but ignoring\n" .
	 "results if they are different from what was expected.\n";
  } else {
    $time_offset=0;
  }

  print "1..9\n"; 
}
END {
  print "not ok 1\n" unless $loaded;
}

$loaded = 1;
print "ok 1\n";

$testnum=2;

use Metadata::IAFA;

my $a=new Metadata::IAFA;

my $now=time;

$a->set_date_as_seconds('Date', $now);

my $value=$a->get('Date');

my $revnow=$a->get_date_as_seconds('Date');

if ($revnow eq $now) {
  print "ok $testnum\n";
} else {
  print "notok $testnum\n";
  warn "Date element value was $revnow but expected $now\n";
}
$testnum++;


my $now_iso8601=Metadata::Base::seconds_to_iso8601($now);

my $revnow_iso8601=Metadata::Base::iso8601_to_seconds($now_iso8601);

if ($revnow_iso8601 eq $now) {
  print "ok $testnum\n";
} else {
  print "notok $testnum\n";
  warn "ISO 8601 formatted & reversed time value was $revnow_iso8601 but expected $now\n";
}
$testnum++;


# Tests with burnt-in time values; will fail when Epoch isn't same as Unix
# Compensation added for Mac above.

my(@timevals)=(
  '1997' , '852076800',
  '1997-07' , '867715200',
  '1997-07-16' , '869011200',
  '1997-07-16T19:20+01:00' , '869084400',
  '1997-07-16T19:20:30+01:00' , '869084430',
  '1997-07-16T19:20:30.45+01:00' , '869084430.45',
);

while(@timevals) {
  my($isoval,$expected_value)=splice(@timevals,0,2);

  my $value=Metadata::Base::iso8601_to_seconds($isoval);

  if ($value == $expected_value + $time_offset) {
    print "ok $testnum\n";
  } else {
    print $is_a_mac ? "ok " : "notok", " $testnum\n";
    warn "ISO 8601 formatted value of $isoval was $value but expected $expected_value\n";
  }
  $testnum++;
}
