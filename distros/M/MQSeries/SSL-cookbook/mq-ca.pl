#!/usr/bin/perl -w
# self signed CA SSL certificate generator for MQ using IBM GSK
# $Id: mq-ca.pl,v 32.1 2008/03/27 18:20:19 biersma Exp $
# $Date: 2008/03/27 18:20:19 $

# morten.bjornsvik@experian-scorex.no Jan 2008

use strict;
use warnings;
use Time::HiRes qw(time);
use Getopt::Long;

# set default parameters

# binaries we use
my $gsk7cmd = "/bin/gsk7cmd"; # ibm gskit command binary found in MQ distribution
my $rm = "/bin/rm";
my $mkdir = "/bin/mkdir";

# set default parameters
#my $qm  = undef;     # quemanager to issue certificates
my $qm        = 'swolinux';
#my $pw        = 'password123';   # certificate password, we use the same all over for convenience
my $pw = undef;
my $exp       = 365;        # expiration in days
my $calabel   = 'Experian Secana Public CA';

my $debug = 1;        # 0-none,1-standard,2-verbose,3-everything
my $test = undef;     # do not execute only test
my $op= undef;
my $force = undef;        
#my $dn  = undef;     # distinguished name, tailored for your organization
my $dn = "CN=Experian Secana CA,O=Experian,OU=Decision Analytics,L=Oslo,C=NO";
my $help = undef;
my $JAVA_HOME = '/opt/mqm/ssl/jre';   #gsk7cmd is java based
my $old_java_home = undef;
my $hint = 1;  # print oout some mq setup hint 
my $cadir = 'ca';
my $uname = undef;

my $nparam = GetOptions (
  "op=s"                     => \$op,
  "qm|queuemanager=s"        => \$qm,
  "username|uname=s"         => \$uname,
  "pw|password|passwd=s"     => \$pw,
  "exp|expiredays=i"         => \$exp,
  "calabel|label=s"          => \$calabel,
  "cadir=s"                  => \$cadir,
  "dn=s"                     => \$dn,
  "JAVA_HOME=s"              => \$JAVA_HOME,
  "gsk7cmd=s"                => \$gsk7cmd,
  "rm=s"                     => \$rm,
  "mkdir=s"                  => \$mkdir,
  "debug=i"                  => \$debug,
  "test"                     => \$test,
  "force"                    => \$force,
  "help|h"                   => \$help,
  "hint"                     => \$hint,
) || print legend();


# print legend if --help is defined
if(defined $help) {
  print legend()."\n";
  exit(1);
}
# die if any of the needed binaries aren't found
die("binary --gsk7cmd=<gsk7cmd binary> not found or no executable binary, is mq installed?\n") if(! defined $gsk7cmd || ! -x $gsk7cmd);
die("JAVA_HOME environment variable must be set, and point to a java jre runtime\n") if(! defined $JAVA_HOME || ! -d $JAVA_HOME);
die("binary --rm=<rm binary> not found or no executable binary\n") if(! defined $rm || ! -x $rm);
die("binary --mkdir=<mkdir binary> not found or no executable binary\n") if(! defined $mkdir || ! -x $mkdir);

# die if mandatory parameters are not defined
die("--qm=<mq-queuemanager> not defined\n") if(! defined $qm);
die("--pw=<certificate password> not defined\n") if(! defined $pw);
die("--dn=<distinguished name> not defined\n") if(! defined $dn);
die("--calabel=<certificate label> not defined\n") if(! defined $calabel);
die("--cadir=<directory to CA-reporistory> not defined\n") if(! defined $cadir);
die("--op=<operation> must be defined (ca|mq|client)\n") if(! defined $op);

if($op =~ /^client$/i && ! defined $uname) {
  die("--uname=<client username> must be defined if --op=client\n");  
}

