
package Devel::Hide;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.0009';

# blech! package variables
use vars qw( @HIDDEN $VERBOSE );

# a map ( $hidden_file => 1 ) to speed determining if a module/file is hidden
my %IS_HIDDEN;

# whether to hide modules from ...
my %HIDE_FROM = ( 
        children => 0, # child processes or not
);

=begin private

=item B<_to_filename>

    $fn = _to_filename($pm);

Turns a Perl module name (like 'A' or 'P::Q') into
a filename ("A.pm", "P/Q.pm").

=end private

=cut

sub _to_filename {
    my $pm = shift;
    $pm =~ s|::|/|g;
    $pm .= '.pm';
    return $pm;
}

=begin private

=item B<_as_filenames>

    @fn = _as_filenames(@args);
    @fn = _as_filenames(qw(A.pm X B/C.pm File::Spec)); # returns qw(A.pm X.pm B/C.pm File/Spec.pm)

Copies the argument list, turning what looks like
a Perl module name to filenames and leaving everything
else as it is. To look like a Perl module name is
to match C< /^(\w+::)*\w+$/ >.

=end private

=cut

sub _as_filenames {
    return map { /^(\w+::)*\w+$/ ? _to_filename($_) : $_ } @_;
}

BEGIN {

    unless ( defined $VERBOSE ) { # unless user-defined elsewhere, set default
        $VERBOSE
            = defined $ENV{DEVEL_HIDE_VERBOSE} ? $ENV{DEVEL_HIDE_VERBOSE} : 1;
    }

}

# Pushes a list to the set of hidden modules/filenames
# warns about the modules which could not be hidden
# and about the ones that were successfully hidden (if $VERBOSE)
#
# It works as a batch producing warning messages
# at each invocation (when appropriate).
#
sub _push_hidden {

    return unless @_;

    my @too_late;
    for ( _as_filenames(@_) ) {
        if ( $INC{$_} ) {
            push @too_late, $_;
        }
        else {
            $IS_HIDDEN{$_}++;
        }
    }
    if ( $VERBOSE && @too_late ) {
        warn __PACKAGE__, ': Too late to hide ', join( ', ', @too_late ), "\n";
    }
    if ( $VERBOSE && keys %IS_HIDDEN ) {
        warn __PACKAGE__, ' hides ', join( ', ', sort keys %IS_HIDDEN ), "\n";
    }
}

# $ENV{DEVEL_HIDE_PM} is split in ' '
# as well as @HIDDEN it accepts Module::Module as well as File/Names.pm

BEGIN {

    # unless @HIDDEN was user-defined elsewhere, set default
    if ( !@HIDDEN && $ENV{DEVEL_HIDE_PM} ) {
        _push_hidden( split q{ }, $ENV{DEVEL_HIDE_PM} );

        # NOTE. "split ' ', $s" is special. Read "perldoc -f split".
    }
    else {
        _push_hidden(@HIDDEN);
    }

    # NOTE. @HIDDEN is not changed anymore

}

# works for perl 5.8.0, uses in-core files
sub _scalar_as_io8 {
    open my $io, '<', \$_[0]
        or die $!;    # this should not happen (perl 5.8 should support this)
    return $io;
}

# works for perl >= 5.6.1, uses File::Temp
sub _scalar_as_io6 {
    my $scalar = shift;
    require File::Temp;
    my $io = File::Temp::tempfile();
    print {$io} $scalar;
    seek $io, 0, 0;    # rewind the handle
    return $io;
}

BEGIN {

    *_scalar_as_io = ( $] >= 5.008 ) ? \&_scalar_as_io8 : \&_scalar_as_io6;

    # _scalar_as_io is one of the two sub's above

}

sub _dont_load {
    my $filename = shift;
    my $oops;
    my $hidden_by = $VERBOSE ? 'hidden' : 'hidden by ' . __PACKAGE__;
    $oops = qq{die "Can't locate $filename ($hidden_by)\n"};
    return _scalar_as_io($oops);
}

sub _is_hidden {
    my $filename = shift;
    return $IS_HIDDEN{$filename};
}

sub _inc_hook {
    my ( $coderef, $filename ) = @_;
    if ( _is_hidden($filename) ) {
        return _dont_load($filename);    # stop right here, with error
    }
    else {
        return undef;                    # go on with the search
    }
}

use lib ( \&_inc_hook );

=begin private

=item B<_core_modules>

    @core = _core_modules($perl_version);

Returns the list of core modules according to
Module::CoreList.

!!! UNUSED BY NOW

It is aimed to expand the tag ':core' into all core
modules in the current version of Perl ($]).
Requires Module::CoreList.

=end private

=cut

sub _core_modules {
    require Module::CoreList;    # XXX require 2.05 or newer
    return Module::CoreList->find_modules( qr/.*/, shift );
}

