#!perl
package File::Replace::Inplace;
use warnings;
use strict;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see Inplace.pod

our $VERSION = '0.18';

our @CARP_NOT = qw/ File::Replace /;

# this var is used by File::Replace::import
our $GlobalInplace;  ## no critic (ProhibitPackageVars)

sub new {  ## no critic (RequireArgUnpacking)
	my $class = shift;
	croak "Useless use of $class->new in void context" unless defined wantarray;
	croak "$class->new: bad number of args" if @_%2;
	my %args = @_; # really just so we can inspect the debug option
	my $self = {
		_debug => ref($args{debug}) ? $args{debug} : ( $args{debug} ? *STDERR{IO} : undef),
		_h_argv => *ARGV{IO},
	};
	tie *{$self->{_h_argv}}, 'File::Replace::Inplace::TiedArgv', @_;
	bless $self, $class;
	$self->_debug("$class->new: tied ARGV\n");
	return $self;
}
*_debug = \&File::Replace::_debug;  ## no critic (ProtectPrivateVars)
sub cleanup {
	my $self = shift;
	if ( defined($self->{_h_argv}) && defined( my $tied = tied(*{$self->{_h_argv}}) ) ) {
		if ( $tied->isa('File::Replace::Inplace::TiedArgv') ) {
			$self->_debug(ref($self)."->cleanup: untieing ARGV\n");
			untie *{$self->{_h_argv}};
		}
		delete $self->{_h_argv};
	}
	delete $self->{_debug};
	return 1;
}
sub DESTROY { return shift->cleanup }

{
	## no critic (ProhibitMultiplePackages)
	package # hide from pause
		File::Replace::Inplace::TiedArgv;
	use Carp;
	use File::Replace;
	
	BEGIN {
		require Tie::Handle::Argv;
		our @ISA = qw/ Tie::Handle::Argv /;  ## no critic (ProhibitExplicitISA)
	}
	
	# this is mostly the same as %NEW_KNOWN_OPTS from File::Replace,
	# except without "in_fh" (note "debug" is also passed to the superclass)
	my %TIEHANDLE_KNOWN_OPTS = map {$_=>1} qw/ debug layers create chmod
		perms autocancel autofinish backup files filename /;
	
	sub TIEHANDLE {  ## no critic (RequireArgUnpacking)
		croak __PACKAGE__."->TIEHANDLE: bad number of args" unless @_ && @_%2;
		my ($class,%args) = @_;
		for (keys %args) { croak "$class->tie/new: unknown option '$_'"
			unless $TIEHANDLE_KNOWN_OPTS{$_} }
		my %superargs = map { exists($args{$_}) ? ($_=>$args{$_}) : () }
			qw/ files filename debug /;
		delete @args{qw/ files filename /};
		my $self = $class->SUPER::TIEHANDLE( %superargs );
		$self->{_repl_opts} = \%args;
		return $self;
	}
	
	sub OPEN {
		my $self = shift;
		croak "bad number of arguments to open" unless @_==1;
		my $filename = shift;
		if ($filename eq '-') {
			$self->_debug(ref($self).": Reading from STDIN, writing to STDOUT");
			$self->set_inner_handle(*STDIN{IO});
			select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		}
		else {
			$self->{_repl} = File::Replace->new($filename, %{$self->{_repl_opts}} );
			$self->set_inner_handle($self->{_repl}->in_fh);
			*ARGVOUT = $self->{_repl}->out_fh;  ## no critic (RequireLocalizedPunctuationVars)
			select(ARGVOUT);  ## no critic (ProhibitOneArgSelect)
		}
		return 1;
	}
	
	sub inner_close {
		my $self = shift;
		if ( $self->{_repl} ) {
			$self->{_repl}->finish;
			$self->{_repl} = undef;
		}
		return 1;
	}
	
	sub sequence_end {
		my $self = shift;
		$self->set_inner_handle(\do{local*HANDLE;*HANDLE})  ## no critic (RequireInitializationForLocalVars)
			if $self->innerhandle==*STDIN{IO};
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		return;
	}
	
	sub UNTIE {
		my $self = shift;
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		delete @$self{ grep {/^_[^_]/} keys %$self };
		return $self->SUPER::UNTIE(@_);
	}
	
	sub DESTROY {
		my $self = shift;
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		# File::Replace destructor will warn on unclosed file
		delete @$self{ grep {/^_[^_]/} keys %$self };
		return $self->SUPER::DESTROY(@_);
	}
	
}

1;
