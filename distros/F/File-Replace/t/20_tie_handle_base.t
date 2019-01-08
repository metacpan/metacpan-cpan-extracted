#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module Tie::Handle::Base.

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

use Test::More tests=>55;

use Encode qw/encode/;

BEGIN { use_ok('Tie::Handle::Base') }

## no critic (RequireCarping, RequireBriefOpen)

ok open(my $innerfh, '+<', \(my $x="Foo\n")), 'open inner'
	or die $!;
my $fh = \do{local*HANDLE;*HANDLE};  ## no critic (RequireInitializationForLocalVars)
isa_ok tie(*$fh, 'Tie::Handle::Base', $innerfh),
	'Tie::Handle::Base', 'tie';
is tied(*$fh)->innerhandle, $innerfh, 'innerhandle';
ok !eof($fh), 'eof 1';
is ''.<$fh>, "Foo\n", 'readline <>';
is $., 1, '$. 1';
is tell($fh), 4, 'tell';
ok eof($fh), 'eof 2';
ok print($fh "Bar\n"), 'print';
is syswrite($fh," Quz\n ",4,1), 4, 'syswrite';
ok printf($fh "%4s", "Baz"), 'printf';
ok seek($fh,0,0), 'seek';
is tell($fh),0, 'tell after seek';
is read($fh,my $buf,4,1), 4, 'read';
is $buf, "\0Foo\n", 'read buf';
is sysread($fh,$buf,3), 3, 'sysread';
is $buf, "Bar", 'sysread buf';
is getc($fh), "\n", 'getc';
is_deeply [readline($fh)], ["Quz\n"," Baz"], 'readline';
is $., 3, '$. 2';
is fileno($fh), fileno($innerfh), 'fileno';
ok close($fh), 'close';
ok !defined(fileno($innerfh)), 'closed fileno';
is $x, "Foo\nBar\nQuz\n Baz", 'scalar file';

