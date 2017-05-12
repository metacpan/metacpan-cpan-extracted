package HTML::TagUtil;

##HTML::TagUtil

use 5.008001; #Need 5.8.1.
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
tagged
opentagged
closetagged
tagpos
string
comment
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ); #allow all public methods to export.



our $VERSION = '1.43';

##package variable to set whether to allow hyphens in comments.
##Note: this is a *hack* to avoid having to deal with putting it in the 
##invocant's hashref here. (Couldn't figure out how to do it right. :-)
## still looks the same to the user though, if they call the allow_hyphen 
##method.
our $Allow_Hyphen = 0;



#$file will someday be available for checking. 
#my $file;

###########################
#####Class Constructor#####
###########################

sub new {
   my $self = {
   string       => shift,
   tag          => shift,
   };

   $self->{string      } ||= '';
   $self->{tag         } ||= '';
   # $file = shift;
   bless $self, 'HTML::TagUtil';
   return $self;
}   

####################################
##########PRIVATE METHODS###########
####################################

##
## Private method that does the actual matching for tagged.
##

sub _is_fully_tagged {
   my $self = shift;
   my $arg = shift || $_;
   if ($arg =~ /<(([a-zA-Z])+((\s+\w+)=?("?\w+"?)?){0,})( (\/)?)?\s*>.*<\/(([a-zA-Z])+((\s+\w+)=?("?\w+"?)?){0,})( (\/)?)?\s*/) {
      return 1;
   } else {
      return 0;
   }
   $_ = $arg if ($arg);
   $self->{string} = $arg if ($arg);
}   

##
## Private method that matches for opentagged.
## 

sub _is_open_tagged {
   my $self = shift;
   my $arg = shift || $_;
   if ($arg =~ /<(([a-zA-Z])+((\s+\w+)=?("?\w+"?)?){0,})( (\/)?)?\s*>/) {
      return 1;
   } else {
      return 0;
   }
   $_ = $arg if ($arg);
   $self->{string} = $arg if ($arg);
}   

## 
## Private method that matches for closetagged.
##

sub _is_close_tagged {
   my $self = shift;
   my $arg = shift || $_;
   if ($arg =~ /<\/([a-zA-Z])+\s*>/) {
      return 1;
   } else {
      return 0;
   }
   $_ = $arg if ($arg);
   $self->{string} = $arg if ($arg);
}

##
## Private method that matches for empty.
##

sub _is_empty_element {
   my $self = shift;
   my $arg = shift || $_;
   if ($arg =~ /<(([a-zA-Z])+((\s+\w+)=?("?.+"?)?){0,})(\s*\/)\s*>/) {
      return 1;
   } else {
      return 0;
   }
   $_ = $arg if ($arg);
   $self->{string} = $arg if ($arg);
}   

##
## Private method for comment().
##

sub _is_comment {
   my $self = shift;
   my $arg  = shift || $_;
   
   if ($Allow_Hyphen) {
      if ($arg =~ /<!--.*-->/) {
         return 1;
      } else {
         return 0;
      }
   } else {
      if ($arg =~ /<!--[^\-]-->/) {
         return 1;
      } else {
         return 0;
      }
   }
   $_ = $arg if ($arg);
   $self->{string} = $arg if ($arg);
}

####################################
##########PUBLIC METHODS############
####################################

##
## Get/set methods.
## one for getting/setting the string(currenly does not work), and one for
## gettin/setting whether to allow hyphens in comments.
##

sub string {
   my $self   = shift;
   my $string = $self->{string};
   $string    = shift unless ($self->{string});
   return $self->{string} unless ($string);
}   

sub allow_hyphen {
   my $self = shift;
   my $arg  = shift;
   $Allow_Hyphen = $arg;
   return $Allow_Hyphen unless ($arg);
}

sub tagged {
   my $self   = shift;
   my $string = shift || $self->{string} || $_; #string to look at.
   ##check to see if it has both a start tag and an end tag.
   if (_is_fully_tagged ($self->{string})) {
   ##set some variables just in case.
      my $tag       = $1;
      my $element   = $2;
      my $fullattr  = $3;
      my $attrname  = $4;
      my $attrvalue = $5;
      return 1;
   } else {
      return 0;
   }   
   $self->{string} = $string if ($string);
   $_ = $self->{string} if ($self->{string});
}

