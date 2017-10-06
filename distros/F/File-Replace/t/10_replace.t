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
use File::Temp qw/tempfile/;

## no critic (RequireCarping)

BEGIN { use_ok 'File::Replace' }

subtest 'basic test' => sub { plan tests=>7;
	my $fn = newtempfn("Hello,\n");
	my $r = File::Replace->new($fn);
	isa_ok $r, 'File::Replace';
	my $line = readline($r->in_fh);
	is $line, "Hello,\n", 'readline';
	ok eof($r->in_fh), 'eof';
	is slurp($fn), "Hello,\n", 'before write';
	print {$r->out_fh} "World!";
	is slurp($fn), "Hello,\n", 'after write';
	is $r->filename, $fn, 'filename';
	$r->finish;
	is slurp($fn), "World!", 'after finish';
};

subtest 'debug' => sub { plan tests=>5;
	note "Expect some debug output here:";
	my $db = Test::More->builder->output;
	ok( File::Replace->new(newtempfn, debug=>$db)->finish, 'debug' );
	ok( File::Replace->new(newtempfn,':utf8', debug=>$db)->finish, 'debug w/layers' );
	ok 2 <= warns { # this "warns" is also just to hide the warning output from the user
		# author tests make warnings fatal, disable that here
		no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
		my $repl1 = File::Replace->new(newtempfn, debug=>$db);
		ok( $repl1->cancel, 'debug cancel' );
		ok( !$repl1->cancel, 'debug cancel fail' );
		local *STDERR = $db;
		my $repl2 = File::Replace->new(newtempfn, debug=>1);
		$repl2 = undef;
		1; # don't return anything from this block
	}, 'captured at least two warnings';
};

subtest 'options' => sub { plan tests=>3;
	my $r = File::Replace->new(newtempfn(""), create=>'off', perms=>oct('640'));
	# chmod is a default option that we don't change
	# create is a default option that we do change
	# perms is not a default option that we explicitly set
	my $exp = { chmod=>!$File::Replace::DISABLE_CHMOD, create=>'off', perms=>oct('640') };
	is_deeply scalar($r->options), $exp, 'scalar opts';
	is_deeply {$r->options}, $exp, 'list opts';
	$r->finish;
	# default options only
	my $r2 = File::Replace->new(newtempfn(""));
	# note this *shouldn't* include perms
	is_deeply scalar($r2->options), { chmod=>!$File::Replace::DISABLE_CHMOD,
		create=>'later' }, 'default opts';
	$r2->finish;
};

subtest 'layers' => sub { plan tests=>2;
	{
		my $fn = newtempfn("Foo\x{20AC}\n",':utf8');
		my $r = File::Replace->new($fn,':utf8');
		is ''.readline($r->in_fh), "Foo\x{20AC}\n", 'read utf8';
		$r->finish;
	}
	{
		my $fn = newtempfn;
		my $r = File::Replace->new($fn,':crlf');
		print {$r->out_fh} "Foo\nBar\n";
		$r->finish;
		# NOTE that :raw does not quite work right on Perl <5.14, but it does work here
		is slurp($fn,':raw'), "Foo\x0D\x0ABar\x0D\x0A", 'write crlf';
	}
};

subtest 'in_fh' => sub { plan tests=>7;
	my ($tfh,$tfn) = tempfile(DIR=>$TEMPDIR,UNLINK=>1);
	print $tfh "Hello,\nWorld!\n";
	ok seek($tfh, 0, 0), 'seek';
	my $repl = File::Replace->new($tfn, in_fh=>$tfh);
	is readline($repl->in_fh), "Hello,\n", 'readline 1';
	is readline($repl->in_fh), "World!\n", 'readline 2';
	ok eof($repl->in_fh), 'eof';
	print {$repl->out_fh} "Replaced";
	$repl->finish;
	is slurp($tfn), "Replaced", 'file contents';
	# test closed in_fh
	like exception {
		my ($tfh2,$tfn2) = tempfile(DIR=>$TEMPDIR,UNLINK=>1);
		close $tfh2;
		my $replx = File::Replace->new($tfn2, in_fh=>$tfh2);
	}, qr/\bin_fh\b.+\bclosed\b/, 'closed in_fh';
	# test stat failure
	my $tiedfh = Tie::Handle::FakeFileno->new;
	like exception {
		# force chmod to be on in case $DISABLE_CHMOD is set
		my $repl0 = File::Replace->new($tfn, chmod=>1, in_fh=>$tiedfh);
	}, qr/\bstat\s+failed\b/, 'stat fails';
	# these shouldn't fail, since they shouldn't try to stat
	my $repl1 = File::Replace->new($tfn, in_fh=>$tiedfh, chmod=>0);
	my $repl2 = File::Replace->new($tfn, in_fh=>$tiedfh, perms=>oct('600'));
	$repl1->finish;
	$repl2->finish;
};

