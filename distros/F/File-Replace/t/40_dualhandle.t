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

use Test::More tests=>6;

## no critic (RequireCarping, RequireBriefOpen, ProhibitMixedBooleanOperators)

BEGIN {
	use_ok 'File::Replace::DualHandle';
	use_ok 'File::Replace', 'replace';
}

my $fn = newtempfn;
{
	open my $tfh, '>', $fn or die $!;
	# workaround for :raw not working properly in Perl <5.14
	binmode $tfh;
	binmode $tfh, ':utf8';  ## no critic (RequireEncodingWithUTF8Layer)
	print $tfh "HelloFoo\n\x{20AC}Bar\nX\nY\n";
	close $tfh;
}

subtest 'tiehandle methods' => sub { plan tests=>29;
	my $fh = replace($fn);
	isa_ok tied(*$fh)->replace, 'File::Replace';
	ok binmode($fh), 'binmode 0';
	# reading
	is read($fh, my $rbuf0, 5, 2), 5, 'read len 5';
	is $rbuf0, "\0\0Hello", 'read buf';
	is read($fh, my $rbuf1, 1), 1, 'read len 1';
	is $rbuf1, 'F', 'read char';
	is getc($fh), 'o', 'getc';
	ok !eof($fh), 'eof 1';
	ok seek($fh,-1,1), 'seek';
	is readline($fh), "oo\n", 'readline 1';
	is tell($fh), 9, 'tell';
	ok !grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh)->in_fh ) ), 'in isnt utf8'
		or diag explain [PerlIO::get_layers( tied(*$fh)->in_fh )];
	ok !grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh)->out_fh ) ), 'out isnt utf8'
		or diag explain [PerlIO::get_layers( tied(*$fh)->out_fh )];
	ok binmode($fh, ':utf8'), 'binmode 1';  ## no critic (RequireEncodingWithUTF8Layer)
	ok grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh)->in_fh ) ), 'in has utf8'
		or diag explain [PerlIO::get_layers( tied(*$fh)->in_fh )];
	ok grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh)->out_fh ) ), 'out has utf8'
		or diag explain [PerlIO::get_layers( tied(*$fh)->out_fh )];
	is scalar(<$fh>), "\x{20AC}Bar\n", 'readline 2';
	is_deeply [<$fh>], ["X\n","Y\n"], 'readline 3';
	ok eof($fh), 'eof 2';
	# writing
	ok print( {$fh} "Hello\n" ), 'print';
	ok printf( {$fh} '%3s%.2f', "Wo", 123 ), 'printf';
	ok binmode($fh), 'binmode 2';
	is syswrite($fh,"ld!!",3), 3, 'write 1';
	is syswrite($fh,"\n"), 1, 'write 2';
	is syswrite($fh,"Quz\n",3,1), 3, 'write 3';
	is fileno($fh),-1,'fileno open';
	ok close($fh), 'close';
	ok !defined(fileno($fh)),'fileno closed';
	is slurp($fn), "Hello\n Wo123.00ld!\nuz\n", 'file after editing';
};

subtest 'mode, reopening, etc.' => sub { plan tests=>12;
	my $fn2 = newtempfn("B\x{20AC}ep\n", ':utf8');
	my $fh2 = replace($fn);
	close $fh2;
	open $fh2, ':utf8', $fn2 or die $!;  ## no critic (RequireEncodingWithUTF8Layer)
	is <$fh2>, "B\x{20AC}ep\n", 'reopen';
	print $fh2 "Hi \x{263A}";
	close $fh2;
	is slurp($fn2, ':utf8'), "Hi \x{263A}", 'before reopen';
	ok open( $fh2, newtempfn("Foo") ), '2-arg open';  ## no critic (ProhibitTwoArgOpen)
	is <$fh2>, "Foo", '2-arg open read';
	close $fh2;
	is slurp($fn2,':utf8'), "Hi \x{263A}", 'after reopen';
	# reopen shouldn't cause the same layers to be used
	my $fh3 = replace($fn, ':utf8', autocancel=>1);
	ok  grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh3)->in_fh  ) ), 'in has utf8';
	ok  grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh3)->out_fh ) ), 'out has utf8';
	ok open( $fh3, $fn2 ), 'reopen w/o layers';  ## no critic (ProhibitTwoArgOpen)
	ok !grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh3)->in_fh  ) ), 'in isnt utf8';
	ok !grep( {$_ eq 'utf8'} PerlIO::get_layers( tied(*$fh3)->out_fh ) ), 'out isnt utf8';
	# check against Perl's own behavior
	open my $fh4, '<:utf8', $fn or die $!;  ## no critic (RequireEncodingWithUTF8Layer)
	ok  grep( {$_ eq 'utf8'} PerlIO::get_layers( $fh4 ) ), 'has utf8';
	open $fh4, $fn2 or die $!;  ## no critic (ProhibitTwoArgOpen)
	ok !grep( {$_ eq 'utf8'} PerlIO::get_layers( $fh4 ) ), 'isnt utf8';
};

