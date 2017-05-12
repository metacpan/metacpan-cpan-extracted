
package HTML::CGIChecker;

use strict;
use Carp;

BEGIN {
	use vars qw ($VERSION @ISA);
	$VERSION     = 0.90;
	@ISA         = ();
}

=head1 NAME

B<HTML::CGIChecker - A Perl module to detect dangerous HTML code>


=head1 SYNOPSIS

	use HTML::CGIChecker;
	
	$feedback = '
	<TABLE CELLPADDING="2"><TR><TD>One column</TD></TR></TABLE><BR>
	" Arrays & variables "
	
	Dough > Hi, how are you ?
	
	And now some Perl code:
	<PRE>
		print "<HTML><BODY></BODY></HTML>";
	</PRE>
	';

	# create the $checker object
	
	$checker = new HTML::CGIChecker (
		mode => 'allow',
		allowclasses => [ qw( tables images ) ],
		allowtags => [ qw ( B I A U STRONG BR HR ) ],	
		jscript => 0,
		html => 0,
		pre => 1,
		debug => 0,
		err_tag => 'Tag {tag} is not allowed in {element}.'
	);

	# Now you can use it to check any string using its checkHTML()
	# method. It "remembers" its configuration, so you can reuse it.

	($checked_feedback, $Warnings) = 
		$checker->checkHTML ($feedback);

	# Process the results ...

	if ($checked_feedback) {
		# save $checked_feedback to the database ....
	} 
	else {
		# print the warnings ...
		print join ("\n", @{$Warnings});
	}

The example above produces no warning messages and returns
$feedback checked and properly HTML escaped. The only HTML "error" -
the unescaped "E<gt>" bracket on the fourth line - is autocorrected.
One warning message was overriden by a customized version. Potential
warnings would not be HTML formatted and HTML safe, because
the 'html' parameter is not true.


=head1 MOTIVATION

Almost every modern website needs some way to get feedback from its users
in form of comments that are also visible to other visitors. It is convenient
to allow the users to use a limited set of HTML tags in their posts to
embold text, create hyperlinks or even include images.

The problem araises when the user posts HTML code that breaks the page on
which the post is displayed. You must check the
posts for dangerous HTML errors and javascripts to prevent a malicious user
to render the rest of the page unusable. This module has been created
to fulfill this function and also to provide some extra features.

Typical HTML validators do not suit well for the above mentioned purpose,
because they are way too strict and do not scale well. A small and fast
checker that also allows a programmer to deny and allow tags on an individual
basis comes as a solution of this problem. Another problem one has to solve
while creating a web site that allows HTML user posts is to escape these
posts correctly before storing them to the database and displaying them
to other users.

The currently available module HTML::QuickCheck that should fill the same
purpose does not offer some crucial features:

Checking of B<correct quoting> - this problem can be fatal, because the
common typo when one forgets to close quotes in for example a HREF parameter
almost always totally corrupts the rest of a page.

B<HTML escaping> of the right parts of the posts - ie. of the non-HTML parts.

Denying/allowing of B<javascripts>.

Denying/allowing of B<images>, applets, styles, forms and other similar
functionality that requires a programmer to be able to deny/allow tags
or entire tags classes on an individual basis.

Support for the special formatting B<PRE tag>. Please note that the
PRE tag has special meaning for this module.
Everything that is placed inside PRE block is automatically HTML
escaped. The users can use this behaviour to easily post for
example code snippets that contain unescaped HTML brackets. All they
need is to place the snippet inside a PRE block. They do not need to
worry about escaping of the brackets.

Ability to B<customize/localize the warning messages> that are returned
to the user in case when a problematic HTML in his post is detected.

Autocorrection of some "common" errors, for example of chat messages
containing unescaped HTML brackets - "peter E<gt> how are you ?".
Both unmatched opening and closing HTML brackets are autocorrected.

Proper detection of some table closing tags problems that can break the page
in some browsers.

Conversion of images to appropriate hyperlinks.

Automatic prepending of "http://" to URLs which do not start with "http://".


=head1 DESCRIPTION

HTML::CGIChecker is a module for web developers to parse HTML and to detect
HTML code that could break a page in some way.
This module is not a HTML validator, but it allows one to check the HTML
code that users post to a web application, for example to a discussion
board, to prevent them to post a piece of code that would render the rest
of a page it is displayed on unusable.

Using it one also can deny javascripts, images, tables or any other
tags on an individual basis. It also can check for correct quoting
and correct URLs.

