package WWW::Fido;

#
# $Header: /cvsroot/WWW::Fido/Fido.pm,v 1.10 2002/11/11 20:09:39 mina Exp $
#

use strict;
use LWP::UserAgent;
use HTTP::Cookies;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

WWW::Fido - Perl extension to send SMS messages to phones served by Fido (http://www.fido.ca)

=head1 SYNOPSIS

=over 4

  use WWW::Fido;

  $phone = new WWW::Fido ("514-123-4567", "JAPH")
	|| die "Error: Couldn't create phone object: $@\n";

  $phone->send("Hello John")
	|| die "Error: Failed to send message: $@\n";

  $phone->send("Hello Again John")
	|| die "Error: Failed to send message: $@\n";

  $phone->setnumber("514-999-8888")
	|| die "Error: Couldn't set destination phone number: $@\n";

  $phone->setname("John Brown")
	|| die "Error: Couldn't set sender name: $@\n";

  $phone->send("Hello Mary")
	|| die "Error: Failed to send message: $@\n";

=back

=head1 DESCRIPTION

=over 4

This module allows you to send SMS messages to Fido subscribers.  It does so by communicating with the web server at http://www.fido.ca and using the Web->SMS gateway available there.

=back

=head1 CONSTRUCTOR

=over 4

=item new($phone, $sendername)

Constructs and returns a new WWW::Fido object.

An optional scalar as the first argument containing the destination phone number can be supplied.  This can be used as a shortcut to save you the call to setnumber().

An optional scalar as the second argument containing the name of the sender can be supplied.  This can be used as a shortcut to save you a call to setname().

=back

=head1 METHODS

=over 4

=item setname($name)

Sets the name of the sender of the message(s). The name will appear in the SMS message at the recipient's end.

=item setnumber($phone)

Sets the phone number that future send() requests should go to.

=item send($message)

Sends the supplied message to the phone number previously set on the object.

=back

=head1 ERRORS ETC...

=over 4

The constructor and all methods return something that evaluates to true when successful and false when not successful.

If not successful, the variable $@ will contain an appropriate message clarifying why it failed.

=back

=head1 IMPORTANT NOTICE

=over 4

Please note that depending on the subscriber's phone plan, receiving SMS messages might cost them.  ALWAYS check with the recipient you use this module to send messages to beforehand.

=back

=head1 AUTHOR

=over 4

Mina Naguib, mnaguib@cpan.org

=back

=head1 COPYRIGHT

=over 4

Copyright (C) 2002 Mina Naguib.
Use is subject to the same terms as the Perl license itself.

I, my employer, my cats, and any lifeforms that live closeby are NOT affiliated in any way with the company Microcell/Fido.  This software is in no way associated or endorsed by them.  It simply provides an easier interface to their SMS gateway on their website. I wrote it to make automating paging to my cellphone easier, that is all.

=back

=head1 SEE ALSO

=over 4

L<http://www.fido.ca>, L<HTTP::UserAgent>

=back

=cut

#
# The main constructor
#
sub new() {
	my $class = shift;
	my $phone = shift;
	my $name = shift;
	my $self = {};
	bless ($self, $class);
	if ($phone && !$self->setphone($phone)) {
		return 0;
		}
	elsif ($name && !$self->setname($name)) {
		return 0;
		}
	else {
		return $self;
		}
	}

#
# This sets the phone number on the given object
#
sub setphone() {
	my $self = shift;
	my $phone = shift;
	$phone =~ s/[^0-9]//g;
	if ($phone !~ /^([0-9]{3})([0-9]{7})$/) {
		$@ = "Phone number ($phone) must be made up of exactly 10 digits";
		return 0;
		}
	else {
		$self->{_phone} = $phone;
		return 1;
		}
	}

#
# This sets the name on the given object
#
sub setname() {
	my $self = shift;
	my $name = shift;
	$self->{_name} = $name;
	return 1;
	}


#
# Ah, the real work here. This is the sub that sends a message
#
sub send() {
	my $self = shift;
	my $message = shift;
	my $error = undef;
	my $maxlength = 155;
	my %data;
	my %data2;
	my $useragent;
	my $request;
        my $cookiejar;
	my $result;
	my $areacode;
	my $phone;

	if (!$self->{_phone}) {
		$error = "No phone number associated with object yet";
		}
	elsif (length($message) < 1) {
		$error = "Message is too short";
		}
	elsif (length($message) > $maxlength) {
		$error = "Message is too long (max is $maxlength)";
		}
	if ($error) {
		$@ = $error;
		return 0;
		}

	#
	# Let's define some variables we'll need while submitting
	#

	($areacode, $phone) = ($self->{_phone} =~ /^(\d\d\d)(\d\d\d\d\d\d\d)$/);

	%data = (
		'lang'			=>	'en',
		'mailfrom'		=>	'fidoweb@infinetcomm.com',
		'mailsubject'	=>	'SMS for you!',
		'areacode'		=>	$areacode,
		'number'			=>	$phone,
		'yourname'		=>	$self->{_name},
		'message'		=>	$message,
		'count'			=>	length($message),
		);

	%data2 = (
		'phone'		=>	$self->{_phone},
		'name'		=>	$self->{_name},
		'text'		=>	$message,
		'textEnc'	=>	$message,
		'lang'		=>	'en',
		'yourName'	=>	$self->{_name},
		);

	#
	# Let's construct the useragent we'll use for our upcoming requests
	#
	$cookiejar = HTTP::Cookies->new;
	$useragent = LWP::UserAgent->new(
		'agent'			=>	"WWW::Fido/$VERSION",
		'cookie_jar'		=>	$cookiejar,
		'requests_redirectable'	=>	['GET', 'POST', 'HEAD'],
		);

	#
	# We need to get the cookies and login stuff by visiting the first page
	#
	$result = $useragent->get("http://www.fido.ca/portal/home/quickMsg.jsp?lang=en");
	$result = $result->as_string();
	if ($result !~ /You can send a message of up to/i) {
		$@ = "Did not receive initial entry page";
		return 0;
		}
	#
	# We submit to the first page:
	#
	$result = $useragent->post("http://www.fido.ca/portal/home/quickValidate.jsp", \%data);
	$result = $result->as_string();
	if ($result !~ /Please confirm the following/i) {
		$@ = "Did not receive the confirmation page";
		return 0;
		}
	#
	# Now we submit to the second page
	#
	$result = $useragent->post("http://www.fido.ca/portal/home/sendmessage.jsp", \%data2);
	$result = $result->as_string();
	if ($result !~ /has been accepted/) {
		$@ = "Did not receive final success page";
		return 0;
		}

	return 1;

	}
