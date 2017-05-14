package HTML::WikiConverter::DokuWikiFCK;

#
#
# DokuWikFCK - A WikiCoverter Dialect for interfacing DokuWiki
# and the FCKEditor (http://www.fckeditor.net)
# which seeks to implement the graphic features of FCKEditor
#
# Myron Turner <turnermm02@shaw.ca>
#
# GNU General Public License Version 2 or later (the "GPL")
#    http://www.gnu.org/licenses/gpl.html
#
#

use strict;

use base 'HTML::WikiConverter::DokuWiki';
use HTML::Element;
use  HTML::Entities;
use Params::Validate ':types';


our $VERSION = '0.32';

  my $SPACEBAR_NUDGING = 0;
  my  $color_pattern = qr/
        ([a-zA-z]+)|                                #colorname 
        (\#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}))|        #colorvalue
        (rgb\(([0-9]{1,3}%?,){2}[0-9]{1,3}%?\))     #rgb triplet
        /x;
 
  my $font_pattern = qr//; 
  my %style_patterns = ( 'color' => \$color_pattern, 'font' => \$font_pattern );       

  my $nudge_char = '&#183;';
 
  my $NL_marker = '~~~'; 
  my $EOL = '=~='; 
  my $code_NL = '-NLn-'; 

  my %_formats = ( 'b' => '**',                
                  'em' => '//',
                  'i'  => '//', 
                  'u' => '__', 
                  'ins' => '__'
               );

  my %_format_regex = ( 'b' => qr/\*\*/,                  
                        'em' => qr/\/\//,
                        'i' => qr/\/\//,
                        'u' => qr/__/, 
                        'ins' => qr/__/ 
               );

  my %_format_esc =   ( 'b' => '%%**%%',                   
                        'em' => '%%//%%',
                        'i'  => '%%//%%', 
                        'u' => '%%__%%', 
                        'ins' => '%%__%%'
               );

 my %dw_code = ( 'regex' => qr/\'\'/,
                 'esc' => "%%\'\'%%"
              );

my $kbd_start   = '<font _dummy_/AmerType Md BT,American Typewriter,courier New>';
my $kbd_end = '</font>';


sub attributes {
  return {
            browser => { default => 'IE5', type => SCALAR },
            group => { default => 'ANY', type => SCALAR },
  };
}
			
sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{'strike_out'} = 0;   # this prevents deletions from being paragraphed
  $self->{'list_type'} = "";
  $self->{'list_output'} = 0;   # tells postprocess_output to clean up lists, if 1
  $self->{'in_table'} = 0;
  $self->{'colspan'} = "";
  $self->{'code'} = 0;
  $self->{'block'} = 0;
  $self->{'share'} = 0;
  $self->{'do_nudge'} = $SPACEBAR_NUDGING;

  if(!$self->{'do_nudge'}) {
        $nudge_char = ' ';
  }
  $self->{'err'} = "NOERR\n";
  $self->{'_fh'} = 0;  # turn off debugging
  # $self->{'_fh'} = getFH();
  $self->{'os'} = $^O;
  return $self;
}




sub getFH {
  my($self) =  @_;
  local *FH; 
  #  if(open(FH, '>> C:\\Windows\\Temp\\dwfckg.log')) { 
  if(open(FH, ">> /var/tmp/dwfckg.log")) {
     return *FH;
  }
  $self->{'err'} = "$! \n";
  return 0;
}



sub rules {
  my $self = shift;
  my $rules = $self->SUPER::rules();
 
  $rules->{ 'span' } = { replace => \&_span_contents };
  $rules->{ 'p' }  = {replace => \&_p_alignment };
  $rules->{ 'div' }  = {replace => \&_p_alignment };
  $rules->{ 'img' }  = {replace => \&_image };
  $rules->{ 'a' } =   { replace => \&_link };
  $rules->{ 'blockquote' } = { replace => \&_block };
  $rules->{ 'pre' } =  { replace => \&_code_types };  
  $rules->{ 'var' } =   { start => '//', end => '//' }; 

  $rules->{ 'address' } =  { start => '//', end => '//' }; 
  $rules->{ 'strike' } =  { start => '<del>', end => '</del>' }; 
  $rules->{ 'cite' } =  { start => '//', end => '//' }; 
  $rules->{ 'del' } =   { alias => 'strike'  };

  $rules->{ 'kbd' } =   { start => $kbd_start, end => $kbd_end }; 
  $rules->{ 'tt' } =    { start => '<font 120%/sans-serif>', end => '</font>' }; 
  $rules->{ 'samp' } =  { start => '<font 120%/courier New>', end => '</font>' }; 
  $rules->{ 'q' }   =   { start => '"', end => '"' };  
  $rules->{ 'li' }   =  { replace => \&_li_start };
  $rules->{ 'ul' } =  { line_format => 'multi', block => 1, line_prefix => '  ',
                            end => "\n<align left></align>\n" },
  $rules->{ 'ol' } = {  alias => 'ul' };
  $rules->{ 'hr' } = { replace => "$NL_marker\n----${NL_marker}\n" };

  if($self->{'do_nudge'}) {
      $rules->{ 'indent' } = { replace => \&_indent  };
  }
  else {  
    $rules->{ 'indent' } = { preserve => 1  };
  }
  $rules->{ 'dwfckg' } = { preserve => 1  };
  $rules->{ 'header' } = { preserve => 1  };  
  $rules->{ 'td' } = { replace => \&_td_start };
  $rules->{ 'th' } = { alias => 'td' };
  $rules->{ 'tr' } = { start => "$NL_marker\n", line_format => 'single', end => \&_row_end };
  for( 1..5 ) {
    $rules->{"h$_"} = { replace => \&_header };
  }
  $rules->{'plugin'} = { replace => \&_plugin};
 # $rules->{ 'table' } = { start =>"<align left></align>", end => "<align left><br /></align>" };
  $rules->{ 'table' } = { replace => \&_table };
  $rules->{'ins'} = { alias => 'u'};
  $rules->{'b'} = { replace => \&_formats };
  $rules->{'i'} = { replace => \&_formats };
  $rules->{'u'} = { replace => \&_formats };
  
  $rules->{'sup'} = { replace  => \&_sup  }; 

  return $rules;
 
}