# store old JAVA_HOME environment if it exists
if(exists $ENV{'JAVA_HOME'}) {
  if($ENV{'JAVA_HOME'} ne $JAVA_HOME) {
    print "Save old 'JAVA_HOME=".$ENV{'JAVA_HOME'}."\n" if($debug);
    $old_java_home=$ENV{'JAVA_HOME'};
  }
}

# set new JAVA_HOME environment needed by gsk7cmd, must run in shell
print "#Set environment variable:\nexport JAVA_HOME=$JAVA_HOME\n" if($debug);
$ENV{'JAVA_HOME'} = $JAVA_HOME;

# since MQ is case-insensitive, we convert everything to lowercase
$qm=lc($qm);

# test mode turns on debug=1 if debug is off
if($test) {
  $debug=1 if(! $debug);
}
# start of main

if($debug > 1) {
  # add additional debug info to the $gsk7cmd if debug is higher than 1
  $gsk7cmd .= " -Dkeyman.debug=true -Dkeyman.jnitracing=YES";
}

# create key operation
if( $op =~ /ca/i) {

  check_dir($cadir);

  print "#Create directory '$cadir'\n" if($debug);
  pexe("$mkdir -p $cadir");
  
  # the timespan on the certificate must be larger than for the keys
  my $exp2 = $exp + 1;
  print "#Create CA key repository '$cadir/myCA.kdb'\n" if($debug);
  pexe("$gsk7cmd -keydb -create -db '$cadir/myCA.kdb' -pw $pw -type cms -expire $exp2");

  print "#Create a self signed CA certificate in '$cadir/myCA.kdb'\n" if($debug);
  pexe("$gsk7cmd -cert -create -db '$cadir/myCA.kdb' -type cms -pw $pw -label '$calabel' -dn '$dn' -expire $exp2 -size 1024");
  
  print "#Extract CA public certificate '$cadir/myCA.cer'\n" if($debug);
  pexe("$gsk7cmd -cert -extract -db '$cadir/myCA.kdb' -pw $pw -label '$calabel' -target '$cadir/myCApublic.cer'");  
}

# create a self-signed certificate for a queue-manager
if( $op =~ /qm/i || $op =~/queuemanager/i) {

  die("--cadir=$cadir not a directory\n") if(! -d $cadir);

  # all files related to keys
  my $keydir = 'qmcert-'.$qm;

  die("#You must do the CA part first\n") if(! -d $cadir);
  check_dir($keydir);

  print "#Create queue-manager directory '$keydir'\n" if($debug);
  pexe("$mkdir -p $keydir");
  
  print "#Creating qm-key repository '$keydir/$qm.kdb'\n" if($debug);
  pexe("$gsk7cmd -keydb -create -db '$keydir/$qm.kdb' -pw $pw -type cms -expire $exp -stash");
  
  print "#Add the CA cert '$cadir/myCAcertfile.cer' to qm-key repository\n" if($debug);
  pexe("$gsk7cmd -cert -add -db '$keydir/$qm.kdb' -pw $pw -label '$calabel' -file '$cadir/myCApublic.cer' -format ascii -trust enable");

  print "#Creating certificate request '$keydir/$qm.req' in key database '$keydir/$qm.kdb'\n" if($debug);
  $dn =~ s/CN=.+?,/CN=$qm - queuemanager,/;    # we need a unique dn fro all certificates
  pexe("$gsk7cmd -certreq -create -db '$keydir/$qm.kdb' -pw $pw -label 'ibmwebspheremq$qm' -dn '$dn' -file '$keydir/$qm.req'");

  # do we need all files in the same directory?  
  print "#CA signs '$keydir/$qm.req' certificate request\n" if($debug);
  pexe("$gsk7cmd -cert -sign -db '$cadir/myCA.kdb' -pw $pw -label '$calabel' -file '$keydir/$qm.req' -target '$keydir/$qm.cer' -expire $exp");
    
  print "#Receive signed certificate '$keydir/$qm.cer' into qm-key repository\n" if($debug);
  pexe("$gsk7cmd -cert -receive -db '$keydir/$qm.kdb' -pw $pw -file '$keydir/$qm.cer'");
  
  print "#Cleaning up temporary files\n" if($debug);
  pexe("$rm $keydir/$qm.cer") if(-f "$keydir/$qm.cer");
  pexe("$rm $keydir/$qm.req") if(-f "$keydir/$qm.req");

  chomp(my $pwd = `pwd`);
  if($hint) {
    print "# hints for queue-manager:\n"
      . "runmqsc $qm\n"
      . "alter qmgr SSLKEYR(\"$keydir/$qm\")\n"
      . "# also change channels aka (see cipherSpec in MQ security manual:\n"
      . "alter channel('channelname') chltype(SDR) SSLCIPH(RC5_MD5_EXPORT)\n";
  }
}

