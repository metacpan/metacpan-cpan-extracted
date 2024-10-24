use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MediaWiki/Bot.pm',
    'lib/MediaWiki/Bot/Constants.pm',
    't/00-compile.t',
    't/00-init.t',
    't/01-api_error.t',
    't/02-login.t',
    't/03-get_text.t',
    't/04-edit.t',
    't/05-revert.t',
    't/06-get_history.t',
    't/07-unicode.t',
    't/08-get_last.t',
    't/09-update_rc.t',
    't/10-what_links_here.t',
    't/11-get_pages_in_category.t',
    't/12-linksearch.t',
    't/13-get_namespace_names.t',
    't/14-get_pages_in_namespace.t',
    't/15-count_contributions.t',
    't/16-last_active.t',
    't/17-was_blocked.t',
    't/18-is_blocked.t',
    't/19-get_pages.t',
    't/20-assertion.t',
    't/21-get_allusers.t',
    't/22-get_id.t',
    't/23-list_transclusions.t',
    't/24-purge_page.t',
    't/25-sitematrix.t',
    't/26-diff.t',
    't/27-prefixindex.t',
    't/28-search.t',
    't/29-get_log.t',
    't/30-was_g_blocked.t',
    't/31-is_g_blocked.t',
    't/32-was_locked.t',
    't/33-is_locked.t',
    't/34-secure.t',
    't/35-get_protection.t',
    't/36-email.t',
    't/37-move.t',
    't/38-test_image_exists.t',
    't/39-image_usage.t',
    't/40-upload.t',
    't/41-get_users.t',
    't/42-expandtemplates.t',
    't/43-recentchanges.t',
    't/44-patrol.t',
    't/45-contributions.t',
    't/46-usergroups.t',
    't/47-global_image_usage.t',
    't/48-get_image.t',
    't/49-get_all_categories.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
