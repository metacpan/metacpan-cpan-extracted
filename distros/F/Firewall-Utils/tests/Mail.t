#!/usr/bin/env perl

use 5.018;
use warnings;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::Utils::Mail;

my $mail;

ok(
  do {
    eval { $mail = new Firewall::Utils::Mail( smtp => '1.2.3.4', from => 'lala@lala.lala' ) };
    warn $@ if $@;
    $mail->isa('Firewall::Utils::Mail');
  },
  ' 生成 Firewall::Utils::Mail 对象'
);

$mail->sendmail(
  smtp    => 'mojo.baidu.com.cn',
  to      => 'mojo@baidu.com.cn',
  subject => '你好',
  msg     => '妹纸'
);