# create acertificate for the client
# foe client $qm denoted the client
if( $op =~ /client/i ) {

  die("--cadir=<directory to CA-reporistory> not defined\n") if(! defined $cadir);
  die("--cadir=$cadir not a directory\n") if(! -d $cadir);
  
  # all files related to keys
  my $keydir = 'clientcert-'.$uname;
  
  die("You must do the CA part first\n") if(! -d $cadir);
  check_dir($keydir);

  print "#Create queue-manager directory '$keydir'\n" if($debug);
  pexe("$mkdir -p $keydir");
  
  print "#Creating qm-key repository '$keydir/key.kdb'\n" if($debug);
  pexe("$gsk7cmd -keydb -create -db '$keydir/$uname.kdb' -pw $pw -type cms -expire $exp -stash");
  
  print "#Add the CA cert '$cadir/myCAcertfile.cer' to qm-key repository\n" if($debug);
  pexe("$gsk7cmd -cert -add -db '$keydir/$uname.kdb' -pw $pw -label '$calabel' -file '$cadir/myCApublic.cer' -format ascii -trust enable");

  print "#Creating certificate request '$keydir/$uname.req' in key database '$keydir/$uname.kdb'\n" if($debug);
  $dn =~ s/CN=.+?,/CN=$qm - client,/;    # we need a unique dn fro all certificates
  pexe("$gsk7cmd -certreq -create -db '$keydir/$uname.kdb' -pw $pw -label 'ibmwebspheremq$uname' -dn '$dn' -file '$keydir/$uname.req'");

  # do we need all files in the same directory?  
  print "#CA signs '$keydir/$uname.req' certificate request\n" if($debug);
  pexe("$gsk7cmd -cert -sign -db '$cadir/myCA.kdb' -pw $pw -label '$calabel' -file '$keydir/$uname.req' -target '$keydir/$uname.cer' -expire $exp");
    
  print "#Receive signed certificate '$keydir/$uname.cer' into $uname-key repository\n" if($debug);
  pexe("$gsk7cmd -cert -receive -db '$keydir/$uname.kdb' -pw $pw -file '$keydir/$uname.cer'");
  
  print "#Cleaning up temporary files\n" if($debug);
  pexe("$rm $keydir/$uname.cer") if(-f "$keydir/$uname.cer");
  pexe("$rm $keydir/$uname.req") if(-f "$keydir/$uname.req");

  chomp(my $pwd = `pwd`);
  if($hint) {
    print "# hints for client:\n"
      . "# Copy the repository in '$pwd/$keydir' to client\n"
      . "# Set MQSSLKEYR environment vaiable on client:\n"
      . "export MQSSLKEYR=$pwd/$keydir/$uname\n"
      . "# SSLCipherSpec must be the same\n";
  }

}


# set back the old java home
if(defined $old_java_home) {
  print "#Resore old 'JAVA_HOME=$old_java_home\n" if($debug);
  $ENV{'JAVA_HOME'} = $old_java_home;
}

