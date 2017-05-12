
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Syntax.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Syntax ;

use strict ;
use vars qw{@ISA @EXPORT_OK %EXPORT_TAGS %DocumentRoot %Syntax} ;

@ISA = qw{Exporter} ;

use constant  ntypTag           => 1 ;
use constant  ntypStartTag      => 1 + 0x20 ;
use constant  ntypStartEndTag   => 1 + 0x80 ;
use constant  ntypEndTag        => 1 + 0x40 ;
use constant  ntypEndStartTag   => 1 + 0x60 ;
use constant  ntypAttr	        => 2 ;
use constant  ntypAttrValue     => 2 + 0x20 ;
use constant  ntypText	        => 3 ;
use constant  ntypCDATA	        => 4 ;
use constant  ntypEntityRef       => 5 ;
use constant  ntypEntity          => 6 ;
use constant  ntypProcessingInstr => 7 ;
use constant  ntypComment         => 8 ;
use constant  ntypDocument        => 9 ;
use constant  ntypDocumentType    => 10 ;
use constant  ntypDocumentFraq    => 11 ;
use constant  ntypNotation        => 12 ;

use constant  aflgSingleQuote     => 8 ;


@EXPORT_OK = qw{
ntypTag           
ntypStartTag      
ntypStartEndTag      
ntypEndTag        
ntypEndStartTag   
ntypAttr	  
ntypAttrValue     
ntypText	  
ntypCDATA	  
ntypEntityRef     
ntypEntity        
ntypProcessingInstr
ntypComment       
ntypDocument      
ntypDocumentType  
ntypDocumentFraq  
ntypNotation

aflgSingleQuote
} ;



%EXPORT_TAGS = (
    types => \@EXPORT_OK,
    ) ;


###################################################################################
#
#   Methods
#
###################################################################################

# ---------------------------------------------------------------------------------
#
#   Create new Syntax Object
#
# ---------------------------------------------------------------------------------

sub new

    {
    my $class = shift ;

    my $self = $class ;
    if (!ref $class)
        {
        $self = { 
                -root => $class -> CloneHash (\%DocumentRoot) ,
                -procinfotype => 'embperl',
               } ;

        bless $self, $class ;
        }

    return $self ;
    }



# ---------------------------------------------------------------------------------
#
#   Add new elemets to root
#
# ---------------------------------------------------------------------------------


sub AddToRoot

    {
    my ($self, $elements) = @_ ;
    
    my $root = $self -> {-root} ;

    while (my ($k, $v) = each (%$elements))
        {
        $root -> {$k} = $v ;
        } 
    }

# ---------------------------------------------------------------------------------
#
#   Adds code that is execute everytime after the compile of a document
#       start and end of the execution of a document
#
# ---------------------------------------------------------------------------------


sub AddInitCode

    {
    my ($self, $compiletimecode, $initcode, $termcode, $procinfo) = @_ ;
    
    my $root = $self -> {-root} ;
    my $ttref ;
    foreach my $tagtype ('Document', 'DocumentFraq')
        {
        die "'$tagtype' unknown" if (!($ttref = $self -> {-root}{$tagtype})) ;
        my $pinfo = ($ttref -> {'procinfo'}{$self -> {-procinfotype}} ||= {}) ;
        $pinfo -> {'compiletimeperlcode'} .= $compiletimecode if ($compiletimecode) ;
        $pinfo -> {'perlcode'} .= $initcode if ($initcode) ;
        $pinfo -> {'perlcodeend'} .= $termcode if ($termcode) ;
        if ($procinfo)
            {
            while (my ($k, $v) = each (%$procinfo))
                {
                $pinfo -> {$k} = $v ;
                } 
            }
        } 
    }



# ---------------------------------------------------------------------------------
#
#   Get root
#
# ---------------------------------------------------------------------------------


sub GetRoot

    {
    my ($self) = @_ ;
    
    return $self -> {-root} ;
    }


# ---------------------------------------------------------------------------------
#
#   Get/create named syntax
#
# ---------------------------------------------------------------------------------


