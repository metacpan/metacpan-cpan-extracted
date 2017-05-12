#!/usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################
# perhaps it could also run timidity -idvv -x for an independent opinion

use MIDI::SoundFont;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
use Test::Simple tests => 42;
# use Class::MakeMethods::Utility::Ref qw( ref_clone ref_compare );
use bytes;

my %sf = MIDI::SoundFont::file2sf('doc/Jeux14.sf2');
ok($sf{'ifil'} eq '2.1', "ifil was 2.1");
ok($sf{'INAM'} =~ /^JEUX version/, "INAM starts with 'JEUX version'");
ok($sf{'isng'} eq 'EMU8000', "isng was EMU8000");
ok($sf{'IPRD'} eq 'SBAWE32', "IPRD was SBAWE32");
ok($sf{'IENG'} =~ /^John W. McCoy/, "IENG starts with 'John W. McCoy'");
ok($sf{'ISFT'} eq 'SFEDT v1.28:', "ISFT is 'SFEDT v1.28:'");
ok($sf{'ICRD'} eq 'May 14, 1999', "ICRD is 'May 14, 1999'");
ok($sf{'ICMT'} =~ /^This SoundFont/, "ICMT starts with 'This SoundFont'");
ok($sf{'ICOP'} =~ /^Copyright 2000,/, "ICOP starts with 'Copyright 2000,'");
ok($sf{'ISFT'} =~ /^SFEDT /, "ISFT starts with 'SFEDT'");

my @gen_list = MIDI::SoundFont::gen_hashref2list({
	decayModEnv => 4852,
	decayVolEnv => 4688,
	fineTune => -28,
	freqModLFO => -808,
	freqVibLFO => -808,
	holdVolEnv => -6184,
	initialAttenuation => 197,
	initialFilterFc => 7198,
	keyRange => [ 0, 36 ],
	modEnvToFilterFc => 3600,
	overridingRootKey => 89,
	pan => 4,
	releaseModEnv => 4061,
	releaseVolEnv => 1902,
	reverbEffectsSend => 70,
	sampleID => 'Music Box C5',
	sampleModes => 1,
	sustainModEnv => 1000,
	sustainVolEnv => 140
}, 'i');
# print Dumper(\@gen_list);

print "# now converting with sf2bytes and back again with bytes2sf:\n";
my $bytes = MIDI::SoundFont::sf2bytes(%sf);
#MIDI::SoundFont::file2dump('doc/Jeux14.sf2');
#MIDI::SoundFont::bytes2dump($bytes); # exit;
#print Dumper(MIDI::SoundFont::bytes2sf($bytes));
my %sf2   = MIDI::SoundFont::bytes2sf($bytes);
ok($sf{'ifil'} eq $sf2{'ifil'}, 'ifil unchanged');
ok($sf{'isng'} eq $sf2{'isng'}, 'isng unchanged');
ok($sf{'INAM'} eq $sf2{'INAM'}, 'INAM unchanged');
ok($sf{'IPRD'} eq $sf2{'IPRD'}, 'IPRD unchanged');
ok($sf{'IENG'} eq $sf2{'IENG'}, 'IENG unchanged');
ok($sf{'ICRD'} eq $sf2{'ICRD'}, 'ICRD unchanged');
ok($sf{'ICMT'} eq $sf2{'ICMT'}, 'ICMT unchanged');
ok($sf{'ICOP'} eq $sf2{'ICOP'}, 'ICOP unchanged');
ok($sf2{'ISFT'} =~ /SFEDT.*MIDI-SoundFont \d+/,
 "ISFT now contains 'MIDI-SoundFont'");
