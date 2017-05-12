###########################################################################
# MODULE     FrameMaker::FromHTML
# VERSION    0.03
# DATE       16 May 2003
# AUTHOR     Peter G. Martin
# EMAIL      peterm@zeta.org.au
# COMPANY    The Scribe & Chutney Trust
# COPYRIGHT NOTICE   (Copyright) The Scribe & Chutney Trust, 2003
# PURPOSE   Converts HTML file to FrameMaker MIF format

=head1 NAME

FrameMaker::FromHTML - class to convert HTML file to FrameMaker MIF

=head1 AUTHOR

Peter G. Martin
The Scribe & Chutney Trust

=head1 VERSION

Version 0.03
16 May 2003 1715 AEST

=head1 SYNOPSIS

use base 'FrameMaker::FromHTML';

use strict;

my ($infile, $outfile);

$infile = shift;

($outfile = $infile) =~ s/\.htm[l]*$/\.mif/;

# Insert routine to validate HTML -- eg, use HTML-Tidy

# VERY important -- this script is fragile at any time

# but worse with bad HTML

my $p = FrameMaker::FromHTML->new($outfile) ;

$p->parse_file("$tempfile") or die "Parsing failed on $tempfile: $!\n";

=head1 DESCRIPTION

Use to convert properly formed HTML into FrameMaker MIF.
Likely to be found buggy, particularly with funny HTML.
Errors in MIF are usually flagged in FrameMaker console
when FrameMaker is used to open the file.

See example file htmltofm.pl, which may be all you'll
need to get it working on some files.  In which case,
you'll need to have HTML-Tidy installed to clean up
your HTML.

=head1 BUGS

Galore. Particularly if expected HTML elements are missing.



=cut

package FrameMaker::FromHTML;
use Image::Size;
use vars qw($imgw $imgh @ISA $VERSION);
our $VERSION = 0.03;
@ISA=qw(HTML::Parser);
require HTML::Parser;
sub new
{
   my ($this, $outfile) = @_;
   my $class = ref($this) || $this;
   my $self = $this->SUPER::new();
   $self->{htmldata} = setup($outfile);
   return bless($self,$class);
}

