#!perl
use strict;
use warnings;
use Test::More;
use MediaWiki::Bot;

my $username = $ENV{PWPAdminUsername};
my $password = $ENV{PWPAdminPassword};
my $host     = $ENV{PWPAdminHost};
my $path     = $ENV{PWPAdminPath};
plan $username && $password && $host
    ? (tests => 4)
    : (skip_all => 'test wiki and admin login required');

my $t = __FILE__;
my $summary = "MediaWiki::Bot::Plugin::Admin tests ($t)";

my $bot = MediaWiki::Bot->new({
    agent   => $summary,
    host    => $host,
    ($path ? (path => $path) : ()),
    login_data => { username => $username, password => $password },
});

my @groups = qw(editor);
my @new_usergroups = $bot->set_usergroups('Perlwikibot testing', \@groups, $t);
my %new_usergroups = map { $_ => 1 } @new_usergroups;
delete $new_usergroups{ $_ } for qw(* user autoconfirmed);
is_deeply [ sort keys %new_usergroups ], [ sort @groups ], q{Rights set to what we wanted}
    or diag explain {
        got => [ sort keys %new_usergroups ],
        expected => [ sort @groups ],
        error => $bot->{error}
    };

my @removed_usergroups = $bot->remove_usergroups('Perlwikibot testing', \@groups, $t);
is_deeply \@removed_usergroups, \@groups, 'Removed what we asked for';

my @added_usergroups = $bot->add_usergroups('Perlwikibot testing', \@groups, $t);
is_deeply \@added_usergroups, \@groups, 'Added what we asked for';

@removed_usergroups = $bot->remove_usergroups('Perlwikibot testing', \@groups, $t);
is_deeply \@removed_usergroups, \@groups, 'Removed what we asked for';