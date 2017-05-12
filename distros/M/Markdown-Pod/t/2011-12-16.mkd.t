use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/2011-12-16.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

Title:    perlbrew, local::lib, smartcd 를 이용하여 Perl 환경 구축하기
Package:  Seoul.pm
Category: perl
Category: Seoul.pm
Author:   corund


=head2 저자

L<@corund|http://twitter.com/#!/corund> -
웹프로그래머. 다년간 Java로 웹 개발을 해왔으며 마음에 드는 언어를 찾기위해
여러 언어를 전전하다 Perl의 매력을 발견하고 현재 주로 Perl로 개발하고 있다.
Catalyst 프레임워크로 웹 개발을 하며 현재 L<경제 포털 ESTIN|http://estin.net>을 구축 및 운영 중이다.


=head2 시작하며

Perl은 하위 호환성이 좋고 L<cpan|https://metacpan.org/module/CPAN>이라는 막강한 툴이 있기 때문에
특별히 버전이나 모듈들을 관리할 필요가 많진 않습니다.
하지만 일반에게 서비스할 웹 서비스를 개발하거나 따로 배포할 프로그램을
개발한다면 특별히 버전과 모듈들을 관리할 필요가 있습니다.
또한 아직 사용중인 운영체제 배포판에서 공식 지원하기 전의
최신 Perl을 실험해 보고 싶은 경우도 있습니다.
Linux나 OSX을 쓴다면 이럴 때
L<perlbrew|http://perlbrew.pl>(L<CPAN의 App::perlbrew 모듈|https://metacpan.org/module/App::perlbrew>)와
L<local::lib|https://metacpan.org/module/local::lib>를 이용해 버전과 모듈들을 따로 관리할 수 있습니다.
덧붙여 L<smartcd|https://github.com/cxreg/smartcd>와 같은 C<bash> 유틸리티를 이용하면
이를 더욱 편리하게 이용할 수 있습니다.


=head2 예제

이 예제에서는 Perl 5.12.x(현재 5.12.4) 버전을 주로 사용하며
5.14.x(현재 5.14.2) 버전을 시험하는 경우를 예로 듭니다.
C<~/project> 디렉터리 밑에 여러 프로젝트를 두고
C<~/project/catalyst> 디렉터리는 L<Catalyst|https://metacpan.org/module/Catalyst> 웹 프로젝트를,
C<~/project/wx> 디렉터리는 L<Wx|https://metacpan.org/module/Wx> GUI 어플리케이션 프로젝트를 두고
관련 모듈들을 따로 관리하는 경우를 가정합니다.
C<~/project/pilot> 디렉터리 밑에는 5.14.x 버전을 시험하는 프로젝트를 두겠습니다.
즉 일반적인 경우의 Perl 버전은 5.12.4가 되며 C<~/project/pilot> 디렉터리로
가면 버전이 5.14.2가 되고, C<~/project/catalyst> 와 C<~/project/wx>에서
각각 따로 모듈을 관리, 이용할 수 있게 하는 것입니다.


=head2 perlbrew & local::lib

사실 Perl을 컴파일 하는 것은 어렵지 않습니다.
하지만 조금이라도 더 손쉽게 다양한 버전의 Perl을
컴파일하고 관리하며 사용하려면 C<perlbrew>를 사용하는 것이 유리합니다.
여기서는 C<perlbrew>를 C<~/perl5/perlbrew> 디렉터리에 설치하겠습니다.
명령줄에서 다음 명령을 입력합니다.

    #!bash
    $ export PERLBREW_ROOT=~/perl5/perlbrew
    $ curl -kL http://xrl.us/perlbrewinstall | bash

=for html <img src="2011-12-16-1.png" alt="perlbrew install" />

C<perlbrew>가 설치되었고 안내에 따라 다음과 같이 C<bash>
초기화 파일(C<.bashrc> 또는 C<.profile>)에 스크립트를 추가합니다.

    #!bash
    $ echo "source ~/perl5/perlbrew/etc/bashrc" >> .bashrc

다시 로그인하면 C<perlbrew>를 사용할 수 있습니다.
이제 C<install> 명령을 사용해 5.12.4 버전과 5.14.2 설치할 수 있습니다.
특별한 이유가 없다면 C<-D usethreads> 옵션을 명시해서 쓰레드 기능을
사용할 수 있도록 컴파일합니다.

    #!bash
    $ perlbrew install perl-5.12.4 -D usethreads
    $ perlbrew install perl-5.14.2 -D usethreads

Perl 5.12.4 버전을 기본으로 사용하려면 다음 명령을 실행합니다.

    #!bash
    $ perlbrew switch perl-5.12.4
    $ perl -v

=for html <img src="2011-12-16-2.png" alt="check perl install" />

