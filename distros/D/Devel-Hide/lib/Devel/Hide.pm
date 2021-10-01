package Devel::Hide;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.0015';

# blech! package variables
#
# @HIDDEN is one of the ways to populate the global hidden list
# $phase is used to identify which version of the hints hash to
#   use - either %^H when we're updating it, or pulling it out
#   of caller() when we want to read it
use vars qw( @HIDDEN $phase );
BEGIN { $phase = 'runtime'; }

# settings are a comma- (and only comma, no quotes or spaces)
# -separated list of key,value,key,value,... There is no
# attempt to support data containing commas.
#
# The list of hidden modules is a comma (and *only* comma,
# no white space, no quotes) separated list of module
# names.
# 
# yes, this is a ridiculous way of storing data. It is,
# however, compatible with what we're going to have to
# store in the hints hash for lexical hiding, as that
# only supports string data.
my %GLOBAL_SETTINGS;
_set_setting('global', children => 0);
_set_setting('global', verbose  =>
  defined $ENV{DEVEL_HIDE_VERBOSE}
    ? $ENV{DEVEL_HIDE_VERBOSE}
    : 1
);

# convert a mixed list of modules and filenames to a list of
# filenames
sub _as_filenames {
    return map { /^(\w+::)*\w+$/
        ? do { my $f = "$_.pm"; $f =~ s|::|/|g; $f }
        : $_
    } @_;
}

# Pushes a list to the set of hidden modules/filenames
# warns about the modules which could not be hidden (always)
# and about the ones that were successfully hidden (if verbose)
#
# It works as a batch producing warning messages
# at each invocation (when appropriate).
#
# the first arg is a reference to the config hash to use,
# either global or lexical
sub _push_hidden {
    my $config = shift;

    return unless @_;

    my @too_late;
    for ( _as_filenames(@_) ) {
        if ( $INC{$_} ) {
            push @too_late, $_;
        }
        else {
            $config->{'Devel::Hide/hidden'} =
              $config->{'Devel::Hide/hidden'}
                ? join(',', $config->{'Devel::Hide/hidden'}, $_)
                : $_;
        }
    }
    if ( @too_late ) {
        warn __PACKAGE__, ': Too late to hide ', join( ', ', @too_late ), "\n";
    }
    if ( _get_setting('verbose') && $config->{'Devel::Hide/hidden'}) {
        no warnings 'uninitialized';
        warn __PACKAGE__ . ' hides ' .
            join(
                ', ',
                sort split(
                    /,/, $config->{'Devel::Hide/hidden'}
                )
            ) . "\n";
    }
}

sub _dont_load {
    my $filename = shift;
    my $hidden_by = _get_setting('verbose')
        ? 'hidden'
        : 'hidden by ' . __PACKAGE__;
    die "Can't locate $filename in \@INC ($hidden_by)\n";
}

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
        '-MDevel::Hide=' . join(',', @_)
    );

}

sub _is_hidden {
    no warnings 'uninitialized';
    my $module = shift;

    +{
        map { $_ => 1 }
        map {
            split(',', _get_config_ref($_)->{'Devel::Hide/hidden'})
        } qw(global lexical)
    }->{$module};
}

sub _get_setting {
    my $name = shift;
    _exists_setting('lexical', $name)
        ? _get_setting_from('lexical', $name)
        : _get_setting_from('global',  $name)
}

sub _get_setting_from {
    my($source, $name) = @_;

    my $config = _get_config_ref($source);
    _setting_hashref($config)->{$name};
}

sub _exists_setting {
    my($source, $name) = @_;
    
    my $config = _get_config_ref($source);
    exists(_setting_hashref($config)->{$name});
}

sub _set_setting {
    my($source, $name, $value) = @_;

    my $config = _get_config_ref($source);
    my %hash = (
        %{_setting_hashref($config)},
        $name => $value
    );
    _get_config_ref($source)
      ->{'Devel::Hide/settings'} = join(',', %hash);
}

sub _setting_hashref {
    my $settings = shift->{'Devel::Hide/settings'};
    no warnings 'uninitialized';
    +{ split(/,/, $settings) };
}

sub _get_config_ref {
    my $type = shift;
    if($type eq 'lexical') {
        if($phase eq 'compile') {
            return \%^H;
        } else {
            my $depth = 1;
            while(my @fields = caller($depth)) {
                my $hints_hash = $fields[10];
                if($hints_hash && grep { /^Devel::Hide\// } keys %{$hints_hash}) {
                    # return a copy
                    return { %{$hints_hash} };
                }
                $depth++;
            }
            return {};
        }
    } else {
        return \%GLOBAL_SETTINGS;
    }
}

sub import {
    shift;
    my $which_config = 'global';
    local $phase = 'compile';
    while(@_ && $_[0] =~ /^-/) {
        if( $_[0] eq '-lexically' ) {
            $which_config = 'lexical';
            if($] < 5.010) {
                die("Can't 'use Devel::Hide qw(-lexically ...)' on perl 5.8 and below\n");
            }
        } elsif( $_[0] eq '-from:children' ) {
            _set_setting($which_config, children => 1);
        } elsif( $_[0] eq '-quiet' ) {
            _set_setting($which_config, verbose  => 0);
        } else {
            die("Devel::Hide: don't recognize $_[0]\n");
        }
        shift;
    }
    if (@_) {
        _push_hidden(
            _get_config_ref($which_config),
            @_
        );
        if (_get_setting('children')) {
            _append_to_perl5opt(
                (_get_setting('verbose') ? () : '-quiet'),
                @_
            );
        }
    }
}

