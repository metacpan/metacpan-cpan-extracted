package JQuery::Treeview ; 

our $VERSION = '1.01';

use strict ;
use warnings ; 

use XML::Writer ;
use IO::String ;

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
    die "No id defined for Treeview" unless $my->{param}{id} =~ /\S/ ; 

    my $jquery = $my->{param}{addToJQuery} ; 
    my $jqueryDir = $jquery->getJQueryDir ; 
    $my->{fileDir} = "$jqueryDir/plugins" ;
    $my->{param}{separator} = "/" unless defined $my->{param}{separator} ; 
    bless $my, $class;
    $my->add_to_jquery ; 
    return $my ;
}

sub add_to_jquery { 
    my $my = shift ; 
    my $jquery = $my->{param}{addToJQuery} ; 
    if (defined $jquery) { 
	$jquery->add($my) ; 
    } 
} 

sub id {
    my $my = shift ;
    return $my->{param}{id} ; 
}

sub type {
    my $my = shift ;
    return $my->{param}{type} ; 
}

sub treeControlId {
    my $my = shift ;
    return $my->{param}{treeControlId} ; 
}

sub debug {
    my $my = shift ;
    return $my->{param}{debug} ; 
}

sub defaultState {
    my $my = shift ;
    return $my->{param}{defaultState} ; 
}

sub highlightUnderline {
    my $my = shift ;
    return $my->{param}{highlightUnderline} ; 
}

sub packages_needed { 
    my $my = shift ;
    return ('taconite/jquery.taconite.js','interface/interface.js','treeview/jquery.treeview.js','cookie/jquery.cookie.js') ; 
} 

sub HTMLControl {
    my $my= shift ;
    my $treeControlText = $my->{param}{treeControlText} ; 
    my $treeControlId =  $my->{param}{treeControlId} ; 
    my $html =<<EOD;
	<div id="$treeControlId">
		<a href="#">$treeControlText->[0]</a>
		<a href="#">$treeControlText->[1]</a>
		<a href="#">$treeControlText->[2]</a>
	</div>
EOD
    return $html ;
}

sub HTML {
    my $my= shift ;

    my $output = new IO::String;
    $my->{writer} = new XML::Writer(OUTPUT => $output, DATA_INDENT=>1,DATA_MODE=>1,UNSAFE=>1 );

    my $id = $my->id ; 
    my $list = $my->{param}{list} ; 
    my $lastIndent = 0 ;
    my @lines = split(/\n/,$list) ; 
    chomp @lines ; 
    my $type = $my->type ; 
    my $htmlResult ; 
    my $writer = $my->{writer} ;

    if ($type eq 'directory') { 
	$writer->startTag("ul", "id" => $id, "class" => "directory") ;
    }
    if ($type ne 'directory') { 
	$writer->startTag("ul", "id" => $id) ;
    }


    my @stack ; 

    for my $line (@lines) { 
	my ($spaces) = $line =~ m!^(\s*)! ; 
	$line =~ s!^\s+!! ; 
	my $indent = length($spaces) ;
	@stack = @stack[0..$indent-1] ; 
	$type = 'leaf' ; 
	my $state = '' ;
	$my->closeNodes($indent) ;
	if ($line =~ m!^(.*)(\([foc]+\))$!) {   
	    $line = $1 ; 
	    $line =~ s!\s+$$!! ; 
	    my $options = $2 ; 
	    
	    $state = 'closed' if $options =~ /c/ ;  
	    $state = 'open' if $options =~ /o/ ; 

	    $type = 'node' ; 
	    push @{$my->{stack}},"$indent $line" ; 
	} 
	push @stack,$line ; 
	$my->produce($line,$type,$state,\@stack) ;
    }
    $my->closeNodes(0) ;
    $writer->endTag() ;
    $writer->end();
    my $htmlRef = $output->string_ref ;
    my $html = $$htmlRef ;
    $output->close();
    return $html ;
}

sub closeNodes { 
    my $my = shift ;
    my $writer = $my->{writer} ;
    my $n = shift ;
    return if $n < 0 ;
    while(1) { 
	my $pop = pop(@{$my->{stack}}) ; 
	last if ! defined $pop ; 
	my ($ind,$line) = split(' ',$pop,2) ; 
	if ($ind < $n) { 
	    push @{$my->{stack}},$pop ; 
	    last ; 
	} 
	$writer->endTag("ul");
	$writer->endTag("li");
    } 
} 