sub GetSyntax

    {
    my ($name, $oldname) = @_ ;

    my %names ;
    my $op = '' ;
    if ($name =~ /^(\+|\-)\s*(.*?)$/)
        {
        $op   = $1 ;
        $name = $2;
        }
    $name = "$oldname $name" if ($op eq '+') ;

    my @split = split (/\s/, $name) ;
    if ($op eq '-')
        {
        my @mnames = map { /::/?$_:'Embperl::Syntax::'. $_ } @split  ;
        foreach (@mnames)
            {
            $names{$_} = 1 ;
            }
        @split = split (/\s/, $oldname) ;
        }                
    
    my @xnames = map { /::/?$_:'Embperl::Syntax::'. $_ } @split  ;
    my @names ;
    foreach (@xnames)
        {
        push @names, $1 if (!$names{$_} && (/^\s*([a-zA-Z_0-9:]+)\s*$/)) ;
        $names{$_} = 1 ;
        }
            
    $name = join (' ', @names) ;

    print Embperl::LOG "[$$]SYNTAX: switch to $name\n" ; 

    return undef if (!$name) ;
    return $Syntax{$name} if (exists ($Syntax{$name})) ;

    foreach my $n (@names)
        {
        eval "require $n" ;
        if ($@) 
            {
            warn $@ ;
            return undef ;
            }
        }

    my $first = shift @names ;

    my $self = $first -> new ;

    foreach my $n (@names)
        {
no strict ;
        &{"${n}::new"}($self) ;
use strict ;
        }

    $self -> {-name} = $name ;

    BuildTokenTable ($self) ;
    $Syntax{$name} = $self ;
    return $self ;
    }

# ---------------------------------------------------------------------------------
#
#   Deep clone a hash and make replacements
#
# ---------------------------------------------------------------------------------

sub CloneHash
    {
    my ($self, $old, $replace, $seen, $new) = @_ ;


    $new     ||= {} ;
    $replace ||= {} ;    
    $seen    ||= {$old => $new} ;

    my ($v, $k) ;
    

    while (($k, $v) = each (%$old))
        {
        if ($replace -> {$k})
            {
            $new -> {$k} = $replace -> {$k} ;
            }
        else
            {
            if (ref ($v) eq 'HASH')
                {
                if ($seen -> {$v})
                    {
                    $new -> {$k} = $seen -> {$v} ;
                    }
                else
                    {
                    my $sub = {} ;
                    $seen -> {$v} = $sub ;
                    $self -> CloneHash ($v, $replace, $seen, $sub) ;
                    $new -> {$k} = $sub ;
                    }
                }
            elsif (ref ($v) eq 'ARRAY')
                {
                $new -> {$k} = [@$v] ;
                }
            else
                {
                $new -> {$k} = $v ;
                }
            }
        }

    return $new ;
    }



###################################################################################
#
#   Definitions for documents
#
###################################################################################


%DocumentRoot = (
    '-lsearch' => 1,

    # The document node is generated always and is not parserd, but can be used to include code
    'Document' => {
        'nodename'  => 'Document',
        'nodetype'  => ntypDocument, 
        'procinfo'  => {
            embperl => { 
                perlcode    => q{ 
# any initialisation could be put here
#$DB::single = 1 ;
$maxrow=100;$maxcol=10;
},
                compiletimeperlcode => q{
use vars ('$_ep_DomTree', '@ISA', '@param') ;
*_ep_rp=\\&XML::Embperl::DOM::Node::iReplaceChildWithCDATA;
*_ep_rpid=\\&XML::Embperl::DOM::Node::iReplaceChildWithMsgId;
*_ep_rpurl=\\&XML::Embperl::DOM::Node::iReplaceChildWithUrlDATA;
*_ep_cp=\\&XML::Embperl::DOM::Tree::iCheckpoint;
*_ep_dcp=\\&XML::Embperl::DOM::Tree::iDiscardAfterCheckpoint;
*_ep_opt=\\&Embperl::Cmd::Option;
*_ep_hid=\\&Embperl::Cmd::Hidden;
*_ep_ac=\\&XML::Embperl::DOM::Node::iAppendChild;
*_ep_sa=\\&XML::Embperl::DOM::Element::iSetAttribut; 
Embperl::Util::CreateAliases ;
},
                perlcodeend => q{# Include here any cleanup code
                                $DB::single = 0 ;
                                }, 
                stackname   => 'metacmd',
                stackmatch  => 'Document',
                'push'      => 'Document',
                mayjump     => 1,
                }
            },
        },
    # The document fraq node is generated always and is not parserd, but can be used to include code
    'DocumentFraq' => {
        'nodename'  => 'DocumentFraq',
        'nodetype'  => ntypDocumentFraq, 
        'procinfo'  => {
            embperl => { 
                perlcode    => q{ 
#my $_ep_param_save = \@param ; 
#*param = $Embperl::req -> component -> param -> param || [];
},
                compiletimeperlcode => q{
use vars ('$_ep_DomTree', '@ISA', '@param') ;
*_ep_rp=\\&XML::Embperl::DOM::Node::iReplaceChildWithCDATA;
*_ep_rpid=\\&XML::Embperl::DOM::Node::iReplaceChildWithMsgId;
*_ep_rpurl=\\&XML::Embperl::DOM::Node::iReplaceChildWithUrlDATA;
*_ep_cp=\\&XML::Embperl::DOM::Tree::iCheckpoint;
*_ep_dcp=\\&XML::Embperl::DOM::Tree::iDiscardAfterCheckpoint;
*_ep_opt=\\&Embperl::Cmd::Option;
*_ep_hid=\\&Embperl::Cmd::Hidden;
*_ep_ac=\\&XML::Embperl::DOM::Node::iAppendChild;
*_ep_sa=\\&XML::Embperl::DOM::Element::iSetAttribut; 
Embperl::Util::CreateAliases ;
},
                perlcodeend => q{
#*param = $_ep_param_save ;
}, 
                stackname   => 'metacmd',
                stackmatch  => 'DocumentFraq',
                'push'      => 'DocumentFraq',
                mayjump     => 1,
                }
            },
        },
    ) ;

