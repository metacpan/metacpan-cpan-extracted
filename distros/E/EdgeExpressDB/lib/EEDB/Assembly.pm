=head1 NAME - EEDB::Assembly

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

my $__riken_gsc_assembly_global_should_cache = 1;
my $__riken_gsc_assembly_global_id_cache = {};

$VERSION = 0.953;

package EEDB::Assembly;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "Assembly"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_gsc_assembly_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_gsc_assembly_global_id_cache = {};
  }
}

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'assembly_name'} = undef;  
  $self->{'taxon_id'} = undef;
  $self->{'ncbi_version'} = undef;
  $self->{'ucsc_name'} = undef;
  $self->{'release_date'} = undef;  
  return $self;
}

##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub taxon_id {
  my $self = shift;
  return $self->{'taxon_id'} = shift if(@_);
  return $self->{'taxon_id'};
}

sub ncbi_version {
  my $self = shift;
  return $self->{'ncbi_version'} = shift if(@_);
  $self->{'ncbi_version'}='' unless(defined($self->{'ncbi_version'}));
  return $self->{'ncbi_version'};
}

sub ucsc_name {
  my $self = shift;
  return $self->{'ucsc_name'} = shift if(@_);
  $self->{'ucsc_name'}='' unless(defined($self->{'ucsc_name'}));
  return $self->{'ucsc_name'};
}

sub release_date {
  my $self = shift;
  return $self->{'release_date'} = shift if(@_);
  $self->{'release_date'}=''unless(defined($self->{'release_date'}));
  return $self->{'release_date'};
}

sub display_desc
{
  my $self = shift;
  return sprintf("Assembly(db %s ) %s : %s : %s", 
    $self->id,
	  $self->ncbi_version,
    $self->ucsc_name,
    $self->release_date);
}

sub xml {
  my $self = shift;
  return sprintf("<assembly taxon_id=\"%s\" ncbi=\"%s\" ucsc=\"%s\" />\n",
	  $self->taxon_id,
	  $self->ncbi_version,
          $self->ucsc_name);
}

####################################

sub name_equals {
  my $self = shift;
  my $other = shift;
  
  return 1 if(($self->ucsc_name eq $other->ucsc_name) or ($self->ncbi_version eq $other->ncbi_version));
  return 0;
}

#################################################
#
# DBObject override methods
#
#################################################

sub store {
  my $self = shift;
  my $db   = shift;
  
  if($db) { $self->database($db); }
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO assembly (
                taxon_id,
                ncbi_version,
                ucsc_name,
                release_date)
             VALUES(?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->taxon_id,
                $self->ncbi_version,
                $self->ucsc_name,
                $self->release_date);

  my $dbID = $sth->{'mysql_insertid'};
  $sth->finish;
  return undef unless($dbID);
  $self->primary_id($dbID);
}

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  $self->primary_id($rowHash->{'assembly_id'});
  $self->taxon_id($rowHash->{'taxon_id'});
  $self->ncbi_version($rowHash->{'ncbi_version'});
  $self->ucsc_name($rowHash->{'ucsc_name'});
  $self->release_date($rowHash->{'release_date'});
    
  if($__riken_gsc_assembly_global_should_cache != 0) {
    $__riken_gsc_assembly_global_id_cache->{$self->database() . $self->id} = $self;
  }
      
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_gsc_assembly_global_should_cache != 0) {
    my $assembly = $__riken_gsc_assembly_global_id_cache->{$db . $id};
    return $assembly if(defined($assembly));
  }
  my $sql = "SELECT * FROM assembly WHERE assembly_id=?";
  return $class->fetch_single($db, $sql, $id);
}


sub fetch_by_name {
  #a 'high level' method where by either the ncbi name or ucsc name is valid
  my $class = shift;
  my $db = shift;
  my $name = shift;

  my $sql = "SELECT * FROM assembly WHERE ncbi_version=? or ucsc_name=?";
  return $class->fetch_single($db, $sql, $name, $name);
}


sub fetch_all {
  my $class = shift;
  my $db = shift;
  
  my $sql = "SELECT * FROM assembly";
  return $class->fetch_multiple($db, $sql);
}


1;

