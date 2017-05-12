#!/usr/bin/perl -w

use strict;
use 5.005;

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

# The default mailbox for delivery.
my $default = "/var/spool/mail/".getpwuid($>);

# A pattern to break out words in email names.
my $wordpat = qr/[-a-zA-Z0-9_.]+/;
my $wordpat_nodot = qr/[-a-zA-Z0-9_]+/;

# Destination for special emails.
sub incoming { $ENV{HOME}."/Mail/Incoming/".$_[0].".spool" }

# Destination for mailing lists.
sub maillist { incoming("maillists.".$_[0]) }

# Destination for SPAM.
sub spambox  { incoming("spam.".$_[0]) }

use Mail::Procmail;

################ The Process ################

eval { ################ BEGIN PROTECTED EXECUTION ################

# Setup Procmail module.
my $m_obj = pm_init ( logfile => 'stderr', loglevel => 3 );

# Init local values for often used headers.
my $m_from		    = pm_gethdr("from");
my $m_to		    = pm_gethdr("to");
my $m_cc		    = pm_gethdr("cc");
my $m_subject		    = pm_gethdr("subject");
my $m_sender		    = pm_gethdr("sender");
my $m_apparently_to	    = pm_gethdr("apparently-to");
my $m_resent_to		    = pm_gethdr("resent-to");
my $m_resent_cc		    = pm_gethdr("resent-cc");
my $m_resent_from	    = pm_gethdr("resent-from");
my $m_resent_sender	    = pm_gethdr("resent-sender");
my $m_apparently_resent_to  = pm_gethdr("apparently-resent-to");

my $m_header                = $m_obj->head->as_string || '';
my $m_lines		    = pm_body();
my $m_body                  = join("", @$m_lines);
my $m_size		    = length($m_body);

# These mimic procmail's TO and FROM patterns.
my $m_TO   = join("\n", $m_to, $m_cc, $m_apparently_to,
	                $m_resent_to, $m_resent_cc,
                        $m_apparently_resent_to);
my $m_FROM = join("\n", $m_from, $m_sender,
		        $m_resent_from, $m_resent_sender);

# Start logging.
pm_log(1, "Mail from $m_from");
pm_log(1, "To: $m_to");
pm_log(1, "Subject: $m_subject");

################ Get rid of some SPAMs ################

pm_ignore("Non-ASCII in subject")
  if $m_subject =~ /[\232-\355]{3}/;

pm_ignore("Bogus address: \@internet.sciurius.nl")
  if $m_TO =~ /\@internet.sciurius.nl/mi;

################ Dispatching ################

# External mail to xxx@sciurius.nl is delivered to me. Dispatch here.
# Internal mail to xxx@sciurius.nl is delivered via aliases.

if ( $m_TO =~ /jjkenzen@/mi ) {
    # Maybe CC to me?
    pm_deliver($default, continue => 1)
      if $m_TO =~ /jv(romans)?@/mi;
    pm_resend("jojan");
}

################ Intercepting ################

# I always want to see these.
pm_deliver($default, continue => 1)
  if $m_header =~ /getopt(ions|(-|::)?long)/i
  || $m_body   =~ /getopt(ions|(-|::)?long)/i;

pm_deliver($default)
  if $m_subject =~ /MODERATE/;

################ Mailing lists ################

# More or less standard mailing lists.
if ( $m_sender =~ /owner-($wordpat)@($wordpat)/i
     || $m_sender =~ /($wordpat)-owner@($wordpat)/i ) {
    my ($topic, $host) = ($1, $2);

    # Fix some list names.
    if ( $host eq "perl.org" ) {
	$topic = "perl-" . $topic
	  unless $topic =~ /^perl/;
    }
    elsif ( $topic eq "announce" ) {
	if ( $host eq "htmlscript.com" ) {
	    $topic = "htmlscript";
	}
    }

    pm_deliver(maillist($topic));
}

for ( pm_gethdr("x-mailing-list"),
      pm_gethdr("list-post"),
      pm_gethdr("mailing-list"),
      pm_gethdr("x-loop"),
    ) {

    my ($topic, $host);

    if ( ($topic, $host) = /($wordpat)@($wordpat)/i ) {

	if ( $host eq "perl.org" ) {
	    $topic = "perl6-bootstrap" if lc eq "bootstrap";
	    $topic = "perl-" . $topic unless $topic =~ /^perl/;
	    $topic =~ s/-help$//;
	}
    }

    pm_deliver(maillist($topic)) if defined $topic;
}

###### Miscellaneous

# Wannabe mailing lists (without standard headers).
for ( qw( j2ee-interest
	  cwnl-developers
	  tex-nl
	  bbdb-info bbdb-announce
	  nbui nbdev
	  info-cvs
	)
    ) {
    if ( $m_sender =~ /\b$_@/i || $m_TO =~ /\b$_@/mi ) {
	$_ = "bbdb-info" if /^bbdb-/i;
	pm_deliver(maillist($_));
    }
}

# A mailing list that catches SPAM.
if ( $m_TO =~ /(info|bug-)?vm[@%]/mi 
     || $m_FROM =~ /(info|bug-)?vm(-request)[@%]/mi ) {

    deliver_continue($default)
      if $m_subject =~ /^\[announcement\]/i;

    # Make sure VM is at least mentioned in the body...
    pm_deliver(maillist("vm"))
      if $m_body =~ /\bvm\b/i;
    spam("VM spam");
}

# A mailing list with several aliases.
pm_deliver(maillist("gnu-prog-disc"))
  if $m_TO =~ /gnu-prog(-disc(uss)?)?[@%]/mi;

# Host dependent actions
if ( $pm_hostname =~ /\.sciurius\.nl/i ) {

    # Notice mail to obsolete adresses.
    pm_deliver($ENV{HOME}."/Mail/AddrChange", continue => 1)
      if $m_TO =~ m/(jv|johan|johan.vromans|jvromans)
		    \@
		    (mh\.nl|((solair1\.)?inter\.)?nl\.net)/xmi;
}

# Discard mail that is not addressed to me.
spam("Apparently not for me")
  if $m_apparently_to =~ /<(jv|johan)/i;

# It's probably a real message for me.
pm_deliver($default);

}; ################ END PROTECTED EXECUTION ################

if ( $@ ) {
    # Something went seriously wrong...
    my $msg = $@;
    $msg =~ s/\n.*//s;

    # Log it using syslog.
    my ($tool, $facility, $level) = qw(procmail mail crit);
    require Sys::Syslog;
    import Sys::Syslog;
    openlog($tool, "pid,nowait", $facility);
    syslog($level, "%s", $msg);
    closelog();

    # Also, log normally.
    pm_log(0, "FATAL: $msg");

    # Turn it into temporary failure and hope someone notices...
    exit Mail::Procmail::TEMPFAIL;
}

################ Subroutines ################

sub spam {
    my ($tag, $reason, %atts) = ("spam", @_);
    my $line = (caller(1))[2];
    pm_log(2, $tag."[$line]: $reason");
    pm_deliver(spambox($tag), %atts);
}
