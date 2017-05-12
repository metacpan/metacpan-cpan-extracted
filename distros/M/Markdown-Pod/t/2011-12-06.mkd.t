use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/2011-12-06.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

Title:    초소형 프레임워크와 함께 춤을
Package:  Seoul.pm
Category: perl
Category: Seoul.pm
Author:   am0c


=head2 저자

L<@am0c|http://twitter.com/am0c> - 
단것과 귀여운 것을 좋아하는
올해 크리스마스 달력의 주편집자. 하지만 웹디자인에 더 열중했다는 비하인드 스토리.
결국 L<@keedi|http://twitter.com/keedi>님의 도움을 받고 있다.
최근 안드로이드와 리눅스 커널에 관심을 돌리고 있으나
L<페이스북|http://facebook.com/am0c.yn>의 재미에 빠져 허우적대고 있다.


=head2 시작하며

웹사이트 개발 패러다임도 계속 변하고 있습니다.

CGI가 쌘 놈이었던 때도 있었다고 합니다.
물론 CGI는 이미 흘러간 물입니다. 몇 년 전에는 철도 위에 놓인 루비가 붐이었죠.
지금은 웹 클라우딩뇨인지 클라우드인지 하는 플랫폼 서비스 사업이 일어나고 있습니다.

저는 웹 개발자도 아니고 HTML5를 어서 만져보고 싶어하는 덕후도 아니기 때문에
이런 패러다임에 대해 시시각각 논하지는 못합니다만,
취미로 만든 서비스가 완성되면 보기 좋기 운영하거나 외부에 공개허거나 인터페이스를 제공하고 싶게 되고,
그러다보면 어쨌든 웹 서비스 개발에 직면하게 됩니다.


=head2 무엇으로 만들까

생각해보니 올해 부산에서 열린 지스타에 가지 못했습니다.
현장에서 찍은 사진들을 인터넷에서 구해 아름답게 정리해보고 싶습니다.
부스별로 정리하거나 색상별로 정리하면 즐거울 것 같군요.

일일이 받아서 폴더에 전부 쑤셔넣는 것은 짜증나는 일입니다.
지금은 정말 간단하게 테스트 페이지만 만들고 나중에 다양한 카테고리의 
사진들도 관리하도록 확장하고 싶습니다. 
아무래도 지금이 바로 웹 서비스가 필요한 상황이군요. 그런데 무엇으로 만드는 것이 가장 적합할까요.

Perl에는 아주 좋은 웹 프레임워크가 있습니다. 바로 L<Catalyst|http://www.catalystframework.org/>라고 불리는 놈입니다.
참고로 카탈리스트는 L<크리스마스 달력|http://www.catalystframework.org/calendar>을 진행하고 있습니다. 어쨌든
이것만 있으면 아주 세밀하고도 거대하게 웹을 개발할 수 있고, 대량의 플러그인까지 존재합니다.

그런데 작은 블로그나 웹 페이지 하나 만드는데 이만한 것이 필요한 것은 아닙니다.
그렇다고 정해진 틀에만 구애받아야 하는 PHP의 I<CodeIgniter>는 사용하고 싶지 않습니다.
PHP 페이지 몇개로 include를 나열하는 것은 더 소름끼치는 일입니다.
맙소사, 이 상황에 I<Java>를 사용하라고 하진 않겠죠?

그러니까 너무 간단한 나머지 불필요한 타이핑은 존재하지 않으며, 동시에 유연하고 확장 가능한 것을 원하는 겁니다.
물론 의존하고 있는 라이브러리가 너무 많은 것도 원하지 않습니다. 웹 프레임워크의 설정을 편집하느라 허송세월하고 싶지도 않습니다.
그런건 아무래도 없을테니 올해 크리스마스도 TV와 함께 보내야 하겠군요. 그렇게 슬퍼하고 있을 때,

놀랍게도 그런게 있었다는 겁니다. 바로 L<댄서|http://perldancer.org/>입니다.

    #!perl
    use Dancer;
    
    get '/' => sub {
        "I can code in Christmas!!"
    };
    
    dance;


