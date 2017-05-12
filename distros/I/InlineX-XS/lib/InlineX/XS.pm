package InlineX::XS;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

InlineX::XS - Auto-convert Inline::C based modules to XS

=head1 SYNOPSIS

  package Your::Module;

  # Make sure your $VERSION is accessible at compile time for XSLoader:
  # (yes, this is strict-safe)
  our $VERSION = '0.01';
  BEGIN {$VERSION = '0.01'}

  # Replace the use of Inline::C:
  # use Inline C => <<'CODE';
  # becomes:

  use InlineX::XS <<'CODE';
     ... C code ...
  CODE

  # Perl code, more C, more Perl...
  
  # Replace the final '1;' of your module with:
  use InlineX::XS 'END';

=head1 DESCRIPTION

Make sure to read the CAVEATS section below before using this.
This is experimental software.

=head2 Introduction

Extending Perl with C was made much easier by the introduction of Ingy's
L<Inline> or rather L<Inline::C> module. It is possible to create
CPAN distributions which use C<Inline::C>, but traditionally, writing
XS, the C-to-Perl glue language, by hand has been considered
superior in that regard because C<Inline::C> writes its compiled shared
libraries to cache areas whereas the libraries compiled from XS are
properly installed. (I know, technically, C<Inline::C> I<generates XS on
the fly>.)

This module is intended to enable developers to use C<Inline::C> and
have the C code converted to (static) XS code before they make
a release.

=head2 How it works

Mostly, you replace any invocation of C<Inline::C> with C<InlineX::XS>
as follows:

  use Inline C => <<'CODE';
     ... C code ...
  CODE

becomes

  use InlineX::XS <<'CODE';
     ... C code ...
  CODE

Note that most advanced usage of C<Inline::C>
is currently B<ignored> by C<InlineX::XS> during packaging.
Also, C<InlineX::XS> cannot read from the C<__DATA__> section of your
module.

There are some other changes you need to make to your code, but
the above is the main difference. The other changes are shown in the
SYNOPSIS above.

C<InlineX::XS> will take the plain C code and first look for a loadable
shared object file which was compiled from XS and if that wasn't found,
fall back to passing the code to C<Inline::C>.

=head2 Packaging

By forcing C<InlineX::XS> into the packaging mode and compiling your C<.pm>
file with C<perl -c>, you can make it extract the
C code from your F<.pm> file into the F<src/> subdirectory. From there,
C<InlineX::C2XS> will be used to generate a F<.xs> file in the current
directory.

You may do so explicitly from the main distribution directory with the
following command:

  perl -c -MInlineX::XS=PACKAGE lib/Your/Module.pm

You should now have a shiny new XS file F<Module.XS>. Add it to the
distributions F<MANIFEST> file and you are good to go. But read on:

=head2 Easier packaging

More conveniently, you can just slightly modify your F<Makefile.PL> if you
are using L<ExtUtils::MakeMaker> and not the newer L<Module::Build> or
L<Module::Install>. It should be straightforward to do with those as well,
but I haven't explored that. Please contact me if you would like to give
a hand concerning support for other build systems.

In the F<Makefile.PL>, there is a call to C<WriteMakefile>. Add a key/value
pair to the argument list of this call:

  dist => {
    PREOP => 'perl -MInlineX::XS::MM=$(DISTNAME)-$(VERSION) -c lib/Your/Module.pm'
  }

Of course, you need to add a dependency on C<InlineX::XS>. You do B<not>
need a dependency on C<Inline::C>. On the user's machine, the generated
XS code will be compiled and installed. C<Inline::C> will not be used unless
the user removes the XS code before compilation.

Given this modified F<Makefile.PL>, you can issue the following usual commands
to create a release-ready package of your module:

  perl Makefile.PL
  make dist

C<InlineX::XS::MM> will take care of generating the XS and modifying your
F<MANIFEST>. Expect similar utility modules for C<Module::Build> and
C<Module::Install> in the future. (Help welcome, though.)

An example distribution C<Foo::Bar> can be found in the F<examples/>
subdirectory.

=head1 CAVEATS

C<InlineX::XS> isn't a drop-in replacement for C<Inline::C> in some cases.
For example, it doesn't support reading from arbitrary files or getting the
code from code references.

When passing the arguments through to C<Inline::C> because no loadable
object was found, some of the various advanced Inline::C features work alright.
Once extracted as XS and compiled, those won't be available any more.

The configuration options are only partially supported. Additionally,
there is one major discrepancy in behaviour:
Any configuration settings (i.e. C<use Inline C => 'Config'...>
or C<use Inline C => '...code...', cfg1=>'value1'...>) are applied
B<to all Inlined code in the package!> In ordinary C<Inline::C> code,
these are built up as the various inlined code sections are parsed and
compiled.

Multiple modules which use C<InlineX::XS> in the same distribution are
problematic. This isn't really an C<InlineX::XS> problem but rather a general
issue with distributions that contain XS. It's possible, but I haven't
explored it fully.

Naturally, if you use the C<bind> function from C<Inline> to load
C routines at run-time, C<InlineX::XS> can't interfere.

Do not think you can use C<InlineX::XS> like a random Inline language
module because it isn't one of those.

  # Cannot work and should not work:
  use Inline XS => 'code';

We can't declare our prerequisites in the C<Makefile.PL> because
they're not needed by users who use modules which have been
compiled to XS.

