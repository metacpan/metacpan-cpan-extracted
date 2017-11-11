
use Test::More;
use experimental qw(lexical_subs);

my sub ok { goto &Test::More::ok }

my sub stash_subs {
  my $stash = Jojo::Role::_getstash(shift);
  return grep { ref $_ eq 'CODE' || !ref $_ && *$_{CODE} } values %$stash;
}

# Are exports lexical?

{

  package Foo;
  use Jojo::Role;

  # after, around, before, requires, with
  ok(\&after    && !__PACKAGE__->can('after'),    q{"after" is lexical});
  ok(\&around   && !__PACKAGE__->can('around'),   q{"around" is lexical});
  ok(\&before   && !__PACKAGE__->can('before'),   q{"before" is lexical});
  ok(\&requires && !__PACKAGE__->can('requires'), q{"requires" is lexical});
  ok(\&with     && !__PACKAGE__->can('with'),     q{"with" is lexical});

  ok(!stash_subs(__PACKAGE__), 'no unexpected subs in stash');
}

{

  package Bah;
  use Jojo::Role -with;

  # with
  ok(\&with && !__PACKAGE__->can('with'), q{"with" is lexical});

  ok(!stash_subs(__PACKAGE__), 'no unexpected subs in stash');
}

done_testing;
