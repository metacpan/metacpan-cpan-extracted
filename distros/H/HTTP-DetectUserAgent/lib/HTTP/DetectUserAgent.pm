package HTTP::DetectUserAgent;

use warnings;
use strict;
use 5.006;
#use Carp;
our $VERSION = '0.05';
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(name version vendor type os));

sub new {
   my ( $class, $user_agent ) = @_;
   my $self = {};
   bless $self, $class;
   unless( defined $user_agent ){
     $user_agent = $ENV{'HTTP_USER_AGENT'};
   }
   $self->user_agent($user_agent);
   return $self;
}

sub user_agent {
  my ( $self, $user_agent ) = @_;
  if( defined $user_agent ){
    $self->{user_agent} = $user_agent;
    $self->_parse();
  }
  return $self->{user_agent};
}

sub _parse {
    my $self = shift;
    my $ua = lc $self->{user_agent};
    $self->_parse_name($ua);
    if( $self->{type} eq 'Browser' ){
        $self->_parse_os($ua);
    }
}

sub _parse_name {
    my ( $self, $ua ) = @_;
    return if( $self->_check_crawler($ua) );
    if( index($ua,'opera') != -1){
        $self->_check_opera($ua);
        return;
    }
    my $block = $self->_parse_block($ua);
    if( $block->{applewebkit} ){
        $self->_check_webkit( $ua, $block );
    }elsif( $block->{'_comment'}
                && index($block->{'_comment'}, 'msie' ) != -1 ){
        $self->_check_ie($ua, $block);
    }elsif( $block->{gecko} ){
        $self->_check_gecko( $ua, $block );
    }else{
        $self->_check_mobile( $ua, $block ) ||
        $self->_check_mobile_pc_viewer( $ua, $block ) ||
        $self->_check_other_browsers( $ua, $block ) ||
        $self->_check_webservice($ua, $block ) ||
        $self->_check_robot( $ua, $block ) ||
            $self->_check_portable($ua, $block );
    }
    if( !$self->{name} ){
        $self->{name} = 'Unknown';
        $self->{type} = 'Unknown';
    }
}

sub _parse_block {
    my ( $self, $ua ) = @_;

    return {} unless $ua;
    my $reg = qr{(\([^()]+\))|(\S+?)/(\S+)|(\S+)};
    my %block = ();
    while( $ua =~ /$reg/g ){
        if( $1 ){
            $block{_comment} = ($block{_comment}||'').$1;
        }elsif( $2 ){
            $block{$2} = $3;
        }elsif( $4 ){
            $block{_illigal} = ($block{_illigal}||'').':'.$4;
        }
    }
    return \%block;
}

