package HTML::CruftText;

use 5.012;
use strict;
use warnings;

use Time::HiRes;
use List::MoreUtils qw(first_index indexes last_index);

# STATICS

# markers -- patterns used to find lines than can help find the text
my $_MARKER_PATTERNS = {
    startclickprintinclude => qr/<\!--\s*startclickprintinclude/pi,
    endclickprintinclude   => qr/<\!--\s*endclickprintinclude/pi,
    startclickprintexclude => qr/<\!--\s*startclickprintexclude/pi,
    endclickprintexclude   => qr/<\!--\s*endclickprintexclude/pi,
    sphereitbegin          => qr/<\!--\s*DISABLEsphereit\s*start/i,
    sphereitend            => qr/<\!--\s*DISABLEsphereit\s*end/i,
    body                   => qr/<body/i,
    comment                => qr/(id|class)="[^"]*comment[^"]*"/i,
};

#TODO handle sphereit like we're now handling CLickprint.

# blank everything within these elements
my $_SCRUB_TAGS = [ qw/script style frame applet textarea/ ];

sub _remove_everything_except_newlines($)
{
    my $data = shift;

    # Retain the number of newlines
    my $newlines = ($data =~ tr/\n//);

    return "\n" x $newlines;    
}


my $_process_html_comment_regex_clickprint_comments = qr/^\s*(start|end)clickprint(in|ex)clude/ios;
my $_process_html_comment_regex_brackets = qr/[<>]/os;

sub _process_html_comment($)
{
    my $data = shift;

    # Don't touch clickprint comments
    if ($data =~ $_process_html_comment_regex_clickprint_comments) {
        return $data;
    }

    # Replace ">" and "<" to "|"
    $data =~ s/$_process_html_comment_regex_brackets/|/g;

    # Prepend every line with comment (not precompiled because trivial)
    $data =~ s/\n/ -->\n<!-- /gs;

    return $data;
}

# remove >'s from inside comments so the simple line density scorer
# doesn't get confused about where tags end.
# also, split multiline comments into multiple single line comments
my $_remove_tags_in_comments_regex_html_comment = qr/<!--(.*?)-->/ios;

sub _remove_tags_in_comments($)
{
    my $lines = shift;

    my $html = join("\n", @{ $lines });

    # Remove ">" and "<" in comments
    $html =~ s/$_remove_tags_in_comments_regex_html_comment/'<!--'._process_html_comment($1).'-->'/eg;

    $lines = [ split("\n", $html) ];

    return $lines;
}

# make sure that all tags start and close on one line
# by adding false <>s as necessary, eg:
#
# <foo
# bar>
#
# becomes
#
# <foo>
# <tag bar>
#
sub _fix_multiline_tags
{
    my ( $lines ) = @_;

    my $add_start_tag;
    for ( my $i = 0 ; $i < @{ $lines } ; $i++ )
    {
        if ( $add_start_tag )
        {
            $lines->[ $i ] = "<$add_start_tag " . $lines->[ $i ];
            $add_start_tag = undef;
        }

        if ( $lines->[ $i ] =~ /<([^ >]*)[^>]*$/ )
        {
            $add_start_tag = $1;
            $lines->[ $i ] .= ' >';
        }
    }
}

#remove all text not within the <body> tag
#Note: Some badly formated web pages will have multiple <body> tags or will not have an open tag.
#We go the conservative thing of only deleting stuff before the first <body> tag and stuff after the last </body> tag.
sub _remove_nonbody_text
{
    my ( $lines ) = @_;

    my $add_start_tag;

    my $state = 'before_body';

    my $body_open_tag_line_number = first_index { $_ =~ /<body/i } @{ $lines };

    if ( $body_open_tag_line_number != -1 )
    {

        #delete everything before <body>
        for ( my $line_number_to_clear = 0 ; $line_number_to_clear < $body_open_tag_line_number ; $line_number_to_clear++ )
        {
            $lines->[ $line_number_to_clear ] = '';
        }

        $lines->[ $body_open_tag_line_number ] =~ s/^.*?\<body/<body/i;
    }

    my $body_close_tag_line_number = last_index { $_ =~ /<\/body/i } @{ $lines };

    if ( $body_close_tag_line_number != -1 )
    {

        #delete everything after </body>

        $lines->[ $body_close_tag_line_number ] =~ s/<\/body>.*/<\/body>/i;
        for (
            my $line_number_to_clear = ( $body_close_tag_line_number + 1 ) ;
            $line_number_to_clear < scalar( @{ $lines } ) ;
            $line_number_to_clear++
          )
        {
            $lines->[ $line_number_to_clear ] = '';
        }
    }
}

sub _clickprint_start_line
{
    my ( $lines ) = @_;

    my $i = 0;

    my $found_clickprint = 0;

    while ( ( $i < @{ $lines } ) && !$found_clickprint )
    {
        if ( $lines->[ $i ] =~ $_MARKER_PATTERNS->{ startclickprintinclude } )
        {
            $found_clickprint = 1;
        }
        else
        {
            $i++;
        }
    }

    if ( !$found_clickprint )
    {
        return;
    }
    else
    {
        return $i;

    }
}

sub _remove_nonclickprint_text
{
    my ( $lines, $clickprintmap ) = @_;

    my $clickprint_start_line = _clickprint_start_line( $lines );

    return if !defined( $clickprint_start_line );

    # blank out all line before the first click_print

    for ( my $j = 0 ; $j < $clickprint_start_line ; $j++ )
    {
        $lines->[ $j ] = '';
    }

    my $i = $clickprint_start_line;

    my $current_substring = \$lines->[ $i ];
    my $state             = "before_clickprint";

    while ( $i < @{ $lines } )
    {

        #		print
        #		  "i = $i state = $state current_substring = $$current_substring \n";

        if ( $state eq "before_clickprint" )
        {
            if ( $$current_substring =~ $_MARKER_PATTERNS->{ startclickprintinclude } )
            {
                $$current_substring =~
                  "s/.*?$_MARKER_PATTERNS->{startclickprintinclude}/$_MARKER_PATTERNS->{startclickprintinclude}/p";

                $$current_substring =~ $_MARKER_PATTERNS->{ startclickprintinclude };

                $current_substring = \substr( $$current_substring, length( ${^PREMATCH} ) + length( ${^MATCH} ) );

                $current_substring = \_get_string_after_comment_end_tags( $current_substring );

                $state = "in_click_print";
            }
            else
            {
                $$current_substring = '';
            }
        }

        if ( $state eq 'in_click_print' )
        {

            #			print "in_click_print\n";
            if ( $$current_substring =~ $_MARKER_PATTERNS->{ startclickprintexclude } )
            {
                $current_substring = \substr( $$current_substring, length( ${^MATCH} ) + length( ${^PREMATCH} ) );

                $current_substring = \_get_string_after_comment_end_tags( $current_substring );
                $state             = "in_click_print_exclude";

            }
            elsif ( $$current_substring =~ $_MARKER_PATTERNS->{ endclickprintinclude } )
            {
                $current_substring = \substr( $$current_substring, length( ${^MATCH} ) + length( ${^PREMATCH} ) );

                $current_substring = \_get_string_after_comment_end_tags( $current_substring );

                $state = 'before_clickprint';
                next;
            }
        }

        if ( $state eq 'in_click_print_exclude' )
        {
            if ( $$current_substring =~ $_MARKER_PATTERNS->{ endclickprintexclude } )
            {
                my $index = index( $$current_substring, $_MARKER_PATTERNS->{ endclickprintexclude } );

                substr( $$current_substring, 0, length( ${^PREMATCH} ), '' );

                $current_substring = \substr( $$current_substring, length( ${^MATCH} ) );

                $current_substring = \_get_string_after_comment_end_tags( $current_substring );

                $state = "in_click_print";
                next;
            }
            else
            {
                $$current_substring = '';
            }
        }

        $i++;
        if ( $i < @{ $lines } )
        {
            $current_substring = \$lines->[ $i ];
        }
    }
}

sub _get_string_after_comment_end_tags
{
    my ( $current_substring, $i ) = @_;

    my $comment_end_pos = 0;

    if ( $$current_substring =~ /^\s*-->/p )
    {
        $comment_end_pos = length( ${^MATCH} );
    }
    return substr( $$current_substring, $comment_end_pos );
}

# remove text wthin script, style, iframe, applet, and textarea tags
sub _remove_script_text
{
    my ( $lines ) = @_;

    my $state = 'text';
    my $start_scrub_tag_name;

    for ( my $i = 0 ; $i < @{ $lines } ; $i++ )
    {
        my $line = $lines->[ $i ];

        #print "line $i: $line\n";
        my @scrubs;
        my $start_scrub_pos = 0;
        while ( $line =~ /(<(\/?[a-z]+)[^>]*>)/gi )
        {
            my $tag      = $1;
            my $tag_name = $2;

            #print "found tag $tag_name\n";
            if ( $state eq 'text' )
            {
                if ( grep { lc( $tag_name ) eq $_ } @{ $_SCRUB_TAGS } )
                {

                    #print "found scrub tag\n";
                    $state                = 'scrub_text';
                    $start_scrub_pos      = pos( $line );
                    $start_scrub_tag_name = $tag_name;
                }
            }
            elsif ( $state eq 'scrub_text' )
            {
                if ( lc( $tag_name ) eq lc( "/$start_scrub_tag_name" ) )
                {
                    $state = 'text';
                    my $end_scrub_pos = pos( $line ) - length( $tag );

                    # delay actual scrubbing of text until the end so that we don't
                    # have to reset the position of the state machine
                    push( @scrubs, [ $start_scrub_pos, $end_scrub_pos - $start_scrub_pos ] );
                }
            }
        }

        if ( $state eq 'scrub_text' )
        {
            push( @scrubs, [ $start_scrub_pos, length( $line ) - $start_scrub_pos ] );
        }

        my $scrubbed_length = 0;
        for my $scrub ( @scrubs )
        {

            #print "scrub line $i\n";
            substr( $lines->[ $i ], $scrub->[ 0 ] - $scrubbed_length, $scrub->[ 1 ] ) = '';
            $scrubbed_length += $scrub->[ 1 ];
        }

        #print "scrubbed line: $lines->[$i]\n";
    }
}


my $_start_time;
my $_last_time;

sub _print_time
{
    return;

    my ( $s ) = @_;

    my $t = Time::HiRes::gettimeofday();
    $_start_time ||= $t;
    $_last_time  ||= $t;

    my $elapsed     = $t - $_start_time;
    my $incremental = $t - $_last_time;

    printf( STDERR "time $s: %f elapsed %f incremental\n", $elapsed, $incremental );

    $_last_time = $t;
}

=head1 NAME

HTML::CruftText - Remove unuseful text from HTML

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Removes junk from HTML page text. 

This module uses a regular expression based approach to remove cruft from HTML. I.e. content/text that is very unlikely to be useful or interesting.


    use HTML::CruftText;

    open (my $MYINPUTFILE, '<input.html' );
    
    my @lines = <$MYINPUTFILE>;

    my $de_crufted_lines = HTML::CruftText::clearCruftText( \@lines);

    ...

=head1 DESCRIPTION

This module was developed for the Media Cloud project (http://mediacloud.org) as the first step in differentiating article text from ads, navigation, and other boilerplate text. Its approach is very conservative and almost never removes legitimate article text. However, it still leaves in a lot of cruft so many users will want to do additional processing.

Typically, the clearCruftText method is called with an array reference containing the lines of an HTML file. Each line is then altered so that the cruft text is removed. After completion some lines will be entirely blank, while others will have certain text removed. In a few rare cases, additional HTML tags are added. The result is NOT GUARANTEED to be valid, balanced HTML though some HTML is retained because it is extremely useful for further processing. Thus some users will want to run an HTML stripper over the results.

The following tactics are used to remove cruft text:

* Nonbody text --anything outside of the <body></body> tags -- is removed

* Text within the following tags is removed: <script>, <style>, <frame>, <applet>, and <textarea>

* clickprint markers -- many web sites have clickprint annotation comments that explicitly mark whether text should be included.

* Removal of HTML tags in comments: we remove any HTML tags within <!-- --> comments but keep other comment text. This makes the result easier to process with regular expressions.

* Close tags that span multiple lines within an single open tag. For example, we would change:

     FOO<a 
   href="bar.com>BAZ

 to:

     FOO<a >
   <a href="bar.com>BAZ
   
this makes the output easier to process with regular expressions.


=head1 SUBROUTINES/METHODS

=head2 clearCruftText( $lines )

This is the main method for this module. Removes cruft text from $lines and returns the result. Generally $lines will be a reference to an array of lines from an HTML file. However, this method can also be called with a string, in which case, the string will be split into multiple lines and an array reference of decrufted html lines is returned.

=cut

sub clearCruftText
{
    my $lines = shift;

    if ( !ref( $lines ) )
    {
        $lines = [ split( /[\n\r]+/, $lines ) ];
    }

    _print_time( "split_lines" );

    $lines = _remove_tags_in_comments( $lines );
    _print_time( "remove tags" );
    _fix_multiline_tags( $lines );
    _print_time( "fix multiline" );
    _remove_script_text( $lines );
    _print_time( "remove scripts" );
    _remove_nonbody_text( $lines );
    _print_time( "remove nonbody" );
    _remove_nonclickprint_text( $lines );
    _print_time( "remove clickprint" );

    return $lines;
}

=head2 has_clickprint ( $lines )

Returns true if the HTML in $lines has clickprint annotation comment tags.
Returns false otherwise.

=cut

sub has_clickprint
{
    my ( $lines ) = @_;

    return defined( _clickprint_start_line( $lines ) );
}


=head1 AUTHOR

David Larochelle, C<< <dlarochelle at cyber.law.harvard.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-crufttext at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-CruftText>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::CruftText


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-CruftText>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-CruftText>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-CruftText>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-CruftText/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Berkman Center for Internet & Society at Harvard University.

This program is released under the following license: aAffero General Public License


=cut

1; # End of HTML::CruftText
