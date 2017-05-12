#line 1
package HTML::Template;

$HTML::Template::VERSION = '2.9';

#line 370

#line 907


use integer; # no floating point math so far!
use strict; # and no funny business, either.

use Carp; # generate better errors with more context
use File::Spec; # generate paths that work on all platforms
use Digest::MD5 qw(md5_hex); # generate cache keys
use Scalar::Util qw(tainted);

# define accessor constants used to improve readability of array
# accesses into "objects".  I used to use 'use constant' but that
# seems to cause occasional irritating warnings in older Perls.
package HTML::Template::LOOP;
sub TEMPLATE_HASH () { 0 };
sub PARAM_SET     () { 1 };

package HTML::Template::COND;
sub VARIABLE           () { 0 };
sub VARIABLE_TYPE      () { 1 };
sub VARIABLE_TYPE_VAR  () { 0 };
sub VARIABLE_TYPE_LOOP () { 1 };
sub JUMP_IF_TRUE       () { 2 };
sub JUMP_ADDRESS       () { 3 };
sub WHICH              () { 4 };
sub UNCONDITIONAL_JUMP () { 5 };
sub IS_ELSE            () { 6 };
sub WHICH_IF           () { 0 };
sub WHICH_UNLESS       () { 1 };

# back to the main package scope.
package HTML::Template;

# open a new template and return an object handle
sub new {
  my $pkg = shift;
  my $self; { my %hash; $self = bless(\%hash, $pkg); }

  # the options hash
  my $options = {};
  $self->{options} = $options;

  # set default parameters in options hash
  %$options = (
               debug => 0,
               stack_debug => 0,
               timing => 0,
               search_path_on_include => 0,
               cache => 0,               
               blind_cache => 0,
	       file_cache => 0,
	       file_cache_dir => '',
	       file_cache_dir_mode => 0700,
	       force_untaint => 0,
               cache_debug => 0,
               shared_cache_debug => 0,
               memory_debug => 0,
               die_on_bad_params => 1,
               vanguard_compatibility_mode => 0,
               associate => [],
               path => [],
               strict => 1,
               loop_context_vars => 0,
               max_includes => 10,
               shared_cache => 0,
               double_cache => 0,
               double_file_cache => 0,
               ipc_key => 'TMPL',
               ipc_mode => 0666,
               ipc_segment_size => 65536,
               ipc_max_size => 0,
               global_vars => 0,
               no_includes => 0,
               case_sensitive => 0,
               filter => [],
              );
  
  # load in options supplied to new()
  $options = _load_supplied_options( [@_], $options);

  # blind_cache = 1 implies cache = 1
  $options->{blind_cache} and $options->{cache} = 1;

  # shared_cache = 1 implies cache = 1
  $options->{shared_cache} and $options->{cache} = 1;

  # file_cache = 1 implies cache = 1
  $options->{file_cache} and $options->{cache} = 1;

  # double_cache is a combination of shared_cache and cache.
  $options->{double_cache} and $options->{cache} = 1;
  $options->{double_cache} and $options->{shared_cache} = 1;

  # double_file_cache is a combination of file_cache and cache.
  $options->{double_file_cache} and $options->{cache} = 1;
  $options->{double_file_cache} and $options->{file_cache} = 1;

  # vanguard_compatibility_mode implies die_on_bad_params = 0
  $options->{vanguard_compatibility_mode} and 
    $options->{die_on_bad_params} = 0;

  # handle the "type", "source" parameter format (does anyone use it?)
  if (exists($options->{type})) {
    exists($options->{source}) or croak("HTML::Template->new() called with 'type' parameter set, but no 'source'!");
    ($options->{type} eq 'filename' or $options->{type} eq 'scalarref' or
     $options->{type} eq 'arrayref' or $options->{type} eq 'filehandle') or
       croak("HTML::Template->new() : type parameter must be set to 'filename', 'arrayref', 'scalarref' or 'filehandle'!");

    $options->{$options->{type}} = $options->{source};
    delete $options->{type};
    delete $options->{source};
  }

  # make sure taint mode is on if force_untaint flag is set
  if ($options->{force_untaint} && ! ${^TAINT}) {
    croak("HTML::Template->new() : 'force_untaint' option set but perl does not run in taint mode!");
  }

  # associate should be an array of one element if it's not
  # already an array.
  if (ref($options->{associate}) ne 'ARRAY') {
    $options->{associate} = [ $options->{associate} ];
  }

  # path should be an array if it's not already
  if (ref($options->{path}) ne 'ARRAY') {
    $options->{path} = [ $options->{path} ];
  }

  # filter should be an array if it's not already
  if (ref($options->{filter}) ne 'ARRAY') {
    $options->{filter} = [ $options->{filter} ];
  }
  
  # make sure objects in associate area support param()
  foreach my $object (@{$options->{associate}}) {
    defined($object->can('param')) or
      croak("HTML::Template->new called with associate option, containing object of type " . ref($object) . " which lacks a param() method!");
  } 

  # check for syntax errors:
  my $source_count = 0;
  exists($options->{filename}) and $source_count++;
  exists($options->{filehandle}) and $source_count++;
  exists($options->{arrayref}) and $source_count++;
  exists($options->{scalarref}) and $source_count++;
  if ($source_count != 1) {
    croak("HTML::Template->new called with multiple (or no) template sources specified!  A valid call to new() has exactly one filename => 'file' OR exactly one scalarref => \\\$scalar OR exactly one arrayref => \\\@array OR exactly one filehandle => \*FH");
  }

  # check that cache options are not used with non-cacheable templates
  croak "Cannot have caching when template source is not file"
    if grep { exists($options->{$_}) } qw( filehandle arrayref scalarref)
      and 
       grep {$options->{$_}} qw( cache blind_cache file_cache shared_cache 
                                 double_cache double_file_cache );
    
  # check that filenames aren't empty
  if (exists($options->{filename})) {
      croak("HTML::Template->new called with empty filename parameter!")
        unless length $options->{filename};
  }

  # do some memory debugging - this is best started as early as possible
  if ($options->{memory_debug}) {
    # memory_debug needs GTop
    eval { require GTop; };
    croak("Could not load GTop.  You must have GTop installed to use HTML::Template in memory_debug mode.  The error was: $@")
      if ($@);
    $self->{gtop} = GTop->new();
    $self->{proc_mem} = $self->{gtop}->proc_mem($$);
    print STDERR "\n### HTML::Template Memory Debug ### START ", $self->{proc_mem}->size(), "\n";
  }

  if ($options->{file_cache}) {
    # make sure we have a file_cache_dir option
    croak("You must specify the file_cache_dir option if you want to use file_cache.") 
      unless length $options->{file_cache_dir};


    # file_cache needs some extra modules loaded
    eval { require Storable; };
    croak("Could not load Storable.  You must have Storable installed to use HTML::Template in file_cache mode.  The error was: $@")
      if ($@);
  }

  if ($options->{shared_cache}) {
    # shared_cache needs some extra modules loaded
    eval { require IPC::SharedCache; };
    croak("Could not load IPC::SharedCache.  You must have IPC::SharedCache installed to use HTML::Template in shared_cache mode.  The error was: $@")
      if ($@);

    # initialize the shared cache
    my %cache;
    tie %cache, 'IPC::SharedCache',
      ipc_key => $options->{ipc_key},
      load_callback => [\&_load_shared_cache, $self],
      validate_callback => [\&_validate_shared_cache, $self],
      debug => $options->{shared_cache_debug},
      ipc_mode => $options->{ipc_mode},
      max_size => $options->{ipc_max_size},
      ipc_segment_size => $options->{ipc_segment_size};
    $self->{cache} = \%cache;
  }

  if ($options->{default_escape}) {
    $options->{default_escape} = uc $options->{default_escape};
    unless ($options->{default_escape} =~ /^(HTML|URL|JS)$/) {
      croak("HTML::Template->new(): Invalid setting for default_escape - '$options->{default_escape}'.  Valid values are HTML, URL or JS.");
    }
  }

  print STDERR "### HTML::Template Memory Debug ### POST CACHE INIT ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};

  # initialize data structures
  $self->_init;
  
  print STDERR "### HTML::Template Memory Debug ### POST _INIT CALL ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};
  
  # drop the shared cache - leaving out this step results in the
  # template object evading garbage collection since the callbacks in
  # the shared cache tie hold references to $self!  This was not easy
  # to find, by the way.
  delete $self->{cache} if $options->{shared_cache};

  return $self;
}

sub _load_supplied_options {
    my $argsref = shift;
    my $options = shift;
    for (my $x = 0; $x < @{$argsref}; $x += 2) {
      defined(${$argsref}[($x + 1)]) or croak(
        "HTML::Template->new() called with odd number of option parameters - should be of the form option => value");
      $options->{lc(${$argsref}[$x])} = ${$argsref}[($x + 1)]; 
    }
    return $options;
}

# an internally used new that receives its parse_stack and param_map as input
sub _new_from_loop {
  my $pkg = shift;
  my $self; { my %hash; $self = bless(\%hash, $pkg); }

  # the options hash
  my $options = {};
  $self->{options} = $options;

  # set default parameters in options hash - a subset of the options
  # valid in a normal new().  Since _new_from_loop never calls _init,
  # many options have no relevance.
  %$options = (
               debug => 0,
               stack_debug => 0,
               die_on_bad_params => 1,
               associate => [],
               loop_context_vars => 0,
              );
  
  # load in options supplied to new()
  $options = _load_supplied_options( [@_], $options);

  $self->{param_map} = $options->{param_map};
  $self->{parse_stack} = $options->{parse_stack};
  delete($options->{param_map});
  delete($options->{parse_stack});

  return $self;
}