# helper subroutines, places at the end because of global variable dependencies
sub legend {
  print<<EOF;
$0 - gsk7cmd certificate management program
options:
--op  = <operation> ca|key|sign
        ca creates a certificate authority (ca)
        key creates a key based on the ca
        sign - only sign a key
--qm  = <queuemanager to reside files on>
--cadir = directory to put ca under. (default ./ca)
--pw  = <CA password> the same for both ca and keys
--exp = <certificate expireperiod in days> default 365 days
--dn  = <distinguished name> identificator, should be unique for all certificates
        just change the CN, can be anything
        ex: 'CN=Experian Secana CA,O=Experian,OU=Decision Analytics,L=Oslo,C=NO'
--gsk7cmd = <path to gsk2cmd binary> does all the certificate/ssl handling for mq

gsk7cmd is found in the MQSeriesKeyMan.*.rpm or newer package.
This package is part of the WebsphereMQ for linux distribution.

gsk7cmd uses Java Cryptographic Extension(JCE), which is bundled in
MQSeriesKeyMan, point the JAVA_HOME environment variable there
'export JAVA_HOME=/opt/mqm/ssl/jre'

unset it with 'unset JAVA_HOME'

See perldoc for more info, especially debugging

EOF
  exit();
}

# delete directories if found and global var $force is set
sub check_dir {
  my $dir = shift;
   if(-d $dir) {
    print "#Found old directory for '$dir'\n" if($debug);
    if(defined $force) {
      print "#delete old directory '$dir'\n" if($debug);
      pexe("$rm -rdf $dir");
    }
    else {
      die("Unable to delete '$dir', set --force to overwrite\n");
    }
  }   
}
# parsing execute string
# if global $test is defined then just print the command, do not execute
sub pexe {
  my $c = shift;        # command to execute
  my $success = shift;  # write in case of success (default OK) ($debug must be on)
  my $fail = shift;     # write in case of failure (default failed) and then die

  my $starttime = time;
  $success="ok" if(! defined $success);
  $fail="failed" if(! defined $fail);
  print "test: " if($test);
  print "$c " if($debug);
  if($test) {
    print "\n";
    return;
  }
  my $ret = system($c);
  if(!$ret) {
    printf("\n#$success %.2f sec\n",time-$starttime) if($debug);
  }
  else {
    die "\n#$fail\n";
  }
  return $ret;
}

__END__

=pod

=head1 NAME

Frontend to gsk7cmd for creating MQ SSL queuemanager certificates

=head1 SYNOPSIS

 # create Certification Authority (CA) used to sign certificates:
 mq-ca.pl -op=ca -qm=queuemanager -pw=passwd -exp=expire in days \
  -label=label of cetificate [--force] [-debug=0|1|2] 

 # create certificate for queuemanager being signed by the above CA:
 mq-ca.pl -op=qm -qm=queuemanager -pw=passwd -exp=expire in days \
  -label=label of cetificate [--force] [-debug=0|1|2] 

 # create a client certificate being signed by the above CA:
 mq-ca.pl -op=client -uname=username -pw=passwd -exp=expire in days \
  -label=label of cetificate [--force] [-debug=0|1|2]
 
 here username is clients username which must be present and member of mqm on
 both client and server. Do a 'refresh security' inside the queue-manager.
 
 -op = type of operation:
     ca     - create a CA which is used to sign certtificates
     qm     - name of quememanager to reside queues on
     client - a client which connects to a qm through a listener
 -qm  = <queuemanager to reside files on>
 -pw  = <CA password> the is set in --op=ca and is being used for --op=client and qm
 -cadir = <path to CA repository> (default ./ca)
 -exp = <certificate expireperiod in days> default 365 days
 -dn  = <distinguished name> identificator, should be unique for all certificates
        just change the CN, can be anything
        ex: 'CN=Experian Secana CA,O=Experian,OU=Decision Analytics,L=Oslo,C=NO'
 -gsk7cmd = <path to gsk2cmd binary> does all the certificate/ssl handling for mq             

