# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { plan tests => 17, todo => [] }

use Mail::Query;

######################### End of black magic.

#$::RD_TRACE = 1;
my $mail = new Mail::Query('data' => [<DATA>]);

ok  $mail->query("To LIKE /swarth/");
ok !$mail->query("To LIKE /gesundheit/");
ok  $mail->query("To NOT LIKE /gesundheit/");
ok  $mail->query("MIME-Version =  '1.0\n'");
ok  $mail->query("MIME-Version <= '3.0'");
ok  $mail->query("Content-type >= 'mashed/potatoes'");
ok  $mail->query("Unknown-header IS NULL");
ok  $mail->query("To IS NOT NULL");
ok  $mail->query("Recipient LIKE /swarth/");
ok  $mail->query("NOT Recipient NOT LIKE /swarth/");
ok  $mail->query("NOT (Recipient NOT LIKE /swarth/)"); #11
ok  $mail->query("To LIKE /swarth/ AND Unknown-header IS NULL");
ok  $mail->query("To LIKE /swarth/ AND NOT (Unknown-header IS NOT NULL OR To IS NULL)");
ok  $mail->query("Body LIKE /609218347983745/");
ok !$mail->query("Body LIKE /609218347983746/");
ok  $mail->query('To LIKE /ken@forum/');
ok  $mail->query("To LIKE /^ken/");

__DATA__
Received: from juniper.its.swarthmore.edu
    (IDENT:postfix@juniper.its.swarthmore.edu [130.58.64.64]) by
    forum.mathforum.com (8.9.1a/8.9.1) with ESMTP id FAA342285 for
    <ken@forum.swarthmore.edu>; Thu, 4 Oct 2001 05:56:56 -0400 (EDT)
Received: from try.com (f231.law11.try.com [64.4.17.231]) by
    juniper.its.swarthmore.edu (Postfix) with ESMTP id BBF0317E85 for
    <ken@forum.swarthmore.edu>; Tue,  2 Oct 2001 13:18:40 -0400 (EDT)
Received: from mail pickup service by try.com with Microsoft SMTPSVC;
    Tue, 2 Oct 2001 10:15:01 -0700
Received: from 12.107.64.128 by lw11fd.law11.try.msn.com with HTTP;
    Tue, 02 Oct 2001 17:15:01 GMT
X-Originating-Ip: [12.107.64.128]
From: "Christian Henry" <nice@try.com>
To: ken@forum.swarthmore.edu
Subject: Re: schickele
Date: Tue, 02 Oct 2001 13:15:01 -0400
MIME-Version: 1.0
Content-Type: text/plain; format=flowed
Message-Id: <F231VH9exkIWh2cuEUb0000d74d@try.com>
X-Originalarrivaltime: 02 Oct 2001 17:15:01.0935 (UTC) FILETIME=[C57083F0:
    01C14B65]

Ken,

You need more information.  You don't have enough information yet, so
I thought you could use more.  Here it is:

34229782130987345876328945761290348712398457612903473849756293
48729834712384762934876213894763904563879456902384789374569021
84739837456092384578236457903284568973645901287348913746509387
42987654309458798374560921834798374560928374987546023948572083
74659812374918764509128374019827654893764509187234091874589763
45890723405897612938745610928374897364589374589176354918723648
90746598273465827364019283740812763598736450892367459871623498
17263598736245087162398547634985076123985476340589767894651082
73645871263408716235489736450982734589723645981723401872364598
23764592736459817623459817623048917623459876349857623485761983

 -Chris
