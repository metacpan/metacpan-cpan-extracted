package Mail::Exchange::Attachment;

=head1 NAME

Mail::Exchange::Attachment - class to handle attachments to messages

=head1 SYNOPSIS

    use Mail::Exchange::Attachment;

    my $attachment=Mail::Exchange::Attachment->new("file.dat");

=head1 DESCRIPTION

A Mail::Exchange::Attachment object reflects the data that
Mail::Exchange::Message uses to add an attachment to a message.

=cut

use strict;
use warnings;
use 5.008;

use Exporter;
use Encode;
use Mail::Exchange::ObjectTypes;
use Mail::Exchange::PidTagDefs;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PropertyContainer;
use Mail::Exchange::Time qw(mstime_to_unixtime);

use vars qw($VERSION @ISA);
@ISA=qw(Mail::Exchange::PropertyContainer Exporter);

$VERSION = "0.01";

=head2 new()

$msg=Mail::Exchange::Attachment->new([$file])

Create a message object, and read C<$file> into it, if given.

=cut

sub new {
	my $class=shift;
	my $file=shift;

	my $self=Mail::Exchange::PropertyContainer->new();
	bless($self, $class);
	my $now=Mail::Exchange::Time->new(time());
	$self->set(PidTagObjectType, otAttachment);
	$self->set(PidTagAttachMethod, 1, 7);
	$self->set(PidTagAccess, 2);
	$self->set(PidTagAccessLevel, 1);
	$self->set(PidTagRenderingPosition, 0xffffffff);
	$self->set(PidTagCreationTime,          $now->mstime());
	$self->set(PidTagLastModificationTime,  $now->mstime());

	if ($file) {
		$self->setFile($file);
	}
	$self;
}

=head2 setFile()

$attach->setFile($filename)

setFile reads the file identified by C<$filename>, makes it the content
object of the attachment, and sets various other attributes accordingly.

=cut

sub setFile {
	my $self=shift;
	my $file=shift;

	my $fh;
	die("$file: $!") unless open($fh, "<$file");
	binmode $fh;
	local $/;
	my $content=<$fh>;
	close $fh;

	$self->setString($content);
	$self->setFileInfo($file);
}

=head2 setFileInfo($filename)

$attach->setFileInfo($filename)

setFileInfo sets various properties of an attachment (filename, extension,
creation/modification time) to correspond to the local file identified
by C<$filename><.

=cut

sub setFileInfo {
	my $self=shift;
	my $file=shift;

	die("$file: $!") unless my @f=stat($file);
	$self->set(PidTagCreationTime,		mstime_to_unixtime($f[9]));
	$self->set(PidTagLastModificationTime,	mstime_to_unixtime($f[10]));
	$self->setFileName($file);
}

=head2 setFileName($filename)

$attach->setFileName($filename)

setFileName sets the various file-related properties of an attachment
(filename, extension, ...) to correspond with C<$filename>, without
requiring this file to exist.

=cut

sub setFileName {
	my $self=shift;
	my $file=shift;

	my $filename=$file;
	$filename=~s/.*\///;
	my $ext;
	if ($filename =~ /\./) {
		($ext=$filename)=~s/.*\././;
	} else {
		$ext="";
	}
	my $shortname;
	if (length($filename) - length($ext) > 8) {
		$shortname=substr($filename, 0, 6)."~1";
	} else {
		$shortname=substr($filename, 0, length($filename)-length($ext))
	}
	$shortname.=substr($ext, 0, 4);

	$self->set(PidTagAttachExtension,	$ext);
	$self->set(PidTagAttachFilename,	$shortname);
	$self->set(PidTagAttachLongFilename,	$filename);
	$self->set(PidTagAttachPathname,	$file);
	$self->set(PidTagDisplayName,		$filename);
}

=head2 setString()

$attach->setString($content)

setString sets the content of the attachment to C<$string>.

=cut

sub setString {
	my $self=shift;
	my $string=shift;

	$self->set(PidTagAttachDataBinary, $string);
}

sub OleContainer {
	my $self=shift;
	my $no=shift;
	my $unicode=shift;

	my $header=pack("V2", 0, 0);

	$self->set(PidTagAttachNumber, $no);
	$self->set(PidTagStoreSupportMask, $unicode ? 0x40000 : 0);

	my @streams=$self->_OlePropertyStreamlist($unicode, $header);
	my $dirname=Encode::encode("UCS2LE", sprintf("__attach_version1.0_#%08X", $no));
	my @ltime=localtime();
	my $dir=OLE::Storage_Lite::PPS::Dir->new($dirname, \@ltime, \@ltime, \@streams);
	return $dir;
}

sub _parseAttachmentProperties {
	my $self=shift;
	my $file=shift;
	my $dir=shift;
	my $namedProperties=shift;

	$self->_parseProperties($file, $dir, 8, $namedProperties);
}

1;