=head2 세상에 이런것이!

위의 코드는 완전한 코드입니다. 즉 웹브라우저에 C</>로 요청을 하면 C<I can code in Christmas!!>가 출력됩니다.
이보다 간단할 수는 없습니다.

각 라우트 핸들러는 기본적으로 사용자 함수(C<sub>)입니다. GET 요청을 위해 C<get>을 POST 요청을 위해 C<post>를 연결합니다.

    #!perl
    get '/admin' => sub { }
    post '/send' => sub { }

이렇게 간단하게 특정 정적 경로에 대한 핸들러를 기술할 수 있습니다.
물론 패턴 매치를 수행하고 파라미터로 받을 수 있습니다.

    #!perl
    get '/post/id/:id' => sub { 
       my $id = params->{id};
    }

정말 간단하죠? 요청을 통해 들어온 쿼리나 메시지도 이렇게 받아낼 수 있습니다.
또 아래와 같이 정적인 파일을 전달할 수도 있습니다.

    #!perl
    get '/download/:file' => sub {
       my $file = params->{file};
       send_file $file;
    }

헤더를 변경합니다.

    #!perl
    get '/' => sub {
       content_type 'text/plain';
       ...
    }

리다이렉트도 간단합니다.

    #!perl
    get '/admin' => sub {
       redirect '/login';
    }

탬플렛을 지정합니다.

    #!perl
    get '/welcome' => sub {
       template 'welcome', { user => guest' };
    }

로그를 기록합니다.

    #!perl
    get '/error' => sub {
       debug 'TODO or not TODO';
    }

와우! 깔끔해요. :)


=head2 만들어 봅시다

지금까지는 신택스를 보았습니다. 이번에는 실제로 웹 사이트를 만들어 봅시다.
웹에서 많이 사진을 끌어오고 쉽게 관리하는 서비스를 만들어 보겠습니다.
웹 어플리케이션 이름은 I<YouPerl>이라고 지어보았습니다.
CPAN 도구를 통해 Dancer를 설치한 후 아래와 같이 명령을 내리면
YouPerl이라는 웹 어플리케이션을 위한 파일 뼈대들이 생성됩니다.

    #!bash
    $ dancer -a YouPerl
    $ cd YouPerl

C<find>를 입력하여 전체 구조를 살펴봅시다. 아래는 파일을 어느정도 생략한 모습입니다.

    #!bash
    $ find
    ./views
    ./bin
    ./bin/app.pl
    ./t
    ./public
    ./environments
    ./lib
    ./lib/YouPerl.pm

C</views> 디렉터리에는 탬플릿이 위치합니다. C</bin>에는 실행도구들이 있습니다. C</t>디렉터리에는
테스트 스크립트가 모여 있습니다. C</public> 디렉터리 이하의 파일들은 정적 파일로 외부에 노출됩니다.
기본적인 설정은 C</config.yml>에 있지만 C</environments> 디렉터리 밑에 개발버전과 정식버전으로 나눈 설정을
따로 보관합니다. C</lib> 이하에 웹 어플리케이션의 로직 코드가 위치합니다.

아래와 같이 입력하고 웹부라우저를 통해 I<http://localhost:3000/>으로 접근해봅시다.

    #!bash
    $ bin/app.pl

=for html <img src="2011-12-06-1.png" alt="이미 완성?" />

이미 완성된 것 같은 페이지가 뜹니다.
여기에 나타난 링크를 따라가 강좌와 문서를 읽어봅시다.


=head2 재료를 준비합니다

먼저 웹을 통해 지스타 이미지를 긁어 데이터베이스에 기록합니다.
데이터베이스는 L<Redis|http://redis.io/>를 사용하겠습니다. 
L<Dancer::Plugin::Redis|https://metacpan.org/module/Dancer::Plugin::Redis>를 받습니다.

    #!bash
    $ cpanm Dancer::Plugin::Redis

