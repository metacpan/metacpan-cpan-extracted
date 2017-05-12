use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;

BEGIN { use_ok 'Finance::Bank::JP::Mizuho' }

my $m = Finance::Bank::JP::Mizuho->new( consumer_id => '12345678' );
$m->logout;

{
    is $m->consumer_id, '12345678';
    ok !$m->logged_in;
    $m->logged_in(1);
    ok $m->logged_in;
    $m->logged_in(0);

    is $m->form1_action(
        qq{<FORM action="https://mydomain.tld/path/to/app.do" name="FORM1" onSubmit="doSomething();return false;">
            HOGEHOGE
        </FORM>}),
        'https://mydomain.tld/path/to/app.do',
        'form1_action';

    is $m->form1_action(
        qq{<FORM name="FORM1" action="https://mydomain.tld/path/to/app.do" onSubmit="doSomething();return false;">
            HOGEHOGE
        </FORM>}),
        'https://mydomain.tld/path/to/app.do',
        'form1_action';

    is
        $m->parse_question(
            q{
                <TR> 
                    <TD width="200" align="right"><DIV style="font-size:9pt">質問：</DIV></TD> 
                    <TD width="390" align="left"><DIV style="font-size:9pt">母親の誕生日はいつですか（例：５月１４日）</DIV></TD> 
                </TR>
            }),
            '母親の誕生日はいつですか（例：５月１４日）',
            'parse_question';

}

{
    like
        $m->login_url1,
        qr{^https://web\d*.ib.mizuhobank\.co\.jp/servlet/mib\?xtr=Emf00000$},
        'login url 1';

    like
        $m->login_url2,
        qr{^https://web\d*\.ib\.mizuhobank\.co\.jp:443/servlet/mib\?xtr=Emf00100&NLS=JP$},
        'login url 2';

    like
        $m->list_url,
        qr{^https://web\d*\.ib\.mizuhobank\.co\.jp/servlet/mib\?xtr=Emf04610&NLS=JP$},
        'list url';

    like
        $m->logout_url,
        qr{^https://web\d*\.ib\.mizuhobank\.co\.jp:443/servlet/mib\?xtr=EmfLogOff&NLS=JP$},
        'logout url';
}
$m->logout;

done_testing;


