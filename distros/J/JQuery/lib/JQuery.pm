package JQuery;

use warnings;
use strict;

our $VERSION = '1.00';


#  The expected parameters
#   jqueryDir - the javascript directory
#   usePacked - use the compressed library if available

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my = {@_} ;
    $my->{usePacked} = 0 unless defined $my->{usePacked} ;
    $my->{useDump}  = 0 unless defined $my->{useDump} ;
    $my->{css} = [] ;
    $my->{csslast} = [] ;
    $my->{objectList} = [] ; 
    bless $my, $class;

    return $my ;
}

sub getJQueryDir { 
    my $my = shift ;
    return $my->{jqueryDir} ; 
} 


sub usePacked { 
    my $my = shift ; 
    return $my->{usePacked} ; 
} 

# Allow css to be set 
sub add_css { 
    my $my = shift ;
    my $css = shift ;
    push @{$my->{css}}, $css ; 
} 

sub add_css_last { 
    my $my = shift ;
    my $css = shift ;
    push @{$my->{csslast}}, $css ; 
} 

sub add { 
    my $my = shift ;
    my $object = shift ;
    push @{$my->{objectList}},$object ;
    my @packagesNeeded = $object->packages_needed($my->{usePacked})  ; 
    # Keep track of which packages to include in the header
    grep { $my->{packages}{$_} ++ } @packagesNeeded ; 

    return $object ;
} 

sub get_css {
    my $my = shift ;
    my $style ;
    for my $css (@{$my->{css}}) { 
	if ($css->can('output_text')) { 
	    $style .= $css->output_text ; 
	}
    }

    my @objects = @{$my->{objectList}} ;
    for my $object (@objects) { 
	my $id = $object->id ; 
	next unless $object->can('get_css') ; 
	my $css = $object->get_css ;
	# Either an object is returned or a string
	if (ref($css) =~ /\S/) { 
	    for my $c (@$css) { 
		if (ref($c) =~ /\S/) { 
		    $style .= $c->output_text($id) . "\n" ; 
		} else {
		    $style .= qq[<style type="text/css">\n] .  $c . "</style>\n" if $c =~ /\S/ ; # HTML Validator doesn't like empty styles
		}
	    }
	} else { 
	    $style .= qq[<style type="text/css">\n] .  $css . "</style>\n" if $css =~ /\S/;   # HTML Validator doesn't like empty styles
	} 
    } 
    for my $css (@{$my->{csslast}}) { 
	if ($css->can('output_text')) { 
	    $style .= $css->output_text ; 
	}
    }
    return $style ; 
}

sub get_jquery_code { 
    my $my = shift ; 
    my @packages = keys %{$my->{packages}} ; 
    my $jqueryDir = $my->{jqueryDir} ;
    my $pack = $my->{usePacked} ? ".pack" : "" ; 
    my $code = qq[<script type="text/javascript" src="$jqueryDir/jquery/jquery-latest${pack}.js"></script>] ."\n" ; 
    if ($my->{useDump}) { 
	push @packages,"dumper/jquery.dump.js" ; 
    }

    for my $package (@packages) { 
	$code .= qq[<script type="text/javascript" src="$jqueryDir/plugins/$package"></script>] . "\n" ; 
    } 

    $code .= qq[<script type="text/javascript">] . "\n";
    $code .= '$(document).ready(function() {' . "\n" ; 
					    
    my @objects = @{$my->{objectList}} ; 

    for my $object (@objects) {
	next unless $object->can('get_jquery_code') ; 
	$code .= $object->get_jquery_code . "\n"; 
    }
				 
    $code .= "});\n</script>\n" ;
    return  $code ;
} 

=head1 NAME

JQuery - Interface to Jquery, a language based on Javascript

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

JQuery provides some of the functionality provided by the JQuery language. 

    use JQuery;

    my $jquery = new JQuery(jqueryDir => '/jquery_js') ; 

    my $accordion = JQuery::Accordion->new(id => 'myAccordion',
				           headers => \@headers,
				           texts => \@texts,
				           panelHeight => 200,
				           panelWidth => '400px'
				           ) ;

    $jquery->add_css_last(new JQuery::CSS( hash => {'#myAccordion' => {width => '600px'}})) ; 

    my $data = [['Id','Total','Ip','Time','US Short Date','US Long Date'],
		['66672',  '$22.79','172.78.200.124','08:02','12-24-2000','Jul 6, 2006 8:14 AM'],
		['66672','$2482.79','172.78.200.124','15:10','12-12-2001','Jan 6, 2006 8:14 AM']
	       ] ;

    my $tableHTML = $jquery->Add(JQuery::TableSorter->new(id => 'table1', 
                                                          data => $data, 
                                                          headerClass => 'largeHeaders',
                                                          dateFormat=>'dd/mm/yyyy' ))->HTML ; 

    $jquery->add($accordion) ; 
    my $html = $accordion->HTML . $tableHTML ;
    my $jquery_code = $jquery->get_jquery_code ; 
    my $css = $jquery->get_css ; 
    
