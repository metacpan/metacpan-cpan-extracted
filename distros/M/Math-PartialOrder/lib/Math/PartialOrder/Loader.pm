# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder::Loader.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: Load QuD Hierarchies from files
#
###############################################################


package Math::PartialOrder::Loader;
use Math::PartialOrder::Base;
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw($_tr_name $_tr_parents $_tr_attrs);
%EXPORT_TAGS = (
		trvars => [qw($_tr_name $_tr_parents $_tr_attrs)],
	      );

our $VERSION = 0.01;
our $BIN_COMPAT = 0.01;
our ($_tr_name, $_tr_parents, $_tr_attrs) = (0..2);

our $PS_VIEWER = 'gv';
our @TMPFILES = qw();
our $UNLINK_TMPFILES = 1;

package Math::PartialOrder::Base;
use FileHandle;
eval "use Storable qw();";
eval "use GraphViz;";
eval "use File::Temp;";
Math::PartialOrder::Loader->import(q(:trvars));

###############################################################
# Constants
###############################################################
# None

###############################################################
# perl-load
###############################################################

# usage: add_perl_class($class,%opts);
# + options:
#   descend=>$bool
sub from_perl_isa {
  my ($h,$class,%opts) = @_;
  my %seen = ();
  $opts{descend} = 1 unless (defined($opts{descend}));
  if ($opts{descend}) {
    my @q = ($class);
    while (defined($class = shift(@q))) {
      next if (exists($seen{$class}));
      $seen{$class} = undef;
      $h->add($class, @{$class.'::ISA'});
      push(@q, grep { !exists($seen{$_}) } @{$class.'::ISA'});
    }
  } else {
    # just add this class
    $h->add($class,@{$class.'::ISA'});
  }
}


###############################################################
# Text-Load
###############################################################

#----------------------------------------------------------------------
# Public loading functions:
#   load($filename,\%opts)    => undef
#   load($FileHandle,\%opts)  => undef
#     + loads in hierarchy from $filename or $FileHandle,
#       wiping any existant data
# Private loading functions:
#   _load($FileHandle,\%opts)   => undef
#     + top-level do the work of loading
#----------------------------------------------------------------------
sub load {
  my $self = shift;
  my $file = shift;
  return $self->_load($file,@_) if (ref($file));

  my $handle = FileHandle->new("<$file");
  croak("open failed for `$file': $!") unless (defined($handle));
  my $rv = $self->_load($handle, @_);
  $handle->close();
  return $rv;
}

