use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/2011-12-24.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

Title:    Perl 생태계 가이드
Package:  Seoul.pm
Category: perl
Category: Seoul.pm
Author:   aer0


=head2 저자

L<@aer0|http://twitter.com/aer0> -
Seoul.pm, #perl-kr의 정신적 지주, 
Perl에 대한 근원적이면서 깊은 부분까지 놓치지 않고 다루는
L<홈페이지 및 블로그|http://aero.sarang.net/>를 운영하고 있다. aero라는 닉을 사용하기도 한다.


=head2 시작하며

23일 동안 열혈 서울 펄 몽거스를 위시한 많은
펄 몽거들이 푸짐한 선물 보따리를 풀어놓았습니다.
관심을 가지고 지켜보신 분들이라면 Perl의
새로운 모습을 느꼈으리라고 생각합니다.
Perl은 과거 웹 프로그래밍이라면 CGI로 인식되던 시대에
잘나가던 시절이 있었습니다.
하지만 PHP의 등장으로 CGI로 웹을 만들던 사람들이
PHP로 넘어가게 되었고 그 후 Python, Ruby 같은 언어들이 인지도를 높혀가면서
Perl은 상대적으로 시야에서 멀어진 언어로 인식되어 왔던게 사실입니다.
그와 함께 훈련되지 않은 프로그래머들이 양산해놓은 많은 스파게티 CGI 코드들로 인해 
유지보수가 힘들다는 근거 없는 루머에 시달리기도 했죠.
하지만 Perl은 유행과 시류에 휘둘리지 않고 조용히 안정성을 추구하며 
함께 새로운 기술들을 받아들이면서 꾸준히 발전해 왔으며
2009년경 부터 이른바 L<Modern Perl|http://www.slideshare.net/search/slideshow?searchfrom=header&q=modern+perl>이라는 움직임이 일어나 
다시금 중흥기를 맞고 있습니다.
이 글은 그 동안 Perl이 변화한 모습을 설명할 것입니다.
또, Perl을 새롭게 접하고자 하거나 다른 언어 사용자의 입장에서 Perl을 접하고자 할 때
어떤 과정을 통해 Perl에 익숙해질 수 있는지 설명할 것입니다.
마지막으로, 원하는 바를 구현하려고 할 때 어떤 기술을 사용할 수 있는지
Perl 생태계에 대한 총체적인 가이드라인을 제시할 것입니다.


=head2 Perl을 어떻게 배울 것인가?

시중의 최신 한글 Perl 서적은
Learning Perl 5판 번역서인 L<거침없이 배우는 Perl|http://books.perl.kr/lp5/>입니다. 
이 책으로 시작하는 것을 추천합니다.
책을 읽으면서 다음 내용도 같이 참고해서 살을 붙여나가세요.

=over

=item -

L<거침없이 배우는 Perl 서평|https://github.com/aero/perl_docs/blob/master/Learning_Perl_5th_kor_review.md>


=back

Perl은 OOP(Object Oriented Programming), AOP(Aspect Orientied Programming), FP(Functional Programming) 같은
특정 패러다임을 추구하지 않고 유연한 구조로 멀티 패러다임을 추구하고 있으며(아래 링크 참조)
Perl이 가지는 문법적 유연성으로 인해 어떤 방향으로든 쉽게 진화가 가능합니다.
이를 통해 고집스럽게 하위 호환성을 유지하면서도 새로운 모습으로 발전해나가는 힘이 되고 있습니다.

=over

=item -

L<Perl로 하는 함수형 프로그래밍|http://advent.perl.kr/2010/2010-12-14.html>


=item -

L<Moose로 OOP하기|http://advent.perl.kr/2010/2010-12-20.html>


=back


=head2 Perl 5 와 Perl 6는 어떻게 다른가?

