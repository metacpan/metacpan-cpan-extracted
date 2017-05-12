package Math::Matlab::Local;

use strict;
use vars qw($VERSION $ROOT_MWD $CMD);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;
}

use Math::Matlab;
use base qw( Math::Matlab );

use Cwd qw( getcwd abs_path );

##-----  assign defaults, unless already set externally  -----
$CMD		= 'matlab -nodisplay -nojvm'	unless defined $CMD;
$ROOT_MWD	= getcwd						unless defined $ROOT_MWD;

##-----  Public Class Methods  -----
sub new {
	my ($class, $href) = @_;
	my $self	= {
		cmd					=> defined($href->{cmd})		? $href->{cmd}		: $CMD,
		root_mwd			=> defined($href->{root_mwd}) 	? $href->{root_mwd}	: $ROOT_MWD,
		err_msg				=> '',
		result				=> '',
		wrapper_fn			=> '',
		script_fn			=> '',
		output_fn			=> '',
		generated_script	=> undef,
	};

	bless $self, $class;
}

##-----  Public Object Methods  -----
sub execute {
	my ($self, $code, $rel_mwd, $script_fn) = @_;
	my $success	= 0;
	my ($cwd, $cmd);
	
	## clear err_msg
	$self->clear_err_msg;
	
	## save current directory and change to Matlab working directory
	$cwd = getcwd	if $self->root_mwd or $rel_mwd;
	if ($self->root_mwd) {
		chdir $self->root_mwd	or die("Couldn't chdir to '@{[ $self->root_mwd ]}'");
	}
	if ($rel_mwd) {
		my $mwd = abs_path( $rel_mwd );
		chdir $mwd	or die("Couldn't chdir to '$mwd'");
	}
	
	## create input files
	$self->_create_input_files($code, $script_fn);

	## set up command to fire off Matlab with the input file
	$cmd = sprintf('%s -r %s -logfile %s',
				$self->cmd, substr($self->wrapper_fn, 0, -2), $self->output_fn);

	## run it
	my $err = `$cmd 2>&1`;
	if (open(Matlab::IO, $self->output_fn)) {
		$self->{'result'} = join('', <Matlab::IO>);
		close(Matlab::IO);
		if ($self->{'result'} =~ /-----MATLAB-BEGIN-----\n-----SUCCESS/) {
			$success = 1;
			$self->remove_files;
		} elsif ($self->{'result'} =~ /-----MATLAB-BEGIN-----\n-----ERROR/) {
			## runtime error
			$self->err_msg(
				sprintf("MATLAB RUNTIME ERROR\n[%s] in [%s] returned:\n%s",
					$cmd, getcwd, $self->{'result'} )
			);
		} else {
			## couldn't execute Matlab code (compile err, license err)
			$self->err_msg(
				sprintf("MATLAB INITIALIZATION ERROR\n[%s] in [%s] returned:\n%s",
					$cmd, getcwd, $self->{'result'} )
			);
		}
	} else {
		## couldn't launch Matlab (no output file created)
		$self->err_msg(
			sprintf("MATLAB LAUNCH FAILURE\n[%s] in [%s] returned:\n%s",
				$cmd, getcwd, $err )
		);
	}

	## restore current working directory
	if ($cwd) {
		chdir $cwd	or die("Couldn't chdir to '$cwd'");
	}

	return $success;
}

sub cmd {			my $self = shift; return $self->_getset('cmd',			@_); }
sub root_mwd {		my $self = shift; return $self->_getset('root_mwd',		@_); }
sub wrapper_fn {	my $self = shift; return $self->_getset('wrapper_fn',	@_); }
sub script_fn {		my $self = shift; return $self->_getset('script_fn',	@_); }
sub output_fn {		my $self = shift; return $self->_getset('output_fn',	@_); }

sub remove_files {
	my ($self) = @_;

	unlink $self->script_fn		if $self->{generated_script} && -f $self->script_fn;
	unlink $self->wrapper_fn	if -f $self->wrapper_fn;
	unlink $self->output_fn		if -f $self->output_fn;
	$self->{script_fn} = '';
	$self->{wrapper_fn} = '';
	$self->{output_fn} = '';
}

sub _create_input_files {
	my ($self, $code, $script_fn) = @_;

	## set script file name
	if (defined($script_fn)) {		## name given
		if (-f $script_fn) {
			if ($code) {
				$self->{generated_script} = undef;
				die("File '$script_fn' already exists");
			} else {
				$self->{generated_script} = 0;
			}
		}
	} else {					## generate random name
		while (!defined($script_fn) or -f $script_fn ) {
			$script_fn = 'mm'.(int rand 10000000).'.m';		## generate random file name
		}
		$self->{generated_script} = 1;
	}

	## create script
	$self->script_fn( $script_fn );
	if ($self->{generated_script}) {
		$self->_create_script_file( $code );
	}

	## create command wrapper
	$self->_set_wrapper_fn;
	$self->_create_wrapper_file;

	## set output file name
	$self->_set_output_fn;

	return 1;
}

