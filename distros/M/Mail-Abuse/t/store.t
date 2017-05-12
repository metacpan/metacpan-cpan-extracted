
# $Id: store.t,v 1.8 2005/11/14 00:14:51 lem Exp $

use Storable;
use IO::File;
use Test::More;
use File::Spec;
use File::Path;

my $loaded = 0;
my $config = './config.' . $$;
my $tests = 14;

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

sub write_config
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
store root path: test$$
#store mode: serialized-gz
#debug store: on
EOF
    ;
    return $fh->close;
}

END 
{ 
    rmtree(File::Spec->catfile(File::Spec->curdir, "test$$"));
    unlink $config; 
}

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

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config;

    my $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myParser ],
	 processors	=> [ new Mail::Abuse::Processor::Store ],
#	 debug		=> 1,
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, scalar keys %dates, 
       "Correct number of incidents");

    ok(-f $dates{79416000}, "Correct naming $dates{79416000}");
    ok(-s $dates{79416000}, "$dates{79416000} is not empty");
    ok(my $stored = retrieve($dates{79416000}), "Retrieve succesful");
    isa_ok($stored, ref $rep, "Proper type restored");
    is_deeply($stored, $rep, "Exact same structure restored");

    $rep = new Mail::Abuse::Report 
	(config		=> $config,
	 reader		=> new myReader,
	 parsers	=> [ new myEmpty ],
	 processors	=> [ new Mail::Abuse::Processor::Store ],
#	 debug		=> 1,
	 );

    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;
    is(scalar @{$rep->incidents}, 0,
       "Correct number of incidents");

    ok(-f "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
       "Correct naming for empty report");
    ok(-s "test$$/empty/a493127733ea0c38a6e7d1ab3821042b", 
       "empty report produces a complete file");
    ok($stored 
       = retrieve("test$$/empty/a493127733ea0c38a6e7d1ab3821042b"), 
       "Retrieve succesful");
    isa_ok($stored, ref $rep, "Proper type restored");
    is_deeply($stored, $rep, "Exact same structure restored");
}





