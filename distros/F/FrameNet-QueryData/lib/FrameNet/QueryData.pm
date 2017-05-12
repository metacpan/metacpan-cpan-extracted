package FrameNet::QueryData;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '0.07';

use Carp;
use warnings;
use strict;
use Storable;
use XML::TreeBuilder;
use XML::XPath;
use File::Spec;
use Data::Dumper;

my $CACHE_VERSION = '0.03.2';

sub new {
  my $class = shift;
  my $self = {};

  $class = ref $class || $class;

  bless $self, $class;
  
  my %params = @_;

  ##############
  ### FNHOME ###
  ##############
  # precedence: parameter, environment variable
  if (defined $params{-fnhome}) {
    $self->fnhome($params{-fnhome});
  } elsif (defined $ENV{FNHOME}) {
    $self->fnhome($ENV{FNHOME});
  } else {
      carp "FrameNet could not be found. Did you set \$FNHOME?\n";
    
  }

  ###############
  ### VERBOSE ###
  ###############
  if (defined $params{-verbose}) {
    $self->verbose($params{-verbose})
  } else {
    # Default: No output
    $self->verbose(0);
  };

  ###############
  ### CACHE #####
  ###############
  if (defined $params{-cache}) {
      $self->cache(1);
  } else {
      $self->cache(0);
  }

  # Currently no cache system available
  # $self->cache(0);
  # $self->{VCACHE} = 0.01;
  
  my $infix = "xml";
  $infix = "frXML" if (-e File::Spec->catfile(($self->fnhome,"frXML"),
					      "frames.xml"));
  $self->file_frames_xml(File::Spec->catfile(($self->fnhome,$infix),
					     "frames.xml"));
  $infix = "xml" if (-e File::Spec->catfile(($self->fnhome,"xml"),
					      "frRelation.xml"));
  $self->file_frrelation_xml(File::Spec->catfile(($self->fnhome,$infix),
						 "frRelation.xml"));
  
  # no cache in this version


  return $self;
}

sub _init_cache {
    my $self = shift;


    # Used for untainting
    my $u = $ENV{'USER'};
    
    if ($u =~ /^([\w\.\-]+)$/) {
	$u = $1;
    } else {
	$u = 'user';
    }

    $self->{'cachefilename'} = File::Spec->catfile((File::Spec->tmpdir),$u."-FrameNet-QueryData-".$CACHE_VERSION.".dat");

    if ($self->cache) {
	if (! -e $self->{'cachefilename'}) {
	    store({}, $self->{'cachefilename'});
	}
	$self->{'cache'} = retrieve($self->{'cachefilename'});
    }

    return $self->cache;
}

sub _store_cache {
    my $self = shift;
    if ($self->cache) {
	store($self->{'cache'}, $self->{'cachefilename'});
    }
}

sub fnhome {
    my ($self, $fnhome) = @_;
    $self->{'fnhome'} = $fnhome if (defined $fnhome);
    return $self->{'fnhome'};
}

sub verbose {
    my ($self, $verbose) = @_;
    $self->{'verbose'} = $verbose if (defined $verbose);
    return $self->{'verbose'};
}

sub cache {
    my ($self, $cache) = @_;
    $self->{'cache_enabled'} = $cache if (defined $cache);
    return $self->{'cache_enabled'};
}

sub frame {
  my ($self, $framename) = @_;
  return {} if (not defined $framename);
  if ($self->cache) {
      $self->_init_cache;
      if (exists($self->{'cache'}{'frames'}{$framename})) {
	  return $self->{'cache'}{'frames'}{$framename};
      }
  }
  my $ret = {};
  $ret->{'name'} = $framename;
  $self->parse;
  $ret->{'lus'} = $self->_lu_part_of_frame($framename);
  $ret->{'fes'} = $self->_fe_part_of_frame($framename);

  if ($self->cache) {
      $self->_init_cache;
      $self->{'cache'}{'frames'}{$framename} = $ret;
      $self->_store_cache;
  }

  return $ret;
};

sub related_frames {
  my ($self, $framename, $relation) = @_;
  $self->xparse;
  return $self->{'rels'}->{$relation}->{$framename};  
};

sub related_inv_frames {
  my ($self, $framename, $relation) = @_;
  $self->xparse;
  return $self->{rels}->{$relation}->{'inverse'}->{$framename};  
};

sub _fe_part_of_frame {
  my ($self, $framename) = @_;
  my $partnodes = $self->_part_of_frame($framename, 'fe');
  my $ret = [];
  foreach my $pa (@$partnodes) {
    push(@$ret, { 'name' => $pa->find('@name')->string_value,
		  'ID' => $pa->find('@ID')->string_value,
		  'abbrev' => $pa->find('@abbrev')->string_value,
		  'coreType' => $pa->find('@coreType')->string_value });
  }
  return $ret;
};