## Private class methods
sub _gen_script_name {	return 'mm'.(int rand 10000000).'.m'; }

## Private object methods
sub _set_wrapper_fn {
	my ($self) = @_;
	return $self->wrapper_fn( substr($self->script_fn, 0, -2).'_wrap.m' );
}
sub _set_output_fn {
	my ($self) = @_;
	return $self->output_fn( substr($self->script_fn, 0, -2).'_out.txt' );
}

sub _create_script_file {
	my ($self, $code) = @_;
	
	my $fn = $self->script_fn;
	open(Matlab::IO, ">$fn") || die "Couldn't open '$fn'";
	print Matlab::IO $code;
	close(Matlab::IO);

	return 1;
}

sub _create_wrapper_file {
	my ($self) = @_;
	
	my $fn = $self->wrapper_fn;
	open(Matlab::IO, ">$fn") || die "Couldn't open '$fn'";
	print Matlab::IO <<END_OF_CODE;
fprintf('-----MATLAB-BEGIN-----\\n');
try
	rv = evalc('@{[ substr($self->script_fn, 0, -2) ]}');
	fprintf('-----SUCCESS\\n\%s', rv);
catch
	fprintf('-----ERROR\\n\%s\\n\%s', lasterr);
end
quit;
END_OF_CODE
	close(Matlab::IO);

	return 1;
}



1;
__END__

=head1 NAME

Math::Matlab::Local - Interface to a local Matlab process.

=head1 SYNOPSIS

  use Math::Matlab::Local;
  $matlab = Math::Matlab::Local->new({
      cmd      => '/usr/local/matlab -nodisplay -nojvm',
      root_mwd => '/path/to/matlab/working/directory/'
  });
  
  my $code = q/fprintf( 'Hello world!\n' );/;
  if ( $matlab->execute($code) ) {
      print $matlab->fetch_result;
  } else {
      print $matlab->err_msg;
  }

=head1 DESCRIPTION

Math::Matlab::Local implements an interface to a local Matlab
executeable. It takes a string containing Matlab code, saves it to a
script file in a specified directory, along with a wrapper script, and
invokes the Matlab executeable with this wrapper file as input,
capturing everything the Matlab program prints to a result string.

=head1 Attributes

=over 4

=item cmd

A string containing the command used to invoke the Matlab executeable.
The default is taken from the package variable $CMD, whose default value
is 'matlab -nodisplay -nojvm'

=item root_mwd

A string containing the absolute path to the root Matlab working
directory. All Matlab code is executed in directories which are
specified relative to this path. The default is taken from the package
variable $ROOT_MWD, whose default value is the current working
directory.

=back

=head1 METHODS

=head2 Public Class Methods

=over 4

=item new

 $matlab = Math::Matlab::Local->new;
 $matlab = Math::Matlab::Local->new( {
    cmd      => '/usr/local/matlab -nodisplay -nojvm',
    root_mwd => '/root/matlab/working/directory/'
 } )

Constructor: creates an object which can run Matlab programs and return
the output. Attributes 'cmd' and 'root_mwd' can be initialized via a
hashref argument to new(). Defaults for these values are taken from the
package variables $CMD and $ROOT_MWD, respectively.

=back

=head2 Public Object Methods

=over 4

=item execute

 $TorF = $matlab->execute($code)
 $TorF = $matlab->execute($code, $relative_mwd)
 $TorF = $matlab->execute($code, $relative_mwd, $filename)

Takes a string containing Matlab code, saves it to a script file in a
specified directory, along with a wrapper script, and invokes the Matlab
executeable with this wrapper file as input, capturing everything the
Matlab program prints to a result string. The optional second argument
specifies the Matlab working directory relative to the root Matlab
working directory for the object. This is where the command file will be
created and Matlab invoked. The optional third argument specifies the
filename to use for the command file. If this name refers to an existing
file and the $code argument is undefined or an empty string, then the
existing file will be executed. The output is stored in the object.
Returns true if successful, false otherwise.

=item cmd

 $cmd = $matlab->cmd
 $cmd = $matlab->cmd($cmd)

Get or set the command used to invoke Matlab.

=item root_mwd

 $root_mwd = $matlab->root_mwd
 $root_mwd = $matlab->root_mwd($root_mwd)

Get or set the root Matlab working directory.

=item wrapper_fn

 $wrapper_fn = $matlab->wrapper_fn
 $wrapper_fn = $matlab->wrapper_fn($wrapper_fn)

Get or set the file name to use for the wrapper script.

=item script_fn

 $script_fn = $matlab->script_fn
 $script_fn = $matlab->script_fn($script_fn)

Get or set the file name to use for the script file.

=item output_fn

 $output_fn = $matlab->output_fn
 $output_fn = $matlab->output_fn($output_fn)

Get or set the file name to use for the output file.

=item remove_files

  $matlab->remove_files

Removes the wrapper script, script file and output file from the most
recent unsuccessful execute. They are removed automatically for a
successful execute. The script file is only removed if it was created
during the most recent execute.

=back

=head1 COPYRIGHT

Copyright (c) 2002, 2007 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1), Math::Matlab

=cut