The module can autocorrect some common bad users' behaviour, for
example the use of unescaped HTML brackets in a chat room, etc.

It is easy to use and very useful in any CGI application in which
you want its users to be able to use HTML in their posts to some
customizable extent. It is object oriented and designed to be easily
extensible.

B<This is not a validator>, for validation you need an other
solution. This module does not care about correctness of the parsed HTML code
at all. All it does care about is whether the HTML code could break a page.
HTML tags that are not paired correctly or that cannot be rendered at all
can pass this checker. All the names of elements and attributes are not case
sensitive.

The checker object is created by calling new() constructor of HTML::CGIChecker
class.


	$checker = new HTML::CGIChecker (
		mode => 'allow',
		....
	);


Then you can use the checkHTML() instance method to perform a check on
a string using the settings this object has been configured with. 

	($checked_string, $Warnings) = 
		$checker->checkHTML ($string);


B<new() - the constructor>

Creates and returns a new checker object that can be configured with
parameters that are described below. Default configuration allows only
a few harmless inline tags to be used in the HTML code:

    B I A U STRONG BR
    EM CITE VAR ABBR Q DFN CODE SUB SUP SAMP KBD ACRONYM

Other tags except the special PRE tag are not allowed.
Javascripts are by default also not allowed. 

The various parameters are passed in as a list of B<parameter =E<gt> value>
pairs. List of these parameters together with their default values follows:

	mode => 'allow'
	allowclasses => []
	allowtags => [ qw ( 
        B I A U STRONG BR EM CITE VAR ABBR Q DFN CODE
        SUB SUP SAMP KBD ACRONYM
	) ]	
	denyclasses => [ keys (%tagclasses) ]
	denytags => [ qw ( FONT ) ]
	jscript => 0
	html => 0
	pre => 1
	img_to_link => 0
	check_http => 1
	debug => 0
	nonpairtags => [ qw (
	    IMG HR BR INPUT META AREA COL BASE LINK PARAM
	) ]
	check_attribs => {}
	err_tag => 'Tag {tag} is not allowed in {element}.'
	err_javascript => 'Javascript is not allowed in {element}.'
	err_quote => 'Missing quote in {element}.'
	err_notclosed => 'Pair tag {tag} was not closed.'
	err_notopened => 'Pair tag {tag} was not opened.'


B<mode>

Two modes are available: allow (default) and deny.

B<allow>: Error is raised if any tag that is not explicitely
allowed is found.

B<deny>: Error is raised if an explicitely denied tag is found,
any other tags are allowed.


B<allowclasses, allowtags>

These parameters apply only in the 'allow' mode.
Here you can specify the tags you allow the user to use.
Allowtags must be a reference to an array of tag names.
Allowclasses must be a refernce to an array of class names.
Tag class (tag group) is a set of tags that can be allowed or denied all
at once by allowing or denying the class. These classes are available:

	base        FRAMESET FRAME HTML BODY HEAD TITLE BASE
	            STYLE SCRIPT META NOSCRIPT NOFRAMES
	externals   APPLET OBJECT LINK IFRAME PARAM
	forms       FORM TEXTAREA SELECT INPUT BUTTON LABEL
	            FIELDSET LEGEND OPTGROUP
	tables      TABLE TR TD TBODY THEAD TFOOT TH COLGROUP
	            COL CAPTION
	lists       UL OL LI DL DT DD
	images      IMG MAP AREA
	heading     H1 H2 H3 H4 H5 H6 H7 H8

By default only the above mentioned harmless inline tags are allowed.
By default no classes are allowed.

B<denyclasses>, B<denytags>

These parameters apply only in the 'deny' mode.
They work similar to the allowclasses and allowtags
parameters. By default B<all> above listed classes plus the FONT tag are
denied. All other tags are by default allowed in this mode.

B<jscript>

This option disables javascript inside HTML elements.
You also must ensure that the SCRIPT tag is not allowed to block
the javascript completely.

	0: javascript is not allowed
	1: javascript is allowed
	Default: 0


B<html>

	0: messages will not be in HTML format nor HTML escaped -
       useful for the command line mode
	1: all warning messages will be in HTML versions and also
       HTML escaped
	Default: 0

B<pre>

	0: users will not be allowed to use the special PRE tag
	1: users will be allowed to use the special PRE tag
	Default: 1

