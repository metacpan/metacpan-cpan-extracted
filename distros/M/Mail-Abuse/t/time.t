
# $Id: time.t,v 1.6 2004/05/29 17:52:27 lem Exp $

use IO::File;
use Test::More;

my $loaded = 0;
my $config = './config.' . $$;
my $tests = 4;

plan tests => $tests;

package myParser;
use base 'Mail::Abuse::Incident';
sub parse
{
    my @incidents = ();
    push @incidents, new myIncident for (0 .. 4);
    $incidents[0]->time(1000);
    $incidents[1]->time(time - 5);
    $incidents[2]->time(time - 120);
    $incidents[3]->time(time + 11 * 3600);
    $incidents[4]->time(time + 12 * 3600);
    print "# incident ", $_->time, "\n" for @incidents;
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
#debug time filter: on
filter before: $_[0]
filter after: $_[1]
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

    eval { use Mail::Abuse::Filter::Time; $loaded = 1; };
    skip 'Mail::Abuse::Filter::Time failed to load (FATAL)', $tests,
	unless $loaded;
    $loaded = 0;

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config("96 hours ago", "in 10 hours");

    diag("You can install Mail::Abuse even if this test fails");

    my $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 filters	=> [ new Mail::Abuse::Filter::Time ],
#	 debug		=> 1,
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 2, "Correct number of incidents filtered");

    skip "Failed to create dummy config $config: $!\n", $tests - 2,
	unless write_config("60 seconds ago", "in 10 hours");

    $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 filters	=> [ new Mail::Abuse::Filter::Time ],
#	 debug		=> 1,
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 2, "Correct number of incidents filtered");
}
