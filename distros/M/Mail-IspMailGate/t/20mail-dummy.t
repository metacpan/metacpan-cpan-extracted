# -*- perl -*-
#
# Check the dummy filter: Feed a mail into it; result must be identical
# with input.
#

use strict;

use Mail::IspMailGate::Test;
require Mail::IspMailGate::Filter::Dummy;

$| = 1;
print "1..4\n";

my @recipients =
    ( { 'recipient' => 'joe-dummy@ispsoft.de',
	'filters' => [ Mail::IspMailGate::Filter::Dummy->new({}) ] } );
my $parser = MiMail('20mail-dummy.t',
		    'output_dir' => 'output',
		    'tmp_dir' => 'output/tmp',
		    'recipients' => \@recipients);

my $e = MIME::Entity->build('From' => 'amar@ispsoft.de',
			    'To' => 'joe@ispsoft.de',
			    'Subject' => 'Mail-Attachment',
			    'Type' => 'multipart/mixed');
$e->attach('Path' => 'Makefile',
	   'Type' => 'text/plain',
	   'Encoding' => 'quoted-printable');
$e->attach('Path' => 'ispMailGateD',
	   'Type' => 'application/x-perl',
	   'Encoding' => 'base64');
my($entity) = MIME::Entity->build('From' => 'joe@ispsoft.de',
				  'To' => 'amar@ispsoft.de',
				  'Subject' => 'Re: Mail-Attachment',
				  'Type' => 'multipart/mixed');
$entity->attach('Path' => 'MANIFEST',
		'Type' => 'text/plain',
		'Encoding' => 'quoted-printable');
$entity->add_part($e);
MiTest($entity, undef, "Building the entity\n");

my $filter = Mail::IspMailGate::Filter::Dummy->new({});
MiTest($filter, undef, "Creating the filter\n");

my $input = $entity->as_string();
my $output = MiMailParse($parser, $filter, $input,
			 'joe@ispsoft.de', ['joe-dummy@ispsoft.de'],
			 "20md.in", "20md.out");
MiTest($input eq $output);
