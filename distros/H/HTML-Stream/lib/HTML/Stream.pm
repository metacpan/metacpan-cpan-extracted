package HTML::Stream;

=head1 NAME

HTML::Stream - HTML output stream class, and some markup utilities


=head1 SYNOPSIS

Here's small sample of some of the non-OO ways you can use this module:

      use HTML::Stream qw(:funcs);
      
      print html_tag('A', HREF=>$link);     
      print html_escape("<<Hello & welcome!>>");      

And some of the OO ways as well:

      use HTML::Stream;
      $HTML = new HTML::Stream \*STDOUT;
      
      # The vanilla interface...
      $HTML->tag('A', HREF=>"$href");
      $HTML->tag('IMG', SRC=>"logo.gif", ALT=>"LOGO");
      $HTML->text($copyright);
      $HTML->tag('_A');
      
      # The chocolate interface...
      $HTML -> A(HREF=>"$href");
      $HTML -> IMG(SRC=>"logo.gif", ALT=>"LOGO");
      $HTML -> t($caption);
      $HTML -> _A;
       
      # The chocolate interface, with whipped cream...
      $HTML -> A(HREF=>"$href")
            -> IMG(SRC=>"logo.gif", ALT=>"LOGO")
            -> t($caption)
            -> _A;

      # The strawberry interface...
      output $HTML [A, HREF=>"$href"], 
                   [IMG, SRC=>"logo.gif", ALT=>"LOGO"],
                   $caption,
                   [_A];


=head1 DESCRIPTION

The B<HTML::Stream> module provides you with an object-oriented
(and subclassable) way of outputting HTML.  Basically, you open up 
an "HTML stream" on an existing filehandle, and then do all of your  
output to the HTML stream.  You can intermix HTML-stream-output and 
ordinary-print-output, if you like.

There's even a small built-in subclass, B<HTML::Stream::Latin1>, which can
handle Latin-1 input right out of the box.   But all in good time...


=head1 INTRODUCTION (the Neapolitan dessert special)

=head2 Function interface

Let's start out with the simple stuff.
This module provides a collection of non-OO utility functions
for escaping HTML text and producing HTML tags, like this:

    use HTML::Stream qw(:funcs);        # imports functions from @EXPORT_OK
    
    print html_tag(A, HREF=>$url);
    print '&copy; 1996 by', html_escape($myname), '!';
    print html_tag('/A');

By the way: that last line could be rewritten as:

    print html_tag(_A);

And if you need to get a parameter in your tag that doesn't have an
associated value, supply the I<undefined> value (I<not> the empty string!):

    print html_tag(TD, NOWRAP=>undef, ALIGN=>'LEFT');
    
         <TD NOWRAP ALIGN=LEFT>
    
    print html_tag(IMG, SRC=>'logo.gif', ALT=>'');
    
         <IMG SRC="logo.gif" ALT="">

There are also some routines for reversing the process, like:

    $text = "This <i>isn't</i> &quot;fun&quot;...";    
    print html_unmarkup($text);
       
         This isn't &quot;fun&quot;...
      
    print html_unescape($text);
       
         This isn't "fun"...

I<Yeah, yeah, yeah>, I hear you cry.  I<We've seen this stuff before.>
But wait!  There's more...


=head2 OO interface, vanilla

Using the function interface can be tedious... so we also
provide an B<"HTML output stream"> class.  Messages to an instance of
that class generally tell that stream to output some HTML.  Here's the
above example, rewritten using HTML streams:

    use HTML::Stream;
    $HTML = new HTML::Stream \*STDOUT;
    
    $HTML->tag(A, HREF=>$url);
    $HTML->ent('copy');
    $HTML->text(" 1996 by $myname!");
    $HTML->tag(_A);

As you've probably guessed:

    text()   Outputs some text, which will be HTML-escaped.
    
    tag()    Outputs an ordinary tag, like <A>, possibly with parameters.
             The parameters will all be HTML-escaped automatically.
     
    ent()    Outputs an HTML entity, like the &copy; or &lt; .
             You mostly don't need to use it; you can often just put the 
             Latin-1 representation of the character in the text().

You might prefer to use C<t()> and C<e()> instead of C<text()> 
and C<ent()>: they're absolutely identical, and easier to type:

    $HTML -> tag(A, HREF=>$url);
    $HTML -> e('copy');
    $HTML -> t(" 1996 by $myname!");
    $HTML -> tag(_A);

Now, it wouldn't be nice to give you those C<text()> and C<ent()> shortcuts
without giving you one for C<tag()>, would it?  Of course not...


=head2 OO interface, chocolate

The known HTML tags are even given their own B<tag-methods,> compiled on 
demand.  The above code could be written even more compactly as:

    $HTML -> A(HREF=>$url);
    $HTML -> e('copy');
    $HTML -> t(" 1996 by $myname!");
    $HTML -> _A;

As you've probably guessed:

    A(HREF=>$url)   ==   tag(A, HREF=>$url)   ==   <A HREF="/the/url">
    _A              ==   tag(_A)              ==   </A>

All of the autoloaded "tag-methods" use the tagname in I<all-uppercase>.
A C<"_"> prefix on any tag-method means that an end-tag is desired.
The C<"_"> was chosen for several reasons: 
(1) it's short and easy to type,
(2) it doesn't produce much visual clutter to look at,
(3) C<_TAG> looks a little like C</TAG> because of the straight line.

=over 4 

=item *

I<I know, I know... it looks like a private method.
You get used to it.  Really.>

=back

I should stress that this module will only auto-create tag methods
for B<known> HTML tags.  So you're protected from typos like this
(which will cause a fatal exception at run-time):

    $HTML -> IMGG(SRC=>$src);

