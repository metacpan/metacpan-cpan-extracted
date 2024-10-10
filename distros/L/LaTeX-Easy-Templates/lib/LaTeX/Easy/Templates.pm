package LaTeX::Easy::Templates;

#########

### NOTE: latex basedir will be copied ALL, even if you specify a filepath!!

##########

use 5.010;
use strict;
use warnings;

our $VERSION = '1.0';

use Exporter qw(import);
our @EXPORT = qw(
	latex_driver_executable
);

use LaTeX::Driver;
use Text::Xslate;
use Mojo::Log;
use File::Spec;
use Clone qw/clone/;
use File::Temp qw/tempdir tempfile/;
use File::Basename;
use File::Path 'make_path';
use File::Copy::Recursive qw/fmove rcopy/;
use Filesys::DiskUsage qw/du/;
use File::Which;
use Cwd 'abs_path';

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

# these are the allowed parameters to be passed to
# LaTeX::Driver's constructor by the user of current module:
my @OPTIONS_ALLOWED_TO_BE_PASSED_TO_LATEX_DRIVER = qw/
	format paths maxruns extraruns timeout indexstyle
	indexoptions DEBUG DEBUGPREFIX
/;

# constructor, 
sub new {
	my $class = $_[0];
	my $params = $_[1] // {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $self = {
		'_private' => {
			'processors' => {
				'templater_object' => undef, # in init
				# stores all templates loaded into the templater and are known and need not be loaded (read) again
				'loaded-info' => {},
			},
			# we use these defaults if anybody is missing this information
			# for example 'processors' needs a latex output filename
			# if that is missing, then we take it from here.
			# these defaults can be set by the caller e.g. with params->{latex}->{...}
			'options' => {
				'latex' => {
					# these will be used only if 'processor'->{id} does not define them
					# default latex OUTPUT file
					# produced via the latex template
					'filename' => 'main.tex',
					'latex-driver-parameters' => {
						'format' => 'pdf(pdflatex)',
					},
				},
				'debug' => {
					'verbosity' => 0, # zero is mute
					'cleanup' => 1, # 1: cleanup all tempfiles after exit including LaTeX::Driver's, 0: leave tempfiles after exit
				},
				'tempdir' => undef, # we will use a standard tempdir if none specified later
				# if any of auxfiles' or basedir's  total (recursively calculated) file size
				# exceeds this limit, file copy will be aborted and untemplate() will fail
				'max-size-for-filecopy' => 3*1024*1024, # bytes
				# Saved parameters to be passed
				# to the constructor of the templater (e.g. Text::Xslate)
				# there are defaults below
				# they can be overwritten by param: 'templater-parameters'
				'templater-parameters' => {},
			},
			'log' => {
				'logger_object' => undef,
			},
		},
	};
	bless $self => $class;

	# NOTE: up until now we do not have a logger, we either use STDERR or die()

	# do we have a logger specified in params?
	if( exists($params->{'logfile'}) && defined($params->{'logfile'}) ){
		my $adir = File::Basename::dirname($params->{'logfile'});
		if( ! -d $adir ){ make_path($adir); if( ! -d $adir ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, logfile directory '$adir' is not a dir or failed to be created.\n"; return undef } }
		$self->log( Mojo::Log->new(path => $params->{'logfile'} ) )
	} elsif( exists($params->{'logger_object'}) && defined($params->{'logger_object'}) ){
		$self->log( $params->{'logger_object'} )
	} else { $self->log( Mojo::Log->new() ) }

	# Now we have a logger
	my $log = $self->log();

	my $options = $self->options();

	# check for some required fields in params:
	if( ! defined($self->options($params)) ){ $log->error(perl2dump($params)."${whoami} (via $parent), line ".__LINE__." : error, failed to parse input parameters, see above."); return undef }

	my $verbosity = $self->verbosity();

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	# this will instantiate objects we store etc. (if any)
	if( $self->init() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to init() has failed."); return undef }

	# user can set Text::Xslate constructor parameters via 'templater-parameters'
	# these are our defaults
	$options->{'templater-parameters'}->{'warn_handler'} = sub { $log->warn($_[0]) };
	$options->{'templater-parameters'}->{'die_handler'} = sub { $log->error($_[0]); die $_[0] };
	$options->{'templater-parameters'}->{'verbose'} = $verbosity;
	# Text::Xslate syntax to use, it is one of Kolon or TTerse
	# Kolon is used in all our tests!
	$options->{'templater-parameters'}->{'syntax'} = 'Kolon';
	# the suffix of template files
	$options->{'templater-parameters'}->{'suffix'} = '.tx';
	# stop silly-escaping for html or xml,
	# this makes the use of mark_raw redundant ouph!
	$options->{'templater-parameters'}->{'type'} = 'text';
	# note: you can specify functions to be called in the template
	#'function' => {
	#	'templatedir' => sub { # it takes an input param as input $args }
	#}
	# and make shallow copies of whatever params the user specified:
	if( exists($params->{'templater-parameters'}) && defined($params->{'templater-parameters'}) ){
		if( ref($params->{'templater-parameters'}) ne 'HASH' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'templater-parameters' must be a HASHref."); return undef }
		# warning: shallow copy!
		for my $k (keys %{ $params->{'templater-parameters'} }){ $options->{'templater-parameters'}->{$k} = $params->{'templater-parameters'}->{$k} }
	}

	# required input parameter 'processors' must be a hash
	#   keys: id of the processor, just a name.
	#   values: ...
	# this parameter contains all the template processors
	if( ! exists($params->{'processors'}) || ! defined($params->{'processors'})
	 || (ref($params->{'processors'})ne'HASH')
	 || (scalar(keys %{ $params->{'processors'} })==0)
	){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'processors' was not specified or it was not a HASH or it was empty."); return undef }
	my %pars = (
		'processors' => $params->{'processors'}
	);
	if( ! defined $self->_init_processors_data(\%pars) ){ $log->error("--begin parameters:\n".perl2dump(\%pars)."--end parameters.\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'_init_processors_data()'." has failed for above parameters."); return undef }

	# done!
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done, success.") }
	return $self
}

# this function will eventually produce a PDF either
#  from the specified latex source or
#  from the specified template name (as loaded during contruction)
# If the template is specified in the parameters, then it will call
#   untemplate()
# to produce the latex source dir as a copy of the template dir
# (i.e. with all sty/bib/image files contained therein)
# plus the latex source (produced from the template file)
# In this case the latex dir to contain all these will be temporary
# unless specified in the parameters.
# Required input parameters:
#  'output' => {'filename', 'filepath', 'basedir'} << the final pdf file, it needs filename+basedir OR filepath
#  'template' => {'filename', 'filepath', 'basedir'} << filename+basedir OR filepath
# OR
#  when specifying ALL of the following 3,
#  it means caller is supplying a latex src file (and not a template)
#  which means we just render the latex src:
#  (either created via a template or just yours)
#  'latex' => {'filename', 'filepath', 'basedir'} (filename+basedir OR filepath)
# OR
#  specify these when you have a latex TEMPLATE file. We will process
#  the template and create the latex src file and then we render it as above:
#  'template' => {'filename', 'filepath', 'basedir'} (filename+basedir or filepath)
#  'template-data' : hash with data to be substituted into the template
#  'processor' : this is the id/name of the 'processor' holding
#		 template processing parameters, as specified in the constructor's
#                'processors' (which is a HASH and this specified processor is a key to it)
#		 This processor will be used to turn the template into latex src.
#
# It RETURNS undef on failure or a hash, with following keys, on success:
#  'latex' => {'filename', 'filepath', 'basedir'} << this now exists and is the latex src
#  'template' => {'filename', 'filepath', 'basedir'} << this is what it was specified as input param
sub format {
	my ($self, $params) = @_;
	$params //= {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $options = $self->options();
	my $verbosity = $self->verbosity();

	my $starttime = time;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	# if ANY of these were specified in the input params, then
	# it means we have a latex src file and not a template
	# we just need to run latex on that file
	my @latexsrcparams_names = ('basedir', 'filepath', 'filename');

	# this will be returned: %latexsrcparams

	my ($template_data, $latex_driver_params, $processor_data, $processor_name, $group, $al);

	# we are reading this data from 'procesors' set during construction time
	if( ! exists($params->{'processor'})
	 || ! defined($processor_name=$params->{'processor'})
	){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'processor' was not specified and it is required since no latex-file-parameters were specified (@latexsrcparams_names). I need to produce latex files from a template and 'processor' is the id/name of this processor."); return undef }
	my $loaded_info = $self->loaded_info();
	if( ! exists($loaded_info->{$params->{'processor'}}) || ! defined($params->{'processor'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, specified processor '".$params->{'processor'}."' is not known. These are all the known processors: '".join("','", sort keys %$loaded_info)."'."); return undef }
	$processor_data = $loaded_info->{$params->{'processor'}};

	my $need_to_run_untemplate = 0;
	$group = 'template';
	my $template_info = {};
	if( (exists($params->{$group}) && defined($al=$params->{$group}))
	 || (exists($processor_data->{$group}) && defined($al=$processor_data->{$group}))
	){
		my ($af, $ab);
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$template_info->{'filepath'} = Cwd::abs_path($af) // $af;
			$template_info->{'filename'} = File::Basename::basename($template_info->{'filepath'});
			$template_info->{'basedir'} = File::Basename::dirname($template_info->{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item $group->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$template_info->{'filename'} = $af;
			$template_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$template_info->{'filepath'} = File::Spec->catfile(
				$template_info->{'basedir'},
				$template_info->{'filename'}
			);
		} elsif( exists($al->{'content'}) && defined($al->{'content'}) ){
			$template_info->{'content'} = $al->{'content'};
			for (qw/filename basedir filepath/){ $template_info->{$_} = undef }
		} else { $log->error(perl2dump($al)."${whoami} (via $parent), line ".__LINE__." : error, group '$group' must contain key 'content' (for in-memory template) or 'filepath' or 'filename' AND 'basedir' but it didn't, above is what it has."); return undef }

		# do we have any aux files to copy into the tmpdirs for the processing, e.g. perhaps
		# images needed by the template, or other template files to be included
		# you need to specify them here with ['fullpath-a', 'fullpath-b', ...]
		if( exists($al->{'auxfiles'}) && defined($al->{'auxfiles'}) ){
			if( ref($al->{'auxfiles'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, parameter 'template'->'auxfiles' needs to be an ARRAYref."); return undef }
			$template_info->{'auxfiles'} = $al->{'auxfiles'};
		}

		$template_data = exists($params->{'template-data'}) && defined($params->{'template-data'}) ? $params->{'template-data'} : undef;
		$need_to_run_untemplate = defined($template_data) ? 1 : 0;
	} else {
		$need_to_run_untemplate = 0; #<< no template! we need a latex source file then
	}

	# optionally we have a latex filepath/filename
	$group = 'latex';
	my $latex_info = {};
	if( (exists($params->{$group}) && defined($al=$params->{$group}))
	 || (exists($processor_data->{$group}) && defined($al=$processor_data->{$group}))
	){
		my ($af, $ab);
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$latex_info->{'filepath'} = Cwd::abs_path($af) // $af;
			$latex_info->{'filename'} = File::Basename::basename($latex_info->{'filepath'});
			$latex_info->{'basedir'}  = File::Basename::dirname($latex_info->{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item $group->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$latex_info->{'filename'} = $af;
			$latex_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$latex_info->{'filepath'} = File::Spec->catfile(
				$latex_info->{'basedir'},
				$latex_info->{'filename'}
			);
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'}) ){
			# we have a basedir only, that means we need a template and this will
			# be the output dir with the default latex source file
			$need_to_run_untemplate = 1;
			$latex_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$latex_info->{'filename'} = $self->options()->{'latex'}->{'filename'}; # default latex out filename
			$latex_info->{'filepath'} = File::Spec->catfile(
				$latex_info->{'basedir'},
				$latex_info->{'filename'}
			);
		}
	}

	if( defined($latex_info->{'basedir'}) && (! -d $latex_info->{'basedir'}) ){ make_path($latex_info->{'basedir'}); if( ! -d $latex_info->{'basedir'} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, dir to place latex source files '".$latex_info->{'basedir'}."' is not a dir and could not be created."); return undef } }

	$group = 'output';
	my $output_info = {};
	if( exists($params->{$group}) && defined($al=$params->{$group})
	 || (exists($processor_data->{$group}) && defined($al=$processor_data->{$group}))
	){
		my ($af, $ab);
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$output_info->{'filepath'} = Cwd::abs_path($af) // $af;
			$output_info->{'filename'} = File::Basename::basename($output_info->{'filepath'});
			$output_info->{'basedir'} = File::Basename::dirname($output_info->{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item $group->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$output_info->{'filename'} = $af;
			$output_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$output_info->{'filepath'} = File::Spec->catfile(
				$output_info->{'basedir'},
				$output_info->{'filename'}
			);
		} else { $log->error(perl2dump($al)."${whoami} (via $parent), line ".__LINE__." : error, group '$group' must contain key 'filepath' or 'filename' AND 'basedir' but it didn't, above is what it has"); return undef }
	} else {
		# we are reading this data from 'procesors' set during construction time
		$output_info = Clone::clone($loaded_info->{$group});
	}
	if( defined($output_info->{'basedir'}) && (! -d $output_info->{'basedir'}) ){ make_path($output_info->{'basedir'}); if( ! -d $output_info->{'basedir'} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, dir to place output files '".$output_info->{'basedir'}."' is not a dir and could not be created."); return undef } }

	# either we have latex src params meaning
	# that we have a latex src file
	# else (below) we need to run untemplate()
	if( $need_to_run_untemplate == 0 ){
		# We don't have a template file, we have a latex src file,
		# because caller has already run untemplate() or none was required
		if( $verbosity > 0 ){ $log->info(perl2dump($latex_info)."--end latex source parameters.\n${whoami} (via $parent), line ".__LINE__." : latex source file was specified in the input parameters, see above. There is no need to run untemplate() ...") }
		if( ! -f $latex_info->{'filepath'} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, latex source 'filepath' (".$latex_info->{'filepath'}.") does not exist or is not a file."); return undef }
		if( ! exists($latex_info->{'content'}) || ! defined($latex_info->{'content'}) ){
			# no latex content was specified, read it from the filepath
			my $FH;
			if( ! open($FH, '<:utf8', $latex_info->{'filepath'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open latex source file '".$latex_info->{'filepath'}."' for reading latex content : $!"); return undef }
			{ local $/ = undef; $latex_info->{'content'} = <$FH> } close $FH
		}
	} else {
		# we need to produce the latex src file because what we have is a template
		# so we run untemplate()
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : untemplate() needs to be called in order to produce the latex source ...") }

		my %pars;
		if( ! exists($params->{'processor'})
		 || ! defined($params->{'processor'})
		){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'processor' was not specified and it is required since no latex-file-parameters were specified (@latexsrcparams_names). I need to produce latex files from a template and 'processor' is the id/name of this processor."); return undef }

		$pars{'processor'} = $processor_name;

		# we need template-data for sure
		if( ! defined($template_data) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'template-data' (which contains data to render the templated latex file into a proper latex source file) was not specified but it is absolutely needed."); return undef }

		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : a template processor '".$pars{'processor'}."' has been specified ..."); }

		my $tpars = {
			%pars,
			'latex' => $latex_info,
			'template' => $template_info,
			'template-data' => $template_data,
		};

		my $ret = $self->untemplate($tpars);
		if( ! defined $ret ){
			$log->error(($verbosity>1?(perl2dump($tpars)."--end parameters.\n"):"")."${whoami} (via $parent), line ".__LINE__." : error, call to ".'untemplate()'." has failed for above parameters.");
			return undef
		}
		$latex_info = Clone::clone($ret->{'latex'});
		$template_info = Clone::clone($ret->{'template'});
		if( $verbosity > 0 ){ $log->info(perl2dump($latex_info)."--end latex source parameters.\n${whoami} (via $parent), line ".__LINE__." : latex source file has been created from specified template and template data via ".'untemplate()'.", see details above.") }
	}

	# we are not sure we have a $latex_info->{'content'} here
	#die unless exists($latex_info->{'content'}) && defined($latex_info->{'content'});

	my $outfile = $output_info->{'filepath'};
	if( defined($outfile) && ($verbosity > 0) ){ $log->info("${whoami} (via $parent), line ".__LINE__." : output will be written to file '$outfile'."); }

	# at this point we have latex src either from caller or from template,
	# we will process it with LaTeX::Driver
	my %drivparams = (
 		# all output will go to the dirname of the source filepath, so make sure it is a path
		'source' => $latex_info->{'filepath'},
		# this is now commented, the output will be where the input tex file will be,
		# later on in here, we move to outfile if one was specified
		# who wrote this checks if $outfile can be broken into $volume, $dir, file with File::Spec->splitpath
		# and if $dir is empty it dies, so make sure that output
		# file contains some form of a dir, at least './' etc.
		#'output' => $outfile,
		# pdflatex is standard in installations i guess, this can be
		# overwritten with the 'latex-driver-parameters' specified
		'format' => 'pdf(pdflatex)',
		# use xelatex when you have unicodez and multi-language, you can set this on per-case
		#'format' => 'pdf(xelatex)',
		'DEBUG'  => $verbosity,
#		'texinputs' => $latex_info->{'basedir'},
#		'basedir' => $outdir,
		# if tmpdir=1 it will override the 'basedir' param below
		# which will die if tex file depends on images/sty files in the folder
		'tmpdir' => 0, # use a tempdir that it will make itself for output the aux files and shit, no need to retain this.
		# removes all tmp files created, use 'none' not to
		'cleanup' => ($self->cleanup()>0) ? 'tempfiles' : 'none',
		'capture_stderr' => 1,
	);

	# We allow *SOME* LaTeX::Driver options to be set via input params or
	# the processor or the configuration hash (in this order)
	my $extra_driver_params;
	if( exists($params->{'latex-driver-parameters'}) && defined($params->{'latex-driver-parameters'}) ){
		$extra_driver_params = $params->{'latex-driver-parameters'};
	} elsif( defined($processor_data) && exists($processor_data->{'latex'}) && exists($processor_data->{'latex'}->{'latex-driver-parameters'}) && defined($processor_data->{'latex'}->{'latex-driver-parameters'}) ){
		$extra_driver_params = $processor_data->{'latex'}->{'latex-driver-parameters'};
	} elsif( exists($options->{'latex'}->{'latex-driver-parameters'}) && defined($options->{'latex'}->{'latex-driver-parameters'}) ){
		$extra_driver_params = $options->{'latex'}->{'latex-driver-parameters'};
	}

	if( defined $extra_driver_params ){
		# this is what we allow to be set into the LaTeX::Driver new() parameters:
		for my $ak (qw /
			format paths maxruns extraruns timeout indexstyle
			indexoptions DEBUG DEBUGPREFIX
		/){
			if( exists($extra_driver_params->{$ak}) ){
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : setting LaTeX::Driver parameter '$ak' from user-specified value ...") }
				$drivparams{$ak} = $extra_driver_params->{$ak}
			}
		}
	}

	if( $verbosity > 0 ){
		if( $verbosity > 1 ){ $log->info("--begin parameters:\n".perl2dump(\%drivparams)."--end parameters.\n${whoami} (via $parent), line ".__LINE__." : processing latex file '".$latex_info->{'filepath'}."' with above parameters and it may take long time (you can always do this manually with xelatex '".$latex_info->{'filepath'}."' -- if not a temp file) ...") }
		elsif( $verbosity == 1 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : processing latex file '".$latex_info->{'filepath'}."' with above parameters ...") }
	}

	my $latex_driver = LaTeX::Driver->new(%drivparams);
	if( ! defined $latex_driver ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'LaTeX::Driver->new()'." has failed."); return undef }

	# reset latex so that it does run even if a .aux file exists (in case we run again in this dir)
	$latex_driver->rerun_required(1);

	# this returns 1 on success or exception on failure
	my $ret = eval { $latex_driver->run() };
	if( $@ ){
		my ($filecontents, $aFH);
		if( open($aFH, '<:utf8', $latex_info->{'filepath'}) ){
			{ local $/ = undef; $filecontents = <$aFH> } close $aFH;
		} else { $filecontents="<file contents na>"; $log->error("error, failed to open input latex file for reading '".$latex_info->{'filepath'}."' and will not be able to display the latex file contents for the error message following : $!"); }
		$log->error("error caught:\n--begin file contents:\n${filecontents}\n--end file contents.\n\n--begin stderr:\n".($latex_driver->stderr()//"<stderr na>")."\n--end stderr.\n\n--begin parameters:\n".perl2dump(\%drivparams)."--end parameters.\n${whoami} (via $parent), line ".__LINE__." : error, failed to run latex on file '".$latex_info->{'filepath'}."' with above parameters, exception was caught: $@");
		return undef
	}
	if( $ret != 1 ){
		my ($filecontents, $aFH);
		if( open($aFH, '<:utf8', $latex_info->{'filepath'}) ){
			{ local $/ = undef; $filecontents = <$aFH> } close $aFH;
		} else { $filecontents="<file contents na>"; $log->error("error, failed to open input latex file for reading '".$latex_info->{'filepath'}."' and will not be able to display the latex file contents for the error message following : $!"); }
		$log->error("error caught:\n--begin file contents:\n${filecontents}\n\n--end file contents.--begin stderr:\n".($latex_driver->stderr()//"<stderr na>")."\n--end stderr.\n--begin stdout:\n".($latex_driver->stdout()//"<stdout na>")."\n--end stdout.\n\n--begin parameters:\n".perl2dump(\%drivparams)."--end parameters.\n${whoami} (via $parent), line ".__LINE__." : error, failed to run latex on file '".$latex_info->{'filepath'}."' with above parameters (status was not 1): ".$latex_driver->stderr);
		return undef
	}

	# the pdf output will be in the latex's basedir and its name
	# will be the same as latex source file except the extension will be .pdf
	my $actual_pdf_outfile = $latex_info->{'filepath'};
	$actual_pdf_outfile =~ s/\.tex$/.pdf/i;

	if( defined $outfile ){
		# an output file was specified, so we move the produced pdf to that file
		my $outfiledir = $output_info->{'basedir'};
		if( ! -d $outfiledir ){ make_path($outfiledir); if( ! -d $outfiledir ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the parent dir of the 'outfile' specified ('$outfile' in dir '$outfiledir') could not be created or it is not a dir, exiting but pdf is at '$actual_pdf_outfile'."); return undef } }
		if( ! File::Copy::Recursive::fmove($actual_pdf_outfile, $outfile) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error failed to move '$actual_pdf_outfile' to '$outfile': $!"); return undef }
	} else {
		# no output file was specified so update all the info
		$outfile = $actual_pdf_outfile;
		$output_info->{'basedir'} = File::Basename::dirname($outfile);
		$output_info->{'filepath'} = $outfile;
		$output_info->{'filename'} = File::Basename::basename($outfile);
	}

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done, success in ".(time-$starttime)." seconds. LaTeX was run and pdf output was created into '${outfile}' (source latex file: '".$latex_info->{'filepath'}."').") }

	return {
		'latex' => $latex_info,
		'template' => $template_info,
		'output' => $output_info,
	}; # success
}

# this will create a latex src file from a latex template
# PLUS: it will place it in a new dir (which will create) and in there will
# copy, recursively, all files from the template dir
# into the user-specified destination dir ('latex-src-dir')
# So, at the end 'latex-src-dir' will contain exactly what template dir
# contains plus the latex source (created from the template)
# if template was an in-memory string, then the deistnation dir
# will contain just latex source file as there is really no template dir
# Required input parameters:
#  'latex' => {
#   optional:
#   'filename', 'filepath', 'basedir' : either filename AND basedir or just filepath
#      this is the produced output latex source file or some tmp if none specified
# },
#  'template' => {'filename'+'basedir' OR 'filepath' OR 'content'(for in-memory))
#  'template-data' : hash with data to be substituted into the template
# It RETURNS undef on failure or this hash on success:
#  'latex' => { 'filename', 'filepath', 'basedir' }, << produced latex source etc.
#  'template' => { 'filename', 'filepath', 'basedir' }, << these can be undef if template was in-memory
# The returned hash can be passed on to format() for producing the PDF
# (or run format() directly by passing it the template file)
sub untemplate {
	my ($self, $params) = @_;
	$params //= {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $template_data;
	if( ! exists($params->{'template-data'}) || ! defined($template_data=$params->{'template-data'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, inpur parameter 'template-data' was not specified."); return undef }

	my $LI = $self->loaded_info();
	my ($loaded_info, $processor);
	if( exists($params->{'processor'}) && defined($processor=$params->{'processor'}) ){
		if( ! exists($LI->{$processor}) || ! defined($loaded_info=$LI->{$processor}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, 'processor' name '$processor' was not found, these are the known processors: '".join("', '", sort keys %$LI)."'."); return undef }
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, parameter 'processor' was not specified."); return undef }

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called with processor '${processor}' ...") }

	my $al;

	# user can specify a 'latex' hash for overriding loaded-info 'latex'
	# and/or 'template'

	my $group = 'latex';
	my $latex_info = {};
	if( exists($params->{$group}) && defined($al=$params->{$group}) ){
		my ($af, $ab);
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$latex_info->{'filepath'} = Cwd::abs_path($af) // $af;
			$latex_info->{'filename'} = File::Basename::basename($latex_info->{'filepath'});
			$latex_info->{'basedir'} = File::Basename::dirname($latex_info->{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item $group->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$latex_info->{'filename'} = $af;
			$latex_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$latex_info->{'filepath'} = File::Spec->catfile(
				$latex_info->{'basedir'},
				$latex_info->{'filename'}
			);
		} else { $log->error(perl2dump($al)."${whoami} (via $parent), line ".__LINE__." : error, group '$group' must contain key 'filepath' or 'filename' AND 'basedir' but it didn't, above is what it has"); return undef }
	} else {
		# we are reading this data from 'procesors' set during construction time
		$latex_info = Clone::clone($loaded_info->{$group});
	}
	if( defined($latex_info->{'basedir'}) && (! -d $latex_info->{'basedir'}) ){ make_path($latex_info->{'basedir'}); if( ! -d $latex_info->{'basedir'} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, dir to place latex source files '".$latex_info->{'basedir'}."' is not a dir and could not be created."); return undef } }

	$group = 'template';
	my $template_info = {};
	# this will be set if basedir was specified, then we will copy
	# all contents of basedir into latex dir
	# perhaps there are images in there that are needed, etc.
	my $need_to_copy_the_whole_dir = 0;
	if( exists($params->{$group}) && defined($al=$params->{$group}) ){
		my ($af, $ab);
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$template_info->{'filepath'} = Cwd::abs_path($af) // $af;
			$template_info->{'filename'} = File::Basename::basename($template_info->{'filepath'});
			$template_info->{'basedir'} = File::Basename::dirname($template_info->{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item $group->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$template_info->{'filename'} = $af;
			$template_info->{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$template_info->{'filepath'} = File::Spec->catfile(
				$template_info->{'basedir'},
				$template_info->{'filename'}
			);
			$need_to_copy_the_whole_dir = 1;
		} elsif( exists($al->{'content'}) && defined($al->{'content'}) ){
			$template_info->{'content'} = $al->{'content'};
			for (qw/filename basedir filepath/){ $template_info->{$_} = undef }
		} else { $log->error(perl2dump($al)."${whoami} (via $parent), line ".__LINE__." : error, group '$group' must contain key 'content' (for in-memory template) or 'filepath' or 'filename' AND 'basedir' but it didn't, above is what it has."); return undef }

		# do we have any aux files to copy into the tmpdirs for the processing, e.g. perhaps
		# images needed by the template, or other template files to be included
		# you need to specify them here with ['fullpath-a', 'fullpath-b', ...]
		if( exists($al->{'auxfiles'}) && defined($al->{'auxfiles'}) ){
			if( ref($al->{'auxfiles'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, parameter 'template'->'auxfiles' needs to be an ARRAYref."); return undef }
			$template_info->{'auxfiles'} = $al->{'auxfiles'};
		}
	} else {
		# we are reading this data from 'procesors' set during construction time
		$template_info = Clone::clone($loaded_info->{$group});
	}

	# some of these filenames/paths will be undef if template is memory
	if( ($need_to_copy_the_whole_dir == 1)
	 && exists($template_info->{'basedir'}) && defined($template_info->{'basedir'})
	){
		# basedir was explicitly specified, we copy all its contents
		my $tmpdir = File::Spec->catdir($template_info->{'basedir'}, '.');
		if( $self->max_size_for_filecopy() >= 0 ){
			# check the max limit if >=0 else we don't do the check
			my $total_size = Filesys::DiskUsage::du($tmpdir);
			if( $total_size > $self->max_size_for_filecopy() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the size of 'template'->'basedir' is ${total_size} bytes but the maximum size allowed is ".$self->max_size_for_filecopy().". Reconsider or change the max file size via a call to max_size_for_filecopy(). Setting it to -1 will skip this check."); return undef }
		}
		if( ! File::Copy::Recursive::rcopy($tmpdir, $latex_info->{'basedir'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to copy contents of template dir '$tmpdir' into output dir '".$latex_info->{'basedir'}."'."); return undef }
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template container dir ($tmpdir) was copied into the output dir (".$latex_info->{'basedir'}."). This is because 'template'->'basedir' was explicitly specified. If you do not want this then specify 'filepath' instead.") }
	}

	if( exists($template_info->{'filepath'}) && defined($template_info->{'filepath'}) ){
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template exists on-disk (with name '$processor').") }
	} else {
		# we have an in-memory template and templater object works well with this
		# outdir is already created, so all is well
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template is an in-memory string (with name '$processor').") }
	}

	# copy any auxfiles/dirs into output
	if( exists($template_info->{'auxfiles'}) && defined($template_info->{'auxfiles'}) ){
		# we have aux files to copy to the latex dir, images, other templates, style files etc.
		for my $apath (@{ $template_info->{'auxfiles'} }){
			if( $self->max_size_for_filecopy() >= 0 ){
				# check the max limit if >=0 else we don't do the check
				my $total_size = Filesys::DiskUsage::du($apath);
				if( $total_size > $self->max_size_for_filecopy() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the size of '$apath' (specified via 'template'->'auxfiles') is ${total_size} bytes but the maximum size allowed is ".$self->max_size_for_filecopy().". Reconsider or change the max file size via a call to max_size_for_filecopy(). Setting it to -1 will skip this check."); return undef }
			}
			if( ! File::Copy::Recursive::rcopy($apath, $latex_info->{'basedir'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to copy auxiliary file/dir specified via 'template'->'auxfiles' ($apath) into output dir '".$latex_info->{'basedir'}."'."); return undef }
			if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : auxiliary file/dir ($apath) was copied into the output dir (".$latex_info->{'basedir'}.").") }
		}
	}

	# Text::Xslate object:
	my $tobj = $self->templater();

	my $tdata = {
		'data' => $template_data,
		'private' => {
			'template' => $template_info
		}
	};

	# e.g. xslateobj->render('hello.tx', \%vars);
	if( $verbosity > 2 ){ $log->info("--begin template info:\n".perl2dump($template_info)."--end template info.\n${whoami} (via $parent), line ".__LINE__." : rendering template with above data ..."); }
	my $latexstr = eval { $tobj->render($processor, $tdata) };
	if( ! defined $latexstr ){
		$log->error("--begin template vars:\n".perl2dump($tdata)."--end template vars.\n${whoami} (via $parent), line ".__LINE__." : error, exception caught during call to ".'templater->render()'." for ".(defined($template_info->{'filepath'})?"template file '".$template_info->{'filepath'}."'":"in-memory template '$processor'")." and above template vars data:\n\n  $@");
		return undef
	};
	if( ! defined $latexstr ){ $log->error("--begin template vars:\n".perl2dump($template_data)."--end template vars.\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'render()'." has failed for template file '".$template_info->{'filepath'}."' and above template vars data."); return undef }

	# write out the latex src str
	my $FH;
	if( ! open($FH, '>:utf8', $latex_info->{'filepath'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file '".$latex_info->{'filepath'}."' for writing out the produced latex source, $!"); return undef }
	print $FH $latexstr; close $FH;

	return {
		'template' => $template_info,
		'latex' => $latex_info,
	};
}

# any initialisation code goes here, it is called during construction
# when all the constructor parameters have been procesed
# It returns 1 on failure, 0 on success
sub init {
	my $self = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	if( ! defined $self->options()->{'tempdir'} ){ $self->options()->{'tempdir'} = File::Temp::tempdir(CLEANUP=>$self->cleanup()) }

	return 0 # success
}

####################################################################################
# It creates the templater object if not exists
# and adds any specified templates to it.
# Templates can be specified by means of the parameters key:
#   'processors'
# whose value is a HASH whose *KEYS* are:
#   1. the key is a name/nickname/alias for each template/latex/pdf item it contains.
# ... and its *VALUES* are: a HASH with these 3 items:
#   1. 'latex' : info about the latex src file TO BE PRODUCED (from template).
#                it can contain 'filename', 'basedir' and 'latex-driver-parameters'
#                NOTE: 'filename' is not path it is just a filename
#                if none specified, default/tmp will be used.
#   2. 'template' : info about the template to use with these keys:
#                   'filepath' => template-file-path
#              OR   'content' => template-in-memory-string
#              OR   nothing, in which case we use the latex src
#                   which must already exist on disk
#                   (via 'latex'->'basedir' and 'latex'->'filename')
#                   so, in this mode we are using a static latex src file (no template will be rendered).
#   3. 'output' : info about the output of compiling latex with keys
#                 'filename' and 'basedir' (defaults will be used if none specified).
#                 NOTE: 'filename' is not a path it is just a filename
#                 (relative to whatever outdir specified)
#
# Parameters to the constructor of Text::Xslate are held
# in $self->options()->{'templater-parameters'}
# and should have been specified via our constructor's
# parameters with a hash keyed on 'templater-parameters'.
# See Text::Xslate constructor documentation at
#   https://metacpan.org/pod/Text::Xslate#Text::Xslate-%3Enew(%25options)
# for the list of options.
#
# It returns undef on failure, the templater object on success
# (on success it saves the templater obj to self, on failure it does not change the previous)
# NOTE: calling this function a second time it will overwrite
#       the templater object created previously (and all templates loaded in it will be lost)
#       So, you need to load templates again.
# NOTE: ideally, you do not need to call this directly because it is called in the constructor
#       with the specified templates to new()
#################################################################################################
# Some info on Text::Xslate's path parameter in the constructor:
# T::X accepts 'path' in its constructor. This is an array or a single path (as a string scalar)
# Each item of the array can be either:
#   a scalar denoting a template dir
#     in which case you can render any file under this path, i.e. render('anyfile', ...)
#     or even any file under subdir as long as you specify
#        the subdir in the filename, i.e. render('subdir/subdir2/anyfile', ...)
# OR  
#   a hashref of just ONE key/value pair, in which case:
#     key: is a template alias which you can refer to
#          when you want to render it, i.e. render('myalias', ...)
#     value: is the template string content 
#   This case is for in-memory templates.
#
# NOTE: it is possible that an in-memory template includes disk-based (not in-memory) templates
#
# Below we load all templates in memory (TODO: can't we just load only those specified as inmemory?)
# and we also add into T::X's path the basedir in the case of include'ed templates.
#################################################################################################
sub _init_processors_data {
	my ($self, $params) = @_;
	$params //= {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity();
	my $options = $self->options();

	my (@filenames, $ak, $av, $m, %xslate_vpaths);
	if( ! exists($params->{'processors'}) || ! defined($params->{'processors'})
	 || (ref($params->{'processors'})ne'HASH')
	 || (scalar(keys %{ $params->{'processors'} })==0)
	){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'processors' was not specified or it is not a HASH or it is empty."); return undef }

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called for these processors: '".join("', '", sort keys %{ $params->{'processors'} })."'.") }

	# this is a list of paths to search for templates mainly for T::X's 'include'
	# WARNING: the include name is just like 'xyz.tex.tx' what happens if two or more
	# of these are to be found in the %template_inc_paths? We need to use distinct filenames I guess
	my %template_inc_paths;

	my $LI = $self->loaded_info();
	# the key is an id/alias/name for each processor item
	# and we store the parameters for each processor keyed on this name
	for $ak (keys %{ $params->{'processors'} }){
		my $av = $params->{'processors'}->{$ak};

		my ($content, $bdir, $fname, $al, $af, $ab, $ad,
		    %template_info, %latex_info, %output_info
		);
		my %loaded_info = (
			'template' => \%template_info,
			'latex' => \%latex_info,
			'output' => \%output_info # about the final pdf
		);

		# group: 'latex'
		# this is some info about produced latex src files
		# caller can specify nothing or a FILEPATH or a BASEDIR+FILENAME
		# if nothing, then we creare a temp basedir and filename will be
		# the default specified in $self->options
		# (which is set by default in options as main.tex if none exists)
		# note: FILEPATH is full path to the filename
		#       FILENAME is just the filename without the basedir
		#	BASEDIR is the dir component of the filepath
		my $group = 'latex';
		$al = (exists($av->{'latex'}) && defined($av->{'latex'}))
			? $av->{'latex'}
			: {}
		;

		# full path to the file
		if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
			$latex_info{'filename'} = File::Basename::basename($af);
			$latex_info{'filepath'} = Cwd::abs_path($af) // $af;
			$latex_info{'basedir'}  = File::Basename::dirname($latex_info{'filepath'});
		} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
		      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
		){
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item '$group'->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$latex_info{'filename'} = $af;
			$latex_info{'basedir'}  = Cwd::abs_path($ab) // $ab;
			$latex_info{'filepath'} = File::Spec->catfile(
				$latex_info{'basedir'},
				$latex_info{'filename'}
			);
		} elsif( exists($al->{'filename'}) && defined($af=$al->{'filename'}) ){
			# just a filename, basedir will be temp
			# if you want it at ./xx then set it via filepath
			if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item '$group'->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
			$latex_info{'filename'} = $af;
			$latex_info{'basedir'}  = $options->{'tempdir'};
			$latex_info{'filepath'} = File::Spec->catfile(
				$latex_info{'basedir'},
				$latex_info{'filename'}
			);
		} else {
			# nothing was specifed we use tempdir and a default latex filename
			$latex_info{'basedir'}  = $options->{'tempdir'};
			$latex_info{'filename'} = $options->{$group}->{'filename'};
			$latex_info{'filepath'} = File::Spec->catfile(
				$latex_info{'basedir'},
				$latex_info{'filename'}
			);
		}
		# also in this group we have the latex driver parameters
		$latex_info{'latex-driver-parameters'} = Clone::clone($options->{$group}->{'latex-driver-parameters'});
		if( exists($al->{'latex-driver-parameters'}) && defined($af=$al->{'latex-driver-parameters'}) ){
			for(keys %{ $options->{$group}->{'latex-driver-parameters'} }){
				if( exists($af->{$_}) && defined($af->{$_}) ){ $latex_info{'latex-driver-parameters'}->{$_} = $af->{$_} }
			}
		}

		# group: 'template'
		# and info about templates and setting up the templater object
		$group = 'template';
		if( exists($av->{$group}) && defined($al=$av->{$group}) ){
			if( exists($al->{'content'}) && defined($al->{'content'}) ){
				# optionally a basedir can be specified so that
				# if this template is calling other templates from disk
				# then it will be the search path for them
				$content = $al->{'content'};
				# we have an in-memory template, key is a nickname (a virtual filename sotospeak)
				# and value is the template content as a string
				%template_info = (
					'filename' => undef,
					'basedir' => undef,
					'content' => $content
				); # this still keeps the initial ref to \%templ...
				if( exists($al->{'basedir'}) && defined($al->{'basedir'}) ){
					# only in this case basedir can be ARRAYref
					# for many paths or just a string for a single path
					if( ref($al->{'basedir'}) eq 'ARRAY' ){
						$template_info{'basedir'} = $al->{'basedir'}->[0];
						$template_inc_paths{ $_ }++ for @{$al->{'basedir'}};
					} elsif( ref($al->{'basedir'}) eq '' ){
						$template_info{'basedir'} = $al->{'basedir'};
						$template_inc_paths{ $template_info{'basedir'} }++;
					} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, when 'template'->'content' is specified, optional 'basedir' can either be an ARRAYref or a scalar (string), and not '".ref($al->{'basedir'})."'."); return undef }
				}
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : template specified as in-memory string.") }
			} elsif( exists($al->{'basedir'}) && defined($ab=$al->{'basedir'})
			      && exists($al->{'filename'}) && defined($af=$al->{'filename'})
			){
				if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item '$group'->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
				$template_info{'filename'} = $af;
				$template_info{'basedir'}  = Cwd::abs_path($ab) // $ab;
				$template_info{'filepath'} = File::Spec->catfile(
					$template_info{'basedir'},
					$template_info{'filename'}
				);
				my $FH;
				if( ! open($FH, '<:utf8', $template_info{'filepath'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : error, failed to open specified (in options) latex-template file '".$template_info{'filepath'}."', $!"); return undef }
				{ local $/ = undef; $content = <$FH> } close $FH;
				$template_inc_paths{ $template_info{'basedir'} }++;
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : template filename : '".$template_info{'filename'}."' in dir '".$template_info{'basedir'}."'.") }
			} elsif( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
				# TODO: perhaps we don't need to load disk-based templates as inmemory???
				# read a template file from disk, we also record its basedir and abs filename
				my $FH;
				if( ! open($FH, '<:utf8', $af) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : error, failed to open specified (in options) latex-template file '$af', $!"); return undef }
				{ local $/ = undef; $content = <$FH> } close $FH;
				$template_info{'filepath'} = Cwd::abs_path($af) // $af;
				$template_info{'filename'} = File::Basename::basename($template_info{'filepath'});
				$template_info{'basedir'} = File::Basename::dirname($template_info{'filepath'});
				$template_inc_paths{ $template_info{'basedir'} }++;
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : template filepath : '".$template_info{'filepath'}.".") }
			} else {
				# ERROR! no template info, and no latex filename on disk!
				$log->error("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : error, there is no template specified because you need to specify either filename+basedir or filepath or content under entry 'processors'->'$group'.");
				next;
			}
			# do we have any aux files to copy into the tmpdirs for the processing, e.g. perhaps
			# images needed by the template, or other template files to be included
			# you need to specify them here with ['fullpath-a', 'fullpath-b', ...]
			if( exists($al->{'auxfiles'}) && defined($al->{'auxfiles'}) ){
				if( ref($al->{'auxfiles'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, parameter 'template'->'auxfiles' needs to be an ARRAYref."); return undef }
				$template_info{'auxfiles'} = $al->{'auxfiles'};
			}

			# this goes into Xslate to load at startup and cache
			# it works for both real disk files and also in-memory templates
			# the latter has filename and basedir as undef
			# (key is a nickname of the template)
			$xslate_vpaths{$ak} = $content if defined $content;
		} else { $log->error("${whoami} (via $parent), line ".__LINE__." : processor '$ak' : error, there is no key 'template' but it is needed."); return undef }

		# group: 'output'
		# info about PDF output
		$group = 'output';
		if( exists($av->{$group}) && defined($al=$av->{$group}) ){
			if( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
				$output_info{'filepath'} = Cwd::abs_path($af) // $af;
				$output_info{'filename'} = File::Basename::basename($output_info{'filepath'});
				$output_info{'basedir'} = File::Basename::dirname($output_info{'filepath'});
			} elsif( exists($al->{'filename'}) && defined($af=$al->{'filename'}) ){
				if( File::Spec->splitdir($af) > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, item '$group'->'filename' ($af) must be a filename (and not a filePATH, it should not contain any directory components)."); return undef }
				$ab = exists($al->{'basedir'}) && defined($al->{'basedir'})
					? $al->{'basedir'}
					: exists($latex_info{'basedir'}) && defined($latex_info{'basedir'})
						? $latex_info{'basedir'}
						: File::Spec->catdir('.')
				;
				$output_info{'filename'} = $af;
				$output_info{'basedir'}  = Cwd::abs_path($ab) // $ab;
				$output_info{'filepath'} = File::Spec->catfile(
					$output_info{'basedir'},
					$output_info{'filename'}
				);
			} else {
				$output_info{'filename'} = $latex_info{'filename'};
				  $output_info{'filename'} =~ s/\.tex$/.pdf/i;
				$output_info{'basedir'} = $latex_info{'basedir'};
				$output_info{'filepath'} = File::Spec->catfile($output_info{'basedir'}, $output_info{'filename'});
			}
		} else {
			if( $verbosity > 4 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : processor '$ak' : warning, there is no 'output' section, output will be determined during format() ..."); }
		}
		# and save to self under '_private'->'processors'->'loaded-info' ...
		$LI->{$ak} = \%loaded_info;
	}
	# these are default params to the Text::Xslate constructor,
	# next we will add all those set via construction parameters (keyed under 'templater-parameters')
	if( ! exists($options->{'templater-parameters'}) || ! defined($options->{'templater-parameters'}) ){ $log->info("${whoami} (via $parent), line ".__LINE__." : error, there is no option 'templater-parameters'! Something is seriously wrong."); return undef }
	my %parms = ( %{ $options->{'templater-parameters'} } );
	# WARNING: we don't want to make any permanent changes to the $options->{'templater-parameters'}
	# so make sure you don't modify anything permanently, e.g. $options->{'templater-parameters'}->{'path'}!
	# as it is now, 'path' is not modified permanently:
	if( (scalar(keys %xslate_vpaths) > 0) || (scalar(keys %template_inc_paths) > 0) ){
		# using 'path' we achieve caching for both diskfiles and inmemory
		# otherwise inmemory need render_string() which does not cache like render() does.
		# see https://metacpan.org/pod/Text::Xslate#$tx-%3Erender_string($string,-\%vars)-:Str
		# it is important for file templates which also call other templates to add
		# to the %template_inc_paths above.
		my @tmp = sort keys %template_inc_paths;
		for (sort keys %xslate_vpaths){
			push @tmp, {$_ => $xslate_vpaths{$_} }
		}
		if( exists($parms{'path'}) && defined($parms{'path'}) ){
			# just a sanity check
			if( ref($parms{'path'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, parameter to Text::Xslate 'path' must be an ARRAYref of paths."); return undef }
			# yes we have already a set of paths, add to it
			push @{$parms{'path'}} , @tmp;
		} else { $parms{'path'} = \@tmp }
	}

	if( $verbosity > 1 ){ $log->info(perl2dump(\%parms)."\n--end parameters.\n${whoami} (via $parent), line ".__LINE__." : creating the Text::Xslate object with above parameters ...") }

	my $tobj = Text::Xslate->new(\%parms);
	if( ! defined $tobj ){ log->error(perl2dump(\%parms)."\n--end parameters.\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'Text::Xslate->new()'." has failed for above parameters."); return undef }

	$self->templater($tobj);
	if( $verbosity > 0 ){
		$log->info("${whoami} (via $parent), line ".__LINE__." : loaded ".scalar(keys %xslate_vpaths)." templates: ".join(",", keys %xslate_vpaths))
	}
	return $tobj;
}

# Returns the current options
# If an input 'defaults' hash is specified then it checks if it contains certain keys
# which are necessary and then it loads it into self
# and returns it back
# if a logger has not been created at this time a temp logger will be created just for this sub
# it returns undef on failure
sub options {
	my ($self, $src) = @_;
	return $self->{'_private'}->{'options'} unless defined $src;

	my $log = $self->log();

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my ($x, $y);
	my $dst = $self->options();

	if( exists($src->{'latex'}) && defined($x=$src->{'latex'}) ){
		if( ref($x) ne 'HASH' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, key 'latex' must be a HASH."); return undef }
		for (qw/filename/){
			if( exists($x->{$_}) && defined($x->{$_}) ){ $dst->{'latex'}->{$_} = $x->{$_} }
		}
		if( exists($x->{'latex-driver-parameters'}) && defined($y=$x->{'latex-driver-parameters'}) ){
			if( ref($y) ne 'HASH' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, key 'latex'->'latex-driver-parameters' must be a HASH."); return undef }
			for (@OPTIONS_ALLOWED_TO_BE_PASSED_TO_LATEX_DRIVER){
				if( exists($y->{$_}) && defined($y->{$_}) ){ $dst->{'latex'}->{'latex-driver-parameters'}->{$_} = $y->{$_} }
			}
		}
	}

	# check debug
	if( exists($src->{'debug'}) && defined($x=$src->{'debug'}) ){
		if( ref($x) ne 'HASH' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, key 'debug' must be a HASH."); return undef }
		for (qw/verbosity cleanup/){
			if( exists($x->{$_}) && defined($x->{$_}) ){ $dst->{'debug'}->{$_} = $x->{$_} }
		}
	}

	# check tempdir
	if( exists($src->{'tempdir'}) && defined($x=$src->{'tempdir'}) ){ $dst->{'tempdir'} = $x }

	# check max-size-for-filecopy
	if( exists($src->{'max-size-for-filecopy'}) && defined($x=$src->{'max-size-for-filecopy'}) ){ $dst->{'max-size-for-filecopy'} = $x }

	# check templater parameters
	if( exists($src->{'templater-parameters'}) && defined($src->{'templater-parameters'}) ){
		$dst->{'templater-parameters'} = Clone::clone($src->{'templater-parameters'})
	}
	return $dst
}
# return or set the log
sub log { 
	my ($self, $m) = @_;
	return $self->{'_private'}->{'log'}->{'logger_object'} unless defined $m;
	$_[0]->{'_private'}->{'log'}->{'logger_object'} = $m;
	return $m;
}

# checks if LaTeX::Driver has found the specifed executable.
# The executable can be something like: latex, pdflatex, xelatex etc.
# as well as dvips etc.
# returns the FULL path to the executable if found
# or undef if not found or errors (e.g. failed to instantiate LaTeX::Driver)
sub latex_driver_executable {
	my $program_name = $_[0];
	my $pa;
	if( defined $program_name ){
		$pa = LaTeX::Driver->program_path($program_name);
		return undef unless $pa;
		# this returns undef if not found or not executable (even if via a link)
		return File::Which::which($pa)
	}
	# just iterate over all program names and check them
	my (%ret, $pk);
	for $pk (keys %LaTeX::Driver::program_path){
		if( defined($pa=latex_driver_executable($pk)) ){
			$ret{$pk} = $pa
		}
	}
	return \%ret;
}

# to be removed
sub latex_driver_executable_old {
	# NOTE you can check program names without LaTeX::Driver object
	# like this: LaTeX::Driver->program_name('xelatex')
	my ($program_name) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my ($fh, $tmpfil) = File::Temp::tempfile(SUFFIX => '.tex');
	my $drivobj = eval { LaTeX::Driver->new('source' => $tmpfil) };
	if( ! defined($drivobj) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, failed to instantiate LaTeX::Driver: $@"; return undef }
	close $fh; unlink $tmpfil;
	if( defined $program_name ){
		if( exists($drivobj->{_program_path}->{$program_name})
		 && defined($drivobj->{_program_path}->{$program_name})
		# LaTeX::Driver seems to return 'xelatex' (note: no path)
		# even if xelatex is not on the system,
		# so add this check too:
		 && (-x $drivobj->{_program_path}->{$program_name})
		){
			return $drivobj->{_program_path}->{$program_name}
		}
		return undef # not found
	} else { return Clone::clone($drivobj->{_program_path}) }

	return undef # should not be coming here
}

sub templater { 
	my ($self, $m) = @_;
	if( defined $m ){
		$self->processors()->{'templater_object'} = $m;
	}
	return $self->processors()->{'templater_object'}
}
sub templater_reset {
	my $self = $_[0];
	$self->processors()->{'templater_object'} = undef;
	$self->processors()->{'loaded-info'} = {};
	$self->{'_private'}->{'processors'} = {};
}

sub processors { return $_[0]->{'_private'}->{'processors'} }
sub loaded_info { return $_[0]->processors()->{'loaded-info'} }

sub is_template_loaded {
	my ($self, $atf) = @_;
	#my $parent = ( caller(1) )[3] || "N/A";
	#my $whoami = ( caller(0) )[3];
	#my $log = $self->log();
	#my $verbosity = $self->verbosity();

	my $li = $self->loaded_info();
	return exists($li->{$atf})
	 ? $li->{$atf}
	 : undef
	;
}

# set or get the max total recusrive file size for copying
# if that size exceeds this limit it will croak
# if you set it to -1 no size checks will be made.
sub max_size_for_filecopy { 
	my ($self, $m) = @_;
	if( defined $m ){
		$self->options()->{'max-size-for-filecopy'} = $m;
	}
	return $self->options()->{'max-size-for-filecopy'}
}

# returns the current verbosity level optionally setting its value
# Value must be an integer >= 0
# setting a verbosity level will also spawn a chain of other debug subs,
# e.g. set the verbosity (verbosity) of the LWP ua
# if any of the above fails, this sub WILL RETURN -1
sub verbosity {
	my ($self, $m) = @_;
	my $log = $self->log();
	if( defined $m ){
		$self->options()->{'debug'}->{'verbosity'} = $m;
	}
	return $self->options()->{'debug'}->{'verbosity'}
}
sub cleanup {
	my ($self, $m) = @_;
	my $log = $self->log();
	if( defined $m ){
		$self->options()->{'debug'}->{'cleanup'} = $m;
	}
	return $self->options()->{'debug'}->{'cleanup'}
}

=pod

=head1 NAME

LaTeX::Easy::Templates - Easily format content into PDF/PS/DVI with LaTeX templates.

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

This module provides functionality to format
text content from a Perl data structure
into printer-ready documents (PDF/Postscript/DVI).
It utilises the idea of Templates and employs the
powerful LaTeX (via L<LaTeX::Driver>) in order
to format and render the final documents into
printer feed.

Its use requires
that LaTeX is already installed in your system.
Don't be alarmed! LaTeX is simple to install in any OS,
see section L</INSTALLING LaTeX> for how. In Linux
it is provided by the system package manager.

Using LaTeX will not only empower you like
Guttenberg's press did and does, but it
will also satisfy even the highest aesthetic
standards with its 20/20 perfect typography.
LaTeX is one of the rare
cases where Software can be termed as Hardware.
Install it and use it. Now.

Here is a basic scenario borrowed from Dilbert's adventures.
You have a number of emails with fields like C<sender>,
C<recipient>, C<subject> and C<content>. This data
can be represented in Perl as an array of hashes like:

  [
    {
      sender => 'jack',
      recipient => 'the clown',
      subject => 'hello',
      content => 'blah blah',
    },
    {
      sender => 'dede',
      recipient => 'kinski',
      subject => 'Paris rooftops',
      content => 'blah2 blah2',
    },
    ...
  ]

You want to render this data to PDF.

A more interesting scenario:

You are scraping a, say, News website. You want each article
rendered as PDF. Your scraper provides the following data
for each News article, and you have lots of those:

  [
    {
      author => 'jack',
      title => '123',
      date => '12/12/2012',
      content => [
         'paragraph1',
         'paragraph2',
         ...
      ],
      usercomments => [
        {
          'author' => 'sappho',
          'content' => 'yearning ...',
       },
       ... # more comments
    }
    ... # more News articles
  ]

Once you collect your data and save it
into a Perl data structure as above (note:
the stress is on B<structure>) you need to
create a templated LaTeX document which
will be complete except that where
the C<author>, C<sender>, C<recipient>, C<content>,
etc. would be, you will place some tags like:

  <: $author :>
  <: $sender :>

or control like:

   : for $authors -> $author {
   : # call a new template for each author and
   : # append the result here
   :   include "authors-template.tex.tx" {
   :     author => $author
   :   }
   : }

etc.

The L<LaTeX::Easy::Templates> module
will then take your data and your LaTeX template
and produce the final rendered documents.

In section L</STARTING WITH LaTeX> you will see how to easily build a LaTeX template
from open source, publicly available, superbly styled "I<themes>".

The template engine used in this module is L<Text::Xslate>, chosen
because of its very good performance when rendering templates.


    use LaTeX::Easy::Templates;

    # templated LaTeX document in-memory
    # (with variables to be substituted)
    my $latex_template =<<'EOLA';
    % basic LaTeX document
    \documentclass[a4,12pt]{article}
    \begin{document}
    \title{ <: $data.['title'] :> }
    \author{ <: $data.author.name :> <: $data.author['surname'] :> }
    \date{ <: $data.date :> }
    \maketitle
    <: $data.content :>
    \end{document}
    EOLA

    # my template variable substitutions
    my $template_data = {
      'title' => 'a test title',
      'author' => {
      	'name' => 'myname',
      	'surname' => 'surname',
      },
      'date' => '2024/12/12',
      'content' => 'blah blah',
    };

    sub myfunc { return "funced ".$_[0] }

    my $latte = LaTeX::Easy::Templates->new({
      debug => {verbosity=>2, cleanup=>1},
      'templater-parameters' => {
        # passing parameters to Text::Xslate's constructor
        # myfunc() will be accessible from each template
        'function' => {
          'myfunc' => \&myfunc,
        },
        'module' => [
          # and so the exports of this module:
          'Data::Roundtrip' => [qw/perl2json json2perl/],
        ],
      },
      'processors' => {
        # if it includes other in-memory templates
        # then just include them here with their name
        'mytemplate' => {
          'template' => {
            'content' => $latex_template_string,
          },
          'output' => {
            'filepath' => 'output.pdf'
          }
        }
      }
    });
    die unless $latte;

    my $ret = $latter->format({
      'template-data' => $template_data,
      'outfile' => 'xyz.pdf',
      # this is the in-memory LaTeX template
      'processor' => 'mytemplate'
    });
    die unless $ret;

In this way you can nicely and easily typeset your data
into a PDF.

=head1 EXPORT

=over 2

=item * L</latex_driver_executable($program_name)>

=back

=head1 METHODS

=head2 C<new()>

The constructor.

The full list of arguments, provided as a hashref, is as follows:

=over 2

=item * B<processors> : required parameter as a hash(ref) specifying one or more
I<processors> which are responsible for rendering the final typeset document
from either a template or a LaTeX source file. The processor name is a key to the
specified hash and should contain these items:

=over 2

=item * B<template> : a hash(ref) containing information about the input LaTeX template.
This information must be specified if no LaTeX source file is specified (see B<latex> section below).
Basically you need to specify the location of the LaTeX template file or
a string with the contents of this template (as an in-memory template).

Note that B<basedir> and B<filename> are explictly specified (instead of B<filepath>)
then B<**ALL CONTENTS**> of B<basedir>
will be B<copied recursively> to the output dir assuming that there are other files there
(for example images, LaTeX style files etc.) which are needed during
processing the template or running latex. If you do not want this file copying then
just specify B<filepath>.

If there are other files or directories you will need during processing the
template or running latex then you can specify them as an array(ref)
in B<auxfiles>. These will be B<copied recursively> to the output dir.

=over 2

=item * B<filepath> : specify the full path to the template file, or,

=item * B<filename> and B<basedir> : specify a filename (not a file path) and the
directory it resides. Note that if you specify these two,
then B<**ALL CONTENTS**> of B<basedir>
will be B<copied recursively> to the output dir assuming that there are other files there
(for example images, LaTeX style files etc.) which are needed during
processing the template or running latex.

=item * B<content> : specify a string with the template contents. If this
template calls other templates (from disk) then you should specify B<basedir>
to point to the path which holds these extra files. In this
case B<basedir> can be an array(ref) with more than one paths or just
a scalar with a single path.

=item * B<auxfiles> : specify a set of files or directories, as an array(ref), to
be B<copied recursively> to the output dir. These files may be needed for processing the template
or for running latex (for example, style files, images, other template files, etc.).
However, copying directories recursively can be pretty heavy. So, there is an
upper limit on the total file size of each of the paths specified. This can be
set during runtime with

   $self->max_size_for_filecopy(1024*1024);
   # or set it to negative for skipping all file size checks
   $self->max_size_for_filecopy(-1);


=back

=item * B<output> : specifies the file path to the output typeset document:

=over 2

=item * B<filepath> : specify the full path to the output file, or,

=item * B<filename> and B<basedir> : specify a filename (not a file path) and the
directory it should reside.

Note that the path will be created if it does not exist.

=back

=item * B<latex> : a hash(ref) containing information about the LaTeX source
which will either be created from a LaTeX template (see B<template> above)
and some data for the template variables (more on this later) or be provided
(the LaTeX source file) by the caller without any template.

=over 2

=item * B<filepath> : specify the full path to the LaTeX source file which
will be created from the template if the B<template> parameter was specified,
or be used directly if no template was specified. In the former case, the
file may or may not exist on disk and will be created. In the latter case,
it must exist on disk.

=item * B<filename> and B<basedir> : specify a filename (not a file path)
and the directory it resides. Again, the LaTeX source file needs to exist
if no B<template> parameter was specified.

=item * B<latex-driver-parameters> : parameters in a hash(ref) to be passed on
to the LaTeX driver (L<LaTeX::Driver>)
which does the actual rendering of the LaTeX source file into the typeset
printer-ready document. Refer to the L<documentation|LaTeX::Driver#new(%params)>
of L<LaTeX::Driver>'s constructor for the description of each of the parameters.

Note that B<only the following> parameters will be passed on:

=over 2

=item * B<format> : specify the output format (e.g. B<pdf>, B<ps>, etc.)
of the rendered document and, optionally, the LaTeX "I<flavour>" or "I<processor>" to be used,
e.g. C<xelatex>, C<pdflatex>, C<latex>, etc. The default value is C<pdf(pdflatex)>.

=item * B<paths> : specifies a mapping of program names to full pathname as a hash reference.
These paths override the paths determined at installation time (of L<LaTeX::Driver>).

=item * B<maxruns> : The maximum number of runs of the formatter program (defaults to 10 in L<LaTeX::Driver>)

=item * B<extraruns> : The number of additional runs of the formatter program after the document has stabilized.

=item * B<timeout> : Specifies a timeout in seconds within which any commands spawned should finish. Even for very long
documents LaTeX is extremely fast, so this can be well under a minute.

=item * B<indexstyle> : The name of a makeindex index style file that should be passed to makeindex.

=item * B<indexoptions> : Specifies additional options that should be passed to makeindex. Useful options are: -c to compress intermediate blanks in index keys, -l to specify letter ordering rather than word ordering, -r to disable implicit range formation. Refer to LaTeX's makeindex(1) for full details.

=item * B<DEBUG> : Enables debug statements if set to a non-zero value. The value will be the same as our verbosity level.

=item * B<DEBUGPREFIX> : Sets the debug prefix, which is prepended to debug output if debug statements. By default there is no prefix.

=back

Note that the descriptions of the parameters (above) to be passed on to L<LaTeX::Driver> are taken more-or-less verbatim from
its documentation page, refer to the original document in case there are changes.

=back

=item * B<latex> : specify default parameters for B<processors>' B<latex> data
in case it is absent:

=over 2

=item * B<filename> : default LaTeX source filename (not a filepath).

=item * B<latex-driver-parameters> : default parameters to be passed on to
L<LaTeX::Driver>'s constructor. See above for what it includes.

=back

=item * B<debug> :

=over 2

=item * B<verbosity> : script's verbosity. A value of zero mutes the script.
A higher integer increases the verbosity.

=item * B<cleanup> : a non-zero value will clean up all temporary files and directories
including those created by L<LaTeX::Driver>. This is the default. For debugging purpose,
set this to zero so that you can inspect all intermediate files created.

=back

=item * B<tempdir> : specify where the temporary files will be placed. This location
will be created if it does not exist. Default is to use a temporary location as
given by the OS.

=item * B<logfile> : specify a file to redirect the logger's output to. Default
is to log messages to the console (STDOUT, STDERR).

=item * B<logger_object> : supply a L<Mojo::Log> object to use as the logger.
In fact any object implementing just these three: C<error()>, C<warn()> and C<info()>, which
L<Mojo::Log> does, will be accepted.

=item * B<templater-parameters> : a HASH containing parameters to be
passed on to the L<Text::Xslate> constructor. 

These are some common templater paramaters:

=over 2

=item * B<syntax> : specify the template syntax to be either L<Kolon|Text::Xslate::Syntax::Kolon> or C<TTerse|Text::Xslate::Syntax::TTerse>. Default is C<Kolon>.

=item * B<suffix> : specify the template files suffix. Default is C<.tx> (do not forget the dot).

=item * B<verbose> : set the verbosity of L<Text::Xslate>.
Default is the verbosity level currently set in the
L<LaTeX::Easy::Templates> object.

=item * B<path> : an array(ref) of paths to be searched for included templates. This is crucial
when templates are including other templates in different directories.

=item * B<function>, B<module> : specify your own perl functions and modules you want to use
from within a template. That's very handy in overcoming the limitations of the template syntax.

=back

See L<Text::Xslate#Text::Xslate-%3Enew(%options)> for all the supported options.

=over 2

=item * B<path> : an array of paths to be searched for on-disk template
files which are dependencies, i.e. they are included by other templates (in-memory or on-disk).
This is very important if your main template includes other templates which
are in different directories.

=item * B<syntax> : the template syntax. Default is 'Kolon'.

=item * B<function>, B<module> : a hash of user-specified or built-in perl functions (coderefs)
to be used in the templates. And a list of modules to be included for using these.
Quite a powerful feature of L<Text::Xslate>.

=item * B<cache>, B<cache_dir> : cache level and location.

=item * B<line_start>, B<tag_start>, B<line_end>, B<tag_end> : the token strings denoting
the start and end of lines and tags.

=back

For example:

      'templater-parameters' => {
        # dependent templates search paths
        'path' => ['a/b/c', 'x/y/z', ...],
        # user-specified functions to be called
        # from a template
        'function' => {
          'xyz' => sub { my (@params) = @_; ...; return ... }
        },
        # installed Perl modules can be accessed
        # from a template (caveat: complains for fully
	# qualified sub names '::')
        'module' => [
          'Data::Roundtrip' => [qw/perl2json json2perl/],
        ],
        ...
      },

=back

=back

The constructor returns C<undef> on failure.

Here is example code for calling the constructor:

     use LaTeX::Easy::Template;
     my $latter = LaTeX::Easy::Template->new({
      'processors' => {
        'in-memory' => {
           'latex' => {
        	'filename' => undef # create tmp
           },
           'template' => {
                # the template is in-memory string
        	'content' => '...'
           },
           'output' => {
        	'filename' => 'out.pdf'
           }
        }
        'on-disk' => {
          'latex' => {
        	'filename' => undef, # create tmp
           },
           'template' => {
        	'filepath' => 't/templates/simple01/main.tex.tx'
           },
           'output' => {
        	'filename' => 'out2.pdf'
           }
        }
      }, # end processors
      # log to this file, path will be created if not exists
      'logfile' => 'xyz/abc.log',
      'latex' => {
        'latex-driver-parameters' => {
           # we want PDF output run with xelatex which
           # easily supports multi-language documents
           'format' => 'pdf(xelatex)',
           'paths' => {
              # the path to the xelatex needed only if not standard
              'xelatex' => '/non-standard-path/xyz/xelatex'
           }
        }
      },
      'verbosity' => 1,
      'cleanup' => 0,
    });

The above creates a L<LaTeX::Easy::Templates> object which has 2 "processors"
one which uses a LaTeX template from disk and one in-memory.
Default L<LaTeX::Driver> parameters are specified as well
and will be used for these processors which do not specify any.

=head2 C<untemplate()>

It creates a LaTeX source file from a template.
This is the first step in rendering the final typeset document.
which is done by L</format()>.

Note that calling this method is not necessary
if you intend to call L</format()> next.
The latter will call the former if needed.

The full list of arguments is as follows:

=over 2

=item * B<processor> : specify the name of the "processor" to use.
The "processor" must be a key to the B<processors> parameter
passed to the constructor.

=item * B<template-data> : specify the data for the template's variables
as a hash or array ref, depending on the structure of the template in use.
This data is passed on to the template using the key C<data>.
So if your template data is this:

  {
    name => 'aa',
  }

Then your template will access C<name>'s value via C< <: $data.name :> >

See L</TEMPLATE PROCESSING> for more on the syntax of the template files.

=item * B<latex>, B<template> : optionally, overwrite "processor"'s
B<latex>, B<template> fields by specifying any of these fields here
in exactly the same format as that of the B<processors> parameter
passed to the constructor (L</new()>).

=back

On failure, L</untemplate()> returns C<undef>.

On success, it returns a hash(ref) with two entries:

=over 2

=item * B<latex> : contains B<fileapth>, B<filename> and B<basedir>
of the produced LaTeX source file.

=item * B<template> : it contains B<fileapth>, B<filename>, B<basedir>
and B<content>. The last one will be undefined if
the template used if the template was a file read from disk.
The first three will be undefined otherwise.

=back

=head2 C<format()>

It renders the final typeset document.
It will call L</untemplate()> if is
required to produce the intermediate LaTeX
source file. If that file was specified,
then it will render the final document
by calling L<LaTeX::Driver>.

The full list of arguments, provided by a hashref, is as follows:

=over 2

=item * B<processor> : specify the name of the "processor" to use.
The "processor" must be a key to the B<processors> parameter
passed to the constructor.

=item * B<template-data> : specify the data for the template's variables
as a hash or array ref, depending on the structure of the template in use.
This data is only needed if the intermediate LaTeX source file needs to
be produced.

=item * B<latex>, B<template>, B<output> : optionally, overwrite "processor"'s
B<latex>, B<template>, B<output> fields by specifying any of these fields here
in exactly the same format as that of the B<processors> parameter
passed to the constructor (L</new()>).

=back

On failure, L</format()> returns C<undef>.

On success, it returns a hash(ref) with three entries:

=over 2

=item * B<latex> : contains B<fileapth>, B<filename> and B<basedir>
of the produced LaTeX source file.

=item * B<template> : it contains B<fileapth>, B<filename>, B<basedir>
and B<content>. The last one will be undefined if
the template used if the template was a file read from disk.
The first three will be undefined otherwise.

=item * B<output> : it contains B<fileapth>, B<filename> and B<basedir>
pointing to the output typeset document it created.

=back

=head2 C<max_size_for_filecopy($maxsize)>

It gets or sets (with optional parameter C<$maxsize>) the maximum size for doing a
recursive file copy. Recursive file copies are done for template extra files
which may be needed for processing the template or running latex. They are
specified if B<template-E<gt>basedir> is explicitly set (then the whole B<basedir> will be copied)
or when B<template-E<gt>auxfiles> are specified as an arrayref of files/dirs to copy individually.
In order to reduce the risk
of unintentionally copying vast files and directories there is a limit
to the total (recursively calculated)
size of files/directories to be copied. This can be set here.
The default is 3MB. However if you set this limit to a negative integer
no checks will be make and file copying will be done unreservedly.

=head2 C<verbosity($verbosity)>

It gets or sets (with optional parameter C<$verbosity>) the verbosity level.

=head2 C<cleanup($c)>

It gets or sets (with optional parameter C<$c>) the B<cleanup> parameter
which contols the cleaning up of temporary
files and directories or not. Set it to 1 to clean up. This is currently
the default. Set it to 0 to keep these files for inspection during debugging.

=head2 C<templater($t)>

It gets or sets (with optional parameter C<$t>) the templater
object. This is the object which convertes the LaTeX template
into LaTeX source. Currently only L<Text::Xslate>
is supported.

=head2 C<templater_reset()>

Reset the templater object which means to forget all the templates
it knows and had possibly loaded in memory. After a reset all
"processors" will be forgotten as well.

=head2 C<log($l)>

It gets or sets (with optional parameter C<$l>) the logger
object. Currently the logger is of type L<Mojo::Log>.

=head2 C<latex_driver_executable($program_name)>

This is an exported sub (and not a method)

It enquires L<LaTeX::Driver> for what is the fullpath to the
program named C<$program_name>. The program can be C<latex>, C<dvips>,
C<makeindex>, C<pdflatex> etc.
If the program is not found or if it is not an executable
(for the current user), it returns C<undef>.
If it is found and it is executable (for the current user),
its fullpath is returned.

The parameter C<$program_name> is optional,
if it is omitted, it returns a hash(ref) with all known
programs (the keys)
and their full paths (the values).

Note that L<LaTeX::Driver>'s paths are detected during its installation
(according to its documentation).

Program full paths can be set during running L</format()> by passing it
the parameter
B<latex-E<gt>latex-driver-parameters-E<gt>paths>
(a hashref mapping program names to their paths).

=head2 C<processors()>

It returns the hash(ref) of known "processors" as they were
set up during construction.

=head2 C<loaded_info()>

It returns the hash(ref) of extra information relating to the "processors".

=head1 TEMPLATE PROCESSING

The LaTeX templates will be processed with L<Text::Xslate> and must
follow its rules. It understands two template syntaxes:

=over 2

=item * it's own L<Text::Xslate::Syntax::Kolon>

=item * and a subset of Template Toolkit 2 L<Text::Xslate::Syntax::TTerse>

=back

The default syntax is L<Text::Xslate::Syntax::Kolon>. This can be changed
via the parameters to the constructor of L<LaTeX::Easy::Templates> by
specifying this:

  'templater-parameters' => {
      'syntax' => 'Kolon' #or 'TTerse'
  }

The B<data> for substituting into the template variables comes bundled into a hashref
which comes bundled into a hashref keyed under the name "C<data>". Therefore
all references must be preceded by key C<data.>

So if your template data is this:

  {
    name => 'aa',
  }

Then your template will access C<name>'s value via C< <: $data.name :> >.

L<Text::Xslate> supports loops and conditional statements.
It also offers a lot of L<builtin functions|Text::Xslate::Manual::Builtin>.
Additionally you can call user-specified perl subs (or subs from other modules)
from within a template.

Read
the documentation for L<Text::Xslate>'s syntax
L<Text::Xslate::Syntax::Kolon> or L<Text::Xslate::Syntax::TTerse>.

=head1 TEMPLATES INCLUDING TEMPLATES

Templates which include other templates are supported.

The included and the includee templates can be a
combination of on-disk files and/or in-memory strings.
Which means in-memory templates can include on-disk and vice-versa.

=head2 In-memory templates

The C<processor> parameter to L<LaTeX::Easy::Templates>'s L<constructor|/new()>
should contain both the main template and all other
included templates keyed on their include name. For example, the
main template is:

    \documentclass[letterpaper,twoside,12pt]{article}
    \begin{document}
    : include "preamble.tex.tx" {data => $data};
    : for [1, 2, 3] -> $i {
      \section{Content for section <: $i :>}
      : include "content.tex.tx" {data => $data};
   : }
   \end{document}

The above I<includes> two other templates:

    :# preamble.tex.tx
    \title{ <: $data.title :> }
    \author{ <: $data.author.name :> <: $data.author.surname :> }
    \date{ <: $data.date :> }

and

    :# content.tex.tx
    <: $data.content :>

In order to load all above templates, construct the L<LaTeX::Easy::Templates>
object like this:

     my $latter = LaTeX::Easy::Template->new({
      'processors' => {
        # the main entry
        'main.tex.tx' => {
           'template' => {
        	'content' => '... main.tex.tx contents ...'
           },
           'output' => {
        	'filename' => 'out.pdf'
           }
        },
        # it includes these other templates:
        'preamble.tex.tx' => { # one ...
           'template' => {
        	'content' => '... preamble.tex.tx contents ...'
           }
        },
        'content.tex.tx' => { # ... and two
           'template' => {
        	'content' => '... content.tex.tx contents ...'
           },
        }
      } # end 'processors'

With the above, all in-memory templates required are loaded in memory.
All you need now is to specify "C<main.tex.tx>" (which
is the main entry point) as the
C<processor> name when
calling L</untemplate()> or L</format()>. You do not need
to mention the included template names at all:

    my $ret = $latter->format({
      'template-data' => $template_data,
      'output' => {
        'filepath' => ...,
      },
      # just specify the main entry template
      'processor' => 'main.tex.tx',
});


The above functionality is demonstrated and tested in
file C<t/460-inmemory-template-usage-calling-other-templates.t>

=head2 On-disk file templates

If both the main template and all templates it includes are in the
same directory then you only need to specify
the C<main.tex.tx> template under key C<processors>
in the parameters to L<LaTeX::Easy::Templates>'s L<constructor|/new()>.
In this case all dependencies will
be taken care of (thank you L<Text::Xslate>).

Additionally, you can specify a list of directories as
paths to be searched for dependent templates. These I<include paths>
can be passed on as parameters to L<LaTeX::Easy::Templates>'s
L<constructor|/new()>, under 

     ...
     'templater-parameters' => {
       'path' => ['a/b/c', 'x/y/z', ...]
     },
     ...

     my $latter = LaTeX::Easy::Template->new({
       'templater-parameters' => {
         'path' => ['a/b/c', 'x/y/z', ...],
         ...
       },
       'processors' => {
        # the main entry
         'main.tex.tx' => {
           'template' => {
             'filepath' => '/x/y/z/main.tex.tx'
             # works also with specifying
             #   'filename' & 'basedir'  
           },
           'output' => {
        	'filename' => 'out.pdf'
           }
         },
         # the dependent templates are not needed
         # to be included if in same dir
         # include them ONLY if in different dir
       } # end 'processors'
     }); # end constructor

With the above, the "C<main.tex.tx>" template,
which is the main entry point, is loaded.
As long as its dependencies, i.e. the templates
it includes, are in the same directory
or are specified with their full path,
then there is nothing else you need to include.
The dependencies will be found and included as needed.

All you need now is to specify "C<main.tex.tx>" as the
C<processor> name when
calling L</untemplate()> or L</format()>. You do not need
to mention the included template names at all. Like this:

    my $ret = $latter->format({
      'template-data' => $template_data,
      'output' => {
        'filepath' => '/x/y/z/out.pdf',
      },
      # just specify the main entry template
      # dependencies will be included as needed:
      'processor' => 'main.tex.tx',
});


The above functionality is demonstrated and tested in
file C<t/360-ondisk-template-usage-calling-other-templates.t>

=head2 Mixed use of in-memory and on-disk templates

One can have a project of mixed, in-memory and on-disk, templates
one including the other in any combination. This is
straightforward, just follow the above guidelines.

Mixed templates functionality is demonstrated and tested in
file C<t/500-mix-template-usage-calling-other-mix-templates.t>.


=head1 EXAMPLE: PRINTING STICKY LABELS

We will use the LaTeX package L<labels|https://ctan.org/pkg/labels?lang=en>
(documented L<here|https://mirrors.ctan.org/macros/latex/contrib/labels/labels.pdf>)
to prepare sticky labels for addressing envelopes etc. By the way, there
is also the L<ticket|https://ctan.org/pkg/ticket?lang=en> LaTeX package
available over at CTAN (documented L<here|http://mirrors.ctan.org/macros/latex/contrib/ticket/doc/manual.pdf>)
which can be of similar use, printing tickets.

We will create two template files. One called C<labels.tex.tx> as the
main entry point. And one called C<label.tex.tx> to be called by the
first one in a loop over each label item in the input data.

Here they are:

    % I am ./templates/labels/labels.tex.tx
    \documentclass[12pt]{letter}
    \usepackage{graphicx}
    \usepackage{labels}
    \begin{document}
    : for $data -> $label {
    :   include 'label.tex.tx' { label => $label };

and

    % I am ./templates/labels/label.tex.tx
    \genericlabel{
      \begin{tabular}{|c|}
        \hline
    : if $label.sender.logo {
        \includegraphics[width=1cm,angle=0]{<: $label.sender.logo :>}\\
    : }
        \hline
        <: $label.recipient.fullname :>\\
        \hline
    : for $label.recipient.addresslines -> $addressline {
        <: $addressline :>
    : }
        \\
        <: $label.recipient.postcode :>\\
        \hline
      \end{tabular}
    }

Save them on disk in the suggested directory structure.
Or, if you decide to change it, make sure you adjust
the paths in the script below.

Optionally, save a logo image to
L<./templates/images/logo.png>. If that exists then
the template will pick it up.

And here is the Perl script to harness the beast:

    use LaTeX::Easy::Templates;
    use FindBin;

    my $curdir = $FindBin::Bin;

    # the templates can be placed anywhere as long these
    # paths are adjusted. As it is now, they
    # must both be placed in ./templates/labels
    # the main entry is ./templates/labels/labels.tex.tx
    # which calls/includes ./templates/labels/label.tex.tx
    my $template_filename = File::Spec->catfile($curdir, 'templates', 'labels', 'labels.tex.tx');
    # optionally specify a logo image
    my $logo_filename = File::Spec->catfile($curdir, 'templates', 'images', 'logo.png');
    if( ! -e $logo_filename ){ $logo_filename = undef }

    my $output_filename = 'labels.pdf';

    # see LaTeX::Driver's doc for other formats, e.g. pdf(xelatex)
    my $latex_driver_and_format = 'pdf(pdflatex)';

    # debug settings:
    my $verbosity = 1;
    # keep intermediate latex file for inspection
    my $cleanup = 1;

    my $sender = {
      fullname => 'Gigi Comp',
      addresslines => [
        'Apt 5',
        '25, Jen Way',
        'Balac'
      ],
      postcode => '1An34',
      # this assumes that ./templates/images/logo.png exists, else comment it out:  
      logo => $logo_filename,
    };
    my @labels_data = map {
      {
        recipient => {
          fullname => "Teli Bingo ($_)",
          addresslines => [
            'Apt 5',
            '25, Jen Way',
            'Balac'
          ],
          postcode => '1An34',
        },
        sender => $sender,
      }
    } (1..42); # create many labels yummy

    my $latter = LaTeX::Easy::Templates->new({
      'debug' => {
        'verbosity' => $verbosity,
        'cleanup' => $cleanup
      },
      'processors' => {
        'custom-labels' => {
        'template' => {
          'filepath' => $template_filename,
        },
        'latex' => {
          'filepath' => 'xyz.tex',
          'latex-driver-parameters' => {
            'format' => $latex_driver_and_format,
          }
        }
        },
      }
    });
    die "failed to instantiate 'LaTeX::Easy::Templates'" unless defined $latter;

    my $ret = $latter->format({
      'template-data' => \@labels_data,
      'output' => {
        'filepath' => $output_filename,
      },
      'processor' => 'custom-labels',
    });
    die "failed to format the document, most likely latex command has failed." unless defined $ret;
    print "$0 : done, output in '$output_filename'.\n";

This is the result in very low resolution:

=begin HTML

<img src="data:image/jpeg;base64,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">

=end HTML

=head1 EXAMPLE: NESTED PERL DATA STRUCTURES TO PDF

Thanks to the amazing work put in L<Text::Xslate>
one can have access to user-defined Perl functions,
Perl modules and macros from inside a template file.

This allows recusrsion which makes possible walking and
printing a nested Perl data structure with this
simple template:

    %templates/nested-data-structures/nested-data-structures.tex.tx
    \documentclass[12pt]{article}
    \begin{document}

    : macro walk -> $d {
    :   if( ref($d) == 'ARRAY' ){
    $\lbrack$
    :     for $d -> $item {
    :       walk($item);
    :     }
    $\rbrack,$
    :   } elsif( ref($d) == 'HASH' ){
    $\{$
    :     for $d.kv() -> $pair {
            <: $pair.key() :> $=>$
    :       walk($pair.value())
    :     }
    $\},$
    :   } elsif( ref($d) == '' ){
          <: $d :>,
    :   } else {
          beginUNKNOWN <: $d :> endUNKNOWN
    :   }
    : } # macro

    <: walk($data) :>

    \end{document}

First we create a macro which walks the input data structure
and recurses into it until a scalar is found.

The function C<ref()> is Perl's builtin but it is not available
from inside an L<Text::Xslate> template. So, we create our own
function for doing this and pass it on to the L<Text::Xslate>'s
constructor, as was demonstrated previously with the
C<templater-parameters> hash pass to L<LaTeX::Easy::Templates>'s
L<constructor|<new()>.

Here is a Perl script to render any data structure into PDF:

    use strict;
    use warnings;

    use LaTeX::Easy::Templates;
    use FindBin;

    my $curdir = $FindBin::Bin;

    # the templates must be placed in ./templates/nested-data-structures
    my $template_filename = File::Spec->catfile($curdir, 'templates', 'nested-data-structures', 'nested-data-structures.tex.tx');

    my $output_filename = 'nested-data-structures.pdf';

    # see LaTeX::Driver's doc for other formats, e.g. pdf(xelatex)
    my $latex_driver_and_format = 'pdf(pdflatex)';

    my $nested_data_structure = {'a' => [1,2,3], 'b' => {'c' => [4,5,6, {'z'=>1}]}};

    # debug settings:
    my $verbosity = 1;
    # keep intermediate latex file for inspection
    my $cleanup = 1;

    my $latter = LaTeX::Easy::Templates->new({
      'debug' => {
        'verbosity' => $verbosity,
        'cleanup' => $cleanup
      },
      'templater-parameters' => {
        'function' => {'ref' => sub { return ref($_[0]) } }
      },
      'processors' => {
        'nested-data-structures' => {
          'template' => {
            'filepath' => $template_filename,
          },
          'latex' => {
            'filepath' => 'xyz.tex',
            'latex-driver-parameters' => {
              'format' => $latex_driver_and_format,
            }
          },
        }
      }
    });
    die "failed to instantiate 'LaTeX::Easy::Templates'" unless defined $latter;

    my $ret = $latter->format({
      'template-data' => $nested_data_structure,
      'output' => {
        'filepath' => $output_filename,
      },
      'processor' => 'nested-data-structures',
    });
    die "failed to format the document, most likely latex command has failed." unless defined $ret;
    print "$0 : done, output in '$output_filename'.\n";

And here is the result:

=begin HTML

<img src="data:image/jpeg;base64,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">

=end HTML

Thank you LaTeX, thank you Xslate.


=head1 STARTING WITH LaTeX

Currently, the best place to get started with LaTeX is at
the site L<https://www.overleaf.com/> (which I am not affiliated in any way).
There is no subscription involved or any registration required.

Click on L<Templates|https://www.overleaf.com/latex/templates>
and search the presented PDFs of example typeset documents
for a look you fancy. For example, if you are scraping a news
website you may be interested in the
L<Committee Times|https://www.overleaf.com/latex/templates/newspaper-slash-news-letter-template/wjxxhkxdjxhw> template.
First check its license and if you agree with that, click on B<View Source>, copy the contents and paste
them into your new LaTeX file, let's call that C<main.tex> located in a new directory C<templates/committee-times>.

Firstly, run latex on it  with this command C<latex main.tex>.
It will fail if it can not find, in your LaTeX installation,
the packages it requires.
For example it requires package C<newspaper>.
If it complains that certain packages are not found,
please read section L</INSTALLING LaTeX PACKAGES>.

Now study that LaTeX source file and identify what template variables
and control structures to use in order to turn it into a template.
Rename the file to C<main.tex.tx> and you are ready.

Naturally, there will be a lot of head banging and hair pulling before you
manage to produce results.

=head1 LaTeX TEMPLATES

Creating a LaTeX template is very easy. You need to start with
a usual LaTeX document and identify those sections which can be
replaced by the template variables. You can also identify
repeated sections and replace them with loops.
It is exactly the same procedure as with creating HTML templates
or email messages templates.

At this moment, the template processor is L<Text::Xslate>.
Therefore the syntax for declaring template variables, loops,
conditionals, etc. must comply with what L<Text::Xslate>
expects. See
section L</TEMPLATE PROCESSING> for where to start
with L<Text::Xslate>.

A LaTeX template can live in memory as a Perl string
or on disk, as a file in its own directory or not.

If your template dependes on other templates you
can include all as files in the same directory.

If your template depends on your own
LaTeX style files, packages etc., then
include those in the same directory with
the LaTeX templates. Additionally, when specifying the location
of the template, specify C<basedir> and C<filename>
(instead of a single C<filepath>). This will
ensure that all file dependencies contained within
C<basedir> will be copied to the temporary processing
directories. See L</new()> for how this works.

=head1 INSTALLING LaTeX

Today, as far as I know,
there are two main TeX/LaTeX distributions:
L<MikTeX|https://miktex.org/>
and
L<TexLive|https://www.tug.org/texlive/>

Both provide the same LaTeX. They
just package different things with it.
And both provide package managers in order
to make installing extra packages easy.

I believe L<MikTeX|https://miktex.org/>
was, at some time, aimed for M$ systems and
L<TexLive|https://www.tug.org/texlive/>
for the proper operating systems.

My Linux package manager installs
L<TexLive|https://www.tug.org/texlive/>
and I am absolutely happy with it.

=head1 INSTALLING LaTeX PACKAGES

In Linux, it is preferred to install
LaTeX packages
via the system package manager.

With modern TeX distributions installing
LaTeX packages is quite simple. Both
L<MikTeX|https://miktex.org/>
and
L<TexLive|https://www.tug.org/texlive/>
provide package installers.

See L<this guide|https://en.wikibooks.org/wiki/LaTeX/Installing_Extra_Packages#Automatic_installation>
for more information.

=head2 Manual installation

This is the hard way.

All available LaTeX packages are
located at the L<Comprehensive TeX Archive Network (CTAN) site | https://ctan.org>.
Search the package, download it, locate and change to your
LaTeX installation directory (for example C</usr/share/texlive/texmf-dist>),
change to C<tex>. Decide which flavour of LaTeX (processor)
this package is for, e.g. C<latex>, C<pdflatex> or C<xelatex>,
change to that directory and unzip the downloaded file there.

=head1 TESTING

Some tests may fail because some required LaTeX fonts
and/or style files are missing from your LaTeX installation.
As of version 0.04 the test files which use complex
LaTeX formatting and may require extra LaTeX packages
have been designated as I<author tests> and have
been moved to the C<xt/> directory. They are not
part of the usual unit tests suite run with C<make test>.
They can be run using C<make authortest>. If there are failures,
try installing the missing LaTeX fonts and style files
(see section L</INSTALLING LaTeX PACKAGES>).
Or freshen up your LaTeX installation. In any event,
these tests are not important and their possible
failure should not cause any convern.

In order to run all tests download the
tarball distribution of this module from CPAN
(there is a link on the left side of the module's
page for that), extract it, enter the directory and do:

    perl Makefile.PL
    make all
    make test
    make authortest


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 HUGS

!Almaz!

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-easy-templates at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-Easy-Templates>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::Easy::Templates


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=LaTeX-Easy-Templates>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<https://metacpan.org/release/LaTeX-Easy-Templates>

=back


=head1 ACKNOWLEDGEMENTS

=over

=item * TeX/LaTeX - excellent typography, superb aesthetics.
Thank you Donald Knuth and Leslie Lamport and countless contributors.

=item * L<Text::Xslate> - fast and feature-rich template engine.
Thank you Shoichi Kaji and contributors.

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of LaTeX::Easy::Templates
