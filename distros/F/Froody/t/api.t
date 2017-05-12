#!/usr/bin/perl -w

#########################################################################
# This tests loads an xml based API (Testobject::API) and makes sure that 
# the right things are set up in the repository
#########################################################################

use strict;
use lib 't/lib';

use Data::Dumper;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

use Test::More tests => 49;
use Test::Exception;
use Test::Differences;

# this is where we keep our modules
use Froody::Repository;
use Test::Logger;

use Scalar::Util qw(blessed);

# load our test API
use_ok ('Testproject::API');

{
  my @stuff = Testproject::API->load();

  # Check we got our methods back
  my @methods = grep { blessed($_) && $_->isa("Froody::Method") } @stuff;
  my $methods = { map { $_->full_name => 1 } @methods };
    
  # Check we got our error types back
  my @et = grep { blessed($_) && $_->isa("Froody::ErrorType") } @stuff;
  is(@et, 2, "got two error types back from the api");
  my $et = { map { $_->name => 1 } @et };
  is_deeply($et, { map { $_ => 1 } qw(
     foo.fish
     foo.fish.fred
  )},"got the right error type names")

}

# ignore the previous methods, and just load up Testproject::Service
# that will register them for us
use_ok("Testproject::Object");
my $repos = Froody::Repository->new();
Testproject::Object->register_in_repository($repos);

# okay, so I removed the ability for the framework to be called on just
# method names, now you need to invoke with a proper Froody::Method.  This
# makes sense from the way the API is now used (since nothing but the
# method object should really be calling invoke,) but makes testing a bit more
# painful.
my $email    = $repos->get_method('testproject.object.email');
my $text     = $repos->get_method('testproject.object.text');
my $sum      = $repos->get_method('testproject.object.sum');
my $texttest = $repos->get_method('testproject.object.texttest');
my $extra    = $repos->get_method('testproject.object.extra');
my $range    = $repos->get_method('testproject.object.range');
my $range2   = $repos->get_method('testproject.object.range2');
my $params   = $repos->get_method('testproject.object.params');
my $get      = $repos->get_method('testproject.object.get');
foreach ($email, $text, $sum, $texttest, $extra, $range, $range2, $params)
 { isa_ok($_, 'Froody::Method') }

my $metadata = { repository => $repos, dispatcher => Froody::Dispatch->new };

{
  my $resp = $email->call({ email_trim => 'test@fotango.com'}, $metadata);
  is( $resp->status, 'ok' );
}

{
  my $resp = $email->call({ email_trim => '  test@fotango.com  '}, $metadata);
  is( $resp->status, 'ok' );
}

{
  my $resp = $email->call({ email_trim => '  test @fotango.com  '}, $metadata);
  is( $resp->status, 'fail' );
  like $resp->message, qr{Error validating incoming parameters}, "bad arg";
  is($resp->data->{error}[0]{-text}, 'Email not valid');
  is($resp->data->{error}[0]{name}, 'email_trim');
}

{
  my $resp = $email->call({ email => '  test@fotango.com  '}, $metadata);
  is( $resp->status, 'fail' );
  like $resp->message, qr{Error validating incoming parameters}, "bad arg";
  is($resp->data->{error}[0]{-text}, 'Email not valid');
  is($resp->data->{error}[0]{name}, 'email');
}

dies_ok {
    Froody::API->load
} 'need to override ::load';

lives_ok {
    $text->call({}, $metadata);
} "we can invoke thingy.text without errors";

lives_ok {
    my $ret = $get->call({});
    is($ret->content, 'myget reached');
} "we can invoke get without errors";

{
  my $result = $sum->call({ values => '10,20,30'}, $metadata)->as_terse->content;
  is_deeply ( $result, 60, 'multi argument handling')
    or diag(Dumper $result);

  $result = $sum->call({ values => [10,20,30] }, $metadata)->as_terse->content;
  is_deeply ( $result, 60, 'multi argument handling')
    or diag(Dumper $result);
}

{
  my $resp = $sum->call({ values => '10,20f,30'}, $metadata);
  like $resp->message, qr{Error validating incoming parameters}, "bad arg";
  is($resp->data->{error}[0]{-text}, 'not a number');
}



isa_ok( my $resp = $sum->call({ values => undef }, $metadata), "Froody::Response", "called with bad argument");
like( $resp->message, qr{Error validating incoming parameters}, "bad arg");

isa_ok( $resp = $sum->call({}, $metadata), "Froody::Response", "called with missing argument");
like( $resp->message, qr{Error validating incoming parameters}, "missing");

is_deeply($resp = $range->call({ base => 90, offset => 10 }, $metadata)->as_terse->content,
    { value => [ 80, 100] },"range") or diag Dumper($resp);

is_deeply($resp = $range2->call({ base => 90, offset => 10 }, $metadata)->as_terse->content,
    { value => [ { num => 80}, { num => 100 } ] }, "range2") or diag Dumper($resp); 

{
  my $log = Test::Logger->expect(["froody.walker.terse",
				  warn => qr/unknown key 'blah' defined/]);

  is_deeply($resp = $extra->call({}, $metadata)->as_terse->content, { value => []}, "wibble")
    or diag Dumper($resp);
}

is_deeply($params->call( { bob => 'baz', fred => "wobble" }, $metadata )
  ->as_terse->content, 2, "remaining params passed ok");

is_deeply($params->call( { this_one => 1 }, $metadata)
  ->as_terse->content, 0, "can pass no params and it still works.");


#### test the errortypes #####

my $default = $repos->get_errortype('');
my $fish = $repos->get_errortype('foo.fish');
my $fred = $repos->get_errortype('foo.fish.fred');
foreach ($fish, $fred, $default)
 { isa_ok($_, 'Froody::ErrorType') }

is($fish->name, 'foo.fish', "fish name");
is($fred->name, 'foo.fish.fred', "fred name");
is($default->name, '', "default name");

eq_or_diff($fish->structure, {
            'err' => {
                     'elts'  => [ 'foo' ],
                     'attr'  => [ 'code', 'msg' ],
                     'multi' => 0,
                     'text' => 0,
                   },
            'err/foo' => {
              elts => [],
              attr => [],
              text => 1,
              multi=> 0
            },
            '' => {
                    'elts' => [
                                'err'
                              ],
                    'text' => 0,
                    'multi' => 0,
                    'attr' => []
                  },

}, "fish struct");

eq_or_diff($fred->structure, {
          'err/bars/bar' => {
                            'elts' => [],
                            'text' => 1,
                            'multi' => 1,
                            'attr' => []
                          },
          'err/bars' => {
                        'elts' => [ 'bar' ],
                        'attr' => [],
                        multi => 0,
                        text => 0,
                      },
          'err/foo' => {
              elts => [],
              attr => [],
              multi => 0,
              text => 1
          },
          'err' => {
                     'elts' => [ 'bars', 'foo' ],
                     'attr' => [ 'code', 'msg' ],
                     'multi' => 0,
                      'text' => 0,
                   },
          '' => {
                  'elts' => [
                              'err'
                            ],
                  'text' => 0,
                  'multi' => 0,
                  'attr' => []
                },

}, "fred struct");

eq_or_diff($default->structure, {
  'err' => {
           'elts' => [ ],
           'attr' => [
                       'code',
                       'msg'
                     ]
         },
}, "default struct");