(You're not yet protected from illegal tag parameters, but it's a start, 
ain't it?)

If you need to make a tag known (sorry, but this is currently a 
I<global> operation, and not stream-specific), do this:

    accept_tag HTML::Stream 'MARQUEE';       # for you MSIE fans...

B<Note: there is no corresponding "reject_tag".>  I thought and thought
about it, and could not convince myself that such a method would 
do anything more useful than cause other people's modules to suddenly
stop working because some bozo function decided to reject the C<FONT> tag.


=head2 OO interface, with whipped cream

In the grand tradition of C++, output method chaining is supported
in both the Vanilla Interface and the Chocolate Interface.  
So you can (and probably should) write the above code as:

    $HTML -> A(HREF=>$url) 
          -> e('copy') -> t(" 1996 by $myname!") 
          -> _A;

I<But wait!  Neapolitan ice cream has one more flavor...>


=head2 OO interface, strawberry

I was jealous of the compact syntax of HTML::AsSubs, but I didn't
want to worry about clogging the namespace with a lot of functions
like p(), a(), etc. (especially when markup-functions like tr() conflict
with existing Perl functions).  So I came up with this:

    output $HTML [A, HREF=>$url], "Here's my $caption", [_A];

Conceptually, arrayrefs are sent to C<html_tag()>, and strings to 
C<html_escape()>.


=head1 ADVANCED TOPICS

=head2 Auto-formatting and inserting newlines

I<Auto-formatting> is the name I give to the Chocolate Interface feature
whereby newlines (and maybe, in the future, other things)
are inserted before or after the tags you output in order to make 
your HTML more readable.  So, by default, this:

    $HTML -> HTML 
          -> HEAD  
          -> TITLE -> t("Hello!") -> _TITLE 
          -> _HEAD
          -> BODY(BGCOLOR=>'#808080');

Actually produces this:

    <HTML><HTML>
    <HEAD>
    <TITLE>Hello!</TITLE>
    </HEAD>
    <BODY BGCOLOR="#808080">

B<To turn off autoformatting altogether> on a given HTML::Stream object,
use the C<auto_format()> method:

    $HTML->auto_format(0);        # stop autoformatting!

B<To change whether a newline is automatically output> before/after the 
begin/end form of a tag at a B<global> level, use C<set_tag()>:

    HTML::Stream->set_tag('B', Newlines=>15);   # 15 means "\n<B>\n \n</B>\n"
    HTML::Stream->set_tag('I', Newlines=>7);    # 7 means  "\n<I>\n \n</I>  "

B<To change whether a newline is automatically output> before/after the 
begin/end form of a tag B<for a given stream> level, give the stream
its own private "tag info" table, and then use C<set_tag()>:

    $HTML->private_tags;
    $HTML->set_tag('B', Newlines=>0);     # won't affect anyone else!

B<To output newlines explicitly>, just use the special C<nl> method
in the Chocolate Interface:

    $HTML->nl;     # one newline
    $HTML->nl(6);  # six newlines

I am sometimes asked, "why don't you put more newlines in automatically?"
Well, mostly because...

=over 4

=item *

Sometimes you'll be outputting stuff inside a C<PRE> environment.

=item *

Sometimes you really do want to jam things (like images, or table
cell delimiters and the things they contain) right up against each other.

=back

So I've stuck to outputting newlines in places where it's most likely
to be harmless. 


=head2 Entities

As shown above, You can use the C<ent()> (or C<e()>) method to output 
an entity:

    $HTML->t('Copyright ')->e('copy')->t(' 1996 by Me!');

But this can be a pain, particularly for generating output with
non-ASCII characters:

    $HTML -> t('Copyright ') 
          -> e('copy') 
          -> t(' 1996 by Fran') -> e('ccedil') -> t('ois, Inc.!');

Granted, Europeans can always type the 8-bit characters directly in
their Perl code, and just have this:

    $HTML -> t("Copyright \251 1996 by Fran\347ois, Inc.!');

But folks without 8-bit text editors can find this kind of output
cumbersome to generate.  Sooooooooo...


=head2 Auto-escaping: changing the way text is escaped

I<Auto-escaping> is the name I give to the act of taking an "unsafe"
string (one with ">", "&", etc.), and magically outputting "safe" HTML.

The default "auto-escape" behavior of an HTML stream can be a drag if
you've got a lot character entities that you want to output, or if 
you're using the Latin-1 character set, or some other input encoding.  
Fortunately, you can use the C<auto_escape()> method to change the 
way a particular HTML::Stream works at any time.

First, here's a couple of special invocations:

    $HTML->auto_escape('ALL');      # Default; escapes [<>"&] and 8-bit chars.
    $HTML->auto_escape('LATIN_1');  # Like ALL, but uses Latin-1 entities
                                    #   instead of decimal equivalents.
    $HTML->auto_escape('NON_ENT');  # Like ALL, but leaves "&" alone.

You can also install your own auto-escape function (note
that you might very well want to install it for just a little bit
only, and then de-install it):

    sub my_auto_escape {
        my $text = shift;
	HTML::Entities::encode($text);     # start with default
        $text =~ s/\(c\)/&copy;/ig;        # (C) becomes copyright
        $text =~ s/\\,(c)/\&$1cedil;/ig;   # \,c becomes a cedilla
 	$text;
    }
    
    # Start using my auto-escape:
    my $old_esc = $HTML->auto_escape(\&my_auto_escape);  
    
    # Output some stuff:
    $HTML-> IMG(SRC=>'logo.gif', ALT=>'Fran\,cois, Inc');
    output $HTML 'Copyright (C) 1996 by Fran\,cois, Inc.!';
    
    # Stop using my auto-escape:
    $HTML->auto_escape($old_esc);

If you find yourself in a situation where you're doing this a lot,
a better way is to create a B<subclass> of HTML::Stream which installs
your custom function when constructed.  For an example, see the 
B<HTML::Stream::Latin1> subclass in this module.


=head2 Outputting HTML to things besides filehandles

As of Revision 1.21, you no longer need to supply C<new()> with a 
filehandle: I<any object that responds to a print() method will do>.
Of course, this includes B<blessed> FileHandles, and IO::Handles.

If you supply a GLOB reference (like C<\*STDOUT>) or a string (like
C<"Module::FH">), HTML::Stream will automatically create an invisible
object for talking to that filehandle (I don't dare bless it into a
FileHandle, since the underlying descriptor would get closed when 
the HTML::Stream is destroyed, and you might not want that).

You say you want to print to a string?  For kicks and giggles, try this:

    package StringHandle;
    sub new {
	my $self = '';
	bless \$self, shift;
    }
    sub print {
        my $self = shift;
        $$self .= join('', @_);
    }
    
  
    package main;
    use HTML::Stream;
    
    my $SH = new StringHandle;
    my $HTML = new HTML::Stream $SH;
    $HTML -> H1 -> t("Hello & <<welcome>>!") -> _H1;
    print "PRINTED STRING: ", $$SH, "\n";


=head2 Subclassing

This is where you can make your application-specific HTML-generating code
I<much> easier to look at.  Consider this:

    package MY::HTML;
    @ISA = qw(HTML::Stream);
     
    sub Aside {
	$_[0] -> FONT(SIZE=>-1) -> I;
    }
    sub _Aside {
	$_[0] -> _I -> _FONT;
    }

Now, you can do this:

    my $HTML = new MY::HTML \*STDOUT;
    
    $HTML -> Aside
          -> t("Don't drink the milk, it's spoiled... pass it on...")
          -> _Aside;

If you're defining these markup-like, chocolate-interface-style functions,
I recommend using mixed case with a leading capital.  You probably 
shouldn't use all-uppercase, since that's what this module uses for
real HTML tags.


=head1 PUBLIC INTERFACE

=cut

use Carp;
use Exporter;
use strict;
use vars qw(@ISA %EXPORT_TAGS $AUTOLOAD $DASH_TO_SLASH $VERSION %Tags);

# Exporting...
@ISA = qw(Exporter);
%EXPORT_TAGS = (
      'funcs' => [qw(html_escape html_unescape html_unmarkup html_tag)]
);
Exporter::export_ok_tags('funcs');

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.60$, 10;



#------------------------------
#
# GLOBALS
#
#------------------------------

# Allow dashes to become slashes?
$DASH_TO_SLASH = 1;

# HTML escape sequences.  This bit was stolen from html_escape() in CGI::Base.
my %Escape = (
    '&'    => 'amp', 
    '>'    => 'gt', 
    '<'    => 'lt', 
    '"'    => 'quot',
);
my %Unescape;
{my ($k, $v); $Unescape{$v} = $k while (($k, $v) = each %Escape);}

# Flags for streams:
my $F_NEWLINE = 0x01;      # is autonewlining allowed?



#------------------------------
#
# PRIVATE UTILITIES
#
#------------------------------

#------------------------------
# escape_all TEXT
#
# Given a TEXT string, turn the text into valid HTML by interpolating the 
# appropriate escape sequences for all troublesome characters
# (angles, double-quotes, ampersands, and 8-bit characters).
#
# Uses the decimal-value syntax for 8-bit characters).

sub escape_all {
    my $text = shift;
    $text =~ s/([<>"&])/\&$Escape{$1};/mg; 
    $text =~ s/([\x80-\xFF])/'&#'.unpack('C',$1).';'/eg;
    $text;
}

#------------------------------
# escape_latin_1 TEXT
#
# Given a TEXT string, turn the text into valid HTML by interpolating the 
# appropriate escape sequences for all troublesome characters
# (angles, double-quotes, ampersands, and 8-bit characters).
#
# Uses the Latin-1 entities for 8-bit characters.

sub escape_latin_1 {
    my $text = shift;
    HTML::Entities::encode($text);  # can't use $_[0]! encode is destructive!
    $text;
}

#------------------------------
# escape_non_ent TEXT
#
# Given a TEXT string, turn the text into valid HTML by interpolating the 
# appropriate escape sequences for angles, double-quotes, and 8-bit
# characters only (i.e., ampersands are left alone).

sub escape_non_ent {
    my $text = shift;
    $text =~ s/([<>"])/\&$Escape{$1};/mg; 
    $text =~ s/([\x80-\xFF])/'&#'.unpack('C',$1).';'/eg;
    $text;
}

#------------------------------
# escape_none TEXT
#
# No-op, provided for very simple compatibility.  Just returns TEXT.

sub escape_none {
    $_[0];
}

#------------------------------
# build_tag ESCAPEFUNC, \@TAGINFO
#
# I<Internal use only!>  Build an HTML tag using the given ESCAPEFUNC.
# As an efficiency hack, only the values are HTML-escaped currently:
# it is assumed that the tag and parameters will already be safe.

sub build_tag {
    my $esc = shift;       # escape function
    my $taginfo = shift;   # tag info

    # Start off, converting "_x" to "/x":
    my $tag = shift @$taginfo;
    $tag =~ s|^_|/|;
    my $s = '<' . $tag;

    # Add parameters, if any:
    while (@$taginfo) {
	my $k = shift @$taginfo;
	my $v = shift @$taginfo;
	$s .= " $k";
	defined($v) and ((($s .= '="') .= &$esc($v)) .= '"');
    }
    $s .= '>';
}


#------------------------------



=head2 Functions

=over 4

=cut

#------------------------------


#------------------------------

=item html_escape TEXT

Given a TEXT string, turn the text into valid HTML by escaping "unsafe" 
characters.  Currently, the "unsafe" characters are 8-bit characters plus:

    <  >  =  &

B<Note:> provided for convenience and backwards-compatibility only.
You may want to use the more-powerful B<HTML::Entities::encode>
function instead.

=cut

sub html_escape {
    my $text = shift;
    $text =~ s/([<>"&])/\&$Escape{$1};/mg; 
    $text =~ s/([\x80-\xFF])/'&#'.unpack('C',$1).';'/eg;
    $text;
}
 
#------------------------------

=item html_tag TAG [, PARAM=>VALUE, ...]

Return the text for a given TAG, possibly with parameters.
As an efficiency hack, only the values are HTML-escaped currently:
it is assumed that the tag and parameters will already be safe.

For convenience and readability, you can say C<_A> instead of C<"/A">
for the first tag, if you're into barewords.

=cut

sub html_tag {
    build_tag(\&html_escape, \@_);    # warning! using ref to @_!
}

#------------------------------

=item html_unescape TEXT

Remove angle-tag markup, and convert the standard ampersand-escapes
(C<lt>, C<gt>, C<amp>, C<quot>, and C<#ddd>) into ASCII characters.

B<Note:> provided for convenience and backwards-compatibility only.
You may want to use the more-powerful B<HTML::Entities::decode>
function instead: unlike this function, it can collapse entities
like C<copy> and C<ccedil> into their Latin-1 byte values.

=cut

sub html_unescape {
    my ($text) = @_;

    # Remove <tag> sequences.  KLUDGE!  I'll code a better way later.
    $text =~ s/\<[^>]+\>//g;
    $text =~ s/\&([a-z]+);/($Unescape{$1}||'')/gie;
    $text =~ s/\&\#(\d+);/pack("C",$1)/gie;
    return $text;
}

#------------------------------

=item html_unmarkup TEXT

Remove angle-tag markup from TEXT, but do not convert ampersand-escapes.  
Cheesy, but theoretically useful if you want to, say, incorporate
externally-provided HTML into a page you're generating, and are worried
that the HTML might contain undesirable markup.

=cut

sub html_unmarkup {
    my ($text) = @_;

    # Remove <tag> sequences.  KLUDGE!  I'll code a better way later.
    $text =~ s/\<[^>]+\>//g;
    return $text;
}



#------------------------------

=back

=head2 Vanilla

=over 4

=cut

#------------------------------

# Special mapping from names to utility functions (more stable than symtable):
my %AutoEscapeSubs = 
    ('ALL'     => \&HTML::Stream::escape_all,
     'LATIN_1' => \&HTML::Stream::escape_latin_1,
     'NON_ENT' => \&HTML::Stream::escape_non_ent,
     );


#------------------------------

=item new [PRINTABLE] 

I<Class method.>
Create a new HTML output stream.

The PRINTABLE may be a FileHandle, a glob reference, or any object
that responds to a C<print()> message.
If no PRINTABLE is given, does a select() and uses that.

=cut

sub new {
    my $class = shift;
    my $out = shift || select;      # defaults to current output stream

    # If it looks like an unblessed filehandle, bless it:
    if (!ref($out) || ref($out) eq 'GLOB') {
	$out = new HTML::Stream::FileHandle $out;
    }

    # Create the object:
    my $self = { 
	OUT   => $out,
	Esc   => \&escape_all,
	Tags  => \%Tags,          # reference to the master table
	Flags => $F_NEWLINE,      # autonewline
    };
    bless $self, $class;
}

#------------------------------
# DESTROY
#
# Destructor.  Does I<not> close the filehandle!

sub DESTROY { 1 }

#------------------------------
# autoescape - DEPRECATED as of 1.31 due to bad name choice
#
sub autoescape {
    my $self = shift;
    warn "HTML::Stream's autoescape() method is deprecated.\n",
         "Please use the identical (and more nicely named) auto_escape().\n";
    $self->auto_escape(@_);
}

#------------------------------

=item auto_escape [NAME|SUBREF]

I<Instance method.>
Set the auto-escape function for this HTML stream.

If the argument is a subroutine reference SUBREF, then that subroutine 
will be used.  Declare such subroutines like this:

    sub my_escape {
	my $text = shift;     # it's passed in the first argument
        ...
        $text;
    }

If a textual NAME is given, then one of the appropriate built-in 
functions is used.  Possible values are:

=over 4

=item ALL

Default for HTML::Stream objects.  This escapes angle brackets, 
ampersands, double-quotes, and 8-bit characters.  8-bit characters 
are escaped using decimal entity codes (like C<#123>).

=item LATIN_1

Like C<"ALL">, but uses Latin-1 entity names (like C<ccedil>) instead of
decimal entity codes to escape characters.  This makes the HTML more readable
but it is currently not advised, as "older" browsers (like Netscape 2.0)
do not recognize many of the ISO-8859-1 entity names (like C<deg>).

B<Warning:> If you specify this option, you'll find that it attempts
to "require" B<HTML::Entities> at run time.  That's because I didn't want 
to I<force> you to have that module just to use the rest of HTML::Stream.
To pick up problems at compile time, you are advised to say:

    use HTML::Stream;
    use HTML::Entities;

in your source code.

=item NON_ENT

Like C<"ALL">, except that ampersands (&) are I<not> escaped.
This allows you to use &-entities in your text strings, while having
everything else safely escaped:

    output $HTML "If A is an acute angle, then A > 90&deg;";

=back

Returns the previously-installed function, in the manner of C<select()>.
No arguments just returns the currently-installed function.

=cut

sub auto_escape {
    my $self = shift;

    # Grab existing value:
    my $oldesc = $self->{Esc}; 

    # If arguments were given, they specify the new value:
    if (@_) { 
	my $newesc = shift;
	if (ref($newesc) ne 'CODE') {  # must be a string: map it to a subref
	    require HTML::Entities if ($newesc eq 'LATIN_1');
	    $newesc = $AutoEscapeSubs{uc($newesc)} or
		croak "never heard of auto-escape option '$newesc'";
	}
	$self->{Esc} = $newesc;
    }

    # Return old value:
    $oldesc;
}

#------------------------------

=item auto_format ONOFF

I<Instance method.>
Set the auto-formatting characteristics for this HTML stream.
Currently, all you can do is supply a single defined boolean
argument, which turns auto-formatting ON (1) or OFF (0). 
The self object is returned.

Please use no other values; they are reserved for future use.

=cut

sub auto_format {
    my ($self, $onoff) = @_;
    ($self->{Flags} &= (~1 << 0)) |= ($onoff << 0);
    $self;
}

#------------------------------

=item comment COMMENT

I<Instance method.>
Output an HTML comment.
As of 1.29, a newline is automatically appended.

=cut

sub comment {
    my $self = shift;
    $self->{OUT}->print('<!-- ', &{$self->{Esc}}(join('',@_)), " -->\n");
    $self;
}

#------------------------------

=item ent ENTITY

I<Instance method.>
Output an HTML entity.  For example, here's how you'd output a 
non-breaking space:

      $html->ent('nbsp');

You may abbreviate this method name as C<e>:

      $html->e('nbsp');

B<Warning:> this function assumes that the entity argument is legal.

=cut

sub ent {
    my ($self, $entity) = @_;
    $self->{OUT}->print("\&$entity;");
    $self;
}
*e = \&ent;


#------------------------------

=item io

Return the underlying output handle for this HTML stream.
All you can depend upon is that it is some kind of object
which responds to a print() message:

    $HTML->io->print("This is not auto-escaped or nuthin!");

=cut

sub io {
    shift->{OUT};
}


#------------------------------

=item nl [COUNT]

I<Instance method.>
Output COUNT newlines.  If undefined, COUNT defaults to 1.

=cut

sub nl {
    my ($self, $count) = @_;
    $self->{OUT}->print("\n" x (defined($count) ? $count : 1));
    $self;
}

#------------------------------

=item tag TAGNAME [, PARAM=>VALUE, ...]

I<Instance method.>
Output a tag.  Returns the self object, to allow method chaining.
You can say C<_A> instead of C<"/A">, if you're into barewords.

=cut

sub tag {
    my $self = shift;
    $self->{OUT}->print(build_tag($self->{Esc}, \@_));
    $self;
}

#------------------------------

=item text TEXT...

I<Instance method.>
Output some text.  You may abbreviate this method name as C<t>:

      $html->t('Hi there, ', $yournamehere, '!');

Returns the self object, to allow method chaining.

=cut

sub text {
    my $self = shift;
    $self->{OUT}->print(&{$self->{Esc}}(join('',@_)));
    $self;
}
*t = \&text;

#------------------------------

=item text_nbsp TEXT...

I<Instance method.>
Output some text, but with all spaces output as non-breaking-space
characters: 

      $html->t("To list your home directory, type: ")
           ->text_nbsp("ls -l ~yourname.")

Returns the self object, to allow method chaining.

=cut

sub text_nbsp {
    my $self = shift;
    my $txt = &{$self->{Esc}}(join('',@_));
    $txt =~ s/ /&nbsp;/g;
    $self->{OUT}->print($txt);
    $self;
}
*nbsp_text = \&text_nbsp;      # deprecated, but supplied for John :-)


#------------------------------

=back

=head2 Strawberry

=over 4

=cut

#------------------------------

#------------------------------

=item output ITEM,...,ITEM

I<Instance method.>
Go through the items.  If an item is an arrayref, treat it like
the array argument to html_tag() and output the result.  If an item
is a text string, escape the text and output the result.  Like this:

     output $HTML [A, HREF=>$url], "Here's my $caption!", [_A];

=cut

sub output {
    my $self = shift;
    my $out = $self->{OUT};
    my $esc = $self->{Esc};
    foreach (@_) {
	if (ref($_) eq 'ARRAY') {    # E.g., $_ is [A, HREF=>$url]
	    $out->print(&build_tag($esc, $_));
	}
	elsif (!ref($_)) {           # E.g., $_ is "Some text"
	    $out->print(&$esc($_));
	}
	else {
	    confess "bad argument to output: $_";
	}
    }
    $self;        # heh... why not...
}


#------------------------------

=back

=head2 Chocolate

=over 4

=cut

#------------------------------

#------------------------------
# %Tags
#------------------------------
# The default known HTML tags.  The value if each is CURRENTLY a set of flags:
#
#     0x01    newline before <TAG>
#     0x02    newline after <TAG>
#     0x04    newline before </TAG>
#     0x08    newline after </TAG>
#
# This can be summarized as:

my $TP     = 1 | 0 | 0 | 0;
my $TBR    = 0 | 2 | 0 | 0;
my $TFONT  = 0 | 0 | 0 | 0;  # fontlike
my $TOUTER = 1 | 0 | 0 | 8;
my $TBOTH  = 0 | 2 | 0 | 8;
my $TLIST  = 0 | 2 | 0 | 8;
my $TELEM  = 0 | 0 | 0 | 8; 
my $TTITLE = 0 | 0 | 0 | 8;
my $TSOLO  = 0 | 2 | 0 | 0;

%Tags = 
    (
     A       => 0,
     ABBR    => 0,
     ACRONYM => 0,
     ADDRESS => $TBOTH,
     APPLET  => $TBOTH,
     AREA    => $TELEM,
     B       => 0,
     BASE    => 0,
    BASEFONT => $TBOTH,
     BDO     => $TBOTH,
     BIG     => 0,
     BGSOUND => $TELEM,
     BLINK   => 0,
  BLOCKQUOTE => $TBOTH,
     BODY    => $TBOTH,
     BUTTON  => $TP,
     BR      => $TBR,
     CAPTION => $TTITLE,
     CENTER  => $TBOTH,
     CITE    => 0,
     CODE    => 0,
     COMMENT => $TBOTH,
    COLGROUP => $TP,
     COL     => $TP,
     DEL     => 0,
     DFN     => 0,
     DD      => $TLIST,
     DIR     => $TLIST,
     DIV     => $TP,
     DL      => $TELEM,
     DT      => $TELEM,
     EM      => 0,
     EMBED   => $TBOTH,
     FONT    => 0,
     FORM    => $TBOTH,
    FIELDSET => $TBOTH,
     FRAME   => $TBOTH,
    FRAMESET => $TBOTH,
     H1      => $TTITLE,
     H2      => $TTITLE,
     H3      => $TTITLE,
     H4      => $TTITLE,
     H5      => $TTITLE,
     H6      => $TTITLE,
     HEAD    => $TBOTH,
     HR      => $TBOTH,
     HTML    => $TBOTH,
     I       => 0,
     IFRAME  => $TBOTH,
     IMG     => 0,
     INPUT   => 0,
     INS     => 0,
     ISINDEX => 0,
     KEYGEN  => $TBOTH,
     KBD     => 0,
     LABEL   => $TP,
     LEGEND  => $TP,
     LI      => $TELEM,
     LINK    => 0,
     LISTING => $TBOTH,
     MAP     => $TBOTH,
     MARQUEE => $TTITLE,
     MENU    => $TLIST,
     META    => $TSOLO,
     NEXTID  => $TBOTH,
     NOBR    => $TFONT,
     NOEMBED => $TBOTH,
     NOFRAME => $TBOTH,
    NOFRAMES => $TBOTH,
    NOSCRIPT => $TBOTH,
     OBJECT  => 0,
     OL      => $TLIST, 
     OPTION  => $TELEM,
    OPTGROUP => $TELEM,
     P       => $TP,
     PARAM   => $TP,
   PLAINTEXT => $TBOTH,
     PRE     => $TOUTER,
     Q       => 0,
     SAMP    => 0,
     SCRIPT  => $TBOTH,
     SELECT  => $TBOTH,
     SERVER  => $TBOTH,
     SMALL   => 0,
     SPAN    => 0,
     STRONG  => 0,
     STRIKE  => 0,
     STYLE   => 0,
     SUB     => 0,
     SUP     => 0,
     TABLE   => $TBOTH,
     TBODY   => $TP,
     TD      => 0,
    TEXTAREA => 0,
     TFOOT   => $TP,
     TH      => 0,
     THEAD   => $TP,
     TITLE   => $TTITLE,
     TR      => $TOUTER,
     TT      => 0,
     U       => 0,
     UL      => $TLIST, 
     VAR     => 0,
     WBR     => 0,
     XMP     => 0,
     );


#------------------------------

=item accept_tag TAG

I<Class method.>
Declares that the tag is to be accepted as valid HTML (if it isn't already).
For example, this...

     # Make sure methods MARQUEE and _MARQUEE are compiled on demand:
     HTML::Stream->accept_tag('MARQUEE'); 

...gives the Chocolate Interface permission to create (via AUTOLOAD)
definitions for the MARQUEE and _MARQUEE methods, so you can then say:

     $HTML -> MARQUEE -> t("Hi!") -> _MARQUEE;

If you want to set the default attribute of the tag as well, you can
do so via the set_tag() method instead; it will effectively do an
accept_tag() as well.

     # Make sure methods MARQUEE and _MARQUEE are compiled on demand,
     #   *and*, set the characteristics of that tag.
     HTML::Stream->set_tag('MARQUEE', Newlines=>9);

=cut

sub accept_tag {
    my ($self, $tag) = @_;
    my $class = (ref($self) ? ref($self) : $self);   # force it, for now
    $class->set_tag($tag);
}


#------------------------------

=item private_tags 

I<Instance method.>
Normally, HTML streams use a reference to a global table of tag
information to determine how to do such things as auto-formatting,
and modifications made to that table by C<set_tag> will
affect everyone.

However, if you want an HTML stream to have a private copy of that
table to munge with, just send it this message after creating it.  
Like this:

    my $HTML = new HTML::Stream \*STDOUT;
    $HTML->private_tags;

Then, you can say stuff like:

    $HTML->set_tag('PRE',   Newlines=>0);
    $HTML->set_tag('BLINK', Newlines=>9);

And it won't affect anyone else's I<auto-formatting> (although they will 
possibly be able to use the BLINK tag method without a fatal
exception C<:-(> ).

Returns the self object.

=cut

sub private_tags {
    my $self = shift;
    my %newtags = %Tags;
    $self->{Tags} = \%newtags;
    $self;
}

#------------------------------

=item set_tag TAG, [TAGINFO...]

I<Class/instance method.>
Accept the given TAG in the Chocolate Interface, and (if TAGINFO
is given) alter its characteristics when being output.

=over 4

=item *

B<If invoked as a class method,> this alters the "master tag table",
and allows a new tag to be supported via an autoloaded method:

     HTML::Stream->set_tag('MARQUEE', Newlines=>9);

Once you do this, I<all> HTML streams you open from then on 
will allow that tag to be output in the chocolate interface.

=item *

B<If invoked as an instance method,> this alters the "tag table" referenced
by that HTML stream, usually for the purpose of affecting things like
the auto-formatting on that HTML stream.  

B<Warning:> by default, an HTML stream just references the "master tag table" 
(this makes C<new()> more efficient), so I<by default, the 
instance method will behave exactly like the class method.>

     my $HTML = new HTML::Stream \*STDOUT;
     $HTML->set_tag('BLINK', Newlines=>0);  # changes it for others!

If you want to diddle with I<one> stream's auto-formatting I<only,> 
you'll need to give that stream its own I<private> tag table.  Like this:

     my $HTML = new HTML::Stream \*STDOUT;
     $HTML->private_tags;
     $HTML->set_tag('BLINK', Newlines=>0);  # doesn't affect other streams

B<Note:> this will still force an default entry for BLINK in the I<master> 
tag table: otherwise, we'd never know that it was legal to AUTOLOAD a 
BLINK method.   However, it will only alter the I<characteristics> of the 
BLINK tag (like auto-formatting) in the I<object's> tag table.

=back

The TAGINFO, if given, is a set of key=>value pairs with the following 
possible keys:

=over 4

=item Newlines

Assumed to be a number which encodes how newlines are to be output 
before/after a tag.   The value is the logical OR (or sum) of a set of flags:

     0x01    newline before <TAG>         .<TAG>.     .</TAG>.    
     0x02    newline after <TAG>          |     |     |      |
     0x04    newline before </TAG>        1     2     4      8
     0x08    newline after </TAG>    

Hence, to output BLINK environments which are preceded/followed by newlines:

     set_tag HTML::Stream 'BLINK', Newlines=>9;

=back

Returns the self object on success.

=cut

sub set_tag {
    my ($self, $tag, %params) = @_;
    $tag = uc($tag);                           # it's GOT to be uppercase!!!

    # Force it to BE in the MASTER tag table, regardless:
    defined($Tags{$tag}) or $Tags{$tag} = 0;       # default value

    # Determine what table we ALTER, and force membership in that table:
    my $tags = (ref($self) ? $self->{Tags} : \%Tags);
    defined($tags->{$tag}) or $tags->{$tag} = 0;   # default value

    # Now, set selected characteristics in that table:
    if (defined($params{Newlines})) {
	$tags->{$tag} = ($params{Newlines} || 0);
    }
    $self;
}

#------------------------------

=item tags 

I<Class/instance method.>
Returns an unsorted list of all tags in the class/instance tag table 
(see C<set_tag> for class/instance method differences).

=cut

sub tags {
    my $self = shift;
    return (keys %{ref($self) ? $self->{Tags} : \%Tags});
}


#------------------------------
# AUTOLOAD
#
# The custom autoloader, for the chocolate interface.
#
# B<WARNING:> I have no idea if the mechanism I use to put the
# functions in this module (HTML::Stream) is perlitically correct.

sub AUTOLOAD {
    my $funcname = $AUTOLOAD;
    $funcname =~ s/.*:://;            # get rid of package name 
    my $tag;
    ($tag = $funcname) =~ s/^_//;     # get rid of leading "_"

    # If it's a tag method that's been approved in the master table...
    if (defined($Tags{$tag})) {

	# A begin-tag, like "IMG"...
	if ($funcname !~ /^_/) {     
	    eval <<EOF;
            sub HTML::Stream::$funcname { 
		my \$self = shift; 
		\$self->{OUT}->print("\n") if (\$self->{Tags}{'$tag'} & 1 and
					       \$self->{Flags} & $F_NEWLINE);
                \$self->{OUT}->print(html_tag('$tag',\@_));
		\$self->{OUT}->print("\n") if (\$self->{Tags}{'$tag'} & 2 and
					       \$self->{Flags} & $F_NEWLINE);
                \$self;
            }
EOF
	}
        # An end-tag, like "_IMG"...
	else { 
	    eval <<EOF;
            sub HTML::Stream::$funcname { 
		my \$self = shift; 
		\$self->{OUT}->print("\n") if (\$self->{Tags}{'$tag'} & 4 and
					       \$self->{Flags} & $F_NEWLINE);
                \$self->{OUT}->print("</$tag>");
		\$self->{OUT}->print("\n") if (\$self->{Tags}{'$tag'} & 8 and
					       \$self->{Flags} & $F_NEWLINE);
                \$self;
            }
EOF
	}
	if ($@) { $@ =~ s/ at .*\n//; croak $@ }   # die!
        my $fn = "HTML::Stream::$funcname";        # KLUDGE: is this right???
        goto &$fn;
    }

    # If it's NOT a tag method...
    else { 
	# probably should call the *real* autoloader in the future...
	croak "Sorry: $AUTOLOAD is neither defined or loadable";
    }
    goto &$AUTOLOAD;
}


=back

=head1 SUBCLASSES

=cut


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# A small, private package for turning FileHandles into safe printables:

package HTML::Stream::FileHandle;

use strict;
no strict 'refs';

sub new {
    my ($class, $raw) = @_;
    bless \$raw, $class;
}
sub print {
    my $self = shift;
    print { $$self } @_;
}


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

=head2 HTML::Stream::Latin1

A small, public package for outputting Latin-1 markup.  Its
default auto-escape function is C<LATIN_1>, which tries to output
the mnemonic entity markup (e.g., C<&ccedil;>) for ISO-8859-1 characters.

So using HTML::Stream::Latin1 like this:

    use HTML::Stream;
    
    $HTML = new HTML::Stream::Latin1 \*STDOUT;
    output $HTML "\253A right angle is 90\260, \277No?\273\n";

Prints this:

    &laquo;A right angle is 90&deg;, &iquest;No?&raquo;

Instead of what HTML::Stream would print, which is this:

    &#171;A right angle is 90&#176;, &#191;No?&#187;

B<Warning:> a lot of Latin-1 HTML markup is not recognized by older 
browsers (e.g., Netscape 2.0).  Consider using HTML::Stream; it will output 
the decimal entities which currently seem to be more "portable".

B<Note:> using this class "requires" that you have HTML::Entities.

=cut

package HTML::Stream::Latin1;

use strict;
use vars qw(@ISA);
@ISA = qw(HTML::Stream);

# Constructor:
sub new {
    my $class = shift;
    my $self = HTML::Stream->new(@_);
    $self->auto_escape('LATIN_1');
    bless $self, $class;
}


__END__

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

=head1 PERFORMANCE

Slower than I'd like.  Both the output() method and the various "tag" 
methods seem to run about 5 times slower than the old 
just-hardcode-the-darn stuff approach.  That is, in general, this:

    ### Approach #1...
    tag  $HTML 'A', HREF=>"$href";
    tag  $HTML 'IMG', SRC=>"logo.gif", ALT=>"LOGO";
    text $HTML $caption;
    tag  $HTML '_A';
    text $HTML $a_lot_of_text;

And this:

    ### Approach #2...
    output $HTML [A, HREF=>"$href"], 
	         [IMG, SRC=>"logo.gif", ALT=>"LOGO"],
		 $caption,
		 [_A];
    output $HTML $a_lot_of_text;

And this:

    ### Approach #3...
    $HTML -> A(HREF=>"$href")
	  -> IMG(SRC=>"logo.gif", ALT=>"LOGO")
	  -> t($caption)
	  -> _A
          -> t($a_lot_of_text);

Each run about 5x slower than this:

    ### Approach #4...
    print '<A HREF="', html_escape($href), '>',
          '<IMG SRC="logo.gif" ALT="LOGO">',
  	  html_escape($caption),
          '</A>';
    print html_escape($a_lot_of_text);

Of course, I'd much rather use any of first three I<(especially #3)> 
if I had to get something done right in a hurry.  Or did you not notice
the typo in approach #4?  C<;-)>

(BTW, thanks to Benchmark:: for allowing me to... er... benchmark stuff.)



=head1 VERSION

$Id: Stream.pm,v 1.60 2008/08/06 dstaal Exp $

=head1 CHANGE LOG

=over 4

=item Version 1.60   (2008/08/06)

Fixed up the tests some more, updated changelog.  (Which I'd forgotten 
about...)

=item Version 1.59   (2008/06/01)

Better tests, better Meta.yml.

=item Version 1.58   (2008/05/28)

Another attempt at cleanup, as well expanding the Meta.yml file.

=item Version 1.57   (2008/05/28)

Cleaned up the Mac-specific files that were getting created in the archive.

=item Version 1.56   (2008/05/27)

Added the start of a testing suite.  In the process, I found an error:
HTML defines the tag 'NOFRAMES', not 'NOFRAME'.  Both are currently in
the tag list, but consider 'NOFRAME' depriciated.

The test suite requires Test::More and Test::Output.

=item Version 1.55   (2003/10/28)

New maintainer: Daniel T. Staal.  No major changes in the code, except
to complete the tag list to HTML 4.01 specifications. (With the
exception of the 'S' tag, which I want to test, and is depreciated
anyway.  Note that the DOCTYPE is not actually a HTML tag, and is not
currently included.)


=item Version 1.54   (2001/08/20)

The terms-of-use have been placed in the distribution file "COPYING".  
Also, small documentation tweaks were made.

=item Version 1.51   (2001/08/16)

No real changes to code; just improved documentation,
and removed HTML::Entities and HTML::Parser from ./etc
at CPAN's request.


=item Version 1.47   (2000/06/10)

No real changes to code; just improved documentation.


=item Version 1.45   (1999/02/09)

Cleanup for Perl 5.005: removed duplicate typeglob assignments.


=item Version 1.44   (1998/01/14)

Win95 install (5.004) now works.
Added SYNOPSIS to POD.


=item Version 1.41   (1998/01/02)

Removed $& for efficiency.
I<Thanks, Andreas!>

Added support for OPTION, and default now puts newlines after SELECT 
and /SELECT.  Also altered "TELEM" syntax to put newline after end-tags 
of list element tags (like /OPTION, /LI, etc.).  In theory, this change
could produce undesireable results for folks who embed lists inside of PRE 
environments... however, that kind of stuff was done in the days before 
TABLEs; also, you can always turn it off if you really need to.
I<Thanks to John D Groenveld for these patches.>

Added text_nbsp().
I<Thanks to John D Groenveld for the patch.>
This method may also be invoked as nbsp_text() as in the original patch, 
but that's sort of a private tip-of-the-hat to the patch author, and the 
synonym may go away in the future.


=item Version 1.37   (1997/02/09)

No real change; just trying to make CPAN.pm happier.


=item Version 1.32   (1997/01/12)

B<NEW TOOL for generating Perl code which uses HTML::Stream!> 
Check your toolkit for B<html2perlstream>.

Added built-in support for escaping 8-bit characters.

Added C<LATIN_1> auto-escape, which uses HTML::Entities to generate
mnemonic entities.  This is now the default method for HTML::Stream::Latin1.

Added C<auto_format(),> 
so you can now turn auto-formatting off/on.

Added C<private_tags()>, 
so it is now possible for HTML streams to each have their own "private"
copy of the %Tags table, for use by C<set_tag()>.

Added C<set_tag()>.  The tags tables may now be modified dynamically so 
as to change how formatting is done on-the-fly.  This will hopefully not
compromise the efficiency of the chocolate interface (until now,
the formatting was compiled into the method itself), and I<will> add
greater flexibility for more-complex programs.

Added POD documentation for all subroutines in the public interface.


=item Version 1.29   (1996/12/10)

Added terminating newline to comment().
I<Thanks to John D Groenveld for the suggestion and the patch.>


=item Version 1.27   (1996/12/10)

Added built-in HTML::Stream::Latin1, which does a very simple encoding
of all characters above ASCII 127.

Fixed bug in accept_tag(), where 'my' variable was shadowing argument.
I<Thanks to John D Groenveld for the bug report and the patch.>


=item Version 1.26   (1996/09/27)

Start of history.

=back

=head1 COPYRIGHT

This program is free software.  You may copy or redistribute it under
the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Warmest thanks to...

    Eryq                   For writing the orginal version of this module.

    John Buckman           For suggesting that I write an "html2perlstream",
                           and inspiring me to look at supporting Latin-1.
    Tony Cebzanov          For suggesting that I write an "html2perlstream"
    John D Groenveld       Bug reports, patches, and suggestions
    B. K. Oxley (binkley)  For suggesting the support of "writing to strings"
                           which became the "printable" interface.

=head1 AUTHOR

Daniel T. Staal (F<DStaal@usa.net>).

Enjoy.  Yell if it breaks.

=cut

#------------------------------
1;

