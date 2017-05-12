package HTTP::MobileAgent::Plugin::RoamingZone;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');
use HTTP::MobileAgent;
use Mobile::Data::ITU;
use Mobile::Data::SID;

##########################################
# Base Module

package # hide from PAUSE 
       HTTP::MobileAgent;
use Mobile::Data::ITU;

sub zone_code { $_[0]->_zone_code || '440' }

sub _zone_code {}

sub zone_name { 
    my $ret = $_[0]->_zone_name;
    unless ( $ret ) {
        my $code = $_[0]->zone_code;
        $ret = itu2country($code) if ($code =~ /^\d+$/);
        $ret = 'Unknown' unless ($ret);
    }
    $ret;
}

sub _zone_name {}

sub is_oversea { $_[0]->zone_name eq 'Japan' ? 0 : 1 }


##########################################
# DoCoMo Module

package # hide from PAUSE
       HTTP::MobileAgent::DoCoMo;

sub _zone_code { 
    my $ret = $_[0]->get_header('x-dcmroaming');
    $ret =~ s/^.*(\d{3}).*$/$1/ if ( $ret );
    $ret;
}

##########################################
# EZWeb Module

package # hide from PAUSE
       HTTP::MobileAgent::EZweb;
use Mobile::Data::SID;

sub _zone_code { $_[0]->get_header('x-up-devcap-zone') || 12304 }

sub _zone_name { sid2country( $_[0]->zone_code ) }

##########################################
# SoftBank Module

package # hide from PAUSE
       HTTP::MobileAgent::Vodafone;
use Mobile::Data::ITU;

sub _zone_code { $_[0]->get_header('x-jphone-region') }

#sub _zone_name {'Japan' if ( $_[0]->zone_code eq '44020' ) }


1; # Magic true value required at end of module
__END__

=encoding utf-8

=head1 NAME

HTTP::MobileAgent::Plugin::RoamingZone - 日本の携帯電話から国内/海外のアクセス地域情報を得る


=head1 SYNOPSIS

    use HTTP::MobileAgent::Plugin::RoamingZone;

    my $ma = HTTP::MobileAgent->new;

    # 地域コードを得る
    $ma->zone_code;

    # 地域名を得る
    $ma->zone_name;

    # 国外かどうかの判定をする
    $ma->is_oversea;

  
=head1 METHODS

=over

=item C<< zone_code >>

=item C<< zone_name >>

=item C<< is_oversea >>

=back


=head1 DEPENDENCIES

=over

=item C<< HTTP::MobileAgengt >>

=item C<< Mobile::Data::ITU >>

=item C<< Mobile::Data::SID >>

=item C<< Test::Base >>

=back


=head1 BUGS AND LIMITATIONS

本モジュールは以下の仕様に基づき実装され、また実現している機能に制限があります。

=head2 NTTドコモ

L<http://www.nttdocomo.co.jp/service/imode/make/content/ip/index.html#world>に記載された仕様に従い実装され、
国番号を取得し、L<http://www.itu.int/itudoc/itu-t/ob-lists/icc/e212_685.html>で配布されている国番号->国名の
変換テーブルに従って、Mobile::Data::ITUモジュールを使って国名/国内海外判定を行っています。

=head2 SoftBank

L<http://creation.mb.softbank.jp/download.php?docid=102>にて配布されている、技術資料HTTP編に従い実装しています。
2008年8月現在、国内海外判定しか機能せず、国名の判定には対応していません。

=head2 KDDI

公式な仕様が存在していませんが、L<http://mscl.jp/diary/img/KDDI-SA3D.txt>等でレポートされているグローバル
パスポート携帯のみに存在するヘッダC<x-up-devcap-zone>において、L<http://www.ifast.org/files/SIDNumeric.htm>
の仕様に規定された国コードが返される模様であるため、Mobile::Data::SIDモジュールを使って国名変換を行います。


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
