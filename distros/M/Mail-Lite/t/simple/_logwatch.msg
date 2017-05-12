From walery  Tue Jan  9 08:55:41 2007
Delivered-To: xdespair@gmail.com
Received: from gmail-pop.l.google.com [64.233.185.109]
	by localhost.localdomain with POP3 (fetchmail-6.3.4)
	for <walery@localhost> (single-drop); Tue, 09 Jan 2007 08:55:41 +0300 (MSK)
Received: by 10.78.164.4 with SMTP id m4cs858561hue;
        Sun, 31 Dec 2006 17:00:02 -0800 (PST)
Received: by 10.49.57.1 with SMTP id j1mr20526210nfk.1167613202786;
        Sun, 31 Dec 2006 17:00:02 -0800 (PST)
Return-Path: <root@testdomain.com>
Received: from mail.testdomain.com (testdomain.com [89.108.90.7])
        by mx.google.com with ESMTP id p43si79327543nfa.2006.12.31.17.00.02;
        Sun, 31 Dec 2006 17:00:02 -0800 (PST)
Received-SPF: pass (google.com: best guess record for domain of root@testdomain.com designates 89.108.90.7 as permitted sender)
Received: from testdomain.com (localhost [127.0.0.1])
	by mail.testdomain.com (Postfix) with ESMTP id 2B402DF800C
	for <root@testdomain.com>; Mon,  1 Jan 2007 04:02:15 +0300 (MSK)
Received: (from root@localhost)
	by testdomain.com (8.13.8/8.13.8/Submit) id l0112BlW001680;
	Mon, 1 Jan 2007 04:02:11 +0300
Date: Mon, 1 Jan 2007 04:02:11 +0300
Message-Id: <200701010102.l0112BlW001680@testdomain.com>
To: root@testdomain.com
From: logwatch@testdomain.com
Subject: Logwatch for testdomain.com (Linux)
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: text/plain; charset="iso-8859-1"
Status: RO
Content-Length: 2709
Lines: 80


 ################### Logwatch 7.2.1 (01/18/06) #################### 
        Processing Initiated: Mon Jan  1 04:02:11 2007
        Date Range Processed: yesterday
                              ( 2006-Dec-31 )
                              Period is day.
      Detail Level of Output: 0
              Type of Output: unformatted
           Logfiles for Host: testdomain.com
  ################################################################## 
 
 --------------------- POP-3 Begin ------------------------ 

 [POP3] Logout stats (in MB):
 ============================
                                    User | Logouts | Downloaded |  Mbox Size
 --------------------------------------- | ------- | ---------- | ----------
                   andrew@testdomain.com |       1 |       0.01 |          0
                   bashanova@agni.com.ru |       5 |       0.00 |          0
                            info@nbbr.ru |       9 |       0.01 |          0
                   makarov@agniphoto.com |       1 |       0.53 |          0
 ---------------------------------------------------------------------------
                                                16 |       0.55 |       0.00
 
 
 
 **Unmatched Entries**
    Disconnected, ip=[::ffff:81.200.210.114]: 2 Time(s)
    LOGIN FAILED, user=makarov, ip=[::ffff:81.200.210.114]: 2 Time(s)
 
 ---------------------- POP-3 End ------------------------- 

 
 --------------------- postfix Begin ------------------------ 

 
 
 16266512 bytes transferred
 755 messages sent
 4 messages expired and returned to sender
 626 messages removed from queue
 
 Unknown users: 150, 1492 Time(s)
 
 SASL Authenticated messages from: 7 Host(s), 48 Time(s)
 
 Relaying denied: 6 Time(s)
 
 Foreign Bounce: 86, 90 Time(s)
 
 Connections lost:
    Connection lost while CONNECT : 223 Time(s)
    Connection lost while DATA : 15 Time(s)
    Connection lost while EHLO : 71 Time(s)
    Connection lost while HELO : 22 Time(s)
    Connection lost while MAIL : 18 Time(s)
    Connection lost while NOOP : 3 Time(s)
    Connection lost while RCPT : 1392 Time(s)
    Connection lost while sending DATA command : 1 Time(s)
 
 
 Illegal address syntax:
    In command MAIL from: 2 Host(s), 3 Time(s)
 
 ---------------------- postfix End ------------------------- 

 
 --------------------- Disk Space Begin ------------------------ 

 Filesystem                            Size   Used  Avail Use%  Mounted on
 /dev/md1                               57G    17G    38G  32%  /var
 /dev/md0                               83G   4.6G    74G   6%  /
 
 
 ---------------------- Disk Space End ------------------------- 

 
 ###################### Logwatch End ######################### 
