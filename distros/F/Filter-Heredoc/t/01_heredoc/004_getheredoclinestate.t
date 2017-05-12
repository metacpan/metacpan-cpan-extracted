#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 146;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );

# This is just a long 146 lines bash script (part of moinmoin setup)

while (<DATA>) {
    
    next if /^\s+/ ; # prevents trailing empty __DATA__ cause split's undefs
    ( $state , $line ) = split /]/ ;
    %state = hd_getstate( $line );
    is( $state{statemarker}, $state, 'hd_getstate()');
    
}


__DATA__
S]#!/bin/bash
S]# /root/bin/10apache2-init-default
S]# - If not done, backup 'default' original
S]# - Create the new default (catch all virtual hosts)
S]# - Copy htdocs files for that domain to /var/www...
S]#   and from the moinrc directory (index, ico to /var/www)
S]# - Enable the default site in apache2
S]# - Consider? ports.conf if apache2
S]#   complains about no virtual host?
S]# - Test apache2 configuraton syntax
S]# - Restart apache2
S]###################################
S]# Definitions
S]###################################
S]PROGNAME=$(basename $0)
S]DEFAULTSITE="_default_"
S]defaultfile="default"
S]defaultpath="/etc/apache2/sites-available/default"
S]backupdefname="/etc/apache2/sites-available/default.original"
S]portspath="/etc/apache2/ports.conf"
S]portsconfigbackupname="/etc/apache2/ports.conf.original"
S]###################################
S]
S]###################################
S]# Ask user if we should continue 
S]###################################
S]
S]echo  "This will set up a default site for apache2 [Y/N] ?"
S]read continue
S]if [ "$continue" = "Y" ] || [ "$continue" = "y" ] ; then
S]     echo "OK we will copy a new \"$defaultfile\" file to use."
S]else
S]     echo "User aborted installation!"    
S]     exit 1   
S]fi
S]
S]###################################
S]# If not a backup of the original
S]# ports.conf file exist make copy now 
S]###################################
S]
S]if [ ! -e "$portsconfigbackupname" ] ; then
S]   cp $portspath $portsconfigbackupname 
S]fi
S]
S]###################################
S]# Use 'here' document to make a  
S]# new ports.conf that works  
S]###################################
S]
S](
I]cat <<EOF
H]NameVirtualHost *:80
H]Listen 80
E]EOF
S]) > $portspath
S]
S]###################################
S]# If not a backup of the original
S]# default file exist make copy now 
S]###################################
S]
S]if [ ! -e "$backupdefname" ] ; then
S]   cp $defaultpath $backupdefname 
S]fi
S]
S]###################################
S]#  Use template 'here' document and 
S]# and create a catch all virtual site. 
S]###################################
S]site=${DEFAULTSITE}":*"
S]
S](
I]cat <<EOF
H]<VirtualHost $site>
H]        ServerAdmin root@localhost
H]        DocumentRoot   /var/www
H]
H]        # Allways block file system root access
H]
H]        <Directory />
H]             AllowOverride None
H]             Options None
H]             Order Deny,allow
H]             Deny from all
H]        </Directory>
H]
H]        # This allow moin access required files  
H]
H]        <Directory /usr/share/moin/server>
H]             AllowOverride None
H]             Options None
H]             Order Allow,Deny
H]             Allow from all
H]        </Directory>
H]
H]        # This sets access to only /var/www and below
H]
H]        <Directory /var/www>
H]             AllowOverride None
H]             Order Allow,Deny
H]             Allow from all
H]        </Directory>
H]
H]        ErrorLog /var/log/apache2/error.log
H]
H]        # Possible values include: debug, info, notice, warn, error, crit,
H]        # alert, emerg.
H]        LogLevel debug
H]
H]        CustomLog /var/log/apache2/access.log combined
H]
H]</VirtualHost>
E]EOF
S]) > $defaultfile
S]
S]echo "Copying virtual site \"$defaultfile\" to \"/etc/apache2/sites-avilable/$defaultfile\" "
S]mv $defaultfile "/etc/apache2/sites-available/default"
S]
S]ls -la /etc/apache2/sites-available
S]ls -la /etc/apache2
S]
S]###################################
S]#  Enable the default domain 
S]###################################
S]a2ensite $defaultfile
S]
S]###################################
S]#  Copy default index.html and ico file
S]###################################
S]cp moinrc/default.index.html  /var/www/index.html
S]cp moinrc/default.favicon.ico  /var/www/favicon.ico
S]
S]ls -la /var/www
S]
S]###################################
S]#  Final apache2 syntax check and
S]#  restart web server
S]###################################
S]
S]apache2ctl -t
S]/etc/init.d/apache2 restart
S]netstat -tulpn | grep LISTEN
S]
S]###################################
S]# eof #

