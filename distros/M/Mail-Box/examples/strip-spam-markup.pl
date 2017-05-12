#!/usr/bin/perl
#
# Usage:
#
#   strip-spam-markup.pl mbox
#
# This script reads a mailbox and strips header fields that may have
# been added by various SPAM and mail filtering programs.  If the SPAM
# filter program attached the original message as an RFC822 message part,
# the original message will be used, and any other message parts introduced
# by the SPAM filter program will be ignored.
#
# Author: Gary Funck <gary@intrepid.com>, 2010-08-22
# This code can be used and modified without restriction.
#
use strict;
use warnings;
use File::Remove 'remove';
use Mail::Box::Manager;
use Mail::Message::Head::SpamGroup;
use aliased 'Mail::Box::Manager' => 'MBM';
use aliased 'Mail::Message::Head::SpamGroup' => 'MMHS';

my $SA;
# If SpamAssassin is installed, we will use
# its remove_spamassassin_markup function.
if (eval 'require Mail::SpamAssassin;') {
  $SA = new Mail::SpamAssassin;
}

# The following sub's perform rewrites, and are
# called from $m->rebuild, below.
# See: Mail::Message::Construct::Rebuild

sub use_orig_msg_part ($$)
{
  my ($self, $part) = @_;
  for my $p ($part->head->isMultipart
               ? $part->body->parts : ($part)) {
    next unless $p->body->isNested;
    my $content_type = $p->contentType;
    my $content_description = $p->get('Content-Description');
    if (defined($content_type) && defined($content_description)
	&& $content_type eq 'message/rfc822'
	&& $content_description =~ /^original message/i) {
      # Use the nested original message body.
      $part->body($p->body->nested->body);
      last;
    }
  }
  return $part;
}

sub remove_dspam_sig_part ($$)
{
  my ($self, $part) = @_;
  my $container = $part->container;
  my $content_type = $part->contentType;
  if (defined($container) && $container->isMultipart
      && defined($content_type) && $content_type eq 'text/plain') {
    my $x_dspam_sig = $part->head->get('X-DSPAM-Signature');
    # delete this part if it has a DSPAM signature header.
    return undef if defined $x_dspam_sig;
  }
  return $part;
}

sub remove_dspam_sig_text ($$)
{
  my ($self, $part) = @_;
  if ($part->body->isText
      && !($part->isMultipart || $part->body->isNested)) {
    # See: Mail::Message::Body::Construct
    $part->body($part->body->foreachLine(
       sub {my $line = $_;
	    $line  =~ s/!DSPAM:\s*(?:\d+,)?[[:xdigit:]]+!//g;
	    return $line;}));
  }
  return $part;
}

#
# DSPAM Headers:
# X-DSPAM-Confidence: 0.5138
# X-DSPAM-Factors: 15,
# X-DSPAM-Improbability: 1 in 107 chance of being ham
# X-DSPAM-Probability: 1.0000
# X-DSPAM-Processed: Fri Jan 20 14:51:41 2006
# X-DSPAM-Reclassified
# X-DSPAM-Result: Spam
# X-DSPAM-Signature: 43d13f4d154401696382214
# X-DSPAM-User
# DSPAM Signature in body:
# !DSPAM:\s(\d+,)?[[:xdigit:]]+!
#
MMHS->fighter('DSPAM',
  fields   => qr/^X-DSPAM-/i,
  isspam   => sub
	       {
		 my ($sg, $head)  = @_;
		 if (my $result = head->get('X-DSPAM-Result')) {
		   return $result =~ /^(?:SPAM|BL[AO]CKLISTED|VIRUS)$/i;
		 }
		 return 0;
	       },
  version  => sub
	       {
		 my ($sg, $head) = @_;
		 if (my $scan_header = $head->get('X-DSPAM-Result')) {
		   # DSPAM doesn't supply a header with its version number.
		   my ($software, $version) = qw/DSPAM 0.0/;
		   return ($software, $version);
		 }
		 return ();
	       }
  );
