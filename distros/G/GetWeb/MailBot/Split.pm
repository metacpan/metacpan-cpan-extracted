package MailBot::Split;

# jfj delete Split class

use Net::Domain qw( hostfqdn );
use MIME::IO;
use strict;

my @MOVE_OUTSIDE = qw( To Cc Bcc );

sub split_into_array
{
    my $entity = shift;
    my ($chunkSize, $maxSize) = @_;

    defined $maxSize or
	$maxSize = $chunkSize;

    my $length = &get_length($entity);
    return [$entity] if $length <= $maxSize;

    my $id = "$$." . time . '@' . hostfqdn;
    
    $entity -> head -> add("Message-Id",'<'.$id.'>');
    my @body = &entity_to_array($entity);

    my @apaPartial = ();
    while (@body)
    {
	my @aPartial = ();
	my $left = $chunkSize;
	while (@body)
	{
	    my $line = $body[0];
	    $left -= length($line);
	    last if $left < 0;
	    push(@aPartial,shift @body);
	}
	@aPartial or die "line " . $body[0] . " is bigger than chunk";
	push(@aPartial,"\n");
	push(@apaPartial,\@aPartial);
    }

    my $head = $entity -> head;

    my $total = @apaPartial;
    my $number = 0;

    my @aReference;
    my @aEntity;
    my $paPartial;
    foreach $paPartial (@apaPartial)
    {
	$number++;

	my $newEntity =
	    ref($entity) -> build(Data => $paPartial,
				  Type => "message/partial; number=$number; ".
				  "total=$total; id=\"$id\"");
	my $newHead = $newEntity -> head;

	my $keyword;
	foreach $keyword (@MOVE_OUTSIDE)
	{
	    my $val = $head -> get($keyword);
	    defined $val and
		$newHead -> replace($keyword,$val);
	}
	my $subject = $head -> get('Subject');
	$newHead -> replace('Subject',"$subject ($number/$total)");

	my $partID =  "<$number.$id>";
	$newHead -> replace('Message-ID',$partID);

	@aReference and
	    $newHead -> replace('References',join(' ',@aReference));
	push(@aReference,$partID);

	push(@aEntity,$newEntity);
    }
    [@aEntity];
}

sub get_length
{
    my $entity = shift;

    my @aEntity = &entity_to_array($entity);

    my $length = 0;
    my $line;
    foreach $line (@aEntity)
    {
	$length += length($line);
    }
    $length;
}

sub head_to_array
{
    my $head = shift;
    @{$head->{'mail_hdr_list'}};
}

sub entity_to_array
{
    my $entity = shift;

    my @body = ();

    # Output the head and its terminating blank line:
    push(@body,&head_to_array($entity->head));
    push(@body,"\n");

    # Output either the body or the parts:
    if ($entity->is_multipart) {    # Multipart...
        my $boundary = $entity->head->multipart_boundary;     # get boundary

        # Preamble:
        push(@body,"This is a multi-part message in MIME format.\n");

        # Parts:
        my $part;
        foreach $part ($entity->parts) {
            push(@body,"\n--$boundary\n");
            push(@body,&entity_to_array($part));
	}
	push(@body,"\n--$boundary--\n\n");
    }
    else {                        # Single part...

	# Get the encoding:
	my $encoding = ($entity->head->mime_encoding || 'binary');
	my $decoder = new MIME::Decoder $encoding;
	
	# Output the body:
	my $body = $entity->bodyhandle;
	my $IO = $body->open("r") || die "open body: $!";
	
	my $encoded;
	my $encodeIO = new MIME::IO::Scalar \$encoded;

	$decoder->encode($IO, $encodeIO);      # encode it
	$IO->close;
	$encodeIO -> close;

	push(@body,split(/^/m,$encoded));
    }

    @body;
}

0;
