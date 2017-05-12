package Device::ISDN::OCLM;

=head1 NAME

Device::ISDN::OCLM - A perl module to control the 3com OfficeConnect LanModem

=head1 SYNOPSIS

 $sp = 1;
 $pw = 'secret;
 $lanmodem = Device::ISDN::OCLM->new ();
 $lanmodem->password ($pw);
 $command = 'manualConnect';
 $status = $lanmodem->$command ($sp);
 while (($status eq 'CLOCK') || ($status eq 'PASSWORD') ||
        ($status eq 'CONNECTING') || ($status eq 'LOGGING IN')) {
   if ($status eq 'CLOCK') {
     sleep (1);
     $status = $lanmodem->setClock ();
   } elsif ($status eq 'PASSWORD') {
     sleep (1);
     $status = $lanmodem->enterPasword ();
   } elsif (($status eq 'CONNECTING') || ($status eq 'LOGGING IN')) {
     $command = 'connectStatus';
     $status = 'OK';
   }
   if ($status eq 'OK') {
     sleep (1);
     $status = $lanmodem->$command ($sp);
   }
 }
 print "$status\n";

=head1 DESCRIPTION

This module can be used to control the 3com OfficeConnect LanModem, an
ISDN TA/router. Device statistics can be queried and manual connections
can be brought up and taken down. Support is provided for setting the
clock if the device is power-cycled, and for automatically entering the
password if the device is password-protected.

All operations that access the device return a status code indicating
whether the operation was successful or not; and, if not, why. For
example, if you attempt to query device statistics and the device is
locked then the status code will indicate this fact, allowing you to enter
the password and retry the operation. Hence the loop in the above
synopsis.

This module does not perform these loops internally in an effort to allow
it to be embedded within a controlling application such as the B<oclm>
Perl command-line application, and a GNOME/GTK graphical user interface
that is available separately.

This module has a few warts; some are mandated by the device itself and
some are the fault of the author.

=head1 CONSTRUCTORS

The following constructor is provided:

=over 4

=item $lanmodem = Device::ISDN::OCLM->new ()

This class method constructs a new LanModem object. A default
HTTP user agent is created with no proxy information.

=back

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $lanmodem->clone ()

This method returns a clone of this object.

=item $oldHostname = $lanmodem->lanmodem ( [$newHostname] )

This method gets, and optionally sets, the hostname (and optionally port)
of the device being controlled. The default value is I<3com.oc.lanmodem>.

=item $oldPassword = $lanmodem->password ( [$newPassword] )

This method gets, and optionally sets, the password needed to access the
device. This is only needed if your device is password-protected.

=item $userAgent = $lanmodem->userAgent ()

This method gets the B<LWP::UserAgent> that is used by this object to access
the device. Use this if you want to configure HTTP proxy settings, etc.

=item $defHostname = $lanmodem->defaultLanModem ()

This method gets the default device hostname, I<3com.oc.lanmodem>.

=item $status = $lanmodem->manualConnect ($providerIndex)

This method attempts to manually connect to the specified service provider
(identified by index, starting from 1). The result will be one of the
standard status codes, I<'CONNECTING'> if the ISDN connection attempt is
in progress (most likely), I<'LOGGING IN'> if the device is attempting to
log in to the service provider, I<'ISDN FAILED'> if there was an error
placing the ISDN call or I<'LOGON FAILED'> if there was an error logging
on. Currently, further details of the error are not available.

Once you have called this and the response is I<'CONNECTING'> or
I<'LOGGING IN'> then you should poll the B<connectStatus()> method to
determine the updated connection attempt status.

If you call this method while the device is already connecting to, or
logging into the service provider, then the results are not clearly
defined; the connection attempt may be aborted. If you call this after the
device has connected to the service provider, then again it is not clearly
defined; it may return success.

=item $status = $lanmodem->connectStatus ($providerIndex)

This method returns the connection status of the call currently in
progress to the specified provider.

=item $status = $lanmodem->manualDisconnect ($lineIndex)

This method attempts to manually disconnect the specified ISDN line
(identified by index, starting from 1). The result will be one of the
standard status codes.

=item $status = $lanmodem->manualAbort ($lineIndex)

This method attempts to abort the current connection attempt on the
specified ISDN line (identified by index, starting from 1). The result
will be one of the standard status codes.

