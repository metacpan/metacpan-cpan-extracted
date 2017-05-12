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

use Exception::Stringy method_prefix => '_x_';
BEGIN { Exception::Stringy->declare_exceptions(
  PermissionException => { fields => [ qw(login password) ], throw_alias => 'throw_plop' },
  'PermissionException2',
  ExceptionAliasOnly => { throw_alias => 'throw_me' },
  ExceptionNameAlias => { name_alias => 'Plop' },
);
    }

sub exception (&) { my ($coderef) = @_; local $@; eval { $coderef->() }; $@ }

is_deeply( [ sort Exception::Stringy->registered_exception_classes ],
           [ qw(ExceptionAliasOnly ExceptionNameAlias PermissionException PermissionException2) ],
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
    is_deeply([ $e->$_x_fields ], [], "exception contains no fields");
    is_deeply([ sort $e->$_x_class->registered_fields ],
              [ qw(login password) ], "listing possible fields");
    ok($e->$_x_isa('PermissionException'), "exception isa PermissionException");
    is($e->$_x_class, 'PermissionException', "exception class is ok");
    ok(! $e->$_x_isa('PermissionException2'), "exception is not a PermissionException2");
    ok($e->$_x_isa('Exception::Stringy'), "exception is a Exception::Stringy");
    is($e->$_x_message, "This is the text", "exception has the right message");
}

{
    my $e = PermissionException->new('This is the text');
    $e->$_x_field(login => 1);
    $e->$_x_field(password => 1);
    is($e, '[PermissionException|login:1|password:1|]This is the text',
       "exception + fields looks good");
    is_deeply([sort $e->$_x_fields], [qw(login password)],
              "exception contains the right fields" );
}

{
    my $e = PermissionException->new('This is the text');
    $e->$_x_field(login => 1);
    $e->$_x_field(password => 1);
    is($e, '[PermissionException|login:1|password:1|]This is the text',
       "exception + fields looks good");
    is_deeply([sort $e->$_x_fields], [qw(login password)],
              "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => 1, password => 1);
    is_deeply([sort $e->$_x_fields], [qw(login password)],
              "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => 1);
    is($e, '[PermissionException|login:1|]This is the text', "exception + fields looks good");
    ok($e->$_x_field('login'), "exception has login");
    ok(!$e->$_x_field('password'), "exception doesn't have login");
    is_deeply([sort $e->$_x_fields], [qw(login)], "exception contains the right fields");
}

{
    my $e = PermissionException->new('This is the text', login => "foobarbaz");
    is($e, '[PermissionException|login:foobarbaz|]This is the text',
       "login is normal");
    $e = PermissionException->new('This is the text', login => "");
    is($e, '[PermissionException|login:|]This is the text',
       "exception string with login empty");
    is($e->$_x_field('login'), '',
       "login is empty");
    $e = PermissionException->new('This is the text', login => "in base \034 64");
    is($e, "[PermissionException|login:\034aW4gYmFzZSAcIDY0|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), "in base \034 64",
       "exception + field properly decodes");
    $e = PermissionException->new('This is the text', login => ":should be base64");
    is($e, "[PermissionException|login:\034OnNob3VsZCBiZSBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), ":should be base64",
       "exception + field properly decodes");
    $e = PermissionException->new('This is the text', login => "should be| base64");
    is($e, "[PermissionException|login:\034c2hvdWxkIGJlfCBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), "should be| base64",
       "exception + field properly decodes");
}

{
    my $e = PermissionException->new();
    $e->$_x_error('This is the text');
    $e->$_x_field(login => 'foobarbaz');
    is($e, '[PermissionException|login:foobarbaz|]This is the text',
       "login is normal");
    $e->$_x_field(login => "");
    is($e, '[PermissionException|login:|]This is the text',
       "exception string with login empty");
    is($e->$_x_field('login'), '',
       "login is empty");
    $e->$_x_field( login => "in base \034 64");
    is($e, "[PermissionException|login:\034aW4gYmFzZSAcIDY0|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), "in base \034 64",
       "exception + field properly decodes");
    $e->$_x_field( login => ":should be base64");
    is($e, "[PermissionException|login:\034OnNob3VsZCBiZSBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), ":should be base64",
       "exception + field properly decodes");
    $e->$_x_field( login => "should be| base64");
    is($e, "[PermissionException|login:\034c2hvdWxkIGJlfCBiYXNlNjQ=|]This is the text",
       "exception + fields looks good");
    is($e->$_x_field('login'), "should be| base64",
       "exception + field properly decodes");
}

{
    my $e = PermissionException2->new('This is the text');
    is($e, '[PermissionException2||]This is the text', "exception2 without fields looks good");
    is_deeply([$e->$_x_fields], [], "exception contains no fields");
}

{
    like( exception { PermissionException2->new('This is the text', login => 1) },
          qr/invalid field 'login', exception class 'PermissionException2' didn't declare it/,
          "exception2 with invalid field" );
}

{
    eval { PermissionException->throw('This is the text', login => 'foo') } 
    or do { my $e = $@;
            ok($e->$_x_isa('PermissionException'), "exception is of right class");
            ok($e->$_x_isa('Exception::Stringy'), "exception inherits Exception::Stringify");
            is($e->$_x_class, 'PermissionException', "exception class is ok");
        };
}

{
    eval { throw_me('This is the text') }
    or do { my $e = $@;
            ok($e->$_x_isa('ExceptionAliasOnly'), "exception is of right class");
            ok($e->$_x_isa('Exception::Stringy'), "exception inherits Exception::Stringify");
            is($e->$_x_class, 'ExceptionAliasOnly', "exception class is ok");
        };
}

{
    my $e = PermissionException2->new('This is the text');
    ok($e->$_x_isa('Exception::Stringy'), "it's an exception");
}

like( exception { Exception::Stringy->declare_exceptions(NewException => { throw_alias => 'throw_me' }) },
      qr/throw_alias 'throw_me' is invalid. It has already been defined/,
      "dies when throw_alias is repeated" );

{
    my $e = Plop->new('This is the text');
    ok($e->$_x_isa(Plop), "it's the right aliased exception");
}