# a few shortcuts to new(), of possible use...
sub new_file {
  my $pkg = shift; return $pkg->new('filename', @_);
}
sub new_filehandle {
  my $pkg = shift; return $pkg->new('filehandle', @_);
}
sub new_array_ref {
  my $pkg = shift; return $pkg->new('arrayref', @_);
}
sub new_scalar_ref {
  my $pkg = shift; return $pkg->new('scalarref', @_);
}

# initializes all the object data structures, either from cache or by
# calling the appropriate routines.
sub _init {
  my $self = shift;
  my $options = $self->{options};

  if ($options->{double_cache}) {
    # try the normal cache, return if we have it.
    $self->_fetch_from_cache();
    return if (defined $self->{param_map} and defined $self->{parse_stack});

    # try the shared cache
    $self->_fetch_from_shared_cache();

    # put it in the local cache if we got it.
    $self->_commit_to_cache()
      if (defined $self->{param_map} and defined $self->{parse_stack});
  } elsif ($options->{double_file_cache}) {
    # try the normal cache, return if we have it.
    $self->_fetch_from_cache();
    return if (defined $self->{param_map});

    # try the file cache
    $self->_fetch_from_file_cache();

    # put it in the local cache if we got it.
    $self->_commit_to_cache()
      if (defined $self->{param_map});
  } elsif ($options->{shared_cache}) {
    # try the shared cache
    $self->_fetch_from_shared_cache();
  } elsif ($options->{file_cache}) {
    # try the file cache
    $self->_fetch_from_file_cache();
  } elsif ($options->{cache}) {
    # try the normal cache
    $self->_fetch_from_cache();
  }
  
  # if we got a cache hit, return
  return if (defined $self->{param_map});

  # if we're here, then we didn't get a cached copy, so do a full
  # init.
  $self->_init_template();
  $self->_parse();

  # now that we have a full init, cache the structures if cacheing is
  # on.  shared cache is already cool.
  if($options->{file_cache}){
    $self->_commit_to_file_cache();
  }
  $self->_commit_to_cache() if (
         ($options->{cache} 
            and not $options->{shared_cache} 
            and not $options->{file_cache}
         ) 
      or ($options->{double_cache}) 
      or ($options->{double_file_cache})
    );
}

# Caching subroutines - they handle getting and validating cache
# records from either the in-memory or shared caches.

# handles the normal in memory cache
use vars qw( %CACHE );
sub _fetch_from_cache {
  my $self = shift;
  my $options = $self->{options};

  # return if there's no file here
  my $filepath = $self->_find_file($options->{filename});
  return unless (defined($filepath));
  $options->{filepath} = $filepath;

  # return if there's no cache entry for this key
  my $key = $self->_cache_key();
  return unless exists($CACHE{$key});  
  
  # validate the cache
  my $mtime = $self->_mtime($filepath);  
  if (defined $mtime) {
    # return if the mtime doesn't match the cache
    if (defined($CACHE{$key}{mtime}) and 
        ($mtime != $CACHE{$key}{mtime})) {
      $options->{cache_debug} and 
        print STDERR "CACHE MISS : $filepath : $mtime\n";
      return;
    }

    # if the template has includes, check each included file's mtime
    # and return if different
    if (exists($CACHE{$key}{included_mtimes})) {
      foreach my $filename (keys %{$CACHE{$key}{included_mtimes}}) {
        next unless 
          defined($CACHE{$key}{included_mtimes}{$filename});
        
        my $included_mtime = (stat($filename))[9];
        if ($included_mtime != $CACHE{$key}{included_mtimes}{$filename}) {
          $options->{cache_debug} and 
            print STDERR "### HTML::Template Cache Debug ### CACHE MISS : $filepath : INCLUDE $filename : $included_mtime\n";
          
          return;
        }
      }
    }
  }

  # got a cache hit!
  
  $options->{cache_debug} and print STDERR "### HTML::Template Cache Debug ### CACHE HIT : $filepath => $key\n";
      
  $self->{param_map} = $CACHE{$key}{param_map};
  $self->{parse_stack} = $CACHE{$key}{parse_stack};
  exists($CACHE{$key}{included_mtimes}) and
    $self->{included_mtimes} = $CACHE{$key}{included_mtimes};

  # clear out values from param_map from last run
  $self->_normalize_options();
  $self->clear_params();
}

sub _commit_to_cache {
  my $self     = shift;
  my $options  = $self->{options};
  my $key      = $self->_cache_key();
  my $filepath = $options->{filepath};

  $options->{cache_debug} and print STDERR "### HTML::Template Cache Debug ### CACHE LOAD : $filepath => $key\n";
    
  $options->{blind_cache} or
    $CACHE{$key}{mtime} = $self->_mtime($filepath);
  $CACHE{$key}{param_map} = $self->{param_map};
  $CACHE{$key}{parse_stack} = $self->{parse_stack};
  exists($self->{included_mtimes}) and
    $CACHE{$key}{included_mtimes} = $self->{included_mtimes};
}

# create a cache key from a template object.  The cache key includes
# the full path to the template and options which affect template
# loading.  Has the side-effect of loading $self->{options}{filepath}
sub _cache_key {
    my $self = shift;
    my $options = $self->{options};

    # assemble pieces of the key
    my @key = ($options->{filepath});
    push(@key, @{$options->{path}});
    push(@key, $options->{search_path_on_include} || 0);
    push(@key, $options->{loop_context_vars} || 0);
    push(@key, $options->{global_vars} || 0);

    # compute the md5 and return it
    return md5_hex(@key);
}

# generates MD5 from filepath to determine filename for cache file
sub _get_cache_filename {
  my ($self, $filepath) = @_;

  # get a cache key
  $self->{options}{filepath} = $filepath;
  my $hash = $self->_cache_key();
  
  # ... and build a path out of it.  Using the first two charcters
  # gives us 255 buckets.  This means you can have 255,000 templates
  # in the cache before any one directory gets over a few thousand
  # files in it.  That's probably pretty good for this planet.  If not
  # then it should be configurable.
  if (wantarray) {
    return (substr($hash,0,2), substr($hash,2))
  } else {
    return File::Spec->join($self->{options}{file_cache_dir}, 
                            substr($hash,0,2), substr($hash,2));
  }
}

# handles the file cache
sub _fetch_from_file_cache {
  my $self = shift;
  my $options = $self->{options};
  
  # return if there's no cache entry for this filename
  my $filepath = $self->_find_file($options->{filename});
  return unless defined $filepath;
  my $cache_filename = $self->_get_cache_filename($filepath);
  return unless -e $cache_filename;
  
  eval {
    $self->{record} = Storable::lock_retrieve($cache_filename);
  };
  croak("HTML::Template::new() - Problem reading cache file $cache_filename (file_cache => 1) : $@")
    if $@;
  croak("HTML::Template::new() - Problem reading cache file $cache_filename (file_cache => 1) : $!") 
    unless defined $self->{record};

  ($self->{mtime}, 
   $self->{included_mtimes}, 
   $self->{param_map}, 
   $self->{parse_stack}) = @{$self->{record}};
  
  $options->{filepath} = $filepath;

  # validate the cache
  my $mtime = $self->_mtime($filepath);
  if (defined $mtime) {
    # return if the mtime doesn't match the cache
    if (defined($self->{mtime}) and 
        ($mtime != $self->{mtime})) {
      $options->{cache_debug} and 
        print STDERR "### HTML::Template Cache Debug ### FILE CACHE MISS : $filepath : $mtime\n";
      ($self->{mtime}, 
       $self->{included_mtimes}, 
       $self->{param_map}, 
       $self->{parse_stack}) = (undef, undef, undef, undef);
      return;
    }

    # if the template has includes, check each included file's mtime
    # and return if different
    if (exists($self->{included_mtimes})) {
      foreach my $filename (keys %{$self->{included_mtimes}}) {
        next unless 
          defined($self->{included_mtimes}{$filename});
        
        my $included_mtime = (stat($filename))[9];
        if ($included_mtime != $self->{included_mtimes}{$filename}) {
          $options->{cache_debug} and 
            print STDERR "### HTML::Template Cache Debug ### FILE CACHE MISS : $filepath : INCLUDE $filename : $included_mtime\n";
          ($self->{mtime}, 
           $self->{included_mtimes}, 
           $self->{param_map}, 
           $self->{parse_stack}) = (undef, undef, undef, undef);
          return;
        }
      }
    }
  }

  # got a cache hit!
  $options->{cache_debug} and print STDERR "### HTML::Template Cache Debug ### FILE CACHE HIT : $filepath\n";

  # clear out values from param_map from last run
  $self->_normalize_options();
  $self->clear_params();
}

