package Metadata::DB::CLI;
use strict;
use Exporter;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS);
use LEOCHARRE::DEBUG;
use LEOCHARRE::DBI;
use base 'LEOCHARRE::CLI';
use YAML;

@ISA = qw/Exporter/;
@EXPORT_OK = qw(cli_get_dbh cli_log cli_find_all_files cli_consolidate_params);
%EXPORT_TAGS = ( all=> \@EXPORT_OK );

sub cli_consolidate_params {
   my $o = shift;
   ref $o eq 'HASH' or die('must pass opts hashref');

   if($o->{c}){
      my $conf = YAML::LoadFile($o->{c});


      $o->{a} ||= $conf->{DBABSPATH} ;
      $o->{D} ||= $conf->{DBNAME}    ;
      $o->{U} ||= $conf->{DBUSER}    ;
      $o->{P} ||= $conf->{DBPASSWORD};
      $o->{H} ||= $conf->{DBHOST}    ;
      $o->{n} ||= $conf->{ABSCONVENTION};
      $o->{R} ||= $conf->{DOCUMENT_ROOT};

      $o->{f} ||= $conf->{ABSSEARCHFORM};

      $ENV{HTML_TEMPLATE_ROOT} ||= $conf->{HTML_TEMPLATE_ROOT};
      $ENV{HTML_TEMPLATE_ROOT} ||= '/var/www/cgi-bin';


      unless( $o->{f} ){
         if ( $conf->{mdw_search_tmpl_name} ){
            $o->{f} = $ENV{HTML_TEMPLATE_ROOT} .'/'.$conf->{mdw_search_tmpl_name};
         }
      } 
      for my $param ( qw(mdw_search_tmpl_name mdw_search_results_tmpl_name) ){
         my $val = $conf->{$param};
         if ( defined $val ){
            $o->{$param} = $val;
         }
      }
   }
   else {
      debug('no conf');
   }

   unless($o->{R}){
      $o->{R} = $ENV{HOME};  
   }


   return $o;
}



sub cli_get_dbh{
   my $o = shift;

   my $dbh;


   if ($o->{a}){
      $dbh = DBI::connect_sqlite($o->{a}) or die("cant sqlite connect to $$o{a}");
      debug("got sqlite $$o{a} connect");
   }
   else {
      for my $p (qw(D U P)){
         $o->{$p} or die("missing -$p");
      }
      $dbh = DBI::connect_mysql($o->{D},$o->{U},$o->{P},$o->{H}) or die('cant connect to db');
      debug("got mysql connect $$o{D}");
   }
   debug('got dbh');
   return $dbh;
}

sub cli_find_all_files {
   my ($abs,$limit) = @_;
   -d $abs or die("not dir: $abs");

   my @files = grep { !/\/\./ } File::Find::Rule->in( $abs );
   debug("count is $#files");

   if( $limit and ( $limit < $#files ) ){
      debug("will prune to $limit");
      $#files = ( $limit - 1 );
   }

   return \@files;
}


sub cli_log {
   my $msg = shift;

   my $logname = $0;
   $logname=~s/.+\///;

   my $abs_loc;

   if ( `whoami` =~/root/ ){
      $abs_loc = '/var/log';
   }
   else {
      $abs_loc = "$ENV{HOME}";
   }
   my $abs_log = $abs_loc."/$logname.log";


   open(LOG,'>>',$abs_log) or die("cant open $abs_log for appending, $!");

   require Time::Format;
   my $msg_ = sprintf "%s %s %s\n", $0, $msg, Time::Format::time_format('yyyy-mm-dd hh:mm', time);
   print LOG $msg_;
   close LOG;
   return $msg_;
}









1;



__END__


=pod




=head2 cli_get_dbh()


argument is hashref
can be the gopts() return, or a conf hashref

you can specify database connection by 
 
   -a abs path to sqlite | DBABSPATH

or mysql..
   
   -U username | DBUSER
   -P password | DBPASSWORD
   -D database name | DBNAME
   -H host, ni* | DBHOST
   -E metadata table name, ni*

ni* not implemented





=head2 cli_find_all_files()

does not return hidden files or hidden dirs
returns dirs and files

arg is abs path, optional arg is number limit to return
returns array ref

=head2 cli_log()

argument is message
places time into message

the abs path to log is to /var/log/$PROGRAMNAME.log
$PROGRAMNAME is $0 modified

returns message as was logged 

   debug( cli_log('started') );




