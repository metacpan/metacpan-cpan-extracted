package JQuery::ClickMenu ; 

our $VERSION = '1.00';

use strict ;
use warnings ; 

use XML::Writer ;
use IO::String ;
use JQuery::CSS ; 

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
    die "No id defined for ClickMenu" unless $my->{param}{id} =~ /\S/ ; 

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

sub packages_needed { 
    my $my = shift ;
    return ('taconite/jquery.taconite.js','clickmenu/jquery.clickmenu.js') ; 
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
    my $htmlResult ; 
    my $writer = $my->{writer} ;

    $writer->startTag("div", "id" => "${id}HEADER") ; 
    $writer->startTag("ul", "id" => $id) ;
    
    my @stack ; 
    my $type ; 
    for my $line (@lines) { 
	my ($spaces) = $line =~ m!^(\s*)! ; 
	$line =~ s!^\s+!! ; 
	my $indent = length($spaces) ;
	@stack = @stack[0..$indent-1] ; 
	$type = 'leaf' ; 
	my $state = '' ;
	$my->closeNodes($indent) ;
	if ($line =~ m!\(s\)!) { 
	    $type = "separator" ;
	} 
	if ($line =~ m!^(.*)(\([f]+\))$!) {   
	    $line = $1 ; 
	    $line =~ s!\s+$$!! ; 
	    my $options = $2 ; 
	    $type = 'node' ; 
	    push @{$my->{stack}},"$indent $line" ; 
	} 
	push @stack,$line ; 
	$my->produce($line,$type,$state,\@stack) ;
    }
    $my->closeNodes(0) ;
    $writer->endTag() ;
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

    if ($nodeType eq 'separator') {
	$writer->startTag("li", class => 'sep');
	$writer->startTag("div");
	$writer->endTag ; # Just to stop HTML errors  
	$writer->endTag('li') ; 
    } 
    if ($nodeType eq 'leaf') { 
	$writer->startTag("li");
	#$writer->emptyTag('img',src=>"$my->{fileDir}/treeview/images/file.gif") if $type eq 'directory' ; 
	my $underline = '' ;
	
	$writer->characters($line) ; 
	$writer->startTag('a', href => $stackLine) ;
	$writer->endTag("a") ; 
	$writer->endTag("li") ;
    }
    if ($nodeType eq 'node') { 
	$writer->startTag("li");
	#$writer->emptyTag('img',src=>"$my->{fileDir}/treeview/images/folder.gif") if $type eq 'directory' ; 
	my $underline = '' ;
	
	$writer->characters($line) ; 
	$writer->startTag("ul");
    }
} 

sub get_css { 
    my $my = shift ;
    my $id = $my->id ; 
    # The css has urls which are not correct
    # So, just use the css file and override the urls afterwards
    

    my $css1 = new JQuery::CSS( file => "$my->{fileDir}/clickmenu/clickmenu.css") ; 

    my $css2 =<<'EOD';
html>body div.shadowbox1
{
	background: url(PLUGIN_DIR/clickmenu/myshadow.png) no-repeat right top;
}

html>body div.shadowbox2
{
	background: url(PLUGIN_DIR/clickmenu/myshadow.png) left bottom;
}

html>body div.shadowbox3
{
	background: url(PLUGIN_DIR/clickmenu/myshadow.png) no-repeat right bottom;
}
EOD
    $css2 =~ s!PLUGIN_DIR!$my->{fileDir}!g ;

    my $css3 =<<'EOD';
body
{
	margin: 0;
	font-family: Verdana, Arial, Helvetica, sans-serif;
}
EOD

    my $css4 =<<'EOD';
#IDHEADER
{
	border-bottom: 1px solid gray;
	padding: 0 0 0 5px;
	z-index: 10;
	background-color: #eee;
}
#IDHEADER div.cmDiv
{
	border: 0;
}
#IDHEADER li.main.hover
{
	background-color: #dedede;
}
#IDHEADER li.main li.hover
{
	background-color: #4a93e3;
}
EOD

    my $css5 =<<'EOD';
li.sep
{
	border-top: 1px solid gray;
	margin: 2px 0;
	height: 0px;
	//fmargin-bottom: 0px; /* ie */
	//font-size: 0; /* ie */
	//float: left; /* ie */
	//width: 100%; /* ie */
}
EOD

    my $css6 =<<'EOD';
#IDHEADER
{
        position: fixed;
	top: 0;
	border: 0;
	width: 100%;
}
EOD

    $css4 =~ s!ID!$my->{param}{id}!g ; 
    $css6 =~ s!ID!$my->{param}{id}!g ; 
    if (!$my->{param}{headerMenu}) { 
	$css6 = '' ; 
    }  
    # css4 needs to be at the end, otherwise the border does not show.
    return [$css1,$css2,$css3,$css5,$css6,$css4] ; 

} 