sub _commit_to_file_cache {
  my $self = shift;
  my $options = $self->{options};

  my $filepath = $options->{filepath};
  if (not defined $filepath) {
    $filepath = $self->_find_file($options->{filename});
    confess("HTML::Template->new() : Cannot open included file $options->{filename} : file not found.")
      unless defined($filepath);
    $options->{filepath} = $filepath;   
  }

  my ($cache_dir, $cache_file) = $self->_get_cache_filename($filepath);  
  $cache_dir = File::Spec->join($options->{file_cache_dir}, $cache_dir);
  if (not -d $cache_dir) {
    if (not -d $options->{file_cache_dir}) {
      mkdir($options->{file_cache_dir},$options->{file_cache_dir_mode})
	or croak("HTML::Template->new() : can't mkdir $options->{file_cache_dir} (file_cache => 1): $!");
    }
    mkdir($cache_dir,$options->{file_cache_dir_mode})
      or croak("HTML::Template->new() : can't mkdir $cache_dir (file_cache => 1): $!");
  }

  $options->{cache_debug} and print STDERR "### HTML::Template Cache Debug ### FILE CACHE LOAD : $options->{filepath}\n";

  my $result;
  eval {
    $result = Storable::lock_store([ $self->{mtime},
                                     $self->{included_mtimes}, 
                                     $self->{param_map}, 
                                     $self->{parse_stack} ],
                                   scalar File::Spec->join($cache_dir, $cache_file)
                                  );
  };
  croak("HTML::Template::new() - Problem writing cache file $cache_dir/$cache_file (file_cache => 1) : $@")
    if $@;
  croak("HTML::Template::new() - Problem writing cache file $cache_dir/$cache_file (file_cache => 1) : $!")
    unless defined $result;
}

# Shared cache routines.
sub _fetch_from_shared_cache {
  my $self = shift;
  my $options = $self->{options};

  my $filepath = $self->_find_file($options->{filename});
  return unless defined $filepath;

  # fetch from the shared cache.
  $self->{record} = $self->{cache}{$filepath};
  
  ($self->{mtime}, 
   $self->{included_mtimes}, 
   $self->{param_map}, 
   $self->{parse_stack}) = @{$self->{record}}
     if defined($self->{record});
  
  $options->{cache_debug} and defined($self->{record}) and print STDERR "### HTML::Template Cache Debug ### CACHE HIT : $filepath\n";
  # clear out values from param_map from last run
  $self->_normalize_options(), $self->clear_params()
    if (defined($self->{record}));
  delete($self->{record});

  return $self;
}

sub _validate_shared_cache {
  my ($self, $filename, $record) = @_;
  my $options = $self->{options};

  $options->{shared_cache_debug} and print STDERR "### HTML::Template Cache Debug ### SHARED CACHE VALIDATE : $filename\n";

  return 1 if $options->{blind_cache};

  my ($c_mtime, $included_mtimes, $param_map, $parse_stack) = @$record;

  # if the modification time has changed return false
  my $mtime = $self->_mtime($filename);
  if (defined $mtime and defined $c_mtime
      and $mtime != $c_mtime) {
    $options->{cache_debug} and 
      print STDERR "### HTML::Template Cache Debug ### SHARED CACHE MISS : $filename : $mtime\n";
    return 0;
  }

  # if the template has includes, check each included file's mtime
  # and return false if different
  if (defined $mtime and defined $included_mtimes) {
    foreach my $fname (keys %$included_mtimes) {
      next unless defined($included_mtimes->{$fname});
      if ($included_mtimes->{$fname} != (stat($fname))[9]) {
        $options->{cache_debug} and 
          print STDERR "### HTML::Template Cache Debug ### SHARED CACHE MISS : $filename : INCLUDE $fname\n";
        return 0;
      }
    }
  }

  # all done - return true
  return 1;
}

sub _load_shared_cache {
  my ($self, $filename) = @_;
  my $options = $self->{options};
  my $cache = $self->{cache};
  
  $self->_init_template();
  $self->_parse();

  $options->{cache_debug} and print STDERR "### HTML::Template Cache Debug ### SHARED CACHE LOAD : $options->{filepath}\n";
  
  print STDERR "### HTML::Template Memory Debug ### END CACHE LOAD ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};

  return [ $self->{mtime},
           $self->{included_mtimes}, 
           $self->{param_map}, 
           $self->{parse_stack} ]; 
}

