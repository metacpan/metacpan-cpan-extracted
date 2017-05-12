package Mail::Exchange::Message;

=head1 NAME

Mail::Exchange::Message - class to deal with .msg files, used by Microsoft
Exchange / MS Outlook.

=head1 SYNOPSIS

    use Mail::Exchange::Message;
    use Mail::Exchange::Message::MessageFlags;
    use Mail::Exchange::Recipient;
    use Mail::Exchange::Attachment;
    use Mail::Exchange::PidTagIDs;

    # modify an existing .msg file

    my $msg=Mail::Exchange::Message->new("my.msg");
    print "old Subject: ", $msg->get(PidTagSubject), "\n";
    $msg->setSubject('new subject');
    $msg->save("changed.msg");

    # create a .msg file from scratch, and send it to
    # the browser from a CGI script

    my $msg=Mail::Exchange::Message->new();
    $msg->setUnicode(1);
    $msg->setSubject('message subject');
    $msg->setBody('message body');
    $msg->set(PidTagMessageFlags, mfUnsent);
    $message->setDisplayTo('test@somewhere.com');

    my $recipient=Mail::Exchange::Recipient->new();
    $recipient->setEmailAddress('test@somewhere.com');
    $recipient->setDisplayName('John Tester');
    $recipient->setRecipientType('To');
    $message->addRecipient($recipient);

    my $attachment=Mail::Exchange::Message->new("attach.dat");
    $message->addAttachment($attachment);

    binmode(STDOUT);
    print STDOUT qq(Content-type: application/vnd.ms-outlook
    Content-Disposition: attachment; filename="newmessage.msg"

    );

    $message->save(\*STDOUT);

=head1 DESCRIPTION

Mail::Exchange::Message allows you to read and write binary message files that
Microsoft Outlook uses to store emails, to-dos, appointments and so on. It does
not need Windows, or Outlook, installed, and should be able to run on any
operating system that supports perl.

It might have been named "Outlook" instead of "Exchange", but the 
"Mail::Outlook" and "Email::Outlook" namespaces had both been taken at the
time of its implementation, and it contains some sub-modules that might be
helpful to implementations of more functionality with Microsoft Exchange,
with which it is intended to coexist.

=cut


use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;
use Mail::Exchange::Time;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidTagDefs;
use Mail::Exchange::PropertyContainer;
use Mail::Exchange::NamedProperties;
use Mail::Exchange::Recipient;
use Mail::Exchange::Attachment;
use Mail::Exchange::Message::MessageFlags;
use OLE::Storage_Lite;

use vars qw($VERSION @ISA);
@ISA=qw(Mail::Exchange::PropertyContainer Exporter);

$VERSION = "0.04";

=head2 new()

$msg=Mail::Exchange::Message->new([$file])

Read a message from the .msg file C<$file>, or create a new, empty one,
if C<$file> isn't given.

=cut

sub new {
	my $class=shift;
	my $file=shift;

	my $self=Mail::Exchange::PropertyContainer->new();
	bless($self, $class);

	$self->{_recipients}=();
	$self->{_attachments}=();
	$self->{_namedProperties}=Mail::Exchange::NamedProperties->new();
	
	if ($file) {
		$self->parse($file);
	} else {
		# these are taken from [MS-OXCMSG] 3.2.5.2
		# PidTagMessageClass is NOT initialized, there are
		# subclasses for that.
		my $now=Mail::Exchange::Time->new(time());
		$self->set(PidTagImportance,		1);
		$self->set(PidTagSensitivity,		0);
		$self->set(PidTagDisplayBcc,		"");
		$self->set(PidTagDisplayCc,		"");
		$self->set(PidTagDisplayTo,		"");
		$self->set(PidTagMessageFlags,		9);
		$self->set(PidTagMessageSize,		1);
		$self->set(PidTagHasAttachments,	0);
		$self->set(PidTagTrustSender,		1);
		$self->set(PidTagAccess,		3);
		$self->set(PidTagAccessLevel,		3);
		$self->set(PidTagUrlCompName,		"No Subject.EML");
		$self->set(PidTagCreationTime,		$now->mstime());
		$self->set(PidTagLastModificationTime,	$now->mstime());
	}

	$self;
}