sub start
  {
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    my($ptag, $imgunit, $imgfile, $imgtype, $imgentry);
    my ($maxwidth, $maxheight, $picwidth, $picheight, $curpar, $utag);
    my($rowspan, $colspan, $emptycell);

    # REMINDER: $attr is reference to a HASH, $attrseq is reference to an ARRAY
    # for the present, we'll just ignore the (lone-tag) <HR> and variant
    return if($tag =~ /^hr[\/]*$/);
    # now set up to ignore these tags AND any text content they embrace
    # ignore is signal to the text sub
    if ($tag =~ /^((area)|(base)|(button)|(title)|(div)|(style)|(head)|(meta)|(body)|(span)|(link)|(dl))$/)
      {
        $self->{htmldata}->{"ignore"}=1;
        return;
      }
    else
      {
        $self->{htmldata}->{"ignore"}=0;
      }
    #  Coping with end of non-tagged text. Here, it has been started off
    #  but needs to be finished because we've arrived at the start of new, tagged text
    if (!$self->{htmldata}->{"betweentags"})
      {
        $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"thispar"};
        $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparend"};
        $self->{htmldata}->{"thisparstart"}=$self->{htmldata}->{"thispar"}= $self->{htmldata}->{"thisparend"}="";
      }
    if($tag =~  /^html$/o)                # start <HTML>
      {
        # initialisations may be needed at start of file ?
        # here's one -- in case we change Text flow stuff later
        $self->{htmldata}->{"textflow"} = $self->{htmldata}->{"textflowtop"};
      }
    elsif ($tag =~ /^((p)|(h\d+)|(address)|(pre)|(blockquote)|(li)|(dt)|(dd)|(abbr)|(acronym))$/o)
      {
        # miscellaneous known tags
        # no special formatting for two tag types
        $tag = "p" if($tag =~ /((abbr)|(acronym))/);
        # get the paragraph start format -- it differs for lists
        if ($tag =~ /^li$/)
          {
            # should have list type
            $curtag = pop(@{$self->{htmldata}->{"inlist"}});
            if ($curtag eq "ol")
              {
                if ($self->{htmldata}->{"numfirst"})
                  {
                    $ptag = "OL-LI1";
                    $self->{htmldata}->{"numfirst"}=0;
                  }
                else
                  {
                    $ptag = "OL-LI";
                  }
              }
            else
              {
                $ptag = "UL-LI" if($curtag eq "ul");
              }
            push( @{$self->{htmldata}->{"inlist"}},$curtag);
          }
        else
          {
            $ptag = $tag;
          }
        # MIF tags are capitalised in template components
        $ptag  =~ tr/a-z/A-Z/;
        $self->{htmldata}->{"thisparstart"}  = $self->{htmldata}->{"parastart"} . $self->{htmldata}->{"paraline"}. $self->{htmldata}->{"flowrect"};
        # insert the style tag
        $self->{htmldata}->{"thisparstart"} =~ s/TAG/$ptag/;
        $self->{htmldata}->{"thisparend"} = $self->{htmldata}->{"paralineend"}.$self->{htmldata}->{"paraend"};
        $self->{htmldata}->{"betweentags"}= 1;
      }
    elsif ($tag =~ /^((ol)|(ul))$/)
      {
        # just save list type and flag start if numeric for numbering (re-)initialisation)
        push(@{$self->{htmldata}->{"inlist"}},$tag);
        $self->{htmldata}->{"numfirst"}=1 if($tag eq "ol");
      }
    elsif ($tag =~ /^img$/o)                 # start and end <IMG..>
      {
        # get the anchored frame format
        $imgunit = $self->{htmldata}->{"imgunit"};
        # counter for frame instances
        $self->{htmldata}->{"imgcount"}++;
        # no end tag, so complete par here
        unless ($self->{htmldata}->{"intable"})
          {
            $self->{htmldata}->{"thisparstart"} = $self->{htmldata}->{"parastart"};
            $self->{htmldata}->{"thisparstart"} =~ s/TAG/P/;
          }
        # insert instance reference in text format
        $self->{htmldata}->{"thisparstart"} .= $self->{htmldata}->{"paraline"} . "   \<AFrame ".$self->{htmldata}->{"imgcount"}."\>\n";
        # put it in place in the text flow of the document or the table
        $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"paralineend"}.$self->{htmldata}->{"paraend"} if($self->{htmldata}->{"inflow"});
        $self->{htmldata}->{"thiscell"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"paralineend"} if($self->{htmldata}->{"intable"});
        $self->{htmldata}->{"thisparstart"}="";
        # get details for image file, and proportion it to the
        # standard 12.6 cm x 8.8 cm anchored frame
        if ($$attr{src})                     # insert file reference in AFrame
          {
            # set file name, type details in frame format
            $imgfile = $$attr{src};
            $imgtype = uc($imgfile);
            $imgtype =~ s/([\w+\.]+)\.(\w+)$/$2/;
            $imgentry = $self->{htmldata}->{"imgunit"};
            $imgentry =~ s/martin\.gif/$imgfile/g;
            $imgentry =~ s/(updater)\s+\`GIF\'/$1 \`$imgtype\'/i;
            $imgentry =~ s/\<ID 1\>/\<ID $self->{htmldata}->{"imgcount"}\>/;
            # set picture dimensions within frame
            $maxwidth = 12.6;
            $maxheight = 8.8;
            # if max width implies excessive height,
            # set proportion according to maximum height
            # get picture size details via Image::Size
            ($imgw, $imgh) = imgsize($imgfile);
            if (($imgw ) && ($imgh))
              {
                if ($imgw >= $imgh)
                  {
                    $picwidth = $maxwidth;
                    $picheight = $imgh/$imgw*$maxwidth;
                  }
                else
                  {
                    $picheight = $maxheight;
                    $picwidth = $imgw/$imgh*$maxheight;
                  }
              }
            else
              {
                warn "No picture details for $imgfile ?\n";
                $picwidth = $maxwidth;
                $picheight = $maxheight;
              }
            $imgentry =~ s/XXX cm/$picwidth cm/g;
            $imgentry =~ s/YYY cm/$picheight cm/g;
            $self->{htmldata}->{"aframe_instances"} =~ s/(\> # end of AFrames)/$imgentry$1/;
                                            }
          }
        elsif($tag =~ /^a$/o)            # start <A  -- for names, hrefs
          {
            # just flag our state
            if(exists $$attr{"name"})    # label name
              {
                $self->{htmldata}->{"inmark"}=1;
              }
            elsif(exists $$attr{"href"})  # HREF
              {
                $self->{htmldata}->{"inhref"}=1;
              }
          }
        elsif ($tag =~ /^br[\/]*$/)
          {
            if ($self->{htmldata}->{"inflow"})
              {
                $self->{htmldata}->{"thispar"} .= $self->{htmldata}->{"paralineend"} if(!($self->balanced("\\<ParaLine", "end of ParaLine", "thisparstart")));
                $self->{htmldata}->{"thispar"} .= $self->{htmldata}->{"paraend"} if(!($self->balanced("\\<Para\\b", "end of Para\\b", "thisparstart")));
                $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"thispar"};
                # br in a list signals new indented par with no numbering
                if(@{$self->{htmldata}->{"inlist"}})
                  {
                    $ptag = "LI-BR" ;
                    $curtag = $self->{htmldata}->{"parastart"};
                    $curtag =~ s/PgfTag\s+\`TAG/PgfTag \`$ptag/;
                    $self->{htmldata}->{"thispar"} .= $curtag . $self->{htmldata}->{"paraline"}. $self->{htmldata}->{"flowrect"};
                  }
                # otherwise, we continue previous para style, preserving thisparstart
                else
                  {
                    $self->{htmldata}->{"thispar"} = "";
                  }
              }
            elsif ($self->{htmldata}->{"intable"})
              {
                $self->{htmldata}->{"thiscell"} .= "     ". $self->{htmldata}->{"paraline"} if($self->balanced("\\<ParaLine", "end of ParaLine", "thiscell"));
                $self->{htmldata}->{"thiscell"} .= "     ". $self->{htmldata}->{"paralineend"} if(!($self->balanced("\\<ParaLine", "end of ParaLine", "thiscell")));
                unless ($self->balanced("\\<Para\\b", "end of Para\\b", "thiscell"))
                  {
                    $self->{htmldata}->{"thiscell"} .= "      ". $self->{htmldata}->{"paraend"};
                    $self->{htmldata}->{"thiscell"} .= "      ".$self->{htmldata}->{"parastart"} ;
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TH/ if($self->{htmldata}->{"intblhd"});
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TD/ if($self->{htmldata}->{"intblbody"});
                  }
                else
                  {
                    $self->{htmldata}->{"thiscell"}  .= "      ".$self->{htmldata}->{"parastart"} ;
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TH/ if($self->{htmldata}->{"intblhd"});
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TD/ if($self->{htmldata}->{"intblbody"});
                    $self->{htmldata}->{"thiscell"} .= "     ". $self->{htmldata}->{"paraline"};
                    $self->{htmldata}->{"thiscell"} .= "     ".$self->{htmldata}->{"paralineend"};
                    $self->{htmldata}->{"thiscell"} .= "        ".$self->{htmldata}->{"paraend"};
                    $self->{htmldata}->{"thiscell"} .= "      ".$self->{htmldata}->{"parastart"} ;
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TH/ if($self->{htmldata}->{"intblhd"});
                    $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG/     \<PgfTag \`TD/ if($self->{htmldata}->{"intblbody"});
                  }
              }
          }
        elsif($tag =~ /^table$/o)     # start <TABLE
          {
            $self->{htmldata}->{"intable"}=1;
            $self->{htmldata}->{"inflow"}=0;
            $self->{htmldata}->{"thisformat"} = $self->{htmldata}->{"tblstart"}; # Tbl, TblID
            $self->{htmldata}->{"thisformat"} =~ s/TblID\s+1/TblID $self->{htmldata}->{"tblcount"}/;
            $self->{htmldata}->{"tblcount"}++;
            $self->{htmldata}->{"thisformat"} .= (($$attr{border}) && ($$attr{border} ne "0")) ?
              $self->{htmldata}->{"tblnormbords"}: $self->{htmldata}->{"tblnobords"};
            $self->{htmldata}->{"maxtblcols"}= $self->{htmldata}->{"maxcols"}= $self->{htmldata}->{"rowcount"}= $self->{htmldata}->{"colcount"}=0;
            $self->{htmldata}->{"intblhd"} = $self->{htmldata}->{"intblbody"}= 0;
            $self->{htmldata}->{"betweentags"}= 1;
          }
        elsif($tag =~ /^th$/o)            # start <TH
          {
            if (!$self->{htmldata}->{"intblhd"})
              {
                if ($self->{htmldata}->{"thistable"} =~ /\<TblBody\s*\n$/)
                  {
                    $self->{htmldata}->{"thistable"} =~ s/\s*\<TblBody\s*$/$self->{htmldata}->{"theadstart"}/;
                  }
                else
                  {
                    $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"theadstart"};
                  }
                $self->{htmldata}->{"intblhd"}=1;
              }
            $self->{htmldata}->{"colcount"}++;
            if (defined $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$self->{htmldata}->{"colcount"}])
              {
                $emptycell = $self->{htmldata}->{"tdstart"}."    ".$self->{htmldata}->{"parastart"};
                $emptycell =~ s/\<PgfTag\s+\`TAG\'/    \<PgfTag \`TH\'/o ;
                $emptycell .= "   ".$self->{htmldata}->{"paraline"}.$self->{htmldata}->{"paralineend"};
                $emptycell .= "   ".$self->{htmldata}->{"paraend"}.$self->{htmldata}->{"tdend"};
                do
                  {
                    $self->{htmldata}->{"thiscell"} = $emptycell;
                    $self->{htmldata}->{"thisrow"} .= $self->{htmldata}->{"thiscell"};
                    $self->{htmldata}->{"thiscell"} = "";
                    $self->{htmldata}->{"maxcols"}++;
                    $self->{htmldata}->{"colcount"}++;
                  } while (defined $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$self->{htmldata}->{"colcount"}]);
              }
            $self->{htmldata}->{"thiscell"} = $self->{htmldata}->{"tdstart"} . "    ".$self->{htmldata}->{"parastart"};
            $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG\'/    \<PgfTag \`TH\'/o;
            $self->{htmldata}->{"betweentags"}= 1;
            if ($$attr{"rowspan"})
              {
                # save rowspan count
                $rowspan = $$attr{"rowspan"} ;
                $self->{htmldata}->{"thiscell"} =~ s/(\<Cell)/$1\n     \<CellRows $rowspan\>/;
                foreach (($self->{htmldata}->{"rowcount"}+1) .. ($self->{htmldata}->{"rowcount"}+$rowspan-1))
                  {
                    $self->{htmldata}->{"tblmatrix"}[$_]->[$self->{htmldata}->{"colcount"}]++;
                  }
              }
            if ($$attr{"colspan"})
              {
                # save colspan count
                $colspan = $$attr{"colspan"};
                $self->{htmldata}->{"thiscell"} =~ s/(\<Cell)/$1\n     \<CellColumns $colspan\>/;
                foreach ( ($self->{htmldata}->{"colcount"}+1) .. ($self->{htmldata}->{"colcount"}+$colspan-1))
                  {
                    $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$_]++;
                  }
              }
          }
        elsif ($tag =~ /^thead$/o)             # start <THEAD
          {
            $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"theadstart"} unless $self->{htmldata}->{"intblhd"};
            $self->{htmldata}->{"intblhd"}=1;
            $self->{htmldata}->{"intblbody"}=0;
            $self->{htmldata}->{"betweentags"}= 1;
          }
        elsif($tag =~ /^tr$/o)               # start <TR
          {
            $self->{htmldata}->{"thisrow"} = $self->{htmldata}->{"trstart"};
            $self->{htmldata}->{"maxcols"} = $self->{htmldata}->{"colcount"} = 0;
            $self->{htmldata}->{"rowcount"}++;
            $self->{htmldata}->{"betweentags"}= 1;
          }
        elsif ($tag =~ /^tbody$/o )
          {
            $self->{htmldata}->{"intblhd"}=0;
            $self->{htmldata}->{"intblbody"}=1;
            $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"tbodystart"};
            $self->{htmldata}->{"betweentags"}= 1;
          }
        elsif($tag =~ /^td$/o)               # start <TD
          {
            $self->{htmldata}->{"intblbody"}=1;
            if ($self->{htmldata}->{"intblhd"})
              {
                $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"theadend"}. $self->{htmldata}->{"tbodystart"};
                $self->{htmldata}->{"intblhd"}=0;
              }
            else
              {
                $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"tbodystart"} unless ($self->{htmldata}->{"thistable"}=~ /\<TblBody/);
              }
            $self->{htmldata}->{"colcount"}++;
            if (defined $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$self->{htmldata}->{"colcount"}])
              {
                $emptycell = $self->{htmldata}->{"tdstart"}."    ".$self->{htmldata}->{"parastart"};
                $emptycell =~ s/\<PgfTag\s+\`TAG\'/    \<PgfTag \`TD\'/o ;
                $emptycell .= "   ".$self->{htmldata}->{"paraline"}.$self->{htmldata}->{"paralineend"};
                $emptycell .= "   ".$self->{htmldata}->{"paraend"}.$self->{htmldata}->{"tdend"};
                do
                  {
                    $self->{htmldata}->{"thiscell"} = $emptycell;
                    $self->{htmldata}->{"thisrow"} .= $self->{htmldata}->{"thiscell"};
                    $self->{htmldata}->{"thiscell"} = "";
                    $self->{htmldata}->{"maxcols"}++;
                    $self->{htmldata}->{"colcount"}++;
                  } while (defined $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$self->{htmldata}->{"colcount"}]);
              }
            $self->{htmldata}->{"thiscell"} = $self->{htmldata}->{"tdstart"}."    ".$self->{htmldata}->{"parastart"};
            $self->{htmldata}->{"thiscell"} =~ s/\<PgfTag\s+\`TAG\'/    \<PgfTag \`TD\'/o ;
            $self->{htmldata}->{"betweentags"}= 1;
            if ($$attr{"rowspan"})
              {
                $rowspan = $$attr{"rowspan"} ;
                $self->{htmldata}->{"thiscell"} =~ s/(\<Cell)/$1\n     \<CellRows $rowspan\>/;
                foreach (($self->{htmldata}->{"rowcount"}+1) .. ($self->{htmldata}->{"rowcount"}+$rowspan-1))
                  {
                    $self->{htmldata}->{"tblmatrix"}[$_]->[$self->{htmldata}->{"colcount"}]++;
                  }
              }
            elsif ($$attr{"colspan"})
              {
                $colspan = $$attr{"colspan"};
                $self->{htmldata}->{"thiscell"} =~ s/(\<Cell)/$1\n   \<CellColumns $colspan\>/;
                foreach ( ($self->{htmldata}->{"colcount"}+1) .. ($self->{htmldata}->{"colcount"}+$colspan-1))
                  {
                    $self->{htmldata}->{"tblmatrix"}[$self->{htmldata}->{"rowcount"}]->[$_]++;
                  }
              }
          }
        elsif ($tag =~ /^((b)|(i)|(sub)|(sup)|(strong)|(em)|(samp)|(kbd)|(var)|(cite)|(dfn)|(code)|(tt))$/)
          {
            $curpar = $self->{htmldata}->{"fontstart"};     # start various char fonts
            $utag = uc $tag;
            $curpar =~ s/FTAG/$utag/;
            $self->{htmldata}->{"thispar"} .= $curpar if($self->{htmldata}->{"inflow"});
            $self->{htmldata}->{"thiscell"} .= $curpar if($self->{htmldata}->{"intable"});
          }
        else
          {
            # for the present, all unknowns become "P"s
            # get the paragraph start format
            $self->{htmldata}->{"thisparstart"}  = $self->{htmldata}->{"parastart"} . $self->{htmldata}->{"paraline"} . $self->{htmldata}->{"flowrect"};
            # insert the P style tag (styles have caps)
            $self->{htmldata}->{"thisparstart"} =~ s/TAG/P/;
            $tag = "P";
            $self->{htmldata}->{"thisparend"} = $self->{htmldata}->{paralineend}.$self->{htmldata}->{paraend};
            $self->{htmldata}->{"betweentags"}= 1;
          }
        $self->{htmldata}->{"lasttag"}=$tag;
      }

    sub end
      {
        my($self, $tag, $origtext) = @_;
        my($tblpar, $newcol, $tblcolwidth, $tcount);
        if ($tag =~ /^((area)|(base)|(button)|(title)|(div)|(style)|(head)|(meta)|(body)|(span)|(link)|(dl))$/)
          {
            $self->{htmldata}->{"ignore"}=0;
            return;
          }
        if($tag =~ /html/i)                     # end </HTML>
          {
            $self->{htmldata}->{"table_instances"} .= " \> # end of Tbls\n";
            $self->{htmldata}->{"parastart"} =~ s/TAG/P/;
            $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"parastart"}.$self->{htmldata}->{"paraline"}.$self->{htmldata}->{"flowrect"};
            $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"paralineend"}. $self->{htmldata}->{"paraend"};
            #end of file processing
            open(OFILE, ">$self->{htmldata}->{outfile}") or die "Outfile: $self->{htmldata}->{outfile} not opened:$!\n";
            print OFILE $self->{htmldata}->{"filetop"};
            print OFILE $self->{htmldata}->{"aframe_instances"};
            print OFILE $self->{htmldata}->{"table_instances"};
            print OFILE $self->{htmldata}->{"masterpages"};
            print OFILE $self->{htmldata}->{"textflow"};
            print OFILE $self->{htmldata}->{"endofall"};
            close OFILE;
          }
        elsif ($tag =~ /^((p)|(h\d+)|(address)|(pre)|(blockquote)|(li)|(dd)|(dt)|(abbr)|(acronym))$/o)  # ends
          {
            $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"thispar"}.$self->{htmldata}->{"thisparend"} if($self->{htmldata}->{"inflow"});
            $self->{htmldata}->{"thisparstart"} = $self->{htmldata}->{"thispar"} = $self->{htmldata}->{"thisparend"} = "";
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif ($tag =~ /^((ol)|(ul))$/)
          {
            pop(@{$self->{htmldata}->{"inlist"}});
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif ($tag =~ /^a$/)
          {
            $self->{htmldata}->{"inmark"}=0 if($self->{htmldata}->{"inmark"});    # problems if these nested ?
            $self->{htmldata}->{"inhref"}=0 if($self->{htmldata}->{"inhref"});
          }
        elsif($tag =~ /^table$/o)                 # end </TABLE>
          {
            $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"tblend"};  #  EO TblBody, Tbl
            foreach (0 ..  ($self->{htmldata}->{"maxtblcols"}-1) )
              {
                $newcol = $self->{htmldata}->{"tblcolblank"};
                $newcol =~ s/TblColumnNum 0\>/TblColumnNum $_\>/;
                $self->{htmldata}->{"thisformat"} .= $newcol;
              }
            $tblcolwidth = $self->{htmldata}->{'maxtblcols'} ? $self->{htmldata}->{"txtarea"}/$self->{htmldata}->{"maxtblcols"} : 0;
            $self->{htmldata}->{"thisformat"} .= $self->{htmldata}->{"tblformend"};
            $self->{htmldata}->{"thisformat"} .= "  \<TblNumColumns ".$self->{htmldata}->{"maxtblcols"}."\>\n";
            foreach (1 .. $self->{htmldata}->{"maxtblcols"})
              {
                $newcol = $self->{htmldata}->{"colwidth"};
                $newcol =~ s/XXwidthXX cm/$tblcolwidth cm/;
                $self->{htmldata}->{"thisformat"} .= $newcol;
              }
            $self->{htmldata}->{"thisformat"} .= $self->{htmldata}->{"thistable"};
            $self->{htmldata}->{"table_instances"} .=  $self->{htmldata}->{"thisformat"};
            $self->{htmldata}->{"thistable"}= "";
            $self->{htmldata}->{"thisformat"}= "";
            $tblpar = $self->{htmldata}->{"parastart"};
            $tblpar =~ s/TAG/P/;
            # insert instance reference in text format
            $tblpar .= $self->{htmldata}->{"paraline"}.$self->{htmldata}->{"flowrect"};
            $tcount = $self->{htmldata}->{"tblcount"} - 1;
            $tblpar .= "   \<ATbl " . $tcount ."\>\n";
            $tblpar .= $self->{htmldata}->{"paralineend"}.$self->{htmldata}->{"paraend"};
            $self->{htmldata}->{"textflow"} .= $tblpar;
            $self->{htmldata}->{"maxcols"} = $self->{htmldata}->{"maxtblcols"} = 0;
            $self->{htmldata}->{"inflow"}=1;
            $self->{htmldata}->{"intable"}=0;
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif($tag =~ /^th$/o)                       # end </TH>
          {
            $self->{htmldata}->{"thiscell"} .= "    ".$self->{htmldata}->{"paraend"}.$self->{htmldata}->{"tdend"};
            $self->{htmldata}->{"thisrow"} .= $self->{htmldata}->{"thiscell"};
            $self->{htmldata}->{"thiscell"} = "";
            $self->{htmldata}->{"maxcols"}++;
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif($tag =~ /^tr$/o)                      # end </TR>
          {
            $self->{htmldata}->{"thisrow"} .= $self->{htmldata}->{"trend"};
            $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"thisrow"};
            $self->{htmldata}->{"thisrow"}= "";
            if ( $self->{htmldata}->{"maxcols"} > $self->{htmldata}->{"maxtblcols"} )
              {
                $self->{htmldata}->{"maxtblcols"} = $self->{htmldata}->{"maxcols"};
              }
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif($tag =~ /^td$/o)                       # end </TD>
          {
            $self->{htmldata}->{"thiscell"} .= "   ".$self->{htmldata}->{"paraend"}.$self->{htmldata}->{"tdend"};
            $self->{htmldata}->{"thisrow"} .= $self->{htmldata}->{"thiscell"};
            $self->{htmldata}->{"thiscell"} = "";
            $self->{htmldata}->{"maxcols"}++;
            $self->{htmldata}->{"betweentags"} = 0;
          }
        elsif ($tag =~ /^thead$/)
          {
            $self->{htmldata}->{"thistable"} .= $self->{htmldata}->{"theadend"};
          }
        elsif ($tag =~ /^((b)|(i)|(sub)|(sup)|(strong)|(em)|(samp)|(kbd)|(var)|(cite)|(dfn)|(code)|(tt))$/)
          {
            $self->{htmldata}->{"thispar"} .= $self->{htmldata}->{"fontend"} if($self->{htmldata}->{"inflow"});
            $self->{htmldata}->{"thiscell"} .= "  ".$self->{htmldata}->{"fontend"} if($self->{htmldata}->{"intable"});
          }
        else
          {
            $self->{htmldata}->{"textflow"} .= $self->{htmldata}->{"thisparstart"}.$self->{htmldata}->{"thispar"}.$self->{htmldata}->{"thisparend"};
            $self->{htmldata}->{"thisparstart"} = $self->{htmldata}->{"thispar"} = $self->{htmldata}->{"thisparend"} = "";
            $self->{htmldata}->{"betweentags"} = 0;
          }
      }


    sub text
      {
        my($self, $text) = @_;
        return if($self->{htmldata}->{"ignore"});
        my $curpar;
        #
        # $text = HTML::Entities::decode($text);  # -- don't use, cos going to MIF equivalents
        # trim spaces and newlines first
        $text =~ s/\n/ /g;
        $text =~ s/^\s+//g;
        $text =~ s/\s+$//g;
        $text =~ s/\s+/ /g;
        $text = $self->strfilt($text) if($text);
        if ($self->{htmldata}->{"inflow"})                  # main text flow
          {
            # paralines and strings to insert using
            # a paragraph format constructor
            if ( ($text) && ($text =~ /\S/))
              {
                # try to fix untagged pars. Assume they're all P
                if ((!$self->{htmldata}->{"betweentags"}) && (!$self->{htmldata}->{"thisparstart"}))
                  {
                    $self->{htmldata}->{"thisparstart"} = $self->{htmldata}->{"parastart"} . $self->{htmldata}->{"paraline"};
                    $self->{htmldata}->{"thisparstart"} .= $self->{htmldata}->{"flowrect"};
                    $self->{htmldata}->{"thisparstart"} =~ s/PgfTag\s+\`TAG/PgfTag \`P/;
                    $self->{htmldata}->{"thisparend"} = $self->{htmldata}->{paralineend}.$self->{htmldata}->{paraend};
                  }
                $curpar = $self->{htmldata}->{"textform"};
                $curpar =~ s/STRINGCONTENTS/$text/;
                # try out as place to do special char insertion lines
                $curpar =~ s/\&ndash\;/\'\>\n     \<Char EnDash\>\n      \<String \`/g;
                if ($self->{htmldata}->{"inmark"})
                  {
                    $curpar = $self->{htmldata}->{"mark"} . $curpar;
                    $curpar =~ s/XXMarkTextXX/$text/;
                  }
                elsif ($self->{htmldata}->{"inhref"})
                  {
                    $curpar = $self->{htmldata}->{"xrefstart"}.$curpar."   \<XRefEnd \>\n";
                    $curpar =~ s/XXXRefTextXXX/$text/;
                  }
                $self->{htmldata}->{"thispar"} .= $curpar;
              }
          }
        elsif ($self->{htmldata}->{"intable"})                 # table text flow
          {
            # paralines and strings to insert using $origtext and
            # a paragraph format constructor

            if (($text) && ($text =~ /\S/))
              {
                # trim leading on table text but allow end space (in format)
                $self->{htmldata}->{"thiscell"} .= "    ".$self->{htmldata}->{"paraline"};
                $curpar = "    ".$self->{htmldata}->{"textform"};
                $text =~ s/^\s+//go;
                $text =~ s/\s+$//go;
                $curpar =~ s/STRINGCONTENTS/$text/;
                $curpar =~ s/\&ndash\;/\'\>\n     \<Char EnDash\>\n      \<String \`/g;
                if ($self->{htmldata}->{"inmark"})
                  {
                    $curpar = $self->{htmldata}->{"mark"} . $curpar;
                    $curpar =~ s/XXMarkTextXX/$text/;
                  }
                elsif ($self->{htmldata}->{"inhref"})
                  {
                    $curpar = $self->{htmldata}->{"xrefstart"}.$curpar."   \<XRefEnd \>\n";
                    $curpar =~ s/XXXRefTextXXX/$text/;
                  }
                $self->{htmldata}->{"thiscell"} .= $curpar;
                $self->{htmldata}->{"thiscell"} .= "    ".$self->{htmldata}->{"paralineend"};
              }
          }
      }

    sub declaration
      {
        my($self, $decl) = @_;
        # might help to record origins ?;           # document type
      }

    sub comment
      {
        my($self, $comment) = @_;
        # maybe oneday conditional text ?;
      }

    sub strfilt
      {
        my ($self, $astr)=@_;
        $astr =~ s/\'/\\xd5 /g;
        $astr =~ s/\b\"/\\xd3 /g;
        $astr =~ s/\"\b/\\xd2 /g; #"
        $astr =~ s/\.\.\./\\xc9 /g;            # ellipsis
        $astr =~ s/--/\\xd1 /g;         # emdash
        $astr =~ s/\`/\\xd4 /g;
        $astr =~ s/\'/\\xd5 /g;         #  '
        $astr =~ s/&#183;/\\xd7 /g;     # maths dot
        $astr =~ s/&#39;/\\xd5 /g;       # r single quote
        $astr =~ s/&lt;=/\\xa3 /g;       # <= in Symbols
        $astr =~ s/&gt;=/\\xb3 /g;        # >= in Symbols
        if($astr =~ /&\w+\;/)
          {
            $astr =~ s/&nbsp\;/\\x10 /og;
            $astr =~ s/&Auml\;/\\x80 /g;
            $astr =~ s/&Aring\;/\\x81 /g;
            $astr =~ s/&Ccedil;/\\x82 /g;
            $astr =~ s/&Eacute;/\\x83 /g;
            $astr =~ s/&Ntilde;/\\x84 /g;
            $astr =~ s/&Ouml;/\\x85 /g;
            $astr =~ s/&Uuml;/\\x86 /g;
            $astr =~ s/&aacute;/\\x87 /g;
            $astr =~ s/&agrave;/\\x88 /g;
            $astr =~ s/&acirc;/\\x89 /g;
            $astr =~ s/&auml;/\\x8a /g;
            $astr =~ s/&atilde;/\\x8b /g;
            $astr =~ s/&aring;/\\x8c /g;
            $astr =~ s/&ccedil;/\\x8d /g;
            $astr =~ s/&eacute;/\\x8e /g;
            $astr =~ s/&egrave;/\\x8f /g;
            $astr =~ s/&ecirc;/\\x90 /g;
            $astr =~ s/&euml;/\\x91 /g;
            $astr =~ s/&iacute;/\\x92 /g;
            $astr =~ s/&igrave;/\\x93 /g;
            $astr =~ s/&icirc;/\\x94 /g;
            $astr =~ s/&iuml;/\\x95 /g;
            $astr =~ s/&ntilde;/\\x96 /g;
            $astr =~ s/&oacute;/\\x97 /g;
            $astr =~ s/&ograve;/\\x98 /g;
            $astr =~ s/&ocirc;/\\x99 /g;
            $astr =~ s/&ouml;/\\x9a /g;
            $astr =~ s/&otilde;/\\x9b /g;
            $astr =~ s/&uacute;/\\x9c /g;
            $astr =~ s/&ugrave;/\\x9d /g;
            $astr =~ s/&ucirc;/\\x9e /g;
            $astr =~ s/&uuml;/\\x9f /g;
            $astr =~ s/&curren;/\\xa0 /g; # replace general currency sign with dagger
            $astr =~ s/&cent;/\\xa2 /g;
            $astr =~ s/&sect;/\\xa4 /g;
            $astr =~ s/&middot;/\\xa5 /g;
            $astr =~ s/&para;/\\xa6 /g;
            $astr =~ s/&szlig;/\\xa7 /g;
            $astr =~ s/&reg;/\\xa8 /g;
            $astr =~ s/&copy;/\\xa9 /g;
            $astr =~ s/&reg;/\\xaa /g;         # registered symb - TM
            $astr =~ s/&acute;/\\xab /g;
            # $astr =~ s/\b&quot;/ \\xd2/g;
            $astr =~ s/&quot;/\\xd3  /g;
            $astr =~ s/&AElig;/\\xae /g;
            $astr =~ s/&Oslash;/\\xaf /g;
            $astr =~ s/&yen;/\\xb4 /g;
            $astr =~ s/&ordf;/\\xbb /g;
            $astr =~ s/&ordm;/\\xbc /g;
            $astr =~ s/&aelig;/\\xbe /g;
            $astr =~ s/&oslash;/\\xbf /g;
            $astr =~ s/&iquest;/\\xc0 /g;
            $astr =~ s/&iexcl;/\\xc1 /g;
            $astr =~ s/&not;/\\xc2 /g;
            #        $astr =~ s/f/\\xc4 /g;
            $astr =~ s/&laquo;/\\xc7 /g;
            $astr =~ s/&raquo;/\\xc8 /g;
            $astr =~ s/&lsquo;/\\xd4 /g;
            $astr =~ s/&rsquo;/\\xd5 /g;
            $astr =~ s/&Agrave;/\\xcb /g;
            $astr =~ s/&Atilde;/\\xcc /g;
            $astr =~ s/&Otilde;/\\xcd /g;
            $astr =~ s/OE/\\xce /g;         # oe dipthong/ligature
            $astr =~ s/oe/\\xcf /g;
            $astr =~ s/&shy;/\\xd0 /g;      # soft hyphen for endash
            $astr =~ s/&yuml;/\\xd8 /g;
            $astr =~ s/&curren;/\\xdb /g;
            #         $astr =~ s/&lt;/\\xdc /g;
            #         $astr =~ s/&gt;/\\xdd /g;
            #        $astr =~ s/&reg;/\\xe2 /g;   # symbol fonts ??
            $astr =~ s/&copy;/\\xe3 /g;
            $astr =~ s/&reg;/\\xe4 /g;       # TM - registered sign
            $astr =~ s/&lt;/\\\</g;
            $astr =~ s/&gt;/\\\>/g;
            $astr =~ s/&amp\;/\&/g;
          }
        $astr;
      }

    sub balanced
      {
        my($self, $string1, $string2, $target) = @_;
        my (@arr1, @arr2);
        my $countof1 = (@arr1 = ($self->{htmldata}->{"$target"} =~ m/$string1/g));
        my $countof2 = (@arr2 = ($self->{htmldata}->{"$target"} =~ m/$string2/g));
        my $diffcount = ($countof1 - $countof2);
        $diffcount *= -1 if($diffcount < 0);
        return( ($diffcount % 2) == 0);
      }

sub setup

    # initialisation
    {
      my ($outfile) = shift;

      my @initkeys = qw (outfile tblmatrix filetop aframe_instances table_instances
                         masterpages textflowtop textflow endofall inflow intable intblhd
                         intblbody inmark inhref lasttag mark xrefstart inlist
                         numfirst textform imgunit imgcount thisparstart thispar
                         thisparend thistable thisformat thisrow thiscell tblcount
                         maxcols rowcount colcount maxtblcols tblstart tblnormbords
                         tblnobords theadstart tbodystart theaddone trstart
                         tdstart tblformend tblcolblank theadend trend tdend
                         tblend parastart paraline flowrect paraend paralineend fontstart
                         fontend colwidth txtarea betweentags ignore);

      my ($filetop, $aframe_instances, $table_instances, $inflow, $intable, $intblhd, $intblbody);
      my ($inmark, $inhref, $numfirst, $imgcount, $tblcount, $maxcols, $maxtblcols, $theaddone);
      my ($betweentags, $ignore, $lasttag, $inlist, $thisparstart, $thispar, $thisparend, $thistable);
      my ($thisformat, $thisrow, $thiscell, $mark, $xrefstart, $masterpages, $textflowtop);
      my ($endofall, $textform, $imgunit, $tblstart, $tblnormbords, $tblnobords);
      my ($theadstart, $tbodystart, $trstart, $tdstart,$tblformend, $rowcount, $colcount );
      my ($tblcolblank, $theadend, $trend, $tdend, $tblend, $parastart, $flowrect );
      my ($paraend, $paralineend, $colwidth, $paraline, $fontstart, $fontend, $txtarea  );


      $table_instances = "\<Tbls \n";
      $inflow = 1;
      $intable = $intblhd = $intblbody = $inmark = $inhref = $numfirst = $imgcount = $tblcount= 0;
      $maxcols = $maxtblcols = $theaddone= $betweentags =$ignore = $rowcount = $colcount=0;
      $lasttag = $inlist = $thisparstart = $thispar = $thisparend = $thistable = $thisformat = "";
      $thisrow = $thiscell = $textflow = "";
      $txtarea = "12";
      $tblmatrix = ();



      $filetop=<<EOFT;
<MIFFile 5.00> # Generated by FrameMaker::FromHTML
# Options:
#    Paragraph Text
#    Paragraph Tags
#    Paragraph Formats
#    Font Information
#    Markers
#    Anchored Frames
#    Tables
#    Graphics and TextRect Layout
#    Master Page Items
#    Condition Catalog
#    Table Catalogs
#    Font Catalog
#    Paragraph Catalog
#    Document Template
#    Document Dictionary
#    Variables
#
<Units Ucm>
<ColorCatalog
 <Color
  <ColorTag `Black'>
  <ColorCyan  0.000000>
  <ColorMagenta  0.000000>
  <ColorYellow  0.000000>
  <ColorBlack  100.000000>
  <ColorAttribute ColorIsBlack>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `White'>
  <ColorCyan  0.000000>
  <ColorMagenta  0.000000>
  <ColorYellow  0.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsWhite>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Red'>
  <ColorCyan  0.000000>
  <ColorMagenta  100.000000>
  <ColorYellow  100.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsRed>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Green'>
  <ColorCyan  100.000000>
  <ColorMagenta  0.000000>
  <ColorYellow  100.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsGreen>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Blue'>
  <ColorCyan  100.000000>
  <ColorMagenta  100.000000>
  <ColorYellow  0.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsBlue>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Cyan'>
  <ColorCyan  100.000000>
  <ColorMagenta  0.000000>
  <ColorYellow  0.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsCyan>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Magenta'>
  <ColorCyan  0.000000>
  <ColorMagenta  100.000000>
  <ColorYellow  0.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsMagenta>
  <ColorAttribute ColorIsReserved>
 > # end of Color
 <Color
  <ColorTag `Yellow'>
  <ColorCyan  0.000000>
  <ColorMagenta  0.000000>
  <ColorYellow  100.000000>
  <ColorBlack  0.000000>
  <ColorAttribute ColorIsYellow>
  <ColorAttribute ColorIsReserved>
 > # end of Color
> # end of ColorCatalog
<ConditionCatalog
> # end of ConditionCatalog
<PgfCatalog
 <Pgf
  <PgfTag `ActiveIX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `ActiveTOC'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `ADDRESS'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment LeftRight>
  <PgfFIndent  1.5 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  1.5 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  4.0 pt>
  <PgfSpAfter  5.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.I.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Italic'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 10>
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace Yes>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `BLOCKQUOTE'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment LeftRight>
  <PgfFIndent  1.5 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  1.5 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  4.0 pt>
  <PgfSpAfter  5.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 10>
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace Yes>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `DD'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.75 cm>
  <PgfLIndent  0.75 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  4.0 pt>
  <PgfSpAfter  5.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 12>
  <TabStop
   <TSX  0.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace Yes>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `DT'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  4.0 pt>
  <PgfSpAfter  6.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.700'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 12>
  <TabStop
   <TSX  0.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace Yes>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `GroupTitlesIX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Center>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.700'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  14.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H1'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  4.45 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `1Heading Rule'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement PageTop>
  <PgfPlacementStyle Straddle>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  25.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Verdana.R.700'>
   <FFamily `Verdana'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  20.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  -2.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Proportional>
  <PgfLeading  6.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 4>
  <TabStop
   <TSX  4.45 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.49999 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.49999 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  13.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H1TOC'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `'>
  <PgfSpBefore  20.0 pt>
  <PgfSpAfter  6.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.700'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 2>
  <TabStop
   <TSX  1.0 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  12.625 cm>
   <TSType Right>
   <TSLeaderStr `.'>
  > # end of TabStop
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H2'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Straddle>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  27.0 pt>
  <PgfSpAfter  8.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Verdana.R.700'>
   <FFamily `Verdana'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  15.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 1>
  <TabStop
   <TSX  1.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H2TOC'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  0.75 cm>
  <PgfLIndent  1.75 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `'>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.400'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `\\\\t'>
  <PgfNumberFont `'>
  <PgfNumAtEnd Yes>
  <PgfNumTabs 2>
  <TabStop
   <TSX  1.0 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  12.625 cm>
   <TSType Right>
   <TSLeaderStr ` .'>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H3'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  1.75 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Straddle>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  20.0 pt>
  <PgfSpAfter  4.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Verdana.R.700'>
   <FFamily `Verdana'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  13.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  3.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 1>
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H3TOC'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  1.5 cm>
  <PgfLIndent  2.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `'>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.400'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `\\\\t'>
  <PgfNumberFont `'>
  <PgfNumAtEnd Yes>
  <PgfNumTabs 2>
  <TabStop
   <TSX  1.0 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  12.625 cm>
   <TSType Right>
   <TSLeaderStr ` .'>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H4'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  12.0 pt>
  <PgfSpAfter  6.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Verdana.R.700'>
   <FFamily `Verdana'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  3.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H4TOC'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  2.5 cm>
  <PgfLIndent  2.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `'>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.400'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `\\\\t'>
  <PgfNumberFont `'>
  <PgfNumAtEnd Yes>
  <PgfNumTabs 1>
  <TabStop
   <TSX  12.625 cm>
   <TSType Right>
   <TSLeaderStr ` .'>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `H5'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle SideheadFirstBaseline>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  8.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Verdana.R.700'>
   <FFamily `Verdana'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  0.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `IgnoreCharsIX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 75>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 125>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `Level1IX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `Level2IX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  0.318 cm>
  <PgfLIndent  0.953 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  1.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 1>
  <TabStop
   <TSX  1.0 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `Level3IX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  0.635 cm>
  <PgfLIndent  1.27 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  1.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `LI-BR'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  1.5 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  1.0 pt>
  <PgfSpAfter  2.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 10>
  <TabStop
   <TSX  2.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `OL-LI'>
  <PgfUseNextTag Yes>
  <PgfNextTag `StepAgain'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.75 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  10.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `S:\<n+\\>)\\\\t'>
  <PgfNumberFont `BlueText'>
  <PgfNumAtEnd No>
  <PgfNumTabs 6>
  <TabStop
   <TSX  1.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `OL-LI1'>
  <PgfUseNextTag Yes>
  <PgfNextTag `StepAgain'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.75 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  10.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `S:\<n=1\\>)\\\\t'>
  <PgfNumberFont `BlueText'>
  <PgfNumAtEnd No>
  <PgfNumTabs 6>
  <TabStop
   <TSX  1.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `P'>
  <PgfUseNextTag Yes>
  <PgfNextTag `P'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  4.0 pt>
  <PgfSpAfter  6.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 12>
  <TabStop
   <TSX  0.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace Yes>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `PRE'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  6.0 pt>
  <PgfSpAfter  5.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Courier New.R.400'>
   <FFamily `Courier New'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 12>
  <TabStop
   <TSX  0.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  2.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  4.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  6.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  8.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  10.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage NoLanguage>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `SeparatorsIX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `SortOrderIX'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate Yes>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 2>
  <HyphenMinSuffix 2>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `TD'>
  <PgfUseNextTag Yes>
  <PgfNextTag `TD'>
  <PgfAlignment Left>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Straddle>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  3.0 pt>
  <PgfWithPrev No>
  <PgfWithNext Yes>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.400'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  9.5 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  -0.5 pt>
  <PgfAutoNum No>
  <PgfNumTabs 1>
  <TabStop
   <TSX  1.75 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `TH'>
  <PgfUseNextTag No>
  <PgfNextTag `'>
  <PgfAlignment Center>
  <PgfFIndent  0.0 cm>
  <PgfLIndent  0.0 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  0.0 pt>
  <PgfSpAfter  0.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 1>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Arial.R.700'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FSize  10.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum No>
  <PgfNumTabs 0>
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
 <Pgf
  <PgfTag `UL-LI'>
  <PgfUseNextTag Yes>
  <PgfNextTag `BulletNext'>
  <PgfAlignment LeftRight>
  <PgfFIndent  0.75 cm>
  <PgfLIndent  1.5 cm>
  <PgfRIndent  0.0 cm>
  <PgfFIndentRelative No>
  <PgfFIndentOffset  0.0 cm>
  <PgfTopSeparator `'>
  <PgfTopSepAtIndent No>
  <PgfTopSepOffset  0.0 cm>
  <PgfBotSeparator `'>
  <PgfBotSepAtIndent No>
  <PgfBotSepOffset  0.0 cm>
  <PgfPlacement Anywhere>
  <PgfPlacementStyle Normal>
  <PgfRunInDefaultPunct `. '>
  <PgfSpBefore  2.0 pt>
  <PgfSpAfter  4.0 pt>
  <PgfWithPrev No>
  <PgfWithNext No>
  <PgfBlockSize 2>
  <PgfFont
   <FTag `'>
   <FPlatformName `W.Times New Roman.R.400'>
   <FFamily `Times New Roman'>
   <FVar `Regular'>
   <FWeight `Regular'>
   <FAngle `Regular'>
   <FSize  11.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern Yes>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of PgfFont
  <PgfLineSpacing Fixed>
  <PgfLeading  2.0 pt>
  <PgfAutoNum Yes>
  <PgfNumFormat `B:\\xa5 \\\\t'>
  <PgfNumberFont `'>
  <PgfNumAtEnd No>
  <PgfNumTabs 6>
  <TabStop
   <TSX  1.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  3.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  5.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  7.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  9.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <TabStop
   <TSX  11.5 cm>
   <TSType Left>
   <TSLeaderStr ` '>
  > # end of TabStop
  <PgfHyphenate No>
  <HyphenMaxLines 2>
  <HyphenMinPrefix 3>
  <HyphenMinSuffix 3>
  <HyphenMinWord 5>
  <PgfLetterSpace No>
  <PgfMinWordSpace 90>
  <PgfOptWordSpace 100>
  <PgfMaxWordSpace 110>
  <PgfLanguage UKEnglish>
  <PgfCellAlignment Top>
  <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
  <PgfCellLMarginFixed No>
  <PgfCellTMarginFixed No>
  <PgfCellRMarginFixed No>
  <PgfCellBMarginFixed No>
  <PgfLocked No>
 > # end of Pgf
> # end of PgfCatalog
<FontCatalog
 <Font
  <FTag `B'>
  <FFamily `Times New Roman'>
  <FWeight `Bold'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `CANDSC'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FSmallCaps>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `CITE'>
  <FPlatformName `W.Times New Roman.I.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Italic'>
  <FSize  11.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `CODE'>
  <FPlatformName `W.Courier New.R.400'>
  <FFamily `Courier New'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  9.5 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `TT'>
  <FPlatformName `W.Courier New.R.400'>
  <FFamily `Courier New'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  9.5 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `DEL'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  11.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike Yes>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 4>
  <FColor `Blue'>
 > # end of Font
 <Font
  <FTag `DFN'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  11.0 pt>
  <FUnderlining FSingle>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `EM'>
  <FPlatformName `W.Times New Roman.I.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Italic'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `I'>
  <FFamily `Times New Roman'>
  <FAngle `Italic'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `INS'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  11.0 pt>
  <FUnderlining FSingle>
  <FOverline No>
  <FStrike No>
  <FChangeBar Yes>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 2>
  <FColor `Red'>
 > # end of Font
 <Font
  <FTag `KBD'>
  <FPlatformName `W.Courier New.R.400'>
  <FFamily `Courier New'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  10.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern No>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `SAMP'>
  <FPlatformName `W.Courier New.R.400'>
  <FFamily `Courier New'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  10.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern No>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `SANSSERIF'>
  <FFamily `Arial'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `STRONG'>
  <FPlatformName `W.Times New Roman.R.700'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Bold'>
  <FAngle `Regular'>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `SUB'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  11.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FSubscript>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `SUP'>
  <FPlatformName `W.Times New Roman.R.400'>
  <FFamily `Times New Roman'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Regular'>
  <FSize  11.0 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern Yes>
  <FCase FAsTyped>
  <FPosition FSuperscript>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
 <Font
  <FTag `VAR'>
  <FPlatformName `W.Courier New.I.400'>
  <FFamily `Courier New'>
  <FVar `Regular'>
  <FWeight `Regular'>
  <FAngle `Italic'>
  <FSize  9.5 pt>
  <FUnderlining FNoUnderlining>
  <FOverline No>
  <FStrike No>
  <FChangeBar No>
  <FPairKern No>
  <FCase FAsTyped>
  <FPosition FNormal>
  <FDW  0.0%>
  <FLocked No>
  <FSeparation 0>
  <FColor `Black'>
 > # end of Font
