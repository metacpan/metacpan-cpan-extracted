use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/rt-77889-ordered-list.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8


=head2 준비물

필요한 모듈은 다음과 같습니다.

=over

=item -

L<CPAN의 Win32::GuiTest 모듈|http://p3rl.org/Win32::GuiTest>


=item -

L<CPAN의 Win32::GuiTest::Examples 예제|http://p3rl.org/Win32::GuiTest::Examples>


=back

윈도우에서는 다음 명령을 이용해서 모듈을 설치합니다.

=over

=item 1.

cpan Win32::GuiTest


=item 2.

cpan Win32::GuiTest::Examples


=back
