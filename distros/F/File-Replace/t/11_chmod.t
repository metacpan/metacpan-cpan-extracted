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

use Test::More $File::Replace::DISABLE_CHMOD
	? (skip_all=>'$File::Replace::DISABLE_CHMOD is set')
	: (tests=>3);

use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;
use File::stat;
use Fcntl qw/S_IMODE/;

## no critic (RequireCarping, RequireArgUnpacking)

BEGIN { use_ok 'File::Replace' }

sub checked_chmod {
	@_==2 or die "checked_chmod bad arg cnt";
	my ($modestr,$file) = @_;
	ok chmod(oct($modestr),$file), "chmod $modestr $file";
	is S_IMODE(stat($file)->mode), oct($modestr), "check $modestr $file";
	return 1;
}

sub check_mode {
	@_==2 or die "check_mode bad arg cnt";
	my ($modestr,$file) = @_;
	return is S_IMODE(stat($file)->mode), oct($modestr), "check $modestr $file";
}

# See if we can discern the modes 600 and 640 on this system
my $cant_chmod_modes = sub {
	my $testfn = spew(newtempfn, "XYZ");
	if (!chmod(oct('600'), $testfn)) { return "can't chmod b/c chmod 1 failed" }
	my $perms1 = S_IMODE(stat($testfn)->mode);
	if ( $perms1!=oct('600') ) { return "can't chmod b/c 1st perms are ".sprintf('%05o',$perms1) }
	if (!chmod(oct('640'), $testfn)) { return "can't chmod b/c chmod 2 failed" }
	my $perms2 = S_IMODE(stat($testfn)->mode);
	if ( $perms2!=oct('640') ) { return "can't chmod b/c 2nd perms are ".sprintf('%05o',$perms2) }
}->();
subtest 'perms / chmod' => sub {
	plan $cant_chmod_modes ? (skip_all=>$cant_chmod_modes) : (tests=>7);
	{
		my $fn = spew(newtempfn,"PermTest1");
		checked_chmod('600',$fn);
		File::Replace->new($fn, perms=>oct('640'))->finish;
		check_mode('640',$fn);
	}
	{
		my $fn = newtempfn;
		File::Replace->new($fn, perms=>oct('640'))->finish;
		check_mode('640',$fn);
	}
	{
		my $fn = spew(newtempfn,"qqq\nrrr\nsss");
		checked_chmod('640',$fn);
		File::Replace->new($fn, chmod=>0)->finish;
		# we know File::Temp defaults to 0600
		check_mode('600',$fn);
	}
};

# Use some heuristics to see whether "chmod" should work on this system,
# and whether we can use chmod(0, ...) to prevent opening a file.
my $cant_chmod_permdeny = sub {
	my $testfn = spew(newtempfn, "XYZ");
	if (!chmod(0, $testfn)) { return "can't chmod b/c chmod failed" }
	my $perms = S_IMODE(stat($testfn)->mode);
	if ( $perms!=0 )
		{ return "can't chmod b/c perms are ".sprintf('%05o',$perms) }
	if (open my $fh, '<', $testfn)  ## no critic (RequireBriefOpen)
		{ return "can't chmod b/c open succeeded" }
	if (!chmod(oct('600'), $testfn)) { return "can't chmod b/c chmod 2 failed" }
	return;
}->();
subtest 'open/chmod/rename failure tests' => sub {
	$cant_chmod_permdeny and plan skip_all => $cant_chmod_permdeny;
	my $tmpdir = tempdir(CLEANUP=>1);
	
	# cause opening the file to fail
	my $tfn = spew(catfile($tmpdir,'file1'), "Blah");
	checked_chmod('000',$tfn);
	ok exception { my $r = File::Replace->new($tfn) }, 'file permission denied';
	
	{ # cause opening /dev/null to fail
		no warnings 'redefine';  ## no critic (ProhibitNoWarnings)
		local *File::Replace::devnull = sub { return $tfn };
		use warnings 'all';
		ok exception { my $r = File::Replace->new(newtempfn) }, 'devnull failure';
	}
	
	# allow opening the file again
	ok chmod(oct('600'),$tfn), "chmod 600 $tfn";
	
	# cause chmoding the file to fail
	my $r1 = File::Replace->new($tfn);
	print {$r1->out_fh} "Test1";
	checked_chmod('400',$tmpdir);
	like exception { $r1->finish }, qr/\bchmod\b/,
		'close permission denied (chmod fail)';
	
	checked_chmod('500',$tmpdir);
	is slurp($tfn), "Blah", 'not replaced after chmod fail';
	
	# temp file creation will fail
	like exception { my $r = File::Replace->new($tfn) }, qr/\bte?mp/i, 'tempfile fail';
	
	# cause renaming the file to fail
	checked_chmod('700',$tmpdir);
	my $r2 = File::Replace->new($tfn);
	print {$r2->out_fh} "Test2";
	checked_chmod('500',$tmpdir);
	like exception { $r2->finish }, qr/\brenam(?:e|ing)\b/i,
		'close permission denied (rename fail)';
	is slurp($tfn), "Blah", 'not replaced after rename fail';
	
	checked_chmod('700',$tmpdir);
	checked_chmod('600',$tfn);
};

