package Email::Folder::RFC2822;
use base 'Email::Folder';
sub bless_message {$_[1]}

package main;
use Test::More tests => 3;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

Email::Store::Mail->store($_) for
    Email::Folder::RFC2822->new("plucene-200406")->messages;
Email::Store::Plucene->optimize();

is_deeply([do_search("listserv")],
 ['20040616075804.GA20643@soto.kasei.com',
  '32BF98DC-BF3C-11D8-9FC1-003065AC1682@ohwy.com',],
  "Search for something in body OK");

is_deeply([do_search("from:Marvin")],
 [
  '2533A539-BF26-11D8-9FC1-003065AC1682@ohwy.com',
  '32BF98DC-BF3C-11D8-9FC1-003065AC1682@ohwy.com',
 'E0D9CA9C-BF1E-11D8-9FC1-003065AC1682@ohwy.com',
  ]);

sub do_search {
    return sort map {$_->id} Email::Store::Mail->plucene_search($_[0]);
}
