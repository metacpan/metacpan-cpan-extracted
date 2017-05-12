package HTML::PrettyPrinter;

=head1 NAME

 HTML::PrettyPrinter - generate nice HTML files from HTML syntax trees

=head1 SYNOPSIS

  use HTML::TreeBuilder;
  # generate a HTML syntax tree
  my $tree = new HTML::TreeBuilder;
  $tree->parse_file($file_name);
  # modify the tree if you want

  use HTML::PrettyPrinter;
  my $hpp = new HTML::PrettyPrinter ('linelength' => 130,
                                     'quote_attr' => 1);
  # configure
  $tree->address("0.1.0")->attr(_hpp_indent,0);    # for an individual element
  $hpp->set_force_nl(1,qw(body head));             # for tags
  $hpp->set_force_nl(1,qw(@SECTIONS));             # as above
  $hpp->set_nl_inside(0,'default!');               # for all tags

  # format the source
  my $linearray_ref = $hpp->format($tree);
  print @$linearray_ref;

  # alternative: print directly to filehandle
  use FileHandle;
  my $fh = new FileHandel ">$filenaem2";
  if (defined $fh) {
    $hpp->select($fh);
    $hpp->format();
    undef $fh;
    $hpp->select(undef),  
  }

=head1 DESCRIPTION

HTML::PrettyPrinter produces nicely formatted HTML code from
a HTML syntax tree. It is especially usefull if the produced HTML file
shall be read or edited manually afterwards. Various parameters let you
adapt the output to different styles and requirements.

If you don't care how the HTML source looks like as long as it is valid
and readable by browsers, you should use the F<as_HTML()> method of 
HTML::Element instead of the pretty printer. It is about five times faster.

The pretty printer will handle line wrapping, indention and structuring
by the way the whitespace in the tree is represented in the output. 
Furthermore upper/lowercase markup and markup minimization, quoting of 
attribute values, the encoding of entities and the presence of optional 
end tags are configurable.

There are two types of parameters to influence the output, individual
parameters that are set on a per element and per tag basis and common
parameters that are set only once for each instance of a pretty printer.

In order to faciliate the configuration a mechanism to handle tag groups
is provided. Thus, it is possible to modify a parameter for a group of tags 
(e.g. all known block elements) without writing each tag name explicitly. 
Perhaps the code for tag groups will move to an other Perl module in the 
future.

For HTML::Elements that require a special treatment like
<PRE>, <XMP>, <SCRIPT>, comments and declarations, pretty printer will
fall back to the method C<as_HTML()> of the HTML elements. 

=cut

#'

use strict;
use vars qw($VERSION  @EXPORT_OK @ISA %taggroups %noformattags %specialtags);

$VERSION = 0.03;

use Carp;
use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(HPP list_groups group_expand sub_groups group_set group_get 
	       group_add group_remove);

use HTML::Entities;
use HTML::Element     1.56;
use HTML::Tagset;

require 5.004;

use constant ALWAYS     => -1;
use constant NEVER      => 0;
use constant DEPENDS    => 1;
use constant AFTER_ATTR => 1;

# PREFIX for configuration attribs in HTML Elements 
use constant HPP        => '_hpp_'; 

# tags where HTML::Element::as_HTML() is used
%noformattags = map {$_ => 1} qw(pre xmp plaintext listing script style);

# ==========================================================================
#    PARAMETER ACCESS
# ==========================================================================

=head1 INDIVIDUAL PARAMETERS

Following individual paramters exist

=over 4

=item indent I<n>

The indent of new lines inside the element is increased by I<n>
coloumns. Default is 2 for all tags.

=item skip I<bool>

If I<true>, the element and its content is skipped from output.
Default is I<false>.

=item nl_before I<n>

Number of newlines before the start tag. Default is 0 for inline elements
and 1 for other elements.

=item nl_inside I<n>

Number of newlines between the tags and the contents of an element. 
Default is 0.

=item nl_after I<n>

Number of newlines after an element. Default is 0 for inline elements
and 1 for other elements.

=item force_nl I<bool>

Force linebreaks before and after an element even if the HTML tree does 
not contain whitespace at this place. Default is I<false> for inline
elements and true for all other elements. This parameter is superseded
if the common parameter I<allow_forced_nl> is set to I<false>.

=item endtag I<bool>

Print an optional endtag. Default is I<true>.

=back

=head2 Access Methods

Following access methods exist for each individual paramenter. 
Replace I<parameter> by the respective name.

=over 4

=item $hpp->I<parameter>($element)

Takes a reference to an HTML element as argument. Returns the value of the 
parameter for that element. The priority to retrieve the value is:

=over 4

=item 1.

The value of the element's internal attribute C<_hpp_I<parameter>>.

=item 2.

The value specified inside the pretty printer for the tag of the element.

=item 3.

The value specified inside the pretty printer for C<'default!'>.

=back

=item $hpp->I<parameter>('tag')

Like C<I<parameter>($element)>, except that only priorities 2 and 3 are 
evaluated.

=item $hpp->set_I<parameter>($value,'tag1','tag2',...)

Sets the parameter for each tag in the list to I<$value>.

If I<$value> is undefined, the entries for the tags are deleted. 

