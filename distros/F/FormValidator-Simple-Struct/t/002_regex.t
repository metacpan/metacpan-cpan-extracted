#!perl -w
use utf8;
use strict;
use Test::More;

use FormValidator::Simple::Struct::Regex;

# test FormValidator::Simple::Struct here

# NOT_BLANK

ok FormValidator::Simple::Struct::Regex::NOT_BLANK(1);
ok FormValidator::Simple::Struct::Regex::NOT_BLANK("aaa");
ok FormValidator::Simple::Struct::Regex::NOT_BLANK(0);
ok FormValidator::Simple::Struct::Regex::NOT_BLANK("0");
ok !FormValidator::Simple::Struct::Regex::NOT_BLANK();


# INT
ok FormValidator::Simple::Struct::Regex::INT(1);
ok FormValidator::Simple::Struct::Regex::INT(100);
ok FormValidator::Simple::Struct::Regex::INT(-100);
ok FormValidator::Simple::Struct::Regex::INT("1000000000000000000000000");
ok FormValidator::Simple::Struct::Regex::INT("-100000000000001");

ok !FormValidator::Simple::Struct::Regex::INT("aaa");
ok !FormValidator::Simple::Struct::Regex::INT("111aaa");
ok !FormValidator::Simple::Struct::Regex::INT("aaa111");
ok !FormValidator::Simple::Struct::Regex::INT("aaa111aaa");
ok !FormValidator::Simple::Struct::Regex::INT("111aaa111");

ok !FormValidator::Simple::Struct::Regex::INT(0.13);
ok !FormValidator::Simple::Struct::Regex::INT(-0.13);
ok !FormValidator::Simple::Struct::Regex::INT(1.13);
ok !FormValidator::Simple::Struct::Regex::INT(-1.13);

# ASCII
ok FormValidator::Simple::Struct::Regex::ASCII(1);
ok FormValidator::Simple::Struct::Regex::ASCII("0");
ok FormValidator::Simple::Struct::Regex::ASCII(0.1);
ok FormValidator::Simple::Struct::Regex::ASCII("0.1");
ok FormValidator::Simple::Struct::Regex::ASCII("hoge");
ok FormValidator::Simple::Struct::Regex::ASCII(0);
ok FormValidator::Simple::Struct::Regex::ASCII(0.0);

ok !FormValidator::Simple::Struct::Regex::ASCII("あいうえお");

# DECIMAL

ok FormValidator::Simple::Struct::Regex::DECIMAL(0.13);
ok FormValidator::Simple::Struct::Regex::DECIMAL(-0.13);
ok FormValidator::Simple::Struct::Regex::DECIMAL(1.13);
ok FormValidator::Simple::Struct::Regex::DECIMAL(-1.13);

ok FormValidator::Simple::Struct::Regex::DECIMAL(13);
ok FormValidator::Simple::Struct::Regex::DECIMAL(-13);
ok !FormValidator::Simple::Struct::Regex::DECIMAL("aaa");
ok !FormValidator::Simple::Struct::Regex::DECIMAL("111aaa");
ok !FormValidator::Simple::Struct::Regex::DECIMAL("aaa111");
ok !FormValidator::Simple::Struct::Regex::DECIMAL("aaa111aaa");
ok !FormValidator::Simple::Struct::Regex::DECIMAL("111aaa111");

ok FormValidator::Simple::Struct::Regex::DATETIME("2012-12-20 00:23:59");
ok FormValidator::Simple::Struct::Regex::DATETIME("2012/12/20 00:23:59");
ok FormValidator::Simple::Struct::Regex::DATETIME("2012-12-20 00-23-59");
ok FormValidator::Simple::Struct::Regex::DATETIME("2012/12/20 00-23-59");
ok !FormValidator::Simple::Struct::Regex::DATETIME("2012-12-20 24:28:59");
ok !FormValidator::Simple::Struct::Regex::DATETIME("2012-12-32 00:23:59");
ok !FormValidator::Simple::Struct::Regex::DATETIME("aaaaa");
ok !FormValidator::Simple::Struct::Regex::DATETIME("2012-12-32 00:23:59 aaaa ");
ok !FormValidator::Simple::Struct::Regex::DATETIME("2012-12-32 aaa 00:23:59");

ok FormValidator::Simple::Struct::Regex::DATE("2012-12-20");
ok FormValidator::Simple::Struct::Regex::DATE("2012/12/20");
ok FormValidator::Simple::Struct::Regex::DATE("2012-12-20");
ok FormValidator::Simple::Struct::Regex::DATE("2012/12/20");
ok FormValidator::Simple::Struct::Regex::TIME("24-28-59");
ok FormValidator::Simple::Struct::Regex::TIME("00-23-59");
ok FormValidator::Simple::Struct::Regex::TIME("24:28:59");
ok FormValidator::Simple::Struct::Regex::TIME("00:23:59");
ok !FormValidator::Simple::Struct::Regex::DATE("aaaaa");
ok !FormValidator::Simple::Struct::Regex::TIME("aaaaa");

ok FormValidator::Simple::Struct::Regex::URL("http://google.co.jp");
ok FormValidator::Simple::Struct::Regex::URL("https://google.co.jp");
ok FormValidator::Simple::Struct::Regex::URL("http://localhost/hoge/fuga");
ok FormValidator::Simple::Struct::Regex::URL("https://localhost/hoge/fuga/");

ok !FormValidator::Simple::Struct::Regex::URL("ftp://google.co.jp");
ok !FormValidator::Simple::Struct::Regex::URL("ftps://google.co.jp");
ok !FormValidator::Simple::Struct::Regex::URL("smb://localhost/hoge/fuga");

ok FormValidator::Simple::Struct::Regex::TINYINT(0);
ok FormValidator::Simple::Struct::Regex::TINYINT(1);
ok FormValidator::Simple::Struct::Regex::TINYINT("0");
ok FormValidator::Simple::Struct::Regex::TINYINT("1");
ok !FormValidator::Simple::Struct::Regex::TINYINT(13);
ok !FormValidator::Simple::Struct::Regex::TINYINT(-13);
ok !FormValidator::Simple::Struct::Regex::TINYINT("aaa");
ok !FormValidator::Simple::Struct::Regex::TINYINT("111aaa");
ok !FormValidator::Simple::Struct::Regex::TINYINT("aaa111");
ok !FormValidator::Simple::Struct::Regex::TINYINT("aaa111aaa");
ok !FormValidator::Simple::Struct::Regex::TINYINT("111aaa111");

done_testing;
