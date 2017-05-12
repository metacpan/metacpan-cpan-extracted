package Lemonldap::Cluster::Status;

use strict;
use warnings;
use LWP::UserAgent;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lemonldap::Cluster::Status ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.
sub new {
    my $that =shift;
    my $class = ref($that)|| $that ;

     my $self ={}; 
	bless ($self,$class);
  %$self= @_;
#### init nb node ####
	my $cp;
	my @nodes;
	foreach (keys %$self ) {
	    next if /^ADMIN/i ;
		$cp++ ;
          push @nodes,$_;
	  
    }

	$self->{NODES} = $cp;
	$self->{anode} =\@nodes;
#####
#### init time  ###
$self->{TIME} = localtime();

#####
    $self->{VERSION}= $VERSION;
#### load nodes infos
####
my %result;
my @NOEUD = @{$self->{anode} };
foreach (@NOEUD) {
	##  
my $retour = collect($self->{$_});
$result{$_} = $retour;


}
$self->{RESULT} = \%result;


return $self;

}
sub PrintHtml {
    my $self =shift;
###  formate unit ####
    my $t= $self->{TMB} ;
my  $unite='MB' ;   
  if ($t  > 1023 ) {
	$unite = 'GB';
    $t= $t / 1024 ;
 } 
$t = sprintf("%.2f",$t);
    my $tr =$self->{TREQUEST};
    my $ta = $self->{ACCESSES} ;
#    $ta=~ s/(\d{3})$/\.$1/;
# $ta=~ s/^(\d+)(\d{3})/$1\.$2/;

my $message= <<DEBUT;


<html>
<HEAD>
<TITLE>Cluster Apache Status</TITLE>
</HEAD>
<BODY>
<H1>Cluster Apache Status for $self->{ADMIN} Group</H1>
Lemonldap::Cluster::Status version: $self->{VERSION}<br>
<hr>
Current Time: $self->{TIME}<br>
Number of Nodes: $self->{TNODES} : Status : $self->{STATUS}<br>
Total accesses: $ta - Total Traffic: $t $unite<br>
CPU Usage: min: $self->{MIN}% max: $self->{MAX}% ave : $self->{MOY}% CPU load<br>
$tr requests currently being processed, $self->{IDLE} idle servers<br>

<p>


<table border=0>
<tr><th>Server<th>Address<th>Req<th>Idle<th>CPU<th>Accesses<th>Traffic</tr>


DEBUT


#suite 
my $sum = $self->{SUMMARY} ;
my %hs= %$sum;

my $ligne;
    foreach (keys %hs ) {

            my $pu =$hs{$_}{cpu};
        $pu= sprintf("%.3f",$pu);

            my $tr = $hs{$_}{traffic};

if ($tr > 1023)  {
        $tr= $tr/ 1024 ;
        $tr= sprintf("%.2fGB",$tr);
  }  else {
          $tr.="MB";
  }
        $ligne .= "<td>$_<td>$self->{$_}<td>$hs{$_}{request}<td>";
$ligne.="$hs{$_}{idle}<td align=right>$pu%<td align=right>$hs{$_}{accesses}<td align=right>$tr</tr>\n";
    }

$message.=$ligne;


         $message.=<<tIN;
</table>
<hr>
tIN

if   ( $self->{STATUS} ne "NORMAL" ) {
$message.=<<sy;

SERVER NO AVAILABLE<p>
sy

my $hu= $self->{RESULT} ;
my $li;
foreach (keys %$hu )  {
if ($hu->{$_} =~ /^UN/) {
 $li.="$_ $self->{$_}<br>";
}
}
$message.=$li;
}

$message.=<<FIN;



</BODY>
</HTML>
FIN


return $message;
1; 




}
sub collect {
    my $node =shift;
    my $browser =LWP::UserAgent->new();
   my  $url= "http://$node/server-status";
   my $response = $browser->get($url);
   return "UNAVAILABLE"  unless $response->is_success();
   my $content = $response->content();
   return $content ;
 

	

}
sub analyze {
    my $self = shift;
   my $host =$self->{RESULT} ;
    my %res;
  my $ta;  
    $self->{MIN} = 999;
    $self->{MAX} =0;
##########

    my $cp;
    my $tres;
    my $tchiffre;
    my $ti;
    my $tcpu;
  foreach (keys %$host) {
      next if $host->{$_} =~ /^UNA/ ;
  $cp++; 
### request ####
   (my $resquest )= ($host->{$_}=~ /(\d+) requests curr/) ;    
		    $res{$_}{request}= $resquest-1; # -1 : request for server-status
      $tres +=$resquest-1;
### traffic ###
   (my $chiffre,my $unite) = ($host->{$_}=~ /Total Traffic: (.+?) (MB|GB|kB|B)/); 
if ($unite eq 'GB') { $chiffre = $chiffre * 1024    }
if ($unite eq 'B') { $chiffre =0  }
if ($unite eq 'kB') { $chiffre=$chiffre / 1024  }
      $chiffre =sprintf ("%.2f",$chiffre);
      $tchiffre += $chiffre;
      $res{$_}{traffic}  = $chiffre;
### accesses ###
 (my $accesses) =  ($host->{$_}=~ /Total accesses: (\d+)/) ;
 $res{$_}{accesses} = $accesses ; 
      $ta  += $accesses;
### idle ###
 (my $idle) =  ($host->{$_}=~ /(\d+) idle servers/) ;
 $res{$_}{idle} = $idle +1 ; 
      $ti  += $idle +1 ;
### CPU ###
(my $cpu) = ($host->{$_} =~ /Usage.+-(.+)% CPU load/); 
$tcpu+= $cpu;
$res{$_}{cpu} =$cpu; 
$self->{MIN} = $cpu if $cpu < $self->{MIN};
$self->{MAX} = $cpu if $cpu > $self->{MAX};



}   
 
     $self->{SUMMARY} = \%res;
#### totalization ###
    $self->{STATUS} ="NORMAL";
    if ($self->{NODES} != $cp) {
	$self->{STATUS}  = 'WARNING'; }
    $self->{ACCESSES} = $ta ;     
    $self->{TNODES} = "$cp/$self->{NODES}";
    $self->{TREQUEST} = $tres;
    $self->{TMB} = $tchiffre;
    $self->{IDLE} = $ti;
$self->{CPU} = $tcpu;
$self->{MOY}=0;
$self->{MOY} = $self->{CPU} / $cp if $cp ;
$self->{MOY} = sprintf ("%.3f",$self->{MOY});
$self->{MIN} = sprintf ("%.3f",$self->{MIN});
$self->{MAX} = sprintf ("%.3f",$self->{MAX});
     return 1;

}







