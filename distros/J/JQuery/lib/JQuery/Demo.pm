
=head1 NAME

JQuery::Demo - A module used for the JQuery examples

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use JQuery::Demo ;
    
=head1 DESCRIPTION

The examples are based on CGI::Application. CGI::Application need a
setup routine to be defined and a cgiapp_postrun, which gathers the
HTMLm jquery and css and puts it into an HTML template.

=head2 Functions

=over 4

=item setup

The run modes are defined JQuery is insantiated.

=item cgiapp_postrun

Get the jquery code, the css and put them, together with the html into the template.

=item show_html

Get the HTML template

=back

=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

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

package JQuery::Demo ; 

our $VERSION = '1.01';

use strict ; 
use warnings ; 

use CGI::Carp qw(fatalsToBrowser);
use base qw(CGI::Application);
use JQuery ; 

sub setup {
    my $my = shift;
    $my->run_modes([qw(start reply)]);
    my $jquery = new JQuery(jqueryDir => '/jquery_js') ; 
    $my->{jquery} = $jquery ;
}


sub cgiapp_postrun { 
    my $my = shift ; 
    my $outputRef = shift ;
#    $ENV{HTTP_X_REQUESTED_WITH} eq 'XMLHttpRequest') { 
    if (exists $my->{info}{AJAX}) {
	$$outputRef = $my->{info}{AJAX} ; 
	$my->header_props(-type=>'text/xml') ; 
	return ;
    } 
    my $jquery = $my->{jquery} ; 
    $my->{info}{JQUERY_JAVASCRIPT} = $jquery->get_jquery_code ; 
    $my->{info}{JQUERY_STYLE} = $jquery->get_css ; 
    $$outputRef = $my->show_html ; 
} 

# I have no idea why, but if this line is included, the pictures on 
# clickmenu don't work.
# <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">

sub show_html {
    my $my = shift ;
    my $JAVASCRIPT = $my->{info}{JQUERY_JAVASCRIPT} || '' ;
    my $TITLE = $my->{info}{TITLE} || '' ; 
    my $STYLE = $my->{info}{JQUERY_STYLE} || '' ;
    my $BODY = $my->{info}{BODY} || '' ; 
    my  $html = <<EOT;


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>$TITLE</title>
$JAVASCRIPT
$STYLE
</head>


<body>
$BODY
</body>
</html>

EOT
    
}
1;