Perl 5 와 Perl 6는 같은 가족이지만 다른 언어라고 생각하면 됩니다.
쉽게 말하면 C와 C++의 관계 쯤으로 생각할 수 있습니다.
C++이 나오고 나서도 C는 여전히 함께 잘 쓰이고 있습니다.
Perl 6는 현재 본격적인 개발에 사용되기에는 주변 환경이 완전히 갖추어진 상태가 아닙니다. 
따라서 현재는 Perl 5가 Perl을 대표하며 그간의 버전업 과정에서 Perl 6의 좋은 특징들을
지속적으로 backport 해왔습니다. Perl 5와 Perl 6는 같은 가족으로서 철학과 문화를 공유하며 같이 발전해 나갈 것 입니다.


=head2 Perl 설치와 모듈 설치

다음 링크는 한눈에 알아볼 수 있는 Perl의 다운로드 페이지입니다.

=over

=item -

L<Download Perl Distributions|http://www.perl.org/get.html>


=back

Windows에서 Perl은 L<Strawberry Perl|http://strawberryperl.com/>과 L<ActiveState Perl|http://www.activestate.com/activeperl>이 있습니다.
사용 예는 다음을 링크를 참고하세요.

=over

=item -

L<MS Windows에서 Perl 활용하기|http://advent.perl.kr/2010/2010-12-01.html>


=item -

L<윈도우즈 환경에서 Perl은 어디에 써먹을 수 있을까?|http://advent.perl.kr/2010/2010-12-05.html>


=item -

L<Win32 Perl Wiki|http://win32.perl.org/wiki/index.php?title=Main_Page>


=back

Solaris, FreeBSD, Mac OS X, Linux 등 UNIX류 OS에는 Perl이 기본으로 설치되어 있습니다.
하지만 다른 패키지들이 의존하고 있는 시스템의 기본 Perl은 건드리지 않고 
최신 버전의 Perl이나 모듈을 나름대로 독립적인 환경에서 설치하여 쓰려면 다음 글을 참고합니다.

=over

=item -

L<How to Use CPAN, Actually|http://advent.perl.kr/2011/2011-12-13.html>


=item -

L<perlbrew, local::lib, smartcd 를 이용하여 Perl 환경 구축하기|http://advent.perl.kr/2011/2011-12-16.html>


=back

요즘은 여러 PaaS(Platform as a Service) Cloud 서비스에서 Perl을 지원하고 있습니다.

=over

=item -

L<DotCloud|http://docs.dotcloud.com/services/perl/>


=item -

L<Stackato|http://docs.stackato.com/perl/index.html>


=item -

L<How to deploy the Perl Dancer framework on OpenShift Express|https://www.redhat.com/openshift/community/kb/kb-e1014-how-to-deploy-the-perl-dancer-framework-on-openshift-express>


=back


=head2 Perl의 성능은 어떤가?

Perl의 성능은 여타 스크립트 언어들에 비해
속도와 메모리 효율성에 있어 우위에 있다고 알려져 있습니다.
현대적 어플리케이션의 대부분의 작업은 문자열(데이터)을 다루는 것이며,
다음은 각 언어들이 얼마나 그것을 빠르게 처리하고
메모리를 효율적으로 다루는가에 초점을 맞춘 벤치마크 자료입니다.
결과를 보면 Perl이 C, C++, PHP, Python, Ruby 등을 제치고 1등의 성능을 보여주고 있음을 볼 수 있습니다.

=over

=item -

L<Perl, Python, Ruby, PHP, C, C++, Lua, tcl, javascript and Java benchmark/comparison.|http://onlyjob.blogspot.com/2011/03/perl5-python-ruby-php-c-c-lua-tcl.html>


=back

벤치마크 결과에 이견이 있을 수는 있지만
별다른 테크닉을 사용하지 않고 평이한 문법을 그대로 사용한 상태에서
빠르고 효율적인 모습을 보여주었다고 하면 그 만큼 더 가치를 발하는 것이겠지요.


=head2 Perl 관련 싸이트는?


=head3 Perl 언어관련

=over

=item -

L<Perl 메인 싸이트|http://www.perl.org> - perl.org


=item -

L<Perl 학습 싸이트|http://learn.perl.org> - learn.perl.org


=item -

L<Perl 문서 싸이트|http://perldoc.perl.org/> - perldoc.perl.org


