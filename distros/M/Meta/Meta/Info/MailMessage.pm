#!/bin/echo This is a perl module and should not be run

package Meta::Info::MailMessage;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Mail::Sendmail qw();
use Meta::Class::MethodMaker qw();
use Meta::Baseline::Test qw();
use Meta::Utils::Utils qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub send($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_subject",
		-java=>"_text",
		-java=>"_from",
		-java=>"_recipients",
		-java=>"_error",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_recipients(Meta::Ds::Array->new());
}

sub send($) {
	my($self)=@_;
	my($reci)=$self->get_recipients();
	my(@list);
	for(my($i)=0;$i<$reci->size();$i++) {
		push(@list,$reci->getx($i));
	}
	my($to)=join("\,\ ",@list);
	my(%mail)=(
		To=>$to,
#		From=>$self->get_from(),
		Subject=>$self->get_subject(),
		Message=>$self->get_text()
	);
	if(defined($self->get_from())) {
		$mail{"From"}=$self->get_from();
	}
	my($scod)=Mail::Sendmail::sendmail(%mail);
	if($scod) {
		$self->set_error($Mail::Sendmail::log);
	} else {
		$self->set_error($Mail::Sendmail::error);
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	my($user)=Meta::Baseline::Test::get_user();
	my($host)=Meta::Baseline::Test::get_host();
	my($domain)=Meta::Baseline::Test::get_domain();

	my($message)=Meta::Info::MailMessage->new();
	$message->set_subject("Meta::Info::MailMessage::TEST()");
	$message->set_text("This is a dummy message sent from Meta::Info::MailMessage TEST()");
	my($sender)=Meta::Utils::Utils::cuname();
	$message->set_from($sender."\@".$domain);
	$message->get_recipients()->push($user."\@".$host);
	my($scod)=$message->send();
	if(!$scod) {
		Meta::Utils::Output::print("error was [".$message->get_error()."]\n");
	}
	return($scod);
}

1;

__END__

=head1 NAME

Meta::Info::MailMessage - an email message encapsulation.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: MailMessage.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Info::MailMessage qw();
	my($message)=Meta::Info::MailMessage->new();
	$message->set_subject("Microsoft paradigm shift into the hamburger business");
	$message->set_recipients(["billg@microsoft.com"]);
	$message->set_text("Dear Sir! I wish to complain about the bad quality of chips with your hamburger");
	$message->set_from("john@doe.org");
	my($result)=$message->send();
	if($result) {
		print "Message sent\n";
	}

=head1 DESCRIPTION

This is an object which encapsulates an email message.
It has the subject, text, recipients etc...
What is this good for ? object oriented encapsulation.
This object can, ofcourse, send itself using the Mail::Sendmail
module.

=head1 FUNCTIONS

	BEGIN()
	init($)
	send($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method sets up accessor methods for the attributes of this class.
The attributes are:
0. "subject" - subject of the message.
1. "text" - text of the message.
2. "from" - for field for the message.
3. "recipients" - recipient list for the message.
4. "error" - error message string (retrieve in case of error).

=item B<init($)>

Internal method which does instance initialization.

=item B<send($)>

This method will send the message.
The method returns the result of the send.

=item B<TEST($)>

Test suite for this module.
Currently it creates a message and sends it. The information about the
recipent is taken from the Test module.

This test currently creates a short message and sends it to the consenting
to be abused user.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging again
	0.01 MV more Perl packaging
	0.02 MV PDMT
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV more Class method generation
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site development
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV finish papers
	0.15 MV md5 issues

=head1 SEE ALSO

Mail::Sendmail(3), Meta::Baseline::Test(3), Meta::Class::MethodMaker(3), Meta::Ds::Array(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-add more capabilities here. (attachments and signatures for instance). Also add fields from which email program this was send (X-Mailer or some tags).

-do the test stuff.