sub opentagged {
   my $self   = shift;
   my $string = shift || $self->{string} || $_; #string to look at.
   ##check to see if it at least has a start tag.
   if (_is_open_tagged ($string)) {
      ##regexp vars.
      my $tag       = $1;
      my $element   = $2;
      my $fullattr  = $3;
      my $attrname  = $4;
      my $attrvalue = $5;
      return 1;
   } else {
      return 0;
   }
   $self->{string} = $string if ($string);
   $_ = $self->{string} if ($self->{string});
}   

sub closetagged {
   my $self   = shift;
   my $string = shift || $self->{string} || $_; #string to look at.
   ##check to see if it at least has an end tag.
   if (_is_close_tagged ($string)) {
      ##regexp vars.
      my $tag       = $1;
      my $element   = $2;
      my $fullattr  = $3;
      my $attrname  = $4;
      my $attrvalue = $5;
      return 1;
   } else {
      return 0;
   }
   $self->{string} = $string if ($string);
   $_ = $self->{string} if ($self->{string});
} 

sub tagpos {
   my $self = shift;
   my $string = shift || $self->{string} || $_; #string to look at.
   my $tag =    shift || $self->{tag}    || $_; #tag to look for.
   my $offset = shift || 0;                     # offset.
   $tag = '<' . $tag . '>'   if ($tag !~ /(<(([a-zA-Z])+((\s+\w+)=?("?\w+"?)?){0,})( (\/)?)?\s*>|<\/([a-zA-Z])+\s*>)/);
   return index ($string, $tag, $offset) + 1;
   $self->{string} = $string if ($string);
   $self->{tag   } = $tag    if ($tag);
   $_  = $self->{string}     if ($self->{string});
   $_ .= "||$tag"            if ($self->{tag}); 
}

sub empty {
   my $self =   shift;
   my $string = shift || $self->{string} || $_;
   if (_is_empty_element ($string)) {
      return 1;
      my $tag       = $1;
      my $element   = $2;
      my $fullattr  = $3;
      my $attrname  = $4;
      my $attrvalue = $5;
   } else {
      return 0;
   }
   $self->{string} = $string if ($string);
   $_ = $self->{string} if ($self->{string});
}   

sub comment {
   my $self   = shift;
   my $string = shift || $self->{string} || $_;
   if (_is_comment($string)) {
      my $tag       = $1;
      my $element   = $2;
      my $fullattr  = $3;
      my $attrname  = $4;
      my $attrvalue = $5;
      return 1;
   } else {
      return 0;
   }
   $self->{string} = $string if ($string);
   $_ = $self->{string} if ($self->{string});
}



1;

__END__

=head1 NAME

HTML::TagUtil - Perl Utility for HTML tags

=head1 SYNOPSIS

use HTML::TagUtil;
$_ = "<i>Now!</i>";

my $tagger = HTML::TagUtil->new();
print "Tagged!"       if ($tagger->tagged());
print "Open Tagged!"  if ($tagger->opentagged());
print "Close Tagged!" if ($tagger->closetagged());

=head1 DESCRIPTION

HTML::TagUtil is a perl module providing a
Object-Oriented interface to
getting information about HTML/SGML/XML
tags and their attributes and content.

=head1 METHODS

=over 3

=item new

B<new> is the constructor for HTML::TagUtil.
it can be called like this:
my $tagger = new HTML::TagUtil ();
my $tagger = HTML::TagUtil->new();

also, you can supply an optional
argument as the string to use if none is given
to one of the methods. if you do not
supply it here, it defaults to the default variable
($_) here and everywhere else.

=item $tagger->tagged

B<tagged> checks to see if a string has both an end tag and a start tag in it.
if it does, it returns true,
if not, it returns false.
a few examples would be: 

$_ = "<html>html stuff</html>";
print "Tagged" if ($tagger->tagged); #prints "Tagged"
$_ = "<html>html stuff";
print "Tagged" if ($tagger->tagged); #prints nothing.
$_ = "html stuff</html>";
print "Tagged" if ($tagger->tagged); #prints nothing.
$_ = "<html blah="blah_blah">html stuff</html>";
print "Tagged" if ($tagger->tagged); #prints "Tagged"

tagged can handle attributes and empty elements.

=item $tagger->opentagged