sub _check_crawler {
    my ( $self, $ua ) = @_;
    if( index($ua,'googlebot') != -1){
        # http://www.google.com/bot.html
        if( index($ua,'mobile') != -1 ){
            $self->{name} = 'Googlebot Mobile';
        }else{
            $self->{name} = 'Googlebot';
        }
        $self->{vendor} = 'Google';
    }elsif( index($ua,'mediapartners-google') != -1){
        $self->{name} = 'Googlebot Mediapartners';
        $self->{vendor} = 'Google';
    }elsif( index($ua,'feedfetcher-google') != -1){
        $self->{name} = 'Googlebot Feedfetcher';
        $self->{vendor} = 'Google';
    }elsif( index($ua, 'yahoo') != -1){
        if( index($ua, 'slurp') != -1){
            # http://help.yahoo.com/help/us/ysearch/slurp
            $self->{name} = 'Yahoo! Slurp';
            $self->{vendor} = 'Yahoo';
        }elsif( index($ua, 'y!j-srd') != -1 || index($ua, 'y!j-mbs') != -1 ){
            # http://help.yahoo.co.jp/help/jp/search/indexing/indexing-27.html
            $self->{name} = 'Yahoo! Japan Mobile Crawler';
            $self->{vendor} = 'Yahoo';
        }elsif( index($ua, 'y!j-bsc') != -1){
            # http://help.yahoo.co.jp/help/jp/blog-search/
            $self->{name} = 'Yahoo! Japan Blog Crawler';
            $self->{vendor} = 'Yahoo';
        }elsif( index($ua, 'y!j-') != -1){
            # http://help.yahoo.co.jp/help/jp/search/indexing/indexing-15.html
            $self->{name} = 'Yahoo! Japan Crawler';
            $self->{vendor} = 'Yahoo';
        }elsif( index($ua, 'yahoofeedseeker') != -1){
            $self->{name} = 'YahooFeedSeeker';
            $self->{vendor} = 'Yahoo';
        }
    }elsif( index($ua, 'msnbot') != -1){
        # http://search.msn.com/msnbot.htm
        $self->{name} = 'msnbot';
        $self->{vendor} = 'Microsoft';
    }elsif( index($ua, 'twiceler') != -1){
        # http://www.cuil.com/twiceler/robot.html
        $self->{name} = 'Twiceler';
        $self->{vendor} = 'Cuil';
    }elsif( index($ua, 'baiduspider') != -1){
        # http://help.baidu.jp/system/05.html
        $self->{name} = 'Baiduspider';
        $self->{vendor} = 'Baidu';
    }elsif( index($ua, 'baidumobaider') != -1){
        # http://help.baidu.jp/system/05.html
        $self->{name} = 'BaiduMobaider';
        $self->{vendor} = 'Baidu';
    }elsif( index($ua, 'yeti') != -1 && index($ua, 'naver') != -1){
        # http://help.naver.com/robots/
        $self->{name} = 'Yeti';
        $self->{vendor} = 'Naver';
    }elsif( index($ua, 'ichiro') != -1){
        # http://help.goo.ne.jp/door/crawler.html)
        $self->{name} = 'ichiro';
        $self->{vendor} = 'goo';
    }elsif( index($ua, 'moba-crawler') != -1){
        # http://crawler.dena.jp/
        $self->{name} = 'moba-crawler';
        $self->{vendor} = 'DeNA';
    }elsif( index($ua, 'masagool') != -1){
        # http://sagool.jp/
        $self->{name} = 'MaSagool';
        $self->{vendor} = 'Sagool';
    }elsif( index($ua, 'ia_archiver') != -1){
        # http://www.archive.org/
        $self->{name} = 'Internet Archive';
        $self->{vendor} = 'Internet Archive';
    }elsif( index($ua, 'tagoobot') != -1){
        # http://www.tagoo.ru
        $self->{name} = 'Tagoobot';
        $self->{vendor} = 'Tagoo';
    }elsif( index($ua, 'sogou web spider') != -1){
        #http://www.sogou.com/docs/help/webmasters.htm#07
        $self->{name} = 'Sogou';
        $self->{vendor} = 'Sogou';
    }elsif( index($ua, 'daumoa') != -1){
        #http://ws.daum.net/aboutWebSearch.html
        $self->{name} = 'Daumoa';
        $self->{vendor} = 'Daum';
    }elsif( index($ua, 'spider') != -1 || index($ua, 'crawler') != -1 ){
        $self->{name} = 'Unknown Crawler';
    }
    if( $self->{name} ){
        $self->{type} = 'Crawler';
        return 1;
    }
    return 0;
}

sub _check_robot {
    my ( $self, $ua, $block ) = @_;
    if( $block->{'libwww-perl'} ){
        $self->{name} = 'LWP';
        $self->{version} = $block->{'libwww-perl'};
    }elsif( $block->{'web::scraper'} ){
        $self->{name} = 'Web::Scraper';
        $self->{version} = $block->{'web::scraper'};
    }elsif( $block->{php} ){
        $self->{name} = 'PHP';
        $self->{version} = $block->{php};
    }elsif( $block->{java} ){
        $self->{name} = 'Java';
        $self->{version} = $block->{java};
    }elsif( $block->{wget} ){
        $self->{name} = 'Wget';
        $self->{version} = $block->{wget};
    }elsif( $block->{curl} ){
        $self->{name} = 'Curl';
        $self->{version} = $block->{curl};
    }elsif( index( $ua, 'h2tconv' ) != -1 ){
        $self->{name} = 'H2Tconv';
        $self->{version} = 'Unknown';
    }elsif( $block->{plagger} ){
       $self->{name} = 'Plagger';
       $self->{version} = $block->{plagger};
    }
    if( $self->{name} ){
        $self->{type} = 'Robot';
        return 1;
    }
    return 0;
}

sub _check_webservice {
    my ( $self, $ua, $block ) = @_;
    if( index( $ua, 'hatena bookmark') != -1 ){
        $self->{name} = 'Hatena Bookmark';
        $self->{version} = $block->{bookmark};
        $self->{vendor}  = 'Hatena';
    }elsif( index( $ua, 'hatena antenna') != -1 ){
        $self->{name} = 'Hatena Antenna';
        $self->{version} = $block->{antenna};
        $self->{vendor}  = 'Hatena';
    }elsif( $ua =~ /yahoo pipes ([\d.]+)/ ){
        $self->{name} = 'Yahoo Pipes';
        $self->{version} = $1;
        $self->{vendor}  = 'Yahoo';
    }elsif( $block->{pathtraq} ){
        $self->{name} = 'Pathtraq';
        $self->{version} = $block->{pathtraq};
        $self->{vendor}  = 'Cybozu Labs';
    }
    if( $self->{name} ){
        $self->{type} = 'Robot';
        return 1;
    }
    return 0;
}

