Perl WebsphereMQv6.x SSL Tutorial

Requirements:
WebsphereMQ v6 or higher (linux ia32/X64 tested):
http://www.ibm.com/developerworks/downloads/ws/wmq/?S_TACT=105AGX28&S_CMP=TRIALS

Perl MQSeries.pm Cpan Module:
http://search.cpan.org/~hbiersma/MQSeries-1.28-b/MQSeries.pm

At least two hosts
Perl knowledge, how to install cpan-modules.

Goal:
Show working samples of SSL encrypted client connections using perl.

Content:
mq-ca.pl - a simplified frontend to gsk7cmd
MQclient.pl - a client connection script for testing
(You most likely have to change the very first line of the scripts, so they
point to your working instance of perl).

MQmanager-swolinux-sslclient.sh - a script setting up a mqmanager ready for
client connections.

Please see the extensive perldocs, should answer all your questions.
I've tried adding as much as possible here, in case I forget myself
between each time I have to remodify a WMQ queuemanager settings.

--
Morten Bjoernsvik - morten_bjoernsvik@yahoo.no - MAR 2008