Redis 플러그인은 설정 몇줄만 넣으면 아래와 같이 redis 키워드를 통해 접근할 수 있습니다.

    #!perl
    use Dancer;
    use Dancer::Plugin::Redis;
    
    get '/widget/view/:id' => sub {
        template 'display_widget', { widget => redis->get('hash_key'); };
    };
    
    dance;

설정은 C</config.yml>을 열고 마지막에 다음 네 줄을 입력하면 됩니다.

    #!plain
    plugins:
      Redis:
        server: 127.0.0.1:6379
        debug:  0

아래 구글을 통해 검색해보니 지스타 이미지를 모은 24개의 게시물이 보입니다.
L<Web::Scraper|http://metacpan.org/module/Web::Scraper>나 L<Web::Query|http://metacpan.org/module/Web::Query>를 사용해도 되지만,
24개의 게시물의 경로를 구하기 위한 정규표현식
한 개와 각 게시물에서 이미지를 긁어올 정규표현식 한 개만 있으면 
모든 이미지를 간단히 긁어올 수 있겠습니다.

=for html <img src="2011-12-06-2.png" alt="발견" />

    #!perl
    my $grep_srclist = qr|<a href="([^"]+)".{1,30}지스타 2011 부스걸 사진 보기|si;
    my $grep_imglist = qr|http://p.playforum.net/[^"]+|si;

긁은 이미지의 파일명을 서로 겹치지 않게 하기 위해 MD5 알고리즘을 이용하고, 이것을 데이터베이스에서 각 파일의
식별자로 사용하겠습니다. L<GD::Thumbnail|http://metacpan.org/module/GD::Thumbnail>을 사용하면 쉽게 썸네일을 생성할 수도 있습니다. C<bin/grep_gstar.pl>으로 저장합니다..

    #!perl
    #!/usr/bin/env perl
    use utf8;
    use 5.010;
    use Dancer qw();
    use Dancer::Plugin::Redis;
    use Digest::MD5 qw(md5_hex);
    use GD::Thumbnail;
    use File::Basename;
    use LWP::Simple;
    
    ## 시작 전 데이터베이스 항목 초기화
    redis->setnx("youperl:img:cat.gstar:page", 0);
    
    ## 긁을 페이지 목록을 구하는 구하는 정규표현식과
    ## 각 페이지에서 이미지를 긁을 정규표현식
    my $grep_srclist = qr|<a href="([^"]+)".{1,30}지스타 2011 부스걸 사진 보기|si;
    my $grep_imglist = qr|http://p.playforum.net/[^"]+|si;
    
    ## 일단 첫번째 페이지를 가져와요!
    my $first_page = 'http://www.playforum.net/www/newsDirectory/-/id/1047955';
    my $src_list = get $first_page;
    
    ## 페이지 목록을 긁어요!
    my @urls = $src_list =~ m/$grep_srclist/g;
    my @imgs;
    
    ## 각 페이지를 순회하면서 이미지 목록을 긁어요!
    for my $url ($first_page, @urls) {
        say " <- $url";
        my $src_imgs = get $url;
        push @imgs, $src_imgs =~ m/$grep_imglist/g;
    }
    
    ## 각 이미지를 처리합니다.
    for my $img (@imgs) {
        say $img;
        my ($name, $path, $suffix) = fileparse $img, qr/\.[a-z]+/i;
        my $hex = md5_hex "youperl_$path$name";
        my $fn = "public/img/$hex$suffix";
        my $thumb = "public/img/thumb/$hex$suffix";
        my $i;
    
        ## 유일한 파일명을 구해요.
        while (-e $fn) {
            ++$i;
            $fn = sprintf "public/img/${hex}_%d$suffix", $i;
            $thumb = sprintf "public/img/thumb/${hex}_%d$suffix", $i;
        }
        $hex = "${hex}_$i" if defined $i;
        
        ## 이미지를 저장하구요.
        say " -> $fn";
        getstore $img, $fn unless -e $fn;
    
        ## 작은 파일은 필요 없습니다.
        if (-s $fn < 1024 * 8) {
            say " xx $fn";
            unlink $fn;
            next;
        }
    
        ## 썸네일도 생성합시다.
        say " -> $thumb";
        my $t = GD::Thumbnail->new;
        my $raw = $t->create($fn, 140, 0);
        open my $fh, '>', $thumb or die;
        binmode $fh;
        print $fh $raw;
    
        say " -o $fn";
        ## 데이터베이스에 400개씩 기록합니다.
        my $page = redis->get("youperl:img:cat.gstar:page");
        my $size = redis->llen("youperl:img:cat.gstar:$page");
        if ($size >= 400) {
            $page = redis->incr("youperl:img:cat.gstar:page");
        }
        redis->lpush("youperl:img:cat.gstar:$page", $hex);
    }