=head1 REQUIREMENTS

This program needs IBM's Global Security Kit v7 installed. You'll find
it enclosed with MQv6 and MQv6 fixpacks.

 You need to install the following rpms:
 * gsk7bas
 * MQSeriesKeyMan


=head1 HOWTO

This is a frontend to gsk7cmd which is a frontend to the java based iKeycmd.
mq-ca.pl will document every stage and show you all needed gsk7cmd commands

First we create the CA which we will use to sign all the certificates:
 mq-ca.pl -op=ca -qm=swolinux -pw=mypassword -exp=365 \
  -label "Experian Decision Analytics Secana CA" -cadir='./ca'

You will get a ./CA directory with the CA key-repository. keep this safe.

Create the queue-manager certificate and signs it with the above CA
 mq-ca.pl -op=qm -qm=swolinux -pw=mypassword -exp=365 \
  -label "Swolinux certificate" -cadir='./ca'

We now get a qmcert-swolinux directory which holds the swolinux self signed
keyrepository. This can be placed anywhere but must be readable by the queuemanager
process. this is the qmgr SSLKEYR parameter which points here.


Create the client certificate, sign it with the above CA
 mq-ca.pl -op=client -qm=mbj -pw=mypassword -exp=365 \
  -label "mbj client certificate" -cadir='./ca'

Here MQclient.pl on client will run as user mbj, ensure mbj is a user on both client
and server and a member of mqm on both client and server

Then copy the ./clientcert-mbj/mbj.* files to the client under ex: /tmp/mqssl/
This is then refered to as --sslkey=/tmp/mqssl/mbj when using MQclient.pl

=head2 CHANGES ON QUEUEMANAGER (SERVER)

 #change keyrepository of queuemanager:
 echo "alter qmgr SSLKEYR('/dist/mq/mqscripts/qmcert-swolinux/swolinux')" | runmqsc swolinux
 echo "refresh sequrity type(SSL)" | runmqsc swolinux

 #change sslauth to required for client channel 'secana.ssl':
 echo "alter channel('secana.ssl') chltype(svrconn) sslcauth(required)" | runmqsc swolinux
 echo "refresh security" | runmqsc swolinux

 # view changes:
 echo "dis qmgr all" | runmqsc swolinux
 echo "dis chl('secana.ssl') all" | runmqsc swolinux
 
=head2 CHANGES ON CLIENT

On client you only have to refere the --sslkey parameter in the MQclient.pl call


=head1 DEBUG
 
 List certificates in a key-database:
 gsk7cmd -cert -list all -db key.kdb -pw *****

 To add debug features:
 gsk7cmd -Dkeyman.debug=true -Dkeyman.jnitracing=YES ....

 Then check log files:
 ikmcdbg.log, ikmgdbg.log, ikmjdbg.log
 
 You can also try and recreate the problem using the gui-tool gsk7ikm
 with full debug:
 gsk7ikm -Dkeyman.debug=true -Dkeyman.jinitracing=ON \
  -Djava.security.debug=ALL 2>ikeyman.txt

Also since gsk7 seems to be so buggy, please update to latest version:
As of Jan2008 it is 'Websphere MQ v6 linux x86 fixpack 6.0.2.3'
a 359MB! large download. You need a ibm partnerworld login to get it.

 See more about debugging:
 http://www.ibm.com/support/docview.wss?uid=swg27006684
 http://www.ibm.com/support/docview.wss?uid=swg21202820

All certificates you create must have a unique dn, change the CN to make it unique.

=head1 A COMPLETE RUN

