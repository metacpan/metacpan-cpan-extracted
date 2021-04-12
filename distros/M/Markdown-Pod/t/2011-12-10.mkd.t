use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/2011-12-10.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

Title:    GuiTest를 활용한 네이트온 원격제어 자동 수락기
Package:  Seoul.pm
Category: perl
Category: Seoul.pm
Author:   perlstudy


=head2 저자

L<@perlstudy|http://twitter.com/perlstudy> - L<네이버 Perl 카페|http://cafe.naver.com/perlstudy> 운영자, L<홈페이지|http://honeyperl.tistory.com/>에는 Perl과 관련한 유용한 정보를 종종 올리고 있다. 한 때 보안업계에 몸담았던 언더그라운드 Perler. 호네이, h0ney라는 닉을 사용하기도 한다.


=head2 시작하며

저는 자동화 도구에 관심이 많습니다.
자동화 도구는 직접 해야하는 작업이나 단순한 반복 작업을
자동으로 처리할 수 있게 도와줍니다.
작년에는 L<Advent Calendar|http://advent.perl.kr/2010/2010-12-07.html> 기사에서 
L<WWW::Mechanize|http://p3rl.org/WWW::Mechanize> 모듈을 통한 웹 자동화 방법에 대해 소개했습니다.
오늘은 Windows에서 유용하게 사용할 수 있는 테스트 자동화 모듈을 소개해 볼까합니다.

자동화 기술로써 가장 먼저 떠오르는 것 중 하나는 I<후킹(hooking)>일 것입니다.
후킹이란 메시지나 이벤트를 중간에 가로채거나 가로챈 이벤트를 임의로 바꾸는 기술입니다.
후킹을 통해 컴퓨터에서 일어나는 일을 마음대로 조정할 수 있습니다.
이 기술을 완벽하게 사용하기 위해서는 많은 노력이 필요합니다.
I<Win32 API>부터 Windows의 내부 동작 원리까지 상세하게 공부해야 합니다.
이런 덕목들은 Windows 프로그래머에게는 기본 소양으로 여겨지겠지만
단지 활용하고 싶은 사람들에게는 하늘에 별 따기일 수 있습니다.

2005년 Perl 진영에 Windows에서 다양한 GUI 테스트를 쉽게 할 수 있는
L<Win32::GuiTest - Perl GUI Test Utilities|http://p3rl.org/Win32::GuiTest> 모듈이 나왔습니다.
문서나 소스로만 공개되어 실제로는 사용하기 까다로운 자동화 기술이
모듈로 제공되어 많은 이들이 쉽게 자동화할 수 있도록 도왔습니다.
이 모듈을 처음 발견 했을 당시 깜짝 놀랐습니다.
이렇게 쉽고 간단하게 자동화를 할 수 있다니!
그 후로 이 모듈은 저의 최고의 장난감이 되어 크고 작은 자동화 부분을
획기적으로 처리하는 일등공신이 되었습니다.
그럼 지금부터 I<Win32::GuiTest>를 사용해봅시다!


=head2 준비물

필요한 모듈은 다음과 같습니다.

=over

=item -

L<CPAN의 Win32::GuiTest 모듈|http://p3rl.org/Win32::GuiTest>


=item -

L<CPAN의 Win32::GuiTest::Examples 예제|http://p3rl.org/Win32::GuiTest::Examples>


=back

윈도우에서는 다음 명령을 이용해서 모듈을 설치합니다.

    #!plain
    c:\> cpan Win32::GuiTest


=head2 GuiTest 예제로 배우기

설명을 읽는 것보다 예제를 직접 보고 실행해보면
사용법과 활용 방법을 쉽게 이해할 수 있습니다.

CPAN의 GuiTest는 총 26개의 예제를 제공합니다.

=over

=item -

L<ask.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-ask.pl>


=item -

L<calc.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-calc.pl>


=item -

L<excel.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-excel.pl>


=item -

L<excel2.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-excel2.pl>


=item -

L<fonts.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-fonts.pl>


=item -

L<iswindowstyle.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-iswindowstyle.pl>


=item -

L<keypress.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-keypress.pl>


=item -

L<menuselect.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-menuselect.pl>


=item -

L<notepad.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-notepad.pl>


=item -

L<notepad_text.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-notepad_text.pl>


=item -

L<paint.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-paint.pl>


=item -

L<paint_abs.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-paint_abs.pl>


=item -

L<pushbutton.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-pushbutton.pl>


=item -

L<rawkey.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-rawkey.pl>


=item -

L<selecttabitem.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-selecttabitem.pl>


=item -

L<showcpl.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-showcpl.pl>


=item -

L<showmouse.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-showmouse.pl>


