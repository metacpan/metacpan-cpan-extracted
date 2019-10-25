#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Domain::PublicSuffix;

ok( my $dps = Domain::PublicSuffix->new({
	'use_default'             => 1,
	'domain_allow_underscore' => 1,
    'allow_unlisted_tld'      => 1,
}) );

sub checkPublicSuffix {
    my ($root, $domain) = @_;

    is( $dps->get_root_domain($root), $domain, $root . ' -> ' . ($domain or 'undef') );
}

# Any copyright is dedicated to the Public Domain.
# https://creativecommons.org/publicdomain/zero/1.0/

# undef input.
checkPublicSuffix(undef, undef);
# Mixed case.
checkPublicSuffix('COM', undef);
checkPublicSuffix('example.COM', 'example.com');
checkPublicSuffix('WwW.example.COM', 'example.com');
# Leading dot.
checkPublicSuffix('.com', undef);
checkPublicSuffix('.example', undef);
checkPublicSuffix('.example.com', undef);
checkPublicSuffix('.example.example', undef);
# Unlisted TLD.
checkPublicSuffix('example', undef);
checkPublicSuffix('example.example', 'example.example');
checkPublicSuffix('b.example.example', 'example.example');
checkPublicSuffix('a.b.example.example', 'example.example');
# Listed, but non-Internet, TLD.
#checkPublicSuffix('local', undef);
#checkPublicSuffix('example.local', undef);
#checkPublicSuffix('b.example.local', undef);
#checkPublicSuffix('a.b.example.local', undef);
# TLD with only 1 rule.
checkPublicSuffix('biz', undef);
checkPublicSuffix('domain.biz', 'domain.biz');
checkPublicSuffix('b.domain.biz', 'domain.biz');
checkPublicSuffix('a.b.domain.biz', 'domain.biz');
# TLD with some 2-level rules.
checkPublicSuffix('com', undef);
checkPublicSuffix('example.com', 'example.com');
checkPublicSuffix('b.example.com', 'example.com');
checkPublicSuffix('a.b.example.com', 'example.com');
checkPublicSuffix('uk.com', undef);
checkPublicSuffix('example.uk.com', 'example.uk.com');
checkPublicSuffix('b.example.uk.com', 'example.uk.com');
checkPublicSuffix('a.b.example.uk.com', 'example.uk.com');
checkPublicSuffix('test.ac', 'test.ac');
# TLD with only 1 (wildcard) rule.
checkPublicSuffix('mm', undef);
checkPublicSuffix('c.mm', undef);
checkPublicSuffix('b.c.mm', 'b.c.mm');
checkPublicSuffix('a.b.c.mm', 'b.c.mm');
# More complex TLD.
checkPublicSuffix('jp', undef);
checkPublicSuffix('test.jp', 'test.jp');
checkPublicSuffix('www.test.jp', 'test.jp');
checkPublicSuffix('ac.jp', undef);
checkPublicSuffix('test.ac.jp', 'test.ac.jp');
checkPublicSuffix('www.test.ac.jp', 'test.ac.jp');
checkPublicSuffix('kyoto.jp', undef);
checkPublicSuffix('test.kyoto.jp', 'test.kyoto.jp');
checkPublicSuffix('ide.kyoto.jp', undef);
checkPublicSuffix('b.ide.kyoto.jp', 'b.ide.kyoto.jp');
checkPublicSuffix('a.b.ide.kyoto.jp', 'b.ide.kyoto.jp');
checkPublicSuffix('c.kobe.jp', undef);
checkPublicSuffix('b.c.kobe.jp', 'b.c.kobe.jp');
checkPublicSuffix('a.b.c.kobe.jp', 'b.c.kobe.jp');
checkPublicSuffix('city.kobe.jp', 'city.kobe.jp');
checkPublicSuffix('www.city.kobe.jp', 'city.kobe.jp');
# TLD with a wildcard rule and exceptions.
checkPublicSuffix('ck', undef);
checkPublicSuffix('test.ck', undef);
checkPublicSuffix('b.test.ck', 'b.test.ck');
checkPublicSuffix('a.b.test.ck', 'b.test.ck');
checkPublicSuffix('www.ck', 'www.ck');
checkPublicSuffix('www.www.ck', 'www.ck');
# US K12.
checkPublicSuffix('us', undef);
checkPublicSuffix('test.us', 'test.us');
checkPublicSuffix('www.test.us', 'test.us');
checkPublicSuffix('ak.us', undef);
checkPublicSuffix('test.ak.us', 'test.ak.us');
checkPublicSuffix('www.test.ak.us', 'test.ak.us');
checkPublicSuffix('k12.ak.us', undef);
checkPublicSuffix('test.k12.ak.us', 'test.k12.ak.us');
checkPublicSuffix('www.test.k12.ak.us', 'test.k12.ak.us');
# IDN labels.
checkPublicSuffix('食狮.com.cn', '食狮.com.cn');
checkPublicSuffix('食狮.公司.cn', '食狮.公司.cn');
checkPublicSuffix('www.食狮.公司.cn', '食狮.公司.cn');
checkPublicSuffix('shishi.公司.cn', 'shishi.公司.cn');
checkPublicSuffix('公司.cn', undef);
checkPublicSuffix('食狮.中国', '食狮.中国');
checkPublicSuffix('www.食狮.中国', '食狮.中国');
checkPublicSuffix('shishi.中国', 'shishi.中国');
checkPublicSuffix('中国', undef);
# Same as above, but punycoded.
checkPublicSuffix('xn--85x722f.com.cn', 'xn--85x722f.com.cn');
checkPublicSuffix('xn--85x722f.xn--55qx5d.cn', 'xn--85x722f.xn--55qx5d.cn');
checkPublicSuffix('www.xn--85x722f.xn--55qx5d.cn', 'xn--85x722f.xn--55qx5d.cn');
checkPublicSuffix('shishi.xn--55qx5d.cn', 'shishi.xn--55qx5d.cn');
checkPublicSuffix('xn--55qx5d.cn', undef);
checkPublicSuffix('xn--85x722f.xn--fiqs8s', 'xn--85x722f.xn--fiqs8s');
checkPublicSuffix('www.xn--85x722f.xn--fiqs8s', 'xn--85x722f.xn--fiqs8s');
checkPublicSuffix('shishi.xn--fiqs8s', 'shishi.xn--fiqs8s');
checkPublicSuffix('xn--fiqs8s', undef);

done_testing();