> # end of FontCatalog
<RulingCatalog
 <Ruling
  <RulingTag `Thin'>
  <RulingPenWidth  0.5 pt>
  <RulingGap  0.0 pt>
  <RulingSeparation 0>
  <RulingColor `Black'>
  <RulingPen 0>
  <RulingLines 1>
 > # end of Ruling
 <Ruling
  <RulingTag `Medium'>
  <RulingPenWidth  2.0 pt>
  <RulingGap  0.0 pt>
  <RulingSeparation 0>
  <RulingColor `Black'>
  <RulingPen 0>
  <RulingLines 1>
 > # end of Ruling
 <Ruling
  <RulingTag `Double'>
  <RulingPenWidth  0.5 pt>
  <RulingGap  2.0 pt>
  <RulingSeparation 0>
  <RulingColor `Black'>
  <RulingPen 0>
  <RulingLines 2>
 > # end of Ruling
 <Ruling
  <RulingTag `Thick'>
  <RulingPenWidth  3.0 pt>
  <RulingGap  0.0 pt>
  <RulingSeparation 0>
  <RulingColor `Black'>
  <RulingPen 0>
  <RulingLines 1>
 > # end of Ruling
 <Ruling
  <RulingTag `Very Thin'>
  <RulingPenWidth  0.25 pt>
  <RulingGap  0.0 pt>
  <RulingSeparation 0>
  <RulingColor `Black'>
  <RulingPen 0>
  <RulingLines 1>
 > # end of Ruling
