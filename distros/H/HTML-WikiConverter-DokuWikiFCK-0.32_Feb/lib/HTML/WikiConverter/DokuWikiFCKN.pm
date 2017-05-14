package HTML::WikiConverter::DokuWikiFCKN;

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
#

use strict;

use base 'HTML::WikiConverter::DokuWiki';
use HTML::Element;
use  HTML::Entities;
use Params::Validate ':types';


our $VERSION = '0.28';

  my $SPACEBAR_NUDGING = 1;
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


 sub attributes {
  return {
          browser => { default => 'IE5', type => SCALAR },
         group => { default => 'ANY', type => SCALAR },
      };
 }
 

my $kbd_start   = '<font _dummy_/AmerType Md BT,American Typewriter,courier New>';
my $kbd_end = '</font>';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{'strike_out'} = 0;   # this prevents deletions from being paragraphed
  $self->{'list_type'} = "";
  $self->{'list_output'} = 0;   # tells postprocess_output to clean up lists, if 1
  $self->{'in_table'} = 0;
  $self->{'colspan'} = "";
  $self->{'code'} = 0;
  $self->{'do_nudge'} = $SPACEBAR_NUDGING;
  if(!$self->{'do_nudge'}) {
        $nudge_char = ' ';
  }
  $self->{'err'} = "NOERR\n";
  $self->{'_fh'} = 0;  # turn off debugging
  return $self;
}




