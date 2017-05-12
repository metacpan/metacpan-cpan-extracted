use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'LingrBadge' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Lingr Badge script - test1
--- input
<script type="text/javascript" src="http://www.lingr.com/room/cS4z6S34MJv/badge/render" charset="utf-8"></script>
--- expected
Lingr Badge