# MIMEDefang headers (at our installation):
# (There are no standard MIMEDefang headers per se.)
# X-Spam-Score: 7.872 (*******)
#    DATE_IN_PAST_96_XX,FORGED_MUA_OUTLOOK,MSOE_MID_WRONG_CASE,SPF_SOFTFAIL
# X-Scanned-By: MIMEDefang 2.70 on 198.2.168.1
MMHS->fighter('MIMEDefang',
  fields   => qr/^(?:X-Scanned-By|X-Spam-Score)/i,
  isspam   => sub
	       {
		 my ($sg, $head)  = @_;
		 if (my $score_header = $head->get('X-Spam-Score')) {
		   if (my ($spam_score) = ($score_header =~ /^(\d+(?:\.\d+)?)/)) {
		     return $spam_score >= 5.0;
		   }
		 }
		 return 0;
	       },
  version  => sub
	       {
		 my ($sg, $head) = @_;
		 if (my $scan_header = $head->get('X-Scanned-By')) {
		   if (my ($software, $version) =
		          ($scan_header =~ /^(\S+)\s+(\d+(?:\.\d+)?)/i)) {
		     return ($software, $version);
		   }
		 }
		 return ();
	       }
  );
#
# Get the command line arguments.
#
die "Usage: $0 mailbox\n"
    . "    (where 'mailbox' may be either a maildir or mbox file)\n"
    unless @ARGV==1;
my $filename = shift @ARGV;
#
# Open the folders
#
my $outfilename = "${filename}.strip";
my $recursive = \1;
remove($recursive, $outfilename)
  if (-e $outfilename);
my $mgr = MBM->new;
# Open the original folder; don't parse message body unless needed.
my $folder = $mgr->open($filename , access => 'r', extract => 'LAZY')
  or die "Cannot open $filename: $!\n";
my $outbox = $mgr->open($outfilename, access => 'a', create => 1)
  or die "Cannot open $outfilename to write: $!\n";
my $nr_msgs = $folder->nrMessages;
print "Mail folder '$folder' contains $nr_msgs",
      " message" . ($nr_msgs > 1 ? 's' : ''), ":\n";
for my $msg ($folder->messages) {
  printf "%6d. %s\n", $msg->seqnr+1, $msg->subject;
  my $m = $msg->clone;
  # If the SpamAssassin module is available,
  # and there are SA artifacts in the message,
  # then let SA clean up the message first, because
  # the rules for cleaning up SA markup can be rather complex.
  if (defined($SA)
      && MMHS->from($m, types => ['SpamAssassin'])) {
    # See: Mail::Message::Construct::Text
    my $msg_text = $m->string;
    my $SA_msg = $SA->parse($msg_text);
    $msg_text = $SA->remove_spamassassin_markup($SA_msg);
    # See: Mail::Message::Construct::Read
    $m = Mail::Message->read($msg_text);
  }
  # See: Mail::Message::Construct::Rebuild
  $m->rebuild(keep_message_id => 1,
              extra_rules => [\&use_orig_msg_part,
                              \&remove_dspam_sig_part,
                              \&remove_dspam_sig_text]);
  my $head = $m->head;
  # Remove SPAM mark up that is specific to each "SPAM fighter" tool.
  # See: Mail::Message::Head::SpamGroup
  $head->removeSpamGroups;
  # To be on the safe side, remove all the 'X-' fields.
  $head->removeFields(qr/^X-/i);
  my $subj = $head->get('Subject');
  # Remove various Subject line mark ups that are
  # sometimes used to indicate a possible SPAM message.
  if (defined($subj)
      && ($subj =~ s/\[SPAM(?::\s*\d+\.\d+)?\]\s*//gi
          | $subj =~ s/\bSPAM:\s+//gi
          | $subj =~ s/\[?\*+\s*SPAM\s*\*+\]?//gi
          | $subj =~ s/\{SPAM\??\}\s*//gi)) {
    $head->delete('Subject');
    $head->add("Subject: $subj");
  }
  if ($outbox->messageId($m->messageId)) {
    # Assign a new internal message ID.
    # If we don't do this, the message will be detected
    # as a duplicate, and will not be written to the
    # output mailbox.
    print "\tWARNING: Duplicate message ID\n";
    $m->takeMessageId(undef);
  }
  $m->printStructure(select, "\t");
  $outbox->addMessage($m);
}
$folder->close(write => 'NEVER');
$outbox->close(write => 'ALWAYS');
