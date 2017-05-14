package Email::IsFree::CN;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.01';

sub new {
    my $class = shift;
    my %domains;

    while (<DATA>) {
        chomp;
        $domains{$_} = 1;
    }

    bless { domains => \%domains },$class;
}

sub by_domain {
    my $self = shift;
    my $domain = lc(+shift);
    return exists $self->{domains}->{$domain} ? 1 : 0;
}

sub by_email {
    my $self = shift;
    my $email = shift;
    return $self->by_domain((split('@',$email))[-1]);
}

1;

=pod

=head1 NAME

Email::IsFree::CN - Detect whether e-mail is from free provider in China

=head1 SYNOPSIS

  use Email::IsFree::CN;

  my $cnfm = Email::IsFree::CN->new;
  print $cnfm->by_domain('163.com');  # print 1
  print $cnfm->by_email('foo@sina.com');  # print 1
  print $cnfm->by_email('bar@vip.163.com');  # print 0

=head1 ABSTRACT

This module detects whether an e-mail address belongs to a
free e-mail provider in China such as 163.com or sina.com.

=head1 DESCRIPTION

This module can be used to screen credit card orders based
on e-mail.  Many credit card scamsters use free, anonymous
email accounts with another person's name to place fraudulent
orders.

=head1 AUTHOR

Xiaolan Fu <GZ_AF@yahoo.com>

=head1 CREDITS

I got the idea from the module Email::IsFree whose author is 
TJ Mather, thanks.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Xiaolan Fu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__DATA__
163.com
126.com
yeah.net
sina.com
sina.cn
2008.sina.com
yahoo.com.cn
yahoo.com
yahoo.cn
gmail.com
hotmail.com
live.cn
msn.cn
aolchina.com
tom.com
21cn.com
sohu.com
sogou.com
qq.com
foxmail.com
139.com
189.cn
wo.com.cn
eyou.com
56.com
xinhuanet.com
people.com.cn
hexun.com
tianya.cn
ymail.cn
zeld.cn
