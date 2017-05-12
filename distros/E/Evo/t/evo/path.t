use Evo 'Test::More; Evo::Path; -Internal::Exception';

TO_STRING: {
  my $path = Evo::Path->new(base => '/hello');
  is $path, '/hello/';

  $path = Evo::Path->from_string('bar', '/hello');
  is $path, '/hello/bar';
}

APPEND: {
  my $path = Evo::Path->new(base => '/hello');
  $path = $path->append('///');
  ok !$path->children->@*;
  $path = $path->append('///1///2///');
  is_deeply $path->children, [1, 2];

  $path = Evo::Path->new()->append('./foo');
  is_deeply $path->children, ['foo'];

  $path = Evo::Path->new()->append('.');
  is_deeply $path->children, [];

  $path = Evo::Path->new()->append('.//');
  is_deeply $path->children, [];

  $path = Evo::Path->new()->append('.foo');
  is_deeply $path->children, ['.foo'];
}


TO_STRING: {
  my $path = Evo::Path->new(children => [1, 2]);
  is $path->to_string, "/1/2";
  is "$path", '/1/2';

  $path = Evo::Path->new(base => '/foo', children => [1, 2]);
  is $path->to_string, "/foo/1/2";

  $path = Evo::Path->new(base => 'foo://', children => [1, 2]);
  is $path->to_string, "foo://1/2";

  $path = Evo::Path->new(base => 'foo://bar', children => [1, 2]);
  is $path->to_string, "foo://bar/1/2";

  $path = Evo::Path->new(base => 'foo://bar/', children => [1, 2]);
  is $path->to_string, "foo://bar/1/2";
}

SAFE_UNSAFE: {
  my $path = Evo::Path->new(base => '/base');
  like exception { $path->append('../foo'); },      qr/append_unsafe/i;
  like exception { $path->append('/foo/../bar'); }, qr/append_unsafe/i;
  is $path->append_unsafe('/foo/../bar')->to_string, '/base/foo/../bar';
}

FROM_STRING: {
  my $path = Evo::Path->from_string('/a/b/');
  is $path->base, '/';
  is_deeply $path->children, [qw(a b)];

  $path = Evo::Path->from_string();
  is $path->base, '/';
  is_deeply $path->children, [];

  is(Evo::Path->from_string('p',   '/base')->to_string, '/base/p');
  is(Evo::Path->from_string('/p/', '/base')->to_string, '/base/p');
  like exception { Evo::Path->from_string('../foo', '/base') }, qr/append_unsafe/;
}


done_testing;
