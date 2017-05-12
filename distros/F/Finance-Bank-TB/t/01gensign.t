#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..3\n"; }

use Finance::Bank::TB;

sub do_test
{
  my ($num, $key, $expect, $amt, $vs, $cs, $rurl ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('9999',$key);

  $myob1->configure(
		cs => $cs,
		vs => $vs,
		amt => $amt,
		rurl => $rurl,
	);

  my $result = $myob1->get_send_sign();
  print "initStr: $myob1->{'initstr'}\n";
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

sub do_test1
{
  my ($num, $key, $expect, $vs, $res ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('9999',$key);

  $myob1->configure(
		vs => $vs,
		res => $res,
	);

  my $result = $myob1->get_recv_sign();
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

sub do_test2
{
  my ($num, $key, $expect, $amt, $vs, $cs, $rurl, $name, $ipc ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('9999',$key);

  $myob1->configure(
		cs => $cs,
		vs => $vs,
		name => $name,
		amt => $amt,
		ipc => $ipc,
		rurl => $rurl,
	);

  my $result = $myob1->get_send_sign();
  print "initStr: $myob1->{'initstr'}\n";
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

print "If the following results don't match, there's something wrong.\n\n";

do_test("1", "12345678" , "5C65E607C8E45B19",
	'1234.50', '1111', '0308', 'https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/example.jsp', 'OK'
);

do_test1("2", "12345678" , "810EE9A1BCE9CD94",
	 '1111', 'OK'
);

do_test2("3", "12345678" , "7C1A24298933462D",
	'1234.50', '1111', '0308', 'https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/example.jsp', 'Jan Pokusny', '1.2.3.4', 'OK'
);
