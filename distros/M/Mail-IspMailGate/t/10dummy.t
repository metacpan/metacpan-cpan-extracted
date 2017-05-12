# -*- perl -*-
#
# Check the dummy filter: Feed a mail into it; result must be identical
# with input.
#

use strict;

use Mail::IspMailGate::Test;
require Mail::IspMailGate::Filter::Dummy;

$| = 1;
print "1..5\n";

my $parser = MiParser();

my $e = MIME::Entity->build('From' => 'amar@ispsoft.de',
			    'To' => 'joe@ispsoft.de',
			    'Subject' => 'Mail-Attachment',
			    'Path' => 'Makefile',
			    'Type' => 'text/plain',
			    'Encoding' => 'quoted-printable');
$e->attach('Path' => 'ispMailGateD',
	   'Type' => 'application/x-perl',
	   'Encoding' => 'base64');
my $entity = MIME::Entity->build('From' => 'joe@ispsoft.de',
				 'To' => 'amar@ispsoft.de',
				 'Subject' => 'Re: Mail-Attachment',
				 'Path' => 'MANIFEST',
				 'Type' => 'text/plain',
				 'Encoding' => 'quoted-printable');
$entity->add_part($e);
MiTest($entity, undef, "Building the entity\n");

my $filter = Mail::IspMailGate::Filter::Dummy->new({});
MiTest($filter, undef, "Creating the dummy filter\n");

my($result, $entity2) = MiParse($parser, $filter, $entity,
				"10d.in", "10d.out");
MiTest(!$result);
MiTest($entity->as_string() eq $entity2->as_string());
