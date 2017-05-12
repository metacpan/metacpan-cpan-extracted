package Inline::Java ;
@Inline::Java::ISA = qw(Inline Exporter) ;

# Export the cast function if wanted
@EXPORT_OK = qw(cast coerce study_classes caught jar j2sdk) ;


use strict ;
require 5.006 ;

$Inline::Java::VERSION = '0.53' ;


# DEBUG is set via the DEBUG config
if (! defined($Inline::Java::DEBUG)){
	$Inline::Java::DEBUG = 0 ;
}

# Set DEBUG stream
*DEBUG_STREAM = *STDERR ;

require Inline ;
use Carp ;
use Config ;
use File::Copy ;
use File::Spec ;
use Cwd ;
use Data::Dumper ;

use Inline::Java::Portable ;
use Inline::Java::Class ;
use Inline::Java::Object ;
use Inline::Java::Array ;
use Inline::Java::Handle ;
use Inline::Java::Protocol ;
use Inline::Java::Callback ;
# Must be last.
use Inline::Java::JVM ;
# Our default J2SK
require Inline::Java->find_default_j2sdk() ;


# This is set when the script is over.
my $DONE = 0 ;

# This is set when at least one JVM is loaded.
my $JVM = undef ;

# This list will store the $o objects...
my @INLINES = () ;

my $report_version = "V2" ;

# This stuff is to control the termination of the Java Interpreter
sub done {
	my $signal = shift ;

	# To preserve the passed exit code...
	my $ec = $? ;

	$DONE = 1 ;

	if (! $signal){
		Inline::Java::debug(1, "killed by natural death.") ;
	}
	else{
		Inline::Java::debug(1, "killed by signal SIG$signal.") ;
	}

	shutdown_JVM() ;
	Inline::Java::debug(1, "exiting with $ec") ;
	CORE::exit($ec) ;
	exit($ec) ;
}


END {
	if ($DONE < 1){
		done() ;
	}
}


# To export the cast function and others.
sub import {
	my $class = shift ;

	foreach my $a (@_){
		if ($a eq 'jar'){
			print Inline::Java::Portable::get_server_jar() ;
			exit() ;
		}
		elsif ($a eq 'j2sdk'){
			print Inline::Java->find_default_j2sdk() . " says '" .
				Inline::Java::get_default_j2sdk() . "'\n" ;
			exit() ;
		}
		elsif ($a eq 'so_dirs'){
			print Inline::Java::Portable::portable('SO_LIB_PATH_VAR') . "=" . 
				join(Inline::Java::Portable::portable('ENV_VAR_PATH_SEP'), 
				Inline::Java::get_default_j2sdk_so_dirs()) ;
			exit() ;
		}
	}
    $class->export_to_level(1, $class, @_) ;
}



######################## Inline interface ########################



# Register this module as an Inline language support module
sub register {
	return {
		language => 'Java',
		aliases => ['JAVA', 'java'],
		type => 'interpreted',
		suffix => 'jdat',
	} ;
}