> # end of RulingCatalog
<TblCatalog
 <TblFormat
  <TblTag `NoBorders'>
  <TblColumn
   <TblColumnNum 0>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
     <PgfTag `TH'>
   > # end of TblColumnH
   <TblColumnBody
     <PgfTag `TD'>
   > # end of TblColumnBody
   <TblColumnF
     <PgfTag `TD'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblColumn
   <TblColumnNum 1>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
     <PgfTag `TH'>
   > # end of TblColumnH
   <TblColumnBody
     <PgfTag `TD'>
   > # end of TblColumnBody
   <TblColumnF
     <PgfTag `TD'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblCellMargins  4.0 pt 4.0 pt 4.0 pt 4.0 pt>
  <TblLIndent  0.0 cm>
  <TblRIndent  0.0 cm>
  <TblAlignment Center>
  <TblPlacement Anywhere>
  <TblSpBefore  0.0 pt>
  <TblSpAfter  18.0 pt>
  <TblBlockSize 2>
  <TblHFFill 15>
  <TblHFSeparation 0>
  <TblHFColor `Black'>
  <TblBodyFill 15>
  <TblBodySeparation 0>
  <TblBodyColor `Black'>
  <TblShadeByColumn No>
  <TblLocked No>
  <TblShadePeriod 2>
  <TblXFill 15>
  <TblXSeparation 0>
  <TblXColor `Black'>
  <TblAltShadePeriod 2>
  <TblLRuling `'>
  <TblBRuling `'>
  <TblRRuling `'>
  <TblTRuling `'>
  <TblColumnRuling `'>
  <TblXColumnRuling `'>
  <TblBodyRowRuling `'>
  <TblXRowRuling `'>
  <TblHFRowRuling `'>
  <TblSeparatorRuling `'>
  <TblXColumnNum 1>
  <TblRulingPeriod 4>
  <TblLastBRuling Yes>
  <TblTitlePlacement None>
  <TblTitlePgf1
   <Pgf
    <PgfTag `TableTitle'>
    <PgfFIndent  1.75 cm>
    <PgfLIndent  4.75 cm>
    <PgfPlacementStyle Straddle>
    <PgfSpBefore  2.0 pt>
    <PgfWithNext Yes>
    <PgfBlockSize 2>
    <PgfFont
     <FTag `'>
     <FPlatformName `W.Arial.R.700'>
     <FFamily `Arial'>
     <FVar `Regular'>
     <FWeight `Bold'>
     <FAngle `Regular'>
     <FSize  12.0 pt>
     <FUnderlining FNoUnderlining>
     <FOverline No>
     <FStrike No>
     <FChangeBar No>
     <FOutline No>
     <FShadow No>
     <FPairKern Yes>
     <FCase FAsTyped>
     <FPosition FNormal>
     <FDX  0.0%>
     <FDY  0.0%>
     <FDW  0.0%>
     <FLocked No>
     <FSeparation 0>
     <FColor `Black'>
    > # end of PgfFont
    <PgfAutoNum Yes>
    <PgfNumFormat `T:Table  \<n+\\>\\\\t'>
    <PgfNumberFont `'>
    <PgfNumAtEnd No>
    <PgfNumTabs 1>
    <TabStop
     <TSX  4.75 cm>
     <TSType Left>
     <TSLeaderStr ` '>
    > # end of TabStop
   > # end of Pgf
  > # end of TblTitlePgf1
  <TblTitleGap  0.0 pt>
  <TblInitNumColumns 2>
  <TblInitNumHRows 1>
  <TblInitNumBodyRows 3>
  <TblInitNumFRows 0>
  <TblNumByColumn No>
 > # end of TblFormat
 <TblFormat
  <TblTag `NormalBorders'>
  <TblColumn
   <TblColumnNum 0>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
    <Pgf
     <PgfTag `TH'>
     <PgfUseNextTag No>
     <PgfNextTag `'>
     <PgfAlignment Center>
     <PgfFIndent  0.0 cm>
     <PgfLIndent  0.0 cm>
     <PgfRIndent  0.0 cm>
     <PgfFIndentRelative No>
     <PgfFIndentOffset  0.0 cm>
     <PgfTopSeparator `'>
     <PgfTopSepAtIndent No>
     <PgfTopSepOffset  0.0 cm>
     <PgfBotSeparator `'>
     <PgfBotSepAtIndent No>
     <PgfBotSepOffset  0.0 cm>
     <PgfPlacement Anywhere>
     <PgfPlacementStyle Normal>
     <PgfRunInDefaultPunct `. '>
     <PgfSpBefore  0.0 pt>
     <PgfSpAfter  0.0 pt>
     <PgfWithPrev No>
     <PgfWithNext No>
     <PgfBlockSize 1>
     <PgfFont
      <FTag `'>
      <FPlatformName `W.Arial.R.700'>
      <FFamily `Arial'>
      <FVar `Regular'>
      <FWeight `Bold'>
      <FAngle `Regular'>
      <FSize  10.0 pt>
      <FUnderlining FNoUnderlining>
      <FOverline No>
      <FStrike No>
      <FChangeBar No>
      <FOutline No>
      <FShadow No>
      <FPairKern Yes>
      <FCase FAsTyped>
      <FPosition FNormal>
      <FDX  0.0%>
      <FDY  0.0%>
      <FDW  0.0%>
      <FLocked No>
      <FSeparation 0>
      <FColor `Black'>
     > # end of PgfFont
     <PgfLineSpacing Fixed>
     <PgfLeading  2.0 pt>
     <PgfAutoNum No>
     <PgfNumTabs 0>
     <PgfHyphenate No>
     <HyphenMaxLines 2>
     <HyphenMinPrefix 3>
     <HyphenMinSuffix 3>
     <HyphenMinWord 5>
     <PgfLetterSpace No>
     <PgfMinWordSpace 90>
     <PgfOptWordSpace 100>
     <PgfMaxWordSpace 110>
     <PgfLanguage UKEnglish>
     <PgfCellAlignment Top>
     <PgfCellMargins  0.0 pt 0.0 pt 0.0 pt 0.0 pt>
     <PgfCellLMarginFixed No>
     <PgfCellTMarginFixed No>
     <PgfCellRMarginFixed No>
     <PgfCellBMarginFixed No>
     <PgfLocked No>
    > # end of Pgf
   > # end of TblColumnH
   <TblColumnBody
    <Pgf
     <PgfTag `TD'>
     <PgfUseNextTag Yes>
     <PgfNextTag `TD'>
     <PgfAlignment Left>
     <PgfFIndent  0.0 cm>
     <PgfLIndent  0.0 cm>
     <PgfRIndent  0.0 cm>
     <PgfFIndentRelative No>
     <PgfFIndentOffset  0.0 cm>
     <PgfTopSeparator `'>
     <PgfTopSepAtIndent No>
     <PgfTopSepOffset  0.0 cm>
     <PgfBotSeparator `'>
     <PgfBotSepAtIndent No>
     <PgfBotSepOffset  0.0 cm>
     <PgfPlacement Anywhere>
     <PgfPlacementStyle Normal>
     <PgfRunInDefaultPunct `. '>
     <PgfSpBefore  0.0 pt>
     <PgfSpAfter  3.0 pt>
     <PgfWithPrev No>
     <PgfWithNext Yes>
     <PgfBlockSize 1>
     <PgfFont
      <FTag `'>
      <FPlatformName `W.Arial.R.700'>
      <FFamily `Arial'>
      <FVar `Regular'>
      <FWeight `Regular'>
      <FAngle `Regular'>
      <FSize  9.5 pt>
      <FUnderlining FNoUnderlining>
      <FOverline No>
      <FStrike No>
      <FChangeBar No>
      <FOutline No>
      <FShadow No>
      <FPairKern No>
      <FCase FAsTyped>
      <FPosition FNormal>
      <FDX  0.0%>
      <FDY  0.0%>
      <FDW  0.0%>
      <FLocked No>
      <FSeparation 0>
      <FColor `Black'>
     > # end of PgfFont
    > # end of Pgf
   > # end of TblColumnBody
   <TblColumnF
    <PgfTag `TH'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblColumn
   <TblColumnNum 1>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
    <PgfTag `TH'>
   > # end of TblColumnH
   <TblColumnBody
     <PgfTag `TD'>
   > # end of TblColumnBody
   <TblColumnF
    <PgfTag `TH'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblColumn
   <TblColumnNum 2>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
    <PgfTag `TH'>
   > # end of TblColumnH
   <TblColumnBody
     <PgfTag `TD'>
   > # end of TblColumnBody
   <TblColumnF
    <PgfTag `TH'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblColumn
   <TblColumnNum 3>
   <TblColumnWidth  3.125 cm>
   <TblColumnH
    <PgfTag `TH'>
   > # end of TblColumnH
   <TblColumnBody
     <PgfTag `TD'>
   > # end of TblColumnBody
   <TblColumnF
    <PgfTag `TH'>
   > # end of TblColumnF
  > # end of TblColumn
  <TblCellMargins  4.0 pt 4.0 pt 4.0 pt 4.0 pt>
  <TblLIndent  0.0 cm>
  <TblRIndent  0.0 cm>
  <TblAlignment Center>
  <TblPlacement Anywhere>
  <TblSpBefore  12.0 pt>
  <TblSpAfter  18.0 pt>
  <TblBlockSize 2>
  <TblHFFill 15>
  <TblHFSeparation 0>
  <TblHFColor `Black'>
  <TblBodyFill 15>
  <TblBodySeparation 0>
  <TblBodyColor `Black'>
  <TblShadeByColumn No>
  <TblLocked No>
  <TblShadePeriod 2>
  <TblXFill 15>
  <TblXSeparation 0>
  <TblXColor `Black'>
  <TblAltShadePeriod 2>
  <TblLRuling `Very Thin'>
  <TblBRuling `Very Thin'>
  <TblRRuling `Very Thin'>
  <TblTRuling `Very Thin'>
  <TblColumnRuling `Very Thin'>
  <TblXColumnRuling `Very Thin'>
  <TblBodyRowRuling `Very Thin'>
  <TblXRowRuling `Very Thin'>
  <TblHFRowRuling `Very Thin'>
  <TblSeparatorRuling `Very Thin'>
  <TblXColumnNum 1>
  <TblRulingPeriod 4>
  <TblLastBRuling No>
  <TblTitlePlacement None>
  <TblTitlePgf1
   <Pgf
    <PgfTag `TableTitle'>
    <PgfAlignment Left>
    <PgfFIndent  1.75 cm>
    <PgfLIndent  4.75 cm>
    <PgfPlacementStyle Straddle>
    <PgfSpBefore  2.0 pt>
    <PgfWithNext Yes>
    <PgfBlockSize 2>
    <PgfFont
     <FTag `'>
     <FPlatformName `W.Arial.R.700'>
     <FFamily `Arial'>
     <FVar `Regular'>
     <FWeight `Bold'>
     <FAngle `Regular'>
     <FSize  12.0 pt>
     <FUnderlining FNoUnderlining>
     <FOverline No>
     <FStrike No>
     <FChangeBar No>
     <FOutline No>
     <FShadow No>
     <FPairKern Yes>
     <FCase FAsTyped>
     <FPosition FNormal>
     <FDX  0.0%>
     <FDY  0.0%>
     <FDW  0.0%>
     <FLocked No>
     <FSeparation 0>
     <FColor `Black'>
    > # end of PgfFont
    <PgfAutoNum Yes>
    <PgfNumFormat `T:Table  \<n+\\>\\\\t'>
    <PgfNumberFont `'>
    <PgfNumAtEnd No>
    <PgfNumTabs 1>
    <TabStop
     <TSX  4.75 cm>
     <TSType Left>
     <TSLeaderStr ` '>
    > # end of TabStop
   > # end of Pgf
  > # end of TblTitlePgf1
  <TblTitleGap  6.0 pt>
  <TblInitNumColumns 4>
  <TblInitNumHRows 1>
  <TblInitNumBodyRows 3>
  <TblInitNumFRows 0>
  <TblNumByColumn No>
 > # end of TblFormat
