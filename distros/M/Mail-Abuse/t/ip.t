
# $Id: ip.t,v 1.2 2003/10/02 00:02:20 lem Exp $

use IO::File;
use Test::More;
use NetAddr::IP;

my $loaded = 0;
my $config = './config.' . $$;
my $tests = 6;

plan tests => $tests;

package myParser;
use base 'Mail::Abuse::Incident';
sub parse
{
    my @incidents = ();
    push @incidents, new myIncident for (0 .. 2);
    $incidents[0]->ip(new NetAddr::IP '10.10.10.10');
    $incidents[1]->ip(new NetAddr::IP '192.168.0.1/24');
    $incidents[2]->ip(new NetAddr::IP '10.100.10.1');
    return @incidents;
}
package main;

package myReader;
use base 'Mail::Abuse::Reader';
sub read 
{
    $_[1]->text(\ "This is some random text");
    return 1;
}
package main;

package myIncident;
use base 'Mail::Abuse::Incident';
sub new { bless {}, ref $_[0] || $_[0] };
package main;

sub write_config
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
source ip within: $_[0]
source ip outside: $_[1]
#debug ip filter: on
EOF
    ;
    return $fh->close;
}

END { unlink $config; }

SKIP:
{
    eval { use Mail::Abuse::Report; $loaded = 1; };
    skip 'Mail::Abuse::Report failed to load (FATAL)', $tests,
	unless $loaded;
    $loaded = 0;

    eval { use Mail::Abuse::Filter::IP; $loaded = 1; };
    skip 'Mail::Abuse::Filter::IP failed to load (FATAL)', $tests,
	unless $loaded;
    $loaded = 0;

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config("0/0", "localhost");

    my $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 filters	=> [ new Mail::Abuse::Filter::IP ],
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 3, 
       "Correct number of incidents filtered" . 
       (@{$rep->incidents} ? 
	": " . join(', ', map { $_->ip } @{$rep->incidents})
	: '.'));

    skip "Failed to create dummy config $config: $!\n", $tests - 2,
	unless write_config("10.10.10.0/24, 10.100.10.0/24", "192.168/18");

    $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 filters	=> [ new Mail::Abuse::Filter::IP ],
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 2, 
       "Correct number of incidents filtered" . 
       (@{$rep->incidents} ? 
	": " . join(', ', map { $_->ip } @{$rep->incidents})
	: '.'));

    skip "Failed to create dummy config $config: $!\n", $tests - 4,
	unless write_config("192.168/18", "10.0.0.0/8");

    $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 filters	=> [ new Mail::Abuse::Filter::IP ],
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 1, 
       "Correct number of incidents filtered" . 
       (@{$rep->incidents} ? 
	": " . join(', ', map { $_->ip } @{$rep->incidents})
	: '.'));
}