긁어온 모습입니다.

=for html <img src="2011-12-06-3.png" alt="잔뜩" />

심심하지 않은 웹서비스를 만들기 위해 각 이미지를 색상별로 분류해 봅니다. 역시 데이터베이스에 기록합니다. C<bin/calc_gstar.pl>으로 저장합니다.

    #!perl
    #!/usr/bin/env perl
    use 5.010;
    use Dancer qw();
    use Dancer::Plugin::Redis;
    use File::Basename;
    use GD;
    
    ## 마음대로 골라본 색상 샘플 목록
    
    my %sample = (
        gray    => [177, 177, 177],
        black   => [0,   0,   0  ],
        red     => [255, 0,   0  ],
        magenta => [255, 0,   255],
        blue    => [0,   0,   255],
        cyan    => [0,   255, 255],
        green   => [0,   255, 0  ],
        yellow  => [255, 255, 0  ],
        white   => [255, 255, 255],
        ocean   => [125, 148, 183],
        grass   => [125, 183, 133],
        sky     => [125, 183, 174],
        flower  => [183, 125, 181],
        stone   => [183, 174, 125],
        wood    => [183, 125, 125],
    );
    
    my $page = redis->get("youperl:img:cat.gstar:page");
    for my $p (0 .. $page) {
        my @items = redis->lrange("youperl:img:cat.gstar:$p", 0, -1);
        for my $item (@items) {
            my ($img) = glob "public/img/$item.*";
            my $color_name = sampling($img);
            
            redis->sadd("youperl:img:cat.gstar.color:$p:$color_name", $item);
        }
    }
    
    
    ## 가장 가까운 색을 고르자
    ##
    sub sampling {
        my $file = shift;
        return unless -f $file;
    
        my ($hex, $path, $suffix) = fileparse $file, qr/\.[a-z]+/i;
    
        my %dist;
        my $image = new GD::Image($file);
        my $color = new GD::Image(1, 1);
    
        ## 이미지 평균 색상값을 구한다.
        ##
        $color->copyResampled(
            $image,
            (0, 0),   (0, 0),
            (1, 1),   ($image->width, $image->height),
        );
    
        my $index = $color->getPixel(0, 0);
    
        ## 샘플 색상과 각각 비교해본다
        ##
        for my $name (keys %sample) {
            $dist{$name} = rgb_dist( $sample{$name}, [$color->rgb($index)] );
        }
    
        ## 오름차순으로 정렬한다
        ##
        my @sort = sort {
            $dist{$a} <=> $dist{$b}
        } keys %sample;
    
        
        print "$hex:\t $sort[0]\t   ";
        print "$_(", int $dist{$_}, ") " for @sort;
        print "\n";
    
        return $sort[0];
    }
    
    sub rgb2xyz {
        my ($r, $g, $b) = @_;
        my ($x, $y, $z);
    
        $r = $r / 255;
        $g = $g / 255;
        $b = $b / 255;
        
        for $c ($r, $g, $b) {
            if ($c > 0.04045) {
                $c = ($c + 0.055) / 1.055;
                $c = $c ** 2.4;
            }
            else {
                $c = $c / 12.92;
            }
            $c = $c * 100;
        }
        
        $x = $r * 0.4124 + $g * 0.3576 + $b * 0.1805;
        $y = $r * 0.2126 + $g * 0.7152 + $b * 0.0722;
        $z = $r * 0.0193 + $g * 0.1192 + $b * 0.9505;
    
        return $x, $y, $z;
    }
    
    sub xyz_dist {
        my ($l, $r) = @_;
        my ($x1, $y1, $z1) = @$l;
        my ($x2, $y2, $z2) = @$r;
        my $t = ($x1 - $x2) ** 2 + ($y1 - $y2) ** 2 + ($z1 - $z2) ** 2;
        return sqrt $t;
    }
    
    sub rgb_dist {
        my ($l, $r) = @_;
        return xyz_dist [rgb2xyz @$l], [rgb2xyz @$r];
    }

