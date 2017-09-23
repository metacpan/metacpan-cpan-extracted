#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

=head1 Author, Copyright, and License

Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use File_Replace_Testlib;

use Test::More tests=>8;

## no critic (RequireCarping)

BEGIN {
	use_ok 'File::Replace::SingleHandle';
	use_ok 'File::Replace', 'replace2';
}

subtest 'two SingleHandles (in/out)' => sub { plan tests=>8;
	my $fn = spew(newtempfn,"Foo\nBar\nQuz\n");
	my ($ifh,$ofh) = replace2($fn);
	isa_ok tied(*$ifh)->replace, 'File::Replace';
	is tied(*$ifh)->replace, tied(*$ofh)->replace, 'same replace object';
	ok tied(*$ifh)->out_fh, 'out_fh accessor';
	ok tied(*$ofh)->in_fh, 'in_fh accessor';
	is slurp($fn), "Foo\nBar\nQuz\n", 'before loop';
	while (<$ifh>) {
		tr/aeiou/12345/;
		print $ofh $_;
	}
	is slurp($fn), "Foo\nBar\nQuz\n", 'after loop';
	close $ifh;
	is slurp($fn), "Foo\nBar\nQuz\n", 'after close ifh';
	close $ofh;
	is slurp($fn), "F44\nB1r\nQ5z\n", 'after close ofh';
};

subtest 'reverse close order' => sub { plan tests=>3;
	my $fn = spew(newtempfn,"Hello,\nWorld!");
	my ($ifh,$ofh) = replace2($fn);
	while (<$ifh>) {
		tr/ol/ui/;
		print $ofh $_;
	}
	is slurp($fn), "Hello,\nWorld!", 'after loop';
	close $ofh;
	is slurp($fn), "Hello,\nWorld!", 'after close ofh';
	close $ifh;
	is slurp($fn), "Heiiu,\nWurid!", 'after close ifh';
};

subtest 'close and discard reference' => sub { plan tests=>3;
	my $fn = spew(newtempfn,"Foo\nBar\n");
	my ($ifh,$ofh) = replace2($fn);
	while (<$ifh>) {
		chomp;
		print $ofh reverse."\n";
	}
	is slurp($fn), "Foo\nBar\n", 'after loop';
	close $ofh;
	$ofh = undef;
	is slurp($fn), "Foo\nBar\n", 'after close ofh';
	close $ifh;
	is slurp($fn), "ooF\nraB\n", 'after close ifh';
};

subtest 'one SingleHandle (out)' => sub { plan tests=>2;
	my $fn = spew(newtempfn,"Blah\nBlah\n");
	my $ofh = replace2($fn);
	print $ofh "Hi\nthere";
	is slurp($fn), "Blah\nBlah\n", 'after print';
	close $ofh;
	is slurp($fn), "Hi\nthere", 'after close';
};

subtest 'autocancel, autofinish' => sub { plan tests=>8;
	ok !grep( {/\bunclosed file\b/i}
		warns {
			my $fn = spew(newtempfn, "xxxxx\n");
			my ($ifh,$ofh) = replace2($fn, autocancel=>1);
			print $ofh "yyyyyyyy\n";
			is slurp($fn), "xxxxx\n", 'original unchanged';
			$ifh = undef;
			is slurp($fn), "xxxxx\n", 'original still unchanged';
			$ofh = undef;
			is slurp($fn), "xxxxx\n", 'unchanged after autocancel';
		}), 'no warn with autocancel';
	ok !grep( {/\bunclosed file\b/i}
		warns {
			my $fn = spew(newtempfn, "xxxxx\n");
			my ($ifh,$ofh) = replace2($fn, autofinish=>1);
			print $ofh "yyyyyyyy\n";
			is slurp($fn), "xxxxx\n", 'original unchanged';
			$ifh = undef;
			is slurp($fn), "xxxxx\n", 'original still unchanged';
			$ofh = undef;
			is slurp($fn), "yyyyyyyy\n", 'original replaced after autofinish';
		}), 'no warn with autocancel';
};

subtest 'warnings and errors' => sub { plan tests=>10;
	like exception { my ($r) = replace2() },
		qr/\bnot enough arguments\b/i, 'replace2 not enough args';
	like exception { my ($r) = replace2("somefn",BadArg=>"boom") },
		qr/\bunknown option\b/i, 'replace2 bad args';
	
	like exception {
		File::Replace::SingleHandle->new(qw/too many args/);
	}, qr/\bbad\b.+\bargs\b/i, 'tie SingleHandle bad nr of args';
	like exception {
		File::Replace::SingleHandle->new('blah', 'blub');
	}, qr/\bFile::Replace object\b/, 'tie SingleHandle not blessed';
	like exception {
		File::Replace::SingleHandle->new(bless({},'SomeClass'), 'blub');
	}, qr/\bFile::Replace object\b/, 'tie SingleHandle wrong class';
	like exception {
		File::Replace::SingleHandle->new(bless({},'File::Replace'), 'blub');
	}, qr/\bbad mode\b/, 'tie SingleHandle bad mode';
	
	like exception {
		my ($i,$o) = replace2(newtempfn);
		tied(*$i)->replace->finish;
		open $i, '<', 'somefn';  ## no critic (RequireBriefOpen, RequireCheckedOpen)
	}, qr/\bcan't reopen\b/i, 'open fails';
	
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\buseless\b.+\bvoid\b\s+\bcontext\b/i}
		warns { replace2(newtempfn); 1 } ),
			'replace2 in void ctx';
	is grep( {/\bplease don't untie\b/i}
		warns {
			my ($i,$o) = replace2(newtempfn);
			tied(*$i)->replace->finish;
			untie *$i;
			untie *$o;
		}), 2, 'dont untie';
	is grep( {/\bunclosed file\b.+\bnot replaced\b/i}
		warns {
			do {
				my ($i,$o) = replace2(newtempfn);
				1; # so objects don't get returned from do
			};
			do {
				my ($i,$o) = replace2(newtempfn);
				# close and destroy one of the handles
				close $o;
				$o = undef;
				1; # so objects don't get returned from do
			};
			do {
				my $o = replace2(newtempfn);
				1; # so object doesn't get returned from do
			};
		}), 3, 'unclosed file';
	
};

