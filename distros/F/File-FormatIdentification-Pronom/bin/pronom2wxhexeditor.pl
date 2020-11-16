#!/usr/bin/env perl
#===============================================================================
#
#         FILE: pronom2wxhexeditor.pl
#
#        USAGE: ./pronom2wxhexeditor.pl
#
#  DESCRIPTION: perl ./pronom2wxhexeditor.pl <DROIDSIGNATURE-FILE> <BINARYFILE>
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Andreas Romeyke,
#      CREATED: 28.08.2018 14:26:43
#     REVISION: ---
#===============================================================================
# PODNAME: pronom2wxhexeditor.pl
use strict;
use warnings 'FATAL';
use utf8;
use feature qw(say);
use Fcntl qw(:seek);
use Digest::CRC qw( crc8 );
use Scalar::Util;
use File::Map qw(:map :extra);
use File::FormatIdentification::Pronom;
use Getopt::Long;
use Carp;

# calc a random color
sub rndcolor {
    my $rgb = int( rand( 256 * 256 * 256 ) );
    return sprintf( "#%06x", $rgb );
}

sub puidcolor {
    my $puid = shift;
    my $crc  = crc8($puid);
    return sprintf( "#%02x%02x%02x", $crc, $crc, $crc );
}

sub dircolor {
    my $direction = shift;
    my $pos       = shift;
    if ( $direction > 0 ) {
        return sprintf( "#ff%04x", $pos * $pos );
    }
    elsif ( $direction < 0 ) {
        return sprintf( "#%04xff", $pos * $pos );
    }
    else {
        return sprintf( "#%02xff%02x", $pos, $pos );
    }
} ## end sub dircolor

# helper function to collect all things needed for output and adds to a given buffer
sub push_output ($$$$$$$$$$) {
    my %tmp;
    $tmp{puid}  = shift;
    $tmp{name}  = shift;
    $tmp{begin} = shift;
    $tmp{end}   = shift;
    $tmp{regex} = shift;

    #$tmp{hexdump}   = shift;
    $tmp{position}           = shift;
    $tmp{signature}          = shift;
    $tmp{internal_signature} = shift;
    $tmp{bytesequence}       = shift;
    my $ref_buffer = shift;
    push @{$ref_buffer}, \%tmp;
    return;
} ## end sub push_output

#render HTML output
sub render_for_html {
    my $ref_buffer = shift;
    my $fh         = shift;
    my $binaryfile = shift;
    my @tmp        = sort { $a->{begin} <=> $b->{begin} } ( @{$ref_buffer} );
    say $fh <<HEAD;
<html><head />
<body>
<h1> Result for "$binaryfile"</h1>
HEAD
    foreach my $tagid ( 0 .. $#tmp ) {
        my $pos          = $tmp[$tagid]->{position};
        my $begin        = $tmp[$tagid]->{begin};
        my $end          = $tmp[$tagid]->{end};
        my $puid         = $tmp[$tagid]->{puid};
        my $name         = $tmp[$tagid]->{name};
        my $regex        = $tmp[$tagid]->{regex};
        my $internal     = $tmp[$tagid]->{internal_signature};
        my $bytesequence = $tmp[$tagid]->{bytesequence};
        my $partial      = get_partial_regex( $pos, $regex );

        #my $hexdump = $tmp[$tagid]->{hexdump};
        #if ( length($hexdump) > 10 ) {
        #    $hexdump = substr( $hexdump, 0, 10 ) . "...";
        #}
        my $fgcolor = puidcolor($puid);

        #my $bgcolor = dircolor( $begin <=> $end, $pos );
        my $bgcolor = rndcolor();
        say $fh "
        <h2>$puid</h2>
        <p>Internal Signature: $internal</p>
        <p>Byte Sequence: $bytesequence</p>
        <p>Bytes $begin - $end</p>
        <p>$name</p>
        <p>regex=$regex</p>
        <p>matching $pos-th partial regex: $partial</p>
"

          #<p>pos=$pos</p>
          #<p>hexdump:<br />$hexdump</p>"
    } ## end foreach my $tagid ( 0 .. $#tmp)

    say $fh <<FOOT;
  </body>
</html>
FOOT
    return;
} ## end sub render_for_html

# render output for wxhexeditor
sub render_for_wxhexeditor {
    my $ref_buffer = shift;
    my $fh         = shift;
    my $binaryfile = shift;
    my @tmp        = sort {
        if ( $a->{begin} == $b->{begin} ) {
            return ( $a->{end} <=> $b->{end} );
        }
        else {
            return ( $a->{begin} <=> $b->{begin} );
        }
    } ( @{$ref_buffer} );
    say $fh <<HEAD;
<?xml version="1.0" encoding="UTF-8"?>
<wxHexEditor_XML_TAG>
  <filename path="$binaryfile">
HEAD

    foreach my $tagid ( 0 .. $#tmp ) {
        my $pos          = $tmp[$tagid]->{position};
        my $begin        = $tmp[$tagid]->{begin};
        my $end          = $tmp[$tagid]->{end};
        my $puid         = $tmp[$tagid]->{puid};
        my $name         = $tmp[$tagid]->{name};
        my $regex        = $tmp[$tagid]->{regex};
        my $internal     = $tmp[$tagid]->{internal_signature};
        my $bytesequence = $tmp[$tagid]->{bytesequence};

        #my $hexdump = $tmp[$tagid]->{hexdump};
        #if ( length($hexdump) > 10 ) {
        #    $hexdump = substr( $hexdump, 0, 10 ) . "...";
        #}
        my $fgcolor = puidcolor($puid);

        #my $bgcolor = dircolor( $begin <=> $end, $pos );
        my $bgcolor = rndcolor();
        my $partial = get_partial_regex( $pos, $regex );
        say $fh "
<TAG id='$tagid'>
      <start_offset>$begin</start_offset>
      <end_offset>$end</end_offset>
      <tag_text>$puid
      $name
      at Bytes($begin, $end)
      $regex
      matching $pos-th partial regex: $partial
      Internal Signature: $internal
      Byte Sequence: $bytesequence

      </tag_text>
      <font_colour>$fgcolor</font_colour>
      <note_colour>$bgcolor</note_colour>
</TAG>";
    } ## end foreach my $tagid ( 0 .. $#tmp)

    say $fh <<FOOT;
  </filename>
</wxHexEditor_XML_TAG>
FOOT
    return;
} ## end sub render_for_wxhexeditor