ok open($fh, '+<', \$x), 'open' or die $!;
ok defined(fileno($innerfh)), 'inner fileno after open';
{
	my $prev = select($fh);  ## no critic (ProhibitOneArgSelect)
	local $_ = 'oof';
	ok print(), 'implicit print $fh $_';
	local ($,,$",$\) = ("X","=","-");
	my @x = ("Bar","Quz");
	ok print("@x","Baz"), '$, $" $\ ';
	select($prev);  ## no critic (ProhibitOneArgSelect)
}
ok open($fh, '>', \(my $y)), 'reopen' or die $!;
is $x, "oofBar=QuzXBaz-z", 'scalar file 2';
ok binmode($fh), 'binmode';
ok !grep( {$_ eq 'utf8'} PerlIO::get_layers($innerfh) ), 'no utf8';
ok binmode($fh,':utf8'), 'binmode utf8';  ## no critic (RequireEncodingWithUTF8Layer)
ok  grep( {$_ eq 'utf8'} PerlIO::get_layers($innerfh) ), 'has utf8';
my $str = "3\x{20AC}";
print $fh $str;
ok close($fh), 'close 2';
is $y, encode('UTF-8',$str,Encode::FB_CROAK), 'scalar file 3';

# test a few variations of open
my $fn = newtempfn("blah");
ok open($fh, '<', $fn), "3-arg open";
ok open($fh, '<:utf8', $fn), "3-arg open w/layer";  ## no critic (RequireEncodingWithUTF8Layer)
ok open($fh, "<$fn"), "2-arg open";  ## no critic (ProhibitTwoArgOpen)
close $fh;
# open: "As a shortcut a one-argument call takes the filename from the
# global scalar variable of the same name as the filehandle".
our $TESTFILE = $fn;
*SOMEHANDLE = Tie::Handle::Base->new(*TESTFILE);
ok open(SOMEHANDLE), '1-arg open';  ## no critic (ProhibitBarewordFileHandles)
is <SOMEHANDLE>, "blah", '1-arg open read';
close SOMEHANDLE;

ok my $fh2 = Tie::Handle::Base->new(), 'new'; # don't pass in a handle here
isa_ok tied(*$fh2), 'Tie::Handle::Base';
# NOTE that :raw does not quite work right on Perl <5.14, but it does work here
my $fn2 = newtempfn("Foo\n",':raw');
ok open($fh2,'>>:raw:crlf',$fn2), 'open 2' or die $!;
ok print($fh2 "Bar\n"), 'print 2';
ok close($fh2), 'close 3';
is slurp($fn2,':raw'), "Foo\nBar\x0D\x0A", 'check file';
untie(*$fh2);
ok !defined(tied(*$fh2)), 'untie';

subtest 'return values' => sub {
	my $s1 = "Hello";
	my $s2 = "\x{2764}\x{1F42A}";
	ok open(my $ofh, '+<:raw', newtempfn("")), 'open orig';
	ok open(my $tfh, '+<:raw', newtempfn("")), 'open tied';
	$tfh = Tie::Handle::Base->new($tfh);
	is syswrite($tfh,$s1), syswrite($ofh,$s1), 'syswrite matches';
	# "sysread(), recv(), syswrite() and send() operators
	# are deprecated on handles that have the :utf8 layer"
	my $s2e = encode('UTF-8',my $temp=$s2,Encode::FB_CROAK);
	is syswrite($tfh,$s2e), syswrite($ofh,$s2e), 'syswrite enc matches';
	# print only "Returns true if successful." (and printf is "equivalent" to print),
	# so in our tests we don't care what that true value is.
	ok print($ofh "abc"), 'print orig true';
	ok print($tfh "abc"), 'print tied true';
	ok printf($ofh "%c%s",100,"ef"), 'printf orig true';
	ok printf($tfh "%c%s",100,"ef"), 'printf tied true';
	# check this case, since WRITE will return a length of 0 (false)
	ok print($ofh ""), 'print empty orig true';
	ok print($tfh ""), 'print empty tied true';
	ok printf($ofh ""), 'printf empty orig true';
	ok printf($tfh ""), 'printf empty tied true';
	# now read back
	ok seek($ofh,0,0), 'seek orig';
	ok seek($tfh,0,0), 'seek tied';
	is sysread($tfh,my $rt1,length($s1)), sysread($ofh,my $ro1,length($s1)), 'sysread matches';
	is $ro1, $s1, 'sysread orig';
	is $rt1, $s1, 'sysread tied';
	ok binmode($ofh,':encoding(UTF-8)'), 'binmode orig';
	ok binmode($tfh,':encoding(UTF-8)'), 'binmode tied';
	is read($tfh,my $rt2,length($s2)+6), read($ofh,my $ro2,length($s2)+6), 'read matches';
	is $ro2, $s2."abcdef", 'read orig';
	is $rt2, $s2."abcdef", 'read tied';
	ok eof($ofh), 'eof orig';
	ok eof($tfh), 'eof tied';
	ok close($ofh), 'close orig';
	ok close($tfh), 'close tied';
	# check what our three emulated functions return on failure
	# (read and sysread return the same values on errors, and we pass both
	# of those through to read, so we don't need to check them)
	is grep({/\bon closed filehandle\b/} warns {
		no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
		is_deeply [syswrite($ofh,$s1)], [undef], 'syswrite fail returns undef';
		is_deeply [syswrite($tfh,$s1)], [syswrite($ofh,$s1)], 'syswrite fail matches';
		is_deeply [print($ofh "abc")], [undef], 'print fail returns undef';
		is_deeply [print($tfh "abc")], [print($ofh "abc")], 'print fail matches';
		is_deeply [printf($ofh "%s","def")], [undef], 'printf fail returns undef';
		is_deeply [printf($tfh "%s","def")], [printf($ofh "%s","def")], 'printf fail matches';
	}), 9, 'warns about closed fh';
	# for completeness, confirm what close returns
	is_deeply [close $ofh], [!1], 'close orig fail';
	is_deeply [close $tfh], [close $ofh], 'close fail matches';
};

subtest 'open_parse' => sub {
	my @tests = ( # various examples from perldoc -f open
		[' < input.txt ', "<", "input.txt"],
		[' > output.txt ', ">", "output.txt"],
		[' >> /usr/spool/news/twitlog ', ">>", "/usr/spool/news/twitlog"],
		["+<dbase.mine", "+<", "dbase.mine"],
		["caesar <\$article |", "-|", "caesar <\$article"],
		[">&STDOUT", ">&", 'STDOUT'],
		["<&=\$fd", "<&=", "\$fd"],
		[">>&=\$B", '>>&=', "\$B"],
		["|tr '[a-z]' '[A-Z]'", "|-", "tr '[a-z]' '[A-Z]'"],
		["cat -n '\$file'|", "-|", "cat -n '\$file'"],
		["rsh cat file |", '-|', 'rsh cat file'],
		[" foo ", "<", "foo"],
	);
	plan tests => 3+@tests;
	for my $i (0..$#tests) {
		my $in = shift @{$tests[$i]};
		is_deeply [Tie::Handle::Base::open_parse($in)], $tests[$i], "'$in'";
	}
	is grep({/\btoo many arguments to open_parse\b/} warns {
		is_deeply [Tie::Handle::Base::open_parse(' x ',' y ',' z ')], [' x ',' y '], 'passthru';
	}), 1, 'warns about too many args';
	like exception { Tie::Handle::Base::open_parse() },
		qr/\bnot enough arguments to open_parse\b/i, 'not enough args';
};

{
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\btoo many arg/i}
		warns {
			Tie::Handle::Base->new(undef, 'bar');
		}), 'tiehandle too many args';
}

ok !print( {Tie::Handle::Base->new( Tie::Handle::Unprintable->new )} "Foo" ), 'print fails';

{ # mostly for code coverage
	open my $hnd, '>', \(my $foo) or die $!;
	bless $hnd, 'SomeClass';
	ok Tie::Handle::Base::inner_write($hnd,"Foo"), 'inner_write';
	close $hnd;
	is $foo, "Foo", 'inner_write data';
}

