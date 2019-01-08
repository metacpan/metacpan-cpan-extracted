#!perl
package Tie::Handle::Argv;
use warnings;
use strict;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.12';

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
__END__

=head1 Name

Tie::Handle::Argv - A base class for tying Perl's magic ARGV handle

=head1 Synopsis

=for comment
REMEMBER to keep these examples in sync with 91_author_pod.t

 package Tie::Handle::MyDebugArgv;
 use parent 'Tie::Handle::Argv';
 sub OPEN {
     my $self = shift;
     print STDERR "Debug: Open '@_'\n";
     return $self->SUPER::OPEN(@_);
 }

Then use your custom tied handle:

 tie *ARGV, 'Tie::Handle::MyDebugArgv';
 while (<>) {
     chomp;
     print "<$_>\n";
 }
 untie *ARGV;

=head1 Description

This is a base class for tied filehandles that reproduces the behavior
of Perl's C<ARGV> filehandle, more commonly known as the magic C<< <> >>
C<readline> operator. By itself, this class attempts to reproduce the
behavior of the magical C<ARGV> and its associated variables (C<$ARGV>,
C<@ARGV>, and C<$.>) as faithfully as possible.

B<This documentation is somewhat sparse>, because I assume that if you
want to subclass this class, you will probably have to look at its code
anyway. I will expand on it as necessary (patches and suggestions welcome).

=head2 Constructor

The constructor C<TIEHANDLE> takes several optional arguments as key/value
pairs:

=over

=item C<files>

If you set this to an array reference, that array will be used instead of
the default global C<@ARGV>.

=item C<filename>

If you set this to a reference to a scalar, then that scalar will be
populated with the current filename instead of the default global C<$ARGV>.

=item C<debug>

Described in L</Debugging>; set this to either a true value or a reference
to a filehandle to enable debugging.

=back

=head2 Subclassing

You should first study L<Tie::Handle::Base>, of which this class is a
subclass. In particular, note that this class wraps an "inner handle",
which is the underlying handle which is typically the "real" filehandle
that is being read from (but could in theory itself be a tied handle -
hint: see the C<set_inner_handle> method in L<Tie::Handle::Base>).

There are several methods that have been abstracted out so that you may
override their default behavior in subclasses, as follows. When overriding
methods from this class, I<make sure> you first understand their behavior,
and when you might need to call the superclass method.

=over

=item C<inner_close>

Override this if you want to intercept a call to
L<Tie::Handle::Base|Tie::Handle::Base>'s C<CLOSE> method.
Takes no arguments and, like C<CLOSE>, should always return a scalar
(typically true/false).

=item C<inner_eof>

Override this if you want to intercept a call to
L<Tie::Handle::Base|Tie::Handle::Base>'s C<EOF> method.
Takes zero or one arguments (see L<perltie>) and should always return
a scalar (typically true/false).

=item C<read_one_line>

Override this if you want to intercept a call to
L<Tie::Handle::Base|Tie::Handle::Base>'s C<READLINE> method.
Will only ever be called in scalar context and therefore should read
one line (as with Perl's C<readline>, the definition of "line" varies
depending on the current setting of the input record separator C<$/>).
Takes no arguments and should always return a scalar.

=item C<init_empty_argv>

This method is called when the magic C<ARGV> filehandle is read from the
first time and C<@ARGV> is empty. If you want the read to succeed, this
method needs to modify C<@ARGV> so that it is no longer empty.
The default implementation is Perl's normal behavior, which is
C<unshift @ARGV, '-';>.
Takes no arguments and should return nothing ("C<return;>").

=item C<advance_argv>

This method should modify C<$ARGV> so that it contains the next filename
to pass to the C<OPEN> method, and also return that filename.
The default implementation is Perl's normal behavior, which is
C<$ARGV = shift @ARGV;>.
Takes no arguments and should always return a scalar (the filename).

=item C<OPEN>

You may override this method to modify its behavior. Make sure you understand
its arguments and expected behavior - see L<Tie::Handle::Base/OPEN>
and L<perltie>.

=item C<sequence_end>

Override this if you want to take action after the last file in C<@ARGV>
has been closed.
Takes no arguments and should return nothing ("C<return;>").

=item Other methods: C<TIEHANDLE>, C<UNTIE>, C<DESTROY>

You may override these methods if needed, making sure to call the
superclass methods!

=item B<Don't> override: C<READLINE>, C<CLOSE>, or C<EOF>

These methods contain much of the logic of this class. I recommend using
the hooks provided above instead. If you are missing a hook, please report
the issue (with sample code and expected behavior) in the issue tracker.

In particular, note the source code of C<CLOSE> in this class: This method
is called when the user of the tied handle explicitly calls e.g.
C<close ARGV;>, which should have the effect of resetting the line number
counter C<$.>, whereas a C<close> operation that may occur when advancing
to the next file in the sequence should not. This is why there is an internal
C<_close> method to abstract out this behavior. If you do plan on overriding
C<CLOSE>, then make sure you call the appropriate method in this class.

=item Object Storage

Subclasses may store whatever they like in this hashref, I<except> that keys
beginning with two underscores (C<__>) are reserved for this base class
and for L<Tie::Handle::Base|Tie::Handle::Base>.

=back

This documentation describes version 0.12 of this module.

=head2 Warning About Perls Older Than v5.16 and Windows

Perl versions before 5.12 did not support C<eof()> (with an empty parameter
list) on tied handles. See also L<perltie/Tying FileHandles>
and L<perl5120delta/Other potentially incompatible changes>.

Also, Perl 5.14 had several regressions regarding, among other things,
C<eof> on tied handles. See L<perl5160delta/Filehandle, last-accessed>.

It is therefore B<strongly recommended> to use this module on Perl 5.16
and up. On older versions, be aware of the aforementioned issues.

In addition, there are some slight behavioral differences on Windows
up to and including Perl 5.16, and not all features of this module can
currently be tested on Windows, in particular in regards to opening anything
other than regular files, such as C<STDIN> via the special filename F<->.

=head2 Caveats and Known Differences to Perl's C<< <> >>

=over

=item *

Perl's C<tie> mechanism currently does not allow a tied C<ARGV> to
distinguish between a regular C<< <> >> operator and the newer double-diamond
C<<< <<>> >>> operator (introduced in Perl 5.22), which uses the three-argument
C<open>. When using this module, C<<< <<>> >>> will currently act the same
as C<< <> >>.

If a newer version of Perl is released which allows for tied filehandles
to make use of C<<< <<>> >>>, this module can be updated correspondingly.
(At the time of writing, all released versions of Perl, up to and including
5.28, do not support special treatment of C<<< <<>> >>> on tied filehandles.)

Note: On the other hand, this class can be used to change C<< <> >> to
work like C<<< <<>> >>> even on older Perls, for instance:

 package Tie::Handle::ThreeArgOpenArgv;
 use parent 'Tie::Handle::Argv';
 sub OPEN {
     my $self = shift;
     return $self->SUPER::OPEN('<',shift);
 }

=back

=head2 Debugging

This class contains a C<_debug> method that may be called by subclasses
to provide debug output (when enabled). C<TIEHANDLE> takes an argument
C<debug => $debug>, where C<$debug> is either a scalar with a true value,
in which case debugging messages will be sent to C<STDERR>, or a reference
to a filehandle, in which case debugging messages will be sent to that
filehandle.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