1;

__END__        


=pod

=head1 NAME

Embperl::Syntax - base class for defining custom syntaxes

=head1 SYNOPSIS


=head1 DESCRIPTION

Embperl::Syntax provides a base class from which all custom syntaxes
should be derived. Currently Embperl comes with the following derived syntaxes:

=over 4

=item EmbperlHTML       

all the HTML tag that Embperl recognizes by default

=item EmbperlBlocks

all the [ ] blocks that Embperl supports


=item Embperl

The default syntax; is derived from C<EmbperlHtml> and C<EmbperlBlocks>

=item ASP

<%  %> and <%=  %>, see perldoc Embperl::Syntax::ASP

=item SSI

Server Side Includes, see perldoc Embperl::Syntax::SSI

=item Perl

File contains pure Perl (similar to Apache::Registry), but
can be used inside EmbperlObject

=item Text

File contains only Text, no actions is taken on the Text


=item Mail

Defines the <mail:send> tag, for sending mail. This is an
example for a taglib, which could be a base for writing
your own taglib to extent the number of available tags

=item POD

Parses POD out of any file and creates a XML tree similar to pod2xml, which
can be formatted by XSLT afterwards.

=back

You can choose which syntax is used inside your page, either by
the C<EMBPERL_SYNTAX> configuration directive, the C<syntax>,
parameter to C<Execute> or the C<[$ syntax $]> metacommand.

You can also specify multiple syntaxes e.g.

    PerlSetEnv EMBPERL_SYNTAX "Embperl SSI"

    Execute ({inputfile => '*', syntax => 'Embperl ASP'}) ;

The syntax metacommand allows you to switch the syntax or to
add or subtract syntaxes e.g.

    [$ syntax + Mail $]

will add the Mail taglib so the <mail:send> tag is available after
this line.

    [$ syntax - Mail $]

now the <mail:send> tag is unknown again

    [$ syntax SSI $]

now you can only use SSI commands inside your page.


=head1 Defining your own Syntax


If you want to define your own syntax, you have to derive a new class from
one of the existing ones and extent it with new tags/functionality. The
best thing is to take a look at the syntax classes that comes with Embperl.
(inside the directory Embperl/Syntax/).

For example if you want to add new html tags, derive from I<Embperl::Syntax::HTML>,
if you want to add new metacommands derive from I<Embperl::Syntax::EmbperlBlocks>.

Some of the classes define addtionaly methods to easily add new tags. See the 
respective pod file, which methods are available for a certain class.

I<Embperl::Syntax> defines the basic methods to create a syntax:

=head1 Methods

=head2 Embperl::Syntax -> new  /  $self -> new

Create a new syntax class. This method should only be called inside a constructor
of a derived class.


=head2 $self -> AddToRoot ($elements) 

This adds a new element to the root of the parser tree. C<$elements> must be a
hashref. See I<Embperl::Syntax::ASP> for an example.

=head2 $self -> AddInitCode ($compiletimecode, $initcode, $termcode, $procinfo) 

