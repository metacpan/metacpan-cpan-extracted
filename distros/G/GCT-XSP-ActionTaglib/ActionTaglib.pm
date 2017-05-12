
=head1 NAME

GCT::XSP::ActionTaglib - Helps Compose AxKit XSP taglibs in a simple and extensible manor.

=head1 SYNOPSIS

    package MyTaglib;
    use GCT::XSP::ActionTaglib;
    @ISA = qw(use GCT::XSP::ActionTaglib;);
    our $NS = 'MyTaglib-URI';
    our $tagactions;
 
    $tagactions->{tag1}=[ ...actionlist for tag1... ];
    
=head1 DESCRIPTION

ActionTaglib helps write a talgib module for AxKit. One or more 'actions' are assigned to each XML element processed by the taglib. When the XSP page is 'run' ActionTaglib performs these actions as it parses the XML elements they are assigned to. An action is implemented as two Perl subroutines one for when the opening XML element is parsed, the 'start' subroutine, and one for when the closing XML element is parsed, the 'end' subroutine. For example:

by adding a tag1 entry to the tagactions hashref as follows:

    $tagactions->{tag1}=[{-action => 'myaction'}];

And adding the following tags to an XSP page (with the relevant namespace settings)

    <ns:tag1> ... </ns:tag1>

'myaction_start' will be called for the opening <ns:tag1> and 'myaction_end' will be called for the closing element </ns:tag1>.


This behavior extends Apache::AxKit::Language::XSP which does essentially the same thing but with one 'action' for all XML elements (parse_start / parse_end). The hope is to make taglibs easier to layout and read but more importantly it is possible to share actions between taglibs and thus save writing the same code twice for different taglibs. Libraries of actions can be written and shared by importing their actions into a taglib module that uses ActionTaglib.

ActionTaglib has two further features to enhance the idea and useage of 'actions'. The first is that a tag can be assigned multiple actions and the second is actions can be given arbitrary options. Multiple actions are assigned in the following manor:

    $tagactions->{tag1}=[{-action => 'library_action'},
                         {-action => 'myaction'}        ];

With our <ns:tag1> ... </ns:tag1> example 'library_action_start' followed by 'myaction_start' would be called for the opening element <ns:tag> and 'myaction_end' followed by 'library_action_end' would be called for the closing element </ns:tag>. Note the change in order, actions are proccess in the forward order for an opening element and in the reverse order for a closnig element.

Options can be parsed in the following manor:

    $tagactions->{tag1}= [{-action => 'myaction',
                           -options => {-anyoption => 'anyvalue'} }];

=head1 THE tagactions HASHREF

The tagactions hashref, as introduced above, accosiates XML elements with the actions that should be performed to proccess them. The format is to specify an array, called an 'actionlist' for each tag as follows:

    $tagactions->{tag1} = [..actionlist for tag1..]

Actions are the spcifed, in order, as elements of the array as follows:

    [action,action,action...]

Each action is defined by a hash containing th following keys:

-action. Required string. the name of the action to call.

-when. Optional string, Values can be 'start', 'end' or the default 'both'. If the value is 'start' is the action will only be called for the opening tag, if the value is 'end' the action will only be called for the closing tag and if the value is 'both' (or the key -when is ommited) the action will be called for both the opeing and closing tag. 

-pkg. Optional string, The pkg that contanis the action to be called. If ommited the default package is the package of the taglib being written, i.e. the current package..

-options. Optional hash, Any options to be passed to the action.

The options are passed as a hash of option value pairs. A complete example of a tagactions hashref is given bellow.

=head1 WRITEING ACTIONS

Actions are written in a very similar way to you would write the parse_start and parse_end subs when using AxKit::Lanaguage::XSP directly. Just like the parse* subs in AxKit::Langauge::XSP, action subs output some perl code, as a string, which will be added to the script that is being built for the current XSP page. The proccess, for taglibs in general, is that an XSP page is parsed (with a SAX parser), taglibs transfor it into a perl script, the perl script is executed and ouputs an XML document. The genrated script uses a DOM to build and output it's XML document but this is all handeled by AxKit::Langauge::XSP and a taglib author often need not know.

If you have never written a parse_start or parse_end using AxKit::Language::XSP you can still write actions. They are defined by writing two subs: actionname_start{} and actionname_end{}. which are called or an element that is specified to use the action named 'actionname', that _start sub when the an opening tag is being parsed and the _end sub when a closing tag is being parsed. They both take the following arguments:

