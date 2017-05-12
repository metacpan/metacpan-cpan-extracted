use strict;
use warnings;
use Test::More;

my $obj = eval { Git::Class::Test::Role::Execute->new };
plan skip_all => $@ if $@;

# execute
subtest 'echo' => sub {
  my ($out, $err) = $obj->_execute(echo => 'foo');
  ok $out =~ /foo/, 'executed and captured successfully';
};

subtest 'echo_with_space' => sub {
  my ($out, $err) = $obj->_execute(echo => 'foo bar');
  ok $out =~ /foo bar/, 'looks like quote worked properly';
};

subtest 'tee' => sub {
  $obj->is_verbose(1);
  my ($out, $err) = $obj->_execute(echo => 'foo bar');
  ok $out =~ /foo bar/, 'you will see "foo bar" when you run "prove -lv"';
};

# get options
subtest 'get_options basic' => sub {
  my ($opts, @args) = $obj->_get_options(
    'arg1', { first => 'value1' }, 'arg2', { second => 'value2' },
  );
  ok $opts->{first} eq 'value1', 'got first option';
  ok $opts->{second} eq 'value2', 'got second option';
  ok $args[0] eq 'arg1', 'got first arg';
  ok $args[1] eq 'arg2', 'got second arg';
};

subtest 'options_with_same_key' => sub {
  my ($opts, @args) = $obj->_get_options(
    { key => 'value1' }, { key => 'value2' },
  );
  ok $opts->{key} eq 'value2', 'first option is overwritten';
};

subtest 'no_options' => sub {
  my ($opts, @args) = $obj->_get_options('foo');
  ok ref $opts eq 'HASH' && !%{ $opts }, 'got a blank hash reference';
  ok $args[0] eq 'foo', 'args are not affected';
};

# prepare options
subtest 'two_dashes_and_a_value' => sub {
  my $got = join ' ', $obj->_prepare_options({ key => 'value' });
  ok $got eq '--key=value', $got;
};

subtest 'two_dashes_and_a_blank' => sub {
  my $got = join ' ', $obj->_prepare_options({ key => '' });
  ok $got eq '--key', $got;
};

subtest 'one_dash_and_a_value' => sub {
  my $got = join ' ', $obj->_prepare_options({ k => 'value' });
  ok $got eq '-k value', $got;
};

subtest 'one_dash_and_a_blank' => sub {
  my $got = join ' ', $obj->_prepare_options({ k => '' });
  ok $got eq '-k', $got;
};

done_testing;

BEGIN {
  package #
    Git::Class::Test::Role::Execute;

  use Moo; with 'Git::Class::Role::Execute';

  has no_capture => (is => 'rw');
}
