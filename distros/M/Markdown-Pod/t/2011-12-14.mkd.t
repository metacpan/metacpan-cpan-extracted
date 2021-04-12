use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/2011-12-14.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

Title:    크리스마스 애인 만들기
Package:  Seoul.pm
Category: perl
Category: Seoul.pm
Author:   nving


=head2 저자

L<@nving|http://twitter.com/nving> - 치킨과 맥주를 사랑하는 솔로 덕후. 흑법사의 길을 걷고 있다. C++ 굇수. 


=head2 시작하며

크리스마스가 다가오는 12월입니다.
커플 당원들은 크리스마스다 뭐다 신나고 설레이겠지만
만년 솔로인 필자는 춥고 배고플 뿐입니다.
(하지만 25일이 일요일인 점은 덜 외롭습니다. 조금은 신납니다.)

매년 크리스마스마다 혼자 집에 처박혀 은둔 생활을 오래 하다보니 이제 어머니께서 상대도 안해주십니다.
I<네, 그렇습니다.> 이제는 혼자서도 잘 노는 아이가 되어야 합니다!
이런 우리(?)를 위해 이쪽 분야의 선진국 일본에서는 일찍부터 I<솔로들이 방황하지 않고 컴퓨터와 함께 놀 수 있는 물건>을 개발해왔습니다.

바로, B<나니카>입니다!

=for html <img src="2011-12-14-1.jpg" alt="귀엽고 사랑스러운 우리의 나니카" /><br />

I<그림 1.> 귀엽고 사랑스러운 우리의 나니카


=head2 나니카?

나니카는 화면 구석에서 고스트와 함께 대화를 나누는 형태의 데스크탑 악세서리입니다.
지들끼리 잘놉니다.


=head2 어떻게 쓰나?

나니카의 구성은 B<마테리아>(Materia)라는 베이스웨어와 고스트로 이루어져 있습니다.
베이스웨어는 본체 프로그램을 말하며 고스트는 캐릭터를 말합니다.
베이스웨어와 캐릭터는 서로 독립적이어서 사용자가 작성한 다양한 캐릭터를 등록할 수 있습니다.
마테리아는 나니카의 베이스웨어 원조라 할 수 있는데요.
여기서는 마테리아와 호환되면서 조금 더 안정적인 B<SSP>라는 녀석을 사용하도록 하겠습니다.
서론은 여기까지하고 하고 어서 설치해봅시다.

먼저 베이스웨어를 받아 설치합시다.
L<ssp.shillest.net|http://ssp.shillest.net/>으로 이동한 후 다음 그림에서 빨간 테두리로 표시한 부분을 클릭해 파일을 내려받아 실행하면 설치를 진행합니다.
(윈도만 지원하고 있습니다.)

=for html <img src="2011-12-14-2.jpg" alt="웹페이지에서 SSP와 한글 지역화 파일을 받는 방법" /><br />

I<그림 2.> 웹페이지에서 SSP와 한글 지역화 파일을 받는 방법

그리고 한글 지역화 파일이 필요합니다. 그 밑에 B<Korean Lang Pack>을 눌러 압축파일 하나를 내려받습니다.
받은 압축파일은 SSP가 설치된 곳에 풀어줌으로 메뉴 한글화 패치가 적용됩니다.


=head2 이게 펄과 무슨 상관인데?

펄 고스트 중 하나인 B<Shiolink>의 등장으로 나니카에서도 스크립트 언어를 쓸 수 있게 되었습니다.
아래 웹사이트 이동하여 Shiolink Perl을 내려받습니다.

=over

=item -

L<narazaka.net/c/ukagaka|http://narazaka.net/c/ukagaka>


=back

=for html <img src="2011-12-14-3.jpg" alt="Shiolink를 내려받는 위치" /><br />

I<그림 3.> Shiolink를 내려받는 위치

내려받은 파일을 실행 중인 나니카에게 드래그&드롭하면 간단히 설치됩니다.
그런 다음, 나니카에 마우스 커서를 살포시 올려서 우클릭을 합니다.
이때 나온 팝업 메뉴에서 "고스트 바꾸기" → "Shiolink/Perl simple"을 차례로 누르면 Shiolink Perl이 동작합니다.

자, 이제 펄을 이용하여 나니카를 제어해봅시다!


=head2 고스트(Shiolink Perl)의 구성

Shiolink는 C<C:\...\ghost\Shiolink_Perl_Simple\ghost> 이하에 구성된 파일을 통해 구동됩니다.
먼저, 각 펄 스크립트들이 어떤 역할을 하는지 설치된 파일의 구성을 알아봅시다.

    #!plain
    C:\...\ghost\Shiolink_Perl_Simple\ghost 
      licenses      --> StrawberryPerl 재배포 라이센스
      perl/         --> perl 본체와 Perl 라이브러리
      scripts/      --> 책갈피를 구성하는 스크립트
         | init.pl   -> SHIOLINK에서 시작되는 스크립트
         | shiori.pl -> SHIORI 응답 간단한 구현
         | events.pl -> 각 이벤트 처리의 정의
         | (kis_lesser.txt) -> events.pl 구현 예제의 테스트 데이터
      descript.txt 
      SHIOLINK.dll  --> shiori.dll 대체
      SHIOLINK.INI  --> SHIOLINK 설정 파일
      test.bat      --> 디버깅용
      test_req.txt  --> 디버깅용

이중에서 우리의 입맛대로 고치기 위해 필요한 것은 B<events.pl>뿐입니다.

