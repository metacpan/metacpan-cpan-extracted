=head1 NAME

DynaLoader::Functions - deconstructed dynamic C library loading

=head1 SYNOPSIS

    use DynaLoader::Functions qw(
	loadable_for_module
	linkable_for_loadable linkable_for_module);

    $loadable = loadable_for_module("Acme::Widget");
    @linkable = linkable_for_loadable($loadable);
    @linkable = linkable_for_module("Acme::Widget");

    use DynaLoader::Functions qw(dyna_load dyna_resolve dyna_unload);

    $libh = dyna_load($loadable, {
		require_symbols => ["boot_Acme__Widget"],
	    });
    my $bootfunc = dyna_resolve($libh, "boot_Acme__Widget");
    dyna_unload($libh);

=head1 DESCRIPTION

This module provides a function-based interface to dynamic loading as used
by Perl.  Some details of dynamic loading are very platform-dependent,
so correct use of these functions requires the programmer to be mindful
of the space of platform variations.

=cut

package DynaLoader::Functions;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(
	loadable_for_module linkable_for_loadable linkable_for_module
	dyna_load dyna_resolve dyna_unload
);

use constant _IS_VMS => $^O eq "VMS";
use constant _IS_NETWARE => $^O eq "NetWare";

# It is presumed that VMS::Filespec will always be installed on VMS.
# It is not listed as a dependency of this module, because it is
# unavailable on other platforms.
require VMS::Filespec if _IS_VMS;

# Load Carp lazily, as do DynaLoader and other things at this level.
sub _carp { require Carp; Carp::carp(@_); }
sub _croak { require Carp; Carp::croak(@_); }

# Logic duplicated from Params::Classify.  This is too much of an
# infrastructure module, an early build dependency, for it to have such
# a dependency.
sub _is_string($) {
	my($arg) = @_;
	return defined($arg) && ref(\$arg) eq "SCALAR";
}
sub _check_string($) { die "argument is not a string\n" unless &_is_string; }

