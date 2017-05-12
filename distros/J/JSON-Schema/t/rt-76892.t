=head1 PURPOSE

Test that an empty C<additionalProperties> is a no-op.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=76892>.

=head1 AUTHOR

Piotr Piatkowski

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Piotr Piatkowski

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use Test::More tests => 2;
use JSON::Schema;

my $schema = {
    type => 'object',
    properties => {
        x => { type => 'integer' },
    },
};

my $doc = {
    foo => 123,
};

my $res = JSON::Schema->new($schema)->validate($doc);
ok($res, "Object with extra property is valid") or diag(join("\n", $res->errors));

$schema->{additionalProperties} = {};
my $res2 = JSON::Schema->new($schema)->validate($doc);
ok($res2, "Same with added empty additionalProperties") or diag(join("\n", $res2->errors));
