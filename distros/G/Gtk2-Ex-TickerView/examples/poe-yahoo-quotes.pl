#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


=head1 NAME

poe-yahoo-quotes.pl - TickerView and POE download and display of Yahoo stock quotes

=head1 SYNOPSIS

 ./poe-yahoo-quotes.pl symbol symbol ...

=head1 DESCRIPTION

This is some fun downloading share prices from Yahoo using POE for
non-blocking HTTP in the GUI.

The default stock symbols are some miscellaneous shares and indexes, or a
list of symbols can be given on the command line.

POE means the GUI continues to run and display while downloading.  If you've
got C<POE::Component::Client::DNS> then the hostname lookup is asynchronous
too.  But get Client::DNS 1.04 since earlier versions only looked at the
first name server in F</etc/resolv.conf> instead of going through all like
the C library etc does.  (Or if your first there is a local name server then
make sure it forwards somewhere for hostnames it doesn't itself handle.)

The only tricky bit for POE and Gtk together is to note that some POE things
can only be done from within a POE "current session".  So the HTTP request
in refresh_start() can't be initiated directly from the $refresh_button Gtk
signal handler, instead that signal handler must POE::Kernel->post() a POE
event which is queued and then back in the main loop is dispatched to
'refresh_start' in $session.  $session->postback creates an anonymous subr
which does the post() -- it's a convenient way to create that glue when you
don't need anything else in the Gtk handler.

POE HTTP is happy to send out multiple requests simultaneously and if you
click the Refresh button a few times fast then that's what you get.  In a
real program you might want only one refresh in progress, or some limit on
them.  If you set $refresh_button to insensitive with
$refresh_button->set_sensitive(0) then it stops the user clicking again,
however as of Gtk 2.12 there's a very long standing Gtk bug where if the
mouse is in the button when you turn it back sensitive again then clicking
does nothing until the user moves out and back in.  (Botched maintenance of
the "armed" ready-to-click notion.)

=head1 SEE ALSO

L<Gtk2::Ex::TickerView>, L<POE>, L<POE::Component::Client::HTTP>,
L<POE::Component::Client::DNS>

=cut

#-----------------------------------------------------------------------------

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;
use POE 'Loop::Glib';
use URI::Escape;

my @symbols = ('^FTSE', 'GM', 'BHP.AX', 'TSCO.L', 'XAUUSD=X', 'CLZ09.NYM');
if (@ARGV) {
  @symbols = @ARGV;
}

# "f=" format is
#   s    symbol
#   l1   last price
#   c1   change from yesterday's close
#
my $url = 'http://download.finance.yahoo.com/d/quotes.csv?f=sl1c1&e=.csv&s='
  . join(',', map {URI::Escape::uri_escape($_)} @symbols);
print "Yahoo URL $url\n";

#-----------------------------------------------------------------------------

# $session is the toplevel POE session.  Posting 'refresh_start' to it
# starts a refresh of the quotes.  'refresh_response' receives its callbacks
# from the HTTP component.
#
# $session is kept alive by the postback() held in the $refresh_button,
# otherwise session_start() would want to refcount_increment().  Because
# $refresh_button is in a global variable it in turn stays alive forever,
# hence the use of UIDESTROY in the $toplevel widget destroy handler to shut
# down everything.
#
my $session = POE::Session->create
  (inline_states => { _start           => \&session_start,
                      refresh_start    => \&refresh_start,
                      refresh_response => \&refresh_response,
                    });

#-----------------------------------------------------------------------------

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (350, -1);
$toplevel->signal_connect
  (destroy => sub { POE::Kernel->signal ($session, 'UIDESTROY') });

# column 0 is the symbol, column 1 the displayed symbol+price+change string
my $liststore = Gtk2::ListStore->new ('Glib::String', 'Glib::String');
foreach my $symbol (@symbols) {
  $liststore->set ($liststore->append, 0=>$symbol, 1=>"$symbol ...");
}

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $ticker = Gtk2::Ex::TickerView->new (model => $liststore);
$vbox->pack_start ($ticker, 1,1,0);

my $renderer = Gtk2::CellRendererText->new;
$renderer->set (background => 'black',
                foreground => 'white',
                xpad => 8);
$ticker->pack_start ($renderer, 0);
$ticker->set_attributes ($renderer, text => 1); # display column 1

my $hbox = Gtk2::HBox->new;
$vbox->pack_start ($hbox, 1,1,0);

my $refresh_button = Gtk2::Button->new_from_stock ('gtk-refresh');
$hbox->pack_start ($refresh_button, 0,0,0);
$refresh_button->signal_connect
  (clicked => $session->postback('refresh_start'));

my $quit_button = Gtk2::Button->new_from_stock ('gtk-quit');
$hbox->pack_start ($quit_button, 0,0,0);
$quit_button->signal_connect (clicked => sub { $toplevel->destroy });

my $status_label = Gtk2::Label->new;
$hbox->pack_start ($status_label, 1,1,0);

#-----------------------------------------------------------------------------
my $http_created;

sub session_start {
  my $kernel = $_[KERNEL];
  $kernel->delay('refresh_start', 1);  # initial refresh after 1 second
}

sub refresh_start {
  my ($kernel) = $_[KERNEL];
  $status_label->set_text ('Downloading');

  # POE::Component::Client::HTTP and HTTP::Request aren't blindingly fast to
  # load, so don't load and create until the initial GUI is up, so there's
  # something to look at while the initial refresh is initiated!
  if (! $http_created) {
    require POE::Component::Client::HTTP;
    require HTTP::Request;
    POE::Component::Client::HTTP->spawn (Alias => 'http_component');
    $http_created = 1;
  }
  $kernel->post ('http_component',    # target component
                 'request',           # ask to initiate request
                 'refresh_response',  # postback for final result
                 HTTP::Request->new('GET', $url));
}

sub refresh_response {
  my $response_packet = $_[ARG1];
  my $resp = $response_packet->[0];  # HTTP::Response object

  if (! $resp->is_success) {
    # The plain status_line() from POE tends to be only "Internal server
    # error" and from a proxy error it's likely to be equally little, so
    # show the $resp content.  That content is HTML for the POE internal
    # errors and almost certainly likewise from a proxy.  In a real program
    # you'd render it to text or use a browser widget or something instead
    # of showing raw.
    $status_label->set_text ($resp->status_line . "\n"
                             . $resp->decoded_content);
    return;
  }

  $status_label->set_text ('');

  # $str is symbol/price/change lines from Yahoo like
  #    "BHP.AX",45.16,-0.33\r\n
  #
  my $str = $resp->decoded_content;
  my %show;  # symbol => display-string
  foreach my $line (split /[\r\n]+/, $str) {
    my ($symbol, $price, $change) = split /,/, $line;
    $symbol =~ s/"//g;
    my $show = "$symbol $price";
    # change is N/A for things like currencies and spot gold, ignore that
    if ($change ne 'N/A') { $show .= " $change"; }
    $show{$symbol} = $show;
  }
  $liststore->foreach
    (sub {
       my ($liststore, $path, $iter) = @_;
       my $symbol = $liststore->get ($iter, 0);
       my $show = $show{$symbol};
       if (! defined $show || $show eq '') { $show = "$symbol ???"; }
       $liststore->set ($iter, 1 => $show);
     });
}

$toplevel->show_all;
POE::Kernel->run;
exit 0;
