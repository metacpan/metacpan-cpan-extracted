#!/usr/bin/env perl
#
# Test the processing of list groups.
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Head::Complete;
use Mail::Message::Head::ListGroup;

use Test::More;
use IO::Scalar;
use File::Spec;
use File::Basename qw(dirname);

BEGIN {
   eval { require Mail::Box::Mbox };
   if($@)
   {   plan skip_all => 'these tests need Mail::Box::Mbox';
       exit 0;
   }
   else
   {   plan tests => 119;
   }
}

#
# Creation of a group
#

my $mailbox = '"Mail::Box development" <mailbox@perl.overmeer.net>';
my $lg0 = Mail::Message::Head::ListGroup->new(address => $mailbox);

ok(defined $lg0,                         'simple construction');
my $addr = $lg0->address;

ok(defined $addr,                        'address defined');
isa_ok($addr, 'Mail::Message::Field::Address');
is($addr->phrase, 'Mail::Box development');
is($lg0->listname, 'Mail::Box development');
is($addr->address, 'mailbox@perl.overmeer.net');
is("$addr", $mailbox);
is($lg0->address->string, $mailbox);

ok(!defined $lg0->type);
ok(!defined $lg0->software);
ok(!defined $lg0->version);
ok(!defined $lg0->rfc);

#
# Extraction of a group
#

my $h = Mail::Message::Head::Complete->new;
ok(defined $h);

my $lg = Mail::Message::Head::ListGroup->from($h);
ok(!defined $lg,                     "no listgroup in empty header");

#
# Open folder with example messages
#

my $fn = dirname(__FILE__).'/203-mlfolder.mbox';
die "Cannot find file with mailinglist examples ($fn)" unless -f $fn;

my $folder = Mail::Box::Mbox->new(folder => $fn, extract => 'ALWAYS');
ok(defined $folder,                   "open example folder");
die unless defined $folder;