B<opentagged> checks to see if a string has one or more start tags in it,
ignoring whether it has an end tag in it or not.
if it does have a start tag, it returns true.
otherwise, it returns false.
some examples are:

$_ = "<html>stuff";
print "Open Tagged" if ($tagger->opentagged); #prints "Open Tagged"
$_ = "<html>stuff</html>";
print "Open Tagged" if ($tagger->opentagged); #prints "Open Tagged"
$_ = "stuff</html>";
print "Open Tagged" if ($tagger->openedtagged); prints nothing
$_ = "<html some="cool" attributes="yes">stuff";
print "Open Tagged" if ($tagger->opentagged); #prints "Open Tagged"

opentagged can handle attributes as well as empty elements.

=item $tagger->closetagged

B<closetagged> checks to see if a string has one or more end tags in it,
ignoring whether it has a start tag or not.
if it does have an end tag, it returns true,
otherwise, it returns false.
some examples are:

$_ = "stuff</html>";
print "Close Tagged" if ($tagger->closetagged); #prints "Closed Tagged" 
$_ = "<html>stuff</html>";
print "Close Tagged" if ($tagger->closetagged); #prints "Closed Tagged"
$_ = "<html>stuff";
print "Closed Tagged" if ($tagger->closetagged); #prints nothing.
$_ = "stuff</html stuff="cool">";
print "Closed Tagged" if ($tagger->closetagged); #prints nothing.

closedtagged can not handle attributes or empty elements.
because end tags can't have attributes or be empty.

=item $tagger->tagpos

B<tagpos> returns the position that a certain tag is at in
a string, 0 meaning that it is not there, and
1 meaning the first position in the string and so on.
It will add the < and the > on to the tag you specify if you do
not.
some examples are:

$_ = "<html>stuff</html>"; 
my $pos = $tagger->tagpos ($_, '<html>', 0);
print $pos; #prints "1"
$_ = "<html>stuff</html>";
my $pos = $tagger->tagpos ($_, 'html', 0);
print $pos; #prints "1" because the < and > get added on to the 'html'.
$_ = "stuff<html>";
my $pos = $tagger->tagpos ($_, '<html>', 0);
print $pos; #prints "6" because counting starts from one for this.
$_ = "stuff<html>";
my $pos = $tagger->tagpos ($_, 'html', 0);
print $pos; #prints "6" again because counting starts from one for this.

tagpos can handle anything that is surrounded by < and >.

=item $tagger->empty

B<empty> checks to see if the specified string contains
an empty element in it. That is, one that ends with " />".
it returns true if it does have one in it, or false otherwise.
some examples would be:

$_ = "<img />";
print "Empty" if ($tagger->empty); #prints "Empty"
$_ = "<img/>";
print "Empty" if ($tagger->empty); #prints "Empty"
$_ = "<img></img>";
print "Empty" if ($tagger->empty); #prints nothing
$_ = "<img src=\"http://www.example.com/cool.gif\" />";
print "Empty" if ($tagger->empty); #prints "Empty"

empty can handle attributes and varying amounts of space before
the end tag.

=item $tagger->comment

B<comment> checks to see if the specified string contains
a comment in it. A comment is any string surrounded by
'<!--' and '-->'. Sometimes, people put more than two hyphens
in the comment. this is not actually allowed according to the SGML/HTML
specification, but is allowable. Allowability of hyphens in comments
is by default set to 0, but you can override this by calling
$tagger->allow_hyphen(1) or setting
$HTML::TagUtil::Allow_Hyphen to 1. (Not recommended.)
Some examples are:

 $_ = "<!--comment here-->";
 print "Comment" if ($tagger->comment); #prints "Comment"
 $_ = "<!---comment-here-->";
 print "Comment" if ($tagger->comment); #prints nothing.
 $HTML::TagUtil::Allow_Hyphen = 1;
 $_ = "<!---comment-here-->";
 print "Comment" if ($tagger->comment); #prints "Comment"
 
comment can handle anything in between '<!--' and '-->',
with the option of allowing hyphens in the comment.

=back

=head1 EXPORT

none. (OO)

=head1 BUGS

none known.

=head1 SEE ALSO

L<HTML::Parser>
L<HTML::Tagset>

HTML::TagUtil's website is L<http://www.x-tac.net/html-util.htm/>

=head1 AUTHOR

<nightcat>, E<lt>nightcat@crocker.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by <nightcat>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