1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lemonldap::Cluster::Status - Perl extension for apache cluster server-status

=head1 SYNOPSIS

    use Lemonldap::Cluster::Status ;
    my $serverstatus = Lemonldap::Cluster::Status->new (
                  'ADMIN' => 'title on top of page' ,
                  'node1' => '10.ip.ip.ip',
                  'node2' => 'server1.net',
                  'foo' => 'server2.net',
                  'bar' => '10.ip.ip.ip',
		);
   $serverstatus->analyze;
   my $a=$serverstatus->PrintHtml;



=head1 DESCRIPTION

This module aggregates sereval  server-status pages (from apache)  in one page.

It's usefull in order to manage cluster, or for working with nagios and cacti

This version understands refresh=nb_of_second parameters like mod_status

Your servers (nodes) MUST TO BE turn on extended status mode (see apache doc)  

This module may be used in sereval ways :

 1) Like a package (see bellow) 
 2) Embeded in CGI script :(see StatusCGI.pl)
 3) With modperl : (see StatusMP.pm) 
 4) Like lemonldap websso composant :(see Statuslemonldap.pm)

 ONLY last way NEEDS another Lemonldap composant . Thus this module is independent of lemonldap websso. 
 
The server-status report seems to be issu of real apache server.

 The apache server wich implements server-status summary  doesn't need to be a nodes .

=head1 METHODS

=over 1

=item new ('ADMIN' => 'name' ,
     'foo' =>   'bar.fr' );


The word  ADMIN is REQUIRED .
This method does the GET http://bar.fr/server-status
(This for every nodes).


=item analize () ;

Does the calculation and summarizes stat.

=item printHtml() 

return the whole html page .
  

=back 

=head1 StatusCGI.pl

first, puts a copy of StatusCGI.pl in your apache  cgi-bin directory .
next, you MUST modify the script in order to add your address servers.
last, try with the url http://myserver.net/cgi-bin/StatusCGI.pl.
 
(you can addd  '?refresh=5' (in second) at the end of URL ) 

=head1 StatusPM.pm  (under mod_perl)

Just add those lines in httpd.conf

 <Location /clusterstatus >
    SetHandler perl-script
    PerlHandler Lemonldap::Cluster::StatusMP
    perlsetvar ADMIN name_of_group
    perlsetvar node1 10.ip.ip.ip
    perlsetvar foo   server1.net
    perlsetvar bar   sever2.net
 </Location>

Restart httpd daemon and point on location /clusterstatus

=head1 Statuslemonldap.pm  (with lemonldap::Config::Parameters)

 Add this in lemonldap_config.xml 

  <cluster  id ="ADMIN" >
        <node id="node"
              address="10.ip.ip.ip" />
        <node id="other"
              address="10.ip.ip.ip" />
        <node id="last"
              address="server.net" />
  </cluster>

 Add also this in httpd.conf 

 <Location /statuslemon >
  SetHandler perl-script
  PerlHandler Lemonldap::Cluster::Statuslemonldap
  perlsetvar LemonldapConfig /etc/apache-perl/lemonldap_config.xml
  perlsetvar LemonldapConfigipckey /var/cache/lemondb/CONF
 </Location>

Restart httpd daemon and point on location /statuslemon


=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install



=head1 EXPORT

None by default.



=head1 SEE ALSO

 Lemonldap websso
 server-status of apache
 LWP

 Lemonldap::Cluster::StatusMP  (under mod_perl)
 Lemonldap::Cluster::StatusCGI (under CGI) 
 Lemonldap::Cluster::Statuslemonldap (embeded in lemonldap config) 
 (all files are in tarball ) 


=head1 AUTHOR

Eric German, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Eric German, E<lt>germanlinux@yahoo.frE<gt>

    Lemonldap originaly written by Eric German who decided to publish him in
    2003 under the terms of the GNU General Public License version 2.

    This package is under the GNU General Public License, Version 2.
    The primary copyright holder is Eric German.
    Portions are copyrighted under the same license as Perl itself.
    Portions are copyrighted by Doug MacEachern and Lincoln Stein. This
    library is under the GNU General Public License, Version 2.
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; version 2 dated June, 1991.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    A copy of the GNU General Public License is available in the source tree;
    if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.






=cut
