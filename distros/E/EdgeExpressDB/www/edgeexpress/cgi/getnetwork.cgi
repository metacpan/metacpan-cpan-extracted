#!/usr/local/bin/perl -w
BEGIN{
    unshift(@INC, "/usr/local/bioperl/bioperl-1.5.2_102");
    unshift(@INC, "/usr/local/src/EdgeExpress/modules");
}

use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Switch;
use Time::HiRes qw(time gettimeofday tv_interval);
use POSIX qw(ceil floor log10);

use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use File::Temp;

use MQdb::Database;
use MQdb::MappedQuery;
use EEDB::Feature;
use EEDB::Edge;
use EEDB::Expression;

use GraphViz;

my $known  = 0;
my $sqlite = 0;
my $eeDB;

my $feature_id = param('id');
my $id_list = param('ids');
my $name_list = param('names');
my $format = param('format');
my $assembly = param('assembly');
my $singles = param('singles');
my $leaves = param('leaves');
my $expand = param('expand');
my $preview = param('preview');
my $timepoint = param('timepoint');
my $layout = param('layout');

if($format eq 'debug') { print header(-type => "text/plain", -charset=> "UTF8"); }

my $edgeset1 = {'tfbs'=>0, 'ppi'=>0, 'pub'=>0, 'chip'=>0, 'perturb'=>0, 'mirnaT'=>0};
my $edgeset2 = undef;

if(param('edgeSet1')) {
  foreach my $type (split /,/, param('edgeSet1')) {
    $edgeset1->{$type} = 1;
  }
} else {
  $edgeset1 = {'tfbs'=>1, 'ppi'=>1, 'pub'=>1, 'chip'=>1, 'perturb'=>1, 'mirnaT'=>1};
}
#foreach my $key (keys(%$edgeset1)) { printf("filter1: %s : %s\n", $key, $edgeset1->{$key}); }

if(param('edgeSet2')) {
  $edgeset2 = {'tfbs'=>0, 'ppi'=>0, 'pub'=>0, 'chip'=>0, 'perturb'=>0, 'mirnaT'=>0};
  foreach my $type (split /,/, param('edgeSet2')) {
    $edgeset2->{$type} = 1;
  }
  #foreach my $key (keys(%$edgeset2)) { printf("filter2: %s : %s\n", $key, $edgeset2->{$key}); }
}

$format='xml' unless(defined($format));
$assembly='hg18' unless(defined($assembly));
$singles='y' unless(defined($singles));
$leaves='y' unless(defined($leaves));
$layout = 'dot' unless($layout);
#if($expand) { $layout="twopi"; }

$eeDB = MQdb::Database->new(
				'-host'=>'fantom40.gsc.riken.jp', 
				'-port'=>'3306', 
				'-user'=>'read', 
				'-password'=>'read', 
				'-database'=>'f4_goi'); 

EEDB::Feature->set_cache_behaviour(1);

my $connection_count = 0;

my $starttime = time()*1000;
  
fetch_edges();

exit(1);
#########################################################################################

