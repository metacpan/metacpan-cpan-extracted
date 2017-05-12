# Change 1..1 below to 1..last_test_to_print .


BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use vars qw($verbose);

$loaded = 1;
print "ok 1\n";

$testnum=2;

use Carp;
use IO::File;

use Metadata::SOIF;

#Metadata::SOIF::debug(1);

{
  my $a=new Metadata::SOIF;

  $a->set("Domain", "ukc.ac.uk");
  $a->set("URI", "http://www.ukc.ac.uk/");
  $a->set("Host", "www.ukc.ac.uk");

  my $v1=$a->get("Domain");
  my $v2=$a->get("URI");
  my $v3=$a->get("Host");

  if (defined $v1 && $v1 eq 'ukc.ac.uk' &&
      defined $v2 && $v2 eq 'http://www.ukc.ac.uk/' &&
      defined $v3 && $v3 eq 'www.ukc.ac.uk') {
    print "ok $testnum\n";
  } else {
    warn "Domain value was $v1\n";
    warn "URI value was $v2\n";
    warn "Host value was $v3\n";
    print "not ok $testnum\n";
  }

  $testnum++;

  my $tmp="test$$.soif";
  my $fmt=$a->format("file:$tmp");
  {
    my $out_h=new IO::File ">$tmp";
    croak "Could not create tmp file $tmp - $!\n" unless $out_h;
    print $out_h $fmt;
    $out_h->close;
  }

  {
    my $b=new Metadata::SOIF;

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


if (0) {
 my $b=new Metadata::SOIF;

 my $file="0/OBJ1770431700";

 my $in_h=new IO::File "$file";
 croak "Could not read file $file - $!\n" unless $in_h;
 $b->read($in_h,"file:$file");
 $in_h->close;

 warn "Got ",$b->size, " elements:\n";

 for my $element ($b->elements) {
   my $s=($b->size($element) >1) ? " (".$b->size($element)." sub values)" : '';
   warn $element,$s,' - ',length($b->get($element))," bytes\n";
 }

 $testnum++;
}


# The pack and unpack methods don't preserve either the template type
# or the URL of the SOIF structure. The following short piece of code
# shows the bug. - Simon Wilkinson
{

	my $soif1=new Metadata::SOIF;
	$soif1->template_type("foo");
	$soif1->url("bar");
	print $soif1->as_string;
	$packed=$soif1->pack;
	
	my $soif2=new Metadata::SOIF;
	$soif2->unpack($packed);

	my $url=$soif2->url;
	my $tt=$soif2->template_type;
	if ($url eq 'bar' && $tt eq 'foo') {
	  print "ok $testnum\n";
	} else {
	  warn "URL was $url - expected bar\n";
	  warn "Template Type was $tt - expected foo\n";
	  print "not ok $testnum\n";
	}
	$testnum++;
}

# I believe that I've found a bug in Metadata::SOIF (0.21)
# ... read() doesn't work as expected ... [when the start of the
# value is a newline] - Hrvoje Stipetic
{
  my $tmp_soif="ex1.soif";
  open(OUT, ">$tmp_soif") or die "Cannot create $tmp_soif - $!\n";
  print OUT <<'EOD';
@FILE { news:foo@bar
Attribute1{11}:	
0123456789
Attribute2{10}:	0123456789
}
EOD
  close(OUT);
  
  open (IN, $tmp_soif) or die "Cannot read $tmp_soif - $!\n";
  my $soif=new Metadata::SOIF;
  $soif->read(\*IN);
  close(IN);
  
  unlink $tmp_soif;

  my $v1=$soif->get("Attribute1") || '(undefined)';
  my $v2=$soif->get("Attribute2") || '(undefined)';

  if ($v1 eq "\n0123456789" && $v2 eq '0123456789') {
    print "ok $testnum\n";
  } else {
    warn "Attribute1 is '$v1', expected <NL>0123456789\n";
    warn "Attribute2 is '$v2', expected 0123456789\n";
    print "not ok $testnum\n";
  }
  $testnum++;
}