my @msgs   = $folder->messages;
my @expect =
 ( {
   }
 , { type    => 'Mailman'
   , version => '2.0rc1'
   , address => 'templates@template-toolkit.org'
   , listname=> 'templates'
   , details => 'Mailman at templates@template-toolkit.org (2.0rc1), 11 fields'
   , rfc     => 'rfc2369'
   }
 , { type    => 'Ezmlm'
   , software=> undef
   , version => undef
   , address => 'perl5-porters@perl.org'
   , listname=> 'perl5-porters'
   , details => 'Ezmlm at perl5-porters@perl.org, 6 fields'
   , rfc     => 'rfc2369'
   }
 , { type    => 'Smartlist'
   , software=> undef
   , version => undef
   , address => 'debian-devel@lists.debian.org'
   , listname=> 'debian-devel'
   , details => 'Smartlist at debian-devel@lists.debian.org, 12 fields'
   , rfc     => undef
   }
 , { type    => 'Majordomo'
   , software=> undef
   , version => undef
   , address => 'london-pm@lists.dircon.co.uk'
   , listname=> 'london-pm'
   , details => 'Majordomo at london-pm@lists.dircon.co.uk, 2 fields'
   , rfc     => undef
   }
 , { type    => 'Sympa'
   , software=> undef
   , version => undef
   , address => 'noustestons@cru.fr'
   , listname=> 'noustestons'
   , details => 'Sympa at noustestons@cru.fr, 9 fields'
   , rfc     => 'rfc2369'
   }
 , { type    => 'Listar'
   , software=> 'Listar'
   , version => 'v0.129a'
   , address => 'adm@oasys.net'
   , listname=> 'adm'
   , details => 'Listar at adm@oasys.net (v0.129a), 8 fields'
   , rfc     => undef
   }
 , { type    => 'YahooGroups'
   , software=> undef
   , version => undef
   , address => 'ryokoforever@yahoogroups.com'
   , listname=> 'ryokoforever'
   , details => 'YahooGroups at ryokoforever@yahoogroups.com, 7 fields'
   , rfc     => undef
   }
 , { type    => 'Mailman'
   , software=> undef
   , version => '2.0.1'
   , address => 'London.pm Perl M[ou]ngers <london-pm@london.pm.org>'
   , listname=> 'London.pm Perl M[ou]ngers <london.pm.london.pm.org>'
   , details => 'Mailman at london.pm@london.pm.org (2.0.1), 6 fields'
   , rfc     => 'rfc2919'
   }
 , { type    => 'Ecartis'
   , software=> 'Ecartis'
   , version => 'v1.0.0'
   , address => 'adm@oasys.net'
   , listname=> 'adm'
   , details => 'Ecartis at adm@oasys.net (v1.0.0), 7 fields'
   , rfc     => undef
   }
 , { type    => 'CommuniGatePro'
   , software=> 'CommuniGate Pro'
   , version => '4.0.6'
   , address => 'Mail-ListDetector@gunzel.org'
   , listname=> 'Mail-ListDetector.gunzel.org'
   , details => 'CommuniGatePro at Mail-ListDetector@gunzel.org (CommuniGate Pro 4.0.6), 4 fields'
   , rfc     => 'rfc2919'
   }
 , { type    => 'FML'
   , software=> 'fml'
   , version => '4.0 STABLE (20010208)'
   , address => 'mlname@domain.example.com'
   , listname=> 'mlname'
   , details => 'FML at mlname@domain.example.com (fml 4.0 STABLE (20010208)), 10 fields'
   , rfc     => 'rfc2369'
   }
 , { type    => 'FML'
   , software=> 'fml'
   , version => '4.0 STABLE (20010218)'
   , address => 'Announce@mldetector.gr.jp'
   , listname=> 'Announce'
   , details => 'FML at Announce@mldetector.gr.jp (fml 4.0 STABLE (20010218)), 6 fields'
   , rfc     => undef
   }
 , { type    => 'Listbox'             # based on sending address (old)
   , software=> undef
   , version => undef
   , address => 'sample@v2.listbox.com'
   , listname=> 'sample'
   , details => 'Listbox at sample@v2.listbox.com, 5 fields'
   , rfc     => 'rfc2919'
   }
 , { type    => 'Listbox'             # based on List-Software
   , software=> 'listbox.com'
   , version => 'v2.0'
   , address => 'sample@v2.listbox.com'
   , listname=> 'sample'
   , details => 'Listbox at sample@v2.listbox.com (listbox.com v2.0), 6 fields'
   , rfc     => 'rfc2919'
   }
 , { type    => 'Listserv'
   , software=> 'LISTSERV-TCP/IP'
   , version => '1.8e'
   , address => '"EXAMPLE Discussion" <EXAMPLE@LISTSERV.EXAMPLE.COM>'
   , listname=> 'EXAMPLE Discussion'
   , details => 'Listserv at "EXAMPLE Discussion" <EXAMPLE@LISTSERV.EXAMPLE.COM> (LISTSERV-TCP/IP 1.8e), 1 fields'
   , rfc     => undef
   }
 , { type    => 'Listserv'
   , software=> 'LISTSERV-TCP/IP'
   , version => '1.8d'
   , address => '"Comedy Company" <COCO@LISTSERV.EXAMPLE.COM>'
   , listname=> 'Comedy Company'
   , details => 'Listserv at "Comedy Company" <COCO@LISTSERV.EXAMPLE.COM> (LISTSERV-TCP/IP 1.8d), 1 fields'
   , rfc     => undef
   }
 , { type    => 'CommuniGate'
   , software=> 'CommuniGate'
   , version => '1.4'
   , address => '<CGnet@total.example.com> (CGnet)'
   , listname=> 'CGnet'
   , details => 'CommuniGate at CGnet@total.example.com (1.4), 1 fields'
   , rfc     => undef
   }
 );

cmp_ok(scalar @msgs, '==', @expect,         "all messages");

for(my $nr = 0; $nr < @msgs; $nr++)
{  my $msg = $msgs[$nr];
   my %exp = %{$expect[$nr]};

   my $lg = $msg->head->listGroup;
   if(! defined $lg)
   {   ok(keys %exp == 0,                   "msg $nr is non-list message");
       next;
   }
   isa_ok($lg, 'Mail::Message::Head::ListGroup', "msg $nr from $exp{type}");

   is($lg->details, $exp{details},          "$nr details");
   is($lg->type, $exp{type},                "$nr type");
   is($lg->software, $exp{software},        "$nr software");
   is($lg->version, $exp{version},          "$nr version");
   is($lg->rfc, $exp{rfc},                  "$nr rfc");
}