=item -

L<Perl 5 wiki|https://www.socialtext.net/perl5/> - socialtext.net/perl5


=item -

L<Perl 재단|http://www.perlfoundation.org/> - perlfoundation.org


=back


=head3 CPAN 모듈 관련

CPAN은 라이브러리의 재사용성이 실제로 현실에 적용되도록 해준
선구자적인 모듈 저장소입니다.
CPAN의 모듈수는 10만개를 넘는 수준으로 타의 추종을 불허하며 
PHP의 PEAR, R의 CRAN, Ruby의 rubygems, Python의 Pypi, Node.js의 npm 등의
모듈 저장소들이 CPAN의 모델을 따라 만들어 졌습니다.

=over

=item -

L<오리지널 CPAN 싸이트|http://www.cpan.org> - cpan.org


=item -

L<CPAN모듈 문서에 유저들이 첨언을 넣는 싸이트|http://annocpan.org> - annocpan.org


=item -

L<CPAN모듈의 테스트결과 및 의존관계등에 대한 통계 싸이트|http://cpantesters.org> - cpantesters.org


=item -

L<최근에 생긴 CPAN을 좀 더 자세하고 쉽게 검색하게 해주는 싸이트|https://metacpan.org> - metacpan.org


=item -

L<CPAN모듈들을 예쁘게 가시화해서 보여주는 싸이트|http://mapofcpan.org> - mapofcpan.org


=back


=head3 Perl 관련 커뮤니티 싸이트

외국:

=over

=item -

L<Perl 컨퍼런스 YAPC 정보|http://www.yapc.org/> - yapc.org


=item -

L<YAPC Asia|http://yapcasia.org> - yapcasia.org


=item -

L<Perl 질문/답변 싸이트|http://perlmonks.org> - perlmonks.org


=item -

L<StackOverflow Perl 질문/답변|http://stackoverflow.com/questions/tagged/?tagnames=perl&sort=active>


=item -

L<Reddit Perl 관련 뉴스/토론|http://www.reddit.com/r/perl/>


=item -

L<일본 Perl 유저 그룹|http://j2k.naver.com/j2k_frame.php/korean/perl-users.jp/> (일한번역)


=back

한국:

=over

=item -

L<한국 Perl 대표싸이트|http://perl.kr/> - perl.kr


=item -

L<서울 Perl 몽거스|http://seoul.pm> - seoul.pm


=item -

L<네이버 Perl 카페|http://cafe.naver.com/perlstudy> - cafe.naver.com/perlstudy


=item -

L<서울 Perl 몽거스 크리스마스 달력|http://advent.perl.kr> - advent.perl.kr


=item -

L<#perl-kr IRC 채팅|http://webchat.freenode.net/?channels=perl-kr>


=back


=head3 Perl 뉴스 및 정보 싸이트

다음은 Perl의 최신 소식을 가장 빠르게 받아볼 수 있는 싸이트입니다.
관심있다는 사이트의 RSS를 구독하면 도움이 될 것입니다.

=over

=item -

L<Perl.com|http://www.perl.com/> - perl.com


=item -

L<Perl 5 언어 개발 메일링 리스트|http://www.nntp.perl.org/group/perl.perl5.porters/> (Perl 5 Porters)


=item -

L<Perl 커뮤니티 블로그 플랫폼|http://blogs.perl.org/> - blogs.perl.org


=item -

L<Perl 뉴스|http://perlnews.org/> - perlnews.org


=item -

L<Perl 블로그 포스트 집합소|http://ironman.enlightenedperl.org/> - ironman.enlightenedperl.org


=item -

L<Perl 블로그 포스트 집합소|http://perlsphere.net/> - perlsphere.net


=item -

L<주간지 이메일 아티클 모음|http://perlweekly.com/> - perlweekly.com


=item -

L<Perl 빅 이슈 모음|http://perlbuzz.com/> - perlbuzz.com


=item -

L<Perl 생태계를 총체적으로 아우르는 주옥같은 지혜들|http://www.modernperlbooks.com> - modernperlbooks.com


