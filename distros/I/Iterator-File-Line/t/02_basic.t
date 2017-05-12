use strict;
use Encode;
use Test::More (tests => 14);

BEGIN
{
    use_ok("Iterator::File::Line");
}

{
    my $string = join("\n",
        "line1",
        "line2"
    );
    open(my $fh, '<', \$string) or die;

    my $iter = Iterator::File::Line->new(fh => $fh);
    ok($iter);
    is($iter->next, "line1");
    is($iter->next, "line2");

    $iter->rewind();

    my $i = 0;
    while ($iter->next) {
        $i++;
        last if $i > 10; # safety
    }
    is($i, 2);
}


{
    my $string = join("\n",
        "line1",
        "line2"
    );
    open(my $fh, '<', \$string) or die;

    my $iter = Iterator::File::Line->new(fh => $fh, chomp => 0);
    ok($iter);
    is($iter->next, "line1\n");
    is($iter->next, "line2");
}

{
    my $string = join("\r\n",
        "line1",
        "line2"
    );
    open(my $fh, '<', \$string) or die;

    my $iter = Iterator::File::Line->new(fh => $fh, eol => "LF", chomp => 0);
    ok($iter);
    is($iter->next, "line1\n");
    is($iter->next, "line2");
}

{
    use utf8;
    my $string = join("\n", map { encode('euc-jp', $_) } (
        "日本語",
        "有限会社endeworks"
    ) );
    open(my $fh, '<', \$string) or die;

    my $iter = Iterator::File::Line->new(fh => $fh, encoding => 'euc-jp');
    ok($iter);
    is($iter->next, "日本語");
    is($iter->next, "有限会社endeworks" );
}