Beside individual tags the list may include tag groups like 'C<@BLOCK>' (see 
below) and 'C<default!>'. Individual tag names are written in lower case,
the names of tag groups start with an '@' and are written in upper case 
letters. Tag groups are expanded during the call of C<set_I<parameter>()>.
'C<default!>' sets the default value, which is retrived if no value is 
defined for the individual element or tag. 

=item $hpp->set_I<parameter>($value,'all!')

Deletes all existing settings for I<parameter> inside the pretty printer and 
sets the default to I<$value>..

=back

=cut

#' List of individual parmeters. The access functions are generated afterwards

my @individual_parameters = qw(indent skip nl_before nl_inside nl_after 
			       force_nl endtag);

# define generic access function to individual paramters
use constant DEFINE_INDIVIDUAL_PARAMETER => << 'EOF';

sub XXX {
  my ($self, $tag_or_elem) = @_;
  my $val;

  if (ref $tag_or_elem && $tag_or_elem->isa('HTML::Element')) {
    # it is an element
    $val = $tag_or_elem->attr(HPP.'XXX');
    return $val if defined $val;      # ready
    $tag_or_elem = $tag_or_elem->tag; # now it is a tag
  }
  
  # retieve a tag specific value
  $val = $self->{'XXX'}->{lc $tag_or_elem};
  # use default value if no tag specific value given
  $val = $self->{'XXX'}->{'default!'} unless defined $val;
  return $val;
}
 
sub set_XXX {
  my ($self, $val, @tags) = @_;
  
  if ($tags[0] eq 'all!') {
    $self->{'XXX'} = { 'default!' => $val};
  }
  else {
    foreach my $t (group_expand(@tags)) {
      $self->{'XXX'}->{lc $t} = $val;
    }
  }
}

EOF

map {my $src = DEFINE_INDIVIDUAL_PARAMETER; 
     $src =~ s/XXX/$_/g; 
     eval $src} @individual_parameters;

=head1 COMMON PARAMETERS

=over 4

=item tabify I<n>

If non zero, each I<n> spaces at the beginnig of a line are converted 
into one TAB. Default is 8. 

=item linelength I<n>

The maximum number of character a line should have. Default is 80.

The linelength may be exceeded if there is no proper way to break a line
without modifying the content, e.g. inside <PRE> and other special elements
or if there is no whitespace.

=item min_bool_attr I<bool>

Minimize boolean attributes, e.g. print <UL COMPACT> instead of 
<UL COMPACT=COMPACT>. Default is true.

=item quote_attr I<bool>

Always quote attribute values. If false, attribute values consisting
entirely of letters, digits, periods and hyphens only are not put into 
quotes. Default is false.

=item entities I<string>

The string contains all characters that are escaped to their entity names.
Default is the bare minimum of "&<>" plus the non breaking space 'nbsp'
(because otherwise it is difficult for the human eye to distiguish it from 
a normal space in most editors).

=item wrap_at_tagend NEVER|AFTER_ATTR|ALWAYS

May pretty printer wrap lines before the closing ankle of a start tag?
Supported values are the predifined constants NEVER (allow line wraps at 
white space only ), AFTER_ATTR (allow line wraps at the end of tags that 
contain attributes only) and ALWAYS (allow line wraps at the end of every 
start tag). Default is AFTER_ATTR.

=item allow_forced_nl I<bool>

Allow the addition of white space, that is not in the HTML tree.
If set to false (the default) the force_nl parameter is ignored.
It is recomended to set this parameter to true if the HTML tree was
generated with ignore_ignorable_whitespace set to true.

=item uppercase I<bool>

Use uppercase letters for markup. Default is the value of
$HTML::Element::html_uc at the time the constructor is called.

=back

=head2 Access Method

=over 4

=item $hpp->I<paramter>([value])

Retrieves and optionaly sets the parameter.

=back

=cut

my @common_paramters = qw(tabify linelength min_bool_attr quote_attr entities 
			  wrap_at_tagend allow_forced_nl uppercase);

# define access functions for common_paramters
map { 
  eval "sub $_ ".'{
         my ($self, $val) = @_;
	 my $tmp = $self->{'.$_.'};
	 $self->{'.$_.'} = $val if defined $val;
	 return $tmp;
	}'} @common_paramters; 

=head1 OTHER METHODS

=over 4

=item $hpp = HTML::PrettyPrinter->new(%common_paremeters)

This class method creates a new HTML::PrettyPrinter and returns it.
Key/value pair arguments may be provided to overwrite the default settings
of common parameters. There is currently no mechanism to overwrite the
default values for individual parameters at construction. Use the 
C<$hpp->set_I<parameter>()> methods instead.

=item $hpp->select($fh)

Select a FileHandle object for output. 

If a FileHandle is selected the generated HTML is printed directly
to that file. With $hpp->select(undef) you can switch back to the
default behaviour.

=item $line_array_ref = $hpp->format($tree,[$indent],[$line_array_ref])

Format the HTML syntax (sub-) tree. 

C<$tree> is not restricted to the root of the HTML syntax tree. A
reference to any HTML::Element will do.

The optional C<$indent> indents the first element by I<n> characters

Return value is the reference to an array with the generated lines.
If such a reference is provided as third argument, the lines will
be appended to that array. Otherwise a new array will be created.

