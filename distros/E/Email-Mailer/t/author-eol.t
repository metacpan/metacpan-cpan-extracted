
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Email/Mailer.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/module.t',
    't/qr/html_auto_text.qr',
    't/qr/html_auto_text_img.qr',
    't/qr/html_auto_text_img_noembed.qr',
    't/qr/html_text.qr',
    't/qr/html_text_attachments.qr',
    't/qr/iterative_send_0.qr',
    't/qr/iterative_send_1.qr',
    't/qr/templating.qr',
    't/qr/text_only.qr',
    't/release-kwalitee.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