=item -

L<Perl 재단 뉴스|http://news.perlfoundation.org/> - news.perlfoundation.org


=back


=head2 Perl 관련 프레임웍 및 기술


=head3 웹 관련 프레임웍

웹기술은 주로 C나 Perl로 하던 CGI에서 PHP같은 언어자체가 템플릿요소를 포함한 유행을 거쳐 요즘은 다시
웹서버/캐시레이어/프락시/미들웨어/웹어플리케이션 등의 레이어가 세분화된 프레임웍 기반의 개발이
대세가 되고 있습니다. Perl은 이런 시대적 흐름에 맞춘 각종 웹 관련 프레임웍을 갖추고 있습니다.

=over

=item -

L<Plack|http://plackperl.org/> - 표준적인 웹서버/웹어플리케이션 인터페이스


=item -

L<Deploying Plack Web Applications|http://www.slideshare.net/miyagawa/deploying-plack-web-applications-oscon-2011-8706659>


=item -

L<Tatsumaki로 비동기 웹 서비스 구축하기|http://advent.perl.kr/2011/2011-12-19.html>


=item -

L<Catalyst|http://www.catalystframework.org/> - 본격적인 Perl 웹 프레임워크(Ruby의 Rails와 Python의 Django 급)


=item -

대표적인 레퍼런스 싸이트는 L<BBC iplayer|http://www.bbc.co.uk/iplayer/>와 세계 최대 성인 동영상 싸이트 Youp*rn


=item -

L<Catalyst vs Ruby on Rails|http://www.wikivs.com/wiki/Catalyst_vs_Ruby_on_Rails>


=item -

L<남미 W3C 주최 공공정보 웹서비스화 경연대회 Perl Catalyst팀 우승|http://mdk.per.ly/2011/12/06/perl-rocks-latin-america/>


=item -

L<Dancer|http://perldancer.org/> - 경량 웹 프레임워크 (Ruby의 Sintara와 Python의 Flask 급)


=item -

L<Perl Dancer for Python programmer|http://www.slideshare.net/xSawyer/perl-dancer-for-python-programmers>


=item -

L<초소형 프레임워크와 함께 춤을|http://advent.perl.kr/2011/2011-12-06.html>


=item -

L<Mojolicious|http://mojolicio.us/> - 리얼타임 웹 프레임워크


=item -

L<Mojolicious, HTML5, WebSocket을 이용한 비동기 채팅|http://advent.perl.kr/2011/2011-12-20.html>


=item -

L<기타 Perl 웹 프레임웍들|https://www.socialtext.net/perl5/web_frameworks>


=item -

L<Pocket.io|https://metacpan.org/release/PocketIO> - Socket.IO Plack application


=item -

L<Monday Newbie Corner: Long polling / realtime Web applications?|http://jjnapiorkowski.typepad.com/modern-perl/2011/09/monday-newbie-corner-long-polling-realtime-web-applications.html>


=item -

L<Web::Hippie|https://metacpan.org/release/Web-Hippie> - Web toolkit for the long hair, or comet


=item -

L<AnyMQ, Hippie, and the realtime web|http://www.slideshare.net/clkao/anymq-hippie-and-the-realtime-web>


=item -

L<TIMTOW to build a WebSocket server in Perl|http://showmetheco.de/articles/2010/11/timtow-to-build-a-websocket-server-in-perl.html>



=item -

L<Template Toolkit|http://template-toolkit.org/>


=item -

L<Xslate|http://xslate.org/> - Scalable template engine for Perl5



=item -

대표적 ORM


=item -

L<DBIx::Class for beginners|http://www.slideshare.net/ranguard/dbixclass-introduction-2010>


=item -

L<DBIx::Class로 스키마 관리하기|http://advent.perl.kr/2011/2011-12-17.html>


=item -

L<Fey, Fey, Fey|http://advent.perl.kr/2010/2010-12-11.html>


=back


=head3 비동기/네트웍/동시성 프레임웍

