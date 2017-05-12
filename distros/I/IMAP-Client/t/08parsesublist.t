use Test::More tests => 346;

use IMAP::Client;
my $client = IMAP::Client->new;
my @resp;

my @lsub_response_cyrus = ('* LIST (\HasChildren) "." "user.johndoe"'."\r\n",
'* LIST (\HasChildren) "." "user.johndoe.spam"'."\r\n",
'* LIST (\HasNoChildren) "." "user.johndoe.spam.total garbage"'."\r\n",
'* LIST (\HasNoChildren) "." "user.johndoe.spam.phishing"'."\r\n",
'* LIST (\HasChildren) "." "user.johndoe.home"'."\r\n",
'* LIST (\HasNoChildren) "." "user.johndoe.home.mom"'."\r\n",
'* LIST (\HasNoChildren) "." "user.johndoe.home.grandparents"'."\r\n",
'1234 OK Completed (0.000 secs 7 calls)'."\r\n");

@resp = IMAP::Client::parse_list_lsub(@lsub_response_cyrus);
is (scalar @resp, 7);
is ($resp[0]->{'FLAGS'}, '\HasChildren');
is ($resp[0]->{'REFERENCE'}, '.');
is ($resp[0]->{'MAILBOX'}, 'user.johndoe');
is ($resp[1]->{'FLAGS'}, '\HasChildren');
is ($resp[1]->{'REFERENCE'}, '.');
is ($resp[1]->{'MAILBOX'}, 'user.johndoe.spam');
is ($resp[2]->{'FLAGS'}, '\HasNoChildren');
is ($resp[2]->{'REFERENCE'}, '.');
is ($resp[2]->{'MAILBOX'}, 'user.johndoe.spam.total garbage');
is ($resp[3]->{'FLAGS'}, '\HasNoChildren');
is ($resp[3]->{'REFERENCE'}, '.');
is ($resp[3]->{'MAILBOX'}, 'user.johndoe.spam.phishing');
is ($resp[4]->{'FLAGS'}, '\HasChildren');
is ($resp[4]->{'REFERENCE'}, '.');
is ($resp[4]->{'MAILBOX'}, 'user.johndoe.home');
is ($resp[5]->{'FLAGS'}, '\HasNoChildren');
is ($resp[5]->{'REFERENCE'}, '.');
is ($resp[5]->{'MAILBOX'}, 'user.johndoe.home.mom');
is ($resp[6]->{'FLAGS'}, '\HasNoChildren');
is ($resp[6]->{'REFERENCE'}, '.');
is ($resp[6]->{'MAILBOX'}, 'user.johndoe.home.grandparents');


#my @lsub_response_iplanet = ('* LIST (\NoInferiors) "/" INBOX'."\r\n",
#'* LIST (\HasNoChildren) "/" Deleted'."\r\n",
#'* LIST (\HasNoChildren) "/" "Deleted Messages"'."\r\n",
#'* LIST (\HasNoChildren) "/" Drafts'."\r\n",
#'* LIST (\HasNoChildren) "/" Junk'."\r\n",
#'* LIST (\HasNoChildren) "/" "Junk E-mail"'."\r\n",
#'* LIST (\HasNoChildren) "/" Sent'."\r\n",
#'* LIST (\HasNoChildren) "/" "Sent Items"'."\r\n",
#'* LIST (\HasNoChildren) "/" Sent-aug-2005'."\r\n",
#'* LIST (\HasNoChildren) "/" Test'."\r\n",
#'* LIST (\HasNoChildren) "/" Test.txt'."\r\n",
#'* LIST (\HasNoChildren) "/" Trash'."\r\n",
#'A1 OK Completed'."\r\n");