sub produce { 
    my $my = shift ;
    my $writer = $my->{writer} ;

    my $line = shift ;
    my $nodeType = shift ; 
    my $state = shift ; 
    my $stack = shift ; 
    my $separator = $my->{param}{separator} ;
    
    my $stackLine = join($separator,grep {defined} @$stack) ; 

    my $type = $my->type ; 
    my $highlightLeaves = $my->highlightLeaves ; 
    my $highlightNodes = $my->highlightNodes ; 
    my $defaultState = $my->defaultState ; 

    if ($nodeType eq 'leaf') { 
	$writer->startTag("li");
	$writer->emptyTag('img',src=>"$my->{fileDir}/treeview/images/file.gif", alt=>"file") if $type eq 'directory' ; 
	my $underline = '' ;
	
	$underline = "text-decoration: underline" if $my->highlightUnderline ; 

	$writer->startTag('span',style=>"cursor: pointer; $underline") if $highlightLeaves ; 
	$writer->characters($line) ; 
	$writer->endTag('span') if $highlightLeaves ;
	$writer->startTag('div', class => "hidden") ;
	$writer->characters($stackLine) ; 
	$writer->endTag("div") ; 
	$writer->endTag("li") ;
    }
    if ($nodeType eq 'node') { 
	if (defined $state and $state eq $defaultState) {
	    $writer->startTag("li");
	} else { 
	    $writer->startTag("li", class=> $state);
	} 
	$writer->emptyTag('img',src=>"$my->{fileDir}/treeview/images/folder.gif",alt=>"folder") if $type eq 'directory' ; 
	my $underline = '' ;
	$underline = "text-decoration: underline" if $my->highlightUnderline ; 

	$writer->startTag('span',style=>"cursor: pointer; $underline") if $highlightNodes ; 
	$writer->characters($line) ; 
	$writer->endTag('span') if $highlightNodes ;
	$writer->startTag('div', class => "hidden") ;
	$writer->characters($stackLine) ; 
	$writer->endTag("div") ; 
	$writer->startTag("ul");
    }
} 

sub highlightLeaves { 
    my $my = shift ;
    return $my->{param}{highlightLeaves} ; 
} 

sub highlightNodes { 
    my $my = shift ;
    return $my->{param}{highlightNodes} ; 
} 

sub get_css { 
    my $my = shift ;
    my $id = $my->id ; 
    my $type = $my->type ;
    # generate the css according to the id name and type
    my $css=<<'CSS';
		.treeview, .treeview ul { 
			padding: 0;
			margin: 0;
			list-style: none;
		}	

		.treeview li { 
			margin: 0;
			padding: 3px 0pt 3px 16px;
		}
		
		ul.directory li { padding: 2px 0 0 16px; }
		
CSS

      my $cssDir =<<CSS1 ;
	  	#ID.treeview li { background: url($my->{fileDir}/treeview/images/tv-item.gif) 0 0 no-repeat; }
	  	#ID.treeview .collapsable { background-image: url($my->{fileDir}/treeview/images/tv-collapsable.gif); }
	  	#ID.treeview .expandable { background-image: url($my->{fileDir}/treeview/images/tv-expandable.gif); }
	  	#ID.treeview .last { background-image: url($my->{fileDir}/treeview/images/tv-item-last.gif); }
	  	#ID.treeview .lastCollapsable { background-image: url($my->{fileDir}/treeview/images/tv-collapsable-last.gif); }
	  	#ID.treeview .lastExpandable { background-image: url($my->{fileDir}/treeview/images/tv-expandable-last.gif); }
	  	
	  	#treecontrol { margin: 1em 0; }

CSS1
      my $cssColor=<<CSS2;
                #ID.treeview li { background: url($my->{fileDir}/treeview/images/TYPE/tv-item.gif) 0 0 no-repeat; }
                #ID.treeview .collapsable { background-image: url($my->{fileDir}/treeview/images/TYPE/tv-collapsable.gif); }
                #ID.treeview .expandable { background-image: url($my->{fileDir}/treeview/images/TYPE/tv-expandable.gif); }
                #ID.treeview .last { background-image: url($my->{fileDir}/treeview/images/TYPE/tv-item-last.gif); }
                #ID.treeview .lastCollapsable { background-image: url($my->{fileDir}/treeview/images/TYPE/tv-collapsable-last.gif); }
                #ID.treeview .lastExpandable { background-image: url($my->{fileDir}/treeview/images/TYPE/tv-expandable-last.gif); }

CSS2
      if ($type eq 'directory') { 
         $cssDir =~ s/ID/$id/g ; 
         return $css . $cssDir  ; 
      } 
      if ($type =~ /^(red|gray|black)$/) { 
         $cssColor =~ s/ID/$id/g ; 
         $cssColor =~ s/TYPE/$type/g ; 
         return $css . $cssColor ; 

      } 
} 

sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 
    return '' unless $id =~ /\S/ ; 
    my $treeControlId = $my->treeControlId ; 
    my $function1 =<<'EOD1';
	
$("#ID").Treeview(TREE_CONTROL);
EOD1
    my $treeControl = '' ; 
    if ($treeControlId =~ /\S/) { 
	$treeControl = qq[{ control: "#$treeControlId" }] ;
    } 
    $function1 =~ s/TREE_CONTROL/$treeControl/ ; 

    my $function2 =<<'EOD2';
$("#ID span").click(function(event) { 
    ALERT
    $.post("PROGRAM_TO_RUN", { date: new Date().getTime(), data: $(this).text(), data1: $(this).next().text() RM } );
    event.stopPropagation();
    });
EOD2
    my $function3=<<'EOD';
$(".hidden").hide() ; 
EOD

    my $alert = q[alert('Button clicked ' + $(this).text())] ;
    $alert = '' if $my->debug == 0 ; 
    $function2 =~ s/^\s*ALERT/$alert/m ;
    $function1 =~ s/#ID/#$id/ ; 
    $function2 =~ s/#ID/#$id/ ; 
    $function2 =~ s/PROGRAM_TO_RUN/$remoteProgram/ ; 
    my $rm = ", rm: '$my->{param}{rm}'" ;
    $rm = '' unless $my->{param}{rm} =~ /\S/ ; 
    $function2 =~ s/RM/$rm/ ;
    $function2 = '' unless $remoteProgram =~ /\S/ ; 
    my $function4 = $my->dragAndDrop ;
    
    return $function1 . $function2 . $function3 . $function4 ; 
}
1;
=head1 NAME

JQuery::Treeview -  shows a information as a tree. 

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

JQuery::Treeview shows a information as a tree. 

    use JQuery;
    use JQuery::Treeview;

    my $list =<<EOD;
 folder 1(fc)
  file 1.1
  file 1.2 
  file 1.3
  folder 1.2(f)
   file 2.1
   file 2.2 
   file 2.3
   folder 1.3(fc)
    folder 1.4(f)
   file 1.4 
 folder 2(f)
  file 2.1
 folder 3(f)
 EOD

   my $tree = JQuery::Treeview->new(list => $list, 
				 id => 'mytree',
                                 separator => "/",
				 addToJQuery => $jquery,
				 treeControlId => 'myTreeControl',
				 treeControlText => ['Collapse All','Expand All','Toggle All'],
				 defaultState => 'open', 
				 highlightNodes => 1, 
				 highlightLeaves => 1, 
				 highlightUnderline => 1,
				 type => 'directory',
				 rm => 'MyTreeView',
				 debug => 0,
				 remoteProgram => '/cgi-bin/jquery_treeview_results.pl') ; 
    my $htmlControl = $tree->HTMLControl ;
    my $html = $tree->HTML ;
    
=head1 DESCRIPTION

Treeview shows data in a tree format. For an example see L<http://jquery.bassistance.de/treeview/>

The simplest way to present the data is in the format shown
above. Each indentation represents another level. The letters in brackets stand for

=over 

=item f

A folder or node

=item c

The node is initially closed

=item o

The node is initially open

=back

(Putting all this information in a Perl array with embedded hashes is
possible, but really ugly, and hard to debug visually. I tried, but didn't like the result.)

The other parameters are:

=over

=item list

The list in the format show above

=item id

The css id of the element

=item separator

When an item is pressed, the it and all ancestors are concatenated and
sent to the calling program.  The item called 'data' contains just the
data as shown at the leaf or node. 'data1' gives the whole path, each
element being separated by the separator.

In other words, you might get data=myfile, and data1=dir/dir1/dir2/myfile

=item addToJQuery

The JQuery container

=item treeControlId 

The id of a control element. JQuery::Treeview can
generate the control HTML, which is just a set of links allowing the
user to manipulate the tree. The user can collapse all, expand all, and toggle all.

=item treeControlText

These are the text items needed for the treeControlId

=item defaultState

The default state of the tree, either open or closed.

=item highlightNodes

If highlightNodes is set, then nodes will be underlined

=item highlightLeaves

If highlightLeaves is set, then the leaves will be underlined

=item type

If type is 'directory', the folder and file icons will be used in the display.
If the type is gray, red or black no icons are used.

=item rm

This is the runmode to be used when running an external program

=item remoteProgram

This is the name of the remote program to be used when an item is pressed.

=back

=head1 FUNCTIONS

=over 

=item new

Instantiate the object.

=item HTML

Produce the HTML code

=item HTMLControl

Produce the HTML code for the control

=back 

=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jquery-taconite at rt.cpan.org>, or through the web interface at
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

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Gordon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of JQuery::Treeview

