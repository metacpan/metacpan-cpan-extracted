use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'Wassr' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Wassr script - test1
--- input
<script type="text/javascript" src="http://wassr.jp/js/WassrBlogParts.js"></script>
--- expected
Wassr

=== Wassr script - test2
--- input
<script type="text/javascript">wassr_host = "wassr.jp";wassr_userid = "kentaro";wassr_defaultview = "";wassr_bgcolor="";wassr_titlecolor="";wassr_textcolor="";wassr_boxcolor="";WassrFlashBlogParts();</script>
--- expected
Wassr

=== Wassr script - test3
--- input
<script type="text/javascript">
    wassr_host = "wassr.jp";
    wassr_userid = "kentaro";
    wassr_defaultview = "user";
    wassr_bgcolor="FDFAFA";
    wassr_titlecolor="C1B3B3";
    wassr_textcolor="5D5555";
    wassr_boxcolor="F8F5F5";
    WassrFlashBlogParts();
</script>
--- expected
Wassr