색상을 대표하는 값은 GD의 C<copyResampled> 함수를 사용하면 됩니다. "Perl Hacks" 책의 44번 항목을 참고했습니다.
색상별로 분류하는 방법은 다음의 문서를 참고했습니다.

=over

=item -

L<Wikipedia for Color Difference|http://en.wikipedia.org/wiki/Color_difference>


=item -

L<Color Difference Algorithm|http://www.emanueleferonato.com/2009/08/28/color-differences-algorithm/>


=back


=head2 래퍼 만들기

래퍼 파일(C</views/layouts/main.tt>)을 적절하게 수정합니다.
컨테이너 부분이 C<[% content %]>로 되어 있습니다. 각 링크를 클릭하면
선택한 분류에 따라 컨테이너 안에 이미지가 다르게 출력되도록 할 것입니다.
색상 목록을 전역 변수로 빼놓는 것이 더 좋겠습니다.
지금은 그대로 두겠습니다.

    #!plain
    <div id="menu">
      <ul>
        <li> <a href="/category/gstar">지스타</a>
        <li> <a href="/category/gstar/color/gray">gray</a>
        <li> <a href="/category/gstar/color/black">black</a>
        <li> <a href="/category/gstar/color/red">red</a>
        <li> <a href="/category/gstar/color/magenta">magenta</a>
        <li> <a href="/category/gstar/color/blue">blue</a>
        <li> <a href="/category/gstar/color/cyan">cyan</a>
        <li> <a href="/category/gstar/color/green">green</a>
        <li> <a href="/category/gstar/color/yellow">yellow</a>
        <li> <a href="/category/gstar/color/white">white</a>
        <li> <a href="/category/gstar/color/ocean">ocean</a>
        <li> <a href="/category/gstar/color/grass">grass</a>
        <li> <a href="/category/gstar/color/sky">sky</a>
        <li> <a href="/category/gstar/color/flower">flower</a>
        <li> <a href="/category/gstar/color/stone">stone</a>
        <li> <a href="/category/gstar/color/wood">wood</a>
      </ul>
    </div>
    <div id="cont">
      [% content %]
    </div>


=head2 로직 작성하기

먼저 기본 페이지를 만들어야 겠군요. 기본 요청은 이것으로 그대로 둡시다.

    #!perl
    get '/' => sub {
        template 'index';
    };

C<index.tt>는 간단한 문구로 완성합니다.

    #!plain
    I can code in Christmas! :)

C</category/gstar>와 같이 카테고리를 부여하면 특정 카테고리에 해당하는
이미지를 모두 반환하도록 합니다. 템플릿으로 반환합니다.

    #!perl
    get '/category/:category' => sub {
        my $name = param 'category';
        
        my @items = redis->lrange("youperl:img:cat.$name:0", 0, -1);
        my $files = items2files @items;
    
        template 'images', { images => $files };
    };

래퍼는 이미 만들었으므로 이미지 템플릿은 단순히 이미지를 나열하도록 합시다.

    #!plain
    [% FOREACH file IN images %]
      <a href="/img/[% file %]"><img src="/img/thumb/[% file %]" /></a>
    [% END %]

