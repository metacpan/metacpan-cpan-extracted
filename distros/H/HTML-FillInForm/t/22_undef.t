# -*- Mode: Perl; -*-

use strict;

$^W = 1;

use Test::More;

unless ( eval "use Test::Output; 1" ) {
    plan skip_all => 'These tests require Test::Output';
}

plan tests => 10;


use_ok('HTML::FillInForm');

{
    my $html = qq[
<form>
<input type="text" name="one" value="">
</form>
];

    stderr_is( sub { fill( $html, undef ) },
               '',
               'no warnings with undef value for input' );
}

{
    my $html = qq[
<form>
<textarea name="one"></textarea>
</form>
];

    stderr_is( sub { fill( $html, undef ) },
               '',
               'no warnings with undef value for textarea' );
}

{
    my $html = qq[
<form>
<select name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, undef ) },
               '',
               'no warnings with undef value for select' );
}

{
    my $html = qq[
<form>
<select name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, [] ) },
               '',
               'no warnings with empty array value for select' );
}

{
    my $html = qq[
<form>
<select name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, [ undef ] ) },
               '',
               'no warnings with array containing undef for select' );
}

{
    my $html = qq[
<form>
<select multiple="1" name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, undef ) },
               '',
               'no warnings with undef for multi select' );
}

{
    my $html = qq[
<form>
<select multiple="1" name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, [] ) },
               '',
               'no warnings with empty array for multi select' );
}

{
    my $html = qq[
<form>
<select multiple="1" name="one"><option value="">option</option></select>
</form>
];

    stderr_is( sub { fill( $html, [ undef ] ) },
               '',
               'no warnings with array containing undef for multi select' );
}

{
    my $html = qq[
<form>
<select multiple="1" name="one"><option value="">option</option><option value="2">option 2</option></select>
</form>
];

    stderr_is( sub { fill( $html, [ 1, undef ] ) },
               '',
               'no warnings with array containing undef as second value for multi select' );
}


sub fill {
    my $html = shift;
    my $val  = shift;

    HTML::FillInForm->new->fill_scalarref(
                                \$html,
                                fdat => {
                                  one => $val,
                                },
                                );
}
