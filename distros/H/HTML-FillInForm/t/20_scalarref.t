use strict;
use warnings;
use Test::More;
use HTML::FillInForm;

# a few strings to test against
my @contents = (
    q{404},
    q{404 Not Found},
    q{Hello World},
    q{<html><body>Hello World</body></html>},
);

# our number of tests in the number of elements in @contents
plan tests => (scalar @contents);


# run each string through H::FIF
foreach my $content (@contents) {
    my $output = HTML::FillInForm->fill( \$content, fdat      => {});

    is($output, $content, q{output and content should be the same});
}