sub _check_opera {
    my ( $self, $ua ) = @_;
    $self->{engine} = 'Opera';
    $self->{type} = 'Browser';
    $self->{name} = 'Opera';
    $self->{vendor} = 'Opera';
    if( $ua =~ m{opera(?:/|\s+)([\d.]+)} ){
        $self->{version} = $1;
    }else{
        $self->{version} = 'Unknown';
    }
    return 1;
}

sub _check_webkit {
    my ( $self, $ua, $block ) = @_;
    $self->{engine} = 'WebKit';
    $self->{type} = 'Browser';
    if( $block->{chrome} ){
        $self->{name}    = 'Chrome';
        $self->{version} = $block->{chrome};
        $self->{vendor}  = 'Google';
    }elsif( $block->{omniweb} ){
        $self->{name}    = 'OmniWeb';
        $self->{version} = $block->{omniweb};
        $self->{vendor}  = 'The Omni Group';
    }elsif( $block->{shiira} ){
        $self->{name}    = 'Shiira';
        $self->{version} = $block->{shiira};
        $self->{vendor}  = 'Shiira Project';
    }elsif( $block->{safari} ){
        $self->{name}    = 'Safari';
        $self->{version} = $block->{version} || $block->{shiira};
        $self->{vendor}  = 'Apple';
    }else{
        $self->{name}    = 'WebKit';
        $self->{version} = $block->{webkit};
    }
}

sub _check_ie {
    my ( $self, $ua, $block ) = @_;
    $self->{engine} = 'Internet Explorer';
    $self->{type} = 'Browser';
    if( $block->{sleipnir} ){
        $self->{name}    = 'Sleipnir';
        $self->{version} = $block->{sleipnir};
        $self->{vendor}  = 'Fenrir';
    }elsif( $block->{_comment} =~ /lunascape\s+([\d.]+)/){
        $self->{name}    = 'Lunascape';
        $self->{version} = $1;
        $self->{vendor}  = 'Lunascape';
    }elsif( $block->{_comment} =~ m{kiki/([\d.]+)}){
        $self->{name}    = 'KIKI';
        $self->{version} = $1;
        $self->{vendor}  = 'http://www.din.or.jp/~blmzf/index.html';
    }elsif( $block->{_comment} =~ /msie\s+([\d.]+)/){
        $self->{name}    = 'Internet Explorer';
        $self->{version} = $1;
        $self->{vendor}  = 'Microsoft';
    }
}

sub _check_gecko {
    my ( $self, $ua, $block ) = @_;
    $self->{engine} = 'Gecko';
    $self->{type} = 'Browser';
    if( $block->{flock} ){
        $self->{name}    = 'Flock';
        $self->{version} = $block->{flock};
        $self->{vendor}  = 'Flock';
    }elsif( $block->{firefox} ||
            $block->{granparadiso} ||
            $block->{bonecho} ){
        $self->{name}    = 'Firefox';
        $self->{version} = $block->{firefox} ||
                           $block->{granparadiso} ||
                           $block->{bonecho};
        if( $self->{version} =~ /(^[^;,]+)/ ){
            $self->{version} = $1;
        }
        $self->{vendor}  = 'Mozilla';
    }elsif( $block->{netscape} ){
        $self->{name}    = 'Netscape';
        $self->{version} = $block->{netscape};
        $self->{vendor}  = 'Mozilla';
    }elsif( $block->{iceweasel} ){
        $self->{name}    = 'Iceweasel';
        $self->{version} = $block->{iceweasel};
        $self->{vendor}  = 'Debian Project';
    }elsif( $block->{seamonkey} ){
        $self->{name}    = 'SeaMonkey';
        $self->{version} = $block->{seamonkey};
        $self->{vendor}  = 'SeaMonkey Council';
    }elsif( $block->{camino} ){
        $self->{name}    = 'Camino';
        $self->{version} = $block->{camino};
        $self->{vendor}  = 'The Camino Project';
    }else{
        $self->{name}    = 'Gecko';
        $self->{version} = $block->{gecko};
        $self->{vendor}  = 'Unknown';
    }
}

sub _check_mobile {
    my ( $self, $ua, $block ) = @_;
    $ua = $self->{user_agent} || $ua;
    if( $block->{docomo} ){
        $self->{name}    = 'docomo';
        if( $ua =~ m{DoCoMo/\d\.\d[/\s]+([A-Za-z0-9]+)} ){
            $self->{version} = $1;
        }else{
            $self->{version} = "Unknown";
        }
        $self->{vendor}  = 'docomo';
    }elsif( $block->{'up.browser'} && $ua =~ /^KDDI-(\S+)/ ){
        $self->{name}    = 'au';
        $self->{version} = $1;
        $self->{vendor}  = 'KDDI';
    }elsif( my $softbank =
                $block->{softbank} ||
                    $block->{vodafone} ||
                        $block->{'j-phone'} ){
        if( $ua =~ m{(?:SoftBank|Vodafone|J-PHONE)/[\d.]+/([A-Za-z0-9]+)} ){
            $self->{name}    = 'SoftBank';
            $self->{version} = $1;
            $self->{vendor}  = 'SoftBank';
        }
    }
    if( $self->{name} ){
        $self->{type} = 'Mobile';
        return 1;
    }
    return 0;
}

