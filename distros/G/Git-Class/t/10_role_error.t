use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture';
use Try::Tiny;

subtest 'basic' => sub {
  my $obj = Git::Class::Test::Role::Error->new;

  ok $obj->can('_die_on_error'), 'has _die_on_error accessor';
  ok $obj->can('is_verbose'), 'has is_verbose predicate';
  ok $obj->can('_error'), 'has _error accessor';

  ok !$obj->_die_on_error, '_die_on_error is false';
  ok !$obj->is_verbose, 'is_verbose is false';
};

subtest 'die_on_error' => sub {
  my $e;
  my $obj = try {
    Git::Class::Test::Role::Error->new(die_on_error => 1);
  } catch { $e = shift };
  ok !$e, 'object is successfully created';
  if ($e) {
    note 'object is not created';
    return;
  }

  ok $obj->_die_on_error, 'init_arg should work';

  undef $e;
  try { $obj->_error('set error') } catch { $e = shift };
  ok $e && $e =~ /set error/, 'error message is correct';

  $obj->_die_on_error(0);
  undef $e;
  my ($out, $err) = capture {
    try { $obj->_error('set error') } catch { $e = shift };
  };
  ok !$e && $err =~ /set error/, 'should not die';
};

subtest 'verbose' => sub {
  my $e;
  my $obj = try {
    Git::Class::Test::Role::Error->new(verbose => 1);
  } catch { $e = shift };
  ok !$e, 'object is successfully created';
  if ($e) {
    note 'object is not created';
    return;
  }
  ok $obj->is_verbose, 'init_arg should work';

  $obj->is_verbose(0);
  ok !$obj->is_verbose, 'can make it quite';
};

done_testing;

BEGIN {
  package #
    Git::Class::Test::Role::Error;

  use Moo; with 'Git::Class::Role::Error';
}