($parseargs,$options,$action,$i,$actionlist,$tagactions)

Which are as follows:

$parseargs, array, contains ($e, $tag, %attribs) for the _start sub and ($e, $tag) for the end sub, which is the same idea as used with parse_start and parse_end in AxKit::Lanagauge::XSP.

$options. hashref, the options to use for this action as specified in the $tagactionshash.

Note the passed values of $action, $i, $actionlist and $tagactions are used for wrtiting more advanced actions. They enable an action to modify the $tagactions hahref it is in and thus change the way actions are performed for tags while the source ducument is being parsed, in otherwords on-the-fly. This feature must be used with care becuase the $tagactions hash could easily be changed in a way that makes no sence. However it is enables us to write actions that and, remove or change other action specifications in the taglib. 

$action, hashref, the action currently being run.

$i, integer, the index of the current action in it's action list.

$actionlist, arrayref, the actionlist in which the current action is specified.

$tagactions, hasref, all the tagactions.

=head2 $parseargs

The variables in passed in parse args are as follows:

$e, the script being build

$tag, the name of the tag being parsed

$attribs, a hash of the attributes bellonging to the current tag.


MORE TO COME...


An example

    $tagactions->{helloworld} = [{-action  => 'format',          #the name of the action
                                  -pkg     => 'htmlformating', #the package it is defined in
                                  -when    => 'both',          #when to call the action
                                  -options => {-type => 'bold'}
                                 },{
                                  -action  => 'text',
                                  -when    => 'start',
                                  -options => { text => 'Hello World'}
                                 }];



=head2 EXPORT

None by default.

=cut

use 5.006;
use strict;
use warnings;

package GCT::XSP::ActionTaglib;

use Apache::AxKit::Language::XSP;
our @ISA = ('Apache::AxKit::Language::XSP', 'Exporter');
# our $NS = ...
# No namespace here, ActionTaglib is designed to be inherited from
# Implementations should declare 'our $NS' with a unique URI.

our $VERSION = '0.02';
our $REVISION; $REVISION = '$Revision: 1.4 $';
our $dbug=0;
our $dbug_tagactions=0;

########################################
# package GCT::XSP::ActionTaglib;
# the 'action processor', reads the action list
# and calls the relevant subroutines.

sub Debug{
    AxKit::Debug(1,"[ActionTaglib]", @_);
  }
############################################################
#parses all elements and calls the relevant subroutine
#to deal with them.
sub parse_element{
    my ($parseargs,$when) = @_;
    #$parseargs, arrayref, the standard AxKit arguments as given to
    #parse_start / parse_end.($e,$tag,%attribs).
    #$when, string, 'start' => opening element, 'end' => closing element.

    my $tag = $parseargs->[1];
    #get the tagactions hashref that specifies how to deal with this element
    my $tagactions;
    my $pkg = $AxKit::XSP::TaglibPkg; #not very OOP! would be better if we could call $self->tagactions
    {no strict;
	$tagactions = ${"$pkg\::tagactions"};};
    Debug("parse_start -$pkg-$tag-") if $dbug;
    #get the actionlist for this element
    if(my $actionlist = ($tagactions->{$tag})){
	Debug("ActionTaglib             Actions:")  if $dbug;
	#TODO use a reference to the actionlist and avoid creating a ne array
	#that way the actionlist array will refer to the actual array rather
	#than a copy of it.
	Debug("parsing $tag $when         ") if $dbug;
	#Do all the actions for this element,
	#pass $actionslist and $tagactions so the action can modify them is necessary. 
	return processactionlist($parseargs,$actionlist,$tagactions,$when,$pkg)
    }else{
	return '';
    }
}

############################################################
#processes an array of actions, in forward order if they are
#being started ($when = 'start') and in reverse order if
#they are being ended ($when = 'end').
sub processactionlist{
    my ($parseargs,$actionlist,$tagactions,$when,$default_pkg) = @_;
    #$parseargs, as above.
    #$actionlist, arrayref, a list of actions to do for this element.
    #$tagactions, hashref, all the tagactions in this taglib
    #$when, as above.
    #$default_pkg, string, the default package to contain the action sub's.

    my $last = scalar @{$actionlist};
    my $ret;
    Debug("COUNT: $last ACTIONS TODO              ") if $dbug;
    if ($when eq 'start'){  #forward
	for (my $i=0;$i<$last;$i++){
	    $ret .= processactioni($parseargs,$i,$actionlist,$tagactions,$when,$default_pkg);
	}
    }elsif($when eq 'end'){ #reverse
	for (my $i=$last;$i>-1;$i--){
	    $ret .= processactioni($parseargs,$i,$actionlist,$tagactions,$when,$default_pkg);
	}
    }else{
	die "'$when' is not a valid when, value must be start or end";
    }
    return $ret;
}

