package GSM::SMS::Support::RTTTL2MIDI;

use strict;
use vars qw(@ISA @EXPORT $VERSION $error_rtttl %rtl_props @rtl_notes $rtl_name);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(Rtttl2Midi); 
$VERSION = 0.1;

$rtl_name  = "";
%rtl_props = ();
@rtl_notes = ();
$error_rtttl = "Yaketysax:d=4,o=5,b=125:8d.,16e,8g,8g,16e,16d,16a4,16b4,16d,16b4,";
$error_rtttl .="8e,16d,16b4,16a4,16b4,8a4,16a4,16a#4,16b4,16d,16e,16d,g,p,16d,16e,";
$error_rtttl .="16d,8g,8g,16e,16d,16a4,16b4,16d,16b4,8e,16d,16b4,16a4,16b4,8d,16d,";
$error_rtttl .="16d,16f#,16a,8f,d,p,16d,16e,16d,8g,16g,16g,8g,16g,16g,8g,8g,16e,8e.,";
$error_rtttl .="8c,8c,8c,8c,16e,16g,16a,16g,16a#,8g,16a,16b,16a#,16b,16a,16b,8d6,16a,";
$error_rtttl .="16b,16d6,8b,8g,8d,16e6,16b,16b,16d,8a,8g,g";


sub Rtttl2Midi {
	my($xrtttl,$program) = @_;
	   $program = 1 unless defined $program;
	my $status = pharse_rtttl($xrtttl);
	if ($status == 0) { 
		$rtl_name  = "";
		%rtl_props = ();
		@rtl_notes = ();
	
		$xrtttl = $error_rtttl;
		pharse_rtttl($xrtttl);
	}

	my ($head, $track_data, $track_head, $midi);

	$head	     = mf_write_header_chunk(0,1,384);
	$track_data  = copy_right();
	$track_data .= track_name("MIDI by RTTTL2MIDI");
	$track_data .= volumeup();
	$track_data .= mf_write_tempo($rtl_props{b});
	$track_data .= add_program($program);
	$track_data .= notes2midi();
	$track_data .= end_track();
	$track_head  = mf_write_track_chunk($track_data);
	$midi	     = $head . $track_head . $track_data;
	return($midi);
}

sub clean_spaces {
	my ($str) = @_;
	    $str =~ s/\s//g;
	return($str);
}

