
# $Id: report.t,v 1.4 2003/10/02 00:02:20 lem Exp $

use IO::File;
use Test::More;

my $loaded = 0;
my $config = './config.' . $$;
my $tests = 73;

our $log = '';

plan tests => $tests;

sub write_config
{
    my $fh = new IO::File $config, "w";
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
dummy: 1
EOF
    ;
    return $fh->close;
}

END { unlink $config; }

eval { use Mail::Abuse::Report; $loaded = 1; };

package Reader;
our $count = 0;
sub read
{
    $_[1]->text(\ "This is the text that Reader::read inserted $count");
    main::ok(1, "Reader::read $count");
    $main::log .= " Rr $count";
    ++$count;
}
package main;

package Parser1;
use base 'Mail::Abuse::Incident';
our $count = 0;
sub parse
{
  main::ok(1, "Parser1::parse $count");
    $main::log .= " Pp1 $count";
    ++$count;
    bless { ip => $count, time => time() }, ref $_[0];
}
package main;

package Parser2;
use base 'Mail::Abuse::Incident';
our $count = 0;
sub parse
{
    main::ok(1, "Parser2::parse $count");
    $main::log .= " Pp2 $count";
    ++$count;
    bless { ip => $count, time => time() }, ref $_[0];
}
package main;

package Filter1;
our $count = 0;
sub criteria
{
    main::ok(1, "Filter1::criteria $count");
    $main::log .= " Fc1 $count";
    ++$count;
}
package main;

package Filter2;
our $count = 0;
sub criteria
{
    main::ok(1, "Filter2::criteria $count");
    $main::log .= " Fc2 $count";
    ++$count;
}
package main;

package Processor1;
our $count = 0;
sub process
{
    main::ok(1, "Processor1::process $count");
    $main::log .= " Pp1 $count";
    ++$count;
}
package main;

package Processor2;
our $count = 0;
sub process
{
    main::ok(1, "Processor2::process $count");
    $main::log .= " Pp2 $count";
    ++$count;
}
package main;

SKIP:
{
    skip 'Mail::Abuse::Report failed to load (FATAL)', $tests,
	unless $loaded;

    skip "Failed to create dummy config $config: $!\n", $tests,
	unless write_config;

    my $parsers		= [ map { bless {}, $_ } qw/Parser1 Parser2/ ];
    my $filters		= [ map { bless {}, $_ } qw/Filter1 Filter2/ ];
    my $processors	= [ map { bless {}, $_ } qw/Processor1 Processor2/ ];
    my $reader		= bless {}, 'Reader';

				# 1 - All the parameters are passed

    my $rep = new Mail::Abuse::Report (text		=> \ "Your text here",
				       config		=> $config,
				       reader 		=> $reader,
				       parsers		=> $parsers,
				       filters 		=> $filters,
				       processors	=> $processors,
				       );
    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Rr 0 Pp1 0 Fc1 0 Fc2 0 Pp2 0 Fc1 1 Fc2 1 Pp1 0 Pp2 0", 
       'Correct call sequence with all parameters');

    eval { is($ {$rep->text}, 
	      "This is the text that Reader::read inserted 0", 
	      "Proper text contents") };

    $log = '';

    $rep->next;

    is($log, " Rr 1 Pp1 1 Fc1 2 Fc2 2 Pp2 1 Fc1 3 Fc2 3 Pp1 1 Pp2 1", 
       'Correct call sequence with all parameters');

    eval { is($ {$rep->text}, 
	      "This is the text that Reader::read inserted 1", 
	      "Proper text contents on 2nd iter with all params") };

    $log = '';

				# 2 - Omit reader

    $rep = new Mail::Abuse::Report (text		=> \ "Your text here",
				    config		=> $config,
				    parsers		=> $parsers,
				    filters 		=> $filters,
				    processors	=> $processors,
				    );
    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Pp1 2 Fc1 4 Fc2 4 Pp2 2 Fc1 5 Fc2 5 Pp1 2 Pp2 2", 
       'Correct call sequence with no reader');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text contents with no reader") };

    $log = '';

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Pp1 3 Fc1 6 Fc2 6 Pp2 3 Fc1 7 Fc2 7 Pp1 3 Pp2 3", 
       'Correct call sequence with no reader on 2nd iter');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text contents with no reader on 2nd iter") };

    $log = '';

				# 3 - Omit parsers

    $rep = new Mail::Abuse::Report (text		=> \ "Your text here",
				    config		=> $config,
				    filters 		=> $filters,
				    processors	=> $processors,
				    );
    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Pp1 4 Pp2 4", 
       'Correct call sequence with no reader and no parsers');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text contents with no reader and no parsers") };

    $log = '';

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Pp1 5 Pp2 5", 
       'Correct call sequence with no reader and no parsers (2nd iter)');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text contents with no reader or parsers, 2nd iter") };

    $log = '';

				# 3 - Omit processors

    $rep = new Mail::Abuse::Report (text		=> \ "Your text here",
				    config		=> $config,
				    filters 		=> $filters,
				    );
    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;			# This fires up a lot of embedded tests

    is($log, "", 
       'Correct call sequence with no reader, parsers or processors');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text contents with no reader, parser or processors") };

    $log = '';

    $rep->next;			# This fires up a lot of embedded tests

    is($log, "", 
       'Correct call sequence with no reader, parser or processors (2nd)');

    eval { is($ {$rep->text}, 
	      "Your text here", 
	      "Proper text with no reader, parser or processors, (2)") };

    $log = '';

				# 4 - Omit filters

    $rep = new Mail::Abuse::Report (text		=> \ "Your text here",
				    config		=> $config,
				    reader 		=> $reader,
				    parsers		=> $parsers,
				    processors	=> $processors,
				    );
    isa_ok($rep, 'Mail::Abuse::Report');

    $rep->next;			# This fires up a lot of embedded tests

    is($log, " Rr 2 Pp1 4 Pp2 4 Pp1 6 Pp2 6", 
       'Correct call sequence with all parameters');

    eval { is($ {$rep->text}, 
	      "This is the text that Reader::read inserted 2", 
	      "Proper text contents without filters") };

    $log = '';

    $rep->next;

    is($log, " Rr 3 Pp1 5 Pp2 5 Pp1 7 Pp2 7", 
       'Correct call sequence without filters, 2nd iter');

    eval { is($ {$rep->text}, 
	      "This is the text that Reader::read inserted 3", 
	      "Proper text contents on 2nd iter without filters") };

    $log = '';

}