#A1 LIST "" "*"
my @lsub_response_iplanet = ('* LIST (\NoInferiors) "/" INBOX'."\r\n",
'* LIST (\HasNoChildren) "/" "Deleted Messages"'."\r\n",
'* LIST (\HasNoChildren) "/" " &-AKEAogCjAKQApQCmAKcAqACpAKoAqwCsAK0ArgCv-"'."\r\n",
'* LIST (\HasNoChildren) "/" !'."\r\n",
'* LIST (\HasNoChildren) "/" !test'."\r\n",
'* LIST (\HasNoChildren) "/" $'."\r\n",
'* LIST (\HasNoChildren) "/" $test'."\r\n",
'* LIST (\HasNoChildren) "/" &-'."\r\n",
'* LIST (\HasNoChildren) "/" &-ALAAsQCyALMAtAC1ALYAtwC4ALkAugC7ALwAvQC+AL8-'."\r\n",
'* LIST (\HasNoChildren) "/" &-AMAAwQDCAMMAxADFAMYAxwDIAMkAygDLAMwAzQDOAM8-'."\r\n",
'* LIST (\HasNoChildren) "/" &-ANAA0QDSANMA1ADVANYA1wDYANkA2gDbANwA3QDeAN8-'."\r\n",
'* LIST (\HasNoChildren) "/" &-AOAA4QDiAOMA5ADlAOYA5wDoAOkA6gDrAOwA7QDuAO8-'."\r\n",
'* LIST (\HasNoChildren) "/" &-APAA8QDyAPMA9AD1APYA9wD4APkA+gD7APwA,QD+AP8-'."\r\n",
'* LIST (\HasNoChildren) "/" &-test'."\r\n",
'* LIST (\HasNoChildren) "/" \''."\r\n",
'* LIST (\HasNoChildren) "/" \'test'."\r\n",
'* LIST (\HasNoChildren) "/" "("'."\r\n",
'* LIST (\HasNoChildren) "/" "(test"'."\r\n",
'* LIST (\HasNoChildren) "/" ")"'."\r\n",
'* LIST (\HasNoChildren) "/" ")test"'."\r\n",
'* LIST (\HasNoChildren) "/" +'."\r\n",
'* LIST (\HasNoChildren) "/" +test'."\r\n",
'* LIST (\HasNoChildren) "/" ,'."\r\n",
'* LIST (\HasNoChildren) "/" ,test'."\r\n",
'* LIST (\HasNoChildren) "/" -'."\r\n",
'* LIST (\HasNoChildren) "/" -test'."\r\n",
'* LIST (\HasNoChildren) "/" :'."\r\n",
'* LIST (\HasNoChildren) "/" :test'."\r\n",
'* LIST (\HasNoChildren) "/" ;'."\r\n",
'* LIST (\HasNoChildren) "/" ;test'."\r\n",
'* LIST (\HasNoChildren) "/" <'."\r\n",
'* LIST (\HasNoChildren) "/" <test'."\r\n",
'* LIST (\HasNoChildren) "/" ='."\r\n",
'* LIST (\HasNoChildren) "/" =test'."\r\n",
'* LIST (\HasNoChildren) "/" >'."\r\n",
'* LIST (\HasNoChildren) "/" >test'."\r\n",
'* LIST (\HasNoChildren) "/" @'."\r\n",
'* LIST (\HasNoChildren) "/" @test'."\r\n",
'* LIST (\HasNoChildren) "/" ['."\r\n",
'* LIST (\HasNoChildren) "/" [test'."\r\n",
'* LIST (\HasNoChildren) "/" ]'."\r\n",
'* LIST (\HasNoChildren) "/" ]test'."\r\n",
'* LIST (\HasNoChildren) "/" ^'."\r\n",
'* LIST (\HasNoChildren) "/" ^test'."\r\n",
'* LIST (\HasNoChildren) "/" _'."\r\n",
'* LIST (\HasNoChildren) "/" _test'."\r\n",
'* LIST (\HasNoChildren) "/" `'."\r\n",
'* LIST (\HasNoChildren) "/" `test'."\r\n",
'* LIST (\HasNoChildren) "/" test!'."\r\n",
'* LIST (\HasNoChildren) "/" test!test'."\r\n",
'* LIST (\HasNoChildren) "/" test#'."\r\n",
'* LIST (\HasNoChildren) "/" test#test'."\r\n",
'* LIST (\HasNoChildren) "/" test$'."\r\n",
'* LIST (\HasNoChildren) "/" test$test'."\r\n",
'* LIST (\HasNoChildren) "/" test&-'."\r\n",
'* LIST (\HasNoChildren) "/" test&-test'."\r\n",
'* LIST (\HasNoChildren) "/" test\''."\r\n",
'* LIST (\HasNoChildren) "/" test\'test'."\r\n",
'* LIST (\HasNoChildren) "/" "test("'."\r\n",
'* LIST (\HasNoChildren) "/" "test(test"'."\r\n",
'* LIST (\HasNoChildren) "/" "test)"'."\r\n",
'* LIST (\HasNoChildren) "/" "test)test"'."\r\n",
'* LIST (\HasNoChildren) "/" test+'."\r\n",
'* LIST (\HasNoChildren) "/" test+test'."\r\n",
'* LIST (\HasNoChildren) "/" test,'."\r\n",
'* LIST (\HasNoChildren) "/" test,test'."\r\n",
'* LIST (\HasNoChildren) "/" test-'."\r\n",
'* LIST (\HasNoChildren) "/" test-test'."\r\n",
'* LIST (\HasNoChildren) "/" test.'."\r\n",
'* LIST (\HasNoChildren) "/" test.test'."\r\n",
'* LIST (\HasNoChildren) "/" test:'."\r\n",
'* LIST (\HasNoChildren) "/" test:test'."\r\n",
'* LIST (\HasNoChildren) "/" test;'."\r\n",
'* LIST (\HasNoChildren) "/" test;test'."\r\n",
'* LIST (\HasNoChildren) "/" test<'."\r\n",
'* LIST (\HasNoChildren) "/" test<test'."\r\n",
'* LIST (\HasNoChildren) "/" test='."\r\n",
'* LIST (\HasNoChildren) "/" test=test'."\r\n",
'* LIST (\HasNoChildren) "/" test>'."\r\n",
'* LIST (\HasNoChildren) "/" test>test'."\r\n",
'* LIST (\HasNoChildren) "/" test@'."\r\n",
'* LIST (\HasNoChildren) "/" test@test'."\r\n",
'* LIST (\HasNoChildren) "/" test['."\r\n",
'* LIST (\HasNoChildren) "/" test[test'."\r\n",
'* LIST (\HasNoChildren) "/" test]'."\r\n",
'* LIST (\HasNoChildren) "/" test]test'."\r\n",
'* LIST (\HasNoChildren) "/" test^'."\r\n",
'* LIST (\HasNoChildren) "/" test^test'."\r\n",
'* LIST (\HasNoChildren) "/" test_'."\r\n",
'* LIST (\HasNoChildren) "/" test_test'."\r\n",
'* LIST (\HasNoChildren) "/" test`'."\r\n",
'* LIST (\HasNoChildren) "/" test`test'."\r\n",
'* LIST (\HasNoChildren) "/" testtest'."\r\n",
'* LIST (\HasNoChildren) "/" "test{"'."\r\n",
'* LIST (\HasNoChildren) "/" "test{test"'."\r\n",
'* LIST (\HasNoChildren) "/" test|'."\r\n",
'* LIST (\HasNoChildren) "/" test|test'."\r\n",
'* LIST (\HasNoChildren) "/" test}'."\r\n",
'* LIST (\HasNoChildren) "/" test}test'."\r\n",
'* LIST (\HasNoChildren) "/" test~'."\r\n",
'* LIST (\HasNoChildren) "/" test~test'."\r\n",
'* LIST (\HasNoChildren) "/" "{"'."\r\n",
'* LIST (\HasNoChildren) "/" "{test"'."\r\n",
'* LIST (\HasNoChildren) "/" |'."\r\n",
'* LIST (\HasNoChildren) "/" |test'."\r\n",
'* LIST (\HasNoChildren) "/" }'."\r\n",
'* LIST (\HasNoChildren) "/" }test'."\r\n",
'* LIST (\HasNoChildren) "/" &-'."\r\n",
#'* LIST (\HasNoChildren) "/" {1}'."\r\n", #"\""
#'"'."\r\n",
'A1 OK Completed'."\r\n");

