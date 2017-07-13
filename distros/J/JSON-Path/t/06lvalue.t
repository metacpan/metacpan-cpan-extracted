
=head1 PURPOSE

Basic tests for some of the lvalue stuff.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use warnings;
use Test::More;

use JSON::Path -all;

my $person = { name => "Robert", foo => { bar => [ 1, 2, 3 ] } };
my $path = JSON::Path->new('$.name');
$path->value($person) = "Bob";

is_deeply( $person, { name => "Bob", foo => { bar => [ 1, 2, 3 ] } } , q{Setting 'name' changes only the 'name' key and nothing else});

jpath1( $person, '$.name' )    = "Robbie";
jpath1( $person, '$.foo.bar' ) = 12;

is_deeply( $person, { name => "Robbie", foo => { bar => 12 } }, q{jpath1() works as lvalue});
$path->value($person) ||= 'Fred';
is $person->{name}, 'Robbie', q{lvalue works with ||=};

$path = JSON::Path->new('$.quux');
$path->value($person) = 'alpha';
is $person->{quux}, 'alpha', q{lvalue will create keys not previously extant};

$path = JSON::Path->new('$.quuy');
$path->value($person) ||= 'beta';
is $person->{quuy}, 'beta', q{lvalue and ||= will create keys not previously extant};

done_testing;

