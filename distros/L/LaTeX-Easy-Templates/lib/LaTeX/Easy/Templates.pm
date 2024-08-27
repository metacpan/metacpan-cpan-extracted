package LaTeX::Easy::Templates;

#########

### NOTE: latex basedir will be copied ALL, even if you specify a filepath!!

##########

use 5.010;
use strict;
use warnings;

our $VERSION = '0.06';

use Exporter qw(import);
our @EXPORT = qw(
	latex_driver_executable
);

use LaTeX::Driver;
use Text::Xslate;
use Mojo::Log;
use File::Spec;
use Storable qw/dclone/;
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
		$output_info = Storable::dclone($loaded_info->{$group});
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

		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : an in-memory template '".$pars{'processor'}."' has been specified ..."); }

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
		$latex_info = Storable::dclone($ret->{'latex'});
		$template_info = Storable::dclone($ret->{'template'});
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
		$log->error("error caught:\n--begin file contents:\n${filecontents}\n--end file contents.\n\n--begin stderr:\n".($latex_driver->stderr()//"<stderr na>")."\n--end stderr.\n--begin stdout:\n".($latex_driver->stdout()//"<stdout na>")."\n--end stdout.\n\n--begin parameters:\n".perl2dump(\%drivparams)."--end parameters.\n${whoami} (via $parent), line ".__LINE__." : error, failed to run latex on file '".$latex_info->{'filepath'}."' with above parameters, exception was caught: $@");
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
		$latex_info = Storable::dclone($loaded_info->{$group});
	}
	if( defined($latex_info->{'basedir'}) && (! -d $latex_info->{'basedir'}) ){ make_path($latex_info->{'basedir'}); if( ! -d $latex_info->{'basedir'} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, dir to place latex source files '".$latex_info->{'basedir'}."' is not a dir and could not be created."); return undef } }

	$group = 'template';
	my $template_info = {};
	# this will be set if basedir was specified, then we will copy all contents of basedir into latex dir
	# perhaps there are images etc.
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
		$template_info = Storable::dclone($loaded_info->{$group});
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
		$latex_info{'latex-driver-parameters'} = Storable::dclone($options->{$group}->{'latex-driver-parameters'});
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
				if( ! open($FH, '<:utf8', $template_info{'filepath'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : error, failed to open specified (in options) article template file '".$template_info{'filepath'}."', $!"); return undef }
				{ local $/ = undef; $content = <$FH> } close $FH;
				$template_inc_paths{ $template_info{'basedir'} }++;
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : template filename : '".$template_info{'filename'}."' in dir '".$template_info{'basedir'}."'.") }
			} elsif( exists($al->{'filepath'}) && defined($af=$al->{'filepath'}) ){
				# TODO: perhaps we don't need to load disk-based templates as inmemory???
				# read a template file from disk, we also record its basedir and abs filename
				my $FH;
				if( ! open($FH, '<:utf8', $af) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : template key '$ak' : error, failed to open specified (in options) article template file '$af', $!"); return undef }
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
			if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : processor '$ak' : warning, there is no 'output' section, output will be determined during format() ..."); }
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
	if( exists($src->{'templater-parameters'}) && defined($x=$src->{'templater-parameters'}) ){
		my $tem = $dst->{'templater-parameters'};
		for my $k (keys %$x){
			my $r = ref($x->{$k});
			# we deep clone only ARRAY and HASH,
			# we can have scalars and coderefs. dclone() can not clone coderefs, so:
			if( $r =~ /^HASH|ARRAY$/ ){ $tem->{$k} = Storable::dclone($x->{$k}) }
			else { $tem->{$k} = $x->{$k} }
		}
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
	} else { return Storable::dclone($drivobj->{_program_path}) }

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

Version 0.06

=head1 SYNOPSIS

This module provides functionality to format
text content, living in a Perl data structure,
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
      comments => [
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

etc.

The L<LaTeX::Easy::Templates> module
will then take your data and your LaTeX template
and produce the final rendered documents.

In section L</STARTING WITH LaTeX> you will see how to easily build a LaTeX template
from open source, publicly available, superbly styled "I<themes>".

    use LaTeX::Easy::Templates;

    # templated LaTeX document in-memory
    # (with variables to be substituted)
    my $latex_template =<<'EOLA';
    % basic LaTeX document
    \documentclass[a4,12pt]{article}
    \begin{document}
    \title{ <: $data.title :> }
    \author{ <: $data.author.name :> <: $data.author.surname :> }
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

    my $latte = LaTeX::Easy::Templates->new({
      debug => {verbosity=>2, cleanup=>1},
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


=head1 STARTING WITH LaTeX

Currently, the best place to get started with LaTeX is at
the site L<https://www.overleaf.com/> (which I am not affiliated in any way).
There is no subscription involved or any registration required.

Click on L<Templates|https://www.overleaf.com/latex/templates> and search for anything
you are interested to typeset your data with. For example, if you are scraping a news
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
manage to produce anything decent.

=head1 LaTeX TEMPLATES

Creating a LaTeX template is very easy. You need to start with
a LaTeX document and identify those sections which can be
replaced by the template variables. You can also identify
repeated sections and replace them with loops.
It is exactly the same procedure as with creating HTML templates
or email messages templates.

At this moment, the template processor is L<Text::Xslate>.
Therefore the syntax for declaring template variables, loops,
conditionals, etc. must comply with L<Text::Xslate>. See
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
for the saner operating systems.

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
located at the L<Comprehensive TeX Archive Network (CTAN) site | https://ctan.org>. Search the package,
download it, locate and change to your LaTeX installation directory (for example C</usr/share/texlive/texmf-dist>),
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
tarball of this module, extract it,
enter the directory and do:

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

=item * LaTeX - excellent typography, superb aesthetics.

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of LaTeX::Easy::Templates
