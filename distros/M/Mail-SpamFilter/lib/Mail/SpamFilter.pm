package Mail::SpamFilter;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::SpamFilter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

extract_header
extract_spam_headers
filter_message
report_message
count_votes

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.08';

my $HOME = $ENV{'HOME'} || $ENV{'LOGDIR'} || $ENV{'USERPROFILE'} ||
                die "You're homeless!\n";
my $USER = $ENV{'USER'} || $ENV{'LOGNAME'} || $ENV{'USERNAME'} ||
                getlogin || die "You're nameless!\n";


# Table of spam filters and the tags they produce that we are interested in:

our %FILTER_TAGS = (

  spamassassin	=> [qw(X-Spam-Level
		       X-Spam-Status)],

  crm114	=> [qw(X-CRM114-Status
		       X-CRM114-Version
		       X-CRM114-CacheID
		       X-CRM114-Notice)],

  wpbl		=> [qw(X-WPBL)],

  dspam		=> [qw(X-DSPAM-Result
                       X-DSPAM-Confidence
		       X-DSPAM-Probability
                       X-DSPAM-Signature
		       X-DSPAM-User)],

  spamprobe	=> [qw(X-SpamProbe)],

  bogofilter	=> [qw(X-Bogosity)],

  spamhaus_zen	=> [qw(X-SPAMHOUSE-ZEN)],

);


our %FILTER_SPAM_TAG = (

  spamassassin	=> qr/X-Spam-Status: Yes/,

  crm114	=> qr/X-CRM114-Status: SPAM/,

  wpbl		=> qr/X-WPBL: BLOCK/,

  dspam		=> qr/X-DSPAM-Result: Spam/,

  spamprobe	=> qr/X-SpamProbe: SPAM/,

  bogofilter	=> qr/X-Bogosity: Spam/,

  spamhaus_zen	=> qr/X-SPAMHOUSE-ZEN: BLOCK/,

);


our %FILTER_GOOD_TAG = (

  spamassassin	=> qr/X-Spam-Status: No/,

  crm114	=> qr/X-CRM114-Status: (Good|UNSURE)/,

  wpbl		=> qr/X-WPBL: OK/,

  dspam		=> qr/X-DSPAM-Result: Innocent/,

  spamprobe	=> qr/X-SpamProbe: GOOD/,

  bogofilter	=> qr/X-Bogosity: (Ham|Unsure)/,

  spamhaus_zen	=> qr/X-SPAMHOUSE-ZEN: OK/,

);


# The command required to run each filter.
# Ensure that these are in your PATH: you may need to set
# the PATH variable in your .procmailrc for example.

our %FILTER_CMD = (

  spamassassin	=> "spamassassin",

  crm114	=> "crm -u $HOME/.crm114 mailreaver.crm",

  wpbl		=> "wpbl_check",

  dspam		=> "dspam --user $USER --mode=teft --stdout --deliver=innocent,spam",

  spamprobe	=> "spamprobe_check",

  bogofilter	=> "bogofilter -pe",

  spamhaus_zen	=> "spamhaus_zen_check",

);


# Command to tell the scanner that this message is spam:

our %ISSPAM_CMD = (

  spamassassin	=> "spamassassin --report",

  crm114	=> "crm -u $HOME/.crm114 mailreaver.crm --spam",

  wpbl		=> "wpbl spam",

  dspam		=> "dspam-train spam",

  spamprobe	=> "spamprobe spam",

  bogofilter	=> "bogofilter -Ns",

);


# Command to tell the scanner that this message is NOT spam:

our %NOTSPAM_CMD = (

  spamassassin	=> "spamassassin --revoke",

  crm114	=> "crm -u $HOME/.crm114 mailreaver.crm --good",

  wpbl		=> "wpbl good",

  dspam		=> "dspam-train good",

  spamprobe	=> "spamprobe good",

  bogofilter	=> "bogofilter -Sn",

);



# Headers that we want to remove before passing through our filters:
our @EXTRA_TAGS = (

  qr/X-(\w+)-MailScanner/,

  qr/X-(\w+)-MailScanner-SpamScore/,

  qr/X-(\w+)-MailScanner-SpamCheck/,

  qr/Status/,

  qr/X-Status/,

  qr/X-KMail-(\S+)/,

);



our @FILTER_LIST = keys %FILTER_TAGS;

# Some filters want to see the existing headers when reporting as spam/notspam:

our @KEEP_TAG_CMDS = qw(dspam);



# Preloaded methods go here.


# Split a message into header and body:

sub extract_header($) {
  my ($msg) = @_;
  if ($msg =~ s/\n(\n.*)/\n/s) {
    return($msg, $1);
  } else {
    # Assume we were just given a header
    return($msg, "");
  }
}


# Extract the spam headers relating to the given list of filters
# Return a hash table: key->headers

sub extract_spam_headers($@) {
  my ($msg, @filters) = @_;
  @filters = @FILTER_LIST unless @filters;
  my ($header, $body) = extract_header($msg);
  my %tags = ();
  foreach my $filter (@filters) {
    $tags{$filter} = "";
    foreach my $tag (@{$FILTER_TAGS{$filter}}) {
      $tags{$filter} .= "$1\n" while $header =~ s/\n($tag:.*(\n[ \t].*)*)//;
    }
  }
  # Always remove the extra tags:
  $tags{"*extra*"} = "";
  foreach my $tag (@EXTRA_TAGS) {
    $tags{"*extra*"} .= "$1\n" while $header =~ s/\n($tag:.*(\n[ \t].*)*)//;
  }
  return(\%tags, $header, $body);
}