#$("#ID").clickMenu({onClick:function(){
#    $.post("PROGRAM_TO_RUN", { date: new Date().getTime(), data: $(this).text(), path: $(this).next().text() RM } );
#}});
#$.post("PROGRAM_TO_RUN", { date: new Date().getTime(), data: $(this).text(), path: $(this).find("span").attr("value") RM } );
#$('#ID').clickMenu({arrowSrc:'arrow_right.png'})
sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 
    my $function =<<'EOD';
        $('#ID').clickMenu({
                arrowSrc:'PLUGINS_DIR/clickmenu/arrow_right.gif', 

                onClick:function(){
		var a = $(this).find('>a');
		if ( a.length )
		{
			//close the menu
			//alert($(this).text() + ' was clicked ' + a.attr('href') );
			$('#ID').trigger('closemenu');
                        $.post("PROGRAM_TO_RUN", { date: new Date().getTime(), data: $(this).text(), path: a.attr('href') , rm: 'MyClickMenu' } );
		}
		return false; //stop default action
	}});
EOD
    $function =~ s/#ID/#$id/g ; 
    $function =~ s/PROGRAM_TO_RUN/$remoteProgram/ ; 
    $function =~ s/PLUGINS_DIR/$my->{fileDir}/g ; 
    my $rm = ", rm: '$my->{param}{rm}'" ;
    $rm = '' unless $my->{param}{rm} =~ /\S/ ; 
    $function =~ s/RM/$rm/ ;
    $function = '' unless $remoteProgram =~ /\S/ ; 
    return $function ; 
}
1;
=head1 NAME

JQuery::ClickMenu - A clickable menu

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

JQuery::ClickMenu is a desktop style menu. 

    use JQuery;
    use JQuery::ClickMenu ; 
 my $list =<<EOD;
 File(f)
  Menu1
  sep(s)
  Menu2
 Options(f)
  Menu1
  sep(s)
  Menu2
  SubMenu(f)
   Submenu1
   Submenu2
 EOD

 my $clickmenu = JQuery::ClickMenu->new(list => $list, 
				  id => 'myclickmenu',
				  headerMenu => 1,
				  separator => '/',
				  addToJQuery => $jquery,
				  rm => 'MyClickMenu',
				  remoteProgram => '/cgi-bin/jquery_clickmenu_results.pl') ; 
 my $html = $clickmenu->HTML ;
 my $html = $tree->HTML ;
    
=head1 DESCRIPTION

ClickMenu displays a menu in desktop format

The simplest way to present the data is in the format shown
above. Each indentation represents another level. The letters in brackets stand for

=over 

=item f

A folder or node

=item s

A separator line between items

=item list

The list in the format show above

=item id

The css id of the element

=item separator

When an item is pressed, the it and all ancestors are concatenated and
sent to the calling program.  The item called 'data' contains just the
data as shown at the leaf or node. 'path' gives the whole path, each
element being separated by the separator.

In other words, you might get data=myfile, and path=dir/dir1/dir2/myfile

=item addToJQuery

The JQuery container

=item rm
This is the runmode to be used when running an external program

=item remoteProgram
This is the name of the remote program to be used when an item is pressed.

=item headerMenu 

Sets the menu flush at the top with the following css:

        position: fixed;
	top: 0;
	border: 0;
	width: 100%;

=back

=head1 FUNCTIONS

=over

=item new

Instantiate the object

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

1; # End of JQuery::ClickMenu

