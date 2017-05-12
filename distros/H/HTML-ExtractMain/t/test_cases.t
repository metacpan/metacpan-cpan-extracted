#!perl

use File::Slurp qw( slurp );
use HTML::FormatText 2.04;
use HTML::TreeBuilder;
use Test::More;
use HTML::ExtractMain 'extract_main_html';

chdir 't';    # may not be needed
chdir 'test_case_data'
    || BAIL_OUT q{Can't find test data directory "test_case_data"};

my @expected = ({ name         => 'indymedia_feature.html',
                  expect_start => qr/2010 est une ann|pour bannir les armes/,
                  expect_end   => qr/fermera la base/,
                },
                { name         => 'google_blogger.html',
                  expect_start => qr/the Google Maps API Blog/,
                  expect_end   => qr/Product Manager/,
                },
                { name         => 'google_short_blog.html',
                  expect_start => qr/The principle behind the advertising/,
                  expect_end   => qr/check them out/,
                  todo => 'Does not work with v1 of Readability algorithm',
                },
                { name         => 'lessig_blog.html',
                  expect_start => qr/So my blog turns seven today/,
                  expect_end   => qr/Thank you to everyone, again./,
                },
);

plan tests => 5 * scalar @expected;

foreach my $test_set (@expected) {

    my $name = $test_set->{name};
    my $data = slurp($name, binmode => ':utf8') || die $name;
    my $main = extract_main_html($data);

    my $length = length $main;
    ok( $length, 'got main content' );

    my $wiggle_room = int( $length * 0.02 );

    # ensure that test data is reasonable
    unlike( html_to_text($data),
            qr/^.{0,$wiggle_room}$test_set->{expect_start}/s,
            "$name: in original, start of main text is not at start of HTML"
    );
    unlike( html_to_text($data),
            qr/$test_set->{expect_end}.{0,$wiggle_room}$/s,
            "$name: in original, end of main text is not at end of HTML"
    );

    if ( $test_set->{todo} ) {
    TODO: {
            local $TODO = $test_set->{todo};
            like( html_to_text($main),
                  qr/^.{0,$wiggle_room}$test_set->{expect_start}/s,
                  "$name: is start of main text near the beginning?"
            );
            like( html_to_text($main),
                  qr/$test_set->{expect_end}.{0,$wiggle_room}$/s,
                  "$name: is end of main text near the end?" );
        }
    } else {
        like( html_to_text($main),
              qr/^.{0,$wiggle_room}$test_set->{expect_start}/s,
              "$name: is start of main text near the beginning?" );
        like( html_to_text($main),
              qr/$test_set->{expect_end}.{0,$wiggle_room}$/s,
              "$name: is end of main text near the end?" );
    }
}

my $html_formatter;

sub html_to_text {
    $html_formatter ||= HTML::FormatText->new( lm => 0, rm => 1_000_000 );

    my $html_content = shift;
    my $parsed_tree
        = eval { HTML::TreeBuilder->new_from_content($html_content) };
    my $plain_text = $html_formatter->format($parsed_tree);
    return $plain_text;
}

# Local Variables:
# mode: perltidy
# End:
