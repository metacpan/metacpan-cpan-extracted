#!/usr/local/bin/perl -w
BEGIN{
    unshift(@INC, "/usr/local/bioperl/bioperl-1.5.2_102");
}

use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use CGI::Fast qw(:standard);

use strict;
use Getopt::Long;
use Data::Dumper;
use Switch;
use Time::HiRes qw(time gettimeofday tv_interval);
use POSIX qw(ceil floor);

use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use File::Temp;

use MQdb::Database;
use MQdb::MappedQuery;
use EEDB::Feature;
use EEDB::Edge;

my $connection_count = 0;
my $total_edge_count = 0;

my $eeDB = undef;
my $eeDB_url = undef;

my $start_date = localtime();
my $launch_time = time();

while (my $fcgi_session = new CGI::Fast) {
  process_url_request($fcgi_session);
  $connection_count++;
}

##########################

sub process_url_request {
  my $fcgi_session = shift;

  $total_edge_count = 0;

  my $self = {};
  $self->{'window_width'} = 640;
  $self->{'mode'} = 'region';
  $self->{'submode'} = 'area';

  $self->{'fcgi_session'} = $fcgi_session;
  $self->{'assembly_name'} = $fcgi_session->param('asm');
  $self->{'mode'} = $fcgi_session->param('mode');
  $self->{'format'} = $fcgi_session->param('format');

  $self->{'window_width'} = $fcgi_session->param('width') if(defined($fcgi_session->param('width'))); 
  $self->{'span'} = $fcgi_session->param('span') if(defined($fcgi_session->param('span'))); 
  $self->{'submode'} = $fcgi_session->param('submode') if(defined($fcgi_session->param('submode'))); 

  $self->{'loc'} = $fcgi_session->param('loc');
  $self->{'loc'} = $fcgi_session->param('segment') if(defined($fcgi_session->param('segment'))); 
  $self->{'chrom_name'} = $fcgi_session->param('chrom') if(defined($fcgi_session->param('chrom')));

  $self->{'fsrc_filters'} = $fcgi_session->param('fsrc_filters') if(defined($fcgi_session->param('fsrc_filters')));
  $self->{'fsrc_filters'} = $fcgi_session->param('types') if(defined($fcgi_session->param('types'))); 

  ##### 
  # now process
  #

  #first init
  if(!defined($eeDB)) { init_db($self); } 

  # now the location processing
  if(defined($self->{'loc'}) and ($self->{'loc'} =~ /(.*)\:(.*)\.\.(.*)/)) {
    $self->{'chrom_name'} = $1;
    $self->{'start'} = $2;
    $self->{'end'} = $3;
  }

  $self->{'mode'} ='region' unless(defined($self->{'mode'}));
  $self->{'savefile'} ='' unless(defined($self->{'savefile'}));
  $self->{'format'}='bed' unless(defined($self->{'format'}));
  $self->{'assembly_name'}='hg18' unless(defined($self->{'assembly_name'}));

  $self->{'window_width'} = 640 unless(defined($self->{'window_width'}));
  $self->{'window_width'} = 200 if($self->{'window_width'} < 200);

  if($self->{'fsrc_filters'}) {
    my @names = split /,/, $self->{'fsrc_filters'};
    foreach my $fsrc (@names) {
      $self->{'sourcename_hash'}->{$fsrc}=1;
      my $fsource = EEDB::FeatureSource->fetch_by_name($eeDB, $fsrc);
      if($fsource) { $self->{'sourcename_hash'}->{$fsrc} = $fsource; }
    }
  }

  if(defined($self->{'chrom_name'})) {
    if($self->{'mode'} eq 'region') {
      return fetch_named_region($self); 
    } 
  }

  show_fcgi($self, $fcgi_session);
  #printf("ERROR : URL improperly formed\n");
}


sub show_fcgi {
  my $self = shift;
  my $fcgi_session = shift;

  my $id = $fcgi_session->param("id"); 

  my $uptime = time()-$launch_time;
  my $uphours = floor($uptime / 3600);
  my $upmins = ($uptime - ($uphours*3600)) / 60.0;

  print header;
  print start_html("EdgeExpressDB CGI object server");
  print h1("CGI object server (perl)");
  print p("eedb_region.cgi version 1.01<br>\n");
  printf("<p>server launched on: %s Tokyo time\n", $start_date);
  printf("<br>uptime %d hours % 1.3f mins ", $uphours, $upmins);
  print "<br>Invocation number ",b($connection_count);
  print " PID ",b($$);
  my $hostname = `hostname`;
  printf("<br>host : %s\n",$hostname);
  printf("<br>dburl : %s\n",$eeDB->url);
  printf("<br>default assembly : %s\n", $self->{"assembly_name"});
  print hr;

  #if(defined($id)) { printf("<h2>id = %d</h2>\n", $id); }
  print("<table border=1 cellpadding=10><tr>");
  printf("<td>%d features in cache</td>", EEDB::Feature->get_cache_size);
  printf("<td>%d edges in cache</td>", EEDB::Edge->get_cache_size);
  print("</tr></table>");
  
  show_api($fcgi_session);
  print end_html;
}

