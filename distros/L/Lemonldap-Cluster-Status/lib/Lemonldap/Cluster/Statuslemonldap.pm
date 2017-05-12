package Lemonldap::Cluster::Statuslemonldap;
#Copyright (C) 2005 by Eric German, <germanlinux@yahoo.fr>
# FILE  Statuslemonlda.pm
#    Lemonldap originaly written by Eric German who decided to publish him in
#    2003 under the terms of the GNU General Public License version 2.
########

use Lemonldap::Cluster::Status;
use Lemonldap::Config::Parameters;

use Apache::Constants qw (:common) ;
sub handler {
my $CONF;
my $FILE;
my $GLUE;

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
$FILE = $r->dir_config('LemonldapConfig');
$GLUE = $r->dir_config('LemonldapConfigIpcKey');
$GLUE = $r->dir_config('LemonldapConfigdbpath') unless $GLUE;
$CONF= Lemonldap::Config::Parameters->new (
                                                file => $FILE ,
                                              cache => $GLUE );
my $config=$CONF->getAllConfig();
########
# test the present of one parameter cluster
###
my $cluster = $param{'cluster'};
my $clu =$config->{cluster} ;
unless ($cluster)  {
#I don't find cluster i' ll take the first 
#
my @t =keys %$clu;
$cluster= $t[0]; 
}
my $cl =$config->{cluster}->{$cluster};
return OK unless $cl;
my %machine;

$machine{ADMIN} =$cluster;
my $cc = $cl->{node};
foreach (keys %$cc) {
$machine{$_} = $cc->{$_}{address};
}

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