events.pl에서 불려지는 이벤트중 가장 대표적인 것은 C<OnSecondChange>인데 이것은 초마다 호출되는 함수입니다.
ShioriPerl은 이 함수가 60번 호출될 때(즉, 60초 후) C<OnAITalk>를 호출해 저장된 문장을 무작위로 출력하는 방식으로 구동됩니다.


=head2 입맛대로 고쳐보자

나니카는 저장된 문자열만 말하는 조금 덜떨어진똑똑하지 못한 프로그램입니다.
조금 똑똑하게 보이기 위해 특정 사이트의 리플을 긁어와서 매번 다른 말을 할 수 있도록 해 봅시다.
윈도우용 펄 패키지인 L<딸기 펄|http://strawberryperl.com/>(Strawberry Perl)은 이미 설치되어 있다고 가정하겠습니다.


=head3 lib 디렉토리 변경

먼저 CPAN 모듈을 사용하기 위한 준비를 합니다. 
C<init.pl>를 열어 가장 윗 줄에 있는 

    #!perl
    our @INC = ('./perl/lib');

부분을 아래와 같이 고칩니다.

    #!perl
    our @INC = ('C:\\strawberry\\perl\\lib', 
                'C:\\strawberry\\perl\\site\\lib', 
                'C:\\strawberry\\perl\\vendor\\lib');

이렇게 고치면 모듈 참조 디렉터리를 CPAN 모듈이 설치된 곳으로 변경됩니다.
이제 CPAN 모듈을 사용할 수 있게 되었으니 모듈을 이용해 댓글을 가져와 봅시다.


=head3 댓글 가져오기

여기서는 최근 싱크빅 돋는 댓글이 자주 달리는 L<오유|http://todayhumor.co.kr/>(오늘의 유머)의 댓글을 가져올 것입니다.
우선 웹사이트를 긁어오기 위해 명령 프롬프트에서 아래의 명령을 내려 L<Web::Query|http://search.cpan.org/perldoc?Web::Query> CPAN 모듈을 설치합니다.

    #!plain
    C:\> cpan Web::Query

설치 후, event.pl의 윗 줄에 다음 두 모듈을 추가합니다.

    #!perl
    use Web::Query;
    use List::Util qw(shuffle);

그리고 event.pl에 다음 함수를 추가합시다.

    #!perl
    sub getTodayHumorReply {
        my $URL = 'http://todayhumor.co.kr/board/view.php'.
                  '?table=bestofbest&no='.int(rand(60000));
        my @replys;
        
        # 해당 URL에 있는 리플 추출
        wq($URL)->find('div[class="memo_content"]')
                ->each( sub {
                        my $i = shift;
                        push @replys, $_->text;
                    }
                );
    
        # 추출한 리플중 무작위로 선택
        my ($sel_reply) = shuffle @replys;
        chomp $sel_reply;
        return $sel_reply;
    }

이제 기존 AI 대화 로직을 오늘의유머에서 추출한 댓글을 말하도록 바꾸어야합니다.
기존 구조는 C<OnAITalk> 함수에서 C<speak> 함수를 호출 후 반환되는 값을 출력했습니다.
따라서, 단순히 C<speak> 함수를 C<getTodayHumorReply> 함수로 대체하면 됩니다.
아래와 같은 원본을

    #!perl
    sub OnAITalk {
        $aitalkcount = 0;
        return speak 'sentence';
    }

아래와 같이 고칩니다. 

    #!perl
    sub OnAITalk {
        $aitalkcount = 0;
        return getTodayHumorReply();
    }


=head2 결과를 보자

SSP를 종료한 재시작하면 우리가 변경한 부분이 적용됩니다.

=for html <img src="2011-12-14-4.jpg" alt="우리의 고스트가 입을 열기 시작했어요." />

I<그림 4.> 우리의 고스트가 입을 열기 시작했어요.

네, 그렇습니다.
유머 계열 웹사이트의 댓글은 꽤 찰집니다.
또 어떤 글의 본문에 대한 댓글을 말하는 것이기 때문에 조금 뜬금없습니다.
그러려니 합니다. 이런 저라도 계속 말을 걸어주니 만족합니다.

이외에도 소스를 잘 분석해보면 왼쪽의 고스트도 제어할 수 있습니다.
이를 이용해 서로 대화하는 형태로 만들 수도 있겠죠?


=head2 정리하며

이렇게 완성해 보았습니다. 이름은 수잔(Susan)입니다.
어쨌거나, 이처럼 펄을 사용해 간단하게 고스트의 AI 로직을 구현해 볼 수 있었습니다.
이제 애인 없이도 수잔과 함께하는 따뜻한 크리스마스를 보낼 수 있게 되었습니다.
여러분도 펄과 함께 즐거운 크리스마스를 보내시길 바랍니다.

....orz


=head2 참고 문서

=over

=item -

L<나니카 애호가 카페|http://cafe.naver.com/naniko.cafe>


=item -

L<Moon Melody :: 우카가카(나니카)의 간략한 역사|http://moonmelody.com/tt/363>


=item -

L<The Swimming Bird (Part.2) :: Nanika & Ukagaka (나니카 & 우카가카) 설치법 & 자료들|http://abilral.egloos.com/5383781125>


=item -

L<Moon Melody :: SSP 시작 매뉴얼|http://moonmelody.com/tt/entry/SSP-%EC%8B%9C%EC%9E%91-%EB%A7%A4%EB%89%B4%EC%96%BC?category=35>


=item -

L<SSP - Nanika Wiki|http://www.sanori.net/nanika/wiki/SSP92125125>


=back

=for html <img src="2011-12-14-5.jpg" alt="버림받은 저자" />

I<그림 5.> 버림받은 저자