sub get_partial_regex($$) {
    my $position = shift;
    my $regex    = shift;
    if ( $regex =~ m/\({$position}(.{20})/ ) { return "'$1'..."; }
    return "";
}

################################################################################
# main
################################################################################
my $pronomfile;
my $binaryfile;

GetOptions (
    "signature=s" => \$pronomfile,
    "binary=s" => \$binaryfile,
    "help" => sub {
        say "$0 --signature=droid_signature_filename --binary=binary_filename";
        say "$0 --help ";
        say "";
        exit 1;
    }
) or croak "wrong option, try '$0 --help'";

if ( !defined $pronomfile ) {
    say "you need at least a pronom signature file";
    exit;
}
if ( !defined $binaryfile ) {
    say "you need an binaryfile";
    exit;
}


# write basic main.osd

open( my $filehandle, "<", "$binaryfile" );
binmode($filehandle);
seek( $filehandle, 0, SEEK_END );
my $eof = tell($filehandle);
close $filehandle;

my $pronom = File::FormatIdentification::Pronom->new(
    "droid_signature_filename" => $pronomfile
);

my @output_buffer;

#my $pathobj = path($binaryfile);
#my $filestream = $pathobj->slurp_raw;
map_file my $filestream, $binaryfile, "<";
advise( $filestream, 'random' );
foreach my $internalid ( $pronom->get_all_internal_ids() ) {
    my $sig = $pronom->get_signature_id_by_internal_id($internalid);
    if ( !defined $sig ) { next; }
    my $puid = $pronom->get_puid_by_signature_id($sig);
    my $name = $pronom->get_name_by_signature_id($sig);

    my @regexes = $pronom->get_regular_expressions_by_internal_id($internalid);
    my @res;
    my $timer = time;
    foreach my $regex (@regexes) {

        # MATCHed?
        #warn "$internalid, regex='$regex'\n";
        if ( !defined $regex ) {
            warn "No regex found for internalid $internalid\n";
        }

        #say "REGEX='$regex'";
        if ( $filestream =~ m/$regex/saa ) {
            my $tmp;
            $tmp->{matched} = 1;
            $tmp->{regex}   = $regex;

            #$tmp->{groups};

            #use Data::Printer;
            #p( @+ );
            #p( @- );
            my %groups;
            for ( my $match = 0 ; $match <= $#- ; $match++ ) {
                if ( defined $-[$match] && defined $+[$match] ) {
                    my $matches;
                    my $begin = $-[$match];
                    my $end   = $+[$match];
                    $matches->{begin} = $begin;
                    $matches->{end}   = $end;
                    $matches->{pos}   = $match;
                    $groups{ ( $begin, $end ) } = $matches;
                }
            }
            my @uniqgroups = values %groups;

            #use Data::Printer;
            #p( @uniqgroups );
            $tmp->{groups} = \@uniqgroups;

            #p( $tmp->{groups} );
            #die "matched '$_'";
            push @res, $tmp;
        }
        else {
            last;    # break for loop
        }
    }

    if ( ( scalar @res ) == ( scalar @regexes ) ) {    # all matches successfull
            #   my %tmp;
            #     $tmp{puid}      = shift;
            #     $tmp{name}      = shift;
            #     $tmp{begin}     = shift;
            #     $tmp{end}       = shift;
            #     $tmp{regex}     = shift;
            #     #$tmp{hexdump}   = shift;
            #     $tmp{position}  = shift;
            #     $tmp{signature} = shift;
            #     my $ref_buffer = shift;

        for ( my $receiptidx = 0 ; $receiptidx <= $#res ; $receiptidx++ ) {
            my $receipt = $res[$receiptidx];
            foreach my $group ( @{ $receipt->{groups} } ) {
                push_output(
                    $puid,
                    $name,
                    $group->{begin},
                    $group->{end},
                    $receipt->{regex},
                    $group->{pos},
                    $sig,
                    $internalid,
                    $receiptidx,

                    \@output_buffer
                );
            }
        }
    }

    #say " ... time=", (time - $timer), "s";
} ## end foreach my $internal ( keys...)

open( my $OUT,  ">", "$binaryfile.tags" );
open( my $HTML, ">", "$binaryfile.html" );
render_for_wxhexeditor(
    #filter_matches_by_signature_priority( $signatures, \@output_buffer ),
    \@output_buffer,
    $OUT, $binaryfile
);
render_for_html(
    #filter_matches_by_signature_priority( $signatures, \@output_buffer ),
    \@output_buffer,
    $HTML, $binaryfile
);
close $HTML;
close $OUT;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

pronom2wxhexeditor.pl

=head1 VERSION

version 0.05

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
