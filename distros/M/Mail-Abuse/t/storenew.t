
# $Id: storenew.t,v 1.1 2005/11/14 00:14:51 lem Exp $

use IO::File;
use Test::More;
use File::Spec;
use File::Path;
use PerlIO::gzip;
use Storable qw/fd_retrieve/;

my $config = './config.' . $$;
our %dates = 
    (
     1023249600	=> File::Spec->catfile(File::Spec->curdir, "test$$",
				       '2002', '06', '05', '001023249600'),

     954648000	=> File::Spec->catfile(File::Spec->curdir, "test$$",
				       '2000', '04', '02', '000954648000'),

     79416000	=> File::Spec->catfile(File::Spec->curdir, "test$$",
				       '1972', '07', '08', 
				       'a493127733ea0c38a6e7d1ab3821042b'),
     );			

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
    push @incidents, map { my $i = myIncident->new; $i->time($_); $i } 
    keys %main::dates;
    return @incidents;
}
package main;

package myEmpty;
use base 'Mail::Abuse::Incident';
sub parse
{
    return;
}
package main;

sub write_config ($)
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
store root path: test$$
store mode: $_[0]
#debug store: on
EOF
    ;
    return $fh->close;
}

sub cleanup
{
    rmtree(File::Spec->catfile(File::Spec->curdir, "test$$"));
    unlink $config; 
}

END { cleanup() }

my %modes = (
    serialized	=> [ qw/serialized serialized-gz/ ],
    plain	=> [ qw/plain plain-gz/ ],
);

plan tests => 14 * (@{$modes{serialized}} + @{$modes{plain}});

SKIP:
{
    eval { use Mail::Abuse::Report; $loaded = 1; };
    skip 'Mail::Abuse::Report failed to load (FATAL)', $tests,
	unless $loaded;
    $loaded = 0;

    eval { use Mail::Abuse::Processor::Store; $loaded = 1; };
    skip 'Mail::Abuse::Processor::Store failed to load (FATAL)', 
    $tests unless $loaded;
    $loaded = 0;

    for my $mode (@{$modes{serialized}})
    {
	cleanup();
	skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config($mode);

	my @rep = (
	    new Mail::Abuse::Report 
	    (config		=> $config,
	     reader		=> new myReader,
	     parsers	=> [ new myParser ],
	     processors	=> [ new Mail::Abuse::Processor::Store ],
	    ),
	    new Mail::Abuse::Report 
	    (config		=> $config,
	     reader		=> new myReader,
	     parsers	=> [ new myEmpty ],
	     processors	=> [ new Mail::Abuse::Processor::Store ],
	    ),
	);

	isa_ok($rep[0], 'Mail::Abuse::Report');
	isa_ok($rep[1], 'Mail::Abuse::Report');

	$_->next for @rep;
	is(scalar @{$rep[0]->incidents}, 3, "Correct number of incidents");
	is(scalar @{$rep[1]->incidents}, 0, "Correct number of incidents");

	ok(-f $dates{79416000}, "$mode: Correct naming $dates{79416000}");
	ok(-s $dates{79416000}, "$mode: $dates{79416000} is not empty");
	ok(-f "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
	   "Correct naming for empty report");
	ok(-s "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
	   "empty report produces a complete file");

	is($dates{79416000}, $rep[0]->store_file, "Correct store location");
	is("test$$/empty/a493127733ea0c38a6e7d1ab3821042b",
	   $rep[1]->store_file, "Correct store location");
	
	for my $r (@rep)
	{
	    my $fh = new IO::File $r->store_file, "<:gzip(autopop)";
	    isa_ok($fh, 'IO::File');
	    my $stored;
	    eval { $stored = fd_retrieve($fh) };
	    if ($@) { fail("Read failed: $@") }
	    else { is_deeply($r, $stored) } 
	    $fh->close;
	}
    }

    for my $mode (@{$modes{plain}})
    {
	cleanup();
	skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config($mode);

	my @rep = (
	    new Mail::Abuse::Report 
	    (config		=> $config,
	     reader		=> new myReader,
	     parsers	=> [ new myParser ],
	     processors	=> [ new Mail::Abuse::Processor::Store ],
	    ),
	    new Mail::Abuse::Report 
	    (config		=> $config,
	     reader		=> new myReader,
	     parsers	=> [ new myEmpty ],
	     processors	=> [ new Mail::Abuse::Processor::Store ],
	    ),
	);
	
	isa_ok($rep[0], 'Mail::Abuse::Report');
	isa_ok($rep[1], 'Mail::Abuse::Report');

	$_->next for @rep;
	is(scalar @{$rep[0]->incidents}, 3, "Correct number of incidents");
	is(scalar @{$rep[1]->incidents}, 0, "Correct number of incidents");

	ok(-f $dates{79416000}, "$mode: Correct naming $dates{79416000}");
	ok(-s $dates{79416000}, "$mode: $dates{79416000} is not empty");
	ok(-f "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
	   "Correct naming for empty report");
	ok(-s "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
	   "empty report produces a complete file");

	is($dates{79416000}, $rep[0]->store_file, "Correct store location");
	is("test$$/empty/a493127733ea0c38a6e7d1ab3821042b",
	   $rep[1]->store_file, "Correct store location");
	
	for my $r (@rep)
	{
	    my $fh = new IO::File $r->store_file, "<:gzip(autopop)";
	    isa_ok($fh, 'IO::File');
	    my $stored;
	    do { local $/ = undef; $stored = <$fh> };
	    is(${$r->text}, $stored, "Report contents match");
	    $fh->close;
	}
    }
}