> # end of TblCatalog
<Views
 <View
  <ViewNumber 1>
  <ViewCutout `White'>
 > # end of View
 <View
  <ViewNumber 2>
  <ViewCutout `White'>
  <ViewInvisible `Red'>
  <ViewInvisible `Green'>
  <ViewInvisible `Blue'>
  <ViewInvisible `Cyan'>
  <ViewInvisible `Magenta'>
 > # end of View
 <View
  <ViewNumber 3>
  <ViewInvisible `Black'>
  <ViewCutout `White'>
 > # end of View
 <View
  <ViewNumber 4>
  <ViewCutout `White'>
 > # end of View
 <View
  <ViewNumber 5>
  <ViewCutout `White'>
 > # end of View
 <View
  <ViewNumber 6>
  <ViewCutout `White'>
 > # end of View
> # end of Views
<VariableFormats
 <VariableFormat
  <VariableName `Running H/F 4'>
  <VariableDef `\<\$marker2\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Running H/F 1'>
  <VariableDef `\<\$paratext[Chapter]\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Current Page #'>
  <VariableDef `\<\$curpagenum\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Modification Date (Long)'>
  <VariableDef `\<\$shortmonthname\\> \<\$daynum\\>, \<\$year\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Modification Date (Short)'>
  <VariableDef `\<\$daynum\\>/\<\$monthnum\\>/\<\$shortyear\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Page Count'>
  <VariableDef `\<\$lastpagenum\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Running H/F 2'>
  <VariableDef `\<\$paratext[Heading]\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Running H/F 3'>
  <VariableDef `\<\$marker1\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Creation Date (Short)'>
  <VariableDef `\<\$year\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Creation Date (Long)'>
  <VariableDef `\<\$monthname\\> \<\$daynum\\>, \<\$year\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Filename (Long)'>
  <VariableDef `\<\$fullfilename\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Current Date (Long)'>
  <VariableDef `\<\$daynum\\> \<\$monthname\\>, \<\$year\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Current Date (Short)'>
  <VariableDef `\<\$monthnum\\>/\<\$daynum\\>/\<\$shortyear\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Filename (Short)'>
  <VariableDef `\<\$filename\\>'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Table Continuation'>
  <VariableDef ` (Continued)'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `Table Sheet'>
  <VariableDef ` (Sheet \<\$tblsheetnum\\> of \<\$tblsheetcount\\>)'>
 > # end of VariableFormat
 <VariableFormat
  <VariableName `DraftNotice'>
  <VariableDef `\<HUGE\\>Draft Only\<Default \\xa6  Font\\>'>
 > # end of VariableFormat
> # end of VariableFormats
<XRefFormats
 <XRefFormat
  <XRefName `ParaText'>
  <XRefDef `\<\$paratext\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `See section ..'>
  <XRefDef `section \<\$paranum\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `HugeText'>
  <XRefDef `\<HUGE\\>\<\$paratext\\>\<Default \\xa6  Font\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `Page'>
  <XRefDef `page \<\$pagenum\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `Heading & Page'>
  <XRefDef `\<\$paratext\\> on page \<\$pagenum\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `Section & Page'>
  <XRefDef `section \<\$paranum\\> on page \<\$pagenum\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `ParaNum'>
  <XRefDef `\<\$paranum\\>'>
 > # end of XRefFormat
 <XRefFormat
  <XRefName `ParaNumOnly'>
  <XRefDef `\<\$paranumonly\\>'>
 > # end of XRefFormat
> # end of XRefFormats
<Document
 <DViewRect 24 45 601 498 >
 <DWindowRect 2 2 669 583 >
 <DViewScale  100.0%>
 <DNextUnique 216474>
 <DPageSize  21.0 cm 29.7 cm>
 <DMenuBar `'>
 <DVoMenuBar `'>
 <DStartPage 1>
 <DPageNumStyle Arabic>
 <DPagePointStyle Arabic>
 <DTwoSides Yes>
 <DParity FirstRight>
 <DFrozenPages No>
 <DPageRounding DeleteEmptyPages>
 <DFNoteMaxH  10.16 cm>
 <FNoteStartNum 1>
 <DFNoteRestart PerPage>
 <DFNoteTag `Footnote'>
 <DFNoteLabels `*\\xa0 \\xe0 '>
 <DFNoteNumStyle Arabic>
 <DFNoteAnchorPos FNSuperscript>
 <DFNoteNumberPos FNSuperscript>
 <DFNoteAnchorPrefix `'>
 <DFNoteAnchorSuffix `'>
 <DFNoteNumberPrefix `'>
 <DFNoteNumberSuffix `.  '>
 <DTblFNoteTag `TableFootnote'>
 <DTblFNoteLabels `*\\xa0 \\xe0 '>
 <DTblFNoteNumStyle LCAlpha>
 <DTblFNoteAnchorPos FNSuperscript>
 <DTblFNoteNumberPos FNBaseline>
 <DTblFNoteAnchorPrefix `'>
 <DTblFNoteAnchorSuffix `'>
 <DTblFNoteNumberPrefix `'>
 <DTblFNoteNumberSuffix `. '>
 <DLinebreakChars `- \\xd0  \\xd1 '>
 <DPunctuationChars `:;,.\\xc9 !?'>
 <DChBarGap  0.3 cm>
 <DChBarWidth  1.5 pt>
 <DChBarPosition NearestEdge>
 <DChBarColor `Black'>
 <DAutoChBars No>
 <DShowAllConditions No>
 <DDisplayOverrides Yes>
 <DPageScrolling Variable>
 <DViewOnly No>
 <DViewOnlyXRef GotoBehavior>
 <DViewOnlySelect Yes>
 <DViewOnlyWinBorders Yes>
 <DViewOnlyWinMenubar Yes>
 <DViewOnlyWinPopup Yes>
 <DViewOnlyWinPalette No>
 <DFluid No>
 <DFluidSideheads No>
 <DGridOn No>
 <DPageGrid  1.0 cm>
 <DSnapGrid  0.2 cm>
 <DSnapRotation  0.25>
 <DRulersOn Yes>
 <DFullRulers Yes>
 <DGraphicsOff No>
 <DCurrentView 1>
 <DBordersOn Yes>
 <DSymbolsOn Yes>
 <DLinkBoundariesOn No>
 <DSmartQuotesOn Yes>
 <DSmartSpacesOn Yes>
 <DUpdateTextInsetsOnOpen Yes>
 <DUpdateXRefsOnOpen Yes>
 <DLanguage UKEnglish>
 <DSuperscriptSize  80.0%>
 <DSubscriptSize  80.0%>
 <DSmallCapsSize  80.0%>
 <DSuperscriptShift  40.0%>
 <DSubscriptShift  25.0%>
 <DMathAlphaCharFontFamily `Times New Roman'>
 <DMathSmallIntegral  14.0 pt>
 <DMathMediumIntegral  18.0 pt>
 <DMathLargeIntegral  24.0 pt>
 <DMathSmallSigma  14.0 pt>
 <DMathMediumSigma  18.0 pt>
 <DMathLargeSigma  24.0 pt>
 <DMathSmallLevel1  9.0 pt>
 <DMathMediumLevel1  10.0 pt>
 <DMathLargeLevel1  14.0 pt>
 <DMathSmallLevel2  7.0 pt>
 <DMathMediumLevel2  7.0 pt>
 <DMathLargeLevel2  12.0 pt>
 <DMathSmallLevel3  5.0 pt>
 <DMathMediumLevel3  5.0 pt>
 <DMathLargeLevel3  8.0 pt>
 <DMathSmallHoriz  0.0 pt>
 <DMathMediumHoriz  0.0 pt>
 <DMathLargeHoriz  0.0 pt>
 <DMathSmallVert  0.0 pt>
 <DMathMediumVert  0.0 pt>
 <DMathLargeVert  0.0 pt>
 <DMathShowCustom No>
 <DMathFunctions `'>
 <DMathNumbers `'>
 <DMathVariables `EquationVariables'>
 <DMathStrings `'>
 <DMathGreek `'>
  <DMathCatalog >
 <DPrintSkipBlankPages No>
 <DPrintSeparations No>
 <DNoPrintSepColor `White'>
 <DGenerateAcrobatInfo No>
 <DAcrobatParagraphBookmarks Yes>
 <DAcrobatBookmarksIncludeTagNames No>
> # end of Document
<BookComponent
 <FileName `\<c\\>HTMLIX.doc'>
 <FileNameSuffix `IX'>
 <DeriveLinks No>
 <DeriveType IDX>
 <DeriveTag `Index'>
