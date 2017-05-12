our %CONFIG;

$CONFIG{msgid1} = '200111132338.fADNc4727035@example.com';
$CONFIG{msgid2} = '200111132338.fADNcNg27040@example.com';
$CONFIG{msgid3} = '200111132338.fADNcna27048@example.com';
$CONFIG{msg1from} = "From user  Tue Nov 13 23:38:04 2001\n";
$CONFIG{msg1nofrom} = <<EOF;
Return-Path: <user\@example.com>
Received: (from user\@localhost)
        by host.example.com (8.11.2/8.11.2) id fADNc4727035
        for user; Tue, 13 Nov 2001 23:38:04 GMT
Date: Tue, 13 Nov 2001 23:38:04 GMT
From: User <user\@example.com>
Message-Id: <$CONFIG{msgid1}>
To: user\@host.example.com
Subject: test

EOF
$CONFIG{msg1} = $CONFIG{msg1from} . $CONFIG{msg1nofrom};
$CONFIG{msg2from} = "From user  Tue Nov 13 23:38:23 2001\n";
$CONFIG{msg2nofrom} = <<EOF;
Return-Path: <user\@example.com>
Received: (from user\@localhost)
        by host.example.com (8.11.2/8.11.2) id fADNcNg27040
        for user; Tue, 13 Nov 2001 23:38:23 GMT
Date: Tue, 13 Nov 2001 23:38:23 GMT
From: User <user\@example.com>
Message-Id: <$CONFIG{msgid2}>
To: user\@host.example.com
Subject: test2

EOF
$CONFIG{msg2} = $CONFIG{msg2from} . $CONFIG{msg2nofrom};
$CONFIG{msg3from} = "From user  Tue Nov 13 23:38:49 2001\n";
$CONFIG{msg3topnofrom} = <<EOF;
Return-Path: <user\@example.com>
Received: (from user\@localhost)
        by host.example.com (8.11.2/8.11.2) id fADNcna27048
        for user; Tue, 13 Nov 2001 23:38:49 GMT
Date: Tue, 13 Nov 2001 23:38:49 GMT
From: User <user\@example.com>
Message-Id: <$CONFIG{msgid3}>
To: user\@host.example.com
Subject: test3

it's got a
longer
EOF
$CONFIG{msg3bot} = <<EOF;
body

EOF
$CONFIG{msg3nofrom} = $CONFIG{msg3topnofrom} . $CONFIG{msg3bot};
$CONFIG{msg3} = $CONFIG{msg3from} . $CONFIG{msg3nofrom};
$CONFIG{fake_mbox_text} = join '', $CONFIG{msg1}, $CONFIG{msg2}, $CONFIG{msg3};
$CONFIG{outdir} = File::Temp->newdir;

1;