=head1 PREREQUISITES

Depending on the mode of operation, this module may required various
other modules. For end-users who use modules which make use of
C<InlineX::XS>, there are currently B<no> prerequisites at all.

Developers who use C<InlineX::XS> in conjunction with C<Inline::C>
need to install C<Inline::C>.

Those who generate distributions with XS code from the C<Inline::C>
(or rather C<InlineX::XS>) code need an installed C<InlineX::C2XS> and
thus an installed C<Inline::C>. B<In particular, version 0.08 or higher of
C<InlineX::C2XS> is required for packaging (only).>

=cut

our @INLINE_ARGS;
our $PACKAGE = 0;
our $PACKAGER;
our $DEBUG = 0;
our %SEEN_PKG; # used for determining packages without 'END' marker.

=head1 CLASS METHODS

=head2 debug

Get or set the debugging flag. Defaults to false.

=cut

sub debug {
    my $class = shift;
    $DEBUG = shift if @_;
    return $DEBUG;
}

=head2 import

Automatically called via C<use InlineX::XS>.

=cut

sub import {
    my $class = shift;
    my @args = @_;
    my ($pkg) = caller(0);
    $SEEN_PKG{$pkg} = {end => 0} if not exists $SEEN_PKG{$pkg};

    return if not @args;

    # special cases: PACKAGEing mode
    if (@args==1 and $args[0] eq 'PACKAGE') {
        warn "Entering PACKAGE-ing mode for package $pkg";
        $PACKAGE = 1;
        return 1;
    }
    # ... and END marker
    elsif (@args == 1 and $args[0] eq 'END') {
        warn 'Not generating XS because not in packaging mode.'
          if $class->debug;
        $SEEN_PKG{$pkg}{end} = 1; # have END for pkg using us.
        return 1 unless $PACKAGE; # no XS if not in packaging mode.
        warn 'C extraction complete';
        _generate();
        return 1;
    }
    # We're in packaging mode:
    elsif ($PACKAGE) {
        warn 'Saving arguments to Inline because we\'re in PACKAGE mode'
          if $class->debug;
        push @INLINE_ARGS, {pkg => $pkg, args => \@args};
    }
    else {
        warn 'Trying to load shared obj file' if $class->debug;

        require XSLoader;
        eval {
            XSLoader::load($pkg);
        };
        return 1 if not $@;
        warn "Failed to load shared obj file, resorting to inline. Reason for failure: $@"
          if $class->debug;
        eval "package $pkg; require Inline; Inline->import('C', \@args);";
        die "Error while resorting to using Inline::C: $@" if $@;
        return 1;
    }
}

sub _generate {
    warn "Starting XS generation";

    require File::Spec;
    require InlineX::C2XS;

    mkdir('src');
    my %pkg;
    foreach my $call (@INLINE_ARGS) {
        my $pkg = $call->{pkg};
        my $args = $call->{args};
        my $code;

        $pkg{$pkg} = {config=>{}, code => 0} if not exists $pkg{$pkg};

        # Assume code was passed in if not in Config mode
        if (@$args == 1 and $args->[0] ne 'Config') {
            $code = $args->[0];
        }
        # We're in config-only ->mode!
        elsif (@$args and $args->[0] eq 'Config') {
            die "Uneven number of arguments to 'InlineX::XS \"Config\"'."
              if (@$args-1)%2;
            
            # merge configuration for package
            my %cfg = @{$args}[1..$#$args];
            $pkg{$pkg}{config}{$_} = $cfg{$_} foreach keys %cfg;
        }
        # Code, then config
        else {
            $code = $args->[0];
            die "Uneven number of arguments to 'InlineX::XS \"...code...\", ....'"
              if (@$args-1)%2;
            
            # merge configuration for package
            my %cfg = @{$args}[1..$#$args];
            $pkg{$pkg}{config}{$_} = $cfg{$_} foreach keys %cfg;
        }

        if (defined $code) {
            my $file = $pkg;
            $file =~ s/^(?:[^:]*::)*([^:]+)$/$1/;
            $file .= '.c';
            open my $fh, '>>', File::Spec->catfile('src', $file) or die $!;
            print $fh "\n".$code;
            close $fh;

            $pkg{$pkg}{code} = 1;
        }
    }

    foreach my $pkg (keys %pkg) {
        next if not $pkg{$pkg}{code};

        InlineX::C2XS::c2xs($pkg, $pkg, '.', $pkg{$pkg}{config});
        $PACKAGER->hook_after_c2xs($pkg) if $PACKAGER;
    }
}


END {
    foreach my $pkg (keys %SEEN_PKG) {
        warn <<HERE if not $SEEN_PKG{$pkg}{end};
Package '$pkg' uses InlineX::XS but does not have a
  use InlineX::XS 'END';
statement at the end. This is required in order for
InlineX::XS to work correctly.
HERE
    }
}

1;

__END__

=head1 SEE ALSO

The obvious place to learn how to use C<Inline::C> (and thus
InlineX::XS) is L<Inline::C>.

This class implements the ExtUtils::MakeMaker packager:
L<InlineX::XS::MM>, see also: L<ExtUtils::MakeMaker>, 

The XS is generated from the C code using L<InlineX::C2XS>.

The shared objects that are compiled from the generated XS code
are loaded using L<XSLoader>.

The concept was originally proposed here:
L<http://perlmonks.org/index.pl?node_id=584125>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