> # end of BookComponent
<BookComponent
 <FileName `\<c\\>HTMLLOT.doc'>
 <FileNameSuffix `LOT'>
 <DeriveLinks No>
 <DeriveType LOT>
 <DeriveTag `TableTitle'>
> # end of BookComponent
<BookComponent
 <FileName `\<c\\>HTMLLOF.doc'>
 <FileNameSuffix `LOF'>
 <DeriveLinks No>
 <DeriveType LOF>
 <DeriveTag `FigTitle'>
> # end of BookComponent
<BookComponent
 <FileName `\<c\\>HTMLTOC.doc'>
 <FileNameSuffix `TOC'>
 <DeriveLinks No>
 <DeriveType TOC>
 <DeriveTag `1Heading'>
 <DeriveTag `2Heading'>
 <DeriveTag `3Heading'>
 <DeriveTag `Appendix1'>
 <DeriveTag `Appendix2'>
 <DeriveTag `Appendix3'>
 <DeriveTag `ChapterFirst'>
 <DeriveTag `ChapterNext'>
> # end of BookComponent
<InitialAutoNums
 <AutoNumSeries
  <FlowTag `A'>
  <Series `B'>
 > # end of AutoNumSeries
 <AutoNumSeries
  <FlowTag `A'>
  <Series `'>
 > # end of AutoNumSeries
 <AutoNumSeries
  <FlowTag `A'>
  <Series `F'>
  <NumCounter 1>
 > # end of AutoNumSeries