=item $status = $lanmodem->enterPassword ()

This method enters the password on the device to unlock it. You should
first configure a password through the B<password()> method. This method
should generally be called when a query returns the status code
I<'PASSWORD'>. The result will be one of the standard status codes or
I<'BAD PASSWORD'> if the password you configured is incorrect.

=item $status = $lanmodem->setClock ()

This method sets the time on the device to the current time on your
system. This should generally be called when a query returns the status
code I<'CLOCK'>. The result will be one of the standard status codes.

=item $status = $lanmodem->getManualStatistics ()

This method queries manual calling statistics from the device. This
includes all configured service providers and whether they are currently
connected or not. The result will be one of the standard status codes.

=item $info = $lanmodem->manualStatistics ()

This method returns the result of the previous manual calling statistics
query; the result is of type Device::ISDN::OCLM::ManualStatistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getSystemStatistics ()

This method queries system statistics from the device. This includes the
device serial number, firmware revision etc. The result will be one
of the standard status codes.

=item $info = $lanmodem->systemStatistics ()

This method returns the result of the previous system statistics
query; the result is of type Device::ISDN::OCLM::SystemStatistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getISDNStatistics ()

This method queries ISDN statistics from the device. This includes the
status of the different ISDN layers, etc. The result will be one
of the standard status codes.

=item $info = $lanmodem->isdnStatistics ()

This method returns the result of the previous ISDN statistics
query; the result is of type Device::ISDN::OCLM::ISDNStatistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getCurrentStatistics ()

This method queries current call statistics from the device. This includes
details about the current connection on each ISDN line, including its up
time, to whom it is connected, etc. The result will be one of the standard
status codes.

=item $info = $lanmodem->currentStatistics ()

This method returns the result of the previous current call statistics
query; the result is of type Device::ISDN::OCLM::CurrentStatistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getLastStatistics ()

This method queries last call statistics from the device. This includes
details about the previous connection on each ISDN line, including its up
time, the reason for it going down, etc. The result will be one of the
standard status codes.

=item $info = $lanmodem->lastStatistics ()

This method returns the result of the previous last call statistics
query; the result is of type Device::ISDN::OCLM::LastStatistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getLast10Statistics ()

This method queries last 10 call statistics from the device. This includes
details of the last 10 calls, including their durations, the reason for
going up, etc. The result will be one of the standard status codes.

=item $info = $lanmodem->last10Statistics ()

This method returns the result of the previous last 10 call statistics
query; the result is of type Device::ISDN::OCLM::Last10Statistics. If the
previous request failed, then the result is indeterminate.

=item $status = $lanmodem->getSPStatistics ()

This method queries service provider statistics from the device. This
includes the name of each configured service provider as well as how much
time you have spent connected to that provider, etc. The result will be
one of the standard status codes.

=item $info = $lanmodem->spStatistics ()

This method returns the result of the previous service provider statistics
query; the result is of type Device::ISDN::OCLM::SPStatistics. If the
previous request failed, then the result is indeterminate.

=back

=head1 STANDARD STATUS CODES

The following are the status codes that you should expect from any command
that you perform against the device:

=over 4

=item 'OK'

The command succeeded.

=item 'CLOCK'

The device clock is unset (probably because of a power cycle). You should
call B<setClock()> to set the clock and then repeat your original command.

=item 'PASSWORD'

The device is password locked. You should call B<enterPassword()> to enter
the password and then repeat your original command.

=item 'BAD HTML'

The device returned and unexpected HTML page. This is either because of
a bug in this module or because your firmware is different from mine.
Probably best to contact me and we can work out the problem.

=item 'BAD HTTP'

There was a problem performing an HTTP request of the device. Either you
got the hostname wrong, it is not reachable from your machine, there
was a network error, or something bizarre of that nature happened.

=back

=head1 BUGS

Specifying your password in any manner is, of course, insecure. Doesn't
support multiple concurrent connection attemps. Others unknown.

=head1 SEE ALSO

