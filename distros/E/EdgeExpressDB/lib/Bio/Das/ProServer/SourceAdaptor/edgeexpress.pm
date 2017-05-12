#########
# Author:        Jessica Severin
# Maintainer:    Jessica Severin
# Created:       2008-08-27
# Last Modified: $Date: 2008/10/29 10:22:15 $
#

=head1 NAME

 Bio::Das::ProServer::SourceAdaptor::edgeexpress
 Auto-config ProServer that talks with an EdgeExpress database

=head1 VERSION

$LastChangedRevision: 2 $

=head1 SYNOPSIS

 An auto-config ProServer that talks with an EdgeExpress database
  - auto-configs segments and sources from the database
  - Builds simple DAS features from the EdgeExpress database
  - uses EdgeExpress perl API for enhanced speed and smart caching

=head1 DESCRIPTION

=head2 capabilities

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

  [my_eedb]
  state          = on
  adaptor        = edgeexpress
  transport      = edgeexpress
  eedb_url       = mysql://<user>:<pass>@<host>:<port optional>/<database_name>
  assembly       = <assembly name as used in the eeDB>  #eeDB is multi_species, each DAS source is not
  description    = description of the EdgeExpressDB this is configured for

=head1 DEPENDENCIES
 
 ProServer
   Bio::Das::ProServer::SourceAdaptor

 EdgeExpress
   EEDB::FeatureSource;
   EEDB::Feature;
   EEDB::Assembly;
   EEDB::Chrom;

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

 Jessica Severin <severin@gsc.riken.jp>.

=head1 LICENSE AND COPYRIGHT

=head1 APPENDIX

 The rest of the documentation details each of the object methods. 
 Internal methods are usually preceded with a _

=head1 SUBROUTINES/METHODS

=cut

package Bio::Das::ProServer::SourceAdaptor::edgeexpress;
use strict;
use warnings;

use EEDB::FeatureSource;
use EEDB::Feature;
use EEDB::Assembly;
use EEDB::Chrom;

use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub capabilities {
  return {
	  features     => '1.0',
    types        => '1.0',
    entry_points => '1.0'
	 };
} 

####################################

sub build_entry_points {
  my $self = shift;
  #printf("edgeexpress::build_entry_points called\n");

  my $asm = $self->config->{'assembly'};

  my $chroms = EEDB::Chrom->fetch_all_by_assembly_name($self->transport->database, $asm);
  my @segments;
  foreach my $chrom (sort {$b->chrom_length <=> $a->chrom_length} @$chroms) {
    my $segment = {
                    'segment'  => $chrom->chrom_name,
                    'length'   => $chrom->chrom_length,
                   #'start'    => $
                   #'stop'     => $
                   #'ori'      => $
                    'subparts' => 'yes'
                  };
    push @segments, $segment;
  }
  return @segments;
}


sub known_segments {
  my $self = shift;
  #printf("edgeexpress::known_segments called\n");

  my $asm = $self->config->{'assembly'};

  my $chroms = EEDB::Chrom->fetch_all_by_assembly_name($self->transport->database, $asm);
  my @segments;
  foreach my $chrom (sort {$a->chrom_name cmp $b->chrom_name} @$chroms) {
    push @segments, $chrom->chrom_name;
  }
  return @segments;
}


###############################

sub das_types {
  my ($self, $opts) = @_;
  printf("\nhijack das_types before going back to superclass\n");
  print($opts, "\n");
  foreach my $key (keys(%$opts)) {
    printf("  %s => %s\n", $key, $opts->{$key});
  }

  #first clear from last feature request
  $self->{'feature_filter_type'} = undef;
  if($opts->{'type'}) {
    $self->{'feature_filter_type'} = $opts->{'type'};
  }
  return $self->SUPER::das_types($opts);
}

sub build_types {
  my ($self, @args) = @_;

  #printf("build_types\n");
  my $type_filter  = $self->{'feature_filter_type'};

  my @return_types = ();
  my $fsrcs = EEDB::FeatureSource->fetch_all($self->transport->database);
  foreach my $fsrc (@$fsrcs) {
    next unless($fsrc->is_active and $fsrc->is_active eq 'y');
    next unless($fsrc->is_visible and $fsrc->is_visible eq 'y');
    next if(defined($type_filter) and ($type_filter ne $fsrc->name));
    $fsrc->display_info;

    if(scalar @args) {
      for (@args) {
        my ($seg, $start, $end) = @{$_}{qw(segment start end)};
      }
    }
    
    my $type = {
        'count'        => $fsrc->get_feature_count,
        'type'         => $fsrc->name,
        'category'     => $fsrc->category,
        'description'  => $fsrc->comments,
      # 'method'       => $
      # 'c_ontology'   => $
      # 'evidence'     => $
      # 'e_ontology'   => $
         'count'       => $fsrc->get_feature_count
         };

    push @return_types, $type;

  }
  return @return_types;
}


###############################

sub das_features {
  my ($self, $opts) = @_;

  #printf("\nhijack das_features before going back to superclass\n");
  #print($opts, "\n");
  #foreach my $key (keys(%$opts)) {
  #  printf("  %s => %s\n", $key, $opts->{$key});
  #}
  
  #first clear from last feature request
  $self->{'feature_filter_type'} = '';
  $self->{'wiggle_plot'} = undef;
  if($opts->{'type'}) {
    if($opts->{'type'} =~/(.*)\.wig/) {
      $self->{'feature_filter_type'} = $1;
      $self->{'wiggle_plot'} = 1;
    } else {
      $self->{'feature_filter_type'} = $opts->{'type'};
    }
  }
  return $self->SUPER::das_features($opts);
}


sub build_features {
  my ($self, $opts) = @_;
  
  my $type          = $self->{'feature_filter_type'};
  my $wiggle        = $self->{'wiggle_plot'};
  my $segment       = $opts->{segment};
  my $start         = $opts->{start};
  my $end           = $opts->{end};
  my $dsn           = $self->{dsn};
  
  my $asm           = $self->config->{'assembly'};

  printf("edgeexpress::build_features called\n");
  if($type) { printf("type = [%s]\n", $type); }
  if($wiggle) { printf("wiggle\n"); }
  if($dsn) { printf("dsn = [%s]\n", $dsn); }
  
  my $fsrc = EEDB::FeatureSource->fetch_by_name($self->transport->database, $type);
  my $features = EEDB::Feature->fetch_all_named_region($self->transport->database, $asm, $segment, $start, $end, $fsrc);
  
  my @rtn_features;
  foreach my $feature (@$features) {
    next unless($feature->feature_source->is_active and $feature->feature_source->is_active eq 'y');
    next unless($feature->feature_source->is_visible and $feature->feature_source->is_visible eq 'y');
    my $das_feature = {
                      id     => $feature->id,
                      label  => $feature->primary_name,
                      type   => $feature->feature_source->name,
                      method => $feature->feature_source->category,
                      start  => $feature->chrom_start,
                      end    => $feature->chrom_end,
                      ori    => $feature->strand,
                      #note   => $row->{note},
                      #link   => $row->{link},
                      };
    if($wiggle) {
      $das_feature->{score} = $feature->significance;
    }
    push @rtn_features, $das_feature;
  }
  return @rtn_features;
}


1;
__END__