> # end of InitialAutoNums
<Dictionary
> # end of Dictionary
EOFT
  $imgunit =<<EOFF;
 <Frame
  <ID 1>
  <Pen 15>
  <Fill 15>
  <PenWidth  1.0 pt>
  <Separation 0>
  <ObColor `Black'>
  <DashedPattern
   <DashedStyle Solid>
  > # end of DashedPattern
  <RunaroundGap  6.0 pt>
  <RunaroundType None>
  <Angle  360.0>
  <Overprint No>
  <ShapeRect  5.81255 cm 16.61219 cm 12.7 cm 8.9 cm>
  <BRect  5.81255 cm 16.61219 cm 12.7 cm 8.9 cm>
  <FrameType Below>
  <Float No>
  <NSOffset  0.0 cm>
  <BLOffset  0.0 cm>
  <AnchorAlign Right>
  <Cropped No>
  <ImportObject
   <Fill 7>
   <RunaroundType Contour>
   <Overprint No>
   <ImportObFileDI `\<c\\>martin.gif'>
   <ImportObFile `martin.gif'>
   <ImportHint `0001FRAMGIF WIN3    grphfilt.dll'>
   <ImportObUpdater `GIF'>
   <ShapeRect  0.1 cm 0. cm XXX cm YYY cm>
   <BRect  0.1 cm 0.1 cm XXX cm YYY cm>
   <ImportObFixedSize Yes>
   <BitMapDpi 0>
   <FlipLR No>
  > # end of ImportObject
 > # end of Frame
EOFF

  $aframe_instances=<<EOAF;
<AFrames
> # end of AFrames
EOAF

  $masterpages=<<EOMP;
<Page
 <PageType ReferencePage>
 <PageTag `Reference'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <Frame
  <Pen 15>
  <Fill 15>
  <PenWidth  1.0 pt>
  <Separation 0>
  <ObColor `Black'>
  <DashedPattern
   <DashedStyle Solid>
  > # end of DashedPattern
  <RunaroundGap  0.0 pt>
  <RunaroundType None>
  <Angle  360.0>
  <ShapeRect  2.62818 cm 4.79999 cm 17.37179 cm 0.47055 cm>
  <BRect  2.62818 cm 4.79999 cm 17.37179 cm 0.47055 cm>
  <FrameType NotAnchored>
  <Tag `1Heading Rule'>
  <PolyLine
   <Pen 0>
   <HeadCap Square>
   <TailCap Square>
   <NumPoints 2>
   <Point  0.0 cm 0.2 cm>
   <Point  17.25172 cm 0.2 cm>
  > # end of PolyLine
 > # end of Frame
 <TextLine
  <TLOrigin  2.54 cm 4.55168 cm>
  <TLAlignment Left>
  <Font
   <FTag `'>
   <FPlatformName `W.Arial.R.700'>
   <FFamily `Arial'>
   <FVar `Regular'>
   <FWeight `Bold'>
   <FAngle `Regular'>
   <FEncoding `FrameRoman'>
   <FSize  12.0 pt>
   <FUnderlining FNoUnderlining>
   <FOverline No>
   <FStrike No>
   <FChangeBar No>
   <FOutline No>
   <FShadow No>
   <FPairKern No>
   <FCase FAsTyped>
   <FPosition FNormal>
   <FDX  0.0%>
   <FDY  0.0%>
   <FDW  0.0%>
   <FLocked No>
   <FSeparation 0>
   <FColor `Black'>
  > # end of Font
  <String `1Heading Rule'>
 > # end of TextLine
 <TextLine
  <TLOrigin  4.5 cm 11.49999 cm>
  <TLAlignment Left>
  <Font
   <FTag `'>
   <FSize  10.0 pt>
   <FPairKern Yes>
   <FLocked No>
  > # end of Font
 > # end of TextLine