# Pass the message through the given list of filters,
# collect the results and return the tags:

sub filter_message($@) {
  my ($msg, @filters) = @_;
  @filters = @FILTER_LIST unless @filters;
  # Remove all tags before testing the message:
  my ($orig_tags, $header, $body) = extract_spam_headers($msg, @FILTER_LIST);
  my %tags;
  foreach my $filter (@filters) {
    next unless $FILTER_CMD{$filter};
    $tags{$filter} = "";
    my ($in_fh, $out_fh);
    unless(open($in_fh, "-|")) {
      open($out_fh, "|$FILTER_CMD{$filter}")
	or croak "Can't run $FILTER_CMD{$filter}: $!\n";
      print $out_fh $header, $body;
      close($out_fh);
      exit(0);
    }
    my $output = join("", <$in_fh>);
    close($in_fh);
    next if $output eq "";
    my ($output_tags) = extract_spam_headers($output, $filter);
    $tags{$filter} = $$output_tags{$filter};
  }
  # Copy any extra tags:
  $tags{"*extra*"} = $$orig_tags{"*extra*"};
  return(\%tags, $header, $body);
}


# Report this message as spam or good to the given list of filters:

sub report_message($$@) {
  my ($type, $msg, @filters) = @_;
  croak qq[report_message: type must be "spam" or "good", not "$type"]
    unless ($type eq "spam") || ($type eq "good");
  # Remove all tags before reporting:
  my ($orig_tags, $header, $body) = extract_spam_headers($msg, @FILTER_LIST);
  foreach my $filter (@filters) {
    my $cmd = "";
    if ($type eq "spam") {
      $cmd = $ISSPAM_CMD{$filter};
    } else {
      $cmd = $NOTSPAM_CMD{$filter};
    }
    next unless $cmd;
    open(my $out_fh, "|$cmd") or croak "Can't run $cmd: $!\n";
    if (grep { $filter eq $_ } @KEEP_TAG_CMDS) {
      print $out_fh $header, $$orig_tags{$filter}, $body;
    } else {
      print $out_fh $header, $body;
    }
    close($out_fh) or die "close failed on pipe to $cmd";
  }
}


# Count how many of the given filters have marked this message
# as either spam or good.
# Returns ($spam_count, $good_count, \@spam_voters, \@good_voters)

sub count_votes($@) {
  my ($msg, @filters) = @_;
  # If we are given a message or header, then extract the tags
  my $tags;
  if (ref $msg eq "HASH") {
    $tags = $msg;
  } else {
    ($tags) = extract_spam_headers($msg, @FILTER_LIST);
  }
  my $spam_count = 0;
  my $good_count = 0;
  my @spam_voters = ();
  my @good_voters = ();
  foreach my $filter (@filters) {
    if ($$tags{$filter} =~ /$FILTER_SPAM_TAG{$filter}/) {
      $spam_count++;
      push(@spam_voters, $filter);
    }
    if ($$tags{$filter} =~ /$FILTER_GOOD_TAG{$filter}/) {
      $good_count++;
      push(@good_voters, $filter);
    }
  }
  return($spam_count, $good_count, \@spam_voters, \@good_voters);
}




1;
__END__

=head1 NAME

Mail::SpamFilter - Provides a convenient interface for several spam filters.

=head1 SYNOPSIS

use Mail::SpamFilter ':all';

  ($header, $body) = extract_header($msg);

  # To run all the filters on $msg:
  @filters = @Mail::SpamFilter::FILTER_LIST;
  ($tags, $header, $body) = filter_message($msg, @filters);
  print $$tags{spamassasin};

  # To extract the spam headers from an already filtered message:
  ($tags, $header, $body)
    = extract_spam_headers($filtered_msg, @filters);
  print $$tags{spamassasin};

  # Count the votes and list the voters in a set of extracted tags:
  ($spam_count, $good_count, $spam_voters, $good_voters)
    = count_votes($tags, @filters);

  # If this messsage was a spam, then report it to
  # the good voters for training:
  report_message("spam", $msg, @{$good_voters});

  # If this messsage was a good message, then report it to
  # the spam voters for training:
  report_message("good", $msg, @{$spam_voters});

=head1 DESCRIPTION

Provides functions to filter messages using several spam filters and
count how many filters consider the message to be spam.




=head2 EXPORT

None by default.



=head1 SEE ALSO

http://www.spamassassin.org/	   SpamAssassin

http://crm114.sourceforge.net/   The CRM114 Discriminator

http://www.nuclearelephant.com/projects/dspam/ Nuclear Elephant: DSPAM

http://wpbl.pc9.org/		   WPBL - Weighted Private Block List

http://sourceforge.net/projects/spamprobe/     SpamProbe

http://bogofilter.sourceforge.net/	Bogofilter

http://www.spamhaus.org/ZEN/		Spamhaus ZEN DNSBL

=head1 AUTHOR

Martin Ward, E<lt>martin@gkc.org.uk<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Martin Ward

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
