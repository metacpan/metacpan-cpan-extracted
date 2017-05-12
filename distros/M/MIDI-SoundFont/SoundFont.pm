# MIDI::SoundFont.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package MIDI::SoundFont;
no strict;
use bytes;
#my $debug = 1; use Data::Dumper;
$VERSION = '1.08';
$VERSION_DATE = '18may2013';

# 20130518 1.07 Makefile.PL specifies PREREQ_PM, to improve test results :-)
# 20130515 1.06 test.pl skips Gravis.zip test if String::Approx not installed
# 20120809 1.05 added the csound_scoresynth and csound_midisynth examples
# 20120322 1.04 pack a=zeropadded rather than A=spacepadded; introduce
#               new_gf(), gravis2file now works, and make_bank5 does gravis too
# 20120320 1.03 new_sf(), and chCorrection is packed as signed
# 20120318 1.02 detect duplicate Preset,Inst,Sample names and uniquely rename
# 20120216 1.01 gravis2file writes .zip files
# 20120215 1.00 first released version

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = ();
@EXPORT_OK = qw( GeneratorOperators GenAmountType bytes2sf file2sf
  sf2bytes sf2file new_sf file2gravis gravis2file new_pat timidity_cfg
);
@EXPORT_CONSTS = qw(GeneratorOperators GenOpname2num GenAmountType
  MODES_16BIT   MODES_UNSIGNED MODES_LOOPING  MODES_PINGPONG
  MODES_REVERSE MODES_SUSTAIN  MODES_ENVELOPE MODES_CLAMPED);
%EXPORT_TAGS = (ALL => [@EXPORT_OK], CONSTS => [@EXPORT_CONSTS]);

eval 'require File::Format::RIFF';
if ($@) {
 die "you need to install the File::Format::RIFF module from www.cpan.org\n";
}
# local $[ = 0; # SoundFont indexes start at zero but setting $[ is deprecated
my %SampleName = ();   # to avoid duplicating sample-names...

# ----------------------- exportable constants -----------------------
@GeneratorOperators = qw(
    startAddrsOffset endAddrsOffset startloopAddrsOffset endloopAddrsOffset
    startAddrsCoarseOffset modLfoToPitch vibLfoToPitch modEnvToPitch
    initialFilterFc initialFilterQ modLfoToFilterFc modEnvToFilterFc
    endAddrsCoarseOffset modLfoToVolume unused1 chorusEffectsSend
    reverbEffectsSend pan unused2 unused3
    unused4 delayModLFO freqModLFO delayVibLFO
    freqVibLFO delayModEnv attackModEnv holdModEnv
    decayModEnv sustainModEnv releaseModEnv keynumToModEnvHold
    keynumToModEnvDecay delayVolEnv attackVolEnv holdVolEnv
    decayVolEnv sustainVolEnv releaseVolEnv keynumToVolEnvHold
    keynumToVolEnvDecay instrument reserved1 keyRange
    velRange startloopAddrsCoarseOffset keynum velocity
    initialAttenuation reserved2 endloopAddrsCoarseOffset coarseTune
    fineTune sampleID sampleModes reserved3
    scaleTuning exclusiveClass overridingRootKey unused5
    endOper
);
%GenOpname2num = (); {
	my $i=0; while ($i <= $#GeneratorOperators) {
		$GenOpname2num{$GeneratorOperators[$i]} = $i;
		$i += 1;
	}
}
@GenAmountType = qw (
	S s s s
	s s s s
	s s s s
	s s x s
	s s x x
	x s s s
	s s s s
	s s s s
	s s s s
	s s s s
	s S x C2
	C2 s S S
	S x s s
	s S S x
	s S s x
	x
);  # s signed, S unsigned, C2 two bytes, x null; sfspec21 8.1.2 & guesswork

$MODES_16BIT    = 1;  $MODES_UNSIGNED = 2;
$MODES_LOOPING  = 4;  $MODES_PINGPONG = 8;
$MODES_REVERSE  = 16; $MODES_SUSTAIN  = 32;
$MODES_ENVELOPE = 64; $MODES_CLAMPED  = 128;

# sf:
# see http://www.pjb.com.au/midi.sfspec21.html#8.1.3
my %OnlyValidInInstr = map { $_, 1 } (0,1,2,3,4,12,45,50,54,57,58);
# gravis:
my $DefaultEnvelopeData = "\x3f\x46\x81\x42\x3f\x3f\xd5\xf2\xf6\x08\x08\x08";


# ----------------------- exportable functions -----------------------
sub file2bytes {
    # read bytes from file, or url, or filehandle, or - is stdin
	my $bytes;
	if ($_[0] eq '-') {
		undef $/; binmode STDIN, ':raw';
		$bytes = <STDIN>;
	} elsif ($_[0] =~ /^[a-z]+:\//) {
		eval 'require LWP::Simple'; if ($@) {
			die "you'll need to install libwww-perl from www.cpan.org\n";
		}
		my $bytes = LWP::Simple::get($_[0]);
		if (! defined $bytes) { die("can't fetch $_[0]\n"); }
	} elsif (ref($_[0]) eq 'GLOB') {
		# must open the file ?
		undef $/; binmode $_[0], ':raw';
		$bytes = <$_[0]>;
		close $_[0];
	} else {
		if (! open(F, '<:raw', $_[0])) {
			warn "can't open $_[0]: $!\n"; return '';
		}
		undef $/; binmode F; $bytes = <F>; close F;
	}
	return $bytes;
}

sub file2sf {
	my $bytes = file2bytes($_[0]);
    return bytes2sf($bytes);
}

sub file2dump {
	my $bytes = file2bytes($_[0]);
    return bytes2dump($bytes);
}

sub bytes2dump { my $bytes = $_[0];
	my %sf = ();
	if (! open(P, '<', \$bytes)) {
		warn "can't open in-memory filehandle: $!\n"; return;
	}
	undef $/; binmode P;
	my $riff = File::Format::RIFF->read(\*P, length($bytes));
	close P;
	my $info = $riff->at(0);  $info->dump;
	my $sdta = $riff->at(1);  $sdta->dump;
	my $smpl = $sdta->shift();
	my $smpl_data = $smpl->data();
	my $pdta = $riff->at(2);  $pdta->dump;
}

