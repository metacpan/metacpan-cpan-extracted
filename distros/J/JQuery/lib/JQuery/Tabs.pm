package JQuery::Tabs ; 

our $VERSION = '1.00';

use warnings;
use strict;
use CGI::Util ; 

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 

    $my->{param}{texts} = [] if ! defined $my->{param}{texts} ;  
    $my->{param}{tabs} = [] if ! defined $my->{param}{tabs} ; 
    $my->{param}{remote} = 0 if  ! defined $my->{param}{remote} ; 

    die "No id defined for Tabs" unless $my->{param}{id} =~ /\S/ ; 

    bless $my, $class;
    if ($my->{param}{css}) { 
	push @{$my->{css}},$my->{param}{css} ; 
    } 
    my $jquery = $my->{param}{addToJQuery} ; 
    $my->{param}{history} = 0 unless defined $my->{param}{history} ;
    my $jqueryDir = $jquery->getJQueryDir ; 
    $my->{fileDir} = "$jqueryDir/plugins" ;

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
    my @packages = ('tabs/jquery.tabs.js') ; 
    push @packages,'history_remote/jquery.history_remote.js' if $my->{param}{history} ; 
    return @packages ;
} 

sub get_css { 
    my $my = shift ;

    my $id = $my->id ; 

    my $cssFile1 = "$my->{fileDir}/tabs/tabs.css" ; 
    my $cssFile2 = '' ;
    # There is apparently a problem with IE 6.0
    if (defined $ENV{HTTP_USER_AGENT} and $ENV{HTTP_USER_AGENT} =~ /MSIE\s*6/) { 
	$cssFile2 = "$my->{fileDir}/tabs/tabs_ie.css" ; 
    }
    my $css1 = new JQuery::CSS(file => $cssFile1) ; 
    my $css2 = '' ;
    $css2 = new JQuery::CSS(file => $cssFile2) unless $cssFile2 eq '' ; 

    my $css3Text =<<'EOD';
.tabs-loading span {
    padding: 0 0 0 20px;
    background: url(PLUGIN_DIR/tabs/loading.gif) no-repeat 0 50%;
} 
EOD

    $css3Text =~ s!PLUGIN_DIR!$my->{fileDir}!g ; 
 
    my $css3 = new JQuery::CSS(text => $css3Text) ; 
    if (!$my->{param}{spinner}) { 
	$css3 = '' ; 
    } 

    return [$css1,$css2,$css3] ; 
} 

sub HTML {
    my $my = shift ; 
    my $id = $my->id ; 
    my @tabs = @{$my->{param}{tabs}} ;
    my @texts = @{$my->{param}{texts}} ;
    my $n = 0 ; 
    my $html = qq[<div id="$id">\n<ul>\n] ; 
    my $headerId = $n ;
    for my $h (@tabs) { 
	$n ++ ;
	my $href = qq[<a href="#$id-fragment-$n">] ; 
	my $tabLabel = CGI::Util::escape($h) ; 
	$href = qq[<a href="$my->{param}{remoteProgram}?rm=$my->{param}{rm}&amp;tab=$tabLabel">] if $my->{param}{remote} ; 
	$html .= qq[<li>$href] . $h . qq[</a></li>\n] ; 
    }
    $html .= "</ul>\n" ;
    $n = 0 ; 
    for my $text (@texts) { 
	$n ++ ; 
	$html .= qq[<div id="$id-fragment-$n">\n$text\n</div>\n] ; 
    } 
    $html .= "</div>\n" ; 
    return $html ; 
}

sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 
    return '' unless $id =~ /\S/ ; 
    
    my $function =<<'EOD';
    
    $('#ID').tabs({PARAMS});
EOD
    $function =~ s/ID/$id/g ; 
    my @params = () ; 
    for (qw[remote defaultTab fxFade fxSpeed fxAutoHeight bookmarkable navClass selectedClass disabledClass containerClass loadingClass]) { 
	push @params, "$_: $my->{param}{$_}" if defined $my->{param}{$_} ;
    }

    my $params = join(',',@params) ;
    $function =~ s/PARAMS/$params/ ; 

    return $function ; 
}


=head1 NAME

JQuery::Tabs - Have tabs to see different pages

=head1 SYNOPSIS

   my @tabs = ("tab 1","tab 2","tab 3","tab 4") ; 
   my @texts = ("line 1","line 2","line 3","line4") ; 

   my $tab = JQuery::Tabs->new(id => 'myTab',
			    tabs => \@tabs,
                            texts => \@texts,
			    addToJQuery => $jquery,
			   ) ;

   my $tab = JQuery::Tabs->new(id => 'myTab',
			       tabs => \@tabs,
			       remote => 'true', # no texts needed if remote
			       remoteProgram => '/cgi-bin/jquery_tabs_results.pl',
			       rm => 'myMode',
			       addToJQuery => $jquery,
                               spinner => 1,
			      ) ;
    my $html = $tab->HTML ;

=head1 DESCRIPTION

Allow the user to see different pages using tabs. For an example of
how it looks, see L<http://www.stilbuero.de/jquery/tabs/>.

This module sets up tabs for different pages. The HTML can be supplied
directly, or the page can be updated remotely. When used remotely, the
program returns the run mode parameter, rm, as well as the parameter
tab, which contains the text in the tab header.

In remote mode, taconite is not used to refresh the page. All that is
expected is a normal html. If you are using CGI, something like this
is expected:

   use CGI ;    
   my $q = new CGI ; 
   print $q->header(-type=>'text/html');
   print $env ; 

=head1 FUNCTIONS

=over 

=item new 

Instantiate the object

=item HTML

Get the HTML for the object

=back

=head2 Parameters

=over 4 

=item id

This is the id of the tab

=item addToJQuery

The JQuery object to be added to.

=item tabs

This is a list of tab names for the headers

=item texts 

This is a list of HTML texts needed for each tab. If the page is going
to be updated remotely, this is not needed.

=item rm

The run mode that will be returned to the server.

=item spinner

When updated remotely, this add a little spinning wheel to the tab to
show that it is being updated.

=item bookmarkable

Allow the back button in the browser to give the expected results.

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

1; # End of JQuery::Tabs


