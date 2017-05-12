package Mail::Exchange::Recipient;

=head1 NAME

Mail::Exchange::Recipient - class to handle message recipients

=head1 SYNOPSIS

    use Mail::Exchange::Recipient;

    my $recipient=Mail::Exchange::Recipient->new();
    $recipient->setEmailAddress('gbl@bso2001.com');
    $recipient->setDisplayName('Guntram Blohm <gbl@bso2001.com>');
    $message->addRecipient($recipient);

=head1 DESCRIPTION

A Mail::Exchange::Recipient object reflects the data that
Mail::Exchange::Recipient uses to add a recipient to a message. Since
a message has only one sender, but possibly multiple recipients,
the recipient data isn't stored in message properties (like sender data is),
instead, a message has zero or more recipient objects attached.

=cut

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;
use Mail::Exchange::PidTagDefs;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::ObjectTypes;
use Mail::Exchange::PropertyContainer;

use vars qw($VERSION @ISA);
@ISA=qw(Mail::Exchange::PropertyContainer Exporter);

$VERSION = "0.04";

=head2 new()

$msg=Mail::Exchange::Recipient->new()

Create a recipient object.

=cut

sub new {
	my $class=shift;

	my $self=Mail::Exchange::PropertyContainer->new();
	bless($self, $class);

	$self->set(PidTagRowid, 1);
	$self->set(PidTagRecipientType, 1);
	$self->set(PidTagDisplayType, 0);
	$self->set(PidTagObjectType, otMailUser);
	$self->set(PidTagAddressType, "SMTP");

	$self;
}

=head2 setRecipientType()

$recipient->setRecipientType(type)

Sets the type of recipient, which can be 1 for "To", 2 for "CC",
or 3 for "BCC". For convenience, the strings "to", "cc" and "bcc",
case-insensitive, are recognized as well.

=cut

sub setRecipientType {
	my $self=shift;
	my $field=shift;

	my $type=0;
	if (uc $field eq "TO")	{ $type=1; }
	if (uc $field eq "CC")	{ $type=2; }
	if (uc $field eq "BCC")	{ $type=3; }
	if ($field =~ /^[0-9]+$/) { $type=$field; }

	die "unknown Recipient Type $field" if ($type==0);

	$self->set(PidTagRecipientType, $type);
}

=head2 setAddressType()

$recipient->setRecipientType(type)

Sets the address type of the recipient, which is "SMTP" normally,
but may have different values as well depending on transmission type. For
example, the Microsoft Exchange server uses "EX".

=cut

sub setAddressType {
	my $self=shift;
	my $type=shift;

	$self->set(PidTagAddressType, $type);
}

=head2 setDisplayName()

$recipient->setDisplayName(name)

Sets the display name of the recipient. This may be something like
"Guntram Blohm <gbl@bso2001.com>" for SMTP recipients,
or just "Blohm, Guntram" for transport within an Exchange Domain.

=cut

sub setDisplayName {
	my $self=shift;
	my $name=shift;

	$self->set(PidTagDisplayName, $name);
	$self->set(PidTagTransmittableDisplayName, $name);
}

=head2 setSMTPAddress()

$recipient->setSMTPAddress(name)

Sets the SMTP Address of the recipient. This should be an SMTP
address, even if the address type is not SMTP.

=cut

sub setSMTPAddress {
	my $self=shift;
	my $recipient=shift;

	$self->set(PidTagSmtpAddress, $recipient);
}

=head2 setEmailAddress()

$recipient->setEmailAddress(name)

Sets the Email Address of the recipient. This can be an SMTP
address, if the address type is SMTP, or a differently formatted address,
if you're using a different Address Type. This sets the SMTP Address as
well, so if you're using this method for non-SMTP-Adresses, you should
call setSMTPAddress afterwards.

=cut

sub setEmailAddress {
	my $self=shift;
	my $recipient=shift;

	$self->set(PidTagSmtpAddress, $recipient);
	$self->set(PidTagEmailAddress, $recipient);
}

sub OleContainer {
	my $self=shift;
	my $no=shift;
	my $unicode=shift;

	my $header=pack("V2", 0, 0);

	$self->set(PidTagRowid, $no);

	my @streams=$self->_OlePropertyStreamlist($unicode, $header);
	my $dirname=Encode::encode("UCS2LE", sprintf("__recip_version1.0_#%08X", $no));
	my @ltime=localtime();
	my $dir=OLE::Storage_Lite::PPS::Dir->new($dirname, \@ltime, \@ltime, \@streams);
	return $dir;
}

sub _parseRecipientProperties {
	my $self=shift;
	my $file=shift;
	my $dir=shift;
	my $namedProperties=shift;

	$self->_parseProperties($file, $dir, 8, $namedProperties);
}

1;
