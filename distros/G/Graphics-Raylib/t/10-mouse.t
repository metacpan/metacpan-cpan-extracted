use Test::More tests => 7;

use_ok 'Graphics::Raylib::Mouse';

my $mouse = Graphics::Raylib::Mouse->new;
my @pos = $mouse->position;
diag "Co-ords: $pos[0], $pos[1]";
ok $pos[0] >= 0;
ok $pos[1] >= 0;
is scalar @pos, 2;

@pos = Graphics::Raylib::Mouse::position();
diag "Co-ords: $pos[0], $pos[1]";
ok $pos[0] >= 0;
ok $pos[1] >= 0;
is scalar @pos, 2;
