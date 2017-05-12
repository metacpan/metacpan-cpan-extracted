=head1 PURPOSE

Test that schema unions work.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=80083>.

=head1 AUTHOR

DAVIDIAM

=head1 COPYRIGHT AND LICENCE

Copyright 2012 DAVIDIAM.

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use Test::More;
use strict;
use warnings;
use JSON::Schema;

#primitive types are object, array, string, number, integer, boolean, null or any

my $schema1 = JSON::Schema->new(
                { type => 'object'
                , additionalProperties => 0
                , properties =>
                        { test =>
                                { type => [ 'boolean', 'integer' ]
                                , required => 1
                                }
                        }
                } );

my $schema2 = JSON::Schema->new(
                { type => 'object'
                , additionalProperties => 0
                , properties =>
                        { test =>
                                { type =>
                                        [ { type=>"object"
                                                , additionalProperties => 0
                                                , properties=>
                                                        { dog => { type=>"string", required=>1 } }
                                                }
                                        , { type => "object"
                                                , additionalProperties => 0
                                                , properties =>
                                                  { sound =>
                                                                { type => 'string'
                                                                , enum => ["bark","meow","squeak"]
                                                                , required => 1
                                                                }
                                                        }
                                                }
                                        ]
                                , required => 1
                                }
                        }
                });

my $schema3 = JSON::Schema->new(
                { type => 'object'
                , additionalProperties => 0
                , properties =>
                        { test =>
                                { type => [ qw/object array string number integer boolean null/ ], required => 1 }
                        }
                } );

my $result = $schema1->validate({ test => "strang" });
ok !$result->valid, 'boolean or integer against string'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => 1 });
ok $result->valid, 'boolean or integer against integer'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => [ 'array' ] });
ok not($result->valid), 'boolean or integer against array'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => { object => 'yipe' } });
ok !$result->valid, 'boolean or integer against object'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => 1.1 });
ok not($result->valid), 'boolean or integer against number'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => !!1 });
ok $result->valid, 'boolean or integer against boolean'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({ test => undef });
ok !$result->valid, 'boolean or integer against null'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => { dog => "woof" } });
ok $result->valid, 'object or object against object a'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => { sound => "meow" } });
ok $result->valid, 'object or object against object b nested enum pass'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => { sound => "oink" } });
ok not($result->valid), 'object or object against object b enum fail'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => { audible => "meow" } });
ok !$result->valid, 'object or object against invalid object'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => 2 });
ok !$result->valid, 'object or object against integer'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => 2.2 });
ok !$result->valid, 'object or object against number'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => !1 });
ok !$result->valid, 'object or object against boolean'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => undef });
ok !$result->valid, 'object or object against null'
  or map { diag "reason: $_" } $result->errors;

$result = $schema2->validate({ test => { dog => undef } });
ok not($result->valid), 'object or object against object a bad inner type'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => { dog => undef } });
ok $result->valid, 'all types against object'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => [ 'dog' ] });
ok $result->valid, 'all types against array'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => 'dog' });
ok $result->valid, 'all types against string'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => 1.1 });
ok $result->valid, 'all types against number'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => 1 });
ok $result->valid, 'all types against integer'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => 1 });
ok $result->valid, 'all types against boolean'
  or map { diag "reason: $_" } $result->errors;

$result = $schema3->validate({ test => undef });
ok $result->valid, 'all types against null'
  or map { diag "reason: $_" } $result->errors;

done_testing;
