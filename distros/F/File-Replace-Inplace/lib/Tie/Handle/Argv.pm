#!perl
package Tie::Handle::Argv;
use warnings;
use strict;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see Argv.pod

our $VERSION = '0.18';

require Tie::Handle::Base;
our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)

my %TIEHANDLE_KNOWN_ARGS = map {($_=>1)} qw/ files filename debug /;

sub TIEHANDLE {  ## no critic (RequireArgUnpacking)
	my $class = shift;
	croak $class."::tie/new: bad number of arguments" if @_%2;
	my %args = @_;
	for (keys %args) { croak "$class->tie/new: unknown argument '$_'"
		unless $TIEHANDLE_KNOWN_ARGS{$_} }
	croak "$class->tie/new: filename must be a scalar ref"
		if defined($args{filename}) && ref $args{filename} ne 'SCALAR';
	croak "$class->tie/new: files must be an arrayref"
		if defined($args{files}) && ref $args{files} ne 'ARRAY';
	my $self = $class->SUPER::TIEHANDLE();
	$self->{__lineno} = undef; # also keeps state: undef = not currently active, defined = active
	$self->{__debug} = ref($args{debug}) ? $args{debug} : ( $args{debug} ? *STDERR{IO} : undef);
	$self->{__s_argv} = $args{filename};
	$self->{__a_argv} = $args{files};
	return $self;
}

sub _debug {  ## no critic (RequireArgUnpacking)
	my $self = shift;
	return 1 unless $self->{__debug};
	confess "not enough arguments to _debug" unless @_;
	local ($",$,,$\) = (' ');
	return print {$self->{__debug}} ref($self), " DEBUG: ", @_ ,"\n";
}

sub inner_close {
	return shift->SUPER::CLOSE(@_);
}
sub _close {
	my $self = shift;
	confess "bad number of arguments to _close" unless @_==1;
	my $keep_lineno = shift;
	my $rv = $self->inner_close;
	if ($keep_lineno)
		{ $. = $self->{__lineno} }  ## no critic (RequireLocalizedPunctuationVars)
	else
		{ $. = $self->{__lineno} = 0 }  ## no critic (RequireLocalizedPunctuationVars)
	return $rv; # see tests in 20_tie_handle_base.t: we know close always returns a scalar
}
sub CLOSE { return shift->_close(0) }

sub init_empty_argv {
	my $self = shift;
	$self->_debug("adding '-' to file list");
	unshift @{ defined $self->{__a_argv} ? $self->{__a_argv} : \@ARGV }, '-';
	return;
}
sub advance_argv {
	my $self = shift;
	# Note: we do these gymnastics with the references because we always want
	# to access the currently global $ARGV and @ARGV - if we just stored references
	# to these in our object, we wouldn't notices changes due to "local"ization!
	return ${ defined $self->{__s_argv} ? $self->{__s_argv} : \$ARGV }
		= shift @{ defined $self->{__a_argv} ? $self->{__a_argv} : \@ARGV };
}
sub sequence_end {}
sub _advance {
	my $self = shift;
	my $peek = shift;
	confess "too many arguments to _advance" if @_;
	if ( !defined($self->{__lineno}) && !@{ defined $self->{__a_argv} ? $self->{__a_argv} : \@ARGV } ) {
		$self->_debug("file list is initially empty (\$.=0)");
		# the normal <> also appears to reset $. to 0 in this case:
		$. = 0;  ## no critic (RequireLocalizedPunctuationVars)
		$self->init_empty_argv;
	}
	FILE: {
		$self->_close(1) if defined $self->{__lineno};
		if ( !@{ defined $self->{__a_argv} ? $self->{__a_argv} : \@ARGV } ) {
			$self->_debug("file list is now empty, closing and done (\$.=$.)");
			$self->{__lineno} = undef unless $peek;
			$self->sequence_end;
			return;
		} # else
		my $fn = $self->advance_argv;
		$self->_debug("opening '$fn'");
		# note: ->SUPER::OPEN uses ->CLOSE, but we don't want that, so we ->_close above
		if ( $self->OPEN($fn) ) {
			defined $self->{__lineno} or $self->{__lineno} = 0;
		}
		else {
			$self->_debug("open '$fn' failed: $!");
			warnings::warnif("inplace", "Can't open $fn: $!");
			redo FILE;
		}
	}
	return 1;
}

sub read_one_line {
	return scalar shift->SUPER::READLINE(@_);
}
sub READLINE {
	my $self = shift;
	$self->_debug("readline in ", wantarray?"list":"scalar", " context");
	my @out;
	RL_LINE: while (1) {
		while ($self->EOF(1)) {
			$self->_debug("current file is at EOF, advancing");
			$self->_advance or last RL_LINE;
		}
		my $line = $self->read_one_line;
		last unless defined $line;
		push @out, $line;
		$. = ++$self->{__lineno};  ## no critic (RequireLocalizedPunctuationVars)
		last unless wantarray;
	}
	$self->_debug("readline: ",0+@out," lines (\$.=$.)");
	return wantarray ? @out : $out[0];
}

sub inner_eof {
	return shift->SUPER::EOF(@_);
}
sub EOF {  ## no critic (RequireArgUnpacking)
	my $self = shift;
	# "Starting with Perl 5.12, an additional integer parameter will be passed.
	# It will be zero if eof is called without parameter;
	# 1 if eof is given a filehandle as a parameter, e.g. eof(FH);
	# and 2 in the very special case that the tied filehandle is ARGV
	# and eof is called with an empty parameter list, e.g. eof()."
	if (@_ && $_[0]==2) {
		while ( $self->inner_eof(1) ) {
			$self->_debug("eof(): current file is at EOF, peeking");
			if ( not $self->_advance("peek") ) {
				$self->_debug("eof(): could not peek => EOF");
				return !!1;
			}
		}
		$self->_debug("eof(): => Not at EOF");
		return !!0;
	}
	return $self->inner_eof(@_);
}

sub WRITE { croak ref(shift)." is read-only" }

sub UNTIE {
	my $self = shift;
	delete @$self{ grep {/^__(?!innerhandle)/} keys %$self };
	return $self->SUPER::UNTIE(@_);
}

sub DESTROY {
	my $self = shift;
	delete @$self{ grep {/^__(?!innerhandle)/} keys %$self };
	return $self->SUPER::DESTROY(@_);
}

1;
