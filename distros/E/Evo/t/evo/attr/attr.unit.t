package main;
use Evo 'Test::More; -Internal::Util';
use Evo::Attr;
use Evo::Internal::Exception;
use Evo::Internal::Util;

no warnings 'once';

PREPARE_PACKAGE: {
  local *My::Provider::MODIFY_CODE_ATTRIBUTES;
  Evo::Attr->patch_package('My::Provider1');
  Evo::Attr->patch_package('My::Provider2');
  is(My::Provider1->can('MODIFY_CODE_ATTRIBUTES'), My::Provider2->can('MODIFY_CODE_ATTRIBUTES'));
}

REGISTER_HANDLER: {
  local %Evo::Attr::HANDLERS;
  Evo::Attr::register_attribute('My::Provider1', H1 => sub { });
  like exception {
    Evo::Attr::register_attribute('My::Provider1', H1 => sub { });
  }, qr/H1.+My::Provider1.+$0/;
}

PARSE_ATTR: {
  is_deeply([Evo::Attr::parse_attr('Name(one, two)')], [qw(Name one two)]);
  is_deeply([Evo::Attr::parse_attr('Name(one)')],      [qw(Name one)]);
  is_deeply([Evo::Attr::parse_attr('Name()')],         [qw(Name)]);
  is_deeply([Evo::Attr::parse_attr('Name')],           [qw(Name)]);
}

INVOKE_HANDLERS: {
  local %Evo::Attr::HANDLERS;

  my @calls;
  local *My::Dest::mysub;
  sub My::Dest::mysub { }
  Evo::Attr::register_attribute('My::Provider1', H1 => sub { push @calls, \@_ });
  my @bad = Evo::Attr::invoke_handlers('My::Dest', \&My::Dest::mysub, 'H1(a,b, c)', 'Bad');
  is_deeply \@bad, [qw(Bad)];
  is_deeply \@calls, [['My::Dest', \&My::Dest::mysub, 'mysub', 'a', 'b', 'c']];

}


done_testing;