subtest 'autocancel, autofinish' => sub { plan tests=>6;
	ok !grep( {/\bunclosed file\b/i}
		warns {
			my $fn2 = newtempfn("aaaa\n");
			my $fh = replace($fn2, autocancel=>1);
			print $fh "bbbbbb\n";
			is slurp($fn2), "aaaa\n", 'original unchanged';
			$fh = undef;
			is slurp($fn2), "aaaa\n", 'unchanged after autocancel';
		}), 'no warn with autocancel';
	ok !grep( {/\bunclosed file\b/i}
		warns {
			my $fn2 = newtempfn("12345\n");
			my $fh = replace($fn2, autofinish=>1);
			print $fh "678\n";
			is slurp($fn2), "12345\n", 'original unchanged';
			$fh = undef;
			is slurp($fn2), "678\n", 'original replaced after autofinish';
		}), 'no warn with autofinish';
};

subtest 'warnings and exceptions' => sub { plan tests=>31;
	like exception { my $r = replace() },
		qr/\bnot enough arguments\b/i, 'replace not enough args';
	like exception { my $r = replace("somefn",BadArg=>"boom") },
		qr/\bunknown option\b/i, 'replace bad args';
	
	{
		my $fh = replace(newtempfn(""));
		like exception { open $fh, '>bad2argopen' },  ## no critic (ProhibitTwoArgOpen, RequireCheckedOpen)
			qr/\bopen mode\b/i, 'bad 2 arg reopen';
		like exception { open $fh, '>', 'badmode' },  ## no critic (RequireCheckedOpen)
			qr/\bopen mode\b/i, 'bad 3 arg reopen';
		like exception { open $fh },  ## no critic (RequireCheckedOpen)
			qr/\b3-arg open\b/i, 'not enough args to open';
		like exception { open $fh, '', 'badargs', 'foo' },  ## no critic (RequireCheckedOpen)
			qr/\b3-arg open\b/i, 'too many args to open';
		close $fh;
	}
	
	like exception {
		File::Replace::DualHandle->new(qw/toomany args/);
	}, qr/\bbad\b.+\bargs\b/i, 'tie DualHandle bad nr of args';
	like exception {
		File::Replace::DualHandle->new('blah');
	}, qr/\bFile::Replace object\b/, 'tie DualHandle not blessed';
	like exception {
		File::Replace::DualHandle->new(bless {}, 'SomeClass');
	}, qr/\bFile::Replace object\b/, 'tie DualHandle wrong class';
	{
		my $fh = replace(newtempfn, autocancel=>1);
		tied(*$fh)->{repl}{ifh} = Tie::Handle::MockBinmode->new(tied(*$fh)->{repl}{ifh}, 0, 0, 1, 1, 0, 0, 1, 1);
		tied(*$fh)->{repl}{ofh} = Tie::Handle::MockBinmode->new(tied(*$fh)->{repl}{ofh},       0, 1,       0, 1);
		is binmode($fh), 0, 'binmode 00';
		is binmode($fh), 0, 'binmode 01';
		is binmode($fh), 0, 'binmode 10';
		is binmode($fh), 1, 'binmode 11';
		is binmode($fh,':raw'), 0, 'binmode w/l 00';
		is binmode($fh,':raw'), 0, 'binmode w/l 01';
		is binmode($fh,':raw'), 0, 'binmode w/l 10';
		is binmode($fh,':raw'), 1, 'binmode w/l 11';
		ok tied( *{tied(*$fh)->{repl}{ifh}} )->endmock, 'all ifh mocks used up';
		ok tied( *{tied(*$fh)->{repl}{ofh}} )->endmock, 'all ofh mocks used up';
	}
	like exception {
		my $fh = replace(newtempfn);
		Tie::Handle::Unclosable->install( $fh, 'ifh' );
		close $fh;
	}, qr/\bcouldn't close input handle\b/, 'close can die 1';
	like exception {
		my $fh = replace(newtempfn);
		Tie::Handle::Unclosable->install( $fh, 'ofh' );
		close $fh;
	}, qr/\bcouldn't close output handle\b/, 'close can die 2';
	
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\buseless\b.+\bvoid\b\s+\bcontext\b/i}
		warns { replace(newtempfn); 1; }), 'replace in void ctx';
	ok grep( {/\bplease don't untie\b/i}
		warns {
			my $h = replace(newtempfn);
			tied(*$h)->replace->finish;
			untie *$h;
		}), 'dont untie';
	ok grep( {/\bunclosed file\b.+\bnot replaced\b/i}
		warns {
			do {
				my $o = replace(newtempfn);
				1; # so object doesn't get returned from do
			}
		}), 'unclosed file';
	is grep( {/\bunclosed file\b.+\bnot replaced\b/i}
		warns {
			my $fn1 = newtempfn("First");
			my $fh = replace($fn1);
			print $fh "Second";
			my $fn2 = newtempfn("Third");
			open $fh, '', $fn2 or die $!;
			print $fh "Fourth";
			is slurp($fn1), "First", 'not replaced after re-open';
			is slurp($fn2), "Third", 'not yet replaced';
			close $fh;
			is slurp($fn1), "First", 'still not replaced';
			is slurp($fn2), "Fourth", 'is now replaced';
		}), 1, 'reopen causes unclosed file';
	is grep( {/\balready closed\b/}
		warns {
			my $fh = replace(newtempfn(""));
			close $fh;
			# note we know what a failed close returns from the tests
			# for Tie::Handle::Base
			is_deeply [close $fh], [!1], 'close fails';
		}), 1, 'already closed warns';
	
};

