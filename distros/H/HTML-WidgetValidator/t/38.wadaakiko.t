use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'WadaAkiko' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Wada Akiko script - test1
--- input
<script language="JavaScript" type="text/javascript" src="http://www.cyberclone.jp/parts/ako160/ako.js" charset="UTF-8"></script>
--- expected
Wada Akiko