=head2 parse()

$msg->parse($file)

Read a message file into an internal structure. Called from new() if a
filename argument is given. C<$file> is expected to be a string, but may
be anything that is accepted by OLE::Storage_Lite.

=cut

sub parse {
	my $self=shift;
	my $file=shift;
	my $OLEFile = OLE::Storage_Lite->new($file);
	my $root=$OLEFile->getPpsTree(1);
	die "$file does not seem to be an OLE File" unless $root;

	my $nameid=Encode::encode("UCS2LE", "__nameid_version1.0");
	foreach my $entry (@{$root->{Child}}) {
		if ($entry->{Name} eq $nameid) {
			$self->_parsePropertyNames($entry);
		}
	}

	my $propid=Encode::encode("UCS2LE", "__properties_version1.0");
	foreach my $entry (@{$root->{Child}}) {
		if ($entry->{Name} eq $propid) {
			$self->_parseMessageProperties($entry, $root);
		}
	}

	foreach my $entry (@{$root->{Child}}) {
		# print Encode::decode("UCS2LE", $entry->{Name}), "\n";
		if (Encode::decode("UCS2LE", $entry->{Name})
				=~ /__recip_version1.0_#([0-9A-F]{8})/) {
			my $idx=hex($1);
			foreach my $subentry (@{$entry->{Child}}) {
				if ($subentry->{Name} eq $propid) {
					$self->{_recipients}[$idx]=Mail::Exchange::Recipient->new();
					$self->{_recipients}[$idx]->_parseRecipientProperties(
						$subentry, $entry, $self->{_namedProperties});
				}
			}
		}

		if (Encode::decode("UCS2LE", $entry->{Name})
				=~ /__attach_version1.0_#([0-9A-F]{8})/) {
			my $idx=hex($1);
			foreach my $subentry (@{$entry->{Child}}) {
				if ($subentry->{Name} eq $propid) {
					$self->{_attachments}[$idx]=Mail::Exchange::Attachment->new();
					$self->{_attachments}[$idx]->_parseAttachmentProperties(
						$subentry, $entry, $self->{_namedProperties});
				}
			}
		}
	}
}

sub _parsePropertyNames {
	my $self=shift;
	my $dir=shift;

	my $stringstreamdata;
	my $guidstreamdata;
	my $ssid=Encode::encode("UCS2LE", "__substg1.0_00040102");
	my $gsid=Encode::encode("UCS2LE", "__substg1.0_00020102");
	foreach my $item (@{$dir->{Child}}) {
		if ($item->{Name} eq $ssid) {
			$stringstreamdata=$item->{Data};
		}
		if ($item->{Name} eq $gsid) {
			$guidstreamdata=$item->{Data};
		}
	}

	my $psid=Encode::encode("UCS2LE", "__substg1.0_00030102");
	foreach my $item (@{$dir->{Child}}) {
		if ($item->{Name} eq $psid) {
			my $data=$item->{Data};
			while ($data ne "") {
				my ($niso, $iko)=unpack("VV", $data);
				my $pi=($iko>>16)&0xffff;
				my $gi=($iko>>1)&0x7fff;
				my $pk=$iko&1;
				my $guid;
				my $name;
				if ($gi==1) { $guid="PS_MAPI"; }
				if ($gi==2) { $guid="PS_PUBLIC_STRINGS"; }
				if ($gi>2)  { $guid=GUIDDecode(substr($guidstreamdata, 16*($gi-3), 16)); }

				# We don't know the type here, so we just
				# add the property with undef type. The type
				# will be set later when we actually read
				# the value from the properties stream.
				if ($pk==0) {
					$self->{_namedProperties}->namedPropertyIndex(
						$niso, undef, $guid);
				} else {
					my $len=unpack("V", substr($stringstreamdata, $niso, 4));
					$name=Encode::decode("UCS2LE", substr($stringstreamdata, $niso+4, $len));
					$self->{_namedProperties}->namedPropertyIndex($name, undef, $guid);
					# @@@ die if returncode != $pi ??
				}
				$data=substr($data, 8);
			}
		}
	}
}