# utility function - given a filename performs documented search and
# returns a full path or undef if the file cannot be found.
sub _find_file {
  my ($self, $filename, $extra_path) = @_;
  my $options = $self->{options};
  my $filepath;

  # first check for a full path
  return File::Spec->canonpath($filename)
    if (File::Spec->file_name_is_absolute($filename) and (-e $filename));

  # try the extra_path if one was specified
  if (defined($extra_path)) {
    $extra_path->[$#{$extra_path}] = $filename;
    $filepath = File::Spec->canonpath(File::Spec->catfile(@$extra_path));
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try pre-prending HTML_Template_Root
  if (defined($ENV{HTML_TEMPLATE_ROOT})) {
    $filepath =  File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $filename);
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try "path" option list..
  foreach my $path (@{$options->{path}}) {
    $filepath = File::Spec->catfile($path, $filename);
    return File::Spec->canonpath($filepath) if -e $filepath;
  }

  # try even a relative path from the current directory...
  return File::Spec->canonpath($filename) if -e $filename;

  # try "path" option list with HTML_TEMPLATE_ROOT prepended...
  if (defined($ENV{HTML_TEMPLATE_ROOT})) {
    foreach my $path (@{$options->{path}}) {
      $filepath = File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $path, $filename);
      return File::Spec->canonpath($filepath) if -e $filepath;
    }
  }
  
  return undef;
}

# utility function - computes the mtime for $filename
sub _mtime {
  my ($self, $filepath) = @_;
  my $options = $self->{options};
  
  return(undef) if ($options->{blind_cache});

  # make sure it still exists in the filesystem 
  (-r $filepath) or Carp::confess("HTML::Template : template file $filepath does not exist or is unreadable.");
  
  # get the modification time
  return (stat(_))[9];
}

# utility function - enforces new() options across LOOPs that have
# come from a cache.  Otherwise they would have stale options hashes.
sub _normalize_options {
  my $self = shift;
  my $options = $self->{options};

  my @pstacks = ($self->{parse_stack});
  while(@pstacks) {
    my $pstack = pop(@pstacks);
    foreach my $item (@$pstack) {
      next unless (ref($item) eq 'HTML::Template::LOOP');
      foreach my $template (values %{$item->[HTML::Template::LOOP::TEMPLATE_HASH]}) {
        # must be the same list as the call to _new_from_loop...
        $template->{options}{debug} = $options->{debug};
        $template->{options}{stack_debug} = $options->{stack_debug};
        $template->{options}{die_on_bad_params} = $options->{die_on_bad_params};
        $template->{options}{case_sensitive} = $options->{case_sensitive};
        $template->{options}{parent_global_vars} = $options->{parent_global_vars};

        push(@pstacks, $template->{parse_stack});
      }
    }
  }
}      

# initialize the template buffer
sub _init_template {
  my $self = shift;
  my $options = $self->{options};

  print STDERR "### HTML::Template Memory Debug ### START INIT_TEMPLATE ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};

  if (exists($options->{filename})) {    
    my $filepath = $options->{filepath};
    if (not defined $filepath) {
      $filepath = $self->_find_file($options->{filename});
      confess("HTML::Template->new() : Cannot open included file $options->{filename} : file not found.")
        unless defined($filepath);
      # we'll need this for future reference - to call stat() for example.
      $options->{filepath} = $filepath;   
    }

    confess("HTML::Template->new() : Cannot open included file $options->{filename} : $!")
        unless defined(open(TEMPLATE, $filepath));
    $self->{mtime} = $self->_mtime($filepath);

    # read into scalar, note the mtime for the record
    $self->{template} = "";
    while (read(TEMPLATE, $self->{template}, 10240, length($self->{template}))) {}
    close(TEMPLATE);

  } elsif (exists($options->{scalarref})) {
    # copy in the template text
    $self->{template} = ${$options->{scalarref}};

    delete($options->{scalarref});
  } elsif (exists($options->{arrayref})) {
    # if we have an array ref, join and store the template text
    $self->{template} = join("", @{$options->{arrayref}});

    delete($options->{arrayref});
  } elsif (exists($options->{filehandle})) {
    # just read everything in in one go
    local $/ = undef;
    $self->{template} = readline($options->{filehandle});

    delete($options->{filehandle});
  } else {
    confess("HTML::Template : Need to call new with filename, filehandle, scalarref or arrayref parameter specified.");
  }

  print STDERR "### HTML::Template Memory Debug ### END INIT_TEMPLATE ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};

  # handle filters if necessary
  $self->_call_filters(\$self->{template}) if @{$options->{filter}};

  return $self;
}

# handle calling user defined filters
sub _call_filters {
  my $self = shift;
  my $template_ref = shift;
  my $options = $self->{options};

  my ($format, $sub);
  foreach my $filter (@{$options->{filter}}) {
    croak("HTML::Template->new() : bad value set for filter parameter - must be a code ref or a hash ref.")
      unless ref $filter;

    # translate into CODE->HASH
    $filter = { 'format' => 'scalar', 'sub' => $filter }
      if (ref $filter eq 'CODE');

    if (ref $filter eq 'HASH') {
      $format = $filter->{'format'};
      $sub = $filter->{'sub'};

      # check types and values
      croak("HTML::Template->new() : bad value set for filter parameter - hash must contain \"format\" key and \"sub\" key.")
        unless defined $format and defined $sub;
      croak("HTML::Template->new() : bad value set for filter parameter - \"format\" must be either 'array' or 'scalar'")
        unless $format eq 'array' or $format eq 'scalar';
      croak("HTML::Template->new() : bad value set for filter parameter - \"sub\" must be a code ref")
        unless ref $sub and ref $sub eq 'CODE';

      # catch errors
      eval {
        if ($format eq 'scalar') {
          # call
          $sub->($template_ref);
        } else {
	  # modulate
	  my @array = map { $_."\n" } split("\n", $$template_ref);
          # call
          $sub->(\@array);
	  # demodulate
	  $$template_ref = join("", @array);
        }
      };
      croak("HTML::Template->new() : fatal error occured during filter call: $@") if $@;
    } else {
      croak("HTML::Template->new() : bad value set for filter parameter - must be code ref or hash ref");
    }
  }
  # all done
  return $template_ref;
}

# _parse sifts through a template building up the param_map and
# parse_stack structures.
#
# The end result is a Template object that is fully ready for
# output().
sub _parse {
  my $self = shift;
  my $options = $self->{options};
  
  $options->{debug} and print STDERR "### HTML::Template Debug ### In _parse:\n";
  
  # setup the stacks and maps - they're accessed by typeglobs that
  # reference the top of the stack.  They are masked so that a loop
  # can transparently have its own versions.
  use vars qw(@pstack %pmap @ifstack @ucstack %top_pmap);
  local (*pstack, *ifstack, *pmap, *ucstack, *top_pmap);
  
  # the pstack is the array of scalar refs (plain text from the
  # template file), VARs, LOOPs, IFs and ELSEs that output() works on
  # to produce output.  Looking at output() should make it clear what
  # _parse is trying to accomplish.
  my @pstacks = ([]);
  *pstack = $pstacks[0];
  $self->{parse_stack} = $pstacks[0];
  
  # the pmap binds names to VARs, LOOPs and IFs.  It allows param() to
  # access the right variable.  NOTE: output() does not look at the
  # pmap at all!
  my @pmaps = ({});
  *pmap = $pmaps[0];
  *top_pmap = $pmaps[0];
  $self->{param_map} = $pmaps[0];

  # the ifstack is a temporary stack containing pending ifs and elses
  # waiting for a /if.
  my @ifstacks = ([]);
  *ifstack = $ifstacks[0];

  # the ucstack is a temporary stack containing conditions that need
  # to be bound to param_map entries when their block is finished.
  # This happens when a conditional is encountered before any other
  # reference to its NAME.  Since a conditional can reference VARs and
  # LOOPs it isn't possible to make the link right away.
  my @ucstacks = ([]);
  *ucstack = $ucstacks[0];
  
  # the loopstack is another temp stack for closing loops.  unlike
  # those above it doesn't get scoped inside loops, therefore it
  # doesn't need the typeglob magic.
  my @loopstack = ();

  # the fstack is a stack of filenames and counters that keeps track
  # of which file we're in and where we are in it.  This allows
  # accurate error messages even inside included files!
  # fcounter, fmax and fname are aliases for the current file's info
  use vars qw($fcounter $fname $fmax);
  local (*fcounter, *fname, *fmax);

  my @fstack = ([$options->{filepath} || "/fake/path/for/non/file/template",
                 1, 
                 scalar @{[$self->{template} =~ m/(\n)/g]} + 1
                ]);
  (*fname, *fcounter, *fmax) = \ ( @{$fstack[0]} );

  my $NOOP = HTML::Template::NOOP->new();
  my $ESCAPE = HTML::Template::ESCAPE->new();
  my $JSESCAPE = HTML::Template::JSESCAPE->new();
  my $URLESCAPE = HTML::Template::URLESCAPE->new();

  # all the tags that need NAMEs:
  my %need_names = map { $_ => 1 } 
    qw(TMPL_VAR TMPL_LOOP TMPL_IF TMPL_UNLESS TMPL_INCLUDE);
    
  # variables used below that don't need to be my'd in the loop
  my ($name, $which, $escape, $default);

  # handle the old vanguard format
  $options->{vanguard_compatibility_mode} and 
    $self->{template} =~ s/%([-\w\/\.+]+)%/<TMPL_VAR NAME=$1>/g;

  # now split up template on '<', leaving them in
  my @chunks = split(m/(?=<)/, $self->{template});

  # all done with template
  delete $self->{template};

  # loop through chunks, filling up pstack
  my $last_chunk =  $#chunks;
 CHUNK: for (my $chunk_number = 0;
	    $chunk_number <= $last_chunk;
	    $chunk_number++) {
    next unless defined $chunks[$chunk_number]; 
    my $chunk = $chunks[$chunk_number];
    
    # a general regex to match any and all TMPL_* tags 
    if ($chunk =~ /^<
                    (?:!--\s*)?
                    (
                      \/?[Tt][Mm][Pp][Ll]_
                      (?:
                         (?:[Vv][Aa][Rr])
                         |
                         (?:[Ll][Oo][Oo][Pp])
                         |
                         (?:[Ii][Ff])
                         |
                         (?:[Ee][Ll][Ss][Ee])
                         |
                         (?:[Uu][Nn][Ll][Ee][Ss][Ss])
                         |
                         (?:[Ii][Nn][Cc][Ll][Uu][Dd][Ee])
                      )
                    ) # $1 => $which - start of the tag

                    \s* 

                    # DEFAULT attribute
                    (?:
                      [Dd][Ee][Ff][Aa][Uu][Ll][Tt]
                      \s*=\s*
                      (?:
                        "([^">]*)"  # $2 => double-quoted DEFAULT value "
                        |
                        '([^'>]*)'  # $3 => single-quoted DEFAULT value
                        |
                        ([^\s=>]*)  # $4 => unquoted DEFAULT value
                      )
                    )?

                    \s*

                    # ESCAPE attribute
                    (?:
                      [Ee][Ss][Cc][Aa][Pp][Ee]
                      \s*=\s*
                      (?:
                        (
                           (?:["']?0["']?)|
                           (?:["']?1["']?)|
                           (?:["']?[Hh][Tt][Mm][Ll]["']?) |
                           (?:["']?[Uu][Rr][Ll]["']?) |
                           (?:["']?[Jj][Ss]["']?) |
                           (?:["']?[Nn][Oo][Nn][Ee]["']?)
                         )                         # $5 => ESCAPE on
                       )
                    )* # allow multiple ESCAPEs

                    \s*

                    # DEFAULT attribute
                    (?:
                      [Dd][Ee][Ff][Aa][Uu][Ll][Tt]
                      \s*=\s*
                      (?:
                        "([^">]*)"  # $6 => double-quoted DEFAULT value "
                        |
                        '([^'>]*)'  # $7 => single-quoted DEFAULT value
                        |
                        ([^\s=>]*)  # $8 => unquoted DEFAULT value
                      )
                    )?

                    \s*                    

                    # NAME attribute
                    (?:
                      (?:
                        [Nn][Aa][Mm][Ee]
                        \s*=\s*
                      )?
                      (?:
                        "([^">]*)"  # $9 => double-quoted NAME value "
                        |
                        '([^'>]*)'  # $10 => single-quoted NAME value
                        |
                        ([^\s=>]*)  # $11 => unquoted NAME value
                      )
                    )? 
                    
                    \s*

                    # DEFAULT attribute
                    (?:
                      [Dd][Ee][Ff][Aa][Uu][Ll][Tt]
                      \s*=\s*
                      (?:
                        "([^">]*)"  # $12 => double-quoted DEFAULT value "
                        |
                        '([^'>]*)'  # $13 => single-quoted DEFAULT value
                        |
                        ([^\s=>]*)  # $14 => unquoted DEFAULT value
                      )
                    )?

                    \s*

                    # ESCAPE attribute
                    (?:
                      [Ee][Ss][Cc][Aa][Pp][Ee]
                      \s*=\s*
                      (?:
                        (
                           (?:["']?0["']?)|
                           (?:["']?1["']?)|
                           (?:["']?[Hh][Tt][Mm][Ll]["']?) |
                           (?:["']?[Uu][Rr][Ll]["']?) |
                           (?:["']?[Jj][Ss]["']?) |
                           (?:["']?[Nn][Oo][Nn][Ee]["']?)
                         )                         # $15 => ESCAPE on
                       )
                    )* # allow multiple ESCAPEs

                    \s*

                    # DEFAULT attribute
                    (?:
                      [Dd][Ee][Ff][Aa][Uu][Ll][Tt]
                      \s*=\s*
                      (?:
                        "([^">]*)"  # $16 => double-quoted DEFAULT value "
                        |
                        '([^'>]*)'  # $17 => single-quoted DEFAULT value
                        |
                        ([^\s=>]*)  # $18 => unquoted DEFAULT value
                      )
                    )?

                    \s*

                    (?:--)?>                    
                    (.*) # $19 => $post - text that comes after the tag
                   $/sx) {

      $which = uc($1); # which tag is it

      $escape = defined $5 ? $5 : defined $15 ? $15
        : (defined $options->{default_escape} && $which eq 'TMPL_VAR') ? $options->{default_escape} : 0; # escape set?
      
      # what name for the tag?  undef for a /tag at most, one of the
      # following three will be defined
      $name = defined $9 ? $9 : defined $10 ? $10 : defined $11 ? $11 : undef;

      # is there a default?
      $default = defined $2  ? $2  : defined $3  ? $3  : defined $4  ? $4 : 
                 defined $6  ? $6  : defined $7  ? $7  : defined $8  ? $8 : 
                 defined $12 ? $12 : defined $13 ? $13 : defined $14 ? $14 : 
                 defined $16 ? $16 : defined $17 ? $17 : defined $18 ? $18 :
                 undef;

      my $post = $19; # what comes after on the line

      # allow mixed case in filenames, otherwise flatten
      $name = lc($name) unless (not defined $name or $which eq 'TMPL_INCLUDE' or $options->{case_sensitive});

      # die if we need a name and didn't get one
      die "HTML::Template->new() : No NAME given to a $which tag at $fname : line $fcounter." 
        if ($need_names{$which} and (not defined $name or not length $name));

      # die if we got an escape but can't use one
      die "HTML::Template->new() : ESCAPE option invalid in a $which tag at $fname : line $fcounter." if ( $escape and ($which ne 'TMPL_VAR'));

      # die if we got a default but can't use one
      die "HTML::Template->new() : DEFAULT option invalid in a $which tag at $fname : line $fcounter." if ( defined $default and ($which ne 'TMPL_VAR'));
        
      # take actions depending on which tag found
      if ($which eq 'TMPL_VAR') {
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : parsed VAR $name\n";
	
	# if we already have this var, then simply link to the existing
	# HTML::Template::VAR, else create a new one.        
	my $var;        
	if (exists $pmap{$name}) {
	  $var = $pmap{$name};
	  (ref($var) eq 'HTML::Template::VAR') or
	    die "HTML::Template->new() : Already used param name $name as a TMPL_LOOP, found in a TMPL_VAR at $fname : line $fcounter.";
	} else {
	  $var = HTML::Template::VAR->new();
	  $pmap{$name} = $var;
	  $top_pmap{$name} = HTML::Template::VAR->new()
	    if $options->{global_vars} and not exists $top_pmap{$name};
	}

        # if a DEFAULT was provided, push a DEFAULT object on the
        # stack before the variable.
	if (defined $default) {
            push(@pstack, HTML::Template::DEFAULT->new($default));
        }
	
	# if ESCAPE was set, push an ESCAPE op on the stack before
	# the variable.  output will handle the actual work.
        # unless of course, they have set escape=0 or escape=none
	if ($escape) {
          if ($escape =~ /^["']?[Uu][Rr][Ll]["']?$/) {
            push(@pstack, $URLESCAPE);
          } elsif ($escape =~ /^["']?[Jj][Ss]["']?$/) {
	    push(@pstack, $JSESCAPE);
          } elsif ($escape =~ /^["']?0["']?$/) {
            # do nothing if escape=0
          } elsif ($escape =~ /^["']?[Nn][Oo][Nn][Ee]["']?$/ ) {
            # do nothing if escape=none
          } else {
	    push(@pstack, $ESCAPE);
          }
        }

	push(@pstack, $var);
	
      } elsif ($which eq 'TMPL_LOOP') {
	# we've got a loop start
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : LOOP $name start\n";
	
	# if we already have this loop, then simply link to the existing
	# HTML::Template::LOOP, else create a new one.
	my $loop;
	if (exists $pmap{$name}) {
	  $loop = $pmap{$name};
	  (ref($loop) eq 'HTML::Template::LOOP') or
	    die "HTML::Template->new() : Already used param name $name as a TMPL_VAR, TMPL_IF or TMPL_UNLESS, found in a TMP_LOOP at $fname : line $fcounter!";
	  
	} else {
	  # store the results in a LOOP object - actually just a
	  # thin wrapper around another HTML::Template object.
	  $loop = HTML::Template::LOOP->new();
	  $pmap{$name} = $loop;
	}
	
	# get it on the loopstack, pstack of the enclosing block
	push(@pstack, $loop);
	push(@loopstack, [$loop, $#pstack]);
	
	# magic time - push on a fresh pmap and pstack, adjust the typeglobs.
	# this gives the loop a separate namespace (i.e. pmap and pstack).
	push(@pstacks, []);
	*pstack = $pstacks[$#pstacks];
	push(@pmaps, {});
	*pmap = $pmaps[$#pmaps];
	push(@ifstacks, []);
	*ifstack = $ifstacks[$#ifstacks];
	push(@ucstacks, []);
	*ucstack = $ucstacks[$#ucstacks];
	
	# auto-vivify __FIRST__, __LAST__ and __INNER__ if
	# loop_context_vars is set.  Otherwise, with
	# die_on_bad_params set output() will might cause errors
	# when it tries to set them.
	if ($options->{loop_context_vars}) {
	  $pmap{__first__}   = HTML::Template::VAR->new();
	  $pmap{__inner__}   = HTML::Template::VAR->new();
	  $pmap{__last__}    = HTML::Template::VAR->new();
	  $pmap{__odd__}     = HTML::Template::VAR->new();
	  $pmap{__counter__} = HTML::Template::VAR->new();
	}
	
      } elsif ($which eq '/TMPL_LOOP') {
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : LOOP end\n";
	
	my $loopdata = pop(@loopstack);
	die "HTML::Template->new() : found </TMPL_LOOP> with no matching <TMPL_LOOP> at $fname : line $fcounter!" unless defined $loopdata;
	
	my ($loop, $starts_at) = @$loopdata;
	
	# resolve pending conditionals
	foreach my $uc (@ucstack) {
	  my $var = $uc->[HTML::Template::COND::VARIABLE]; 
	  if (exists($pmap{$var})) {
	    $uc->[HTML::Template::COND::VARIABLE] = $pmap{$var};
	  } else {
	    $pmap{$var} = HTML::Template::VAR->new();
	    $top_pmap{$var} = HTML::Template::VAR->new()
	      if $options->{global_vars} and not exists $top_pmap{$var};
	    $uc->[HTML::Template::COND::VARIABLE] = $pmap{$var};
	  }
	  if (ref($pmap{$var}) eq 'HTML::Template::VAR') {
	    $uc->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_VAR;
	  } else {
	    $uc->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_LOOP;
	  }
	}
	
	# get pmap and pstack for the loop, adjust the typeglobs to
	# the enclosing block.
	my $param_map = pop(@pmaps);
	*pmap = $pmaps[$#pmaps];
	my $parse_stack = pop(@pstacks);
	*pstack = $pstacks[$#pstacks];
	
	scalar(@ifstack) and die "HTML::Template->new() : Dangling <TMPL_IF> or <TMPL_UNLESS> in loop ending at $fname : line $fcounter.";
	pop(@ifstacks);
	*ifstack = $ifstacks[$#ifstacks];
	pop(@ucstacks);
	*ucstack = $ucstacks[$#ucstacks];
	
	# instantiate the sub-Template, feeding it parse_stack and
	# param_map.  This means that only the enclosing template
	# does _parse() - sub-templates get their parse_stack and
	# param_map fed to them already filled in.
	$loop->[HTML::Template::LOOP::TEMPLATE_HASH]{$starts_at}             
	  = ref($self)->_new_from_loop(
					   parse_stack => $parse_stack,
					   param_map => $param_map,
					   debug => $options->{debug}, 
					   die_on_bad_params => $options->{die_on_bad_params}, 
					   loop_context_vars => $options->{loop_context_vars},
                                           case_sensitive => $options->{case_sensitive},
                                           force_untaint => $options->{force_untaint},
                                           parent_global_vars => ($options->{global_vars} || $options->{parent_global_vars} || 0)
					  );
	
      } elsif ($which eq 'TMPL_IF' or $which eq 'TMPL_UNLESS' ) {
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : $which $name start\n";
	
	# if we already have this var, then simply link to the existing
	# HTML::Template::VAR/LOOP, else defer the mapping
	my $var;        
	if (exists $pmap{$name}) {
	  $var = $pmap{$name};
	} else {
	  $var = $name;
	}
	
	# connect the var to a conditional
	my $cond = HTML::Template::COND->new($var);
	if ($which eq 'TMPL_IF') {
	  $cond->[HTML::Template::COND::WHICH] = HTML::Template::COND::WHICH_IF;
	  $cond->[HTML::Template::COND::JUMP_IF_TRUE] = 0;
	} else {
	  $cond->[HTML::Template::COND::WHICH] = HTML::Template::COND::WHICH_UNLESS;
	  $cond->[HTML::Template::COND::JUMP_IF_TRUE] = 1;
	}
	
	# push unconnected conditionals onto the ucstack for
	# resolution later.  Otherwise, save type information now.
	if ($var eq $name) {
	  push(@ucstack, $cond);
	} else {
	  if (ref($var) eq 'HTML::Template::VAR') {
	    $cond->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_VAR;
	  } else {
	    $cond->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_LOOP;
	  }
	}
	
	# push what we've got onto the stacks
	push(@pstack, $cond);
	push(@ifstack, $cond);
	
      } elsif ($which eq '/TMPL_IF' or $which eq '/TMPL_UNLESS') {
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : $which end\n";
	
	my $cond = pop(@ifstack);
	die "HTML::Template->new() : found </${which}> with no matching <TMPL_IF> at $fname : line $fcounter." unless defined $cond;
	if ($which eq '/TMPL_IF') {
	  die "HTML::Template->new() : found </TMPL_IF> incorrectly terminating a <TMPL_UNLESS> (use </TMPL_UNLESS>) at $fname : line $fcounter.\n" 
	    if ($cond->[HTML::Template::COND::WHICH] == HTML::Template::COND::WHICH_UNLESS);
	} else {
	  die "HTML::Template->new() : found </TMPL_UNLESS> incorrectly terminating a <TMPL_IF> (use </TMPL_IF>) at $fname : line $fcounter.\n" 
	    if ($cond->[HTML::Template::COND::WHICH] == HTML::Template::COND::WHICH_IF);
	}
	
	# connect the matching to this "address" - place a NOOP to
	# hold the spot.  This allows output() to treat an IF in the
	# assembler-esque "Conditional Jump" mode.
	push(@pstack, $NOOP);
	$cond->[HTML::Template::COND::JUMP_ADDRESS] = $#pstack;
	
      } elsif ($which eq 'TMPL_ELSE') {
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : ELSE\n";
	
	my $cond = pop(@ifstack);
	die "HTML::Template->new() : found <TMPL_ELSE> with no matching <TMPL_IF> or <TMPL_UNLESS> at $fname : line $fcounter." unless defined $cond;
        die "HTML::Template->new() : found second <TMPL_ELSE> tag for  <TMPL_IF> or <TMPL_UNLESS> at $fname : line $fcounter." if $cond->[HTML::Template::COND::IS_ELSE];	
	
	my $else = HTML::Template::COND->new($cond->[HTML::Template::COND::VARIABLE]);
	$else->[HTML::Template::COND::WHICH] = $cond->[HTML::Template::COND::WHICH];
        $else->[HTML::Template::COND::UNCONDITIONAL_JUMP] = 1;
	$else->[HTML::Template::COND::IS_ELSE] = 1;

	# need end-block resolution?
	if (defined($cond->[HTML::Template::COND::VARIABLE_TYPE])) {
	  $else->[HTML::Template::COND::VARIABLE_TYPE] = $cond->[HTML::Template::COND::VARIABLE_TYPE];
	} else {
	  push(@ucstack, $else);
	}
	
	push(@pstack, $else);
	push(@ifstack, $else);
	
	# connect the matching to this "address" - thus the if,
	# failing jumps to the ELSE address.  The else then gets
	# elaborated, and of course succeeds.  On the other hand, if
	# the IF fails and falls though, output will reach the else
	# and jump to the /if address.
	$cond->[HTML::Template::COND::JUMP_ADDRESS] = $#pstack;
		
      } elsif ($which eq 'TMPL_INCLUDE') {
	# handle TMPL_INCLUDEs
	$options->{debug} and print STDERR "### HTML::Template Debug ### $fname : line $fcounter : INCLUDE $name \n";
	
	# no includes here, bub
	$options->{no_includes} and croak("HTML::Template : Illegal attempt to use TMPL_INCLUDE in template file : (no_includes => 1)");
	
	my $filename = $name;
	
	# look for the included file...
	my $filepath;
	if ($options->{search_path_on_include}) {
	  $filepath = $self->_find_file($filename);
	} else {
	  $filepath = $self->_find_file($filename, 
					[File::Spec->splitdir($fstack[-1][0])]
				       );
	}
	die "HTML::Template->new() : Cannot open included file $filename : file not found."
	  unless defined($filepath);
	die "HTML::Template->new() : Cannot open included file $filename : $!"
	  unless defined(open(TEMPLATE, $filepath));              
	
	# read into the array
	my $included_template = "";
        while(read(TEMPLATE, $included_template, 10240, length($included_template))) {}
	close(TEMPLATE);
	
	# call filters if necessary
	$self->_call_filters(\$included_template) if @{$options->{filter}};
	
	if ($included_template) { # not empty
	  # handle the old vanguard format - this needs to happen here
	  # since we're not about to do a next CHUNKS.
	  $options->{vanguard_compatibility_mode} and 
	    $included_template =~ s/%([-\w\/\.+]+)%/<TMPL_VAR NAME=$1>/g;
	  
	  # collect mtimes for included files
	  if ($options->{cache} and !$options->{blind_cache}) {
	    $self->{included_mtimes}{$filepath} = (stat($filepath))[9];
	  }
	  
	  # adjust the fstack to point to the included file info
	  push(@fstack, [$filepath, 1,
			 scalar @{[$included_template =~ m/(\n)/g]} + 1]);
	  (*fname, *fcounter, *fmax) = \ ( @{$fstack[$#fstack]} );
	  
          # make sure we aren't infinitely recursing
          die "HTML::Template->new() : likely recursive includes - parsed $options->{max_includes} files deep and giving up (set max_includes higher to allow deeper recursion)." if ($options->{max_includes} and (scalar(@fstack) > $options->{max_includes}));
          
	  # stick the remains of this chunk onto the bottom of the
	  # included text.
	  $included_template .= $post;
	  $post = undef;
	  
	  # move the new chunks into place.  
	  splice(@chunks, $chunk_number, 1,
		 split(m/(?=<)/, $included_template));

	  # recalculate stopping point
	  $last_chunk = $#chunks;

	  # start in on the first line of the included text - nothing
	  # else to do on this line.
	  $chunk = $chunks[$chunk_number];

	  redo CHUNK;
	}
      } else {
	# zuh!?
	die "HTML::Template->new() : Unknown or unmatched TMPL construct at $fname : line $fcounter.";
      }
      # push the rest after the tag
      if (defined($post)) {
	if (ref($pstack[$#pstack]) eq 'SCALAR') {
	  ${$pstack[$#pstack]} .= $post;
	} else {
	  push(@pstack, \$post);
	}
      }
    } else { # just your ordinary markup
      # make sure we didn't reject something TMPL_* but badly formed
      if ($options->{strict}) {
	die "HTML::Template->new() : Syntax error in <TMPL_*> tag at $fname : $fcounter." if ($chunk =~ /<(?:!--\s*)?\/?[Tt][Mm][Pp][Ll]_/);
      }
      
      # push the rest and get next chunk
      if (defined($chunk)) {
	if (ref($pstack[$#pstack]) eq 'SCALAR') {
	  ${$pstack[$#pstack]} .= $chunk;
	} else {
	  push(@pstack, \$chunk);
	}
      }
    }
    # count newlines in chunk and advance line count
    $fcounter += scalar(@{[$chunk =~ m/(\n)/g]});
    # if we just crossed the end of an included file
    # pop off the record and re-alias to the enclosing file's info
    pop(@fstack), (*fname, *fcounter, *fmax) = \ ( @{$fstack[$#fstack]} )
      if ($fcounter > $fmax);
    
  } # next CHUNK

  # make sure we don't have dangling IF or LOOP blocks
  scalar(@ifstack) and die "HTML::Template->new() : At least one <TMPL_IF> or <TMPL_UNLESS> not terminated at end of file!";
  scalar(@loopstack) and die "HTML::Template->new() : At least one <TMPL_LOOP> not terminated at end of file!";

  # resolve pending conditionals
  foreach my $uc (@ucstack) {
    my $var = $uc->[HTML::Template::COND::VARIABLE]; 
    if (exists($pmap{$var})) {
      $uc->[HTML::Template::COND::VARIABLE] = $pmap{$var};
    } else {
      $pmap{$var} = HTML::Template::VAR->new();
      $top_pmap{$var} = HTML::Template::VAR->new()
        if $options->{global_vars} and not exists $top_pmap{$var};
      $uc->[HTML::Template::COND::VARIABLE] = $pmap{$var};
    }
    if (ref($pmap{$var}) eq 'HTML::Template::VAR') {
      $uc->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_VAR;
    } else {
      $uc->[HTML::Template::COND::VARIABLE_TYPE] = HTML::Template::COND::VARIABLE_TYPE_LOOP;
    }
  }

  # want a stack dump?
  if ($options->{stack_debug}) {
    require 'Data/Dumper.pm';
    print STDERR "### HTML::Template _param Stack Dump ###\n\n", Data::Dumper::Dumper($self->{parse_stack}), "\n";
  }

  # get rid of filters - they cause runtime errors if Storable tries
  # to store them.  This can happen under global_vars.
  delete $options->{filter};
}

# a recursive sub that associates each loop with the loops above
# (treating the top-level as a loop)
sub _globalize_vars {
  my $self = shift;
  
  # associate with the loop (and top-level templates) above in the tree.
  push(@{$self->{options}{associate}}, @_);
  
  # recurse down into the template tree, adding ourself to the end of
  # list.
  push(@_, $self);
  map { $_->_globalize_vars(@_) } 
    map {values %{$_->[HTML::Template::LOOP::TEMPLATE_HASH]}}
      grep { ref($_) eq 'HTML::Template::LOOP'} @{$self->{parse_stack}};
}

# method used to recursively un-hook associate
sub _unglobalize_vars {
  my $self = shift;
  
  # disassociate
  $self->{options}{associate} = undef;
  
  # recurse down into the template tree disassociating
  map { $_->_unglobalize_vars() } 
    map {values %{$_->[HTML::Template::LOOP::TEMPLATE_HASH]}}
      grep { ref($_) eq 'HTML::Template::LOOP'} @{$self->{parse_stack}};
}

#line 2492


sub param {
  my $self = shift;
  my $options = $self->{options};
  my $param_map = $self->{param_map};

  # the no-parameter case - return list of parameters in the template.
  return keys(%$param_map) unless scalar(@_);
  
  my $first = shift;
  my $type = ref $first;

  # the one-parameter case - could be a parameter value request or a
  # hash-ref.
  if (!scalar(@_) and !length($type)) {
    my $param = $options->{case_sensitive} ? $first : lc $first;
    
    # check for parameter existence 
    $options->{die_on_bad_params} and !exists($param_map->{$param}) and
      croak("HTML::Template : Attempt to get nonexistent parameter '$param' - this parameter name doesn't match any declarations in the template file : (die_on_bad_params set => 1)");
    
    return undef unless (exists($param_map->{$param}) and
                         defined($param_map->{$param}));

    return ${$param_map->{$param}} if 
      (ref($param_map->{$param}) eq 'HTML::Template::VAR');
    return $param_map->{$param}[HTML::Template::LOOP::PARAM_SET];
  } 

  if (!scalar(@_)) {
    croak("HTML::Template->param() : Single reference arg to param() must be a hash-ref!  You gave me a $type.")
        unless $type eq 'HASH' or UNIVERSAL::isa($first, 'HASH');
    push(@_, %$first);
  } else {
    unshift(@_, $first);
  }
  
  croak("HTML::Template->param() : You gave me an odd number of parameters to param()!")
    unless ((@_ % 2) == 0);

  # strangely, changing this to a "while(@_) { shift, shift }" type
  # loop causes perl 5.004_04 to die with some nonsense about a
  # read-only value.
  for (my $x = 0; $x <= $#_; $x += 2) {
    my $param = $options->{case_sensitive} ? $_[$x] : lc $_[$x];
    my $value = $_[($x + 1)];
    
    # check that this param exists in the template
    $options->{die_on_bad_params} and !exists($param_map->{$param}) and
      croak("HTML::Template : Attempt to set nonexistent parameter '$param' - this parameter name doesn't match any declarations in the template file : (die_on_bad_params => 1)");
    
    # if we're not going to die from bad param names, we need to ignore
    # them...
    unless (exists($param_map->{$param})) {
        next if not $options->{parent_global_vars};

        # ... unless global vars is on - in which case we can't be
        # sure we won't need it in a lower loop.
        if (ref($value) eq 'ARRAY') {
            $param_map->{$param} = HTML::Template::LOOP->new();
        } else {
            $param_map->{$param} = HTML::Template::VAR->new();
        }
    }

    
    # figure out what we've got, taking special care to allow for
    # objects that are compatible underneath.
    my $value_type = ref($value);
    if (defined($value_type) and length($value_type) and ($value_type eq 'ARRAY' or ((ref($value) !~ /^(CODE)|(HASH)|(SCALAR)$/) and $value->isa('ARRAY')))) {
      (ref($param_map->{$param}) eq 'HTML::Template::LOOP') or
        croak("HTML::Template::param() : attempt to set parameter '$param' with an array ref - parameter is not a TMPL_LOOP!");
      $param_map->{$param}[HTML::Template::LOOP::PARAM_SET] = [@{$value}];
    } else {
      (ref($param_map->{$param}) eq 'HTML::Template::VAR') or
        croak("HTML::Template::param() : attempt to set parameter '$param' with a scalar - parameter is not a TMPL_VAR!");
      ${$param_map->{$param}} = $value;
    }
  }
}

#line 2581

sub clear_params {
  my $self = shift;
  my $type;
  foreach my $name (keys %{$self->{param_map}}) {
    $type = ref($self->{param_map}{$name});
    undef(${$self->{param_map}{$name}})
      if ($type eq 'HTML::Template::VAR');
    undef($self->{param_map}{$name}[HTML::Template::LOOP::PARAM_SET])
      if ($type eq 'HTML::Template::LOOP');    
  }
}


# obsolete implementation of associate
sub associateCGI { 
  my $self = shift;
  my $cgi  = shift;
  (ref($cgi) eq 'CGI') or
    croak("Warning! non-CGI object was passed to HTML::Template::associateCGI()!\n");
  push(@{$self->{options}{associate}}, $cgi);
  return 1;
}


#line 2631

use vars qw(%URLESCAPE_MAP);
sub output {
  my $self = shift;
  my $options = $self->{options};
  local $_;

  croak("HTML::Template->output() : You gave me an odd number of parameters to output()!")
    unless ((@_ % 2) == 0);
  my %args = @_;

  print STDERR "### HTML::Template Memory Debug ### START OUTPUT ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};

  $options->{debug} and print STDERR "### HTML::Template Debug ### In output\n";

  # want a stack dump?
  if ($options->{stack_debug}) {
    require 'Data/Dumper.pm';
    print STDERR "### HTML::Template output Stack Dump ###\n\n", Data::Dumper::Dumper($self->{parse_stack}), "\n";
  }

  # globalize vars - this happens here to localize the circular
  # references created by global_vars.
  $self->_globalize_vars() if ($options->{global_vars});

  # support the associate magic, searching for undefined params and
  # attempting to fill them from the associated objects.
  if (scalar(@{$options->{associate}})) {
    # prepare case-mapping hashes to do case-insensitive matching
    # against associated objects.  This allows CGI.pm to be
    # case-sensitive and still work with asssociate.
    my (%case_map, $lparam);
    foreach my $associated_object (@{$options->{associate}}) {
      # what a hack!  This should really be optimized out for case_sensitive.
      if ($options->{case_sensitive}) {
        map {
          $case_map{$associated_object}{$_} = $_
        } $associated_object->param();
      } else {
        map {
          $case_map{$associated_object}{lc($_)} = $_
        } $associated_object->param();
      }
    }

    foreach my $param (keys %{$self->{param_map}}) {
      unless (defined($self->param($param))) {
      OBJ: foreach my $associated_object (reverse @{$options->{associate}}) {
          $self->param($param, scalar $associated_object->param($case_map{$associated_object}{$param})), last OBJ
            if (exists($case_map{$associated_object}{$param}));
        }
      }
    }
  }

  use vars qw($line @parse_stack); local(*line, *parse_stack);

  # walk the parse stack, accumulating output in $result
  *parse_stack = $self->{parse_stack};
  my $result = '';

  tie $result, 'HTML::Template::PRINTSCALAR', $args{print_to}
    if defined $args{print_to} and not tied $args{print_to};
	
  my $type;
  my $parse_stack_length = $#parse_stack;
  for (my $x = 0; $x <= $parse_stack_length; $x++) {
    *line = \$parse_stack[$x];
    $type = ref($line);
    
    if ($type eq 'SCALAR') {
      $result .= $$line;
    } elsif ($type eq 'HTML::Template::VAR' and ref($$line) eq 'CODE') {
      if ( defined($$line) ) {
        if ($options->{force_untaint}) {
          my $tmp = $$line->($self);
          croak("HTML::Template->output() : 'force_untaint' option but coderef returns tainted value")
            if tainted($tmp);
          $result .= $tmp;
        } else {
          $result .= $$line->($self);
        }
      }
    } elsif ($type eq 'HTML::Template::VAR') {
      if (defined $$line) {
        if ($options->{force_untaint} && tainted($$line)) {
          croak("HTML::Template->output() : tainted value with 'force_untaint' option");
        }
        $result .= $$line;
      }
    } elsif ($type eq 'HTML::Template::LOOP') {
      if (defined($line->[HTML::Template::LOOP::PARAM_SET])) {
        eval { $result .= $line->output($x, $options->{loop_context_vars}); };
        croak("HTML::Template->output() : fatal error in loop output : $@") 
          if $@;
      }
	} elsif ($type eq 'HTML::Template::COND') {
    	
     if ($line->[HTML::Template::COND::UNCONDITIONAL_JUMP]) {
       $x = $line->[HTML::Template::COND::JUMP_ADDRESS]
     } else {
        if ($line->[HTML::Template::COND::JUMP_IF_TRUE]) {
          if ($line->[HTML::Template::COND::VARIABLE_TYPE] == HTML::Template::COND::VARIABLE_TYPE_VAR) {
            if (defined ${$line->[HTML::Template::COND::VARIABLE]}) {
              if (ref(${$line->[HTML::Template::COND::VARIABLE]}) eq 'CODE') {
                $x = $line->[HTML::Template::COND::JUMP_ADDRESS] if ${$line->[HTML::Template::COND::VARIABLE]}->($self);
              } else {
                $x = $line->[HTML::Template::COND::JUMP_ADDRESS] if ${$line->[HTML::Template::COND::VARIABLE]};
              }
            }
          } else {
            $x = $line->[HTML::Template::COND::JUMP_ADDRESS] if
              (defined $line->[HTML::Template::COND::VARIABLE][HTML::Template::LOOP::PARAM_SET] and
               scalar @{$line->[HTML::Template::COND::VARIABLE][HTML::Template::LOOP::PARAM_SET]});
          }
        } else {
          if ($line->[HTML::Template::COND::VARIABLE_TYPE] == HTML::Template::COND::VARIABLE_TYPE_VAR) {
            if (defined ${$line->[HTML::Template::COND::VARIABLE]}) {
              if (ref(${$line->[HTML::Template::COND::VARIABLE]}) eq 'CODE') {
                $x = $line->[HTML::Template::COND::JUMP_ADDRESS] unless ${$line->[HTML::Template::COND::VARIABLE]}->($self);
              } else {
                $x = $line->[HTML::Template::COND::JUMP_ADDRESS] unless ${$line->[HTML::Template::COND::VARIABLE]};
              }
            } else {
              $x = $line->[HTML::Template::COND::JUMP_ADDRESS];
            }
          } else {
            $x = $line->[HTML::Template::COND::JUMP_ADDRESS] if
              (not defined $line->[HTML::Template::COND::VARIABLE][HTML::Template::LOOP::PARAM_SET] or
               not scalar @{$line->[HTML::Template::COND::VARIABLE][HTML::Template::LOOP::PARAM_SET]});
          }
        }
      }      	
    } elsif ($type eq 'HTML::Template::NOOP') {
      next;
    } elsif ($type eq 'HTML::Template::DEFAULT') {
      $_ = $x;  # remember default place in stack

      # find next VAR, there might be an ESCAPE in the way
      *line = \$parse_stack[++$x];
      *line = \$parse_stack[++$x] 
        if ref $line eq 'HTML::Template::ESCAPE' or
           ref $line eq 'HTML::Template::JSESCAPE' or
           ref $line eq 'HTML::Template::URLESCAPE';

      # either output the default or go back
      if (defined $$line) {
        $x = $_;
      } else {
        $result .= ${$parse_stack[$_]};
      }
      next;      
    } elsif ($type eq 'HTML::Template::ESCAPE') {
      *line = \$parse_stack[++$x];
      if (defined($$line)) {
        if (ref($$line) eq 'CODE') {
            $_ = $$line->($self);
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : 'force_untaint' option but coderef returns tainted value");
            }
        } else {
            $_ = $$line;
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : tainted value with 'force_untaint' option");
            }
        }
        
        # straight from the CGI.pm bible.
        s/&/&amp;/g;
        s/\"/&quot;/g; #"
        s/>/&gt;/g;
        s/</&lt;/g;
        s/'/&#39;/g; #'
        
        $result .= $_;
      }
      next;
    } elsif ($type eq 'HTML::Template::JSESCAPE') {
      $x++;
      *line = \$parse_stack[$x];
      if (defined($$line)) {
        if (ref($$line) eq 'CODE') {
            $_ = $$line->($self);
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : 'force_untaint' option but coderef returns tainted value");
            }
        } else {
            $_ = $$line;
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : tainted value with 'force_untaint' option");
            }
        }
        s/\\/\\\\/g;
        s/'/\\'/g;
        s/"/\\"/g;
        s/\n/\\n/g;
        s/\r/\\r/g;
        $result .= $_;
      }
    } elsif ($type eq 'HTML::Template::URLESCAPE') {
      $x++;
      *line = \$parse_stack[$x];
      if (defined($$line)) {
        if (ref($$line) eq 'CODE') {
            $_ = $$line->($self);
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : 'force_untaint' option but coderef returns tainted value");
            }
        } else {
            $_ = $$line;
            if ($options->{force_untaint} > 1 && tainted($_)) {
              croak("HTML::Template->output() : tainted value with 'force_untaint' option");
            }
        }
        # Build a char->hex map if one isn't already available
        unless (exists($URLESCAPE_MAP{chr(1)})) {
          for (0..255) { $URLESCAPE_MAP{chr($_)} = sprintf('%%%02X', $_); }
        }
        # do the translation (RFC 2396 ^uric)
        s!([^a-zA-Z0-9_.\-])!$URLESCAPE_MAP{$1}!g;
        $result .= $_;
      }
    } else {
      confess("HTML::Template::output() : Unknown item in parse_stack : " . $type);
    }
  }

  # undo the globalization circular refs
  $self->_unglobalize_vars() if ($options->{global_vars});

  print STDERR "### HTML::Template Memory Debug ### END OUTPUT ", $self->{proc_mem}->size(), "\n"
    if $options->{memory_debug};
    
  return undef if defined $args{print_to};
  return $result;
}

#line 2947

sub query {
  my $self = shift;
  $self->{options}{debug} and print STDERR "### HTML::Template Debug ### query(", join(', ', @_), ")\n";

  # the no-parameter case - return $self->param()
  return $self->param() unless scalar(@_);
  
  croak("HTML::Template::query() : Odd number of parameters passed to query!")
    if (scalar(@_) % 2);
  croak("HTML::Template::query() : Wrong number of parameters passed to query - should be 2.")
    if (scalar(@_) != 2);

  my ($opt, $path) = (lc shift, shift);
  croak("HTML::Template::query() : invalid parameter ($opt)")
    unless ($opt eq 'name' or $opt eq 'loop');

  # make path an array unless it already is
  $path = [$path] unless (ref $path);

  # find the param in question.
  my @objs = $self->_find_param(@$path);
  return undef unless scalar(@objs);
  my ($obj, $type);

  # do what the user asked with the object
  if ($opt eq 'name') {
    # we only look at the first one.  new() should make sure they're
    # all the same.
    ($obj, $type) = (shift(@objs), shift(@objs));
    return undef unless defined $obj;
    return 'VAR' if $type eq 'HTML::Template::VAR';
    return 'LOOP' if $type eq 'HTML::Template::LOOP';
    croak("HTML::Template::query() : unknown object ($type) in param_map!");

  } elsif ($opt eq 'loop') {
    my %results;
    while(@objs) {
      ($obj, $type) = (shift(@objs), shift(@objs));
      croak("HTML::Template::query() : Search path [", join(', ', @$path), "] doesn't end in a TMPL_LOOP - it is an error to use the 'loop' option on a non-loop parameter.  To avoid this problem you can use the 'name' option to query() to check the type first.") 
        unless ((defined $obj) and ($type eq 'HTML::Template::LOOP'));
      
      # SHAZAM!  This bit extracts all the parameter names from all the
      # loop objects for this name.
      map {$results{$_} = 1} map { keys(%{$_->{'param_map'}}) }
        values(%{$obj->[HTML::Template::LOOP::TEMPLATE_HASH]});
    }
    # this is our loop list, return it.
    return keys(%results);   
  }
}

# a function that returns the object(s) corresponding to a given path and
# its (their) ref()(s).  Used by query() in the obvious way.
sub _find_param {
  my $self = shift;
  my $spot = $self->{options}{case_sensitive} ? shift : lc shift;

  # get the obj and type for this spot
  my $obj = $self->{'param_map'}{$spot};
  return unless defined $obj;
  my $type = ref $obj;

  # return if we're here or if we're not but this isn't a loop
  return ($obj, $type) unless @_;
  return unless ($type eq 'HTML::Template::LOOP');

  # recurse.  this is a depth first seach on the template tree, for
  # the algorithm geeks in the audience.
  return map { $_->_find_param(@_) }
    values(%{$obj->[HTML::Template::LOOP::TEMPLATE_HASH]});
}

# HTML::Template::VAR, LOOP, etc are *light* objects - their internal
# spec is used above.  No encapsulation or information hiding is to be
# assumed.

package HTML::Template::VAR;

sub new {
    my $value;
    return bless(\$value, $_[0]);
}

package HTML::Template::DEFAULT;

sub new {
    my $value = $_[1];
    return bless(\$value, $_[0]);
}

package HTML::Template::LOOP;

sub new {
    return bless([], $_[0]);
}

sub output {
  my $self = shift;
  my $index = shift;
  my $loop_context_vars = shift;
  my $template = $self->[TEMPLATE_HASH]{$index};
  my $value_sets_array = $self->[PARAM_SET];
  return unless defined($value_sets_array);  
  
  my $result = '';
  my $count = 0;
  my $odd = 0;
  foreach my $value_set (@$value_sets_array) {
    if ($loop_context_vars) {
      if ($count == 0) {
        @{$value_set}{qw(__first__ __inner__ __last__)} = (1,0,$#{$value_sets_array} == 0);
      } elsif ($count == $#{$value_sets_array}) {
        @{$value_set}{qw(__first__ __inner__ __last__)} = (0,0,1);
      } else {
        @{$value_set}{qw(__first__ __inner__ __last__)} = (0,1,0);
      }
      $odd = $value_set->{__odd__} = not $odd;
      $value_set->{__counter__} = $count + 1;
    }
    $template->param($value_set);    
    $result .= $template->output;
    $template->clear_params;
    @{$value_set}{qw(__first__ __last__ __inner__ __odd__ __counter__)} = 
      (0,0,0,0)
        if ($loop_context_vars);
    $count++;
  }

  return $result;
}

package HTML::Template::COND;

sub new {
  my $pkg = shift;
  my $var = shift;
  my $self = [];
  $self->[VARIABLE] = $var;

  bless($self, $pkg);  
  return $self;
}

package HTML::Template::NOOP;
sub new {
  my $unused;
  my $self = \$unused;
  bless($self, $_[0]);
  return $self;
}

package HTML::Template::ESCAPE;
sub new {
  my $unused;
  my $self = \$unused;
  bless($self, $_[0]);
  return $self;
}

package HTML::Template::JSESCAPE;
sub new {
  my $unused;
  my $self = \$unused;
  bless($self, $_[0]);
  return $self;
}

package HTML::Template::URLESCAPE;
sub new {
  my $unused;
  my $self = \$unused;
  bless($self, $_[0]);
  return $self;
}

# scalar-tying package for output(print_to => *HANDLE) implementation
package HTML::Template::PRINTSCALAR;
use strict;

sub TIESCALAR { bless \$_[1], $_[0]; }
sub FETCH { }
sub STORE {
  my $self = shift;
  local *FH = $$self;
  print FH @_;
}
1;
__END__

#line 3442
