# -*- perl -*-

# t/07_builder_integration.t - integration tests

use Test::Most tests => 67 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Email::Address;
use utf8;

my ($mime1,$mime2,$mime3);

lives_ok {
    my $object = Mail::Builder->new();

    isa_ok ($object, 'Mail::Builder');
    ok($object->returnpath('return@test.com'),'Set returnpath ok');
    isa_ok($object->returnpath,'Mail::Builder::Address');
    ok($object->organization('organization'),'Set organization');
    is($object->organization,'organization','Organization ok');
    ok($object->language('de'),'Set language ok');
    is($object->language,'de','Language ok');

    my $replyaddress = Mail::Builder::Address->new('reply@test.com','Reply name');
    ok($object->reply($replyaddress),'Set reply address ok');
    isa_ok($object->reply(),'Mail::Builder::Address');
    ok($object->priority('5'),'Set priority ok');

    throws_ok {
        $object->build_message();
    } qr/Recipient address/,'Recipient address missing';

    ok($object->to('recipient1@test.com'),'Set recipient ok');
    isa_ok($object->to(),'Mail::Builder::List');
    is($object->to->length,1,'One recipient');
    isa_ok($object->to->item(0),'Mail::Builder::Address');
    is($object->to->item(0)->email,'recipient1@test.com','Recipient email ok');
    isa_ok($object->cc(),'Mail::Builder::List');
    is($object->cc->length,0,'CC list empty');
    my $list = Mail::Builder::List->new(type => 'Mail::Builder::Address');
    $list->add('cc1@test.com');
    $list->add('cc2@test.com');
    ok($object->cc($list),'Set new list ok');
    is($object->cc->length,2,'CC list has two addresses');
    throws_ok {
        $object->build_message();
    } qr/From address missing/,'Sender missing';

    ok($object->from('from@test.com'),'Set sender ok');
    ok($object->sender('sender@test.com'),'Set sender ok');
    isa_ok($object->from,'Mail::Builder::Address');
    isa_ok($object->sender,'Mail::Builder::Address');
    is($object->from->email,'from@test.com','From ok');
    ok($object->sender->name('boss'),'Sender ok');
    throws_ok {
        $object->build_message();
    } qr/e-mail subject missing/,'Subject missing';

    ok($object->subject('subject'),'Set subject ok');
    is($object->subject,'subject','Subject ok');

    my $test_date = 'Wed, 26 Oct 2011 14:52:53 +0200';
    ok($object->date($test_date),'Set date ok');

    throws_ok {
        $object->build_message();
    } qr/e-mail content/,'Content missing';

    ok($object->htmltext(qq[<html><head></head><body><h1>Headline</h1>

    <p>
    <ul>
        <li>Bullet</li>
        <li>Bullet</li>
    </ul>
    <strong>This is a bold text</strong>
    <ol>
        <li>Item</li>
        <li>Item</li>
    </ol>
    <em>This is an <span>italic</span> text</em>

    <p><a href="http://k-1.com">Visit me</a></p>

    <img src="cid:revdev" alt="revdev logo"/>

    <table>
      <tr>
        <td>Test1</td>
        <td>Test2</td>
        <td>Test3</td>
      </tr>
      <tr>
        <td colspan="2">Test21</td>
        <td>Test23</td>
      </tr>
      <tr>
        <td>Test31</td>
        <td>Test32</td>
        <td>Test33</td>
      </tr>
    </table>

    </p>
    </body>
    </html>
    ]),'Set HTML Text');

    $mime1 = $object->build_message();

    isa_ok($mime1,'MIME::Entity');
    like($object->{'plaintext'},qr/\t* Bullet/,'Plaintext bullet ok');
    like($object->{'plaintext'},qr/\t1\. Item/,'Plaintext item ok');
    like($object->{'plaintext'},qr/_This is an italic text_/,'Plaintext italic ok');
    like($object->{'plaintext'},qr/\*This is a bold text\*/,'Plaintext bold ok');
    like($object->{'plaintext'},qr/\[http:\/\/k-1\.com Visit me\]/,'Plaintext link ok');
    like($object->{'plaintext'},qr/\[revdev logo\]/,'Plaintext image ok');

    like($object->{'plaintext'},qr/Test1\s\sTest2\s\sTest3/,'Plaintext paragraph ok');
    like($object->{'plaintext'},qr/Test21\s{8}Test23/,'Plaintext paragraph ok');

    isa_ok($mime1->head,'MIME::Head');
    is($mime1->head->get('Date'),$test_date."\n",'Date header ok');
    is($mime1->head->get('To'),'recipient1@test.com'."\n",'Recipient header ok');
    is($mime1->head->get('Cc'),'cc1@test.com,cc2@test.com'."\n",'CC header ok');
    is($mime1->head->get('Sender'),'"boss" <sender@test.com>'."\n",'Sender header ok');
    is($mime1->head->get('X-Priority'),'5'."\n",'Priority header ok');
    is($mime1->head->get('Subject'),'subject'."\n",'Subject header ok');
    is($mime1->parts,2,'No. of mime parts ok');

    $mime2 = $object->stringify();

    like($mime2,qr/Content-Type: text\/html; charset="utf-8"/,'Stringified message ok');
    like($mime2,qr/------_=_NextPart_000\d_/,'Stringified message ok');
} 'Object 1 ok';