현재 쉘에 한해 임시로 Perl 5.14.2 버전을 사용하려면 다음 명령을 실행합니다.

    #!bash
    $ perlbrew use perl-5.14.2
    $ perl -v

각 버전의 Perl에 대해 L<cpanm|https://metacpan.org/module/App::cpanminus>과
L<CPAN의 local::lib 모듈|https://metacpan.org/module/local::lib>을 설치합니다.

    #!bash
    $ perlbrew switch perl-5.12.4
    $ cpan App::cpanminus local::lib
    $ perlbrew switch perl-5.14.2
    $ cpan App::cpanminus local::lib

지금부터 모든 모듈은 C<local::lib>를 이용해 C<~/perl5/local> 디렉터리 아래서 관리합니다.


=head2 smartcd

C<perlbrew>나 C<local::lib>나 모두 환경 변수를 이용해 사용할
Perl 버전과 모듈 설치 및 검색 디렉터리를 지정합니다.
따라서 필요할 때마다 환경 변수를 적절하게 변경해주어야 합니다.
이는 여간 번거로운 일이 아닐 수 없습니다.
이런 번거로움을 해결하기 위해 L<smartcd|https://github.com/cxreg/smartcd>를 써볼까요?
smartcd는 디렉터리를 옮겨 다닐 때마다 자동으로
환경 변수를 변경해주는 유틸리티입니다.
smartcd를 설치하는 방법은 무척 간단합니다.

    #!bash
    $ cd project
    $ git clone git://github.com/cxreg/smartcd.git
    $ cd smartcd
    $ make install
    $ make setup

smartcd는 홈 디렉터리에 C<.bash_arrays>, C<.bash_smartcd>, C<.bash_varstash>
파일을 만들고 C<bash> 초기화 파일에 초기화 코드를 설정합니다.
디렉터리를 옮겨갈 때마다 지정한 쉘 스크립트를 실행하는데
C<~/.smartcd> 디렉터리 밑에 저정합니다.

C<~/project/catalyst> 디렉터리로 들어갔을 때 C<local::lib>로
C<~/perl5/local/5.12.5/catalyst> 디렉터리 밑의 모듈을
관리할 수 있도록 하려면 다음처럼 실행합니다.

    #!bash
    $ perl -Mlocal::lib=~/perl5/local/5.12.4/catalyst

=for html <img src="2011-12-16-3.png" alt="init local::lib" />

앞의 명령을 실행하면 C<~perl5/local/5.12.4/catalyst> 디렉터리를 생성하고
모듈들을 관리할 구조들을 생성한 후 환경 변수를 지정할 코드를 출력됩니다.
보통은 이 구문을 Bash 초기화 파일에 추가합니다만 여기서는 smartcd로
관리할 것이므로 C<~/.smartcd> 디렉터리 밑에 설정합니다.
C<<< ~/.smartcd/home/<your_account>/project/catalyst >>> 디렉터리를 만들고
그 밑에 C<bash_enter> 파일을 만듭니다.
이 파일이 smartcd로 C<~/project/catalyst> 디렉터리에
들어갈 때 실행되는 스크립트입니다.
이 곳에서 C<local::lib> 설정을 하면 됩니다.

    #!bash
    $ mkdir -p ~/.smartcd/home/<your_account>/project/catalyst
    $ cd ~/.smartcd/home/<your_account>/project/catalyst
    $ echo 'eval $(perl -Mlocal::lib=~/perl5/local/5.12.4/catalyst | sed '\''s/export/autostash/'\'')' > bash_enter

즉석에서 생성한 C<bash_enter> 파일은 C<perl -Mlocal::lib=~/perl5/local/5.12.4/catalyst>
명령을 실행했을 때 출력되는 환경 변수 값으로 설정하는 스크립트인데,
C<export> 대신 smartcd의 C<autostash>를 사용하도록 변경한 점을 눈여겨 보세요.
C<autostash>는 현재 환경 변수 값을 저장하고 지정한 값으로 바꾼 다음,
디렉터리를 떠날 때 원래 값으로 복원합니다.
이렇게 함으로써 C<~/project/catalyst> 디렉터리로 들어오면 C<local::lib>로
관리가 되어 지정한 디렉터리(C<~/perl5/local/5.12.4/catalyst>)에 모듈을
설치하고 사용할 수 있게 됩니다.
이제 C<cpanm> 등을 사용하여 필요한 모듈을 설치할 수 있습니다.

    #!bash
    $ cd ~/project/catalyst
    $ cpanm Catalyst::Runtime