Perl의 Thread는 Python, Ruby와 다르게 GIL(Global Interpreter Lock)이 없어 multi-core CPU 환경에서
모든 core를 사용할 수 있습니다.
L<AnyEvent|https://metacpan.org/search?q=anyevent>, L<POE|https://metacpan.org/search?q=POE> 등 비동기 이벤트 기반 프레임워크나
L<Coro|https://metacpan.org/release/Coro>와 같은 Coroutine도 지원합니다.
이외에도 fork 기반의 다양한 병렬 처리 모듈이 준비되어 있습니다.
L<AnyEvent|https://metacpan.org/search?q=anyevent> 모듈을 만든 L<Marc Lehmann|https://metacpan.org/author/MLEHMANN>이 
AnyEvent에 쓰기위해 만든 L<libev|https://metacpan.org/module/libev>는 우수한 성능이
입증되어 Python의 Twisted, Ruby의 EventMachine, Node.js에서도 기반 라이브러리로 가져다 쓰고 있습니다.

=over

=item -

L<AnyEvent 모듈|https://metacpan.org/search?q=anyevent>


=item -

L<Coro 모듈|https://metacpan.org/release/Coro>


=item -

L<POE 공식 사이트|http://poe.perl.org/>


=back

참고 글:

=over

=item -

L<A Threading Model Overview|http://justin.harmonize.fm/index.php/2008/09/threading-model-overview/>


=item -

L<Why Perl Is a Great Language for Concurrent Programming|http://t-a-w.blogspot.com/2006/10/why-perl-is-great-language-for.html>


=item -

L<Parallel Processing Perl Modules|http://www.openfusion.net/perl/parallel_processing_perl_modules>


=item -

L<how to write fast server with perl|http://d.hatena.ne.jp/tokuhirom/20090924/1253758449>


=back


=head3 GUI 및 그래픽

=over

=item -

L<GTK2|https://metacpan.org/release/Gtk2>


=item -

L<gtk2-perl home|http://gtk2-perl.sourceforge.net/>


=item -

L<Gtk2 programming with DSL|http://advent.perl.kr/2010/2010-12-24.html>


=item -

L<GTK3|https://metacpan.org/release/Gtk3>


=item -

L<Win32::GUI|https://metacpan.org/release/Win32-GUI>


=item -

L<윈도우 환경에서 화면 캡쳐 후 자동 저장 기능의 구현|http://advent.perl.kr/2011/2011-12-07.html>



=item -

L<wxWidgets|https://metacpan.org/release/Wx>


=item -

L<wxWidgets기반 Perl IDE Padre|http://padre.perlide.org/>


=item -

L<Tk|https://metacpan.org/release/Tk>


=item -

L<Tkx|https://metacpan.org/release/Tkx>


=item -

L<Qt|https://metacpan.org/release/Qt>


=item -

L<Prima|https://metacpan.org/release/Prima>


=item -

L<한 이미지 안에 들어있는 사진들 추출하기 Prima 모듈|http://advent.perl.kr/2011/2011-12-15.html>


=item -

L<IUP|https://metacpan.org/release/IUP>


=item -

L<FLTK|https://metacpan.org/release/FLTK>


=item -

L<XUL|https://metacpan.org/release/XUL-Gui>


=item -

L<GD|https://metacpan.org/release/GD>


=item -

L<Imager|https://metacpan.org/release/Imager>


=item -

L<ImageMagick|https://metacpan.org/release/PerlMagick>


=item -

L<SDL|https://metacpan.org/release/SDL>


=item -

L<Perl SDL|http://sdl.perl.org>


=item -

L<OpenGL|https://metacpan.org/release/OpenGL>


=item -

L<Games::Construder|http://ue.o---o.eu/>


=back


=head3 과학 및 수치계산

=over

=item -

L<PDL|http://pdl.perl.org/> - Perl Data Language, Scientific computing with Perl


=item -

L<Generating cool fractrals Matlab vs PDL and others|http://www.freesoftwaremagazine.com/articles/cool_fractals_with_perl_pdl_a_benchmark>


=item -

L<Math modules|https://metacpan.org/search?q=Math>


