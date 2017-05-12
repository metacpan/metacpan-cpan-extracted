#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_expression_table.pl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTACT

Jessica Severin <severin@gsc.riken.jp>

=head1 LICENSE

  * Software License Agreement (BSD License)
  * EdgeExpressDB [eeDB] system
  * copyright (c) 2007-2009 Jessica Severin RIKEN OSC
  * All rights reserved.
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *     * Redistributions of source code must retain the above copyright
  *       notice, this list of conditions and the following disclaimer.
  *     * Redistributions in binary form must reproduce the above copyright
  *       notice, this list of conditions and the following disclaimer in the
  *       documentation and/or other materials provided with the distribution.
  *     * Neither the name of Jessica Severin RIKEN OSC nor the
  *       names of its contributors may be used to endorse or promote products
  *       derived from this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ''AS IS'' AND ANY
  * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
  * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Switch;

use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use File::Temp;
use Compress::Zlib;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::FeatureSource;
use EEDB::EdgeSource;
use EEDB::Feature;
use EEDB::Edge;
use EEDB::Experiment;
use EEDB::Expression;
use EEDB::Tools::MultiLoader;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $url = undef;
my $update = 0;
my $store = 0;
my $debug=0;
my $display_interval = 100;
my $no_mapping = 0;
my $sparse =0;

my $assembly_name = undef;
my $assembly = undef;

my $fsrc = undef;
my $fsrc_name = undef;

my $exp_prefix = '';
my $platform = '';
my $sym_type = undef;
my $default_data_type = "norm";

my @exp_column_types = ();
my $exp_col_count = 0;

GetOptions( 
            'url:s'        =>  \$url,
            'file:s'       =>  \$file,
            'fsrc:s'       =>  \$fsrc_name,
            'exp_prefix:s' =>  \$exp_prefix,
            'symtype:s'    =>  \$sym_type,
            'datatype:s'   =>  \$default_data_type,
            'platform:s'   =>  \$platform,
            'asm:s'        =>  \$assembly_name,
            'assembly:s'   =>  \$assembly_name,
            'update'       =>  \$update,
            'nomap'        =>  \$no_mapping,
            'sparse'       =>  \$sparse,
            'store'        =>  \$store,
            'v'            =>  \$debug,
            'debug:s'      =>  \$debug,
            'help'         =>  \$help
            );


if ($help) { usage(); }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
} 
unless($eeDB) { 
  printf("ERROR: connection to database\n\n");
  usage(); 
}

printf("\n==============\n");

if(defined($fsrc_name)) {
  $fsrc = EEDB::FeatureSource->create_from_name($fsrc_name, $eeDB);
  if($store) { $fsrc->store($eeDB); }
  $fsrc->display_info;
} 

unless($fsrc){
  printf("ERROR must specify -fsrc param\n\n");
  usage();
}

if(!$no_mapping) {
  unless(defined($assembly_name)) {
    printf("ERROR: must supply -assembly parameter if mapping data is provided\n\n");
    usage();
  }
  $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
  unless(defined($assembly)) {
    printf("ERROR: assembly [%s] not in database\n\n", $assembly_name);
    usage();
  }
  $assembly->display_info;
}


if($file and (-e $file)) { 
  my $error_path = $file . ".errors";
  open(ERRORFILE, ">>", $error_path);
  load_expression();
  close(ERRORFILE);
} else {
  printf("ERROR: must specify tsv edge file for data loading\n\n");
  usage(); 
}

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_expression_table.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to EEDB database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "  -exp_prefix <name>  : add this prefix to the experiment names defined from the column heading\n";
  print "  -platform <name>    : name of the experimental platform when creating experiments\n";
  print "                        eg nanoCAGE, CAGE, GeneChip, IlluminaChip\n";
  print "  -datatype <type>    : expression datatype if it is not specified in the datafile column headings\n";
  print "  -nomap              : seq-based expression (nanoCAGE, CAGE, RNAseq) has mapping columns, microarray does not\n";
  print "  -sparse             : do not insert 0.0 expression values\n";
  print "  -assembly <name>    : name of species/assembly when mapping data is provided (eg hg18, mm9, rn4...)\n";
  print "  -store              : (default not store for debugging) actually store the data in the database\n";
  print "  -update             : try to lookup feature in database and reuse for loading expression\n";
  print "  -v                  : simple debugging output\n";
  print "  -debug <level>      : extende debugging output (eg -debug 3)\n";
  print "eedb_load_expression_table.pl v1.0\n";
  
  exit(1);  
}


#########################################################################################


