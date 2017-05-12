package FWS::V2::Safety;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Safety - Framework Sites version 2 safe data wrappers

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;
    
    my $fws = FWS::V2->new();

    #
    # each one of these statements will clean the string up to make it "safe"
    # depending on its context
    #    

    print $fws->safeDir( "../../this/could/be/dangrous" );
    
    print $fws->safeFile( "../../i-am-trying-to-change-dir.ext" );
    
    print $fws->safeSQL( "this ' or 1=1 or ' is super bad" );


=head1 DESCRIPTION

FWS version 2 safety methods are used for security when using unknown parameters that could be malicious.   Whenever data is passed to another method it should be wrapped in its appropriate safety wrapper under the guidance of each method.


=head1 METHODS

=head2 safeDir

All directories or directry with file combination should be wrapped in this method before being used.  It will remove any context that could change its scope to higher than its given location.  When using directories ALWAYS prepend them with $fws->{fileDir} or $fws->{secureFileDir} to ensure they root path is always in a known location to further prevent any tampering.  NEVER use a directory that is not prepended with a known depth!

In addition this also will convert any directory backslashes to forward slashes in case a dos style windows path was tossed into the directory.

    #
    # will return //this/could/be/dangerous
    #
    print $fws->safeDir( "../../this/could/be/dangrous" );

    #
    # will return this/is/fine
    #
    print $fws->safeDir( "this/is/fine" );

    #
    # using this with files is fine also
    #
    print $fws->safeDir( "c:/this/is/fine/also.zip" );

=cut

sub safeDir {
    my ( $self, $incomingText ) = @_;

    #
    # not dots, no pipes, no semi colons
    #
    $incomingText =~ s/(\.\.|\||;)//sg;

    #
    # no matter what there should be no back slashes
    # switch them to forwards if some funky windows paths
    # made it into the dir
    #
    $incomingText =~ s/\\/\//sg;
    
    return $incomingText;
}


=head2 safeFile

All files should be wrapped in this method before being applied.  It will remove any context that could change its scope to a different directory.

    #
    # will return ....i-am-trying-to-change-dir.ext
    #
    print $fws->safeFile( "../../i-am-trying-to-change-dir.ext" );

=cut


sub safeFile {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/(\/|\\|;|\|)//sg;
    return $incomingText;
}


=head2 safeNumber

Make sure a number is a valid number and strip anything that would make it not.  The first character in the string has to be a '-' for the number to maintain its negative status.

    #
    # will return -34663.43
    #
    print $fws->safeNumber( '- $34,663.43' );

=cut

sub safeNumber {
    my ( $self, $number ) = @_;
    my $negative = 0;
    if ( $number =~ /^-/ ) { $negative = 1 }
    $number =~ s/[^\d.]+//g;
    if ( $negative ) { return '-' . ( $number + 0 ) }
    return $number + 0;
}


=head2 safeSQL

All fields and dynamic content in SQL statements should be wrapped in this method before being applied.  It will add double tics and escape any escapes so you can not break out of a statement and inject anything not intended.

    #
    # will return this '' or 1=1 or '' is super bad
    #
    print $fws->safeSQL("this ' or 1=1 or ' is super bad");

=cut

sub safeSQL {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/\'/\'\'/sg;
    $incomingText =~ s/\\/\\\\/sg;
    return $incomingText;
}


=head2 safeQuery

Remove anything from a query string that could advocate a cross site scripting attack

    #
    # Do something that could be used for evil
    #
    my $querySting = 'id=<script>alert( 'bo!' )</script>url&this=that';
    $valueHash{html} .= '<a href="http://www.frameworksites.com/cgi-bin/go.pl?' . $fws->safeQuery( $queryString ) . '">Click Me</a>';

=cut

sub safeQuery {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/\%3C/\</sg;
    $incomingText =~ s/\%3E/\>/sg;
    return $self->removeHTML( $incomingText );
}


=head2 safeURL

Switch a string into a safe url by replacing all non 0-9 a-z A-Z with a dash but not start with a dash.  For SEO reasons this will also switch any & with the word "and".

    #
    # change the product name into a safe url
    #
    my $productName = 'My super cool product & title';
    my $frindlyURL = $fws->safeURL( $productName ) . '.html';

    #
    # change an name into a safe class name
    #
    my $productAttribute = 'Size: Large';
    my $className = 'productAttribute_' . $fws->safeURL( $productAttribute );

=cut

sub safeURL {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/\&/and/sg;
    $incomingText =~ s/[^0-9a-zA-Z]/_/sg;
    $incomingText =~ s/^\s+//;
    return $incomingText;
}


=head2 safeJSON

Replace any thing harmful to an JSON node that could cause it to fail.  It will escape stuff like quotes and such.

    #
    # make a node safe
    #
    my $sillyNode = 'This "Can not" be in json';
    my $safeSillyNode = $fws->safeJSON( $sillyNode );
    print 'Safe JSON: '.$sillyNode;

=cut


sub safeJSON {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/\\/\\\\/sg;
    $incomingText =~ s/"/\\"/sg;
    $incomingText =~ s/\//\\\//sg;
    return $incomingText;
}

 
=head2 safeXML

Replace any thing harmful to an XML node that could cause it to fail validation.   & and < will be converted to &amp; and &lt;

    #
    # make a node safe
    #
    my $sillyNode = '55 is < 66 & 77';
    my $safeSillyNode = $fws->safeXML( $sillyNode );
    print '<silly>' . $safeSillyNode . '</silly>';
    
    #
    # all in one
    #
    print '<silly>' . $fws->safeXML( '55 is < 66 & 77' ) . '</silly>';


=cut

sub safeXML {
    my ( $self, $incomingText ) = @_;
    $incomingText =~ s/&/&amp;/sg;
    $incomingText =~ s/</&lt;/sg;
    return $incomingText;
}



=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Safety


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Safety