=item -

L<showwin.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-showwin.pl>


=item -

L<spy--.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-.pl>


=item -

L<spy.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-spy.pl>


=item -

L<start.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-start.pl>


=item -

L<tab.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-tab.pl>


=item -

L<waitwindow.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-waitwindow.pl>


=item -

L<which.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-which.pl>


=item -

L<winbmp.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-winbmp.pl>


=item -

L<wptr.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-wptr.pl>


=back

엑셀에 자동으로 자료를 입력하거나 그림판을 실행시킨 후 선을 긋고
키보드와 마우스를 자유자재로 사용하는 예제들을 확인할 수 있습니다.


=head2 네이트온 원격제어 자동 수락기

지금까지 살펴본 모듈을 활용하여 네이트온의 원격 제어 요청을 자동으로 수락해주는 프로그램을 만들어 봅시다.
먼저 네이트온의 원격 제어 요청이 들어오는 창을 찾아야 합니다.
윈도우 창을 열거하는 예제 프로그램으로
L<spy--.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-.pl>와 L<spy.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-spy.pl>가 있습니다.
L<spy--.pl|http://p3rl.org/Win32::GuiTest::Examples#eg-.pl>의 소스를 확인해봅시다.

    #!perl
    #!/usr/bin/perl
    # MS has a very nice tool (Spy++).
    # This is Spy--
    #
      
    use Win32::GuiTest qw(FindWindowLike GetWindowText GetClassName
        GetChildDepth GetDesktopWindow);
      
    for (FindWindowLike()) {
        $s = sprintf("0x%08X", $_ );
        $s .= ", '" .  GetWindowText($_) . "', " . GetClassName($_);
        print "+" x GetChildDepth(GetDesktopWindow(), $_), $s, "\n";
    }

위 코드를 실행하면 윈도 창의 목록이 출력되며 하위 목록은 '+'로 깊이를 주어 출력됩니다.

    #!plain
    ++0x028F10DA, '시작', Button
    +0x001C1280, '', Shell_TrayWnd
    ++0x00191264, '', TrayNotifyWnd
    +++0x0042125E, '오후 9:08', TrayClockWClass
    +++0x00151242, '', TrayShowDesktopButtonWClass
    +++0x0032119A, '', SysPager
    ++++0x00151192, '사용자 프롬프트 알림 영역', ToolbarWindow32
    +++0x0057117E, '시스템 프롬프트 알림 영역', ToolbarWindow32
    +++0x00581152, '', Button
    ++0x00E206C6, '', ReBarWindow32
    +++0x0025004A, 'TF_FloatingLangBar_WndTitle', CiceroUIWndFrame
    +++0x007C0A4C, '응용 프로그램 실행 중', MSTaskSwWClass
    ++++0x002D1106, '응용 프로그램 실행 중', MSTaskListWClass
    ++0x007406AA, '', tooltips_class32
    ...

예를들어 박병조라는 분이 네이트온에서 원격 접속을 요청하면 아래 그림과 같이 요청을 수락할 것인지 알람이 나타납니다.

=for html <img src="2011-12-10-1.png" alt="네이트온 수락 요청 알람" />
<br />

I<그림 1.> 네이트온 수락 요청 알람 L<(원본)|2011-12-10-1.png>

이 요청은 메시지로 확인할 수 있을 것입니다.
아래와 같이 메시지가 발생할 윈도 창의 이름은 C<박병조(Bazinga!)님과의 대화>인 것을 확인할 수 있습니다.

    #!plain
    +0x009B0E26, '박병조(Bazinga!)님과의 대화', #32770
    ++0x004212CE, 'NateOn Menu Bar', Afx:00400000:3:00010003:01900010:00000000
    ++0x0085134A, '', SOFTWEB_CONTROL
    ++0x00480FEC, '', AfxWnd80su
    ++0x001F18B6, '', AfxWnd80su
    +++0x002118B4, '', Static
    +++0x00A30CF8, '', AfxWnd80su
    ++0x005418A0, '', AfxWnd80su
    +++0x007A0F74, 'WebCam', Button
    +++0x00421016, 'HideBtn', Button
    ++0x008016B6, '', SOFTWEB_CONTROL
    +++0x00510C18, 'Search', AfxWnd80su
    ++++0x0035010E, 'Search', Button
    ++0x0027186A, '', SOFTWEB_CONTROL
    ++0x009406C8, '', Edit
    ++0x0012194C, 'chat_titleIcon', Button
    ++0x005B1374, '보내기(&S)', Button
    ++0x0097100C, '>>', Button


=head2 만들어 봅시다