sub pharse_rtttl {
	my ($str) = @_;
	my ($name,$defaults,$notes) = split /:/, $str;
	unless($name=~/[a-zA-Z0-9]/ && length($name) < 32) { return 0; }
    map { my($n,$v) = split /=/, $_; $rtl_props{$n} = $v; } split /,/, $defaults;
	unless($rtl_props{d} =~ /\d+/) { return 0; }
	unless($rtl_props{o} =~ /\d+/) { return 0; }
	unless($rtl_props{b} =~ /\d+/) { return 0; }
	my($dotted, $i, $r) = 0;
	my @nts = split /,/, clean_spaces($notes);
	for($i=0; $i < @nts; $i++) {
		my($d,$n,$s,$x) = ($nts[$i] =~ /(\d*)([a-z]#?)(\d*)(\.?)/);
	        #duration, note, oktav, dot
		unless($d =~ /\d*/)     { return 0; }
		unless($n =~ /[a-z]#?/) { return 0; }
		unless($s =~ /\d*/)     { return 0; }
		unless($x =~ /\.?/)     { return 0; }
		$dotted = ($x eq ".") ? 1:0;
		$d = $rtl_props{d} if($d == "");
		$s = $rtl_props{o} if($s == "");
		$rtl_notes[$i] = ([$d,$n,$s,$dotted]);
		$r = 1;
	}
	return($r);
}

sub eputc {
	my($input) = @_;
	return(chr($input));
}

sub write32bit  {
	my ($data) = @_;
	my $r;
        $r .= eputc((($data >> 24) & 0xff));
   	$r .= eputc((($data >> 16) & 0xff));
        $r .= eputc((($data >> 8 ) & 0xff));
   	$r .= eputc(($data & 0xff));
	return($r);
}

sub write16bit {
	my ($data) = @_;
	my $r;
        $r .= eputc((($data & 0xff00) >> 8));
   	$r .= eputc(($data & 0xff));
	return($r);
}	

sub mf_write_header_chunk {
	my ($format, $ntracks, $division) = @_;
	my $ident = 0x4d546864;
	my $length = 6;
	my $r;
	   $r .= write32bit($ident);
           $r .= write32bit($length);
           $r .= write16bit($format);
           $r .= write16bit($ntracks);
           $r .= write16bit($division);
	return($r);
}

sub mf_write_track_chunk {
	my ($track) = @_;
	my $trkhdr = 0x4d54726b;
	my $r;
  	   $r .= write32bit($trkhdr);
	   $r .= write32bit(length($track));
	return($r);
}

sub WriteVarLen {
	my ($value) = @_;
	my $buffer=0;
	my $r;
	   $buffer = $value & 0x7f;
  	   while(($value >>= 7) > 0) {
		  $buffer <<= 8;
		  $buffer |= 0x80;
		  $buffer += ($value & 0x7f);
	   }
	   while(1) {
		  $r .= eputc(($buffer & 0xff));
			if($buffer & 0x80) {
			   $buffer >>= 8;
			} else {
			return($r);
			}
	   }
}

sub mf_write_tempo {
	my ($t) = @_;
	my $tempo  = (60000000.0 / ($t));
        my $r;
	   $r .= eputc(0);
	   $r .= eputc(0xff);
	   $r .= eputc(0x51);
	   $r .= eputc(3);
	   $r .= eputc((0xff & ($tempo >> 16)));
	   $r .= eputc((0xff & ($tempo >> 8)));
	   $r .= eputc((0xff & $tempo));
	return($r);
}

sub mf_write_midi_event {
	my ($delta_time, $type, $chan, @data) = @_;
    	my $i;
    	my $c = 0;
    	my $r = WriteVarLen($delta_time);
	   $c = $type | $chan;
	   $r .= eputc($c);
	    for($i = 0; $i < @data; $i++) {
		$r .= eputc($data[$i]);
	    }
	return($r);
}

sub data {
	my($p1,$p2) = @_;
	my @r;
	   $r[0] = $p1;
	   $r[1] = $p2;
	return @r;
}

sub data1 {
	my($p1)=@_;
	my @r;
	   $r[0] = $p1;
	return @r;
}

sub end_track {
	my $r;
	$r .= eputc(0);
	$r .= eputc(0xFF);
	$r .= eputc(0x2f);
	$r .= eputc(0);
	return($r);
}

sub add_program {
	my ($prg) = @_;
	my $r;
	   $r = mf_write_midi_event(0,0xc0,0,data1($prg));
	return($r);
}

sub note {
	my($s, $d, $p, $td) = @_;
	my $r;
	   $r .= mf_write_midi_event($s,0x90,0,data($p,100));
	   $r .= mf_write_midi_event($d,0x80,0,data($p,0));
	   return($r);
}

sub volume {
	my $r = "";
	return($r);
}

sub copy_right {
	my $c = "Rtttl2Midi CopyRight under GPL written by sanalCell.com 2001";
	my $r;
	   $r .= eputc(0);
           $r .= eputc(0xff);
           $r .= eputc(0x02);
	   $r .= eputc(length($c));
	   $r .= $c;
	return($r);
}

sub track_name {
	my($c) = @_;
	my $r;
	   $r .= eputc(0);
	   $r .= eputc(0xff);
	   $r .= eputc(0x03);
	   $r .= eputc(length($c));
	   $r .= $c;
	return($r);
}

sub volumeup() {
	my $r;
	   $r = mf_write_midi_event(0,0xB0,0,data(0x07,127));
	return($r);
}

sub get_pitch {
	my($nt,$oc) = @_;
	   $nt = lc(clean_spaces($nt));
	my $r =0;
	my %n =("p"     =>  -1,
	        "c"     =>   0,
	        "c#"    =>   1,
	        "d"     =>   2,
	        "d#"    =>   3,
	        "e"     =>   4,
	        "f"     =>   5,
	        "f#"    =>   6,
	        "g"     =>   7,
	        "g#"    =>   8,
	        "a"     =>   9,
	        "a#"    =>  10,
        	"b"     =>  11);
		#h=b
	$r = $n{$nt};
	if($r != -1) {
	      $r = 12 + (12*$oc) + $r;
	}
	return($r);
}

sub get_time {
	my($t, $isd) = @_;
	my $r = 0;
	my %d =("1"	=>	1536,
		"2"	=>	768,
		"4"	=>	384,
		"8"	=>	192,
		"16"	=>	96,
		"32"	=>	48,
		"64"	=>	24);
	$r = $d{$t};
	if($isd) {
		$r = $r + ($r/2);
	}
	return($r);
}

sub notes2midi {
	my ($r,$alldata);
	my ($a, $pt, $tm, $rest) = 0;	
	for($a = 0; $a != @rtl_notes; $a++) {
		$pt = get_pitch($rtl_notes[$a][1],$rtl_notes[$a][2]-1);
		$tm = get_time($rtl_notes[$a][0],$rtl_notes[$a][3]);

		if($pt == -1) {
			$rest = $tm;
		} else {
			$alldata .= note($rest,$tm,$pt,$r);
			$rest = 0;
		}
	}
	return($alldata);
}

1;

=head1 NAME

GSM::SMS::Support::RTTTL2MIDI

=head1 SYNOPSIS

 use GSM::SMS::Support::RTTTL2MIDI;

 print "Content-type: audio/x-midi\n\n";
 print Rtttl2Midi($rtttl_string, $piano);

=head1 DESCRIPTION

Converts rtttl strings to midi sound. Also you can set piano
like Hammod Organ (17) and Grand Piano (1).

=head1 METHODS

=head2 Rtttl2Midi($strRTTTL, $piano)

Generate a binary midi stream from $strRTTTL, using $piano as the
instrument.

=head1 AUTHOR

Ethem Evlice <webmaster@tuzluk.com>
