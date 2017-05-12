use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'UranaiParts' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Uramai Parts script - test1
--- input
<script language='JavaScript' src='http://www.pixmax.jp/uranai_parts/BlogNavigator.js'></script>
--- expected
Uranai Parts

=== Ryuji Kagami script - test2
--- input
<script language='JavaScript'>writeBlogNavigator("vippix","kagami")</script>
--- expected
Uranai Parts

=== Takamitsu Tominaga script - test3
--- input
<script language='JavaScript'>writeBlogNavigator("vippix","rune")</script>
--- expected
Uranai Parts

=== Rei Ophelia script - test4
--- input
<script language='JavaScript'>writeBlogNavigator("vippix","ophelia")</script>
--- expected
Uranai Parts
