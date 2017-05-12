package JQuery::CSS ; 

our $VERSION = '1.00';

use strict ;
use warnings ;

use CSS ; 
use Carp ; 

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    croak "Invalid number of argument" if @_ % 2 ;
    %{$my->{param}} = @_ ; 
    carp "Must have file, hash or text" unless exists $my->{param}{file} or exists $my->{param}{hash} or exists $my->{param}{text} ; 
    my $css = new CSS({'adaptor' => 'CSS::Adaptor::Pretty'}); 
    
    if (exists $my->{param}{file}) { 
	my $file = $my->{param}{file} ; 
    } 
    if (exists $my->{param}{text}) { 
	$css->read_string($my->{param}{text}) ;
    }    
    if (exists $my->{param}{hash}) { 
	my $text ; 
	my $hash = $my->{param}{hash} ; 
	for my $key (keys %$hash) { 
	    $text .= "$key {" ; 
	    my @subKeys = keys(%{$hash->{$key}}) ; 
	    for my $subKey (@subKeys) {
		$text .= $subKey . ": " ; 
		my $v = $hash->{$key}{$subKey} ; 
		$text .= $v . "; " ;
	    } 
	    $text .= "}\n" ; 
	} 
	$css->read_string($text) ;
    }
    
    $my->{css} = $css ;
    
    bless $my, $class;
    return $my ;
}

sub output_text { 
    my $my = shift ;
    my $id = shift ; 
    # This is a filename

    if (exists $my->{param}{file}) { 
	my $fileName = $my->{param}{file} ;
	my $css = qq[<style type="text/css">\@import "$fileName";</style>\n] ;
	return $css ; 
    } 

    if (exists $my->{param}{text} or exists $my->{param}{hash}) { 
	my $css = $my->{css} ;
	my $result = qq[<style type="text/css">\n] . $css->output() . "</style>" ;
	return $result ; 
    } 
} 
1;
__END__

=head1 NAME

JQuery::CSS - a CSS helper

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

Allow CSS to be defined either as a file, text or a hash

     my $css = new JQuery::CSS(file => '/jquery_js/dates/default.css') ;
     $css->output_text ; 

=head1 DESCRIPTION 

The CSS is created and will normally be added to JQuery. JQuery will
then output the css automatically, so there will generally be no need
to call $css->output_text.

     my $css = new JQuery::CSS(file => '/jquery_js/dates/default.css') ;
     $css->output_text ; 
     my $css = new JQuery::CSS( text => "tr.alt   td {background: #ecf6fc;} \
                                tr.over  td {background: #bcd4ec;} \
                                ") ; 


     $css->output_text ; 
     $css = new JQuery::CSS( hash => {
	   			    '.odd' => {'background-color' => "#FFF"} , 
				    '.even' => {'background-color' => "#D7FF00"} , 
				    '.highlight' => {'background-color' => "#333", 
						     'color' => '#FFF', 
						     'font-weight' => 'bold', 
						     'border-left' => '1px solid #FFF', 
						     'border-right' => '1px solid #FFF' }, 
				     'table' => {width => '900px', 'font-size' => '16px'},
				     }) ; 
     $css->output_text ; 
     my $css = new JQuery::CSS(text => 'body {font-family:	Arial, Sans-Serif;font-size:	10px;}') ;
     $css->output_text ; 

     my $css = new JQuery::CSS(text => ['body {font-family:	Arial, Sans-Serif;font-size:	10px;}',
				   'head {font-family:	Arial, Sans-Serif;font-size:	10px;}']) ;

=head1 FUNCTIONS

=over

=item new

Instantiate the object

=item output_text

Get the text for the object. Usually, JQuery takes care of calling
this and the user program should not need to call it.

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

1; # End of JQuery::CSS