sub fetch_edges {

  my $feature_hash = {};

  my $raw_edges=[];
  my $edges = [];
  my $newedges = [];

  if($feature_id) {
    $edges = EEDB::Edge->fetch_all_visible_with_feature_id($eeDB, $feature_id);
    my $feature = EEDB::Feature->fetch_by_id($eeDB, $feature_id);
    $feature_hash->{$feature->id} = $feature;
  } else {
    if($name_list) {
      my @names = split(/[,\s]/, $name_list);
      my @ids;
      foreach my $name (@names) {
        my $t_features = EEDB::Feature->fetch_all_by_primary_name($eeDB, $name);
        foreach my $tfeat (@$t_features) {
          next unless($tfeat->feature_source->is_visible eq 'y');
          next unless($tfeat->feature_source->is_active eq 'y');
          push @ids, $tfeat->id;
        }
      }
      $id_list = join(',', @ids);
    }
  }
  
  if(defined($id_list)) {
    if($expand) {
      $edges = EEDB::Edge->fetch_all_active_expand_from_feature_id_list($eeDB, $id_list);
    } else {
      $edges = EEDB::Edge->fetch_all_active_between_feature_id_list($eeDB, $id_list);
    }
    $raw_edges = $edges;
  }

  #
  # first apply the edge filters
  #
  $edges = filter_edges($edges);

  #
  # OK this is where I will do the leaf filter step (on the edges)
  # then the remaining code will work just fine...
  # feature_hash has not been built yet...
  if($leaves eq 'n') { ## 'n' means hide the leaves
    $newedges=[];
    my $intnodes = {};
    foreach my $edge (@$edges) {
      if($edge->direction eq "=") {
        $intnodes->{$edge->feature1_id} = 1; 
        $intnodes->{$edge->feature2_id} = 1; 
      } else {
        $intnodes->{$edge->feature1_id} = 1; 
      }
    }
    foreach my $edge (@$edges) {
      if($edge->direction eq "=") { push @$newedges, $edge; }
      elsif($intnodes->{$edge->feature1_id} and $intnodes->{$edge->feature2_id}) {
        push @$newedges, $edge;
      } 
    }
    $edges = $newedges;
  }


  #show the singletons as unconnected nodes
  if($singles eq 'y' and $id_list) {
    my $features = EEDB::Feature->fetch_all_by_id_list($eeDB, $id_list);
    foreach my $feature (@$features) {
      next unless($feature->feature_source->is_visible eq 'y');
      next unless($feature->feature_source->is_active eq 'y');
      next if($feature->feature_source->name eq 'Agilent_miRNA_probe');
      next if($feature->feature_source->name eq 'miRBase_mature');
    
      $feature_hash->{$feature->id} = $feature;
    }
  }

  # makes sure all features on ends of edges are included
  foreach my $edge (@$edges) {
    next if($edge->feature1_id == $edge->feature2_id);
    $feature_hash->{$edge->feature1_id} = $edge->feature1;
    $feature_hash->{$edge->feature2_id} = $edge->feature2;
  }
  $newedges=[];
  foreach my $edge (@$edges) {
    next unless($feature_hash->{$edge->feature1_id} and $feature_hash->{$edge->feature2_id});
    push @$newedges, $edge;
  }
  $edges = $newedges;
  

  ##printf("\nprepared the edge List now : %d edges\n", scalar(@$edges));


  if($format eq 'cytoscape') {
    output_cytoscape_edges($edges, $feature_hash);
  } elsif($format eq 'svg') {
    output_svg_graph($edges, $feature_hash);
  } elsif($format eq 'netgenes') {
    output_netgenes($edges, $feature_hash);
  } elsif($format eq 'xml') {
    output_xml_edges($edges, $feature_hash, $id_list, $name_list);
  } elsif($format eq 'debug') {
  } else {
    print header(-type => "text/plain", -charset=> "UTF8");
    printf("unknown format : %s\n", $format);
  }
} 


sub filter_edges {
  my $input_edges = shift;

  my $out_edges =[];
  my $edge_hash = {};

  #pre-step, merge the edges into EdgeSets (node-pairs) to enable the multi-edge filtering
  foreach my $edge (@$input_edges) {
    #edge must be valid in one of the edgeSets
    next if(!test_edge_filters($edge, $edgeset1) and !test_edge_filters($edge, $edgeset2));

    my $id1 = $edge->feature1_id;
    my $id2 = $edge->feature2_id;
  ## if($id2<$id1) { my $t=$id1; $id1=$id2; $id2=$t; } ##nope this is not right
    my $key = $id1 ."_". $id2;
    push @{$edge_hash->{$key}}, $edge;
  }

  #printf("the node-pair merges\n");
  foreach my $edge_list (values(%$edge_hash)) {
    my $set1_valid=0;
    my $set2_valid=0;
    my $base_edge = $edge_list->[0];
    #printf("%10s <-> %10s :: ", $base_edge->feature1->primary_name, $base_edge->feature2->primary_name);
    foreach my $edge (@$edge_list) {
      #printf("%40s", $edge->edge_source->name);
      if(!$set1_valid and test_edge_filters($edge, $edgeset1)) { $set1_valid=1; }
      if(!$set2_valid and test_edge_filters($edge, $edgeset2)) { $set2_valid=1; }
    }
    $set2_valid = 1 if(!defined($edgeset2));
    if($set1_valid and $set2_valid) {
      #printf(" !!! VALID !!!");
      foreach my $edge (@$edge_list) {
        push @$out_edges, $edge;
      }
    }
    #print("\n");
  }
  #sort the strongest edges first
  my @tedges = sort({$a->weight <=> $b->weight} @$out_edges);
  return \@tedges;
}


sub expand_nodes {
  my $feature_ids = shift;

  foreach my $fid (split(/,/, $feature_ids)) {
    printf("fid [%s]\n", $fid);
    #my $edges = EEDB::Edge->fetch_all_visible_with_feature_id($eeDB, $fid);
    #printf("feature_id: %d  :: %d edges\n", $fid, scalar(@$edges));
  }
  return $feature_ids;
}

