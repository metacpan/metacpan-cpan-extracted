use strict;
use Test::More (tests => 4);

BEGIN
{
    use_ok("Iterator::File::Line");
}

{
    my $string = join("\n",
        "col1\tcol2\tcol3",
        "col4\tcol5\tcol6",
    );
    open(my $fh, '<', \$string) or die;

    my $iter = Iterator::File::Line->new(
        fh => $fh,
        filter => sub { return [ split(/\t/, $_[0]) ] }
    );
    ok($iter);
    is_deeply($iter->next, [ qw(col1 col2 col3) ]);
    is_deeply($iter->next, [ qw(col4 col5 col6) ]);
}