sub _parseMessageProperties {
	my $self=shift;
	my $file=shift;
	my $dir=shift;

	$self->_parseProperties($file, $dir, 32, $self->{_namedProperties});
}

=head2 set()

$msg->set($tag, $value, [$flags,] [$type,] [$guid])

Set a property within a message. C<$tag> can be any numeric property defined in
Mail::Exchange::PidTagIDs.pm, a numeric named property defined in
Mail::Exchange::PidLidIDs.pm, or a string property. C<$value> is the value
the property is set to. 

C<$flags> is a bit-wise or of 1 (this property is mandatory and must not be
deleted), 2 (property is writable) and 4 (property is readable and may be
displayed to the user). Default is 6.

When a string named property is defined for the first time, its C<$type>
and C<$guid> must be given as well, as stated [MS-OXPROPS], section 1.3.2

=cut

sub set {
	my ($self, $tag, $value, $flags, $type, $guid) = @_;
	Mail::Exchange::PropertyContainer::set($self, $tag, $value,
		$flags, $type, $guid, $self->{_namedProperties});
}

sub get {
	my ($self, $tag) = @_;
	return Mail::Exchange::PropertyContainer::get($self, $tag,
		$self->{_namedProperties});
}

=head2 setSender()

$msg->setSender($address)

setSender is a shortcut for setting various properties that
descripe the sender of a message.

=cut

sub setSender {
	my $self=shift;
	my $sender=shift;

	$self->set(PidTagSentRepresentingAddressType, "SMTP");
	$self->set(PidTagSentRepresentingName, $sender);
	$self->set(PidTagSentRepresentingEmailAddress, $sender);

	$self->set(PidTagSenderAddressType, "SMTP");
	$self->set(PidTagSenderName, $sender);
	$self->set(PidTagSenderEmailAddress, $sender);
	$self->set(PidTagSenderSmtpAddress, $sender);
	# $self->set(0x5D02, $sender);
}

=head2 setDisplayTo()

$msg->setDisplayTo($text)

setDisplayTo sets the recipient list that is shown by outlook in the
"To:" address line.

=cut

sub setDisplayTo {
	my $self=shift;
	my $recipient=shift;

	$self->set(PidTagDisplayTo, $recipient);
}

=head2 setDisplayCc()

$msg->setDisplayCc($text)

setDisplayCc sets the recipient list that is shown by outlook in the
"Cc:" address line.

=cut

sub setDisplayCc {
	my $self=shift;
	my $recipient=shift;

	$self->set(PidTagDisplayCc, $recipient);
}

=head2 setDisplayBcc()

$msg->setDisplayBcc($text)

setDisplayBcc sets the recipient list that is shown by outlook in the
"Bcc:" address line.

=cut

sub setDisplayBcc {
	my $self=shift;
	my $recipient=shift;

	$self->set(PidTagDisplayBcc, $recipient);
}

=head2 setSubject()

$msg->setSubject($text)

setSubject sets the subject of the message by setting various internal
properties.

=cut

sub setSubject {
	my $self=shift;
	my $subject=shift;

	$self->set(PidTagSubject, $subject);
	$self->set(PidTagSubjectPrefix, "");
	$self->set(PidTagConversationTopic, $subject);
	$self->set(PidTagNormalizedSubject, $subject);
}

=head2 setBody()

$msg->setBody($text)

setBody sets the plain text body of the message.

=cut

sub setBody {
	my $self=shift;
	my $body=shift;

	$self->set(PidTagBody, $body);
}

