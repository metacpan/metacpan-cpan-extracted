use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'ChonmageKacho' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Chonmage Kacho script - test1
--- input
<script language="JavaScript" src="http://chonmage.netcinema.tv/blog/01.js" charset="Shift_JIS"></script>
--- expected
Chonmage Kacho
