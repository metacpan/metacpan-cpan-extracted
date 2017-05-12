package MIME::Fast;

use strict;
use warnings;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

use 5.008; # require perl v5.8.0 or higher

our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
#

our @EXPORT = qw(
	GMIME_LENGTH_ENCODED
	GMIME_LENGTH_CUMULATIVE
	    
	GMIME_PART_ENCODING_DEFAULT
	GMIME_PART_ENCODING_7BIT
	GMIME_PART_ENCODING_8BIT
	GMIME_PART_ENCODING_BASE64
	GMIME_PART_ENCODING_QUOTEDPRINTABLE
	GMIME_PART_NUM_ENCODINGS

	GMIME_RECIPIENT_TYPE_TO
	GMIME_RECIPIENT_TYPE_CC
	GMIME_RECIPIENT_TYPE_BCC

	INTERNET_ADDRESS_NONE
	INTERNET_ADDRESS_NAME
	INTERNET_ADDRESS_GROUP
);
our $VERSION = '1.6';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0 || $! =~ /Invalid/) {
      $val = MIME::Fast::constant_string($constname, @_ ? $_[0] : 0);
    }
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined MIME::Fast macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap MIME::Fast $VERSION;

package main;

@MIME::Fast::DataWrapper::ISA     = qw(MIME::Fast::Object);
@MIME::Fast::Message::ISA         = qw(MIME::Fast::Object);
@MIME::Fast::MessagePart::ISA     = qw(MIME::Fast::Object);
@MIME::Fast::MultiPart::ISA       = qw(MIME::Fast::Object);
#@MIME::Fast::MultipartEncrypted::ISA = qw(MIME::Fast::Object);
#@MIME::Fast::MultipartSigned::ISA = qw(MIME::Fast::Object);
@MIME::Fast::Part::ISA            = qw(MIME::Fast::Object);
@MIME::Fast::MessagePartial::ISA  = qw(MIME::Fast::Part);
@MIME::Fast::MessageDelivery::ISA = qw(MIME::Fast::Part);
@MIME::Fast::MessageMDN::ISA      = qw(MIME::Fast::Part);
@MIME::Fast::Parser::ISA          = qw(MIME::Fast::Object);
@MIME::Fast::Stream::ISA 	  = qw(MIME::Fast::Object);
@MIME::Fast::StreamFilter::ISA 	  = qw(MIME::Fast::Stream);
@MIME::Fast::Filter::ISA 	  = qw(MIME::Fast::Object);
@MIME::Fast::Filter::Basic::ISA   = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Best::ISA    = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Charset::ISA = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Crlf::ISA    = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::From::ISA    = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Func::ISA    = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Html::ISA    = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Md5::ISA     = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Strip::ISA   = qw(MIME::Fast::Filter);
@MIME::Fast::Filter::Yenc::ISA    = qw(MIME::Fast::Filter);

package MIME::Fast::Message;

sub sendmail {
  my $msg = shift;
  
  require Mail::Mailer;
  my $mailer = new Mail::Mailer;
  my %headers;

  tie %headers, 'MIME::Fast::Hash::Header', $msg;

  # send headers
  $mailer->open(\%headers);

  my $msg_body = $msg->to_string;
  $msg_body = substr($msg_body, index($msg_body,"\n\n"));
  print $mailer $msg_body;

  $mailer->close();

  untie(%headers);
}

package MIME::Fast::Object;

sub is_multipart {
  my $self = shift;
  return $self->get_content_type->is_type("multipart","*");
}

sub effective_type {
  my $self = shift;
  my $type = $self->get_content_type;
  if (ref $type eq "MIME::Fast::ContentType") {
    $type = $type->to_string;
  }
  return lc($type);
}

package MIME::Fast::MultiPart;

sub get_mime_struct {
  my ($part, $maxdepth, $depth) = @_;
  my $ret = "";
  my $part2;
  
  $depth = 0 if not defined $depth;
  $maxdepth = 3 if not defined $maxdepth;
  return if ($depth > $maxdepth);
  my $space = "   " x $depth;
  #my $type = $part; # ->get_content_type();
  my $object_type = MIME::Fast::get_object_type($part);
  # warn "Type of $part is $object_type";
  if ($object_type eq 'MIME::Fast::MessagePart') {
    my $message = $part->get_message();
    $part2 = $part;
    $part = $message->get_mime_part();
    $ret .= $space . 'Message/rfc822 part' . "\n";
    $ret .= $space . "--\n";
    $depth++;
    $space = "   " x $depth;
  }
  my $type = $part->get_content_type();
  $ret .= $space . "Content-Type: " . $type->type . "/" . $type->subtype . "\n";
  if ($type->is_type("multipart","*")) {
  #if ($type->type =~ /^multipart/i) {
    my @children = $part->children;
    #print "Child = $children\n";
    $ret .= $space . "Num-parts: " . @children . "\n";
    $ret .= $space . "--\n";
    foreach (@children) {
      #print "$depth Part: $_\n";
      my $str = $_;
      $ret .= &get_mime_struct($str,$maxdepth - 1, $depth + 1);
    }
  } else {
    $ret .= $space . "--\n";
  }
  return $ret;
}

package MIME::Fast;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