my $l1 = scalar(keys %{$sf{'shdr'}});
my $l2 = scalar(keys %{$sf2{'shdr'}});
ok("$l1" eq "$l2", "shdr length $l1 unchanged at $l2");
$l1 = scalar @{$sf{'phdr'}};
$l2 = scalar @{$sf2{'phdr'}};
ok($l1 == $l2, "phdr length $l1 unchanged at $l2");
$l1 = scalar(keys %{$sf{'inst'}});
$l2 = scalar(keys  %{$sf2{'inst'}});
ok("$l1" eq "$l2", "inst length $l1 unchanged at $l2");
my @smpl_list1 = ();
foreach (sort keys %{$sf{'shdr'}}) {
	push @smpl_list1, $sf{'shdr'}{$_}{'sampledata'};
}
my @smpl_list2 = ();
foreach (sort keys %{$sf2{'shdr'}}) {
	push @smpl_list2, $sf{'shdr'}{$_}{'sampledata'};
}
ok($smpl_list1[1] eq $smpl_list2[1], '2nd samples match');
ok($smpl_list1[$#smpl_list1-1] eq $smpl_list2[$#smpl_list2-1],
 '2nd-last samples match');
ok($smpl_list1[$#smpl_list1] eq $smpl_list2[$#smpl_list2],
 'last samples match');
my $s1 = join '', @smpl_list1;
my $s2 = join '', @smpl_list2;
ok(length $s1 == length $s2,
 'total sample-data length '.(length $s1).' unchanged');

ok(equal($sf{'shdr'}{'Flute 7-3'},$sf2{'shdr'}{'Flute 7-3'}),
 "sf{'shdr'}{'Flute 7-3'} is unchanged");
ok(equal($sf{'inst'}{'Principal 2'},$sf2{'inst'}{'Principal 2'}),
 "sf{'inst'}{'Principal 2'} is unchanged");

#---------------------------------------------------------

my $pat_file = 'gravis/fiddle.pat';
print "# now testing file2gravis('$pat_file') ...\n";
my %gravis_pat = MIDI::SoundFont::file2gravis($pat_file);
foreach (sort keys %gravis_pat) { print "# key is $_\n"; }
my %pat1 = %{$gravis_pat{'fiddle.pat'}};
ok($pat1{'filename'} eq $pat_file, "filename is $pat_file");
my @wavsamples1=@{$pat1{'instruments'}->[0]->{'layers'}->[0]->{'wavsamples'}};
ok(scalar(@wavsamples1) == 3, "there are 3 wavsamples");
ok(length($wavsamples1[0]->{'data'}) == 5018,
 'first sample data is 5018 bytes long');
ok(length($wavsamples1[1]->{'data'}) == 3934,
 'second sample data is 3934 bytes long');
ok(length($wavsamples1[2]->{'data'}) == 2830,
 'third sample data is 2830 bytes long');

my %gravis_zip = MIDI::SoundFont::file2gravis('gravis/Gravis.zip');

print "# now converting with pat2bytes and back again with bytes2pat:\n";
my $patbytes = MIDI::SoundFont::pat2bytes(%pat1);
$l1 = length($patbytes);
ok($l1 == -s 'gravis/fiddle.pat',"pat2bytes length was $l1");
my %pat2 = MIDI::SoundFont::bytes2pat($patbytes);
#open (P,'|less'); print P Dumper(\%pat1); print P Dumper(\%pat2); close P;
my @wavsamples2
  = @{$pat2{'instruments'}->[0]->{'layers'}->[0]->{'wavsamples'}};
ok(scalar(@wavsamples2) == 3, "there are 3 wavsamples");
$l2 = length($wavsamples2[0]->{'data'});
ok($l2 == 5018, "first sample data was $l2 bytes long");
$l2 = length($wavsamples2[1]->{'data'});
ok($l2 == 3934, "second sample data was $l2 bytes long");
$l2 = length($wavsamples2[2]->{'data'});
ok($l2 == 2830, "third sample data was $l2 bytes long");
ok($wavsamples1[2]->{'data'} eq $wavsamples2[2]->{'data'},
 'last samples match');

my @c = split("\n",MIDI::SoundFont::timidity_cfg('doc/Jeux14.sf2',%sf));
ok($c[78] eq '75 %font Jeux14.sf2 0 75   # Schalmei 8',
 'timidity_cfg on doc/Jeux14.sf2');
@c = split("\n",
 MIDI::SoundFont::timidity_cfg('gravis/fiddle.pat','fiddle.pat',\%pat1));
ok(3 == scalar @c, 'timidity_cfg on gravis/fiddle.pat');
@c = split("\n",
 MIDI::SoundFont::timidity_cfg('gravis/Gravis.zip',%gravis_zip));
eval 'require String::Approx';
if ($@) {
	ok(1, 'String::Approx not installed; skipping Gravis.zip test');
} else {
	ok($c[48] eq '99 atmosphr.pat', 'timidity_cfg on gravis/Gravis.zip');
}

exit;

# timidity -idvv -x 'soundfont /tmp/k.sf2' /tmp/t.mid 2>&1 | less

# --------------------------- infrastructure ----------------
sub equal { my ($x, $y) = @_;
	if (! defined $y) { warn "y is not defined\n"; return 0; }
	my $dx = Dumper($x);
	my $dy = Dumper($y);
	if ($dx eq $dy) { return 1;
	} else { warn "x = $dx\ny = $dy\n"; return 0;
	}
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test MIDI::SoundFont.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests MIDI::SoundFont.pm

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 MIDI::ALSA
 http://www.pjb.com.au/
 http://www.pjb.com.au/midi/
 http://www.pjb.com.au/comp/
 perl(1).

=cut

