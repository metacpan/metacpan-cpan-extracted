#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'lyris-announce', 'listname');
is($list->listsoftware, 'Lyris', 'list software');
is($list->posting_address, 'lyris-announce@clio.lyris.net', 'posting address');

__DATA__
Return-Path: <bounce-lyris-announce-1290111@clio.lyris.net>
Received: from clio.lyris.net ([216.91.57.25] verified)
  by example.com (CommuniGate Pro SMTP 4.1.1)
  with SMTP id 484904 for matthew@example.com; Thu, 23 Oct 2003 19:20:28 +0000
From: "Lyris Technologies" <editor@lyris.com>
To: Matthew <matthew@example.com>
Subject: [lyris-announce] Making Mail Work: How Frederick's of Hollywood Does "Bombshell Marketing"
Date: Thu, 23 Oct 2003 12:19:38 -0700
MIME-Version: 1.0
Content-Type: text/plain; charset="ISO-8859-1"
List-Unsubscribe: <mailto:leave-lyris-announce-1290111T@clio.lyris.net>
Reply-To: "Lyris Technologies" <editor@lyris.com>
Message-Id: <LYRIS-1290111-2005106-2003.10.23-12.19.40--matthew#example.com@clio.lyris.net>

You are subscribed as matthew@example.com.
View the online version of this newsletter here:
http://www.lyris.com/makingmailwork

=======================================================================
>>MAKING MAIL WORK
News and Ideas from Lyris Technologies
on Email Marketing, Publishing, and Productivity     

>>IN THIS ISSUE
Free Email Marketing Strategy Book
Customer Spotlight: Fredericks of Hollywood
New ListManager Member Profiles
PR Firm Uses Email Append Service
Lyris Named One of Fastest Growing Companies 
Special Offer: Save $100 on Training
Tips and Tricks: Email Client Testing
Upcoming Events



>>NEW BOOK: ADVANCED EMAIL MARKETING

Do you need to be more strategic in your email marketing approach? 
Not sure how to measure the true ROI of your email program? 

Youll want to get a free copy of Advanced Email Marketing. Written 
by best-selling web marketing expert Jim Sterne, this 115-page guide 
offers examples, worksheets, and charts you can use to optimize your 
email strategy.

[order your free copy:] 
http://www.lyris.com/email_book/


>>HOW FREDERICK'S OF HOLLYWOOD DOES "BOMBSHELL" MARKETING

Famous lingerie retailer Fredericks of Hollywood has always dared to 
be just a little bit different. Fredericks Online Marketing Director 
Jennifer Bedolla unveils her most effective marketing strategy  along 
with her plans for future online initiatives.

[read more:] 
http://www.lyris.com/about/casestudy_fredericks.html

Would you like to be highlighted in a future customer spotlight?
Would you like to build awareness of your company by talking to
journalists researching email marketing? Please contact 
editor@lyris.com to discuss!  


>>LISTMANAGER ADDS MEMBER PROFILES
Let your list members update their preferences or other demographic 
information in easy-to-use web forms. Member Profile forms are one of 
the handy new features in the newest ListManager release, version 7.6. 

[read more:] 
http://www.lyris.com/products/listmanager/whats_new.html


>>REVERSE APPEND STRATEGY FOR PR FIRM

Like many companies with a strong online marketing program, The Primoris 
Group had a great list of leadswith email addresses only. 

In preparation for launching a new hard-copy magazine initiative, the Toronto-
based investor relations PR firm decided to try Lyris new Reverse Email Append 
service. 

We did a test over 20,000 records and were quoted a 20% match  but actually got 
around 30%, says Primoris Group VP Nick Boutsalis. Well follow up and report 
back on Primoris Groups results in a future issue.

[learn more adding postal, telephone or other data to your list:] 
http://www.lyris.com/reverseappend/


>>LYRIS RANKED ONE OF FASTEST GROWING COMPANIES IN SAN FRANCISCO AREA

Despite a sluggish technology sector, Lyris Technologies was recently named 
one of the fastest growing companies in the San Francisco Bay Area.

The San Francisco Business Times traces Lyris success to its independence 
and reliability. "When the dot-coms began to fizzle," the article notes, "Lyris' 
competitors were dying out and Lyris was the one offering new and better (and 
proven) features."

[read more:]
http://www.lyris.com/about/pr/pr-101003.html

[read the SFBT article:]
http://www.lyris.com/about/articles_fastest_growing.pdf


>>SPECIAL OFFER: BECOME A LISTMANAGER PRO AND SAVE $100  

Now for a limited time, you can choose one person on your team to 
become a real email marketing guru! Sign up for both Fundamentals 
and Advanced classes and pay just $400  thats a $100 savings off the 
per-class rate.  

Youll come away with the knowledge and practical tips to take full 
advantage of your email software or hosting investment. The sessions 
normally cost $250/person, last 90 minutes, and are offered via Web 
and telephone conference. 


This special offer is available through December 31, 2003. To enroll, 
call (800) 768-2929 or 

[sign up online:]
http://www.lyris.com/products/listmanager/training.html

Next classes:
FUNDAMENTALS: Nov. 4
ADVANCED: Oct. 28
ENTERPRISE FEATURE SET: call us at (800) 768-2929 for schedule
ADMINISTRATION: Nov. 6

We also offer personalized installation and training assistance, and we're planning
to expand our training program.  If you have suggestions or requests for particular
training topics, please send them to editor@lyris.com.

>>TIPS AND TRICKS: EMAIL CLIENT TESTING

You've tested your mailing for typos, broken links, and missing images. 
But don't press "send" before you test for email client compatibility.

[read more:]
http://www.lyris.com/products/listmanager/tools/html_testing.html

>>UPCOMING EVENTS   

The Folio:Show
October 27-29, 2003 
Hilton New York (New York City)
Booth 332
http://www.folioshow.com 


AD:TECH New York
November 3-5, 2003 in New York City
Hilton New York
Booth 202
http://www.ad-tech.com

NCDM Winter
December 3-5, 2003 in Orlando
Walt Disney World Dolphin
Booth 712
http://www.ncdmwinter.com


----------------------------------------------------------------------


>>ABOUT THIS NEWSLETTER 

We hope you enjoyed this issue of Making Mail Work, the monthly
newsletter of Lyris Technologies. You are subscribed as matthew@example.com. 

UNSUBSCRIBE
To end your subscription, send a blank email to 
leave-lyris-announce-1290111T@clio.lyris.net.

SUBSCRIBE
To add a subscription, send a blank email to join-lyris-announce@clio.lyris.net.
(We'll ask you to confirm your request by follow-up email. Please check your email 
for a confirmation message from *clio.lyris.net*.) 

REFER
To refer a friend or colleague who might be interested in this
publication, visit here: http://clio.lyris.net/invite/3/0/1290111/2005106/10298/10299/450/. 
(We'll ask your friend to confirm interest in a subscription first.) 

CONTACT
Send feedback to: editor@lyris.com.