lives_ok {
    my $object2 = Mail::Builder->new();

    my $email_address1 = Email::Address->new('Test3','recipient3@test.com');
    my $email_address2 = Email::Address->new('Test4','recipient4@test.com');

    $object2->to->add('recipient2@test.com','nice üft-8 nämé');
    $object2->cc->add('recipient5@test.com','very long name that exceeds the 75 character limit of an encoded word üft-8 nämé');
    $object2->bcc($email_address2);
    $object2->from('from2@test.com','me');
    $object2->sender({ email => 'from3@test.com', name => 'me2'});
    $object2->reply($email_address1);

    $object2->subject('Testmail');
    $object2->plaintext('Text');
    $object2->language('de');
    $object2->attachment->add(qq[t/testfile.pdf],q[test.pdf]);

    is($object2->attachment->length,1,'Attachment length ok');

    $mime3 = $object2->build_message();

    isa_ok($mime3,'MIME::Entity');
    isa_ok($mime3->head,'MIME::Head');

    is($mime3->head->get('To'),'=?UTF-8?B?bmljZSDDvGZ0LTggbsOkbcOp?= <recipient2@test.com>'."\n",'To header encoding ok');
    is($mime3->head->get('Reply-To'),'"Test3" <recipient3@test.com>'."\n",'Reply header encoding ok');
    is($mime3->head->get('Bcc'),'"Test4" <recipient4@test.com>'."\n",'Bcc header encoding ok');
    like($mime3->head->get('Cc'),qr/^=\?UTF-8\?B\?dmVyeSBsb25nIG5hbWUgdGhhdCBleGNlZWRzIHRoZSA3NSBjaGFyYWN0ZXIg\?=\s*=\?UTF-8\?B\?bGltaXQgb2YgYW4gZW5jb2RlZCB3b3JkIMO8ZnQtOCBuw6Rtw6k=\?=\s*<recipient5\@test\.com>\s*$/,'Cc header encoding ok');
    is($mime3->head->get('Subject'),'Testmail'."\n",'Subject ok');
    is($mime3->head->get('From'),'"me" <from2@test.com>'."\n",'From ok');
    is($mime3->head->get('Sender'),'"me2" <from3@test.com>'."\n",'From ok');
    is($mime3->parts,2,'No. of mime parts ok');
    is($mime3->parts(0)->mime_type,'text/plain','Mime type ok');
    is($mime3->parts(1)->mime_type,'application/pdf','Mime type ok');

} 'Object 2 ok';