=head1 DESCRIPTION

JQuery is a frontend for the jQuery language.  I use B<JQuery> to
refer to the Perl part or the package, and B<jQuery> to reference
the javascript part or the package.

A quote from L<http://jquery.com>: jQuery is a fast, concise,
JavaScript Library that simplifies how you traverse HTML documents,
handle events, perform animations, and add Ajax interactions to your
web pages.

JQuery.pm is the main module. There are other modules such as Form,
TableSorter, Splitter, Taconite ..., all of which provide different
functionality. The main module needs to be instantiated, and each
instance of the other modules needs to be registered with the main
module.  It is then the responsibility of JQuery.pm to produce the
relevant HTML, css and javascript code. 

One of the objectives is to produce javascript functioniality with as
little user code as possible and to provide reasonable
defaults. "Reasonable" is of course in the sight of the beholder. Most
defaults are provided by css, and can be changed easily.

Another objective is to allow module writers to be able to add new
functionality within this framework.

=head2 Using JQuery

JQuery comes packaged with jQuery javascript files.  Since the
javascript directory is going to be needed by the web server, you will
probably need to copy the whole of the jquery_js directory to
somewhere the web server can access. Remember to change the web server
config file if necessary. 

=head2 JQuery::CSS

JQuery::CSS is a helper module that helps create CSS objects uses CSS
module from CPAN. 

CSS can be created in the following ways:

   my $css = new JQuery::CSS(text => 'body {font-family: Arial, Sans-Serif;font-size: 10px;}') ;

   my $css = new JQuery::CSS( hash => {
				    '.odd' => {'background-color' => "#FFF"} , 
				    '.even' => {'background-color' => "#D7FF00"} , 
				     }) ; 

   my $css = new JQuery::CSS(file => 'dates/default.css') ;

=over 8

=item text

The "text" form allows plain text to be used to create the CSS object.

=item hash

The "hash" form allows a Perl hash to be used.

=item file

The "file" form allows a file to be specified. 

=back

=head2 Initialization

JQuery needs to be initialized.

    my $jquery = new JQuery(jqueryDir => '/jquery_js', usePacked => 1) ; 

The parameter jqueryDir specifies where the javascript files can be found.
When using a web server, this refers to the directory defined by the web server.

If usePacked is set, the compressed jQuery files are used if available.

=head2 Adding CSS

    CSS objects can be added to JQuery using 
        $jquery->add_css($css) 
    or 
        $jquery->add_css_last($css) 
        
    add_css outputs css before the css of the modules.  add_css_last
    outputs css after the css of the modules. This is useful if you
    want to change the default css supplied by the package.

=head2 Functions

=over 4

=item add

This adds a new object from JQuery::* to JQuery. Typically, this is used in a class
implementing new functionality, and adds the new class to the
controlling JQuery class. It is not normally called directly by the
user.

=item add_css

Add css to JQuery. All css elements added are installed before that of
css implemented by JQuery::*. This is used if the user wants to install CSS.

=item add_css_last

Similar to add_css, but the css gets added after the ccs implemented
by JQuery::*. This means that the css installed by JQuery::* can be
over-ridden by the user. Typically this would be used when changing
colours, urls, backgrounds etc.

=item getJQueryDir

All JQuery::* objects get passed the a variable pointing to
JQuery. Within JQuery::*, there may be a need to reference a path, eg
an image, and the base path can be modified by using this directory.

This parameter is the jqueryDir passed by 

    my $jquery = new JQuery(jqueryDir => '/jquery_js') ; 
  
=item get_css

This is normally called very late in the program when you want to
produce all the css. It goes though all css registered with JQuery,
then it gets all css registered by JQuery::* objects, and then it gets
the css added add_css_last. 

=item get_jquery_code

Similar to get_css, except that it produces the javascript to be
included in the page.

=item new