L<oclm>,
L<Device::ISDN::OCLM::ManualStatistics>,
L<Device::ISDN::OCLM::SystemStatistics>,
L<Device::ISDN::OCLM::ISDNStatistics>,
L<Device::ISDN::OCLM::CurrentStatistics>,
L<Device::ISDN::OCLM::LastStatistics>,
L<Device::ISDN::OCLM::Last10Statistics>,
L<Device::ISDN::OCLM::SPStatistics>,
L<Device::ISDN::OCLM::Statistics>

=head1 COPYRIGHT

Copyright 1999-2000 Merlin Hughes.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Merlin Hughes E<lt>merlin@merlin.org>

=cut

# TODO: Figure out the WizStat2 thing. Maybe that is when there
# is a second connection attempt in progress!! If so, status has
# to be a bit smarter!!

# what about explicit deletion of HTML parsed things?

# TODO: store HTML locally
# TODO: explicit clock set
# TODO: last 10 calls

# TODO: if I've already downloaded a page, don't refetch it...

# "OK"
# "CLOCK"
# "PASSWORD"
# "BAD HTML"
# "BAD HTTP"

# from password
# "BAD PASSWORD"

# from connect or status
# "CONNECTING"
# "LOGGING IN"
# "FAILED"

# when does "MainPage" title occur?

# TOHANDLE: What if you double-call DISC

# TODO: Refuse the temporary provider

use strict;

use HTML::TreeBuilder;
use URI::URL;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Request::Form;
use Time::localtime;

use Device::ISDN::OCLM::UserAgent;
use Device::ISDN::OCLM::ManualStatistics;
use Device::ISDN::OCLM::Last10Statistics;
use Device::ISDN::OCLM::Statistics;

use UNIVERSAL qw (isa);
use vars qw ($VERSION);

$VERSION = "0.40";

my $defLanmodem = '3com.oc.lanmodem';

sub
new
{
  my ($class) = @_;

  my $self = bless {
    'lanmodem' => $defLanmodem,
    'password' => '',
    'userAgent' => Device::ISDN::OCLM::UserAgent->new (),

    # Web request stuff

    'href' => undef,
    'url' => undef,
    'request' => undef,
    'response' => undef,
    'html' => undef,
    'title' => undef,
    'element' => undef,

    # Statistics stuff

    'manualStatistics' => undef,
    'systemStatistics' => undef,
    'isdnStatistics' => undef,
    'currentStatistics' => undef,
    'lastStatistics' => undef,
    'last10Statistics' => undef,
    'spStatistics' => undef,
  }, $class;

  $self;
}

sub
clone
{
  my ($self) = @_;
  my $copy = bless { %$self }, ref $self;

  $copy->{'userAgent'} = $copy->{'userAgent'}->clone ();

  $copy;
}

sub
lanmodem
{
  return shift->_elem ('lanmodem', @_);
}

sub
password
{
  return shift->_elem ('password', @_);
}

sub
_elem
{
  my ($self, $elem, $new) = @_;

  my $old = $self->{$elem};
  $self->{$elem} = $new if defined $new;
  
  return $old;
}

sub
userAgent
{
  return shift->{'userAgent'};
}

sub
defaultLanmodem
{
  return $defLanmodem;
}

sub
manualConnect
{
  my ($self, $index) = @_;
  my $result;

  $self->{'href'} = "CALL$index.HTM";
  $result = $self->_doConnect ();

  $result;
}

# BUG: Doesn't listen to the index...
sub
connectStatus
{
  my ($self, $index) = @_;
  my $result;

  $self->{'href'} = "WizStat.htm";
  $result = $self->_doConnect ();

  $result;
}