sub _formats {
    my($self, $node, $rules ) = @_;

    my $text = $self->get_elem_contents($node);

  # $text = $self->trim($text);
    return "" if ! $text; 
    return "" if $text !~ /[\p{IsDigit}\p{IsAlpha}\p{IsXDigit}\\]/;

    my @count = $text =~ /\\/g;
    if(scalar @count) {
      my $count = scalar @count;
      $text =  "_<em_>dwfckgBACKSLASH_<em_>" x $count;
      return $text;
    }
    $text =~ s/^$_format_regex{$node->tag}//;
    $text =~ s/$_format_regex{$node->tag}$//;
    
    my $tag = $node->tag;
    
    $tag = 'b' if $tag eq 'strong';
 
    return ("_<". $tag  . "_>".  $text . "_<" . $tag . "_>"); 
     
}

sub _plugin {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node);  # text is the plugin pattern
 
  $text = $self->trim($text);
  return "" if  !$text;

  my $title = $node->attr('title');
  $title=$self->trim($title);
  if(!$title) {
        return "";
  }

 $text =~ s/((&lt;)+)/~$1~/g if $text !~ /[~]&lt;/;
 $text =~ s/((&gt;)+)/~$1~/g if $text !~ /&gt;[~]/;  

  return '<plugin title="' . $title  .  '">' . "$text</plugin>";
}


sub _row_end {
  my($self, $node, $rules ) = @_;

  if($self->{'colspan'}) {
      return $self->{'colspan'};
  }
  $self->{'colspan'} = ""  
}


sub _td_start {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node);

    $text =~ s/\<br\>\s*$//m;     # for Word tables pasted into editor
    $text =~ s/\<br\>\s*/<br \/>/gm;
    $text =~ s/\\\\/<br \/>/gm;   # see _p_alignment() comment
    $text =~ s/&lt;/dwfckgTableOpenBRACKET/gm;
    $self->{'colspan'} = "";
    my $prefix = $self->SUPER::_td_start($node, $rules);

    $self->{'in_table'} = 1;  
    $self->{'colspan'} = $node->attr('colspan') || ""; 

    my $td_backcolor = "";
    my %table_header = $self->_get_type($node, ['th', 'th'], 'font'); 

    my $align = $node->attr('align') || 'left';  
    $align =~ /^(\w)\w+/; 
    $align = uc($1);



    if(!%table_header && $prefix !~ /\s*\^\s/) {
       my $style = $node->attr('style') || '';  
       if($style) {
          my @styles = split ';', $style;
          my $td_w;  my $td_bg; my $td_a; my $back_color = "";  my $td_width = "";
          foreach my $s (@styles) {
             if($s =~ /background-color/) {
                    $td_bg = $s;
             }
             elsif($s =~ /width/) {
                $td_w = $s;
             }
            elsif($s =~ /text-align/) {
                $td_a = $s;
             }
          }
          $back_color = $self->_extract_style_value($td_bg, 'background-color') if $td_bg;

          $td_width = $self->_extract_style_value($td_w, 'width') if $td_w;
          
          if(($align eq 'L') && ($td_a = $self->_extract_style_value($td_a, 'text-align'))) {
                   $td_a =~ /^(\w)\w+/; 
                   $align = uc($1);
          }

           if($back_color || $td_width || $align) {
               $td_backcolor = " #$align" . $back_color . $td_width . '# ';
           }
       }
         else {
            $align = "#$align#";
         }
    }
    else {
       $align = "";  $td_backcolor = "";
    }



    if(%table_header) {
     
        if($table_header{'th'} =~ 'th') {
               $prefix = ' ^ ' ;
         
        }
        else {
               $prefix = ' | ' ;
        }

      $text = $self->trim($text);         
    }


   my $suffix = $self->_td_end($node,$rules);

   if($self->{'colspan'}) {
       $self->{'colspan'} = chop $suffix;  # save suffix marker for _row_end
 
   }
   
   $text =~ s/\n/ /gm;

   $td_backcolor = $align  if !$td_backcolor;

   return $prefix . $td_backcolor . $text . $suffix;
   
}


sub _extract_values {
  my ($self, $attr, $values) = @_;
  my $HTML_Elements = scalar @$values;

  return $values->[0]->{$attr} if exists $values->[0]->{$attr};

  $HTML_Elements--;
  if($HTML_Elements) {
     return $values->[$HTML_Elements]->{$attr} if exists $values->[$HTML_Elements]->{$attr};
  }
  
 return ""; 
}

sub _extract_style_value {
   my($self, $at, $search_term) = @_;

   my($attribute, $value) = split /:/, $at;

   $attribute =~ s/^\s+//;
   $attribute =~ s/\s+$//;

   $value =~ s/^\s+//;
   $value =~ s/\s+$//;

   return $value if $search_term &&  $attribute eq $search_term;
   return 0;
}


