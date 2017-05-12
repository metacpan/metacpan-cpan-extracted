use strict;
use warnings;

use Git::Wrapper;
use Path::Tiny qw(path);
use Test::More 0.88;            # done_testing

use lib 't';
use Util;

# rt#56485 - skip test to avoid failures for old git versions
skip_unless_git_version('1.7.0');

plan tests => 7;

init_test(corpus => 'push-multi');

$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# create a clone, and use it to set up origin
my $clone1 = $base_dir->child('clone1');
my $clone2 = $base_dir->child('clone2');
$git->clone( { quiet=>1, 'no-checkout'=>1, bare=>1 }, "$git_dir", "$clone1" );
$git->clone( { quiet=>1, 'no-checkout'=>1, bare=>1 }, "$git_dir", "$clone2" );
$git->remote('add', 'origin', "$clone1");
$git->remote('add', 'another', "$clone2");
$git->config('branch.master.remote', 'origin');
$git->config('branch.master.merge', 'refs/heads/master');

# do the release
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");

new_zilla_from_repo;
$zilla->release;

# Check log
zilla_log_is('Git::Push', <<'');
[Git::Push] pushing to origin
[Git::Push] pushing to another

for my $c ( $clone1, $clone2 ) {
  # check if everything was pushed
  my $git = Git::Wrapper->new( "$c" );
  my $cName = $c->basename;
  my ($log) = $git->log( 'HEAD' );
  like( $log->message, qr/v1.23\n[^a-z]*foo[^a-z]*bar[^a-z]*baz/,
        "commit pushed to $cName" );

  # check if tag has been correctly created
  my @tags = $git->tag;
  is( scalar(@tags), 1, "one tag pushed to $cName" );
  is( $tags[0], 'v1.23', "found v1.23 tag in $cName" );
}

done_testing;