B<img_to_link>

	0: do not alter images
	1: convert all images to appropriate links to these
       images: <IMG SRC="url">  ---->  <A HREF="url">url</A>
	Default: 0

B<check_http>

	0: do not alter URLs
	1: prepend "http://" to URLs that do not start
	   with "http://", "ftp://" or "mailto:"
	Default: 1
	
	Note: the URLs are recognized only in
    HREF and SRC parameters.

B<debug>

	0: debugging to STDERR is disabled
	1: debugging to STDERR is enabled
	Default: 0	

B<nonpairtags>

The tags that are processed as non-pair can be specified here
via a reference to an anonymous array.
By default these tags are processed as non-pair:

    IMG HR BR INPUT META AREA COL BASE LINK PARAM

B<check_attribs>

You also can use the check_attribs parameter to allow the user to use
only a limited set of attributes in an element. The parameter is a
hash reference, that consists of key->value pairs, in which the key is
name of an element, and the value is a reference to an array of attributes.
For each element specified in this hash, the user will only be allowed
to use the specified attributes.

For example, if you define following hash reference:

	check_attribs => {
			img => [ 'src', 'width', 'height', 'alt' ]
		}

then the user will be allowed to use ONLY the specified attributes in
the <IMG> element. Any other elements are not affected and the user
will be allowed to use any attributes in them. Names of the elements
and of the attributes are not case sensitive.

B<Warning messages> can be redefined by setting these parameters:

	err_tag          = 'Tag {tag} is not allowed in {element}.'
	err_javascript   = 'Javascript is not allowed in {element}.'
	err_quote        = 'Missing quote in {element}.'
	err_notclosed    = 'Pair tag {tag} was not closed.'
	err_notopened    = 'Pair tag {tag} was not opened.'

Messages displayed above are the defaults. Special tokens {tag} and {element}
are replaced by the appropriate values. You can redefine these messages to
localize them.


B<checkHTML() - the actual HTML check method>


	($checked_string, $Warnings) = 
		$checker->checkHTML ($string);


This method accepts only one parameter - the actual string to check.

If the string contains anything dangerous or not allowed then this method
returns an undefined value and a reference to an array of warning messages
that describe the problems that were detected.

If the string is safe then checked and escaped version of the
string is returned together with an reference to an empty array.

Please note the warning messages are not returned as an array, but as a
reference to an array, that must be B<dereferenced> when you use it as an
array. Usual way to print all the warnings is using the join() function:

	print join ("<BR>\n", @{$Warnings});


=head1 SUPPORT

No official support is provided, but I welcome any comments, patches
and suggestions on my email. If you suggest a new feature, please justify
how it will help the purpose of this module - to provide B<fast> checking
for HTML code that breaks pages.


=head1 BUGS

I am aware of no bugs. But remember, this is NOT a validator - bad HTML may
and will pass it. Please let me know if you find any chunk of code that passes
it and also breaks a page.


=head1 AVAILABILITY

	http://www.geocities.com/tripiecz/


=head1 AUTHOR

B<Tomas Styblo>, tripiecz@yahoo.com

Prague, the Czech republic


=head1 LICENSE

HTML::CGIChecker  - A Perl module to detect dangerous HTML code