sub getFH {
  my($self) =  @_;
  local *FH; 
  if(open(FH, ">> /var/tmp/fckw.log")) {
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
  $rules->{ 'code' } =  { replace => \&_code_types }; 
  $rules->{ 'kbd' } =   { start => $kbd_start, end => $kbd_end }; 
  $rules->{ 'tt' } =    { alias => 'kbd' }; 
  $rules->{ 'samp' } =  { start => '<font _dummy_/courier New>', end => '</font>' }; 
  $rules->{ 'q' }   =   { start => '"', end => '"' };  
  $rules->{ 'li' }   =  { replace => \&_li_start };
  $rules->{ 'ul' } =  { line_format => 'multi', block => 1, line_prefix => '  ',
                            end => "\n<align left></align>\n" },
  $rules->{ 'ol' } = {  alias => 'ul' };  
  $rules->{ 'hr' } = { replace => "$NL_marker\n----${NL_marker}\n" };
  $rules->{ 'indent' } = { replace => \&_indent  };
  $rules->{ 'header' } = { preserve => 1  };
  $rules->{ 'td' } = { replace => \&_td_start };
  $rules->{ 'th' } = { alias => 'td' };
  $rules->{ 'tr' } = { start => "$NL_marker\n", line_format => 'single', end => \&_row_end };
  for( 1..5 ) {
    $rules->{"h$_"} = { replace => \&_header };
  }
  $rules->{'plugin'} = { replace => \&_plugin};
  $rules->{ 'table' } = { start =>"<align left></align>", end => "<align left></align>" };
 
  $rules->{'ins'} = { alias => 'u'};
  $rules->{'b'} = { replace => \&_formats };
  $rules->{'i'} = { replace => \&_formats };
  $rules->{'u'} = { replace => \&_formats };
  return $rules;
 
}


sub _formats {
    my($self, $node, $rules ) = @_;

    my $text = $self->get_elem_contents($node);

    $text = $self->trim($text);
    return "" if ! $text; 
    return "" if $text !~ /[\p{IsDigit}\p{IsAlpha}\p{IsXDigit}]/;

    $text =~ s/^$_format_regex{$node->tag}//;
    $text =~ s/$_format_regex{$node->tag}$//;

    return $_formats{$node->tag} . $text . $_formats{$node->tag}; 
     
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
          my $td_w;  my $td_bg; my $back_color = "";  my $td_width = "";
          foreach my $s (@styles) {
             if($s =~ /background-color/) {
                    $td_bg = $s;
             }
             elsif($s =~ /width/) {
                $td_w = $s;
             }
          }
          $back_color = $self->_extract_style_value($td_bg, 'background-color') if $td_bg;

          $td_width = $self->_extract_style_value($td_w, 'width') if $td_w;

           if($back_color || $td_width) {
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

   
    my $atts =$self->_get_basic_attributes($node);
    
    if($atts->{'background'}) {
       $text=~ s/(<indent style=['"]color:.*?['"]>)*(\s{3,})(?=.*?(<\/indent>)*)/$self->_td_indent($1,$2, $atts->{'background'})/ge;
   }
    else {
       $text = $self->fix_td_color($atts,$text);   
       if(!$atts->{'background'}) {
            if($text =~/<color\s+(.*?)\/(.*?)>/) {
                 if($2) {
                    $atts->{'background'} = $2;
                 }
                 elsif($1) {
                    $atts->{'background'} = $1;
                 }
            }
       }
       if($atts->{'background'}) {  
            $text=~ s/(<indent style=['"]color:.*?['"]>)*(\s{3,})(?=.*?(<\/indent>)*)/$self->_td_indent($1,$2, $atts->{'background'})/ge;
       }
      }


   my $suffix = $self->_td_end($node,$rules);

   if($self->{'colspan'}) {
       $self->{'colspan'} = chop $suffix;  # save suffix marker for _row_end
 
   }
   
   $text =~ s/\n/ /gm;
   $td_backcolor = $align  if !$td_backcolor;


   return $prefix . $td_backcolor . $text . $suffix;
   
}


sub _td_indent {
 my ($self, $indent, $text, $color) = @_;

 my $indent_tag = ""; 
 my $close_tag = "";

 if($color) {
   $indent_tag = '<indent style="color:' . $color . ';" background-color:' . $color . ';">';
   $close_tag = '</indent>' if(!$indent);
 }
 
 
 return $indent_tag . $text . $close_tag;
}

sub fix_td_color {
   my($self,$atts,$text) = @_;


   my @colors = ();

   if($text =~ /<color.*?<color/ms) {

       while($text =~/<color(.*?)>/gms) {          
             my $color_str = $1;             
             $color_str =~ s/, /,/g;     
             my @elems = split '/', $color_str;        
             push @colors, {fg=>$elems[0],bg=>$elems[1]};  
       }

       my $fg = ""; my $bg = "";
       my $dummy_fg = ""; my $dummy_bg = ""; 
       my $dummy_set = 0; 
       foreach my $color_h(@colors) {
           if($color_h->{'fg'} ne $color_h->{'bg'}) {
               if ($color_h->{'fg'} =~ /_dummy_/ ||  $color_h->{'bg'} =~ /_dummy_/) {
                     if(!$dummy_set) { 
                         $dummy_fg = $color_h->{'fg'}; 
                         $dummy_bg = $color_h->{'bg'};
                     }
                 }
                   else {
                      $fg = $color_h->{'fg'}; 
                      $bg = $color_h->{'bg'};       
                      last; 
                   }
               }
       
           
       }

       if(!$fg) {
           $fg = $dummy_fg ? $dummy_fg : '_dummy_';   
       }
       if(!$bg) {
           $bg = $dummy_bg ? $dummy_bg : '_dummy_';   
       }     
       
       $text=~ s/<color.*?>/ /gms; 
       $text=~ s/<\/color>/ /gms;

       $atts->{'background'} = $bg;
  
       return "<color $fg/$bg>$text</color>";

   }

  return $text;
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
       $text =~ s/<color\s+[r#].*?\/[r#].*?>\s+<\/color>//g;   # remove empty color/font tags
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

sub _code_types {
    my($self, $node, $rules ) = @_;
    my $text = $self->get_elem_contents($node) || "";

    $text = $self->trim($text);
    $text =~ s/[\\]{2}/\n/g;   # required for IE which places <br> at end of each line
    $text =~ s/\n/$NL_marker\n/gms;
    $text =~ s/<.*?>/ /gs;

   
    $text =~ s/(?<![\w[:punct:]:])[\s](?![\w[:punct:]:])/x\00/gms;
    return "" if ! $text;  
    $self->{'code'} = 1;

    return "$NL_marker\n<code>$NL_marker\n  $text $NL_marker\n</code>\n"; 

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

sub _li__start {
  my($self, $node, $rules ) = @_;

  my $text = $self->get_elem_contents($node) || "";
  if($text !~ /<indent/) {
     $text =~ s/([\s\x{a0}]{2,})/"  <indent style='color:white'>" . $self->_space_convert($1)  . "<\/indent>"/msge;  
  }
  else {
    $text =~ s/(\x{b7}|$nudge_char)([\s\x{a0}]+)/$1 . $self->_space_convert($2)/gme;
  }
 
  my $type = $self->SUPER::_li_start($node, $rules);
  $self->{'list_output'} = 1;  # signal postprocess_output to clean up lists
  return  "$NL_marker$type" . $text . $EOL;
 
}

sub _p_alignment {
  my($self, $node, $rules ) = @_;

  my $output = $self->get_elem_contents($node) || "";

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
    }
  }


  my $newline = "";
  if($self->{'do_nudge'}  &&  $output =~ /^\s{3,}/) {   
       $newline = "<align 1px></align>";
  }
  if($self->{'do_nudge'}) {
      $output =~ s/(?=<color\s+rgb.*?\/(rgb.*?)>)(.*?)(?=\<)/$self->_spaces_to_strikeout($2,$1)/gmse;    

      $output =~ s/(\x{b7}|$nudge_char)([\s\x{a0}]+)/$1 . $self->_space_convert($2)/gme;
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
      if($src !~ /:/) {
         $src = ":$src";
      }
  }


      if($align eq 'center') { 
         return "\n<align center>\n{{$src}}\n</align>\n";
      }
      if($align eq 'right') {
        return "<align right>\n{{$src}} </align>";
      }
      if($align eq 'left') {
       return "<align left>\n{{$src}}</align>";
      }
      if($align =~ /\d+px/) {
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


   if($src !~ /userfiles\/image/) {
         my @elems = split /=/, $src;
         $src = pop @elems;
         return $self->_dwimage_markup($src,$alignment) if($src !~ /^http:/);
         return $self->_dwimage_markup($src,$alignment);
   }


   if($src =~ s/^(.*?)\/userfiles\/image\///) {
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
        }
     } 
  }

  return ""; 
}

sub _indent {
    my($self, $node, $rules ) = @_;     
    
    my @list = $node->content_list();
    my $color = 'white';

    foreach my $n(@list) {
       if(exists($n->{'color'})) {
           $color = $n->{'color'};
           last;
       }
    }

    my $text = $self->_as_text($node);

    if($color eq 'white') {
        my %color_atts = $self->_get_type($node, ['color','background-color'], 'color');
        if(%color_atts) {      
           my $bg = (exists $color_atts{'background-color'}) ? ($color_atts{'background-color'}) : "";
           $color=$bg, if $bg;         
        }
    }

    return "<indent style=\"color:$color; background-color:$color\">$text</indent>";
}

sub format_InternalLink {
  my($self, $node, $file) = @_; 

    my $inner_text = $self->get_elem_contents($node) || "";        
   
    if($inner_text) {
       return "$file|$inner_text";
    }
    return $file;
}

sub _link {
    my($self, $node, $rules ) = @_;   
    my $url = $node->attr('href') || '';
    my $internal_link = "";
    
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
    if($text =~ /([\*\/_\"])\1/) {
        $emphasis = "$1$1";
    }

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
        my $pat =~ s/(\W)/\\$1/g;
        $output =~ s/$pat//g;
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

  

  my  $color_regex = qr/
    (rgb\(.*?\))|(\w+)
   /x;

  if($text =~ s/(?<=\<indent)(\s+style=\"color:)($color_regex)(?=.*?>)/$1$bg/gms) {
          $text =~ s/(?<=background-color:)$color_regex/$bg/g;  
  }
  else {
    $text =~ s/([\s\x{a0}]{2,})/$self->_spaces_to_strikeout($2,$bg)/ge;

  }

   my $block = "<block $width:$margin:${bg};$fg;$border;$font>";
     $text =~ s/^\s+//;          # trim  
     $text =~ s/\s+$//;
     $text =~ s/\n{2,}/\n/g;     # multi
   return $block . $text . '</block>';

}

  sub _spaces_to_strikeout {
     my($self, $text, $color) = @_;
     my $style="";
     if($color) {
        $style = "  style=\"color: $color\"";  
     }
     return if ! $self->{'do_nudge'};
                 
     $text =~ s/([\s\x{a0}]{2,})/"  <indent${style}>" . $self->_space_convert($1)  . "<\/indent>  "/ge;
     return $text; 
  }

  sub _space_convert {
     my( $self, $spaces) = @_;

     my $len = do { use bytes; length($spaces) };
     return if !$len;

     my $count = $spaces =~ s/[\s\x{a0}]/$nudge_char/gm;   
     $spaces =~ s/[\s\x{a0}]//g;   

     return $spaces;
  }

  sub _other_convert {
     my( $self, $spaces ) = @_;

     my $count = $spaces =~ s/.{3}/$nudge_char/gms;   

     return $spaces;
  }


   sub  postprocess_output {
           my($self, $outref ) = @_;  
            $$outref =~ s/^[\s\xa0]+//;          # trim  
            $$outref =~ s/[\s\xa0]+$//;
            $$outref =~ s/\n{2,}/\n/g;     # multi
	    
           $$outref =~ s/(?<=<\/align>)\s+(?=<align>)//gms; #### ???? ####
           $$outref =~ s/\s+$//gms;
           $$outref=~s/http\:(?!\/\/)/http:\/\//gsm; # replace missing forward slashes
           $$outref=~s/__(\/\/[\[\{])/$1/gsm;        # remove underlining markup
           $$outref=~s/([\}\]]\/\/)__/$1/gsm;        #   ditto

   
           $$outref =~ s/\^<align 0px><\/align>//g;           # remove aligns at top of file
           $$outref =~ s/[\s\n]*<align>[\s\n]*<\/align>[\s\n]*//gsm;      # remove empty aligns
                                                                  

          if($self->{'do_nudge'}) {  

              $$outref =~ s/(<indent.*?>)(.*?)(?=\<\/indent>)/ $1 . $self->_other_convert($2)/msge;           
              $$outref =~ s/(?!(${NL_marker}|${nudge_char}|\x{b7}))([\s\x{a0}]{3,})(?!${nudge_char}|[\x{b7}])/"  <indent style='color:white'>" . $self->_space_convert($2)  . "<\/indent> "/msge;                       
              $$outref =~ s/~{3,}(?!&gt;)/\n<align left><\/align>/;
              $$outref =~ s/\|(.*?)<\/indent>\n(?=.*\|)/\|$1<\/indent>/mgs;
          }



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


           if($self->{'list_output'}) {
             $$outref =~ s/(?<![\*\-])([\*\-])(?:\s)(.*?)($EOL[\s\n]*)/$self->_format_list($1,$2, $3)/gmse; 
           }

          $$outref =~ s/(?!\n)<align left>/\n<align left>/gms;


          $$outref =~ s/<font _dummy_\/courier New>\s*<\/font>//gms;

       $$outref =~ s/([\/\{]{2})*(\s*)(?<!\[\[)\s*(http:\/\/[_\p{IsDigit}\p{IsAlpha}\p{IsXDigit};&?:.='"\/]{7,})(?!\|)/$self->_clean_url($3,$1, $2)/egms;   
 
          if($self->{'do_nudge'}) {  
               $$outref =~ s/<indent style=[\'\"]color:white[\'\"]><\/indent>//gms;  # remove blank indents                          
               $$outref =~ s/<indent style=['\"]color:white[\'\"]>(${nudge_char}){1,2}<\/indent>//msg;

               $$outref =~s/(<indent style=[\'\"]color:rgb\(\d+,\s*\d+,\s*\d+\)\;?[\'\"]>)[\s\n]*<\/indent>[\s\n]*<indent\s+style=\"color:white\">(${nudge_char}|[\x{b7}\x{a0}]+<\/indent>)/$1\n$2/gms;
               $$outref =~s/(${nudge_char}|[\x{b7}\x{a0}])+<indent style=['\"]color:white[\'\"]>(${nudge_char}|[\n\s\x{b7}\x{a0}])*<\/indent>/$1$2/gms;

               $$outref =~s/<indent style=['"]color:rgb\(.*?\)['"]><\/indent>//gms;
          }


          $$outref =~s/$EOL//g;

          $$outref =~ s/<code><\/code>//gms;
   	      $$outref =~ s/<code>[\W]+<\/code>//gms;
       
           $$outref =~ s/<align \w+>[\n\s]*(<align \w+>.*?<\/align>[\n\s]*)<\/align>/$1/gms;

           $self->del_xtra_c_aligns($$outref);

            $$outref =~ s/<\/align>\s*<br \/>/<\/align>/gms;
            $$outref =~ s/\n+/\n/gms;


            if($self->{'in_table'}) {    # insure tables start with newline
               
                $$outref =~ s/align>\s*(\||\^)/align>\n$1/gms; 
            }


           $$outref =~ s/(?<=\<\/align>)(\s*[\\]{2}\s*)+//gms;
           $$outref =~ s/(?<=\<\/align>)\s*<br \/>\s*//gms;

           


           if($self->{'code'}) {                 
	            $$outref =~ s/x\00/ /gms;
                $$outref =~ s/(?<=<code>)(.*?)(?=<\/code>)/$self->fix_code($1)/gmse;
                $$outref =~ s/<\/code>/<\/code><br \/>/gm;
           }

         $$outref =~ s/<\/block>/<\/block><align left><\/align>/gm;         
         $$outref .= "\n" unless $$outref =~ /\n\n$/m;
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
  
  return $url if $url=~/editor\/images\/smiley\/msn/; 

  if($markup =~/\{\{/) {   ## an external image, the first pair of brackets have been removed by regex
       
     return $markup . $spaces . $url;
  }

  my $italics="";
  if($markup =~ /\//) {
    $italics='//';;
  }

  $url =~ s/^[^h]+//ms;
  $url =~ s/['"\/*_]{2,}$//ms;

  return $italics .'[[' . $url  . ']]' . $italics;
}

sub _format_list {
  my($self,$type, $item, $rest_of_sel) = @_;  
    my $text = "${type}${item}${rest_of_sel}";
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
     $item =~ s/<indent\s+style=['"]color:white["']>($nudge_char)+<\/indent>\s*$//;
     $item =~ s/<align\s*\w*>\s*<\/align>\s*$//gm;
      return "$prefix\n  $item";

}

sub fix_code {
  my ($self, $text) = @_;
  $text =~s/^([\n\s])+$//m;
  $text =~s/([\n\s])+$//g;
  $text =~ s/<indent.*?>($nudge_char)*<\/indent>//gms;

  $text =~ s/[\x{b7}\x{a0}]//gms;
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
    my $fh = $self->{_fh};
    $where = "" if ! $where;
    $data = "" if ! $data;    
    if( $fh  ) {
        print $fh "$where:  $data\n";
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




