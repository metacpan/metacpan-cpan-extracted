package HTML::Template::Extension;

$VERSION 			= "0.26";
sub Version 		{ $VERSION; }

use HTML::Template;
@HTML::Template::Extension::ISA = qw(HTML::Template);



use Carp;
use Data::Dumper;
use FileHandle;
use vars qw($DEBUG $DEBUG_FILE_PATH);
use strict;

$DEBUG 				= 0;
$DEBUG_FILE_PATH	= '/tmp/HTML-Template-Extension.debug.txt';

my %fields 	=
			    (
			    	plugins => {},
					plugins_cid => {},
			    	filename => undef,
			    	scalarref=>undef,
			    	arrayref=>undef,
			    	filehandle=>undef,
					filter_internal	=> [],
			     );
     
my @fields_req	= qw//;
my $DEBUG_FH;     

sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    # aggiungo il filtro
    my $self  = {};
    # I like %TAG_NAME% syntax
    push @_,('vanguard_compatibility_mode' => 1);
    # no error if a tag present in html was not set
    push @_,('die_on_bad_params' => 0);
    # enable loop variable items
    push @_,('loop_context_vars' => 1);
	# if don't exists neither filename, nor filehandle, nor scalarref,
	# nor arrayref, add an empty scalarref to correct init HTML::Template
	my %check = @_;
	push @_,('scalarref' => \'') unless (	exists $check{'filename'}   || 
											exists $check{'filehandle'} ||
											exists $check{'scalarref'}  || 
											exists $check{'arrayref'});
	bless $self,$class;
    $self->_init_local(@_);
#	$self->_loadDynamicModule;
#	$self->_reloadFilter;
    my $htmpl = $class->HTML::Template::new(@_);
    foreach (keys(%{$htmpl})) {
    	$self->{$_} = $htmpl->{$_};
    }
    bless $self,$class;
    return $self;
}							

sub _init_local {
	my $self = shift;
	my (%options) = @_;
	# add plugins
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
	# add plugins
	foreach (@{$options{plugins}}) {
		$self->plugin_add($_);
	}
	delete $options{plugins};
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}
	$self->{DEBUG_FH} = new FileHandle ">>$DEBUG_FILE_PATH" if ($DEBUG);
	#$self->push_filter;										
}

sub output {
	# redefine standard output function
	my $self = shift;
	my %args = @_;
	if ($self->{_auto_parse}) {
		$self->reloadFile();
	}
	if (exists $args{as}) {
		# delete old params settings
		$self->SUPER::clear_params();
		my %as = %{$args{as}};
		foreach (keys %as) {
			$self->SUPER::param($_ => $as{$_});
		}
	}
	my $output = $self->SUPER::output(%args);
	print {$self->{'DEBUG_FH'}} Data::Dumper::Dumper($self) if ($DEBUG);
	return $output;
}

sub html {
	my $self 		 = shift;
	my %args 		 = (defined $_[0]) ? %{$_[0]} : ();
	$self->{filename}= $_[1] if (defined $_[1]);
	if ( defined $self->{filename} 
			&& (
				!defined $self->{options}->{filename}
					||	$self->{filename} ne $self->{options}->{filename} 
				)
			|| $self->{_auto_parse}
		) {
		$self->reloadFile();
	}
	return $self->output('as' => \%args);
}

sub filename { 
	my $s=shift;
	if (@_)  {
		my $new_file = shift;
		if ($s->{filename} ne $new_file) {
			$s->{filename} = $new_file;
			# reload local file
			$s->{_auto_parse} = 1;	
			# remove other text storage
			delete($s->{scalarref});
			delete($s->{arrayref});
			delete($s->{filehandle});
		}
	};
	return $s->{filename};
}

sub scalarref { 
	my $s=shift;
	if (@_)  {
		$s->{scalarref} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		delete($s->{filename});
		delete($s->{options}->{filename});
		delete($s->{arrayref});
		delete($s->{filehandle});
	};
	# remove other text storage
	return $s->{scalarref};
}

sub arrayref { 
	my $s=shift;
	if (@_)  {
		$s->{arrayref} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		# remove other text storage
		delete($s->{scalarref});
		delete($s->{filename});
		delete($s->{options}->{filename});
		delete($s->{filehandle});
	};
	return $s->{arrayref};
}

sub filehandle { 
	my $s=shift;
	if (@_)  {
		$s->{filehandle} = shift;
		# reload local file
		$s->{_auto_parse} = 1;	
		# remove other text storage
		delete($s->{scalarref});
		delete($s->{arrayref});
		delete($s->{filename});
		delete($s->{options}->{filename});
	};
	
	return $s->{filehandle};
}

sub reloadFile {
	my $self = shift;
	$self->{_auto_parse} = 0;
	if ( defined $self->{filename} 
			&& ( !defined $self->{options}->{filename}
					|| $self->{filename} ne $self->{options}->{filename}
				)
		) {
		$self->{options}->{filename} = $self->{filename};
		my $filepath = $self->_find_file($self->{filename});  
		$self->{options}->{filepath} = $self->{filename};
	} elsif (exists($self->{scalarref})) {
    	$self->{options}->{scalarref} = $self->{scalarref};
	} elsif (exists($self->{arrayref})) {
		$self->{options}->{arrayref}=$self->{arrayref};
	} elsif (exists($self->{filehandle})) {
		$self->{options}->{filehandle} = $self->{filehandle};
	}
	$self->{filter} = $self->{filter_internal};
	$self->{options}->{filter}= $self->{filter};
	$self->_init_template();
	# local caching params
	my %params;
	my @parname = $self->param();
	foreach (@parname) {
		$params{$_} = $self->param($_);
	}
	$self->_parse();
	# reassign params
	foreach (keys(%params)) {
		$self->param($_=> $params{$_});
	}
	# now that we have a full init, cache the structures if cacheing is
	# on.  shared cache is already cool.
	if($self->{options}->{file_cache}){
	$self->_commit_to_file_cache();
	}
	$self->_commit_to_cache() if (($self->{options}->{cache}
	                            and not $self->{options}->{shared_cache}
	                            and not $self->{options}->{file_cache}) or
	                            ($self->{options}->{double_cache}) or
	                            ($self->{options}->{double_file_cache}));
}