이제 모든 준비는 끝났습니다. 실제로 C<박병조>라는 이름이 포함된 윈도 창을 찾아 원격 제어의 수락 버튼을 눌러주기만 하면 됩니다.
버튼을 누르는 함수는 다양하게 존재하지만 지금은 Sendkeys를 사용하여 원격제어를 수락하여 보겠습니다.

    #!perl
    use strict;
    use warnings;
    use Win32::GuiTest qw(:ALL);
    while (1) {
        sleep 2; # 2초마다 한번씩 윈도우 창을 검색합니다.
        for my $window (FindWindowLike()) {
            my $str = sprintf("0x%08X", $window);
            $str .= ", '" .  GetWindowText($window) . "', " . GetClassName($window);
            if($str =~ /박병조/){  # 원격을 걸 수있는 사람을 설정
                SetForegroundWindow($window); # 찾은 윈도우에 포커스를 맞춥니다.
                sleep 1;
                SendKeys("%c"); # 원격제어 수락 단축키 Alt+C 를 뜻합니다.
                sleep 2;
                print "수락되었습니다 :)";
            }
        }
    }

원격 제어가 수락된 모습입니다! 두둥!

=for html <img src="2011-12-10-2.png" alt="원격 제어가 자동으로 수락된 모습" width="700" />
<br />

I<그림 2.> 원격 제어가 자동으로 수락된 모습 L<(원본)|2011-12-10-2.png>


=head2 정리하며

예시를 통해 GuiTest 모듈에 대해 단편적으로 설명했으나 실제로는 다방면으로 활용할 수 있을 것입니다.
직접 다른 모듈과 조합하여 활용한 내용들을 아래에 정리해 보았습니다.

=over

=item -

L<Win32::Process::Memory 활용 예제|http://honeyperl.tistory.com/entry/Win32ProcessMemory>


=item -

L<한글 문자열을 키보드 자판의 영문자로 변환|http://honeyperl.tistory.com/entry/%ED%95%9C%EA%B8%80-%EB%AC%B8%EC%9E%90%EC%97%B4%EC%9D%84-%EC%9E%90%ED%8C%90%EC%97%90-%EC%9E%85%EB%A0%A5%EB%90%98%EB%8A%94-%EC%98%81%EB%AC%B8%EB%A1%9C-%EB%B0%94%EA%BE%B8%EB%8A%94-%EB%B0%A9%EB%B2%95>


=item -

L<네이트온 쪽지 자동 답장 프로그램|http://honeyperl.tistory.com/entry/%EB%84%A4%EC%9D%B4%ED%8A%B8%EC%98%A8-%EC%AA%BD%EC%A7%80-%EC%9E%90%EB%8F%99%EB%8B%B5%EC%9E%A5-%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%A8> (지금은 버전이 바뀌어 작동하지 않습니다.)


=item -

L<플래시 게임을 즐기자.|http://honeyperl.tistory.com/entry/%ED%94%8C%EB%9E%98%EC%8B%9C-%EA%B2%8C%EC%9E%84%EC%9D%84-%EC%A6%90%EA%B8%B0%EC%9E%90>


=back


=head2 후기

Advent Calender의 기고를 부탁받은 뒤 
이번에는 GuiTest를 소개해 보자는 생각이 번뜩 들었습니다.
어떤 예제를 만들어 볼까 고민하다 후배가 사용하던
네이트온 원격제어 자동 수락기를 만들고자 결심한 뒤,
얼마나 시간이 걸릴까 소스는 몇 줄이나 될까 스스로도 궁금했는데
만들고 보니 감탄할 수 밖에 없었습니다.

만들고자 하는 프로그램을 이렇게 신속하게 만드는데 Perl만한 언어가 또 있을까 싶습니다. :)

한국 Perl 진영을 이끌어 주시는 L<@keedi|http://twitter.com/keedi>님,
그리고 L<@y0ngbin|http://twitter.com/y0ngbin>님과 L<Silex|http://facebook.com/silexkr>분들께 행사때마다 연락 주셔서 정말 감사합니다.
놀러 갈 때마다 너무도 따스하게 맞아주시니 눌러 앉아버리고 싶을때가 간혹 있습니다.
최근에는 자주 못 뵈었지만 정신적 지주이신 L<@aer0|http://twitter.com/aer0>님과
L<@gypark|http://twitter.com/gypark>님께 네이버 Perl 카페에서 열정적으로 활동해 주셔서 고맙습니다. 
마지막으로 네이트온 원격을 걸어주며 함께 테스트 해주신 L<@conetPark|http://twitter.com/conetPark>(박병조)님께 감사드리며,
불철주야 Advent Calender를 위해 노력하시는 L<@am0c|http://twitter.com/am0c>님께 박수를 보냅니다.

