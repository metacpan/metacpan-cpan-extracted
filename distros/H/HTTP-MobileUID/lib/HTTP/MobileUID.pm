package HTTP::MobileUID;

use strict;
use warnings;
use base qw/Class::Data::Accessor/;
__PACKAGE__->mk_classaccessors(qw/agent uid convert_uid/);

our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $self = bless {} , ref $proto || $proto;
    $self->init(@_);
    return $self;
}

sub has_uid {  shift->uid }
sub no_uid  { !shift->uid }

*id = \&uid;

sub init {
    my $self  = shift;
    my $agent = $self->agent(shift);
    
    if ( $agent->is_docomo ) {
        # Apache::DoCoMoUIDを利用。
        my $uid = $agent->get_header('x-docomo-uid');
        if ( $self->is_docomo_uid($uid) ) {
            $self->uid($uid);
            $uid =~ s/^0[01]//;
            $self->convert_uid($uid);
        }
    }
    elsif ( $agent->is_softbank ) {
        my $uid = $agent->get_header('x-jphone-uid') || 'NULL';
        if ( $uid ne 'NULL' ) {
            if ( $self->is_softbank_uid($uid) ) {
                $self->uid($uid);
                $uid =~ s/^.//;
                $self->convert_uid($uid);
            }
        }
    }
    elsif ( $agent->is_ezweb ) {
        my $uid = $agent->get_header('x-up-subno');
        if ( $self->is_ezweb_uid($uid) ) {
            $self->uid($uid);
            $self->convert_uid($uid);
        }
    }
}

sub is_docomo_uid {
    my $class = shift;
    my $uid   = shift || '';
    return 0 if $uid eq 'NULLGWDOCOMO';
    $uid =~ /^[0-9a-zA-Z]{12}$/;
}
sub is_softbank_uid { shift; ( shift || '' ) =~ /^[0-9a-zA-Z]{16}$/ }
sub is_ezweb_uid    { shift; ( shift || '' ) =~ /^[0-9]+_[0-9a-zA-Z]+\.[0-9a-zA-Z.\-]+$/ }

1;

__END__

=encoding utf-8

=head1 NAME

HTTP::MobileUID - 携帯端末の公式のユーザIDを取得する

=head1 概要

  use HTTP::MobileUID;
  use HTTP::MobileAgent;
  
  my $agent  = HTTP::MobileAgent->new;
  my $userid = HTTP::MobileUID->new($agent);
  
  print $userid->uid;

=head1 説明

携帯端末の公式のユーザIDを取得します。

=head1 メソッド

=over 4

=item uid()

=item id()

キャリア公式のユーザIDを返します。

DoCoMoの場合はApache::DoCoMoUID互換の環境変数HTTP_X_DOCOMO_UIDから取得する実装になっています。

ユーザIDが取得できなかった場合は未定義値を返します。

=item convert_uid()

コンバートしたユーザIDを返します。

DoCoMoの場合に先頭2文字削っているのと、Softbankの場合に先頭1文字削っているだけです。

基本このメソッドを使うことになると思います。

=item has_uid()

=item no_uid()

端末IDの取得には対応しているが何らかの理由でユーザIDが取得できないケースがあるのでそれを判定します。

no_uidが真になるのは以下のケース

=over 2

=item * DoCoMoでキャリア申請してない場合

=item * SoftBankでユーザIDの通知設定を行わなかった場合

=item * AUでサブスクライバIDの通知設定を行わなかった場合

=back

=item is_docomo_uid($uid)

=item is_softbank_uid($uid)

=item is_ezweb_uid($uid)

ユーザIDとして正しいか判定します。

それぞれクラスメソッドとして用意しているので

 if ( HTTP::MobileUID->is_docomo_uid($uid) ) {}

のような感じで使用することも可能です。

=back

=head1 作者

Ittetsu Miyazaki E<lt>ittetsu.miyazaki __at__ gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>

=cut