=item -

L<SOOT|https://metacpan.org/release/SOOT> - Use L<ROOT|http://root.cern.ch/drupal/> in Perl


=item -

L<BioPerl|http://www.bioperl.org> - Perl tools for bioinformatics, genomics and life science


=item -

L<Perl과 생명정보학|http://advent.perl.kr/2010/2010-12-18.html>


=item -

L<NCBI PubMed와 Perl|http://advent.perl.kr/2011/2011-12-05.html>


=item -

L<Circos|http://circos.ca/> - Circular visualization


=item -

L<PDL::Stats|http://pdl-stats.sourceforge.net/> - a collection of statistics modules in Perl Data Language


=item -

L<Statistics::R|https://metacpan.org/release/Statistics-R> - Perl interface with the R statistical program


=item -

L<recommendations on scientific computing with Perl|http://www.perlmonks.org/?node_id=599596>


=item -

L<Perl & Math: A Quick Reference|http://www.perlmonks.org/?node_id=284324>


=back


=head3 시스템관리 및 자동화

Perl은 Linux/UNIX류 운영체제라면 어디에나 기본적으로 설치되어 있고
그 외 다양한 OS에도 포팅되어 있으며 하위 호환성을 잘 지키며
안정적이고 텍스트 처리에 뛰어나다는 장점 때문에 시스템 관리에 주류 언어로 사용되어 왔습니다.
CPAN에는 SSH, Telnet, FTP, SNMP 등 각종 시스템 관리에 필요한 모듈과 툴이 넘쳐납니다.

=over

=item -

L<Automating System Administration with Perl|http://shop.oreilly.com/product/9780596006396.do?green=f33d6c9a-04e8-4123-ac41-044b892a51c9&cmp=af-mybuy-9780596006396.IP>


=item -

L<Perl for System Administration - Perl Training Australia|http://perltraining.com.au/notes/sysadmin.pdf>


=item -

L<slack|http://code.google.com/p/slack/> 


=item -

L<slack 소개|http://wiki.kldp.org/wiki.php/SlackHowto>


=item -

L<Rex|http://rexify.org/> - 시스템관리 자동화 툴


=item -

L<Opsview|http://www.opsview.com> - Catalyst 웹프레임워크, Nagios 기반 모니터링 시스템


=back


=head3 단일파일 배포 및 패키징

=over

=item -

L<PAR::Packer|https://metacpan.org/release/PAR-Packer>


=item -

L<Perl로 GUI로 프로그래밍해서 exe로 배포하고 싶다면?|http://mabook.com/blog/entry/perl-%BF%A1%BC%AD-Wx-%BF%CD-PAR-%C6%A9%C5%E4%B8%AE%BE%F3>


=item -

L<Perl을 EXE로 배포해보자|http://happydal.blogspot.com/2010/08/perl-%EC%9D%84-exe%EB%A1%9C-%EB%B0%B0%ED%8F%AC%ED%95%B4%EB%B3%B4%EC%9E%90.html>


=item -

L<CavaPackager|http://www.cava.co.uk/>


=item -

L<Cava Packager 사용기|http://honeyperl.tistory.com/entry/Tool-Cava-Packager>


=item -

L<PerlApp|http://www.activestate.com/perl-dev-kit>


=item -

L<Perl에서의 컴파일과 크로스플랫폼 지원 정보|http://blog.naver.com/PostView.nhn?blogId=pulsori&logNo=140050516302>


=back


=head2 정리하며

Perl의 세계는 위에서 다 언급하지 못할 정도로 방대합니다.
그 모든 것을 알려드리기에는 이 글로서는 역부족인 것 같네요.
더 궁금하신 것들이 있으면 주위의 Perl 몽거들에게 도움을 청하면 친절하게 알려줄 것입니다.
혹시 아나요, 내년 Perl 달력에서는 여러분의 글이 실리게 될지... :)

아무쪼록 이 글이 부족하나마 Perl 여행을 떠나시려는 분들께 
도움이 되었으면 합니다.

Merry Christmas!! ;-)

