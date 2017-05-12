package main;
use Evo 'Test::More; Evo::Di; Evo::Class::Meta; Evo::Internal::Exception';
use Evo '-Class::Syntax *';
use Module::Loaded qw(mark_as_loaded is_loaded);
use Symbol 'delete_package';

mark_as_loaded('My::Class');

NOT_EVO_CLASS: {
  my $di = Evo::Di->new();
  delete_package 'My::Class';
  ok !$di->_di_list_pending('My::Class');
  ok !$di->_di_list_pending('My::Class/foo');
  ok !$di->_di_list_pending('!@My::Class/foo');
}

sub reset_class($class = 'My::Class') {
  delete_package $class;
  eval "package $class; use Evo -Class";    ## no critic
  $class->META;
}

OK: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();
  my (@load_args, @is_loaded_args);

  no warnings 'redefine';
  local *Evo::Di::load      = sub { push @load_args,      @_; return };
  local *Evo::Di::is_loaded = sub { push @is_loaded_args, @_; return };

  $meta->reg_attr('d1', inject 'My::Dep1');
  $meta->reg_attr('d2', inject 'My::Dep2');
  my @unresolved = $di->_di_list_pending('My::Class');

  is_deeply \@unresolved,     ['My::Dep1', 'My::Dep2'];
  is_deeply \@load_args,      ['My::Dep1', 'My::Dep2'];
  is_deeply \@is_loaded_args, ['My::Dep1', 'My::Dep2'];
}

ALREADY_IN_STASH: {
  my $di = Evo::Di->new();
  $di->{di_stash}{'Foo/bar'} = 1;
  my $meta = reset_class();
  $meta->reg_attr('d1', inject 'Foo/bar',);
  ok !$di->_di_list_pending('My::Class');
}

DONT_LOAD_UNLESS_NEEDED: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();

  no warnings 'redefine';
  local *Evo::Di::load      = sub { fail "shouldn't be called" };
  local *Evo::Di::is_loaded = sub {1};

  $meta->reg_attr('d1', inject 'My::Dep1');
  $meta->reg_attr('d2', inject 'My::Dep2');
  my @unresolved = $di->_di_list_pending('My::Class');

  is_deeply \@unresolved, ['My::Dep1', 'My::Dep2'];
}

MISSING_REQUIRED_DIE: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();

  $meta->reg_attr('d1', inject 'My::Dep1',);
  like exception { $di->_di_list_pending('My::Class') }, qr/"My::Dep1" for class "My::Class".+$0/;
}

MISSING_BUT_NOT_REQUIRED: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();
  $meta->reg_attr('d1', inject 'My::Dep1', optional);
  ok !$di->_di_list_pending('My::Class');
}

done_testing;