sub _lu_part_of_frame {
  my ($self, $framename) = @_;
  my $partnodes = $self->_part_of_frame($framename, 'lexunit');
  my $ret = [];
  foreach my $pa (@$partnodes) {
      my $name = $pa->find('@name')->string_value;
      chop $name;
      chop $name;


    push(@$ret, { 'name' => $name,
		  'ID' => $pa->find('@ID')->string_value,
		  'pos' => $pa->find('@pos')->string_value,
		  'status' => $pa->find('@status')->string_value,
		  'lemmaId' => $pa->find('@lemmaId')->string_value });
  }
  return $ret;
};

sub _part_of_frame {
  my ($self, $framename, $part) = @_;
  $self->parse;
  my @parts = $self->{xtree}->
    find('//frames/frame[@name="'.$framename.'"]/'.$part.'s/'.$part)->
      get_nodelist;
  return \@parts;
}

sub related {
  my $self = shift;
  my ($f1,$f2) = @_;

  $self->xparse;

  foreach my $relname (keys %{$self->{'rels'}}) {
      #print STDERR "Checking ".$relname."\n";
      #print STDERR Dumper($self->{'rels'}{'inverse'}{$relname}{$f2});
      return $relname if (grep(/$f2/, @{$self->{'rels'}{$relname}{$f1}}) or
		   grep(/$f1/, @{$self->{'rels'}{$relname}{$f2}}));
  };
  return 0;
  
};

sub transitive_related {
    my $self = shift;
    my ($frame1, $frame2) = @_;

    $self->xparse;

    foreach my $relname (keys %{$self->{'rels'}}) {
	if (grep(/$frame2/, @{$self->{'rels'}{$relname}{$frame1}}) or
	    grep(/$frame1/, @{$self->{'rels'}{$relname}{$frame2}})) {
	    #print STDERR $relname;

	    return 1;
	}
	foreach my $f (@{$self->{'rels'}{$relname}{$frame1}},
		       @{$self->{'rels'}{$relname}{$frame2}}) {
	    if ($self->transitive_related($frame1, $f)) {
		#print STDERR $f."\n";
		return 1;
	    }
	}
    }
    return 0;
}

sub path_related {
    my $self = shift;
    my $frame1 = shift;
    my $frame2 = shift;
    my @path = @_;

    $self->xparse;
    #print STDERR "$frame1 vs. $frame2 ".join(', ', @path)."\n";
    if (@path == 0) {
	return ($frame1 eq $frame2);
    }

    my $rel = shift(@path);

    foreach my $f (@{$self->{'rels'}{$rel}{$frame1}}) {
	return 1 if ($f eq $frame2);
	return 1 if ($self->path_related($f, $frame2, @path));
    };
    
    foreach my $f (@{$self->{'rels'}{$rel}{'inverse'}{$frame1}}) {
	return 1 if ($f eq $frame2);
	return 1 if ($self->path_related($f, $frame2, @path));
    };

    return 0;
}

sub dumpout {
  my $self = shift;
  $self->xparse;
  print Dumper($self->{rels});
};

sub xparse {
  my $self = shift;
  if (! defined $self->{'xp'}) {
      if ($self->_init_cache and exists($self->{'cache'}{'rels'})) {
	  $self->{'rels'} = $self->{'cache'}->{'rels'};
      } else {

	  print STDERR "Parsing XML file (frRelation.xml)\n" if ($self->verbose > 0);
	  $self->{'xp'} = XML::XPath->new(filename => $self->file_frrelation_xml);
	  
	  foreach my $frame_relation ($self->{'xp'}->find("//frame-relation-type/frame-relations/frame-relation")->get_nodelist) {
	      
	      my $relation_type = $frame_relation->find('../../@name')->string_value;
	      
	      my $super = $frame_relation->find('@superFrameName')->string_value;
	      my $sub = $frame_relation->find('@subFrameName')->string_value;
	      
	      push(@{$self->{rels}->{$relation_type}->{$sub}},$super);
	      #      if (! grep(/$super/,@{$self->{rels}->{$relation_type}->{$sub}}));
	      push(@{$self->{rels}->{$relation_type}->{'inverse'}->{$super}},$sub);
	      #      if (! grep(/$super/,@{$self->{rels}->{$relation_type}->{'inverse'}->{$super}}));
	  };
	  if ($self->_init_cache) {
	      $self->{'cache'}->{'rels'} = $self->{'rels'};
	      $self->_store_cache;
	  }
      };
  };
};

sub file_frames_xml {
    my ($self, $fname) = @_;
    $self->{'file_frames_xml'} = $fname if (defined $fname);
    return $self->{'file_frames_xml'};
}

sub file_frrelation_xml {
    my ($self, $fname) = @_;
    $self->{'file_frrelation_xml'} = $fname if (defined $fname);
    return $self->{'file_frrelation_xml'};
}

sub parse {
   my $self = shift;
   if (not (defined $self->{xtree})) {
     print STDERR "Parsing XML file (frames.xml)\n" if ($self->verbose > 0);
     $self->{xtree} = XML::XPath->new(filename => $self->file_frames_xml);
   };
};

