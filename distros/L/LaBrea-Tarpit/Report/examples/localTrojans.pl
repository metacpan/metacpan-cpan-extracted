#!/usr/bin/perl
package LaBrea::Tarpit::Report::localTrojans;
#
# version 1.25, updated 2-5-05, never complete :-)
#
# find a port by number, try tcp then udp
#
# port assignments can be found at
# http://www.iana.org/assignments/port-numbers
#
# unused trojan lists
# http://www.onctek.com/trojanports.html
#
# some new additionf from
# http://www.dshield.org

# FEEL FREE TO ADD TO BOTH OF THESE TROJAN LISTS
# PLEASE SEND UPDATES TO michael@bizsystems.com
# differences would be appreciated.

#use diagnostics;
use vars qw( $trojans );

$trojans = {
# some well known ports not always in 'services'
  1108	=> 'ratio-adp',
  1115	=> 'ardus-trns',
  1182	=> 'Sobig.a (BigBoss) virus',
  1214	=> 'Kazaa',
  1257	=> 'Frenzy - Frenzy2000',
  1555	=> 'Sobig.e - RTSP Streaming Media Proxy',
  1745	=> 'Qhosts aka (aolfix.exe) trojan',
  1998	=> 'cisco X.25 service',
  2001	=> 'Sobig.e - Remote Control Service',
  2002	=> 'TransScout',
  2003	=> 'TransScout',
  2004	=> 'TransScout',
  2005	=> 'TransScout',
  2280	=> 'Sobig.e - SOCKS Proxy server',
  2281	=> 'Sobig.e - Telnet Proxy server',
  2282	=> 'Sobig.e - WWW Proxy server',
  2283	=> 'Sobig.e - FTP Proxy server',
  2284	=> 'Sobig.e - POP3 Proxy server',
  2285	=> 'Sobig.e - SMTP Server',
  3127	=> 'MyDoom_A',
  3128	=> 'MyDoom',
  3382	=> 'fujitsu-neat',
  3643	=> 'AudioJuggler',
  4480	=> 'proxy-plus',
  4489	=> 'Brown Orifice??',
  5190	=> 'Aol Instant Messenger',
  5191	=> 'Aol Instant Messenger',
  5192	=> 'Aol Instant Messenger',
  5193	=> 'Aol Instant Messenger',
  5433	=> 'postgreSQL, Stunnel',
  5490	=> 'LNVALARM Access',
  5554	=> 'Sasser Worm',
  6346	=> 'Gnutella',
  6588	=> 'AnalogX Proxy Server',
  6660	=> 'IRC Chat',
  6661	=> 'IRC Chat',
  6662	=> 'IRC Chat',
  6663	=> 'IRC Chat',
  6664	=> 'IRC Chat',
  6665	=> 'IRC Chat',
  6666	=> 'IRC Chat',
  6667	=> 'IRC Chat',
  6668	=> 'IRC Chat',
  6669	=> 'IRC Chat',
  7441	=> 'LNVALARM Access',
  8000	=> 'Shoutcast WWW Server Hack',
  8001	=> 'VCOM Tunnel',
  8002	=> 'Teradata ORDMBS',
  8180	=> 'Aplore/Aphex/Bloodhound worm',
  9100	=> 'Backdoor.Cabro',
  10080	=> 'alternate www, MyDoom',
  10168	=> 'Lovgates remote control',
  20168	=> 'Lovgates remote control',
  25867	=> 'Ring0 trojan',
  34816	=> 'Dirt, Backdoor.SubSari15 trojan',
  45295	=> 'Firebird DB trojan',
  43981	=> 'NewareIP',
# these trojans can be found at
# http://www.robertgraham.com/pubs/firewall-seen.html
  555	=> 'phAse zero',
  1243	=> 'Sub-7',
  2745	=> 'Bagle backdoor',
  3129	=> 'Masters Paradise',
  4755	=> 'Bagle-V backdoor',
  6670  => 'Deep Throat',
  6711	=> 'Sub-7',
  6969	=> 'GateCrasher',
  9898	=> 'Dabber Virus backdoor',
  21544	=> 'GirlFriend',
  12345	=> 'NetBus',
  23456	=> 'EvilFTP',
  27374	=> 'Sub-7',
  30100	=> 'NetSphere',
  31789	=> "Hack'aTack",
  31337	=> 'BackOrifice',
  50505	=> 'Sockets de Troie',
  65506	=> 'myDoom proxy',
};


my $builder = sub {
  my($port,@trjs) = @_;
  my $line = '';
  foreach(0..$#trjs) {
    $trjs[$_] =~ s/\s+([\..]+)/$1/;
    while ($trjs[$_] =~ /\s$/) { chop $trjs[$_] };
    if (length($trjs[$_]) + length($line) > 25) {
      if ($line) {
        $line .= ', more...';
      } elsif (length($trjs[$_]) < 37) {
	$line = $trjs[$_];
      } else {
	$line = substr($trjs[$_],0,34) . '...';
      }
      last;
    } else {
      $line .= ', ' if $line;
      $line .= $trjs[$_];
    }
  }
  return($line);
};


# overlay above with below in order

@_ = split('\n',q|
#
# my additions + user contributions
1 Sockets des Troie
2 Death
701 Marotob
778 NetCrack
887 W32.Huayu
890 Dsklite
905 Netdevil
1022 W32.Sasser
1023 W32.Sasser
1026 MStask planner
1027 ICQ port trojan
1029 ICQ port trojan
1093 proofd
1094 rootd
1220 qt-serveradmin
1502 T.120
1533 LiveTutor
1666 netview-aix-6
1718 Gatekeeper Discovery
1719 Gatekeeper RAS
1731 Audio Call Control
1900 MS UPnP
1915 facelink
1978 unisql
2082 infowave
3606 splitlock
4128 RedShad, RCServer backdoor
4899 Radmin, JDeveloperPro
6101 Veritas Backup Exploit
6129 Dameware
7040 Star Wars Galaxies server
7070 Star Wars Galaxies server
9666 RabbIT2
8004 IExchange https proxy
8005 IExchange https proxy
8081 Tomcat 4 proxy
9273 trojan Wingate 3.0
9274 trojan Wingate 3.0
9275 trojan Wingate 3.0
9276 trojan Wingate 3.0
9277 trojan Wingate 3.0
9278 trojan Wingate 3.0
11768 Dipnet/Oddbob
14441 Bagel-V Mitglieder.AG
15118 Dipnet/Oddbob
17300 Milkit trojan
17771 Bagel-V Mitglieder.AG
18844 backdoor socks4 proxy
21000 IRTrans Control
29992 Bagel-V Mitglieder.BG
31121 Troj/BagleDl-H
38884 Bagle-V Mitglieder.BN
#
# this URL has links to many descriptions of hacks and ports that are
# not listed on it's port list page which are included below.
# ports from: http://www.networkice.com/Advice/Exploits/Ports/default.htm
# some trojans here, some well known ports
27 ETRN
29 msg-icp
31 msg-auth
33 dsp
38 RAP
49 TACACS, Login Host Protocol
50 RMCP, re-mail-ck
59 NFILE
63 whois++
66 sql*net
96 DIXIE
98 linuxconf
106 poppassd
124 SecureID
129 PWDGEN
133 statsrv
135 loc-srv/epmap
144 NewS
152 BFTP
153 SGMP
175 vmnet
180 SLmail admin
218 MPP
259 ESRO
264 FW1_topo
311 Apple WebAdmin
350 MATIP type A
351 MATIP type B
363 RSVP tunnel
366 ODMR (On-Demand Mail Relay)
387 AppleTalk Update-Based Routing Protocol
389 LDAP
407 Timbuktu
434 Mobile IP
443 ssl
444 snpp, Simple Network Paging Protocol
445 SMB
458 QuickTime TV/Conferencing
468 Photuris
500 ISAKMP, pluto
521 RIPng
522 ULS
531 IRC
543 KLogin, AppleShare over IP
545 QuickTime
548 AFP
554 Real Time Streaming Protocol
555 phAse Zero
563 NNTP over SSL
575 VEMMI
581 Bundle Discovery Protocol
593 MS-RPC
608 SIFT/UFT
626 Apple ASIA
631 IPP (Internet Printing Protocol)
635 mountd
636 sldap
642 EMSD
648 RRP (NSI Registry Registrar Protocol)
655 tinc
660 Apple MacOS Server Admin
666 Doom
674 ACAP
687 AppleShare IP Registry
700 buddyphone
705 AgentX for SNMP
901 swat, realsecure
993 s-imap
995 s-pop
1062 Veracity
1080 MyDoom
1085 WebObjects
1227 DNS2Go
1243 SubSeven
1338 Millennium Worm
1352 Lotus Notes
1381 Apple Network License Manager
1417 Timbuktu
1418 Timbuktu
1419 Timbuktu
1433 Microsoft SQL Server
1434 Microsoft SQL Monitor
1494 Citrix ICA Protocol
1503 T.120
1521 Oracle SQL
1525 prospero
1526 prospero
1527 tlisrv
1604 Citrix ICA, MS Terminal Server
1645 RADIUS Authentication
1646 RADIUS Accounting
1680 Carbon Copy
1701 L2TP/LSF
1717 Convoy
1720 H.323/Q.931
1723 PPTP control port
1755 Windows Media .asf
1758 TFTP multicast
1812 RADIUS server
1813 RADIUS accounting
1818 ETFTP
1973 DLSw DCAP/DRAP
1985 HSRP
1999 Cisco AUTH
2001 glimpse
2049 NFS
2064 distributed.net
2065 DLSw
2066 DLSw
2106 MZAP
2140 DeepThroat
2301 Compaq Insight Management Web Agents
2327 Netscape Conference
2336 Apple UG Control
2427 MGCP gateway
2504 WLBS
2535 MADCAP
2543 sip
2592 netrek
2727 MGCP call agent
2628 DICT
2998 ISS Real Secure Console Service Port
3000 Firstclass
3031 Apple AgentVU
3128 squid
3130 ICP
3150 DeepThroat
3264 ccmail
3283 Apple NetAssitant
3288 COPS
3305 ODETTE
3306 mySQL
3389 RDP Protocol (Terminal Server)
3521 netrek
4000 icq, command-n-conquer
4321 rwhois
4333 mSQL
4827 HTCP
5004 RTP
5005 RTP
5010 Yahoo! Messenger
5060 SIP
5190 AIM
5500 securid
5501 securidprop
5423 Apple VirtualUser
5631 PCAnywhere data
5632 PCAnywhere
5800 VNC
5801 VNC
5900 VNC
5901 VNC
6000 X Windows
6112 BattleNet, CDE
6502 Netscape Conference
6667 IRC
6670 VocalTec Internet Phone, DeepThroat
6699 napster
6776 Sub7
6970 RTP
7007 MSBD, Windows Media encoder
7070 RealServer/QuickTime
7778 Unreal
7648 CU-SeeMe
7649 CU-SeeMe
8010 WinGate 2.1
8080 HTTP
8181 HTTP
8383 IMail WWW
8875 napster
8888 napster
10008 cheese worm
11371 PGP 5 Keyserver
13223 PowWow
13224 PowWow
14237 Palm
14238 Palm
18888 LiquidAudio
21157 Activision
23213 PowWow
23214 PowWow
23456 EvilFTP
26000 Quake
27001 QuakeWorld
27010 Half-Life
27015 Half-Life
27960 QuakeIII
30029 AOL Admin
31337 Back Orifice
32777 rpc.walld
40193 Novell
41524 arcserve discovery
45000 Cisco NetRanger postofficed
32773 rpc.ttdbserverd
32776 rpc.spray
32779 rpc.cmsd
38036 timestep
|);

foreach(@_) {
  next unless $_ =~ /^(\d+)\s+(.*)$/;
  $trojans->{$1} = $2;
}

# trojans from 
# http://www.simovits.com/trojans/trojans.html
#
# this is the most comprehensive list of trojans
#
@_ = split(/\n/,q
|port 0 REx
port 1 (UDP) - Sockets des Troie
port 2 Death
port 5 yoyo
port 11 Skun
port 16 Skun
port 17 Skun
port 18 Skun
port 19 Skun
port 20 Amanda
port 21 ADM worm, Back Construction, Blade Runner, BlueFire, Bmail,Cattivik FTP Server, CC Invader, Dark FTP, Doly Trojan, FreddyK,Invisible FTP,KWM, MscanWorm, NerTe, NokNok, Pinochet, Ramen, Reverse Trojan, RTB 666,The Flu, WinCrash, Voyager Alpha Force
port 22 InCommand, Shaft, Skun
port 23 ADM worm, Aphex's Remote Packet Sniffer , AutoSpY, ButtMan, Fire HacKer, My Very Own trojan, Pest, RTB 666, Tiny Telnet Server - TTS,Truva Atl
port 25 Antigen, Barok, BSE, Email Password Sender , Gip, Laocoon, Magic Horse, MBT , Moscow Email trojan, Nimda, Shtirlitz, Stukach, Tapiras, WinPC
port 27 Assasin
port 28 Amanda
port 30 Agent 40421
port 31 Agent 40421, Masters Paradise, Skun
port 37 ADM worm
port 39 SubSARI
port 41 Deep Throat , Foreplay
port 44 Arctic
port 51 Fuck Lamers Backdoor
port 52 MuSka52, Skun
port 53 ADM worm, li0n, MscanWorm, MuSka52
port 54 MuSka52
port 66 AL-Bareki
port 69 BackGate Kit, Nimda, Pasana, Storm, Storm worm, Theef
port 69 (UDP) - Pasana
port 70 ADM worm
port 79 ADM worm, Firehotcker
port 80 711 trojan (Seven Eleven), AckCmd, BlueFire, Cafeini, Duddie, Executor, God Message, Intruzzo , Latinus, Lithium, MscanWorm, NerTe, Nimda, Noob, Optix Lite, Optix Pro , Power, Ramen, Remote Shell ,Reverse WWW Tunnel Backdoor, RingZero, RTB 666, Scalper, Screen Cutter , Seeker, Slapper, Web Server CT , WebDownloader
port 80 (UDP) - Penrox
port 81 Asylum
port 101 Skun
port 102 Delf, Skun
port 103 Skun
port 105 NerTe
port 107 Skun
port 109 ADM worm
port 110 ADM worm
port 111 ADM worm, MscanWorm
port 113 ADM worm, Alicia, Cyn, DataSpy Network X, Dosh, Gibbon, Taskman
port 120 Skun
port 121 Attack Bot, God Message, JammerKillah
port 123 Net Controller
port 137 Chode, Nimda
port 137 (UDP) - Bugbear, Msinit, Opaserv, Qaz
port 138 Chode, Nimda
port 139 Chode, Fire HacKer, Msinit, Nimda, Opaserv, Qaz
port 143 ADM worm
port 146 Infector
port 146 (UDP) - Infector
port 166 NokNok
port 170 A-trojan
port 171 A-trojan
port 200 CyberSpy
port 201 One Windows Trojan
port 202 One Windows Trojan, Skun
port 211 One Windows Trojan
port 212 One Windows Trojan
port 221 Snape
port 222 NeuroticKat, Snape
port 230 Skun
port 231 Skun
port 232 Skun
port 285 Delf
port 299 One Windows Trojan
port 334 Backage
port 335 Nautical
port 370 NeuroticKat
port 400 Argentino
port 401 One Windows Trojan
port 402 One Windows Trojan
port 411 Backage
port 420 Breach
port 443 Slapper
port 445 Nimda
port 455 Fatal Connections
port 511 T0rn Rootkit
port 513 ADM worm
port 514 ADM worm
port 515 MscanWorm, Ramen
port 520 (UDP) - A UDP backdoor
port 555 711 trojan (Seven Eleven), Phase Zero, Phase-0
port 564 Oracle
port 589 Assasin
port 600 SweetHeart
port 623 RTB 666
port 635 ADM worm
port 650 Assasin
port 661 NokNok
port 666 Attack FTP, Back Construction, BLA trojan, NokNok, Reverse Trojan, Shadow Phyre, Unicorn, yoyo
port 667 NokNok, SniperNet
port 668 Unicorn
port 669 DP trojan , SniperNet
port 680 RTB 666
port 692 GayOL
port 700 REx
port 777 Undetected
port 798 Oracle
port 808 WinHole
port 831 NeuroticKat
port 901 Net-Devil, Pest
port 902 Net-Devil, Pest
port 903 Net-Devil
port 911 Dark Shadow, Dark Shadow
port 956 Crat Pro
port 991 Snape
port 992 Snape
port 999 Deep Throat , Foreplay
port 1000 Der Späher / Der Spaeher, Direct Connection, GOTHIC Intruder ,Theef
port 1001 Der Späher / Der Spaeher, GOTHIC Intruder , Lula, One Windows Trojan, Theef
port 1005 Pest, Theef
port 1008 AutoSpY, li0n
port 1010 Doly Trojan
port 1011 Doly Trojan, Augudor
port 1012 Doly Trojan, Backdoor.Ura
port 1015 Doly Trojan
port 1016 Doly Trojan
port 1020 Vampire
port 1024 Latinus, Lithium, NetSpy, Ptakks
port 1025 AcidkoR, BDDT, DataSpy Network X, Fraggle Rock , KiLo, MuSka52, NetSpy, Optix Pro , Paltalk, Ptakks, Real 2000, Remote Anything, Remote Explorer Y2K, Remote Storm, RemoteNC
port 1025 (UDP) - KiLo, Optix Pro , Ptakks, Real 2000, Remote Anything, Remote Explorer Y2K, Remote Storm, Yajing
port 1026 BDDT, Dark IRC, DataSpy Network X, Delta Remote Access , Dosh, Duddie, IRC Contact, Remote Explorer 2000, RUX The TIc.K
port 1026 (UDP) - Remote Explorer 2000
port 1027 Clandestine, DataSpy Network X, KiLo, UandMe
port 1028 DataSpy Network X, Dosh, Gibbon, KiLo, KWM, Litmus, Paltalk, SubSARI
port 1028 (UDP) - KiLo, SubSARI
port 1029 Clandestine, KWM, Litmus, SubSARI
port 1029 (UDP) - SubSARI
port 1030 Gibbon, KWM
port 1031 KWM, Little Witch, Xanadu, Xot
port 1031 (UDP) - Xot
port 1032 Akosch4, Dosh, KWM
port 1032 (UDP) - Akosch4
port 1033 Dosh, KWM, Little Witch, Net Advance
port 1034 KWM
port 1035 Dosh, KWM, RemoteNC, Truva Atl
port 1036 KWM
port 1037 Arctic , Dosh, KWM, MoSucker
port 1039 Dosh
port 1041 Dosh, RemoteNC
port 1042 BLA trojan
port 1042 (UDP) - BLA trojan
port 1043 Dosh
port 1044 Ptakks
port 1044 (UDP) - Ptakks
port 1047 RemoteNC
port 1049 Delf, The Hobbit Daemon
port 1052 Fire HacKer, Slapper, The Hobbit Daemon
port 1053 The Thief
port 1054 AckCmd, RemoteNC
port 1080 SubSeven 2.2, WinHole, MyDoom
port 1081 WinHole
port 1082 WinHole
port 1083 WinHole
port 1092 Hvl RAT
port 1095 Blood Fest Evolution, Hvl RAT, Remote Administration Tool - RAT
port 1097 Blood Fest Evolution, Hvl RAT, Remote Administration Tool - RAT
port 1098 Blood Fest Evolution, Hvl RAT, Remote Administration Tool - RAT
port 1099 Blood Fest Evolution, Hvl RAT, Remote Administration Tool - RAT
port 1104 (UDP) - RexxRave
port 1111 Daodan, Ultors Trojan
port 1111 (UDP) - Daodan
port 1115 Lurker, Protoss
port 1116 Lurker
port 1116 (UDP) - Lurker
port 1122 Last 2000, Singularity
port 1122 (UDP) - Last 2000, Singularity
port 1133 SweetHeart
port 1150 Orion
port 1151 Orion
port 1160 BlackRat
port 1166 CrazzyNet
port 1167 CrazzyNet
port 1170 Psyber Stream Server , Voice
port 1180 Unin68
port 1183 Cyn, SweetHeart
port 1183 (UDP) - Cyn, SweetHeart
port 1200 (UDP) - NoBackO
port 1201 (UDP) - NoBackO
port 1207 SoftWAR
port 1208 Infector
port 1212 Kaos
port 1215 Force
port 1218 Force
port 1219 Force
port 1221 Fuck Lamers Backdoor
port 1222 Fuck Lamers Backdoor
port 1234 KiLo, Ultors Trojan
port 1243 BackDoor-G, SubSeven , Tiles
port 1245 VooDoo Doll
port 1255 Scarab
port 1256 Project nEXT, RexxRave
port 1272 The Matrix
port 1313 NETrojan
port 1314 Daodan
port 1349 BO dll
port 1369 SubSeven 2.2
port 1386 Dagger
port 1415 Last 2000, Singularity
port 1433 Voyager Alpha Force
port 1441 Remote Storm
port 1492 FTP99CMP
port 1524 Trinoo
port 1560 Big Gluck, Duddie
port 1561 (UDP) - MuSka52
port 1600 Direct Connection
port 1601 Direct Connection
port 1602 Direct Connection
port 1703 Exploiter
port 1711 yoyo
port 1772 NetControle
port 1772 (UDP) - NetControle
port 1777 Scarab
port 1826 Glacier
port 1833 TCC
port 1834 TCC
port 1835 TCC
port 1836 TCC
port 1837 TCC
port 1905 Delta Remote Access
port 1911 Arctic
port 1966 Fake FTP
port 1967 For Your Eyes Only , WM FTP Server
port 1978 (UDP) - Slapper
port 1981 Bowl, Shockrave
port 1983 Q-taz
port 1984 Intruzzo , Q-taz
port 1985 Black Diver, Q-taz
port 1985 (UDP) - Black Diver
port 1986 Akosch4
port 1991 PitFall
port 1999 Back Door, SubSeven , TransScout
port 2000 A-trojan, Der Späher / Der Spaeher, Fear, Force, GOTHIC Intruder , Last 2000, Real 2000, Remote Explorer 2000, Remote Explorer Y2K, Senna Spy Trojan Generator, Singularity
port 2000 (UDP) - GOTHIC Intruder , Real 2000, Remote Explorer 2000, Remote Explorer Y2K
port 2001 Der Späher / Der Spaeher, Duddie, Glacier, Protoss, Senna Spy Trojan Generator, Singularity, Trojan Cow
port 2001 (UDP) - Scalper
port 2002 Duddie, Senna Spy Trojan Generator, Sensive
port 2002 (UDP) - Slapper
port 2004 Duddie
port 2005 Duddie
port 2023 Ripper Pro
port 2060 Protoss
port 2080 WinHole
port 2101 SweetHeart
port 2115 Bugs
port 2130 (UDP) - Mini BackLash
port 2140 The Invasor
port 2140 (UDP) - Deep Throat , Foreplay , The Invasor
port 2149 Deep Throat
port 2150 R0xr4t
port 2156 Oracle
port 2222 SweetHeart, Way
port 2222 (UDP) - SweetHeart, Way
port 2281 Nautical
port 2283 Hvl RAT
port 2300 Storm
port 2311 Studio 54
port 2330 IRC Contact
port 2331 IRC Contact
port 2332 IRC Contact, Silent Spy
port 2333 IRC Contact
port 2334 IRC Contact, Power
port 2335 IRC Contact
port 2336 IRC Contact
port 2337 IRC Contact, The Hobbit Daemon
port 2338 IRC Contact
port 2339 IRC Contact, Voice Spy
port 2339 (UDP) - Voice Spy
port 2343 Asylum
port 2345 Doly Trojan
port 2407 yoyo
port 2418 Intruzzo
port 2555 li0n, T0rn Rootkit
port 2565 Striker trojan
port 2583 WinCrash
port 2589 Dagger
port 2600 Digital RootBeer
port 2702 Black Diver
port 2702 (UDP) - Black Diver
port 2772 SubSeven
port 2773 SubSeven , SubSeven 2.1 Gold
port 2774 SubSeven , SubSeven 2.1 Gold
port 2800 Theef
port 2929 Konik
port 2983 Breach
port 2989 (UDP) - Remote Administration Tool - RAT
port 3000 InetSpy, Remote Shut, Theef
port 3006 Clandestine
port 3024 WinCrash
port 3031 MicroSpy
port 3119 Delta Remote Access
port 3128 MyDoom, RingZero, Reverse Tunnel
port 3129 Masters Paradise
port 3131 SubSARI
port 3150 Deep Throat , The Invasor, The Invasor
port 3150 (UDP) - Deep Throat , Foreplay , Mini BackLash
port 3215 XHX
port 3215 (UDP) - XHX
port 3292 Xposure
port 3295 Xposure
port 3333 Daodan
port 3333 (UDP) - Daodan
port 3410 Optix Pro
port 3417 Xposure
port 3418 Xposure
port 3456 Fear, Force, Terror trojan
port 3459 Eclipse 2000, Sanctuary
port 3505 AutoSpY
port 3700 Portal of Doom
port 3721 Whirlpool
port 3723 Mantis
port 3777 PsychWard
port 3791 Total Solar Eclypse
port 3800 Total Solar Eclypse
port 3801 Total Solar Eclypse
port 3945 Delta Remote Access
port 3996 Remote Anything
port 3996 (UDP) - Remote Anything
port 3997 Remote Anything
port 3999 Remote Anything
port 4000 Remote Anything, SkyDance
port 4092 WinCrash
port 4128 RedShad
port 4128 (UDP) - RedShad
port 4156 (UDP) - Slapper
port 4201 War trojan
port 4210 Netkey
port 4211 Netkey
port 4225 Silent Spy
port 4242 Virtual Hacking Machine - VHM
port 4315 Power
port 4321 BoBo
port 4414 AL-Bareki
port 4442 Oracle
port 4444 CrackDown, Oracle, Prosiak, Swift Remote
port 4445 Oracle
port 4447 Oracle
port 4449 Oracle
port 4451 Oracle
port 4488 Event Horizon
port 4567 File Nail
port 4653 Cero
port 4666 Mneah
port 4700 Theef
port 4836 Power
port 5000 Back Door Setup, Bubbel, Ra1d, Sockets des Troie
port 5001 Back Door Setup, Sockets des Troie
port 5002 Shaft
port 5005 Aladino
port 5011 Peanut Brittle
port 5025 WM Remote KeyLogger
port 5031 Net Metropolitan
port 5032 Net Metropolitan
port 5050 R0xr4t
port 5135 Bmail
port 5150 Pizza
port 5151 Optix Lite
port 5152 Laphex
port 5155 Oracle
port 5221 NOSecure
port 5250 Pizza
port 5321 Firehotcker
port 5333 Backage
port 5350 Pizza
port 5377 Iani
port 5400 Back Construction, Blade Runner, Digital Spy
port 5401 Back Construction, Blade Runner, Digital Spy , Mneah
port 5402 Back Construction, Blade Runner, Digital Spy , Mneah
port 5418 DarkSky
port 5419 DarkSky
port 5419 (UDP) - DarkSky
port 5430 Net Advance
port 5450 Pizza
port 5503 Remote Shell
port 5534 The Flu
port 5550 Pizza
port 5555 Daodan, NoXcape
port 5555 (UDP) - Daodan
port 5556 BO Facil
port 5557 BO Facil
port 5569 Robo-Hack
port 5650 Pizza
port 5669 SpArTa
port 5679 Nautical
port 5695 Assasin
port 5696 Assasin
port 5697 Assasin
port 5742 WinCrash
port 5802 Y3K RAT
port 5873 SubSeven 2.2
port 5880 Y3K RAT
port 5882 Y3K RAT
port 5882 (UDP) - Y3K RAT
port 5888 Y3K RAT
port 5888 (UDP) - Y3K RAT
port 5889 Y3K RAT
port 5933 NOSecure
port 6000 Aladino, NetBus , The Thing
port 6006 Bad Blood
port 6267 DarkSky
port 6400 The Thing
port 6521 Oracle
port 6526 Glacier
port 6556 AutoSpY
port 6661 Weia-Meia
port 6666 AL-Bareki, KiLo, SpArTa
port 6666 (UDP) - KiLo
port 6667 Acropolis, BlackRat, Dark FTP, Dark IRC, DataSpy Network X, Gunsan, InCommand, Kaitex, KiLo, Laocoon, Net-Devil, Reverse Trojan, ScheduleAgent, SlackBot, SubSeven , Subseven 2.1.4 DefCon 8, Trinity, Y3K RAT, yoyo
port 6667 (UDP) - KiLo
port 6669 Host Control, Vampire, Voyager Alpha Force
port 6670 BackWeb Server, Deep Throat , Foreplay , WinNuke eXtreame
port 6697 Force
port 6711 BackDoor-G, Duddie, KiLo, Little Witch, Netkey, Spadeace, SubSARI, SubSeven , SweetHeart, UandMe, Way, VP Killer
port 6712 Funny trojan, KiLo, Spadeace, SubSeven
port 6713 KiLo, SubSeven
port 6714 KiLo
port 6715 KiLo
port 6718 KiLo
port 6723 Mstream
port 6766 KiLo
port 6766 (UDP) - KiLo
port 6767 KiLo, Pasana, UandMe
port 6767 (UDP) - KiLo, UandMe
port 6771 Deep Throat , Foreplay
port 6776 2000 Cracks, BackDoor-G, SubSeven , VP Killer
port 6838 (UDP) - Mstream
port 6891 Force
port 6912 Shit Heep
port 6969 2000 Cracks, BlitzNet, Dark IRC, GateCrasher, Kid Terror, Laphex, Net Controller, SpArTa, Vagr Nocker
port 6970 GateCrasher
port 7000 Aladino, Gunsan, Remote Grab, SubSeven , SubSeven 2.1 Gold, Theef
port 7001 Freak88, Freak2k
port 7007 Silent Spy
port 7020 Basic Hell
port 7030 Basic Hell
port 7119 Massaker
port 7215 SubSeven , SubSeven 2.1 Gold
port 7274 AutoSpY
port 7290 NOSecure
port 7291 NOSecure
port 7300 NetSpy
port 7301 NetSpy
port 7306 NetSpy
port 7307 NetSpy, Remote Process Monitor
port 7308 NetSpy, X Spy
port 7312 Yajing
port 7410 Phoenix II
port 7424 Host Control
port 7424 (UDP) - Host Control
port 7597 Qaz
port 7626 Glacier
port 7648 XHX
port 7673 Neoturk
port 7676 Neoturk
port 7677 Neoturk
port 7718 Glacier
port 7722 KiLo
port 7777 God Message
port 7788 Last 2000, Last 2000, Singularity
port 7788 (UDP) - Singularity
port 7789 Back Door Setup
port 7800 Paltalk
port 7826 Oblivion
port 7850 Paltalk
port 7878 Paltalk
port 7879 Paltalk
port 7979 Vagr Nocker
port 7983 (UDP) - Mstream
port 8011 Way
port 8012 Ptakks
port 8012 (UDP) - Ptakks
port 8080 Reverse WWW Tunnel Backdoor , RingZero, Screen Cutter
port 8090 Aphex's Remote Packet Sniffer
port 8090 (UDP) - Aphex's Remote Packet Sniffer
port 8097 Kryptonic Ghost Command Pro
port 8100 Back streets
port 8110 DLP
port 8111 DLP
port 8127 9_119, Chonker
port 8127 (UDP) - 9_119, Chonker
port 8130 9_119, Chonker, DLP
port 8131 DLP
port 8301 DLP
port 8302 DLP
port 8311 SweetHeart
port 8322 DLP
port 8329 DLP
port 8488 (UDP) - KiLo
port 8489 KiLo
port 8489 (UDP) - KiLo
port 8685 Unin68
port 8732 Kryptonic Ghost Command Pro
port 8734 AutoSpY
port 8787 Back Orifice 2000
port 8811 Fear
port 8812 FraggleRock Lite
port 8821 Alicia
port 8848 Whirlpool
port 8864 Whirlpool
port 8888 Dark IRC
port 9000 Netministrator
port 9090 Aphex's Remote Packet Sniffer
port 9117 Massaker
port 9148 Nautical
port 9301 DLP
port 9325 (UDP) - Mstream
port 9329 DLP
port 9400 InCommand
port 9401 InCommand
port 9536 Lula
port 9561 Crat Pro
port 9563 Crat Pro
port 9870 Remote Computer Control Center
port 9872 Portal of Doom
port 9873 Portal of Doom
port 9874 Portal of Doom
port 9875 Portal of Doom
port 9876 Rux
port 9877 Small Big Brother
port 9878 Small Big Brother, TransScout
port 9879 Small Big Brother
port 9919 Kryptonic Ghost Command Pro
port 9999 BlitzNet, Oracle, Spadeace
port 10000 Oracle, TCP Door, XHX
port 10000 (UDP) - XHX
port 10001 DTr, Lula
port 10002 Lula
port 10003 Lula
port 10008 li0n
port 10012 Amanda
port 10013 Amanda
port 10067 Portal of Doom
port 10067 (UDP) - Portal of Doom
port 10084 Syphillis
port 10084 (UDP) - Syphillis
port 10085 Syphillis
port 10086 Syphillis
port 10100 Control Total, GiFt trojan, Scalper
port 10100 (UDP) - Slapper
port 10167 Portal of Doom
port 10167 (UDP) - Portal of Doom
port 10498 (UDP) - Mstream
port 10520 Acid Shivers
port 10528 Host Control
port 10607 Coma
port 10666 (UDP) - Ambush
port 10887 BDDT
port 10889 BDDT
port 11000 DataRape, Senna Spy Trojan Generator
port 11011 Amanda
port 11050 Host Control
port 11051 Host Control
port 11111 Breach
port 11223 Progenic trojan, Secret Agent
port 11225 Cyn
port 11225 (UDP) - Cyn
port 11660 Back streets
port 11718 Kryptonic Ghost Command Pro
port 11831 DarkFace, DataRape, Latinus, Pest, Vagr Nocker
port 11977 Cool Remote Control
port 11978 Cool Remote Control
port 11980 Cool Remote Control
port 12000 Reverse Trojan
port 12310 PreCursor
port 12321 Protoss
port 12321 (UDP) - Protoss
port 12345 Ashley, BlueIce 2000, Mypic , NetBus , Pie Bill Gates, Q-taz, Sensive, Snape, Vagr Nocker, ValvNet , Whack Job
port 12345 (UDP) - BlueIce 2000
port 12346 NetBus
port 12348 BioNet
port 12349 BioNet, The Saint
port 12361 Whack-a-mole
port 12362 Whack-a-mole
port 12363 Whack-a-mole
port 12623 ButtMan
port 12623 (UDP) - ButtMan, DUN Control
port 12624 ButtMan, Power
port 12631 Whack Job
port 12684 Power
port 12754 Mstream
port 12904 Rocks
port 13000 Senna Spy Trojan Generator, Senna Spy Trojan Generator
port 13013 PsychWard
port 13014 PsychWard
port 13028 Back streets
port 13079 Kryptonic Ghost Command Pro
port 13370 SpArTa
port 13371 Optix Pro
port 13500 Theef
port 13753 Anal FTP
port 14194 CyberSpy
port 14285 Laocoon
port 14286 Laocoon
port 14287 Laocoon
port 14500 PC Invader
port 14501 PC Invader
port 14502 PC Invader
port 14503 PC Invader
port 15000 In Route to the Hell, R0xr4t
port 15092 Host Control
port 15104 Mstream
port 15206 KiLo
port 15207 KiLo
port 15210 (UDP) - UDP remote shell backdoor server
port 15382 SubZero
port 15432 Cyn
port 15485 KiLo
port 15486 KiLo
port 15486 (UDP) - KiLo
port 15500 In Route to the Hell
port 15512 Iani
port 15551 In Route to the Hell
port 15695 Kryptonic Ghost Command Pro
port 15845 (UDP) - KiLo
port 15852 Kryptonic Ghost Command Pro
port 16057 MoonPie
port 16484 MoSucker
port 16514 KiLo
port 16514 (UDP) - KiLo
port 16515 KiLo
port 16515 (UDP) - KiLo
port 16523 Back streets
port 16660 Stacheldraht
port 16712 KiLo
port 16761 Kryptonic Ghost Command Pro
port 16959 SubSeven , Subseven 2.1.4 DefCon 8
port 17166 Mosaic
port 17449 Kid Terror
port 17499 CrazzyNet
port 17500 CrazzyNet
port 17569 Infector
port 17593 AudioDoor
port 17777 Nephron
port 18753 (UDP) - Shaft
port 19191 BlueFire
port 19216 BackGate Kit
port 20000 Millenium, PSYcho Files, XHX
port 20001 Insect, Millenium, PSYcho Files
port 20002 AcidkoR, PSYcho Files
port 20005 MoSucker
port 20023 VP Killer
port 20034 NetBus 2.0 Pro, NetBus 2.0 Pro Hidden, Whack Job
port 20331 BLA trojan
port 20432 Shaft
port 20433 (UDP) - Shaft
port 21212 Sensive
port 21544 GirlFriend, Kid Terror
port 21554 Exploiter, FreddyK, Kid Terror, Schwindler, Sensive, Winsp00fer
port 21579 Breach
port 21957 Latinus
port 22115 Cyn
port 22222 Donald Dick, G.R.O.B., Prosiak, Ruler, RUX The TIc.K
port 22223 RUX The TIc.K
port 22456 Clandestine
port 22554 Schwindler
port 22783 Intruzzo
port 22784 Intruzzo
port 22785 Intruzzo
port 23000 Storm worm
port 23001 Storm worm
port 23005 NetTrash, Oxon
port 23006 NetTrash, Oxon
port 23023 Logged
port 23032 Amanda
port 23321 Konik
port 23432 Asylum
port 23456 Clandestine, Evil FTP, Vagr Nocker, Whack Job
port 23476 Donald Dick
port 23476 (UDP) - Donald Dick
port 23477 Donald Dick
port 23777 InetSpy
port 24000 Infector
port 24289 Latinus
port 25002 MOTD
port 25002 (UDP) - MOTD
port 25123 Goy'Z TroJan
port 25555 FreddyK
port 25685 MoonPie
port 25686 DarkFace, MoonPie
port 25799 FreddyK
port 25885 MOTD
port 25982 DarkFace, MoonPie
port 26274 (UDP) - Delta Source
port 26681 Voice Spy
port 27160 MoonPie
port 27184 Alvgus trojan 2000
port 27184 (UDP) - Alvgus trojan 2000
port 27373 Charge
port 27374 Bad Blood, Fake SubSeven, li0n, Ramen, Seeker, SubSeven, SubSeven 2.1 Gold, Subseven 2.1.4 DefCon 8, SubSeven 2.2, SubSeven Muie, The Saint
port 27379 Optix Lite
port 27444 (UDP) - Trinoo
port 27573 SubSeven
port 27665 Trinoo
port 28218 Oracle
port 28431 Hack´a´Tack
port 28678 Exploiter
port 29104 NETrojan, NetTrojan
port 29292 BackGate Kit
port 29559 AntiLamer BackDoor , DarkFace, DataRape, Ducktoy, Latinus, Pest, Vagr Nocker
port 29589 KiLo
port 29589 (UDP) - KiLo
port 29891 The Unexplained
port 29999 AntiLamer BackDoor
port 30000 DataRape, Infector
port 30001 Err0r32
port 30005 Litmus
port 30100 NetSphere
port 30101 NetSphere
port 30102 NetSphere
port 30103 NetSphere
port 30103 (UDP) - NetSphere
port 30133 NetSphere
port 30303 Sockets des Troie
port 30331 MuSka52
port 30464 Slapper
port 30700 Mantis
port 30947 Intruse
port 31320 Little Witch
port 31320 (UDP) - Little Witch
port 31335 Trinoo
port 31336 Butt Funnel
port 31337 ADM worm, Back Fire, Back Orifice (Lm), Back Orifice russian, BlitzNet, BO client, BO Facil, BO2, Freak88, Freak2k, NoBackO
port 31337 (UDP) - Back Orifice, Deep BO
port 31338 Back Orifice, Butt Funnel, NetSpy (DK)
port 31338 (UDP) - Deep BO, NetSpy (DK)
port 31339 Little Witch, NetSpy (DK), NetSpy (DK)
port 31339 (UDP) - Little Witch
port 31340 Little Witch
port 31340 (UDP) - Little Witch
port 31382 Lithium
port 31415 Lithium
port 31416 Lithium
port 31416 (UDP) - Lithium
port 31557 Xanadu
port 31745 BuschTrommel
port 31785 Hack´a´Tack
port 31787 Hack´a´Tack
port 31788 Hack´a´Tack
port 31789 Hack´a´Tack
port 31789 (UDP) - Hack´a´Tack
port 31790 Hack´a´Tack
port 31791 Hack´a´Tack
port 31791 (UDP) - Hack´a´Tack
port 31792 Hack´a´Tack
port 31887 BDDT
port 32000 BDDT
port 32001 Donald Dick
port 32100 Peanut Brittle, Project nEXT
port 32418 Acid Battery
port 32791 Acropolis, Rocks
port 33270 Trinity
port 33333 Prosiak
port 33545 G.R.O.B.
port 33567 li0n, T0rn Rootkit
port 33568 li0n, T0rn Rootkit
port 33577 Son of PsychWard
port 33777 Son of PsychWard
port 33911 Spirit 2000, Spirit 2001
port 34312 Delf
port 34313 Delf
port 34324 Big Gluck
port 34343 Osiris
port 34444 Donald Dick
port 34555 (UDP) - Trinoo (for Windows)
port 35000 Infector
port 35555 (UDP) - Trinoo (for Windows)
port 35600 SubSARI
port 36794 Bugbear
port 37237 Mantis
port 37651 Charge
port 38741 CyberSpy
port 38742 CyberSpy
port 40071 Ducktoy
port 40308 SubSARI
port 40412 The Spy
port 40421 Agent 40421, Masters Paradise
port 40422 Masters Paradise
port 40423 Masters Paradise
port 40425 Masters Paradise
port 40426 Masters Paradise
port 41337 Storm
port 41666 Remote Boot Tool , Remote Boot Tool
port 43720 (UDP) - KiLo
port 44014 Iani
port 44014 (UDP) - Iani
port 44444 Prosiak
port 44575 Exploiter
port 44767 School Bus
port 44767 (UDP) - School Bus
port 45092 BackGate Kit
port 45454 Osiris
port 45632 Little Witch
port 45673 Acropolis, Rocks
port 46666 Taskman
port 46666 (UDP) - Taskman
port 47017 T0rn Rootkit
port 47262 (UDP) - Delta Source
port 47698 KiLo
port 47785 KiLo
port 47785 (UDP) - KiLo
port 47891 AntiLamer BackDoor
port 48004 Fraggle Rock
port 48006 Fraggle Rock
port 48512 Arctic
port 49000 Fraggle Rock
port 49683 Fenster
port 49683 (UDP) - Fenster
port 49698 (UDP) - KiLo
port 50000 SubSARI
port 50021 Optix Pro
port 50130 Enterprise
port 50505 Sockets des Troie
port 50551 R0xr4t
port 50552 R0xr4t
port 50766 Schwindler
port 50829 KiLo
port 50829 (UDP) - KiLo
port 51234 Cyn
port 51966 Cafeini
port 52365 Way
port 52901 (UDP) - Omega
port 53001 Remote Windows Shutdown - RWS
port 54283 SubSeven , SubSeven 2.1 Gold
port 54320 Back Orifice 2000
port 54321 Back Orifice 2000, School Bus , yoyo
port 55165 File Manager trojan, File Manager trojan
port 55555 Shadow Phyre
port 55665 Latinus, Pinochet
port 55666 Latinus, Pinochet
port 56565 Osiris
port 57163 BlackRat
port 57341 NetRaider
port 57785 G.R.O.B.
port 58134 Charge
port 58339 Butt Funnel
port 59211 Ducktoy
port 60000 Deep Throat , Foreplay , Sockets des Troie
port 60001 Trinity
port 60008 li0n, T0rn Rootkit
port 60068 The Thing
port 60411 Connection
port 60551 R0xr4t
port 60552 R0xr4t
port 60666 Basic Hell
port 61115 Protoss
port 61337 Nota
port 61348 Bunker-Hill
port 61440 Orion
port 61603 Bunker-Hill
port 61746 KiLo
port 61746 (UDP) - KiLo
port 61747 KiLo
port 61747 (UDP) - KiLo
port 61748 (UDP) - KiLo
port 61979 Cool Remote Control
port 62011 Ducktoy
port 63485 Bunker-Hill
port 64101 Taskman
port 65000 Devil, Sockets des Troie, Stacheldraht
port 65289 yoyo
port 65421 Alicia
port 65422 Alicia
port 65432 The Traitor (= th3tr41t0r)
port 65432 (UDP) - The Traitor (= th3tr41t0r)
port 65530 Windows Mite
port 65535 RC1 trojan
|.
# add Sobig f varients from http://www.lurhq.com/Sobig-f.html
q
|port 2555 Sobig.f RTSP Streaming Media Proxy
port 3001 Sobig.f Remote Control Service
port 3380 Sobig.f SOCKS Proxy server
port 3381 Sobig.f Telnet Proxy server
port 3382 Sobig.f WWW Proxy server
port 3383 Sobig.f FTP Proxy server
port 3384 Sobig.f POP3 Proxy server
port 3385 Sobig.f SMTP Server
|);

foreach(@_) {
  $_ =~ /port\s+(\d+)\s+(.+)/;
  my $port = $1;
  my $trjs = $2;
  next if $trjs =~ /\(UDP\)/;
  my @trjs = split(",",$trjs);

  $trojans->{$port} = &$builder($port,@trjs);
}


# http://www.bekkoame.ne.jp/~s_ita/port/port1-99.html
# another very comprehensive list
#
$_ = q|
0	tcp/udp	#	Reserved
1	tcp/udp	tcpmux	TCP Port Service Multiplexer
1 	udp 	# 	Sockets des Troie
2	tcp/udp	compressnet	Management Utility
2 	tcp 	# 	Death
3	tcp/udp	compressnet	Compression Process
3 	tcp/udp 	compressnet 	Midnight Commander
Sometimes this program is assigned to this port
4	tcp/udp	#	Unassigned
4 	tcp 	# 	Self-Certifying File System(SFS)
sfssd acceps connections on TCP port 4 and
passes them to the appropriate SFS daemon.
SFS is a secure, global file system with
completely decentralized control. SFS uses
NFS 3 as the underlying protocol for file access.
4 	tcp 	# 	Midnight Commander
Sometimes this program is assigned to this prot
5	tcp/udp	rje	Remote Job Entry
6	tcp/udp	#	Unassigned
7	tcp/udp	echo	Echo
8	tcp/udp	#	Unassigned
9	tcp/udp	discard	Discard
10	tcp/udp	#	Unassigned
11	tcp/udp	systat	Active Users
12	tcp/udp	#	Unassigned
13	tcp/udp	daytime	Daytime (RFC 867)
14	tcp/udp	#	Unassigned
15	tcp	#	Unassigned [was netstat]
15	tcp/udp	#	Unassigned
17	tcp/udp	qotd	Quote of the Day
18	tcp/udp	msp	Message Send Protocol
19	tcp/udp	chargen	Character Generator
20	tcp/udp	ftp-data	File Transfer [Default Data]
20 	tcp 	# 	Randex
21	tcp/udp	ftp	File Transfer [Control]
21 	tcp 	# 	Senna Spy FTP server
21 	tcp 	# 	Back Construction, Blade Runner,
Cattivik FTP Server, CC Invader, Dark FTP,
Doly Trojan, Fore, Invisible FTP,
Juggernaut 42, Larva, MotIv FTP,
Net Administrator, Ramen,
Senna Spy FTP server, The Flu, Traitor 21,
WebEx, WinCrash
22	tcp/udp	ssh	SSH Remote Login Protocol
22 	tcp 	# 	Shaft
22 	udp 	# 	pcAnywhere(Used in older versions,
though newer version still use it for
backwards compatibility.)
23	tcp/udp	telnet	Telnet
23 	tc 	# 	Fire HacKer, Tiny Telnet Server - TTS,
Truva Atl, MindControl
24	tcp/udp	#	any private mail system
25	tcp/udp	smtp	Simple Mail Transfer
25 	tcp 	# 	Ajan, Antigen, Barok,
Email Password Sender - EPS, EPS II, Gip,
Gris, Happy99, Hpteam mail, Hybris, I love you,
Kuang2, Magic Horse, MBT (Mail Bombing Trojan),
Moscow Email trojan, Naebi, NewApt worm,
ProMail trojan, Shtirlitz, Stealth, Tapiras,
Terminator, WinPC, WinSpy
26	tcp/udp	#	Unassigned
26 	tcp 	# 	W32.Netsky
27	tcp/udp	nsw-fe	NSW User System FE
28	tcp/udp	#	Unassigned
29	tcp/udp	msg-icp	MSG ICP
30	tcp/udp	#	Unassigned
30 	tcp 	# 	Agent 40421
31	tcp/udp	msg-auth	MSG Authentication
31 	tcp 	# 	Agent 31, Hackers Paradise, Masters Paradise
32	tcp/udp	#	Unassigned
33	tcp/udp	dsp	Display Support Protocol
34	tcp/udp	#	Unassigned
35	tcp/udp	#	any private printer server
36	tcp/udp	#	Unassigned
37	tcp/udp	time	Time
37 	tcp/udp 	# 	W32.Sober, Dimi
38	tcp/udp	rap	Route Access Protocol
39	tcp/udp	rlp	Resource Location Protocol
39 	tcp/udp 	# 	Upfudoor
40	tcp/udp	#	Unassigned
40 	tcp 	# 	Midnight Commander
Sometimes access FTP servers running at this port.
41	tcp/udp	graphics	Graphics
41 	tcp 	# 	RAT: Deep Throat
Puts an FTP service at port 41 (TCP).
Foreplay
42	tcp/udp	name	Host Name Server
42	tcp/udp	nameserver	Host Name Server
43	tcp/udp	nicname	Who Is
44	tcp/udp	mpm-flags	MPM FLAGS Protocol
45	tcp/udp	mpm	Message Processing Module [recv]
46	tcp/udp	mpm-snd	MPM [default send]
47	tcp/udp	ni-ftp	NI FTP
48	tcp/udp	auditd	Digital Audit Daemon
48 	tcp 	# 	DRAT
49	tcp/udp	tacacs	Login Host Protocol (TACACS)
50	tcp/udp	re-mail-ck	Remote Mail Checking Protocol
48 	tcp 	# 	DRAT
51	tcp/udp	la-maint	IMP Logical Address Maintenance
52	tcp/udp	xns-time	XNS Time Protocol
53	tcp/udp	domain	Domain Name Server
54	tcp/udp	xns-ch	XNS Clearinghouse
55	tcp/udp	isi-gl	ISI Graphics Language
56	tcp/udp	xns-auth	XNS Authentication
57	tcp/udp	#	any private terminal access
58	tcp/udp	xns-mail	XNS Mail
58-59 	tcp 	# 	DMSetup
59	tcp/udp	#	any private file service
59 	tcp 	# 	Sdbot
60	tcp/udp	#	Unassigned
61	tcp/udp	ni-mail	NI MAIL
62	tcp/udp	acas	ACA Services
63	tcp/udp	whois++	whois++
64	tcp/udp	covia	Communications Integrator (CI)
65	tcp/udp	tacacs-ds	TACACS-Database Service
66	tcp/udp	sql*net	Oracle SQL*NET
67	tcp/udp	bootps	Bootstrap Protocol Server
68	tcp/udp	bootpc	Bootstrap Protocol Client
69	tcp/udp	tftp	Trivial File Transfer
69 	tcp 	# 	W32.Evala.Worm, W32.Mockbot
69 	udp 	# 	W32.Blaster.Worm, W32.Bolgi.Worm, W32.Cycle
70	tcp/udp	gopher	Gopher
70 	tcp 	# 	W32.Evala.Worm
71	tcp/udp	netrjs-1	Remote Job Service
72	tcp/udp	netrjs-2	Remote Job Service
73	tcp/udp	netrjs-3	Remote Job Service
74	tcp/udp	netrjs-4	Remote Job Service
75	tcp/udp	#	any private dial out service
76	tcp/udp	deos	Distributed External Object Store
77	tcp/udp	#	any private RJE service
78	tcp/udp	vettcp	vettcp
79	tcp/udp	finger	Finger
79 	tcp 	# 	RAT:Firehotcker
Requires VB
CDK
80	tcp/udp	http	World Wide Web HTTP
80	tcp/udp	www	World Wide Web HTTP
80	tcp/udp	www-http	World Wide Web HTTP
80 	tcp 	# 	711 trojan (Seven Eleven), AckCmd, Back End,
Back Orifice 2k Plug-Ins, Cafeini, CGI Backdoor,
Executor, God Message, God Message Creator,
Hooker, IISworm, MTX, NCX,
Reverse WWW Tunnel Backdoor, RingZero,
Seeker, WAN Remote, Web Server CT,
WebDownloader, Xeory, Zombam, W32.Yaha,
Ketch, Mydoom, W32.Welchia,
W32.HLLW.Doomjuice, W32.HLLW.Heycheck,
W32.Gaobot, W32.HLLW.Polybot, W32.Beagle,
W32.Spybot
80 	udp 	# 	W32.Beagle
81	tcp/udp	hosts2-ns	HOSTS2 Name Server
81 	tcp 	# 	RemoConChubo, Xeory, W32.Beagle
81 	udp 	# 	W32.Beagle
82	tcp/udp	xfer	XFER Utility
82 	tcp 	# 	W32.Netsky
83	tcp/udp	mit-ml-dev	MIT ML Device
84	tcp/udp	ctf	Common Trace Facility
85	tcp/udp	mit-ml-dev	MIT ML Device
86	tcp/udp	mfcobol	Micro Focus Cobol
87	tcp/udp	#	any private terminal link
88	tcp/udp	kerberos	Kerberos
88 	tcp 	# 	PWSteal.Likmet
89	tcp/udp	su-mit-tg	SU/MIT Telnet Gateway
90	tcp/udp	dnsix	DNSIX Securit Attribute Token Map
91	tcp/udp	mit-dov	MIT Dover Spooler
92	tcp/udp	npp	Network Printing Protocol
93	tcp/udp	dcp	Device Control Protocol
94	tcp/udp	objcall	Tivoli Object Dispatcher
95	tcp/udp	supdup	SUPDUP
96	tcp/udp	dixie	DIXIE Protocol Specification
97	tcp/udp	swift-rvf	Swift Remote Virtural File Protocol
98	tcp/udp	tacnews	TAC News
99	tcp/udp	metagram	Metagram Relay
99 	tcp 	# 	Hidden Port, NCX
100	tcp	newacct	[unauthorized use]
101	tcp/udp	hostname	NIC Host Name Server
101 	tcp/udp 	# 	Udps
102	tcp/udp	iso-tsap	ISO-TSAP Class 0
103	tcp/udp	gppitnp	Genesis Point-to-Point Trans Net
104	tcp/udp	acr-nema	ACR-NEMA Digital Imag. & Comm. 300
105	tcp/udp	cso	CCSO name server protocol
105	tcp/udp	csnet-ns	Mailbox Name Nameserver
106	tcp/udp	3com-tsmux	3COM-TSMUX
106 	tcp 	poppassd
(epass) 	allows passwords to be changed on POP servers.
Traditionally, users would have to have shell
(Telnet) accounts on the servers in order to
change their passwords. This allows users with
just POP access to change their passwords.
107	tcp/udp	rtelnet	Remote Telnet Service
108	tcp/udp	snagas	SNA Gateway Access Server
109	tcp/udp	pop2	Post Office Protocol - Version 2
110	tcp/udp	pop3	Post Office Protocol - Version 3
110 	tcp 	# 	ProMail trojan
111	tcp/udp	sunrpc	SUN Remote Procedure Call
112	tcp/udp	mcidas	McIDAS Data Transmission Protocol
113	tcp	ident	 
113	tcp/udp	auth	Authentication Service
113 	tcp 	# 	Invisible Identd Deamon, Kazimas, Randex,
W32.Korgo, W32.Spybot, W32.Mydoom,
W32.Linkbot, W32.Bofra
114	tcp/udp	#	Unassigned
115	tcp/udp	sftp	Simple File Transfer Protocol
116	tcp/udp	ansanotify	ANSA REX Notify
116 	udp 	# 	Diablo
117	tcp/udp	uucp-path	UUCP Path Service
118	tcp/udp	sqlserv	SQL Services
118 	udp 	# 	Diablo
119	tcp/udp	nntp	Network News Transfer Protocol
119 	tcp 	# 	Happy99
120	tcp/udp	cfdptkt	CFDPTKT
121	tcp/udp	erpc	Encore Expedited Remote Pro.Call
121 	tcp 	# 	Attack Bot, God Message, JammerKillah
122	tcp/udp	smakynet	SMAKYNET
122 	tcp/udp 	# 	Upfudoor
123	tcp/udp	ntp	Network Time Protocol
123 	tcp 	# 	Net Controller, Madfind
124	tcp/udp	ansatrader	ANSA REX Trader
124	tcp	#	SecureID v1
125	tcp/udp	locus-map	Locus PC-Interface Net Map Ser
126	tcp/udp	nxedit	NXEdit
126	tcp/udp	#unitary	Unisys Unitary Login
127	tcp/udp	locus-con	Locus PC-Interface Conn Server
128	tcp/udp	gss-xlicen	GSS X License Verification
129	tcp/udp	pwdgen	Password Generator Protocol
130	tcp/udp	cisco-fna	cisco FNATIVE
131	tcp/udp	cisco-tna	cisco TNATIVE
132	tcp/udp	cisco-sys	cisco SYSMAINT
133	tcp/udp	statsrv	Statistics Service
133 	tcp 	# 	Farnaz
134	tcp/udp	ingres-net	INGRES-NET Service
135	tcp/udp	epmap	DCE endpoint resolution
135 	tcp/udp 	# 	Femot, W32.Blaster.Worm,W32.HLLW.Gaobot,
W32.Yaha, W32.Francette.Worm,W32.Cissi,
W32.Welchia, W32.HLLW.Polybot,
W32.Kibuv.Worm, W32.Explet, W32.Lovgate,
W32.Spybot, W32.Maslan
136	tcp/udp	profile	PROFILE Naming System
137	tcp/udp	netbios-ns	NETBIOS Name Service
137-139 	tcp 	# 	Chode
137 	udp 	# 	Msinit, Femot
138	tcp/udp	netbios-dgm	NETBIOS Datagram Service
139	tcp/udp	netbios-ssn	NETBIOS Session Service
139 	tcp 	# 	God Message worm, Msinit, Netlog,
Network, Qaz, W32.HLLW.Deborms,
W32.HLLW.Moega, W32.Yaha,W32.Cissi
140	tcp/udp	emfis-data	EMFIS Data Service
141	tcp/udp	emfis-cntl	EMFIS Control Service
142	tcp/udp	bl-idm	Britton-Lee IDM
142 	tcp 	# 	NetTaxi
143	tcp/udp	imap	Internet Message Access Protocol
144	tcp/udp	uma	Universal Management Architecture
145	tcp/udp	uaac	UAAC Protocol
145 	tcp 	# 	W32.Spybot
146	tcp/udp	iso-tp0	ISO-IP0
146 	tcp/udp 	# 	Infector
147	tcp/udp	iso-ip	ISO-IP
148	tcp/udp	jargon	Jargon
149	tcp/udp	aed-512	AED 512 Emulation Service
150	tcp/udp	sql-net	SQL-NET
151	tcp/udp	hems	HEMS
152	tcp/udp	bftp	Background File Transfer Program
153	tcp/udp	sgmp	SGMP
154	tcp/udp	netsc-prod	NETSC
155	tcp/udp	netsc-dev	NETSC
156	tcp/udp	sqlsrv	SQL Service
157	tcp/udp	knet-cmp	KNET/VM Command/Message Protocol
158	tcp/udp	pcmail-srv	PCMail Server
159	tcp/udp	nss-routing	NSS-Routing
160	tcp/udp	sgmp-traps	SGMP-TRAPS
161	tcp/udp	snmp	SNMP
162	tcp/udp	snmptrap	SNMPTRAP
163	tcp/udp	cmip-man	CMIP/TCP Manager
164	tcp/udp	cmip-agent	CMIP/TCP Agent
165	tcp/udp	xns-courier	Xerox
166	tcp/udp	s-net	Sirius Systems
167	tcp/udp	namp	NAMP
168	tcp/udp	rsvd	RSVD
169	tcp/udp	send	SEND
170	tcp/udp	print-srv	Network PostScript
170 	tcp 	# 	A-trojan
171	tcp/udp	multiplex	Network Innovations Multiplex
172	tcp/udp	cl/1	Network Innovations CL/1
173	tcp/udp	xyplex-mux	Xyplex
174	tcp/udp	mailq	MAILQ
175	tcp/udp	vmnet	VMNET
176	tcp/udp	genrad-mux	GENRAD-MUX
177	tcp/udp	xdmcp	X Display Manager Control Protocol
178	tcp/udp	nextstep	NextStep Window Server
179	tcp/udp	bgp	Border Gateway Protocol
180	tcp/udp	ris	Intergraph
181	tcp/udp	unify	Unify
182	tcp/udp	audit	Unisys Audit SITP
183	tcp/udp	ocbinder	OCBinder
184	tcp/udp	ocserver	OCServer
185	tcp/udp	remote-kis	Remote-KIS
186	tcp/udp	kis	KIS Protocol
187	tcp/udp	aci	Application Communication Interface
188	tcp/udp	mumps	Plus Five's MUMPS
189	tcp/udp	qft	Queued File Transport
190	tcp/udp	gacp	Gateway Access Control Protocol
191	tcp/udp	prospero	Prospero Directory Service
192	tcp/udp	osu-nms	OSU Network Monitoring System
193	tcp/udp	srmp	Spider Remote Monitoring Protocol
194	tcp/udp	irc	Internet Relay Chat Protocol
195	tcp/udp	dn6-nlm-aud	DNSIX Network Level Module Audit
196	tcp/udp	dn6-smm-red	DNSIX Session Mgt Module Audit Redir
197	tcp/udp	dls	Directory Location Service
198	tcp/udp	dls-mon	Directory Location Service Monitor
199	tcp/udp	smux	SMUX
200	tcp/udp	src	IBM System Resource Controller
201	tcp/udp	at-rtmp	AppleTalk Routing Maintenance
202	tcp/udp	at-nbp	AppleTalk Name Binding
203	tcp/udp	at-3	AppleTalk Unused
204	tcp/udp	at-echo	AppleTalk Echo
205	tcp/udp	at-5	AppleTalk Unused
206	tcp/udp	at-zis	AppleTalk Zone Information
207	tcp/udp	at-7	AppleTalk Unused
208	tcp/udp	at-8	AppleTalk Unused
209	tcp/udp	qmtp	The Quick Mail Transfer Protocol
210	tcp/udp	z39.50	ANSI Z39.50
211	tcp/udp	914c/g	Texas Instruments 914C/G Terminal
212	tcp/udp	anet	ATEXSSTR
213	tcp/udp	ipx	IPX
214	tcp/udp	vmpwscs	VM PWSCS
215	tcp/udp	softpc	Insignia Solutions
216	tcp/udp	CAIlic	Computer Associates Int'l License Server
217	tcp/udp	dbase	dBASE Unix
218	tcp/udp	mpp	Netix Message Posting Protocol
219	tcp/udp	uarps	Unisys ARPs
220	tcp/udp	imap3	Interactive Mail Access Protocol v3
221	tcp/udp	fln-spx	Berkeley rlogind with SPX auth
222	tcp/udp	rsh-spx	Berkeley rshd with SPX auth
223	tcp/udp	cdc	Certificate Distribution Center
224	tcp/udp	masqdialer	masqdialer
225-241	tcp/udp	#	Reserved
242	tcp/udp	direct	Direct
243	tcp/udp	sur-meas	Survey Measurement
244	tcp/udp	inbusiness	inbusiness
245	tcp/udp	link	LINK
246	tcp/udp	dsp3270	Display Systems Protocol
247	tcp/udp	subntbcst_tftp	SUBNTBCST_TFTP
248	tcp/udp	bhfhs	bhfhs
249-255	tcp/udp	#	Reserved
256	tcp/udp	rap	RAP
256	tcp	#	FW1
Certificate/key distribution. VPN clients
(SecuRemote) can download keys on this port.
257	tcp/udp	set	Secure Electronic Transaction
257	tcp	#	FW1
logging
258	tcp/udp	yak-chat	Yak Winsock Personal Chat
258	tcp	#	FW1
Remote control over policy editing.
259	tcp/udp	esro-gen	Efficient Short Remote Operations
260	tcp/udp	openport	Openport
261	tcp/udp	nsiiops	IIOP Name Service over TLS/SSL
262	tcp/udp	arcisdms	Arcisdms
263	tcp/udp	hdap	HDAP
264	tcp/udp	bgmp	BGMP
264	tcp	#	FW1_topo
FW1 can be flooded on this port in order to cause
CPU utilization to reach 100% and stopping managers
from connecting. However, it requires a fast link and
access to that port, probably from the local network.
265	tcp/udp	x-bone-ctl	X-Bone CTL
266	tcp/udp	sst	SCSI on ST
267	tcp/udp	td-service	Tobit David Service Layer
268	tcp/udp	td-replica	Tobit David Replica
269-279	tcp/udp	#	Unassigned
280	tcp/udp	http-mgmt	http-mgmt
281	tcp/udp	personal-link	Personal Link
282	tcp/udp	cableport-ax	Cable Port A/X
283	tcp/udp	rescap	rescap
284	tcp/udp	corerjd	corerjd
285	tcp/udp	#	Unassigned
286	tcp/udp	fxp	FXP Communication
287	tcp/udp	k-block	K-BLOCK
288-299	tcp/udp	#	Unassigned
300-307	tcp/udp	#	Unassigned
308	tcp/udp	novastorbakcup	Novastor Backup
309	tcp/udp	entrusttime	EntrustTime
310	tcp/udp	bhmds	bhmds
311	tcp/udp	asip-webadmin	AppleShare IP WebAdmin
312	tcp/udp	vslmp	VSLMP
313	tcp/udp	magenta-logic	Magenta Logic
314	tcp/udp	opalis-robot	Opalis Robot
315	tcp/udp	dpsi	DPSI
316	tcp/udp	decauth	decAuth
317	tcp/udp	zannet	Zannet
318	tcp/udp	pkix-timestamp	PKIX TimeStamp
319	tcp/udp	ptp-event	PTP Event
320	tcp/udp	ptp-general	PTP General
321	tcp/udp	pip	PIP
322	tcp/udp	rtsps	RTSPS
323-332	tcp/udp	#	Unassigned
333	tcp/udp	texar	Texar Security Port
334-343	tcp/udp	#	Unassigned
334 	tcp 	# 	Backage
335 	tcp/udp 	# 	W32.HLLW.Nautic
344	tcp/udp	pdap	Prospero Data Access Protocol
345	tcp/udp	pawserv	Perf Analysis Workbench
346	tcp/udp	zserv	Zebra server
347	tcp/udp	fatserv	Fatmen Server
348	tcp/udp	csi-sgwp	Cabletron Management Protocol
349	tcp/udp	mftp	mftp
350	tcp/udp	matip-type-a	MATIP Type A
351	tcp/udp	matip-type-b	MATIP Type B
351	tcp	bhoetty	bhoetty (added 5/21/97)
351	udp	bhoetty	bhoetty
352	tcp	dtag-ste-sb	DTAG (assigned long ago)
352	udp	dtag-ste-sb	DTAG
352	tcp	bhoedap4	bhoedap4 (added 5/21/97)
352	udp	bhoedap4	bhoedap4
353	tcp/udp	ndsauth	NDSAUTH
354	tcp/udp	bh611	bh611
355	tcp/udp	datex-asn	DATEX-ASN
356	tcp/udp	cloanto-net-1	Cloanto Net 1
357	tcp/udp	bhevent	bhevent
358	tcp/udp	shrinkwrap	Shrinkwrap
359	tcp/udp	nsrmp	Network Security Risk Management Protocol
360	tcp/udp	scoi2odialog	scoi2odialog
361	tcp/udp	semantix	Semantix
362	tcp/udp	srssend	SRS Send
363	tcp/udp	rsvp_tunnel	RSVP Tunnel
364	tcp/udp	aurora-cmgr	Aurora CMGR
365	tcp/udp	dtk	DTK
366	tcp/udp	odmr	ODMR
367	tcp/udp	mortgageware	MortgageWare
368	tcp/udp	qbikgdp	QbikGDP
369	tcp/udp	rpc2portmap	rpc2portmap
370	tcp/udp	codaauth2	codaauth2
371	tcp/udp	clearcase	Clearcase
371 	udp 	# 	BackWeb
"push" servers use this port on UDP.
372	tcp/udp	ulistproc	ListProcessor
373	tcp/udp	legent-1	Legent Corporation
374	tcp/udp	legent-2	Legent Corporation
375	tcp/udp	hassle	Hassle
376	tcp/udp	nip	Amiga Envoy Network Inquiry Proto
377	tcp/udp	tnETOS	NEC Corporation
378	tcp/udp	dsETOS	NEC Corporation
379	tcp/udp	is99c	TIA/EIA/IS-99 modem client
380	tcp/udp	is99s	TIA/EIA/IS-99 modem server
381	tcp/udp	hp-collector	hp performance data collector
382	tcp/udp	hp-managed-node	hp performance data managed node
382 	tcp/udp 	# 	W32.Rotor
383	tcp/udp	hp-alarm-mgr	hp performance data alarm manager
384	tcp/udp	arns	A Remote Network Server System
385	tcp/udp	ibm-app	IBM Application
386	tcp/udp	asa	ASA Message Router Object Def.
387	tcp/udp	aurp	Appletalk Update-Based Routing Pro.
388	tcp/udp	unidata-ldm	Unidata LDM
389	tcp/udp	ldap	Lightweight Directory Access Protocol
390	tcp/udp	uis	UIS
391	tcp/udp	synotics-relay	SynOptics SNMP Relay Port
392	tcp/udp	tcp/udp	synotics-broker
393	tcp/udp	meta5	Meta5
394	tcp/udp	embl-ndt	EMBL Nucleic Data Transfer
395	tcp/udp	netcp	NETscout Control Protocol
396	tcp/udp	netware-ip	Novell Netware over IP
397	tcp/udp	mptn	Multi Protocol Trans. Net.
398	tcp/udp	kryptolan	Kryptolan
399	tcp/udp	iso-tsap-c2	ISO Transport Class 2 Non-Control over TCP
400	tcp/udp	work-sol	Workstation Solutions
401	tcp/udp	ups	Uninterruptible Power Supply
402	tcp/udp	genie	Genie Protocol
403	tcp/udp	decap	decap
404	tcp/udp	nced	nced
405	tcp/udp	ncld	ncld
406	tcp/udp	imsp	Interactive Mail Support Protocol
407	tcp/udp	timbuktu	Timbuktu
408	tcp/udp	prm-sm	Prospero Resource Manager Sys. Man.
409	tcp/udp	prm-nm	Prospero Resource Manager Node Man.
410	tcp/udp	decladebug	DECLadebug Remote Debug Protocol
411	tcp/udp	rmt	Remote MT Protocol
411 	tcp 	# 	Backage
412	tcp/udp	synoptics-trap	Trap Convention Port
413	tcp/udp	smsp	Storage Management Services Protocol
414	tcp/udp	infoseek	InfoSeek
415	tcp/udp	bnet	BNet
416	tcp/udp	silverplatter	Silverplatter
417	tcp/udp	onmux	Onmux
418	tcp/udp	hyper-g	Hyper-G
419	tcp/udp	ariel1	Ariel 1
420	tcp/udp	smpte	SMPTE
420 	tcp 	# 	Breach, Incognito, W32.Kibuv.Worm
421	tcp/udp	ariel2	Ariel 2
421 	tcp 	# 	TCP Wrappers trojan
422	tcp/udp	ariel3	Ariel 3
423	tcp/udp	opc-job-start	IBM Operations Planning and Control Start
424	tcp/udp	opc-job-track	IBM Operations Planning and Control Track
425	tcp/udp	icad-el	ICAD
426	tcp/udp	smartsdp	smartsdp
427	tcp/udp	svrloc	Server Location
428	tcp/udp	ocs_cmu	OCS_CMU
429	tcp/udp	ocs_amu	OCS_AMU
430	tcp/udp	utmpsd	UTMPSD
431	tcp/udp	utmpcd	UTMPCD
432	tcp/udp	iasd	IASD
433	tcp/udp	nnsp	NNSP
434	tcp/udp	mobileip-agent	MobileIP-Agent
435	tcp/udp	mobilip-mn	MobilIP-MN
436	tcp/udp	dna-cml	DNA-CML
437	tcp/udp	comscm	comscm
438	tcp/udp	dsfgw	dsfgw
439	tcp	dasp	dasp Thomas Obermair
439	udp	dasp	dasp tommy@inlab.m.eunet.de
440	tcp/udp	sgcp	sgcp
441	tcp/udp	decvms-sysmgt	decvms-sysmgt
442	tcp/udp	cvc_hostd	cvc_hostd
443	tcp/udp	https	http protocol over TLS/SSL
443 	tcp 	# 	Tabdim
444	tcp/udp	snpp	Simple Network Paging Protocol
445	tcp/udp	microsoft-ds	Microsoft-DS
445 	tcp 	# 	W32.HLLW.Gaobot, W32.HLLW.Lioten,
W32.HLLW.Deloder, W32.Slackor,
W32.HLLW.Nebiwo, W32.HLLW.Moega,
W32.HLLW.Deborms, W32.Yaha, Randex,
W32.Bolgi.Worm,W32.Cissi, W32.Welchia,
W32.HLLW.Polybot, W32.Sasser, W32.Cycle,
W32.Bobax, W32.Kibuv.Worm, W32.Korgo,
W32.Explet, Otinet, W32.Scane, W32.Aizu
Rtkit, W32.Spybot, W32.Janx, Netdepix
446	tcp/udp	ddm-rdb	DDM-Remote Relational Database Access
447	tcp/udp	ddm-dfm	DDM-Distributed File Management
448	tcp/udp	ddm-ssl	DDM-Remote DB Access Using Secure Sockets
449	tcp/udp	as-servermap	AS Server Mapper
449 	tcp/udp 	# 	Krei
450	tcp/udp	tserver	Computer Supported Telecomunication
Applications
451	tcp/udp	sfs-smp-net	Cray Network Semaphore server
452	tcp/udp	sfs-config	Cray SFS config server
453	tcp/udp	creativeserver	CreativeServer
454	tcp/udp	contentserver	ContentServer
455	tcp/udp	creativepartnr	CreativePartnr
455 	tcp 	# 	Fatal Connections
456	tcp	macon-tcp	macon-tcp
456 	tcp 	# 	Hackers Paradise
456	udp	macon-udp	macon-udp
457	tcp/udp	scohelp	scohelp
458	tcp/udp	appleqtc	apple quick time
459	tcp/udp	ampr-rcmd	ampr-rcmd
460	tcp/udp	skronk	skronk
461	tcp/udp	datasurfsrv	DataRampSrv
462	tcp/udp	datasurfsrvsec	DataRampSrvSec
463	tcp/udp	alpes	alpes
464	tcp/udp	kpasswd	kpasswd
465	tcp	urd	URL Rendesvous Directory for SSM
465	udp	igmpv3lite	IGMP over UDP for SSM
466	tcp/udp	digital-vrc	digital-vrc
467	tcp/udp	mylex-mapd	mylex-mapd
468	tcp/udp	photuris	proturis
469	tcp/udp	rcp	Radio Control Protocol
470	tcp/udp	scx-proxy	scx-proxy
471	tcp/udp	mondex	Mondex
472	tcp/udp	ljk-login	ljk-login
473	tcp/udp	hybrid-pop	hybrid-pop
474	tcp	tn-tl-w1	tn-tl-w1
474	udp	tn-tl-w2	tn-tl-w2
475	tcp/udp	tcpnethaspsrv	tcpnethaspsrv
475 	tcp 	# 	SCO Unizware 7 default installation
includes an HTTP server running on
this port for the "scohelp" service.
476	tcp/udp	tn-tl-fd1	tn-tl-fd1
477	tcp/udp	ss7ns	ss7ns
478	tcp/udp	spsc	spsc
479	tcp/udp	iafserver	iafserver
480	tcp/udp	iafdbase	iafdbase
481	tcp/udp	ph	Ph service
482	tcp/udp	bgs-nsi	bgs-nsi
483	tcp/udp	ulpnet	ulpnet
484	tcp/udp	integra-sme	Integra Software Management Environment
485	tcp/udp	powerburst	Air Soft Power Burst
486	tcp/udp	avian	avian
487	tcp/udp	saft	saft Simple Asynchronous File Transfer
488	tcp/udp	gss-http	gss-http
489	tcp/udp	nest-protocol	nest-protocol
490	tcp/udp	micom-pfs	micom-pfs
491	tcp/udp	go-login	go-login
492	tcp/udp	ticf-1	Transport Independent Convergence for FNA
493	tcp/udp	ticf-2	Transport Independent Convergence for FNA
494	tcp/udp	pov-ray	POV-Ray
495	tcp/udp	intecourier	intecourier
496	tcp/udp	pim-rp-disc	PIM-RP-DISC
497	tcp/udp	dantz	dantz
498	tcp/udp	siam	siam
499	tcp/udp	iso-ill	ISO ILL Protoco
500	tcp/udp	isakmp	isakmp
501	tcp/udp	stmf	STMF
502	tcp/udp	asa-appl-proto	asa-appl-proto
503	tcp/udp	intrinsa	Intrinsa
504	tcp/udp	citadel	citadel
505	tcp/udp	mailbox-lm	mailbox-lm
506	tcp/udp	ohimsrv	ohimsrv
507	tcp/udp	crs	crs
508	tcp/udp	xvttp	xvttp
509	tcp/udp	snare	snare
510	tcp/udp	fcp	FirstClass Protocol
511	tcp/udp	passgo	PassGo
511 	tcp 	# 	Part of rootkit t0rn, a program called
"leeto's socket daemon" runs at this port.
512	tcp	exec	remote process execution; authentication
performed using passwords and UNIX login names
512	udp	comsat	 
512	udp	biff	used by mail system to notify users of
new mail received; currently receives
messages only from processes on
the same machine
513	tcp	login	"remote login a la telnet; automatic
authentication performed based on
priviledged port numbers and
distributed data bases which
identify ""authentication domains"""
513	udp	who	maintains data bases showing who's logged in to
machines on a local net and the load average
of the machine
513 	tcp 	# 	Grlogin
514	tcp	shell	"cmd like exec, but automatic authentication is
performed as for login server"
514 	tcp 	# 	RPC Backdoor
514	udp	syslog	 
515	tcp/udp	printer	spooler
516	tcp/udp	videotex	videotex
517	tcp/udp	talk	"like tenex link, but across machine - unfortunately,
doesn't use link protocol (this is actually just a
rendezvous port from which a tcp connection is established)"
518	tcp/udp	ntalk	 
519	tcp/udp	utime	unixtime
520	tcp	efs	extended file name server
520	udp	router	local routing process (on site); uses variant of
Xerox NS routing information protocol - RIP
521	tcp/udp	ripng	ripng
522	tcp/udp	ulp	ULP
523	tcp/udp	ibm-db2	IBM-DB2
524	tcp/udp	ncp	NCP
525	tcp/udp	timed	timeserver
526	tcp/udp	tempo	newdate
527	tcp/udp	stx	Stock IXChange
528	tcp/udp	custix	Customer IXChange
529	tcp/udp	irc-serv	IRC-SERV
530	tcp/udp	courier	rpc
531	tcp/udp	conference	chat
531 	tcp 	# 	Net666, Rasmin
532	tcp/udp	netnews	readnews
533	tcp/udp	netwall	for emergency broadcasts
534	tcp/udp	mm-admin	MegaMedia Admin
535	tcp/udp	iiop	iiop
536	tcp/udp	opalis-rdv	opalis-rdv
537	tcp/udp	nmsp	Networked Media Streaming Protocol
538	tcp/udp	gdomap	gdomap
539	tcp/udp	apertus-ldp	Apertus Technologies Load Determination
540	tcp/udp	uucp	uucpd
541	tcp/udp	uucp-rlogin	uucp-rlogin
542	tcp/udp	commerce	commerce
543	tcp/udp	klogin	 
544	tcp/udp	kshell	krcmd
545	tcp/udp	appleqtcsrvr	appleqtcsrvr
546	tcp/udp	dhcpv6-client	DHCPv6 Client
547	tcp/udp	dhcpv6-server	DHCPv6 Server
548	tcp/udp	afpovertcp	AFP over TCP
549	tcp/udp	idfp	IDFP
550	tcp/udp	new-rwho	new-who
551	tcp/udp	cybercash	cybercash
552	tcp/udp	devshr-nts	DeviceShare
553	tcp/udp	pirp	pirp
554	tcp/udp	rtsp	Real Time Stream Control Protocol
555	tcp/udp	dsf	 
555 	tcp/udp 	# 	Trojan: phAse Zero
711 trojan (Seven Eleven), Ini-Killer,
Net Administrator,
Phase Zero, Phase-0, Stealth Spy
556	tcp/udp	remotefs	rfs server
557	tcp/udp	openvms-sysipc	openvms-sysipc
558	tcp/udp	sdnskmp	SDNSKMP
559	tcp/udp	teedtap	TEEDTAP
559 	tcp 	# 	Domwis
560	tcp/udp	rmonitor	rmonitord
561	tcp/udp	monitor	 
562	tcp/udp	chshell	chcmd
563	tcp/udp	nntps	nntp protocol over TLS/SSL (was snntp)
564	tcp/udp	9pfs	plan 9 file service
565	tcp/udp	whoami	whoami
566	tcp/udp	streettalk	streettalk
567	tcp/udp	banyan-rpc	banyan-rpc
568	tcp/udp	ms-shuttle	microsoft shuttle
569	tcp/udp	ms-rome	microsoft rome
570	tcp/udp	meter	demon
571	tcp/udp	meter	udemon
572	tcp/udp	sonar	sonar
573	tcp/udp	banyan-vip	banyan-vip
574	tcp/udp	ftp-agent	FTP Software Agent System
575	tcp/udp	vemmi	VEMMI
576	tcp/udp	ipcd	ipcd
577	tcp/udp	vnas	vnas
578	tcp/udp	ipdd	ipdd
579	tcp/udp	decbsrv	decbsrv
580	tcp/udp	sntp-heartbeat	SNTP HEARTBEAT
581	tcp/udp	bdp	Bundle Discovery Protocol
582	tcp/udp	scc-security	SCC Security
583	tcp/udp	philips-vc	Philips Video-Conferencing
584	tcp/udp	keyserver	Key Server
585	tcp/udp	imap4-ssl	IMAP4+SSL (use 993 instead)
586	tcp/udp	password-chg	Password Change
587	tcp/udp	submission	Submission
588	tcp/udp	cal	CAL
589	tcp/udp	eyelink	EyeLink
590	tcp/udp	tns-cml	TNS CML
591	tcp/udp	http-alt	"FileMaker, Inc. - HTTP Alternate (see Port 80)"
592	tcp/udp	eudora-set	Eudora Set
593	tcp/udp	http-rpc-epmap	HTTP RPC Ep Map
594	tcp/udp	tpip	TPIP
595	tcp/udp	cab-protocol	CAB Protocol
596	tcp/udp	smsd	SMSD
597	tcp/udp	ptcnameservice	PTC Name Service
598	tcp/udp	sco-websrvrmg3	SCO Web Server Manager 3
599	tcp/udp	acp	Aeolon Core Protocol
600	tcp/udp	ipcserver	Sun IPC server
601	tcp/udp	syslog-conn	Reliable Syslog Service
602	tcp/udp	xmlrpc-beep	XML-RPC over BEEP
603	tcp/udp	idxp	IDXP
604	tcp/udp	tunnel	TUNNEL
605	tcp/udp	soap-beep	SOAP over BEEP
605 	tcp 	# 	Secret Service
606	tcp/udp	urm	Cray Unified Resource Manager
607	tcp/udp	nqs	nqs
608	tcp/udp	sift-uft	Sender-Initiated/Unsolicited File Transfer
609	tcp/udp	npmp-trap	npmp-trap
610	tcp/udp	npmp-local	npmp-local
611	tcp/udp	npmp-gui	npmp-gui
612	tcp/udp	hmmp-ind	HMMP Indication
613	tcp/udp	hmmp-op	HMMP Operation
614	tcp/udp	sshell	SSLshell
615	tcp/udp	sco-inetmgr	Internet Configuration Manager
616	tcp/udp	sco-sysmgr	SCO System Administration Server
617	tcp/udp	sco-dtmgr	SCO Desktop Administration Server
618	tcp/udp	dei-icda	DEI-ICDA
619	tcp/udp	compaq-evm	Compaq EVM
620	tcp/udp	sco-websrvrmgr	SCO WebServer Manager
621	tcp/udp	escp-ip	ESCP
622	tcp/udp	collaborator	Collaborator
623	tcp/udp	asf-rmcp	ASF Remote Management and Control Protocol
624	tcp/udp	cryptoadmin	Crypto Admin
625	tcp/udp	dec_dlm	DEC DLM
626	tcp/udp	asia	ASIA
627	tcp/udp	passgo-tivoli	PassGo Tivoli
628	tcp/udp	qmqp	QMQP
629	tcp/udp	3com-amp3	3Com AMP3
630	tcp/udp	rda	RDA
631	tcp/udp	ipp	IPP (Internet Printing Protocol)
632	tcp/udp	bmpp	bmpp
633	tcp/udp	servstat	Service Status update (Sterling Software)
634	tcp/udp	ginad	ginad
635	tcp/udp	rlzdbase	RLZ DBase
635	tcp/udp	#	mountd
636	tcp/udp	ldaps	ldap protocol over TLS/SSL (was sldap)
637	tcp/udp	lanserver	lanserver
638	tcp/udp	mcns-sec	mcns-sec
639	tcp/udp	msdp	MSDP
640	tcp/udp	entrust-sps	entrust-sps
641	tcp/udp	repcmd	repcmd
642	tcp/udp	esro-emsdp	ESRO-EMSDP V1.3
643	tcp/udp	sanity	SANity
644	tcp/udp	dwr	dwr
645	tcp/udp	pssc	PSSC
646	tcp/udp	ldp	LDP
647	tcp/udp	dhcp-failover	DHCP Failover
648	tcp/udp	rrp	Registry Registrar Protocol (RRP)
649	tcp/udp	cadview-3d	Cadview-3d - streaming 3d models over the internet
650	tcp/udp	obex	OBEX
651	tcp/udp	ieee-mms	IEEE MMS
652	tcp/udp	hello-port	HELLO_PORT
653	tcp/udp	repscmd	RepCmd
654	tcp/udp	aodv	AODV
655	tcp/udp	tinc	TINC
656	tcp/udp	spmp	SPMP
657	tcp/udp	rmc	RMC
658	tcp/udp	tenfold	TenFold
659	tcp/udp	#	Removed
660	tcp/udp	mac-srvr-admin	MacOS Server Admin
661	tcp/udp	hap	HAP
662	tcp/udp	pftp	PFTP
663	tcp/udp	purenoise	PureNoise
664	tcp/udp	asf-secure-rmcp	ASF Secure Remote Management and Control
Protocol
665	tcp/udp	sun-dr	Sun DR
665 	tcp 	# 	W32.Netsky
666	tcp/udp	mdqs	 
666	tcp/udp	doom	doom Id Software
666 	tcp 	# 	Attack FTP, Back Construction, BLA trojan,
Cain & Abel, NokNok, Satans Back Door - SBD,
ServU, Shadow Phyre, th3r1pp3rz, Sixca, Beasty
FTP_Ana, Private, Checkesp, Futro
667	tcp/udp	disclose	campaign contribution disclosures - SDR Technologies
667 	tcp 	# 	SniperNet
668	tcp/udp	mecomm	MeComm
669	tcp/udp	meregister	MeRegister
669 	tcp 	# 	DP trojan
670	tcp/udp	vacdsm-sws	VACDSM-SWS
671	tcp/udp	vacdsm-app	VACDSM-APP
672	tcp/udp	vpps-qua	VPPS-QUA
673	tcp/udp	cimplex	CIMPLEX
674	tcp/udp	acap	ACAP
675	tcp/udp	dctp	DCTP
676	tcp/udp	vpps-via	VPPS Via
677	tcp/udp	vpp	Virtual Presence Protocol
678	tcp/udp	ggf-ncp	GNU Generation Foundation NCP
679	tcp/udp	mrm	MRM
680	tcp/udp	entrust-aaas	entrust-aaas
681	tcp/udp	entrust-aams	entrust-aams
682	tcp/udp	xfr	XFR
683	tcp/udp	corba-iiop	CORBA IIOP
684	tcp/udp	corba-iiop-ssl	CORBA IIOP SSL
685	tcp/udp	mdc-portmapper	MDC Port Mapper
686	tcp/udp	hcp-wismar	Hardware Control Protocol Wismar
687	tcp/udp	asipregistry	asipregistry
688	tcp/udp	realm-rusd	REALM-RUSD
689	tcp/udp	nmap	NMAP
690	tcp/udp	vatp	VATP
691	tcp/udp	msexch-routing	MS Exchange Routing
692	tcp/udp	hyperwave-isp	Hyperwave-ISP
692 	tcp 	# 	GayOL
693	tcp/udp	connendp	connendp
694	tcp/udp	ha-cluster	ha-cluster
695	tcp/udp	ieee-mms-ssl	IEEE-MMS-SSL
696	tcp/udp	rushd	RUSHD
697	tcp/udp	uuidgen	UUIDGEN
698	tcp/udp	olsr	OLSR
699	tcp/udp	accessnetwork	Access Network
700	tcp/udp	epp	Extensible Provisioning Protocol
700 	tcp/udp 	buddyphone 	This Internet telephony product communicates
over this port as well as the TCP range 5000-5111.
701	tcp/udp	lmp	Link Management Protocol (LMP)
702	tcp/udp	iris-beep	IRIS over BEEP
703	tcp/udp	#	Unassigned
701 	tcp/udp 	# 	Marotob
704	tcp/udp	elcsd	errlog copy/server daemon
705	tcp/udp	agentx	AgentX
706	tcp/udp	silc	SILC
707	tcp/udp	borland-dsj	Borland DSJ
708	tcp/udp	#	Unassigned
709	tcp/udp	entrust-kmsh	Entrust Key Management Service Handler
710	tcp/udp	entrust-ash	Entrust Administration Service Handler
711	tcp/udp	cisco-tdp	Cisco TDP
712	tcp/udp	tbrpf	TBRPF
713-728	tcp/udp	#	Unassigned
729	tcp/udp	netviewdm1	IBM NetView DM/6000 Server/Client
730	tcp/udp	netviewdm2	IBM NetView DM/6000 send tcp
731	tcp/udp	netviewdm3	IBM NetView DM/6000 receive tcp
732-740	tcp/udp	#	Unassigned
741	tcp/udp	netgw	netGW
742	tcp/udp	netrcs	Network based Rev. Cont. Sys.
743	tcp/udp	#	Unassigned
744	tcp/udp	flexlm	Flexible License Manager
745-746	tcp/udp	#	Unassigned
747	tcp/udp	fujitsu-dev	Fujitsu Device Control
748	tcp/udp	ris-cm	Russell Info Sci Calendar Manager
749	tcp/udp	kerberos-adm	kerberos administration
750	tcp	rfile	 
750	udp	loadav	 
750	udp	kerberos-iv	kerberos version iv
751	tcp/udp	pump	 
752	tcp/udp	qrh	 
753	tcp/udp	rrh	 
754	tcp/udp	tell	send
755-756	tcp/udp	#	Unassigned
758	tcp/udp	nlogin	 
759	tcp/udp	con	 
760	tcp/udp	ns	 
761	tcp/udp	rxe	 
762	tcp/udp	quotad	 
763	tcp/udp	cycleserv	 
764	tcp/udp	omserv	 
765	tcp/udp	webster	 
766	tcp/udp	#	Unassigned
767	tcp/udp	phonebook	phone
768	tcp/udp	#	Unassigned
769	tcp/udp	vid	 
770	tcp/udp	cadlock	 
771	tcp/udp	rtip	 
772	tcp/udp	cycleserv2	 
773	tcp	submit	 
773	udp	notify	 
774	tcp	rpasswd	 
774	udp	acmaint_dbd	 
775	tcp	entomb	 
775	udp	acmaint_transd	 
776	tcp/udp	wpages	 
777	tcp/udp	multiling-http	Multiling HTTP
777 	tcp 	# 	AimSpy, Undetected, NetCrack
778 	tcp 	# 	NetCrack
778-779	tcp/udp	#	Unassigned
780	tcp/udp	wpgs	 
781-785	tcp/udp	#	Unassigned
786	tcp/udp	#	Unassigned
787	tcp/udp	#	Unassigned
788-799	tcp/udp	#	Unassigned
800	tcp/udp	mdbs_daemon	 
801	tcp/udp	device	 
802-809	tcp/udp	#	Unassigned
808 	tcp 	# 	WinHole
810	tcp	fcp-udp	FCP
810	udp	fcp-udp	FCP Datagram
811-827	tcp/udp	#	Unassigned
828	tcp/udp	itm-mcell-s	itm-mcell-s
829	tcp/udp	pkix-3-ca-ra	PKIX-3 CA/RA
830-846	tcp/udp	#	Unassigned
847	tcp/udp	dhcp-failover2	dhcp-failover 2
848	tcp/udp	gdoi	GDOI
849-859	tcp/udp	#	Unassigned
860	tcp/udp	iscsi	iSCSI
861-872	tcp/udp	#	Unassigned
873	tcp/udp	rsync	rsync
874-885	tcp/udp	#	Unassigned
886	tcp/udp	iclcnet-locate	ICL coNETion locate server
887	tcp/udp	iclcnet_svinfo	ICL coNETion server info
887 	tcp 	# 	W32.Huayu
888	tcp/udp	accessbuilder	AccessBuilder
888	tcp	cddbp	CD Database Protocol
889-899	tcp/udp	#	Unassigned
890 	tcp 	# 	Dsklite
900	tcp/udp	omginitialrefs	OMG Initial Refs
901	tcp/udp	smpnameres	SMPNAMERES
901 	tcp 	swat 	SWAT is an HTTP interface to SAMBA.
901 	tcp/udp 	# 	ISS RealSecure
The IDS sensor listens on this port
for communication from the console.
902	tcp/udp	ideafarm-chat	IDEAFARM-CHAT
903	tcp/udp	ideafarm-catch	IDEAFARM-CATCH
904-910	tcp/udp	#	Unassigned
905 	tcp/udp 	# 	NetDevil
911	tcp/udp	xact-backup	xact-backup
911 	tcp 	# 	Dark Shadow
912	tcp/udp	apex-mesh	APEX relay-relay service
913	tcp/udp	apex-edge	APEX endpoint-relay service
914-988	tcp/udp	#	Unassigned
989	tcp/udp	ftps-data	"ftp protocol, data, over TLS/SSL"
990	tcp/udp	ftps	"ftp protocol, control, over TLS/SSL"
991	tcp/udp	nas	Netnews Administration System
992	tcp/udp	telnets	telnet protocol over TLS/SSL
993	tcp/udp	imaps	imap4 protocol over TLS/SSL
994	tcp/udp	ircs	irc protocol over TLS/SSL
995	tcp/udp	pop3s	pop3 protocol over TLS/SSL (was spop3)
996	tcp/udp	vsinet	vsinet
997	tcp/udp	maitrd	 
998	tcp	busboy	 
998	udp	puparp	 
999	tcp	garcon	 
999	udp	applix	Applix ac
999	tcp/udp	puprouter	 
999 	tcp 	# 	RAT: Deep Throat
Puts a keylogger at port 999 (TCP).
This will record all of a user's keystrokes.
999 	tcp 	# 	Foreplay, WinSatan
1000	tcp/udp	cadlock2	 
1000 	tcp 	# 	Der Spaher / Der Spaeher, Direct Connection, Nibu
1001-1009	tcp/udp	#	Unassigned
1001 	tcp 	# 	Der Spaher / Der Spaeher, Le Guardien,
Silencer, WebEx, Ghoice, Nibu, W32.Dumaru
1008	udp	#	Possibly used by Sun Solaris????
1010	tcp/udp	surf	surf
1010-1012 	tcp 	# 	Doly Trojan
1011-1022	tcp/udp	#	Reserved
1011 	tcp 	# 	Augudor
1012 	tcp 	# 	Backdoor.Urat
1015-1016 	tcp 	# 	Doly Trojan
1020 	tcp 	# 	Vampire
1022 	tcp 	# 	W32.Sasser
1023	tcp/udp	#	Reserved
1023 	tcp 	# 	W32.Sasser
1024	tcp/udp	#	Reserved
1024 	tcp 	# 	RAT:NetSpy, Jade, Latinus, Randex,
W32.Mydoom
1025	tcp/udp	blackjack	network blackjack
1025 	tcp/udp 	# 	Remote Storm, ABCHlp, Lala
1025- 	tcp/udp 	# 	W32.Keco
1026	tcp/udp	cap	Calender Access Protocol
1027	tcp/udp	exosee	ExoSee
1027 	tcp/udp 	# 	ABCHlp
1028	tcp/udp	#	Unassigned
1029	tcp/udp	solid-mux	Solid Mux Server
1029 	tcp/udp 	# 	W32.Kipis
1030	tcp/udp	iad1	BBN IAD
1031	tcp/udp	iad2	BBN IAD
1032	tcp/udp	iad3	BBN IAD
1033	tcp/udp	netinfo-local	local netinfo port
1034	tcp/udp	activesync	ActiveSync Notifications
1034 	tcp 	# 	Zincite, W32.Mydoom, W32.Zindos
1035	tcp/udp	mxxrlogin	MX-XR RPC
1035 	tcp 	# 	Multidropper
1036	tcp/udp	nsstp	Nebula Secure Segment Transfer Protocol
1037	tcp/udp	ams	AMS
1038	tcp/udp	mtqp	Message Tracking Query Protocol
1039	tcp/udp	sbl	Streamlined Blackhole
1039 	tcp/udp 	# 	Gapin
1040	tcp/udp	netarx	Netarx
1040 	tcp/udp 	# 	Medias
1041	tcp/udp	danf-ak2	AK2 Product
1042	tcp/udp	afrog	Subnet Roaming
1042 	tcp 	# 	BLA trojan
1043	tcp/udp	boinc-client	BOINC Client Control
1044	tcp/udp	dcutility	Dev Consortium Utility
1045	tcp/udp	fpitp	Fingerprint Image Transfer Protocol
1045 	tcp 	# 	Rasmin
1046	tcp/udp	wfremotertm	WebFilter Remote Monitor
1047	tcp/udp	neod1	Sun's NEO Object Request Broker
1048	tcp/udp	neod2	Sun's NEO Object Request Broker
1049	tcp/udp	td-postman	Tobit David Postman VPMN
1049 	tcp 	# 	/sbin/initd
1050	tcp/udp	cma	CORBA Management Agent
1050 	tcp 	piranha	Heartbeat listening port on the primary and
backup routers in this load-balancing
package for Linux.
1050 	tcp 	# 	MiniCommand
1051	tcp/udp	optima-vnet	Optima VNET
1052	tcp/udp	ddt	Dynamic DNS Tools
1053	tcp/udp	remote-as	Remote Assistant (RA)
1053 	tcp 	# 	The Thief
1054	tcp/udp	brvread	BRVREAD
1054 	tcp 	# 	AckCmd
1055	tcp/udp	ansyslmd	ANSYS - License Manager
1056	tcp/udp	vfo	VFO
1057	tcp/udp	startron	STARTRON
1058	tcp/udp	nim	nim
1059	tcp/udp	nimreg	nimreg
1060	tcp/udp	polestar	POLESTAR
1061	tcp/udp	kiosk	KIOSK
1062	tcp/udp	veracity	Veracity
1063	tcp/udp	kyoceranetdev	KyoceraNetDev
1064	tcp/udp	jstel	JSTEL
1065	tcp/udp	syscomlan	SYSCOMLAN
1066	tcp/udp	fpo-fns	FPO-FNS
1067	tcp/udp	instl_boots	Installation Bootstrap Proto. Serv.
1068	tcp/udp	instl_bootc	Installation Bootstrap Proto. Cli.
1069	tcp/udp	cognex-insight	COGNEX-INSIGHT
1070	tcp/udp	gmrupdateserv	GMRUpdateSERV
1071	tcp/udp	bsquare-voip	BSQUARE-VOIP
1072	tcp/udp	cardax	CARDAX
1073	tcp/udp	bridgecontrol	Bridge Control
1074	tcp/udp	fastechnologlm	FASTechnologies License Manager
1075	tcp/udp	rdrmshc	RDRMSHC
1076	tcp/udp	dab-sti-c	DAB STI-C
1077	tcp/udp	imgames	IMGames
1078	tcp/udp	avocent-proxy	Avocent Proxy Protocol
1079	tcp/udp	asprovatalk	ASPROVATalk
1080	tcp/udp	socks	Socks
1080 	tcp 	# 	Lixy, Mydoom, W32.HLLW.Deadhat,
W32.Beagle, Webus
1080-1083 	tcp 	# 	WinHole
1081	tcp/udp	pvuniwien	PVUNIWIEN
1082	tcp/udp	amt-esd-prot	AMT-ESD-PROT
1083	tcp/udp	ansoft-lm-1	Anasoft License Manager
1084	tcp/udp	ansoft-lm-2	Anasoft License Manager
1085	tcp/udp	webobjects	Web Objects
1086	tcp/udp	cplscrambler-lg	CPL Scrambler Logging
1087	tcp/udp	cplscrambler-in	CPL Scrambler Internal
1088	tcp/udp	cplscrambler-al	CPL Scrambler Alarm Log
1088 	tcp 	# 	Webus
1089	tcp/udp	ff-annunc	FF Annunciation
1090	tcp/udp	ff-fms	FF Fieldbus Message Specification
1090 	tcp 	# 	Xtreme
1091	tcp/udp	ff-sm	FF System Management
1092	tcp/udp	obrpd	Open Business Reporting Protocol
1092 	tcp 	# 	Lovgate
1093	tcp/udp	proofd	PROOFD
1094	tcp/udp	rootd	ROOTD
1095	tcp/udp	nicelink	NICELink
1095 	tcp 	# 	Remote Administration Tool - RAT
1096	tcp/udp	cnrprotocol	Common Name Resolution Protocol
1097	tcp/udp	sunclustermgr	Sun Cluster Manager
1097-1099 	tcp 	# 	Remote Administration Tool - RAT
1098	tcp/udp	rmiactivation	RMI Activation
1099	tcp/udp	rmiregistry	RMI Registry
1099 	tcp 	# 	Blood Fest Evolution
1100	tcp/udp	mctp	MCTP
1100 	tcp/udp 	# 	Double-Take
1101	tcp/udp	pt2-discover	PT2-DISCOVER
1101-1115 	tcp/udp 	# 	Hatckel
1102	tcp/udp	adobeserver-1	ADOBE SERVER 1
1103	tcp/udp	adobeserver-2	ADOBE SERVER 2
1104	tcp/udp	xrl	XRL
1105	tcp/udp	ftranhc	FTRANHC
1105 	tcp/udp 	# 	Double-Take
1106	tcp/udp	isoipsigport-1	ISOIPSIGPORT-1
1107	tcp/udp	isoipsigport-2	ISOIPSIGPORT-2
1108	tcp/udp	ratio-adp	ratio-adp
1109	tcp/udp	#	Reserved - IANA
1110	tcp	nfsd-status	Cluster status info
1110	udp	nfsd-keepalive	Client status info
1111	tcp/udp	lmsocialserver	LM Social Server
1111 	tcp/udp 	# 	AIMVision
1112	tcp/udp	icp	Intelligent Communication Protocol
1113	tcp/udp	#	Unassigned
1114	tcp/udp	mini-sql	Mini SQL
1115	tcp/udp	ardus-trns	ARDUS Transfer
1116	tcp/udp	ardus-cntl	ARDUS Control
1117	tcp/udp	ardus-mtrns	ARDUS Multicast Transfer
1118	tcp/udp	sacred	SACRED
1119-1120	tcp/udp	#	Unassigned
1121	tcp/udp	rmpp	Datalode RMPP
1122	tcp/udp	availant-mgr	availant-mgr
1123	tcp/udp	murray	Murray
1124	tcp/udp	hpvmmcontrol	HP VMM Control
1125	tcp/udp	hpvmmagent	HP VMM Agent
1126	tcp/udp	hpvmmdata	HP VMM Agent
1127-1154	tcp/udp	#	Unassigned
1129 	tcp 	# 	Anyserv
1145 	tcp/udp 	# 	CHCP
1150-1151 	tcp 	# 	Orion
1155	tcp/udp	nfa	Network File Access
1156	tcp/udp	iascontrol-oms	iasControl OMS
1157	tcp/udp	iascontrol	Oracle iASControl
1158	tcp/udp	dbcontrol-oms	dbControl OMS
1159	tcp/udp	oracle-oms	Oracle OMS
1160	tcp/udp	#	Unassigned
1161	tcp/udp	health-polling	Health Polling
1162	tcp/udp	health-trap	Health Trap
1163	tcp/udp	sddp	SmartDialer Data Protocol
1164	tcp/udp	qsm-proxy	QSM Proxy Service
1165	tcp/udp	qsm-gui	QSM GUI Service
1166	tcp/udp	qsm-remote	QSM RemoteExec
1167	tcp/udp	#	Unassigned
1168	tcp/udp	vchat	VChat Conference Service
1169	tcp/udp	tripwire	TRIPWIRE
1170	tcp/udp	atc-lm	AT+C License Manager
1171	tcp/udp	atc-appserver	AT+C FmiApplicationServer
1172	tcp/udp	dnap	DNA Protocol
1173	tcp/udp	d-cinema-rrp	D-Cinema Request-Response
1174	tcp/udp	fnet-remote-ui	FlashNet Remote Admin
1175	tcp/udp	dossier	Dossier Server
1176	tcp/udp	indigo-server	Indigo Home Server
1177	tcp/udp	dkmessenger	DKMessenger Protocol
1178	tcp/udp	sgi-storman	SGI Storage Manager
1179	tcp/udp	b2n	Backup To Neighbor
1170 	tcp 	# 	Psyber Stream Server PSS,
Streaming Audio Server, Voice
1180	tcp/udp	mc-client	Millicent Client Proxy
1181	tcp/udp	3comnetman	3Com Net Management
1182	tcp/udp	accelenet	AcceleNet Control
1183	tcp/udp	llsurfup-http	LL Surfup HTTP
1184	tcp/udp	llsurfup-https	LL Surfup HTTPS
1185	tcp/udp	catchpole	Catchpole port
1186	tcp/udp	mysql-cluster	MySQL Cluster Manager
1187	tcp/udp	alias	Alias Service
1188	tcp/udp	hp-webadmin	HP Web Admin
1189	tcp/udp	unet	Unet Connection
1190	tcp/udp	commlinx-avl	CommLinx GPS / AVL System
1191	tcp/udp	gpfs	General Parallel File System
1192	tcp/udp	caids-sensor	caids sensors channel
1193	tcp/udp	fiveacross	Five Across Server
1194	tcp/udp	openvpn	OpenVPN
1195	tcp/udp	rsf-1	RSF-1 clustering
1196-1198	tcp/udp	#	Unassigned
1192 	tcp 	# 	Lovgate
1199	tcp/udp	dmidi	DMIDI
1200	tcp/udp	scol	SCOL
1200-1201 	udp 	# 	NoBackO
1201	tcp/udp	nucleus-sand	Nucleus Sand
1202	tcp/udp	caiccipc	caiccipc
1203	tcp/udp	ssslic-mgr	License Validation
1204	tcp/udp	ssslog-mgr	Log Request Listener
1205	tcp/udp	accord-mgc	Accord-MGC
1206	tcp/udp	anthony-data	Anthony Data
1207	tcp/udp	metasage	MetaSage
1207 	tcp 	# 	SoftWAR
1208	tcp/udp	seagull-ais	SEAGULL AIS
1208 	tcp 	# 	Infector
1209	tcp/udp	ipcd3	IPCD3
1210	tcp/udp	eoss	EOSS
1211	tcp/udp	groove-dpp	Groove DPP
1212	tcp/udp	lupa	lupa
1212 	tcp 	# 	Kaos
1213	tcp/udp	mpc-lifenet	MPC LIFENET
1214	tcp/udp	kazaa	KAZAA
1215	tcp/udp	scanstat-1	scanSTAT 1.0
1216	tcp/udp	etebac5	ETEBAC 5
1217	tcp/udp	hpss-ndapi	HPSS-NDAPI
1218	tcp/udp	aeroflight-ads	AeroFlight-ADs
1218 	tcp/udp 	# 	Feardoor
1219	tcp/udp	aeroflight-ret	AeroFlight-Ret
1219 	tcp/udp 	# 	Feardoor
1220	tcp/udp	qt-serveradmin	QT SERVER ADMIN
1221	tcp/udp	sweetware-apps	SweetWARE Apps
1222	tcp/udp	nerv	SNI R&D network
1223	tcp/udp	tgp	TGP
1224	tcp/udp	vpnz	VPNz
1225	tcp/udp	slinkysearch	SLINKYSEARCH
1226	tcp/udp	stgxfws	STGXFWS
1227	tcp/udp	dns2go	DNS2Go
1228	tcp/udp	florence	FLORENCE
1229	tcp/udp	novell-zfs	Novell ZFS
1230	tcp/udp	periscope	Periscope
1231	tcp/udp	menandmice-lpm	menandmice-lpm
1233	tcp/udp	univ-appserver	Universal App Server
1234	tcp/udp	search-agent	Infoseek Search Agent
1234 	tcp/udp 	# 	The bindshell.c program puts a backdoor
root shell on this port by default.
This assumes that you've already been
compromised by some other exploit and
that the hacker uses the default port.
1234 	tcp 	# 	SubSeven Java client, Ultors Trojan,
W32.Beagle
1235	tcp/udp	mosaicsyssvc1	mosaicsyssvc1
1236	tcp/udp	bvcontrol	bvcontrol
1237	tcp/udp	tsdos390	tsdos390
1238	tcp/udp	hacl-qs	hacl-qs
1239	tcp/udp	nmsd	NMSD
1240	tcp/udp	instantia	Instantia
1241	tcp/udp	nessus	nessus
1242	tcp/udp	nmasoverip	NMAS over IP
1243	tcp/udp	serialgateway	SerialGateway
1243 	tcp 	#	BackDoor-G, SubSeven,
SubSeven Apocalypse, Tiles
1244	tcp/udp	isbconference1	isbconference1
1245	tcp/udp	isbconference2	isbconference2
1245 	tcp 	# 	VooDoo Doll
1246	tcp/udp	payrouter	payrouter
1247	tcp/udp	visionpyramid	VisionPyramid
1248	tcp/udp	hermes	hermes
1249	tcp/udp	mesavistaco	Mesa Vista Co
1250	tcp/udp	swldy-sias	swldy-sias
1250 	tcp 	# 	W32.Explet
1251	tcp/udp	servergraph	servergraph
1252	tcp/udp	bspne-pcc	bspne-pcc
1253	tcp/udp	q55-pcc	q55-pcc
1254	tcp/udp	de-noc	de-noc
1255	tcp/udp	de-cache-query	de-cache-query
1255 	tcp 	# 	Scarab
1256	tcp/udp	de-server	de-server
1256 	tcp 	# 	Project nEXT
1257	tcp/udp	shockwave2	Shockwave 2
1258	tcp/udp	opennl	Open Network Library
1259	tcp/udp	opennl-voice	Open Network Library Voice
1260	tcp/udp	ibm-ssd	ibm-ssd
1261	tcp/udp	mpshrsv	mpshrsv
1262	tcp/udp	qnts-orb	QNTS-ORB
1263	tcp/udp	dka	dka
1264	tcp/udp	prat	PRAT
1265	tcp/udp	dssiapi	DSSIAPI
1266	tcp/udp	dellpwrappks	DELLPWRAPPKS
1267	tcp/udp	epc	eTrust Policy Compliance
1268	tcp/udp	propel-msgsys	PROPEL-MSGSYS
1269	tcp/udp	watilapp	WATiLaPP
1269 	tcp 	# 	Matrix
1270	tcp/udp	opsmgr	Microsoft Operations Manager
1271	tcp/udp	excw	eXcW
1272	tcp/udp	cspmlockmgr	CSPMLockMgr
1272 	tcp 	# 	The Matrix
1273	tcp/udp	emc-gateway	EMC-Gateway
1274	tcp/udp	t1distproc	t1distproc
1275	tcp/udp	ivcollector	ivcollector
1276	tcp/udp	ivmanager	ivmanager
1277	tcp/udp	miva-mqs	mqs
1278	tcp/udp	dellwebadmin-1	Dell Web Admin 1
1279	tcp/udp	dellwebadmin-2	Dell Web Admin 2
1280	tcp/udp	pictrography	Pictrography
1281	tcp/udp	healthd	healthd
1282	tcp/udp	emperion	Emperion
1283	tcp/udp	productinfo	ProductInfo
1284	tcp/udp	iee-qfx	IEE-QFX
1285	tcp/udp	neoiface	neoiface
1286	tcp/udp	netuitive	netuitive
1287	tcp/udp	#	Unassigned
1288	tcp/udp	navbuddy	NavBuddy
1289	tcp/udp	jwalkserver	JWalkServer
1290	tcp/udp	winjaserver	WinJaServer
1291	tcp/udp	seagulllms	SEAGULLLMS
1292	tcp/udp	dsdn	dsdn
1293	tcp/udp	pkt-krb-ipsec	PKT-KRB-IPSec
1294	tcp/udp	cmmdriver	CMMdriver
1295	tcp/udp	ehtp	End-by-Hop Transmission Protocol
1296	tcp/udp	dproxy	dproxy
1297	tcp/udp	sdproxy	sdproxy
1298	tcp/udp	lpcp	lpcp
1299	tcp/udp	hp-sci	hp-sci
1300	tcp/udp	h323hostcallsc	H323 Host Call Secure
1301	tcp/udp	ci3-software-1	CI3-Software-1
1302	tcp/udp	ci3-software-2	CI3-Software-2
1303	tcp/udp	sftsrv	sftsrv
1304	tcp/udp	boomerang	Boomerang
1305	tcp/udp	pe-mike	pe-mike
1306	tcp/udp	re-conn-proto	RE-Conn-Proto
1307	tcp/udp	pacmand	Pacmand
1308	tcp/udp	odsi	Optical Domain Service Interconnect (ODSI)
1309	tcp/udp	jtag-server	JTAG server
1309 	tcp 	# 	Jittar
1310	tcp/udp	husky	Husky
1311	tcp/udp	rxmon	RxMon
1312	tcp/udp	sti-envision	STI Envision
1313	tcp/udp	bmc_patroldb	BMC_PATROLDB
1313 	tcp 	# 	NETrojan
1314	tcp/udp	pdps	Photoscript Distributed Printing System
1315	tcp/udp	els	"E.L.S., Event Listener Service"
1316	tcp/udp	exbit-escp	Exbit-ESCP
1317	tcp/udp	vrts-ipcserver	vrts-ipcserver
1318	tcp/udp	krb5gatekeeper	krb5gatekeeper
1319	tcp/udp	panja-icsp	Panja-ICSP
1320	tcp/udp	panja-axbnet	Panja-AXBNET
1321	tcp/udp	pip	PIP
1322	tcp/udp	novation	Novation
1323	tcp/udp	brcd	brcd
1324	tcp/udp	delta-mcp	delta-mcp
1325	tcp/udp	dx-instrument	DX-Instrument
1326	tcp/udp	wimsic	WIMSIC
1327	tcp/udp	ultrex	Ultrex
1328	tcp/udp	ewall	EWALL
1329	tcp/udp	netdb-export	netdb-export
1330	tcp/udp	streetperfect	StreetPerfect
1331	tcp/udp	intersan	intersan
1332	tcp/udp	pcia-rxp-b	PCIA RXP-B
1333	tcp/udp	passwrd-policy	Password Policy
1334	tcp/udp	writesrv	writesrv
1335	tcp/udp	digital-notary	Digital Notary Protocol
1336	tcp/udp	ischat	Instant Service Chat
1337	tcp/udp	menandmice-dns	menandmice DNS
1337 	tcp/udp 	# 	OptixPro
1338	tcp/udp	wmc-log-svc	WMC-log-svr
1338 	tcp/udp 	# 	Millennium Worm
TCP backdoor created by the Millennium Worm
1339	tcp/udp	kjtsiteserver	kjtsiteserver
1340	tcp/udp	naap	NAAP
1341	tcp/udp	qubes	QuBES
1342	tcp/udp	esbroker	ESBroker
1343	tcp/udp	re101	re101
1344	tcp/udp	icap	ICAP
1345	tcp/udp	vpjp	VPJP
1346	tcp/udp	alta-ana-lm	Alta Analytics License Manager
1347	tcp/udp	bbn-mmc	multi media conferencing
1348	tcp/udp	bbn-mmx	multi media conferencing
1349	tcp/udp	sbook	Registration Network Protocol
1349 	tcp 	# 	Bo dll
1350	tcp/udp	editbench	Registration Network Protocol
1351	tcp/udp	equationbuilder	Digital Tool Works (MIT)
1352	tcp/udp	lotusnote	Lotus Note
1353	tcp/udp	relief	Relief Consulting
1354	tcp/udp	XSIP-network	Five Across XSIP Network
1355	tcp/udp	intuitive-edge	Intuitive Edge
1357	tcp/udp	pegboard	Electronic PegBoard
1358	tcp/udp	connlcli	CONNLCLI
1359	tcp/udp	ftsrv	FTSRV
1360	tcp/udp	mimer	MIMER
1361	tcp/udp	linx	LinX
1362	tcp/udp	timeflies	TimeFlies
1363	tcp/udp	ndm-requester	Network DataMover Requester
1364	tcp/udp	ndm-server	Network DataMover Server
1365	tcp/udp	adapt-sna	Network Software Associates
1366	tcp/udp	netware-csp	Novell NetWare Comm Service Platform
1367	tcp/udp	dcs	DCS
1368	tcp/udp	screencast	ScreenCast
1369	tcp/udp	gv-us	GlobalView to Unix Shell
1370	tcp/udp	us-gv	Unix Shell to GlobalView
1371	tcp/udp	fc-cli	Fujitsu Config Protocol
1372	tcp/udp	fc-ser	Fujitsu Config Protocol
1373	tcp/udp	chromagrafx	Chromagrafx
1374	tcp/udp	molly	EPI Software Systems
1375	tcp/udp	bytex	Bytex
1376	tcp/udp	ibm-pps	IBM Person to Person Software
1377	tcp/udp	cichlid	Cichlid License Manager
1378	tcp/udp	elan	Elan License Manager
1379	tcp/udp	dbreporter	Integrity Solutions
1380	tcp/udp	telesis-licman	Telesis Network License Manager
1381	tcp/udp	apple-licman	Apple Network License Manager
1382	tcp/udp	udt_os	udt_os
1383	tcp/udp	gwha	GW Hannaway Network License Manager
1384	tcp/udp	os-licman	Objective Solutions License Manager
1385	tcp/udp	atex_elmd	Atex Publishing License Manager
1386	tcp/udp	checksum	CheckSum License Manager
1387	tcp/udp	cadsi-lm	Computer Aided Design Software Inc LM
1388	tcp/udp	objective-dbc	Objective Solutions DataBase Cache
1389	tcp/udp	iclpv-dm	Document Manager
1390	tcp/udp	iclpv-sc	Storage Controller
1391	tcp/udp	iclpv-sas	Storage Access Server
1392	tcp/udp	iclpv-pm	Print Manager
1393	tcp/udp	iclpv-nls	Network Log Server
1394	tcp/udp	iclpv-nlc	Network Log Client
1394 	tcp 	# 	GoFriller, Backdoor G-1
1395	tcp/udp	iclpv-wsm	PC Workstation Manager software
1396	tcp/udp	dvl-activemail	DVL Active Mail
1397	tcp/udp	audio-activmail	Audio Active Mail
1398	tcp/udp	video-activmail	Video Active Mail
1399	tcp/udp	cadkey-licman	Cadkey License Manager
1400	tcp/udp	cadkey-tablet	Cadkey Tablet Daemon
1401	tcp/udp	goldleaf-licman	Goldleaf License Manager
1402	tcp/udp	prm-sm-np	Prospero Resource Manager
1403	tcp/udp	prm-nm-np	Prospero Resource Manager
1404	tcp/udp	igi-lm	Infinite Graphics License Manager
1405	tcp/udp	ibm-res	IBM Remote Execution Starter
1406	tcp/udp	netlabs-lm	NetLabs License Manager
1407	tcp/udp	dbsa-lm	DBSA License Manager
1408	tcp/udp	sophia-lm	Sophia License Manager
1409	tcp/udp	here-lm	Here License Manager
1409 	tcp/udp 	# 	IRC.Bifrut
1410	tcp/udp	hiq	HiQ License Manager
1411	tcp/udp	af	AudioFile
1412	tcp/udp	innosys	InnoSys
1413	tcp/udp	innosys-acl	Innosys-ACL
1414	tcp/udp	ibm-mqseries	IBM MQSeries
1415	tcp/udp	dbstar	DBStar
1416	tcp/udp	novell-lu6.2	Novell LU6.2
1417	tcp/udp	timbuktu-srv1	Timbuktu Service 1 Port
1418	tcp/udp	timbuktu-srv2	Timbuktu Service 2 Port
1419	tcp/udp	timbuktu-srv3	Timbuktu Service 3 Port
1420	tcp/udp	timbuktu-srv4	Timbuktu Service 4 Port
1421	tcp/udp	gandalf-lm	Gandalf License Manager
1422	tcp/udp	autodesk-lm	Autodesk License Manager
1423	tcp/udp	essbase	Essbase Arbor Software
1424	tcp/udp	hybrid	Hybrid Encryption Protocol
1425	tcp/udp	zion-lm	Zion Software License Manager
1426	tcp/udp	sais	Satellite-data Acquisition System 1
1427	tcp/udp	mloadd	mloadd monitoring tool
1428	tcp/udp	informatik-lm	Informatik License Manager
1429	tcp/udp	nms	Hypercom NMS
1430	tcp/udp	tpdu	Hypercom TPDU
1431	tcp/udp	rgtp	Reverse Gossip Transport
1432	tcp/udp	blueberry-lm	Blueberry Software License Manager
1433	tcp/udp	ms-sql-s	Microsoft-SQL-Server
1434	tcp/udp	ms-sql-m	Microsoft-SQL-Monitor
1434 	tcp/udp 	# 	W32.SQLExp.Worm, W32.Spybot
1434 	udp 	# 	W32.Gaobot
1435	tcp/udp	ibm-cics	IBM CICS
1436	tcp/udp	saism	Satellite-data Acquisition System 2
1437	tcp/udp	tabula	Tabula
1438	tcp/udp	eicon-server	Eicon Security Agent/Server
1439	tcp/udp	eicon-x25	Eicon X25/SNA Gateway
1440	tcp/udp	eicon-slp	Eicon Service Location Protocol
1441	tcp/udp	cadis-1	Cadis License Management
1441 	tcp 	# 	Remote Storm
1442	tcp/udp	cadis-2	Cadis License Management
1443	tcp/udp	ies-lm	Integrated Engineering Software
1444	tcp/udp	marcam-lm	Marcam License Management
1445	tcp/udp	proxima-lm	Proxima License Manager
1446	tcp/udp	ora-lm	Optical Research Associates License Manager
1447	tcp/udp	apri-lm	Applied Parallel Research LM
1448	tcp/udp	oc-lm	OpenConnect License Manager
1449	tcp/udp	peport	PEport
1450	tcp/udp	dwf	Tandem Distributed Workbench Facility
1451	tcp/udp	infoman	IBM Information Management
1452	tcp/udp	gtegsc-lm	GTE Government Systems License Man
1453	tcp/udp	genie-lm	Genie License Manager
1454	tcp/udp	interhdl_elmd	interHDL License Manager
1455	tcp/udp	esl-lm	ESL License Manager
1456	tcp/udp	dca	DCA
1457	tcp/udp	valisys-lm	Valisys License Manager
1458	tcp/udp	nrcabq-lm	Nichols Research Corp.
1459	tcp/udp	proshare1	Proshare Notebook Application
1460	tcp/udp	proshare2	Proshare Notebook Application
1461	tcp/udp	ibm_wrless_lan	IBM Wireless LAN
1462	tcp/udp	world-lm	World License Manager
1463	tcp/udp	nucleus	Nucleus
1464	tcp/udp	msl_lmd	MSL License Manager
1465	tcp	pipes	Pipes Platform
1465	udp	pipes	Pipes Platform mfarlin@peerlogic.com
1466	tcp/udp	oceansoft-lm	Ocean Software License Manager
1467	tcp/udp	csdmbase	CSDMBASE
1468	tcp/udp	csdm	CSDM
1469	tcp/udp	aal-lm	Active Analysis Limited License Manager
1470	tcp/udp	uaiact	Universal Analytics
1471	tcp/udp	csdmbase	csdmbase
1472	tcp/udp	csdm	csdm
1473	tcp/udp	openmath	OpenMath
1474	tcp/udp	telefinder	Telefinder
1475	tcp/udp	taligent-lm	Taligent License Manager
1476	tcp/udp	clvm-cfg	clvm-cfg
1477	tcp/udp	ms-sna-server	ms-sna-server
1478	tcp/udp	ms-sna-base	ms-sna-base
1479	tcp/udp	dberegister	dberegister
1480	tcp/udp	pacerforum	PacerForum
1481	tcp/udp	airs	AIRS
1482	tcp/udp	miteksys-lm	Miteksys License Manager
1483	tcp/udp	afs	AFS License Manager
1484	tcp/udp	confluent	Confluent License Manager
1485	tcp/udp	lansource	LANSource
1486	tcp/udp	nms_topo_serv	nms_topo_serv
1487	tcp/udp	localinfosrvr	LocalInfoSrvr
1488	tcp/udp	docstor	DocStor
1489	tcp/udp	dmdocbroker	dmdocbroker
1490	tcp/udp	insitu-conf	insitu-conf
1490 	tcp 	# 	VocalTec Internet Phone
TCP connection for the Conference
engine supporting whiteboard/chat/file transfer.
1491	tcp/udp	anynetgateway	anynetgateway
1491 	tcp 	# 	W32.Spybot
1492	tcp/udp	stone-design-1	stone-design-1
1492 	tcp 	# 	FTP99CMP
1493	tcp/udp	netmap_lm	netmap_lm
1494	tcp/udp	ica	ica
1495	tcp/udp	cvc	cvc
1496	tcp/udp	liberty-lm	liberty-lm
1497	tcp/udp	rfx-lm	rfx-lm
1498	tcp/udp	sybase-sqlany	Sybase SQL Any
1499	tcp/udp	fhc	Federico Heinz Consultora
1500	tcp/udp	vlsi-lm	VLSI License Manager
1500 	tcp 	# 	ADSM/Tivoli Storage Manager (backup software) default port
1501	tcp/udp	saiscm	Satellite-data Acquisition System 3
1502	tcp/udp	shivadiscovery	Shiva
1503	tcp/udp	imtc-mcs	Databeam
1503 	tcp/udp 	# 	T.120 teleconferencing protocol
1504	tcp/udp	evb-elm	EVB Software Engineering License Manager
1505	tcp/udp	funkproxy	"Funk Software, Inc."
1506	tcp/udp	utcd	Universal Time daemon (utcd)
1507	tcp/udp	symplex	symplex
1508	tcp/udp	diagmond	diagmond
1509	tcp/udp	robcad-lm	"Robcad, Ltd. License Manager"
1510	tcp/udp	mvx-lm	Midland Valley Exploration Ltd. Lic. Man.
1511	tcp/udp	3l-l1	3l-l1
1512	tcp/udp	wins	Microsoft's Windows Internet Name Service
1513	tcp/udp	fujitsu-dtc	"Fujitsu Systems Business of America, Inc"
1514	tcp/udp	fujitsu-dtcns	"Fujitsu Systems Business of America, Inc"
1515	tcp/udp	ifor-protocol	ifor-protocol
1516	tcp/udp	vpad	Virtual Places Audio data
1517	tcp/udp	vpac	Virtual Places Audio control
1518	tcp/udp	vpvd	Virtual Places Video data
1519	tcp/udp	vpvc	Virtual Places Video control
1520	tcp/udp	atm-zip-office	atm zip office
1521	tcp/udp	ncube-lm	nCube License Manager
1521 	tcp/udp 	# 	Oracle SQL defaults to listening at this port (SQL*Net v2.x)
1522	tcp/udp	ricardo-lm	Ricardo North America License Manager
1522 	tcp/udp 	# 	Oracle SqlNet 2
1523	tcp/udp	cichild-lm	cichild
1524	tcp/udp	ingreslock	ingres
1524 	tcp 	# 	Trinoo
1525	tcp/udp	orasrv	oracle
1525	tcp/udp	prospero-np	Prospero Directory Service non-priv
1526	tcp/udp	pdap-np	Prospero Data Access Prot non-priv
1527	tcp/udp	tlisrv	oracle
1528	tcp/udp	mciautoreg	micautoreg
1529	tcp/udp	coauthor	oracle
1530	tcp/udp	rap-service	rap-service
1531	tcp/udp	rap-listen	rap-listen
1532	tcp/udp	miroconnect	miroconnect
1533	tcp/udp	virtual-places	Virtual Places Software
1533 	tcp/udp 	# 	Miffice
1534	tcp/udp	micromuse-lm	micromuse-lm
1534 	tcp/udp 	# 	W32.Bizex
1535	tcp/udp	ampr-info	ampr-info
1536	tcp/udp	ampr-inter	ampr-inter
1537	tcp/udp	sdsc-lm	isi-lm
1538	tcp/udp	3ds-lm	3ds-lm
1539	tcp/udp	intellistor-lm	Intellistor License Manager
1540	tcp/udp	rds	rds
1541	tcp/udp	rds2	rds2
1542	tcp/udp	gridgen-elmd	gridgen-elmd
1543	tcp/udp	simba-cs	simba-cs
1544	tcp/udp	aspeclmd	aspeclmd
1545	tcp/udp	vistium-share	vistium-share
1546	udp	abbaccuray	abbaccuray
1547	tcp/udp	laplink	laplink
1548	tcp/udp	axon-lm	Axon License Manager
1549	tcp	shivahose	Shiva Hose
1549	udp	shivasound	Shiva Sound
1550	tcp/udp	3m-image-lm	Image Storage license manager 3M Company
1551	tcp/udp	hecmtl-db	HECMTL-DB
1552	tcp/udp	pciarray	pciarray
1553	tcp/udp	sna-cs	sna-cs
1554	tcp/udp	caci-lm	CACI Products Company License Manager
1555	tcp/udp	livelan	livelan
1556	tcp/udp	veritas_pbx	VERITAS Private Branch Exchange
1557	tcp/udp	arbortext-lm	ArborText License Manager
1558	tcp/udp	xingmpeg	xingmpeg
1559	tcp/udp	web2host	web2host
1560	tcp/udp	asci-val	ASCI-RemoteSHADOW
1561	tcp/udp	facilityview	facilityview
1562	tcp/udp	pconnectmgr	pconnectmgr
1563	tcp/udp	cadabra-lm	Cadabra License Manager
1564	tcp/udp	pay-per-view	Pay-Per-View
1565	tcp/udp	winddlb	WinDD
1566	tcp/udp	corelvideo	CORELVIDEO
1567	tcp/udp	jlicelmd	jlicelmd
1568	tcp/udp	tsspmap	tsspmap
1568 	tcp 	# 	Remote Hack
1569	tcp/udp	ets	ets
1570	tcp/udp	orbixd	orbixd
1571	tcp/udp	rdb-dbs-disp	Oracle Remote Data Base
1572	tcp/udp	chip-lm	Chipcom License Manager
1573	tcp/udp	itscomm-ns	itscomm-ns
1574	tcp/udp	mvel-lm	mvel-lm
1575	tcp/udp	oraclenames	oraclenames
1576	tcp/udp	moldflow-lm	moldflow-lm
1577	tcp/udp	hypercube-lm	hypercube-lm
1578	tcp/udp	jacobus-lm	Jacobus License Manager
1579	tcp/udp	ioc-sea-lm	ioc-sea-lm
1580	tcp	tn-tl-r1	tn-tl-r1
1580	udp	tn-tl-r2	tn-tl-r2
1581	tcp/udp	mil-2045-47001	MIL-2045-47001
1582	tcp/udp	msims	MSIMS
1583	tcp/udp	simbaexpress	simbaexpress
1584	tcp/udp	tn-tl-fd2	tn-tl-fd2
1585	tcp/udp	intv	intv
1586	tcp/udp	ibm-abtact	ibm-abtact
1587	tcp/udp	pra_elmd	pra_elmd
1588	tcp/udp	triquest-lm	triquest-lm
1589	tcp/udp	vqp	VQP
1590	tcp/udp	gemini-lm	gemini-lm
1591	tcp/udp	ncpm-pm	ncpm-pm
1592	tcp/udp	commonspace	commonspace
1593	tcp/udp	mainsoft-lm	mainsoft-lm
1594	tcp/udp	sixtrak	sixtrak
1595	tcp/udp	radio	radio
1596	tcp	radio-sm	radio-sm
1596	udp	radio-bc	radio-bc
1597	tcp/udp	orbplus-iiop	orbplus-iiop
1598	tcp/udp	picknfs	picknfs
1599	tcp/udp	simbaservices	simbaservices
1600	tcp/udp	issd	 
1600 	tcp 	# 	Direct Connection, Shivka-Burka
1601	tcp/udp	aas	aas
1602	tcp/udp	inspect	inspect
1603	tcp/udp	picodbc	pickodbc
1604	tcp/udp	icabrowser	icabrowser
1605	tcp/udp	slp	Salutation Manager (Salutation Protocol)
1606	tcp/udp	slm-api	Salutation Manager (SLM-API)
1607	tcp/udp	stt	stt
1608	tcp/udp	smart-lm	Smart Corp. License Manager
1609	tcp/udp	isysg-lm	isysg-lm
1610	tcp/udp	taurus-wh	taurus-wh
1611	tcp/udp	ill	Inter Library Loan
1612	tcp/udp	netbill-trans	NetBill Transaction Server
1613	tcp/udp	netbill-keyrep	NetBill Key Repository
1614	tcp/udp	netbill-cred	NetBill Credential Server
1615	tcp/udp	netbill-auth	NetBill Authorization Server
1616	tcp/udp	netbill-prod	NetBill Product Server
1617	tcp/udp	nimrod-agent	Nimrod Inter-Agent Communication
1618	tcp/udp	skytelnet	skytelnet
1619	tcp/udp	xs-openstorage	xs-openstorage
1620	tcp/udp	faxportwinport	faxportwinport
1621	tcp/udp	softdataphone	softdataphone
1622	tcp/udp	ontime	ontime
1623	tcp/udp	jaleosnd	jaleosnd
1624	tcp/udp	udp-sr-port	udp-sr-port
1625	tcp/udp	svs-omagent	svs-omagent
1626	tcp/udp	shockwave	Shockwave
1627	tcp/udp	t128-gateway	T.128 Gateway
1628	tcp/udp	lontalk-norm	LonTalk normal
1629	tcp/udp	lontalk-urgnt	LonTalk urgent
1630	tcp/udp	oraclenet8cman	Oracle Net8 Cman
1631	tcp/udp	visitview	Visit view
1632	tcp/udp	pammratc	PAMMRATC
1633	tcp/udp	pammrpc	PAMMRPC
1634	tcp/udp	loaprobe	Log On America Probe
1635	tcp/udp	edb-server1	EDB Server 1
1636	tcp/udp	cncp	CableNet Control Protocol
1637	tcp/udp	cnap	CableNet Admin Protocol
1638	tcp/udp	cnip	CableNet Info Protocol
1639	tcp/udp	cert-initiator	cert-initiator
1639 	tcp/udp 	# 	W32.Mydoom, W32.Bofra
1640	tcp/udp	cert-responder	cert-responder
1640 	tcp/udp 	# 	W32.Bofra
1641	tcp/udp	invision	InVision
1642	tcp/udp	isis-am	isis-am
1643	tcp/udp	isis-ambc	isis-ambc
1644	tcp	saiseh	Satellite-data Acquisition System 4
1645	tcp/udp	sightline	SightLine
1645 	tcp/udp 	# 	Remote Authentication Dial In User Service (RADIUS)
RADIUS, or Remote Authentication Dial-In User service,
is a freely available distributed security system developed
by Lucent Technologies InterNetworking Systems. Lucent
has worked with the Internet Engineering Task Force (IETF)
to define RADIUS as an interoperable method for distributed
security on the Internet. RADIUS was designed based on
a previous recommendation from the IETF's Network
Access Server Working Requirements Group.
1646	tcp/udp	sa-msg-port	sa-msg-port
1646	udp	#	Remote Authentication Dial In User Service (RADIUS)
RADIUS accounting consists of an accounting server
and accounting clients (Lucent (formerly Livingston
Enterprises)PortMaster products). RADIUS accounting
starts automatically when the RADIUS server starts.
On a UNIX host, the radiusd accounting daemon is a
child process of the radiusd authentication daemon.
The RADIUS accounting server uses the User
Datagram Protocol (UDP), and listens for UDP
packets at port 1646 by default.
1647	tcp/udp	rsap	rsap
1648	tcp/udp	concurrent-lm	concurrent-lm
1649	tcp/udp	kermit	kermit
1650	tcp	nkd	nkdn
1650	udp	nkd	nkd
1651	tcp/udp	shiva_confsrvr	shiva_confsrvr
1652	tcp/udp	xnmp	xnmp
1653	tcp/udp	alphatech-lm	alphatech-lm
1654	tcp/udp	stargatealerts	stargatealerts
1655	tcp/udp	dec-mbadmin	dec-mbadmin
1656	tcp/udp	dec-mbadmin-h	dec-mbadmin-h
1657	tcp/udp	fujitsu-mmpdc	fujitsu-mmpdc
1658	tcp/udp	sixnetudr	sixnetudr
1659	tcp/udp	sg-lm	Silicon Grail License Manager
1660	tcp/udp	skip-mc-gikreq	skip-mc-gikreq
1661	tcp/udp	netview-aix-1	netview-aix-1
1662	tcp/udp	netview-aix-2	netview-aix-2
1663	tcp/udp	netview-aix-3	netview-aix-3
1664	tcp/udp	netview-aix-4	netview-aix-4
1665	tcp/udp	netview-aix-5	netview-aix-5
1666	tcp/udp	netview-aix-6	netview-aix-6
1667	tcp/udp	netview-aix-7	netview-aix-7
1668	tcp/udp	netview-aix-8	netview-aix-8
1669	tcp/udp	netview-aix-9	netview-aix-9
1670	tcp/udp	netview-aix-10	netview-aix-10
1671	tcp/udp	netview-aix-11	netview-aix-11
1672	tcp/udp	netview-aix-12	netview-aix-12
1673	tcp/udp	proshare-mc-1	Intel Proshare Multicast
1674	tcp/udp	proshare-mc-2	Intel Proshare Multicast
1675	tcp/udp	pdp	Pacific Data Products
1676	tcp	netcomm1	netcomm1
1676	udp	netcomm2	netcomm2
1677	tcp/udp	groupwise	groupwise
1678	tcp/udp	prolink	prolink
1679	tcp/udp	darcorp-lm	darcorp-lm
1680	tcp/udp	microcom-sbp	microcom-sbp
1680 	tcp/udp 	# 	Carbon Copy v5.0
Carbon Copy is a remote control and file
transfer software package that available
for use under the Microsoft Windows Environment.
1681	tcp/udp	sd-elmd	sd-elmd
1682	tcp/udp	lanyon-lantern	lanyon-lantern
1683	tcp/udp	ncpm-hip	ncpm-hip
1684	tcp/udp	snaresecure	SnareSecure
1685	tcp/udp	n2nremote	n2nremote
1686	tcp/udp	cvmon	cvmon
1687	tcp/udp	nsjtp-ctrl	nsjtp-ctrl
1688	tcp/udp	nsjtp-data	nsjtp-data
1689	tcp/udp	firefox	firefox
1690	tcp/udp	ng-umds	ng-umds
1691	tcp/udp	empire-empuma	empire-empuma
1692	tcp/udp	sstsys-lm	sstsys-lm
1693	tcp/udp	rrirtr	rrirtr
1694	tcp/udp	rrimwm	rrimwm
1695	tcp/udp	rrilwm	rrilwm
1696	tcp/udp	rrifmm	rrifmm
1697	tcp/udp	rrisat	rrisat
1698	tcp/udp	rsvp-encap-1	RSVP-ENCAPSULATION-1
1699	tcp/udp	rsvp-encap-2	RSVP-ENCAPSULATION-2
1700	tcp/udp	mps-raft	mps-raft
1700 	tcp/udp 	# 	Udps, NetHasp
1701	tcp/udp	l2f	l2f
1701	tcp/udp	l2tp	l2tp
1702	tcp/udp	deskshare	deskshare
1703	tcp/udp	hb-engine	hb-engine
1703 	tcp 	# 	Exploiter
1704	tcp/udp	bcs-broker	bcs-broker
1705	tcp/udp	slingshot	slingshot
1706	tcp/udp	jetform	jetform
1707	tcp/udp	vdmplay	vdmplay
1708	tcp/udp	gat-lmd	gat-lmd
1709	tcp/udp	centra	centra
1710	tcp/udp	impera	impera
1711	tcp/udp	pptconference	pptconference
1712	tcp/udp	registrar	resource monitoring service
1713	tcp/udp	conferencetalk	ConferenceTalk
1714	tcp/udp	sesi-lm	sesi-lm
1715	tcp/udp	houdini-lm	houdini-lm
1716	tcp/udp	xmsg	xmsg
1717	tcp/udp	fj-hdnet	fj-hdnet
1717 	tcp/udp 	# 	Microsoft Convoy
1718	tcp/udp	h323gatedisc	h323gatedisc
1719	tcp/udp	h323gatestat	h323gatestat
1720	tcp/udp	h323hostcall	h323hostcall
1721	tcp/udp	caicci	caicci
1722	tcp/udp	hks-lm	HKS License Manager
1723	tcp/udp	pptp	pptp
1724	tcp/udp	csbphonemaster	csbphonemaster
1725	tcp/udp	iden-ralp	iden-ralp
1726	tcp/udp	iberiagames	IBERIAGAMES
1727	tcp/udp	winddx	winddx
1728	tcp/udp	telindus	TELINDUS
1729	tcp/udp	citynl	CityNL License Management
1730	tcp/udp	roketz	roketz
1731	tcp/udp	msiccp	MSICCP
1732	tcp/udp	proxim	proxim
1733	tcp/udp	siipat	SIMS - SIIPAT Protocol for Alarm Transmission
1734	tcp/udp	cambertx-lm	Camber Corporation License Management
1735	tcp/udp	privatechat	PrivateChat
1736	tcp/udp	street-stream	street-stream
1737	tcp/udp	ultimad	ultimad
1738	tcp/udp	gamegen1	GameGen1
1739	tcp/udp	webaccess	webaccess
1740	tcp/udp	encore	encore
1741	tcp/udp	cisco-net-mgmt	cisco-net-mgmt
1742	tcp/udp	3Com-nsd	3Com-nsd
1743	tcp/udp	cinegrfx-lm	Cinema Graphics License Manager
1744	tcp/udp	ncpm-ft	ncpm-ft
1745	tcp/udp	remote-winsock	remote-winsock
1746	tcp/udp	ftrapid-1	ftrapid-1
1747	tcp/udp	ftrapid-2	ftrapid-2
1748	tcp/udp	oracle-em1	oracle-em1
1749	tcp/udp	aspen-services	aspen-services
1750	tcp/udp	sslp	Simple Socket Library's PortMaster
1751	tcp/udp	swiftnet	SwiftNet
1752	tcp/udp	lofr-lm	Leap of Faith Research License Manager
1753	tcp/udp	#	Unassigned
1754	tcp/udp	oracle-em2	oracle-em2
1755	tcp/udp	ms-streaming	ms-streaming
1756	tcp/udp	capfast-lmd	capfast-lmd
1757	tcp/udp	cnhrp	cnhrp
1758	tcp/udp	tftp-mcast	tftp-mcast
1759	tcp/udp	spss-lm	SPSS License Manager
1760	tcp/udp	www-ldap-gw	www-ldap-gw
1761	tcp/udp	cft-0	cft-0
1761 	udp 	# 	SMS v1.2 wuser32.exe
1762	tcp/udp	cft-1	cft-1
1762 	udp 	# 	SMS v1.2 wuser32.exe
1763	tcp/udp	cft-2	cft-2
1764	tcp/udp	cft-3	cft-3
1765	tcp/udp	cft-4	cft-4
1766	tcp/udp	cft-5	cft-5
1767	tcp/udp	cft-6	cft-6
1768	tcp/udp	cft-7	cft-7
1769	tcp/udp	bmc-net-adm	bmc-net-adm
1770	tcp/udp	bmc-net-svc	bmc-net-svc
1771	tcp/udp	vaultbase	vaultbase
1772	tcp/udp	essweb-gw	EssWeb Gateway
1773	tcp/udp	kmscontrol	KMSControl
1774	tcp/udp	global-dtserv	global-dtserv
1775	tcp/udp	#	Unassigned
1776	tcp/udp	femis	Federal Emergency Management Information System
1777	tcp/udp	powerguardian	powerguardian
1777 	tcp 	# 	Scarab
1778	tcp/udp	prodigy-intrnet	prodigy-internet
1779	tcp/udp	pharmasoft	pharmasoft
1780	tcp/udp	dpkeyserv	dpkeyserv
1781	tcp/udp	answersoft-lm	answersoft-lm
1782	tcp/udp	hp-hcip	hp-hcip
1784	tcp/udp	finle-lm	Finle License Manager
1785	tcp/udp	windlm	Wind River Systems License Manager
1786	tcp/udp	funk-logger	funk-logger
1787	tcp/udp	funk-license	funk-license
1788	tcp/udp	psmond	psmond
1789	tcp/udp	hello	hello
1790	tcp/udp	nmsp	Narrative Media Streaming Protocol
1791	tcp/udp	ea1	EA1
1792	tcp/udp	ibm-dt-2	ibm-dt-2
1793	tcp/udp	rsc-robot	rsc-robot
1794	tcp/udp	cera-bcm	cera-bcm
1795	tcp/udp	dpi-proxy	dpi-proxy
1796	tcp/udp	vocaltec-admin	Vocaltec Server Administration
1797	tcp/udp	uma	UMA
1798	tcp/udp	etp	Event Transfer Protocol
1799	tcp/udp	netrisk	NETRISK
1800	tcp/udp	ansys-lm	ANSYS-License manager
1801	tcp/udp	msmq	Microsoft Message Que
1802	tcp/udp	concomp1	ConComp1
1803	tcp/udp	hp-hcip-gwy	HP-HCIP-GWY
1804	tcp/udp	enl	ENL
1805	tcp/udp	enl-name	ENL-Name
1806	tcp/udp	musiconline	Musiconline
1807	tcp/udp	fhsp	Fujitsu Hot Standby Protocol
1807 	tcp 	# 	SpySender
1808	tcp/udp	oracle-vp2	Oracle-VP2
1809	tcp/udp	oracle-vp1	Oracle-VP1
1810	tcp/udp	jerand-lm	Jerand License Manager
1811	tcp/udp	scientia-sdb	Scientia-SDB
1812	tcp/udp	radius	RADIUS
1813	tcp/udp	radius-acct	RADIUS Accounting
1814	tcp/udp	tdp-suite	TDP Suite
1815	tcp/udp	mmpft	MMPFT
1816	tcp/udp	harp	HARP
1817	tcp/udp	rkb-oscs	RKB-OSCS
1818	tcp/udp	etftp	Enhanced Trivial File Transfer Protocol
1819	tcp/udp	plato-lm	Plato License Manager
1820	tcp/udp	mcagent	mcagent
1821	tcp/udp	donnyworld	donnyworld
1822	tcp/udp	es-elmd	es-elmd
1823	tcp/udp	unisys-lm	Unisys Natural Language License Manager
1824	tcp/udp	metrics-pas	metrics-pas
1825	tcp/udp	direcpc-video	DirecPC Video
1826	tcp/udp	ardt	ARDT
1827	tcp/udp	asi	ASI
1828	tcp/udp	itm-mcell-u	itm-mcell-u
1829	tcp/udp	optika-emedia	Optika eMedia
1830	tcp/udp	net8-cman	Oracle Net8 CMan Admin
1831	tcp/udp	myrtle	Myrtle
1832	tcp/udp	tht-treasure	ThoughtTreasure
1833	tcp/udp	udpradio	udpradio
1834	tcp/udp	ardusuni	ARDUS Unicast
1835	tcp/udp	ardusmul	ARDUS Multicast
1836	tcp/udp	ste-smsc	ste-smsc
1837	tcp/udp	csoft1	csoft1
1838	tcp/udp	talnet	TALNET
1839	tcp/udp	netopia-vo1	netopia-vo1
1840	tcp/udp	netopia-vo2	netopia-vo2
1841	tcp/udp	netopia-vo3	netopia-vo3
1842	tcp/udp	netopia-vo4	netopia-vo4
1843	tcp/udp	netopia-vo5	netopia-vo5
1844	tcp/udp	direcpc-dll	DirecPC-DLL
1845	tcp/udp	altalink	altalink
1846	tcp/udp	tunstall-pnc	Tunstall PNC
1847	tcp/udp	slp-notify	SLP Notification
1848	tcp/udp	fjdocdist	fjdocdist
1849	tcp/udp	alpha-sms	ALPHA-SMS
1850	tcp/udp	gsi	GSI
1851	tcp/udp	ctcd	ctcd
1852	tcp/udp	virtual-time	Virtual Time
1853	tcp/udp	vids-avtp	VIDS-AVTP
1854	tcp/udp	buddy-draw	Buddy Draw
1855	tcp/udp	fiorano-rtrsvc	Fiorano RtrSvc
1856	tcp/udp	fiorano-msgsvc	Fiorano MsgSvc
1857	tcp/udp	datacaptor	DataCaptor
1858	tcp/udp	privateark	PrivateArk
1859	tcp/udp	gammafetchsvr	Gamma Fetcher Server
1860	tcp/udp	sunscalar-svc	SunSCALAR Services
1861	tcp/udp	lecroy-vicp	LeCroy VICP
1862	tcp/udp	techra-server	techra-server
1863	tcp/udp	msnp	MSNP
1864	tcp/udp	paradym-31port	Paradym 31 Port
1865	tcp/udp	entp	ENTP
1866	tcp/udp	swrmi	swrmi
1867	tcp/udp	udrive	UDRIVE
1868	tcp/udp	viziblebrowser	VizibleBrowser
1869	tcp/udp	yestrader	YesTrader
1870	tcp/udp	sunscalar-dns	SunSCALAR DNS Service
1871	tcp/udp	canocentral0	Cano Central 0
1871 	tcp/udp 	# 	Serpa
1872	tcp/udp	canocentral1	Cano Central 1
1873	tcp/udp	fjmpjps	Fjmpjps
1874	tcp/udp	fjswapsnp	Fjswapsnp
1875	tcp/udp	westell-stats	westell stats
1876	tcp/udp	ewcappsrv	ewcappsrv
1877	tcp/udp	hp-webqosdb	hp-webqosdb
1878	tcp/udp	drmsmc	drmsmc
1879	tcp/udp	nettgain-nms	NettGain NMS
1880	tcp/udp	vsat-control	Gilat VSAT Control
1881	tcp/udp	ibm-mqseries2	IBM WebSphere MQ Everyplace
1882	tcp/udp	ecsqdmn	ecsqdmn
1883	tcp/udp	ibm-mqisdp	IBM MQSeries SCADA
1884	tcp/udp	idmaps	Internet Distance Map Svc
1885	tcp/udp	vrtstrapserver	Veritas Trap Server
1886	tcp/udp	leoip	Leonardo over IP
1887	tcp/udp	filex-lport	FileX Listening Port
1888	tcp/udp	ncconfig	NC Config Port
1889	tcp/udp	unify-adapter	Unify Web Adapter Service
1890	tcp/udp	wilkenlistener	wilkenListener
1891	tcp/udp	childkey-notif	ChildKey Notification
1892	tcp/udp	childkey-ctrl	ChildKey Control
1893	tcp/udp	elad	ELAD Protocol
1894	tcp/udp	o2server-port	O2Server Port
1896	tcp/udp	b-novative-ls	b-novative license server
1897	tcp/udp	metaagent	MetaAgent
1898	tcp/udp	cymtec-port	Cymtec secure management
1899	tcp/udp	mc2studios	MC2Studios
1900	tcp/udp	ssdp	SSDP
1901	tcp/udp	fjicl-tep-a	Fujitsu ICL Terminal Emulator Program A
1902	tcp/udp	fjicl-tep-b	Fujitsu ICL Terminal Emulator Program B
1903	tcp/udp	linkname	Local Link Name Resolution
1904	tcp/udp	fjicl-tep-c	Fujitsu ICL Terminal Emulator Program C
1905	tcp/udp	sugp	Secure UP.Link Gateway Protocol
1906	tcp/udp	tpmd	TPortMapperReq
1907	tcp/udp	intrastar	IntraSTAR
1908	tcp/udp	dawn	Dawn
1909	tcp/udp	global-wlink	Global World Link
1910	tcp/udp	ultrabac	UltraBac Software communications port
1911	tcp/udp	mtp	Starlight Networks Multimedia Transport Protocol
1912	tcp/udp	rhp-iibp	rhp-iibp
1913	tcp/udp	armadp	armadp
1914	tcp/udp	elm-momentum	Elm-Momentum
1915	tcp/udp	facelink	FACELINK
1916	tcp/udp	persona	Persoft Persona
1917	tcp/udp	noagent	nOAgent
1918	tcp/udp	can-nds	Candle Directory Service - NDS
1919	tcp/udp	can-dch	Candle Directory Service - DCH
1919 	tcp/udp 	# 	FTP.Casus
1920	tcp/udp	can-ferret	Candle Directory Service - FERRET
1921	tcp/udp	noadmin	NoAdmin
1922	tcp/udp	tapestry	Tapestry
1923	tcp/udp	spice	SPICE
1924	tcp/udp	xiip	XIIP
1925	tcp/udp	discovery-port	Surrogate Discovery Port
1926	tcp/udp	egs	Evolution Game Server
1927	tcp/udp	videte-cipc	Videte CIPC Port
1928	tcp/udp	emsd-port	Expnd Maui Srvr Dscovr
1929	tcp/udp	bandwiz-system	Bandwiz System - Server
1930	tcp/udp	driveappserver	Drive AppServer
1931	tcp/udp	amdsched	AMD SCHED
1932	tcp/udp	ctt-broker	CTT Broker
1933	tcp/udp	xmapi	IBM LM MT Agent
1934	tcp/udp	xaapi	IBM LM Appl Agent
1935	tcp/udp	macromedia-fcs	Macromedia Flash Communications Server MX
1936	tcp/udp	jetcmeserver	JetCmeServer Server Port
1937	tcp/udp	jwserver	JetVWay Server Port
1938	tcp/udp	jwclient	JetVWay Client Port
1939	tcp/udp	jvserver	JetVision Server Port
1940	tcp/udp	jvclient	JetVision Client Port
1941	tcp/udp	dic-aida	DIC-Aida
1942	tcp/udp	res	Real Enterprise Service
1943	tcp/udp	beeyond-media	Beeyond Media
1944	tcp/udp	close-combat	close-combat
1945	tcp/udp	dialogic-elmd	dialogic-elmd
1946	tcp/udp	tekpls	tekpls
1947	tcp/udp	hlserver	hlserver
1948	tcp/udp	eye2eye	eye2eye
1949	tcp/udp	ismaeasdaqlive	ISMA Easdaq Live
1950	tcp/udp	ismaeasdaqtest	ISMA Easdaq Test
1951	tcp/udp	bcs-lmserver	bcs-lmserver
1952	tcp/udp	mpnjsc	mpnjsc
1953	tcp/udp	rapidbase	Rapid Base
1954	tcp/udp	abr-basic	ABR-Basic Data
1955	tcp/udp	abr-secure	ABR-Secure Data
1956	tcp/udp	vrtl-vmf-ds	Vertel VMF DS
1957	tcp/udp	unix-status	unix-status
1958	tcp/udp	dxadmind	CA Administration Daemon
1959	tcp/udp	simp-all	SIMP Channel
1960	tcp/udp	nasmanager	Merit DAC NASmanager
1961	tcp/udp	bts-appserver	BTS APPSERVER
1962	tcp/udp	biap-mp	BIAP-MP
1963	tcp/udp	webmachine	WebMachine
1964	tcp/udp	solid-e-engine	SOLID E ENGINE
1965	tcp/udp	tivoli-npm	Tivoli NPM
1966	tcp/udp	slush	Slush
1966 	tcp 	# 	Fake FTP
1967	tcp/udp	sns-quote	SNS Quote
1967 	tcp 	# 	WM FTP Server
1968	tcp/udp	lipsinc	LIPSinc
1968 	tcp 	# 	Network Flight Recorder (NFR) systems
use TCP to communicate. A security
administrator must open ports to allow
for communication between the NFR components.
1969	tcp/udp	lipsinc1	LIPSinc 1
1969 	tcp 	# 	OpC BO
1970	tcp/udp	netop-rc	NetOp Remote Control
1971	tcp/udp	netop-school	NetOp School
1971 	tcp 	# 	Bifrose
1972	tcp/udp	intersys-cache	Cache
1973	tcp/udp	dlsrap	Data Link Switching Remote Access Protocol
1974	tcp/udp	drp	DRP
1975	tcp/udp	tcoflashagent	TCO Flash Agent
1976	tcp/udp	tcoregagent	TCO Reg Agent
1977	tcp/udp	tcoaddressbook	TCO Address Book
1978	tcp/udp	unisql	UniSQL
1979	tcp/udp	unisql-java	UniSQL Java
1980	tcp/udp	pearldoc-xact	PearlDoc XACT
1981	tcp/udp	p2pq	p2pQ
1981 	tcp 	# 	Bowl, Shockrave
1982	tcp/udp	estamp	Evidentiary Timestamp
1983	tcp/udp	lhtp	Loophole Test Protocol
1984	tcp/udp	bb	BB
1985	tcp/udp	hsrp	Hot Standby Router Protocol
1986	tcp/udp	licensedaemon	cisco license management
1987	tcp/udp	tr-rsrb-p1	cisco RSRB Priority 1 port
1988	tcp/udp	tr-rsrb-p2	cisco RSRB Priority 2 port
1989	tcp/udp	tr-rsrb-p3	cisco RSRB Priority 3 port
1989	tcp/udp	mshnet	MHSnet system
1990	tcp/udp	stun-p1	cisco STUN Priority 1 port
1991	tcp/udp	stun-p2	cisco STUN Priority 2 port
1992	tcp/udp	stun-p3	cisco STUN Priority 3 port
1992	tcp/udp	ipsendmsg	IPsendmsg
1993	tcp/udp	snmp-tcp-port	cisco SNMP TCP port
1994	tcp/udp	stun-port	cisco serial tunnel port
1995	tcp/udp	perf-port	cisco perf port
1996	tcp/udp	tr-rsrb-port	cisco Remote SRB port
1997	tcp/udp	gdp-port	cisco Gateway Discovery Protocol
1998	tcp/udp	x25-svc-port	cisco X.25 service (XOT)
1999	tcp/udp	tcp-id-port	cisco identification port
1999 	tcp 	# 	Back Door, SubSeven, TransScout
2000	tcp/udp	cisco-sccp	Cisco SCCP
2000 	tcp 	# 	NeWS/OpenWin
(Sun's older technology like X Windows)
2000 	tcp 	# 	The commercial remote-control
program "RemotelyAnywhere" installs
a webserver at this port.
2000 	tcp/udp 	# 	Der Spaher / Der Spaeher,
Insane Network, Last 2000,
Remote Explorer 2000,
Senna Spy Trojan Generator, Fearic, Feardoor
2001	tcp	dc	 
2001	udp	wizard	curry
2001 	tcp 	# 	The popular glimpse search engine runs on this port.
2001 	tcp 	# 	Panda Antivirus for Novell Netware servers listens
on this ports and allows anyone to connect to port
2001 and execute any Novell command.
2001 	tcp 	# 	Der Spaher / Der Spaeher, Trojan Cow, OICQSer
2002	tcp/udp	globe	 
2002 	tcp/udp 	# 	Singu, W32.Beagle
2004	tcp	mailbox	 
2004	udp	emce	CCWS mm conf
2004-2005 	tcp/udp 	# 	OICQSer
2005	tcp	berknet	 
2005	udp	oracle	 
2006	tcp	invokator	 
2006	udp	raid-cd	raid
2007	tcp	dectalk	 
2007	udp	raid-am	 
2007-2012 	tcp/udp 	# 	OICQSer
2008	tcp	conf	 
2008	udp	terminaldb	 
2009	tcp	news	 
2009	udp	whosockami	 
2010	tcp	search	 
2010	udp	pipe_server	 
2010 	tcp 	# 	Network Flight Recorder (NFR) systems
use TCP to communicate. This port
communication allows communication
from the administrative station (NFR
Console) to the central station.
2011	tcp	raid-cc	raid
2011	udp	servserv	 
2012	tcp	ttyinfo	 
2012	udp	raid-ac	 
2013	tcp	raid-am	 
2013	udp	raid-cd	 
2014	tcp	troff	 
2014	udp	raid-sf	 
2014 	tcp/udp 	# 	OICQSer
2015	tcp	cypress	 
2015	udp	raid-cs	 
2016	tcp/udp	bootserver	 
2017	tcp	cypress-stat	 
2017	udp	bootclient	 
2018	tcp	terminaldb	 
2018	udp	rellpack	 
2019	tcp	whosockami	 
2019	udp	about	 
2020	tcp/udp	xinupageserver	 
2021	tcp	servexec	 
2021	udp	xinuexpansion1	 
2022	tcp	down	 
2022	udp	xinuexpansion2	 
2023	tcp/udp	xinuexpansion3	 
2023 	tcp 	# 	RAT:Ripper
gets dialup passwords
2024	tcp/udp	xinuexpansion4	 
2025	tcp	ellpack	 
2025	udp	xribs	 
2026	tcp/udp	scrabble	 
2027	tcp/udp	shadowserver	 
2028	tcp/udp	submitserver	 
2029	tcp/udp	hsrpv6	Hot Standby Router Protocol IPv6
2030	tcp/udp	device2	 
2031	tcp/udp	mobrien-chat	mobrien-chat November 2004
2032	tcp/udp	blackboard	 
2033	tcp/udp	glogger	 
2034	tcp/udp	scoremgr	 
2035	tcp/udp	imsldoc	 
2036	tcp/udp	#	Unassigned
2037	tcp/udp	p2plus	P2plus Application Server
2038	tcp/udp	objectmanager	 
2039	tcp/udp	#	Unassigned
2040	tcp/udp	lam	 
2041	tcp/udp	interbase	 
2041 	tcp 	# 	W32.Korgo
2042	tcp/udp	isis	isis
2043	tcp/udp	isis-bcast	isis-bcast
2044	tcp/udp	rimsl	 
2045	tcp/udp	cdfunc	 
2046	tcp/udp	sdfunc	 
2047	tcp/udp	dls	 
2048	tcp/udp	dls-monitor	 
2048 	tcp 	# 	Some Shiva/Spider Integrator routers listen on
this port for a Telnet connection for configuration.
2049	tcp/udp	shilp	 
2049	tcp/udp	nfs	Network File System - Sun Microsystems
2050	tcp/udp	av-emb-config	Avaya EMB Config Port
2050 	tcp 	# 	PWSteal.Ldpinch
2051	tcp/udp	epnsdp	EPNSDP
2052	tcp/udp	clearvisn	clearVisn Services Port
2053	tcp/udp	lot105-ds-upd	Lot105 DSuper Updates
2054	tcp/udp	weblogin	Weblogin Port
2055	tcp/udp	iop	Iliad-Odyssey Protocol
2056	tcp/udp	omnisky	OmniSky Port
2057	tcp/udp	rich-cp	Rich Content Protocol
2058	tcp/udp	newwavesearch	NewWaveSearchables RMI
2059	tcp/udp	bmc-messaging	BMC Messaging Service
2060	tcp/udp	teleniumdaemon	Telenium Daemon IF
2060 	tcp/udp 	# 	OptixPro
2061	tcp/udp	netmount	NetMount
2062	tcp/udp	icg-swp	ICG SWP Port
2063	tcp/udp	icg-bridge	ICG Bridge Port
2064	tcp/udp	icg-iprelay	ICG IP Relay Port
2064 	tcp/udp 	# 	Distributed.net Bovine client proxy port.
2065	tcp/udp	dlsrpn	Data Link Switch Read Port Number
2066	tcp/udp	#	Unassigned
2066 	tcp/udp 	# 	DLSw
2067	tcp/udp	dlswpn	Data Link Switch Write Port Number
2068	tcp/udp	avauthsrvprtcl	Avocent AuthSrv Protocol
2069	tcp/udp	event-port	HTTP Event Port
2070	tcp/udp	ah-esp-encap	AH and ESP Encapsulated in UDP packet
2071	tcp/udp	acp-port	Axon Control Protocol
2072	tcp/udp	msync	GlobeCast mSync
2073	tcp/udp	gxs-data-port	DataReel Database Socket
2074	tcp/udp	vrtl-vmf-sa	Vertel VMF SA
2075	tcp/udp	newlixengine	Newlix ServerWare Engine
2076	tcp/udp	newlixconfig	Newlix JSPConfig
2077	tcp/udp	trellisagt	TrelliSoft Agent
2078	tcp/udp	trellissvr	TrelliSoft Server
2079	tcp/udp	idware-router	IDWARE Router Port
2080	tcp/udp	autodesk-nlm	Autodesk NLM (FLEXlm)
2080 	tcp 	# 	Some versions of WinGate 3.0 contain a bug
that allows the service to be crashed by
connecting to this port and sending 2000 characters.
2080 	tcp 	# 	WinHole, Curdeal, Tjserv
2081	tcp/udp	kme-trap-port	KME PRINTER TRAP PORT
2082	tcp	infowave	Infowave Mobility Server
2082	udp	infowave	Infowave Mobiltiy Server
2083-2085	tcp/udp	#	Unassigned
2086	tcp/udp	gnunet	GNUnet
2087	tcp/udp	eli	ELI - Event Logging Integration
2088	tcp/udp	#	Unassigned
2089	tcp/udp	sep	Security Encapsulation Protocol - SEP
2090	tcp/udp	lrp	Load Report Protocol
2090 	tcp/udp 	# 	Expjan
2091	tcp/udp	prp	PRP
2092	tcp/udp	descent3	Descent 3
2093	tcp/udp	nbx-cc	NBX CC
2094	tcp/udp	nbx-au	NBX AU
2095	tcp/udp	nbx-ser	NBX SER
2096	tcp/udp	nbx-dir	NBX DIR
2097	tcp/udp	jetformpreview	Jet Form Preview
2098	tcp/udp	dialog-port	Dialog Port
2099	tcp/udp	h2250-annex-g	H.225.0 Annex G
2100	tcp/udp	amiganetfs	Amiga Network Filesystem
2101	tcp/udp	rtcm-sc104	rtcm-sc104
2102	tcp/udp	zephyr-srv	Zephyr server
2103	tcp/udp	zephyr-clt	Zephyr serv-hm connection
2104	tcp/udp	zephyr-hm	Zephyr hostmanager
2105	tcp/udp	minipay	MiniPay
2106	tcp/udp	mzap	MZAP
2107	tcp/udp	bintec-admin	BinTec Admin
2108	tcp/udp	comcam	Comcam
2109	tcp/udp	ergolight	Ergolight
2110	tcp/udp	umsp	UMSP
2111	tcp/udp	dsatp	DSATP
2112	tcp/udp	idonix-metanet	Idonix MetaNet
2113	tcp/udp	hsl-storm	HSL StoRM
2114	tcp/udp	newheights	NEWHEIGHTS
2115	tcp/udp	kdm	Key Distribution Manager
2115 	tcp 	# 	Bugs
2116	tcp/udp	ccowcmr	CCOWCMR
2117	tcp/udp	mentaclient	MENTACLIENT
2118	tcp/udp	mentaserver	MENTASERVER
2119	tcp/udp	gsigatekeeper	GSIGATEKEEPER
2120	tcp/udp	qencp	Quick Eagle Networks CP
2121	tcp/udp	scientia-ssdb	SCIENTIA-SSDB
2122	tcp/udp	caupc-remote	CauPC Remote Control
2123	tcp/udp	gtp-control	GTP-Control Plane (3GPP)
2124	tcp/udp	elatelink	ELATELINK
2125	tcp/udp	lockstep	LOCKSTEP
2126	tcp/udp	pktcable-cops	PktCable-COPS
2127	tcp/udp	index-pc-wb	INDEX-PC-WB
2128	tcp/udp	net-steward	Net Steward Control
2129	tcp/udp	cs-live	cs-live.com
2130	tcp/udp	swc-xds	SWC-XDS
2130 	udp 	# 	Mini Backlash
2131	tcp/udp	avantageb2b	Avantageb2b
2132	tcp/udp	avail-epmap	AVAIL-EPMAP
2133	tcp/udp	zymed-zpp	ZYMED-ZPP
2134	tcp/udp	avenue	AVENUE
2135	tcp/udp	gris	Grid Resource Information Server
2136	tcp/udp	appworxsrv	APPWORXSRV
2137	tcp/udp	connect	CONNECT
2138	tcp/udp	unbind-cluster	UNBIND-CLUSTER
2139	tcp/udp	ias-auth	IAS-AUTH
2140	tcp/udp	ias-reg	IAS-REG
2140 	tcp/udp 	# 	RAT:The DeepThroat trojan
2140 	udp 	# 	Foreplay
2141	tcp/udp	ias-admind	IAS-ADMIND
2142	tcp/udp	tdm-over-ip	TDM-OVER-IP
2143	tcp/udp	lv-jc	Live Vault Job Control
2144	tcp/udp	lv-ffx	Live Vault Fast Object Transfer
2145	tcp/udp	lv-pici	Live Vault Remote Diagnostic Console Support
2146	tcp/udp	lv-not	Live Vault Admin Event Notification
2147	tcp/udp	lv-auth	Live Vault Authentication
2148	tcp/udp	veritas-ucl	VERITAS UNIVERSAL COMMUNICATION LAYER
2149	tcp/udp	acptsys	ACPTSYS
2150	tcp/udp	dynamic3d	DYNAMIC3D
2151	tcp/udp	docent	DOCENT
2152	tcp/udp	gtp-user	GTP-User Plane (3GPP)
2153-2158	tcp/udp	#	Unassigned
2155 	tcp 	# 	Illusion Mailer
2159	tcp/udp	gdbremote	GDB Remote Debug Port
2160	tcp/udp	apc-2160	APC 2160
2161	tcp/udp	apc-2161	APC 2161
2162	tcp/udp	navisphere	Navisphere
2163	tcp/udp	navisphere-sec	Navisphere Secure
2164	tcp/udp	ddns-v3	Dynamic DNS Version 3
2165	tcp/udp	x-bone-api	X-Bone API
2166	tcp/udp	iwserver	iwserver
2167	tcp/udp	raw-serial	Raw Async Serial Link
2168	tcp/udp	easy-soft-mux	easy-soft Multiplexer
2169	tcp/udp	archisfcp	ArchisFCP
2170	tcp/udp	eyetv	EyeTV Server Port
2171	tcp/udp	msfw-storage	MS Firewall Storage
2172	tcp/udp	msfw-s-storage	MS Firewall SecureStorage
2173	tcp/udp	msfw-replica	MS Firewall Replication
2174	tcp/udp	msfw-array	MS Firewall Intra Array
2175-2179	tcp/udp	#	Unassigned
2180	tcp/udp	mc-gt-srv	Millicent Vendor Gateway Server
2181	tcp/udp	eforward	eforward
2182-2183	tcp/udp	#	Unassigned
2184	tcp/udp	nvd	NVD User
2185	tcp/udp	onbase-dds	OnBase Distributed Disk Services
2186-2189	tcp/udp	#	Unassigned
2190	tcp/udp	tivoconnect	TiVoConnect Beacon
2191	tcp/udp	tvbus	TvBus Messaging
2191-2196	tcp/udp	#	Unassigned
2197	tcp/udp	mnp-exchange	MNP data exchange
2198-2199	tcp/udp	#	Unassigned
2200	tcp/udp	ici	ICI
2201	tcp/udp	ats	Advanced Training System Program
2202	tcp/udp	imtc-map	Int. Multimedia Teleconferencing Cosortium
2213	tcp/udp	kali	Kali
2220	tcp/udp	netiq	NetIQ End2End
2221	tcp/udp	rockwell-csp1	Rockwell CSP1
2222	tcp/udp	rockwell-csp2	Rockwell CSP2
2223	tcp/udp	rockwell-csp3	Rockwell CSP3
2232	tcp/udp	ivs-video	IVS Video default
2233	tcp/udp	infocrypt	INFOCRYPT
2234	tcp/udp	directplay	DirectPlay
2235	tcp/udp	sercomm-wlink	Sercomm-WLink
2236	tcp/udp	nani	Nani
2237	tcp/udp	optech-port1-lm	Optech Port1 License Manager
2238	tcp/udp	aviva-sna	AVIVA SNA SERVER
2239	tcp/udp	imagequery	Image Query
2240	tcp/udp	recipe	RECIPe
2241	tcp/udp	ivsd	IVS Daemon
2242	tcp/udp	foliocorp	Folio Remote Server
2243	tcp/udp	magicom	Magicom Protocol
2244	tcp/udp	nmsserver	NMS Server
2245	tcp/udp	hao	HaO
2246	tcp/udp	pc-mta-addrmap	PacketCable MTA Addr Map
2247	tcp/udp	#	Unassigned
2248	tcp/udp	ums	User Management Service
2249	tcp/udp	rfmp	RISO File Manager Protocol
2250	tcp/udp	remote-collab	remote-collab
2251	tcp/udp	dif-port	Distributed Framework Port
2252	tcp/udp	njenet-ssl	NJENET using SSL
2253	tcp/udp	dtv-chan-req	DTV Channel Request
2254	tcp/udp	seispoc	Seismic P.O.C. Port
2255	tcp/udp	vrtp	VRTP - ViRtue Transfer Protocol
2255 	tcp 	# 	Nirvana
2256-2259	tcp/udp	#	Unassigned
2260	tcp/udp	apc-2260	APC 2260
2261-2265	tcp/udp	#	Unassigned
2266	tcp/udp	mfserver	M-Files Server
2267	tcp/udp	ontobroker	OntoBroker
2268	tcp/udp	amt	AMT
2269	tcp/udp	mikey	MIKEY
2270	tcp/udp	starschool	starSchool
2271	tcp/udp	mmcals	Secure Meeting Maker Scheduling
2272	tcp/udp	mmcal	Meeting Maker Scheduling
2273	tcp/udp	mysql-im	MySQL Instance Manager
2274	tcp/udp	pcttunnell	PCTTunneller
2275	tcp/udp	ibridge-data	iBridge Conferencing
2276	tcp/udp	ibridge-mgmt	iBridge Management
2277	tcp/udp	bluectrlproxy	Bt device control proxy
2278	tcp/udp	#	Unassigned
2279	tcp/udp	xmquery	xmquery
2280	tcp/udp	lnvpoller	LNVPOLLER
2281	tcp/udp	lnvconsole	LNVCONSOLE
2281 	tcp/udp 	# 	W32.HLLW.Nautic
2282	tcp/udp	lnvalarm	LNVALARM
2283	tcp/udp	lnvstatus	LNVSTATUS
2283 	tcp 	# 	Hvl RAT, Nibu, W32.Dumaru
2284	tcp/udp	lnvmaps	LNVMAPS
2285	tcp/udp	lnvmailmon	LNVMAILMON
2286	tcp/udp	nas-metering	NAS-Metering
2287	tcp/udp	dna	DNA
2288	tcp/udp	netml	NETML
2289	tcp/udp	dict-lookup	Lookup dict server
2290-2293	tcp/udp	#	Unassigned
2294	tcp/udp	konshus-lm	Konshus License Manager (FLEX)
2295	tcp/udp	advant-lm	Advant License Manager
2296	tcp/udp	theta-lm	Theta License Manager (Rainbow)
2297	tcp/udp	d2k-datamover1	D2K DataMover 1
2298	tcp/udp	d2k-datamover2	D2K DataMover 2
2299	tcp/udp	pc-telecommute	PC Telecommute
2300	tcp/udp	cvmmon	CVMMON
2300 	tcp 	# 	Xplorer
2301	tcp/udp	cpq-wbem	Compaq HTTP
2302	tcp/udp	binderysupport	Bindery Support
2303	tcp/udp	proxy-gateway	Proxy Gateway
2304	tcp/udp	attachmate-uts	Attachmate UTS
2305	tcp/udp	mt-scaleserver	MT ScaleServer
2306	tcp/udp	tappi-boxnet	TAPPI BoxNet
2307	tcp/udp	pehelp	pehelp
2308	tcp/udp	sdhelp	sdhelp
2309	tcp/udp	sdserver	SD Server
2310	tcp/udp	sdclient	SD Client
2311	tcp/udp	messageservice	Message Service
2311 	tcp 	# 	Studio 54
2313	tcp/udp	iapp	IAPP (Inter Access Point Protocol)
2314	tcp/udp	cr-websystems	CR WebSystems
2315	tcp/udp	precise-sft	Precise Sft.
2316	tcp/udp	sent-lm	SENT License Manager
2317	tcp/udp	attachmate-g32	Attachmate G32
2318	tcp/udp	cadencecontrol	Cadence Control
2319	tcp/udp	infolibria	InfoLibria
2320	tcp/udp	siebel-ns	Siebel NS
2321	tcp/udp	rdlap	RDLAP
2322	tcp/udp	ofsd	ofsd
2323	tcp/udp	3d-nfsd	3d-nfsd
2324	tcp/udp	cosmocall	Cosmocall
2325	tcp/udp	designspace-lm	Design Space License Management
2326	tcp/udp	idcp	IDCP
2327	tcp/udp	xingcsm	xingcsm
2328	tcp/udp	netrix-sftm	Netrix SFTM
2329	tcp/udp	nvd	NVD
2330	tcp/udp	tscchat	TSCCHAT
2330-2339 	tcp 	# 	Contact
2331	tcp/udp	agentview	AGENTVIEW
2332	tcp/udp	rcc-host	RCC Host
2333	tcp/udp	snapp	SNAPP
2334	tcp/udp	ace-client	ACE Client Auth
2335	tcp/udp	ace-proxy	ACE Proxy
2336	tcp/udp	appleugcontrol	Apple UG Control
2337	tcp/udp	ideesrv	ideesrv
2338	tcp/udp	norton-lambert	Norton Lambert
2339	tcp/udp	3com-webview	3Com WebView
2339 	tcp/udp 	# 	Voice Spy
2340	tcp/udp	wrs_registry	WRS Registry
2341	tcp/udp	xiostatus	XIO Status
2342	tcp/udp	manage-exec	Seagate Manage Exec
2343	tcp/udp	nati-logos	nati logos
2344	tcp/udp	fcmsys	fcmsys
2345	tcp/udp	dbm	dbm
2345	tcp	#	HP OpenView Network Node Manager
v6.1 for Windows NT 4.0 has a buffer
overflow in its Alarm service which is
installed on TCP port 2345 by default.
2345 	tcp 	# 	Doly Trojan
2346	tcp/udp	redstorm_join	Game Connection Port
2347	tcp/udp	redstorm_find	Game Announcement and Location
2348	tcp/udp	redstorm_info	Information to query for game status
2349	tcp/udp	redstorm_diag	Diagnostics Port
2350	tcp/udp	psbserver	psbserver
2351	tcp/udp	psrserver	psrserver
2352	tcp/udp	pslserver	pslserver
2353	tcp/udp	pspserver	pspserver
2354	tcp/udp	psprserver	psprserver
2355	tcp/udp	psdbserver	psdbserver
2356	tcp/udp	gxtelmd	GXT License Managemant
2357	tcp/udp	unihub-server	UniHub Server
2358	tcp/udp	futrix	Futrix
2359	tcp/udp	flukeserver	FlukeServer
2360	tcp/udp	nexstorindltd	NexstorIndLtd
2361	tcp/udp	tl1	TL1
2362	tcp/udp	digiman	digiman
2363	tcp/udp	mediacntrlnfsd	Media Central NFSD
2364	tcp/udp	oi-2000	OI-2000
2365	tcp/udp	dbref	dbref
2366	tcp/udp	qip-login	qip-login
2367	tcp/udp	service-ctrl	Service Control
2368	tcp/udp	opentable	OpenTable
2369	tcp/udp	acs2000-dsp	ACS2000 DSP
2370	tcp/udp	l3-hbmon	L3-HBMon
2371	tcp/udp	worldwire	Compaq WorldWire Port
2372-2380	tcp/udp	#	Unassigned
2381	tcp/udp	compaq-https	Compaq HTTPS
2382	tcp/udp	ms-olap3	Microsoft OLAP
2383	tcp/udp	ms-olap4	Microsoft OLAP
2384	tcp	sd-request	SD-REQUEST
2384	udp	sd-capacity	SD-CAPACITY
2385	tcp/udp	sd-data	SD-DATA
2386	tcp/udp	virtualtape	Virtual Tape
2387	tcp/udp	vsamredirector	VSAM Redirector
2388	tcp/udp	mynahautostart	MYNAH AutoStart
2389	tcp/udp	ovsessionmgr	OpenView Session Mgr
2390	tcp/udp	rsmtp	RSMTP
2391	tcp/udp	3com-net-mgmt	3COM Net Management
2392	tcp/udp	tacticalauth	Tactical Auth
2393	tcp/udp	ms-olap1	MS OLAP 1
2394	tcp/udp	ms-olap2	MS OLAP 2
2395	tcp/udp	lan900_remote	LAN900 Remote
2396	tcp/udp	wusage	Wusage
2397	tcp/udp	ncl	NCL
2398	tcp/udp	orbiter	Orbiter
2399	tcp/udp	fmpro-fdal	"FileMaker, Inc. - Data Access Layer"
2400	tcp/udp	opequus-server	OpEquus Server
2401	tcp/udp	cvspserver	cvspserver
2402	tcp/udp	taskmaster2000	TaskMaster 2000 Server
2403	tcp/udp	taskmaster2000	TaskMaster 2000 Web
2404	tcp/udp	iec-104	IEC 60870-5-104 process control over IP
2405	tcp/udp	trc-netpoll	TRC Netpoll
2406	tcp/udp	jediserver	JediServer
2407	tcp/udp	orion	Orion
2408	tcp/udp	optimanet	OptimaNet
2409	tcp/udp	sns-protocol	SNS Protocol
2410	tcp/udp	vrts-registry	VRTS Registry
2411	tcp/udp	netwave-ap-mgmt	Netwave AP Management
2412	tcp/udp	cdn	CDN
2413	tcp/udp	orion-rmi-reg	orion-rmi-reg
2414	tcp/udp	beeyond	Beeyond
2414 	tcp 	# 	Shania
2415	tcp/udp	codima-rtp	Codima Remote Transaction Protocol
2416	tcp/udp	rmtserver	RMT Server
2417	tcp/udp	composit-server	Composit Server
2418	tcp/udp	cas	cas
2419	tcp/udp	attachmate-s2s	Attachmate S2S
2420	tcp/udp	dslremote-mgmt	DSL Remote Management
2421	tcp/udp	g-talk	G-Talk
2422	tcp/udp	crmsbits	CRMSBITS
2423	tcp/udp	rnrp	RNRP
2424	tcp/udp	kofax-svr	KOFAX-SVR
2425	tcp/udp	fjitsuappmgr	Fujitsu App Manager
2425 	tcp 	# 	Madfind
2426	tcp/udp	#	Unassigned
2427	tcp/udp	mgcp-gateway	Media Gateway Control Protocol Gateway
2428	tcp/udp	ott	One Way Trip Time
2429	tcp/udp	ft-role	FT-ROLE
2430	tcp/udp	venus	venus
2431	tcp/udp	venus-se	venus-se
2432	tcp/udp	codasrv	codasrv
2433	tcp/udp	codasrv-se	codasrv-se
2434	tcp/udp	pxc-epmap	pxc-epmap
2435	tcp/udp	optilogic	OptiLogic
2436	tcp/udp	topx	TOP/X
2437	tcp/udp	unicontrol	UniControl
2438	tcp/udp	msp	MSP
2439	tcp/udp	sybasedbsynch	SybaseDBSynch
2440	tcp/udp	spearway	Spearway Lockers
2441	tcp/udp	pvsw-inet	Pervasive I*net Data Server
2442	tcp/udp	netangel	Netangel
2443	tcp/udp	powerclientcsf	PowerClient Central Storage Facility
2444	tcp/udp	btpp2sectrans	BT PP2 Sectrans
2445	tcp/udp	dtn1	DTN1
2446	tcp/udp	bues_service	bues_service
2447	tcp/udp	ovwdb	OpenView NNM daemon
2448	tcp/udp	hpppssvr	hpppsvr
2449	tcp/udp	ratl	RATL
2450	tcp/udp	netadmin	netadmin
2451	tcp/udp	netchat	netchat
2452	tcp/udp	snifferclient	SnifferClient
2453	tcp/udp	madge-ltd	madge ltd
2454	tcp/udp	indx-dds	IndX-DDS
2455	tcp/udp	wago-io-system	WAGO-IO-SYSTEM
2456	tcp/udp	altav-remmgt	altav-remmgt
2457	tcp/udp	rapido-ip	Rapido_IP
2458	tcp/udp	griffin	griffin
2459	tcp/udp	community	Community
2460	tcp/udp	ms-theater	ms-theater
2461	tcp/udp	qadmifoper	qadmifoper
2462	tcp/udp	qadmifevent	qadmifevent
2463	tcp/udp	symbios-raid	Symbios Raid
2464	tcp/udp	direcpc-si	DirecPC SI
2465	tcp/udp	lbm	Load Balance Management
2466	tcp/udp	lbf	Load Balance Forwarding
2467	tcp/udp	high-criteria	High Criteria
2468	tcp/udp	qip-msgd	qip_msgd
2469	tcp/udp	mti-tcs-comm	MTI-TCS-COMM
2470	tcp/udp	taskman-port	taskman port
2471	tcp/udp	seaodbc	SeaODBC
2472	tcp/udp	c3	C3
2473	tcp/udp	aker-cdp	Aker-cdp
2474	tcp/udp	vitalanalysis	Vital Analysis
2475	tcp/udp	ace-server	ACE Server
2476	tcp/udp	ace-svr-prop	ACE Server Propagation
2477	tcp/udp	ssm-cvs	SecurSight Certificate Valifation Service
2478	tcp/udp	ssm-cssps	SecurSight Authentication Server (SSL)
2479	tcp/udp	ssm-els	SecurSight Event Logging Server (SSL)
2480	tcp/udp	lingwood	Lingwood's Detail
2481	tcp/udp	giop	Oracle GIOP
2482	tcp/udp	giop-ssl	Oracle GIOP SSL
2483	tcp/udp	ttc	Oracle TTC
2484	tcp/udp	ttc-ssl	Oracle TTC SSL
2485	tcp/udp	netobjects1	Net Objects1
2486	tcp/udp	netobjects2	Net Objects2
2487	tcp/udp	pns	Policy Notice Service
2488	tcp/udp	moy-corp	Moy Corporation
2489	tcp/udp	tsilb	TSILB
2490	tcp/udp	qip-qdhcp	qip_qdhcp
2491	tcp/udp	conclave-cpp	Conclave CPP
2492	tcp/udp	groove	GROOVE
2493	tcp/udp	talarian-mqs	Talarian MQS
2494	tcp/udp	bmc-ar	BMC AR
2495	tcp/udp	fast-rem-serv	Fast Remote Services
2496	tcp/udp	dirgis	DIRGIS
2497	tcp/udp	quaddb	Quad DB
2498	tcp/udp	odn-castraq	ODN-CasTraq
2499	tcp/udp	unicontrol	UniControl
2500	tcp/udp	rtsserv	Resource Tracking system server
2501	tcp/udp	rtsclient	Resource Tracking system client
2502	tcp/udp	kentrox-prot	Kentrox Protocol
2503	tcp/udp	nms-dpnss	NMS-DPNSS
2504	tcp/udp	wlbs	WLBS
2505	tcp/udp	ppcontrol	PowerPlay Control
2506	tcp/udp	jbroker	jbroker
2507	tcp/udp	spock	spock
2508	tcp/udp	jdatastore	JDataStore
2509	tcp/udp	fjmpss	fjmpss
2510	tcp/udp	fjappmgrbulk	fjappmgrbulk
2511	tcp/udp	metastorm	Metastorm
2512	tcp/udp	citrixima	Citrix IMA
2513	tcp/udp	citrixadmin	Citrix ADMIN
2514	tcp/udp	facsys-ntp	Facsys NTP
2515	tcp/udp	facsys-router	Facsys Router
2516	tcp/udp	maincontrol	Main Control
2517	tcp/udp	call-sig-trans	H.323 Annex E call signaling transport
2518	tcp/udp	willy	Willy
2519	tcp/udp	globmsgsvc	globmsgsvc
2520	tcp/udp	pvsw	Pervasive Listener
2521	tcp/udp	adaptecmgr	Adaptec Manager
2522	tcp/udp	windb	WinDb
2523	tcp/udp	qke-llc-v3	Qke LLC V.3
2524	tcp/udp	optiwave-lm	Optiwave License Management
2525	tcp/udp	ms-v-worlds	MS V-Worlds
2526	tcp/udp	ema-sent-lm	EMA License Manager
2526 	tcp/udp 	# 	Delf
2527	tcp/udp	iqserver	IQ Server
2527 	tcp/udp 	# 	Zvrop
2528	tcp/udp	ncr_ccl	NCR CCL
2529	tcp/udp	utsftp	UTS FTP
2530	tcp/udp	vrcommerce	VR Commerce
2531	tcp/udp	ito-e-gui	ITO-E GUI
2532	tcp/udp	ovtopmd	OVTOPMD
2533	tcp/udp	snifferserver	SnifferServer
2534	tcp/udp	combox-web-acc	Combox Web Access
2535	tcp/udp	madcap	MADCAP
2535 	tcp/udp 	# 	W32.Beagle
2536	tcp/udp	btpp2audctr1	btpp2audctr1
2537	tcp/udp	upgrade	Upgrade Protocol
2538	tcp/udp	vnwk-prapi	vnwk-prapi
2539	tcp/udp	vsiadmin	VSI Admin
2540	tcp/udp	lonworks	LonWorks
2541	tcp/udp	lonworks2	LonWorks2
2542	tcp/udp	davinci	daVinci Presenter
2543	tcp/udp	reftek	REFTEK
2543 	tcp/udp 	# 	sip
2544	tcp/udp	novell-zen	Novell ZEN
2545	tcp/udp	sis-emt	sis-emt
2546	tcp/udp	vytalvaultbrtp	vytalvaultbrtp
2547	tcp/udp	vytalvaultvsmp	vytalvaultvsmp
2548	tcp/udp	vytalvaultpipe	vytalvaultpipe
2549	tcp/udp	ipass	IPASS
2550	tcp/udp	ads	ADS
2551	tcp/udp	isg-uda-server	ISG UDA Server
2552	tcp/udp	call-logging	Call Logging
2553	tcp/udp	efidiningport	efidiningport
2554	tcp/udp	vcnet-link-v10	VCnet-Link v10
2555	tcp/udp	compaq-wcp	Compaq WCP
2556	tcp/udp	nicetec-nmsvc	nicetec-nmsvc
2556 	tcp/udp 	# 	W32.Beagle
2557	tcp/udp	nicetec-mgmt	nicetec-mgmt
2558	tcp/udp	pclemultimedia	PCLE Multi Media
2559	tcp/udp	lstp	LSTP
2560	tcp/udp	labrat	labrat
2561	tcp/udp	mosaixcc	MosaixCC
2562	tcp/udp	delibo	Delibo
2563	tcp/udp	cti-redwood	CTI Redwood
2564	tcp	hp-3000-telnet	HP 3000 NS/VT block mode telnet
2565	tcp/udp	coord-svr	Coordinator Server
2565 	tcp 	# 	RAT:Striker
VB + 20k
mostly just crashes windows
infects Win95/Win98/WinNT
2566	tcp/udp	pcs-pcw	pcs-pcw
2567	tcp/udp	clp	Cisco Line Protocol
2568	tcp/udp	spamtrap	SPAM TRAP
2569	tcp/udp	sonuscallsig	Sonus Call Signal
2570	tcp/udp	hs-port	HS Port
2571	tcp/udp	cecsvc	CECSVC
2572	tcp/udp	ibp	IBP
2573	tcp/udp	trustestablish	Trust Establish
2574	tcp/udp	blockade-bpsp	Blockade BPSP
2575	tcp/udp	hl7	HL7
2576	tcp/udp	tclprodebugger	TCL Pro Debugger
2577	tcp/udp	scipticslsrvr	Scriptics Lsrvr
2578	tcp/udp	rvs-isdn-dcp	RVS ISDN DCP
2579	tcp/udp	mpfoncl	mpfoncl
2580	tcp/udp	tributary	Tributary
2581	tcp/udp	argis-te	ARGIS TE
2582	tcp/udp	argis-ds	ARGIS DS
2583	tcp/udp	mon	MON
2583 	tcp 	# 	WinCrash
2584	tcp/udp	cyaserv	cyaserv
2585	tcp/udp	netx-server	NETX Server
2586	tcp/udp	netx-agent	NETX Agent
2587	tcp/udp	masc	MASC
2588	tcp/udp	privilege	Privilege
2589	tcp/udp	quartus-tcl	quartus tcl
2590	tcp/udp	idotdist	idotdist
2591	tcp/udp	maytagshuffle	Maytag Shuffle
2592	tcp/udp	netrek	netrek
2593	tcp/udp	mns-mail	MNS Mail Notice Service
2594	tcp/udp	dts	Data Base Server
2595	tcp/udp	worldfusion1	World Fusion 1
2596	tcp/udp	worldfusion2	World Fusion 2
2597	tcp/udp	homesteadglory	Homestead Glory
2598	tcp/udp	citriximaclient	Citrix MA Client
2599	tcp/udp	snapd	Snap Discovery
2600	tcp/udp	hpstgmgr	HPSTGMGR
2600 	tcp 	# 	Digital RootBeer
2601	tcp/udp	discp-client	discp client
2602	tcp/udp	discp-server	discp server
2603	tcp/udp	servicemeter	Service Meter
2604	tcp/udp	nsc-ccs	NSC CCS
2605	tcp/udp	nsc-posa	NSC POSA
2606	tcp/udp	netmon	Dell Netmon
2607	tcp/udp	connection	Dell Connection
2608	tcp/udp	wag-service	Wag Service
2609	tcp/udp	system-monitor	System Monitor
2610	tcp/udp	versa-tek	VersaTek
2611	tcp/udp	lionhead	LIONHEAD
2612	tcp/udp	qpasa-agent	Qpasa Agent
2613	tcp/udp	smntubootstrap	SMNTUBootstrap
2614	tcp/udp	neveroffline	Never Offline
2615	tcp/udp	firepower	firepower
2616	tcp/udp	appswitch-emp	appswitch-emp
2617	tcp/udp	cmadmin	Clinical Context Managers
2618	tcp/udp	priority-e-com	Priority E-Com
2619	tcp/udp	bruce	bruce
2620	tcp/udp	lpsrecommender	LPSRecommender
2621	tcp/udp	miles-apart	Miles Apart Jukebox Server
2622	tcp/udp	metricadbc	MetricaDBC
2623	tcp/udp	lmdp	LMDP
2624	tcp/udp	aria	Aria
2625	tcp/udp	blwnkl-port	Blwnkl Port
2626	tcp/udp	gbjd816	gbjd816
2627	tcp/udp	moshebeeri	Moshe Beeri
2628	tcp/udp	dict	DICT
2629	tcp/udp	sitaraserver	Sitara Server
2630	tcp/udp	sitaramgmt	Sitara Management
2631	tcp/udp	sitaradir	Sitara Dir
2632	tcp/udp	irdg-post	IRdg Post
2633	tcp/udp	interintelli	InterIntelli
2634	tcp/udp	pk-electronics	PK Electronics
2635	tcp/udp	backburner	Back Burner
2636	tcp/udp	solve	Solve
2637	tcp/udp	imdocsvc	Import Document Service
2638	tcp/udp	sybaseanywhere	Sybase Anywhere
2639	tcp/udp	aminet	AMInet
2640	tcp/udp	sai_sentlm	Sabbagh Associates Licence Manager
2641	tcp/udp	hdl-srv	HDL Server
2642	tcp/udp	tragic	Tragic
2643	tcp/udp	gte-samp	GTE-SAMP
2644	tcp/udp	travsoft-ipx-t	Travsoft IPX Tunnel
2645	tcp/udp	novell-ipx-cmd	Novell IPX CMD
2646	tcp/udp	and-lm	AND License Manager
2647	tcp/udp	syncserver	SyncServer
2648	tcp/udp	upsnotifyprot	Upsnotifyprot
2649	tcp/udp	vpsipport	VPSIPPORT
2650	tcp/udp	eristwoguns	eristwoguns
2651	tcp/udp	ebinsite	EBInSite
2652	tcp/udp	interpathpanel	InterPathPanel
2653	tcp/udp	sonus	Sonus
2654	tcp/udp	corel_vncadmin	Corel VNC Admin
2655	tcp/udp	unglue	UNIX Nt Glue
2656	tcp/udp	kana	Kana
2657	tcp/udp	sns-dispatcher	SNS Dispatcher
2658	tcp/udp	sns-admin	SNS Admin
2659	tcp/udp	sns-query	SNS Query
2660	tcp/udp	gcmonitor	GC Monitor
2661	tcp/udp	olhost	OLHOST
2662	tcp/udp	bintec-capi	BinTec-CAPI
2663	tcp/udp	bintec-tapi	BinTec-TAPI
2664	tcp/udp	patrol-mq-gm	Patrol for MQ GM
2665	tcp/udp	patrol-mq-nm	Patrol for MQ NM
2666	tcp/udp	extensis	extensis
2667	tcp/udp	alarm-clock-s	Alarm Clock Server
2668	tcp/udp	alarm-clock-c	Alarm Clock Client
2669	tcp/udp	toad	TOAD
2670	tcp/udp	tve-announce	TVE Announce
2671	tcp/udp	newlixreg	newlixreg
2672	tcp/udp	nhserver	nhserver
2673	tcp/udp	firstcall42	First Call 42
2674	tcp/udp	ewnn	ewnn
2675	tcp/udp	ttc-etap	TTC ETAP
2676	tcp/udp	simslink	SIMSLink
2677	tcp/udp	gadgetgate1way	Gadget Gate 1 Way
2678	tcp/udp	gadgetgate2way	Gadget Gate 2 Way
2679	tcp/udp	syncserverssl	Sync Server SSL
2680	tcp/udp	pxc-sapxom	pxc-sapxom
2681	tcp/udp	mpnjsomb	mpnjsomb
2682	tcp/udp	#	Removed
2683	tcp/udp	ncdloadbalance	NCDLoadBalance
2684	tcp/udp	mpnjsosv	mpnjsosv
2685	tcp/udp	mpnjsocl	mpnjsocl
2686	tcp/udp	mpnjsomg	mpnjsomg
2687	tcp/udp	pq-lic-mgmt	pq-lic-mgmt
2688	tcp/udp	md-cg-http	md-cf-http
2688 	tcp/udp 	md-cg-http 	IRC.Aladinz
2689	tcp/udp	fastlynx	FastLynx
2690	tcp/udp	hp-nnm-data	HP NNM Embedded Database
2691	tcp/udp	itinternet	ITInternet ISM Server
2692	tcp/udp	admins-lms	Admins LMS
2693	tcp/udp	#	Removed
2694	tcp/udp	pwrsevent	pwrsevent
2695	tcp/udp	vspread	VSPREAD
2696	tcp/udp	unifyadmin	Unify Admin
2697	tcp/udp	oce-snmp-trap	Oce SNMP Trap Port
2698	tcp/udp	mck-ivpip	MCK-IVPIP
2699	tcp/udp	csoft-plusclnt	Csoft Plus Client
2699 	tcp 	# 	Jittar
2700	tcp/udp	tqdata	tqdata
2701	tcp/udp	sms-rcinfo	SMS RCINFO
2702	tcp/udp	sms-xfer	SMS XFER
2703	tcp/udp	sms-chat	SMS CHAT
2704	tcp/udp	sms-remctrl	SMS REMCTRL
2705	tcp/udp	sds-admin	SDS Admin
2706	tcp/udp	ncdmirroring	NCD Mirroring
2707	tcp/udp	emcsymapiport	EMCSYMAPIPORT
2707 	tcp/udp 	# 	Bigfoot
2708	tcp/udp	banyan-net	Banyan-Net
2709	tcp/udp	supermon	Supermon
2710	tcp/udp	sso-service	SSO Service
2711	tcp/udp	sso-control	SSO Control
2712	tcp/udp	aocp	Axapta Object Communication Protocol
2713	tcp/udp	raven1	Raven1
2714	tcp/udp	raven2	Raven2
2715	tcp/udp	hpstgmgr2	HPSTGMGR2
2716	tcp/udp	inova-ip-disco	Inova IP Disco
2716 	tcp 	# 	The Prayer
2717	tcp/udp	pn-requester	PN REQUESTER
2718	tcp/udp	pn-requester2	PN REQUESTER 2
2719	tcp/udp	scan-change	Scan & Change
2720	tcp/udp	wkars	wkars
2721	tcp/udp	smart-diagnose	Smart Diagnose
2722	tcp/udp	proactivesrvr	Proactive Server
2723	tcp/udp	watchdognt	WatchDog NT
2724	tcp/udp	qotps	qotps
2725	tcp/udp	msolap-ptp2	MSOLAP PTP2
2726	tcp/udp	tams	TAMS
2727	tcp/udp	mgcp-callagent	Media Gateway Control Protocol Call Agent
2728	tcp/udp	sqdr	SQDR
2729	tcp/udp	tcim-control	TCIM Control
2730	tcp/udp	nec-raidplus	NEC RaidPlus
2731	tcp	fyre-messanger	Fyre Messanger
2731	udp	fyre-messanger	Fyre Messagner
2732	tcp/udp	g5m	G5M
2733	tcp/udp	signet-ctf	Signet CTF
2734	tcp/udp	ccs-software	CCS Software
2735	tcp/udp	netiq-mc	NetIQ Monitor Console
2736	tcp/udp	radwiz-nms-srv	RADWIZ NMS SRV
2737	tcp/udp	srp-feedback	SRP Feedback
2738	tcp/udp	ndl-tcp-ois-gw	NDL TCP-OSI Gateway
2739	tcp/udp	tn-timing	TN Timing
2740	tcp/udp	alarm	Alarm
2741	tcp/udp	tsb	TSB
2742	tcp/udp	tsb2	TSB2
2743	tcp/udp	murx	murx
2744	tcp/udp	honyaku	honyaku
2745	tcp/udp	urbisnet	URBISNET
2745 	tcp 	# 	W32.Beagle
2746	tcp/udp	cpudpencap	CPUDPENCAP
2747	tcp/udp	fjippol-swrly	 
2748	tcp/udp	fjippol-polsvr	 
2749	tcp/udp	fjippol-cnsl	 
2750	tcp/udp	fjippol-port1	 
2751	tcp/udp	fjippol-port2	 
2752	tcp/udp	rsisysaccess	RSISYS ACCESS
2753	tcp/udp	de-spot	de-spot
2754	tcp/udp	apollo-cc	APOLLO CC
2755	tcp/udp	expresspay	Express Pay
2756	tcp/udp	simplement-tie	simplement-tie
2757	tcp/udp	cnrp	CNRP
2758	tcp/udp	apollo-status	APOLLO Status
2759	tcp/udp	apollo-gms	APOLLO GMS
2760	tcp/udp	sabams	Saba MS
2761	tcp/udp	dicom-iscl	DICOM ISCL
2762	tcp/udp	dicom-tls	DICOM TLS
2763	tcp/udp	desktop-dna	Desktop DNA
2764	tcp/udp	data-insurance	Data Insurance
2765	tcp/udp	qip-audup	qip-audup
2766	tcp/udp	compaq-scp	Compaq SCP
2766 	tcp 	# 	used by Solaris listen/nlps_server.
It was part of System V R3 and Solaris.
In much the same way that scanning for
tcpmux will fingerprint SGI machines,
scanning for this port will fingerprint
SVR3 (Solaris 2.0) machines.
W32.HLLW.Deadhat
2767	tcp/udp	uadtc	UADTC
2768	tcp/udp	uacs	UACS
2769	tcp/udp	exce	eXcE
2770	tcp/udp	veronica	Veronica
2771	tcp/udp	vergencecm	Vergence CM
2772	tcp/udp	auris	auris
2773	tcp/udp	rbakcup1	RBackup Remote Backup
2773-2774 	tcp 	# 	SubSeven, SubSeven 2.1 Gold
2774	tcp/udp	rbakcup2	RBackup Remote Backup
2775	tcp/udp	smpp	SMPP
2776	tcp/udp	ridgeway1	Ridgeway Systems & Software
2777	tcp/udp	ridgeway2	Ridgeway Systems & Software
2778	tcp/udp	gwen-sonya	Gwen-Sonya
2779	tcp/udp	lbc-sync	LBC Sync
2780	tcp/udp	lbc-control	LBC Control
2781	tcp/udp	whosells	whosells
2782	tcp/udp	everydayrc	everydayrc
2783	tcp/udp	aises	AISES
2784	tcp/udp	www-dev	world wide web - development
2785	tcp/udp	aic-np	aic-np
2786	tcp/udp	aic-oncrpc	aic-oncrpc - Destiny MCD database
2787	tcp/udp	piccolo	piccolo - Cornerstone Software
2788	tcp/udp	fryeserv	NetWare Loadable Module - Seagate Software
2789	tcp/udp	media-agent	Media Agent
2790	tcp/udp	plgproxy	PLG Proxy
2791	tcp/udp	mtport-regist	MT Port Registrator
2792	tcp/udp	f5-globalsite	f5-globalsite
2793	tcp/udp	initlsmsad	initlsmsad
2794	tcp/udp	aaftp	aaftp
2795	tcp/udp	livestats	LiveStats
2796	tcp/udp	ac-tech	ac-tech
2797	tcp/udp	esp-encap	esp-encap
2798	tcp/udp	tmesis-upshot	TMESIS-UPShot
2799	tcp/udp	icon-discover	ICON Discover
2800	tcp/udp	acc-raid	ACC RAID
2801	tcp/udp	igcp	IGCP
2801 	tcp 	# 	Phineas Phucker
2802	tcp	veritas-tcp1	Veritas TCP1
2802	udp	veritas-udp1	Veritas UDP1
2803	tcp/udp	btprjctrl	btprjctrl
2804	tcp/udp	dvr-esm	March Networks Digital Video Recorders and
Enterprise Service Manager products
2805	tcp/udp	wta-wsp-s	WTA WSP-S
2806	tcp/udp	cspuni	cspuni
2807	tcp/udp	cspmulti	cspmulti
2808	tcp/udp	j-lan-p	J-LAN-P
2809	tcp/udp	corbaloc	CORBA LOC
2810	tcp/udp	netsteward	Active Net Steward
2811	tcp/udp	gsiftp	GSI FTP
2812	tcp/udp	atmtcp	atmtcp
2813	tcp/udp	llm-pass	llm-pass
2814	tcp/udp	llm-csv	llm-csv
2815	tcp/udp	lbc-measure	LBC Measurement
2816	tcp/udp	lbc-watchdog	LBC Watchdog
2817	tcp/udp	nmsigport	NMSig Port
2818	tcp/udp	rmlnk	rmlnk
2819	tcp/udp	fc-faultnotify	FC Fault Notification
2820	tcp/udp	univision	UniVision
2821	tcp/udp	vrts-at-port	VERITAS Authentication Service
2822	tcp/udp	ka0wuc	ka0wuc
2823	tcp/udp	cqg-netlan	CQG Net/LAN
2824	tcp/udp	cqg-netlan-1	CQG Net/LAN 1
2825	tcp/udp	#	(unassigned) Possibly assigned
2826	tcp/udp	slc-systemlog	slc systemlog
2827	tcp/udp	slc-ctrlrloops	slc ctrlrloops
2828	tcp/udp	itm-lm	ITM License Manager
2829	tcp/udp	silkp1	silkp1
2830	tcp/udp	silkp2	silkp2
2831	tcp/udp	silkp3	silkp3
2832	tcp/udp	silkp4	silkp4
2833	tcp/udp	glishd	glishd
2834	tcp/udp	evtp	EVTP
2835	tcp/udp	evtp-data	EVTP-DATA
2836	tcp/udp	catalyst	catalyst
2837	tcp/udp	repliweb	Repliweb
2838	tcp/udp	starbot	Starbot
2839	tcp/udp	nmsigport	NMSigPort
2840	tcp/udp	l3-exprt	l3-exprt
2841	tcp/udp	l3-ranger	l3-ranger
2842	tcp/udp	l3-hawk	l3-hawk
2843	tcp/udp	pdnet	PDnet
2844	tcp/udp	bpcp-poll	BPCP POLL
2845	tcp/udp	bpcp-trap	BPCP TRAP
2846	tcp/udp	aimpp-hello	AIMPP Hello
2847	tcp/udp	aimpp-port-req	AIMPP Port Req
2848	tcp/udp	amt-blc-port	AMT-BLC-PORT
2849	tcp/udp	fxp	FXP
2850	tcp/udp	metaconsole	MetaConsole
2851	tcp/udp	webemshttp	webemshttp
2852	tcp/udp	bears-01	bears-01
2853	tcp/udp	ispipes	ISPipes
2854	tcp/udp	infomover	InfoMover
2856	tcp/udp	cesdinv	cesdinv
2857	tcp/udp	simctlp	SimCtIP
2858	tcp/udp	ecnp	ECNP
2859	tcp/udp	activememory	Active Memory
2860	tcp/udp	dialpad-voice1	Dialpad Voice 1
2861	tcp/udp	dialpad-voice2	Dialpad Voice 2
2862	tcp/udp	ttg-protocol	TTG Protocol
2863	tcp/udp	sonardata	Sonar Data
2864	tcp/udp	astromed-main	main 5001 cmd
2865	tcp/udp	pit-vpn	pit-vpn
2866	tcp/udp	iwlistener	iwlistener
2867	tcp/udp	esps-portal	esps-portal
2868	tcp/udp	npep-messaging	NPEP Messaging
2869	tcp/udp	icslap	ICSLAP
2870	tcp/udp	daishi	daishi
2871	tcp/udp	msi-selectplay	MSI Select Play
2872	tcp/udp	radix	RADIX
2873	tcp/udp	#	Unassigned
2874	tcp/udp	dxmessagebase1	dxmessagebase1
2875	tcp/udp	dxmessagebase2	dxmessagebase2
2876	tcp/udp	sps-tunnel	SPS Tunnel
2877	tcp/udp	bluelance	BLUELANCE
2878	tcp/udp	aap	AAP
2879	tcp/udp	ucentric-ds	ucentric-ds
2880	tcp/udp	synapse	Synapse Transport
2881	tcp/udp	ndsp	NDSP
2882	tcp/udp	ndtp	NDTP
2883	tcp/udp	ndnp	NDNP
2884	tcp/udp	flashmsg	Flash Msg
2885	tcp/udp	topflow	TopFlow
2886	tcp/udp	responselogic	RESPONSELOGIC
2887	tcp/udp	aironetddp	aironet
2888	tcp/udp	spcsdlobby	SPCSDLOBBY
2889	tcp/udp	rsom	RSOM
2890	tcp/udp	cspclmulti	CSPCLMULTI
2891	tcp/udp	cinegrfx-elmd	CINEGRFX-ELMD License Manager
2892	tcp/udp	snifferdata	SNIFFERDATA
2893	tcp/udp	vseconnector	VSECONNECTOR
2894	tcp/udp	abacus-remote	ABACUS-REMOTE
2895	tcp/udp	natuslink	NATUS LINK
2896	tcp/udp	ecovisiong6-1	ECOVISIONG6-1
2897	tcp/udp	citrix-rtmp	Citrix RTMP
2898	tcp/udp	appliance-cfg	APPLIANCE-CFG
2899	tcp/udp	powergemplus	POWERGEMPLUS
2900	tcp/udp	quicksuite	QUICKSUITE
2901	tcp/udp	allstorcns	ALLSTORCNS
2902	tcp/udp	netaspi	NET ASPI
2903	tcp/udp	suitcase	SUITCASE
2904	tcp/udp	m2ua	M2UA
2905	tcp	m3ua	M3UA
2905	udp	m3ua	De-registered (2001 June 07)
2905	sctp	m3ua	M3UA
2906	tcp/udp	caller9	CALLER9
2907	tcp/udp	webmethods-b2b	WEBMETHODS B2B
2908	tcp/udp	mao	mao
2909	tcp/udp	funk-dialout	Funk Dialout
2910	tcp/udp	tdaccess	TDAccess
2911	tcp/udp	blockade	Blockade
2912	tcp/udp	epicon	Epicon
2913	tcp/udp	boosterware	Booster Ware
2914	tcp/udp	gamelobby	Game Lobby
2915	tcp/udp	tksocket	TK Socket
2916	tcp/udp	elvin_server	Elvin Server
2917	tcp/udp	elvin_client	Elvin Client
2918	tcp/udp	kastenchasepad	Kasten Chase Pad
2919	tcp/udp	roboer	roboER
2920	tcp/udp	roboeda	roboEDA
2921	tcp/udp	cesdcdman	CESD Contents Delivery Management
2922	tcp/udp	cesdcdtrn	CESD Contents Delivery Data Transfer
2923	tcp/udp	wta-wsp-wtp-s	WTA-WSP-WTP-S
2924	tcp/udp	precise-vip	PRECISE-VIP
2926	tcp/udp	mobile-file-dl	MOBILE-FILE-DL
2927	tcp/udp	unimobilectrl	UNIMOBILECTRL
2928	tcp/udp	redstone-cpss	REDSTONE-CPSS
2929	tcp/udp	amx-webadmin	AMX-WEBADMIN
2930	tcp/udp	amx-weblinx	AMX-WEBLINX
2931	tcp/udp	circle-x	Circle-X
2932	tcp/udp	incp	INCP
2933	tcp/udp	4-tieropmgw	4-TIER OPM GW
2934	tcp/udp	4-tieropmcli	4-TIER OPM CLI
2935	tcp/udp	qtp	QTP
2936	tcp/udp	otpatch	OTPatch
2937	tcp/udp	pnaconsult-lm	PNACONSULT-LM
2938	tcp/udp	sm-pas-1	SM-PAS-1
2939	tcp/udp	sm-pas-2	SM-PAS-2
2940	tcp/udp	sm-pas-3	SM-PAS-3
2941	tcp/udp	sm-pas-4	SM-PAS-4
2942	tcp/udp	sm-pas-5	SM-PAS-5
2943	tcp/udp	ttnrepository	TTNRepository
2944	tcp/udp	megaco-h248	Megaco H-248
2945	tcp/udp	h248-binary	H248 Binary
2946	tcp/udp	fjsvmpor	FJSVmpor
2947	tcp/udp	gpsd	GPSD
2948	tcp/udp	wap-push	WAP PUSH
2949	tcp/udp	wap-pushsecure	WAP PUSH SECURE
2950	tcp/udp	esip	ESIP
2951	tcp/udp	ottp	OTTP
2952	tcp/udp	mpfwsas	MPFWSAS
2953	tcp/udp	ovalarmsrv	OVALARMSRV
2954	tcp/udp	ovalarmsrv-cmd	OVALARMSRV-CMD
2955	tcp/udp	csnotify	CSNOTIFY
2956	tcp/udp	ovrimosdbman	OVRIMOSDBMAN
2957	tcp/udp	jmact5	JAMCT5
2958	tcp/udp	jmact6	JAMCT6
2959	tcp/udp	rmopagt	RMOPAGT
2960	tcp/udp	dfoxserver	DFOXSERVER
2961	tcp/udp	boldsoft-lm	BOLDSOFT-LM
2962	tcp/udp	iph-policy-cli	IPH-POLICY-CLI
2963	tcp/udp	iph-policy-adm	IPH-POLICY-ADM
2964	tcp/udp	bullant-srap	BULLANT SRAP
2965	tcp/udp	bullant-rap	BULLANT RAP
2966	tcp/udp	idp-infotrieve	IDP-INFOTRIEVE
2967	tcp/udp	ssc-agent	SSC-AGENT
2968	tcp/udp	enpp	ENPP
2969	tcp/udp	essp	ESSP
2970	tcp/udp	index-net	INDEX-NET
2971	tcp/udp	netclip	NetClip clipboard daemon
2972	tcp/udp	pmsm-webrctl	PMSM Webrctl
2973	tcp/udp	svnetworks	SV Networks
2974	tcp/udp	signal	Signal
2975	tcp/udp	fjmpcm	Fujitsu Configuration Management Service
2976	tcp/udp	cns-srv-port	CNS Server Port
2977	tcp/udp	ttc-etap-ns	TTCs Enterprise Test Access Protocol - NS
2978	tcp/udp	ttc-etap-ds	TTCs Enterprise Test Access Protocol - DS
2979	tcp/udp	h263-video	H.263 Video Streaming
2980	tcp/udp	wimd	Instant Messaging Service
2981	tcp/udp	mylxamport	MYLXAMPORT
2982	tcp/udp	iwb-whiteboard	IWB-WHITEBOARD
2983	tcp/udp	netplan	NETPLAN
2984	tcp/udp	hpidsadmin	HPIDSADMIN
2985	tcp/udp	hpidsagent	HPIDSAGENT
2986	tcp/udp	stonefalls	STONEFALLS
2987	tcp/udp	identify	identify
2988	tcp/udp	hippad	HIPPA Reporting Protocol
2989	tcp/udp	zarkov	ZARKOV Intelligent Agent Communication
2989 	udp 	# 	Remote Administration Tool - RAT
Brador
2990	tcp/udp	boscap	BOSCAP
2991	tcp/udp	wkstn-mon	WKSTN-MON
2992	tcp/udp	itb301	ITB301
2993	tcp/udp	veritas-vis1	VERITAS VIS1
2994	tcp/udp	veritas-vis2	VERITAS VIS2
2995	tcp/udp	idrs	IDRS
2996	tcp/udp	vsixml	vsixml
2997	tcp/udp	rebol	REBOL
2998	tcp/udp	realsecure	Real Secure
2999	tcp/udp	remoteware-un	RemoteWare Unassigned
3000	tcp/udp	hbci	HBCI
3000	tcp/udp	remoteware-cl	RemoteWare Client
3000 	tcp/udp 	# 	FirstClass
3000 	tcp/udp 	# 	MDaemon 3.1.1 Webconfig
3000 	tcp 	# 	Remote Shut, W32.Mimail
3001	tcp/udp	redwood-broker	Redwood Broker
3001 	tcp/udp 	#	MDaemon 3.1.1 Worldclient
3002	tcp/udp	exlm-agent	EXLM Agent
3002	tcp/udp	remoteware-srv	RemoteWare Server
3003	tcp/udp	cgms	CGMS
3004	tcp/udp	csoftragent	Csoft Agent
3005	tcp/udp	geniuslm	Genius License Manager
3006	tcp/udp	ii-admin	Instant Internet Admin
3007	tcp/udp	lotusmtap	Lotus Mail Tracking Agent Protocol
3008	tcp/udp	midnight-tech	Midnight Technologies
3009	tcp/udp	pxc-ntfy	PXC-NTFY
3010	tcp	gw	Telerate Workstation
3010	udp	ping-pong	Telerate Workstation
3011	tcp/udp	trusted-web	Trusted Web
3012	tcp/udp	twsdss	Trusted Web Client
3013	tcp/udp	gilatskysurfer	Gilat Sky Surfer
3014	tcp/udp	broker_service	Broker Service
3015	tcp/udp	nati-dstp	NATI DSTP
3016	tcp/udp	notify_srvr	Notify Server
3017	tcp/udp	event_listener	Event Listener
3018	tcp/udp	srvc_registry	Service Registry
3019	tcp/udp	resource_mgr	Resource Manager
3020	tcp/udp	cifs	CIFS
3021	tcp/udp	agriserver	AGRI Server
3022	tcp/udp	csregagent	CSREGAGENT
3023	tcp/udp	magicnotes	magicnotes
3024	tcp/udp	nds_sso	NDS_SSO
3024 	tcp 	# 	WinCrash
3025	tcp/udp	arepa-raft	Arepa Raft
3026	tcp/udp	agri-gateway	AGRI Gateway
3027	tcp/udp	LiebDevMgmt_C	LiebDevMgmt_C
3028	tcp/udp	LiebDevMgmt_DM	LiebDevMgmt_DM
3029	tcp/udp	LiebDevMgmt_A	LiebDevMgmt_A
3030	tcp/udp	arepa-cas	Arepa Cas
3031	tcp/udp	eppc	Remote AppleEvents/PPC Toolbox
3031 	tcp 	# 	Microspy
3032	tcp/udp	redwood-chat	Redwood Chat
3033	tcp/udp	pdb	PDB
3034	tcp/udp	osmosis-aeea	Osmosis / Helix (R) AEEA Port
3035	tcp/udp	fjsv-gssagt	FJSV gssagt
3036	tcp/udp	hagel-dump	Hagel DUMP
3037	tcp/udp	hp-san-mgmt	HP SAN Mgmt
3038	tcp/udp	santak-ups	Santak UPS
3039	tcp/udp	cogitate	"Cogitate, Inc."
3040	tcp/udp	tomato-springs	Tomato Springs
3041	tcp/udp	di-traceware	di-traceware
3042	tcp/udp	journee	journee
3043	tcp/udp	brp	BRP
3044	tcp/udp	epp	EndPoint Protocol
3045	tcp/udp	responsenet	ResponseNet
3046	tcp/udp	di-ase	di-ase
3047	tcp/udp	hlserver	Fast Security HL Server
3048	tcp/udp	pctrader	Sierra Net PC Trader
3049	tcp/udp	nsws	NSWS
3050	tcp/udp	gds_db	gds_db
3051	tcp/udp	galaxy-server	Galaxy Server
3052	tcp/udp	apc-3052	APC 3052
3053	tcp/udp	dsom-server	dsom-server
3054	tcp/udp	amt-cnf-prot	AMT CNF PROT
3055	tcp/udp	policyserver	Policy Server
3056	tcp/udp	cdl-server	CDL Server
3057	tcp/udp	goahead-fldup	GoAhead FldUp
3058	tcp/udp	videobeans	videobeans
3059	tcp/udp	qsoft	qsoft
3060	tcp/udp	interserver	interserver
3061	tcp/udp	cautcpd	cautcpd
3062	tcp/udp	ncacn-ip-tcp	ncacn-ip-tcp
3063	tcp/udp	ncadg-ip-udp	ncadg-ip-udp
3064	tcp/udp	rprt	Remote Port Redirector
3065	tcp/udp	slinterbase	slinterbase
3066	tcp/udp	netattachsdmp	NETATTACHSDMP
3067	tcp/udp	fjhpjp	FJHPJP
3067 	tcp 	# 	W32.Korgo
3068	tcp/udp	ls3bcast	ls3 Broadcast
3069	tcp/udp	ls3	ls3
3070	tcp/udp	mgxswitch	MGXSWITCH
3071	tcp/udp	csd-mgmt-port	ContinuStor Manager Port
3072	tcp/udp	csd-monitor	ContinuStor Monitor Port
3073	tcp/udp	vcrp	Very simple chatroom prot
3074	tcp/udp	xbox	Xbox game port
3075	tcp/udp	orbix-locator	Orbix 2000 Locator
3076	tcp/udp	orbix-config	Orbix 2000 Config
3077	tcp/udp	orbix-loc-ssl	Orbix 2000 Locator SSL
3078	tcp/udp	orbix-cfg-ssl	Orbix 2000 Locator SSL
3079	tcp/udp	lv-frontpanel	LV Front Panel
3080	tcp/udp	stm_pproc	stm_pproc
3081	tcp/udp	tl1-lv	TL1-LV
3082	tcp/udp	tl1-raw	TL1-RAW
3083	tcp/udp	tl1-telnet	TL1-TELNET
3084	tcp/udp	itm-mccs	ITM-MCCS
3085	tcp/udp	pcihreq	PCIHReq
3086	tcp/udp	jdl-dbkitchen	JDL-DBKitchen
3087	tcp/udp	asoki-sma	Asoki SMA
3088	tcp/udp	xdtp	eXtensible Data Transfer Protocol
3089	tcp/udp	ptk-alink	ParaTek Agent Linking
3090	tcp/udp	rtss	Rappore Session Services
3091	tcp/udp	1ci-smcs	1Ci Server Management
3092	tcp/udp	njfss	Netware sync services
3093	tcp/udp	rapidmq-center	Jiiva RapidMQ Center
3094	tcp/udp	rapidmq-reg	Jiiva RapidMQ Registry
3095	tcp/udp	panasas	Panasas rendevous port
3096	tcp/udp	ndl-aps	Active Print Server Port
3097	tcp/udp	#	Reserved
3097	sctp	iitu-bicc-stc	ITU-T Q.1902.1/Q.2150.3
3098	tcp/udp	umm-port	Universal Message Manager
3099	tcp/udp	chmd	CHIPSY Machine Daemon
3100	tcp/udp	opcon-xps	OpCon/xps
3101	tcp/udp	hp-pxpib	HP PolicyXpert PIB Server
3102	tcp/udp	slslavemon	SoftlinK Slave Mon Port
3103	tcp/udp	autocuesmi	Autocue SMI Protocol
3104	tcp	autocuelog	Autocue Logger Protocol
3104	udp	autocuetime	Autocue Time Service
3105	tcp/udp	cardbox	Cardbox
3106	tcp/udp	cardbox-http	Cardbox HTTP
3107	tcp/udp	business	Business protocol
3108	tcp/udp	geolocate	Geolocate protocol
3109	tcp/udp	personnel	Personnel protocol
3110	tcp/udp	sim-control	simulator control port
3111	tcp/udp	wsynch	Web Synchronous Services
3112	tcp/udp	ksysguard	KDE System Guard
3113	tcp/udp	cs-auth-svr	CS-Authenticate Svr Port
3114	tcp/udp	ccmad	CCM AutoDiscover
3115	tcp/udp	mctet-master	MCTET Master
3116	tcp/udp	mctet-gateway	MCTET Gateway
3117	tcp/udp	mctet-jserv	MCTET Jserv
3118	tcp/udp	pkagent	PKAgent
3119	tcp/udp	d2000kernel	D2000 Kernel Port
3120	tcp/udp	d2000webserver	D2000 Webserver Port
3121	tcp/udp	#	Unassigned
3122	tcp/udp	vtr-emulator	MTI VTR Emulator port
3123	tcp/udp	edix	EDI Translation Protocol
3124	tcp/udp	beacon-port	Beacon Port
3125	tcp/udp	a13-an	A13-AN Interface
3126	tcp/udp	ms-dotnetster	Microsoft .NETster Port
3127	tcp/udp	ctx-bridge	CTX Bridge Port
3127 	tcp/udp 	# 	W32.Mockbot, W32.Solame
3127-3198 	tcp/udp 	# 	Novarg(Mydoom), W32.HLLW.Deadhat
3128	tcp/udp	ndl-aas	Active API Server Port
3128 	tcp/udp 	# 	Squid
3128 	tcp 	# 	Reverse WWW Tunnel Backdoor,
RingZero, Mydoom, W32.HLLW.Deadhat
3129	tcp/udp	netport-id	NetPort Discovery Port
3129 	tcp 	# 	Masters Paradise
3130	tcp/udp	icpv2	ICPv2
3131	tcp/udp	netbookmark	Net Book Mark
3132	tcp/udp	ms-rule-engine	Microsoft Business Rule Engine Update Service
3133	tcp/udp	prism-deploy	Prism Deploy User Port
3134	tcp/udp	ecp	Extensible Code Protocol
3135	tcp/udp	peerbook-port	PeerBook Port
3136	tcp/udp	grubd	Grub Server Port
3137	tcp/udp	rtnt-1	rtnt-1 data packets
3138	tcp/udp	rtnt-2	rtnt-2 data packets
3139	tcp/udp	incognitorv	Incognito Rendez-Vous
3140	tcp/udp	ariliamulti	Arilia Multiplexor
3141	tcp/udp	vmodem	VMODEM
3142	tcp/udp	rdc-wh-eos	RDC WH EOS
3143	tcp/udp	seaview	Sea View
3144	tcp/udp	tarantella	Tarantella
3145	tcp/udp	csi-lfap	CSI-LFAP
3146	tcp/udp	bears-02	bears-02
3147	tcp/udp	rfio	RFIO
3148	tcp/udp	nm-game-admin	NetMike Game Administrator
3149	tcp/udp	nm-game-server	NetMike Game Server
3150	tcp/udp	nm-asses-admin	NetMike Assessor Administrator
3150 	tcp 	# 	The Invasor
3150 	udp 	# 	RAT:The DeepThroat trojan
Foreplay, Mini Backlash
3151	tcp/udp	nm-assessor	NetMike Assessor
3152	tcp/udp	feitianrockey	FeiTian Port
3153	tcp/udp	s8-client-port	S8Cargo Client Port
3154	tcp/udp	ccmrmi	ON RMI Registry
3155	tcp/udp	jpegmpeg	JpegMpeg Port
3156	tcp/udp	indura	Indura Collector
3157	tcp/udp	e3consultants	CCC Listener Port
3158	tcp/udp	stvp	SmashTV Protocol
3159	tcp/udp	navegaweb-port	NavegaWeb Tarification
3160	tcp/udp	tip-app-server	TIP Application Server
3161	tcp/udp	doc1lm	DOC1 License Manager
3162	tcp/udp	sflm	SFLM
3163	tcp/udp	res-sap	RES-SAP
3164	tcp/udp	imprs	IMPRS
3165	tcp/udp	newgenpay	Newgenpay Engine Service
3166	tcp/udp	qrepos	Quest Repository
3167	tcp/udp	poweroncontact	poweroncontact
3168	tcp/udp	poweronnud	poweronnud
3169	tcp/udp	serverview-as	SERVERVIEW-AS
3170	tcp/udp	serverview-asn	SERVERVIEW-ASN
3171	tcp/udp	serverview-gf	SERVERVIEW-GF
3172	tcp/udp	serverview-rm	SERVERVIEW-RM
3172 	tcp 	# 	W32.HLLW.Doomjuice
3173	tcp/udp	serverview-icc	SERVERVIEW-ICC
3174	tcp/udp	armi-server	ARMI Server
3175	tcp/udp	t1-e1-over-ip	T1_E1_Over_IP
3176	tcp/udp	ars-master	ARS Master
3177	tcp/udp	phonex-port	Phonex Protocol
3178	tcp/udp	radclientport	Radiance UltraEdge Port
3179	tcp/udp	h2gf-w-2m	H2GF W.2m Handover prot.
3180	tcp/udp	mc-brk-srv	Millicent Broker Server
3181	tcp/udp	bmcpatrolagent	BMC Patrol Agent
3182	tcp/udp	bmcpatrolrnvu	BMC Patrol Rendezvous
3183	tcp/udp	cops-tls	COPS/TLS
3184	tcp/udp	apogeex-port	ApogeeX Port
3185	tcp/udp	smpppd	SuSE Meta PPPD
3186	tcp/udp	iiw-port	IIW Monitor User Port
3187	tcp/udp	odi-port	Open Design Listen Port
3188	tcp/udp	brcm-comm-port	Broadcom Port
3189	tcp/udp	pcle-infex	Pinnacle Sys InfEx Port
3190	tcp/udp	csvr-proxy	ConServR Proxy
3191	tcp/udp	csvr-sslproxy	ConServR SSL Proxy
3192	tcp/udp	firemonrcc	FireMon Revision Control
3193	tcp/udp	spandataport	SpanDataPort
3194	tcp/udp	magbind	Rockstorm MAG protocol
3195	tcp/udp	ncu-1	Network Control Unit
3195 	tcp 	# 	IRC.Whisper
3196	tcp/udp	ncu-2	Network Control Unit
3197	tcp/udp	embrace-dp-s	Embrace Device Protocol Server
3198	tcp/udp	embrace-dp-c	Embrace Device Protocol Client
3199	tcp/udp	dmod-workspace	DMOD WorkSpace
3200	tcp/udp	tick-port	Press-sense Tick Port
3201	tcp/udp	cpq-tasksmart	CPQ-TaskSmart
3202	tcp/udp	intraintra	IntraIntra
3203	tcp/udp	netwatcher-mon	Network Watcher Monitor
3204	tcp/udp	netwatcher-db	Network Watcher DB Access
3205	tcp/udp	isns	iSNS Server Port
3206	tcp/udp	ironmail	IronMail POP Proxy
3207	tcp/udp	vx-auth-port	Veritas Authentication Port
3208	tcp/udp	pfu-prcallback	PFU PR Callback
3209	tcp/udp	netwkpathengine	HP OpenView Network Path Engine Server
3210	tcp/udp	flamenco-proxy	Flamenco Networks Proxy
3211	tcp/udp	avsecuremgmt	Avocent Secure Management
3212	tcp/udp	surveyinst	Survey Instrument
3213	tcp/udp	neon24x7	NEON 24X7 Mission Control
3214	tcp/udp	jmq-daemon-1	JMQ Daemon Port 1
3215	tcp/udp	jmq-daemon-2	JMQ Daemon Port 2
3216	tcp/udp	ferrari-foam	Ferrari electronic FOAM
3217	tcp/udp	unite	Unified IP & Telecomm Env
3218	tcp/udp	smartpackets	EMC SmartPackets
3219	tcp/udp	wms-messenger	WMS Messenger
3220	tcp/udp	xnm-ssl	XML NM over SSL
3221	tcp/udp	xnm-clear-text	XML NM over TCP
3222	tcp/udp	glbp	Gateway Load Balancing Pr
3223	tcp/udp	digivote	DIGIVOTE (R) Vote-Server
3224 	tcp/udp 	aes-discovery 	AES Discovery Port
3225 	tcp/udp 	fcip-port 	FCIP
3226 	tcp/udp 	isi-irp 	ISI Industry Software IRP
3227 	tcp/udp 	dwnmshttp 	DiamondWave NMS Server
3228 	tcp/udp 	dwmsgserver 	DiamondWave MSG Server
3229 	tcp/udp 	global-cd-port 	Global CD Port
3230 	tcp/udp 	sftdst-port 	Software Distributor Port
3231 	tcp/udp 	dsnl 	Delta Solutions Direct
3232 	tcp/udp 	mdtp 	MDT port
3233 	tcp/udp 	whisker 	WhiskerControl main port
3234 	tcp/udp 	alchemy 	Alchemy Server
3235 	tcp/udp 	mdap-port 	MDAP port
3236 	tcp/udp 	apparenet-ts 	appareNet Test Server
3237 	tcp/udp 	apparenet-tps 	appareNet Test Packet Sequencer
3238 	tcp/udp 	apparenet-as 	appareNet Analysis Server
3239 	tcp/udp 	apparenet-ui 	appareNet User Interface
3240 	tcp/udp 	triomotion 	Trio Motion Control Port
3241 	tcp/udp 	sysorb 	SysOrb Monitoring Server
3242 	tcp/udp 	sdp-id-port 	Session Description ID
3243 	tcp/udp 	timelot 	Timelot Port
3244 	tcp/udp 	onesaf 	OneSAF
3245 	tcp/udp 	vieo-fe 	VIEO Fabric Executive
3246 	tcp/udp 	dvt-system 	DVT SYSTEM PORT
3247 	tcp/udp 	dvt-data 	DVT DATA LINK
3248 	tcp/udp 	procos-lm 	PROCOS LM
3249 	tcp/udp 	ssp 	State Sync Protocol
3250 	tcp/udp 	hicp 	HMS hicp port
3251 	tcp/udp 	sysscanner 	Sys Scanner
3252 	tcp/udp 	dhe 	DHE port
3253 	tcp/udp 	pda-data 	PDA Data
3254 	tcp/udp 	pda-sys 	PDA System
3255 	tcp/udp 	semaphore 	Semaphore Connection Port
3256 	tcp/udp 	cpqrpm-agent 	Compaq RPM Agent Port
3256 	tcp/udp 	# 	W32.HLLW.Dax
3257 	tcp/udp 	cpqrpm-server 	Compaq RPM Server Port
3258 	tcp/udp 	ivecon-port 	Ivecon Server Port
3259 	tcp/udp 	epncdp2 	Epson Network Common Devi
3260	tcp/udp	iscsi-target	iSCSI port
3261	tcp/udp	winshadow	winShadow
3262	tcp/udp	necp	NECP
3263	tcp/udp	ecolor-imager	E-Color Enterprise Imager
3264	tcp/udp	ccmail	cc:mail/lotus
3264 	tcp/udp 	# 	Smother
3265	tcp/udp	altav-tunnel	Altav Tunnel
3266	tcp/udp	ns-cfg-server	NS CFG Server
3267	tcp/udp	ibm-dial-out	IBM Dial Out
3268	tcp/udp	msft-gc	Microsoft Global Catalog
3269	tcp/udp	msft-gc-ssl	Microsoft Global Catalog with LDAP/SSL
3270	tcp/udp	verismart	Verismart
3271	tcp/udp	csoft-prev	CSoft Prev Port
3272	tcp/udp	user-manager	Fujitsu User Manager
3273	tcp/udp	sxmp	Simple Extensible Multiplexed Protocol
3274	tcp/udp	ordinox-server	Ordinox Server
3275	tcp/udp	samd	SAMD
3276	tcp/udp	maxim-asics	Maxim ASICs
3277	tcp/udp	awg-proxy	AWG Proxy
3278	tcp/udp	lkcmserver	LKCM Server
3279	tcp/udp	admind	admind
3280	tcp/udp	vs-server	VS Server
3281	tcp/udp	sysopt	SYSOPT
3282	tcp/udp	datusorb	Datusorb
3283	tcp/udp	net-assistant	Net Assistant
3284	tcp/udp	4talk	4Talk
3285	tcp/udp	plato	Plato
3286	tcp/udp	e-net	E-Net
3287	tcp/udp	directvdata	DIRECTVDATA
3288	tcp/udp	cops	COPS
3289	tcp/udp	enpc	ENPC
3290	tcp/udp	caps-lm	CAPS LOGISTICS TOOLKIT - LM
3291	tcp/udp	sah-lm	S A Holditch & Associates - LM
3292	tcp/udp	cart-o-rama	Cart O Rama
3293	tcp/udp	fg-fps	fg-fps
3294	tcp/udp	fg-gip	fg-gip
3295	tcp/udp	dyniplookup	Dynamic IP Lookup
3296	tcp/udp	rib-slm	Rib License Manager
3297	tcp/udp	cytel-lm	Cytel License Manager
3298	tcp/udp	deskview	DeskView
3299	tcp/udp	pdrncs	pdrncs
3302	tcp/udp	mcs-fastmail	MCS Fastmail
3303	tcp/udp	opsession-clnt	OP Session Client
3304	tcp/udp	opsession-srvr	OP Session Server
3305	tcp/udp	odette-ftp	ODETTE-FTP
3306	tcp/udp	mysql	MySQL
3306 	tcp 	# 	Nemog
3307	tcp/udp	opsession-prxy	OP Session Proxy
3308	tcp/udp	tns-server	TNS Server
3309	tcp/udp	tns-adv	TNS ADV
3310	tcp/udp	dyna-access	Dyna Access
3311	tcp/udp	mcns-tel-ret	MCNS Tel Ret
3312	tcp/udp	appman-server	Application Management Server
3313	tcp/udp	uorb	Unify Object Broker
3314	tcp/udp	uohost	Unify Object Host
3315	tcp/udp	cdid	CDID
3316	tcp/udp	aicc-cmi	AICC/CMI
3317	tcp/udp	vsaiport	VSAI PORT
3318	tcp/udp	ssrip	Swith to Swith Routing Information Protocol
3319	tcp/udp	sdt-lmd	SDT License Manager
3320	tcp/udp	officelink2000	Office Link 2000
3321	tcp/udp	vnsstr	VNSSTR
3322-3325	tcp/udp	active-net	Active Networks
3326	tcp/udp	sftu	SFTU
3327	tcp/udp	bbars	BBARS
3328	tcp/udp	egptlm	Eaglepoint License Manager
3329	tcp/udp	hp-device-disc	HP Device Disc
3330	tcp/udp	mcs-calypsoicf	MCS Calypso ICF
3330-3332 	tcp/udp 	# 	Randex,Roxy(thanx Franz)
3331	tcp/udp	mcs-messaging	MCS Messaging
3332	tcp/udp	mcs-mailsvr	MCS Mail Server
3332 	tcp/udp 	# 	W32.Cycle
3333	tcp/udp	dec-notes	DEC Notes
3334	tcp/udp	directv-web	Direct TV Webcasting
3335	tcp/udp	directv-soft	Direct TV Software Updates
3336	tcp/udp	directv-tick	Direct TV Tickers
3337	tcp/udp	directv-catlg	Direct TV Data Catalog
3338	tcp/udp	anet-b	OMF data b
3339	tcp/udp	anet-l	OMF data l
3340	tcp/udp	anet-m	OMF data m
3341	tcp/udp	anet-h	OMF data h
3342	tcp/udp	webtie	WebTIE
3343	tcp/udp	ms-cluster-net	MS Cluster Net
3344	tcp/udp	bnt-manager	BNT Manager
3345	tcp/udp	influence	Influence
3346	tcp/udp	trnsprntproxy	Trnsprnt Proxy
3347	tcp/udp	phoenix-rpc	Phoenix RPC
3348	tcp/udp	pangolin-laser	Pangolin Laser
3349	tcp/udp	chevinservices	Chevin Services
3350	tcp/udp	findviatv	FINDVIATV
3351	tcp/udp	btrieve	Btrieve port
3352	tcp/udp	ssql	Scalable SQL
3353	tcp/udp	fatpipe	FATPIPE
3354	tcp/udp	suitjd	SUITJD
3355	tcp/udp	ordinox-dbase	Ordinox Dbase
3355 	tcp/udp 	# 	Hogle
3356	tcp/udp	upnotifyps	UPNOTIFYPS
3357	tcp/udp	adtech-test	Adtech Test IP
3358	tcp/udp	mpsysrmsvr	Mp Sys Rmsvr
3359	tcp/udp	wg-netforce	WG NetForce
3360	tcp/udp	kv-server	KV Server
3361	tcp/udp	kv-agent	KV Agent
3362	tcp/udp	dj-ilm	DJ ILM
3363	tcp/udp	nati-vi-server	NATI Vi Server
3364	tcp/udp	creativeserver	Creative Server
3365	tcp/udp	contentserver	Content Server
3366	tcp/udp	creativepartnr	Creative Partner
3367-3371	tcp/udp	satvid-datalnk	Satellite Video Data Link
3372	tcp/udp	tip2	TIP 2
3373	tcp/udp	lavenir-lm	Lavenir License Manager
3374	tcp/udp	cluster-disc	Cluster Disc
3375	tcp/udp	vsnm-agent	VSNM Agent
3376	tcp/udp	cdbroker	CD Broker
3377	tcp/udp	cogsys-lm	Cogsys Network License Manager
3378	tcp/udp	wsicopy	WSICOPY
3379	tcp/udp	socorfs	SOCORFS
3380	tcp/udp	sns-channels	SNS Channels
3381	tcp/udp	geneous	Geneous
3382	tcp/udp	fujitsu-neat	Fujitsu Network Enhanced Antitheft function
3383	tcp/udp	esp-lm	Enterprise Software Products License Manager
3384	tcp	hp-clic	Cluster Management Services
3384	udp	hp-clic	Hardware Management
3385	tcp/udp	qnxnetman	qnxnetman
3386	tcp	gprs-data	GPRS Data
3386	udp	gprs-sig	GPRS SIG
3387	tcp/udp	backroomnet	Back Room Net
3388	tcp/udp	cbserver	CB Server
3389	tcp/udp	ms-wbt-server	MS WBT Server
3390	tcp/udp	dsc	Distributed Service Coordinator
3391	tcp/udp	savant	SAVANT
3392	tcp/udp	efi-lm	EFI License Management
3393	tcp/udp	d2k-tapestry1	D2K Tapestry Client to Server
3394	tcp/udp	d2k-tapestry2	D2K Tapestry Server to Server
3395	tcp/udp	dyna-lm	Dyna License Manager (Elam)
3396	tcp/udp	printer_agent	Printer Agent
3397	tcp/udp	cloanto-lm	Cloanto License Manager
3398	tcp/udp	mercantile	Mercantile
3399	tcp/udp	csms	CSMS
3400	tcp/udp	csms2	CSMS2
3401	tcp/udp	filecast	filecast
3402	tcp/udp	fxaengine-net	FXa Engine Network Port
3403	tcp/udp	copysnap	CopySnap Server Port
3404	tcp/udp	#	Removed
3405	tcp/udp	nokia-ann-ch1	Nokia Announcement ch 1
3406	tcp/udp	nokia-ann-ch2	Nokia Announcement ch 2
3407	tcp/udp	ldap-admin	LDAP admin server port
3408	tcp/udp	issapi	POWERpack API Port
3409	tcp/udp	networklens	NetworkLens Event Port
3410	tcp/udp	networklenss	NetworkLens SSL Event
3410 	tcp/udp 	# 	OptixPro, W32.Mockbot
3411	tcp/udp	biolink-auth	BioLink Authenteon server
3412	tcp/udp	xmlblaster	xmlBlaster
3413	tcp/udp	svnet	SpecView Networking
3414	tcp/udp	wip-port	BroadCloud WIP Port
3415	tcp/udp	bcinameservice	BCI Name Service
3416	tcp/udp	commandport	AirMobile IS Command Port
3417	tcp/udp	csvr	ConServR file translation
3418	tcp/udp	rnmap	Remote nmap
3419	tcp/udp	softaudit	Isogon SoftAudit
3420	tcp/udp	ifcp-port	iFCP User Port
3421	tcp/udp	bmap	Bull Apprise portmapper
3422	tcp/udp	rusb-sys-port	Remote USB System Port
3422 	tcp/udp 	# 	IRC.Aladinz
3423	tcp/udp	xtrm	xTrade Reliable Messaging
3424	tcp/udp	xtrms	xTrade over TLS/SSL
3425	tcp/udp	agps-port	AGPS Access Port
3426	tcp/udp	arkivio	Arkivio Storage Protocol
3427	tcp/udp	websphere-snmp	WebSphere SNMP
3428	tcp/udp	twcss	2Wire CSS
3429	tcp/udp	gcsp	GCSP user port
3430	tcp/udp	ssdispatch	Scott Studios Dispatch
3431	tcp/udp	ndl-als	Active License Server Port
3432	tcp/udp	osdcp	Secure Device Protocol
3433	tcp/udp	alta-smp	Altaworks Service Management Platform
3434	tcp/udp	opencm	OpenCM Server
3435	tcp/udp	pacom	Pacom Security User Port
3436	tcp/udp	gc-config	GuardControl Exchange Protocol
3436-3437 	tcp 	# 	Netjoe
3437	tcp/udp	autocueds	Autocue Directory Service
3438	tcp/udp	spiral-admin	Spiralcraft Admin
3439	tcp/udp	hri-port	HRI Interface Port
3440	tcp/udp	ans-console	Net Steward Mgmt Console
3441	tcp/udp	connect-client	OC Connect Client
3442	tcp/udp	connect-server	OC Connect Server
3443	tcp/udp	ov-nnm-websrv	OpenView Network Node Manager WEB Server
3444	tcp/udp	denali-server	Denali Server
3445	tcp/udp	monp	Media Object Network
3446	tcp/udp	3comfaxrpc	3Com FAX RPC port
3447	tcp/udp	cddn	CompuDuo DirectNet
3448	tcp/udp	dnc-port	Discovery and Net Config
3449	tcp/udp	hotu-chat	HotU Chat
3450	tcp/udp	castorproxy	CAStorProxy
3451	tcp/udp	asam	ASAM Services
3452	tcp/udp	sabp-signal	SABP-Signalling Protocol
3453	tcp/udp	pscupd	PSC Update Port
3454	tcp	mira	Apple Remote Access Protocol
3455	tcp/udp	prsvp	RSVP Port
3456	tcp/udp	vat	VAT default data
3456 	tcp 	# 	Terror trojan, Fearic
3457	tcp/udp	vat-control	VAT default control
3458	tcp/udp	d3winosfi	D3WinOSFI
3459	tcp/udp	integral	TIP Integral
3459 	tcp 	# 	Eclipse 2000, Sanctuary
3460	tcp/udp	edm-manager	EDM Manger
3461	tcp/udp	edm-stager	EDM Stager
3462	tcp/udp	edm-std-notify	EDM STD Notify
3463	tcp/udp	edm-adm-notify	EDM ADM Notify
3464	tcp/udp	edm-mgr-sync	EDM MGR Sync
3465	tcp/udp	edm-mgr-cntrl	EDM MGR Cntrl
3466	tcp/udp	workflow	WORKFLOW
3467	tcp/udp	rcst	RCST
3468	tcp/udp	ttcmremotectrl	TTCM Remote Controll
3469	tcp/udp	pluribus	Pluribus
3470	tcp/udp	jt400	jt400
3471	tcp/udp	jt400-ssl	jt400-ssl
3472	tcp/udp	jaugsremotec-1	JAUGS N-G Remotec 1
3473	tcp/udp	jaugsremotec-2	JAUGS N-G Remotec 2
3474	tcp/udp	ttntspauto	TSP Automation
3475	tcp/udp	genisar-port	Genisar Comm Port
3476	tcp/udp	nppmp	NVIDIA Mgmt Protocol
3477	tcp/udp	ecomm	eComm link port
3478	tcp/udp	nat-stun-port	Simple Traversal of UDP Through
NAT (STUN) port
3479	tcp/udp	twrpc	2Wire RPC
3480	tcp/udp	plethora	Secure Virtual Workspace
3481	tcp/udp	cleanerliverc	CleanerLive remote ctrl
3482	tcp/udp	vulture	Vulture Monitoring System
3483	tcp/udp	slim-devices	Slim Devices Protocol
3484	tcp/udp	gbs-stp	GBS SnapTalk Protocol
3485	tcp/udp	celatalk	CelaTalk
3486	tcp/udp	ifsf-hb-port	IFSF Heartbeat Port
3487	tcp/udp	ltctcp	LISA TCP Transfer Channel
3488	tcp/udp	fs-rh-srv	FS Remote Host Server
3489	tcp/udp	dtp-dia	DTP/DIA
3490	tcp/udp	colubris	Colubris Management Port
3491	tcp/udp	swr-port	SWR Port
3492	tcp/udp	tvdumtray-port	TVDUM Tray Port
3493	tcp/udp	nut	Network UPS Tools
3494	tcp/udp	ibm3494	IBM 3494
3495	tcp/udp	seclayer-tcp	securitylayer over tcp
3496	tcp/udp	seclayer-tls	securitylayer over tls
3497	tcp/udp	ipether232port	ipEther232Port
3498	tcp/udp	dashpas-port	DASHPAS user port
3499	tcp/udp	sccip-media	SccIP Media
3500	tcp/udp	rtmp-port	RTMP Port
3501	tcp/udp	isoft-p2p	iSoft-P2P
3502	tcp/udp	avinstalldisc	Avocent Install Discovery
3503	tcp/udp	lsp-ping	MPLS LSP-echo Port
3504	tcp/udp	ironstorm	IronStorm game server
3505	tcp/udp	ccmcomm	CCM communications port
3506	tcp/udp	apc-3506	APC 3506
3507	tcp/udp	nesh-broker	Nesh Broker Port
3508	tcp/udp	interactionweb	Interaction Web
3509	tcp/udp	vt-ssl	Virtual Token SSL Port
3510	tcp/udp	xss-port	XSS Port
3511	tcp/udp	webmail-2	WebMail/2
3512	tcp/udp	aztec	Aztec Distribution Port
3513	tcp/udp	arcpd	Adaptec Remote Protocol
3514	tcp/udp	must-p2p	MUST Peer to Peer
3515	tcp/udp	must-backplane	MUST Backplane
3515 	tcp 	# 	W32.Spybot
3516	tcp/udp	smartcard-port	Smartcard Port
3517	tcp/udp	802-11-iapp	IEEE 802.11 WLANs WG IAPP
3518	tcp/udp	artifact-msg	Artifact Message Server
3519	tcp	nvmsgd	Netvion Messenger Port
3519	udp	galileo	Netvion Galileo Port
3520	tcp/udp	galileolog	Netvion Galileo Log Port
3520 	tcp 	# 	Outgoing TCP attempts to these ports
could be trying to contact netrek
metaservers. See also port 3521.
3521	tcp/udp	mc3ss	Telequip Labs MC3SS
3521 	tcp 	# 	An old network-based multiplayer game
based upon StarTrek. Also uses ports
3520 for metaservers and port 2592
for gaming traffic.
3522	tcp/udp	nssocketport	DO over NSSocketPort
3523	tcp/udp	odeumservlink	Odeum Serverlink
3524	tcp/udp	ecmport	ECM Server port
3525	tcp/udp	eisport	EIS Server port
3526	tcp/udp	starquiz-port	starQuiz Port
3527	tcp/udp	beserver-msg-q	VERITAS Backup Exec Server
3527 	tcp 	# 	Zvrop
3528	tcp/udp	jboss-iiop	JBoss IIOP
3529	tcp/udp	jboss-iiop-ssl	JBoss IIOP/SSL
3530	tcp/udp	gf	Grid Friendly
3531	tcp/udp	joltid	Joltid
3532	tcp/udp	raven-rmp	Raven Remote Management Control
3533	tcp/udp	urld-port	URL Daemon Port
3534	tcp/udp	#	Unassigned
3535	tcp/udp	ms-la	MS-LA
3536	tcp/udp	snac	SNAC
3537	tcp/udp	ni-visa-remote	Remote NI-VISA port
3538	tcp/udp	ibm-diradm	IBM Directory Server
3539	tcp/udp	ibm-diradm-ssl	IBM Directory Server SSL
3540	tcp/udp	pnrp-port	PNRP User Port
3541	tcp/udp	voispeed-port	VoiSpeed Port
3542	tcp/udp	hacl-monitor	HA cluster monitor
3543	tcp/udp	qftest-lookup	qftest Lookup Port
3544	tcp/udp	teredo	Teredo Port
3545	tcp/udp	camac	CAMAC equipment
3546	tcp/udp	#	Unassigned
3547	tcp/udp	symantec-sim	Symantec SIM
3547 	tcp 	# 	Amitis
3548	tcp/udp	interworld	Interworld
3549	tcp/udp	tellumat-nms	Tellumat MDR NMS
3550	tcp/udp	ssmpp	Secure SMPP
3551	tcp/udp	apcupsd	Apcupsd Information Port
3552	tcp/udp	taserver	TeamAgenda Server Port
3553	tcp/udp	rbr-discovery	Red Box Recorder ADP
3554	tcp/udp	questnotify	Quest Notification Server
3555	tcp/udp	razor	Vipul's Razor
3556	tcp/udp	sky-transport	Sky Transport Protocol
3557	tcp/udp	personalos-001	PersonalOS Comm Port
3558	tcp/udp	mcp-port	MCP user port
3559	tcp/udp	cctv-port	CCTV control port
3560	tcp/udp	iniserve-port	INIServe port
3561	tcp/udp	bmc-onekey	BMC-OneKey
3562	tcp/udp	sdbproxy	SDBProxy
3563	tcp/udp	watcomdebug	Watcom Debug
3564	tcp/udp	esimport	Electromed SIM port
3565	tcp/sctp	m2pa	M2PA
3566	tcp/udp	quest-launcher	Quest Agent Manager
3567	tcp/udp	emware-oft	emWare OFT Services
3568	tcp/udp	emware-epss	emWare EMIT/Secure
3569	tcp/udp	mbg-ctrl	Meinberg Control Service
3570	tcp/udp	mccwebsvr-port	MCC Web Server Port
3571	tcp/udp	megardsvr-port	MegaRAID Server Port
3572	tcp/udp	megaregsvrport	Registration Server Port
3573	tcp/udp	tag-ups-1	Advantage Group UPS Suite
3574	tcp/udp	dmaf-server	DMAF Server
3575	tcp/udp	ccm-port	Coalsere CCM Port
3576	tcp/udp	cmc-port	Coalsere CMC Port
3577	tcp/udp	config-port	Configuration Port
3578	tcp/udp	data-port	Data Port
3579	tcp/udp	ttat3lb	Tarantella Load Balancing
3580	tcp/udp	nati-svrloc	NATI-ServiceLocator
3581	tcp/udp	kfxaclicensing	Ascent Capture Licensing
3582	tcp/udp	press	PEG PRESS Server
3583	tcp/udp	canex-watch	CANEX Watch System
3584	tcp/udp	u-dbap	U-DBase Access Protocol
3585	tcp/udp	emprise-lls	Emprise License Server
3586	tcp/udp	emprise-lsc	License Server Console
3587	tcp/udp	p2pgroup	Peer to Peer Grouping
3588	tcp/udp	sentinel	Sentinel Server
3589	tcp/udp	isomair	isomair
3590	tcp/udp	wv-csp-sms	WV CSP SMS Binding
3591	tcp/udp	gtrack-server	LOCANIS G-TRACK Server
3592	tcp/udp	gtrack-ne	LOCANIS G-TRACK NE Port
3593	tcp/udp	bpmd	BP Model Debugger
3594	tcp/udp	mediaspace	MediaSpace
3595	tcp/udp	shareapp	ShareApp
3596	tcp/udp	iw-mmogame	Illusion Wireless MMOG
3597	tcp/udp	a14	A14 (AN-to-SC/MM)
3598	tcp/udp	a15	A15 (AN-to-AN)
3599	tcp/udp	quasar-server	Quasar Accounting Server
3600  	tcp/udp  	trap-daemon  	text relay-answer
3601 	tcp/udp 	visinet-gui 	Visinet Gui
3602 	tcp/udp 	infiniswitchcl 	InfiniSwitch Mgr Client
3603 	tcp/udp 	int-rcv-cntrl 	Integrated Rcvr Control
3604 	tcp/udp 	bmc-jmx-port 	BMC JMX Port
3605 	tcp/udp 	comcam-io 	ComCam IO Port
3606 	tcp/udp 	splitlock 	Splitlock Server
3607 	tcp/udp 	precise-i3 	Precise I3
3608 	tcp/udp 	trendchip-dcp 	Trendchip control protocol
3609 	tcp/udp 	cpdi-pidas-cm 	CPDI PIDAS Connection Mon
3610 	tcp/udp 	echonet 	ECHONET
3611 	tcp/udp 	six-degrees 	Six Degrees Port
3612 	tcp/udp 	hp-dataprotect 	HP Data Protector
3613 	tcp/udp 	alaris-disc 	Alaris Device Discovery
3614 	tcp/udp 	sigma-port 	Invensys Sigma Port
3615 	tcp/udp 	start-network 	Start Messaging Network
3616 	tcp/udp 	cd3o-protocol 	cd3o Control Protocol
3617 	tcp/udp 	sharp-server 	ATI SHARP Logic Engine
3618 	tcp/udp 	aairnet-1 	AAIR-Network 1
3619 	tcp/udp 	aairnet-2 	AAIR-Network 2
3620 	tcp/udp 	ep-pcp 	EPSON Projector Control Port
3621 	tcp/udp 	ep-nsp 	EPSON Network Screen Port
3622 	tcp/udp 	ff-lr-port 	FF LAN Redundancy Port
3623 	tcp/udp 	haipe-discover 	HAIPIS Dynamic Discovery
3624 	tcp/udp 	dist-upgrade 	Distributed Upgrade Port
3625 	tcp/udp 	volley 	Volley
3626 	tcp/udp 	bvcdaemon-port 	bvControl Daemon
3627 	tcp/udp 	jamserverport 	Jam Server Port
3628 	tcp/udp 	ept-machine 	EPT Machine Interface
3629 	tcp/udp 	escvpnet 	ESC/VP.net
3630 	tcp/udp 	cs-remote-db 	C&S Remote Database Port
3631 	tcp/udp 	cs-services 	C&S Web Services Port
3632 	tcp/udp 	distcc 	distributed compiler
3633 	tcp/udp 	wacp 	Wyrnix AIS port
3634 	tcp/udp 	hlibmgr 	hNTSP Library Manager
3635 	tcp/udp 	sdo 	Simple Distributed Objects
3636 	tcp/udp 	opscenter 	OpsCenter
3637 	tcp/udp 	scservp 	Customer Service Port
3638 	tcp/udp 	ehp-backup 	EHP Backup Protocol
3639 	tcp/udp 	xap-ha 	Extensible Automation
3640 	tcp/udp 	netplay-port1 	Netplay Port 1
3641 	tcp/udp 	netplay-port2 	Netplay Port 2
3642 	tcp/udp 	juxml-port 	Juxml Replication port
3643 	tcp/udp 	audiojuggler 	AudioJuggler
3644 	tcp/udp 	ssowatch 	ssowatch
3645 	tcp/udp 	cyc 	Cyc
3646 	tcp/udp 	xss-srv-port 	XSS Server Port
3647 	tcp/udp 	splitlock-gw 	Splitlock Gateway
3648 	tcp/udp 	fjcp 	Fujitsu Cooperation Port
3649 	tcp/udp 	nmmp 	Nishioka Miyuki Msg Protocol
3650 	tcp/udp 	prismiq-plugin 	PRISMIQ VOD plug-in
3651 	tcp/udp 	xrpc-registry 	XRPC Registry
3652 	tcp/udp 	vxcrnbuport 	VxCR NBU Default Port
3653 	tcp/udp 	tsp 	Tunnel Setup Protocol
3654 	tcp/udp 	vaprtm 	VAP RealTime Messenger
3655 	tcp/udp 	abatemgr 	ActiveBatch Exec Agent
3656 	tcp/udp 	abatjss 	ActiveBatch Job Scheduler
3657 	tcp/udp 	immedianet-bcn 	ImmediaNet Beacon
3658 	tcp/udp 	ps-ams 	PlayStation AMS (Secure)
3659 	tcp/udp 	apple-sasl 	Apple SASL
3660 	tcp/udp 	can-nds-ssl 	Candle Directory Services using SSL
3661 	tcp/udp 	can-ferret-ssl 	Candle Directory Services using SSL
3662 	tcp/udp 	pserver 	pserver
3663 	tcp/udp 	dtp 	DIRECWAY Tunnel Protocol
3664 	tcp/udp 	ups-engine 	UPS Engine Port
3665 	tcp/udp 	ent-engine 	Enterprise Engine Port
3666 	tcp/udp 	eserver-pap 	IBM eServer PAP
3667 	tcp/udp 	infoexch 	IBM Information Exchange
3668 	tcp/udp 	dell-rm-port 	Dell Remote Management
3669 	tcp/udp 	casanswmgmt 	CA SAN Switch Management
3670 	tcp/udp 	smile 	SMILE TCP/UDP Interface
3671 	tcp/udp 	efcp 	e Field Control (EIBnet)
3672 	tcp/udp 	lispworks-orb 	LispWorks ORB
3673 	tcp/udp 	mediavault-gui 	Openview Media Vault GUI
3674 	tcp/udp 	wininstall-ipc 	WinINSTALL IPC Port
3675 	tcp/udp 	calltrax 	CallTrax Data Port
3676 	tcp/udp 	va-pacbase 	VisualAge Pacbase server
3677 	tcp/udp 	roverlog 	RoverLog IPC
3678 	tcp/udp 	ipr-dglt 	DataGuardianLT
3679 	tcp/udp 	newton-dock 	Newton Dock
3680 	tcp/udp 	npds-tracker 	NPDS Tracker
3681 	tcp/udp 	bts-x73 	BTS X73 Port
3682 	tcp/udp 	cas-mapi 	EMC SmartPackets-MAPI
3683 	tcp/udp 	bmc-ea 	BMC EDV/EA
3684 	tcp/udp 	faxstfx-port 	FAXstfX
3685 	tcp/udp 	dsx-agent 	DS Expert Agent
3686 	tcp/udp 	tnmpv2 	Trivial Network Management
3687 	tcp/udp 	simple-push 	simple-push
3688 	tcp/udp 	simple-push-s 	simple-push Secure
3689 	tcp/udp 	daap 	Digital Audio Access Protocol
3690 	tcp/udp 	svn 	Subversion
3691 	tcp/udp 	magaya-network 	Magaya Network Port
3692 	tcp/udp 	intelsync 	Brimstone IntelSync
3693 	tcp/udp 	gttp 	GTTP
3694 	tcp/udp 	vpntpp 	VPN Token Propagation Protocol
3695 	tcp/udp 	bmc-data-coll 	BMC Data Collection
3696 	tcp/udp 	telnetcpcd 	Telnet Com Port Control
3697 	tcp/udp 	nw-license 	NavisWorks License System
3698 	tcp/udp 	sagectlpanel 	SAGECTLPANEL
3699 	tcp/udp 	kpn-icw 	Internet Call Waiting
3700	tcp/udp	lrs-paging	LRS NetPage
3701	tcp/udp	netcelera	NetCelera
3702	tcp/udp	ws-discovery	UPNP v2 Discovery
3703	tcp/udp	adobeserver-3	Adobe Server 3
3704	tcp/udp	adobeserver-4	Adobe Server 4
3705	tcp/udp	adobeserver-5	Adobe Server 5
3706	tcp/udp	rt-event	Real-Time Event Port
3707	tcp/udp	rt-event-s	Real-Time Event Secure Port
3708	tcp/udp	#	Unassigned
3700 	tcp 	# 	Portal of Doom
3709	tcp/udp	ca-idms	CA-IDMS Server
3710	tcp/udp	portgate-auth	PortGate Authentication
3711	tcp/udp	edb-server2	EBD Server 2
3712	tcp/udp	sentinel-ent	Sentinel Enterprise
3713	tcp/udp	tftps	TFTP over TLS
3714	tcp/udp	delos-dms	DELOS Direct Messaging
3715	tcp/udp	anoto-rendezv	Anoto Rendezvous Port
3716	tcp/udp	wv-csp-sms-cir	WV CSP SMS CIR Channel
3717	tcp/udp	wv-csp-udp-cir	WV CSP UDP/IP CIR Channel
3718	tcp/udp	opus-services	OPUS Server Port
3719	tcp/udp	itelserverport	iTel Server Port
3720	tcp/udp	ufastro-instr	UF Astro. Instr. Services
3721	tcp/udp	xsync	Xsync
3722	tcp/udp	xserveraid	Xserve RAID
3723	tcp/udp	sychrond	Sychron Service Daemon
3724	tcp/udp	battlenet	Blizzard Battlenet
3725	tcp/udp	na-er-tip	Netia NA-ER Port
3726	tcp/udp	array-manager	Xyratex Array Manager
3727	tcp/udp	e-mdu	Ericsson Mobile Data Unit
3728	tcp/udp	e-woa	Ericsson Web on Air
3729	tcp/udp	fksp-audit	Fireking Audit Port
3730	tcp/udp	client-ctrl	Client Control
3731	tcp/udp	smap	Service Manager
3732	tcp/udp	m-wnn	Mobile Wnn
3733	tcp/udp	multip-msg	Multipuesto Msg Port
3734	tcp/udp	synel-data	Synel Data Collection Port
3735	tcp/udp	pwdis	Password Distribution
3736	tcp/udp	rs-rmi	RealSpace RMI
3737	tcp/udp	#	Unassigned
3737 	tcp/udp 	# 	Helios
3738	tcp/udp	versatalk	versaTalk Server Port
3739	tcp/udp	launchbird-lm	Launchbird LicenseManager
3740	tcp/udp	heartbeat	Heartbeat Protocol
3741	tcp/udp	wysdma	WysDM Agent
3742	tcp/udp	cst-port	CST - Configuration & Service Tracker
3743	tcp/udp	ipcs-command	IP Control Systems Ltd.
3744	tcp/udp	sasg	SASG
3745	tcp/udp	gw-call-port	GWRTC Call Port
3746	tcp/udp	linktest	LXPRO.COM LinkTest
3747	tcp/udp	linktest-s	LXPRO.COM LinkTest SSL
3748	tcp/udp	webdata	webData
3749	tcp/udp	cimtrak	CimTrak
3750	tcp/udp	cbos-ip-port	CBOS/IP ncapsalation port
3751	tcp/udp	gprs-cube	CommLinx GPRS Cube
3752	tcp/udp	vipremoteagent	Vigil-IP RemoteAgent
3753	tcp/udp	nattyserver	NattyServer Port
3754	tcp/udp	timestenbroker	TimesTen Broker Port
3755	tcp/udp	sas-remote-hlp	SAS Remote Help Server
3756	tcp/udp	canon-capt	Canon CAPT Port
3757	tcp/udp	grf-port	GRF Server Port
3758	tcp/udp	apw-registry	apw RMI registry
3759	tcp/udp	exapt-lmgr	Exapt License Manager
3760	tcp/udp	adtempusclient	adTempus Client
3761	tcp/udp	gsakmp	gsakmp port
3762	tcp/udp	gbs-smp	GBS SnapMail Protocol
3763	tcp/udp	xo-wave	XO Wave Control Port
3764	tcp/udp	mni-prot-rout	MNI Protected Routing
3765	tcp/udp	rtraceroute	Remote Traceroute
3766	tcp/udp	#	Unassigned
3767	tcp/udp	listmgr-port	ListMGR Port
3768	tcp/udp	rblcheckd	rblcheckd server daemon
3769	tcp/udp	haipe-otnk	HAIPE Network Keying
3770	tcp/udp	cindycollab	Cinderella Collaboration
3771	tcp/udp	paging-port	RTP Paging Port
3772	tcp/udp	ctp	Chantry Tunnel Protocol
3773	tcp/udp	ctdhercules	ctdhercules
3774	tcp/udp	zicom	ZICOM
3775	tcp/udp	ispmmgr	ISPM Manager Port
3776	tcp/udp	dvcprov-port	Device Provisioning Port
3777	tcp/udp	jibe-eb	Jibe EdgeBurst
3777 	tcp 	# 	PsychWard
3778	tcp/udp	c-h-it-port	Cutler-Hammer IT Port
3779	tcp/udp	cognima	Cognima Replication
3780	tcp/udp	nnp	Nuzzler Network Protocol
3781	tcp/udp	abcvoice-port	ABCvoice server port
3782	tcp/udp	iso-tp0s	Secure ISO TP0 port
3783	tcp/udp	bim-pem	Impact Mgr./PEM Gateway
3784	tcp/udp	bfd	BFD
3785	tcp/udp	bfd-control	BFD-Control
3786	tcp/udp	upstriggervsw	VSW Upstrigger port
3787	tcp/udp	fintrx	Fintrx
3788	tcp/udp	isrp-port	SPACEWAY Routing port
3789	tcp/udp	remotedeploy	RemoteDeploy Administration Port
3790	tcp/udp	quickbooksrds	QuickBooks RDS
3791	tcp/udp	tvnetworkvideo	TV NetworkVideo Data port
3791 	tcp 	# 	Total Solar Eclypse
3792	tcp/udp	sitewatch	e-watch, Inc. SiteWatch
3793	tcp/udp	dcsoftware	DataCore Software
3794	tcp/udp	jaus	JAUS Robots
3795	tcp/udp	myblast	myBLAST Mekentosj port
3796	tcp/udp	spw-dialer	Spaceway Dialer
3797	tcp/udp	idps	idps
3798	tcp/udp	minilock	Minilock
3799	tcp/udp	radius-dynauth	RADIUS Dynamic Authorization
3800	tcp/udp	pwgpsi	Print Services Interface
3800 	tcp 	# 	Roxy
3801	tcp/udp	#	Unassigned
3801 	tcp 	# 	Total Solar Eclypse,Roxy
3802	tcp/udp	vhd	VHD
3802 	tcp 	# 	Roxy
3803	tcp/udp	soniqsync	SoniqSync
3804	tcp/udp	iqnet-port	Harman IQNet Port
3805	tcp/udp	tcpdataserver	ThorGuard Server Port
3806	tcp/udp	wsmlb	Remote System Manager
3807	tcp/udp	spugna	SpuGNA Communication Port
3808-3809	tcp/udp	#	Unassigned
3810	tcp/udp	wlanauth	WLAN AS server
3811	tcp/udp	amp	AMP
3812	tcp/udp	neto-wol-server	netO WOL Server
3813	tcp/udp	rap-ip	Rhapsody Interface Protocol
3814	tcp/udp	neto-dcs	netO DCS
3815	tcp/udp	lansurveyorxml	LANsurveyor XML
3816	tcp/udp	sunlps-http	Sun Local Patch Server
3817	tcp/udp	tapeware	Yosemite Tech Tapeware
3818	tcp/udp	crinis-hb	Crinis Heartbeat
3819	tcp/udp	epl-slp	EPL Sequ Layer Protocol
3820	tcp/udp	scp	Siemens AuD SCP
3821	tcp/udp	pmcp	ATSC PMCP Standard
3822-3837	tcp/udp	#	Unassigned
3838	tcp/udp	sos	Scito Object Server
3839	tcp/udp	amx-rms	AMX Resource Management Suite
3840	tcp/udp	flirtmitmir	www.FlirtMitMir.de
3841	tcp/udp	zfirm-shiprush3	Z-Firm ShipRush v3
3842	tcp/udp	nhci	NHCI status port
3843	tcp/udp	quest-agent	Quest Common Agent
3844	tcp/udp	rnm	RNM
3845	tcp/udp	v-one-spp	V-ONE Single Port Proxy
3846	tcp/udp	an-pcp	Astare Network PCP
3847	tcp/udp	msfw-control	MS Firewall Control
3848	tcp/udp	item	IT Environmental Monitor
3849	tcp/udp	spw-dnspreload	SPACEWAY DNS Preload
3850	tcp/udp	qtms-bootstrap	QTMS Bootstrap Protocol
3851	tcp/udp	spectraport	SpectraTalk Port
3852	tcp/udp	sse-app-config	SSE App Configuration
3853	tcp/udp	sscan	SONY scanning protocol
3854	tcp/udp	stryker-com	Stryker Comm Port
3855	tcp/udp	opentrac	OpenTRAC
3856	tcp/udp	informer	INFORMER
3857	tcp/udp	trap-port	Trap Port
3858	tcp/udp	trap-port-mom	Trap Port MOM
3859	tcp/udp	nav-port	Navini Port
3860	tcp/udp	ewlm	eWLM
3861	tcp/udp	winshadow-hd	winShadow Host Discovery
3862	tcp/udp	giga-pocket	GIGA-POCKET
3863	tcp/udp	asap-tcp	asap tcp port
3864	tcp/udp	asap-tcp-tls	asap/tls tcp port
3865	tcp/udp	xpl	xpl automation protocol
3866	tcp/udp	dzdaemon	Sun SDViz DZDAEMON Port
3867	tcp/udp	dzoglserver	Sun SDViz DZOGLSERVER Port
3868	tcp/sctp	diameter	DIAMETER
3869	tcp/udp	ovsam-mgmt	hp OVSAM MgmtServer Disco
3870	tcp/udp	ovsam-d-agent	hp OVSAM HostAgent Disco
3871	tcp/udp	avocent-adsap	Avocent DS Authorization
3872	tcp/udp	oem-agent	OEM Agent
3873	tcp/udp	fagordnc	fagordnc
3874	tcp/udp	sixxsconfig	SixXS Configuration
3875	tcp/udp	pnbscada	PNBSCADA
3876	tcp/udp	dl_agent	DirectoryLockdown Agent
3877	tcp/udp	xmpcr-interface	XMPCR Interface Port
3878	tcp/udp	fotogcad	FotoG CAD interface
3879	tcp/udp	appss-lm	appss license manager
3879 	tcp 	# 	An exploit for the gdm XDMCP
vulnerability will bind a root shell
to this port.
3880	tcp/udp	microgrid	microgrid
3881	tcp/udp	idac	Data Acquisition and Control
3882	tcp/udp	msdts1	DTS Service Port
3883	tcp/udp	vrpn	VR Peripheral Network
3884	tcp/udp	softrack-meter	SofTrack Metering
3885	tcp/udp	topflow-ssl	TopFlow SSL
3886	tcp/udp	nei-management	NEI management port
3887	tcp/udp	leogic-data	Leogic Data Transport
3888	tcp/udp	leogic-services	Leogic Services
3889	tcp/udp	dandv-tester	D and V Tester Control Port
3890	tcp/udp	ndsconnect	Niche Data Server Connect
3891	tcp/udp	rtc-pm-port	Oracle RTC-PM port
3892	tcp/udp	pcc-image-port	PCC-image-port
3893	tcp/udp	cgi-starapi	CGI StarAPI Server
3894	tcp/udp	syam-agent	SyAM Agent Port
3895	tcp/udp	syam-smc	SyAm SMC Service Port
3896	tcp/udp	sdo-tls	Simple Distributed Objects over TLS
3897	tcp/udp	sdo-ssh	Simple Distributed Objects over SSH
3898	tcp/udp	senip	IAS, Inc. SmartEye NET Internet Protocol
3899	tcp/udp	itv-control	ITV Port
3900	tcp/udp	udt_os	Unidata UDT OS
3901	tcp/udp	nimsh	NIM Service Handler
3902	tcp/udp	nimaux	NIMsh Auxiliary Port
3903	tcp/udp	charsetmgr	CharsetMGR
3904	tcp/udp	omnilink-port	Arnet Omnilink Port
3905	tcp/udp	mupdate	Mailbox Update (MUPDATE) protocol
3906	tcp/udp	topovista-data	TopoVista elevation data
3907	tcp/udp	imoguia-port	Imoguia Port
3908	tcp/udp	hppronetman	HP Procurve NetManagement
3909	tcp/udp	surfcontrolcpa	SurfControl CPA
3910	tcp/udp	prnrequest	Printer Request Port
3911	tcp/udp	prnstatus	Printer Status Port
3912	tcp/udp	gbmt-stars	Global Maintech Stars
3913	tcp/udp	listcrt-port	ListCREATOR Port
3914	tcp/udp	listcrt-port-2	ListCREATOR Port 2
3915	tcp/udp	agcat	Auto-Graphics Cataloging
3916	tcp/udp	wysdmc	WysDM Controller
3917	tcp/udp	aftmux	AFT multiplex port
3918	tcp/udp	pktcablemmcops	PacketCableMultimediaCOPS
3919	tcp/udp	hyperip	HyperIP
3920	tcp/udp	exasoftport1	Exasoft IP Port
3921	tcp/udp	herodotus-net	Herodotus Net
3922	tcp/udp	sor-update	Soronti Update Port
3923	tcp/udp	symb-sb-port	Symbian Service Broker
3924	tcp/udp	mpl-gprs-port	MPL_GPRS_PORT
3925	tcp/udp	zmp	Zoran Media Port
3926	tcp/udp	winport	WINPort
3927	tcp/udp	natdataservice	ScsTsr
3928	tcp/udp	netboot-pxe	PXE NetBoot Manager
3929	tcp/udp	smauth-port	AMS Port
3930	tcp/udp	syam-webserver	Syam Web Server Port
3931	tcp/udp	msr-plugin-port	MSR Plugin Port
3932	tcp/udp	dyn-site	Dynamic Site System
3933	tcp/udp	plbserve-port	PL/B App Server User Port
3934	tcp/udp	sunfm-port	PL/B File Manager Port
3935	tcp/udp	sdp-portmapper	SDP Port Mapper Protocol
3936	tcp/udp	mailprox	Mailprox
3937	tcp/udp	dvbservdscport	DVB Service Disc Port
3938	tcp/udp	dbcontrol_agent	Oracle dbControl Agent po
3939	tcp/udp	aamp	Anti-virus Application Management
Port
3940	tcp/udp	xecp-node	XeCP Node Service
3941	tcp/udp	homeportal-web	Home Portal Web Server
3942	tcp/udp	srdp	satellite distribution
3943	tcp/udp	tig	TetraNode Ip Gateway
3944	tcp/udp	sops	S-Ops Management
3945	tcp/udp	emcads	EMCADS Server Port
3946	tcp/udp	backupedge	BackupEDGE Server
3947	tcp/udp	ccp	Connect and Control Protocol for Consumer,
Commercial, and Industrial Electronic Devices
3948	tcp/udp	apdap	Anton Paar Device Administration Protocol
3949	tcp/udp	drip	Dynamic Routing Information Protocol
3950	tcp/udp	namemunge	Name Munging
3951	tcp/udp	pwgippfax	PWG IPP Facsimile
3952	tcp/udp	i3-sessionmgr	I3 Session Manager
3953	tcp/udp	xmlink-connect	Eydeas XMLink Connect
3954-3983	tcp/udp	#	Unassigned
3984	tcp/udp	mapper-nodemgr	MAPPER network node manager
3985	tcp/udp	mapper-mapethd	MAPPER TCP/IP server
3986	tcp/udp	mapper-ws_ethd	MAPPER workstation server
3987	tcp/udp	centerline	Centerline
3988-3994	tcp/udp	#	Unassigned
3995	tcp/udp	iss-mgmt-ssl	ISS Management Svcs SSL
3996	tcp/udp	abcsoftware	abcsoftware-01
3997-3999	tcp/udp	#	Unassigned
4000	tcp/udp	terabase	Terabase
4000 	tcp 	# 	SkyDance
4000 	udp 	# 	ICQ uses this as a control port.
4000 	udp 	# 	Command and Conquer (UDP)
The game "Command and Conquer"
by Weswood Studios uses this UDP port.
Also uses UDP port 5400.
4000 	udp 	# 	W32.Witty
4001	tcp/udp	newoak	NewOak
4001 	tcp 	# 	OptixPro
4002	tcp/udp	pxc-spvr-ft	pxc-spvr-ft
4003	tcp/udp	pxc-splr-ft	pxc-splr-ft
4004	tcp/udp	pxc-roid	pxc-roid
4005	tcp/udp	pxc-pin	pxc-pin
4006	tcp/udp	pxc-spvr	pxc-spvr
4007	tcp/udp	pxc-splr	pxc-splr
4008	tcp/udp	netcheque	NetCheque accounting
4009	tcp/udp	chimera-hwm	Chimera HWM
4010	tcp/udp	samsung-unidex	Samsung Unidex
4011	tcp/udp	altserviceboot	Alternate Service Boot
4012	tcp/udp	pda-gate	PDA Gate
4013	tcp/udp	acl-manager	ACL Manager
4014	tcp/udp	taiclock	TAICLOCK
4015	tcp/udp	talarian-mcast1	Talarian Mcast
4016	tcp/udp	talarian-mcast2	Talarian Mcast
4017	tcp/udp	talarian-mcast3	Talarian Mcast
4018	tcp/udp	talarian-mcast4	Talarian Mcast
4019	tcp/udp	talarian-mcast5	Talarian Mcast
4020	tcp/udp	trap	TRAP Port
4021	tcp/udp	nexus-portal	Nexus Portal
4022	tcp/udp	dnox	DNOX
4023	tcp/udp	esnm-zoning	ESNM Zoning Port
4024	tcp/udp	tnp1-port	TNP1 User Port
4025	tcp/udp	partimage	Partition Image Port
4026	tcp/udp	as-debug	Graphical Debug Server
4027	tcp/udp	bxp	bitxpress
4028	tcp/udp	dtserver-port	DTServer Port
4029	tcp/udp	ip-qsig	IP Q signaling protocol
4030	tcp/udp	jdmn-port	Accell/JSP Daemon Port
4031	tcp/udp	suucp	UUCP over SSL
4032	tcp/udp	vrts-auth-port	VERITAS Authorization Service
4033	tcp/udp	sanavigator	SANavigator Peer Port
4034	tcp/udp	ubxd	Ubiquinox Daemon
4035	tcp/udp	wap-push-http	WAP Push OTA-HTTP port
4036	tcp/udp	wap-push-https	WAP Push OTA-HTTP secure
4037-4039	tcp/udp	#	Unassigned
4040	tcp/udp	yo-main	Yo.net main service
4041	tcp/udp	houston	Rocketeer-Houston
4042	tcp/udp	ldxp	LDXP
4043-4044	tcp/udp	#	Unassigned
4045 	udp 	ldxp 	Network Lock Manager (nlockmgr) on Sun Solaris.
4046-4095	tcp/udp	#	Unassigned
4092 	tcp 	# 	WinCrash
4096	tcp/udp	bre	BRE (Bridge Relay Element)
4097	tcp/udp	patrolview	Patrol View
4098	tcp/udp	drmsfsd	drmsfsd
4099	tcp/udp	dpcp	DPCP
4100	tcp/udp	igo-incognito	IGo Incognito Data Port
4101-4110	tcp/udp	#	Unassigned
4111	tcp/udp	xgrid	Xgrid
4112-4113	tcp/udp	#	Unassigned
4114	tcp/udp	jomamqmonitor	JomaMQMonitor
4115-4131	tcp/udp	#	Unassigned
4128 	tcp/udp 	# 	RCServ
4132	tcp/udp	nuts_dem	NUTS Daemon
4133	tcp/udp	nuts_bootp	NUTS Bootp Server
4134	tcp/udp	nifty-hmi	NIFTY-Serve HMI protocol
4135-4137	tcp/udp	#	Unassigned
4138	tcp/udp	nettest	nettest
4139-4140	tcp/udp	#	Unassigned
4141	tcp/udp	oirtgsvc	Workflow Server
4142	tcp/udp	oidocsvc	Document Server
4143	tcp/udp	oidsr	Document Replication
4144	tcp/udp	#	Unassigned
4144 	tcp 	# 	CIM (Compuserve Information Manager)
4145	tcp/udp	vvr-control	VVR Control
4146-4153	tcp/udp	#	Unassigned
4154	tcp/udp	atlinks	atlinks device discovery
4155-4159	tcp/udp	#	Unassigned
4160	tcp/udp	jini-discovery	Jini Discovery
4161-4198	tcp/udp	#	Unassigned
4191 	tcp 	# 	Sdbot
4199	tcp/udp	eims-admin	EIMS ADMIN
4200-4299	tcp/udp	vrml-multi-use	VRML Multi User Systems
4242 	tcp/udp 	# 	This port number is widely used on the net
for MUDs (Multi-User-Dungeons), a type of
chat system. It is also frequently used as
an example port in code demonstrations
or as an alternate HTTP port. The reason
this is so popular is becuase it repeats
the number 42, a popular number among
computer geeks. In Douglas Adams classic
book "Hitch Hikers Guide to the Galaxy",
the number "42" is the answer to life,
the universe, and everything.
o This port is used (TCP) for a remote admin
Trojan called "Virtual Hacking Machine".
o This port is used for configuration for the
Payline e-commerce package.
o Connectix VideoPhone uses this port
for something.
o IBM's version of UNIX, AIX, has a C++
source browser (part of IBM's CSet package)
that listens at this port and is susceptable
to a buffer overflow.
4242 	tcp 	# 	Nemog
4300	tcp/udp	corelccam	Corel CCam
4300 	tcp 	# 	Smokodoor
4301-4320	tcp/udp	#	Unassigned
4321	tcp/udp	rwhois	Remote Who Is
4321 	tcp 	# 	BoBo
4333 	tcp/udp 	# 	mSQL
4343	tcp/udp	unicall	UNICALL
4344	tcp/udp	vinainstall	VinaInstall
4345	tcp/udp	m4-network-as	Macro 4 Network AS
4346	tcp/udp	elanlm	ELAN LM
4347	tcp/udp	lansurveyor	LAN Surveyor
4348	tcp/udp	itose	ITOSE
4349	tcp/udp	fsportmap	File System Port Map
4350	tcp/udp	net-device	Net Device
4351	tcp/udp	plcy-net-svcs	PLCY Net Services
4352	tcp/udp	#	Unassigned
4353	tcp/udp	f5-iquery	F5 iQuery
4354	tcp/udp	qsnet-trans	QSNet Transmitter
4355	tcp/udp	qsnet-workst	QSNet Workstation
4356	tcp/udp	qsnet-assist	QSNet Assistant
4357	tcp/udp	qsnet-cond	QSNet Conductor
4358	tcp/udp	qsnet-nucl	QSNet Nucleus
4359-4368	tcp/udp	#	Unassigned
4369	tcp/udp	epmd	Erlang Port Mapper Daemon
4370-4399	tcp/udp	#	Unassigned
4400	tcp/udp	ds-srv	ASIGRA Services
4401	tcp/udp	ds-srvr	ASIGRA Televaulting DS-System Service
4402	tcp/udp	ds-clnt	ASIGRA Televaulting DS-Client Service
4403	tcp/udp	ds-user	ASIGRA Televaulting DS-Client Monitoring/Management
4404	tcp/udp	ds-admin	ASIGRA Televaulting DS-System Monitoring/Management
4405	tcp/udp	ds-mail	ASIGRA Televaulting Message Level Restore service
4406	tcp/udp	ds-slp	ASIGRA Televaulting DS-Sleeper Service
4407-4425	tcp/udp	#	Unassigned
4426	tcp/udp	beacon-port-2	SMARTS Beacon Port
4427-4441	tcp/udp	#	Unassigned
4432-4433 	tcp/udp 	# 	Acidoor
4442	tcp/udp	saris	Saris
4443	tcp/udp	pharos	Pharos
4443 	tcp/udp 	# 	AOL Instant Messenger(thanx A. Cow)
4444	tcp/udp	krb524	KRB524
4444	tcp/udp	nv-video	NV Video default
4444 	tcp/udp 	# 	Napster, Prosiak, Swift Remote, W32.Blaster.Worm,
W32.Mockbot, W32.HLLW.Donk
4445	tcp/udp	upnotifyp	UPNOTIFYP
4446	tcp/udp	n1-fwp	N1-FWP
4447	tcp/udp	n1-rmgmt	N1-RMGMT
4448	tcp/udp	asc-slmd	ASC Licence Manager
4449	tcp/udp	privatewire	PrivateWire
4450	tcp/udp	camp	Camp
4451	tcp/udp	ctisystemmsg	CTI System Msg
4452	tcp/udp	ctiprogramload	CTI Program Load
4453	tcp/udp	nssalertmgr	NSS Alert Manager
4454	tcp/udp	nssagentmgr	NSS Agent Manager
4455	tcp/udp	prchat-user	PR Chat User
4456	tcp/udp	prchat-server	PR Chat Server
4457	tcp/udp	prRegister	PR Register
4458-4499	tcp/udp	#	Unassigned
4500	tcp/udp	ipsec-nat-t	IPsec NAT-Traversal
4501	tcp/udp	#	De-registered (2001 June 08)
4502-4544	tcp/udp	#	Unassigned
4527 	tcp/udp 	# 	Zvrop
4545	tcp/udp	worldscores	WorldScores
4546	tcp/udp	sf-lm	SF License Manager (Sentinel)
4547	tcp/udp	lanner-lm	Lanner License Manager
4548-4554	tcp/udp	#	Unassigned
4555	tcp/udp	rsip	RSIP Port
4556-4558	tcp/udp	#	Unassigned
4559	tcp/udp	hylafax	HylaFAX
4560-4558	tcp/udp	#	Unassigned
4567	tcp/udp	tram	TRAM
4567 	tcp 	# 	File Nail
4568	tcp/udp	bmc-reporting	BMC Reporting
4569	tcp/udp	iax	Inter-Asterisk eXchange
4570-4599	tcp/udp	#	Unassigned
4590 	tcp 	# 	ICQ Trojan
4600	tcp/udp	piranha1	Piranha1
4601	tcp/udp	piranha2	Piranha2
4602-4657	tcp/udp	#	Unassigned
4658	tcp/udp	playsta2-app	PlayStation2 App Port
4659	tcp/udp	playsta2-lob	PlayStation2 Lobby Port
4627 	tcp/udp 	# 	Lala
4646 	tcp 	# 	Nemog
4660	tcp/udp	smaclmgr	smaclmgr
4661	tcp/udp	kar2ouche	Kar2ouche Peer location service
4661 	tcp 	# 	Nemog
4662-4671	tcp/udp	#	Unassigned
4672	tcp/udp	rfa	remote file access server
4673-4751	tcp/udp	#	Unassigned
4751 	tcp/udp 	# 	W32.Beagle, Mitglieder
4752	tcp/udp	snap	Simple Network Audio Protocol
4753-4799	tcp/udp	#	Unassigned
4800	tcp/udp	iims	Icona Instant Messenging System
4801	tcp/udp	iwec	Icona Web Embedded Chat
4802	tcp/udp	ilss	Icona License System Server
4803-4826	tcp/udp	#	Unassigned
4827	tcp/udp	htcp	HTCP
4828-4836	tcp/udp	#	Unassigned
4837	tcp/udp	varadero-0	Varadero-0
4838	tcp/udp	varadero-1	Varadero-1
4839	tcp/udp	varadero-2	Varadero-2
4840-4847	tcp/udp	#	Unassigned
4848	tcp/udp	appserv-http	App Server - Admin HTTP
4849	tcp/udp	appserv-https	App Server - Admin HTTPS
4850	tcp/udp	sun-as-nodeagt	Sun App Server - NA
4851-4867	tcp/udp	#	Unassigned
4868	tcp/udp	phrelay	Photon Relay
4869	tcp/udp	phrelaydbg	Photon Relay Debug
4870-4884	tcp/udp	#	Unassigned
4885	tcp/udp	abbs	ABBS
4886-4893	tcp/udp	#	Unassigned
4894	tcp/udp	lyskom	LysKOM Protocol A
4895-4898	tcp/udp	#	Unassigned
4899	tcp/udp	radmin-port	RAdmin Port
4899 	tcp 	# 	W32.Rahack
4900-4982	tcp/udp	#	Unassigned
4912 	tcp 	# 	Mirab
4950 	tcp 	# 	ICQ Trojan
4983	tcp/udp	att-intercom	AT&T Intercom
4984-4986	tcp/udp	#	Unassigned
4987	tcp/udp	smar-se-port1	SMAR Ethernet Port 1
4988	tcp/udp	smar-se-port2	SMAR Ethernet Port 2
4989	tcp/udp	parallel	Parallel for GAUSS (tm)
4990-4999	tcp/udp	#	Unassigned
4999 	tcp/udp 	# 	Ripjac
5000	tcp/udp	commplex-main	 
5000 	tcp/udp 	# 	Sockets de Troie
(A French Trojan Horse and virus)
5000 	tcp 	# 	Back Door Setup, Blazer5, Bubbel, ICKiller, Ra1d,
Sockets des Troie port 5001 Back Door Setup,
W32.Bobax, Trojan.Webus
5001	tcp/udp	commplex-link	 
5001 	tcp/udp 	# 	Sockets de Troie
(A French Trojan Horse and virus)
5002	tcp/udp	rfe	radio free ethernet
5002 	tcp/udp 	# 	Shaft DDoS analysis
5002 	tcp 	# 	cd00r
5003	tcp	fmpro-internal	"FileMaker, Inc. - Proprietary transport"
5003	udp	fmpro-internal	"FileMaker, Inc. - Proprietary name binding"
5004	tcp/udp	avt-profile-1	avt-profile-1
5004 	udp 	# 	RTP(Real Time Protocol)
5005	tcp/udp	avt-profile-2	avt-profile-2
5005 	udp 	# 	RTP(Real Time Protocol)
5006	tcp/udp	wsm-server	wsm server
5007	tcp/udp	wsm-server-ssl	wsm server ssl
5008	tcp/udp	synapsis-edge	Synapsis EDGE
5009	tcp/udp	#	Unassigned
5010	tcp/udp	telelpathstart	TelepathStart
5010 	tcp/udp 	# 	Yahoo! Messenger
5010 	tcp 	# 	Solo
5011	tcp/udp	telelpathattack	TelepathAttack
5011 	tcp 	# 	One of the Last Trojans - OOTLT, modified
5012-5019	tcp/udp	#	Unassigned
5020	tcp/udp	zenginkyo-1	zenginkyo-1
5021	tcp/udp	zenginkyo-2	zenginkyo-2
5022	tcp/udp	mice	mice server
5023	tcp/udp	htuilsrv	Htuil Server for PLD2
5024	tcp/udp	scpi-telnet	SCPI-TELNET
5025	tcp/udp	scpi-raw	SCPI-RAW
5026-5041	tcp/udp	#	Unassigned
5025 	tcp 	# 	WM Remote KeyLogger
5031-5032 	tcp 	# 	Net Metropolitan
5042	tcp/udp	asnaacceler8db	asnaacceler8db
5043-5049	tcp/udp	#	Unassigned
5050	tcp/udp	mmcc	multimedia conference control tool
5050	tcp/udp	#	Common for eggdrop
5051	tcp/udp	ita-agent	ITA Agent
5052	tcp/udp	ita-manager	ITA Manager
5053-5054	tcp/udp	#	Unassigned
5055	tcp/udp	unot	UNOT
5056	tcp/udp	intecom-ps1	Intecom PS 1
5057	tcp/udp	intecom-ps2	Intecom PS 2
5058-5059	tcp/udp	#	Unassigned
5060	tcp/udp	sip	SIP
5061	tcp/udp	sip-tls	SIP-TLS
5062-5063	tcp/udp	#	Unassigned
5064	tcp/udp	ca-1	Channel Access 1
5065	tcp/udp	ca-2	Channel Access 2
5066-5067	tcp/udp	#	Unassigned
5066	tcp/udp	stanag-5066	STANAG-5066-SUBNET-INTF
5062-5068	tcp/udp	#	Unassigned
5069	tcp/udp	i-net-2000-npr	I/Net 2000-NPR
5070	tcp/udp	#	Unassigned
5071	tcp/udp	powerschool	PowerSchool
5072-5080	tcp/udp	#	Unassigned
5081	sctp	sdl-ets	SDL - Ent Trans Server
5082-5089	tcp/udp	#	Unassigned
5090	sctp	car	Candidate AR
5091	sctp	cxtp	Context Transfer Protocol
5092	tcp/udp	#	Unassigned
5093	tcp/udp	sentinel-lm	Sentinel LM
5094-5098	tcp/udp	#	Unassigned
5099	tcp/udp	sentlm-srv2srv	SentLM Srv2Srv
5100	tcp/udp	#	Unassigned
5101	tcp/udp	talarian-tcp	Talarian_TCP
5102-5132	tcp/udp	#	Unassigned
5111 	tcp/udp 	# 	W32.Korgo
5133	tcp/udp	nbt-pc	Policy Commander
5134-5136	tcp/udp	#	Unassigned
5137	tcp/udp	ctsd	MyCTS server port
5138-5144	tcp/udp	#	Unassigned
5145	tcp/udp	rmonitor_secure	RMONITOR SECURE
5146-5149	tcp/udp	#	Unassigned
5150	tcp/udp	atmp	Ascend Tunnel Management Protocol
5151	tcp	esri_sde	ESRI SDE Instance
5151	udp	esri_sde	ESRI SDE Remote Start
5151 	tcp/udp 	# 	Optix
5152	tcp/udp	sde-discovery	ESRI SDE Instance Discovery
5153	tcp/udp	#	Unassigned
5154	tcp/udp	bzflag	BZFlag game server
5155-5164	tcp/udp	#	Unassigned
5165	tcp/udp	ife_icorp	ife_1corp
5166-5189	tcp/udp	#	Unassigned
5180 	tcp/udp 	# 	Peeper, Netscape(thanx Bill?)
5190	tcp/udp	aol	America-Online
5191	tcp/udp	aol-1	AmericaOnline1
5192	tcp/udp	aol-2	AmericaOnline2
5193	tcp/udp	aol-3	AmericaOnline3
5194-5199	tcp/udp	#	Unassigned
5200	tcp/udp	targus-getdata	TARGUS GetData
5201	tcp/udp	targus-getdata1	TARGUS GetData 1
5202	tcp/udp	targus-getdata2	TARGUS GetData 2
5203	tcp/udp	targus-getdata3	TARGUS GetData 3
5204-5221	tcp/udp	#	Unassigned
5222	tcp/udp	xmpp-client	XMPP Client Connection
5223-5224	tcp/udp	#	Unassigned
5225	tcp/udp	hp-server	HP Server
5226	tcp/udp	hp-status	HP Status
5227-5235	tcp/udp	#	Unassigned
5277 	tcp/udp 	# 	WinJank
5236	tcp/udp	padl2sim	 
5237-5249	tcp/udp	#	Unassigned
5250	tcp/udp	igateway	iGateway
5251	tcp/udp	caevms	CA eTrust VM Service
5252	tcp/udp	movaz-ssc	Movaz SSC
5253-5264	tcp/udp	#	Unassigned
5264	tcp/udp	3com-njack-1	3Com Network Jack Port 1
5265	tcp/udp	3com-njack-2	3Com Network Jack Port 2
5266-5268	tcp/udp	#	Unassigned
5269	tcp/udp	xmpp-server	XMPP Server Connection
5270-5271	tcp/udp	#	Unassigned
5272	tcp/udp	pk	PK
5273-5281	tcp/udp	#	Unassigned
5282	tcp/udp	transmit-port	Marimba Transmitter Port
5283-5299	tcp/udp	#	Unassigned
5300	tcp/udp	hacl-hb	HA cluster heartbeat
5300 	tcp 	# 	W32.Kibuv.Worm
5301	tcp/udp	hacl-gs	HA cluster general services
5302	tcp/udp	hacl-cfg	HA cluster configuration
5303	tcp/udp	hacl-probe	HA cluster probing
5304	tcp/udp	hacl-local	HA Cluster Commands
5305	tcp/udp	hacl-test	HA Cluster Test
5306	tcp/udp	sun-mc-grp	Sun MC Group
5307	tcp/udp	sco-aip	SCO AIP
5308	tcp/udp	cfengine	CFengine
5309	tcp/udp	jprinter	J Printer
5310	tcp/udp	outlaws	Outlaws
5311	tcp/udp	#	Unassigned
5312	tcp/udp	permabit-cs	Permabit Client-Server
5313	tcp/udp	rrdp	Real-time & Reliable Data
5314	tcp/udp	opalis-rbt-ipc	opalis-rbt-ipc
5315	tcp/udp	hacl-poll	HA Cluster UDP Polling
5316-5350	tcp/udp	#	Unassigned
5321 	tcp 	# 	Firehotcker
5326 	tcp/udp 	# 	Snowdoor
5328 	tcp/udp 	# 	Snowdoor
5333 	tcp 	# 	Backage, NetDemon
5343 	tcp 	# 	wCrat - WC Remote Administration Tool
5351	tcp/udp	nat-pmp	NAT Port Mapping Protocol
5352	tcp/udp	#	Unassigned
5353	tcp/udp	mdns	Multicast DNS
5353 	udp 	# 	WebRamp control
5354	tcp/udp	mdnsresponder	Multicast DNS Responder IPC
5355	tcp/udp	llmnr	LLMNR
5356-5399	tcp/udp	#	Unassigned
5373 	tcp 	# 	W32.Gluber
5400	tcp/udp	excerpt	Excerpt Search
5400-5402 	tcp 	# 	Back Construction, Blade Runner
5400 	udp 	# 	The game "Command and Conquer"
5401	tcp/udp	excerpts	Excerpt Search Secure
5402	tcp/udp	mftp	MFTP
5403	tcp/udp	hpoms-ci-lstn	HPOMS-CI-LSTN
5404	tcp/udp	hpoms-dps-lstn	HPOMS-DPS-LSTN
5405	tcp/udp	netsupport	NetSupport
5406	tcp/udp	systemics-sox	Systemics Sox
5407	tcp/udp	foresyte-clear	Foresyte-Clear
5408	tcp/udp	foresyte-sec	Foresyte-Sec
5409	tcp/udp	salient-dtasrv	Salient Data Server
5410	tcp/udp	salient-usrmgr	Salient User Manager
5411	tcp/udp	actnet	ActNet
5412	tcp/udp	continuus	Continuus
5413	tcp/udp	wwiotalk	WWIOTALK
5414	tcp/udp	statusd	StatusD
5415	tcp/udp	ns-server	NS Server
5416	tcp/udp	sns-gateway	SNS Gateway
5417	tcp/udp	sns-agent	SNS Agent
5418	tcp/udp	mcntp	MCNTP
5418 	tcp/udp 	# 	DarkSky
5419	tcp/udp	dj-ice	DJ-ICE
5419 	tcp/udp 	# 	DarkSky
5420	tcp/udp	cylink-c	Cylink-C
5421	tcp/udp	netsupport2	Net Support 2
5422	tcp/udp	salient-mux	Salient MUX
5423	tcp/udp	virtualuser	VIRTUALUSER
5424	tcp/udp	beyond-remote	Beyond Remote
5425	tcp/udp	#	Unassigned
5424-5426 	tcp/udp 	# 	W32.Mydoom
5426	tcp/udp	devbasic	DEVBASIC
5427	tcp/udp	sco-peer-tta	SCO-PEER-TTA
5428	tcp/udp	telaconsole	TELACONSOLE
5429	tcp/udp	base	Billing and Accounting System Exchange
5430	tcp/udp	radec-corp	RADEC CORP
5431	tcp/udp	park-agent	PARK AGENT
5432	tcp/udp	postgresql	PostgreSQL Database
5433-5434	tcp/udp	#	Unassigned
5435	tcp/udp	dttl	Data Tunneling Transceiver Linking (DTTL)
5436-5452	tcp/udp	#	Unassigned
5453	tcp/udp	surebox	SureBox
5454	tcp/udp	apc-5454	APC 5454
5455	tcp/udp	apc-5455	APC 5455
5456	tcp/udp	apc-5456	APC 5456
5457-5460	tcp/udp	#	Unassigned
5461	tcp/udp	silkmeter	SILKMETER
5462	tcp/udp	ttl-publisher	TTL Publisher
5463	tcp/udp	ttlpriceproxy	TTL Price Proxy
5464	tcp/udp	#	Unassigned
5465	tcp/udp	netops-broker	NETOPS-BROKER
5466-5499	tcp/udp	#	Unassigned
5467 	tcp 	# 	W32.Kobot
5500	tcp/udp	fcp-addr-srvr1	fcp-addr-srvr1
5500 	udp 	# 	SecurID ACE (Access Control) server
5501	tcp/udp	fcp-addr-srvr2	fcp-addr-srvr2
5501 	udp 	# 	SecurID ACE/Server Slave
5502	tcp/udp	fcp-srvr-inst1	fcp-srvr-inst1
5503	tcp/udp	fcp-srvr-inst2	fcp-srvr-inst2
5504	tcp/udp	fcp-cics-gw1	fcp-cics-gw1
5505-5552	tcp/udp	#	Unassigned
5512 	tcp 	# 	Illusion Mailer
5534 	tcp 	# 	The Flu
5550 	tcp 	# 	Xtcp
5553	tcp/udp	sgi-eventmond	SGI Eventmond Port
5554	tcp/udp	sgi-esphttp	SGI ESP HTTP
5554 	tcp 	# 	W32.Sasser, W32.Dabber
5555	tcp/udp	personal-agent	Personal Agent
5555 	tcp 	# 	ServeMe, OptixPro, Sysbug
5556-5565	tcp/udp	#	Unassigned
5556 	tcp 	# 	HP-UX rwd (remove watch)
5556-5567 	tcp 	# 	BO Facil
5566	tcp/udp	udpplus	UDPPlus
5567	tcp/udp	emware-moap	emWare Multicast OAP
5568-5598	tcp/udp	#	Unassigned
5569 	tcp 	# 	Robo-Hack
5599	tcp/udp	esinstall	Enterprise Security Remote Install
5599 	tcp 	# 	Mitglieder
5600	tcp/udp	esmmanager	Enterprise Security Manager
5601	tcp/udp	esmagent	Enterprise Security Agent
5602	tcp/udp	a1-msc	A1-MSC
5603	tcp/udp	a1-bs	A1-BS
5604	tcp/udp	a3-sdunode	A3-SDUNode
5605	tcp/udp	a4-sdunode	A4-SDUNode
5606-5630	tcp/udp	#	Unassigned
5631	tcp/udp	pcanywheredata	pcANYWHEREdata
5632	tcp/udp	pcanywherestat	pcANYWHEREstat
5633-5672	tcp/udp	#	Unassigned
5637-5638 	tcp 	# 	PC Crasher
5665 	tcp 	# 	W32.Kipis
5673	tcp/udp	jms	JACL Message Server
5674	tcp/udp	hyperscsi-port	HyperSCSI Port
5675	tcp/udp/sctp	v5ua	V5UA application port
5676	tcp/udp	raadmin	RA Administration
5677	tcp/udp	questdb2-lnchr	Quest Central DB2 Launchr
5678	tcp/udp	rrac	Remote Replication Agent Connection
5678 	tcp/udp 	# 	A port for remote execution using the
crexd/srexd services.
5678 	tcp/udp 	# 	A frequent port some picks at random.
5678 	tcp/udp 	# 	Port 5678 was originally specified for
the PPTP protocol, but when the standard
was ratified, port 1723 was chosen instead.
5678 	tcp 	# 	Port 5678 is the default port for the
com.hp.util.rcat Java package (from
Hewlett-Packard). This is a simple
debugging package.
5678 	udp 	# 	osagent communication
5679	tcp/udp	dccm	Direct Cable Connect Manager
5679 	tcp/udp 	# 	W32.HLLW.Nautic
5680-5687	tcp/udp	#	Unassigned
5688	tcp/udp	ggz	GGZ Gaming Zone
5689-5712	tcp/udp	#	Unassigned
5695 	tcp/udp 	# 	Assasin
5713	tcp/udp	proshareaudio	proshare conf audio
5714	tcp/udp	prosharevideo	proshare conf video
5715	tcp/udp	prosharedata	proshare conf data
5716	tcp/udp	prosharerequest	proshare conf request
5717	tcp/udp	prosharenotify	proshare conf notify
5718-5719	tcp/udp	#	Unassigned
5720	tcp/udp	ms-licensing	MS-Licensing
5721	tcp/udp	dtpt	Desktop Passthru Service
5722-5728	tcp/udp	#	Unassigned
5729	tcp/udp	openmail	Openmail User Agent Layer
5730	tcp/udp	unieng	Steltor's calendar access
5731-5740	tcp/udp	#	Unassigned
5732 	tcp 	# 	W32.Bolgi.Worm
5741	tcp/udp	ida-discover1	IDA Discover Port 1
5742	tcp/udp	ida-discover2	IDA Discover Port 2
5742 	tcp 	# 	WinCrash
5743	tcp/udp	#	Unassigned
5744	tcp/udp	watchdoc	Watchdoc Server
5745	tcp/udp	fcopy-server	fcopy-server
5746	tcp/udp	fcopys-server	fcopys-server
5747-5754	tcp/udp	#	Unassigned
5748 	tcp 	# 	Ranck
5755	tcp/udp	openmailg	OpenMail Desk Gateway server
5757	tcp/udp	x500ms	OpenMail X.500 Directory Server
5760 	tcp 	# 	Portmap Remote Root Linux Exploit
5766	tcp/udp	openmailns	OpenMail NewMail Server
5767	tcp/udp	s-openmail	OpenMail Suer Agent Layer (Secure)
5768	tcp/udp	openmailpxy	OpenMail CMTS Server
5769-5770	tcp/udp	#	Unassigned
5771	tcp/udp	netagent	NetAgent
5772-5776	tcp/udp	#	Unassigned
5777	tcp/udp	dali-port	DALI Port
5778-5812	tcp/udp	#	Unassigned
5800 	tcp 	# 	Evivinc
5800-5801 	tcp 	# 	VNC
5813	tcp/udp	icmpd	ICMPD
5814	tcp/udp	spt-automation	Support Automation
5815-5858	tcp/udp	#	Unassigned
5843 	tcp/udp 	# 	IIS Admin Service
5859	tcp/udp	wherehoo	WHEREHOO
5860-5962	tcp/udp	#	Unassigned
5880 	tcp 	# 	Y3K RAT
5882 	tcp/udp 	# 	Y3K RAT
5884 	tcp/udp 	# 	Y3K RAT
5888 	tcp/udp 	# 	Y3K RAT
5889 	tcp 	# 	Y3K RAT
5900 	tcp 	# 	Evivinc
5900-5901 	tcp 	# 	VNC
5963	tcp/udp	indy	Indy Application Server
5964-5967	tcp/udp	#	Unassigned
5968	tcp/udp	mppolicy-v5	mppolicy-v5
5969	tcp/udp	mppolicy-mgr	mppolicy-mgr
5970-5986	tcp/udp	#	Unassigned
5987	tcp/udp	wbem-rmi	WBEM RMI
5988	tcp/udp	wbem-http	WBEM HTTP
5989	tcp/udp	wbem-https	WBEM HTTPS
5990	tcp/udp	wbem-exp-https	WBEM Export HTTPS
5991	tcp/udp	nuxsl	NUXSL
5992-5998	tcp/udp	#	Unassigned
5999	tcp/udp	cvsup	CVSup
6000-6063	tcp/udp	x11	X Window System
6000 	tcp 	# 	The Thing, Lovgate
6006 	tcp 	# 	Bad Blood
6050 	tcp/udp 	# 	ARCserv
6051 	tcp/udp 	# 	Zdemon, SysXXX
6060 	tcp 	# 	W32.Lovgate
6064	tcp/udp	ndl-ahp-svc	NDL-AHP-SVC
6065	tcp/udp	winpharaoh	WinPharaoh
6066	tcp/udp	ewctsp	EWCTSP
6067	tcp/udp	srb	SRB
6068	tcp/udp	gsmp	GSMP
6069	tcp/udp	trip	TRIP
6070	tcp/udp	messageasap	Messageasap
6071	tcp/udp	ssdtp	SSDTP
6072	tcp/udp	diagnose-proc	DIAGNOSE-PROC
6073	tcp/udp	directplay8	DirectPlay8
6074-6084	tcp/udp	#	Unassigned
6085	tcp/udp	konspire2b	konspire2b p2p network
6086-6099	tcp/udp	#	Unassigned
6100	tcp/udp	synchronet-db	SynchroNet-db
6101	tcp/udp	synchronet-rtc	SynchroNet-rtc
6102	tcp/udp	synchronet-upd	SynchroNet-upd
6103	tcp/udp	rets	RETS
6104	tcp/udp	dbdb	DBDB
6105	tcp/udp	primaserver	Prima Server
6106	tcp/udp	mpsserver	MPS Server
6107	tcp/udp	etc-control	ETC Control
6108	tcp/udp	sercomm-scadmin	Sercomm-SCAdmin
6109	tcp/udp	globecast-id	GLOBECAST-ID
6110	tcp/udp	softcm	HP SoftBench CM
6111	tcp/udp	spc	HP SoftBench Sub-Process Control
6112	tcp/udp	dtspcd	dtspcd
6112 	tcp/udp 	# 	BattleNet
The popular multiplayer game "Diablo" runs on this port.
6113-6122	tcp/udp	#	Unassigned
6123	tcp/udp	backup-express	Backup Express
6124-6132	tcp/udp	#	Unassigned
6133	tcp/udp	nbt-wol	New Boundary Tech WOL
6134-6140	tcp/udp	#	Unassigned
6129 	tcp/udp 	# 	W32.Mockbot.
6141	tcp/udp	meta-corp	Meta Corporation License Manager
6142	tcp/udp	aspentec-lm	Aspen Technology License Manager
6143	tcp/udp	watershed-lm	Watershed License Manager
6144	tcp/udp	statsci1-lm	StatSci License Manager - 1
6145	tcp/udp	statsci2-lm	StatSci License Manager - 2
6146	tcp/udp	lonewolf-lm	Lone Wolf Systems License Manager
6147	tcp/udp	montage-lm	Montage License Manager
6148	tcp/udp	ricardo-lm	Ricardo North America License Manager
6149	tcp/udp	tal-pod	tal-pod
6150-6160	tcp/udp	#	Unassigned
6161	tcp/udp	patrol-ism	PATROL Internet Srv Mgr
6162	tcp/udp	patrol-coll	PATROL Collector
6163	tcp/udp	pscribe	Precision Scribe Cnx Port
6164-6252	tcp/udp	#	Unassigned
6187 	tcp/udp 	# 	Tilser
6253	tcp/udp	crip	CRIP
6254-6299	tcp/udp	#	Unassigned
6272 	tcp 	# 	Secret Service
6300	tcp/udp	bmc-grx	BMC GRX
6301-6320	tcp/udp	#	Unassigned
6321	tcp/udp	emp-server1	Empress Software Connectivity Server 1
6322	tcp/udp	emp-server2	Empress Software Connectivity Server 2
6323-6345	tcp/udp	#	Unassigned
6343	tcp/udp	sflow	sFlow traffic monitoring
6344-6345	tcp/udp	#	Unassigned
6346	tcp/udp	gnutella-svc	gnutella-svc
6347	tcp/udp	gnutella-rtr	gnutella-rtr
6348-6381	tcp/udp	#	Unassigned
6382	tcp/udp	metatude-mds	Metatude Dialogue Server
6383-6388	tcp/udp	#	Unassigned
6384 	tcp 	# 	W32.HLLW.Gaobot
6389	tcp/udp	clariion-evr01	clariion-evr01
6390-6399	tcp/udp	#	Unassigned
6400	tcp/udp	info-aps	 
6400 	tcp 	# 	The Thing
6401	tcp/udp	info-was	 
6402	tcp/udp	info-eventsvr	 
6403	tcp/udp	info-cachesvr	 
6404	tcp/udp	info-filesvr	 
6405	tcp/udp	info-pagesvr	 
6406	tcp/udp	info-processvr	 
6407	tcp/udp	reserved1	 
6408	tcp/udp	reserved2	 
6409	tcp/udp	reserved3	 
6410	tcp/udp	reserved4	 
6411-6454	tcp/udp	#	Unassigned
6430 	tcp/udp 	# 	Mirab File Transfer
6455	tcp	skip-cert-recv	SKIP Certificate Receive
6456	tcp	skip-cert-send	SKIP Certificate Send
6457-6470	tcp/udp	#	Unassigned
6471	tcp/udp	lvision-lm	LVision License Manager
6472-6499	tcp/udp	#	Unassigned
6499-6500 	tcp 	# 	Netscape CoolTalk Watchdog
6500	tcp/udp	boks	BoKS Master
6501	tcp/udp	boks_servc	BoKS Servc
6502	tcp/udp	boks_servm	BoKS Servm
6502 	tcp/udp 	# 	Netscape Conference
6503	tcp/udp	boks_clntd	BoKS Clntd
6504	tcp/udp	#	Unassigned
6505	tcp/udp	badm_priv	BoKS Admin Private Port
6506	tcp/udp	badm_pub	BoKS Admin Public Port
6507	tcp/udp	bdir_priv	"BoKS Dir Server, Private Port"
6508	tcp/udp	bdir_pub	"BoKS Dir Server, Public Port"
6509	tcp/udp	mgcs-mfp-port	MGCS-MFP Port
6510	tcp/udp	mcer-port	MCER Port
6511-6542	tcp/udp	#	Unassigned
6543	tcp/udp	lds-distrib	lds_distrib
6544-6546	tcp/udp	#	Unassigned
6547	tcp/udp	apc-6547	APC 6547
6548	tcp/udp	apc-6548	APC 6548
6549	tcp/udp	apc-6549	APC 6549
6550	tcp/udp	fg-sysupdate	fg-sysupdate
6551-6557	tcp/udp	#	Unassigned
6558	tcp/udp	xdsxdm	 
6559-6579	tcp/udp	#	Unassigned
6564 	tcp/udp 	# 	Sdbot
6565 	tcp 	# 	Nemog
6566	tcp/udp	sane-port	SANE Control Port
6567-6579	tcp/udp	#	Unassigned
6580	tcp/udp	parsec-master	Parsec Masterserver
6581	tcp/udp	parsec-peer	Parsec Peer-to-Peer
6582	tcp/udp	parsec-game	Parsec Gameserver
6583-6587	tcp/udp	#	Unassigned
6588	tcp/udp	#	Unassigned
Unofficial use of port 6588 by AnalogX and Microsoft
6589-6627	tcp/udp	#	Unassigned
6595 	tcp/udp 	# 	Assasin
6628	tcp/udp	afesc-mc	AFE Stock Channel M/C
6629-6630	tcp/udp	#	Unassigned
6631	tcp/udp	#	Unassigned
6631 	tcp/udp 	# 	Sdbot
6632-6664	tcp/udp	#	Unassigned
6664-6665 	tcp 	# 	Futro
6665-6669	tcp/udp	ircu	IRCU
6661 	tcp 	# 	TEMan, Weia-Meia
6666 	tcp 	# 	AltaVista Tunnel server also uses this port.
6666 	tcp 	# 	Script kiddies trying to compromise
Real Server servers might mistakenly use this port.
6666 	tcp 	# 	Many sites running "napster" may use this port.
6666 	tcp 	# 	Dark Connection Inside, NetBus worm,
W32.HLLW.Warpigs, BAT.Boohoo.Worm
6666 	udp 	# 	Kali uses UDP 6666.
6667 	tcp 	# 	VocalTec Internet Phone
An alternate port other than 6670
used to connect to servers.
6667 	tcp 	# 	IRC Clients can connect to servers on this port.
6667 	tcp 	# 	Dark FTP, ScheduleAgent, SubSeven,
Subseven 2.1.4 DefCon 8, Trinity, WinSatan,
W32.HLLW.Gaobot, IrcContact, Deftcode, IRC.Flood
W32.HLLW.Nool, W32.HLLW.Warpigs, Spigot,
W32.HLLW.Studd, W32.Cissi, W32.Mimail
W32.Opasa, Sdbot, W32.Korgo, Hacarmy, W32.Mota,
W32.Spybot, Alnica, W32.Mydoom, Maxload,
W32.Bofra, Lateda, W32.Protoride
6669 	tcp 	# 	Host Control, Vampire
6670	tcp/udp	vocaltec-gold	Vocaltec Global Online Directory
6670 	tcp 	# 	BackWeb Server, Deep Throat, Foreplay,
WinNuke eXtreame
6671	tcp/udp	#	Unassigned
6672	tcp/udp	vision_server	vision_server
6673	tcp/udp	vision_elmd	vision_elmd
6674-6700	tcp/udp	#	Unassigned
6697 	tcp/udp 	# 	Feardoor
6699 	tcp 	# 	A program called "napster" for exchanging
MP3 files defaults to this port.
6701	tcp/udp	kti-icad-srvr	KTI/ICAD Nameserver
6702-6713	tcp/udp	#	Unassigned
6711 	tcp 	# 	BackDoor-G, SubSeven, VP Killer, Kilo
6712 	tcp 	# 	Funny trojan, SubSeven
6713 	tcp 	# 	SubSeven
6714	tcp/udp	ibprotocol	Internet Backplane Protocol
6715-6766	tcp/udp	#	Unassigned
6718 	tcp 	# 	Kilo
6723 	tcp 	# 	Mstream
6754 	tcp/udp 	# 	Mapsy
6767	tcp/udp	bmc-perf-agent	BMC PERFORM AGENT
6768	tcp/udp	bmc-perf-mgrd	BMC PERFORM MGRD
6769-6787	tcp/udp	#	Unassigned
6771 	tcp 	# 	Deep Throat, Foreplay
6776 	tcp/udp 	hnmp 	RAT:SubSeven
This port often seen as part of the Sub7
communication. You may see a steady
stream of connection attempts: this is
because it uses this port separately from
the command port in order to transfer
information. Sometimes the control-
connection thinks the agent is alive,
and will continue to attempt this
connection as well. Backdoor port in Sub7
6776 	tcp 	# 	2000 Cracks, BackDoor-G, VP Killer
6777 	tcp 	# 	W32.Gaobot
6788	tcp/udp	smc-http	SMC-HTTP
6789	tcp/udp	smc-https	SMC-HTTPS
6789 	tcp 	# 	W32.Netsky
6790	tcp/udp	hnmp	HNMP
6791-6830	tcp/udp	#	Unassigned
6831	tcp/udp	ambit-lm	ambit-lm
6832-6840	tcp/udp	#	Unassigned
6838 	udp 	# 	Mstream
6841	tcp/udp	netmo-default	Netmo Default
6842	tcp/udp	netmo-http	Netmo HTTP
6843-6849	tcp/udp	#	Unassigned
6850	tcp/udp	iccrushmore	ICCRUSHMORE
6851-6887	tcp/udp	#	Unassigned
6883 	tcp 	# 	Delta Source DarkStar
6888	tcp/udp	muse	MUSE
6889-6960	tcp/udp	#	Unassigned
6912 	tcp 	# 	Shit Heep
6939 	tcp 	# 	Indoctrination
6961	tcp/udp	jmact3	JMACT3
6962	tcp/udp	jmevt2	jmevt2
6963	tcp/udp	swismgr1	swismgr1
6964	tcp/udp	swismgr2	swismgr2
6965	tcp/udp	swistrap	swistrap
6966	tcp/udp	swispol	swispol
6967-6968	tcp/udp	#	Unassigned
6969	tcp/udp	acmsoda	acmsoda
6969 	tcp 	# 	GateCrasher, IRC 3, Net Controller, Priority,
Robi, Sparta, Floodnet, Assasin, Khaos, Ratega,
Danton
6970-6997	tcp/udp	#	Unassigned
6970 	tcp 	# 	GateCrasher
6970-6971 	udp 	# 	RTP(RealTime Protocol)
6998	tcp/udp	iatp-highpri	IATP-highPri
6999	tcp/udp	iatp-normalpri	IATP-normalPri
7000	tcp/udp	afs3-fileserver	file server itself
7000 	tcp 	# 	'xfont' (X Windows font server)
7000 	tcp 	# 	Exploit Translation Server, Kazimas,
Remote Grab, SubSeven,
SubSeven 2.1 Gold, BAT.Boohoo.Worm,
W32.Gaobot
7001	tcp/udp	afs3-callback	callbacks to cache managers
7001 	tcp 	# 	Freak88, Freak2k
7002	tcp/udp	afs3-prserver	users & groups database
7003	tcp/udp	afs3-vlserver	volume location database
7004	tcp/udp	afs3-kaserver	AFS/Kerberos authentication service
7005	tcp/udp	afs3-volser	volume managment server
7006	tcp/udp	afs3-errors	error interpretation service
7007	tcp/udp	afs3-bos	basic overseer process
7007 	tcp/udp 	# 	MSBD, Windows Media encoder
7008	tcp/udp	afs3-update	server-to-server updater
7009	tcp/udp	afs3-rmtsys	remote cache manager service
7010	tcp/udp	ups-onlinet	onlinet uninterruptable power supplies
7011	tcp/udp	talon-disc	Talon Discovery Port
7012	tcp/udp	talon-engine	Talon Engine
7013	tcp/udp	microtalon-dis	Microtalon Discovery
7014	tcp/udp	microtalon-com	Microtalon Communications
7015	tcp/udp	talon-webserver	Talon Webserver
7016-7019	tcp/udp	#	Unassigned
7020	tcp/udp	dpserve	DP Serve
7021	tcp/udp	dpserveadmin	DP Serve Admin
7022-7029	tcp/udp	#	Unassigned
7030	tcp/udp	op-probe	ObjectPlanet probe
7031-7069	tcp/udp	#	Unassigned
7070	tcp/udp	arcp	ARCP
7070 	tcp/udp 	# 	The default port for Real Server streams.
7070 	tcp/udp 	# 	Apple QuickTime Streamer Serve accepts
RTSP (RealTime Streaming Protocol) on this port.
7071-7098	tcp/udp	#	Unassigned
7080 	tcp/udp 	# 	Haxdoor
7099	tcp/udp	lazy-ptop	lazy-ptop
7100	tcp/udp	font-service	X Font Service
7101-7120	tcp/udp	#	Unassigned
7119 	tcp/udp 	# 	Massaker
7121	tcp/udp	virprot-lm	Virtual Prototypes License Manager
7122-7160	tcp/udp	#	Unassigned
7161	tcp/udp	cabsm-comm	CA BSM Comm
7161 	tcp 	# 	SMS v1.2 wuser32.exe
7162	tcp/udp	Caistoragemgr	CA Storage Manager
7163-7173	tcp/udp	#	Unassigned
7174	tcp/udp	clutild	Clutild
7175-7199	tcp/udp	#	Unassigned
7200	tcp/udp	fodms	FODMS FLIP
7201	tcp/udp	dlip	DLIP
7202-7226	tcp/udp	#	Unassigned
7215 	tcp 	# 	SubSeven, SubSeven 2.1 Gold
7227	tcp/udp	ramp	Registry A & M Protocol
7228-7279	tcp/udp	#	Unassigned
7280	tcp/udp	itactionserver1	ITACTIONSERVER 1
7281	tcp/udp	itactionserver2	ITACTIONSERVER 2
7282-7299	tcp/udp	#	Unassigned
7300-7390	tcp/udp	swx	The Swiss Exchange
7300-7301 	tcp 	# 	NetMonitor
7306-7308 	tcp 	# 	NetMonitor
7391	tcp/udp	mindfilesys	mind-file system server
7392	tcp/udp	mrssrendezvous	mrss-rendezvous server
7393-7394	tcp/udp	#	Unassigned
7395	tcp/udp	winqedit	winqedit
7396	tcp/udp	#	Unassigned
7397	tcp/udp	hexarc	Hexarc Command Language
7398-7420	tcp/udp	#	Unassigned
7410 	tcp/udp 	# 	Phoenix
7421	tcp/udp	mtportmon	Matisse Port Monitor
7422-7425	tcp/udp	#	Unassigned
7424 	tcp/udp 	# 	Host Control
7426	tcp/udp	pmdmgr	OpenView DM Postmaster Manager
7427	tcp/udp	oveadmgr	OpenView DM Event Agent Manager
7428	tcp/udp	ovladmgr	OpenView DM Log Agent Manager
7429	tcp/udp	opi-sock	OpenView DM rqt communication
7430	tcp/udp	xmpv7	OpenView DM xmpv7 api pipe
7431	tcp/udp	pmd	OpenView DM ovc/xmpv3 api pipe
7437	tcp/udp	faximum	Faximum
7438-7490	tcp/udp	#	Unassigned
7441 	tcp/udp 	# 	MeteorShell
7491	tcp/udp	telops-lmd	telops-lmd
7492-7499	tcp/udp	#	Unassigned
7500	tcp/udp	silhouette	Silhouette User
7501	tcp/udp	ovbus	HP OpenView Bus Daemon
7502-7509	tcp/udp	#	Unassigned
7510	tcp/udp	ovhpas	HP OpenView Application Server
7511	tcp/udp	pafec-lm	pafec-lm
7512-7543	tcp/udp	#	Unassigned
7544	tcp/udp	nta-ds	FlowAnalyzer DisplayServer
7545	tcp/udp	nta-us	FlowAnalyzer UtilityServer
7546-7565	tcp/udp	#	Unassigned
7566	tcp/udp	vsi-omega	VSI Omega
7567-7569	tcp/udp	#	Unassigned
7570	tcp/udp	aries-kfinder	Aries Kfinder
7571-7587	tcp/udp	#	Unassigned
7588	tcp/udp	sun-lm	Sun License Manager
7589-7623	tcp/udp	#	Unassigned
7597 	tcp 	# 	Qaz
7614 	tcp 	# 	GRM
7624	tcp/udp	indi	Instrument Neutral Distributed Interface
7626 	tcp 	# 	Glacier
7625	tcp/udp	#	Unassigned
7626	tcp/udp	simco	SImple Middlebox COnfiguration (SIMCO) Server
7627	tcp/udp	soap-http	SOAP Service Port
7628-7632	tcp/udp	#	Unassigned
7633	tcp/udp	pmdfmgt	PMDF Management
7634-7673	tcp/udp	#	Unassigned
7640 	tcp 	# 	Remote configuration via Telnet
for CU-SeeMe Reflector.
7648 	tcp 	# 	CU-SeenMe client connections
CU-SeeMe connection establishment
7648 	udp 	# 	CU-SeeMe video and audio
7649 	tcp 	# 	CU-SeeMe connection establishment CU-SeeMe
7673 	tcp/udp 	# 	Neodurk
7674	tcp/udp	imqtunnels	iMQ SSL tunnel
7675	tcp/udp	imqtunnel	iMQ Tunnel
7676	tcp/udp	imqbrokerd	iMQ Broker Rendezvous
7677-7706	tcp/udp	#	Unassigned
7707	tcp/udp	sync-em7	EM7 Dynamic Updates
7708-7719	tcp/udp	#	Unassigned
7720	tcp/udp	medimageportal	MedImage Portal
7721-7724	tcp/udp	#	Unassigned
7677 	tcp/udp 	# 	Neodurk
7725	tcp/udp	nitrogen	Nitrogen Service
7726-7742	tcp/udp	#	Unassigned
7714 	tcp/udp 	# 	Berbew
7743	tcp/udp	sstp-1	Sakura Script Transfer Protocol
7744-7776	tcp/udp	#	Unassigned
7777	tcp/udp	cbt	cbt
7777 	tcp/udp 	# 	Hacker can spoof UDP packets to this port
in order to control the cable-modem.
God Message, Tini
7778	tcp/udp	interwise	Interwise
7778 	tcp/udp 	# 	Unreal Tournament, an online multiplayer
personal shooter.
7779	tcp/udp	vstat	VSTAT
7780	tcp/udp	#	Unassigned
7781	tcp/udp	accu-lmgr	accu-lmgr
7782-7785	tcp/udp	#	Unassigned
7786	tcp/udp	minivend	MINIVEND
7787-7796	tcp/udp	#	Unassigned
7789 	tcp 	# 	Back Door Setup, ICKiller
7797	tcp/udp	pnet-conn	Propel Connector port
7798	tcp/udp	pnet-enc	Propel Encoder port
7799-7844	tcp/udp	#	Unassigned
7811 	tcp/udp 	# 	RemoteSOB
7823 	tcp/udp 	# 	Amitis
7845	tcp/udp	apc-7845	APC 7845
7846	tcp/udp	apc-7846	APC 7846
7847-7912	tcp/udp	#	Unassigned
7891 	tcp 	# 	The ReVeNgEr
7896-7897 	tcp 	# 	Futh
7913	tcp/udp	qo-secure	QuickObjects secure port
7914-7931	tcp/udp	#	Unassigned
7932	tcp/udp	t2-drm	Tier 2 Data Resource Manager
7933	tcp/udp	t2-brm	Tier 2 Business Rules Manager
7934-7966	tcp/udp	#	Unassigned
7955 	tcp 	# 	W32.Kibuv
7967	tcp/udp	supercell	Supercell
7968-7978	tcp/udp	#	Unassigned
7979	tcp/udp	micromuse-ncps	Micromuse-ncps
7980	tcp/udp	quest-vista	Quest Vista
7981-7998	tcp/udp	#	Unassigned
7983 	tcp 	# 	Mstream
7999	tcp/udp	irdmi2	iRDMI2
8000	tcp/udp	irdmi	iRDMI
8001	tcp/udp	vcom-tunnel	VCOM Tunnel
8002	tcp/udp	teradataordbms	Teradata ORDBMS
8002 	tcp 	#	'rcgi' or "PERL.NLM' allows running of
PERL scripts on a Novell 4.1 webserver.
8003-8007	tcp/udp	#	Unassigned
8008	tcp/udp	http-alt	HTTP Alternate
8008 	tcp 	# 	Haxdoor
8009-8021	tcp/udp	#	Unassigned
8010 	tcp 	#	WinGate v2.1 has a webserver on port
8010 for the "LogFile Service". If this
port is open, then anyone can connect
to WinGate in order read not only the
logfiles, but any othe file on the drive
WinGate was installed on.
8012 	tcp 	# 	Ptakks
8022	tcp/udp	oa-system	oa-system
8023-8031	tcp/udp	#	Unassigned
8032	tcp/udp	pro-ed	ProEd
8033	tcp/udp	mindprint	MindPrint
8034-8079	tcp/udp	#	Unassigned
8080	tcp/udp	http-alt	HTTP Alternate (see port 80)
8080 	tcp 	# 	Brown Orifice, Reverse WWW Tunnel
Backdoor, RingZero, Mydoom, Nemog, Webus,
W32.Spybot
8081-8099	tcp/udp	#	Unassigned
8088	tcp/udp	radan-http	Radan HTTP
8089-8099	tcp/udp	#	Unassigned
8090 	tcp/udp 	# 	Asniffer
8100	tcp/udp	xprint-server	Xprint Server
8101-8114	tcp/udp	#	Unassigned
8115	tcp/udp	mtl8000-matrix	MTL8000 Matrix
8116	tcp/udp	cp-cluster	Check Point Clustering
8117	tcp/udp	#	Unassigned
8118	tcp/udp	privoxy	Privoxy HTTP proxy
8119-8120	tcp/udp	#	Unassigned
8121	tcp/udp	apollo-data	Apollo Data Port
8122	tcp/udp	apollo-admin	Apollo Admin Port
8123-8129	tcp/udp	#	Unassigned
8126 	tcp 	# 	W32.Pejaybot
8130	tcp/udp	indigo-vrmi	INDIGO-VRMI
8131	tcp/udp	indigo-vbcp	INDIGO-VBCP
8132	tcp/udp	dbabble	dbabble
8133-8147	tcp/udp	#	Unassigned
8148	tcp/udp	isdd	i-SDD file transfer
8149-8159	tcp/udp	#	Unassigned
8160	tcp/udp	patrol	Patrol
8161	tcp/udp	patrol-snmp	Patrol SNMP
8162-8198	tcp/udp	#	Unassigned
8173 	tcp/udp 	# 	Zebroxy
8181 	tcp/udp 	# 	W32.Erkez
8199	tcp/udp	vvr-data	VVR DATA
8200	tcp/udp	trivnet1	TRIVNET
8201	tcp/udp	trivnet2	TRIVNET
8202-8203	tcp/udp	#	Unassigned
8204	tcp/udp	lm-perfworks	LM Perfworks
8205	tcp/udp	lm-instmgr	LM Instmgr
8206	tcp/udp	lm-dta	LM Dta
8207	tcp/udp	lm-sserver	LM SServer
8208	tcp/udp	lm-webwatcher	LM Webwatcher
8209-8329	tcp/udp	#	Unassigned
8311 	tcp/udp 	# 	Mxsender
8230	tcp/udp	rexecj	RexecJ Server
8231-8350	tcp/udp	#	Unassigned
8351	tcp/udp	server-find	Server Find
8352-8375	tcp/udp	#	Unassigned
8376	tcp/udp	cruise-enum	Cruise ENUM
8377	tcp/udp	cruise-swroute	Cruise SWROUTE
8378	tcp/udp	cruise-config	Cruise CONFIG
8379	tcp/udp	cruise-diags	Cruise DIAGS
8380	tcp/udp	cruise-update	Cruise UPDATE
8381-8382	tcp/udp	#	Unassigned
8383	tcp/udp	m2mservices	M2m Services
8383 	tcp/udp 	#	IpSwitch's IMail program has a
administrative web server running on this port.
8384-8399	tcp/udp	#	Unassigned
8400	tcp/udp	cvd	cvd
8401	tcp/udp	sabarsd	sabarsd
8402	tcp/udp	abarsd	abarsd
8403	tcp/udp	admind	admind
8404-8415	tcp/udp	#	Unassigned
8416	tcp/udp	espeech	eSpeech Session Protocol
8417	tcp/udp	espeech-rtp	eSpeech RTP Protocol
8418-8442	tcp/udp	#	Unassigned
8443	tcp/udp	pcsync-https	PCsync HTTPS
8444	tcp/udp	pcsync-http	PCsync HTTP
8445-8449	tcp/udp	#	Unassigned
8450	tcp/udp	npmp	npmp
8451-8472	tcp/udp	#	Unassigned
8473	tcp/udp	vp2p	Virtual Point to Point
8474-8499	tcp/udp	#	Unassigned
8500	tcp/udp	fde	Flight Data Exchange
8501-8553	tcp/udp	#	Unassigned
8520 	tcp/udp 	# 	W32.Socay.Worm
8546 	tcp/udp 	# 	Berbew
8554	tcp/udp	rtsp-alt	RTSP Alternate (see port 554)
8555	tcp/udp	d-fence	SYMAX D-FENCE
8556-8610	tcp/udp	#	Unassigned
8611	tcp/udp	canon-bjnp1	Canon BJNP Port 1
8612	tcp/udp	canon-bjnp2	Canon BJNP Port 2
8613	tcp/udp	canon-bjnp3	Canon BJNP Port 3
8614	tcp/udp	canon-bjnp4	Canon BJNP Port 4
8615-8698	tcp/udp	#	Unassigned
8699	tcp/udp	vnyx	VNYX Primary Port
8700-8732	tcp/udp	#	Unassigned
8719 	tcp/udp 	# 	WinShell.50
8733	tcp/udp	ibus	iBus
8734-8762	tcp/udp	#	Unassigned
8763	tcp/udp	mc-appserver	MC-APPSERVER
8764	tcp/udp	openqueue	OPENQUEUE
8765	tcp/udp	ultraseek-http	Ultraseek HTTP
8766-8769	tcp/udp	#	Unassigned
8770	tcp/udp	dpap	Digital Photo Access Protocol
8771-8785	tcp/udp	#	Unassigned
8786	tcp/udp	msgclnt	Message Client
8787	tcp/udp	msgsrvr	Message Server
8787 	tcp 	# 	Back Orifice 2000
8788-8803	tcp/udp	#	Unassigned
8800 	tcp 	# 	W32.Noomy
8804	tcp/udp	truecm	truecm
8805-8879	tcp/udp	#	Unassigned
8811 	tcp/udp 	# 	Fearic, Monator
8866 	tcp/udp 	# 	W32.Beagle
8875 	tcp/udp 	# 	Napster
8880	tcp/udp	cddbp-alt	CDDBP
8881-8887	tcp/udp	#	Unassigned
8888	tcp	ddi-tcp-1	NewsEDGE server TCP (TCP 1)
8888	udp	ddi-udp-1	NewsEDGE server UDP (UDP 1)
8888 	tcp/udp 	# 	Napster, W32.Axatak, OptixPro
8889	tcp	ddi-tcp-2	Desktop Data TCP 1
8889	udp	ddi-udp-2	NewsEDGE server broadcast
8889 	tcp/udp 	# 	W32.Axatak
8890	tcp	ddi-tcp-3	Desktop Data TCP 2
8890	udp	ddi-udp-3	NewsEDGE client broadcast
8890 	tcp 	# 	Sendmail Switch
8891	tcp	ddi-tcp-4	Desktop Data TCP 3: NESS application
8891	udp	ddi-udp-4	Desktop Data UDP 3: NESS application
8892	tcp	ddi-tcp-5	Desktop Data TCP 4: FARM product
8892	udp	ddi-udp-5	Desktop Data UDP 4: FARM product
8893	tcp	ddi-tcp-6	Desktop Data TCP 5: NewsEDGE/Web application
8893	udp	ddi-udp-6	Desktop Data UDP 5: NewsEDGE/Web application
8894	tcp	ddi-tcp-7	Desktop Data TCP 6: COAL application
8894	udp	ddi-udp-7	Desktop Data UDP 6: COAL application
8895-8899	tcp/udp	#	Unassigned
8900	tcp/udp	jmb-cds1	JMB-CDS 1
8901	tcp/udp	jmb-cds2	JMB-CDS 2
8902-8909	tcp/udp	#	Unassigned
8910	tcp/udp	manyone-http	manyone-http
8911	tcp/udp	manyone-xml	manyone-xml
8912-8953	tcp/udp	#	Unassigned
8954	tcp/udp	cumulus-admin	Cumulus Admin Port
8955-8999	tcp/udp	#	Unassigned
8867 	tcp 	# 	W32.Dabber
8988 	tcp 	# 	BacHack
8989 	tcp 	# 	Rcon, Recon, Xcon
8999	tcp/udp	bctp	Brodos Crypto Trade Protocol
9000	tcp/udp	cslistener	CSlistener
9000 	tcp 	# 	AltaVista HTTP Server
The may be an attempt to compromise
an AltaVista HTTP (web) server.
9000 	tcp 	# 	Sendmail Switch SDAP
Sendmail's "Switch" protocol listens on
this TCP port. It also listens on port 8890.
9000 	tcp 	# 	Netministrator, W32.Randex
9000 	udp 	# 	Asheron's Call
This port is used in Microsoft's massively-
multiplayer game called "Asheron's Call".
The game can continue to contact the
player even after the player has logged out.
9001	tcp/udp	etlservicemgr	ETL Service Manager
9002	tcp/udp	dynamid	DynamID authentication
9003-9005	tcp/udp	#	Unassigned
9006	tcp/udp	#	"De-Commissioned Port 02/24/00, ms"
9007-9008	tcp/udp	#	Unassigned
9009	tcp/udp	pichat	Pichat Server
9010-9019	tcp/udp	#	Unassigned
9010 	tcp 	# 	Tumag
9020	tcp/udp	tambora	TAMBORA
9021	tcp/udp	panagolin-ident	Pangolin Identification
9022	tcp/udp	paragent	PrivateArk Remote Agent
9023	tcp/udp	swa-1	Secure Web Access - 1
9024	tcp/udp	swa-2	Secure Web Access - 2
9025	tcp/udp	swa-3	Secure Web Access - 3
9026	tcp/udp	swa-4	Secure Web Access - 4
9027-9079	tcp/udp	#	Unassigned
9080	tcp/udp	glrpc	Groove GLRPC
9081-9089	tcp/udp	#	Unassigned
9090	tcp/udp	websm	WebSM
9091	tcp/udp	xmltec-xmlmail	xmltec-xmlmail
9092-9099	tcp/udp	#	Unassigned
9100	tcp/udp	hp-pdl-datastr	PDL Data Streaming Port
9100	tcp/udp	pdl-datastream	Printer PDL Data Stream
9101	tcp/udp	bacula-dir	Bacula Director
9102	tcp/udp	bacula-fd	Bacula File Daemon
9103	tcp/udp	bacula-sd	Bacula Storage Daemon
9104	tcp/udp	peerwire	PeerWire
9105-9159	tcp/udp	#	Unassigned
9136 	tcp/udp 	# 	Sdbot
9148 	tcp/udp 	# 	W32.HLLW.Nautic
9160	tcp/udp	netlock1	NetLOCK1
9161	tcp/udp	netlock2	NetLOCK2
9162	tcp/udp	netlock3	NetLOCK3
9163	tcp/udp	netlock4	NetLOCK4
9164	tcp/udp	netlock5	NetLOCK5
9165-9199	tcp/udp	#	Unassigned
9200	tcp/udp	wap-wsp	WAP connectionless session service
9200 	tcp/udp 	# 	Lexmark printers open both TCP and
UDP port 9200 for some unknown purpose.
9201	tcp/udp	wap-wsp-wtp	WAP session service
9202	tcp/udp	wap-wsp-s	WAP secure connectionless session service
9203	tcp/udp	wap-wsp-wtp-s	WAP secure session service
9204	tcp/udp	wap-vcard	WAP vCard
9205	tcp/udp	wap-vcal	WAP vCal
9206	tcp/udp	wap-vcard-s	WAP vCard Secure
9207	tcp/udp	wap-vcal-s	WAP vCal Secure
9208-9209	tcp/udp	#	Unassigned
9210	tcp/udp	oma-mlp	OMA Mobile Location Protocol
9211	tcp/udp	oma-mlp-s	OMA Mobile Location Protocol Secure
9212	tcp/udp	serverviewdbms	Server View dbms access
9213-9216	tcp/udp	#	Unassigned
9217	tcp/udp	fsc-port	FSC Communication Port
9218-9221	tcp/udp	#	Unassigned
9222	tcp/udp	teamcoherence	QSC Team Coherence
9223-9280	tcp/udp	#	Unassigned
9281	tcp/udp	swtp-port1	SofaWare transport port 1
9282	tcp/udp	swtp-port2	SofaWare transport port 2
9283	tcp/udp	callwaveiam	CallWaveIAM
9284	tcp/udp	visd	VERITAS Information Serve
9285	tcp/udp	n2h2server	N2H2 Filter Service Port
9286	tcp/udp	#	Unassigned
9287	tcp/udp	cumulus	Cumulus
9288-9291	tcp/udp	#	Unassigned
9292	tcp/udp	armtechdaemon	ArmTech Daemon
9293-9317	tcp/udp	#	Unassigned
9318	tcp/udp	secure-ts	PKIX TimeStamp over TLS
9319-9320	tcp/udp	#	Unassigned
9321	tcp/udp	guibase	guibase
9322-9342	tcp/udp	#	Unassigned
9325 	udp 	# 	Mstream
9343	tcp/udp	mpidcmgr	MpIdcMgr
9344	tcp/udp	mphlpdmc	Mphlpdmc
9345	tcp/udp	#	Unassigned
9346	tcp/udp	ctechlicensing	C Tech Licensing
9347-9373	tcp/udp	#	Unassigned
9374	tcp/udp	fjdmimgr	fjdmimgr
9375-9395	tcp/udp	#	Unassigned
9396	tcp/udp	fjinvmgr	fjinvmgr
9397	tcp/udp	mpidcagt	MpIdcAgt
9398-9499	tcp/udp	#	Unassigned
9400 	tcp 	# 	InCommand
9500	tcp/udp	ismserver	ismserver
9501-9534	tcp/udp	#	Unassigned
9535	tcp/udp	mngsuite	Management Suite Remote Control
9536-9554	tcp/udp	#	Unassigned
9555	tcp/udp	trispen-sra	Trispen UDP tunnel
9556-9592	tcp/udp	#	Unassigned
9593	tcp/udp	cba8	LANDesk Management Agent
9594	tcp/udp	msgsys	Message System
9595	tcp/udp	pds	Ping Discovery Service
9596-9599	tcp/udp	#	Unassigned
9600	tcp/udp	micromuse-ncpw	MICROMUSE-NCPW
9601-9611	tcp/udp	#	Unassigned
9604 	tcp 	# 	W32.Kibuv.Worm
9612	tcp/udp	streamcomm-ds	StreamComm User Directory
9613-9746	tcp/udp	#	Unassigned
9696-9697 	tcp 	# 	Gholame
9704 	tcp 	# 	A popular Linux rpc.statd exploit
will drop a root shell on this port.
9704 	tcp/udp 	# 	A popular wu-fptd exploit drops
a root shell on this port.
9747	tcp/udp	l5nas-parchan	L5NAS Parallel Channel
9748-9752	tcp/udp	#	Unassigned
9753	tcp/udp	rasadv	rasadv
9754-9799	tcp/udp	#	Unassigned
9777-9778 	tcp/udp 	# 	StealthEye
9800	tcp/udp	davsrc	WebDav Source Port
9801	tcp/udp	sstp-2	Sakura Script Transfer Protocol-2
9802	tcp/udp	davsrcs	WebDAV Source TLS/SSL
9803-9874	tcp/udp	#	Unassigned
9867 	tcp/udp 	# 	Sokeven
9870 	tcp/udp 	# 	Recerv, R3C
9871 	tcp 	# 	Theef
9872-9875 	tcp 	# 	Portal of Doom
9875	tcp/udp	sapv1	Session Announcement v1
9876	tcp/udp	sd	Session Director
9876 	tcp/udp 	#	A Norton Commander lookalike
for UNIX. The client portion can
browse files on the hard disk, in
tar files, and across the network
with this server component. This
protocol is Sun RPC based and
registers with portmapper.
9876 	tcp 	# 	Cyber Attacker, Rux, Lolok
9878 	tcp 	# 	TransScout
9888	tcp/udp	cyborg-systems	CYBORG Systems
9898	tcp/udp	monkeycom	MonkeyCom
9898 	tcp/udp 	# 	CrashCool, W32.Dabber
9899	tcp/udp	sctp-tunneling	SCTP TUNNELING
9900	tcp/udp	iua	IUA
9900 	tcp/udp 	# 	W32.HLLW.Gaobot
9901-9908	tcp/udp	#	Unassigned
9909	tcp/udp	domaintime	domaintime
9910	tcp/udp	#	Unassigned
9911	tcp/udp	sype-transport	SYPECom Transport Protocol
9912-9949	tcp/udp	#	Unassigned
9950	tcp/udp	apc-9950	APC 9950
9951	tcp/udp	apc-9951	APC 9951
9952	tcp/udp	apc-9952	APC 9952
9953-9988	tcp/udp	#	Unassigned
9989 	tcp 	# 	RAT:IniKiller
Destroys basic files, like .ini files
9990	tcp/udp	osm-appsrvr	OSM Applet Server
9991	tcp/udp	osm-oev	OSM Event Server
9992	tcp/udp	palace-1	OnLive-1
9993	tcp/udp	palace-2	OnLive-2
9994	tcp/udp	palace-3	OnLive-3
9995	tcp/udp	palace-4	Palace-4
9996	tcp/udp	palace-5	Palace-5
9996 	tcp/udp 	# 	W32.Sasser
9997	tcp/udp	palace-6	Palace-6
9998	tcp/udp	distinct32	Distinct32
9999	tcp/udp	distinct	distinct
9999 	tcp 	# 	The Prayer, Beasty, Lateda
10000	tcp/udp	ndmp	Network Data Management Protocol
10000 	tcp 	# 	OpwinTRojan, W32.Dumaru, Nibu
10001	tcp/udp	scp-config	SCP Configuration Port
10001-10002 	tcp/udp 	# 	Zdemon
10002-10006	tcp/udp	#	Unassigned
10005 	tcp 	# 	OpwinTRojan
10007	tcp/udp	mvs-capacity	MVS Capacity
10008	tcp/udp	octopus	Octopus Multiplexer
10008 	tcp/udp 	# 	cheese worm
In early year 2001, many exploit scripts
for DNS TSIG name overflow would place
a root shell on this port.
In mid-2001, a worm was created that
enters the system via this port (left behind
by some other attacker), then starts
scanning other machines from this port.
10008-10079	tcp/udp	#	Unassigned
10067 	udp 	# 	Portal of Doom
10080	tcp/udp	amanda	Amanda
10080 	tcp 	# 	Mydoom
10081-10099	tcp/udp	#	Unassigned
10085-10086 	tcp 	# 	Syphillis
10100	tcp/udp	itap-ddtp	VERITAS ITAP DDTP
10100 	tcp 	# 	Control Total, Gift trojan, Ranky
10100 	udp 	# 	Trojan.Dasda
10101	tcp/udp	ezmeeting-2	eZproxy
10101 	tcp 	# 	BrainSpy, Silencer
10102	tcp/udp	ezproxy-2	eZmeeting
10103	tcp/udp	ezrelay	eZrelay
10104-10106	tcp/udp	#	Unassigned
10104 	udp 	# 	Lowtaper, Ranky
10107	tcp/udp	bctp-server	VERITAS BCTP, server
10108-10112	tcp/udp	#	Unassigned
10113	tcp/udp	netiq-endpoint	NetIQ Endpoint
10114	tcp/udp	netiq-qcheck	NetIQ Qcheck
10115	tcp/udp	netiq-endpt	NetIQ Endpoint
10116	tcp/udp	netiq-voipa	NetIQ VoIP Assessor
10117-10127	tcp/udp	#	Unassigned
10128	tcp/udp	bmc-perf-sd	BMC-PERFORM-SERVICE DAEMON
10129-10251	tcp/udp	#	Unassigned
10167 	udp 	# 	Portal of Doom
10168 	tcp/udp 	# 	Lovgate
10252	tcp/udp	apollo-relay	Apollo Relay Port
10253-10259	tcp/udp	#	Unassigned
10260	tcp/udp	axis-wimp-port	Axis WIMP Port
10261-10287	tcp/udp	#	Unassigned
10288	tcp/udp	blocks	Blocks
10289-10989	tcp/udp	#	Unassigned
10500 	tcp 	# 	W32.Linkbot
10520 	tcp 	# 	Acid Shivers
10528 	tcp 	# 	Host Control
10607 	tcp 	# 	Coma
10666 	udp 	# 	Ambush, Roxrat
10752 	tcp/udp 	# 	Backdoor. One of the many Linux
mountd (port 635) exploits installs
its backdoor at this port. Origin???
10751 = 0x2a00, where 0x2a = 42
(proposed by Darren Reed)
The bx.c IRC exploit puts a root shell
backdoor listening at this port.
The ADM named v3 attack puts a
shell at this port.
10888 	udp 	# 	Webus
10990	tcp/udp	rmiaux	Auxiliary RMI Port
10991-10999	tcp/udp	#	Unassigned
11000	tcp/udp	irisa	IRISA
11000 	tcp 	# 	Senna Spy Trojan Generator
11001	tcp/udp	metasys	Metasys
11002-11110	tcp/udp	#	Unassigned
11050-11051 	tcp 	# 	Host Control
11111	tcp/udp	vce	Viral Computing Environment (VCE)
11112-11200	tcp/udp	#	Unassigned
11142 	tcp 	# 	SubSeven
11201	tcp/udp	smsqp	smsqp
11202-11318	tcp/udp	#	Unassigned
11223 	tcp 	# 	Progenic trojan, Secret Agent
11311 	tcp 	# 	Carufax
11319	tcp/udp	imip	IMIP
11320	tcp/udp	imip-channels	IMIP Channels Port
11321	tcp/udp	arena-server	Arena Server Listen
11322-11366	tcp/udp	#	Unassigned
11367	tcp/udp	atm-uhas	ATM UHAS
11368-11370	tcp/udp	#	Unassigned
11371	tcp/udp	hkp	OpenPGP HTTP Keyserver
11372-11599	tcp/udp	#	Unassigned
11600	tcp/udp	tempest-port	Tempest Protocol Port
11601-11719	tcp/udp	#	Unassigned
11720	tcp/udp	h323callsigalt	h323 Call Signal Alternate
11721-11750	tcp/udp	#	Unassigned
11751	tcp/udp	intrepid-ssl	Intrepid SSL
11752-11966	tcp/udp	#	Unassigned
11831 	tcp/udp 	# 	Antilam
11967	tcp/udp	sysinfo-sp	SysInfo Service Protocol
11968-11999	tcp/udp	#	Unassigned
12000	tcp/udp	entextxid	IBM Enterprise Extender SNA
XID Exchange
12001	tcp/udp	entextnetwk	IBM Enterprise Extender SNA
COS Network Priority
12002	tcp/udp	entexthigh	IBM Enterprise Extender SNA
COS High Priority
12003	tcp/udp	entextmed	IBM Enterprise Extender SNA
COS Medium Priority
12004	tcp/udp	entextlow	IBM Enterprise Extender SNA
COS Low Priority
12005	tcp/udp	dbisamserver1	DBISAM Database Server - Regular
12006	tcp/udp	dbisamserver2	DBISAM Database Server - Admin
12007	tcp/udp	accuracer	Accuracer Database System ·Server
12008	tcp/udp	accuracer-dbms	Accuracer Database System ·Admin
12009-12108	tcp/udp	#	Unassigned
12065 	tcp 	# 	Berbew
12076 	tcp 	# 	Gjamer
12109	tcp/udp	rets-ssl	RETS over SSL
12110-12171	tcp/udp	#	Unassigned
12121 	tcp 	# 	Balkart
12172	tcp/udp	hivep	HiveP
12173-12299	tcp/udp	#	Unassigned
12223 	tcp 	# 	HackL99 KeyLogger
12300	tcp/udp	linogridengine	LinoGrid Engine
12301-12344	tcp/udp	#	Unassigned
12321 	tcp 	# 	Roxe
12345	tcp/udp	italk	Italk Chat System
12345 	tcp/udp 	# 	Notice how this port is the sequence of
numbers "1 2 3 4 5". This is common
chosen whenever somebody is asked to
configure a port number. It is likewise
chosen by programmers when creating
default port numbers for their products.
One very famous such uses is with NetBus.

Trend Micro's OfficeScan products use
this port.

Ashley, cron / crontab, Fat Bitch trojan,
GabanBus, icmp_client.c, icmp_pipe.c,
Mypic, NetBus, NetBus Toy, NetBus worm,
Pie Bill Gates, Whack Job, X-bill, Amitis
12346-12752	tcp/udp	#	Unassigned
12346 	tcp/udp 	# 	Fat Bitch trojan, GabanBus, NetBus, X-bill
12349 	tcp 	# 	BioNet
12361-12363 	tcp 	# 	Whack-a-mole
12623 	udp 	# 	DUN Control
12646 	tcp 	# 	ButtMan
12631 	tcp 	# 	Whack Job
12753	tcp/udp	tsaf	tsaf port
12754-12999	tcp/udp	#	Unassigned
12754 	tcp 	# 	Mstream
13000-13159	tcp/udp	#	Unassigned
13000 	udp 	# 	RAT:Senna Spy Trojan Generator
requires VB
13010 	tcp 	# 	Hacker Brasil - HBR
13013-13014 	tcp 	# 	PsychWard
13160	tcp/udp	i-zipqd	I-ZIPQD
13161-13222	tcp/udp	#	Unassigned
13173 	tcp/udp 	# 	Amitis
13223	tcp/udp	powwow-client	PowWow Client
13223 	tcp 	# 	HackL99 KeyLogger
13224	tcp/udp	powwow-server	PowWow Server
13225-13719	tcp/udp	#	Unassigned
13298 	tcp/udp 	# 	Theef
13473 	tcp 	# 	Chupacabra
13720	tcp/udp	bprd	BPRD Protocol (VERITAS NetBackup)
13721	tcp/udp	bpdbm	BPDBM Protocol (VERITAS NetBackup)
13722	tcp/udp	bpjava-msvc	BP Java MSVC Protocol
13723	tcp/udp	#	Unassigned
13724	tcp/udp	vnetd	Veritas Network Utility
13725-13781	tcp/udp	#	Unassigned
13782	tcp/udp	bpcd	VERITAS NetBackup
13783	tcp/udp	vopied	VOPIED Protocol
13784	tcp/udp	#	Unassigned
13785	tcp/udp	nbdb	NetBackup Database
13786-13817	tcp/udp	#	Unassigned
13818	tcp/udp	dsmcc-config	DSMCC Config
13819	tcp/udp	dsmcc-session	DSMCC Session Messages
13820	tcp/udp	dsmcc-passthru	DSMCC Pass-Thru Messages
13821	tcp/udp	dsmcc-download	DSMCC Download Protocol
13822	tcp/udp	dsmcc-ccp	DSMCC Channel Change Protocol
13823-14000	tcp/udp	#	Unassigned
14000 	tcp/udp 	# 	A default port for running Inprise
Visibroker Smart Agent ORB.
14001	tcp	sua	SUA
14001	udp	sua	De-Registered (2001 June 06)
14001	sctp	sua	SUA
14002-14032	tcp/udp	#	Unassigned
14033	tcp/udp	sage-best-com1	sage Best! Config Server 1
14034	tcp/udp	sage-best-com2	sage Best! Config Server 2
14035-14140	tcp/udp	#	Unassigned
14141	tcp/udp	vcs-app	VCS Application
14142-14144	tcp/udp	#	Unassigned
14145	tcp/udp	gcm-app	GCM Application
14146-14148	tcp/udp	#	Unassigned
14149	tcp/udp	vrts-tdd	Veritas Traffic Director
14150-14935	tcp/udp	#	Unassigned
14237-14238 	tcp 	# 	HotSync across the Internet
14500-14504 	tcp 	# 	PC Invader
14690 	tcp 	# 	bitkeeper
14728 	tcp 	# 	Zinx
14936	tcp/udp	hde-lcesrvr-1	hde-lcesrvr-1
14937	tcp/udp	hde-lcesrvr-2	hde-lcesrvr-2
14938-14999	tcp/udp	#	Unassigned
15000	tcp/udp	hydap	Hypack Data Aquisition
15000 	tcp 	# 	NetDemon
15001-15344	tcp/udp	#	Unassigned
15092 	tcp 	# 	Host Control
15104 	tcp 	# 	Mstream
15345	tcp/udp	xpilot	XPilot Contact Port
15346-15739	tcp/udp	#	Unassigned
15348 	tcp 	# 	Bionet
15740	tcp/udp	ptp	Picture Transfer Protocol
15741-16362	tcp/udp	#	Unassigned
15363	tcp/udp	3link	3Link Negotiation
15364-16160	tcp/udp	#	Unassigned
15382 	tcp 	# 	SubZero
15432 	tcp 	# 	Cyn
15858 	tcp 	# 	CDK
16161	tcp/udp	sun-sea-port	Solaris SEA Port
16162-16308	tcp/udp	#	Unassigned
16309	tcp/udp	etb4j	etb4j
16310-16359	tcp/udp	#	Unassigned
16322 	tcp/udp 	# 	Lastdoor
16360	tcp/udp	netserialext1	netserialext1
16361	tcp/udp	netserialext2	netserialext2
16362-16366	tcp/udp	#	Unassigned
16367	tcp/udp	netserialext3	netserialext3
16368	tcp/udp	netserialext4	netserialext4
16369-16383	tcp/udp	#	Unassigned
16384	tcp/udp	connected	Connected Corp
16385-16990	tcp/udp	#	Unassigned
16484 	tcp 	# 	Mosucker
16660 	tcp 	# 	Stacheldraht
16661 	tcp 	# 	Haxdoor
16772 	tcp 	# 	ICQ Revenge
16959 	tcp 	# 	SubSeven, Subseven 2.1.4 DefCon 8
16969 	tcp 	# 	RAT:Priority
16991	tcp/udp	intel-rci-mp	INTEL-RCI-MP
16992-17006	tcp/udp	#	Unassigned
16999 	tcp 	# 	Stealer
17007	tcp/udp	isode-dua	 
17008-17184	tcp/udp	#	Unassigned
17166 	tcp 	# 	Mosaic
17185	tcp/udp	soundsvirtual	Sounds Virtual
17186-17218	tcp/udp	#	Unassigned
17219	tcp/udp	chipper	Chipper
17220-17999	tcp/udp	#	Unassigned
17300 	tcp 	# 	Kuang2 the virus
17449 	tcp 	# 	Kid Terror
17499-17500 	tcp 	# 	CrazzyNet
17569 	tcp 	# 	Infector
15793 	tcp 	# 	Audiodoor
17777 	tcp 	# 	Nephron
18000	tcp/udp	biimenu	Beckman Instruments, Inc.
18001-18180	tcp/udp	#	Unassigned
18181	tcp/udp	opsec-cvp	OPSEC CVP
18182	tcp/udp	opsec-ufp	OPSEC UFP
18183	tcp/udp	opsec-sam	OPSEC SAM
18184	tcp/udp	opsec-lea	OPSEC LEA
18185	tcp/udp	opsec-omi	OPSEC OMI
18186	tcp/udp	ohsc	Occupational Health SC
18187	tcp/udp	opsec-ela	OPSEC ELA
18188-18240	tcp/udp	#	Unassigned
18241	tcp/udp	checkpoint-rtm	Check Point RTM
18242-18462	tcp/udp	#	Unassigned
18463	tcp/udp	ac-cluster	AC Cluster
18464-18768	tcp/udp	#	Unassigned
18753 	udp 	# 	Shaft
18769	tcp/udp	ique	IQue Protocol
18770-18880	tcp/udp	#	Unassigned
18881	tcp/udp	infotos	Infotos
18882-18887	tcp/udp	#	Unassigned
18888	tcp/udp	apc-necmp	APCNECMP
18888 	tcp/udp 	# 	LiquidAudio
18889-18999	tcp/udp	#	Unassigned
18916 	tcp/udp 	# 	Haxdoor
19000	tcp/udp	igrid	iGrid Server
19001-19190	tcp/udp	#	Unassigned
19191	tcp/udp	opsec-uaa	OPSEC UAA
19192-19193	tcp/udp	#	Unassigned
19194	tcp/udp	ua-secureagent	UserAuthority SecureAgent
19195-19282	tcp/udp	#	Unassigned
19283	tcp/udp	keysrvr	Key Server for SASSAFRAS
19284-19314	tcp/udp	#	Unassigned
19315	tcp/udp	keyshadow	Key Shadow for SASSAFRAS
19316-19397	tcp/udp	#	Unassigned
19340 	tcp/udp 	# 	RemoteNC
19381 	tcp/udp 	# 	W32.Watsoon
19398	tcp/udp	mtrgtrans	mtrgtrans
19399-19409	tcp/udp	#	Unassigned
19410	tcp/udp	hp-sco	hp-sco
19411	tcp/udp	hp-sca	hp-sca
19412	tcp/udp	hp-sessmon	HP-SESSMON
19413-19539	tcp/udp	#	Unassigned
19540	tcp/udp	sxuptp	SXUPTP
19541	tcp/udp	jcp	JCP Client
19542-19999	tcp/udp	#	Unassigned
19864 	tcp 	# 	ICQ Revenge
19937 	tcp 	# 	Gaster
20000	tcp/udp	dnp	DNP
20000 	tcp 	# 	Millenium
20001	tcp/udp	microsan	MicroSAN
20002	tcp/udp	commtact-http	Commtact HTTP
20003	tcp/udp	commtact-https	Commtact HTTPS
20004-20033	tcp/udp	#	Unassigned
20034	tcp/udp	nburn_id	NetBurner ID Port
20035-20201	tcp/udp	#	Unassigned
20001 	tcp 	# 	Millenium, Millenium (Lm)
20002 	tcp 	# 	AcidkoR
20005 	tcp 	# 	Mosucker
20023 	tcp 	# 	VP Killer
20034 	tcp 	# 	NetBus 2.0 Pro Hidden, NetRex, Whack Job
20168 	tcp 	# 	Lovgate
20202	tcp/udp	ipdtp-port	IPD Tunneling Port
20203-20221	tcp/udp	#	Unassigned
20203 	tcp 	# 	Chupacabra
20222	tcp/udp	ipulse-ics	iPulse-ICS
20223-20669	tcp/udp	#	Unassigned
20226 	tcp 	# 	AntiLam
20331 	tcp 	# 	BLA trojan
20432 	tcp 	# 	Shaft
20433 	udp 	# 	Shaft
20670	tcp/udp	track	Track
20671-20998	tcp/udp	#	Unassigned
20999	tcp/udp	athand-mmp	At Hand MMP
21000	tcp/udp	irtrans	IRTrans Control
21001-21589	tcp/udp	#	Unassigned
21157 	udp 	# 	Activision gaming protocol
21217 	tcp/udp 	# 	Asniffer
21544 	tcp 	# 	GirlFriend, Kid Terror
21554 	tcp 	# 	Exploiter, Kid Terror, Schwindler, Winsp00fer
21590	tcp/udp	vofr-gateway	VoFR Gateway
21591-21799	tcp/udp	#	Unassigned
21800	tcp/udp	tvpm	TVNC Pro Multiplexing
21801-21844	tcp/udp	#	Unassigned
21845	tcp/udp	webphone	webphone
21846	tcp/udp	netspeak-is	NetSpeak Corp. Directory Services
21847	tcp/udp	netspeak-cs	NetSpeak Corp. Connection Services
21848	tcp/udp	netspeak-acd	NetSpeak Corp. Automatic Call Distribution
21849	tcp/udp	netspeak-cps	NetSpeak Corp. Credit Processing System
21850-21999	tcp/udp	#	Unassigned
22000	tcp/udp	snapenetio	SNAPenetIO
22001	tcp/udp	optocontrol	OptoControl
22002-22272	tcp/udp	#	Unassigned
22222 	tcp 	# 	Donald Dick, Prosiak, Ruler, RUX The TIc.K
22273	tcp/udp	wnn6	wnn6
22274-22554	tcp/udp	#	Unassigned
22311 	tcp/udp 	# 	Simali
22555	tcp	vocaltec-wconf	Vocaltec Web Conference
22555	udp	vocaltec-phone	Vocaltec Internet Phone
22556-22792	tcp/udp	#	Unassigned
22703 	tcp 	# 	WebTV is vulnerable to an exploit
on this port that can reboot the machine..
22793 	tcp 	vocaltec-wconf 	VocalTec Internet Phone
TCP connection to VocalTec's Addressing servers.
22794-22799	tcp/udp	#	Unassigned
22800	tcp/udp	aws-brf	Telerate Information Platform LAN
22801-22950	tcp/udp	#	Unassigned
22951	tcp/udp	brf-gw	Telerate Information Platform WAN
22952-23999	tcp/udp	#	Unassigned
23005-23006 	tcp 	# 	NetTrash, Platrash
23023 	tcp 	# 	Logged
23032 	tcp 	# 	Amanda
23213-23214 	tcp/udp 	# 	PowWow
by Tribal Voice
23232 	tcp 	# 	Berbew
23432 	tcp 	# 	Asylum
23435 	tcp 	# 	Frango, Framar
23456 	tcp/udp 	# 	Trojan:EvilFTP, Ugly FTP, Whack Job
23476 	tcp/udp 	# 	Donald Dick
23477 	tcp 	# 	Donald Dick
23666 	tcp/udp 	# 	Beasty
23777 	tcp 	# 	InetSpy
24000	tcp/udp	med-ltp	med-ltp
24000 	tcp 	# 	Infector
24001	tcp/udp	med-fsp-rx	med-fsp-rx
24002	tcp/udp	med-fsp-tx	med-fsp-tx
24003	tcp/udp	med-supp	med-supp
24004	tcp/udp	med-ovw	med-ovw
24005	tcp/udp	med-ci	med-ci
24006	tcp/udp	med-net-svc	med-net-svc
24007-24241	tcp/udp	#	Unassigned
24242	tcp/udp	filesphere	fileSphere
24243-24248	tcp/udp	#	Unassigned
24249	tcp/udp	vista-4gl	Vista 4GL
24250-24385	tcp/udp	#	Unassigned
24386	tcp/udp	intel_rci	Intel RCI
24387-24553	tcp/udp	#	Unassigned
24554	tcp/udp	binkp	BINKP
24554-34676	tcp/udp	#	Unassigned
24677	tcp/udp	flashfiler	FlashFiler
24678	tcp/udp	proactivate	Turbopower Proactivate
24679-24921	tcp/udp	#	Unassigned
24681 	tcp 	# 	Lowtaper
24759 	tcp 	# 	Zinx
24922	tcp/udp	snip	Simple Net Ident Protocol
24923-24999	tcp/udp	#	Unassigned
25000	tcp/udp	icl-twobase1	icl-twobase1
25001	tcp/udp	icl-twobase2	icl-twobase2
25002	tcp/udp	icl-twobase3	icl-twobase3
25003	tcp/udp	icl-twobase4	icl-twobase4
25004	tcp/udp	icl-twobase5	icl-twobase5
25005	tcp/udp	icl-twobase6	icl-twobase6
25006	tcp/udp	icl-twobase7	icl-twobase7
25007	tcp/udp	icl-twobase8	icl-twobase8
25008	tcp/udp	icl-twobase9	icl-twobase9
25009	tcp/udp	icl-twobase10	icl-twobase10
25010-25792	tcp/udp	#	Unassigned
25025-25026 	tcp 	# 	Kodalo
25044 	tcp 	# 	Kodalo
25685-25686 	tcp 	# 	Moonpie
25793	tcp/udp	vocaltec-hos	Vocaltec Address Server
25794-25899	tcp/udp	#	Unassigned
25900	tcp/udp	tasp-net	TASP Network Comm
25901	tcp/udp	niobserver	NIObserver
25902	tcp/udp	#	Unassigned
25903	tcp/udp	niprobe	NIProbe
25904-25999	tcp/udp	#	Unassigned
25982 	tcp 	# 	Moonpie
26000	tcp/udp	quake	quake
26001-26207	tcp/udp	#	Unassigned
26208	tcp/udp	wnn6-ds	wnn6-ds
26209-26259	tcp/udp	#	Unassigned
26260	tcp/udp	ezproxy	eZproxy
26261	tcp/udp	ezmeeting	eZmeeting
26262	tcp/udp	k3software-svr	K3 Software-Server
26263	tcp/udp	k3software-cli	K3 Software-Client
26264	tcp/udp	gserver	Gserver
26265-26999	tcp/udp	#	Unassigned
26274 	udp 	# 	Trinoo
26681 	tcp 	# 	Voice Spy
27000-27009	tcp/udp	flex-lm	FLEX LM (1-10)
27000 	tcp/udp 	# 	May be used as part of a Quake related game.
27001 	tcp/udp 	# 	QuakeWorld
27010-27344	tcp/udp	#	Unassigned
27010 	tcp 	# 	Half-Life(Server)
27015 	tcp 	# 	Half-Life
27345	tcp/udp	imagepump	ImagePump
27346-27503	tcp/udp	#	Unassigned
27374 	tcp/udp 	# 	Bad Blood, Ramen, Seeker, SubSeven,
Subseven 2.1.4 DefCon 8, SubSeven Muie,
Ttfloader, Baste
27379 	tcp/udp 	# 	Optix
27444 	udp 	# 	Trinoo slave port
27504	tcp/udp	kopek-httphead	Kopek HTTP Head Port
27505-27781	tcp/udp	#	Unassigned
27551 	tcp/udp 	# 	Amitis
27573 	tcp 	# 	SubSeven Trojan
27665 	tcp 	# 	Trinoo master port
27782	tcp/udp	ars-vista	ARS VISTA Application
27783-27998	tcp/udp	#	Unassigned
27910 	tcp/udp 	# 	May be used as part of a Quake related game.
27960 	tcp/udp 	# 	QuakeIII
27999	tcp	tw-auth-key	TW Authentication/Key Distribution and
27999	udp	tw-auth-key	Attribute Certificate Services
28000	tcp/udp	nxlmd	NX License Manager
28000-28008 	udp 	# 	Starsiege TRIBES
28001-28239	tcp/udp	#	Unassigned
28240	tcp/udp	siemensgsm	Siemens GSM
28241-29999	tcp/udp	#	Unassigned
28253 	tcp 	# 	Berbew
28678 	tcp 	# 	Exploiter
28876 	tcp 	# 	Globe
28882-28883 	tcp 	# 	Mitglieder
29104 	tcp 	# 	NetTrojan
29147 	tcp 	# 	Sdbot
29369 	tcp 	# 	ovasOn
29559 	tcp/udp 	# 	Antilam
29891 	tcp 	# 	The Unexplained
30000	tcp/udp	#	Unassigned
30000 	tcp 	# 	Infector
30001	tcp/udp	pago-services1	Pago Services 1
30001 	tcp 	# 	ErrOr32, W32.Gaobot
30002	tcp/udp	pago-services2	Pago Services 2
30003-31415	tcp/udp	#	Unassigned
30003 	tcp 	# 	Lamers Death
30029 	tcp 	# 	AOL Admin 1.1
30100 	tcp 	# 	RAT: NetSphere
30101 	tcp 	# 	RAT: NetSphere
An FTP service is run at TCP port 30101
in order to download the keylogger files
and recorded WAV files.
30102 	tcp 	# 	RAT: NetSphere (TCP)
An FTP service is run at TCP port 30102
in order to download screen captures.
30103 	tcp/udp 	# 	RAT: NetSphere
30133 	tcp 	# 	NetSphere
30303 	tcp/udp 	# 	Sockets de Troie
(A French Trojan Horse and virus)
30464 	tcp 	# 	SMTP ETRN overflow
A known Netwin ESMTP exploit binds
a root shell to TCP port 30464.
30947 	tcp 	# 	Intruse
30999 	tcp 	# 	Kuang2
31320 	tcp/udp 	# 	LittleWitch
31332 	tcp/udp 	# 	Grobodor
31335 	tcp/udp 	# 	Trinoo slave->master port.
The packet contains the string
"*HELLO*" on notification, or "PONG"
when responding to a broadcast.
31336 	tcp 	# 	Bo Whack, Butt Funnel
31337 	tcp 	# 	Back Fire, Back Orifice 1.20 patches,
Back Orifice,Back Orifice russian,
Baron Night, Beeone, BO client, BO Facil,
BO spy, BO2, cron / crontab, Freak88,
Freak2k, icmp_pipe.c, Sockdmini,
W32.HLLW.Gool, Emcommander
31337 	udp 	# 	Back Orifice
Back Orifice is a backdoor program that
commonly runs at this port. Scans on this
port are usually looking for Back Orifice.
31337-31388 	udp 	# 	Deep BO
31388 	tcp 	# 	Back Orifice, Butt Funnel, NetSpy (DK)
31339 	tcp 	# 	NetSpy (DK)
31416	tcp/udp	xqosd	XQoS network monitor
31417-31456	tcp/udp	#	Unassigned
31457	tcp/udp	tetrinet	TetriNET Protocol
31458-31764	tcp/udp	#	Unassigned
31556 	tcp/udp 	# 	Zdemon, SysXXX
31620	tcp/udp	lm-mon	lm mon
31621-31764	tcp/udp	#	Unassigned
31666 	tcp 	# 	BOWhack
31693 	tcp/udp 	# 	Turkojan
31765	tcp/udp	gamesmith-port	GameSmith Port
31766-32248	tcp/udp	#	Unassigned
31785 	tcp 	# 	HackLaLTack
31787-31792 	tcp 	# 	HackLaLTack
32001 	tcp 	# 	Donald Dick
32100 	tcp 	# 	Peanut Brittle, Project nEXT
32121 	tcp 	# 	Berbew
32249	tcp/udp	t1distproc60	T1 Distributed Processor
32250-32634	tcp/udp	#	Unassigned
32418 	tcp 	# 	Acid Battery
32440 	tcp 	# 	Alets
32635	tcp/udp	sec-ntb-clnt	SecureNotebook-CLNT
32636-32767	tcp/udp	#	Unassigned
32768	tcp/udp	filenet-tms	Filenet TMS
32769	tcp/udp	filenet-rpc	Filenet RPC
32770	tcp/udp	filenet-nch	Filenet NCH
32771	tcp/udp	filenet-rmi	FileNET RMI
32771 	tcp/udp 	# 	Ghost Portmapper. Some SunOS machines
listen at this port for portmapper. Since
firewalls frequently don't filter at high ports,
it can allow the attacker access to portmapper
even when port 111 is blocked.
32772	tcp/udp	filenet-pa	FileNET Process Analyzer
32773	tcp/udp	filenet-cm	FileNET Component Manager
32774	tcp/udp	filenet-re	FileNET Rules Engine
32773 	tcp/udp 	#rpc.ttdbserverd 	Sun puts RPC services in this region. Scans
against this port might be looking for any
RPC service, or maybe the rpc.ttdbserverd
or rpc.sadmind service.
32775-32895	tcp/udp	#	Unassigned
32776 	tcp/udp 	#rpc.spray 	Sun puts RPC services in this region. Scans
against this port might be looking for any
RPC service, or maybe the rpc.spray service.
32777 	tcp/udp 	#rpc.walld 	Sun puts RPC services in this region. Scans
against this port might be looking for any
RPC service, or maybe the rpc.walld service.
32779 	tcp/udp 	#rpc.cmsd 	Sun puts RPC services in this region. Scans
against this port might be looking for any
RPC service, or maybe the rpc.cmsd service.
33270 	tcp 	# 	Trinity
32896	tcp/udp	idmgratm	Attachmate ID Manager
32897-33330	tcp/udp	#	Unassigned
33331	tcp/udp	diamondport	DiamondCentral Interface
33332-33433	tcp/udp	#	Unassigned
33333 	tcp 	# 	Blakharaz, Prosiak, Selka
33434	tcp/udp	traceroute	traceroute use
33435-34248	tcp/udp	#	Unassigned
33577 	tcp 	# 	Son of PsychWard
33777 	tcp 	# 	Son of PsychWard
33911 	tcp 	# 	Spirit 2000, Spirit 2001
34249	tcp/udp	turbonote-2	TurboNote Relay Server Default Port
34250-34377	tcp/udp	#	Unassigned
34324 	tcp 	# 	Big Gluck, TN
34378	tcp/udp	p-net-local	P-Net on IP local
34379	tcp/udp	p-net-remote	P-Net on IP remote
34380-34961	tcp/udp	#	Unassigned
34444 	tcp 	# 	Donald Dick
34555 	udp 	# 	Windows Trin00 Trojan
34962	tcp/udp	profinet-rt	PROFInet RT Unicast
34963	tcp/udp	profinet-rtm	PROFInet RT Multicast
34964	tcp/udp	profinet-cm	PROFInet Context Manager
34965-34979	tcp/udp	#	Unassigned
34980	tcp/udp	ethercat	EtherCAT Port
34981-36864	tcp/udp	#	Unassigned
35555 	udp 	# 	Windows Trin00 Trojan
36183 	tcp 	# 	Lifefournow
36865	tcp/udp	kastenxpipe	KastenX Pipe
36866-37474	tcp/udp	#	Unassigned
37237 	tcp 	# 	Mantis
37475	tcp/udp	neckar	science + computing's Venus Administration Port
37476-38200	tcp/udp	#	Unassigned
37651 	tcp 	# 	Yet Another Trojan - YAT
38036 	tcp/udp 	#timestep 	The Timestep VPN from Saytek can run at
this port.
38201	tcp/udp	galaxy7-data	Galaxy7 Data Tunnel
38202	tcp/udp	#	Unassigned
38203	tcp/udp	agpolicy	AppGate Policy Server
38204-39680	tcp/udp	#	Unassigned
39681	tcp/udp	turbonote-1	TurboNote Default Port
39682-39999	tcp/udp	#	Unassigned
39112 	tcp/udp 	# 	Upfudoor
39581 	tcp/udp 	# 	Winshell
39872 	tcp/udp 	# 	Drator
40000-40840	tcp/udp	#	Unassigned
40193 	tcp/udp 	#	Novell servers can be crashed by sending
random data to this port.
40403 	tcp 	# 	W32.Randex
40412 	tcp 	# 	The Spy
40421 	tcp 	# 	Agent 40421, Masters Paradise
40422-40426 	tcp 	# 	Masters Paradise
40841	tcp/udp	cscp	CSCP
40842	tcp/udp	csccredir	CSCCREDIR
40843	tcp/udp	csccfirewall	CSCCFIREWALL
40844-41110	tcp/udp	#	Unassigned
41111	tcp/udp	fs-qos	Foursticks QoS Protocol
41112-41793	tcp/udp	#	Unassigned
41337 	tcp 	# 	Storm
41666 	tcp 	# 	Remote Boot Tool - RBT
41524 	tcp/udp 	#	arcserve
Runs a discovery protocol on this port.
41794	tcp/udp	crestron-cip	Crestron Control Port
41795	tcp/udp	crestron-ctp	Crestron Terminal Port
41796-43187	tcp/udp	#	Unassigned
41934 	tcp 	# 	Ranky
42321 	tcp 	# 	Ranky
43188	tcp/udp	reachout	REACHOUT
43189	tcp/udp	ndm-agent-port	NDM-AGENT-PORT
43190	tcp/udp	ip-provision	IP-PROVISION
43191-44320	tcp/udp	#	Unassigned
43958 	tcp/udp 	# 	IRC.Aladinz
44280 	tcp/udp 	# 	Amitis
44321	tcp/udp	pmcd	PCP server (pmcd)
44322	tcp/udp	pmcdproxy	PCP server (pmcd) proxy
43323-44552	tcp/udp	#	Unassigned
44390 	tcp/udp 	# 	Amitis
44444 	tcp 	# 	Prosiak, W32.Kibuv
44445-44446 	tcp 	# 	W32.Kibuv
44553	tcp/udp	rbr-debug	REALbasic Remote Debug
43554-44817	tcp/udp	#	Unassigned
44575 	tcp 	# 	Exploiter
44818	tcp/udp	rockwell-encap	Rockwell Encapsulation
44819-45053	tcp/udp	#	Unassigned
45000 	tcp/udp 	# 	Cisco SAFE IDS / NetRanger
NetRanger (and IDS probe) regularly
communicates to the "Director"
(management console) via port 45000.
Among other things, this acts as a
hearbeat so that the console knows
the agent is alive.
45054	tcp/udp	invision-ag	InVision AG
45055-45677	tcp/udp	#	Unassigned
45672 	tcp/udp 	# 	Delf
45678	tcp/udp	eba	EBA PRISE
45679-45965	tcp/udp	#	Unassigned
45836 	tcp/udp 	# 	W32.HLLW.Graps
45966	tcp/udp	ssr-servermgr	SSRServerMgr
45967-46998	tcp/udp	#	Unassigned
46999	tcp/udp	mediabox	MediaBox Server
47000	tcp/udp	mbus	Message Bus
47001-47017	tcp/udp	#	Unassigned
47017 	tcp/udp 	# 	Part of rootkit "t0rn", a program
called "in.amqd" might run on this.
47018-47556	tcp/udp	#	Unassigned
47262 	udp 	# 	Delta Source
47387 	tcp/udp 	# 	Amitis
47557	tcp/udp	dbbrowse	Databeam Corporation
47558-47623	tcp/udp	#	Unassigned
47624	tcp/udp	directplaysrvr	Direct Play Server
47625-47805	tcp/udp	#	Unassigned
47806	tcp/udp	ap	ALC Protocol
47807	tcp/udp	#	Unassigned
47808	tcp/udp	bacnet	Building Automation and Control Networks
47809-47999	tcp/udp	#	Unassigned
48000	tcp/udp	nimcontroller	Nimbus Controller
48001	tcp/udp	nimspooler	Nimbus Spooler
48002	tcp/udp	nimhub	Nimbus Hub
48003	tcp/udp	nimgtw	Nimbus Gateway
48004-48555	tcp/udp	#	Unassigned
48556	tcp/udp	com-bardac-dw	com-bardac-dw
48557-48618	tcp/udp	#	Unassigned
48619	tcp/udp	iqobject	iqobject
48620-49150	tcp/udp	#	Unassigned
49151	tcp/udp	#	IANA Reserved
49301 	tcp 	# 	OnLine KeyLogger
50021 	tcp/udp 	# 	OptixPro
50130 	tcp 	# 	Enterprise
50505 	tcp/udp 	# 	Sockets de Troie
(A French Trojan Horse and virus)
50766 	tcp 	# 	Fore, Schwindler
51966 	tcp 	# 	Cafeini
51234 	tcp 	# 	Cyn
52031 	tcp/udp 	# 	Graybird
52317 	tcp 	# 	Acid Battery 2000
52559 	tcp 	# 	AntiLam
52901 	udp 	# 	Possibly the Omega DDoS tool.
53001 	tcp 	# 	Remote Windows Shutdown - RWS
53201 	tcp 	# 	Backdoor.Ranck
54112 	tcp 	# 	Ranky
54283 	tcp 	# 	SubSeven, SubSeven 2.1 Gold
54312 	tcp/udp 	# 	Niovadoor
54320 	tcp 	# 	Back Orifice 2000
54321 	tcp 	# 	Back Orifice 2000, School Bus
54321 	udp 	# 	A service that replies with the load
average of a machine.
55000 	tcp 	# 	Roxe
55808 	udp 	# 	Randex
55165 	tcp 	# 	File Manager trojan, File Manager trojan,
WM Trojan Generator
55166 	tcp 	# 	WM Trojan Generator
55168 	tcp 	# 	Haxdoor
55665-55666 	tcp/udp 	# 	Latinus
57005 	tcp 	# 	IRC.Cirebot
57123 	tcp 	# 	Mprox
57341 	tcp 	# 	NetRaider
58339 	tcp 	# 	Butt Funnel
58343 	tcp 	# 	Prorat
58666 	tcp/udp 	# 	Redkod
60000 	tcp 	# 	Deep Throat, Foreplay, Sockets des Troie
60001 	tcp 	# 	Trinity
60068 	tcp 	# 	Xzip 6000068
60101 	tcp 	# 	Stealer
60411 	tcp 	# 	Connection
61000 	tcp/udp 	# 	Mite
61282 	tcp 	# 	W32.Squirm@mm, W32.Pandem.B.Worm
61348 	tcp 	# 	Bunker-Hill
61466 	tcp 	# 	TeleCommando
61603 	tcp 	# 	Bunker-Hill
63000-63001 	tcp 	# 	W32.Gaobot
63485 	tcp 	# 	Bunker-Hill
63809 	tcp 	# 	Gaobot
64101 	tcp 	# 	Taskman
64429 	tcp 	# 	Amitis
65000 	tcp 	# 	Devil, Sockets des Troie, Stacheldraht, Roxrat
65010 	tcp 	# 	Roxrat
65301 	udp 	# 	PCanywhere
65390 	tcp 	# 	Eclypse
65421 	tcp 	# 	Jade
65432 	tcp/udp 	# 	The Traitor (= th3tr41t0r)
65475 	tcp/udp 	# 	W32.Gaobot
65534 	tcp 	# 	/sbin/initd
65535 	tcp 	# 	RC1 trojan
|;

$_ =~ s/"//g;
@_ = split(/\n/,$_);

sub dobek {
  my($p,$t,$s,$d) = @_;
  return if exists $trojans->{$p} &&
	    $t =~ /udp/;
  $trojans->{$p} = &$builder($p,$d);
}

foreach (@_) {
  next unless $_ =~ /^\d+/;			# skip extra text lines
  my($p,$t,$s,$d) = split(/\s+/,$_,4);
  next unless $d;				# skip null descriptions
  next if $d =~ /unassigned|reserved/i ||	# skip unassigned, null and blank
	  $d !~ /\S/;
  if ($p =~ /(\d+)\-(\d+)/) {
    my $p1 = $1;
    my $p2 = $2;
    foreach($p1..$p2) {
      dobek($_,$t,$s,$d);
    }
  } else {
    $p =~ /\d+/;
    dobek($&,$t,$s,$d);
  }
}

#foreach (sort {$a <=> $b } keys %$trojans) {
#  print "$_\t=> $trojans->{$_}\n";
#}

1;