# _append_to_perl5opt(@to_be_hidden)
sub _append_to_perl5opt {

    $ENV{PERL5OPT} = join( ' ',
        defined($ENV{PERL5OPT}) ? $ENV{PERL5OPT} : (),
        'MDevel::Hide=' . join(',', @_)
    );

}

sub import {
    shift;
    if( @_ && $_[0] eq '-from:children' ) {
        $HIDE_FROM{children} = 1;
        shift;
    }
    if (@_) {
        _push_hidden(@_);
        if ($HIDE_FROM{children}) {
            _append_to_perl5opt(@_);
        }
    }

}

# TO DO:
# * write unimport() sub
# * write decent docs
# * refactor private function names
# * RT #25528

=begin private

perl -MDevel::Hide=!:core -e script.pl # hide all non-core modules
perl -MDevel::Hide=M,!N -e script.pl  # hide all modules but N plus M

how to implement

%IS_HIDDEN
%IS_EXCEPTION       if there is an exception, all but the set of exceptions are to be hidden
                           plus the set of hidden modules

          :core(5.8) 
          :core      synonym to    :core($])


=end private

=cut

1;

__END__

=head1 NAME

Devel::Hide - Forces the unavailability of specified Perl modules (for testing)


=head1 SYNOPSIS

    use Devel::Hide qw(Module/ToHide.pm);
    require Module::ToHide; # fails 

    use Devel::Hide qw(Test::Pod Test::Pod::Coverage);
    require Test::More; # ok
    use Test::Pod 1.18; # fails

Other common usage patterns:

    $ perl -MDevel::Hide=Module::ToHide Makefile.PL

    bash$ PERL5OPT=MDevel::Hide
    bash$ DEVEL_HIDE_PM='Module::Which Test::Pod'
    bash$ export PERL5OPT DEVEL_HIDE_PM
    bash$ perl Makefile.PL

outputs (like blib)

    Devel::Hide hides Module::Which, Test::Pod, etc.


=head1 DESCRIPTION

Given a list of Perl modules/filenames, this module makes
C<require> and C<use> statements fail (no matter the
specified files/modules are installed or not).

They I<die> with a message like:

    Can't locate Module/ToHide.pm (hidden)

The original intent of this module is to allow Perl developers
to test for alternative behavior when some modules are not
available. In a Perl installation, where many modules are
already installed, there is a chance to screw things up
because you take for granted things that may not be there
in other machines. 

For example, to test if your distribution does the right thing
when a module is missing, you can do

    perl -MDevel::Hide=Test::Pod Makefile.PL

forcing C<Test::Pod> to not be found (whether it is installed
or not).

Another use case is to force a module which can choose between
two requisites to use the one which is not the default.
For example, C<XML::Simple> needs a parser module and may use
C<XML::Parser> or C<XML::SAX> (preferring the latter).
If you have both of them installed, it will always try C<XML::SAX>.
But you can say:

    perl -MDevel::Hide=XML::SAX script_which_uses_xml_simple.pl

NOTE. This module does not use L<Carp>. As said before,
denial I<dies>.

This module is pretty trivial. It uses a code reference
in @INC to get rid of specific modules during require -
denying they can be successfully loaded and stopping
the search before they have a chance to be found.

There are three alternative ways to include modules in
the hidden list: 

=over 4

=item * 

setting @Devel::Hide::HIDDEN

=item * 

environment variable DEVEL_HIDE_PM

=item * 

import()

=back

Optionally, you can propagate the list of hidden modules to your
process' child processes, by passing '-from:children' as the
first option when you use() this module. This works by populating
C<PERL5OPT>, and is incompatible with Taint mode, as
explained in L<perlrun>.


=head2 CAVEATS

There is some interaction between C<lib> and this module

    use Devel::Hide qw(Module/ToHide.pm);
    use lib qw(my_lib);

In this case, 'my_lib' enters the include path before
the Devel::Hide hook and if F<Module/ToHide.pm> is found
in 'my_lib', it succeeds.

Also for modules that were loaded before Devel::Hide,
C<require> and C<use> succeeds.

Since 0.0005, Devel::Hide warns about modules already loaded.

    $ perl -MDevel::Hide=Devel::Hide -e ''
    Devel::Hide: Too late to hide Devel/Hide.pm


=head2 EXPORTS

Nothing is exported.


=head1 ENVIRONMENT VARIABLES

DEVEL_HIDE_PM - if defined, the list of modules is added
   to the list of hidden modules

DEVEL_HIDE_VERBOSE - on by default. If off, supresses
   the initial message which shows the list of hidden modules
   in effect

PERL5OPT - used if you specify '-from:children'


=head1 SEE ALSO

L<perldoc -f require> 

L<Test::Without::Module>


=head1 BUGS

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Hide>.


=head1 AUTHORS

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

with contributions from David Cantrell E<lt>dcantrell@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

