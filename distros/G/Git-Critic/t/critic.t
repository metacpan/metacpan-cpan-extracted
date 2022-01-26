#!/usr/bin/env perl

use Test::Most;
use Git::Critic;

#
# Yeah, this sucks. Trying to test something against a changing target like
# the current state of the git repo is painful. Thus, we only have stub tests
# for now.
#

ok my $critic = Git::Critic->new( primary_target => 'main' ),
  'We should be able to create a git critic object';

is $critic->primary_target, 'main', 'We can set the name of our primary branch';

$critic->_add_to_run_queue('current');
is $critic->current_target, 'current', '... and our current branch';

$critic->_add_to_run_queue(<<'END');
lib/Git/Critic.pm
t/critic.t
not-perl.py
END
my @files = $critic->_get_modified_perl_files;
eq_or_diff \@files, [ 'lib/Git/Critic.pm', 't/critic.t' ],
  '... we should be able to get a list of modified files';

$critic->_add_to_run_queue( get_mock_diff() );
my @lines = $critic->_get_diff('lib/Git/Critic.pm');
explain \@lines;

done_testing;

sub get_mock_diff {
    return <<'END';
diff --git a/lib/Git/Critic.pm b/lib/Git/Critic.pm
index d77ff16..70a86b3 100644
--- a/lib/Git/Critic.pm
+++ b/lib/Git/Critic.pm
@@ -11,7 +11,6 @@ use Carp;
 use File::Basename 'basename';
 use List::Util qw(uniq);
 use Moo;
-use MooX::HandlesVia;
 use Types::Standard qw( ArrayRef Int Str);
 
 our $VERSION = '0.1';
@@ -21,10 +20,9 @@ our $VERSION = '0.1';
 #
 
 has primary_target => (
-    is      => 'ro',
-    isa     => Str,
-    lazy    => 1,
-    builder => '_build_primary_target',
+    is       => 'ro',
+    isa      => Str,
+    required => 1,
 );
 
 has current_target => (
@@ -46,6 +44,12 @@ has severity => (
     default => 5,
 );
 
+has verbose => (
+    is      => 'ro',
+    isa     => Int,
+    default => 0,
+);
+
 # this is only for tests
 has _run_test_queue => (
     is       => 'ro',
@@ -58,29 +62,6 @@ has _run_test_queue => (
 # Builders
 #
 
-sub _build_primary_target {
-    my $self = shift;
-    my $primary_target =
-      $self->_run( 'git', 'symbolic-ref', 'refs/remotes/origin/HEAD' );
-
-    if ( !$primary_target ) {
-        croak(<<'END');
-Could not determine target branch via "git symbolic-ref refs/remotes/origin/HEAD"
-You can set your target branch with:
-
-    git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/\$branch_name
-
-Where $branch_name is the name of the primary branch you develop from ('main, 'master', etc.)
-
-Alternatively, you can pass the primary branch name in the constructor:
-
-    my $critic = Git::Critic->new( primary_target => 'main' );
-
-END
-    }
-    return $primary_target;
-}
-
 sub _build_current_target {
     my $self = shift;
     return $self->_run( 'git', 'rev-parse', '--abbrev-ref', 'HEAD' );
@@ -120,6 +101,10 @@ sub _run {
         return $self->_get_next_run_queue_response;
     }
 
+    if ( $self->verbose ) {
+        say STDERR "Running command: @command";
+    }
+
     # XXX yeah, this needs to be more robust
     return capture_stdout { system(@command) };
 }
@@ -127,6 +112,9 @@ sub _run {
 # same as _run, but don't let it die
 sub _run_without_die {
     my ( $self, @command ) = @_;
+    if ( $self->verbose ) {
+        say STDERR "Running command: @command";
+    }
     return capture_stdout {
         no autodie;
         system(@command);
@@ -164,8 +152,11 @@ sub run {
   FILE: foreach my $file (@files) {
         next FILE unless -e $file;    # it was deleted
         next FILE
-          unless -s _ < $self->max_file_size;    # large files are very painful
-        my $critique = $self->_run_without_die( 'perlcritic', $file );
+          unless -s _ < $self->max_file_size;    # large files are very slow
+        my $severity = $self->severity;
+        my $critique =
+          $self->_run_without_die( 'perlcritic', "--severity=$severity",
+            $file );
         next FILE unless $critique; # should never happen unless perlcritic dies
         my @critiques = split /\n/, $critique;
 
END
}
