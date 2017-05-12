use strict;
use Test::More tests => 1;

use HDML::LinkExtor;

my $p = HDML::LinkExtor->new(undef, 'http://test.com/');
$p->parse(join "", <DATA>);
my @links = map { $_->[2]->as_string } $p->links;

is_deeply(
    \@links,
    [
      'http://test.com/',
      'http://test.com/test.png',
      'http://test.com/test.hdml',
      'mailto:milano@cpan.org',
      'http://test.com/choice1.hdml',
      'http://test.com/choice2.hdml',
      'http://test.com/choice3.hdml'
    ],
);

__END__
<HDML version="3.0">
<DISPLAY name="a">
<ACTION dest="/">
<IMG src="test.png"><BR>
This is a link.
<A TASK="go" DEST="./test.hdml">TEST</A>
This is a e-mail.
<A TASK="go" DEST="mailto:milano@cpan.org">milano@cpan.org</A>
</DISPLAY>
<CHOICE>
This is a choice.
<CE task="gosub" dest="choice1.hdml" label="choice1">
<CE task="gosub" dest="choice2.hdml" label="choice2">
<CE task="gosub" dest="choice3.hdml" label="choice3">
</CHOICE>
<ENTRY name="input" key="input">
This is a Input.
<ACTION type="accept" task="go" dest="#input">
</ENTRY>
</HDML>