=head2 setHTMLBody()

$msg->setHTMLBody($text)

setHTMLBody sets the html body of the message.

=cut

sub setHTMLBody {
	my $self=shift;
	my $body=shift;

	$self->set(PidTagHtml, $body);
}

=head2 setRtfBody()

setRtfBody($text[, $compress])

setRtfBody sets the rich text format body of the message.

The message file format allows for compressed or uncompressed
rtf storage. If C<$compress> is set, C<$text> will be compressed before being
stored. (As of now, C<$compress> is not implemented, and C<$text> will always
be stored in uncompressed form).

=cut

sub setRtfBody {
	my $self=shift;
	my $body=shift;

	# OXRTFCP says CRC MUST be 0 when uncompressed.

	my $header=pack("VVVV", length($body)+12, length($body), 0x414c454D, 0);
	$self->set(PidTagRtfCompressed, $header.$body);
	$self->set(PidTagRtfInSync, 1);
}

=head2 getRtfBody()

$msg->getRtfBody()

getRtfBody gets the RTF Body of a message, uncompressing it if neccesary.

=cut

sub getRtfBody {
	my $self=shift;
	my $rtf=$self->get(PidTagRtfCompressed);
	my ($compsize, $rawsize, $comptype, $crc)=unpack("VVVV", $rtf);
	$rtf=substr($rtf, 16);

	if ($comptype == 0x414c454D) {
		return $rtf;
	} elsif ($comptype != 0x75465a4c) {
		die(sprintf("rtf compression type %08x unknown", $comptype));
	}

	my $dictionary='{\rtf1\ansi\mac\deff0\deftab720{\fonttbl;}'.
			'{\f0\fnil \froman \fswiss \fmodern '.
			'\fscript \fdecor MS Sans SerifSymbolArialTimes'.
			' New RomanCourier{\colortbl\red0\green0\blue0'.
			"\r\n".'\par \pard\plain\f0\fs20\b\i\u\tab\tx';

	my $dpos=207;
	my $rpos=0;
	my $rlen=length $rtf;
	my $output='';
RTFTEXT:
	while ($rpos<$rlen) {
		my $control=unpack("C", substr($rtf, $rpos++, 1));
		for (my $i=0; $i<8 && $rpos<$rlen; $i++) {
			my $newbyte;
			my $ofs;
			my $len;
			if ($control & (1<<$i)) {
				my $ref=unpack("n", substr($rtf, $rpos));
				$rpos+=2;
				$ofs=$ref>>4;
				$len=($ref&0x0f)+2;
				if ($ofs==($dpos%4096)) {
					last RTFTEXT;
				}
				for (my $j=0; $j<$len; $j++) {
					$newbyte=substr($dictionary, ($ofs++%4096), 1);
					substr($dictionary, ($dpos++%4096), 1)=$newbyte;
					$output.=$newbyte;

				}
			} else {
				$newbyte=substr($rtf, $rpos++, 1);
				$output.=$newbyte;
				substr($dictionary, ($dpos++%4096), 1)=$newbyte;
			}
		}
	}
	return $output;
}

=head2 setHtmlBody()

$msg->setHtmlBody($htmltext)

setHtmlBody sets the html version of the message body. It is a shortcut
for C<$msg->set(PidTagHtml, $htmltext)>.

=cut

sub setHtmlBody {
	my $self=shift;
	my $body=shift;

	$self->set(PidTagHtml, $body);
}

=head2 setUnicode()

$msg->setUnicode($flag)

If C<$flag> is 0, all strings within the message will be stored one byte per
character. If C<$flag> is 1, strings will be stored in what's called unicode
in the documentation (actually, UCS2LE encoded strings, using 2 bytes per
character).

=cut

sub setUnicode {
	my $self=shift;
	my $flag=shift;
	my $mask=$self->get(PidTagStoreSupportMask);
	if ($flag) {
		$mask |= 0x40000;
	} else {
		$mask &= ~0x40000;
	}
	$self->set(PidTagStoreSupportMask, $mask);
}