This run is just icluded as a reference to gsk7cmd which can be quite confusing

 #create CA:
 $ ./mq-ca.pl -op=ca -cadir='./ca' -pw mypassword123
 #Set environment variable:
 export JAVA_HOME=/opt/mqm/ssl/jre
 #Create directory './ca'
 /bin/mkdir -p ./ca
 #ok 0.00 sec
 #Create CA key repository './ca/myCA.kdb'
 /bin/gsk7cmd -keydb -create -db './ca/myCA.kdb' -pw mypassword123 -type cms -expire 366
 #ok 4.14 sec
 #Create a self signed CA certificate in './ca/myCA.kdb'
 /bin/gsk7cmd -cert -create -db './ca/myCA.kdb' -type cms -pw mypassword123 -label 'Experian Secana Public CA' -dn 'CN=Experian Secana CA,O=Experian,OU=Decision Analytics,L=Oslo,C=NO' -expire 366 -size 1024
 #ok 4.25 sec
 #Extract CA public certificate './ca/myCA.cer'
 /bin/gsk7cmd -cert -extract -db './ca/myCA.kdb' -pw mypassword123 -label 'Experian Secana Public CA' -target './ca/myCApublic.cer'
 #ok 4.19 sec

 $ ls -l /dist/mq/mq-scripts/ca
 -rw-r--r--  1 secana secana     80 Mar  5 13:34 myCA.crl
 -rw-r--r--  1 secana secana 120080 Mar  5 13:34 myCA.kdb
 -rw-r--r--  1 secana secana    868 Mar  5 13:34 myCApublic.cer
 -rw-r--r--  1 secana secana     80 Mar  5 13:34 myCA.rdb
 (it is important the user we use mq-ca.pl as has write access to the keyrepository)

 $ export JAVA_HOME=/opt/mqm/ssl/jre
 $ gsk7cmd -cert -list personal -db 'ca/myCA.kdb' -pw mypassword123
 Certificates in database: ./ca/myCA.kdb
   Experian Secana Public CA

create queuemanager certificate and sign it with the previously created CA:

 $ ./mq-ca.pl --op=qm -qm=swolinux --cadir='./ca' -pw mypassword123
 #Set environment variable:
 export JAVA_HOME=/opt/mqm/ssl/jre
 #Create queue-manager directory 'qmcert-swolinux'
 /bin/mkdir -p qmcert-swolinux
 #ok 0.00 sec
 #Creating qm-key repository 'qmcert-swolinux/swolinux.kdb'
 /bin/gsk7cmd -keydb -create -db 'qmcert-swolinux/swolinux.kdb' -pw mypassword123 -type cms -expire 365 -stash
 #ok 4.13 sec
 #Add the CA cert './ca/myCAcertfile.cer' to qm-key repository
 /bin/gsk7cmd -cert -add -db 'qmcert-swolinux/swolinux.kdb' -pw mypassword123 -label 'Experian Secana Public CA' -file './ca/myCApublic.cer' -format ascii -trust enable
 #ok 4.06 sec
 #Creating certificate request 'qmcert-swolinux/swolinux.req' in key database 'qmcert-swolinux/swolinux.kdb'
 /bin/gsk7cmd -certreq -create -db 'qmcert-swolinux/swolinux.kdb' -pw mypassword123 -label 'ibmwebspheremqswolinux' -dn 'CN=swolinux - queuemanager,O=Experian,OU=Decision Analytics,L=Oslo,C=NO' -file 'qmcert-swolinux/swolinux.req'
 #ok 5.63 sec
 #CA signs 'qmcert-swolinux/swolinux.req' certificate request
 /bin/gsk7cmd -cert -sign -db './ca/myCA.kdb' -pw mypassword123 -label 'Experian Secana Public CA' -file 'qmcert-swolinux/swolinux.req' -target 'qmcert-swolinux/swolinux.cer' -expire 365
 #ok 2.33 sec
 #Receive signed certificate 'qmcert-swolinux/swolinux.cer' into qm-key repository
 /bin/gsk7cmd -cert -receive -db 'qmcert-swolinux/swolinux.kdb' -pw mypassword123 -file 'qmcert-swolinux/swolinux.cer'
 #ok 4.64 sec
 #Cleaning up temporary files
 /bin/rm qmcert-swolinux/swolinux.cer
 #ok 0.00 sec
 /bin/rm qmcert-swolinux/swolinux.req
 #ok 0.00 sec 

