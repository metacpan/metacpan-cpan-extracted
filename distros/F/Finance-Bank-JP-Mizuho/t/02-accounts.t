use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;

BEGIN { use_ok 'Finance::Bank::JP::Mizuho' }

{
    my $m = Finance::Bank::JP::Mizuho->new;
    $m->parse_accounts(q{
<TR BGCOLOR="#FFFFFF">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="0"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;目黒支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;普通</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">12345678</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.08.01&nbsp;～&nbsp;2010.09.01</DIV></TD>
</TR>
<TR BGCOLOR="#E6DFEE">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="1"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;恵比寿支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;当座</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">87654321</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.02.01&nbsp;～&nbsp;2010.03.01</DIV></TD>
</TR>
<TR BGCOLOR="#FFFFFF">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="2"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;恵比寿支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;普通</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">10002000</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.04.01</DIV></TD>
</TR>
    });
    
    is @{ $m->accounts }, 3, 'check number of accounts';
    
    my $account;
    
    $account = $m->accounts->[0];
    
    isa_ok $account, 'Finance::Bank::JP::Mizuho::Account', 'check ref 1';
    is $account->branch,      '目黒支店', 'check branch 1';
    is $account->type,        '普通', 'check type 1';
    is $account->radio_value, '0', 'check radio_value 1';
    is $account->number,      '12345678', 'check number 1';
    is $account->last_downloaded_from->year,  '2010', 'check last downloaded from year 1';
    is $account->last_downloaded_from->month, '8', 'check last downloaded from month 1';
    is $account->last_downloaded_from->day,   '1', 'check last downloaded from day 1';
    is $account->last_downloaded_to->year,  '2010', 'check last downloaded to year 1';
    is $account->last_downloaded_to->month, '9', 'check last downloaded to month 1';
    is $account->last_downloaded_to->day,   '1', 'check last downloaded to day 1';
    
    $account = $m->accounts->[1];
    
    isa_ok $account, 'Finance::Bank::JP::Mizuho::Account', 'check ref 2';
    is $account->branch,      '恵比寿支店', 'check branch 2';
    is $account->type,        '当座', 'check type 2';
    is $account->radio_value, '1', 'check radio_value 2';
    is $account->number,      '87654321', 'check number 2';
    is $account->last_downloaded_from->year,  '2010', 'check last downloaded from year 2';
    is $account->last_downloaded_from->month, '2', 'check last downloaded from month 2';
    is $account->last_downloaded_from->day,   '1', 'check last downloaded from day 2';
    is $account->last_downloaded_to->year,  '2010', 'check last downloaded to year 2';
    is $account->last_downloaded_to->month, '3', 'check last downloaded to month 2';
    is $account->last_downloaded_to->day,   '1', 'check last downloaded to day 2';
    
    $account = $m->accounts->[2];
    
    isa_ok $account, 'Finance::Bank::JP::Mizuho::Account', 'check ref 3';
    is $account->branch,      '恵比寿支店', 'check branch 3';
    is $account->type,        '普通', 'check type 3';
    is $account->radio_value, '2', 'check radio_value 3';
    is $account->number,      '10002000', 'check number 3';
    is $account->last_downloaded_from->year,  '2010', 'check last downloaded from year 3';
    is $account->last_downloaded_from->month, '4', 'check last downloaded from month 3';
    is $account->last_downloaded_from->day,   '1', 'check last downloaded from day 3';
    is $account->last_downloaded_to->year,  '2010', 'check last downloaded to year 3';
    is $account->last_downloaded_to->month, '4', 'check last downloaded to month 3';
    is $account->last_downloaded_to->day,   '1', 'check last downloaded to day 3';
    
    $account = $m->account_by_number('12345678');
    
    is $account->branch,      '目黒支店', 'check branch 1';
    is $account->type,        '普通', 'check type 1';
    is $account->radio_value, '0', 'check radio_value 1';
    is $account->number,      '12345678', 'check number 1';
    is $account->last_downloaded_from->year,  '2010', 'check last downloaded from year 1';
    is $account->last_downloaded_from->month, '8', 'check last downloaded from month 1';
    is $account->last_downloaded_from->day,   '1', 'check last downloaded from day 1';
    is $account->last_downloaded_to->year,  '2010', 'check last downloaded to year 1';
    is $account->last_downloaded_to->month, '9', 'check last downloaded to month 1';
    is $account->last_downloaded_to->day,   '1', 'check last downloaded to day 1';
    
}

done_testing;