sub _get_type {
   my ($self, $node, $attrs,$type) = @_;

   my $valuepat =  ${$style_patterns{$type}};
   my %ret_values=();  


    my @values_1 = $node->look_down($attrs->[0], $valuepat);    
    if(@values_1) {
       my $retv =  $self->_extract_values($attrs->[0],\@values_1);
       if($retv) {
          $ret_values{$attrs->[0]} = $retv;
       }
     }
   
  
    my @values_2 = $node->look_down($attrs->[1], $valuepat) if scalar @$attrs == 2;

    if(@values_2) {
       my $retv =  $self->_extract_values($attrs->[1],\@values_2);
       if($retv) {
          $ret_values{$attrs->[1]} = $retv;
       }
     }

    if(!exists $ret_values{$attrs->[1]} || !exists $ret_values{$attrs->[0]}) {        
        my @style_values = $node->look_down('style',$font_pattern);
        if(@style_values) {
            my $retv =  $self->_extract_values('style',\@style_values);          
                                     
            if(!exists $ret_values{$attrs->[0]}) {
                my $attr_val =$self->_extract_style_value($retv, $attrs->[0]);
                if($attr_val) { 
                    $ret_values{$attrs->[0]} = $attr_val;   
                }
            }
            if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
                my $attr_val =$self->_extract_style_value($retv, $attrs->[1]);
                if($attr_val) {
                    $ret_values{$attrs->[1]} = $attr_val;   
                }
           }
          
        }
    }



    if(!exists $ret_values{$attrs->[0]}) {    
        my @values_1a =   $node->look_up($attrs->[0], $valuepat);
        if(@values_1a) {
           my $retv =  $self->_extract_values($attrs->[0],\@values_1a);
           if($retv) {
              $ret_values{$attrs->[0]} = $retv;
           }
         }
    }
 
    if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {    
        my @values_2a =   $node->look_up($attrs->[1], $valuepat);
        if(@values_2a) {
           my $retv =  $self->_extract_values($attrs->[1],\@values_2a);
           if($retv) {
              $ret_values{$attrs->[1]} = $retv;
           }
         }
    }
 
        if(!exists $ret_values{$attrs->[0]}) {    
            my @values_3 = $node->attr_get_i($attrs->[0]);
            foreach my $val(@values_3) {
                   $ret_values{$attrs->[0]} = $val;  # if there is a hit, take the first one, there 
                   last;                            # shouldn't be more
                }     
            }
    
     if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
        my @values_4 = $node->attr_get_i($attrs->[1]);
        foreach my $val(@values_4) {

               $ret_values{$attrs->[1]} = $val;
               last;                            # ditto to above
        }
     }


    if(!exists $ret_values{$attrs->[1]} || !exists $ret_values{$attrs->[0]}) {
        my @values_5 = $node->attr_get_i("style");
        foreach my $at(@values_5) {

            if(!exists $ret_values{$attrs->[0]}) {
                if($at =~ /$attrs->[0]/) {
                   my $attr_val =$self->_extract_style_value($at,$attrs->[0]);
                   if($attr_val) {     
                       $ret_values{$attrs->[0]} = $attr_val;   
                       last;          
                   }
                }     
            }

            if($attrs->[1] && !exists $ret_values{$attrs->[1]}) {
                if($at =~ /$attrs->[1]/) {
                   my $attr_val =$self->_extract_style_value($at, $attrs->[1]);
                  if($attr_val) {     
                       $ret_values{$attrs->[1]} = $attr_val;   
                       last;
                  }
                }     
            }
          
        }
    }
 
 
   return %ret_values;
}