This gives you the possibility to add some Perl code, that is always executed 
at the beginning of a document (C<$initcode>), at the end of the document
(C<$termcode>) or at compile time (C<$compiletimecode>). The three strings must
be valid Perl code. See I<Embperl::Syntax::SSI> for an example. C<$procinfo>
is a hashref that can consits of addtional processor infos (see below) for the
document.

=head2 $self -> GetRoot

Returns the root of the parser tree.

=head2 Embperl::Syntax::GetSyntax ($name, $oldname) 

Returns a syntax object which is build form the syntaxes named
in C<$name>. If C<$oldname> is given, C<$name> can start with a C<+> or C<->
to add or subtract a syntax. This is normally only needed by Embperl itself
or to implement a syntax switch statement (see I<Embperl::Syntax::SSI>
for an example.)


=head2 $self -> CloneHash ($old, $replace) 

Clones a hash which is given as hashref in C<$old>, optional replace the tags
given in the hashref C<$replace> and return a hashref to the new hash.



=head1 Syntax Structure and Parameter

Internaly the syntax object builds a data structure which serve as base for
the parser. This structure consists of a list of tokens and options, which starts
with a dash:

=head2 Tokens

=over 4

=item    '-lsearch' => 1

Do an linear serach instead of a binary search. This is necessary if the 
tokens can't clearly separated.

=item     '-defnodetype' => ntypText,

Defines the default type for text nodes. Without any specification the type
is CDATA, which mean no escaping takes places. With C<ntypText> all special
characters are escaped.

=item   '-rootnode'

Name for a root node to insert always.

=item    <name> => \%tokendescription

All items which does not start with a slash are treated as names. The name
of a token is only descriptive and is used in error messages. The item must
contain a hashref which describes the token.

=back

=head2 Tokendescription

Each token can have the following members:

=over 4

=item 'text' => '<'

Start text

=item 'end'  => '>'

End text

=item 'matchall'

when set to 1 new token starts at next character, when set to -1 new token
starts at next character, but only if it is the first token inside another one.

=item 'nodename'

Text that should be outputed when node is stringifyed. Defaults to text.
If the first character is a ':' you can specify the sourounding delimiters for this
tag with :<start>:<end>:<text>:<endtag>. Example:  ':{:}:NAME' .
If the nodename starts with a '!' a unique internal id is generated, so two or more
nodename of the same text, can have different meaning in different contexts.

=item 'contains'   => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789'

Token consists of the following characters. Either C<start> and C<end> B<or> C<contains>
could be specified. 

NOTE: If a item that only specfifies contains but no text should be compiled, you must
specfify a nodname.

=item 'unescape' => 1

If C<optRawInput> isn't set unescape the data of the inside the node

=item 'nodetype'   => ntypEndTag

Type of the node

=item 'cdatatype'  => ntypAttrValue

Type of nodes for data (which is not matched by 'inside' definitions) inside
this node. Set to zero to not generate any nodes for text inside of this node,
other then these that are matched by a 'inside' definition.

=item 'endtag'

Name of the tag that marks the end of a block. This is used by the parser
to track correct nesting.

=item 'follow' => \%tokenlist

Hashref that specifices one or more tokens that must follow this token.

=item 'inside' => \%tokenlist

Hashref that specifices one or more tokens that could occur inside
a node that is started with this token.

=item exitinside

when the token found, the parser stop searching in the current level and continues
with the tokens that are defined in the hash from there the current one was "called"
via inside

=item donteat

set to 1 to don't eat the start text, so it will be matched again, by any tokens
set under C<inside>. Set 2 to don't the end text. Set to 3 for both.


=item 'procinfo' => 

Processor info. Hashref with information how to process this token.

=back

=head2 Processor info 

The processor info gives information how to compile this token to valid
code that can be executed later on by the processor. There could be
information for multiple processors. At the moment only the I<embperl>
processor is defined. Normaly you must not worry about different
processor, because the syntax object knows inside that all procinfo is
for the I<embperl> processor. I<procinfo> is a parameter to many methods,
it is a hashref and can take the following items:


=over 4

=item perlcode => <string> or <arrayref>

Code to generate. You can also specify a arrayref of strings.
The first string which contains matching attributes are used.
The following special strings are replaced:

=over 4

=item %#<N>% 

Text of childnode number <N> (starting with zero)

=item %><N>% 

Text of sibling node number <N> . 
0 gives the current node, 
> 0 gives the Nth next node, 
< 0 gives the Nth previous node.

=item %&<attr>%

Value of attribute <attr>.

=item %^<stackname>%

