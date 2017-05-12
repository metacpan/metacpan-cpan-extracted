#!perl
use strict;
use warnings;
use Test::More tests => 4;
my $t = __FILE__;

BEGIN {
    use_ok('MediaWiki::Bot');
};

my $bot = MediaWiki::Bot->new({
    agent   => "MediaWiki::Bot::Plugin::Admin tests ($t)",
});

ok(defined $bot,                        'new() works');
isa_ok($bot, 'MediaWiki::Bot',          'Right class');
my @methods = qw(
    rollback
    delete undelete delete_archived_image
    block unblock
    protect unprotect
    transwiki_import xml_import
    set_usergroups add_usergroups remove_usergroups);
can_ok($bot, @methods);