# Here validate is overridden because some of the config options are needed
# at load as well.
sub validate {
	my $o = shift ;

	# This might not print since debug is set further down...
	Inline::Java::debug(1, "Starting validate.") ;
	
	my $jdk = Inline::Java::get_default_j2sdk() ;
	my $dbg = $Inline::Java::DEBUG ;
	my %opts = @_ ;
	$o->set_option('DEBUG',					$dbg,			'i', 1, \%opts) ;
	$o->set_option('J2SDK',					$jdk,			's', 1, \%opts) ;
	$o->set_option('CLASSPATH',				'',				's', 1, \%opts) ;

	$o->set_option('BIND',					'localhost',	's', 1, \%opts) ;
	$o->set_option('HOST',					'localhost',	's', 1, \%opts) ;
	$o->set_option('PORT',					-1,				'i', 1, \%opts) ;
	$o->set_option('STARTUP_DELAY',			15,				'i', 1, \%opts) ;
	$o->set_option('SHARED_JVM',			0,				'b', 1, \%opts) ;
	$o->set_option('START_JVM',				1,				'b', 1, \%opts) ;
	$o->set_option('JNI',					0,				'b', 1, \%opts) ;
	$o->set_option('EMBEDDED_JNI',			0,				'b', 1, \%opts) ;
	$o->set_option('NATIVE_DOUBLES',		0,				'b', 1, \%opts) ;

	$o->set_option('WARN_METHOD_SELECT',	0,				'b', 1, \%opts) ;
	$o->set_option('STUDY',					undef,			'a', 0, \%opts) ;
	$o->set_option('AUTOSTUDY',				0,				'b', 1, \%opts) ;

	$o->set_option('EXTRA_JAVA_ARGS',		'',				's', 1, \%opts) ;
	$o->set_option('EXTRA_JAVAC_ARGS',		'',				's', 1, \%opts) ;
	$o->set_option('DEBUGGER',				0,				'b', 1, \%opts) ;

	$o->set_option('PRIVATE',				'',				'b', 1, \%opts) ;
	$o->set_option('PACKAGE',				'',				's', 1, \%opts) ;

	my @left_overs = keys(%opts) ;
	if (scalar(@left_overs)){
		croak "'$left_overs[0]' is not a valid configuration option for Inline::Java" ;
	}

	# Now for the post processing
	$Inline::Java::DEBUG = $o->get_java_config('DEBUG') ;

	# Embedded JNI turns on regular JNI
	if ($o->get_java_config('EMBEDDED_JNI')){
		$o->set_java_config('JNI', 1) ;
	}

	if ($o->get_java_config('PORT') == -1){
		if ($o->get_java_config('SHARED_JVM')){
			$o->set_java_config('PORT', 7891) ;
		}
		else{
			$o->set_java_config('PORT', -7890) ;
		}
	}

	if (($o->get_java_config('JNI'))&&($o->get_java_config('SHARED_JVM'))){
		croak("You can't use the 'SHARED_JVM' option in 'JNI' mode") ;
	}
	if (($o->get_java_config('JNI'))&&($o->get_java_config('DEBUGGER'))){
		croak("You can't invoke the Java debugger ('DEBUGGER' option) in 'JNI' mode") ;
	}
	if ((! $o->get_java_config('SHARED_JVM'))&&(! $o->get_java_config('START_JVM'))){
		croak("Disabling the 'START_JVM' option only makes sense in 'SHARED_JVM' mode") ;
	}

	if ($o->get_java_config('JNI')){
		require Inline::Java::JNI ;
	}

	if ($o->get_java_config('DEBUGGER')){
		# Here we want to tweak a few settings to help debugging...
		Inline::Java::debug(1, "Debugger mode activated") ;
		# Add the -g compile option
		$o->set_java_config('EXTRA_JAVAC_ARGS', $o->get_java_config('EXTRA_JAVAC_ARGS') . " -g ") ;
		# Add the -sourcepath runtime option
		$o->set_java_config('EXTRA_JAVA_ARGS', $o->get_java_config('EXTRA_JAVA_ARGS') .
			" -sourcepath " . $o->get_api('build_dir') .
			Inline::Java::Portable::portable("ENV_VAR_PATH_SEP_CP") .
			Inline::Java::Portable::get_source_dir()
		) ;
	}	

	my $study = $o->get_java_config('STUDY') ;
	if ((defined($study))&&(ref($study) ne 'ARRAY')){
		croak "Configuration option 'STUDY' must be an array of Java class names" ;
	}

	Inline::Java::debug(1, "validate done.") ;
}


sub set_option {
	my $o = shift ;
	my $name = shift ;
	my $default = shift ;
	my $type = shift ;
	my $env_or = shift ;
	my $opts = shift ;
	my $desc = shift ;

	if (! exists($o->{ILSM}->{$name})){
		my $val = undef ;
		if (($env_or)&&(exists($ENV{"PERL_INLINE_JAVA_$name"}))){
			$val = $ENV{"PERL_INLINE_JAVA_$name"} ;
		}
		elsif (exists($opts->{$name})){
			$val = $opts->{$name} ;
		}
		else{
			$val = $default ;
		}

		if ($type eq 'b'){
			if (! defined($val)){
				$val = 0 ;
			}
			$val = ($val ? 1 : 0) ;
		}
		elsif ($type eq 'i'){
			if ((! defined($val))||($val !~ /\d/)){
				$val = 0 ;
			}
			$val = int($val) ;
		}

		$o->set_java_config($name, $val) ;
	}

	delete $opts->{$name} ;
}


sub get_java_config {
	my $o = shift ;
	my $param = shift ;

	return $o->{ILSM}->{$param} ;
}


sub set_java_config {
	my $o = shift ;
	my $param = shift ;
	my $value = shift ;

	return $o->{ILSM}->{$param} = $value ;
}