Used to instantiate the JQuery object. The path is the path seen by
the web browser, and not the local path.

    my $jquery = new JQuery(jqueryDir => '/jquery_js') ; 

=item usePacked

JQuery modules can come in an unpacked or packed form. The former is
the original source, while the second, although not compiled, is
highly dense and obfuscated, while being more efficient. 

=back

=head1 JQuery::Examples

There are a number of working examples in the cgi-bin directory, which
can be found in the Perl distribution under the JQuery directory. The
examples are mostly written using CGI::Application , so you will need
to install CGI-Application to run the examples. This is not a
restriction, as the modules will work using CGI and mod-apache as
well, and hopefully the framework of yor choice.

=head2 Demo.pm

The examples mostly use Demo.pm. This is a very simple module which 
initializes JQuery, calls get_jquery_code, get_css 

The module Demo.pm simply does some of the repetitive work. 

The setupfunction initiates $jquery.
cgiapp_postrun gets runs $jquery->get_jquery_code, $jquery->get_css and puts both of these, and
the HTML, into a very basic template.

=head2 Ajax

Let's start with the Ajax.

Suppose you have a button, not neccessarily in a form, and you want
some action to happen when the user presses the button.

Firstly, the JQuery module needs to be initialized.

  use JQuery ; 
  use JQuery::Taconite ; 
  my $jquery = new JQuery(jqueryDir => '/jquery_js') ; 

The button to be pressed needs an id, as it is going to accessed by javascript. So the HTML fragment could read:
   
  <input id="ex1" type="button" value="Run Example 1" />
 
  JQuery::Taconite->new(id => 'ex1', remoteProgram => '/cgi-bin/jquery_taconite_results.pl', rm => 'myRunMode', addToJQuery => $jquery) ; 

You may or may not need to set the run mode. CGI-Applications normally need
them, to define which function is to be executed in the CGI program.

When the button is pressed, some output will be shown, and a placeholder is needed to display the text.

The HTML fragment might be:
   
    <div id="example4" style="display:none; background-color: #ffa; padding:10px; border:1px solid #ccc"> 
    Initially this div is hidden. 
    </div>

This is a div where, initially, the text is not shown.


=head1 Example Programs

=over 

=item jquery_accordion.pl

Shows an example of an accordion

=item jquery_clickmenu.pl

An example of a menu in a normal desktop application

Shows an example of an accordion

=item jquery_form.pl 

This is a small example showing how a from is constructed, and how the
Ajax reply is sent, causing only the specified fields to be updated.

=item jquery_splitter1.pl, jquery_splitter2.pl, jquery_splitter3.pl

Examples showing how to split an area into two or three panes with a
bar allowing the user to resize them.

=item jquery_tabs1.pl jquery_tabs2.pl jquery_tabs_results.pl

Examples showing a tabbing of a pane. When the tab is pressed a
different page is shown. The user can download the page remotely from
a server.

=item jquery_taconite1.pl and jquery_taconite_results1.pl jquery_taconite2.pl

Taconite is a word that doesn't sound very interesting, but this
module allows you update your screen very easily without needing to
know anything about the DOM. This is Ajax at its easiest. You really
want to use this.

jquery_taconite1.pl sets up the page and jquery_taconite_results1.pl
does the reply. This example show a variety of things to do with
Taconite, by adding radio buttons, wiring a button on the fly, adding
and removing items. 

=item jquery_taconite2.pl

jquery_taconite2.pl does the same sort of thing as
jquery_taconite1.pl, except that it uses a run mode to define the
reply.

Examples of split windows with a bar for resizing

=item jquery_treeview.pl

Show an expandable tree. You can choose grid lines or folder icons. 

=item jquery_heartbeat.pl

Show how to update a page every second.

=back

=head1 WRITING NEW MODULES

A module needs to provide the following methods

new - to create the object 

id - the id of the object. There are some modules that don't need this. This only happens in the case of where an instance does not have any css related to the id.

get_css - returns the css for the instance. The return value may be an array reference. css may be plain text or a JQuery:CSS object.

HTML - returns the HTML text for the instance

packages_needed - returns a list of jquery packages needed for the javascript to run

get_jquery_code - returns the jQuery code


=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

=head1 ACKNOWLEDGMENTS

Thanks to Brent Pedersen for pointing me in the direction of JQuery and to all 
contibutors to jQuery from whom css/images/whatever have been plagiarized. 

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jquery at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JQuery>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JQuery

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JQuery>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/JQuery>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Gordon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of JQuery
