package MailBot::Sendable;

use Net::Domain qw( hostfqdn hostname );
use Mail::Util qw(mailaddress);
use MIME::IO;
use MIME::Entity;
use Carp;

@ISA = qw( MIME::Entity );

$gPreamble = "This is a multi-part message in MIME format.";
my $pgPreamble = \$gPreamble;
$gBase64Preamble = "A binary file was encoded in Base64.\n You need a MIME-capable mailer to read it.";
my $pgBase64Preamble = \$gBase64Preamble;

use strict;

my @MOVE_OUTSIDE = qw( To Cc Bcc );

# smtpsend:  adapted from Barr's Mail::Internet::smtpsend.

# changes:
#  works correctly with file-attaches
#  does not delete 'Received' lines (or even misspelled 'Recieved' lines)
#  does not insert 'Sender', 'Mailer' fields
#  allows you to specify envelope from-field

 sub smtpsend 
{
 my $src  = shift;
 my $envelopeFrom = shift;
 my($mail,$smtp,@hosts);

 $envelopeFrom = mailaddress()
     unless defined $envelopeFrom;

 require Net::SMTP;

 @hosts = qw(mailhost localhost);
 unshift(@hosts, split(/:/, $ENV{SMTPHOSTS})) if(defined $ENV{SMTPHOSTS});

 my $host;
 foreach $host (@hosts) {
  $smtp = eval { Net::SMTP->new($host) };
  last if(defined $smtp);
 }

 croak "Cannot initiate a SMTP connection" unless(defined $smtp);

 $smtp->hello( hostname() );
 # only dups the headers, alas
 $mail = $src->dup;

 $mail->delete('From '); # Just in case :-)

 # Ensure the mail has the following headers
 # From, Reply-To

 my($from,$name,$tag);

 $name = (getpwuid($>))[6] || $ENV{NAME} || "";
 while($name =~ s/\([^\(]*\)//) { 1; }

 $from = sprintf "%s <%s>", $name, mailaddress();
 $from =~ s/\s{2,}/ /g;

 foreach $tag (qw(From Reply-To))
  {
   $mail->add($tag,$from) unless($mail->get($tag));
  }

 # Who is it to

 my @rcpt = ($mail->get('To', 'Cc', 'Bcc'));
 chomp(@rcpt);
 my @addr = map($_->address, Mail::Address->parse(@rcpt));

 return () unless(@addr);

 $mail->delete('Bcc'); # Remove blind Cc's
 $mail->clean_header;

 # Send it

 my @fullBody = $src -> body_to_array;

 my $ok = $smtp->mail( $envelopeFrom ) &&
            $smtp->to(@addr) &&
            $smtp->data(join("", $mail -> head_to_array, "\n", @fullBody));

 $smtp->quit;

 $ok ? @addr : ();
}

sub split_into_array
{
    my $entity = shift;
    my ($chunkSize, $maxSize) = @_;

    defined $maxSize or
	$maxSize = $chunkSize;

    my $length = &get_length($entity);
    return [$entity] if $length <= $maxSize;

    my $id = ".$$." . time . '@' . hostfqdn;
    # pad id to 40 characters for more consistency
    while (length($id) < 40)
    {
	$id = "a" . $id;
    }
    
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

	if (@aReference)
	{
	    # limit to four references, like mpack does
	    @aReference > 4 and shift @aReference;
	    $newHead -> replace('References',join(' ',@aReference));
	}
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

# get: bug-fix to Mail::Internet::get

sub get
{
 my $me = shift;
 my $head = $me->head;
 my @val = ();
 my $tag;

 foreach $tag (@_)
  {
   last
	if push(@val, $head->get($tag)) && !wantarray;
  }

 wantarray ? @val : shift @val;
}

sub head_to_array
{
    my $self = shift;
    my $head = $self -> head;
    $head -> delete('X-Mailer');
    @{$head->{'mail_hdr_list'}};
}

sub print
{
    my $self = shift;
    my $fh = shift || select;
    no strict 'refs';

    $self -> head -> delete('X-Mailer');
    
    my @array = $self -> entity_to_array;
    print $fh @array;
}

sub entity_to_array
{
    my $self = shift;
    my @text = ();

    push(@text,$self -> head_to_array);
    push(@text,"\n");
    push(@text,$self -> body_to_array);

    @text;
}

sub body_to_array
{
    my $entity = shift;
    my @body = ();

#    # Output the head and its terminating blank line:
#    push(@body,$entity->head_to_array);
#    push(@body,"\n");

    # Output either the body or the parts:
    if ($entity->is_multipart) {    # Multipart...
        my $boundary = $entity->head->multipart_boundary;     # get boundary

        my $part;

	my $isBase64 = 0;
	foreach $part ($entity->parts)
	{
	    my $encoding = $part -> head -> mime_encoding;
	    if ($encoding eq "base64")
	    {
		$isBase64 = 1;
		last;
	    }
	}
	
	if ($isBase64)
	{
	    push(@body,$$pgBase64Preamble . "\n");
	}
	else
	{
	    push(@body,$$pgPreamble . "\n");
	}

        # Parts:
        foreach $part ($entity->parts) {
            push(@body,"\n--$boundary\n");
            push(@body,&entity_to_array($part));
	}
	push(@body,"\n--$boundary--\n\n");
    }
    else {                        # Single part...

	# Get the encoding:
	my $encoding = ($entity->head->mime_encoding || 'binary');

	my $decoder = new MIME::Decoder ($encoding);
	#$encoding =~ /bit$/i and
	#    $decoder -> encode_8bit_by("ENTITY");
	
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

    # jfj eliminate redundancy with MIME print classes

    @body;
}

1;
