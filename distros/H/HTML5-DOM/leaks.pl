#!/usr/bin/perl
use warnings;
use strict;
use File::Slurp qw|read_file write_file|;
use File::Basename qw|dirname|;
use POSIX;

for my $file (glob("t/*.t")) {
	my $text = read_file($file);
	
	if ($text =~ /<test-body>(.*?)<\/test-body>/sim) {
		print $file."\n";
		my $code = 
			'
				use warnings;
				use strict;
				use Test::LeakTrace;
				use HTML5::DOM;
				
				sub ok {
					print "ok - ".$_[1]."\n" if ($_[0]);
					print "not ok - ".$_[1]."\n" if (!$_[0]);
				};
				sub done_testing { };
				sub require_ok { };
				sub can_ok { };
				sub isa_ok { };
				
				no_leaks_ok {
					(sub {
						'.$1.';
						1;
					})->();
				};
			';
		eval($code);
		die "$@" if ($@);
	}
}