sub
_doConnect
{
  my ($self) = @_;
  my $result;

  $result = $self->_performHREF ();
  return $result if $result ne "OK";

  return "OK" if $self->{'title'} eq "CallMade";
  return "BAD HTML" if $self->{'title'} ne "WizStat";

  $result = $self->_getElement ('html', 'body');
  return $result if $result ne "OK";

  my $body = $self->{'element'};
  my $pars = $body->content;
  my $par;
  my $i = 0;
  my $p = 0;

  while ($p < 4) {
    while (defined ($par = $pars->[$i ++]) && !isa ($par, 'HTML::Element')) {}
##  print "PAR" . $par->as_HTML ();
    return "BAD HTML" if !defined ($par) || ($par->tag ne 'p');
    ++ $p;
  }

##print "PAR" . $par->as_HTML ();

  my $text = Device::ISDN::OCLM::HTML->_toText ($par);

  return "OK" if !defined ($text);
  # This is a hack because if I connect on a connected line then
  # it redirects me to WizStat2.htm which is EMPTY!
  # Strange: If I double-connect then it says "OK" but it autoredirects
  # with LOCATION: http://'/WizStat2.htm ...

  return "CONNECTING" if ($text =~ /Connecting to/);
  return "LOGGING IN" if ($text =~ /Logging in/);
  return "LOGON FAILED" if ($text =~ /Logging on to the Service Provider failed/);
  return "ISDN FAILED" if ($text =~ /ISDN CALL FAILED/);

 # I should return a bit more info on failed; for example, the text might
 # be ...failed!\nPPP: Wrong User ID and/or Password
 # or ...FAILED!\nISDN call did not come up in 20 seconds

  "BAD HTML";
}

sub
manualDisconnect
{
  my ($self, $index) = @_;
  my $result;

  $self->{'href'} = "DISC$index.HTM";
  $result = $self->_performHREF ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "CallDisc";

  "OK";
}

sub
manualAbort
{
  my ($self, $index) = @_;
  my $result;

  $self->{'href'} = "ABORT$index.HTM";
  $result = $self->_performHREF ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "CallDisc";

  "OK";
}

sub
enterPassword
{
  my ($self) = @_;
  my $result;

  $self->{'href'} = "enter.htm";
  $result = $self->_performHREF ();
  return $result if $result ne "PASSWORD";
# return "BAD HTML" unless $self->{'title'} eq "Enter Password";

  $result = $self->_getElement ('html', 'body', 'form');
  return $result if $result ne "OK";
  my $form = HTTP::Request::Form->new ($self->{'element'}, $self->{'url'});
  $form->field ('Password', $self->password);
  $self->{'request'} = $form->press ('Enter');
  $result = $self->_performRequest ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "MainPage";

  "OK";
}

# I should really check the redirects to decide to return
# "CLOCK" so I don't need the hack below and elsewhere
sub
setClock
{
  my ($self) = @_;
  my $result;

  $self->{'href'} = "clockset.htm";
  $result = $self->_performHREF ();
  return $result if $result ne "CLOCK";
# return "BAD HTML" unless $self->{'title'} eq "Clock Set";

  $result = $self->_getElement ('html', 'body', 'form');
  return $result if $result ne "OK";
  my $form = HTTP::Request::Form->new ($self->{'element'}, $self->{'url'});
  my $now = localtime;
  $form->field ('Year', $now->year);
  $form->field ('Month', $now->mon + 1);
  $form->field ('Day', $now->mday);
  $form->field ('Hour', $now->hour);
  $form->field ('Minute', $now->min);
  $form->field ('Second', $now->sec);
  $form->field ('clock', ctime);
  $self->{'request'} = $form->press ();
  $result = $self->_performRequest ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "MainPage";

  "OK";
}

sub
getManualStatistics
{
  my ($self) = @_;
  my $result;

  $self->{'href'} = "CallCtrl.htm";
  $result = $self->_performHREF ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "CallCtrl";
  $result = $self->_getElement ('html', 'body', 'form', 'table');
  return $result if $result ne "OK";
  $self->{'manualStatistics'} = Device::ISDN::OCLM::ManualStatistics->new ($self->{'element'});
  return "BAD HTML" unless $self->{'manualStatistics'};

  "OK";
}

sub
manualStatistics
{
  shift->{'manualStatistics'};
}

sub
getLast10Statistics
{
  my ($self) = @_;
  my $result;

  $self->{'href'} = "last10.htm";
  $result = $self->_performHREF ();
  return $result if $result ne "OK";
  return "BAD HTML" unless $self->{'title'} eq "Stat4"; # ugh
  $result = $self->_getElement ('html', 'body', 'form', 'table');
  return $result if $result ne "OK";
  $self->{'last10Statistics'} = Device::ISDN::OCLM::Last10Statistics->new ($self->{'element'});
  return "BAD HTML" unless $self->{'last10Statistics'};

  "OK";
}

sub
last10Statistics
{
  shift->{'last10Statistics'};
}

sub
getSystemStatistics
{
  return shift->_getStatistics (1, "systemStatistics", "stat1");
}