sub _span_contents {
  my($self, $node, $rules ) = @_;

  my $text = $self->get_elem_contents($node);
  my $current_text = "";   # used where more than one span occurs in the markup retrieved as $text

  if($text =~ /^\s*<(color|font).*?\/(color|font)/) {
        return $text;
   }

  elsif($text =~ /(.*?)<(color|font).*?\/(color|font)/) {       
          $current_text = $1;
          my $tmp = $current_text;
          $tmp =~ s/([*\/\-'"{\[\]\(\)])/\\$1/gms;  # escape regex pattern characters
          $text =~ s/^$tmp//;   
          $current_text =  $self->trim($current_text);
  }
  

  my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
  if(%color_atts) {  
    my $fg = (exists $color_atts{'color'}) ? ($color_atts{'color'}) : "";
    my $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";

    $fg = 'black' if($fg eq 'white' && !$bg);

    if($fg eq $bg && $text =~ /<indent/) {
          $fg = '_dummy_';
    }
    if($fg eq $bg && $text =~ /<redact/) {
          $fg = '_dummy_';
    }
    if($current_text) {          
          $current_text = "<color $fg/$bg>$current_text</color>"; 
    }
    $text = "$current_text<color $fg/$bg>$text</color>";
   }

   elsif($current_text) {
   
   }

 my $pat = qr/<color\s+rgb\(\d+, \d+, \d+\)\/rgb\(\d+, \d+, \d+\)>/;
 $text =~ s/($pat)\s*$pat(.*?)<\/color>/$1$2/;
  

  my %font_atts = $self->_get_type($node, ['size', 'face'], 'font');
  if(%font_atts) {  
    my $size = (exists $font_atts{'size'}) ? ($font_atts{'size'}) : "_dummy_";
    my $face = (exists $font_atts{'face'}) ? ($font_atts{'face'}) : "_dummy_"; 
    if($current_text) {
        $text = "<font $size/$face>$current_text</font><font $size/$face>$text</font>";  
    }
   else {
       $text = "<font $size/$face>$text</font>";  
    }
  }

  if(!%font_atts && !%color_atts && $current_text) {
    $text = "$current_text$text";
  }

  return $text;
}

sub clean_text {
 my($self, $text) = @_;
    $text =~ s/<.*?>/ /gs;
    $text =~ s/\s+/ /gs;
          
    return $text;
}

sub _sup {
    my($self, $node, $rules ) = @_;

    my $text = $self->get_elem_contents($node) || "";
    return "" if $text =~ /Anchor/i;
    $text = $self->trim($text);
    return "<sup>$text</sup>"; 

}

sub _code_types {
    my($self, $node, $rules ) = @_;
    my $text = $self->get_elem_contents($node) || "";

    $text = $self->trim($text);
    $text =~ s/[\\]{2}/\n/g;   # required for IE which places <br> at end of each line
    $text =~ s/\n/$NL_marker\n/gms;

  
    $text =~ s/&lt;/dwfckgOpenPAREN/gms;       # substitution for open angle bracket
    $text =~ s/\/\*/dwfckgOpen_C_COMMENT/gms;   
    $text =~ s/\*\//dwfckgClosed_C_COMMENT/gms;   
 
    $text = $self->replace_formats($text);

    $text =~ s/<.*?>/ /gs;   # remove all tags

    $text =~ s/(?<![\w[:punct:]:])[\s](?![\w[:punct:]:])/x\00/gms;

    return "" if ! $text;  
    $self->{'code'} = 1;
    return "$NL_marker\n<code>${NL_marker}\n$text $NL_marker\n</code>\n"; 
}


sub _li_start {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node) || "";
  $text =~ s/<align\s*\w*>//gm;
  $text =~ s/<\/align>//gm;
  $text =~ s/^\s*//m;
  $text =~ s/\n{2,}/\n/gm; 
  my $type = $self->SUPER::_li_start($node, $rules);
  $self->{'list_output'} = 1;  # signal postprocess_output to clean up lists
  return  "$NL_marker\n$type" . $text . $EOL;
}


sub _hanging_formats {
   my ($self,$str, $search, $format) = @_;
 
   my @matches = $str =~ /$_format_regex{$format}/g;
  
   my $instances = scalar @matches;

   return $str if($instances % 2 == 0);
   if($instances == 1) {
       $str =~ s/$_format_regex{$format}/$_format_esc{$format}/;
 
       return $str;
   }

   return  $str;
}

sub replace_formats {
   my ($self, $output) = @_;

   my @format_ids = ( 'b', 'i', 'u'); 
   foreach my $format(@format_ids) {
        if($output =~ /$_format_regex{$format}/gms) {          
          $output =~ s/(?<!http:)($_format_regex{$format}(.*))/$self->_hanging_formats($1,$2, $format)/mse;          
        }   
    }

  $output =~ s/_<(\w+)_>/$_formats{$1}/g;

  if($output =~ /$dw_code{'regex'}/) {
        $output =~ s/$dw_code{'regex'}/$dw_code{'esc'}/gms;
  }

  return $output;
}

sub _p_alignment {
  my($self, $node, $rules ) = @_;
 
  my $output = $self->get_elem_contents($node) || "";

   $output =~ s/<[\/]*indent>//gm;
   $output =~ s/^([\s\x{a0}]+)/<indent>$1<\/indent>/m;
   $output =~ s/<indent><\/indent>//;
   $output =~ s/\\\\/<br \/>/gm;  # replace \\ with <br /> for p-to-line-break tool

   $output = $self->replace_formats($output);

   if($output =~ /^\s*[*\-]{1}\s+/gms) {
      
        $self->{'list_output'} = 1;
        return "\n  $output$EOL"; 
  }
  elsif($output =~/\<code/) { 
     return $output;
  }

  if($output =~ /<align/gms || $output =~ /<\/align/gms || $output =~ /\{\{.*?\}\}/gms) {

        return $output;
  }


  if($node->parent) {
    my $tag = $node->parent->tag();  
    if($tag eq 'td') { 
          return $output . "<br>";  ## use <br>, not <br /> so it doesn't getlopped of in postprocess
                                    ## converted to <br /> in _td_start and since I don't see
                                    ## where it would get lopped off, this could probably be <br />` 
    }    
  }

 

  my $newline = "";
  if($self->{'do_nudge'}  &&  $output =~ /^\s{3,}/) {   
       $newline = "<align 1px></align>";
  }


  if($output =~ /^(\s*|([\\][\\]))\s*<indent.*?>.*?<\/indent>\s*$/) {
              return "";
  }

  if($self->{'strike_out'}) {
        $self->{'strike_out'} = 0;
        return $output; 
  }

  my $align = $node->{'style'} if exists $node->{'style'};
  
  my $align_tag = "";

  my $aligns_cnt = 0;
  if($align) {   # there have been some styles with multiple attributes, hence this code
      my @styles = split ';', $align if($align);   
      foreach my $style(@styles) { 
          my ($att, $val) = split ':', $style;   
  
          if ($att && $val)
          {
           $att =~ s/^\s//;
           $att =~ s/\s$//;  
            if($att =~ /(text\-align|margin\-left)/) {
               $val =~ s/^\s//;
               $val =~ s/\s$//;  
               $align_tag .= " <align $val>";
               $aligns_cnt++;
            }
          }
      }
   }
  
   if(!$align_tag) {
      $align_tag = "<align>";
   }
  
  

     $output = "${align_tag}\n${output}\n</align>";
   
     $aligns_cnt--;     
     if($aligns_cnt) {
       for(1...$aligns_cnt) {
           $output .= " </align> ";
       }
     }
 

     $output=~s/http\:(?!\/\/)/http:\/\//gsm;
     $output =~ s/\/{3,}/\/\//g; # removes extra newline markers at start and end of images


 if($output =~ s/<align left>[\x{a0}\x{b7}]+<\/align>/<align left><\/align>/gms) {
      return $output;
 }

 $output =~ s/<align center>[\s\n\x{a0}\x{b7}]+<\/align>//gms; 
 $output =~ s/<align right>[\s\n\x{a0}\x{b7}]+<\/align>//gms;
 $output =~ s/<align \d+px>[\s\n\x{a0}\x{b7}]+<\/align>//gms;
 return  "" if(!$output);

 if($output =~/<align>[\s\n]*<\/align>/gms) {
         $output = '<br />';
 }
 return $newline . $output;
}


sub _dwimage_markup {
  my ($self, $src, $align) = @_;
  if($src !~ /^http:/) {
      $src =~ s/\//:/g;   
      if($src !~ /^:/) {
         $src = ":$src";
      }
  }

      if($align eq 'center') { 
         return "\n<align center>\n{{ $src }}\n</align>\n";
      }
      if($align eq 'right') {
       return "<align right>\n{{ $src}} </align>";
      }
      if($align eq 'left') {
       return "<align left>\n{{$src }}</align>";
      }
     if($align =~ /\d+px/) {
       return "<align $align>\n{{$src}}\n</align>";
      }

     if($align =~ /bottom|baseline/) {
       return "<align $align>\n{{$src}}\n</align>";
      }
    
   return "{{$src}}   ";
}

sub _image { 
    my($self, $node, $rules ) = @_;

   my $src = $node->attr('src') || '';

   return "" if(!$src);

  my $alignment = $self->_image_alignment($node);
  if(!$alignment && $node->parent) {
     $alignment = $self->_image_alignment($node->parent);
  }
  my $w = $node->attr('width') || 0;
  my $h = $node->attr('height') || 0;

  if(!$w) {
       $w = $node->attr('w') || 0;
  }
  if(!$h) {
     $h = $node->attr('h') || 0;
  }

  if( $w and $h ) {
    $src .= "?${w}x${h}";
  } elsif( $w ) {
    $src .= "?${w}";
  }

   if($src =~ /editor\/images\/smiley\/msn/) {
        if($src =~ /media=(http:.*?\.gif)/) {
              $src = $1;

        }
       else {
            my $HOST = $self->base_uri;
            $src = 'http://' . $HOST . $src if($src !~ /$HOST/);

       }

        return "{{$src}}   ";
   }


   if($src !~ /userfiles\/image/  && $src !~ /\/data\/media/) {
         my @elems = split /=/, $src;
         $src = pop @elems;
         return $self->_dwimage_markup($src,$alignment) if($src !~ /^http:/);
         return $self->_dwimage_markup($src,$alignment);
   }


   if($src =~ s/^(.*?)\/userfiles\/image\///) {
         return $self->_dwimage_markup($src,$alignment);
   }

   if($src =~ s/^(.*?)\/data\/media\///) {
         return $self->_dwimage_markup($src,$alignment);
   }

    my $img_url = $self->SUPER::_image($node, $rules);

    $img_url =~ s/%25/%/g;
    $img_url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    $img_url =~ s/%25/%/g;
    $img_url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;


   my @elems = split /media/, $img_url;
   if (scalar @elems > 2) {   
       my $last_el = pop @elems;
       my $dw_markup = $last_el;
       if($dw_markup =~ s/^(.*?)userfiles\/image\///) {
         return $self->_dwimage_markup($dw_markup, $alignment);
       }
       $img_url = $elems[0] . 'media' . $last_el;
   }


    return $img_url;
   
}

sub _image_alignment {
  my ($self, $node) = @_;
  my $align = $node->attr('align') || "";
  if($align) {
     $align = 'center' if $align eq 'middle';
     return $align;  
  }
  if($node->parent) {
    my $p = $node->parent;
    my %atts = $p->all_external_attr();
    foreach my $at(keys %atts) {

        if($at eq 'style') {

           if($atts{$at} =~ /margin-left:\s+(\d+px)/) {
                 return $1;
           }
           elsif($atts{$at} =~ /text-align:\s+(\w+)/) {
                 return $1;
           }
           elsif($atts{$at} =~ /bottom|base/) {
                 return 'bottom';
           }

        }
     } 
  }

  return ""; 
}


sub format_InternalLink {
  my($self, $node, $file) = @_; 

    my $inner_text = $self->get_elem_contents($node) || "";        
    $file = ":$file" if $file !~/^:/;
    if($inner_text) {
       return "$file|$inner_text";
    }
    return $file;
}

sub _link {
    my($self, $node, $rules ) = @_;   
    my $url = $node->attr('href') || '';

    my $name = $node->attr('name') || '';

    my $internal_link = "";
    my $_text = $self->get_elem_contents($node) || "";
   
# these manage shares
   if($url =~ /file:/) {
        $url =~ s/^file:[\/]+/__SHARE__/;
        $url =~ s/\//\\/g;
        $self->{'share'} = 1;
        return "[[$url|$_text]]";
   }
   elsif($url =~/[\\]{2,}/) {
        $url =~ s/^[\/]+//;
        $url =~ s/^[\\]+/__SHARE__/;
        $_text = $url if(!$_text);
        $_text =~ s/\\{2,}/\\/g; 

        $self->{'share'} = 1;
        return "[[$url|$_text]]";
    }

    if($name) {
         return '~~ANCHOR:' . $name . ':::' . $_text .'~~';
    }

    if ($url !~ /^\W*http:/ &&   $url =~ /\/(doku\.php\?id=)?:?((((\w)(\w|_)*)*:)*(\w(\w|_)*)*)$/) {

        my $format = $self->format_InternalLink($node,$2);
        $node->attr('href', $format);
        $internal_link = "[[$format]]";
    } 
    elsif($url !~ /^\W*http:/ &&   $url =~ /\/(doku\.php\?id=)?:?(\w+\#[\-\.\w]+)$/) {

        my $format = $self->format_InternalLink($node,$2);
        $node->attr('href', $format);
        $internal_link = "[[$format]]";

    }

    elsif($url !~ /^\W*http:/ &&   $url =~ /\/(doku\.php\?id=)?:(.*?)\.(.*)/ && $3 !~/gif|png|txt|jpg|jpeg/) {

        my $format = $self->format_InternalLink($node,"$2.$3");
        $node->attr('href', $format);
        $internal_link = "{{$format}}";
    }

    elsif ($url =~ /^mailto:(.*)(\?.*)?/) {
        return "<" . $1 . ">";
    } 
    elsif ($url =~ /\/lib\/exe\/fetch.php\?/) {
        my $content = $self->get_elem_contents($node);
        if ($content =~ /\{\{.*\}\}/) {
            return $content;
        }
        if ($url =~ /media=(.*)(&.*)?/) {	
            return "{{" . $1 . "}}" if lc $1 eq lc $content;
            return "{{" . $1 . "|" . $self->_as_text($node) . "}}";
        }
    }
    elsif ($url =~ /\/lib\/exe\/detail.php\?/) {
        my $content = $self->get_elem_contents($node);
        return $content;
    }

    my $output= $internal_link? $internal_link : $self->SUPER::_link($node, $rules); 

    my $text = $self->get_elem_contents($node) || "";

    my $left_alignment = "";   #actually any alignment, not just left
    if($text =~ s/(\<align \d+px>)//) {
      $left_alignment = $1;
      $text =~ s/<\/align>//;
      $output =~ s/\<align \d+px>//;
      $output =~ s/<\/align>//;
    }

    elsif($text =~ s/(\<align \w+>)//) {
      $left_alignment = $1;
      $text =~ s/<\/align>//;
      $output =~ s/\<align \w+>//;
      $output =~ s/<\/align>//;

    }


    my $external_open; my $external_closed;
  
    if($text =~ /(\<(font|color).*?\>)(.*?)(<\/\2>)/) {
         $external_open = $1;
         $external_closed  = $4;
         my $interior = $3;
         $text = $3;

         if($interior =~ /(\<(font|color).*?\>)(.*?)(<\/\2>)/) {
            $text = $3;
            $external_open = "${external_open}$1";  
            $external_closed = "$4${external_closed}";
         }
          
     }

    if($text =~ /^\s*[\\]{2}s*/) { return ""; }    
    
    my $emphasis = "";
   
    if($text =~ /(_<\w_>)/) {
        $emphasis = "$1";
    }
  #    $emphasis = ""  if $emphasis =~ /$_format_regex{'i'}/;
  
    if($text =~ /^(<.*?\w>).*?(<\/.*?>)$/) {
        my $start = $1;
        my $end = $2;

        my $start_pat = $start;
        my $end_pat = $end;
        $start_pat =~ s/(\W)/\\$1/g;
        $end_pat =~ s/(\W)/\\$1/g;

        $text =~ /^$start_pat(.*?)$end_pat$/;  

        $text = $1;
        if($text =~ /\W{2}(.*?)\W{2}/) {
            $text= $1;
        }
        $output =~ s/\|$start_pat.*?$end_pat/|$text/;
        $output = "$start${emphasis}${output}${emphasis}$end";  
    }
    elsif($emphasis) {
        $output =~ s/${emphasis}//g;
        $output = "${emphasis}${output}${emphasis}";
    }

   if($left_alignment) {
     $output = "$left_alignment${output}</align>";
   }


   if($external_open) {
        my($url, $name) = split /\|/, $output;

        $name =~ s/<.*?>//g;

        $output = $url . '|' . $name;
        $output  = $external_open . $output . $external_closed;
   }

    return $output;
}


sub _block {
  my($self, $node, $rules ) = @_;
  my $text = $self->get_elem_contents($node) || "";

  if($text =~ /<block/) {
       return $text;
   }

  $self->{'block'} = 1;
  my $bg = "";
  my $fg = "";
  my $width = '80';
  my $border = "";
  my $font = "";
  my $face = "";
  my $size = "";
  my $margin = "40";

  my $style = $node->attr('style');
  my @styles = split(';',$style);
  foreach my $at(@styles) {
     my $val = "";
     if($val = $self->_extract_style_value($at,'width') ) {
        $val =~ s/\%//;
        $width = int($val);
     }
     elsif($val = $self->_extract_style_value($at,'background-color') ) {
        $bg = $val; 
     }
     elsif($val = $self->_extract_style_value($at,'color') ) {
        $fg = $val; 
     }
     elsif($val = $self->_extract_style_value($at,'border') ) {
        $border = "$val"; 
     }

     elsif($val = $self->_extract_style_value($at,'border-left') ) {
        $border = "$val"; 
     }

     elsif($val = $self->_extract_style_value($at,'margin-left') ) {
        if($val =~/(\d+)/) { 
          $margin = $1; 
       }
     }
 
  }

   my $basics = $self->_get_basic_attributes ($node);
   if(!$fg) {
      $fg = $basics->{'color'};
   }
   $face = $basics->{'face'};
   $size = $basics->{'size'};  
   if($face || $size) {
    $font = "$face/$size";
   }

   $fg = 'black' if($fg eq 'white' && (!$bg || !$fg || $bg eq 'white'));

   if(!$bg) {
      if($text =~ /<color.*?\/(.*?)>/) {
               $bg = $1;
      }
   }

   my $block = "<block $width:$margin:${bg};$fg;$border;$font>";
     $text =~ s/^\s+//;          # trim  
     $text =~ s/\s+$//;
     $text =~ s/\n{2,}/\n/g;     # multi

   return $block . $text . '</block><br />';

}
   sub _table {
     my($self, $node, $rules ) = @_;
     my $text = $self->get_elem_contents($node) || "";
 
     my $table_header = "";
     my $align = $node->attr('align');
     if($align) {

       if($text=~/$NL_marker(.*?)$NL_marker/gms) {  
           my $row   = $1;  
           my @cols = $row=~/[\|\^]/g;
           my $cols = scalar @cols;    
           if($cols) {
             $cols--;
             $table_header = $NL_marker . "|++THEAD++ ALIGN=$align" .  '|' x $cols ;  
          }
       }
     }
        
   #  return "<align left></align>${table_header}$text<align left><br /></align>";
  return "<align left></align>${table_header}$text<align left></align>++END_TABLE++";
     
   }

   sub  postprocess_output {
    
      my($self, $outref ) = @_;  

      $$outref =~ s/^[\s\xa0]+//;          # trim  
            $$outref =~ s/[\s\xa0]+$//;
            $$outref =~ s/\n{2,}/\n/g;     # multi
            $$outref =~ s/\x{b7}/\x{a0}/gm;
	    
           $$outref =~ s/(?<=<\/align>)\s+(?=<align>)//gms; #### ???? ####
           $$outref =~ s/\s+$//gms;
           $$outref=~s/http\:(?!\/\/)/http:\/\//gsm; # replace missing forward slashes
           $$outref=~s/__(\/\/[\[\{])/$1/gsm;        # remove underlining markup
           $$outref=~s/([\}\]]\/\/)__/$1/gsm;        #   ditto
    
           $$outref =~ s/<dwfckg><\/dwfckg>//gms;

           $$outref =~ s/\^<align 0px><\/align>//g;           # remove aligns at top of file
           $$outref =~ s/[\s\n]*<align>[\s\n]*<\/align>[\s\n]*//gsm;      # remove empty aligns
           $$outref =~ s/<indent>\n*<\/indent>//gms;
                
 
          $$outref =~ s/(?<!\w\>)(?<!$NL_marker)\n(?!\<\W\w)/\n<align left><\/align> /gms; 
          $$outref =~ s/$NL_marker/\n/gms;

          $$outref =~ s/\n\s*(?=\|\n)//gms;

          $$outref =~ s/^\s+//gms;   # delete spaces at start of lines
          $$outref =~ s/(<align 0px>[\n\s]*<\/align>[\n\s]*)+//gms;   
          $$outref =~ s/(<align 1px>[\n\s]*<\/align>[\n\s]*)+//gms;   

          $$outref =~ s/\n[\\](2)s*/\n/gms;
 
         $$outref =~ s/(?<=<align>)[\n\s]+(?=<\/align>)//gms;
         $$outref =~ s/\n{3,}/\n/gms;           

         $$outref =~ s/<align left>[\n\s]+<\/align>[\\]{2}\s*//gms;

         $$outref =~ s/([\s\n]*<align><\/align>[\s\n]*){2,}/<align><\/align>/gms;
         $$outref =~ s/([\s\n]*<align center><\/align>[\s\n]*){2,}/<align center><\/align>/gms;
         $$outref =~ s/([\s\n]*<align right><\/align>[\s\n]*){2,}/<align right><\/align>/gms;
         $$outref =~ s/([\s\n]*<align left><\/align>([\s\n])*){2,}/$2 ? "<align left><\/align>$2" : "<align left><\/align>"/gmse;


         if($self->{'list_output'}) {   # start with look behind for bold
             $$outref =~ s/(?<![\*\-])([\*\-])(?:\s)(.*?)($EOL[\s\n]*)/$self->_format_list($1,$2, $3)/gmse; 
         }

         $$outref =~ s/(?!\n)<align left>/\n<align left>/gms;
         $$outref =~ s/<font _dummy_\/courier New>\s*<\/font>//gms;

         $$outref =~ s/([\/\{]{2})*(\s*)(?<!\[\[)\s*(http:\/\/[_\p{IsDigit}\p{IsAlpha}\p{IsXDigit};&?:.\-='"\/]{7,})(?!\|)/$self->_clean_url($3,$1, $2)/egms;   

         $$outref =~ s/__SHARE__/\\\\/gms if $self->{'share'}; 

         $$outref =~s/$EOL//g;

         $$outref =~ s/<code><\/code>//gms;
   	     $$outref =~ s/<code>[\W]+<\/code>//gms;
      
         $$outref =~ s/<align \w+>[\n\s]*(<align \w+>.*?<\/align>[\n\s]*)<\/align>/$1/gms;

         $self->del_xtra_c_aligns($$outref);

         $$outref =~ s/<\/align>\s*<br \/>/<\/align>/gms;
         $$outref =~ s/\n+/\n/gms;


         if($self->{'in_table'}) {    # insure tables start with newline               
             $$outref =~ s/align>\s*(\||\^)/align>\n$1/gms; 
             $$outref =~ s/[\\]{2}(?=\s+\|)//gms;  # remove line breaks at ends of cells
         }


        $$outref =~ s/(?<=\<\/align>)(\s*[\\]{2}\s*)+//gms;
        $$outref =~ s/(?<=\<\/align>)\s*<br \/>\s*//gms;

        if($self->{'code'}) {            
           $$outref =~ s/x\00/ /gms;
           $$outref =~ s/(?<=<code>)(.*?)(?=<\/code>)/$self->fix_code($1)/gmse;
           $$outref =~ s/<\/code>[\s\n]*$/<\/code><br \/>/;          
       }

       $$outref =~ s/<\/block>/<\/block><align left><\/align>/gm if $self->{'block'};         
       $$outref .= "\n" unless $$outref =~ /\n\n$/m;
       
       if($$outref !~ /<align|<dwfckg.*?dwfckg>/gms) {
           $$outref = '<dwfckg></dwfckg>' . $$outref;
       }
      
     
      if($self->{'in_table'}) { 
         $$outref =~ s/\+\+END_TABLE\+\+[\s\n]*$/<br \/>/;
         $$outref =~ s/\++END_TABLE\+\+//g;
      }

    }


    sub del_xtra_c_aligns {
    my ($self, $text) = @_;

        my @left = $text=~ /(<align)/gs;
        my @right = $text=~ /(<\/align)/gms;


        if(scalar @right > scalar @left) {
           my $oCount = 0;
           my $cCount = 0;

           $text =~ s/((<align \w+>)|(<\/align>))/$self->fix_aligns($1, \$oCount, \$cCount)/egms;
        }
    }


    sub fix_aligns {
      my ($self, $align, $open, $close) = @_;
      $$close++ if $align =~ /<\/align/;
      $$open++ if  $align =~ /<align \w+>/;

      if ($$close > $$open) {
           $$close--;
          return "" 
      }

      return $align;
    }

    sub _clean_url {
      my($self,$url, $markup, $spaces) = @_;
      return "{{$url" if $url=~/editor\/images\/smiley\/msn/; 

      if($markup =~/\{\{/) {   ## an external image, the first pair of brackets have been removed by regex
         return $markup . $spaces . $url;
      }

      my $italics="";
      if($markup =~ /\//) {
        $italics='//';
      }

      $url =~ s/^[^h]+//ms;
      $url =~ s/['"\/*_]{2,}$//ms;

      return $italics .'[[' . $url  . ']]' . $italics;
    }

    sub _format_list {
      my($self,$type, $item, $rest_of_sel) = @_;  
        my $text = "${type} ${item}${rest_of_sel}";
        return $text if($text =~ /-&gt;/);
        my $prefix = "";   # any matter which precedes list

        my $p = 0;
        pos($text) = 0;
        while($text =~ /(.*?)(?<!\-\-\-)(?=\s+[\*\-]\s+.*?$EOL)/gms) {
                $prefix .= $1;
                $p = pos($text);
        }
          pos($text) = $p;
          $text =~ /(.*?)$EOL/gms;
          $item = $self->trim($1) if $1; 
          if($item eq '-' || $item eq '*') { 
                  $item = "";      #remove empty list items,they overlap previous line
          }
          $item =~ s/<align\s*\w*>\s*<\/align>\s*$//gm;
          return "$prefix\n  $item";

    }

    sub fix_code {
      my ($self, $text) = @_;
      $text =~ s/<indent.*?>($nudge_char)*<\/indent>//gms;
      # $text =~ s/$code_NL/\n/gms;
      $text =~ s/[\x{b7}\x{a0}]//gms if $self->{'do_nudge'} ;
      return $text;
    }


    sub trim {
     my($self,$text) = @_;
      $text =~ s/^\s+//;
      $text =~ s/\s+$//;
       return $text;
    }

    sub log {
       my($self, $where, $data) = @_;
        my $fh = $self->{'_fh'};
        $where = "" if ! $where;
        $data = "" if ! $data;    
        if( $fh  ) {
            print $fh "$where:  $data\n";
        }
    }


    sub DESTROY {
     my $self=shift;
     my $fh = $self->{_fh};

     if( $fh ) {
        print $fh "\n-----------\n\n";
        close($fh);
     }

    }


    sub _get_basic_attributes {
        my($self, $node) = @_;

        my $fg = '';
        my $bg = '';
           my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
           if(%color_atts) {  
            $fg = (exists $color_atts{'color'}) ? ($color_atts{'color'}) : "";
            $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";
          }

 
          my $face = ''; 
          my $size = ''; 
          my %font_atts = $self->_get_type($node, ['size', 'face'], 'font'); 
          if(%font_atts) {
            $face = (exists $font_atts{'face'}) ? ($font_atts{'face'}) : '';  
            $size = (exists $font_atts{'size'}) ? ($font_atts{'size'}) : "";
          }
          return { 'face'=>$face, 'size'=>$size,'color'=>$fg, 'background'=>$bg };
    }

    sub _header {
        my($self, $node, $rules ) = @_;

        my $text = $self->_as_text($node);

        $node->tag =~ /(\d)/;

        my $pre_and_post_fix = "=" x (7 - $1);

        my $str =  "\n" . "$NL_marker\n$pre_and_post_fix" . $text . "$pre_and_post_fix\n\n<align left></align>";
        return $str;
    }

    sub _as_text {
        my($self, $node) = @_;
        my $text =  join '', map { $self->__get_text($_) } $node->content_list;
        return defined $text ? $text : '';
    }

    sub __get_text {
        my($self, $node) = @_;
        $node->normalize_content();
        if( $node->tag eq '~text' ) {
            return $node->attr('text');
        } elsif( $node->tag eq '~comment' ) {
            return '<!--' . $node->attr('text') . '-->';
        } else {
            my $output = $self->_as_text($node)||'';
            return $output;
        }
    }



1;




