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

sub fmsg { return "File " . shift() . " was not created"; }

my $created_files = $zilla->files->grep ( sub { $_->name =~ m{^docs[/\\]} } );
ok (@{ $created_files->grep ( sub {$_->name =~ m{^docs[/\\]DZT.html$} } ) }        == 1, fmsg ('docs/DZT.html'));
ok (@{ $created_files->grep ( sub {$_->name =~ m{^docs[/\\]DZT-Sample.html$} } ) } == 1, fmsg ('docs/DZT-Sample.html'));
ok (@{ $created_files->grep ( sub {$_->name =~ m{^docs[/\\]myscript.html$} } ) }   == 1, fmsg ('docs/myscript.html'));
done_testing(3);

__END__
