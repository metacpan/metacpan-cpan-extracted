#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net)
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

use Test::More tests=>5;
use File::Replace;

## no critic (RequireCarping)

subtest 'basic test' => sub { plan tests=>7;
	my $fn = newtempfn(join('','a'..'z'),':raw');
	my $repl = File::Replace->new($fn);
	is $repl->copy(3), 3, 'copy 3';
	is $repl->copy(count=>3,bufsize=>3), 3, 'copy 3';
	print {$repl->out_fh} "1";
	is $repl->copy(count=>4,bufsize=>2), 4, 'copy 4';
	is $repl->copy(count=>8,bufsize=>3), 8, 'copy 8';
	print {$repl->out_fh} "234";
	is $repl->copy(count=>4,bufsize=>1), 4, 'copy 4';
	is $repl->copy(count=>6,less=>'ok'), 4, 'copy 6';
	$repl->finish;
	is slurp($fn,':raw'), 'abcdef1ghijklmnopqr234stuvwxyz', 'read back';
};

subtest 'utf8' => sub { plan tests=>2;
	my $fn = newtempfn("I\x{2764}\x{1f42a}",':utf8');
	my $repl = File::Replace->new($fn,':utf8');
	is $repl->copy(3), 3, 'copy 3';
	$repl->finish;
	is slurp($fn,':utf8'), "I\x{2764}\x{1f42a}", 'read back';
};

subtest 'less option' => sub { plan tests=>7;
	my $repl = File::Replace->new(newtempfn);
	use warnings FATAL=>'all';
	like exception { $repl->copy(3) },
		qr/\bread 3 less characters than requested\b/i, 'fatal warn';
	ok !grep( {/\bless characters than requested\b/i}
		warns { $repl->copy(3,less=>'ok') }), 'less=ok with fatal warn';
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\bread 3 less characters than requested\b/i}
		warns { is $repl->copy(3), 0, '0 chars' }), 'normal warning';
	ok !grep( {/\bless characters than requested\b/i}
		warns { $repl->copy(3,less=>'ok') }), 'less=ok';
	ok !grep( {/\bless characters than requested\b/i}
		warns { $repl->copy(3,less=>'ignore') }), 'less=ignore';
	no warnings; ## no critic (ProhibitNoWarnings)
	ok !grep( {/\bless characters than requested\b/i}
		warns { $repl->copy(3) }), 'no warnings';
	use warnings;
	$repl->cancel;
};

subtest 'various fails' => sub { plan tests=>3;
	like exception {
		my $repl = File::Replace->new(newtempfn("12345"),autocancel=>1);
		$repl->{ifh} = Tie::Handle::Unreadable->new($repl->{ifh});
		$repl->copy(5);
	}, qr/\bread failed\b/, 'read failed';
	like exception {
		my $repl = File::Replace->new(newtempfn("12345"),autocancel=>1);
		$repl->{ofh} = Tie::Handle::Unprintable->new($repl->{ofh});
		$repl->copy(5);
	}, qr/\bwrite failed\b/, 'write failed';
	like exception {
		my $repl = File::Replace->new(newtempfn);
		$repl->finish;
		$repl->copy(5);
	}, qr/\balready closed\b/, 'already closed';
};

subtest 'bad arguments' => sub { plan tests=>7;
	my $repl = File::Replace->new(newtempfn);
	like exception { $repl->copy(BadArg=>1) },
		qr/\bunknown option\b/i, 'unknown arg';
	like exception { $repl->copy(2,count=>3) },
		qr/\bcount specified twice\b/i, 'count twice';
	like exception { $repl->copy(count=>'a') },
		qr/\bbad count\b/i, 'bad count arg 1';
	like exception { $repl->copy(count=>undef) },
		qr/\bbad count\b/i, 'bad count arg 2';
	like exception { $repl->copy(4,bufsize=>'b') },
		qr/\bbad bufsize\b/i, 'bad bufsize arg 1';
	like exception { local $File::Replace::COPY_DEFAULT_BUFSIZE=undef; $repl->copy(5,bufsize=>undef) },
		qr/\bbad bufsize\b/i, 'bad bufsize arg 2';
	like exception { $repl->copy(5,less=>'x') },
		qr/\bbad less\b/i, 'bad less arg';
	$repl->cancel;
};

