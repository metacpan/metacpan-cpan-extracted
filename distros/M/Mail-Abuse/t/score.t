
# $Id: score.t,v 1.3 2005/03/22 16:07:31 lem Exp $

# Check the basic scoring of the reports

use IO::File;
use Test::More;
use File::Path;
use Date::Parse;
use NetAddr::IP;
use Mail::Abuse::Reader;
use Mail::Abuse::Report;
use Mail::Abuse::Incident;

@incidents = 
    (
     ['172.16.64.25/32', 'Tue Jul 30 14:48:42 1996', 'test/foobar'],
     ['172.16.64.25/32', 'Tue Jul 30 14:48:42 1996', 'test/foobaz'],
     ['172.16.64.25/32', 'Tue Jul 30 14:48:42 1996', 'test/bazbar'],
     );

my @cases =
    (
     [ '1 All\syour\sbase', undef, [1] ],
     [ '7 All\syour\sbase', undef, [7] ],
     [ '1 all\syour\sbase', undef, [0] ],
     [ undef, '1 ^test/', [3] ],
     [ undef, '7 baz', [14] ],
     [ undef, '7 baz 5 foo', [24] ],
     [ '7 All\syour\sbase', '7 baz', [21] ],
     [ '5 All\syour\sbase', '7 baz 5 foo', [29] ],
     [ undef, undef, [0] ],
     [ '11000 All\syour\sbase', undef, [10000] ],
     [ '-11000 All\syour\sbas', undef, [-10000] ],
     );

				# Some funny helper classes
package myReader;
use base 'Mail::Abuse::Reader';
sub read { my $text = "All your base are belong to us!";
	   $_[1]->text(\$text); return 1 }

package myIncident;
use base 'Mail::Abuse::Incident';
sub new { bless {}, ref $_[0] || $_[0] };

package myParser;
use base 'Mail::Abuse::Incident';
sub parse {
    my @incidents = ();

    for my $i (@main::incidents)
    {
	my $I = new myIncident;
	$I->ip		(new NetAddr::IP $i->[0]);
	$I->time	($i->[1]);
	$I->type	($i->[2]);
	push @incidents, $I;
    }

    return @incidents;
};

package main;

my $config	= "config$$";	# Fake config

sub write_config ($$)		# Produce a suitable config file for testing
{
    my $r_re = shift;
    my $i_re = shift;
    my $fh = new IO::File;
    $fh->open($config, "w")
	or diag "Failed to create test config file: $!";
    print $fh "score report text: $r_re\n" if $r_re;
    print $fh "score incident type: $i_re\n" if $i_re;
    print $fh "score maximum value: 10000\n";
    print $fh "score minimum value: -10000\n";
    print $fh "# debug score: 1\n";
    $fh->close;
}

END { unlink $config };

plan tests => 1 + 3 * @cases;

use_ok('Mail::Abuse::Processor::Score');

my $rep;

for my $c (@cases)
{
    write_config($c->[0], $c->[1]);

    $rep = new Mail::Abuse::Report
    {
	config		=> $config,
	reader		=> new myReader,
	parsers		=> [ new myParser ],
	processors	=> [ new Mail::Abuse::Processor::Score ],
    };

    isa_ok($rep, 'Mail::Abuse::Report');
    $rep->next;
    ok(defined $rep->score, "Score is defined");
    unless (is($rep->score, $c->[2]->[0], "Score matches expected value"))
    {
	diag "Incident text: '" . ${$rep->text} . "'";
	diag "Report config: '" . $c->[0] . "'";
	diag "Incident config: '" . $c->[1] . "'";
    }
}