#
###################################################################
#

sub test_edge_filters {
  my $edge = shift;
  my $filter_set = shift;
  
  #$edge->display_info;
  return 0 if(!defined($filter_set));

  my $lid = $edge->edge_source->id;
  return 0 if($edge->edge_source->name eq 'Entrez_TFmatrix_L2anti_Entrez');
  return 0 if($edge->edge_source->name eq 'miRNA_pre2mature');
  return 0 if($edge->edge_source->name eq 'Entrez_to_TFmatrix');

  my $type = '';
  $type = 'tfbs'    if($edge->edge_source->name eq 'Entrez_TFmatrix_L2_L3_Entrez_may2008');
  $type = 'tfbs'    if($edge->edge_source->name eq 'Entrez_TFmatrix_L2_miRNA');
  $type = 'ppi'     if($edge->edge_source->name eq 'PPI');
  $type = 'pub'     if($edge->edge_source->classification eq 'Published');
  $type = 'chip'    if($edge->edge_source->name eq 'ChIP_chip');
  $type = 'perturb' if($edge->edge_source->name eq 'siRNA_perturbation');
  $type = 'perturb' if($edge->edge_source->name eq 'pre-miRNA_perturbation');
  $type = 'mirnaT'  if($edge->edge_source->name eq 'miRNA_targets');

  #printf("  filter : %s  %d\n", $type, $filter_set->{$type});
  return $filter_set->{$type};
}


sub simple_edge {
  my $edge = shift;

  printf("<edge id=\"%d\" from_name=\"%s\" to_name=\"%s\" from_cat=\"%s\" to_cat=\"%s\" type=\"%s\" from_feature_id=\"%d\" to_feature_id=\"%d\" weight=\"%1.3f\" source=\"%s\" evidence_code=\"%s\" ",
	       $edge->id,
               $edge->feature1->primary_name,
               $edge->feature2->primary_name,
               $edge->feature1->feature_source->category,
               $edge->feature2->feature_source->category,
               $edge->sub_type,
               $edge->feature1_id,
               $edge->feature2_id,
               $edge->weight,
               $edge->edge_source->name,
               $edge->edge_source->classification,
               );

  if($edge->edge_source->name eq 'Entrez_TFBS_L3_novel') {
    my $syms = $edge->symbols;
    foreach my $symbol (@$syms) {
      printf(" %s=\"%s\"", $symbol->type, $symbol->data);
    }
  }
  printf("/>\n");
}


sub simple_edge2 {
  my $edge = shift;

  printf("<edge edge_id=\"%d\" f1id=\"%s\" f2id=\"%s\" name1=\"%s\" name2=\"%s\" source=\"%s\" evidence_code=\"%s\" subtype=\"%s\" weight=\"%1.3f\" ",
	       $edge->id,
               $edge->feature1_id,
               $edge->feature2_id,
               $edge->feature1->primary_name,
               $edge->feature2->primary_name,
               $edge->link_source->name,
               $edge->link_source->classification,
               $edge->sub_type,
               $edge->weight,
               );

  my @pubmed;
  my $syms = $edge->metadataset->metadata_list;
  foreach my $symbol (@$syms) {
    if($symbol->type eq 'PubmedID') { 
      push @pubmed, $symbol->data; 
    } else {
      printf(" %s=\"%s\"", $symbol->type, $symbol->data);
    }
  }

  if(scalar(@pubmed) > 0) {
    printf("pubmed=\"%s\" ", join(',', @pubmed));
  }

  printf("/>\n");
}



sub show_edge {
  my $feature = shift;
  my $edge = shift;

  my ($dir, $neighbor) = $edge->get_neighbor($feature);
  if($edge->sub_type eq "PP") { $dir="link"; }

  printf("<$dir type=\"%s\" feature_id=\"%d\" name=\"%s\" weight=\"%1.3f\" source=\"%s\" evidence_code=\"%s\" loc=\"%s:%d-%d\" ",
               $edge->sub_type,
               $neighbor->id,
               $neighbor->primary_name,
               $edge->weight,
               $edge->edge_source->name,
               $edge->edge_source->classification,
               $neighbor->chrom_name,
               $neighbor->chrom_start,
               $neighbor->chrom_end
               );

  my @pubmed;
  if(lc($edge->edge_source->classification) eq 'published') {
    my @symbols = @{$edge->symbols};
    foreach my $symbol (@symbols) {
      if($symbol->type eq 'PubmedID') { push @pubmed, $symbol->data; }
    }
  }
  if(scalar(@pubmed) > 0) {
    printf("pubmed=\"%s\" ", join(',', @pubmed));
  }

  printf(" />\n");
}