sub _load {
  my ($h,$fh,$args) = @_;
  $args = {} unless (defined($args));

  # actual loading
  my ($gtline,$subx,$sub,$super,@supers,%subattrs,$attref);
  $args->{gtsep} = '>' unless (defined($args->{gtsep}));
  # read in the hierarchy
  while ($gtline = <$fh>) {
    chomp($gtline);
    if ($gtline =~ /^\s*root\s*=\s*(.*)/i && $1 ne $h->root) {
      $h->replace($h->root,$1);
      next;
    }
    next unless ($gtline !~ /^\s*\#/ && $gtline !~ /^\s*$/);
    ($subx, $super) = split(/\s+(?:$args->{gtsep})\s+/, $gtline);

    ($sub, %subattrs) = split(/\s*[\[\]:,]\s*/, $subx);
    $sub =~ s/^\s*(\S+)/$1/;
    if (defined($super)) {
      $super =~ s/^(\S+)\s*/$1/;
      @supers = split(/\s*,\s*/, $super);
    } else {
      @supers = qw();
    }

    if (!$h->has_type($sub)) { # We found a new subtype...
      $h->add($sub, @supers);
    }
    else {
      # subtype already defined -- add/override attributes
      $attref = $h->_attributes($sub);
    }

    # now, set the attributes
    if (%subattrs) {
      $attref = $h->_attributes($sub) || {};
      %$attref = (%$attref, %subattrs);
      $h->_attributes($sub, $attref);
    }

    if (@supers) { # HACK!
      $h->move($sub, @supers);
    }
    #elsif (! grep { $_ eq $sub } $h->root()) {
    #  warn("Undefined supertype ",
	#   (defined($super) ? "'$super'" : ''),
	#   " for subtype '$sub' during text load.\n");
    #}
  }
  return $h;
}


##############################################################
# Text-Save
###############################################################

#----------------------------------------------------------------------
# Public saving functions:
#   save($filename)   => undef
#   save($FileHandle) => undef
# Private saving functions:
#   _save($FileHandle) => undef
#----------------------------------------------------------------------
sub save {
  my $self = shift;
  my $file = shift;
  return $self->_save($file,@_) if (ref($file));

  my $handle = FileHandle->new(">$file");
  croak("open failed for `$file': $!") unless (defined($handle));
  $self->_save($handle,@_);
  $handle->close();
}

sub _save {
  my ($h,$fh,$args) = @_;
  $args = {} unless (defined($args));

  # actual save
  my ($sub,@supers,$super,$attrs);
  print $fh ("# Save-file auto-generated by ", __PACKAGE__ , "::save\n",
	     "#   Hierarchy Class   = ", ref($h) || $h, "\n",
	     "#   Hierarchy Version = ", $h->VERSION, "\n",
	     "#   Loader Version    = ", Math::PartialOrder::Loader->VERSION, "\n",
	     "ROOT=",$h->root,"\n");

  foreach $sub ($h->types) {
    @supers = $h->parents($sub);
    $attrs = $h->_attributes($sub);
    print $fh ("$sub [",
	       (defined($attrs)
		? join(',', map { "$_:$attrs->{$_}" } keys(%$attrs))
	        : qw()),
	       "]",
	       $sub ne $h->root && @supers ?
	       (
		"\t >\t ",
		join(',',
		     grep {
		       defined($_) && $h->has_type($_)
		     } @supers)
	       ) : qw(),
	       "\n");
  }
  return $h;
}



##############################################################
# Visualization
###############################################################
sub graphviz {
  my ($h,%opts) = @_;
  $opts{nodelabel} = ":NAME:\n:ATTRIBUTES:" unless (exists($opts{nodelabel}));
  $opts{label_node} = \&_gv_label_node unless (exists($opts{label_node}));

  my $g = GraphViz->new(directed => 1,
			rankdir => 0,  # top->bottom linking
			node => {
				 shape => 'plaintext',
				},
			edge => {
				 dir => 'none',
				},
			%opts);
  my ($type,$parent,$label);

  # add nodes
  foreach $type ($h->types) {
    if (ref($opts{label_node}) && ref($opts{label_node}) eq 'CODE') {
      $label = &{$opts{label_node}}($h,$type,\%opts);
    } else {
      $label = "$type";
    }
    $g->add_node($type, label => $label);
  }

  # add edges
  foreach $type ($h->types) {
    foreach $parent ($h->parents($type)) {
      $g->add_edge($type, $parent);
    }
  }
  return $g;
}

# label_node callback($h,$t,$opts)
sub _gv_label_node {
  my ($h,$type,$opts) = @_;
  my ($label);
  if ($h->can('get_appr_bytype')) {
    # we have Approp
    $label = "$type";
    my $appr = $h->get_appr_bytype($type);
    my ($f);
    foreach $f (keys(%$appr)) {
      $label .= "\n$f:$appr->{$f}";
    }
  } else {
    # default labelling (hack)
    my $attrs = $h->_attributes($type);
    my $attrstr = join("\n", map { "$_:" . $attrs->{$_} } keys(%$attrs));
    $label = $opts->{nodelabel};
    $label =~ s/:NAME:/$type/;
    $label =~ s/:ATTRIBUTES:/$attrstr/;
  }
  return $label;
}

###############################################################
# Viewing Utility
###############################################################
*gv = \&viewps;
sub viewps {
  my $h = shift;
  my ($fh,$filename) = File::Temp::tempfile('hiXXXXXX', SUFFIX => '.ps');
  $fh->print($h->graphviz->as_ps);
  close($fh);
  system("$Math::PartialOrder::Loader::PS_VIEWER \"$filename\" &");
  if ($Math::PartialOrder::Loader::UNLINK_TMPFILES) {
    push(@Math::PartialOrder::Loader::TMPFILES,$filename);
    sleep(1);
  }
}

##############################################################
# Binary store/retrieve
###############################################################

# $h->store($file)
sub store {
  my ($h,$file) = @_;

  my $handle = ref($file) ? $file : FileHandle->new(">$file");
  croak("open failed for file `$file': $!") unless (defined($handle));

  my $storeme = $h->_store;
  Storable::store_fd($storeme->{Head}, $handle); # store headers first
  delete($storeme->{Head});                      # ... and only once
  Storable::store_fd($storeme, $handle);

  $handle->close() unless (ref($file));
  return $h;
}
# $h->nstore($file)
sub nstore {
  my ($h,$file) = @_;

  my $handle = ref($file) ? $file : FileHandle->new(">$file");
  croak("open failed for file `$file': $!") unless (defined($handle));

  my $storeme = $h->_store;
  Storable::nstore_fd($storeme->{Head}, $handle); # store headers first
  delete($storeme->{Head});                       # ... and only once
  Storable::nstore_fd($storeme, $handle);

  $handle->close() unless (ref($file));
  return $h;
}
# $h->retrieve($file)
sub retrieve {
  my $h = shift;
  my $file = shift;

  my $handle = ref($file) ? $file : FileHandle->new("<$file");
  croak("open failed for file `$file': $!") unless (defined($handle));

  # get and check headers
  my $head = Storable::retrieve_fd($handle);
  unless (defined($h->_retrieve_head($head))) {
    carp("Error: retrieve($file) failed for hierarchy of class `", ref($h) || $h, "'");
    return $h;
  }

  # do the retrieval
  my $retr = Storable::retrieve_fd($handle);
  $retr->{Head} = $head;
  my $rv = $h->_retrieve($retr);

  # and clean things up
  $handle->close() unless (ref($file));
  return $rv;
}


##############################################################
# In-Memory Store/Retrieve
###############################################################

# $frozen = $h->freeze();
sub freeze { return Storable::freeze($_[0]->_store); }

# $h->thaw($frozen);
sub thaw { return $_[0]->_retrieve(Storable::thaw($_[1])); }



#--------------------------------------------------------------
# Storage: $h->_store() => $Ref_To_Store
# + hooks:
#    _store_before(\%storeme),
#    _store_type(\@typerec,\%storeme)
#    _store_after(\%storeme)

#--------------------------------------------------------------
# $headers = $h->_store_head(),
# $headers = $class->_store_head()
sub _store_head {
  my $h = shift;
  return
    {
     Class => ref($h) || $h,
     Cversion => $h->VERSION,
     Ccompat => $h->_get_bin_compat,
     Hstring => "$h",
     Lversion => $Math::PartialOrder::Loader::VERSION,
     Lcompat => $Math::PartialOrder::Loader::BIN_COMPAT
    };
}

#--------------------------------------------------------------
sub _store {
  my $h = shift;
  my $class = ref($h) || $h;
  my $head = $h->_store_head();
  my $refs = { "$h" => $h->_hattributes };
  my $trs = [];
  my $storeme = { Head => $head,
		  Refs => $refs,
		  Types => $trs };

  # preliminary storage-hook
  $h->_store_before($storeme) if ($h->can('_store_before'));

  my ($tr,$attrs);
  foreach ($h->types) {
    # update nested refs
    $refs->{$_} = $_;
    $attrs = $h->_attributes($_);
    $refs->{$attrs} = $attrs if (defined($attrs));

    # create the type-record
    $tr = [
	   "$_", # name
	   [ map { "$_" } $h->parents($_) ], # parents
	   defined($attrs)
	     ? "$attrs" # attrs | undef
	     : undef
	  ];

    # type-storage hook
    $h->_store_type($tr,$storeme) if ($h->can('_store_type'));

    push(@{$trs}, $tr);
  }

  # post-processing hook
  $h->_store_after($storeme) if ($h->can('_store_after'));

  return $storeme;
}

#--------------------------------------------------------------
# + \%tostore|\%retrieved format:
#         { Head  => \%Headers,
#           Refs  => \%RefsByString,
#           Types => \@TypeRecs, ... }
#
# + \%Headers format:
#         { Class => $ClassName,
#           Cversion => $ClassVersion,
#           Hstring => "$HierarchyAsString",
#           Lversion => $LoaderVersion,
#           Lcompat  => $MinLoaderVersion }
#
# + \%RefsByString format: { "$OldStringVal" => $Reference }
# + \@TypeRecs format: [ \@TypeRec1, ..., \@TypeRecN ]
# + \@TypeRec format: [ "$TypeName", \@ParentsNames, "$AttrsName" ]
#--------------------------------------------------------------


#--------------------------------------------------------------
# Compatibility
#--------------------------------------------------------------
sub _is_bin_compat { return undef; } # just a dummy
sub _get_bin_compat { return {}; } # just a dummy


#--------------------------------------------------------------
# Retrieval: $h->_retrieve(\%retrieved) => $h
# + hooks:
#    _retrieve_before(\%storeme),
#    _retrieve_type_before(\@typerec,\%storeme)
#    _retrieve_type(\@typerec,\%storeme)
#    _retrieve_type_after(\@typerec,\%storeme)
#    _retrieve_after(\%storeme)
#
sub _retrieve {
  my ($h,$retr) = @_;
  my ($compat);

  # can we do this?
  unless (defined($compat = $h->_retrieve_head($retr->{Head}))) {
    carp("Error: _retrieve() failed for hierarchy of class `", ref($h) || $h, "'");
    return $h;
  }

  # get the hierarchy attributes...
  $h->_hattributes($retr->{Refs}{$retr->{Head}{Hstring}});

  # preliminary retrieval
  $h->_retrieve_before($retr) if ($compat && $h->can('_retrieve_before'));

  # get the types
  my $typerecs = $retr->{Types};
  my ($tr);
  foreach $tr (@$typerecs) {
    # preliminary type-retrieval
    $h->_retrieve_type_before($tr,$retr) if ($compat && $h->can('_retrieve_type_before'));

    # get the actual type
    if ($compat && $h->can('_retrieve_type')) {
      # override
      $h->_retrieve_type($tr,$retr);
    } else {
      # defaults
      _retrieve_type($h,$tr,$retr);
    }

    # postprocessing
    $h->_retrieve_type_after($tr,$retr) if ($compat && $h->can('_retrieve_type_after'));
  }

  $h->_retrieve_after($retr) if ($compat && $h->can('_retrieve_after'));
  return $h;
}


# $h->_retrieve_type($rec,$retr)
# $retr = { Head => \@Hdrs, Types => \@TypeRecs, Refs => \%Refs }
# $tr = [ $Name, \@Parents, $AttrsName ]
sub _retrieve_type {
  $_[0]->add($_[2]->{Refs}{$_[1]->[$_tr_name]},
	     @{$_[2]->{Refs}}{@{$_[1]->[$_tr_parents]}});
  $_[0]->_attributes
    ($_[2]->{Refs}{$_[1]->[$_tr_name]},
     $_[2]->{Refs}{$_[1]->[$_tr_attrs]}) if (defined($_[1]->[$_tr_attrs]));
}

# $bool_or_undef = $h->_retrieve_head($head)
sub _retrieve_head {
  my ($h,$head) = @_;
  my ($class,$compat);

  # check reftype & existence
  unless (ref($head) && ref($head) eq 'HASH') {
    carp("Warning: non-hashref '$head' cannot be header");
    return undef;
  }

  # does the stored hierarchy have a version?
  if (!defined($head->{Lversion})) {
    carp("Warning: stored hierarchy has no Lversion");
    return undef;
  }

  # does the stored hierarchy have a version?
  if (!defined($head->{Lcompat})) {
    carp("Warning: stored hierarchy has no Lcompat");
    return undef;
  }

  # does the stored hierarchy have a hierarchy-string?
  if (!defined($head->{Hstring})) {
    carp("Warning: stored hierarchy has no Hstring");
    return undef;
  }

  # is the storage-routine too old?
  if ($head->{Lversion} < $Math::PartialOrder::Loader::BIN_COMPAT) {
    carp("Warning: obsolete Math::PartialOrder::Loader stored hierarchy\n",
	 " >   stored version  = $head->{Lversion}\n",
	 " > required version >= $Math::PartialOrder::Loader::BIN_COMPAT\n",
	 " >");
    return undef;
  }

  # is this load-routine too old?
  if ($Math::PartialOrder::Loader::VERSION < $head->{Lcompat}) {
    carp("Warning: obsolete Math::PartialOrder::Loader retrieval routine\n",
	 " >     this version  = $Math::PartialOrder::Loader::VERSION\n",
	 " > required version >= $head->{Lcompat}\n",
	 " >");
    return undef;
  }

  # do we have class?
  if (!defined($head->{Class})) {
    carp("Warning: stored hierarchy has no Class!");
    return 0;
  }

  # do we have class-version?
  if (!defined($head->{Cversion})) {
    carp("Warning: stored hierarchy has no Cversion");
    return 0;
  }

  # is the stored hierarchy the same class & version as the caller?
  if (defined($class = (ref($h)||$h))
	 && $head->{Class} eq $class
	 && $head->{Cversion} == $h->VERSION)
    {
      return 1; # whew.
    }

  # does the stored thingy have compatibility hash?
  if (!defined($head->{Ccompat})) {
    carp("Warning: stored hierarchy has no Ccompat");
    return 0;
  }

  # the stored hierarchy knows something about us, too...
  if (defined($head->{Ccompat}{$class})) {
    if ($head->{Ccompat}{$class} > $h->VERSION) {
      carp("Warning: binary-incompatible hierarchy package detected\n",
	   " >        this class = `$class'\n",
	   " >      stored class = `$head->{Class}'\n",
	   " >      this version = ", $class->VERSION, "\n",
	   " > required version >= $head->{Ccompat}{$class}\n",
	   " > (maybe it's time to update?)");
      return 0;
    }
  }

  # finally, lookup in the retrieving hierarchy
  if (defined($compat = $h->_get_bin_compat) 
      && defined($compat->{$head->{Class}})) {
    if ($compat->{$head->{Class}} > $head->{Cversion})
      {
	# just issue a warning
	carp("Warning: binary-incompatible stored hierarchy detected\n",
	     " >     stored class  = `$head->{Class}'\n",
	     " >       this class  = `$class'\n",
	     " >   stored version  = $head->{Cversion}\n",
	     " > required version >= $compat->{$head->{Class}}\n",
	     " > (maybe it's time to recompile?)");
	return 0;
      }
    return 1;
  }

  # use the defaults
  return 0;
}


END {
  unlink(@Math::PartialOrder::Loader::TMPFILES) if
    ($Math::PartialOrder::Loader::UNLINK_TMPFILES);
}

1;
__END__