If a FileHandle is selected by a previous call of the C<$hpp->select($fh)>
method, the lines are printed to the FileHandle object directly.
The array of lines is not changed in this case.

=back

=cut
  
sub new {
  my $class = shift;
  my $self  = bless {@_}, $class;
  # set to default values unless specified by construction call
  $self->tabify(8)           unless defined $self->tabify;
  $self->linelength(80)      unless defined $self->linelength;
  $self->min_bool_attr(1)    unless defined $self->min_bool_attr;
  $self->quote_attr(0)       unless defined $self->quote_attr;
  $self->entities("<>&\240") unless defined $self->entities;
  $self->wrap_at_tagend(AFTER_ATTR) 
    unless defined $self->wrap_at_tagend;
  $self->allow_forced_nl(0)
    unless defined $self->allow_forced_nl;
  $self->uppercase($HTML::Element::html_uc) unless defined $self->uppercase;
  
  # default values for individual parameters
  $self->set_indent(2,'default!');
  $self->set_skip(0,'default!');
  $self->set_nl_inside(0,'default!');
  $self->set_nl_before(1,'default!');
  $self->set_nl_before(0,'@INLINE');
  $self->set_nl_after(1,'default!');
  $self->set_nl_after(0,'@INLINE');
  $self->set_force_nl(1,'default!');
  $self->set_force_nl(0,'@INLINE');
  $self->set_endtag(1,'default!');

  return $self;
}

# select FileHandle object for output
sub select {
  my ($self,$fh) = @_;
  $self->{_fh} = $fh;
}

# ==========================================================================
#   FORMAT
# ==========================================================================

sub format {
  my ($self, $element, $indent, $lar) = @_;
  # $lar = line array ref
  confess "Need an HTML::Element" unless $element->isa('HTML::Element');
  $indent = 0 unless defined $indent;
   
  my ($accu,    # current line 
      $nl,      # line breaks immediately before current position
      $req_nl,  # requested linebreaks at current position
      $pos,     # position in current line
      $wsp,     # whitespace after pos?
      $ai,      # indet at begin of accu
      $bp,      # last breakpoint
      $bpi      # indent at breakpoint
     );  
  
  if (defined $lar) {
    $accu = pop @$lar;
    $pos  = length($accu);
    $ai = 0;			# possible indention string is in accu anyway.
    $nl = ($accu =~ m/^\s*$/)? 1 : 0; # last line empty?
  }
  else {			# $lar not defined
    $lar  = [];
    $accu = '';
    $pos  = 0;    
    $ai  = $indent;
    $nl   = 1000;		# don't add empty lines in front of
  }
  
  #initialize
  $wsp  = 1;
  $bp   = 0;
  
  $self->{_lar} = $lar;
  ($accu, $pos, $nl, $req_nl, $wsp, $ai, $bp, $bpi) = 
    $self->_format($element, $indent, $accu, $pos, $nl, $wsp, $ai, $bp, $bpi);
  $self->_add_line($accu,$ai) if $accu;
  delete $self->{_lar};
  return $lar;
}

sub _tab {
  # return string for indent
  my ($self,$i) = @_;
  my $tab = $self->tabify;
  return $tab ? ("\t" x($i/$tab) . ' ' x($i % $tab)) :  ' ' x $i;
}

#
# add a single line to the output
#
sub _add_line {
  my ($self,$line,$indent) = @_;
  my $fh = $self->{_fh};
  if ($fh) {
    print $fh $self->_tab($indent).$line."\n";
  }
  else {
    push @{$self->{_lar}}, $self->_tab($indent).$line."\n";
  }
}

#
# add a couple of lines to the output
#
sub _add_lines {
  my ($self,@lines) = @_;
  my $fh = $self->{_fh};

  if ($fh) {
    print $fh  map {$_."\n"} @lines;
  }
  else {
    push @{$self->{_lar}},map {$_."\n"} @lines;
  }
}
    
