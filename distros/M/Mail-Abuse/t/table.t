
# $Id: table.t,v 1.2 2005/06/09 15:04:31 lem Exp $

use IO::File;
use Test::More;

my $loaded	= 0;
my $config	= './config.' . $$;
my $table	= './table.' . $$;

our %incidents = 
    (
     '10.10.10.10' => 'This is a valid incident',
     '10.10.10.11' => 'This is a valid incident',
     '10.10.10.12' => 'This is a valid incident',
     '10.10.20.20' => 'This is an invalid incident',
     '10.10.20.21' => 'This is an invalid incident',
     );

my $tests = 2 + 2 * keys %incidents;

plan tests => $tests;

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

package myParser;
use base 'Mail::Abuse::Incident';
sub parse
{
    my @incidents = ();
    push @incidents, map 
    { 
	my $i = myIncident->new; 
	$i->ip(new NetAddr::IP $_); 
	$i->test_data($main::incidents{$_});
	$i;
    } keys %main::incidents;
    return @incidents;
}
package main;

sub write_config
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
#debug table: on
table location: $table
EOF
    ;
    $fh->close;

    $fh = new IO::File $table, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
10.10.10/24	foo=bar;baz=bad;zzz.yyy=yeah!;deep.struct.we.might.use=1
EOF
    ;
    $fh->close;
    return 1;
}

END 
{ 
    unlink $config; 
    unlink $table; 
}

SKIP:
{
    eval { use Mail::Abuse::Report; $loaded = 1; };
    skip 'Mail::Abuse::Report failed to load (FATAL)', $tests
	unless $loaded;
    $loaded = 0;

    eval { use Mail::Abuse::Processor::Table; $loaded = 1; };
    skip 'Mail::Abuse::Processor::Table failed to load (FATAL)', $tests 
	unless $loaded;
    $loaded = 0;

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config;

    my $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 processors	=> [ new Mail::Abuse::Processor::Table ],
#	 debug		=> 1,
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, scalar keys %incidents, 
       "Correct number of incidents");

    for my $i (@{$rep->incidents})
    {
	if ($i->ip =~ m/^10.10.10./)
	{
	    is(ref $i->table(), 'HASH', "Incident matched and was filled");

	    is_deeply($i->table,
		      {
			  foo => 'bar',
			  baz => 'bad',
			  zzz => {yyy => 'yeah!'},
			  deep => {struct => {we => {might => {use => 1 }}}},
		      },
		      "Correct incident structure contents");
	}
	else
	{
	    ok(!defined $i->table, 
	       "Non - matching incident does not have ->table()");
	    ok(1, "Dummy test that always succeeds");
	}
    }
}