# In theory we shouldn't need to use this, but it seems
# it's not all accessible by the API yet.
sub get_config {
	my $o = shift ;
	my $param = shift ;

	return $o->{CONFIG}->{$param} ;
}


sub get_api {
	my $o = shift ;
	my $param = shift ;

	# Allows us to force a specific package...
	if (($param eq 'pkg')&&($o->get_config('PACKAGE'))){
		return $o->get_config('PACKAGE') ;
	}

	return $o->{API}->{$param} ;
}


# Parse and compile Java code
sub build {
	my $o = shift ;

	if ($o->get_java_config('built')){
		return ;
	}

	Inline::Java::debug(1, "Starting build.") ;

	# Grab and untaint the current directory
	my $cwd = Cwd::cwd() ;
	if ($o->get_config('UNTAINT')){
		($cwd) = $cwd =~ /(.*)/ ;
	}

	# We must grab this before we change to the build dir because
	# it could be relative...
	my $server_jar = Inline::Java::Portable::get_server_jar() ;

	# We need to add all the previous install dirs to the classpath because
	# they can access each other.
	my @prev_install_dirs = () ;
	foreach my $in (@INLINES){
		push @prev_install_dirs, File::Spec->catdir($in->get_api('install_lib'), 
			'auto', $in->get_api('modpname')) ;
	}

	my $cp = $ENV{CLASSPATH} || '' ;
	$ENV{CLASSPATH} = Inline::Java::Portable::make_classpath($server_jar, @prev_install_dirs, $o->get_java_config('CLASSPATH')) ;
	Inline::Java::debug(2, "classpath: $ENV{CLASSPATH}") ;

	# Create the build dir and go there
	my $build_dir = $o->get_api('build_dir') ;
	$o->mkpath($build_dir) ;
	chdir $build_dir ;

	my $code = $o->get_api('code') ;
	my $pcode = $code ;
	my $study_only = ($code =~ /^(STUDY|SERVER)$/) ;
	my $source = ($study_only ? '' : $o->get_api('modfname') . ".java") ;

	# Parse code to check for public class
	$pcode =~ s/\\\"//g ;
	$pcode =~ s/\"(.*?)\"//g ;
	$pcode =~ s/\/\*(.*?)\*\///gs ;
	$pcode =~ s/\/\/(.*)$//gm ;
	if ($pcode =~ /public\s+(abstract\s+)?class\s+(\w+)/){
		$source = "$2.java" ;
	}

	my $install_dir = File::Spec->catdir($o->get_api('install_lib'), 
		'auto', $o->get_api('modpname')) ;
	$o->mkpath($install_dir) ;

	if ($source){
		# Dump the source code...
		open(Inline::Java::JAVA, ">$source") or
			croak "Can't open $source: $!" ;
		print Inline::Java::JAVA $code ;
		close(Inline::Java::JAVA) ;

		# ... and compile it.
		my $javac = File::Spec->catfile($o->get_java_config('J2SDK'), 
			Inline::Java::Portable::portable("J2SDK_BIN"), 
			"javac" . Inline::Java::Portable::portable("EXE_EXTENSION")) ;
		my $redir = Inline::Java::Portable::portable("IO_REDIR") ;

		my $args = "-deprecation " . $o->get_java_config('EXTRA_JAVAC_ARGS') ;
		my $pinstall_dir = Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", $install_dir) ;
		my $cmd = Inline::Java::Portable::portable("SUB_FIX_CMD_QUOTES", 
			"\"$javac\" $args -d \"$pinstall_dir\" $source > cmd.out $redir") ;
		if ($o->get_config('UNTAINT')){
			($cmd) = $cmd =~ /(.*)/ ;
		}
		Inline::Java::debug(2, "$cmd") ;
		my $res = system($cmd) ;
		my $msg = $o->get_compile_error_msg() ;
		if ($res){
			croak $o->compile_error_msg($cmd, $msg) ;
		} ;
		if ($msg){
			warn("\n$msg\n") ;
		}

		# When we run the commands, we quote them because in WIN32 you need it if
		# the programs are in directories which contain spaces. Unfortunately, in
		# WIN9x, when you quote a command, it masks it's exit value, and 0 is always
		# returned. Therefore a command failure is not detected.
		# We need to take care of checking whether there are actually files
		# to be copied, and if not will exit the script.
		if (Inline::Java::Portable::portable('COMMAND_COM')){
			my @fl = Inline::Java::Portable::find_classes_in_dir($install_dir) ;
		 	if (! scalar(@fl)){
				croak "No class files produced. Previous command failed under command.com?" ;
			}
		 	foreach my $f (@fl){
				if (! (-s $f->{file})){
					croak "File $f->{file} has size zero. Previous command failed under command.com?" ;
				}
			}
		}
	}

	$ENV{CLASSPATH} = $cp ;
	Inline::Java::debug(2, "classpath: $ENV{CLASSPATH}") ;

	# Touch the .jdat file.
	my $jdat = File::Spec->catfile($install_dir, $o->get_api('modfname') . '.' . $o->get_api('suffix')) ;
	if (! open(Inline::Java::TOUCH, ">$jdat")){
		croak "Can't create file $jdat" ;
	}
	close(Inline::Java::TOUCH) ;

	# Go back and clean up
	chdir $cwd ;
	if (($o->get_api('cleanup'))&&(! $o->get_java_config('DEBUGGER'))){
		$o->rmpath('', $build_dir) ;
	}

	$o->set_java_config('built', 1) ;
	Inline::Java::debug(1, "build done.") ;
}


