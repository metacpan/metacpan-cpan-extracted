package JQuery::Accordion ; 

our $VERSION = '1.00';

use warnings;
use strict;

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    $my->{param}{headers} = [] ;  
    $my->{param}{texts} = [] ;  
    %{$my->{param}} = @_ ; 
    die "No id defined for Accordion" unless $my->{param}{id} =~ /\S/ ; 

    bless $my, $class;
    if ($my->{param}{css}) { 
	push @{$my->{css}},$my->{param}{css} ; 
    } 
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
    return ('interface/interface.js') ; 
} 

sub get_css { 
    my $my = shift ;

    my $id = $my->id ; 
    my $panelWidth = $my->{param}{panelWidth} || '400px' ;
    my $panelHeight = $my->{param}{panelHeight} || '200px' ;
# The position was absolute
    my $css=<<EOD;
#$id {
	width: $panelWidth ;
	border: 1px solid #6CAF00;
	position: relative;
	left: 10px;
	top: 10px;
}
#$id dt{
	line-height: 20px;
	background-color: #80df20;
	border-top: 2px solid #DAFF9F;
	border-bottom: 2px solid #6CAF00;
	padding: 0 10px;
	font-weight: bold;
	color: #fff;
}
#$id dd{
	overflow: auto;
}

#$id dt.${id}Hover
{
	background-color: #90ef30;
}
#$id dt.${id}Active
{
	background-color: #6CAF00;
	border-top: 2px solid #80df20;
	border-bottom: 2px solid #000;
}
EOD
    return $css ; 
} 



sub HTML {
    my $my = shift ; 
    my $id = $my->id ; 
    my $html = qq[<dl id="$id">\n] ; 
    my @headers = @{$my->{param}{headers}} ;
    my @texts = @{$my->{param}{texts}} ;
    my $n = -1 ; 
    for my $h (@headers) { 
	$n ++ ; 
	my $t = $texts[$n] ;
	$html .= qq[ <dt>$h</dt>\n] ; 
	$html .= qq[ <dd>$t</dd>\n] ; 
    } 
    $html .= qq[</dl>] ;
}


sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 
    return '' unless $id =~ /\S/ ; 
    
    my $function =<<'EOD';

    $('#ID').Accordion({headerSelector	: 'dt',
			panelSelector	: 'dd',
			activeClass		: 'IDActive',
			hoverClass		: 'IDHover',
			panelHeight		: PANEL_HEIGHT,
			speed			: 300
			}
			);
EOD
    my $panelHeight = $my->{param}{panelHeight} || 200 ;
    $function =~ s/PANEL_HEIGHT/$panelHeight/ ; 
    $function =~ s/ID/$id/g ; 
    return $function ; 
}


=head1 NAME

JQuery::Accordion - produce an accordion effect

=head1 SYNOPSIS

    my @headers = ("header 1","header 2","header 3","header4") ; 
    my @texts = ("line 1","line 2","line 3","line4") ; 
    my $accordion = JQuery::Accordion->new(id => 'myAccordion',
				       headers => \@headers,
				       texts => \@texts,
				       panelHeight => 200,
				       panelWidth => '400px'
                                       addToJQuery => $jquery,
				      ) ;

    # Change css defaults - add at the bottom
    $jquery->add_css_last(new JQuery::CSS( hash => {'#myAccordion' => {width => '600px'}})) ; 

    my $html = $accordion->HTML ;

=head1 DESCRIPTION

Add an accordion effect. For an example of how it looks, see L<http://interface.eyecon.ro/demos/accordion.html>.

You will also be wondering how to change colours etc. There are a
number of CSS items that are defined, and taht can be changed. Each
accordion needs an id. So the CSS paragraphs that are created are:

#id

#id dt

#id dd

#id dt.idHover

and

#id dt.idActive

=head1 FUNCTIONS 

=over

=item HTML

Get the HTML for the object

=item new

Instantiate the object 

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

1; # End of JQuery::Accordion