sub output_xml_edges {
  my $edges = shift;
  my $feature_hash = shift;
  my $id_list = shift;
  my $name_list = shift;

  print header(-type => "text/xml", -charset=> "UTF8");
  printf("<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\n");
  printf("<network>\n");
  printf("<search_params>\n");
  if($name_list) { printf("<name_list>%s</name_list>\n", $name_list); }
  if($id_list) { printf("<id_list>%s</id_list>\n", $id_list); }

  print("<edge_set1>\n");
  foreach my $key (sort keys(%$edgeset1)) {  
    printf("<edgefilter type=\"%s\" value=\"%s\" />\n", $key, $edgeset1->{$key}); 
  }
  print("</edge_set1>\n");

  if($edgeset2) {
    print("<edge_set2>\n");
    foreach my $key (sort keys(%$edgeset2)) {  
      printf("<edgefilter type=\"%s\" value=\"%s\" />\n", $key, $edgeset2->{$key}); 
    }
    print("</edge_set2>\n");
  }
  printf("</search_params>\n");

  printf("<edges count=\"%d\">\n", scalar(@$edges));
  foreach my $edge (@{$edges}) {
    ## $feature_hash->{$edge->feature1_id} = $edge->feature1;
    ## $feature_hash->{$edge->feature2_id} = $edge->feature2;

    ## if($format == 1) { print($edge->xml); }
    ## if($format == 2) {  print($edge->simple_xml); }
    ## if($format == 3) { simple_edge($edge); }
    ## if($format == 4) { show_edge($feature, $edge); }

    simple_edge2($edge);
  }
  printf("</edges>\n");

  printf("<nodes count=\"%s\">\n", scalar(values(%$feature_hash)));
  foreach my $feature (values(%$feature_hash)) {
    print($feature->xml);
  }
  printf("</nodes>\n");

  my $total_time = (time()*1000) - $starttime;
  printf("<summary processtime_sec=\"%1.3f\" />\n", $total_time/1000.0);
  printf("<cgi invocation=\"%d\" pid=\"%s\" fcache=\"%d\" ecache=\"%d\" />\n",
                  $connection_count, $$,
                  EEDB::Feature->get_cache_size,
                  EEDB::Edge->get_cache_size);

  printf("</network>\n");
}

#########################################################################################

sub output_cytoscape_edges {
  my $edges = shift;
  my $feature_hash = {};

  print header(-type => "text/plain", -charset=> "UTF8");

  #compress edges
  my $edge_hash = {};
  foreach my $edge (@{$edges}) {
    my $key = $edge->feature1_id ."_". $edge->feature2_id;
    my $lid = $edge->edge_source->id;
    next if($lid == 38); #Entrez_TFmatrix_L2anti_Entrez
    if(($lid==4) || ($lid==11) || ($lid==47) || ($lid==36)) { 
      push @{$edge_hash->{$key}}, $edge;
    } else {
      print_cytoscape_edges($edge, $edge);
    }
  }

  foreach my $edges (values(%$edge_hash)) {
    my $edge = $edges->[0];
    print_cytoscape_edges($edge, @{$edges});
  }
}


sub print_cytoscape_edges {
  my $refedge = shift;
  my @supporting = @_;

  printf("%s\t%s\t",
          $refedge->feature1->primary_name,
          $refedge->feature2->primary_name,
          );
  my $uqsrc = {};
  foreach my $edge (@supporting) {
    $uqsrc->{source_alias($edge)} = 1;
  }
  printf("%s\t", join('_', sort(keys(%$uqsrc))));
  foreach my $edge (@supporting) {
    printf("%s_%1.3f,", source_alias($edge), $edge->weight);
  }
  print("\n");
}

sub source_alias {
  my $edge = shift;
  if($edge->edge_source->id == 11) { return 'ChIP'; }
  elsif($edge->edge_source->id == 47) { return 'pub'; }
  elsif($edge->edge_source->id == 40) { return 'siRNA'; }
  elsif($edge->edge_source->id == 36) { return 'CAGEtf'; }
  else { return $edge->edge_source->name; }
}

####################################################