=head2 save()

save($msgfile)

Saves a message object to a file. $msgfile may be a file, or anything else
that OLE::Storage_Lite accepts.

=cut

sub save {
	my $self=shift;
	my $output=shift;

	my @streams=();
	push(@streams, $self->{_namedProperties}->OleContainer());

	my $unicode=$self->get(PidTagStoreSupportMask)&0x40000;
	my $header=pack("V8",
		0, 0,
		$#{$self->{_recipients}}+1,
		$#{$self->{_attachments}}+1,
		$#{$self->{_recipients}}+1,
		$#{$self->{_attachments}}+1,
		0, 0);


	push(@streams, $self->_OlePropertyStreamlist($unicode, $header));

	foreach my $i (0..$#{$self->{_recipients}}) {
		push(@streams, $self->{_recipients}[$i]->OleContainer($i, $unicode));
	}

	foreach my $i (0..$#{$self->{_attachments}}) {
		push(@streams, $self->{_attachments}[$i]->OleContainer($i, $unicode));
	}

	my @ltime=localtime();
	my $root=OLE::Storage_Lite::PPS::Root->new(\@ltime, \@ltime, \@streams);
	$root->save($output);
}

=head2 addAttachment()

addAttachment($object)

Adds a Mail::Exchange::Attachment object to a message.

=cut

sub addAttachment($$) {
	my $self=shift;
	my $attachment=shift;

	push(@{$self->{_attachments}}, $attachment);
	$self->set(PidTagHasAttachments, 1);
	my $flags=$self->get(PidTagMessageFlags) || 0;
	$self->set(PidTagMessageFlags, $flags | mfHasAttach);
}

=head2 addRecipient()

addRecipient($object)

Adds a Mail::Exchange::Recipient object to a message.

=cut

sub addRecipient($$) {
	my $self=shift;
	my $recipient=shift;

	push(@{$self->{_recipients}}, $recipient);
}

__END__

=head1 WARNING

This Module is quite alpha. It reads most msg files ok, and writing some .msg
files works, but there are several features that aren't implemented yet, 
and using generated .msg files may have any adverse effects on Outlook,
including program crashes.

=head1 COPYRIGHT

The Mail::Exchange modules are Copyright (c) 2012 Guntram Blohm.
All rights reserverd.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

The Name definitions in Mail::Message::PidTagIDs.pm,
Mail::Message::PidTagDefs.pm, Mail::Message::PidLidIDs.pm and
Mail::Message::PropertyTypes.pm are taken from [MS-OXPROPS], which states

Copyrights. This documentation is covered by Microsoft
copyrights. Regardless of any other terms that are contained in the terms
of use for the Microsoft website that hosts this documentation, you may
make copies of it in order to develop implementations of the technologies
described in the Open Specifications and may distribute portions of it
in your implementations using these technologies or your documentation as
necessary to properly document the implementation. You may also distribute
in your implementation, with or without modification, any schema,
IDL’s, or code samples that are included in the documentation. This
permission also applies to any documents that are referenced in the
Open Specifications.

The compression/decompression algorithm for RTF content is described in
[MS-OXRTFCP], which has the same copyright statement.

=head1 AUTHOR

Guntram Blohm gbl@bso2001.com

=head1 REFERENCES

[MS-OXPROPS] Exchange Server Protocols Master Property List, 
http://msdn.microsoft.com/en-us/library/cc433490(v=exchg.80).aspx
on Sep 30, 2012

[MS-OXRTFCP] Rich Text Format (RTF) Compression Algorithm
http://msdn.microsoft.com/en-us/library/cc463890(v=exchg.80).aspx
on Sep 30, 2012

[MS-OXMSG]: Outlook Item (.msg) File Format
http://msdn.microsoft.com/en-us/library/cc463912(v=exchg.80).aspx
on Sep 30, 2012