Stringvalue of given stack

=item %?<stackname>%

Set if stackvalue was used

=item %$n%

Source Dom Tree, Index of current node.

=item %$t%

Source Dom Tree

=item %$x%

Index of current node

=item %$l%

Index of last node

=item %$c%

Sets the current node Index, if not already done

=item %$q%

Index of source Dom Tree

=item %$p%

Number of current checkpoint

=item %%

Gives a single %

=back


All of the above special values (expect those start with $) allows the following
modifiers:

=over 4

=item %<X>B<*><N>%

Attribute/Child etc. must exist.

=item %<X>B<!><N>%

Attribute/Child etc. must not exist.

=item %<X>B<=><N>:<value1>|<value2>|<value3>%

Attribute/Child etc. must have the value = <value1> or <value2> etc.

=item %<X>B<~><N>:<value1>|<value2>|<value3>%

Attribute/Child etc. must contain the substring <value1> or <value2> etc.
and a non alphanum character must follow the substring.

=back

writing a minus sign (-) after * ! = or ~ will cause the child/attribute
not to be included, but the condition is evaluated. Writing an ' will cause
the value to be quoted.

=item perlcodeend => <string> 

Code to generate at the end of the block.

=item compiletimeperlcode => <string> or <arrayref>

Code that is executed at compile time. You can also specify a arrayref of string.
The first string which contains matching attributes are used.
The same special strings are replaced as in C<perlcode>.

C<$_[0]> contains the Embperl request object. The method C<Code> can be used to 
get or set the perl code that should be generated by this node.

If the code begins with #!- all newlines are removed in the code. This is basically
useful to keep all code on the same line, so the line number in error reporting
matches the line in the source. 

=item compiletimeperlcodeend => <string>

Code that is executed at compile time, but at the end of the tag.
The same special strings are replaced as in C<perlcode>.

C<$_[0]> contains the Embperl request object. The method C<Code> can be used to 
get or set the perl code that should be generated by this node.

If the code begins with #!- all newlines are removed in the code. This is basically
useful to keep all code on the same line, so the linenumber in error reporting
matches the line in the source. 

=item perlcoderemove => 0/1

Remove perlcode if perlcodeend condition is not met.


=item removenode => <removelevel>

Remove node after compiling. <removelevel> could be one of the following,
values could be added:

=over 4

=item 1

Remove this node only

=item 2

Remove next node if it consists of only white spaces and optKeepSpaces isn't set.

=item 3

Replace next node with one space if next node consists only of white spaces and
optKeepSpaces isn't set.

=item 4

Set this node to ignore for output.

=item 5

Remove all child nodes

=item 6

Set all child nodes to ignore for output.

=item 7

Calculate Attributes values of this node also for nodes that are set to ignore for output
(makes only sense if 8 is also set).


=back

=item removespaces => <removeflags>

Remove spaces before or after tag.

=over 4

=item 1

Remove all white spaces before tag

=item 2

Remove all white spaces after tag

=item 3

Remove spaces and tabs before tag

=item 4

Remove spaces and tabs after tag

=item 5

Remove all spaces and tabs but one before tag

=item 6

Remove all whihe space after text inside of tag

=item 7

Remove spaces and tabs  after text inside of tag

=back

=item mayjump => 0/1

If set, tells the compiler that this code may jump to another program location.
(e.g. if, while, goto etc.).
Could also be a condition as described under perlcode.


=item compilechilds => 0/1

Compile child nodes. Default: 1

=item stackname => <name>

Name of stack for C<push>, C<stackmatch>
 
=item stackname2 => <name>

Name of stack for C<push2>
 
=item push => <value> 

Push value on stack which name is given with C<stackname>. Value could
include the same specical values as C<perlcode>

=item push2 => <value> 

Push value on stack which name is given with C<stackname2>. Value could
include the same specical values as C<perlcode>

=item stackmatch => <value> 

Check if value on stack which name is given with C<stackname> is the
same as the given value. If not give a error message about tag mismatch. Value could
include the same specical values as C<perlcode>

=item switchcodetype => <1/2>

1 means put the following code into normal code which is executed everytime the page is
requested

2 means put the following code put into code which is executed direct after compilation.
This is mainly for defining subs, or using modules etc.


=item addflags

=item cdatatype

=item forcetype

=item insidemustexist

=item matchall

=item exitinside

=item addfirstchild

=item starttag

=item endtag

=item parsetimeperlcode

=item contains

=back


