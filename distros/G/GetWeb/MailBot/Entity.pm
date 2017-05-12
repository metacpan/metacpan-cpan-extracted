package MailBot::Entity;

use MailBot::Sendable;
use MailBot::UI;
use MIME::Decoder;
use MailBot::UUEncode;

#install MailBot::UUEncode 'x-uuencode';
# broken MIMETools-2.04 'install' makes this workaround necessary:
$MIME::Decoder::DecoderFor{'x-uuencode'} = MailBot::UUEncode;

# jfj create 'profile' for healthnet users who probably have no MIME

@ISA = qw( MailBot::Sendable );

use Carp;
use strict;

my $gEnvelope;

# j implement "fake quota" copies

sub setEnvelope
{
    $gEnvelope = shift;
}

sub send
{
    my $self = shift;
    my $paResource = shift || [];

    my $config = MailBot::Config::current;
    my $ui = &MailBot::UI::current;

    defined $gEnvelope or croak "no envelope";
    my $quotaMultiplier = $gEnvelope -> getQuotaMultiplier;
    my $from = $gEnvelope -> getFrom;
    defined $from and
	$self -> head -> replace('From',$from);

    my $resource;
    foreach $resource (@$paResource)
    {
	my $resourceMultiplier =
	    $config -> getIniVal("quota",$resource,1);
	$quotaMultiplier *= $resourceMultiplier;
    }

    # jf only chop, not die, if message too long

    my $length = $self -> get_length;
    $config ->
	log("send $length bytes to ", $gEnvelope -> getRecip -> asString());

    my $lastByte = $gEnvelope -> getLastByte;
    $length > $lastByte and
	die "UNAVAILABLE: message of length $length too long,\nmaximum length is $lastByte\n";

    my $quota = $ui -> getQuota;

    $quota -> bill(1 * $quotaMultiplier,"message");
    $quota -> bill($length * $quotaMultiplier,"byte");
    my $splitMultiplier = $config -> getSplitMultiplier;

    my $splitSize = $gEnvelope -> getSplitSize;
    if ($splitSize < 500 or $splitSize > 200000)
    {
	die "split size of $splitSize is illegal, must be between 500 and 200000 bytes\n";
    }

    my $maxChunk = $splitSize * $splitMultiplier;

    my $paSplit = $self -> split_into_array($splitSize,$maxChunk);

    my $msg;
    foreach $msg (@$paSplit)
    {
	$ui -> sendMessage($msg);
    }
}

# jfj smarter about when to use 7-bit and when to use q-p encoding

sub build
{
    my $type = shift;
    my %opt = @_;

    my $top = exists($opt{Top}) ? $opt{Top} : 1;
    my $contentEncoding = $opt{Encoding};
    
    my $self = $type -> SUPER::build(@_);
    my $header = $self -> head;

    my $contentType = $header -> mime_type;
    my $newEncoding;

    if (! defined $contentEncoding and
	$contentType !~ m|^multipart/| and
	$contentType !~ m|^message/|)
    {
	my $mime = $$gEnvelope{MIME};
	if (defined $contentType and $contentType !~ m!^text/!)
	{
	    if ($mime)
	    {
		$newEncoding = "base64";
	    }
	    else
	    {
		$newEncoding = "x-uuencode";
	    }
	}
# 	elsif ($mime)
# 	{
# 	    my $body = $self -> bodyhandle;
# 	    my $IO = $body -> open("r");

# 	    my $quote = 0;
# 	    my $line;
# 	    while (defined($line = $IO->getline)) {
# 		$quote++ if length($line) > 120;  #arbitrary length cap
# 		$quote++ if $line =~ /[\200-\377]/;
# 	    }
# 	    $IO->close;

# 	    $newEncoding = "quoted-printable" if $quote;
# 	}
	# default is 7bit
    }

    $header -> replace('Content-Transfer-Encoding',$newEncoding)
        if (defined $newEncoding);

    my $lastByte = $gEnvelope -> getLastByte;

    my $length = $self -> get_length;

    $length <= $lastByte or
	die "UNAVAILABLE: message longer than $lastByte bytes\n";

    return $self unless $top;

    my $recip = $gEnvelope -> getRecip;

    if (defined $recip)
    {
	$self -> head -> add('to',$recip -> to);
	$self -> head -> add('cc',$recip -> cc)
	    if $recip -> cc ne "";
    }

    $self -> head -> add('subject',$gEnvelope -> getSubject);

    if ($top)
    {
	my $ui = &MailBot::UI::current;
	my $paNote = $ui -> getNoteRef;

	$self -> head -> add('X-MailBot-Note',join(', ',@$paNote))
	    if @$paNote;
	@$paNote = ();
    }

    $self;
}

1;
