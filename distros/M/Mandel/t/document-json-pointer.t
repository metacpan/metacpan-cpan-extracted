use Mojo::Base -strict;
use Test::More;
use Mandel::Document;
use Data::Dumper;

my $doc = Mandel::Document->new;

{
  is $doc->set('/person/2/bruce', {age => 42}), $doc, 'set /person/2/bruce';
  is_deeply($doc->data, {person => [undef, undef, {bruce => {age => 42,},},],}, 'data is updated',);

  eval { $doc->set('/person/foo', 'whatever') };
  like $@, qr{Cannot set KEY in ARRAY for /person/foo \(foo\)}, 'cannot set /person/foo';

  is $doc->set('/person/2/bruce/address', 'Gotham'), $doc, 'set /person/2/bruce/address';

  eval { $doc->set('/person/2/bruce/address/42', 'whatever') };
  like $@, qr{Cannot set INDEX in SCALAR for /person/2/bruce/address/42 \(42\)},
    'cannot set /person/2/bruce/address/42';

  eval { $doc->set('/person/2/bruce/address/xyz', 'whatever') };
  like $@, qr{Cannot set KEY in SCALAR for /person/2/bruce/address/xyz \(xyz\)},
    'cannot set /person/2/bruce/address/xyz';

  is $doc->set('/person/4/doe', 42), $doc, 'set /person/4/doe';
  is $doc->set('/person/4', {}), $doc, 'reset /person/4';
  is $doc->set('/person/4', []), $doc, 'reset /person/4';
}

{
  is $doc->get('/person/2/bruce/age'), 42, 'get /person/2/bruce/age';
  is ref $doc->get('/person'), 'ARRAY', 'get /person';

  ok $doc->contains('/person'),             'doc contains /person';
  ok $doc->contains('/person/2/bruce/age'), 'doc contains /person/2/bruce/age';
  ok !$doc->contains('/person/2/foo/age'), 'doc does not contain /person/2/foo/age';
}

done_testing;
