#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 6;
use Test::Warnings qw( warnings );

use HTML::Scrape;

PERLDOC: {
    # Do tests on an actual document, with unclosed tags.

    open( my $fh, '<', 't/perldoc.html' ) or die $!;
    my $html = join( '', <$fh> );
    close $fh;

    my $ids;

    my @warnings = warnings { $ids = HTML::Scrape::scrape_all_ids( $html ) };
    chomp @warnings;

    is_deeply(
        \@warnings,
        [
            'Unexpected closing </div> at 371:2: Expecting </ul>',
            'Unexpected closing </nav> at 372:0: Expecting </ul>',
            'Unexpected closing </body> at 463:2: Expecting </ul>',
            'Unexpected closing </html> at 464:0: Expecting </ul>',
            '6 tag(s) unclosed at end of document: html, body, nav, div, ul, ul',
        ]
    );

    # Check the long ones only partially.
    like( delete $ids->{wrapperlicious}, qr/\Q#Perl 5.36.1 Documentation/ );
    like( delete $ids->{perldocdiv}, qr/\Q#Perl 5.36.1 Documentation/ );
    like( delete $ids->{footer}, qr/Perldoc Browser is maintained by Dan Book/ );
    is_deeply( $ids, {
        'About'                     => '',
        'About-Perl'                => '#About Perl',
        'Perl'                      => '',
        'Perl-5.36.1-Documentation' => '#Perl 5.36.1 Documentation',
        'Reference'                 => '',
        'Reference-Lists'           => '#Reference Lists',
        'content-expand-button'     => 'Expand',
        'dropdownlink-dev'          => 'Dev',
        'dropdownlink-nav'          => 'Documentation',
        'dropdownlink-stable'       => '5.36.1',
    } );
}


exit 0;