sub _reloadFilter {
	my $self = shift;
	undef $self->{filter_internal} ;
	$self->{plugins_cid} = {};
	# plugin priority filter
	{
		foreach (values %{$self->{plugins}}) {
			$self->_pushModule($_);
	    }
    }
}

#sub _loadDynamicModule {
#	my $self = shift;
#	{
#		foreach (keys %{$self->{plugins}}) {
#			$self->_initModule($_);
#	    }
#	}
#} 

sub _importModule {
	my $self		= shift;
	my $module_name	= shift;
	
	$module_name	=~s/::/\//g;
	require $module_name . ".pm";
}

sub _initModule {
	my $self		= shift;
	my $module		= shift;
	if (ref($module) eq '') {
		$self->_importModule($module); 
		no strict "refs";
		&{$module . "::init"}($self);
	} else {
		$module->init($self);
	}
}

sub _pushModule {
	my $self		= shift;
	my ($module, $module_name) 	= $self->_module_info(shift);
	if (exists $self->{plugins_cid}->{$module_name}) {
		# esiste gia' qualcosa di caricato...lo devo scaricare
		# prima di poter fare qualsiasi cosa
		my @code_ids = @{$self->{plugins_cid}->{$module_name}};
		foreach (@code_ids) {
			$self->_remove_filter_id($_);
		}
		delete $self->{plugins_cid}->{$module_name};
	}
	# count coderef items
	my $pre_code_count = $self->{filter_internal} ? scalar(@{$self->{filter_internal}})-1 : -1 ;
	if (ref($module) eq '') {
		no strict "refs";
        &{$module . "::push_filter"}($self);
	} else {
		$module->push_filter($self);
	}
	# count coderef items after push_filter
	my $post_code_count = $self->{filter_internal} ? scalar(@{$self->{filter_internal}})-1 : -1;
	return if ($post_code_count == $pre_code_count);
	return if ($post_code_count <0);
	$pre_code_count++;
	# so this module as add post-pre code items
	if (exists($self->{plugins_cid}->{$module_name})) {
		push @{$self->{plugins_cid}->{$module_name}},($pre_code_count .. 
				$post_code_count)
	} else {
		$self->{plugins_cid}->{$module_name} = [$pre_code_count ..
                $post_code_count];
	}
}


sub filter { my $s=shift; return @_ ? ($s->{filter_internal}=shift) : $s->{filter_internal} }

sub plugin_add { 
	my $s		= shift; 
	if (@_)  {
		my ($module, $module_name) 	= $s->_module_info(shift);
		# plugin gia caricato
		return if (exists $s->{plugins}->{$module_name});
		$s->{plugins}->{$module_name} = $module;
		# init module
		$s->_initModule($module);
		# add filter from added module to me
		$s->_pushModule($module);
		# add the array id of added code 
		$s->{_auto_parse} = 1;
	};
	return $s->{plugins}
}

sub plugin_remove {
	my $s		= shift;
	my ($module, $module_name) 	= $s->_module_info(shift);
	delete $s->{plugins}->{$module_name};
	if (exists $s->{plugins_cid}->{$module_name}) {
		my @code_ids = @{$s->{plugins_cid}->{$module_name}};
		foreach (@code_ids) {
			$s->_remove_filter_id($_);
		}
	}
	delete $s->{plugins_cid}->{$module_name};
	$s->{_auto_parse} = 1;
}

sub _remove_filter_id {
	my $s		= shift;
	my $f_id	= shift;
	my @a		= ();
	push @a, @{$s->{filter_internal}}[0 .. $f_id-1] if ($f_id>0);
	push @a, @{$s->{filter_internal}}[$f_id+1 .. $#{$s->{filter_internal}}]
		if ($f_id< $#{$s->{filter_internal}});
	$s->{filter_internal} = \@a;
}

sub plugins_clear { 
	my $s = shift;
	undef $s->{plugins};
	undef $s->{options}->{plugins};
	undef $s->{filter_internal};
	$s->{plugins_cid} = {};
	return $s->{plugins};
}

sub DESTROY {
}

sub AUTOLOAD {
	my $self = shift;
	my @procs = split(/::/,$HTML::Template::Extension::AUTOLOAD);
	return if (scalar(@procs)<3);
	my $proc = $procs[-1];
	my $value;
	no strict "refs";
	foreach my $module (values %{$self->{plugins}}) {
		my $ret;
		if (ref($module)) {
			#$ret	= eval { return $module->
		} else {
			$ret=  eval { return &{"${module}::$proc"}($self,@_) };
		}
		if (!$@) { return  $ret };
	};
}

sub _module_info {
		my $self 	= shift;
		my $module 	= shift;
		my $module_name;
		if (ref($module)) {
			$module_name = ref($module);
		} else {
			$module = "HTML::Template::Extension::$module" 
				if ($module!~/::/);
			$module_name = $module;
		}
		return ($module,$module_name);
}



1;
