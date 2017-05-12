use warnings;
use strict;

use Dios;
use Test::More;

plan tests => 6;

my @SLURPED = ( \1, \2 );

func opt_slurp (Str $name, Str $checkname = $name, *@etc) {
    is $checkname, $name, 'checkname correct';
    is_deeply \@etc, \@SLURPED, 'slurpy slurped correctly';
}

subtest 'Default activated' => sub { opt_slurp('name', @SLURPED); };
subtest 'Default not needed' => sub { opt_slurp('name', 'name', @SLURPED); };

func opt_undef_slurp (Str $name, Str|Undef $checkname?, *@etc) {
    is $checkname, undef, 'checkname correct';
    is_deeply \@etc, \@SLURPED, 'slurpy slurped correctly';
}

subtest 'Undef default activated'  => sub { opt_undef_slurp('name', @SLURPED); };
subtest 'Undef default not needed' => sub { opt_undef_slurp('name', undef, @SLURPED); };

multi func opt_where_slurp (Str $name, $checkname? where { $_ =~ /name/ }, *@etc) {
    is $checkname, 'name', 'where(name) checkname correct';
    is_deeply \@etc, \@SLURPED, 'slurpy slurped correctly';
}

multi func opt_where_slurp (Str $name, $checkname? where { $_ !~ /name/ } = undef, *@etc) {
    is $checkname, undef, 'where(!name) checkname correct';
    is_deeply \@etc, \@SLURPED, 'slurpy slurped correctly';
}

subtest 'Where default activated'  => sub { opt_where_slurp('name', @SLURPED); };
subtest 'Where default not needed' => sub { opt_where_slurp('name', 'name', @SLURPED); };

done_testing();

