package HTML::Template::Pro::Extension;

use strict;
use integer; # no floating point math so far!

use Carp;
use HTML::Template::Pro;

use base "HTML::Template::Pro";

$HTML::Template::Pro::Extension::VERSION      = "0.11";
sub Version     { $HTML::Template::Pro::Extension::VERSION; }

my $fields 	= { 
							tmplfile => '',
							source => undef,
							source_orig => undef,
							plugins => []	,	
							__plugins => {},
							__reloadSource		=> 0,
							__reloadFile		=> 0,
						};

sub new {
	my $proto = shift;
  my $class = ref($proto) || $proto;	
	# valid HTML::Template::Pro parameter
  my $htpoptions={
		functions => {},
		debug => 0,
		max_includes => 10,
		global_vars => 0,
		no_includes => 0,
		search_path_on_include => 0,
		loop_context_vars => 1,
		path => [],
		associate => [],
		case_sensitive => 0,
		strict => 1,
		die_on_bad_params => 0,
		scalarref => '',
		option => 'value'
	};
	# set the htp options with new parameters
	my %opt							= @_;
	foreach (keys %$htpoptions) {
		$htpoptions->{$_} = $opt{$_} if (exists $opt{$_});
	}
	# carico il modulo HTML::Template::Pro
	my $self						= {%$fields,%{new HTML::Template::Pro(%$htpoptions)}};
	bless $self,$class;
	$self->_init(@_);
  return $self;
}

sub _init {
	my $self 	= shift;
	my %opts	= @_;
	$self->tmplfile($opts{tmplfile}) if ($opts{tmplfile});
	foreach (@{$opts{plugins}}) {
		$self->plugin_add($_);
	}
}

sub DESTROY {}

sub tmplfile {
	my $self	= shift;
	if (my $tmplfile  = shift) {
		$self->{__reloadFile} = 1;
		unless (ref($tmplfile) && $self->{tmplfile}) {
		 # sia $tmplfile che $self->{tmplfile} sono stringhe
			if ($tmplfile eq $self->{tmplfile}) {
				# il tmplfile e' lo stesso, niente reload
				$self->{__reloadFile} = 0;
			}
		}
		$self->{tmplfile} = $tmplfile;	
	}
	return $self->{tmplfile};
}

sub output {
	# redefine standard output function
  my $self = shift;
  my %args = @_;
  $self->_reloadFile 			if ($self->{__reloadFile});
	$self = $self->_reloadSource 		if ($self->{__reloadSource});
  if (exists $args{as}) {
    # delete old params settings
	# I don't know if this is a bug or a change in H::T::Pro interface
	# however
	if ($self->can('clear_params')) {
    	$self->clear_params();
	} else {
    	$self->clear_param();
	}
		$self->param(%{$args{as}});
  }
  return $self->SUPER::output(print_to => $args{print_to});
}

sub html {
  my $self     = shift;
  my %args     = (defined $_[0]) ? %{$_[0]} : ();
  $self->tmplfile($_[1]) if (defined $_[1]);
  return $self->output('as' => \%args);
}

sub _reloadFile {
	my $self = shift;
	$self->_loadFile;
	$self->{__reloadSource} = 1;
}

sub _loadFile {
	my $self = shift;
	if (ref($self->{tmplfile}) eq '') {
    my $filepath = $self->_find_file($self->{tmplfile});
		confess("HTML::Template->new() : Cannot open included file $self->{tmplfile} : file not found.") unless defined($filepath);
    # we'll need this for future reference - to call stat() for example.
    # read into scalar
		confess("HTML::Template::Pro::Extension : Cannot open included file $self->{tmplfile} : $!")
        unless defined(open(TEMPLATE, $filepath));
    $self->{source_orig} = "";
    while (read(TEMPLATE, $self->{source_orig}, 10240, length($self->{source_orig}))) {}
    close(TEMPLATE);
  } elsif (ref($self->{tmplfile}) eq 'SCALAR') { 
    # copy in the template text
    $self->{source_orig} = ${$self->{tmplfile}};
    delete($self->{tmplfile});
  } elsif (ref($self->{tmplfile}) eq 'ARRAY') {
    # if we have an array ref, join and store the template text
    $self->{source_orig} = join("", @{$self->{tmplfile}});
    delete($self->{tmplfile});
  } elsif (ref($self->{tmplfile}) eq 'GLOB') {
    # just read everything in in one go
    local $/ = undef;
    $self->{source_orig} = readline($self->{tmplfile});
    delete($self->{tmplfile});
	} else {
		confess("HTML::Template::Pro::Extension : Need to set file with a filename, filehandle, scalarref or arrayref parameter specified.");
	}
	$self->{__reloadFile} = 0;
}