지금은 탬플릿 언어로 L<Template Toolkit|http://template-toolkit.org/>을 사용하고 있습니다. Dancer의 기본
탬플릿 언어는 L<Dancer::Template::Simple|http://metacpan.org/module/Dancer::Template::Simple>입니다. 
탬플릿 언어를 바꾸려면 C<config.yml>을 수정하면 됩니다.
개인적으로 L<Xslate|http://xslate.org/>이 짱입니다. 

여기까지 완성하면 아래와 같이 사진이 잔뜩 올라옵니다.

=for html <img src="2011-12-06-4.png" alt="이렇게요" />

C</category/gstar/color/red>와 같이 특정 색상을 필터하도록 요청해오면
특정 색상에 대한 항목만 반환하도록 합니다. 간단하죠?

    #!perl
    get '/category/*/**' => sub {
        my ($category) = splat;
        var category => $category;
        pass;
    };
    
    prefix '/category/:category';
    get '/color/:color' => sub {
        my ($color)  = param 'color';
        my $category = vars->{category};
    
        my @items = redis->smembers("youperl:img:cat.$category.color:0:$color");
        my $files = items2files @items;
        template 'images', { images => $files, color => $color };
    };

이것으로 완성입니다.
색상에 따라 필터링도 할 수 있게 되었습니다.

=over

=item -

빨간색:


=back

=for html <img src="2011-12-06-5.png" alt="빨강" />

=over

=item -

파란색:


=back

=for html <img src="2011-12-06-6.png" alt="파랑" />

조금만 고치면 살색 사진만 모을 수도 있겠네요!
(라고 Y님이 뒤에서 조언해주셨습니다.)


=head2 정리하며

배치 스크립트 탓에 예제가 조금 길어졌지만, 이렇게 간단한 서비스를 완성해 보았습니다.

물론 이것이 전부는 아닙니다.
I<다양한 데이터베이스와 세션 및 인증 모듈>을 CPAN에서 얻을 수 있습니다.
L<Task::Dancer|http://metacpan.org/module/Task::Dancer>를 설치하거나 이것의 펄독 문서를 참고하면 
좋은 모듈을 찾는데 수월합니다.
Dancer의 I<플러그인들은 모두 초간단 설정을 통해 동작하며 간단한 신택스를 통해 접근>할 수 있습니다.

Dancer는 I<PSGI>와 I<Plack>을 지원합니다. 이것으로 여러분은 Dancer와 서버 사이에 
통합적인 게이트웨이를 둘 수 있습니다. 이것이 있기 때문에 L<DotCloud|http://dotcloud.com/>나 L<Stakato|http://www.activestate.com/cloud>와 같은
클라우드 플랫폼 서비스에 Dancer 어플리케이션을 쉽게 deploy할 수 있습니다.
다른 환경으로 쉽게 이주할 수도 있을 것입니다.

댄서도 올해 L<크리스마스 달력|http://advent.perldancer.org/2011>을 진행하고 있습니다.
오늘 예제를 만들면서 댄서에서는 카탈리스트와 같이 라우트 핸들러를 체인으로 구성하는 것이
쉽지 않다는 것을 느꼈습니다. 이 부분에 대해 논의하면 좋겠습니다.

아래 첨부한 참고 링크에서 슬라이드는 꼭 읽어보세요. Dancer를 쉽게 이해하는데 도움이 됩니다.
또 L<Mojolicious|http://mojolicio.us/>라는 매력적인 웹 프레임워크도 있으니 한 번 둘러보세요.
마지막으로 필요하신 분들을 위해 이번 기사의 코드도 올려놓았습니다.

Let's Dance!

=over

=item -

L<PSGI/Plack|http://plackperl.org/>


=item -

L<perldancer.org|http://perldancer.org/>


=item -

L<Nice Slides|http://perldancer.org/dancefloor>


=item -

L<Cool Dancers|http://perldancer.org/slides>


=item -

L<YouPerl at github|https://github.com/am0c/seoulpm-advent-calendar-youperl>


=back
