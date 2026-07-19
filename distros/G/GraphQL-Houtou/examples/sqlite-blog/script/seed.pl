#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use DBI;
use FindBin;

my $root = "$FindBin::Bin/..";
my $path = $ENV{BLOG_DB} || "$root/var/blog.sqlite3";
my $posts = shift || 10_000;
my $comments_per_post = shift || 20;
die "posts and comments_per_post must be positive integers\n"
  if $posts !~ /^\d+$/ || $comments_per_post !~ /^\d+$/;

my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, sqlite_unicode => 1,
});
$dbh->do('PRAGMA foreign_keys = ON');
$dbh->do('PRAGMA journal_mode = WAL');
$dbh->do('PRAGMA synchronous = NORMAL');
$dbh->begin_work;
my $post_sth = $dbh->prepare(q{INSERT INTO posts
  (author_id,title,body,language,published_at) VALUES (?,?,?,?,datetime('now'))});
my $comment_sth = $dbh->prepare(q{INSERT INTO comments(post_id,author_id,body) VALUES (?,?,?)});
my $tag_sth = $dbh->prepare(q{INSERT OR IGNORE INTO post_tags(post_id,tag_id) VALUES (?,?)});
for my $n (1 .. $posts) {
  my $ja = $n % 2;
  $post_sth->execute(($n % 3) + 1, $ja ? "負荷試験の投稿 $n" : "Load test post $n",
    $ja ? '日本語本文とUTF-8レスポンスを検証します。' : 'English body for a production-shaped load.',
    $ja ? 'JA' : 'EN');
  my $id = $dbh->sqlite_last_insert_rowid;
  $tag_sth->execute($id, ($n % 3) + 1);
  for my $c (1 .. $comments_per_post) {
    $comment_sth->execute($id, (($n + $c) % 3) + 1,
      $ja ? "コメント $c" : "Comment $c");
  }
  if ($n % 1_000 == 0) { print "seeded $n posts\n" }
}
$dbh->commit;
print "database=$path posts=$posts comments_per_post=$comments_per_post\n";