sub _reloadSource {
	my $self	= shift;	
	my $src_orig = $self->{source_orig};
	foreach my $plugin (values %{$self->{__plugins}}) {
		foreach my $filter (@{$plugin->{filter}}) {
			croak("HTML::Template::Pro::Extension : bad value set for filter parameter - must be a code ref or a hash ref.") unless ref $filter;
			&$filter(\$src_orig,$self);
		}
	}
	$self->{source} = $src_orig;
	
	# ricarico il modulo HTML::Template::Pro
 	$self->{scalarref} = $src_orig;
 	$self->{options}->{scalarref} = $src_orig;
	$self->{__reloadSource} = 0;	
	return $self;
}

sub plugin_add {
  my $s   = shift;
  my ($module, $module_name)  = $s->_module_info(shift);
  # plugin gia caricato
  return if (exists $s->{__plugins}->{$module_name});
  $s->{__plugins}->{$module_name}->{obj} = $module;
  # init module
  $s->_initModule($module);
  # add filter from added module to me
  $s->_pushModule($module);
  $s->{__reloadSource} = 1;
}

sub _initModule {
  my $self    = shift;
  my $module    = shift;
  if (ref($module) eq '') {
    $self->_importModule($module);
    no strict "refs";
    &{$module . "::init"}($self);
  } else {
    $module->init($self);
  }
}

sub _importModule {
  my $self    = shift;
  my $module_name = shift;

  $module_name  =~s/::/\//g;
  require $module_name . ".pm";
}


sub _pushModule {
  my $self    = shift;
  my ($module, $module_name)  = $self->_module_info(shift);
	my @codes;
  if (ref($module) eq '') {
    no strict "refs";
    @codes = &{$module . "::get_filter"}($self);
  } else {
    @codes = $module->get_filter($self);
  }
	$self->{__plugins}->{$module_name}->{filter} = \@codes;
}

sub plugin_remove {
  my $s   = shift;
  my ($module, $module_name)  = $s->_module_info(shift);
  #delete $s->{plugins}->{$module_name};
  delete $s->{__plugins}->{$module_name};
  $s->{__reloadSource} = 1;
}

sub plugins_clear {
  my $s = shift;
  $s->{plugins} = [];
  $s->{__plugins} = {};
  $s->{__reloadSource} = 1;
}

sub _module_info {
    my $self  = shift;
    my $module  = shift;
    my $module_name;
    if (ref($module)) {
      $module_name = ref($module);
    } else {
      $module = "HTML::Template::Pro::Extension::$module"
        if ($module!~/::/);
      $module_name = $module;
    }
    return ($module,$module_name);
}

sub AUTOLOAD {
  my $self = shift;
  my @procs = split(/::/,$HTML::Template::Pro::Extension::AUTOLOAD);
  #confess("Unable to find $HTML::Template::Pro::Extension::AUTOLOAD") if (scalar(@procs)<4);
  my $proc = $procs[-1];
  my $value;
  no strict "refs";
  foreach my $module (keys %{$self->{__plugins}}) {
    my $ret;
    $ret=  eval { return &{"${module}::$proc"}($self,@_) };
    if (!$@) { return  $ret };
  };
	confess("Unable to find $HTML::Template::Pro::Extension::AUTOLOAD");
}

1;

# vim: set ts=2:
