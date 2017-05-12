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

use Test::More tests => 9;

use Exception::Stringy;
Exception::Stringy->declare_exceptions(
  PermissionException => { fields => [ qw(login) ] },
  PermissionException2 => { isa => 'PermissionException' },
  PermissionException3 => { isa => 'PermissionException2',
                            fields => [ qw(password) ],
                          },
);

sub exception (&) { my ($coderef) = @_; local $@; eval { $coderef->() }; $@ }

is_deeply( [ sort Exception::Stringy->registered_exception_classes ],
           [ qw(PermissionException PermissionException2 PermissionException3) ],
           "exceptions properly registered" );

is_deeply( [ sort PermissionException->Fields ],
           [ qw(login) ],
           "exception 1 has proper fields" );

is_deeply( [ sort PermissionException2->Fields ],
           [ qw(login) ],
           "exception 2 has proper fields" );

is_deeply( [ sort PermissionException3->Fields ],
           [ qw(login password) ],
           "exception 3 has proper fields" );

{
    eval { PermissionException3->throw('This is the text', login => 'foo', password => 'bar') } 
    or do { my $e = $@;
            ok(index($e, "[PermissionException3|password:bar|login:foo|]This is the text") == 0
               ||
               index($e, "[PermissionException3|login:foo|password:bar|]This is the text") == 0,
               "exception content"
              );
            ok($e->$xisa('PermissionException3'), "exception is of right class 1");
            ok($e->$xisa('PermissionException2'), "exception is of right class 2");
            ok($e->$xisa('PermissionException'), "exception is of right class 3");
            is($e->$xclass, 'PermissionException3', "exception class is ok");
        };
}