sub load_expression {
  printf("==============\n");
  my $starttime = time();
  my $linecount=0;
  
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);
  
  my $gz = gzopen($file, "rb") ;
  my $line;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    $linecount++;
    $line =~ s/\r//g;

    #
    # seq-map version (either raw tag-mapping or cluster-level output)
    #
    #sequence                     chrom   start      end        strand  A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA    chr12   26364765   26364789   -       1       0       1       0       0       0       0       0       0       0       1
    #
    #cluster                     chrom   start      end        strand  A       E       P3      P5      P7      P9      P12     P18     P28     total
    #CAGE_L2_1234567             chr12   26364765   26364789   -       1       0       1       0       0       0       0       0       0       0       1

    #
    # chip/probe/qRT-PCR version
    #
    #probeset_id      P12GRS_L2_1_RG230   P12GRS_L5_1_RG230   P12SBF_L2_1_RG230   P12SBF_L5_1_RG230   P12GRS_L2_2_RG230   
    #AFFX-BioB-5_at   8.47083             8.66242             8.44700             8.15746             8.15182 

    my ($primaryID, @expression);
    my ($chrname, $start, $end, $strand);
    
    if($no_mapping) {
      ($primaryID, @expression)  = split(/\t/, $line);
    } else {
      ($primaryID, $chrname, $start, $end, $strand, @expression)  = split(/\t/, $line);
    }
    
    if($linecount == 1) {
      create_experiments(@expression);
      next;
    }
    
    my $feature;
    if($update) {
      my $other;
      ($feature, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $primaryID, $fsrc)};
      if(defined($other)) { 
        printf(ERRORFILE "ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $primaryID, $fsrc->name); 
      }
      unless($feature) { 
        print("update WARN: need to create feature:: %s\n", $primaryID); 
        print(ERRORFILE "update WARN: need to create feature:: %s\n", $primaryID); 
      }
    }
    unless($feature) { 
      $feature = new EEDB::Feature;
      $feature->primary_name($primaryID);
      $feature->feature_source($fsrc);
      unless($no_mapping) {
        my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($assembly, $chrname);
        $feature->chrom($chrom);
        $feature->chrom_start($start);
        $feature->chrom_end($end);
        $feature->strand($strand);
      }
      #$feature->metadataset->add_tag_symbol("keyword", $feature->primary_name);
      #print("Needed to create:: %s\n", $feature->simple_display_desc);
    }
    printf("%s\n", $feature->simple_display_desc) if($debug);

    #
    # now do the expressions
    #    
    for(my $x=0; $x<$exp_col_count; $x++) {
      my $expobj        = $exp_column_types[$x];
      my $experiment    = $expobj->{'experiment'};
      my $datatype      = $expobj->{'type'};
      my $colname       = $expobj->{'colname'};
      
      my $value = $expression[$x];
      if($sparse and ($value == 0.0)) { next; }
      
      if($debug>2) {
        printf("\ncolnum   : %d\n", $x);
        printf("colname  : %s\n", $colname);
        printf("exp      : %s\n", $experiment);
        printf("expid    : %s\n", $experiment->id);
        printf("type     : %s\n", $datatype);
        printf("value    : %s\n", $value);
      }
      
      #Feature->get_expression() is a clever (but dangerous) method
      #if the feature is from the database, it can fetch the expression in one bulk operation
      #if not connected then works as a simple hash (but with a bunch of methods calls)
      my $expression = $feature->get_expression($experiment, $datatype);
      unless($expression) {
        $expression = new EEDB::Expression;
        $expression->feature($feature);
        $expression->experiment($experiment);
        $expression->sig_error(0.0); #default
        $feature->add_expression($expression);
      }
      $expression->type($datatype);
      $expression->value($value);
      printf("   %s\n", $expression->display_desc) if($debug>2);
    }
    print("\n") if($debug>2);
    
    if(!($feature->primary_id)) { #need to store feature and expression together
      $multiLoad->store_feature($feature);
      #print("store feature and expression\n");
    } else {
      foreach my $expression (@{$feature->get_expression_array}) {
        printf("   %s\n", $expression->display_desc) if($debug>1);
        if($feature->primary_id and !($expression->primary_id)) { 
          #feature already in database, but not the expression 
          #so just do add the expression
          $multiLoad->store_express($expression);
        }
      }
    }    

    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount-1, $rate, $feature->simple_display_desc); 
    }
  }
  $gz->gzclose();

  $multiLoad->flush_buffers();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}

###################

sub create_experiments {
  my @column_names_list = @_;
  
  printf("====== create experiments ======\n");
  #Detection.xxxx  or   Raw.xxxx
    
  my $expname_hash = {};  #for debugging before store
  @exp_column_types = ();
  $exp_col_count = 0;
  
  foreach my $colname (@column_names_list) {
    #printf("== %s\n", $colname);
    my $datatype = $default_data_type;
    my $exp_name = $colname;
    
    if($colname =~ /[Dd]etection\.(.+)/) {
      $datatype = 'detection';
      $exp_name = $1;
    }
    if($colname =~ /[Nn]orm\.(.+)/) {
      $datatype = 'norm';
      $exp_name = $1;
    }
    if($colname =~ /[Rr]aw\.(.+)/) {
      $datatype = 'raw';
      $exp_name = $1;
    }
    
    $exp_name =~ s/\s/_/g;
    my $fullname = $exp_name;
    if($exp_prefix) { $fullname = $exp_prefix .'_'. $exp_name; }
    
    my $experiment = $expname_hash->{$fullname};
    
    unless($experiment) {
      $experiment = EEDB::Experiment->fetch_by_exp_accession($eeDB, $fullname);
      $expname_hash->{$fullname} = $experiment;
    }
    unless($experiment) {      
      $experiment = new EEDB::Experiment;
      $experiment->exp_accession($fullname);
      $experiment->series_name($exp_prefix);
      $experiment->series_point($exp_col_count);
      $experiment->platform($platform);
      $experiment->is_active('y');

      if($store) { $experiment->store($eeDB); }
      else {$experiment->primary_id($exp_col_count); } #for debugging and certain tools

      #$experiment->display_info if($debug);
      $expname_hash->{$fullname} = $experiment;
    }
    my $expobj = {'colname'=>$colname, 'type'=>$datatype, 'expname'=>$fullname, 'experiment'=>$experiment};
    printf("== %25s  %10s    %s\n", $colname, $datatype, $experiment->display_desc);
    push @exp_column_types, $expobj;
    $exp_col_count++;
  }
  
  printf("loaded %d exp columns\n", scalar(@exp_column_types));
}

