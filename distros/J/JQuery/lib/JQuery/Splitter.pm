package JQuery::Splitter ; 

our $VERSION = '1.00';

use warnings;
use strict;

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
    die "No id defined for Splitter" unless $my->{param}{id} =~ /\S/ ; 
    my $jquery = $my->{param}{addToJQuery} ; 
    my $jqueryDir = $jquery->getJQueryDir ; 
    $my->{fileDir} = "$jqueryDir/plugins/splitter" ;
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
    return ('dimensions/dimensions.js','splitter/splitter.js') ; 
} 

sub panel1 { shift->{param}{panel1} }
sub panel2 { shift->{param}{panel2} ; }
sub panel1CSS { shift->{param}{panel1CSS} }
sub panel2CSS { shift->{param}{panel2CSS} ; }
sub HTML1 { shift->{param}{HTML1} ; }
sub HTML2 { shift->{param}{HTML2} ; }
sub splitBackGround { shift->{param}{splitBackGround} ; }
sub splitHeight { shift->{param}{splitHeight} ; }
sub splitActive { shift->{param}{splitActive} ; }
sub splitRepeat { shift->{param}{splitRepeat} ; }
sub mainPanelCSS { shift->{param}{mainPanelCSS} ; }
sub accessKey { shift->{param}{accessKey} ; }
sub browserFill { shift->{param}{browserFill} ; }
sub type { shift->{param}{type} }
sub panel1Params { shift->{param}{panel1Params} }
sub panel2Params { shift->{param}{panel2Params} }
sub internalPanel { shift->{param}{internalPanel} }

sub setHTML1 { 
    my $my = shift ;
    $my->{param}{HTML1} = shift ;
} 

sub setHTML2 { 
    my $my = shift ;
    $my->{param}{HTML2} = shift ;
} 

sub HTML { 
    my $my = shift ;
    my $id = $my->id ;
    my $panel1 = $my->panel1 ; 
    my $panel2 = $my->panel2 ; 
    my $HTML1 = $my->HTML1 ;
    my $HTML2 = $my->HTML2 ; 

    my $html ; 
    if ($my->internalPanel) { 
	$html = qq[<div id="$panel1">$HTML1</div>
                      <div id="$panel2">$HTML2</div>
                      ] ; 
    }
    if (!$my->internalPanel) { 
	$html = qq[<div id="$id">
                  <div id="$panel1">$HTML1</div>
                  <div id="$panel2">$HTML2</div>
                  </div>] ; 
    }
    return $html ; 
} 

sub get_css { 
    my $my = shift ;
    my $id = $my->id ; 
    my $splitBackGround = $my->splitBackGround || 'gray';
    my $splitHeight =  $my->splitHeight || '6px' ; 
    my $splitActive =  $my->splitActive || 'blue' ; 
    my $panel1 = $my->panel1 ; 
    my $panel2 = $my->panel2 ; 
    my $repeat = $my->splitRepeat ;
    my $repeatX = 'no-repeat' ; 
    my $repeatY = 'no-repeat' ;     
    if ($repeat) { 
	$repeatX = "repeat-x" ; 
	$repeatY = "repeat-y" ;
    } 


    my $headBodyMargins = '' ;

    my $scrollBarsHidden =<<EOD;
html, body
{
	overflow: hidden;	/* Remove scroll bars on browser window */
}
EOD

    if ($my->browserFill) { 
    $headBodyMargins =<<EOD;
html, body
{
	margin: 0;			/* Remove body margin/padding */
	padding: 0;
	overflow: hidden;	/* Remove scroll bars on browser window */
}
EOD
    }	

    my $bars1=<<EOD;
#$id .vsplitbar {
	width: $splitHeight;
	background: $splitBackGround url(PLUGINS_DIR/vgrabber.gif) $repeatY center;
}
#$id .vsplitbar.active, #$id .vsplitbar:hover {
	background: $splitActive url(PLUGINS_DIR/vgrabber.gif) $repeatY center;
}
#$id .hsplitbar {
	height: $splitHeight;
	background: $splitBackGround url( PLUGINS_DIR/hgrabber.gif) $repeatX center;
}
#$id .hsplitbar.active, #$id .hsplitbar:hover {
	background: $splitActive url(PLUGINS_DIR/hgrabber.gif) $repeatX center;
}
EOD


    my $bars2=<<EOD;
#$panel1 {				/* Top nested in right pane */
	overflow: auto;	
}
#$panel2 {
	overflow: auto;		/* Scroll bars appear as needed */
}
$headBodyMargins
EOD
    my $bars = $bars2 ; 
    if (!$my->internalPanel) { 
	$bars = "$bars1$bars2" ;
    } 
    $bars =~ s!PLUGINS_DIR!$my->{fileDir}!g ; 
    my @css = ($bars,$my->mainPanelCSS,$my->panel1CSS,$my->panel2CSS); 
    return \@css ; 
} 

 
sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ;
    my $type = $my->type ; 
    my $accessKey = $my->accessKey ; 
    my $panel1 = $my->panel1 ; 
    my $panel2 = $my->panel2 ; 
    my $panel1Params = $my->panel1Params ;
    my $panel2Params = $my->panel2Params ;
    
    $type = qq[type: "$type"] ; 
    my $minA = $panel1Params->{minA} =~ /\S/ ? qq[minA: $panel1Params->{minA}] : '' ; 
    my $initA = $panel1Params->{initA} =~ /\S/ ? qq[initA: $panel1Params->{initA}] : '' ; 
    my $maxA = $panel1Params->{maxA} =~ /\S/ ? qq[maxA: $panel1Params->{maxA}] : '' ; 

    my $minB = (defined($panel2Params->{minB}) and $panel2Params->{minB} =~ /\S/) ? qq[minB: $panel2Params->{minB}] : '' ; 
    my $initB = (defined $panel2Params->{initB} and $panel2Params->{initB} =~ /\S/) ? qq[initB: $panel2Params->{initB}] : '' ; 
    my $maxB = (defined $panel2Params->{maxB} and $panel2Params->{maxB} =~ /\S/) ? qq[maxB: $panel2Params->{maxB}] : '' ; 
    $accessKey = $my->accessKey =~ /\S/ ? qq[accessKey: "$accessKey"] : '' ; 
    my @items = ($type,$minA,$initA,$maxA,$minB,$initB,$maxB,$accessKey) ; 
    @items = grep { /\S/ } @items ; 

    my $params = join(', ',@items) ; 

    my $function1=<<'EOD'; 