sub show_api {
  my $fcgi_session = shift;
  
  print hr;
  print h2("Access interface methods");
  print("<table cellpadding =3 width=100%>\n");
  print("<tr><td width=20% style=\"border-bottom-color:#990000;border-bottom-width:2px;border-bottom-style:solid;font-weight:bold;\">cgi parameter</td>\n");
  print("<td style=\"border-bottom-color:#990000;border-bottom-width:2px;border-bottom-style:solid;font-weight:bold;\">description</td></tr>\n");
  print("<tr><td>loc=[location]</td><td>does genome location search and returns all features overlapping region. default output mode=region_gff<br>loc is format: chr17:75427837..75427870</td></tr>\n");
  print("<tr><td>segment=[location]</td><td>same as loc=... </td></tr>\n");
  print("<tr><td>types=[source,source,...]</td><td>limits results to a specific set of sources. multiple sources are separated by commas. if not set, all sources are used.</td></tr>\n");
  print("<tr><td>asm=[assembly name]</td><td>change the assembly. for example (hg18 mm9 rn4...)</td></tr>\n");

  print("<tr><td>format=[xml,gff2,gff3,bed,das]</td><td>changes the output format of the result. XML is an EdgeExpress defined XML format, while
GFF2, GFF3, and BED are common formats.</td></tr>\n");
  print("</table>\n");

  print h2("Control modes");
  print("<table cellpadding =3 width=100%>\n");
  print("<tr><td width=20% style=\"border-bottom-color:#990000;border-bottom-width:2px;border-bottom-style:solid;font-weight:bold;\">cgi parameter</td>\n");
  print("<td style=\"border-bottom-color:#990000;border-bottom-width:2px;border-bottom-style:solid;font-weight:bold;\">description</td></tr>\n");
  print("<tr><td>mode=region</td><td>Returns features in region in specified format</td></tr>\n");
  print("<tr><td>submode=[submode]</td><td> available submodes:subfeature. 'subfeature' is used for sources like transcripts with exons</td></tr>\n");
  print("</table>\n");

}

#########################################################################################

sub init_db {
  my $self = shift;
  parse_conf($self, 'eedb_server.conf');

  $eeDB = MQdb::Database->new_from_url($eeDB_url);

  EEDB::Feature->set_cache_behaviour(0);
  EEDB::Edge->set_cache_behaviour(0);
}

sub parse_conf {
  my $self = shift;
  my $conf_file = shift;

  #printf("parse_conf file : %s\n", $conf_file);
  if($conf_file and (-e $conf_file)) {
    #read configuration file from disk
    my $conf_list = do($conf_file);
    #printf("confarray:: %s\n", $conf_list);

    foreach my $confPtr (@$conf_list) {
      #printf("type : %s\n", $confPtr->{TYPE});
      if($confPtr->{TYPE} eq 'EEDB_URL') {
        $eeDB_url = $confPtr->{'url'};
      }
      if($confPtr->{TYPE} eq 'REGION') {
        if(defined($confPtr->{'assembly'}) and !defined($self->{'assembly_name'})) {
          $self->{'assembly_name'}=$confPtr->{"assembly"};
        }
      }
    }
  }
}


#
################################################
#

sub fetch_named_region {
  my $self = shift;

  $self->{'starttime'} = time()*1000;
  
  my $assembly = $self->{'assembly_name'};
  my $chrom_name = $self->{'chrom_name'};
  my $start = $self->{'start'};
  my $end = $self->{'end'};

  output_header($self);

  my $count=0;
  my $src_hash = $self->{'sourcename_hash'};
  my @sources;
  foreach my $source (values(%{$self->{'sourcename_hash'}})) {
    next if($source eq '1');
    if($self->{'format'} eq 'bed') { $source->display_info; }
    push @sources, $source;
  }

  my $chrom = EEDB::Chrom->fetch_by_name($eeDB, $assembly, $chrom_name);
  if($self->{'format'} eq 'xml') { print($chrom->simple_xml,"\n"); }

  my $features;
  if(defined($start) and defined($end)) {
    $features = EEDB::Feature->fetch_all_named_region($eeDB, $assembly, $chrom_name, $start, $end, @sources);
  } else {
    $features = EEDB::Feature->fetch_all_by_chrom($chrom, @sources);
  }
  foreach my $feature (@{$features}) {
    next if($feature->feature_source->is_active ne 'y');
    next if($feature->feature_source->is_visible ne 'y');
    next if(defined($src_hash) and !($src_hash->{$feature->feature_source->name}));
    $count++;
    if($self->{'format'} eq 'gff3') { print($feature->gff_description,"\n"); }
    if($self->{'format'} eq 'bed') { print($feature->bed_description,"\n"); }
    if($self->{'format'} eq 'das') { print($feature->dasgff_xml,"\n"); }
    if($self->{'format'} eq 'xml') { 
      if($self->{'submode'} eq "subfeature") { xml_full_feature($feature); } 
      else { print($feature->simple_xml,"\n"); }
    }
  }

  output_footer($self);
}

sub xml_full_feature {
  my $feature = shift;

  my $edges = EEDB::Edge->fetch_all_with_feature2($feature, 'category'=>"subfeature");
  print($feature->xml_start);
  if(scalar(@$edges)) {
    print("\n  <subfeatures>\n");
    foreach my $edge (sort {(($a->feature1->chrom_start <=> $b->feature1->chrom_start) ||
                              ($a->feature1->chrom_end <=> $b->feature1->chrom_end))
                            } @{$edges}) {
      print("    ", $edge->feature1->simple_xml);
    }
    print("  </subfeatures>\n");
  }
  print($feature->xml_end);
}

sub output_header {
  my $self = shift;
  
  my $window_width = $self->{'window_width'};
  my $assembly_name = $self->{'assembly_name'};
  my $chrom_name = $self->{'chrom_name'};
  my $start = $self->{'start'};
  my $end = $self->{'end'};
  my $span = $self->{'span'};
  my $height = $self->{'height'};

  if(($self->{'format'} =~ /gff/) or ($self->{'format'} eq 'bed')) {
    print header(-type => "text/plain");
    printf("browser position %s %s:%d-%d\n", $assembly_name, $chrom_name, $start, $end);
    #printf("browser hide all\n");
    printf("track name=\"eedb test track\"\n");
    #printf("visibility=2\n");
  }

  elsif($self->{'format'} eq 'xml') {
    print header(-type => "text/xml", -charset=> "UTF8");
    printf("<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\n");
    printf("<region asm=\"%s\" chrom=\"%s\" start=\"%d\" end=\"%d\" len=\"%d\" win_width=\"%d\" >\n", 
            $assembly_name, $chrom_name, $start, $end, $end-$start, $self->{'window_width'});
  }

  elsif($self->{'format'} eq 'das') {
    print header(-type => "text/xml", -charset=> "UTF8");
    printf("<?xml version=\"1.0\" standalone=\"yes\"?>\n");
    printf("<!DOCTYPE DASGFF SYSTEM \"http://www.biodas.org/dtd/dasgff.dtd\">\n");
    printf("<DASGFF>\n");
    printf("<GFF version=\"1.0\" href=\"url\">\n");
    my $chrom = EEDB::Chrom->fetch_by_name($eeDB, $assembly_name, $chrom_name);
    if($chrom) { 
      printf("<SEGMENT id=\"%d\" start=\"%d\" stop=\"%d\" type=\"%s\" version=\"%s\" label=\"%s\">\n",
             $chrom->id, 
             $start, 
             $end, 
             $chrom->chrom_type,
             $chrom->assembly->ucsc_name, 
             $chrom->chrom_name);
    }
  }

  else {
    print header(-type => "text/plain");
  }
}



sub output_footer {
  my $self = shift;

  my $total_time = (time()*1000) - $self->{'starttime'};

  if(($self->{'format'} =~ /gff/) or ($self->{'format'} eq 'bed')) {
    printf("#processtime_sec: %1.3f\n", $total_time/1000.0);
    printf("#count: %d\n", $self->{'count'});
  }
  elsif($self->{'format'} eq 'xml') {
    printf("<process_summary count=\"%d\" processtime_sec=\"%1.3f\" />\n", $self->{'count'}, $total_time/1000.0);
    print("</region>\n");
  }
  elsif($self->{'format'} eq 'das') {
    printf("</SEGMENT>\n");
    printf("</GFF>\n");
    printf("</DASGFF>\n");      
  }

}