Copyright (C) 2000 Tomas Styblo (tripiecz@yahoo.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file Artistic.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA


=head1 SEE ALSO                                                                                                
                                                                                                               
perl(1).                                                                                                       


=cut

# public:
sub new;
sub checkHTML;

# private:
sub _pair_compile;
sub _process_element;
sub _http;		
sub _imgtolink;
sub _quoting;
sub _javascript;
sub _pair_saveinfo;
sub _allowed_tags;
sub _parse_error;
sub _pair_check;
sub _html_escape;

END { }

sub new {
	my $class = shift;
	
	croak ('HTML::CGIChecker - even number of parameters expected.')
		if (@_ % 2);	
	
	my %tagclasses;
	$tagclasses{'base'} = 
	[ qw ( FRAMESET FRAME HTML BODY HEAD TITLE BASE
	       STYLE SCRIPT META NOSCRIPT NOFRAMES ) ];
	$tagclasses{'externals'} = [ qw ( APPLET OBJECT LINK IFRAME PARAM ) ];
	$tagclasses{'forms'} = [ qw (
	    FORM TEXTAREA SELECT INPUT BUTTON LABEL FIELDSET LEGEND
	    OPTGROUP
	) ];
	$tagclasses{'tables'} = 
	[ qw ( TABLE TR TD TBODY THEAD TFOOT TH COLGROUP COL CAPTION ) ];
	$tagclasses{'lists'} = [ qw ( UL OL LI DL DD DT ) ];	
	$tagclasses{'images'} = [ qw ( IMG MAP AREA ) ];
	$tagclasses{'heading'} = [ qw ( H1 H2 H3 H4 H5 H6 H7 H8 ) ];

	# set the defaults
	my $self = {
		check => '',
		mode => 'allow',
		denyclasses => [ keys (%tagclasses) ],
		denytags => [ qw ( FONT ) ],
		allowclasses => [],
		allowtags => [ qw ( 
		    B I A U STRONG BR EM CITE VAR ABBR Q DFN CODE
            SUB SUP SAMP KBD ACRONYM
        ) ],	
		jscript => 0,
		html => 0,
		pre => 1,
		img_to_link => 0,
		check_http => 1,
		debug => 0,
		nonpairtags => [ qw (
		    IMG HR BR INPUT META AREA COL BASE LINK PARAM
		) ],
		check_attribs => {},
		err_tag => 'Tag {tag} is not allowed in {element}.',
		err_javascript => 'Javascript is not allowed in {element}.',
		err_quote => 'Missing quote in {element}.',
		err_notclosed => 'Pair tag {tag} was not closed.',
		err_notopened => 'Pair tag {tag} was not opened.',
		err_attrib => 'Attribute {attrib} is not allowed in {tag}.'
	};

	bless ($self, $class);

	# get parameters, overiding the defaults
	for (my $i = 0; $i <= $#_; $i += 2)	{
		exists ( $self->{lc($_[$i])} ) or 
			croak ('Invalid parameter ' . $_[$i] . '.');
    	$self->{lc($_[$i])} = $_[($i + 1)];
	}

	# convert to uppercase
	map ($_ = uc($_), @{$self->{'allowtags'}});	
	map ($_ = uc($_), @{$self->{'denytags'}});

	my $class;	
	foreach $class (keys(%tagclasses)) {
		map ($_ = uc($_), @{$tagclasses{$class}});
	}
	
	map ($_ = uc($_), @{$self->{'nonpairtags'}});
	
	my $element;
	foreach $element (keys(%{$self->{'check_attribs'}})) {
		map ($_ = uc($_), @{$self->{'check_attribs'}->{$element}});
		if ($element ne uc($element)) {
			my $ucelement = uc($element);
			$self->{'check_attribs'}->{$ucelement} = 
				$self->{'check_attribs'}->{$element};
			delete($self->{'check_attribs'}->{$element});
		}
	}

	# compiles allowed/denied tag data
	$self->_pair_compile (\%tagclasses);

	return $self;
}


sub checkHTML {
	my $self = shift;
	my $in = shift;
	my $out;					# processed input to return
	my $premode = 0;			# indicates we are in a PRE block
	
	$self->{'_errors'} = [];
	$self->{'_opentags'} = {};
	$self->{'_closetags'} = {};

    my @tokens = split(/(<[^<]*?>)/s, $in);
    my $token;
	foreach $token (@tokens) {
        if (index($token, '<') != 0) { 
            # This token is not a HTML element.
            # Jump to the next token.
			$out .= $self->_html_escape($token);
			next;
		}
		
		# This token is a HTML element.					
		$self->{'_element'} = $token;	# element = the whole <.*> thing
		($self->{'_tag'}) = $token =~ m|^<\s*(/?\w+)|s;   # name of this tag
		next if (not $self->{'_tag'});		
		$self->{'_tag'} = uc($self->{'_tag'});
		
		# generetes the abstag
		if (index($self->{'_tag'}, '/') == 0) {
			$self->{'_abstag'} = substr ($self->{'_tag'}, 1);
		}
		else {
			$self->{'_abstag'} = $self->{'_tag'};
		}
		
		# the PRE feature
		# end this pass if PRE is allowed and we are in a PRE block
		
		if ($self->{'pre'}) {
			if (not $premode and $self->{'_tag'} eq 'PRE') {
				$out .= $self->{'_element'};
				$premode = 1;
				$self->_pair_saveinfo();
				next;
			}
			elsif ($premode and $self->{'_tag'} eq '/PRE') {
				$out .= $self->{'_element'};
				$premode = 0;
				$self->_pair_saveinfo();
				next;
			}
		
			if ($premode) {
				$out .= $self->_html_escape($self->{'_element'});
				next;
			}
		}
		
		# If PRE is allowed, then we get to this point only if the current
		# element is not inside a PRE block.
		#
		# This method calls all the methods that process the current element.
		# Override this method in your subclass to add your own methods.		
		$self->_process_element();
		
		# Current element is pushed to the end of the output buffer.			
		$out .= $self->{'_element'};	
	}
	# END of the loop
	
	$self->{'_element'} = '';
	$self->{'_tag'} = '';
	$self->{'_abstag'} = '';
		
	$self->_pair_check ($self->{'_opentags'}, $self->{'err_notclosed'});
	$self->_pair_check ($self->{'_closetags'}, $self->{'err_notopened'});

	# We make a copy of the array of errors to prevent memory leakage
	# that can occur if a bad programmer does not destroy the reference
	# to this array after he is finished with it. If we do not make this copy
	# then the whole object would not be freed in this case.
	
	my @ret_errors = @{$self->{'_errors'}};

	if (@ret_errors) {
		return (undef, \@ret_errors);
	}
	else {	
		return ($out, \@ret_errors);
	}
}

##############################################################################
#####################   	PRIVATE METHODS  		##########################
##############################################################################

# "compiles" the array of allowed/denied tags
# resolves tag classes and merges them with individualy specified tags

sub _pair_compile {
	my $self = shift;
	my $tagclasses = shift;		# reference to predefined tag classes
	my @allow;
	my @deny;
	
	if ($self->{'mode'} eq "allow") {	
		# allow mode = error if any not explicitely allowed tag is found
		my $allowclass;
		foreach $allowclass (@{$self->{'allowclasses'}}) {
			push(@allow,@{$tagclasses->{$allowclass}})
		}
		my $tag;
		foreach $tag (@{$self->{'allowtags'}}) {
				push (@allow, $tag) if (not grep (($_ eq $tag), @allow));	
		}
		$self->{'debug'} and 
			warn('HTML::CGIChecker DEBUG: @allow = '.join(",", @allow));
	}
	elsif ($self->{'mode'} eq "deny") {
		# deny mode = error if any denied tag is found, everything other is OK
		my $denyclass;
		foreach $denyclass (@{$self->{'denyclasses'}}) {
			push (@deny, @{$tagclasses->{$denyclass}}) 
		}
		my $tag;
		foreach $tag (@{$self->{'denytags'}}) {
				push (@deny, $tag) if (not grep (($_ eq $tag), @deny));
		}		
		$self->{'debug'} and
			warn('HTML::CGIChecker DEBUG: @deny = '.join(",", @deny));
	}
	else {
		croak('HTML::CGIChecker - mode has to be either "allow" or "deny".')
	}

	# store refs to the compiled arrays
	$self->{'_allow'} = \@allow;
	$self->{'_deny'} = \@deny;
}


# Processes the current element.
# NOTE: The order in which these methods are called matters !

sub _process_element {
	my $self = shift;
	$self->_http();		
	$self->_imgtolink();
	$self->_quoting();
	$self->_javascript();
	$self->_check_attribs();	
	$self->_pair_saveinfo();
	$self->_allowed_tags();
}


# implements the check_http option

sub _http {
	my $self = shift;
	if ($self->{'check_http'}) {
		$self->{'_element'} =~ s!
					  ^<		
					  (.+)				# 1		
					  (href|src)\s*=\s*	# 2; MSIE allows the spaces ..
					  (")?				# 3 "
					  (.*?)				# 4
					  (".*>|\s.*>|>)$	# 5 "
				 	 !<$1$2=$3http://$4$5!six if 
					($self->{'_element'} !~ 
					   m!
					 	(http://
						|mailto:
						|ftp://
						|telnet://
						|file://
						)
						!xis);
	}
}


# implements the img_to_link option

sub _imgtolink {
	my $self = shift;
	if ($self->{'img_to_link'}) {
		$self->{'_element'} =~ s!
		  	  ^<
		  	  img.+src\s*=\s*	# MSIE allows the spaces ..
		  	  "?				# "
		  	  (.*?)				# $1
			  (".*>|\s.*>|>)$	# "
			 		 !<a href="$1">$1</a>!six;
	}
}


# checks the element for correct quoting

sub _quoting {
	my $self = shift;
	if ($self->{'_element'} =~ tr/"/"/ % 2) {
		push (@{$self->{'_errors'}}, 
			$self->_parse_error ($self->{'err_quote'}));
	}
}


# checks the element for a javascript

sub _javascript {
	my $self = shift;
	if (not $self->{'jscript'}) {
		if ($self->{'_element'} =~ /javascript/i or
			$self->{'_element'} =~ /\son\w+\s*=/i) {
				push (@{$self->{'_errors'}}, 
					$self->_parse_error ($self->{'err_javascript'}));
		}
	}
}


sub _check_attribs {
	my $self = shift;
	my $element = $self->{'_element'};
	
	if (ref($self->{'check_attribs'}->{$self->{'_abstag'}})) {
		$element =~ s/^<\w+\s*//s;
		$element =~ s|/?>$||;
		my @pairs = split(/\s+/, $element);
		my $pair;
		foreach $pair (@pairs) {
			my ($attrib) = split(/=/, $pair);
			$attrib = uc($attrib);
			if (not grep($attrib eq $_, 
				@{$self->{'check_attribs'}->{$self->{'_abstag'}}})) {
				$self->{'_attrib'} = $attrib;
				push (@{$self->{'_errors'}}, 
				$self->_parse_error ($self->{'err_attrib'}));
			}
		}
	}	
}


# Works with counters of tags, so we can later say if there are some tags that
# are not correctly either closed or opened.
# This implementation prevents a user to place a closing tag before the opening
# one and thus make the checker to think it was correctly closed.

sub _pair_saveinfo {
	my $self = shift;
	
	if (index($self->{'_tag'}, '/') == 0) {
	    # this is a closing tag
		if (not grep ( ($_ eq $self->{'_abstag'}), 
				  @{$self->{'nonpairtags'}})) { 
			if ($self->{'_opentags'}->{$self->{'_abstag'}}) { 
				$self->{'_opentags'}->{$self->{'_abstag'}}--;
			}
			else {
				$self->{'_closetags'}->{$self->{'_abstag'}}++;
			}
		}
	}
	elsif (not grep ( ($_ eq $self->{'_abstag'}), 
				  @{$self->{'nonpairtags'}})) {
		# this is an opening tag
		$self->{'_opentags'}->{$self->{'_abstag'}}++;
	}
}


# checks if a given tag is allowed

sub _allowed_tags {
	my $self = shift;
	if ($self->{'mode'} eq "allow") {
		grep ( ($_ eq $self->{'_abstag'}), @{$self->{'_allow'}}) or
			push (@{$self->{'_errors'}}, 
				$self->_parse_error ($self->{'err_tag'}));
	} else {
		grep ( ($_ eq $self->{'_abstag'}), @{$self->{'_deny'}}) and
			push (@{$self->{'_errors'}},
				$self->_parse_error ($self->{'err_tag'}));	
	}
}


# processes the error messages

sub _parse_error {
	my $self = shift;
	my ($error) = @_;
	my $element = $self->{'_element'};
	my $tag = $self->{'_tag'};
	my $attrib = $self->{'_attrib'};

	if ($self->{'html'}) {
		$element = $self->_html_escape ($element);
		$tag = '<strong>&lt;' . $tag . '&gt;</strong>';
		$element = '<strong>' . $element . '</strong>';
		$attrib = '<strong>' . $attrib . '</strong>';
	}
	else { $tag = "<$tag>" }

	$error =~ s/{tag}/$tag/;
	$error =~ s/{element}/$element/;
	$error =~ s/{attrib}/$attrib/;	
	$error =~ s/\n+|\r+|\s+/ /g;	
	return $error;
}


# raises an error if a badly paired tag is found

sub _pair_check {
	my $self = shift;
	my ($Tags, $error) = @_;
	my ($count);
	
	while ( ($self->{'_tag'}, $count) = each (%{$Tags})) {
		if ($count)	{
			push (@{$self->{'_errors'}}, 
					$self->_parse_error ($error));
		}
	}
}


# Escapes some dangerous characters.
# Ampersand "&" is escaped only if it is not part of a HTML entity.
# Therefore, users can post HTML entities. Ampersands that are part
# of an ordinary text are still properly escaped.
# Thanks to godless@hermes.slipstream.com for this idea.

sub _html_escape {
	my $self = shift;
	my ($in) = @_;

	for ($in) {	
	    s/&(?!\w+;)/&amp;/g;
		s/>/&gt;/g;
		s/</&lt;/g;
		s/"/&quot;/g;
	}
	return $in;
}


1;