# Logic duplicated from Module::Runtime for the same reason.
sub _check_module_name($) {
	if(!&_is_string) {
		die "argument is not a module name\n";
	} elsif($_[0] !~ /\A[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*\z/) {
		die "`$_[0]' is not a module name\n";
	}
}

=head1 FUNCTIONS

=head2 File finding

=over

=item loadable_for_module(MODULE_NAME)

I<MODULE_NAME> must be the name of a Perl module, in bareword syntax with
C<::> separators.  The named module is presumed to be an XS extension
following standard conventions, and its runtime-loadable C library file is
searched for.  If found, the name of the library file is returned.  If it
cannot be found, the function C<die>s with an informative error message.

If the named module is actually not an XS extension, or is not installed,
or stores its C library in a non-standard place, there is a non-trivial
danger that this function will find some other library file and believe
it to be the right one.  This function should therefore only be used
when there is an expectation that the module is installed and would in
normal operation load its corresponding C library.

=cut

sub loadable_for_module($) {
	my($modname) = @_;
	_check_module_name($modname);
	require DynaLoader;
	# This logic is derived from DynaLoader::bootstrap().  In places
	# it mixes native directory names from @INC and Unix-style
	# /-separated path syntax.  This apparently works correctly
	# everywhere, except for VMS where there's an explicit conversion.
	my @modparts = split(/::/,$modname);
	my $modfname = $modparts[-1];
	$modfname = &DynaLoader::mod2fname(\@modparts)
		if defined &DynaLoader::mod2fname;
	if(_IS_NETWARE) {
		# This ought to be part of mod2fname.
		$modfname = substr($modfname, 0, 8);
	}
	my $modpname = join("/",@modparts);
	my $loadlib = DynaLoader::dl_findfile(
			(map {
				my $d = $_;
				if(_IS_VMS) {
					$d = VMS::Filespec::unixpath($d);
					chop $d;
				}
				"-L$d/auto/$modpname";
			} @INC),
			@INC,
			$modfname)
		or _croak "Can't locate loadable object ".
			"for module $modname in \@INC (\@INC contains: @INC)";
	if(_IS_VMS && ((require Config),
			$Config::Config{d_vms_case_sensitive_symbols})) {
		$loadlib = uc($loadlib);
	}
	return $loadlib;
}

=item linkable_for_loadable(LOADABLE_FILENAME)

If symbols in one runtime-loadable C library are to be made available
to another runtime-loadable C library, depending on the platform it
may be necessary to refer to the exporting library when linking the
importing library.  Generally this is not required on Unix, but it is
required on Windows.  Where it is required to refer to the exporting
library at link time, the file used may be the loadable library file
itself, or may be a separate file used only for this purpose.  Given the
loadable form of an exporting library, this function determines what is
required at link time for an importing library.

I<LOADABLE_FILENAME> must be the name of a runtime-loadable C library
file.  The function checks what is required to link a library that will
at runtime import symbols from this library.  It returns a list (which
will be empty on many platforms) of names of files that must be used as
additional objects when linking the importing library.

=cut

my $linkable_finder = {
	MSWin32 => sub {
		require Config;
		if((my $basename = $_[0]) =~
				s/\.\Q$Config::Config{dlext}\E\z//oi) {
			foreach my $suffix (qw(.lib .a)) {
				my $impname = $basename.$suffix;
				return ($impname) if -e $impname;
			}
		}
		_croak "Can't locate linkable object for $_[0]";
	},
	cygwin => sub { ($_[0]) },
}->{$^O};

sub linkable_for_loadable($) {
	_check_string($_[0]);
	if($linkable_finder) {
		return $linkable_finder->($_[0]);
	} else {
		return ();
	}
}

=item linkable_for_module(MODULE_NAME)

Performs the job of L</linkable_for_loadable> (which see for explanation),
but based on a module name instead of a loadable library filename.

I<MODULE_NAME> must be the name of a Perl module, in bareword syntax
with C<::> separators.  The function checks what is required to link a
library that will at runtime import symbols from the loadable C library
associated with the module.  It returns a list (which will be empty
on many platforms) of names of files that must be used as additional
objects when linking the importing library.

=cut

sub linkable_for_module($) {
	if($linkable_finder) {
		return $linkable_finder->(loadable_for_module($_[0]));
	} else {
		_check_module_name($_[0]);
		return ();
	}
}

=back

=head2 Low-level dynamic loading

=over

=item dyna_load(LOADABLE_FILENAME[, OPTIONS])

Dynamically load the runtime-loadable C library in the file named
I<LOADABLE_FILENAME>.  The process is influenced by optional information
supplied in the hash referenced by I<OPTIONS>.  On the platforms that
make dynamic loading easiest it is not necessary to supply any options
(in which case the parameter may be omitted), but if wide portability
is required then some options are required.  The permitted keys in the
I<OPTIONS> hash are:

=over

=item B<resolve_using>

Reference to an array, default empty, of names of additional library
files required to supply symbols used by the library being loaded.
On most platforms this is not used.  On those platforms where it is
required, the need for this will be known by whatever generated the
library to be loaded, and it will normally be set by a bootstrap file
(see B<use_bootstrap_options> below).

=item B<require_symbols>

Reference to an array, default empty, of names of symbols expected to be
found in the library being loaded.  On most platforms this is not used,
but on some a library cannot be loaded without naming at least one symbol
for which a need can be satisfied by the library.

=item B<use_bootstrap_options>

Truth value, default false, controlling whether a "bootstrap" file will
be consulted as an additional source of options to control loading.
The "bootstrap" file, if it exists, is located in the same directory as
the loadable library file, and has a similar name differing only in its
C<.bs> ending.

=item B<symbols_global>

Truth value, default false, indicating whether symbols found in the
library being loaded must be made available to subsequently-loaded
libraries.  Depending on platform, symbols may be so available even if
it is not requested.  Some platforms, on the other hand, can't provide
this facility.

On platforms incapable of making loaded symbols globally available,
currently loading is liable to claim success while leaving the symbols
de facto unavailable.  It is intended that in the future such platforms
will instead generate an exception when this facility is requested.

=item B<unresolved_action>

String keyword indicating what should be done if unresolved symbols are
detected while loading the library.  It may be "B<ERROR>" (default)
to treat it as an error, "B<WARN>" to emit a warning, or "B<IGNORE>"
to ignore the situation.  Some platforms can't detect this problem,
so passing this check doesn't guarantee that there won't be any runtime
problems due to unresolved symbols.

=back

On success, returns a handle that can be used to refer to the loaded
library for subsequent calls to L</dyna_resolve> and L</dyna_unload>.
On failure, C<die>s.

=cut

sub dyna_load($;$) {
	my($loadable_filename, $options) = @_;
	$options = {} if @_ < 2;
	_check_string($loadable_filename);
	foreach(sort keys %$options) {
		_croak "bad dyna_load option `$_'" unless /\A(?:
			resolve_using|require_symbols|use_bootstrap_options|
			symbols_global|unresolved_action
		)\z/x;
	}
	my $unres_action = exists($options->{unresolved_action}) ?
		$options->{unresolved_action} : "ERROR";
	_croak "bad dyna_load unresolved_action value `$unres_action'"
		unless _is_string($unres_action) &&
			$unres_action =~ /\A(?:ERROR|WARN|IGNORE)\z/;
	require DynaLoader;
	_croak "dynamic loading not available in this perl"
		unless defined &DynaLoader::dl_load_file;
	local @DynaLoader::dl_resolve_using =
		exists($options->{resolve_using}) ?
			@{$options->{resolve_using}} : ();
	local @DynaLoader::dl_require_symbols =
		exists($options->{require_symbols}) ?
			@{$options->{require_symbols}} : ();
	if($options->{use_bootstrap_options}) {
		(my $bs = $loadable_filename) =~
			s/(?:\.[0-9A-Z_a-z]+)?(?:;[0-9]*)?\z/\.bs/;
		if(-s $bs) {
			eval { package DynaLoader; do $bs; };
			warn "$bs: $@" if $@ ne "";
		}
	}
	my $libh = DynaLoader::dl_load_file($loadable_filename,
			$options->{symbols_global} ? 0x01 : 0)
		or _croak "failed to load library $loadable_filename: ".
				"@{[DynaLoader::dl_error()]}";
	if($unres_action ne "IGNORE" &&
			(my @unresolved = DynaLoader::dl_undef_symbols())) {
		my $e = "undefined symbols in $loadable_filename: @unresolved";
		if($unres_action eq "ERROR") {
			DynaLoader::dl_unload_file($libh);
			_croak $e;
		} else {
			_carp $e;
		}
	}
	return $libh;
}

=item dyna_resolve(LIBRARY_HANDLE, SYMBOL_NAME[, OPTIONS])

Resolve the symbol I<SYMBOL> in the previously-loaded library
identified by the I<LIBRARY_HANDLE>.  The process is influenced by
optional information supplied in the hash referenced by I<OPTIONS>.
The permitted keys in the I<OPTIONS> hash are:

=over

=item B<unresolved_action>

String keyword indicating what should be done if the symbol cannot
be resolved.  It may be "B<ERROR>" (default) to treat it as an error,
"B<WARN>" to emit a warning and return C<undef>, or "B<IGNORE>" to return
C<undef> without a warning.

=back

On success, returns the value of the specified symbol, in a
platform-dependent format.  Returns C<undef> if the symbol could not be
resolved and this is not being treated as an error.

=cut

sub dyna_resolve($$;$) {
	my($libh, $symbol, $options) = @_;
	$options = {} if @_ < 3;
	foreach(sort keys %$options) {
		_croak "bad dyna_resolve option `$_'"
			unless /\Aunresolved_action\z/;
	}
	my $unres_action = exists($options->{unresolved_action}) ?
		$options->{unresolved_action} : "ERROR";
	_croak "bad dyna_load unresolved_action value `$unres_action'"
		unless _is_string($unres_action) &&
			$unres_action =~ /\A(?:ERROR|WARN|IGNORE)\z/;
	require DynaLoader;
	my $val = DynaLoader::dl_find_symbol($libh, $symbol);
	if(!defined($val) && $unres_action ne "IGNORE") {
		my $e = "undefined symbol: $symbol";
		if($unres_action eq "ERROR") {
			_croak $e;
		} else {
			_carp $e;
		}
	}
	return $val;
}

=item dyna_unload(LIBRARY_HANDLE[, OPTIONS])

Unload the previously-loaded library identified by the I<LIBRARY_HANDLE>.
The process is influenced by optional information supplied in the hash
referenced by I<OPTIONS>.  The permitted keys in the I<OPTIONS> hash are:

=over

=item B<fail_action>

String keyword indicating what should be done if unloading detectably
fails.  It may be "B<ERROR>" (default) to treat it as an error, "B<WARN>"
to emit a warning, or "B<IGNORE>" to ignore the situation.

=back

On some platforms unloading is not possible.  On any platform,
unloading can be expected to cause mayhem if any code from the library
is currently executing, if there are any live references to data in the
library, or if any symbols provided by the library are referenced by
any subsequently-loaded library.

=cut

sub dyna_unload($;$) {
	my($libh, $options) = @_;
	$options = {} if @_ < 2;
	foreach(sort keys %$options) {
		_croak "bad dyna_unload option `$_'" unless /\Afail_action\z/;
	}
	my $fail_action = exists($options->{fail_action}) ?
		$options->{fail_action} : "ERROR";
	_croak "bad dyna_load fail_action value `$fail_action'"
		unless _is_string($fail_action) &&
			$fail_action =~ /\A(?:ERROR|WARN|IGNORE)\z/;
	my $err;
	require DynaLoader;
	if(defined &DynaLoader::dl_unload_file) {
		DynaLoader::dl_unload_file($_[0])
			or $err = DynaLoader::dl_error();
	} else {
		$err = "can't unload on this platform";
	}
	if(defined($err) && $fail_action ne "IGNORE") {
		my $e = "failed to unload library: $err";
		if($fail_action eq "ERROR") {
			_croak $e;
		} else {
			_carp $e;
		}
	}
}

=back

=head1 SEE ALSO

L<DynaLoader>,
L<ExtUtils::CBuilder>,
L<XSLoader>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011, 2012, 2013, 2017
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