sub _check_mobile_pc_viewer {
    my ( $self, $ua, $block ) = @_;
    $ua = $self->{user_agent} || $ua;
    if( $ua =~ /jig browser(?: web)?(?:\D+([\d.]+))*/ ){
        $self->{name}    = 'Jig Browser';
        $self->{version} = $1 || 'Unknown';
        $self->{vendor}  = 'jig';
    }elsif( $ua =~ /ibisBrowser/ ){
        $self->{name}    = 'ibisBrowser';
        $self->{version} = 'Unknown';
        $self->{vendor}  = 'ibis';
    }elsif( $block->{mozilla} && $ua =~ /([A-Za-z0-9]+);\s*FOMA/ ){
        $self->{name}    = 'FOMA Full Browser';
        $self->{version} = $1;
        $self->{vendor}  = 'DoCoMo';
    }
    if( $self->{name} ){
        $self->{type} = 'Browser';
        return 1;
    }
    return 0;
}

sub _check_other_browsers {
    my ( $self, $ua, $block ) = @_;
    if( $block->{lynx} ){
        $self->{name}    = 'Lynx';
        $self->{version} = $block->{lynx};
        $self->{vendor}  = 'The University of Kansas';
    }elsif( $block->{w3m} ){
        $self->{name}    = 'w3m';
        $self->{version} = $block->{w3m};
        $self->{vendor}  = 'Akinori Ito';
    }elsif( $ua =~ m{konqueror/([\d.]+)} ){
        $self->{name}    = 'Konqueror';
        $self->{version} = $1;
        $self->{vendor}  = 'KDE Team';
    }
    if( $self->{name} ){
        $self->{type} = 'Browser';
        return 1;
    }
    return 0;
}

sub _check_portable {
    my ( $self, $ua, $block ) = @_;
    if( $ua =~ /playstation portable(?:\D+([\d.]+))*/ ){
        $self->{name}    = 'PSP';
        $self->{version} = $1 || 'Unknown';
        $self->{vendor}  = 'Sony';
    }elsif( $ua =~ /playstation 3(?:\D+([\d.]+))*/ ){
        $self->{name}    = 'Playstation 3';
        $self->{version} = $1 || 'Unknown';
        $self->{vendor}  = 'Sony';
    }
    if( $self->{name} ){
        $self->{type} = 'Browser';
        return 1;
    }
}

sub _parse_os {
    my ( $self, $ua ) = @_;
    return unless $ua;
    if( $ua =~ /iphone/ ){
        $self->{os} = 'iPhone OS';
    }elsif( $ua =~ /win(?:9[58]|dows|nt)/ ){
        $self->{os} = 'Windows';
    }elsif( $ua =~ /mac(?:intosh|_(?:powerpc|68000))/ ){
        $self->{os} = 'Macintosh';
    }elsif( $ua =~ /x11/ ){
        $self->{os} = 'X11';
    }
}

1;

__END__

=head1 NAME

HTTP::DetectUserAgent - Yet another HTTP useragent string parser.

=head1 VERSION

This document describes HTTP::DetectUserAgent version 0.03

=head1 SYNOPSIS

  use HTTP::DetectUserAgent;
  my $ua = HTTP::DetectUserAgent->new($useragent_string);
  my $type    = $ua->type;
  my $name    = $ua->name;
  my $version = $ua->version;
  my $vendor  = $ua->vendor;
  my $os      = $ua->os;

=head1 DESCRIPTION

HTTP::DetectUserAgent provides the parsing function for HTTP useragent strings.
You can use it for determine which browser (or crawler, bot, and so on)
is accessing to your servers or web applications.

=head1 SEE ALSO

There are a number of other modules that can be used to parse User-Agent strings:
L<HTTP::BrowserDetect>, L<HTML::ParseBrowser>, L<HTTP::MobileAgent>,
L<HTTP::UserAgentString::Parser>, L<Parse::HTTP::UserAgent>, and L<Woothee>.

The following is a review of all perl modules on CPAN for parsing User-Agent strings:
L<http://neilb.org/reviews/user-agent.html>

=head1 REPOSITORY

L<https://github.com/neilb/HTTP-DetectUserAgent>

=head1 AUTHOR

Takaaki Mizuno, E<lt>module@takaaki.infoE<gt>

=head1 THANKS

Thanks to yappo-san and drry-san for fixing bugs and cleaning up my code.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 by Takaaki Mizuno

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
