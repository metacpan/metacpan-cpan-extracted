#!perl
#
# This file is part of Exception-Stringy
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#

use strict;
use warnings;

use Test::More tests => 58;

use Exception::Stringy;

Exception::Stringy->declare_exceptions(
  PermissionException => { fields => [ qw(login password) ] },
  'PermissionException2',
);

sub exception (&) { my ($coderef) = @_; local $@; eval { $coderef->() }; $@ }

is_deeply( [ sort Exception::Stringy->registered_exception_classes ],
           [ qw(PermissionException PermissionException2) ],
           "exceptions properly registered" );

# test the declare_exceptions
is( exception { Exception::Stringy->declare_exceptions },
     '',
     "no class is good" );

like( exception { Exception::Stringy->declare_exceptions(undef) },
      qr/class '<undef>' is invalid/,
      "dies when class undef" );

like( exception { Exception::Stringy->declare_exceptions('1plop') },
      qr/class '1plop' is invalid/,
      "dies when class starts with number" );

like( exception { Exception::Stringy->declare_exceptions('|plop') },
      qr/class '|plop' is invalid/,
      "dies when class contains |" );

like( exception { Exception::Stringy->declare_exceptions('pl op') },
      qr/class 'pl op' is invalid/,
      "dies when class contains space" );

like( exception { Exception::Stringy->declare_exceptions(Foo => { fields => [ '1plop' ] }) },
      qr/field '1plop' is invalid/,
      "dies when field starts with number" );

like( exception { Exception::Stringy->declare_exceptions('PermissionException') },
      qr/class 'PermissionException' is invalid. It has already been registered/,
      "dies when exception class is repeated" );

like( exception { Exception::Stringy->declare_exceptions(Foo => { fields => [ '|plop' ] }) },
      qr/field '\|plop' is invalid/,
      "dies when field contains |" );

like( exception { Exception::Stringy->declare_exceptions(Foo => { fields => [ 'pl op' ] }) },
      qr/field 'pl op' is invalid/,
      "dies when field contains space" );


is_deeply( PermissionException->_fields_hashref(),
           { login => 1,
             password => 1,
           },
           "fields have been properly declared" );

{
    my $e = PermissionException->new('This is the text');
    is($e, '[PermissionException||]This is the text', "exception without fields looks good");
    is_deeply([ $e->$xfields ], [], "exception contains no fields");
    is_deeply([ $e->$xfields ], [], "exception contains no fields");
    is_deeply([ sort $e->$xclass->registered_fields ],
              [ qw(login password) ], "listing possible fields");
    ok($e->$xisa('PermissionException'), "exception isa PermissionException");
    is($e->$xclass, 'PermissionException', "exception class is ok");
    ok(! $e->$xisa('PermissionException2'), "exception is not a PermissionException2");
    ok($e->$xisa('Exception::Stringy'), "exception is a Exception::Stringy");
    is($e->$xmessage, "This is the text", "exception has the right message");
}

{
    my $e = PermissionException->new('This is the text');
    $e->$xfield(login => 1);
    $e->$xfield(password => 1);
    is($e, '[PermissionException|login:1|password:1|]This is the text',
       "exception + fields looks good");
    is_deeply([sort $e->$xfields], [qw(login password)],
              "exception contains the right fields" );
}

{
    my $e = PermissionException->new('This is the text');
    $e->$xfield(login => 1);
    $e->$xfield(password => 1);
    is($e, '[PermissionException|login:1|password:1|]This is the text',
       "exception + fields looks good");
    is_deeply([sort $e->$xfields], [qw(login password)],
              "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => 1, password => 1);
    is_deeply([sort $e->$xfields], [qw(login password)],
              "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => 1);
    is($e, '[PermissionException|login:1|]This is the text', "exception + fields looks good");
    ok($e->$xfield('login'), "exception has login");
    ok(!$e->$xfield('password'), "exception doesn't have login");
    is_deeply([sort $e->$xfields], [qw(login)], "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => "foobarbaz");
    is($e, '[PermissionException|login:foobarbaz|]This is the text',
       "login is normal");
    $e = PermissionException->new('This is the text', login => "");
    is($e, '[PermissionException|login:|]This is the text',
       "exception string with login empty");
    is($e->$xfield('login'), '',
       "login is empty");
    $e = PermissionException->new('This is the text', login => undef);
    is($e, '[PermissionException|login:|]This is the text',
       "exception string with login undef");
    is($e->$xfield('login'), '',
       "login is empty");
    $e = PermissionException->new('This is the text', login => "in base \034 64");
    is($e, "[PermissionException|login:\034aW4gYmFzZSAcIDY0|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), "in base \034 64",
       "exception + field properly decodes");
    $e = PermissionException->new('This is the text', login => ":should be base64");
    is($e, "[PermissionException|login:\034OnNob3VsZCBiZSBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), ":should be base64",
       "exception + field properly decodes");
    $e = PermissionException->new('This is the text', login => "should be| base64");
    is($e, "[PermissionException|login:\034c2hvdWxkIGJlfCBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), "should be| base64",
       "exception + field properly decodes");
}

{
    my $e = PermissionException->new();
    $e->$xerror('This is the text');
    $e->$xfield(login => 'foobarbaz');
    is($e, '[PermissionException|login:foobarbaz|]This is the text',
       "login is normal");
    $e->$xfield(login => "");
    is($e, '[PermissionException|login:|]This is the text',
       "exception string with login empty");
    is($e->$xfield('login'), '',
       "login is empty");
    $e->$xfield( login => "in base \034 64");
    is($e, "[PermissionException|login:\034aW4gYmFzZSAcIDY0|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), "in base \034 64",
       "exception + field properly decodes");
    $e->$xfield( login => ":should be base64");
    is($e, "[PermissionException|login:\034OnNob3VsZCBiZSBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), ":should be base64",
       "exception + field properly decodes");
    $e->$xfield( login => "should be| base64");
    is($e, "[PermissionException|login:\034c2hvdWxkIGJlfCBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$xfield('login'), "should be| base64",
       "exception + field properly decodes");
}

{
    my $e = PermissionException2->new('This is the text');
    is($e, '[PermissionException2||]This is the text', "exception2 without fields looks good");
    is_deeply([$e->$xfields], [], "exception contains no fields");
}

{
    like( exception { PermissionException2->new('This is the text', login => 1) },
          qr/invalid field 'login', exception class 'PermissionException2' didn't declare it/,
          "exception2 with invalid field" );
}

{
    eval { PermissionException->throw('This is the text', qw(login password)) }
    or do { my $e = $@;
            ok($e->$xisa('PermissionException'), "exception is of right class");
            ok($e->$xisa('Exception::Stringy'), "exception inherits Exception::Stringify");
            is($e->$xclass, 'PermissionException', "exception class is ok");
        };
}

{
    my $e = PermissionException2->new('This is the text');
    ok($e->$xisa('Exception::Stringy'), "it's an exception");
}

{
    # test with an instance based exception
    my $e = bless({}, 'PermissionException2');
    ok($e->$xisa('Exception::Stringy'), "xisa works on blessed references");
}

{
    # test with an instance based exception
    my $e = "plop";
    ok( ! $e->$xisa('Exception::Stringy'), "xisa doesn't blow up on other things");
}