@resp = IMAP::Client::parse_list_lsub(@lsub_response_iplanet);
#is (scalar @resp, 108);
my @correct_iplanet_mboxes = ('Deleted Messages', ' &-AKEAogCjAKQApQCmAKcAqACpAKoAqwCsAK0ArgCv-', '!', '!test', '$', '$test', '&-', '&-ALAAsQCyALMAtAC1ALYAtwC4ALkAugC7ALwAvQC+AL8-', '&-AMAAwQDCAMMAxADFAMYAxwDIAMkAygDLAMwAzQDOAM8-','&-ANAA0QDSANMA1ADVANYA1wDYANkA2gDbANwA3QDeAN8-', '&-AOAA4QDiAOMA5ADlAOYA5wDoAOkA6gDrAOwA7QDuAO8-', '&-APAA8QDyAPMA9AD1APYA9wD4APkA+gD7APwA,QD+AP8-', '&-test', '\'', '\'test', '(', '(test', ')', ')test', '+', '+test', ',', ',test', '-', '-test', ':', ':test', ';', ';test', '<', '<test', '=', '=test', '>', '>test', '@', '@test', '[', '[test', ']', ']test', '^', '^test', '_', '_test', '`' ,'`test', 'test!', 'test!test', 'test#', 'test#test', 'test$','test$test', 'test&-', 'test&-test', 'test\'', 'test\'test', 'test(', 'test(test', 'test)', 'test)test', 'test+', 'test+test', 'test,', 'test,test', 'test-','test-test', 'test.', 'test.test', 'test:', 'test:test', 'test;', 'test;test', 'test<', 'test<test', 'test=','test=test', 'test>', 'test>test', 'test@', 'test@test', 'test[', 'test[test', 'test]', 'test]test', 'test^', 'test^test', 'test_', 'test_test', 'test`', 'test`test', 'testtest', 'test{', 'test{test', 'test|', 'test|test', 'test}', 'test}test', 'test~', 'test~test', '{', '{test', '|', '|test', '}', '}test', '&-');
is ($resp[0]->{'FLAGS'}, '\NoInferiors'); is ($resp[0]->{'REFERENCE'}, '/'); is ($resp[0]->{'MAILBOX'}, 'INBOX');
$i=0;
foreach my $mbox (@correct_iplanet_mboxes) {
    $i++;
    is ($resp[$i]->{'FLAGS'}, '\HasNoChildren'); 
    is ($resp[$i]->{'REFERENCE'}, '/'); 
    is ($resp[$i]->{'MAILBOX'}, $mbox);
}