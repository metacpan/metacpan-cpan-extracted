#!/usr/bin/perl 
use Lemonldap::Cluster::Status;
use Apache::Constants qw (:common) ;
use CGI  qw(:all) ;
#Copyright (C) 2005 by Eric German, <germanlinux@yahoo.fr>
# FILE  StatusCGI.pl
#    Lemonldap originaly written by Eric German who decided to publish him in
#    2003 under the terms of the GNU General Public License version 2.
########
  

my $p;
$p=param('refresh') ;

# YOU MUST MODIFYING THOSE LINES 
# PUT YOUR NODES
my $re = Lemonldap::Cluster::Status->new (
                  'ADMIN' => 'title on top of page' ,
                  'node1' => '10.ip.ip.ip',
                  'node2' => 'server1.net',
                  'foo' => 'server2.net',
                  'bar' => '10.ip.ip.ip',
					  );

##############################################
$re->analyze;
my $a=$re->PrintHtml;
if ($p) {
print header(-type =>'text/html' ,
             -refresh=>$p );}  else 
{ 
print header(-type =>'text/html'); 
}
print $a;
exit;



