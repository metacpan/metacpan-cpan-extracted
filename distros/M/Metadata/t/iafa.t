# Change 1..1 below to 1..last_test_to_print .


BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use vars qw($verbose);

$loaded = 1;
print "ok 1\n";

$testnum=2;

use Carp;
use IO::File;

use Metadata::IAFA;


{
  my $a=new Metadata::IAFA;

  $a->set("Domain-v0", "ukc.ac.uk");
  $a->set("URI-v2", "http://www.ukc.ac.uk/");
  $a->set("Host", "www.ukc.ac.uk",0);

  my $v1=$a->get("Domain-v0");
  my $v2=$a->get("URI-v2");
  my $v3=$a->get("Host-v0");

  if (defined $v1 && $v1 eq 'ukc.ac.uk' &&
      defined $v2 && $v2 eq 'http://www.ukc.ac.uk/' &&
      defined $v3 && $v3 eq 'www.ukc.ac.uk') {
    print "ok $testnum\n";
  } else {
    warn "Domain-v0 value was $v1\n";
    warn "URI-v2 value was $v2\n";
    warn "Host-v0 value was $v3\n";
    print "not ok $testnum\n";
  }

  $testnum++;

  my $fmt=$a->format;
  my $tmp="test$$.iafa";
  {
    my $out_h=new IO::File ">$tmp";
    croak "Could not create tmp file $tmp - $!\n" unless $out_h;
    print $out_h $fmt;
    $out_h->close;
  }

  {
    my $b=new Metadata::IAFA;

    my $in_h=new IO::File "$tmp";
    croak "Could not read tmp file $tmp - $!\n" unless $in_h;
    $b->read($in_h);
    $in_h->close;

    unlink $tmp;

    my $failed=0;
    for my $element ($a->elements) {
      my $a_val=$a->get($element);
      my $b_val=$b->get($element);
      if (!defined $b_val) {
        warn "Element $element in b was undefined, should be $a_val\n";
        $failed=1;
      } elsif ($a_val ne $b_val) {
        warn "Element $element in b was '$b_val', should be '$a_val'\n";
        $failed=1;
      }
    }

    if (!$failed) {
      print "ok $testnum\n";
    } else {
      print "not ok $testnum\n";
    }
  }

  $testnum++;
}

