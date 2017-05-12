use strict;
use warnings;
use HTML::Video::Embed;

my @urls = (qw|
    http://www.collegehumor.com/video/6879066/disney-princess-spring-breakers-trailer
    http://www.dailymotion.com/video/xy5ueq_action-women-derezzed-movie-montage_shortfilms
    http://www.ebaumsworld.com/video/watch/81510426/
    http://www.funnyordie.com/videos/1ab8850305/spook-hunters
    http://www.liveleak.com/view?i=ffc_1272800490
    http://www.metacafe.com/watch/10099000/clumsy_penguins/
    http://vimeo.com/12279924
    http://www.youtu.be/xExSdzkZZB0
    https://www.youtube.com/watch?v=8EiJHmHPVig
|);

my $embeder = HTML::Video::Embed->new(
    class   => "video",
    secure  => 1,
);

$|++;
foreach my $url ( @urls ){
    my $html = $embeder->url_to_embed( $url );
    next if !$html;

    print $url, "<br/>";
    print $embeder->url_to_embed( $url );
    print "<hr/>";
}
