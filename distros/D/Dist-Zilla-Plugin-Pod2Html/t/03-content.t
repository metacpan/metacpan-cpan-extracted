#!/usr/bin/env perl
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}
use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Moose::Autobox;

my $zilla = Builder->from_config ({ dist_root => 'corpus/DZT' });
$zilla->build;

my $content = $zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]DZT.html$} } )->head->content;
like ($content, qr{<title>DZT</title>}, 'Document title missing');
like ($content, qr{<style type="text/css">}, 'Document style missing');

done_testing(2);

__END__
