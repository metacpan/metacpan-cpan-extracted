use strict;
use Test::More tests => 15;

use FormValidator::Simple qw/Japanese/;
use CGI;

my $q = CGI->new;
$q->param( hira => 'ひらがな'  );
$q->param( kata => 'カタカナ'  );
$q->param( hoge => 'ほげほげ'  );
$q->param( jzip1 => '123-4567' );
$q->param( jzip2 => '1234567'  );
$q->param( jzip3 => '123'      );
$q->param( jzip4 => '4567'     );

my $r = FormValidator::Simple->check( $q => [ 
    hira  => [ 'HIRAGANA' ],
    kata  => [ 'KATAKANA' ],
    jzip1 => [ 'ZIP_JP'     ],
    jzip2 => [ 'ZIP_JP'     ],
    { zip => [qw/jzip3 jzip4/] } => [ 'ZIP_JP' ],
] );

ok(!$r->invalid('hira'));
ok(!$r->invalid('kata'));
ok(!$r->invalid('jzip1'));
ok(!$r->invalid('jzip2'));
ok(!$r->invalid('zip'));

my $r2 = FormValidator::Simple->check( $q => [
    hira => [ 'KATAKANA' ],
    kata => [ 'HIRAGANA' ],
] );

ok($r2->invalid('hira'));
ok($r2->invalid('kata'));

my $r3 = FormValidator::Simple->check( $q => [ 
    hira => [ ['JLENGTH', 4] ],
    kata => [ ['JLENGTH', 2, 5] ],
] );

ok(!$r3->invalid('hira'));
ok(!$r3->invalid('kata'));

my $r4 = FormValidator::Simple->check( $q => [
    hira => [ ['JLENGTH', 3] ],
    kata => [ ['JLENGTH', 5, 7] ],
] );

ok($r4->invalid('hira'));
ok($r4->invalid('kata'));

my $q2 = CGI->new;
$q2->param( mail1 => '123456789@docomo.ne.jp'   );
$q2->param( mail2 => '123456789@ezweb.ne.jp'    );
$q2->param( mail3 => '123456789@t.vodafone.ne.jp' );
$q2->param( mail4 => '123456789@softbank.ne.jp' );
my $r5 = FormValidator::Simple->check( $q2 => [
    mail1 => [ 'EMAIL_MOBILE_JP' ],
    mail2 => [ ['EMAIL_MOBILE_JP', 'IMODE'] ],
    mail3 => [ ['EMAIL_MOBILE_JP', 'EZWEB', 'VODAFONE'] ],
    mail4 => [ ['EMAIL_MOBILE_JP', 'SOFTBANK'] ],
] );

ok(!$r5->invalid('mail1'));
ok($r5->invalid('mail2'));
ok(!$r5->invalid('mail3'));
ok(!$r5->invalid('mail4'));