############################################################
#Process a numbered action from an actionlist but only if
#the time ($when) is right.
sub processactioni{
    my ($parseargs,$i,$actionlist,$tagactions,$when,$default_pkg) = @_;
    #all arguments as above, except:
    #$i, integer, numbered action from $actionlist array to process.
    my $action = $actionlist->[$i];
    #the -when option specifies when the action should be done.
    #'start' => only when an element is opening.
    #'end'   => only when an element is closing.
    #'both'  => both when an element is opening and when is is closing [default].
    my $awhen = $action->{-when} || "both";
    Debug("DOING ACTION $i                ") if $dbug;
    if ( $awhen eq "both" || $awhen eq $when) {				
	$action->{-pkg} ||= $default_pkg;
	return processaction($parseargs,$action,$i,$actionlist,$tagactions,$when);
    }else{
	return '';
    }
}

############################################################
#processes a single action 
sub processaction{
    my ($parseargs,$action,$i,$actionlist,$tagactions,$when) = @_;
    #all arguments as above.
    my $methodpkg = $action->{-pkg};             #required. the package that contains the action
    my $method  = $action->{-action} . "_$when"; #required. the name of the action to perform, appended
                                                 #with the time (start or end) it is being performed
    my $options = $action->{-options};           #optional. any options the action might use/need.
    Debug("LOOKING TO SEE IF $methodpkg -> can ($method)") if $dbug;
    if (my $sub = $methodpkg->can($method)){
	Debug("A SUB CALLED: $method for $parseargs->[1]           ") if $dbug;
	#finally we do the action!
	#see the documentation on how to write an action 
	return $sub->($parseargs,$options,$action,$i,$actionlist,$tagactions);
    }else{
	return '';
    }
}
########################################
# Overriding Apache::AxKit::Language::XSP subs;

sub start_document{
    Debug("[ActionTaglib] START DOCUMENT");

    if($debug_tagations){
	my $tagactions;  
	my $pkg = $AxKit::XSP::TaglibPkg; #holds the package name of the current taglib
	{no strict;
	 $tagactions = \${"$pkg\::tagactions"};};
	use Data::Dumper;
        Debug("TAGATIONS AT START OF DOUCUMENT: " . Dumper($tagactions)) if $dbug;
    }
    return '';
}

sub end_document{    
    Debug(1,warn "END DOCUMENT");

    if($debug_tagations){
	my $tagactions;
	my $pkg = $AxKit::XSP::TaglibPkg;      #not very OOP!
	{no strict;
	 $tagactions = \${"$pkg\::tagactions"};};
	use Data::Dumper;
	Debug("TAGATIONS END: " . Dumper($tagactions)) if $dbug;
    }
    return '';
}

# get the ActionTaglib parse_element to deal with all
# elements opening (start) and closing (end).
sub parse_start{
    return parse_element(\@_,'start');
}

sub parse_end{
    return parse_element(\@_,'end');
}

#default to add characters as text nodes
sub parse_char{
    my ($e, $text) = @_;
    $text =~ s/^\s*//; #remove leading
    $text =~ s/\s*$//; #and trailing spaces
    return '' unless $text;
    $text = Apache::AxKit::Language::XSP::makeSingleQuoted($text);
    return ". $text";
}

#drop comments
sub parse_comment{
    my ($e, $comment);
    return '';
}

1;

__END__

=head1 AUTHOR

Adam Griffiths, E<lt>adam@goldcrosstechnical.co.ukE<gt>

=head1 BUGS

None known, please report any to bugreport@goldcrosstechnical.co.uk

=head1 SEE ALSO

L<perl>, 
L<AxKit>, 
L<Apache::AxKit::Language::XSP>.

For writing action libraries@

L<ActionExporter>.

Other talgib authoring modules:

L<Apache::AxKit::Language::XSP::TaglibHelper>, 
L<Apache::AxKit::Language::XSP::ObjectTaglib>, 
L<Apache::AxKit::Language::XSP::SimpleTaglib>.

=head1 COPYRIGHT

Copyright (C) 2003, Adam Griffiths, Goldcross Technical. All Rights Reserved.

This Program is free software. You may copy or redistribute it under the same terms as Perl itself.

NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

