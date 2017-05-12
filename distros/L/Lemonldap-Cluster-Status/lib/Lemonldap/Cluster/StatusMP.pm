package Lemonldap::Cluster::StatusMP;
#Copyright (C) 2005 by Eric German, <germanlinux@yahoo.fr>
# FILE  StatusMP.pm
#    Lemonldap originaly written by Eric German who decided to publish him in
#    2003 under the terms of the GNU General Public License version 2.
########


use Lemonldap::Cluster::Status;
use Apache::Constants qw (:common) ;

sub handler {
my $r = shift;
  my $p;
my %param;
$p=$r->args if $r->args ;
if ($p) { 
my @parax = split "&" , $p ;
my @pr;
foreach (@parax)  {
 (my $cle,my $val) = split "=" , $_;
 push @pr ,$cle;
 push @pr, $val;
     }
 %param = @pr ;

}
my $conf =$r->dir_config ;
my %machine= %{$conf} ;
my $re = Lemonldap::Cluster::Status->new ( %machine);
$re->analyze;
my $a=$re->PrintHtml;
if ($param{refresh}) {
my $t =$param{refresh};
$r->header_out('refresh',$t);

} 
$r->content_type('text/html');
$r->send_http_header;
$r->print($a);
return OK;

}
1;


