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

use Test::More tests=>48;

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
my $fn = spew(newtempfn,"blah");
ok open($fh, '<', $fn), "3-arg open";
ok open($fh, '<:utf8', $fn), "3-arg open w/layer";  ## no critic (RequireEncodingWithUTF8Layer)
ok open($fh, "<$fn"), "2-arg open";  ## no critic (ProhibitTwoArgOpen)
like exception { open($fh) },  ## no critic (RequireCheckedOpen)
	qr/\bnot enough arguments\b/i, 'open not enough args';
close $fh;

ok my $fh2 = Tie::Handle::Base->new(), 'new'; # don't pass in a handle here
isa_ok tied(*$fh2), 'Tie::Handle::Base';
# NOTE that :raw does not quite work right on Perl <5.14, but it does work here
my $fn2 = spew(newtempfn,"Foo\n",':raw');
ok open($fh2,'>>:raw:crlf',$fn2), 'open 2' or die $!;
ok print($fh2 "Bar\n"), 'print 2';
ok close($fh2), 'close 3';
is slurp($fn2,':raw'), "Foo\nBar\x0D\x0A", 'check file';
untie(*$fh2);
ok !defined(tied(*$fh2)), 'untie';

{
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok grep( {/\btoo many arg/i}
		warns {
			Tie::Handle::Base->new(undef, 'bar');
		}), 'tiehandle too many args';
}

{
	package Tie::Handle::Unprintable;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	# we can't mock CORE::print, but we can use a tied handle to cause it to return false
	sub PRINT { return }
}
ok !print( {Tie::Handle::Base->new( Tie::Handle::Unprintable->new )} "Foo" ), 'print fails';