sub bytes2sf { my $bytes = $_[0];   # take it apart with RIFF
	my %sf = ();
	if (! open(P, '<', \$bytes)) {
		warn "can't open in-memory filehandle: $!\n"; return;
	}
	undef $/; binmode P;
	my $riff = File::Format::RIFF->read(\*P, length($bytes));
	close P;
	my $info = $riff->at(0);
	my $sdta = $riff->at(1);
	my $smpl = $sdta->shift();
	my $smpl_data = $smpl->data();
	my $pdta = $riff->at(2);

	while (1) {   # INFO
		my $chunk = $info->shift();
		if (! defined $chunk) { last; }
		my $id   = $chunk->id();
		my $data = $chunk->data();
		if ($id eq 'ifil' or $id eq 'iver') {
			my ($wMajor, $wMinor) = unpack('SS', $data);
			$sf{$id} = "$wMajor.$wMinor";
		} else {
			$data =~ s/\0*$//s;
			$sf{$id} = $data;
		}
	}
	my %pdta = ();
    while (1) {   # PDTA
        my $chunk = $pdta->shift();
        if (! defined $chunk) { last; }
        $pdta{$chunk->id()} = $chunk->data();
        # warn $chunk->id()." is ".length($pdta{$chunk->id()})." bytes long\n";
    }

	# http://www.pjb.com.au/midi/sfspec21.html#7.2
	if (! $pdta{'phdr'}) { warn "missing phdr sub-chunk\n"; return undef; }
	my $len = length $pdta{'phdr'}; if ($len % 38) {
		warn "phdr sub-chunk not a multiple of 38 bytes\n"; return undef;
	}
	my $ind = 0;  # $[ must be zero
	my @phdr_list = ();
	my %preset_names_seen = ();   # 1.02
	while ($ind < $len) {  # sfspec21.txt 7.2
		my $phdr_rec = substr $pdta{'phdr'}, $ind, 38;
		my ($achPresetName,$wPreset,$wBank,$wPresetBagNdx,$dwLibrary,
		 $dwGenre,$dwMorphology) = unpack 'A20SSSLLL', $phdr_rec;
		$achPresetName =~ s/\0.*$//s;
		# 1.02 detect duplicate names and rename as necessary (7.2)
		my $orig = $achPresetName;
		my $x = 2; while ($preset_names_seen{$achPresetName}) {
			$achPresetName = $orig."_$x"; $x += 1;
		}
		$preset_names_seen{$achPresetName} = 1;
		push @phdr_list, {
			achPresetName => $achPresetName,
			wPreset => $wPreset,
			wBank => $wBank,
			wPresetBagNdx => $wPresetBagNdx,
			# dwLibrary => $dwLibrary,
			# dwGenre => $dwGenre,
			# dwMorphology => $dwMorphology,
		};
		$ind += 38;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.3
	if (! $pdta{'pbag'}) { warn "missing pbag sub-chunk\n"; return undef; }
	$len = length $pdta{'pbag'}; if ($len % 4) {
		warn "pbag sub-chunk not a multiple of 4 bytes\n"; return undef;
	}
	$ind = 0;
	my @pbag_list = ();
	while ($ind < $len) {  # sfspec21.txt 7.3
		my $pbag_rec = substr $pdta{'pbag'}, $ind, 4;
		my ($wGenNdx,$wModNdx) = unpack 'SS', $pbag_rec;
		push @pbag_list, {
			wGenNdx => $wGenNdx,
			wModNdx => $wModNdx,
		};
		$ind += 4;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.4
	if (! $pdta{'pmod'}) { warn "missing pmod sub-chunk\n"; return undef; }
	$len = length $pdta{'pmod'}; if ($len % 10) {
		warn "pmod sub-chunk not a multiple of 10 bytes\n"; return undef;
	}
	$ind = 0;
	my @pmod_list = ();
	while ($ind < $len) {  # sfspec21.txt 7.4
		my $pmod_rec = substr $pdta{'pmod'}, $ind, 10;
		my ($sfModSrcOper,$sfModDestOper,$modAmount,$sfModAmtSrcOper,
		 $sfModTransOper) = unpack 'SSSSS', $pmod_rec;
		push @pmod_list, {
			sfModSrcOper => $sfModSrcOper,
			sfModDestOper => $sfModDestOper,
			modAmount => $modAmount,
			sfModAmtSrcOper => $sfModAmtSrcOper,
			sfModTransOper => $sfModTransOper,
		};
		$ind += 10;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.6
	if (! $pdta{'inst'}) { warn "missing inst sub-chunk\n"; return undef; }
	$len = length $pdta{'inst'}; if ($len % 22) {
		warn "inst sub-chunk not a multiple of 22 bytes\n"; return undef;
	}
	$ind = 0;  # $[ _must_ be zero
	my @inst_list = ();
	my %inst_names_seen = ();   # 1.02
	while ($ind < $len) {  # sfspec21.html#7.6
		my $inst_rec = substr $pdta{'inst'}, $ind, 22;
		my ($achInstName,$wInstBagNdx) = unpack 'A20S', $inst_rec;
		$achInstName =~ s/\0.*$//s;
		# 1.02 detect duplicate names and rename as necessary (7.6)
		my $orig = $achInstName;
		my $x = 2; while ($inst_names_seen{$achInstName}) {
			$achInstName = $orig."_$x"; $x += 1;
		}
		$inst_names_seen{$achInstName} = 1;
		push @inst_list, {
			achInstName => $achInstName,
			wInstBagNdx => $wInstBagNdx,
		};
		$ind += 22;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.7
	if (! $pdta{'ibag'}) { warn "missing ibag sub-chunk\n"; return undef; }
	$len = length $pdta{'ibag'}; if ($len % 4) {
		warn "ibag sub-chunk not a multiple of 4 bytes\n"; return undef;
	}
	$ind = 0;
	my @ibag_list = ();
	while ($ind < $len) {  # sfspec21.txt 7.7
		my $ibag_rec = substr $pdta{'ibag'}, $ind, 4;
		my ($wInstGenNdx,$wInstModNdx) = unpack 'SS', $ibag_rec;
		push @ibag_list, {
			wInstGenNdx => $wInstGenNdx,
			wInstModNdx => $wInstModNdx,
		};
		$ind += 4;
	}
	# now go though @inst_list extracting each preset's lists of bags
	$i = 0; while ($i < $#inst_list) {
		my $from = $inst_list[$i]{'wInstBagNdx'};
		my $to = $inst_list[$i+1]{'wInstBagNdx'};
		# should check monotonicity and in-rangeness
		my @ibags = ();  my $j = $from;
		while ($j < $to) { push @ibags, $ibag_list[$j]; $j += 1; }
		$inst_list[$i]{'ibags'} = \@ibags;
		$i += 1;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.8
	if (! $pdta{'imod'}) { warn "missing imod sub-chunk\n"; return undef; }
	$len = length $pdta{'imod'}; if ($len % 10) {
		warn "imod sub-chunk not a multiple of 10 bytes\n"; return undef;
	}
	$ind = 0;
	my @imod_list = ();
	while ($ind < $len) {  # sfspec21.txt 7.8
		my $imod_rec = substr $pdta{'imod'}, $ind, 10;
		my ($sfModSrcOper,$sfModDestOper,$modAmount,$sfModAmtSrcOper,
		 $sfModTransOper) = unpack 'SSSSS', $imod_rec;
		push @imod_list, {
			sfModSrcOper => $sfModSrcOper,
			sfModDestOper => $sfModDestOper,
			modAmount => $modAmount,
			sfModAmtSrcOper => $sfModAmtSrcOper,
			sfModTransOper => $sfModTransOper,
		};
		$ind += 10;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.10
	if (! $pdta{'shdr'}) { warn "missing shdr sub-chunk\n"; return undef; }
	$len = length $pdta{'shdr'}; if ($len % 46) {
		warn "shdr sub-chunk not a multiple of 46 bytes\n"; return undef;
	}
	$ind = 0;
	my @shdr_list = ();
	my %sample_names_seen = ();   # 1.02
	while ($ind < $len) {  # sfspec21.html#7.10
		my $shdr_rec = substr $pdta{'shdr'}, $ind, 46;
        my ($achSampleName,$dwStart,$dwEnd,$dwStartloop,$dwEndloop,
		 $dwSampleRate,$byOriginalKey,$chCorrection,$wSampleLink,$sfSampleType)
          = unpack 'A20LLLLLCcSS', $shdr_rec;
		$achSampleName =~ s/\0.*$//s;
		# 1.02 detect duplicate names and rename as necessary (7.10)
		my $orig = $achSampleName;
		my $x = 2; while ($sample_names_seen{$achSampleName}) {
			$achSampleName = $orig."_$x"; $x += 1;
		}
		$sample_names_seen{$achSampleName} = 1;
		# extract the sample from $smpl_data
		my $smpl_length = $dwEnd - $dwStart;  # could test
		my $this_sample = substr($smpl_data,  # 16 bits is 2 bytes
		 $dwStart+$dwStart, $smpl_length+$smpl_length);
		if ($achSampleName ne 'EOS') {
			push @shdr_list, {
				achSampleName => $achSampleName,
				dwStart => 0,
				dwEnd => $dwEnd-$dwStart,
				dwStartloop => $dwStartloop-$dwStart,
				dwEndloop => $dwEndloop-$dwStart,
				dwSampleRate => $dwSampleRate,
				byOriginalKey => $byOriginalKey,
				chCorrection => $chCorrection,
				wSampleLink => $wSampleLink,
				sfSampleType => $sfSampleType,
				sampledata => $this_sample,
			};
		}
		$ind += 46;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.9
	# http://www.pjb.com.au/midi/sfspec21.html#8.1.2
	# http://www.pjb.com.au/midi/sfspec21.html#8.1.3
	if (! $pdta{'igen'}) { warn "missing igen sub-chunk\n"; return undef; }
	$len = length $pdta{'igen'}; if ($len % 4) {
		warn "igen sub-chunk not a multiple of 4 bytes\n"; return undef;
	}
	$ind = 0;
	my @igen_list = ();
	while ($ind < $len) {
		my $igen_rec = substr $pdta{'igen'}, $ind, 4;
		my ($sfGenOper,$dummy) = unpack 'SS', $igen_rec;
		my $type = $GenAmountType[$sfGenOper];
		if (! defined $type) {
			warn "sfGenOper=$sfGenOper out of range\n"; return;
		}
		if ($sfGenOper == 41) {  # extract the instrument ILLEGAL HERE
			warn "instruments are not allowed in instrument zones\n"; return;
			my ($dummy,$shAmount) = unpack "SS", $igen_rec;
			push @igen_list, {
				sfGenOper=>$sfGenOper,
				shAmount =>$inst_list[$shAmount]{'achInstName'}
			};
		} elsif ($sfGenOper == 53) {  # extract the sample
			my ($dummy,$shAmount) = unpack "SS", $igen_rec;
            push @igen_list, {
                sfGenOper=>$sfGenOper,
                shAmount =>$shdr_list[$shAmount]{'achSampleName'}
            };
		} elsif ($type eq 'x') {
			# unused; ignore
		} elsif ($type eq 'C2') {
			my ($dummy,$min,$max) = unpack "S$type", $igen_rec;
			push @igen_list, { sfGenOper=>$sfGenOper, shAmount=>[$min,$max] };
		} else {
			my ($dummy,$shAmount) = unpack "S$type", $igen_rec;
			push @igen_list, { sfGenOper=>$sfGenOper, shAmount=>$shAmount, };
		}
		$ind += 4;
	}

	# http://www.pjb.com.au/midi/sfspec21.html#7.5
	# http://www.pjb.com.au/midi/sfspec21.html#8.1.2
	# http://www.pjb.com.au/midi/sfspec21.html#8.1.3
	if (! $pdta{'pgen'}) { warn "missing pgen sub-chunk\n"; return undef; }
	$len = length $pdta{'pgen'}; if ($len % 4) {
		warn "pgen sub-chunk not a multiple of 4 bytes\n"; return undef;
	}
	$ind = 0;
	my @pgen_list = ();
	while ($ind < $len) {
		my $pgen_rec = substr $pdta{'pgen'}, $ind, 4;
		my ($sfGenOper,$dummy) = unpack 'SS', $pgen_rec;
		my $type = $GenAmountType[$sfGenOper];
		if (! defined $type) {
			warn "sfGenOper=$sfGenOper out of range\n"; return;
		}
		if ($OnlyValidInInstr{$sfGenOper}) {
			#warn "sfGenOper=$sfGenOper ($GeneratorOperators[$sfGenOper]) "
			#  . "invalid in presets; ignoring\n";
			# invalid in presets; ignore!  see sfspec21.html#8.5
		} elsif ($sfGenOper == 41) {  # extract the instrument
			my ($dummy,$shAmount) = unpack "SS", $pgen_rec;
			push @pgen_list, {
				sfGenOper=>$sfGenOper,
				shAmount =>$inst_list[$shAmount]{'achInstName'}
			};
		} elsif ($type eq 'x') {
			warn "sfGenOper=$sfGenOper unused; ignoring\n";
		} elsif ($type eq 'C2') {
			my ($dummy,$min,$max) = unpack "S$type", $pgen_rec;
			push @pgen_list, { sfGenOper=>$sfGenOper, shAmount=>[$min,$max] };
		} else {
			my ($dummy,$shAmount) = unpack "S$type", $pgen_rec;
			push @pgen_list, { sfGenOper=>$sfGenOper, shAmount=>$shAmount, };
		}
		$ind += 4;
	}
	# go though @pbag_list extracting each hash of modulators and generators
	my $i = 0; while ($i < $#pbag_list) {
		my $from = $pbag_list[$i]{'wGenNdx'};
		my $to = $pbag_list[$i+1]{'wGenNdx'};
		# should check monotonicity and in-rangeness
		my %gens = ();  my $j = $from;
		while ($j < $to) {
			if (defined $pgen_list[$j]{'shAmount'}) {
				$gens{$GeneratorOperators[$pgen_list[$j]{'sfGenOper'}]}
				  = $pgen_list[$j]{'shAmount'};
			}
			$j += 1;
		}
		$pbag_list[$i]{'generators'} = \%gens;
		delete $pbag_list[$i]{'wGenNdx'};

		# should check monotonicity and in-rangeness
		$from = $pbag_list[$i]{'wModNdx'};
		$to = $pbag_list[$i+1]{'wModNdx'};
		my @mods = ();  $j = $from;
		while ($j < $to) { push @mods, $pmod_list[$j]; $j += 1; }
		$pbag_list[$i]{'modulators'} = \@mods;
		delete $pbag_list[$i]{'wModNdx'};
		$i += 1;
	}
	# now go though @phdr_list extracting each preset's lists of pbags
	$i = 0; while ($i < $#phdr_list) {
		my $from = $phdr_list[$i]{'wPresetBagNdx'};
		my $to = $phdr_list[$i+1]{'wPresetBagNdx'};
		# should check monotonicity and in-rangeness
		my @pbags = ();  my $j = $from;
		while ($j < $to) { push @pbags, $pbag_list[$j]; $j += 1; }
		$phdr_list[$i]{'pbags'} = \@pbags;
		delete $phdr_list[$i]{'wPresetBagNdx'};
		$i += 1;
	}
	# go though @ibag_list extracting each list of modulators and generators
	$i = 0; while ($i < $#ibag_list) {
		my $from = $ibag_list[$i]{'wInstGenNdx'};
		my $to = $ibag_list[$i+1]{'wInstGenNdx'};
		my %gens = ();  my $j = $from;
		while ($j < $to) {
			$gens{$GeneratorOperators[$igen_list[$j]{'sfGenOper'}]}
			  = $igen_list[$j]{'shAmount'};
			$j += 1;
		}
		$ibag_list[$i]{'generators'} = \%gens;
		delete $ibag_list[$i]{'wInstGenNdx'};
		# should check monotonicity and in-rangeness
		$from = $ibag_list[$i]{'wInstModNdx'};
		$to = $ibag_list[$i+1]{'wInstModNdx'};
		my @mods = ();  $j = $from;
		while ($j < $to) { push @mods, $imod_list[$j]; $j += 1; }
		$ibag_list[$i]{'modulators'} = \@mods;
		delete $ibag_list[$i]{'wInstModNdx'};
		$i += 1;
	}
	# now go though @inst_list extracting each preset's lists of bags
	$i = 0; while ($i < $#inst_list) {
		my $from = $inst_list[$i]{'wInstBagNdx'};
		my $to = $inst_list[$i+1]{'wInstBagNdx'};
		# should check monotonicity and in-rangeness
		my @ibags = ();  my $j = $from;
		while ($j < $to) { push @ibags, $ibag_list[$j]; $j += 1; }
		$inst_list[$i]{'ibags'} = \@ibags;
		delete $inst_list[$i]{'wInstBagNdx'};
		$i += 1;
	}

	# pop EOP off the end of @phdr_list
	if ($phdr_list[$#phdr_list]{'achPresetName'} eq 'EOP') { pop @phdr_list; }
	# pop EOI off the end of @inst_list
	if ($inst_list[$#inst_list]{'achInstName'} eq 'EOI') { pop @inst_list; }
	# construct %inst_hash and %shdr_hash
	my %inst_hash = (); foreach (@inst_list) {
		$inst_hash{$_->{'achInstName'}} = $_;
		delete $_->{'achInstName'};
	}
	my %shdr_hash = (); foreach (@shdr_list) {
		$shdr_hash{$_->{'achSampleName'}} = $_;
		delete $_->{'achSampleName'};
	}
#	$sf{'pbag'} = \@pbag_list;
	$sf{'phdr'} = \@phdr_list;
#	$sf{'pmod'} = \@pmod_list;
#	$sf{'pgen'} = \@pgen_list;
#	$sf{'ibag'} = \@ibag_list;
	$sf{'inst'} = \%inst_hash;
#	$sf{'imod'} = \@imod_list;
#	$sf{'igen'} = \@igen_list;
	$sf{'shdr'} = \%shdr_hash;

	if ($debug) {
		$Data::Dumper::Indent=1; $Data::Dumper::Sortkeys=1; print Dumper(%sf);
	}
	return %sf;
}

sub new_sf { my $inam = $_[$[] || 'Name of this SoundFont';
	my ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire)
	  = getpwuid($>);
	$gcos =~ s/,+$//;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	my $y = sprintf ("%4.4d", $year+1900);
	my @abbr = qw( January February March April May June
	  July August September October November December );
	my $now = "$abbr[$mon] $mday, $y";   # sfspec21.html#5.6
	return (
		ICMT => "insert comment here",
		ICOP => "Copyright (c) $y $gcos; may be freely copied and modified",
		ICRD => $now,
		IENG => "$name, $gcos",
		INAM => $inam,
		IPRD => 'TiMidity',
		ISFT => "MIDI-SoundFont $VERSION",
		IVER => '',
		ifil => '2.1',
		inst => {
			inst_0 => {
				ibags => [
					{
						generators => {
							keyRange => [ 0, 127 ],
							pan => -190,
							sampleID => 'smpl_0',
							sampleModes => 1,
						},
						modulators => [],
        			},
				],
			},
		},
		phdr => [
			{
				achPresetName => 'Instrument number 0',
				pbags => [
					{
						generators => {
							velRange => [ 0, 127 ],
							instrument => 'inst_0',
						},
						modulators => [],
					},
				],
				wBank => 0,
				wPreset => 0,
			},
		],
		shdr => {
			inst_0 => {
				byOriginalKey => 69,
				chCorrection => 0,
				dwEnd => 10000,
				dwEndloop => 9990,
				dwSampleRate => 44100,
				dwStart => 0,
				dwStartloop => 9890,
				sampledata => ' ... ',
				sfSampleType => 1,
				wSampleLink => 0,
			},
		},
	);
}

sub sf2file { my $file = shift;
	# write bytes to file, or filehandle (if GLOB), or - is stdout
	if (! $file) { warn "sf2file: missing arguments.\n"; return; }
	my $bytes = sf2bytes(@_);
	if (ref($file) eq 'GLOB') {
	} elsif ($file eq '-') { binmode STDOUT; print STDOUT $bytes;
	} else {
		if (! open(F, '>', $file)) { warn "can't open $file: $!\n"; return; }
		binmode F; print F $bytes;
		close F;
	}
}

sub sf2bytes{ my %sf = @_;   # put it back together with RIFF
	# must be careful not to modify %sf ! it's full of references !
	# using sf_edit to change the banks, and saving to /tmp/k.sf2
	# timidity -idvv -x 'soundfont /tmp/k.sf2' /tmp/t.mid | less

	my $info = new File::Format::RIFF::List('INFO');

	my $ifil_ck = new File::Format::RIFF::Chunk;
	my ($wMajor,$wMinor) = split '\.', $sf{'ifil'};
	$ifil_ck->id('ifil');
	$ifil_ck->data(pack 'SS', $wMajor,$wMinor);
	$info->push($ifil_ck);

	my $isng_ck = new File::Format::RIFF::Chunk;
	$isng_ck->id('isng');
	$isng_ck->data(zero_pad_to_even($sf{'isng'} || 'EMU8000'));
	$info->push($isng_ck);

	my $INAM_ck = new File::Format::RIFF::Chunk;
	$INAM_ck->id('INAM');
	$INAM_ck->data(zero_pad_to_even($sf{'INAM'} || 'General MIDI'));
	$info->push($INAM_ck);

	if ($sf{'irom'}) {  # it's optional
		my $irom_ck = new File::Format::RIFF::Chunk;
		$irom_ck->id('irom');
		$irom_ck->data(zero_pad_to_even($sf{'irom'}));
		$info->push($irom_ck);
	}

	if ($sf{'iver'} and $sf{'iver'}=~/^(\d+)\.(\d+)$/) {  # it's optional
		my $iver_ck = new File::Format::RIFF::Chunk;
		$iver_ck->id('iver');
		$iver_ck->data(pack 'SS', 0+$1,0+$2);
		$info->push($iver_ck);
	}

	if ($sf{'ICRD'}) {  # it's optional
		my $ICRD_ck = new File::Format::RIFF::Chunk;
		$ICRD_ck->id('ICRD');
		$ICRD_ck->data(zero_pad_to_even($sf{'ICRD'}));
		$info->push($ICRD_ck);
	}

	if ($sf{'IENG'}) {  # it's optional
		my $IENG_ck = new File::Format::RIFF::Chunk;
		$IENG_ck->id('IENG');
		$IENG_ck->data(zero_pad_to_even($sf{'IENG'}));
		$info->push($IENG_ck);
	}

	if ($sf{'IPRD'}) {  # it's optional
		my $IPRD_ck = new File::Format::RIFF::Chunk;
		$IPRD_ck->id('IPRD');
		$IPRD_ck->data(zero_pad_to_even($sf{'IPRD'}));
		$info->push($IPRD_ck);
	}

	if ($sf{'ICOP'}) {  # it's optional
		my $ICOP_ck = new File::Format::RIFF::Chunk;
		$ICOP_ck->id('ICOP');
		$ICOP_ck->data(zero_pad_to_even($sf{'ICOP'}));
		$info->push($ICOP_ck);
	}

	if ($sf{'ICMT'}) {  # it's optional
		my $ICMT_ck = new File::Format::RIFF::Chunk;
		$ICMT_ck->id('ICMT');
		$ICMT_ck->data(zero_pad_to_even($sf{'ICMT'}));
		$info->push($ICMT_ck);
	}

	my $ISFT_ck = new File::Format::RIFF::Chunk;
	my $isft_data = "MIDI-SoundFont $VERSION";
	if ($sf{'ISFT'}) {  # it's optional, but we create it here anyway
		my $s = $sf{'ISFT'};
		$s =~ s/:.*$//s;  # truncate to 20 less than max (max actually 256)
		$isft_data = sprintf('%0.58s:%s', $s,$isft_data);
	} else {
		$isft_data = "$isft_data:";
	}
	$ISFT_ck->id('ISFT');
	$ISFT_ck->data(zero_pad_to_even($isft_data));
	$info->push($ISFT_ck);

	# go through @phdr_list, move the pbags out into a @pbag_list, note Ndx's
	# http://www.pjb.com.au/midi/sfspec21.html#7.2
	my @pbag_list = ();
	my @phdr_data = ();
	# could sort:
	# @phdr_list = sort { (1000*$a->{'wBank'}+$a->{'wPreset'})
	#   <=> (1000*$b->{'wBank'}+$b->{'wPreset'})} @{$sf{'phdr'}};
	foreach my $p_ref (@{$sf{'phdr'}}) {
		my $wPresetBagNdx = scalar @pbag_list;
		my @these_pbags = @{$p_ref->{'pbags'}};
		# check that the instrument-generator is last in @these_pbags #7.3
		push @pbag_list, @these_pbags;
        push @phdr_data, pack('a20SSSLLL', $p_ref->{'achPresetName'},
		 $p_ref->{'wPreset'}, $p_ref->{'wBank'}, $wPresetBagNdx, 0,0,0);
	}
	push @phdr_data, pack('a20SSSLLL', 'EOP',0,0,(scalar @pbag_list),0,0,0);
	my $phdr_ck = new File::Format::RIFF::Chunk;
	$phdr_ck->id('phdr');
	$phdr_ck->data(join('', @phdr_data));

	# go through @pbag_list moving the generators and modulators
	# out into their own lists, and noting their Ndx's
	# "the gen and mod lists are in the same order as the phdr and pbag lists"
	# http://www.pjb.com.au/midi/sfspec21.html#7.3
	my @pgen_list = ();  # #7.3
	my @pmod_list = ();  # #7.4
	my @pbag_data = ();  # #7.5
	foreach my $b_ref (@pbag_list) {
		my $wGenNdx = scalar @pgen_list;
		my $wModNdx = scalar @pmod_list;
		my @these_pgens = gen_hashref2list($b_ref->{'generators'}, 'p');
		my @these_pmods = @{$b_ref->{'modulators'}};
		push @pgen_list, @these_pgens;
		push @pmod_list, @these_pmods;
	    push @pbag_data, pack('SS', $wGenNdx, $wModNdx);
	}
	push @pbag_data, pack('SS', scalar @pgen_list, scalar @pmod_list);
	my $pbag_ck = new File::Format::RIFF::Chunk;
	$pbag_ck->id('pbag');
	$pbag_ck->data(join('', @pbag_data));

	# go through pgen_list to put together @inst_list in the required order
	# replace the instrument-names in pgen_list with their indexes in inst
	my %inst_name2index = ();
	my @inst_list = ();
	my @pgen_data = ();
	foreach my $g_ref (@pgen_list) {
		if ($g_ref->[0] == 41) {
			my $inst_name = $g_ref->[1];
			if (defined $inst_name2index{$inst_name}) {
				$g_ref->[1] = $inst_name2index{$inst_name};
			} else {
				$g_ref->[1] = scalar @inst_list;
				$inst_name2index{$inst_name} = $g_ref->[1];
				push @inst_list, $inst_name;
			}
		}
		my $type = $GenAmountType[$g_ref->[0]];
        push @pgen_data, pack("S$type", @{$g_ref});
	}
	push @pgen_data, ("\0"x4);
    my $pgen_ck = new File::Format::RIFF::Chunk;
    $pgen_ck->id('pgen');
    $pgen_ck->data(join('', @pgen_data));

	# pack the pmod chunk
	my @pmod_data = ();
	foreach my $m_ref (@pmod_list) {  # #7.4
		# All modulators within a zone should have a unique set
 		# of sfModSrcOper, sfModDestOper, and sfModSrcAmtOper.
        push @pmod_data, pack( 'SSSSS', $m_ref->{'sfModSrcOper'},
		  $m_ref->{'sfModDestOper'},    $m_ref->{'modAmount'},
		  $m_ref->{'sfModAmtSrcOper'},  $m_ref->{'sfModTransOper'},
		);
	}
	push @pmod_data, ("\0"x10);
    my $pmod_ck = new File::Format::RIFF::Chunk;
    $pmod_ck->id('pmod');
    $pmod_ck->data(join('', @pmod_data));

	# go through @inst_list, move the ibags out into an @ibag_list, note Ndx's
	# http://www.pjb.com.au/midi/sfspec21.html#7.6
	my @ibag_list = ();
    my @inst_data = ();
    foreach my $inst_name (@inst_list) {
		my $i_ref = $sf{'inst'}{$inst_name};
        my $wInstBagNdx = scalar @ibag_list;
        my @these_ibags = @{$i_ref->{'ibags'}};
        push @ibag_list, @these_ibags;
        push @inst_data, pack('a20S', $inst_name, $wInstBagNdx);
    }
    push @inst_data, pack('a20S', 'EOI',(scalar @ibag_list));
    my $inst_ck = new File::Format::RIFF::Chunk;
    $inst_ck->id('inst');
    $inst_ck->data(join('', @inst_data));

    # go through @ibag_list moving the generators and modulators out into
    # their own lists, and noting their Ndx's
    # http://www.pjb.com.au/midi/sfspec21.html#7.7
    my @igen_list = ();  # #7.3
    my @imod_list = ();  # #7.4
    my @ibag_data = ();  # #7.5
    foreach my $b_ref (@ibag_list) {
        my $wGenNdx = scalar @igen_list;
        my $wModNdx = scalar @imod_list;
        my @these_igens = gen_hashref2list($b_ref->{'generators'}, 'i');
        my @these_imods = @{$b_ref->{'modulators'}};
        push @igen_list, @these_igens;
        push @imod_list, @these_imods;
        push @ibag_data, pack('SS', $wGenNdx, $wModNdx);
    }
    push @ibag_data, pack('SS', scalar @igen_list, scalar @imod_list);
    my $ibag_ck = new File::Format::RIFF::Chunk;
    $ibag_ck->id('ibag');
    $ibag_ck->data(join('', @ibag_data));

	# go through igen_list constructing the list of required sample-names,
	# and replace the sample-names in igen_list with their index in that list
	my @igen_data = ();
	my @smpl_list = ();
	my %smpl_name2index = ();
	foreach my $g_ref (@igen_list) {
		if ($g_ref->[0] == 53) {
			my $samplename = $g_ref->[1];
			if (defined $smpl_name2index{$samplename}) {
				$g_ref->[1] = $smpl_name2index{$samplename};
			} else {
				$g_ref->[1] = scalar @smpl_list;
				push @smpl_list, $samplename;
				$smpl_name2index{$samplename} = $g_ref->[1];
			}
		}
		my $type = $GenAmountType[$g_ref->[0]];
        push @igen_data, pack("S$type", @{$g_ref});
	}
	push @igen_data, ("\0"x4);
    my $igen_ck = new File::Format::RIFF::Chunk;
    $igen_ck->id('igen');
    $igen_ck->data(join('', @igen_data));

	# pack the imod chunk
	my @imod_data = ();
	foreach my $m_ref (@imod_list) {  # #7.4
		# All modulators within a zone should have a unique set
 		# of sfModSrcOper, sfModDestOper, and sfModSrcAmtOper.
        push @imod_data, pack( 'SSSSS', $m_ref->{'sfModSrcOper'},
		  $m_ref->{'sfModDestOper'},    $m_ref->{'modAmount'},
		  $m_ref->{'sfModAmtSrcOper'},  $m_ref->{'sfModTransOper'},
		);
	}
	push @imod_data, ("\0"x10);
    my $imod_ck = new File::Format::RIFF::Chunk;
    $imod_ck->id('imod');
    $imod_ck->data(join('', @imod_data));

	# need to append in order of occurence in Presets and Instruments!!
	my %shdr_hash = %{$sf{'shdr'}};
	my $samples = '';   # append to $samples to be able to measure its length
	my @shdr_data = ();
	my $index = 0;
	foreach my $samplename (@smpl_list) {  # must append in order!!
		# adjust dwStart dwEnd dwStartloop dwEndloop
		my $shdr = $shdr_hash{$samplename};
		my $smpl_length  = $shdr->{'dwEnd'}       - $shdr->{'dwStart'};
		my $to_startloop = $shdr->{'dwStartloop'} - $shdr->{'dwStart'};
		my $to_endloop   = $shdr->{'dwEndloop'}   - $shdr->{'dwStart'};
		my $start;
		$start = (length $samples)/2;
		$samples .= $shdr->{'sampledata'} . "\0"x92;
		push @shdr_data, pack 'a20LLLLLCcSS', $samplename,
		  $start, $start+$smpl_length, $start+$to_startloop,
		  $start+$to_endloop, $shdr->{'dwSampleRate'},
	 	  $shdr->{'byOriginalKey'}, $shdr->{'chCorrection'},
		  $shdr->{'wSampleLink'},   $shdr->{'sfSampleType'},
		$index += 1;
	}
	push @shdr_data, 'EOS'."\0"x43;
	my $shdr_ck = new File::Format::RIFF::Chunk;
	$shdr_ck->id('shdr');
	$shdr_ck->data(join '', @shdr_data);
	my $smpl_ck = new File::Format::RIFF::Chunk;
	$smpl_ck->id('smpl');
	$smpl_ck->data($samples);

	my $sdta = new File::Format::RIFF::List('sdta');
	$sdta->push($smpl_ck);
	my $pdta = new File::Format::RIFF::List('pdta');
	$pdta->push($phdr_ck);
	$pdta->push($pbag_ck);
	$pdta->push($pmod_ck);
	$pdta->push($pgen_ck);
	$pdta->push($inst_ck);
	$pdta->push($ibag_ck);
	$pdta->push($imod_ck);
	$pdta->push($igen_ck);
	$pdta->push($shdr_ck);

	my $riff = new File::Format::RIFF('sfbk');  # section 4.1
	$riff->push($info);
	$riff->push($sdta);
	$riff->push($pdta);
	my $bytes;
	if (! open(P, '>', \$bytes)) {
		warn "can't open in-memory filehandle: $!\n"; return;
	}
	binmode P;
	$riff->write(\*P);
	#warn "RIFF:\n"; $riff->dump();
	close P;
	return $bytes;
}
sub gen_hashref2list { my ($gen_hashref, $is_p_or_i) = @_;
	my @gen_list = (); # list of [sfGenOper,genAmount] listrefs, see 7.5 8.1.1
	my $last_item;
	while (my ($name, $shAmount) = each %{$gen_hashref}) {
		my $sfGenOper = $GenOpname2num{$name};
		my $type = $GenAmountType[$sfGenOper];
		if (! defined $type) {
			warn "unrecognised generator=$generator\n"; return;
		}
		if (($sfGenOper == 41) && ($is_p_or_i eq 'i')) {
			warn "instruments are not allowed in instrument zones\n"; return;
		}
		if (($sfGenOper == 53) && ($is_p_or_i eq 'p')) {
			warn "samples are not allowed in preset zones\n"; return;
		}
		if ($OnlyValidInInstr{$sfGenOper} && ($is_p_or_i eq 'p')) {
			warn "sfGenOper=$sfGenOper not valid in preset zones\n"; next;
		}
		# we leave the instruments and samples referred to by name,
		# to be replaced by an index when we know the list.
		if ($type eq 'x') {
			# unused; ignore
		} elsif ($type eq 'C2') {
			if ($sfGenOper == 43) { # keyRange MUST be first
				unshift @gen_list, [$sfGenOper, @{$shAmount}];
			} else {
				push @gen_list, [$sfGenOper, @{$shAmount}];
			}
		} elsif (($sfGenOper == 41) || ($sfGenOper == 53)) { # MUST be last
			$last_item = [$sfGenOper, $shAmount,];
		} else {
			push @gen_list, [$sfGenOper, $shAmount,];
		}
	}
	# could check for global zone
	if ($last_item) { push @gen_list, $last_item; }
	return @gen_list;
}

sub file2smpl { my ($filename, $original_key, $opt_ref) = @_;
	my %opt = %{$opt_ref};  # noloop
	# NB: from_key, to_key, from_vel, to_vel go in the ibags, not the shdrs
	# we generate $SampleID = $achSampleName from the basename of $filename
	# keeping an eye out for duplicates.
	# $original_key can be fractional, e.g. 60.4
	# looping seems mandatory in sf, so 'noloop' means:
	#   pushing >32 zero-samples onto the end, and looping them.
	# invoke file2raw  then  raw2shdr
	my ($sample_rate, $data) = file2raw($filename);
	if (! defined $data) { return; }
	use File::Basename;
	my $base = basename($filename);
	$base =~s/\.\w\w\w\w?$//;
	my $sample_name = $base;
	if ($SampleName{$sample_name}) {
		my $i = 0;
		while (1) {
			$i += 1;
			$sample_name = $base.'_'.$i;
			if (! $SampleName{$sample_name}) { last; }
		}
	}
	my %shdr = ();
	if ($opt{'noloop'}) {
		my $len = length $data;   # warn "len = $len\n";
		my @zeros = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		@zeros = (@zeros,@zeros,$zeros);   # 48 of them
		%shdr = raw2shdr($sample_name, $original_key, $sample_rate,
		  $data . pack('s<*', @zeros));
		$shdr{$sample_name}->{'dwStartloop'} = $len+4;
		$shdr{$sample_name}->{'dwEndloop'}   = $len+44;
	} else {
		%shdr = raw2shdr($sample_name, $original_key, $sample_rate, $data);
		set_looppoints($shdr{$sample_name});
	}
	return $shdr{$sample_name};
}
sub file2wavsample { my $filename = $_[$[];  # provide a 'noloop' option ?
	# need to know sample_name, byOriginalKey
	# invoke file2raw  then  raw2wavsample
}

sub file2raw { my $file = $_[$[];
	if (! -e $file) { warn "does not exist: $file\n"; return; }
	if (! -f $file) { warn "not a file: $file\n"; return; }
	if (! -r $file) { warn "not readable: $file\n"; return; }
	# Use soxi $file to ascertain the channels and sample-rate
	# (don't use File::Format::RIFF because that only handles .wav files)
	# It would be more elegant if there were a CPAN libsox module...
	if (! open(P, '-|', "soxi",$file)) {
		warn "can't run soxi '$file': $!\n"; return;
	}
	my $channels = 2; my $sample_rate = 44100;
	while (<P>) {
		if (/^Channels\s+:\s*(\d+)/)    { $channels = 0+$1; next; }
		if (/^Sample Rate\s+:\s*(\d+)/) { $sample_rate = 0+$1; next; }
	}
	close P;
	my $tmp; my @data = ();
	if ($channels == 1) {   # if already mono:
		if (! open(P, '-|', "sox '$file' -t raw -c 1 -b 16 -e signed -")) {
			warn "can't run sox '$file': $!\n"; return;
		}
	} else {   # stereo to mono:
		if (!open(P,"sox '$file' -t raw -c 1 -b 16 -e signed - remix 1,2 |")) {
			warn "can't run sox '$file': $!\n"; return;
		}
	}
	while (read P, $tmp, 65536) { push @data, $tmp; }
	close P;
	return ($sample_rate, join('',@data));
}

sub raw2shdr { my ($achSampleName,$original_key,$dwSampleRate,$sampledata)=@_;
	# the 16-bit signed $sampledata might come from a file through file2raw(),
	# but might come from a user-supplied wavetable
	# Do we invoke set_looppoints($sampledata) from here ? noloop option...
	my $byOriginalKey = round($original_key);
	my $chCorrection = round(100 * ($original_key-$byOriginalKey));
	return ($achSampleName => {  # 1.03
      byOriginalKey => $byOriginalKey,
      chCorrection => $chCorrection,
      dwEnd => length $sampledata,
      dwEndloop => $dwEndloop,
      dwSampleRate => $dwSampleRate,
      dwStart => 0,
      dwStartloop => $dwStartloop,
      sampledata => $sampledata,
      sfSampleType => 1,
      wSampleLink => 0
	});
}

sub raw2wavsample { my ($sample_name,$root_freq,$sample_rate,$data)=@_;
	# hopefully you used sox to convert data to .s16 raw signed 16bit mono
	# Need to be able to handle non-looped samples...
	# invoke raw2looppoints( ... , $data);
	return {
	  balance => 7,
	  data => $data,
	  envelope_data => $DefaultEnvelopeData,
	  high_freq => 10000000,
	  loop_end => 87800,
	  loop_start => 87400,
	  low_freq => 20000,
	  mode => 101,
	  root_freq => 440000,
	  sample_name => $sample_name||'NoName',
	  sample_rate => 44100,
	  scale_factor => 1024,
	  scale_freq => 60,
	  tremolo_depth => 0,
	  tremolo_phase => 0,
	  tremolo_sweep => 0,
	  tune => 1,
	  vibrato_ctl => 0,
	  vibrato_depth => 0,
	  vibrato_sweep => 0
	};
}
sub set_looppoints { my $sr = $_[$[]; # shdr_ref_or_wavsample_ref
	# pass it a shdr_ref or a wavsample_ref and it will fill in the
	# dwStartloop and dwEndloop, or loop_start and loop_end, and adjust
	# the sample values in the loop for smoothest possible looping
	my $samples_per_cycle;
	if (defined $sr->{'dwStart'}) {     # it's a soundfont shdr
		# dwStart dwEnd  byOriginalKey chCorrection  dwSampleRate  sampledata
		my @data = unpack 's<*', $sr->{'sampledata'};
		splice @data, $[, round(0.5 * ($[+$sr->{'dwStart'})); # bytes 2 samples
		$sr->{'dwEnd'} -= $sr->{'dwStart'};
		$sr->{'dwStart'} = $[;
		my $samples_per_cycle = $sr->{'dwSampleRate'}
		 / midipitch2freq($sr->{'byOriginalKey'} + 0.01*$sr->{'chCorrection'});
		($start, $end) = raw2looppoints($samples_per_cycle, \@data);
		$sr->{'dwStartloop'} = 2 * $start;  # samples to bytes
		$sr->{'dwEndloop'}   = 2 * $end;    # samples to bytes
		$sr->{'sampledata'}  = pack 's<*', @data;
		return $sr;
	} elsif (defined $sr->{'mode'}) {   # it's a gravis wavsample
		# root_freq  sample_rate  data
		my @data = ();
		if ($MODES_UNSIGNED && $sr->{'data'}) {  # could test 16BIT ?
			@data = unpack 's<*', @{$sr->{'data'}};
		} else {
			@data = unpack 'S<*', @{$sr->{'data'}};
		}
		my $samples_per_cycle = $sr->{'sample_rate'}
		 / ($sr->{'sample_rate'} + $sr->{'tune'});  # check tune spec...
		($start, $end) = raw2looppoints($samples_per_cycle, \@data);
		$sr->{'loop_start'} = $start;  # samples
		$sr->{'loop_end'}   = $end;    # samples
		return $sr;
	} else {
		warn "set_looppoints: neither dwStart nor mode present\n";
		return undef;
	}
}

sub raw2looppoints { my ($samples_per_cycle, $data_ref) = @_;
	# Find the pair of zero-crossings exactly integer cycles apart for which
	# the neighboring samples v[x] are situated in the most similar-in-shape
	# curves, weighting nearby samples heavier of course; return indexes
	# in _samples_ not bytes.  Assume 16-bit signed little-endian.
	my @data = @{$data_ref};
	my @up_crossings = ();
	my @down_crossings = ();
	my $i = $[+1;  while ($i < $#data) {
		if ($data[$i]==0) {
			if ($data[$i-1]>0 and $data[$i+1]<0) { push @down_crossings, $i;
			} elsif ($data[$i-1]<0 and $data[$i+1]>0) { push @up_crossings, $i;
			}
		} elsif (($data[$i-1]>0) and ($data[$i]<0)) { push @down_crossings, $i;
		} elsif (($data[$i-1]<0) and ($data[$i]>0)) { push @up_crossings, $i;
		}
		$i += 1;
	}
warn "there are ".scalar(@up_crossings)." up_crossings\n";
warn "there are ".scalar(@down_crossings)." down_crossings\n";
	my $best_start = $[; my $best_end = $#data; my $best_goodness = 0;
# too slow. must choose a loop_length .1<x<.5 sec closest to a multiple of
# $samples_per_cycle, then look for the several pairs of crossings closest
# to that distance apart, then choose the pair with the best goodness.
	foreach my $is (round(0.75*scalar(@up_crossings)) .. ($#up_crossings-1)) {
		foreach my $ie (($is+1) .. $#up_crossings) {
			my $goodness = goodness_of_fit($is,$ie,$samples_per_cycle,\@data);
			if ($goodness > $best_goodness) {
				$best_start=$is; $best_end=$ie; $best_goodness=$goodness;
			}
		}
	}
	foreach my $is (round(0.75*scalar(@down_crossings))..($#down_crossings-1)){
		foreach my $ie (($is+1) .. $#down_crossings) {
			my $goodness = goodness_of_fit($is,$ie,$samples_per_cycle,\@data);
			if ($goodness > $best_goodness) {
				$best_start=$is; $best_end=$ie; $best_goodness=$goodness;
			}
		}
	}
#warn "best_start=$best_start best_end=$best_end goodness=$best_goodness\n";
	return ($best_start, $best_end);
}
sub smooth_a_loop { my ($start, $end, $samples_per_cycle, $data_ref) = @_;
	# 1) +a*t to line up the end to the curve of the beginning
	# then *b*t so that the graph of power/cycle is as horizontal as possible
	# 2) then make a graph of the power (x*x)/cycle
	# then *b*t so that the graph of power/cycle is as horizontal as possible
}
sub goodness_of_fit { my ($start, $end, $samples_per_cycle, $data_ref) = @_;
	my @data = @{$data_ref};
	# how close is $end-$start to a multiple of the cycle ?
	my $cycles = ($end-$start) / $samples_per_cycle;
	my $cycle_badness = 2.0 * abs($cycles - round($cycles));  # or square?
#warn "cycle_badness=$cycle_badness\n";   # 0..1
	# how close are $end and $start to .8 and .95 of the data ?
	my $size = scalar @data;
	my $space_badness = abs(0.625*($start-(0.8*$size))/$size)
	 + abs(0.475*($end-(0.95*$size))/$size);
	#warn "space_badness=$space_badness\n";   # 0..1
	# how well do the +/-1/4 of a cycle data points match ?
	my $match_badness = 0;
	my $quarter_cycle = round(0.25 * $samples_per_cycle);
	foreach my $i (0 .. $quarter_cycle) {
		my $weight = (1+$quarter_cycle-$i) / $quarter_cycle;
		$match_badness += $weight * abs($data[$end+$i] - $data[$start+$i]);
		$match_badness += $weight * abs($data[$end-$i] - $data[$start-$i]);
	}
	$match_badness = $match_badness / ($quarter_cycle*32000);
	#warn "match_badness=$match_badness\n";   # 0..1
	my $goodness = 1.0 - 0.15*$cycle_badness
	 - 0.15*$space_badness - 0.7*$match_badness;
	#warn "goodness=$goodness\n";   # 0..1
}
sub midipitch2freq { my $pitch = $_[$[];
	return 440 * (1.0594630943348**($pitch-69));
}
sub round   { my $x = $_[$[];
	if ($x > 0.0) { return int ($x + 0.5); }
	if ($x < 0.0) { return int ($x - 0.5); }
	return 0;
}

# --------------------------- gravis routines -----------------------

sub file2gravis { my $file = $_[0];
	my $file_type = filetype($file);
	if ($file_type eq 'pat') {
		my %pat = bytes2pat(file2bytes($file));
		$pat{'filename'} = $file;
		eval 'require File::Basename'; if ($@) {
			die "you'll need to install File::Basename from www.cpan.org\n";
		}
		my ($name,$path,$suffix) = File::Basename::fileparse($file,'.pat');
		return "$name$suffix", \%pat;  # kv, will be assigned into a hash
	} elsif ($file_type eq 'zip') {
		eval 'require Archive::Zip'; if ($@) {
			die "you'll need to install Archive::Zip from www.cpan.org\n";
		}
		# take it apart with Archive::Zip
		my $zip = Archive::Zip->new();
		# if ($zip->read($file) != Archive::Zip::AZ_OK) {
		if ($zip->read($file) != 0) {
			warn "can't read zipfile $file: read error\n"; return undef;
		}
		my @memberNames = $zip->memberNames();
		my @gr;   # key/value/key/value...
		foreach my $memberName ($zip->memberNames()) {
			if ($memberName !~ /\.pat$/) { next; }
			my $bytes = $zip->contents($memberName);
			my %pat = bytes2pat($bytes);
			push @gr, $memberName;
			push @gr, \%pat;
		}
		return @gr;   # kvkv, will be assigned into a hash
	}
}
sub bytes2gravis { my $bytes = $_[0];
	# Archive::Zip only does files, not even filehandles;
	# might have to use /tmp in order to handle urls etc.
	eval 'require File::Temp'; if ($@) {
		die "you'll need to install File::Temp from www.cpan.org\n";
	}
	my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.zip');
	return file2gravis($filename);
}
sub bytes2pat { my $bytes = $_[0];
	my $index = 0;
	my $header = substr $bytes, $index, 129;  $index += 129;
	my ($ID,$manufacturer,$description, $num_instrs,$num_voices,$num_channels,
	  $num_waveforms,$master_vol,$data_length, $reserved)
	  = unpack ('A12 A10 A60 C C C S S L C36', $header);
	my %pat = ();
	# $pat{'manufacturer'} = $manufacturer; ID#000002 is mandatory for timidity
	$description =~ s/\0.*$//s;
	$description =~ tr /\cZ//d;
	$pat{'description'}  = $description;
	$pat{'num_voices'}   = $num_voices;
	$pat{'num_channels'} = $num_channels;
	# $pat{'num_instrs'}   = $num_instrs;
	$pat{'instruments'}  = [];
	foreach (1 .. $num_instrs) {
		my %instr = ();
		my $instr_header = substr $bytes, $index, 63;  $index += 63;
		my ($instr_num, $instr_name, $instr_size, $num_layers, $reserved)
		 = unpack('S A16 L C A40', $instr_header);
		$instr{'instr_num'}  = $instr_num;
		$instr_name =~ s/\0.*$//s;
		$instr_name =~ tr /\cZ//d;
		$instr{'instr_name'} = $instr_name;
		# $instr{'instr_size'} = $instr_size;  # 1.04
		# $instr{'num_layers'} = $num_layers;
		my @layers = ();
		foreach (1 .. $num_layers) {
			my $layer_header = substr $bytes, $index, 47;  $index += 47;
			my ($previous, $id, $size, $num_wavsamples, $reserved)
			 = unpack('C C L C A40', $layer_header);
			my @wavsamples = ();
			foreach (1 .. $num_wavsamples) {
				my $wav_header = substr $bytes, $index, 96;  $index += 96;
				# tremolo: sweep 46, phase 43, depth 32
				# vibrato: sweep 1443, ctl 818, depth 32
				my ($sample_name, $fractions, $data_size, $loop_start,
				 $loop_end, $sample_rate, $low_freq, $high_freq, $root_freq,
				 $tune, $balance, $envelope_data,
				 $tremolo_sweep, $tremolo_phase, $tremolo_depth,
				 $vibrato_sweep, $vibrato_ctl,   $vibrato_depth,
				$mode, $scale_freq, $scale_factor) =
				 unpack('a7 C L L L S L L L S C a12 C6 C S S',$wav_header);
				# see doc/headers.c doc/gravis.c doc/timidity/instrum.c
				# 6 bytes envelope_velf  and  6 bytes envelope_keyf,  ?
				# (or  Filter envelope rate  and  Filter envelope offset ?)
				# perhaps bytes: attack_vol attack_time decay_vol decay_time
				# release_vol final_vol; then attack_freq attack_time
				# decay_freq decay_time release_freq final_freq ?
				# See convert_envelope_rate() and convert_envelope_offset()
				$sample_name =~ s/\0.*$//s;
				my $data=substr $bytes,$index,$data_size; $index+=$data_size;
				push @wavsamples, {
					sample_name => $sample_name,
					loop_start  => $loop_start,
					loop_end    => $loop_end,
					sample_rate => $sample_rate,
					low_freq    => $low_freq,
					high_freq   => $high_freq,
					root_freq   => $root_freq,
					tune    => $tune,
					balance => $balance,
					envelope_data => $envelope_data,
					tremolo_sweep => $tremolo_sweep,
					tremolo_phase => $tremolo_phase,
					tremolo_depth => $tremolo_depth,
					vibrato_sweep => $vibrato_sweep,
					vibrato_ctl   => $vibrato_ctl,
					vibrato_depth => $vibrato_depth,
					mode    => $mode,
					scale_freq    => $scale_freq,
					scale_factor  => $scale_factor,
					# data_size   => $data_size ,
					data    => $data,
				};
			}
			push @layers, {
				previous => $previous, id => $id,
				# num_wavsamples => $num_wavsamples,
				wavsamples => \@wavsamples,
			};
		}
		$instr{'layers'} = \@layers;
		push @{$pat{'instruments'}}, \%instr;
	}
	return %pat;
}

sub pat2bytes {  my %pat = @_;
	use bytes;
	my @pat_data = ();
	my @instruments = @{$pat{'instruments'}};
	my $instr_num = 0;
	my $num_waveforms = 0;
	foreach my $instref (@instruments) {
		my @inst_data = ();
		my @layers = @{$instref->{'layers'}};
		my $previous = 0; my $id = 0;
		my @all_layer_data = ();
		foreach my $layerref (@layers) {
			my @this_layer_data = ();
			my @wavsamples = @{$layerref->{'wavsamples'}};
			foreach my $wref (@wavsamples) {
				my $wave_size = length($wref->{'data'});  # bytes? samples?
				# XXX to relate to  timidity -idvv  I should extract:
				# tremolo: sweep 46, phase 43, depth 32
				# vibrato: sweep 1443, ctl 818, depth 32
				# mode: 0x65
				# ? what's this ?  volume comp: 1.024000
				push @this_layer_data,
				  pack('a7 C L L L S L L L S C a12 C6 C S S C36',
				  $wref->{'sample_name'}, 0, $wave_size,
				  $wref->{'loop_start'}, $wref->{'loop_end'},
				  $wref->{'sample_rate'}, $wref->{'low_freq'},
				  $wref->{'high_freq'}, $wref->{'root_freq'}, $wref->{'tune'},
				  $wref->{'balance'}, $wref->{'envelope_data'},
				  $wref->{'tremolo_sweep'}, $wref->{'tremolo_phase'},
				  $wref->{'tremolo_depth'},
				  $wref->{'vibrato_sweep'}, $wref->{'vibrato_ctl'},
				  $wref->{'vibrato_depth'},
				  $wref->{'mode'},
				  $wref->{'scale_freq'}, $wref->{'scale_factor'}, 0
				);
				push @this_layer_data, $wref->{'data'};
				$num_waveforms += 1;
			}
			unshift @this_layer_data, pack('C C L C A40', $previous, $id,
			  length(join '',@this_layer_data), scalar @wavsamples, '');
			push @all_layer_data, @this_layer_data;
			$previous = $id;  $id += 1;
		}
		my $instr_size = length(join '',@all_layer_data);
		my $num_layers = scalar @layers;
        push @inst_data, pack('S a16 L C A40', $instr_num,
		$instref->{'instr_name'}, $instr_size, $num_layers, '');
        push @inst_data, @all_layer_data;
		push @pat_data, @inst_data;
		$instr_num += 1;
	}
	unshift @pat_data, pack ('a12 a10 a60 C C C S S L C36', 'GF1PATCH110',
	  'ID#000002',   # manufacturer=ID#000002 is mandatory for timidity
	  $pat{'description'}, (scalar @instruments),
	  14, 1, $num_waveforms, 100, length(join '',@pat_data), 0);
	return join '', @pat_data;
}

sub gravis2file { my $file = shift;
	if (! $file) { warn "gravis2file: missing arguments.\n"; return 0; }
	my %gravis = @_;
	if (! %gravis) { warn "gravis2file: missing 2nd argument.\n"; return 0; }
	# write bytes to file, or filehandle (if GLOB), or - is stdout
	eval 'require Archive::Zip'; if ($@) {
		die "you'll need to install Archive::Zip from www.cpan.org\n";
	}
	my @pat_names = sort keys %gravis;
	my $n_pat_names = scalar @pat_names;
	if (($n_pat_names != 1) && ($file =~ /\.pat/)) {
		warn "can't store $n_pat_names patches in one .pat file\n"; return 0;
	}
	if ($file =~ /\.pat/) {
		my $bytes = pat2bytes(%{$gravis{$pat_names[0]}});
		if (! $bytes) { return 0; }   # pat2bytes has already warned
		if (! open(F, '>', $file)) { warn "can't open $file:$!\n"; return 0; }
		print F $bytes;   close F;
	} elsif ($file =~ /\.zip/) {   # 1.01
		eval 'require Archive::Zip'; if ($@) {
			die "you'll need to install Archive::Zip from www.cpan.org\n";
		}
		my $zip = Archive::Zip->new();
		foreach my $pat_name (@pat_names) {
			my $bytes = pat2bytes(%{$gravis{$pat_name}});
			if (0 == length $bytes) { warn "gravis{$pat_name} was empty\n"; }
			if ($bytes) { my $member = $zip->addString($bytes,$pat_name); }
		}
		if ($zip->overwriteAs($file) != 0) {
			warn "can't write zipfile $file: write error\n"; return 0;
		}
	} else {
		warn "it has to be either a .pat or a .zip file\n"; return 0;
	}
	return 1;
}

sub new_pat {
	# See doc/timidity/instrum.[ch]
	# MODES_16BIT    1  MODES_UNSIGNED 2  MODES_LOOPING   4  MODES_PINGPONG  8
	# MODES_REVERSE 16  MODES_SUSTAIN 32  MODES_ENVELOPE 64  MODES_CLAMPED 128
	return (
		description  => 'description of patch',
		filename     => 'filename of patch',
		num_channels => 0,
		num_voices   => 14,
		instruments => [
			{
				instr_name => 'instrument name',
				instr_num  => 'instrument number',
				layers => [
					{
						id => 0,
						previous => 0,
						wavsamples => [
							{
								balance => 7,
								data => ' ... ',
								envelope_data => $DefaultEnvelopeData,
								high_freq => 10000000,
								loop_end => 266282,
								loop_start => 149902,
								low_freq => 20000,
								mode => 1+4+32+64,
								root_freq => 261625,
								sample_name => 'name of sample',
								sample_rate => 44100,
								scale_factor => 1024,
								scale_freq    => 69,
								tremolo_depth => 0,
								tremolo_phase => 0,
								tremolo_sweep => 0,
								vibrato_depth => 0,
								vibrato_ctl => 0,
								vibrato_sweep => 0,
								tune => 1,
							}
						]
					},
       			],
			},
		],
	);
}

sub timidity_cfg { my $file = shift; my %sf_or_gr = @_;
	eval 'require File::Basename'; if ($@) {
		die "you'll need to install File::Basename from www.cpan.org\n";
	}
	my @cfg = ('#  See  man timidity.cfg ...');   # array of lines
	if ($sf_or_gr{'ifil'}) {   # it's a sf
		my ($name,$path,$suffix) = File::Basename::fileparse($file,'.sf2');
		my $current_bank = -1;
		push @cfg, "dir $path";
		my @phdr_list = sort { (1000*$a->{'wBank'}+$a->{'wPreset'})
		  <=> (1000*$b->{'wBank'}+$b->{'wPreset'})} @{$sf_or_gr{'phdr'}};
		foreach my $a (@phdr_list) {
			my $patch = $a->{'wPreset'};
			my $bank  = $a->{'wBank'};
			my $pname = $a->{'achPresetName'};
			if ($bank != $current_bank) {
				push @cfg, "bank $bank   # $bank,0  cc0=$bank cc32=0";
				$current_bank = $bank;
			}
			push @cfg, "$patch %font $name.sf2 $bank $patch   # $pname";
		}
	} else {  # it's a gr
		my @patnames = sort keys %sf_or_gr;
		my $bank = 0;
		if (1 == scalar @patnames) {
			push @cfg, "bank $bank   # $bank,0  cc0=$bank cc32=0";
			push @cfg, "0 /home/gravis/$patnames[0]";
		} else {
			push @cfg, "dir $file#";
			push @cfg, "bank $bank   # $bank,0  cc0=$bank cc32=0";
			my @barenames = @patnames;
			foreach (@barenames) { s/\.pat$//; }
			my %unpaired_barename = map {$_,1} (@barenames);
			eval 'require String::Approx'; if ($@) {
				warn "for more appropriate patch numbers "
				  . "you need the String::Approx module\n";
			} else {
				eval 'require MIDI'; if ($@) {
					warn "you need to install the MIDI-Perl module\n";
				} else {
					push @cfg, '# the bank 0 patches have been assigned by '
					  . 'approximate string matching';
					push @cfg, '# to the general-midi patches; '
					  . "you'll probably want to edit them...";
					# for each patname note the distance to each gmname
					# then as long as their are patnames which are the closest
					# of more than one gmname, the patname chooses the closest
					# and the other(s) forget their first pref, and next;
					# when there are no further contested patchnames every
					# remaining first choice is fulfilled.
					# any remaining patchnames are presented alphabetically.
					my @suitors = ();
					# $suitors[$gm_pnum] = [$barename=>$distance, ...]
					my %gm_pn2barename = ();
					foreach my $gm_pnum (0..127) {
						my $gm_patch = $MIDI::number2patch{$gm_pnum};
						my %dh;  @dh{@barenames}= map { abs }
						 String::Approx::adistr($gm_patch, @barenames);
						my @da = sort { $dh{$a} <=> $dh{$b} } @barenames;
						my @da2dist = ();  foreach (@da) {
							push @da2dist, $_, $dh{$_};
						}
						$suitors[$gm_pnum] = \@da2dist;
					}
					# then patchnums first-pick-of-more-than-one-suitor, choose
					# closest until remaining first choices can be fulfilled
					my %unpaired_gm_pnum  = map {$_,1} (0..127);
					while (1) {
						# go through the unpaired_gm_pnums seeking 1st
						# .pat, and note the .pat which occurs most often
						my %pat2gmtarget = (); # hash of [gm_pn,distance, ..]
						my $pat_with_most_gmtargets = undef;
						my $most_targets = 0;
						my @unpaired_gm_pnums
						  = sort {0+$a<=>0+$b} keys %unpaired_gm_pnum;
						if (! @unpaired_gm_pnums) { last; }
						my @unpaired_barenames = sort keys %unpaired_barename;
						if (! @unpaired_barenames) { last; }
						foreach my $gm_pnum (@unpaired_gm_pnums) {
							if ($gm_pn2barename{$gm_pnum}) { next; }
							my @suitrs = @{$suitors[$gm_pnum]};
							$pat2gmtarget{$suitrs[0]} += 1;
							if ($pat2gmtarget{$suitrs[0]} > $most_targets) {
								$pat_with_most_gmtargets = $suitrs[0];
								$most_targets = $pat2gmtarget{$suitrs[0]};
							}
						} 
						if ($most_targets == 0) { last; }
						if ($most_targets > 1.5) {  # barename's choice!
							my $closest_gm_pnum = undef;
							my $closest_gm_dist = 10**30;
							foreach my $gm_pnum (@unpaired_gm_pnums) {
								my @suitrs = @{$suitors[$gm_pnum]};
								if ($suitrs[0] eq $pat_with_most_gmtargets) {
									if ($suitrs[1] < $closest_gm_dist) {
										$closest_gm_pnum = $gm_pnum;
										$closest_gm_dist = $suitrs[1];
									}
								}
							}
							# if (! defined $closest_gm_pnum) { last; }
							$gm_pn2barename{$closest_gm_pnum}
							  = $pat_with_most_gmtargets;
							delete $unpaired_gm_pnum{$closest_gm_pnum};
							delete $unpaired_barename{$pat_with_most_gmtargets};
							# chop $suitrs[0,1] off the lists of the losers
							foreach my $gm_pnum (@unpaired_gm_pnums) {
								while (@{$suitors[$gm_pnum]}) {
									my @suitrs = @{$suitors[$gm_pnum]};
									if ($unpaired_barename{$suitrs[0]}) {last;}
									shift @{$suitors[$gm_pnum]};
									shift @{$suitors[$gm_pnum]};
								}
							}
							next;
						}
						# none left: fulfill all remaining first choices
						foreach my $gm_pnum (@unpaired_gm_pnums) {
							 my @suitrs = @{$suitors[$gm_pnum]};
							$gm_pn2barename{$gm_pnum} = $suitrs[0];
							delete $unpaired_barename{$suitrs[0]};
							delete $unpaired_gm_pnum{$gm_pnum};
						}
					}
					foreach my $k (sort {$a<=>$b} keys %gm_pn2barename) {
						push @cfg, "$k $gm_pn2barename{$k}.pat";
					}
					if (%unpaired_barename) {
						$bank = 1;
						push @cfg, "bank $bank   # $bank,0  cc0=$bank cc32=0";
					}
				}
			}
			my $patch = 0;
			foreach my $bn (sort keys %unpaired_barename) {
				if ($patch >= 127) {
					$bank += 1;
					push @cfg, "bank $bank   # $bank,0  cc0=$bank cc32=0";
					$patch = 0;
				}
				push @cfg, "$patch $bn.pat";
				$patch += 1;
			}
		}
	}
	return join("\n",@cfg,"\n");   # could detect wantarray ...
}

# ----------------------- infrastructure -----------------------------
sub zero_pad_to_even { my $str = $_[$[];
	if (length($str) % 2) { return "$str\0" } else { return "$str\0\0"; }
}
sub filetype { my $f = $_[$[];
	if (! open(F, $f)) { warn "can't open $f: $!\n"; return undef; }
	read F, my $s, 12;
	close F;
	if ($s =~ /^RIFF....sfbk/) { return 'sf2'; }
	if ($s =~ /^PK/)           { return 'zip'; }
	if ($s =~ /^GF1PATCH/)     { return 'pat'; }
	if ($f =~ /.sf2$/) { return 'sf2'; }
	if ($f =~ /.zip$/) { return 'zip'; }
	if ($f =~ /.pat$/) { return 'pat'; }
	return '';
}

1;

__END__

=pod

=head1 NAME

MIDI::SoundFont - Handles .sf2 SoundFont and .pat and .zip Gravis files

=head1 SYNOPSIS

 use MIDI::SoundFont();
 use Data::Dumper(Dumper);
 $Data::Dumper::Indent = 1;  $Data::Dumper::Sortkeys = 1;

 my %sf = MIDI::SoundFont::file2sf('doc/Jeux14.sf2');
 open (P, '|-', 'less'); print P Dumper(\%sf); close P;
 MIDI::SoundFont::sf2file('/tmp/Jeux15.sf2', %sf);

 my %gus = MIDI::SoundFont::file2gravis('gravis/Gravis.zip');
 open (P, '|-', 'less'); print P Dumper(\%gus); close P;
 MIDI::SoundFont::gravis2file('/tmp/Gravis2.zip', %gus);

 print MIDI::SoundFont::timidity_cfg('/home/me/Gr.zip',%gus);
 print MIDI::SoundFont::timidity_cfg('/home/me/Sf.sf2',%sf);

=head1 DESCRIPTION

This module offers a Perl interface to ease the manipulation of
I<SoundFont> and I<Gravis> files.

This module loads these files into a Perl associative array
whose structure is documented in the section
IN-MEMORY SOUNDFONT FORMAT
or
IN-MEMORY GRAVIS FORMAT
below.

Nothing is exported by default,
but all the documented functions can be exported, e.g.:
 use MIDI::SoundFont(file2sf, sf2file);

No functions are provided to manipulate the I<.pat>
members in a Gravis I<.zip> archive; to do this work
you should use I<Archive::Zip> directly.

Future versions should offer translation between I<Gravis> and
I<SoundFont> formats, and should also allow importing a B<.wav> snippet
into a patch by automatically detecting the optimal I<StartLoop>
and I<EndLoop> points. These features are currently unimplemented.

=head1 IN-MEMORY SOUNDFONT FORMAT

See:

 perl examples/sf_list doc/Jeux14.sf2 | less
 perl examples/sf_list -b 0 -p 17 -l  doc/Jeux14.sf2 | less

I<file2sf($filename)> returns a hash with keys:
I<ifil>,
I<isng>,
I<INAM>,
I<irom>,
I<iver>,
I<ICRD>,
I<IENG>,
I<IPRD>,
I<ICOP>,
I<ICMT> and
I<ISFT>
which have scalar values
(see http://www.pjb.com.au/midi/sfspec21.html#i5
), and the keys:
I<phdr>
whose value is an arrayref, and
I<inst> and
I<shdr>
whose values are hashrefs.

Each item of the I<phdr> array is a B<Preset>
("Preset" is a SoundFont term which means
substantially the same as the MIDI "Patch"),
which is a hashref with the following keys:
I<achPresetName> is the Patch-name,
I<wBank> is the MIDI Bank-number,
I<wPreset> is the MIDI Patch-number
( see http://www.pjb.com.au/midi/sfspec21.html#7.2 ),
plus I<pbags> which is an arrayref.
Each I<pbag> is a hashref with the following keys:
I<modulators> which is an arrayref
( see http://www.pjb.com.au/midi/sfspec21.html#7.4 ) and
I<generators> which is a hashref
( see http://www.pjb.com.au/midi/sfspec21.html#7.5 ).
The I<generators> is where most of the action is
( see http://www.pjb.com.au/midi/sfspec21.html#8.1.3 ),
and particularly crucial is I<instrument>
which tells the Patch (i.e. Preset) which Instrument it will be using.

Each key of the I<inst> hash is an Instrument-name,
( see http://www.pjb.com.au/midi/sfspec21.html#7.6 ),
and each value is an B<Instrument>
( see http://www.pjb.com.au/midi/sfspec21.html#8.5 ),
which is a hashref with just one key:
I<ibags> whose value is an arrayref.
Each I<ibag> is a hashref with the following keys:
I<modulators> which is an arrayref
( see http://www.pjb.com.au/midi/sfspec21.html#7.8 ) and
I<generators> which is a hashref
( see http://www.pjb.com.au/midi/sfspec21.html#7.9 ).
The I<generators> is where most of the action is
( see http://www.pjb.com.au/midi/sfspec21.html#8.1.3 ),
and particularly crucial is I<sampleID>
which (at last!) tells the Instrument and hence the Preset
which B<Sample> it will be using :-)

Each item of the I<shdr> array is a B<Sample>
which is a hashref with the following keys, which all have scalar values:
I<achSampleName>,
I<dwStart>,
I<dwEnd>,
I<dwStartloop>,
I<dwEndloop>,
I<dwSampleRate>,
I<byOriginalKey>,
I<chCorrection>,
I<wSampleLink> and
I<sfSampleType>
( see http://www.pjb.com.au/midi/sfspec21.html#7.10 ),
plus I<sampledata>,
which (at last!!) contains the (16-bit signed little-endian) audio data.

The Patch-names ( I<achPresetName> ) must be unique,
the Instrument-names ( I<achInstName> ) must be unique, and
the Sample-names ( I<achSampleName> ) must be unique.

=head1 IN-MEMORY GRAVIS FORMAT

See:
  perl examples/sf_list gravis/fiddle.pat | less

I<file2gravis($filename)> returns a hash with keys:
I<description>,
I<filename>,
I<num_channels>, and
I<num_voices>,
which have scalar values, and
I<instruments> whose value is an arrayref (although in practice
I've never met a patch-file with more than one instrument).
The I<instrument> is a hash with keys:
I<instr_name> and
I<instr_num>,
which have scalar values, and
I<layers> whose value is an arrayref.
Each I<layer> has keys:
I<id> and
I<previous>,
which have scalar values (apparently unused), and
I<wavsamples> whose value is an arrayref.
Each I<wavsample> is a hash with keys:
I<balance>,
I<data>,
I<envelope_data>,
I<high_freq>,
I<loop_end>,
I<loop_start>,
I<low_freq>,
I<mode>,
I<root_freq>,
I<sample_name>,
I<sample_rate>,
I<scale_factor>,
I<scale_freq>,
I<tremolo_depth>,
I<tremolo_phase>,
I<tremolo_sweep>,
I<vibrato_depth>,
I<vibrato_ctl>,
I<vibrato_sweep> and
I<tune>,
which have scalar values.

Unlike the SoundFont format,
the frequencies I<low_freq>, I<high_freq> and I<root_freq>
are in thousandths of a Hz,
and the I<loop_start> and I<loop_end> are in bytes, not samples.

The I<mode> bits describes the format of the I<data>,
and the following package variables can be imported with
I<use MIDI::SoundFont(':CONSTS');>
MODES_16BIT=1  MODES_UNSIGNED=2  MODES_LOOPING=4  MODES_PINGPONG=8
MODES_REVERSE=16  MODES_SUSTAIN=32  MODES_ENVELOPE=64  MODES_CLAMPED=128

See:
I<doc/gravis.txt>
I<doc/headers.c>
I<doc/timidity/instrum.c>
I<doc/timidity/instrum.h>
I<doc/timidity/playmidi.c>
I<doc/wav2pat.c> and
I<ftp://ftp.gravis.com/Public/Sdk/>
for more details of what the values mean.
The tremolo and vibrato data displayed by
B<timidity -idvv -x 'bank 0\n0 ./gravis/fiddle.pat'>
are different from the values of the tremolo and vibrato variables above,
because the I<timidity> variables have been multiplied by corresponding
control ratios: see I<doc/timidity/instrum.c>

See:
I<test.pl>,
I<examples/make_bank5> and
I<examples/sf_list> for examples manipulating this data-structure.

=head1 SOUNDFONT FILE-FORMAT

Fortunately, there exists authoritative and clear documentation
of the SoundFont file format:
http://connect.creativelabs.com/developer/SoundFont/sfspec21.pdf
Unfortunately, it's a fairly hard format to work with...

A SoundFont-2 compatible RIFF file comprises three chunks:
an INFO-list chunk containing a number of required and optional sub-chunks
describing the file, its history, and its intended use, see
http://www.pjb.com.au/midi/sfspec21.html#i5

an SDTA-list chunk comprising a single sub-chunk containing any
referenced digital audio samples, see
http://www.pjb.com.au/midi/sfspec21.html#i6

and a PDTA-list chunk containing nine sub-chunks which define
the articulation of the digital audio data, see
http://www.pjb.com.au/midi/sfspec21.html#i7

=head1 GRAVIS FILE-FORMAT

The files I<doc/gravis.txt>, I<doc/headers.c> and I<doc/wav2pat.c>
disagree somewhat about the file format.
Most authoritative is the TiMidity source in I<doc/timidity/>,
but it's also somewhat hard to interpret.
The format adopted here seems to work with all patches in I<gravis/Gravis.zip>

Several of the parameters seem obscure: for example,
I<num_channels> is often zero, when it should be either 1 or 2,
and I<instr_num> is either zero or, in non-Gravis patches, usually random.
In the I<wavsample> section, I<low_freq> and I<high_freq> seem large
(perhaps in thousandths of Hz? See:
I<ftp://ftp.gravis.com/Public/Sdk/PATCHKIT.ZIP>).
These are the parameters that must correspond to the SoundFont I<key range>,
allowing different wavsamples to be used for different tessituras.
See:
  perl examples/sf_list gravis/fiddle.pat | less


=head1 FUNCTIONS

=over 3

=item %sf = file2sf($filename)

Reads the file, which should be a SoundFont file, and converts it
to the data-structure documented above in the
IN-MEMORY SOUNDFONT FORMAT
section.

The I<filename> can also be a URL, or B<-> meaning I<STDIN>

=item sf2file($filename, %soundfont)

Converts a data-structure as documented above in the
IN-MEMORY SOUNDFONT FORMAT
section into a file as documented in the
SOUNDFONT FILE-FORMAT
section.

=item %sf = new_sf($inam)

Returns a minimal empty soundfont data-structure as documented above in the
IN-MEMORY SOUNDFONT FORMAT section.
The optional argument I<$inam> sets the 'INAM' value.
You can then change I<$sf{'INAM'}> and I<$sf{'phdr'}[0]{'wPreset'}>
or push onto I<@{$sf{'phdr'}}> and so on.
See I<examples/make_bank5> in the I<examples/> directory.

=item %gr = file2gravis($filename)

Reads the file, which should be either a Gravis B<.pat> patch-file,
or a B<.zip> archive of patch-files, and converts it to the
data-structure documented above in the IN-MEMORY GRAVIS FORMAT section.

The I<filename> can also be a URL, or B<-> meaning I<STDIN>

=item gravis2file($filename, %gravis)

Converts a data-structure as documented above in the
IN-MEMORY GRAVIS FORMAT
section either into a B<.pat> patch-file as documented in the
GRAVIS FILE-FORMAT section,
or into a B<.zip> archive of patch-files.

=item %sf = new_pat()

Returns a minimal empty I<patch> data-structure;
the reference to this is a I<value> in the gravis data-structure
documented above in the IN-MEMORY GRAVIS FORMAT section,
the I<key> being the filename it will get when given a home in a I<.zip> file.
See I<examples/make_bank5> in the I<examples/> directory.

=item timidity_cfg($filename, %sf_or_gravis)

This returns a suggested I<timidity.cfg> paragraph to
allow you to use your soundfont, or gravis patch or zip, in I<timidity>.
The B<filename> is the I<.sf2> or I<.pat> or I<.zip> file
in which it resides, or will reside.

You should insert the resulting string into your I<timidity.cfg> by hand,
using your favourite text editor,
because there are bound to be things you'll want to change.

For Gravis I<.zip> archives, the I<String::Approx> module
is used to guess some General-Midi-conformant patch-numbers.

=back

=head1 EXAMPLES

Five simple examples in the I<examples/> subdirectory
are already useful applications:

=over 3

=item sf_list

I<sf_list> displays, in a readable format, a list of
the Patches available in a .sf2 SoundFont file, or in a Gravis .zip archive,
or the contents of a Gravis .pat patch-file.
It displays the Patches in a readable format, e.g.:
  bank 8 patch 17  # Detuned Organ 2

It also has options B<-l> for long, detailed output,
and B<-b> and B<-p> to restrict the choice to particular Banks and Patches,
and a B<-c> option to suggest a paragraph for your I<timidity.cfg>

=item sf_edit

I<sf_edit> is a I<Term::Clui> application which allows certain simple
operations such as moving Banks, deleting Patches.

=item make_bank5

I<make_bank5> puts together a I<SoundFont> file from scratch, using some
simple waveforms, and then puts together some substantially identical
I<Gravis> patches.
These files can be used successfully both by I<timidity> and by I<csound>,
which is a reasonable test of
MIDI::SoundFont's conformance to the file-formats.
See:
http://www.pjb.com.au/midi/free/Bank5.sf2
http://www.pjb.com.au/midi/free/SawtoothToTriangle.pat
and
http://www.pjb.com.au/midi/free/SquareToSine.pat

=item csound_scoresynth.csd

I<csound_scoresynth.csd> evolves from the script
explained on page 148 of the book I<Csound Power> by Jim Aikin.
It shows how to load a SoundFont into I<csound> and play its notes
directly from the I<Score> section of the I<.csd> file.

It assumes you have run I<make_bank5>,
so that the SoundFont I</tmp/Bank5.sf2> already exists.

=item csound_midisynth.csd

I<csound_midisynth.csd> evolves from the script I<fluidcomplex.csd>
by Istvan Varga, as included in the I<csound> documentation.
It shows how to load a SoundFont into I<csound>
and play its notes using a midi keyboard,
which you will have to connect by hand
using some command such as I<aconnect ProKeys 14:0>

It assumes you have run I<make_bank5>,
so that the SoundFont I</tmp/Bank5.sf2> already exists.

=back

=head1 DOWNLOAD

This module is available from CPAN at
http://search.cpan.org/perldoc?MIDI::SoundFont

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://search.cpan.org/perldoc?MIDI::SoundFont
 http://search.cpan.org/perldoc?File::Format::RIFF
 http://search.cpan.org/perldoc?File::Format::RIFF::Container
 http://search.cpan.org/perldoc?Archive::Zip
 http://search.cpan.org/perldoc?File::Temp
 http://search.cpan.org/perldoc?String::Approx
 http://connect.creativelabs.com/developer/SoundFont/sfspec21.pdf
 http://www.pjb.com.au/midi/sfspec21.html
 http://www.onicos.com/staff/iz/timidity/dist/tools-1.1.0/wav2pat.c
 http://timidity.sourceforge.net
 ftp://ftp.gravis.com/Public/Sdk/
 http://www.csounds.com/manual/html/fluidEngine.html
 http://www.csounds.com/manual/html/fluidNote.html
 http://www.csounds.com/manual/html/fluidLoad.html
 "Csound Power" by Jim Aikin, Course Technology, Cengage Learning, 2013,
   ISBN-13 978-1-4354-6004-1
   ISBN-10 1-4354-6004-9
 man timidity         - (1) MIDI-to-WAVE converter and player
 man timidity.cfg     - (5) configure file of TiMidity++

=cut