For queuemanager then point MQclient.pl --sslkey=/dist/mq/mq-scripts/qmcert-swolinux/swolinux or
copy the directory anywhere else more convenient like /var/mqm/ssl which is the default SSLKEYR.

 $ ls -l /dist/mq/mq-scripts/qmcert-swolinux
 -rw-r--r--  1 secana secana     80 Mar  5 13:34 swolinux.crl
 -rw-r--r--  1 secana secana 125080 Mar  5 13:34 swolinux.kdb
 -rw-r--r--  1 secana secana     80 Mar  5 13:34 swolinux.rdb
 -rw-r--r--  1 secana secana    129 Mar  5 13:34 swolinux.sth

Create a client certificate for the user mbj and sign it with the previosuly generated CA:

 $ ./mq-ca.pl --op=client -username=mbj --cadir='./ca' -pw mypassword123
 #Set environment variable:
 export JAVA_HOME=/opt/mqm/ssl/jre
 #Create queue-manager directory 'clientcert-mbj'
 /bin/mkdir -p clientcert-mbj
 #ok 0.00 sec
 #Creating qm-key repository 'clientcert-mbj/key.kdb'
 /bin/gsk7cmd -keydb -create -db 'clientcert-mbj/mbj.kdb' -pw mypassword123 -type cms -expire 365 -stash
 #ok 3.99 sec
 #Add the CA cert './ca/myCAcertfile.cer' to qm-key repository
 /bin/gsk7cmd -cert -add -db 'clientcert-mbj/mbj.kdb' -pw mypassword123 -label 'Experian Secana Public CA' -file './ca/myCApublic.cer' -format ascii -trust enable
 #ok 3.89 sec
 #Creating certificate request 'clientcert-mbj/mbj.req' in key database 'clientcert-mbj/mbj.kdb'
 /bin/gsk7cmd -certreq -create -db 'clientcert-mbj/mbj.kdb' -pw mypassword123 -label 'ibmwebspheremqmbj' -dn 'CN=swolinux - client,O=Experian,OU=Decision Analytics,L=Oslo,C=NO' -file 'clientcert-mbj/mbj.req'
 #ok 5.38 sec
 #CA signs 'clientcert-mbj/mbj.req' certificate request
 /bin/gsk7cmd -cert -sign -db './ca/myCA.kdb' -pw mypassword123 -label 'Experian Secana Public CA' -file 'clientcert-mbj/mbj.req' -target 'clientcert-mbj/mbj.cer' -expire 365
 #ok 2.33 sec
 #Receive signed certificate 'clientcert-mbj/mbj.cer' into mbj-key repository
 /bin/gsk7cmd -cert -receive -db 'clientcert-mbj/mbj.kdb' -pw mypassword123 -file 'clientcert-mbj/mbj.cer'
 #ok 4.47 sec
 
 ls -l /dist/mq/mq-scripts/clientcert-mbj/
 -rw-r--r--  1 secana secana     80 Mar  5 13:38 mbj.crl
 -rw-r--r--  1 secana secana 125080 Mar  5 13:38 mbj.kdb
 -rw-r--r--  1 secana secana     80 Mar  5 13:38 mbj.rdb
 -rw-r--r--  1 secana secana    129 Mar  5 13:37 mbj.sth

Copy the above directory to the client (aka /tmp/mqssl) and use --sslkey=/tmp/mqssl for MQclient.pl
This certificate is userdependable, which means it can be used on any client as long as the
user is mbj connecting to the same queuemanager.


=head1 AUTHOR

Morten Bjoernsvik - morten.bjornsvik@experian-scorex.no - 2008


