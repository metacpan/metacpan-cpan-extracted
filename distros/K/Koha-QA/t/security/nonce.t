use Modern::Perl;
use Test::More;

use Koha::QA::Security::Nonce;

my $expected_messages = {
    missing_nonce => q{<script> or <style> tag does not have 'nonce' attribute (see bug 38365)},
};

subtest 'Template script with src' => sub {
    plan tests => 2;
    my $template_with_script = '<script src="/js/main.js"></script>';

    my $checker  = Koha::QA::Security::Nonce->new( { content => $template_with_script } );
    my $is_valid = $checker->check;
    is( $is_valid, 1, 'No nonce attribute required for script with src' );
    my @errors = $checker->errors;
    is( scalar @errors, 0, 'No nonce attribute required for script with src' );
};

subtest 'Test inline script without nonce' => sub {
    plan tests => 2;
    my $template_with_inline = '<script>alert("test");</script>';
    my $checker              = Koha::QA::Security::Nonce->new( { content => $template_with_inline } );
    my $is_valid             = $checker->check;
    is( $is_valid, 0, 'Nonce attribute required for inline script' );

    my @errors = $checker->errors;
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_nonce',
                message     => $expected_messages->{missing_nonce},
                line        => $template_with_inline,
                line_number => 1,
            }
        ],
        'Nonce attribute required for inline script'
    );
};

subtest 'Test inline script with nonce' => sub {
    plan tests => 2;
    my $template_with_inline = '<script nonce="[% Koha.CSPNonce | $raw %]">alert("test");</script>';
    my $checker              = Koha::QA::Security::Nonce->new( { content => $template_with_inline } );
    my $is_valid             = $checker->check;
    is( $is_valid, 1, 'No error reported if nonce attribute is passed - inline script' );
    my @errors = $checker->errors;
    is( scalar @errors, 0, 'No error reported if nonce attribute is passed - inline script' );
};

subtest 'Test style without nonce' => sub {
    plan tests => 2;
    my $template_with_style = '<style>/* Some style */</style>';
    my $checker             = Koha::QA::Security::Nonce->new( { content => $template_with_style } );
    my $is_valid            = $checker->check;
    is( $is_valid, 0, 'Nonce attribute required for style' );
    my @errors = $checker->errors;
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_nonce',
                message     => $expected_messages->{missing_nonce},
                line        => $template_with_style,
                line_number => 1,
            }
        ],
        'Nonce attribute required for style'
    );
};

subtest 'Test style with nonce' => sub {
    plan tests => 2;
    my $template_with_style = '<style nonce="[% Koha.CSPNonce | $raw %]>/* Some style */</style>';
    my $checker             = Koha::QA::Security::Nonce->new( { content => $template_with_style } );
    my $is_valid            = $checker->check;
    is( $is_valid, 1, 'Nonce attribute required for style' );
    my @errors = $checker->errors;
    is_deeply( \@errors, [], 'Nonce attribute required for style' );
};

done_testing();
