use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'AboutMe' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== About Me script - test1
--- input
<script language="JavaScript" type="text/javascript" charset="utf-8" src="http://p.aboutme.jp/p/qjs/00/19200.js"></script>
--- expected
About Me

=== About Me script - test2
--- input
<script language="JavaScript" type="text/javascript">var AbUnum='d9f744f7cf3e1b856bba53b15b656ba89fe0d9bf';</script>
--- expected
About Me

=== About Me script - test3
--- input
<script language="JavaScript" type="text/javascript" src="http://p.aboutme.jp/p/js/blogp.js"></script>
--- expected
About Me