sub output_svg_graph {
  my $edges = shift;
  my $feature_hash = shift;

  my $g;
  if($preview) { $g = GraphViz->new(layout=>$layout, ratio=>'compress', width=>7, height=>5.3); }
  #if($preview) { $g = GraphViz->new(layout=>$layout, ratio=>'auto', overlap=>'scale', width=>7, height=>5.3); }
  #else {$g = GraphViz->new(layout=>'dot', overlap=>'scale', ratio=>'compress', width=>50, height=>30, landscape=>'true'); }
  else {$g = GraphViz->new(layout=>$layout, overlap=>'scale', ratio=>'compress' ); }

  #
  # Nodes first
  #
  foreach my $feature (values(%$feature_hash)) {
    my $shape = 'ellipse';
    my $textcolor = 'black';
    my $tip = svg_tooltip($feature);
    my $url = "../view/#" . $feature->id;
    my ($express_color, $diam) = get_node_express_info($feature, $timepoint);
    if(defined($diam) and ($diam == 0.0)) { $textcolor = 'red'; }
    if(!defined($diam)) { $express_color = 1; $diam=0; }
    if($express_color >8) { $textcolor = 'white'; }
    if($feature->feature_source->category eq 'mirna') { $shape = 'octagon'; }
    $g->add_node($feature->primary_name, 
                 shape => $shape, 
                 tooltip=>$tip, 
                 URL=>$url,
                 target=>'eeDB_geneview',
                 style=>'filled',
                 colorscheme=>'purples9',
                 fontname=>'helvetica',
                 fontcolor=> $textcolor,
                 fillcolor=>$express_color,
                 width=>$diam, height=>$diam,
                 );
  }

  #compress edges
  my $edge_hash = {};
  foreach my $edge (@{$edges}) {
    my $lid = $edge->edge_source->id;
    my $key = $lid ."_". $edge->feature1_id ."_". $edge->feature2_id;
    next if($lid == 38); #Entrez_TFmatrix_L2anti_Entrez
    next if($lid == 20); #miRNA_pre2mature

    if(($lid==47) || ($lid==36) || ($lid==44) || ($lid==11) || ($lid==40) || ($lid==46)) { 
      push @{$edge_hash->{$key}}, $edge;
    } else {
      svg_add_edge($g, $edge);
    }
  }

  foreach my $edges (values(%$edge_hash)) {
    my $edge = $edges->[0];
    if($edge->edge_source->id == 11) {
      my $weight =0;
      foreach my $tedge (@$edges) { $weight += $tedge->weight; }
      $edge->weight($weight);
    }
    svg_add_edge($g, $edge);
  }

  print header(-type => "image/svg+xml", -charset=> "UTF8");
  print $g->as_svg;
}


sub svg_tooltip {
  my $feature = shift;

  my $tooltip;
  $tooltip = sprintf("%s", $feature->primary_name);
  
  my $desc = $feature->find_symbol('description');
  if($desc) { $tooltip .= sprintf(": %s", $desc->data); }
  return $tooltip; 
}


sub svg_add_edge {
  my $g = shift;
  my $edge = shift;
  
  my $style = 'solid';
  my $color = 'pink';
  my $dir = 'forward';
  my $head = 'normal';
  my $tail = 'none';
  my $penwidth = 1.0;

  $penwidth = abs($edge->weight);
  $penwidth = 1.0 if($penwidth < 1.0);

  my $tooltip = sprintf("%s %1.2f", $edge->edge_source->display_name, $edge->weight);
  if($edge->sub_type eq 'published') { $tooltip .= " pub"; }

  if($edge->edge_source->classification eq 'Experimental') { $color = 'gray'; }

  if($edge->edge_source->classification eq 'Published') { 
    $color = 'gold'; $style="solid"; 
    if($edge->weight < 0.0) { $head='tee'; } else { $head='normal'; }
  }
  if($edge->edge_source->name eq 'ChIP_chip') { $color = 'green'; }
  if($edge->edge_source->name =~ /PPI/) { $color = 'purple'; $dir="none"; $head="dot"; $tail="dot"; }

  if($edge->edge_source->name eq 'siRNA_perturbation') { 
    $color = 'red';  $style="dashed";
    if($edge->weight > 0.0) { $head='tee'; } else { $head='normal'; }
  }
  if($edge->edge_source->name eq 'pre-miRNA_perturbation') { 
    $color = 'red';  $style="dashed";
    if($edge->weight < 0.0) { $head='tee'; } else { $head='normal'; }
  }

  if($edge->edge_source->name eq 'Entrez_TFmatrix_L2_L3_Entrez_may2008') { $color = 'black';  $style="solid";}
  if($edge->edge_source->name eq 'Entrez_TFmatrix_L2_miRNA') { $color = 'black';  $style="solid";}
  if($edge->edge_source->name eq 'miRNA_targets') { $color = 'black';  $style="dashed"; $head="tee"; }

  $g->add_edge($edge->feature1->primary_name => $edge->feature2->primary_name,
               title => $tooltip,
               color => $color,
	       dir => $dir,
               arrowhead => $head,
               arrowtail => $tail,
	       style => $style,
               imagescale => 'true',
               weight => $edge->weight,
               penwidth => $penwidth,
               edgetooltip => $tooltip
              );
}