$("#ID").splitter({PARAMS});
EOD
    $function1 =~ s/ID/$id/ ; 
    $function1 =~ s/PARAMS/$params/ ;

=pod

$("#ID").splitter({
	type: "v", 
	minA: 100, initA: 150, maxA: 300,
	accessKey: "|"
})

=cut 

    my $function2=<<'EOD';

	// Manually set the outer splitter's height to fill the browser window.
	// This must be re-done any time the browser window is resized.
	$(window).bind("resize", function(){
		var $ms = $("#ID");
		var top = $ms.offset().top;		// from dimensions.js
		var wh = $(window).height();
		// Account for margin or border on the splitter container
		var mrg = parseInt($ms.css("marginBottom")) || 0;
		var brd = parseInt($ms.css("borderBottomWidth")) || 0;
		$ms.css("height", (wh-top-mrg-brd)+"px");
		// IE fires resize for splitter; others don't so do it here
		if ( !jQuery.browser.msie )
			$ms.trigger("resize");
	}).trigger("resize");
EOD
    $function2 =~ s/#ID/#$id/ ; 
    $function2 = '' unless $my->browserFill ; 

    return $function1 . $function2  ; 
}
1;

=head1 NAME

JQuery::Splitter - Split into panes 

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

JQuery::Splitter is used to split an area into two panes. This can be
extended to three or more by nesting

    use JQuery;
    use JQuery::Splitter ;
    my $splitter1 = JQuery::Splitter->new(id => 'MySplitter', 
					  addToJQuery => $jquery,
					  browserFill => 1,
					  type => 'v',
					  HTML1 => $leftHTML, HTML2 => $rightHTML) ;


=head1 DESCRIPTION 

This module is a bit more complicated than others, since CSS needs to
be set to get good results. For complete information see L<http://methvin.com/jquery/splitter/>

    my $mainPanelCSS = new JQuery::CSS(hash => {'#MySplitter' => {'min-width' => '500px', 'min-height' => '300px', border => '4px solid #669'}}) ; 
    my $panel1CSS = new JQuery::CSS(hash => { '#LeftPanel' => {background => 'blue', padding => '8px'}}) ; 
    my $panel2CSS = new JQuery::CSS(hash => { '#RightPanel' => {background => 'yellow', padding => '4px'}}) ; 
    my $splitter1 = JQuery::Splitter->new(id => 'MySplitter', 
					  addToJQuery => $jquery,
					  browserFill => 1,
					  type => 'v', accessKey => "I",  panel1 => 'LeftPanel', panel2 => 'RightPanel',
					  mainPanelCSS => $mainPanelCSS,
					  panel1CSS => $panel1CSS,
					  panel2CSS => $panel2CSS,
					  panel1Params => {minA => 100, initA => 100, maxA => 1000},
                                          splitBackGround => 'pink',
                                          splitActive => 'red',
                                          splitHeight => '6px',
                                          splitRepeat => 1,
					  HTML1 => $leftHTML, HTML2 => $rightHTML) ;

Have a look at the splitter examples. 

=over 

=item addToJQuery

Add the item to JQuery

=item browserFill

Set this to 1 if you want the panel to fill the whole page

=item type

Set to h for horizontal split and v for vertical split

=item accessKey

Allows user access to a splitter bar through the keyboard

=item panel1

Give an id to the left/top panel

=item panel2 

Give an id to the right/bottom panel

=item mainPanelCSS

Define CSS for the main panel

=item panel1CSS

Define CSS for the left/top panel

=item panel2CSS

Define CSS for the right/bottom panel

=item panel1Params

=over

=item minA

Minimum size for the panel

=item initA

Initial size for the panel 

=item maxA

Maximum size for the panel 

=back

=item panel2Params

=over

=item minB

Minimum size for the panel

=item initB

Initial size for the panel 

=item maxB

Maximum size for the panel 

=back

=item splitBackGround

Define the colour for the background of the splitter bar

=item splitActive

Define the colour for the splitter bar when it is active

=item splitHeight

Define the size of the splitter bar

=item HTML1

Set the HTML for the top/left panel

=item HTML2

Set the HTML for the bottom/right panel

=item internalPanel

If panels are put one inside another, the internal panels must have
this flag set.  The splitter bars take all their definitions from the
outermost panel. That is, they cannot be changed.

=back

=head1 FUNCTIONS

=over

=item HTML

Get the HTML for the object

=item new

Instantiate the object

=item setHTML1

Set HTML1 for the object

=item setHTML2

Set HTML2 for the object

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

1; # End of JQuery::Taconite