# $ENV{DEVEL_HIDE_PM} is split in ' '
# as well as @HIDDEN it accepts Module::Module as well as File/Names.pm
BEGIN {
    # unless @HIDDEN was user-defined elsewhere, set default
    if ( !@HIDDEN && $ENV{DEVEL_HIDE_PM} ) {
        # NOTE. "split ' ', $s" is special. Read "perldoc -f split".
        _push_hidden(
            _get_config_ref('global'),
            split q{ }, $ENV{DEVEL_HIDE_PM}
        );
    }
    else {
        _push_hidden(
            _get_config_ref('global'),
            @HIDDEN
        );
    }
}

sub _inc_hook {
    my ( $coderef, $filename ) = @_;
    if ( _is_hidden($filename) ) { _dont_load($filename); }
     else { return undef; }
}

use lib ( \&_inc_hook );

# TO DO:
# * write unimport() sub
# * write decent docs
# * refactor private function names
# * RT #25528

=begin private

perl -MDevel::Hide=!:core -e script.pl # hide all non-core modules
perl -MDevel::Hide=M,!N -e script.pl  # hide all modules but N plus M

how to implement

%GLOBAL_SETTINGS
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

    # hide modules globally, across the entire process

    use Devel::Hide qw(Module/ToHide.pm);
    require Module::ToHide; # fails 

    use Devel::Hide qw(Test::Pod Test::Pod::Coverage);
    require Test::More; # ok
    use Test::Pod 1.18; # fails

    # hide modules lexically
    {
        use Devel::Hide qw(-lexically Foo::Bar);
        # this will fail to load
        eval 'use Foo::Bar';
    }
    # but this will load
    use Foo::Bar;

Other common usage patterns:

    $ perl -MDevel::Hide=Module::ToHide Makefile.PL
    $ perl -MDevel::Hide=Module::ToHide,Test::Pod Makefile.PL

    $ PERL5OPT=-MDevel::Hide
    $ DEVEL_HIDE_PM='Module::ToHide Test::Pod'
    $ export PERL5OPT DEVEL_HIDE_PM
    $ perl Makefile.PL

=head1 COMPATIBILITY

=over

=item global hiding

At some point global hiding may B<go away> and only lexical
hiding be supported. At that point support for perl versions
below 5.10 will be dropped. There will be at least a two year
deprecation cycle before that happens.

You are strongly encouraged to only use lexical hiding and to
update existing code.

=item perl 5.6

Support will be dropped at some point after 2022-01-01 with no
further warning. This is because bugs in older perls prevent
some code improvements. See commit dd27e50 in the repository
if you care to know what those are.

=back

=head1 DESCRIPTION

Given a list of Perl modules/filenames, this module makes
C<require> and C<use> statements fail (no matter the
specified files/modules are installed or not).

They I<die> with a message like:

    Can't locate Module/ToHide.pm in @INC (hidden)

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

=item import()

this is probably the most commonly used method, called automagically
when you do this:

    use Devel::Hide qw(Foo Bar::Baz);

or

    perl -MDevel::Hide=...

=item setting @Devel::Hide::HIDDEN

=item environment variable DEVEL_HIDE_PM

both of these two only support 'global' hiding, whereas C<import()>
supports lexical hiding as well.

=back

Optionally, you can provide some arguments *before* the
list of modules:

=over

=item -from:children

propagate the list of hidden modules to your
process' child processes. This works by populating
C<PERL5OPT>, and is incompatible with Taint mode, as
explained in L<perlrun>. Of course, this is unnecessary
if your child processes are just forks of the current one.

=item -lexically

This is only available on perl 5.10.0 and later. It is a fatal
error to try to use it on an older perl.

Everything following this will only have effect until the
end of the current scope. Yes, that includes C<-quiet>.

=begin private

PERL5OPT is populated globally even when -lexically is in use.
How can its value be lexicalised? Or how can all the various ways
of spawning a child be lexicalised?

=end private

=item -quiet

suppresses diagnostic output. You will still get told about
errors. This is passed to child processes if -from:children
is in effect.

=back

=head1 CAVEATS

There is some interaction between C<lib> and this module

    use Devel::Hide qw(Module/ToHide.pm);
    use lib qw(my_lib);

In this case, 'my_lib' enters the include path before
the Devel::Hide hook and if F<Module/ToHide.pm> is found
in 'my_lib', it succeeds. More generally, any code that
adds anything to the front of the C<@INC> list after
Devel::Hide is loaded will have this effect.

Also for modules that were loaded before Devel::Hide,
C<require> and C<use> succeeds.

Since 0.0005, Devel::Hide warns about modules already loaded.

    $ perl -MDevel::Hide=Devel::Hide -e ''
    Devel::Hide: Too late to hide Devel/Hide.pm

=head1 EXPORTS

Nothing is exported.

=head1 ENVIRONMENT VARIABLES

DEVEL_HIDE_PM - if defined, the list of modules is added
   to the list of hidden modules

DEVEL_HIDE_VERBOSE - on by default. If off, suppresses
   the initial message which shows the list of hidden modules
   in effect

PERL5OPT - used if you specify '-from:children'

=head1 SEE ALSO

L<perldoc -f require> 

L<Test::Without::Module>

=head1 BUGS

=over

=item bug

C<-from:children> and C<-lexically> don't like each other.  Anything
hidden lexically may be hidden from all child processes without
regard for scope. Don't use them together.

=back

Please report any other bugs you find via CPAN RT
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Hide>.

=head1 AUTHORS

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

with contributions from David Cantrell E<lt>dcantrell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007, 2018 by Adriano R. Ferreira

Some parts copyright (C) 2020 by David Cantrell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