같은 방식으로 C<~/project/wx> 디렉터리에는 C<~/perl5/local/5.12.4/wx>
하부에 모듈을 관리하도록 설정하려면 다음처럼 실행합니다.

    #!bash
    $ perl -Mlocal::lib=~/perl5/local/5.12.4/wx
    $ mkdir -p .smartcd/home/<your account>/project/wx
    $ cd ~/.smartcd/home/<your accunt>/project/wx
    $ echo 'eval $(perl -Mlocal::lib=~/perl5/local/5.12.4/wx | sed '\''s/export/autostash/'\'')' > bash_enter

이제 C<~/project/wx> 디렉터리로 들어가 원하는 모듈을 설치하고 사용하면 됩니다.

    #!bash
    $ cd ~/project/wx
    $ cpanm Wx

마지막으로 C<~/project/pilot> 디렉터리로 들어가서
C<perlbrew>를 이용해 5.14.2 버전을 사용해 보겠습니다.
C<perlbrew>에는 현재 쉘에 한해 임시로 Perl 버전을 바꾸는 명령어인 C<use>가 있습니다.
이 기능을 이용 특정 디렉터리에 들어갈 때 버전을 바꿀 수 있습니다만,
smartcd 설정이 복잡해지는 단점이 있습니다.
즉, 디렉터리에 들어갈 때 실행하는 스크립트인 C<bash_enter>에서
원래 버전을 저장해두고 버전을 바꾼 다음,
나올 때 실행하는 스크립트인 C<bash_leave>에서 복원해야 합니다.

대신 C<perlbrew env> 명령을 이용하면 간단하게 처리할 수 있습니다.
C<env> 명령은 C<perlbrew>가 쉘과의 통합을 위해 사용하는 비교적 저수준 명령입니다.
이 명령을 사용하면 Perl 버전을 변경할 때 지정하는 환경 변수를 출력합니다.
C<perlbrew>는 이 환경 변수와 C<PATH> 환경 변수를 변경해서 Perl 버전을 변경합니다.
따라서 C<<< ~/.smartcd/home/<your_accout>/project/pilot/bash_enter >>> 스크립트의
내용은 다음과 같습니다.

    #!bash
    eval $(perlbrew env perl-5.14.2 | sed 's/export\(.*\)$/autostash\1;/')
    autostash PATH_WITHOUT_PERLBREW="$(perl -e 'print join ":", grep { index($_, $ENV{PERLBREW_ROOT}) } split/:/,$ENV{PATH};')"
    autostash PATH="$PERLBREW_PATH:$PATH_WITHOUT_PERLBREW"

C<perlbrew env>를 이용해 Perl 버전 변경에 필요한 환경 변수 값을 얻고,
C<sed>를 이용하여 smartcd에서 이용할 수 있게 수정하며,
마지막으로 C<PATH> 환경 변수를 수정하는 점을 주의깊게 보세요.
이제 C<~/project/pilot> 으로 들어가면 5.14.2 버전으로 바뀌게 됩니다.

=for html <img src="2011-12-16-4.png" alt="switch perl version" />

5.12.4 버전의 경우와 마찬가지로 C<~/project/pilot> 디렉터리 밑에 하부 디렉터리를
만들고 C<local::lib>로 각각 모듈을 관리할 수 있습니다.

    #!bash
    $ perl -Mlocal::lib=~/perl5/local/5.14.2/catalyst
    $ mkdir -p ~/.smartcd/home/<your_account>/project/pilot/catalyst
    $ cd ~/.smartcd/home/<your_account>/project/pilot/catalyst
    $ echo 'eval $(perl -Mlocal::lib=~/perl5/local/5.14.2/catalyst | sed '\''s/export/autostash/'\'')' > bash_enter
    $ cd ~/project/pilot/catalyst
    $ perl -v
    $ cpanm Catalyst::Runtime


=head2 정리하며

처음 Java에서 Perl로 넘어왔을 때 가장 편하면서도 불편했던 것이 C<cpan>이었습니다.
원하는 모듈을 간편히 설치해준다는 점에서 편했지만
배포시 모듈을 어떻게 관리해야 할지가 불편했던 것이죠.
정확히는 불편했다기 보다 무엇이 어떻게 돌아가는지 몰라서 불안했달까요?
하지만 C<perlbrew>와 C<local::lib>를 알고 사용법을 조금씩 익혀가면서
Perl과 관련 모듈을 무척 편하게 다룰 수 있다는 것을 알게 되었습니다.
이 두 Perl 모듈은 너무나도 간단해 마치 마술처럼 동작하는 것처럼 보이지만
사실 몇 가지 환경 변수를 조작하는 아주 간단히 동작을 수행할 뿐입니다.
덕분에 smartcd와 같은 쉘 유틸리티와 연동하면 무척 편하게 Perl 개발 환경을 구축할 수 있습니다.