sub frames {
   my $self = shift;
   
   if ($self->cache) {
       $self->_init_cache;
       if (exists($self->{'cache'}{'all_frames'})) {
	   return @{$self->{'cache'}{'all_frames'}};
       }
   }

   $self->parse;

   my $frames;
   foreach my $frame ($self->{xtree}->find("//frames/frame")->get_nodelist) {
     $frames->{$frame->find('@name')->string_value} = 1;
   };

   my @all_frames = keys %$frames;
   
   if ($self->cache) {
       $self->_init_cache;
       $self->{'cache'}{'all_frames'} = \@all_frames;
       $self->_store_cache;
   }

   return @all_frames;
 }


=head1 NAME

FrameNet::QueryData - A module for accessing the FrameNet data. 

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use FrameNet::QueryData;

    # The name of the frame
    my $framename = "Getting";

    my $qd = FrameNet::QueryData->new(-fnhome => $ENV{'FNHOME'},
                                      -verbose => 0,
                                      -cache => 1);
    
    my $frame = $qd->frame($framename);
    # Getting the lexical units
    my $lus = $frame->{'lus'};
    # Getting the frame elements
    my $fes = $frame->{'fes'}

    # Listing the names of all lexical units
    print join(', ', map { $_->{'name'} } @$lus);

    # Listing all frames that are used by Getting
    print $qd->related_frames('Getting', 'Using');

    # List all frames that use Getting
    print $qd->related_inv_frames('Getting', 'Using');

    # Find out if two frames are directly related
    print "They are!" if ($qd->related("Getting", "Intentionally_create"));

    # Find out, if two frames are related through a Using relation
    print "They are!" if ($qd->path_related("Getting", "Intentionally_create", "Using"));

    # Find out if two frames are related through some relations and other frames, i.e. indirectly related
    print "They are!" if ($qd->transitive_related("Getting", "Intentionally_create"));

    # Printing a list of all frames 
    print join(', ', $qd->frames);

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to FrameNet. Its database is organized in large XML files, which are parsed by this module. The module has been tested with FrameNet 1.2 and 1.3. Other versions may work, but it is not guaranteed. 

=head1 METHODS

=over 4

=item new ( -fnhome, -verbose, -cache)

The constructor for this class. It can take two arguments: The path to the FrameNet directory and a verbosity level. Both are not mandatory. -fnhome defaults to the environment variable $FNHOME, -verbose defaults to 0 (zero), which means no output.

-cache (available since 0.03) controls, if the parsed data is kept in a file for later use. This increases performance significantly. The cache itself is located in the temporary directory of your system.

=item fnhome ($FNHOME)

Sets and returns the FrameNet home directory. If the argument is given, it will be set to the new value. If the argument is omitted, the value will be returned.

=item verbose ($VERBOSE) 

Sets and returns the verbosity level. If the argument is given, the verbosity level will be set to this new value. If not, the value is returned. 

=item frame ($FRAMENAME)

This method returns a hash containing information for the frame $FRAMENAME. The hash has three elements: 

=over 8

=item name

The name of the frame

=item lus

A list containing all the lexical units of the frame. The lexical units are represented by another hash containing the keys 'name', 'ID', 'pos', 'status' and 'lemmaId'.

=item fes 

A list containg all the frame elements for this frame. The frame elements are represented by a hash containing the keys 'name', 'ID', 'abbrev' and 'coreType'.

=back

=item related_frames ($FRAMENAME, $RELATIONNAME)

This method returns a list of frame names, that are related to $FRAMENAME via the relation $RELATIONNAME. 

=item related_inv_frames ($FRAMENAME, $RELATIONNAME) 

Does the same as L<related_frames ($FRAMENAME, $RELATIONNAME)>, but in the other direction of the relation. Using the relation "Inheritance", you can ask for the superordinated frames for example. 

=item related ( $FRAME1, $FRAME2 )

Checks, if $FRAME1 and $FRAME2 are somehow related. If they are related, the exact name of the relation is returned. Otherwise, a 0 (zero) is returned. Note, that this method is not transitive. 

=item transitive_related ( $FRAME1, $FRAME2 )

Checks, if $FRAME1 and $FRAME2 are somehow related. There is no limit on the maximum number of steps, so this method can be slow. And it will probably run forever, if a frame is related to itself. 

=item path_related ( $FRAME1, $FRAME2, @RELATIONS ) 

With this method, one can check if $FRAME1 and $FRAME2 are related through the given path. The path itself is a list of relations. The method tries to explore all the possiblities along the path, so it is also slow. 

=item frames ( )

Returns a list (NOT a reference to a list) of all frames that are defined in FrameNet. 

=item file_frames_xml ( $PATH ) 

Can be used to get and set the path to the file frames.xml. To get it, just use it without argument. 

=item file_frrelation_xml ( $PATH ) 

Can be used to get and set the path to the file frrelation.xml. To get, use it without argument. 

=item cache ( $cache )

En- or disables the cache. If $cache is defined, it is enabled. 
This method is experimental!

=item dumpout ( )

This method prints the entire object using Data::Dumper. Can be used to debug the class.

=item parse ( )

Internal method.

=item xparse ( )

Internal method.



=back

=head1 AUTHOR

Nils Reiter, C<< <reiter@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<reiter@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Nils Reiter and Aljoscha Burchardt, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FrameNet::QueryData
