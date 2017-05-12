package main;
use Evo 'Test::More; -Class::Attrs *; -Class::Syntax *; -Class::Meta; -Internal::Exception';

sub parse { Evo::Class::Meta->parse_attr('name', @_); }

ERRORS: {
  like exception { parse 'foo', 'ro' }, qr/foo,ro.+$0/;
  like exception { parse optional, 'foo' }, qr/"optional".+"foo".+$0/;
  like exception { parse lazy }, qr/"lazy".+code reference.+$0/;
  like exception { parse lazy, {} }, qr/"lazy".+code reference.+$0/;
  like exception { parse lazy, 'foo' }, qr/"lazy".+code reference.+$0/;
  like exception { parse {} }, qr/default\("HASH(.+)"\).+code reference.+$0/;
}

my %co = (name => 'name', method => 1);
PARSE: {
  my ($dc, $check) = (sub {1}, sub {2});
  is_deeply { parse() },
    {%co, type => ECA_REQUIRED, value => undef, check => undef, ro => '', inject => undef,};
  is_deeply { parse(ro) },
    {type => ECA_REQUIRED, value => undef, check => undef, ro => 1, inject => undef, %co};

  is_deeply { parse(optional) },
    {type => ECA_OPTIONAL, value => undef, check => undef, ro => '', inject => undef, %co};
  is_deeply { parse(optional, ro) },
    {type => ECA_OPTIONAL, value => undef, check => undef, ro => 1, inject => undef, %co};

  is_deeply { parse('val') },
    {type => ECA_DEFAULT, value => 'val', check => undef, ro => '', inject => undef, %co};

  is_deeply { parse('val', ro) },
    {type => ECA_DEFAULT, value => 'val', check => undef, ro => 1, inject => undef, %co};


  is_deeply { parse($dc) },
    {type => ECA_DEFAULT_CODE, value => $dc, check => undef, ro => '', inject => undef, %co};
  is_deeply { parse($dc, ro) },
    {type => ECA_DEFAULT_CODE, value => $dc, check => undef, ro => 1, inject => undef, %co};

  is_deeply { parse($dc, lazy) },
    {type => ECA_LAZY, value => $dc, check => undef, ro => '', inject => undef, %co};

  is_deeply { parse(ro, $dc, lazy) },
    {type => ECA_LAZY, value => $dc, check => undef, ro => 1, inject => undef, %co};

  is_deeply { parse(optional) },
    {type => ECA_OPTIONAL, value => undef, check => undef, ro => '', inject => undef, %co};

  is_deeply { parse(optional, ro) },
    {type => ECA_OPTIONAL, value => undef, check => undef, ro => 1, inject => undef, %co};

  is_deeply { parse(inject 'Foo::Bar') },
    {type => ECA_REQUIRED, value => undef, check => undef, ro => '', inject => 'Foo::Bar', %co};

  is_deeply { parse(optional, ro, inject 'Foo::Bar') },
    {type => ECA_OPTIONAL, value => undef, check => undef, ro => 1, inject => 'Foo::Bar', %co};

  is_deeply { parse(check $check) },
    {type => ECA_REQUIRED, value => undef, check => $check, ro => '', inject => undef, %co};

  is_deeply { parse(ro, optional, check $check) },
    {type => ECA_OPTIONAL, value => undef, check => $check, ro => 1, inject => undef, %co};

  is_deeply { parse(no_method) },
    {
    type   => ECA_REQUIRED,
    value  => undef,
    check  => undef,
    ro     => '',
    inject => undef,
    method => '',
    name   => 'name',
    };
}

done_testing;