sub get_compile_error_msg {
	my $o = shift ;

	my $msg = '' ;
	if (open(Inline::Java::CMD, "<cmd.out")){
		$msg = join("", <Inline::Java::CMD>) ;
		close(Inline::Java::CMD) ;
	}

	return $msg ;
}


sub compile_error_msg {
	my $o = shift ;
	my $cmd = shift ;
	my $error = shift ;

	my $build_dir = $o->get_api('build_dir') ;

	my $lang = $o->get_api('language') ;
	return <<MSG

A problem was encountered while attempting to compile and install your Inline
$lang code. The command that failed was:
  $cmd

The build directory was:
$build_dir

The error message was:
$error

To debug the problem, cd to the build directory, and inspect the output files.

MSG
;
}


# Load and Run the Java Code.
sub load {
	my $o = shift ;

	if ($o->get_java_config('loaded')){
		return ;
	}

	Inline::Java::debug(1, "Starting load.") ;

	my $install_dir = File::Spec->catdir($o->get_api('install_lib'), 
		'auto', $o->get_api('modpname')) ;

	# If the JVM is not running, we need to start it here.
	my $cp = $ENV{CLASSPATH} || '' ;
	if (! $JVM){
		$ENV{CLASSPATH} = Inline::Java::Portable::make_classpath(
			Inline::Java::Portable::get_server_jar()) ;
		Inline::Java::debug(2, "classpath: $ENV{CLASSPATH}") ;
		$JVM = new Inline::Java::JVM($o) ;
		$ENV{CLASSPATH}	= $cp ;
		Inline::Java::debug(2, "classpath: $ENV{CLASSPATH}") ;

		my $pc = new Inline::Java::Protocol(undef, $o) ;
		$pc->AddClassPath(Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", Inline::Java::Portable::get_user_jar())) ;

		my $st = $pc->ServerType() ;
		if ((($st eq "shared")&&(! $o->get_java_config('SHARED_JVM')))||
			(($st eq "private")&&($o->get_java_config('SHARED_JVM')))){
			croak "JVM type mismatch on port " . $JVM->{port} ;
		}
	}

	$ENV{CLASSPATH}	= '' ;
	my @cp = Inline::Java::Portable::make_classpath($install_dir, $o->get_java_config('CLASSPATH')) ;
	$ENV{CLASSPATH}	= $cp ;
	
	my $pc = new Inline::Java::Protocol(undef, $o) ;
	$pc->AddClassPath(@cp) ;

	# Add our Inline object to the list.
	push @INLINES, $o ;
	$o->set_java_config('id', scalar(@INLINES) - 1) ;
	Inline::Java::debug(3, "Inline::Java object id is " . $o->get_java_config('id')) ;

	$o->study_module() ;
	if ((defined($o->get_java_config('STUDY')))&&(scalar($o->get_java_config('STUDY')))){
		$o->_study($o->get_java_config('STUDY')) ;
	}

	$o->set_java_config('loaded', 1) ;
	Inline::Java::debug(1, "load done.") ;
}


# This function 'studies' the classes generated by the inlined code.
sub study_module {
	my $o = shift ;

	my $install_dir = File::Spec->catdir($o->get_api('install_lib'),
		'auto', $o->get_api('modpname')) ;
	my $cache = $o->get_api('modfname') . '.' . $o->get_api('suffix') ;

	my $lines = [] ;
	if (! $o->get_java_config('built')){
		# Since we didn't build the module, this means that
		# it was up to date. We can therefore use the data
		# from the cache.
		Inline::Java::debug(1, "using jdat cache") ;
		my $p = File::Spec->catfile($install_dir, $cache) ;
		my $size = (-s $p) || 0 ;
		if ($size > 0){
			if (open(Inline::Java::CACHE, "<$p")){
				while (<Inline::Java::CACHE>){
					push @{$lines}, $_ ;
				}
				close(Inline::Java::CACHE) ;
			}
			else{
				croak "Can't open $p for reading: $!" ;
			}
		}
	}
	else{
		# First thing to do is get the list of classes that comprise the module.

		# We need the classes that are in the directory or under...
		my @classes = () ;
		my $cwd = Cwd::cwd() ;
		if ($o->get_config('UNTAINT')){
			($cwd) = $cwd =~ /(.*)/ ;
		}

		# We chdir to the install dir, that makes it easier to figure out
		# the packages for the classes.
		chdir($install_dir) ;
		my @fl = Inline::Java::Portable::find_classes_in_dir('.') ;
		chdir $cwd ;
		foreach my $f (@fl){
			push @classes, $f->{class} ;
		}

		# Now we ask Java the info about those classes...
		$lines = $o->report(@classes) ;

		# and we update the cache with these results.
		Inline::Java::debug(1, "updating jdat cache") ;
		my $p = File::Spec->catfile($install_dir, $cache) ;
		if (open(Inline::Java::CACHE, ">$p")){
			foreach my $l (@{$lines}){
				print Inline::Java::CACHE "$l\n" ;
			}
			close(Inline::Java::CACHE) ;
		}
		else{
			croak "Can't open $p file for writing" ;
		}
	}

	# Now we read up the symbols and bind them to Perl.
	$o->bind_jdat($o->load_jdat($lines)) ;
}


# This function 'studies' the specified classes and binds them to 
# Perl.
sub _study {
	my $o = shift ;
	my $classes = shift ;

	my @new_classes = () ;
	foreach my $class (@{$classes}){
		$class = Inline::Java::Class::ValidateClass($class) ;
		if (! Inline::Java::known_to_perl($o->get_api('pkg'), $class)){
			push @new_classes, $class ;
		}
	}
	if (! scalar(@new_classes)){
		return ;
	}
	
	my $lines = $o->report(@new_classes) ;
	# Now we read up the symbols and bind them to Perl.
	$o->bind_jdat($o->load_jdat($lines)) ;
}


sub report {
	my $o = shift ;
	my @classes = @_ ;

	my @lines = () ;
	if (scalar(@classes)){
		my $pc = new Inline::Java::Protocol(undef, $o) ;
		my $resp = $pc->Report(join(" ", @classes)) ;
		@lines = split("\n", $resp) ;
	}

	return \@lines ;
}


# Load the jdat code information file.
sub load_jdat {
	my $o = shift ;
	my $lines = shift ;

	Inline::Java::debug_obj($lines) ;

	# We need an array here since the same object can have many 
	# study sessions.
	if (! defined($o->{ILSM}->{data})){
		$o->{ILSM}->{data} = [] ;
	}
	my $d = {} ;
	my $data_idx = scalar(@{$o->{ILSM}->{data}}) ;
	push @{$o->{ILSM}->{data}}, $d ;
	
	# The original regexp didn't match anymore under the debugger...
	# Very strange indeed...
	# my $re = '[\w.\$\[;]+' ;
	my $re = '.+' ;

	my $idx = 0 ;
	my $current_class = undef ;
	if (scalar(@{$lines})){
		my $vline = shift @{$lines} ;
		chomp($vline) ;
		if ($vline ne $report_version){
			croak("Report version mismatch ($vline != $report_version). Delete your '_Inline' and try again.") ; 
		}
	}
	foreach my $line (@{$lines}){
		chomp($line) ;
		if ($line =~ /^class ($re) ($re)$/){
			# We found a class definition
			my $java_class = $1 ;
			my $parent_java_class = $2 ;
			$current_class = Inline::Java::java2perl($o->get_api('pkg'), $java_class) ;
			$d->{classes}->{$current_class} = {} ;
			$d->{classes}->{$current_class}->{java_class} = $java_class ;
			if ($parent_java_class ne "null"){
				$d->{classes}->{$current_class}->{parent_java_class} = $parent_java_class ;
			}
			$d->{classes}->{$current_class}->{constructors} = {} ;
			$d->{classes}->{$current_class}->{methods} = {} ;
			$d->{classes}->{$current_class}->{fields} = {} ;
		}
		elsif ($line =~ /^constructor \((.*)\)$/){
			my $signature = $1 ;

			$d->{classes}->{$current_class}->{constructors}->{$signature} = 
				{
					SIGNATURE => [split(", ", $signature)],
					STATIC => 1,
					IDX => $idx,
				} ;
		}
		elsif ($line =~ /^method (\w+) ($re) (\w+)\((.*)\)$/){
			my $static = $1 ;
			my $declared_in = $2 ;
			my $method = $3 ;
			my $signature = $4 ;

			if (! defined($d->{classes}->{$current_class}->{methods}->{$method})){
				$d->{classes}->{$current_class}->{methods}->{$method} = {} ;
			}

			$d->{classes}->{$current_class}->{methods}->{$method}->{$signature} = 
				{
					SIGNATURE => [split(", ", $signature)],
					STATIC => ($static eq "static" ? 1 : 0),
					IDX => $idx,
				} ;
		}
		elsif ($line =~ /^field (\w+) ($re) (\w+) ($re)$/){
			my $static = $1 ;
			my $declared_in = $2 ;
			my $field = $3 ;
			my $type = $4 ;

			if (! defined($d->{classes}->{$current_class}->{fields}->{$field})){
				$d->{classes}->{$current_class}->{fields}->{$field} = {} ;
			}

			$d->{classes}->{$current_class}->{fields}->{$field}->{$type} =  
				{
					TYPE => $type,
					STATIC => ($static eq "static" ? 1 : 0),
					IDX => $idx,
				} ;
		}
		$idx++ ;
	}

	Inline::Java::debug_obj($d) ;

	return ($d, $data_idx) ;
}


# Binds the classes and the methods to Perl
sub bind_jdat {
	my $o = shift ;
	my $d = shift ;
	my $idx = shift ;

	if (! defined($d->{classes})){
		return ;
	}

	my $inline_idx = $o->get_java_config('id') ;

	my %classes = %{$d->{classes}} ;
	foreach my $class (sort keys %classes) {
		my $class_name = $class ;
		$class_name =~ s/^(.*)::// ;

		my $java_class = $d->{classes}->{$class}->{java_class} ;
		# This parent stuff is needed for PerlNatives (so that you can call PerlNatives methods
		# from Perl...)
		my $parent_java_class = $d->{classes}->{$class}->{parent_java_class} ;
		my $parent_module = '' ;
		my $parent_module_declare = '' ;
		if (defined($parent_java_class)){
			$parent_module = java2perl($o->get_api('pkg'), $parent_java_class) ;
			$parent_module_declare = "\$$parent_module" . "::EXISTS_AS_PARENT = 1 ;" ;
			$parent_module .= ' ' ;
		}
		if (Inline::Java::known_to_perl($o->get_api('pkg'), $java_class)){
			next ;
		}

		my $colon = ":" ;
		my $dash = "-" ;
		my $ijo = 'Inline::Java::Object' ;
		
		my $code = <<CODE;
package $class ;
use vars qw(\@ISA \$INLINE \$EXISTS \$JAVA_CLASS \$DUMMY_OBJECT) ;

$parent_module_declare
\@ISA = qw($parent_module$ijo) ;
\$INLINE = \$INLINES[$inline_idx] ;
\$EXISTS = 1 ;
\$JAVA_CLASS = '$java_class' ;
\$DUMMY_OBJECT = $class$dash>__new(
	\$JAVA_CLASS, \$INLINE, 0) ;

use Carp ;

CODE

		while (my ($field, $types) = each %{$d->{classes}->{$class}->{fields}}){
			while (my ($type, $sign) = each %{$types}){
				if ($sign->{STATIC}){
					$code .= <<CODE;
tie \$$class$colon:$field, "Inline::Java::Object::StaticMember", 
	\$DUMMY_OBJECT,
	'$field' ;
CODE
					# We have at least one static version of this field,
					# that's enough.
					# Don't forget to reset the 'each' static pointer
					keys %{$types} ;
					last ;
				}
			}
		}


		if (scalar(keys %{$d->{classes}->{$class}->{constructors}})){
			$code .= <<CODE;

sub new {
	my \$class = shift ;
	my \@args = \@_ ;

	my \$o = \$INLINE ;
	my \$d = \$o->{ILSM}->{data}->[$idx] ;
	my \$signatures = \$d->{classes}->{'$class'}->{constructors} ;
	my (\$proto, \$new_args, \$static) = \$class->__validate_prototype('new', [\@args], \$signatures, \$o) ;

	my \$ret = undef ;
	eval {
		\$ret = \$class->__new(\$JAVA_CLASS, \$o, -1, \$proto, \$new_args) ;
	} ;
	croak \$@ if \$@ ;

	return \$ret ;
}


sub $class_name {
	return new(\@_) ;
}

CODE
		}

		while (my ($method, $sign) = each %{$d->{classes}->{$class}->{methods}}){
			$code .= $o->bind_method($idx, $class, $method) ;
		}

		Inline::Java::debug_obj(\$code) ;

		# open (Inline::Java::CODE, ">>code") and print CODE $code and close(CODE) ;

		# Here it seems that for the eval below to resolve the @INLINES
		# list properly, it must be used in this function...
		my $dummy = scalar(@INLINES) ;

		eval $code ;

		croak $@ if $@ ;
	}
}


sub bind_method {
	my $o = shift ;
	my $idx = shift ;
	my $class = shift ;
	my $method = shift ;
	my $static = shift ;

	my $code = <<CODE;

sub $method {
	my \$this = shift ;
	my \@args = \@_ ;

	my \$o = \$INLINE ;
	my \$d = \$o->{ILSM}->{data}->[$idx] ;
	my \$signatures = \$d->{classes}->{'$class'}->{methods}->{'$method'} ;
	my (\$proto, \$new_args, \$static) = \$this->__validate_prototype('$method', [\@args], \$signatures, \$o) ;

	if ((\$static)&&(! ref(\$this))){
		\$this = \$DUMMY_OBJECT ;
	}

	my \$ret = undef ;
	eval {
		\$ret = \$this->__get_private()->{proto}->CallJavaMethod('$method', \$proto, \$new_args) ;
	} ;
	croak \$@ if \$@ ;

	return \$ret ;
}

CODE

	return $code ; 
}


sub get_fields {
	my $o = shift ;
	my $class = shift ;

	my $fields = {} ;
	my $data_list = $o->{ILSM}->{data} ;

	foreach my $d (@{$data_list}){
		if (exists($d->{classes}->{$class})){
			while (my ($field, $value) = each %{$d->{classes}->{$class}->{fields}}){
				# Here $value is a hash that contains all the different
				# types available for the field $field
				$fields->{$field} = $value ;
			}
		}
	}

	return $fields ;
}


# Return a small report about the Java code.
sub info {
	my $o = shift ;

	if (! (($o->{INLINE}->{object_ready})||($o->get_java_config('built')))){
		$o->build() ;
	}

	if (! $o->get_java_config('loaded')){
		$o->load() ;
	}

	my $info = '' ;
	my $data_list = $o->{ILSM}->{data} ;

	foreach my $d (@{$data_list}){
		if (! defined($d->{classes})){
			next ;
		}

		my %classes = %{$d->{classes}} ;

		$info .= "The following Java classes have been bound to Perl:\n" ;
		foreach my $class (sort keys %classes) {
			$info .= "\n  class $class:\n" ;

			$info .= "    public methods:\n" ;
			while (my ($k, $v) = each %{$d->{classes}->{$class}->{constructors}}){
				my $name = $class ;
				$name =~ s/^(.*)::// ;
				$info .= "      $name($k)\n" ;
			}

			while (my ($k, $v) = each %{$d->{classes}->{$class}->{methods}}){
				while (my ($k2, $v2) = each %{$d->{classes}->{$class}->{methods}->{$k}}){
					my $static = ($v2->{STATIC} ? "static " : "") ;
					$info .= "      $static$k($k2)\n" ;
				}
			}

			$info .= "    public member variables:\n" ;
			while (my ($k, $v) = each %{$d->{classes}->{$class}->{fields}}){
				while (my ($k2, $v2) = each %{$d->{classes}->{$class}->{fields}->{$k}}){
					my $static = ($v2->{STATIC} ? "static " : "") ;
					my $type = $v2->{TYPE} ;

					$info .= "      $static$type $k\n" ;
				}
			}
		}
	}

    return $info ;
}



######################## General Functions ########################


sub __get_JVM {
	return $JVM ;
}


# For testing purposes only...
sub __clear_JVM {
	$JVM = undef ;
}


sub shutdown_JVM {
	if ($JVM){
		$JVM->shutdown() ;
		$JVM = undef ;
	}
}


sub reconnect_JVM {
	if ($JVM){
		$JVM->reconnect() ;
	}
}


sub capture_JVM {
	if ($JVM){
		$JVM->capture() ;
	}
}


sub i_am_JVM_owner {
	if ($JVM){
		return $JVM->am_owner() ;
	}
}


sub release_JVM {
	if ($JVM){
		$JVM->release() ;
	}
}


sub get_DEBUG {
	return $Inline::Java::DEBUG ;
}


sub get_DONE {
	return $DONE ;
}


sub set_DONE {
	$DONE = 1 ;
}


sub __get_INLINES {
	return \@INLINES ;
}


sub java2perl {
	my $pkg = shift ;
	my $jclass = shift ;

	$jclass =~ s/[.\$]/::/g ;

	if ((defined($pkg))&&($pkg)){
		$jclass = $pkg . "::" . $jclass ;
	}

	return $jclass ;
}


sub known_to_perl {
	my $pkg = shift ;
	my $jclass = shift ;

	my $perl_class = java2perl($pkg, $jclass) ;

	no strict 'refs' ;
	if (defined(${$perl_class . "::" . "EXISTS"})){
		Inline::Java::debug(3, "perl knows about '$jclass' ('$perl_class')") ;
		return 1 ;
	}
	else{
		Inline::Java::debug(3, "perl doesn't know about '$jclass' ('$perl_class')") ;
	}

	return 0 ;
}


sub debug {
	my $level = shift ;

	if (($Inline::Java::DEBUG)&&($Inline::Java::DEBUG >= $level)){
		my $x = " " x $level ;
		my $str = join("\n$x", @_) ;
		while (chomp($str)) {}
		print DEBUG_STREAM sprintf("[perl][%s]$x%s\n", $level, $str) ;
	}
}


sub debug_obj {
	my $obj = shift ;
	my $force = shift || 0 ;

	if (($Inline::Java::DEBUG >= 5)||($force)){
		debug(5, "Dump:\n" . Dumper($obj)) ;
		if (UNIVERSAL::isa($obj, "Inline::Java::Object")){
			# Print the guts as well...
			debug(5, "Private Dump:" . Dumper($obj->__get_private())) ;
		}
	}
}


sub dump_obj {
	my $obj = shift ;

	return debug_obj($obj, 1) ;
}


######################## Public Functions ########################


# If we are dealing with a Java object, we simply ask for a new "reference"
# with the requested class. 
sub cast {
	my $type = shift ;
	my $val = shift ;

	if (! UNIVERSAL::isa($val, "Inline::Java::Object")){
		croak("Type casting can only be used on Java objects. Use 'coerce' instead.") ;
	}

	return $val->__cast($type) ;
}


# coerce is used to force a specific prototype to be used.
sub coerce {
	my $type = shift ;
	my $val = shift ;
	my $array_type = shift ;

	if (UNIVERSAL::isa($val, "Inline::Java::Object")){
		croak("Type coercing can't be used on Java objects. Use 'cast' instead.") ;
	}

	my $o = undef ;
	eval {
		$o = new Inline::Java::Class::Coerce($type, $val, $array_type) ;
	} ;
	croak $@ if $@ ;
	
	return $o ;
}


sub study_classes {
	my $classes = shift ;
	my $package = shift || caller() ;

	my $o = undef ;
	my %pkgs = () ;
	foreach (@INLINES){
		my $i = $_ ;
		my $pkg = $i->get_api('pkg') || 'main' ;
		$pkgs{$pkg} = 1 ;
		if ($pkg eq $package){
			$o = $i ;
			last ;
		}
	}

	if (defined($o)){
		$o->_study($classes) ;
	}
	else {
		my $msg = "Can't place studied classes under package '$package' since Inline::Java was not used there. Valid packages are:\n" ;
		foreach my $pkg (keys %pkgs){
			$msg .= "  $pkg\n" ;
		}
		croak($msg) ;
	}
}


sub caught {
	my $class = shift ;

	my $e = $@ ;

	$class = Inline::Java::Class::ValidateClass($class) ;

	my $ret = 0 ;
	if (($e)&&(UNIVERSAL::isa($e, "Inline::Java::Object"))){
		my ($msg, $score) = $e->__isa($class) ;
		if ($msg){
			$ret = 0 ;
		}
		else{
			$ret = 1 ;
		}
	}
	$@ = $e ;

	return $ret ;
}


sub	find_default_j2sdk {
	my $class = shift ;

	return File::Spec->catfile('Inline', 'Java', 'default_j2sdk.pl') ;
}


1 ;
