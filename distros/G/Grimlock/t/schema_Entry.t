use Test::More;
use strict;
use warnings;

use Test::DBIx::Class qw(:resultsets);

fixtures_ok 'basic'
  => 'installed the basic fixtures from configuration files';

my $user;
my $entry;
ok $user = User->create({ name => 'herp', password => 'derp' }), "found our user " . $user->name;
ok $entry = $user->create_related('entries', {
    title => "title with spaces and metacharacters___! <script>alert('and javascript');</script>",
    body => "huehuheuhuehue <marquee>huehuehue</marquee>"
  }), "Created entry " . $entry->title;
ok (( $entry->display_title !~ m/(\s+|\_)/g ) && ( $entry->display_title =~ m/[a-zA-Z0-9\-]/g ), "title created properly");
ok $entry->title !~ m{<script>alert('and javascript');</script>}, "no scripts here";
ok $entry->body !~ m{<marquee>huehuehue</marquee>}, "no shit tags here";
ok my $reply = Entry->create({
  author => $user,
  parent => $entry, 
  title  => 'reply test',
  body   => 'derp'
}), "created reply ok";
diag $entry->created_at;
ok $entry->created_at =~ qr/\w \d+, \d\d\d\d at \d+:\d+:\d+ \w+/, "created_at rendered properly";
done_testing;