sub
getISDNStatistics
{
  return shift->_getStatistics (2, "isdnStatistics", "ISDN Information");
}

sub
getCurrentStatistics
{
  return shift->_getStatistics (3, "currentStatistics", "Stat3");
}

sub
getLastStatistics
{
  return shift->_getStatistics (4, "lastStatistics", "Stat4");
}

sub
getSPStatistics
{
  return shift->_getStatistics (5, "spStatistics", "Service Provider Information");
}

sub
systemStatistics
{
  shift->{'systemStatistics'};
}

sub
isdnStatistics
{
  shift->{'isdnStatistics'};
}

sub
currentStatistics
{
  shift->{'currentStatistics'};
}

sub
lastStatistics
{
  shift->{'lastStatistics'};
}

sub
spStatistics
{
  shift->{'spStatistics'};
}

sub
_getStatistics
{
  my ($self, $index, $name, $title) = @_;
  my $result;

  $self->{'href'} = "Stat$index.htm";
  $result = $self->_performHREF ();
  return $result if $result ne "OK";
  return "BAD HTML1" unless $self->{'title'} eq $title;
  $result = $self->_getElement ('html', 'body', 'form', 'table');
  return $result if $result ne "OK";
  $self->{$name} = Device::ISDN::OCLM::Statistics->_create ($index, $self->{'element'});
  return "BAD HTML2" unless $self->{$name};

  "OK";
}

sub
_performHREF
{
  my ($self) = @_;
  my $result;

  $result = $self->_getURL ();
  $result = $self->_getRequest () if $result eq "OK";
  $result = $self->_performRequest () if $result eq "OK";

  $result;
}

sub
_performRequest
{
  my ($self) = @_;
  my $result;
  
  $result = $self->_getResponse ();
  $result = $self->_getHTML () if $result eq "OK";
  $result = $self->_getTitle () if $result eq "OK";
  return $result if $result ne "OK";

##print STDERR "HREF: " . $self->{'href'} . "\n";
##print STDERR "HTML: " . $self->{'html'}->as_HTML ();

  return "PASSWORD" if $self->{'title'} eq "Locked";
  return "CLOCK" if $self->{'title'} eq "Clock Set";
  return "PASSWORD" if $self->{'title'} eq "Enter Password";
  return "BAD PASSWORD" if $self->{'title'} eq "Incorrect Password";

  "OK";
}

sub
_getURL
{
  my ($self) = @_;
  my $href = $self->{'href'};

  my $hostname = $self->{'lanmodem'};
  $hostname = $self->defaultLanmodem if !$hostname;
  $href = "http://$hostname/$href";
  $self->{'url'} = URI::URL->new ($href);

  "OK";
}

sub
_getRequest
{
  my ($self) = @_;
  my $url = $self->{'url'};

  $self->{'request'} = GET ($url);

  "OK";
}

sub
_getResponse
{
  my ($self) = @_;
  my $request = $self->{'request'};

  $self->{'response'} = $self->userAgent->request ($request);
# $self->{'response'}->message
  return "BAD HTTP" if $self->{'response'}->is_error;

  "OK";
}

sub
_getHTML
{
  my ($self) = @_;
  my $response = $self->{'response'};

  delete $self->{'html'} if $self->{'html'};
  $self->{'html'} = HTML::TreeBuilder->new ();
  $self->{'html'}->parse ($response->content);

  "OK";
}

sub
_getTitle
{
  my ($self) = @_;
  my $result;
  
  $result = $self->_getElement ('html', 'head', 'title');
  return $result if $result ne "OK";
  $self->{'title'} = $self->{'element'}->content->[0];

  "OK";
}

sub
_getElement
{
  my ($self, @tags) = @_;
  my $html = $self->{'html'};

  my $tag = shift (@tags);

  return "BAD HTML3" unless ($tag eq $html->tag);

  foreach $tag (@tags) {
    my $next = 0;
    my $contents = $html->content;

    foreach my $content (@{$contents}) {
      if (!$next && isa ($content, 'HTML::Element') && ($tag eq $content->tag)) {
        $next = $content;
      }
    }

    return "BAD HTML4" if !$next;

    $html = $next;
  }

  $self->{'element'} = $html;

  "OK";
}

1;
