use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'Natalie' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Natalie News script - test1
--- input
<script type="text/javascript" charset="UTF-8" src="http://natalie.mu/widget/news?"></script>
--- expected
Natalie

=== Natalie Hotnews script - test2
--- input
<script type="text/javascript" charset="UTF-8" src="http://natalie.mu/widget/hotnews?"></script>
--- expected
Natalie

=== Natalie List by Category script - test3
--- input
<script type="text/javascript" charset="UTF-8" src="http://natalie.mu/widget/news?category_id=1"></script>
--- expected
Natalie

=== Natalie List by Artist script - test4
--- input
<script type="text/javascript" charset="UTF-8" src="http://natalie.mu/widget/news?artist_id=1"></script>
--- expected
Natalie