subtest 'unclosed file, cancel, autocancel, autofinish' => sub { plan tests=>13;
	ok grep( {/\bunclosed file\b.+\bnot replaced\b/i}
		warns {
			my $dummy = do { # so object gets destroyed when this scope exits
				my $r = File::Replace->new(newtempfn);
				1; # otherwise the object gets returned from do{}
			};
		}), 'warning';
	ok !grep( {/\bunclosed file\b/i} warns {
		{
			my $fn = newtempfn("Alpha\n");
			my $r = File::Replace->new($fn);
			print {$r->out_fh} "Beta\n";
			is slurp($fn), "Alpha\n", 'original unchanged';
			ok $r->cancel, 'cancel returns true';
			is slurp($fn), "Alpha\n", 'unchanged after cancel';
			$r = undef;
			is slurp($fn), "Alpha\n", 'still unchanged';
		}
		{
			my $fn = newtempfn("Gamma\n");
			my $r = File::Replace->new($fn, autocancel=>1);
			print {$r->out_fh} "Delta\n";
			is slurp($fn), "Gamma\n", 'original unchanged';
			$r = undef;
			is slurp($fn), "Gamma\n", 'unchanged after autocancel';
		}
		{
			my $fn = newtempfn("Epsilon\n");
			my $r = File::Replace->new($fn, autofinish=>1);
			print {$r->out_fh} "Zeta\n";
			is slurp($fn), "Epsilon\n", 'original unchanged';
			$r = undef;
			is slurp($fn), "Zeta\n", 'original replaced after autofinish';
		}
		{
			my $fn = newtempfn("Blam\n");
			like exception {
				my $r = File::Replace->new($fn, autofinish=>1);
				my $infh = $r->in_fh;
				while (<$infh>) {
					print {$r->out_fh} "Okay\n";
					is slurp($fn), "Blam\n", 'original unchanged';
					die $_ if /B/;
				}
				$r->cancel; # unreachable
			}, qr/\bBlam\b/, 'exception happens';
			is slurp($fn), "Okay\n", 'original replaced after autofinish+die';
		}
	}), 'no warnings about unclosed files';
};

subtest 'misc failures' => sub { plan tests=>13;
	like exception { my $r = File::Replace->new() },
		qr/\bnot enough arguments\b/i, 'not enough args';
	like exception { my $r = File::Replace->new(newtempfn,BadArg=>1) },
		qr/\bunknown option\b/i, 'bad args';
	like exception { my $r = File::Replace->new("somefn",":utf8",layers=>":utf8") },
		qr/\blayers\b.+\btwice\b/i, 'layers twice';
	like exception { my $r = File::Replace->new("blah",autocancel=>1,autofinish=>1) },
		qr/\bautocancel\b.+\bautofinish\b/, 'autocancel+autofinish fails';
	
	like exception {
			Tie::Handle::Unclosable->install( File::Replace->new(newtempfn), 'ifh' )->finish;
		}, qr/\bcouldn't close input handle\b/, 'finish close input handle failing';
	like exception {
			Tie::Handle::Unclosable->install( File::Replace->new(newtempfn), 'ofh' )->finish;
		}, qr/\bcouldn't close output handle\b/, 'finish close output handle failing';
	ok !Tie::Handle::Unclosable->install( File::Replace->new(newtempfn), 'ifh' )->_cancel(''),
		'cancel close input handle failing';
	ok !Tie::Handle::Unclosable->install( File::Replace->new(newtempfn), 'ofh' )->_cancel(''),
		'cancel close output handle failing';
	{
		my $r = File::Replace->new(newtempfn);
		close $r->in_fh;
		Tie::Handle::Unclosable->install( $r, 'ifh' );
		ok !$r->cancel, 'cancel close input handle already closed';
	}
	
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\buseless\b.+\bvoid\b\s+\bcontext\b/i}
		warns { File::Replace->new(newtempfn); 1 }), 'new in void ctx';
	ok grep({/\btoo many arg/i}
		warns { File::Replace->new(newtempfn)->finish("blah") }
			), 'finish too many args';
	ok grep({/\balready closed\b/i}
		warns { my $r=File::Replace->new(newtempfn); $r->finish; $r->finish }
			), 'finish twice';
	ok grep( {/\balready closed\b/i}
		warns {
			my $r=File::Replace->new(newtempfn);
			$r->cancel; $r->cancel;
		} ), 'cancel twice warning';
	
};