> # end of Page
<Page
 <PageType ReferencePage>
 <PageTag `TOC'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <TextRect
  <ID 6>
  <Pen 15>
  <Fill 7>
  <PenWidth  1.0 pt>
  <Separation 0>
  <ObColor `Black'>
  <DashedPattern
   <DashedStyle Solid>
  > # end of DashedPattern
  <RunaroundGap  0.0 pt>
  <RunaroundType None>
  <ShapeRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <BRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <TRNumColumns 1>
  <TRColumnGap  1.0 cm>
  <TRColumnBalance No>
  <TRSideheadWidth  3.81 cm>
  <TRSideheadGap  0.635 cm>
  <TRSideheadPlacement Left>
  <TRNext 0>
 > # end of TextRect
 <TextLine
  <TLOrigin  2.54 cm 2.0 cm>
  <TLAlignment Left>
  <Font
   <FTag `'>
   <FPlatformName `W.Arial.R.700'>
   <FWeight `Bold'>
   <FEncoding `FrameRoman'>
   <FSize  12.0 pt>
   <FLocked No>
  > # end of Font
  <String `Table of Contents Specification'>
 > # end of TextLine
> # end of Page
<Page
 <PageType ReferencePage>
 <PageTag `IX'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <TextRect
  <ID 7>
  <Pen 15>
  <Fill 15>
  <PenWidth  1.0 pt>
  <Separation 0>
  <ObColor `Black'>
  <DashedPattern
   <DashedStyle Solid>
  > # end of DashedPattern
  <RunaroundGap  0.0 pt>
  <RunaroundType None>
  <ShapeRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <BRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <TRNumColumns 1>
  <TRColumnGap  1.0 cm>
  <TRColumnBalance No>
  <TRSideheadWidth  3.81 cm>
  <TRSideheadGap  0.635 cm>
  <TRSideheadPlacement Left>
  <TRNext 0>
 > # end of TextRect
 <TextLine
  <TLOrigin  2.54 cm 2.0 cm>
  <TLAlignment Left>
  <Font
   <FTag `'>
   <FPlatformName `W.Arial.R.700'>
   <FWeight `Bold'>
   <FEncoding `FrameRoman'>
   <FSize  12.0 pt>
   <FLocked No>
  > # end of Font
  <String `Index Specification'>
 > # end of TextLine
> # end of Page
<Page
 <PageType LeftMasterPage>
 <PageTag `Left'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <TextRect
  <ID 4>
  <Fill 15>
  <Separation 0>
  <ObColor `Black'>
  <RunaroundGap  6.0 pt>
  <ShapeRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <BRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <TRNumColumns 1>
  <TRColumnGap  0.0 cm>
  <TRColumnBalance No>
  <TRSideheadWidth  3.0 cm>
  <TRSideheadGap  0.5 cm>
  <TRSideheadPlacement Left>
 > # end of TextRect
> # end of Page
<Page
 <PageType RightMasterPage>
 <PageTag `Right'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <TextRect
  <ID 5>
  <Fill 15>
  <Separation 0>
  <ObColor `Black'>
  <RunaroundGap  6.0 pt>
  <ShapeRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <BRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <TRNumColumns 1>
  <TRColumnGap  0.0 cm>
  <TRColumnBalance No>
  <TRSideheadWidth  3.0 cm>
  <TRSideheadGap  0.5 cm>
  <TRSideheadPlacement Left>
 > # end of TextRect
> # end of Page
<Page
 <PageType BodyPage>
 <PageNum `1'>
 <PageTag `'>
 <PageSize  21.0 cm 29.7 cm>
 <PageOrientation Portrait>
 <PageAngle  0.0>
 <PageBackground `Default'>
 <TextRect
  <ID 8>
  <Fill 15>
  <Separation 0>
  <ObColor `Black'>
  <RunaroundGap  6.0 pt>
  <ShapeRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <BRect  2.54 cm 2.54 cm 15.92 cm 24.62 cm>
  <TRNumColumns 1>
  <TRColumnGap  0.0 cm>
  <TRColumnBalance No>
  <TRSideheadWidth  3.0 cm>
  <TRSideheadGap  0.5 cm>
  <TRSideheadPlacement Left>
 > # end of TextRect
> # end of Page
<TextFlow
 <TFTag `A'>
 <TFAutoConnect Yes>
 <TFFeather Yes>
 <TFMaxInterLine  2.0 pt>
 <TFMaxInterPgf  5.9 pt>
 <TFSideheads Yes>
 <Notes
 > # end of Notes
 <Para
  <PgfTag `P'>
  <ParaLine
   <TextRectID 4>
  > # end of ParaLine
 > # end of Para
> # end of TextFlow
<TextFlow
 <TFTag `A'>
 <TFAutoConnect Yes>
 <TFFeather Yes>
 <TFMaxInterLine  2.0 pt>
 <TFMaxInterPgf  5.9 pt>
 <TFSideheads Yes>
 <Notes
 > # end of Notes
 <Para
  <PgfTag `P'>
  <ParaLine
   <TextRectID 5>
  > # end of ParaLine
 > # end of Para
> # end of TextFlow
<TextFlow
 <TFTag `'>
 <TFAutoConnect No>
 <TFFeather Yes>
 <TFMaxInterLine  2.0 pt>
 <TFMaxInterPgf  5.9 pt>
 <TFSideheads Yes>
 <Notes
 > # end of Notes
 <Para
  <PgfTag `P'>
  <ParaLine
   <TextRectID 6>
  > # end of ParaLine
 > # end of Para
> # end of TextFlow
<TextFlow
 <TFTag `'>
 <TFAutoConnect No>
 <TFFeather Yes>
 <TFMaxInterLine  2.0 pt>
 <TFMaxInterPgf  5.9 pt>
 <TFSideheads Yes>
 <Notes
 > # end of Notes
 <Para
  <PgfTag `P'>
  <ParaLine
   <TextRectID 7>
  > # end of ParaLine
 > # end of Para
> # end of TextFlow
EOMP
  $textflowtop=<<EOTFT;
<TextFlow
 <TFTag `A'>
 <TFAutoConnect Yes>
 <TFFeather Yes>
 <TFMaxInterLine  2.0 pt>
 <TFMaxInterPgf  5.9 pt>
 <TFSideheads Yes>
 <Notes
 > # end of Notes
EOTFT
  $endofall=<<EOALL;
> # end of TextFlow
# End of MIFFile
EOALL
  $textform=<<EOTXTF;
   <String `STRINGCONTENTS '>
EOTXTF
  $parastart=<<EOBS;
 <Para
  <PgfTag `TAG'>
EOBS
  $paraline=<<EOPL;
  <ParaLine
EOPL
  $flowrect=<<EOFLRECT;
   <TextRectID 8>
EOFLRECT
  $paraend=<<EOPE;
 > # end of Para
EOPE
  $paralineend=<<EOPLE;
  > # end of ParaLine
EOPLE
  $tblstart=<<EOTBLS;
 <Tbl
  <TblID 1>
EOTBLS
  $theadstart =<<EOTH;
  <TblH
EOTH
  $trstart=<<EOTR;
   <Row
EOTR
  $tdstart=<<EOTD;
    <Cell
     <CellContent
EOTD
  $theadend=<<EOTHE;
  > # end of TblH
EOTHE
  $tbodystart=<<EOTBODY;
  <TblBody
EOTBODY
  $trend=<<EOTRE;
   > # end of Row
EOTRE
  $tdend=<<EOTDE;
     > # end of CellContent
    > # end of Cell
EOTDE
  $tblend=<<EOTBLE;
  > # end of TblBody
 > # end of Tbl
EOTBLE
  $tblnobords=<<EONBS;
  <TblFormat
   <TblTag `NoBorders'>
EONBS
  $tblformend=<<EOTBLENDF;
  > # end of TblFormat
EOTBLENDF
  $tblnormbords=<<EONORMBS;
 <TblFormat
  <TblTag `NormalBorders'>
EONORMBS
$fontstart=<<EOFFSTART;
   <Font
    <FTag `FTAG'>
    <FLocked No>
   > # end of Font
EOFFSTART
  $mark=<<EOFMARK;
   <Marker
    <MType 9>
    <MText `XXMarkTextXX'>
  <MCurrPage `1'>
   > # end of Marker
EOFMARK
  $xrefstart=<<EOXREFS;
   <XRef
    <XRefName `ParaText'>
    <XRefSrcText `XXXRefTextXXX'>
  <XRefSrcIsElem No>
  <XRefSrcFile `'>
   > # end of XRef
EOXREFS
  $fontend=<<EOFFEND;
   <Font
    <FTag `'>
    <FLocked No>
   > # end of Font
EOFFEND
  $colwidth=<<EOCOLWID;
  <TblColumnWidth  XXwidthXX cm>
EOCOLWID
  $tblcolblank=<<ENDOFDATA;
   <TblColumn
     <TblColumnNum 0>
   > # end of TblColumn
ENDOFDATA


my @initvalues =  ($outfile, $tblmatrix, $filetop, $aframe_instances, $table_instances,
                  $masterpages, $textflowtop, $textflow, $endofall, $inflow,
                  $intable, $intblhd, $intblbody, $inmark, $inhref, $lasttag, $mark,
                  $xrefstart, $inlist, $numfirst, $textform, $imgunit,
                  $imgcount, $thisparstart, $thispar, $thisparend, $thistable,
                  $thisformat, $thisrow, $thiscell, $tblcount, $maxcols,
                  $rowcount, $colcount, $maxtblcols, $tblstart, $tblnormbords,
                  $tblnobords, $theadstart, $tbodystart, $theaddone, $trstart,
                  $tdstart, $tblformend, $tblcolblank, $theadend, $trend, $tdend,
                  $tblend, $parastart, $paraline, $flowrect, $paraend, $paralineend,
                  $fontstart, $fontend, $colwidth, $txtarea, $betweentags, $ignore);

my %inits;
@inits{@initkeys} = @initvalues;
\%inits;
}
1;