use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

# both of these names are synonyms
use File::Slurp qw(ef edit_file);
use Test::More;

plan tests => 18;

# this one intentionally doesn't exist on a couple of paths. can't be created.
my $file = temp_file_path('gimme a nonexistent path');

# edit_file errors
{
    my ($res, $warn, $err) = trap_function(\&edit_file, sub { s/foo/bar/g }, $file, {err_mode => 'quiet'});
    ok(!$warn, 'edit_file: err_mode opt quiet - no warn!');
    ok(!$err, 'edit_file: err_mode opt quiet - no exception!');
    ok(!$res, 'edit_file: err_mode opt quiet - no content!');
    ($res, $warn, $err) = trap_function(\&edit_file, sub { s/foo/bar/g }, $file, {err_mode => 'carp'});
    ok($warn, 'edit_file: err_mode opt carp - got warn!');
    ok(!$err, 'edit_file: err_mode opt carp - no exception!');
    ok(!$res, 'edit_file: err_mode opt carp - no content!');
    ($res, $warn, $err) = trap_function(\&edit_file, sub { s/foo/bar/g }, $file, {err_mode => 'croak'});
    ok(!$warn, 'edit_file: err_mode opt croak - no warn!');
    ok($err, 'edit_file: err_mode opt croak - got exception!');
    ok(!$res, 'edit_file: err_mode opt croak - no content!');
}

# ef errors
{
    my ($res, $warn, $err) = trap_function(\&ef, sub { s/foo/bar/g }, $file, {err_mode => 'quiet'});
    ok(!$warn, 'ef: err_mode opt quiet - no warn!');
    ok(!$err, 'ef: err_mode opt quiet - no exception!');
    ok(!$res, 'ef: err_mode opt quiet - no content!');
    ($res, $warn, $err) = trap_function(\&ef, sub { s/foo/bar/g }, $file, {err_mode => 'carp'});
    ok($warn, 'ef: err_mode opt carp - got warn!');
    ok(!$err, 'ef: err_mode opt carp - no exception!');
    ok(!$res, 'ef: err_mode opt carp - no content!');
    ($res, $warn, $err) = trap_function(\&ef, sub { s/foo/bar/g }, $file, {err_mode => 'croak'});
    ok(!$warn, 'ef: err_mode opt croak - no warn!');
    ok($err, 'ef: err_mode opt croak - got exception!');
    ok(!$res, 'ef: err_mode opt croak - no content!');
}