#
# add a string to the accu, handle linewraps, breakpoints etc...
# 
sub _add2accu {
  # return internal parameters
  my ($self,
      $str,    # string to add
      $cin,    # current indent;
      $accu,   # accu
      $pos,    # current position
      $ai,     # indent at start of accu
      $bp,     # breakpoint position
      $bpi,    # indent at breakpoint position
      $wsp     # whitespace at pos?
     ) = @_;
  my $l = length $str;

  # wrap neccessary?
  my $wrap = ($pos + $ai + $wsp + $l >= $self->linelength);
  if ($wrap && $wsp) {
    # wrap before word
    $self->_add_line($accu,$ai);
    $accu = $str;
    $ai = $cin;
    $bp = 0;
    $pos = $l;
  }
  elsif ($wrap && $bp) {
    # wrap at last breakpoint;
    my $last_line = substr($accu,0,$bp,'');
    # bug in Perl?  
    # $self->_add_line(substr($accu,0,$bp,''),$ai) doesn't chop $accu;
    $self->_add_line($last_line,$ai);
    ($accu =~ s/^\s+//) && $pos--;  # remove leading white space
    $accu .= $str;
    $ai = $bpi;
    $pos += $l - $bp;
    $bp = 0;
  }
  else {
    # no wrap
    if ($wsp && $pos) {
      $accu .= ' ';
      $bp = $pos++;
      $bpi = $cin;
    }
    $accu .= $str;
    $pos += $l;
  }
  return ($accu, $ai, $pos, $bp, $bpi);
}

#
# recursive function todo the actual formating of a HTML::Element 
# and it's content.
#
sub _format {
  # do the actual formating
  my ($self, 
      $elem,   # HTML::Element to format
      $indent, # number of spaces for indent inside parent element
      $accu,   # working buffer for current line
      $pos,    # current position in line
      $nl,     # number of newlines at current position
      $wsp,    # whitespace at current position? (boolean)
      $ai,     # indent at accu start
      $bp,     # possition of last possible breakpoint
      $bpi     # indent at last possible breakpoint
     ) = @_;
  #my $pos = length $accu;

  if ($self->skip($elem)) {
    # ignore this element
    return ($accu, $pos, $nl, 0, $wsp, $ai, $bp, $bpi);
  }

  # BEFORE ELEMENT
  my $req_nl = $self->nl_before($elem);  # required newlines
  if ($req_nl && ($wsp || 
		  $self->allow_forced_nl() && $self->force_nl($elem))) {
    # line break legal;
    if (!$nl) {
      $self->_add_line($accu,$ai);
      $accu = '';
      $ai = $indent;
      $nl = 1;
      $pos = 0;
      $wsp = 1;
      $bp = 0;
    }
    # already at a new line
    if ($nl < $req_nl) {
      # more empty lines required
      $self->_add_lines((' ') x ($req_nl - $nl));
      $nl = $req_nl;
    }
  }
  
  # ELEMENT
  my $tag = $elem->tag;
  if ($noformattags{$tag} || $tag =~ m/^~/ ) {
    # use HTML::Element::as_HTML 
    my $sav_uc = $HTML::Element::html_uc; # save data;
    $HTML::Element::html_uc = $self->uppercase;
    my $i_str = $self->_tab($indent); # indent string

    # get the lines 
    my @lines = split('\n',$elem->as_HTML($self->entities, $i_str));
    # append to accu
    my $len_l1 = length($lines[0]) - length($i_str);
    if (!$nl) {
	 # still something in the accu
	 if ($ai + $pos + $len_l1  > $self->linelength) {
	   # linebreak at start required
	   if ($wsp) {
	     #  whitespace at current position
	     unshift @lines, $self->_tab($ai).$accu;
	   }
	   elsif ($bp) {
	     # use last breakpoint
	     my $last_line = substr($accu,0,$bp,'');
	     $self->_add_line($last_line,$ai);
	     $bp = 0;
	     $accu =~ s/^\s//;
	     # replace i_str by accu 
	     substr($lines[0],0,0,$self->_tab($bpi).$accu);
	   }
	   else {
	     # no line break possible => replace i_str by accu 
	     substr($lines[0],0,0,$self->_tab($ai).$accu);
	   }
	 } # if line break required
	 else {
	   substr($lines[0],0,0,$self->_tab($ai).$accu.($wsp?' ':''));
	 }
    }
  
    if ($#lines) {
      # multiple lines => append all but the last to array
      $self->_add_lines(@lines[0..$#lines-1]);
      $bp = 0;
    }
    else {
      # compensate for indent now in accu
      $bp += length $self->_tab($ai) if $bp;
    }
    # prepare accu
    $accu = $lines[-1];
    $pos = length($accu) - length($self->_tab($ai)); #compansate for indent
    $ai = 0;
    $wsp = 0;
    $nl = 0;
    
    # ready
    $HTML::ELement::html_uc = $sav_uc; # restore
  } # if handled by HTML::Element->as_HTML()
  else {
    # let PrettyPrinter do it.
    
    # START TAG
    my $tstr = $self->uppercase? "<\U$tag" : "<$tag";
    
    # add to accu => wrap neccessary?
    ($accu, $ai, $pos, $bp, $bpi) = 
      $self->_add2accu($tstr,$indent,$accu,$pos,$ai,$bp,$bpi,$wsp);
    $nl = 0;
    my $cin = $indent + $self->indent($elem);
    
    # ATTRIBUTES
    my (@attr) = $self->_attributes($elem);
    
    foreach my $a (@attr) {
      ($accu, $ai, $pos, $bp, $bpi) = 
	$self->_add2accu($a,$cin,$accu,$pos,$ai,$bp,$bpi,1);
    }
    
    # close start tag
    $wsp = 0;
    if ( $self->wrap_at_tagend == ALWAYS || 
	 @attr && $self->wrap_at_tagend == AFTER_ATTR) {
      # if breakpoint at end of the start tag
      $bp = $pos;
      $bpi = $cin;
    }
    $accu .= '>';
    $pos++;
    
    $req_nl = $self->nl_inside($elem);

    # CONTENT
    foreach my $c ($elem->content_list()) {
      if (ref $c) {
	# ELEMENT => recursive call
	($accu, $pos, $nl, $req_nl, $wsp, $ai, $bp, $bpi) 
	  = $self->_format($c,$cin,$accu,$pos,$nl,$wsp,$ai,$bp,$bpi);
      }
      else {
	# TEXT
	if ($req_nl && substr($c,0,1) eq ' ') {
	  # starts with white space => can insert requested newlines
	  $self->_add_line($accu,$ai);
	  $self->_add_lines((' ') x ($req_nl -1)) if $req_nl> 1;
	  $accu = '';
	  $ai = $cin;
	  $pos = 0;
	  $bp = 0;
	  $nl = $req_nl;
	}
	encode_entities($c,$self->entities);
	my @words = split(/\s/,$c);
	foreach my $w (@words) {
	  ($accu, $ai, $pos, $bp, $bpi) = 
	    $self->_add2accu($w,$cin,$accu,$pos,$ai,$bp,$bpi,$wsp);
	  $wsp = 1; # add whitespace after word
	} # foreach word
	$nl = 0 if $pos;
	$wsp = (substr($c,-1,1) eq ' '); # whitespace at end of text segment?
      }  # else TEXT
    }   # foreach content

    # NEWLINES BEFORE END TAG
    my $rqnl = $self->nl_inside($elem);
    $req_nl = $rqnl if $rqnl > $req_nl;
    $req_nl -= $nl;

    # END TAG
    $ai = $indent unless $pos; # use indent outside element for end tag
    unless ($HTML::Element::emptyElement{$tag} ||
	    ($HTML::Element::optionalEndTag{$tag} && !$self->endtag($elem))) {
      # if endtag required
      if ($req_nl > 0 && $wsp) {
	# if new lines required before endtag
	$self->_add_line($accu,$ai);
	$accu = '';
	$pos = 0;
	$bp = 0;
	$ai = $indent;
	$self->_add_lines((' ') x ($req_nl-1)) if $req_nl-1;
	$req_nl = 0;
      }

      my $etstr = $self->uppercase? "</\U$tag>" : "</$tag>";
      ($accu, $ai, $pos, $bp, $bpi) = 
	$self->_add2accu($etstr,$indent,$accu,$pos,$ai,$bp,$bpi,$wsp);
      $req_nl = 0;
      $nl = 0;
      $wsp = 0;
    } 
  } # else formating by HTML::PrettyPrinter
  
  # NEWLINES AFTER ELEMENT
  my $rqnl = $self->nl_after($elem);
  $req_nl = $rqnl if $rqnl > $req_nl;
  if ($req_nl && $self->allow_forced_nl() && $self->force_nl($elem)) {
    # force newlines
    $self->_add_line($accu,$ai);
    $self->_add_lines((' ') x ($req_nl -1));
    $accu = '';
    $ai = $indent;
    $pos = 0;
    $bp = 0;
    $nl = $req_nl;
    $req_nl = 0;
  }
  return ($accu, $pos, $nl, $req_nl, $wsp, $ai, $bp, $bpi);
}

#
# format the attributes
#
sub _attributes {
  my ($self, $e) = @_;
  my @result = (); # list of ATTR="value" strings to return

  my @attrs = $e->all_external_attr();  # list (name0, val0, name1, val1, ...)
  while (@attrs) {
    my ($a,$v) = (shift @attrs,shift @attrs);  # get current name, value pair

    # string for output: 1. attribute name
    my $s = $self->uppercase? "\U$a" : $a; 
    
    # value part, skip for boolean attributes if desired
    unless ($a eq lc($v) &&
	    $self->min_bool_attr && 
	    exists($HTML::Tagset::boolean_attr{$e->tag}) &&
	    (ref($HTML::Tagset::boolean_attr{$e->tag}) 
	     ? $HTML::Tagset::boolean_attr{$e->tag}{$a} 
	     : $HTML::Tagset::boolean_attr{$e->tag} eq $a)) {
      my $q = '';
      # quote value?
      if ($self->quote_attr || $v =~ tr/a-zA-Z0-9.-//c) {
	# use single quote if value contains double quotes but no single quotes
	$q = ($v =~ tr/"//  && $v !~ tr/'//) ? "'" : '"'; # catch emacs ");
      }
      # add value part
      $s .= '='.$q.(encode_entities($v,$q.$self->entities)).$q;
    }
    # add string to resulting list
    push @result, $s;
  }

  return @result;  # return list ('attr="val"','attr="val"',...);
}

# ==========================================================================
#   Handling of TAG-GROUPS
# ==========================================================================
#
# Should it be moved to HTML::Known? Or build a module of its own?
#

=head1 TAG GROUPS

Tag groups are lists that contain the names of tags and other tag groups
which are considered as subsets. This reflects the way allowed content 
is specified in HTML DTDs, where e.g. %flow consists of all %block and 
%inline elements and %inline covers several subsets like %phrase.

If you add a tag name to a group A, it will be seen in any group that
contains group A. Thus, it is easy to maintain groups of tags with similar 
properties. (and configure HTML pretty printer for these tags).

The names of tag groups are written in upper case letters with a leading
'@' (e.g. '@BLOCK'). The names of simple tags are written all lower case.

=head2 Functions

All the functions to handle and modify tag groups are included in the
@EXPORT_OK list of C<HTML::PrettyPrinter>.

=over 4

=cut

%taggroups = ('@SECTIONS'   => [qw(head body)],
	      '@BODY'       => [keys %HTML::Tagset::isBodyElement],
	      '@HEAD'       => [keys %HTML::Tagset::isHeadElement],
	      '@HEADORBODY' => [keys %HTML::Tagset::isHeadOrBodyElement],
	      '@SPECIAL'    => [qw(~comment ~pi ~directive ~literal)],
	      '@PRE'        => [qw(pre xmp listing)],
	      '@FRAMES'     => [qw(frame frameset noframes iframe 
				   ilayer nolayer)],
	      '@INLINE'     => [keys %HTML::Tagset::isPhraseMarkup],
	      '@BLOCK'      => [qw(@BLOCK1 @BLOCK2 @TABLEROW @TEXTBLOCK hr)],
	      '@BLOCK1'     => [qw(table @LIST)],
	      '@BLOCK2'     => [qw(div form @LISTITEM td)],
	      '@TEXTBLOCK'  => [qw(@HEADLINE address p)],
	      '@HEADLINE'   => [qw(h1 h2 h3 h4 h5 h6)],
	      '@LIST'       => [keys %HTML::TreeBuilder::isList],
	      '@LISTITEM'   => [qw(li dt dd)],
	      '@TABLEELEM'  => [keys %HTML::Tagset::isTableElement],
	      '@TABLEROW'   => [qw (th tr )],
	      '@FORMELEM'   => [keys %HTML::Tagset::isFormElement],
	      '@TIGHTEN'    => [keys %HTML::Tagset::canTighten]
	     );

=item @tag_groups = list_groups()

Returns a list with the names of all defined tag groups

=cut

sub list_groups {
  return keys %taggroups;
}

=item @tags = group_expand('tag_or_tag_group0',['tag_or_tag_group1',...])

Returns a list of every tag in the tag groups and their subgroups
Each tag is listed once only. The order of the list is not specified.

=cut

sub _expand {
  my @a = @_;
  my (%groups,%tags) = ((),());;
  
  my $t;
  while ($t = shift @a) {
    if ($t =~ m/^\@/) {
      next if $groups{uc $t}++; # expand only once
      carp("no tag group '$t'") unless $taggroups{uc $t};
      push @a, @{$taggroups{uc $t}} if $taggroups{uc $t}
    }
    else {
      $tags{$t}++;
    }
  }
  return [\%tags,\%groups];
}

sub group_expand {
  return keys %{_expand(@_)->[0]};
}

=item @tag_groups = sub_group('tag_group0',['tag_group1',...])

Returns a list of every tag group and sub group in the list.
Each group is listed once only. The order of the list is not specified.

=cut

sub sub_groups {
  return keys %{_expand(@_)->[1]};
}

=item group_get('@NAME')

Return the (unexpanded) contents of a tag group.

=cut

sub group_get {
  my ($group) = @_;
  return @{$taggroups{uc $group}};
}

=item C<group_set('@NAME',['tag_or_tag_group0',...])>

Set a tag group.

=cut

sub group_set {
  my ($group,@a) = @_;
  $taggroups{uc $group} = [@a];
}

=item C<group_add('@NAME','tag_or_tag_group0',['tag_or_tag_group1',...])>

Add tags and tag groups to a group.

=cut

sub group_add {
  my ($group,@a) = @_;
  push @{$taggroups{uc $group}} ,@a;
}

=item C<group_remove('@NAME','tag_or_tag_group0',['tag_or_tag_group1',...])>

Remove tags or tag groups from a group. Subgroups are B<not> expanded.
Thus, C<group_remove('@A','@B')> will remove '@B' from '@A' if it is
included directly. Tags included in '@B' will not be removed from '@A'.
Nor will '@A' be changed if '@B' is included in a aubgroup of '@A' but
not in '@A' directly. 

=cut

sub group_remove {
   my ($group,@a) = @_;
   my %rm = map {$_ => 1} @a;
   $taggroups{uc $group} = [grep {!$rm{$_}} @{$taggroups{uc $group}}];
}

1;

__END__

=back

=head2 Predefined Tag Groups

There are a couple of predefined tag groups. Use
C<  foreach my $tg (list_groups()) {
    print "'$tg' =E<gt> qw(".join(',',group_get($tg)).")\n";
  }
>
to get a list.

=head2 Examples for tag groups

=over 4

=item 1. create some groups

C<
  group_set('@A',qw(a1 a2 a3));
  group_set('@B',qw(b1 b2));
  group_set('@C',qw(@A @B c1 @D));  
  # @D needs to be defined when @C is expannded
  group_set('@D',qw(d1 @B));
  group_set('@E',qw(e1 @D));
  group_set('@F',qw(f1 @A));
>

=item 2. add tags

C<
  group_add('@A',qw(a4 a5)); # @A contains (a1 a2 a3 a4 a5)
  group_add('@D',qw(d1));    # @D contains (d1 @B d1)
  group_add('@F',group_exapand('@B'),'@F');
  # @F contains (f1 @A b1 b2 f1 @F)
>

=item 3. evaluate

C<
  group_exapand('@E');    # returns e1, d1, b1, b2 
  sub_groups('@E');       # returns @B, @D
  sub_groups(qw(@E @F));  # returns @A, @B, @D
  group_get('@F'));       # returns f1, @A, b1, b2, f1, @F
>

=item 4. remove tags

C<
  group_remove('@E','@C');  # @E not changed, because it doesn't contain @C
  group_remove('@E','@D');  # @D removed from @E
  group_remove('@D','d1');  # all d1's are removed. Now @D contains @B only
  group_remove('@C','@B');  # @C now contains (@a c1 @D), Thus
  sub_groups('@C');         # still returns @A, @B, @D, 
                            # because @B is included in @D, too
>

=item 5. application

C<
  # set the indent for tags b1, b2, e1, g1 to 0
  $hpp-E<gt>set_indent(0,qw(@D @E g1)); 
>

If the groups @D or @E are modified afterwards, the configuration of the
pretty printer is B<not> affected, because C<set_indent()> will expand the 
tag groups.

=back

=head1 EXAMPLE

Consider the following HTML tree

    <html> @0
      <head> @0.0
    	<title> @0.0.0
    	  "Demonstrate HTML::PrettyPrinter"
      <body> @0.1
    	<h1> @0.1.0
    	  "Headline"
    	<p align="JUSTIFY"> @0.1.1
    	  "Some text in "
    	  <b> @0.1.1.1
    	    "bold"
    	  " and "
    	  <i> @0.1.1.3
    	    "italics"
    	  " and with 'ä' & 'ü'."
    	<table align="LEFT" border=0> @0.1.2
    	  <tr> @0.1.2.0
    	    <td align="RIGHT"> @0.1.2.0.0
    	      "top right"
    	  <tr> @0.1.2.1
    	    <td align="LEFT"> @0.1.2.1.0
    	      "bottom left"
    	<hr noshade="NOSHADE" size=5> @0.1.3
    	<address> @0.1.4
    	  <a href="mailto:schotten@gmx.de"> @0.1.4.0
    	    "Claus Schotten"

and C<
  $hpp = HTML::PrettyPrinter->new('uppercase' => 1);
  print @{$hpp->format($tree)};
>

will print

  <HTML><HEAD><TITLE>Demonstrate
  	HTML::PrettyPrinter</TITLE></HEAD><BODY><H1>Headline</H1><P
  	ALIGN=JUSTIFY>Some text in <B>bold</B> and
  	<I>italics</I> and with 'ä' &amp; 'ü'.</P><TABLE
  	ALIGN=LEFT BORDER=0><TR><TD ALIGN=RIGHT>top
  	    right</TD></TR><TR><TD ALIGN=LEFT>bottom
  	    left</TD></TR></TABLE><HR NOSHADE SIZE=5
  	><ADDRESS><A HREF="mailto:schotten@gmx.de"
  	  >Claus&nbsp;Schotten</A></ADDRESS></BODY></HTML>

That doesn't look very nice. What went wrong? By default HTML::PrettyPrinter 
takes a conservative approach on whitespace. It will enlarge existing 
whitespace, but it will not introduce new whitespace outside of tags, because
that might change the way a browser renders the HTML document. However
the HTML tree was constructed with C<>ignore_ignorable_whitespace> turned on.
Thus, there is no whitespace between block elements that the pretty printer 
could format. So pretty printer does line wrapping and indention only.
E.g. the title is in the third level of the tree. Thus, the second line is
indented six characters. The table cells in the fifth level are indented by
ten characters. Furthermore, you see that there is a whitespace inserted
after the last attribute of the <A> tag.

Let's set $hpp->allow_forced_nl(1);. Now the I<forced_nl> parameters
are enabled. By default, they are set for all non-inline tags. That creates

 <HTML>
   <HEAD>
     <TITLE>Demonstrate HTML::PrettyPrinter</TITLE>
   </HEAD>
   <BODY>
     <H1>Headline</H1>
     <P ALIGN=JUSTIFY>Some text in <B>bold</B> and
       <I>italics</I> and with 'ä' &amp; 'ü'.</P>
     <TABLE ALIGN=LEFT BORDER=0>
       <TR>
 	 <TD ALIGN=RIGHT>top right</TD>
       </TR>
       <TR>
 	 <TD ALIGN=LEFT>bottom left</TD>
       </TR>
     </TABLE>
     <HR NOSHADE SIZE=5>
     <ADDRESS><A HREF="mailto:schotten@gmx.de"
 	 >Claus&nbsp;Schotten</A></ADDRESS>
   </BODY>
 </HTML>
  
Much better, isn't it? Now let's improve the structuring.
  $hpp->set_nl_before(2,qw(body table));
  $hpp->set_nl_after(2,qw(table));
will require two new lines in front of <body> and <table> tags and after
<table> tags.

 <HTML>
   <HEAD>
     <TITLE>Demonstrate HTML::PrettyPrinter</TITLE>
   </HEAD>
  
   <BODY>
     <H1>Headline</H1>
     <P ALIGN=JUSTIFY>Some text in <B>bold</B> and
       <I>italics</I> and with 'ä' &amp; 'ü'.</P>
  
     <TABLE ALIGN=LEFT BORDER=0>
       <TR>
 	 <TD ALIGN=RIGHT>top right</TD>
       </TR>
       <TR>
 	 <TD ALIGN=LEFT>bottom left</TD>
       </TR>
     </TABLE>
  
     <HR NOSHADE SIZE=5>
     <ADDRESS><A HREF="mailto:schotten@gmx.de"
 	 >Claus&nbsp;Schotten</A></ADDRESS>
   </BODY>
 </HTML>

Currently the mail address is the only attribute value which is quoted.
Here the quotes are required by the '@' character. For all other attribute
values quotes are optional and thus ommited by default. $hpp->quote_attr(1);
will turn the quotes on.

$hpp->set_endtag(0,'all!') turns all optional endtags off. 
This affects the </p> (and should affect </tr> and </td>, see below).
Alternatively, we could use $hpp->set_endtag(0,'default!'). That would 
turn the default off, too. But it wouldn't delete settings for
individual tags that supersede the default.

$hpp->set_nl_after(3,'head') requires three new lines after the <head>
element. Because there are already two new lines required by the start
of <body> only one additional line is added.

$hpp->set_force_nl(0,'td') will inhibit the introduction of whitespace 
alround <td>. Thus, the table cells are now on the same line as the table 
rows.


  <HTML>
    <HEAD>
      <TITLE>Demonstrate HTML::PrettyPrinter</TITLE>
    </HEAD> 
    
    
    <BODY>
      <H1>Headline</H1>
      <P ALIGN="JUSTIFY">Some text in <B>bold</B> and
  	<I>italics</I> and with 'ä' &amp; 'ü'.
   
      <TABLE ALIGN="LEFT" BORDER="0">
  	<TR><TD ALIGN="RIGHT">top right</TD></TR>
  	<TR><TD ALIGN="LEFT">bottom left</TD></TR>
      </TABLE>
   
      <HR NOSHADE SIZE="5">
      <ADDRESS><A HREF="mailto:schotten@gmx.de"
  	  >Claus&nbsp;Schotten</A></ADDRESS>
    </BODY>
  </HTML>

The end tags </td> and </tr> are printed because HTML:Tagset says they are
mandatory. 
  map {$HTML::Tagset::optionalEndTag{$_}=1} qw(td tr th);
will fix that.

The additional new line after </head> doesn't look nice. With
$hpp->set_nl_after(undef,'head') we will reset the parameter for the <head>
tag.

$hpp->entities($hpp->entities().'ä'); will enforce the entity encoding of 'ä'.

$hpp->min_bool_attr(0); will inhibt the minimizyation of the NOSHADE 
attribute to <hr>.

Let's fiddle with the indention:
  $hpp->set_indent(8,'@TEXTBLOCK'); 
  $hpp->set_indent(0,'html'); 

New lines inside text blocks (here inside <h1>, <p> and <address>) will 
be indented by 8 characters instead of two, whereas the code 
directly under <html> will not be indented.

 <HTML>
 <HEAD>
   <TITLE>Demonstrate HTML::PrettyPrinter</TITLE>
 </HEAD>
  
 <BODY>
   <H1>Headline</H1>
   <P ALIGN="JUSTIFY">Some text in <B>bold</B> and
 	   <I>italics</I> and with '&auml;' &amp; 'ü'.
  
   <TABLE ALIGN="LEFT" BORDER="0">
     <TR><TD ALIGN="RIGHT">top right
     <TR><TD ALIGN="LEFT">bottom left
   </TABLE>
  
   <HR NOSHADE="NOSHADE" SIZE="5">
   <ADDRESS><A HREF="mailto:schotten@gmx.de"
 	     >Claus&nbsp;Schotten</A></ADDRESS>
 </BODY>
 </HTML>


$hpp->wrap_at_tagend(HTML::PrettyPrinter::NEVER); will disable the line
wrap between the attribute and the '>' of the <a> tag. The resulting line
excedes the target line length by far, but the is no point left, where
the pretty printer could legaly break this line.

$hpp->set_endtag(1,'tr') will overwrite the default. Thus, the </tr>
appears in the code whereas the other optional endtags are still omitted.

Finally, we customize some individual elements:

=over 4

=item C<$tree->address('0.1.1')->attr('_hpp_skip',1)>

will skip the <p> and its content from the output

=item C<$tree->address('0.1.2.1.0')->attr('_hpp_force_nl',1)>

will force new lines arround the second <td>, but will not affect the first.
<td>.

=back

 <HTML>
 <HEAD>
   <TITLE>Demonstrate HTML::PrettyPrinter</TITLE>
 </HEAD>
 
 <BODY>
   <H1>Headline</H1>
  
   <TABLE ALIGN="LEFT" BORDER="0">
     <TR><TD ALIGN="RIGHT">top right</TR>
     <TR>
       <TD ALIGN="LEFT">bottom left
     </TR>
   </TABLE>
  
   <HR NOSHADE="NOSHADE" SIZE="5">
   <ADDRESS><A
 	     HREF="mailto:schotten@gmx.de">Claus&nbsp;Schotten</A></ADDRESS>
 </BODY>
 </HTML>

=head1 KNOWN BUGS

=over 4

=item *

This is early alpha code. The interfaces are subject to changes.

=item *

The module is tested with perl 5.005_03 only. It should work with
perl 5.004 though.

=item *

The predefined tag groups are incomplete. Several tags need to be added.

=item *

Attribute values from a fixed set given in the DTD (e.g. ALIGN=LEFT|RIGHT
etc.) should be converted to upper or lower case depending on the value of 
the uppercase parameter. Currently, they are printed as given in the HTML tree.

=item *

No optimization for performance was done.

=back

=head1 SEE ALSO

L<HTML::TreeBuilder>, L<HTML::Element>, L<HTML::Tagset>

=head1 COPYRIGHT

Copyright 2000 Claus Schotten  schotten@gmx.de

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Claus Schotten <schotten@gmx.de>

=cut