sub get_node_express_info {
  my $feature = shift;
  my $time_point = shift;
  
  $time_point=0 unless(defined($time_point));
  
  my $maxexpress=undef;
  my $min_express=undef;
  my $express_point = undef;
  my @allexp;
  my $probe_express_array;

  #
  # first pick the best probe for this gene
  #
  my $edges = EEDB::Edge->fetch_all_to_feature_id($eeDB, $feature->id, 28); #ILMN express
  foreach my $edge (@{$edges}) {
    next unless($edge->feature2->id eq $feature->id);
    my $express_array = EEDB::Expression->fetch_all_by_feature($edge->feature1);
    my $minexp=undef;
    foreach my $express (@$express_array) {
      next unless($express->type eq 'norm');
      if($express->sig_error >=0.99) { 
        if(!defined($minexp)) { $minexp = $express; }
        if($express->value < $minexp->value) { $minexp = $express; }
      }
    }
    next unless(defined($minexp));

    if(!defined($min_express)) { 
      $probe_express_array = $express_array; 
      $min_express = $minexp; 
    }
    if($minexp->sig_error > $min_express->sig_error) { 
      $probe_express_array = $express_array; 
      $min_express = $minexp; 
    }
  }
  if(!defined($min_express)) { return (1,0);}

  #
  # next loop again for max, median, and timepoint calc
  #
  foreach my $express (@$probe_express_array) {
    next unless($express->type eq 'norm');
    if($express->sig_error >=0.99) { 
      push @allexp, $express; 
    }

    if($express->experiment->series_point eq $time_point) {
      if(!defined($express_point)) { $express_point = $express; }
      if(($express->sig_error >=0.99) and ($express_point->sig_error < 0.99)) { $express_point = $express; }
      if(($express->value > $express_point->value) and 
         (($express->sig_error >=0.99) or ($express_point->sig_error < 0.99))) { $express_point = $express; }
    }

    if(!defined($maxexpress)) { $maxexpress = $express; }
    if(($express->sig_error >=0.99) and ($maxexpress->sig_error < 0.99)) { $maxexpress = $express; }
    if(($express->value > $maxexpress->value) and
       (($express->sig_error >=0.99) or ($maxexpress->sig_error < 0.99))) { $maxexpress = $express; }
  }
  
  my $ratio = floor(0.5 + (9 * ($express_point->value / $maxexpress->value)));
  if($ratio < 1) { $ratio=1; }
  if($express_point->sig_error < 0.99) { $ratio = 1; }

  my @sexp = sort {$a->value <=> $b->value} @allexp;
  my $median_point = $sexp[int(scalar(@sexp)/2)];

  #my $diam = log10($express_point->value/70)/2 +0.5;
  #my $diam = log10($maxexpress->value/70)/2 +0.5;
  #my $diam = log10($median_point->value/70)/2 +0.5;
  my $diam = log10($maxexpress->value / $min_express->value);

  #my $diam = log10($express_point->value / $min_express->value)*2;  #diameter as dB at timepoint
  #my $diam = log10($maxexpress->value / $median_point->value)*2;  #diameter as dB of max/median
  #my $diam2 = log10($median_point->value/ $min_express->value)*2;
  #if($diam2 > $diam) { $diam = $diam2; }

  $diam = 0.5 if($diam < 0.5);
  #$diam = 2.0 if($diam > 2.0);

  return ($ratio, $diam);
}

####################################################

sub output_netgenes {
  my $edges = shift;
  my $feature_hash = shift;

  print header(-type => "text/plain", -charset=> "UTF8");

  my $count=0;
  foreach my $feature (sort {$a->primary_name cmp $b->primary_name} values(%$feature_hash)) {
    printf("%s ", $feature->primary_name);
    $count++;
    if($count % 10 == 0) { print("\n"); }
  }
  printf("\n");
}


