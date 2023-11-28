package Locale::MaybeMaketext;

use v5.20.0;    # minimum of v5.20.0 due to use of signatures.
use strict;
use warnings;
use vars;
use utf8;

use autodie      qw/:all/;
use feature      qw/signatures/;
use Carp         qw/croak/;
use Scalar::Util qw/blessed/;

use constant {
    _MAYBE_MAKETEXT_ALREADY_LOADED => 1,     # Localizer is already loaded.
    _MAYBE_MAKETEXT_LOADABLE       => -1,    # Lcalizer is not currently loaded, but could be loaded.
    _MAYBE_MAKETEXT_NOT_LOADABLE   => 0,     # Localizer is not able to be loaded.
};

# indirect references (such as new Class instead of Class->new)
# are discouraged. can only be disabled on v5.32.0 onwards and is disabled by default on v5.36.0+.
# https://metacpan.org/dist/perl/view/pod/perlobj.pod#Indirect-Object-Syntax
# need to use the old decimal version + (patch level / 1000) version strings here
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

# ISA is needed to allow us to pick our parent
our @ISA = ();    ## no critic (ClassHierarchies::ProhibitExplicitISA)

our $VERSION = '1.233180';    # VERSION: inserted by Dist::Zilla::Plugin::OurPkgVersion

# Encoding is needed for consistency with Maketext libraries
our $Encoding = 'utf-8';    ## no critic (NamingConventions::Capitalization,Variables::ProhibitPackageVars)

# Which localizer package are we currently using?
my $maybe_maketext_has_localizer = undef;

# What is the reasoning behind selecting that localizer?
my ( @maybe_maketext_default_localizers, @maybe_maketext_reasoning );

# our default localizers;
@maybe_maketext_reasoning = @maybe_maketext_default_localizers = (
    'Cpanel::CPAN::Locale::Maketext::Utils',
    'Locale::Maketext::Utils',
    'Locale::Maketext',
);

# List of our known localizers to iterate through.
my @maybe_maketext_known_localizers = @maybe_maketext_default_localizers;

## Private functions

# Checks to see if a package is already loaded or is loadable.
my $maybe_maketext_check_package_loaded = sub ($package_name) {
    my $path = ( $package_name =~ tr{:}{\/}rs ) . '.pm';
    if ( exists( $INC{$path} ) ) {
        if ( defined( $INC{$path} ) ) {
            push @maybe_maketext_reasoning, sprintf(
                '%s: Already %s', $package_name,
                ref( $INC{$path} )
                ? 'loaded by hook'
                : sprintf( 'loaded by filesystem from "%s"', $INC{$path} )
            );
            return _MAYBE_MAKETEXT_ALREADY_LOADED;
        }

        # if the INC entry exists but is 'undef', that means Perl was unable
        # to previously load the package for some unknown reason.
        push @maybe_maketext_reasoning, sprintf(
            '%s: Unable to set as parent localizer due to previous erroring on load',
            $package_name,
        );
        return _MAYBE_MAKETEXT_NOT_LOADABLE;
    }
    push @maybe_maketext_reasoning, sprintf(
        '%s: No record of load attempt found',
        $package_name,
    );
    return _MAYBE_MAKETEXT_LOADABLE;

};

# Try and load a specific localization library.
# Will attempt to try to load if if already loaded - use maybe_maketext_check_package_loaded to check!
# Returns 1 if correctly loaded, 0 if not loaded (for whatever reason)
my $maybe_maketext_try_load = sub ($package_name) {
    my $path   = ( $package_name =~ tr{:}{\/}rs ) . '.pm';
    my $loaded = 0;
    if (
        !eval {

            # Convert any warnings encountered during loading
            # into "dies" to catch "Subroutine redefined at..." and similar messages.
            local $SIG{__WARN__} = sub { die $_[0] };    ## no critic (ErrorHandling::RequireCarping)
                                                         # try the load.
            require $path;
            if ( defined( $INC{$path} ) ) {

                # ensure it has loaded - and if so, record what loaded.
                push @maybe_maketext_reasoning, sprintf(
                    '%s: Loaded correctly from %s',
                    $package_name,
                    ref( $INC{$path} )
                    ? 'loaded by hook'
                    : sprintf( 'loaded by filesystem from "%s"', $INC{$path} )
                );
                $loaded = 1;
            }
            else {
                push @maybe_maketext_reasoning, sprintf(
                    '%s: Failed to correctly load from %s',
                    $package_name,
                    $path
                );
            }
            1;
        }
    ) {
        # reached if any part of the previous code block errors (such as a loading issue).
        push @maybe_maketext_reasoning, sprintf(
            '%s: Unable to set as parent localizer due to "%s" when loading from %s',
            $package_name,
            $@ =~ tr{\n}{ }rs,
            $path
        );
    }
    return $loaded;
};

# Check we are passed in an appropriate class object when needed.
my $maybe_maketext_check_passed_class = sub ( $class, $method ) {
    if ( !defined($class) ) {
        croak( sprintf( '%s should not be called without a class', $method ) );
    }
    my $is_blessed = blessed($class);
    if ( defined($is_blessed) ) {

        # we have an object, let's store its name as a scalar.
        $class = $is_blessed;
    }
    elsif ( ref($class) ne q{} ) {

        # it is a reference to something else.
        croak(
            sprintf( '%s should only be called with class objects: provided a reference of %s', $method, ref($class) )
        );
    }

    # check to see if it is ourselves being called.
    if ( $class eq __PACKAGE__ ) {
        croak( sprintf( '%s should be called on the translation file\'s parent class', $method ) );
    }

    # we should have a scalar now.
    if ( !$class->can($method) ) {
        croak( sprintf( '%s was provided as a class to %s but it does not support %s', $class, $method, $method ) );
    }
    return 1;
};

## Public functions

# Gets the list of known localizers.
sub maybe_maketext_get_localizer_list() {
    return @maybe_maketext_known_localizers;
}

# Sets the list of known localizers.
sub maybe_maketext_set_localizer_list (@localizers) {
    @maybe_maketext_known_localizers = @localizers;
    return 1;
}

# Gets the current localizer if set - if not, tries to load an appropriate one
# using the private 'maybe_maketext_try_load' method.
sub maybe_maketext_get_localizer() {
    if ($maybe_maketext_has_localizer) {

        # already exists
        return $maybe_maketext_has_localizer;
    }
    my @to_attempt = ();
    for my $package_name (@maybe_maketext_known_localizers) {
        my $is_loaded = $maybe_maketext_check_package_loaded->($package_name);
        if ( $is_loaded == _MAYBE_MAKETEXT_ALREADY_LOADED ) {
            $maybe_maketext_has_localizer = $package_name;
            last;
        }
        elsif ( $is_loaded == _MAYBE_MAKETEXT_LOADABLE ) {
            push @to_attempt, $package_name;
        }
    }
    if ( !$maybe_maketext_has_localizer ) {
        push @maybe_maketext_reasoning, 'Attempting to load';
        for my $package_name (@to_attempt) {
            if ( $maybe_maketext_try_load->($package_name) ) {
                $maybe_maketext_has_localizer = $package_name;
                last;
            }
        }
    }
    if ( !$maybe_maketext_has_localizer ) {
        croak( "Unable to load localizers: \n - " . join( "\n - ", @maybe_maketext_reasoning ) );
    }

    # Needed to allow us to pick our parent
    push @ISA, $maybe_maketext_has_localizer;    ## no critic (ClassHierarchies::ProhibitExplicitISA)
    return $maybe_maketext_has_localizer;
}

# Reset which localizer we are currently using.
sub maybe_maketext_reset () {

    # remove parent/inheritance.
    if ($maybe_maketext_has_localizer) {
        ## no critic (ClassHierarchies::ProhibitExplicitISA)
        # If we inherited from other classes, it would be advisable to
        # only remove the localizer - using this grep command:
        #@ISA = grep { !/$maybe_maketext_has_localizer/ } @ISA;
        # but since we don't, we can just reset the inheritence.
        @ISA                          = ();
        $maybe_maketext_has_localizer = undef;
    }
    @maybe_maketext_known_localizers = @maybe_maketext_default_localizers;
    @maybe_maketext_reasoning        = ();
    return 1;
}

# Get the reasoning for the current localizer.
sub maybe_maketext_get_reasoning() {
    return @maybe_maketext_reasoning;
}

# Get the localizer translation handle (after ensuring we have an appropriate
# localizer of course).
sub get_handle ( $class, @languages ) {
    maybe_maketext_get_localizer();    # don't actually care about which localizer we get
    $maybe_maketext_check_passed_class->( $class, 'get_handle' );

    my $return = $class->SUPER::get_handle(@languages);
    return $return;
}

# Dummy method to ensure a localizer is set through get_handle first.
sub maketext ( $class, $string, @params ) {
    if ( !$maybe_maketext_has_localizer ) {
        croak('maketext called without get_handle');
    }
    if ( !ref($class) ) {
        croak('maketext must be called as a method');
    }
    $maybe_maketext_check_passed_class->( $class, 'maketext' );
    if ( !defined($string) ) {
        croak('maketext must be passed a scalar string to translate - it was passed an undefined item');
    }
    if ( ref($string) ne q{} ) {
        croak(
            sprintf(
                'maketext must be passed a scalar string to translate - it was passed a %s reference', ref($string)
            )
        );
    }

    return $class->SUPER::maketext( $string, @params );
}

1;

__END__

=encoding utf8

=head1 NAME

Locale::MaybeMaketext - Find available localization / localisation / translation services.

=head1 VERSION

version 1.233180

=head1 DESCRIPTION

There are, to my knowledge, three slightly different Maketext libraries available on Perl
all of which require your "translation files" to reference that individual library as a
parent/base package: which causes problems if you want to support all three. This package
addresses this issue by allowing you to just reference this package and then it will automatically
figure out which Maketext library is available on the end-users platform.

It will try each localizer in the order:

* L<Cpanel::CPAN::Locale::Maketext::Utils>

* L<Locale::Maketext::Utils>

* L<Locale::Maketext>

=head1 SYNOPSIS

How to use:

1. Create a base/parent localization class which uses C<Locale::MaybeMaketext> as the parent:

    # File YourProjClass/L10N.pm
    package YourProjClass::L10N;
    use parent qw/Locale::MaybeMaketext/;
    # any additional methods to share on all languages
    1;

2. Create the individual translation files using your base/parent class as the parent:

    # File YourProjClass/L10N/en.pm
    package YourProjClass::L10N::EN;
    use parent qw/YourProjClass::L10N/;
    %Lexicon = (
       '_AUTO'=>1,
    );
    1;

3. In your main program use:

    # File YourProjClass/Main.pl
    use parent qw/YourProjClass::L10N/;
       ...
    my $lh=YourProjClass::L10N->get_handle() || die('Unable to find language');
    print $lh->maketext("Hello [_1] thing\n",$thing);

=head1 METHODS

The main method you need to concern yourself about is the C<get_handle> method
which gets an appropriate localizer, sets it as the "parent" of the package
and then returns an appropriate C<maketext> handle.

=over

=item $lh = YourProjClass->get_handle(...langtags...) || die 'language handle?';

This ensures an appropriate localizer/Maketext library is set as the parent
and then tries loading classes based on the language-tags (langtags) you provide -
and for the first class that succeeds, returns YourProjClass::I<language>->new().

=item $lh = YourProjClass->get_handle() || die 'language handle?';

This ensures an appropriate localizer/Maketext library is set as the parent
and then asks that library to "magically" detect the most appropriate language
for the user based on its own logic.

=item $localizer = Locale::MaybeMaketext::maybe_maketext_get_localizer();

Returns the package name of the currently selected localizer/Maketext library -
or, if one is not set, will try and pick one from the list in
C<@maybe_maketext_known_localizers> and return that. If it is unable to find
a localizer (for example, if the user has none of the listed packages installed),
then the C<croak> error message "Unable to load localizers: "... will be emitted
along with why/how it was unable to load each localizer.

=item Locale::MaybeMaketext::maybe_maketext_reset();

Removes the currently set localizer from the package. Intended for testing purposes.

=item $text = $lh->maketext(I<key>, ... parameters for this phrase ... );

This is actually just a dummy function to ensure that C<get_handle> is called
before any attempt is made to translate text.

=item @list = Locale::MaybeMaketext::maybe_maketext_get_localizer_list();

Get the list of currently configured localizers. Intended for testing purposes.

=item Locale::MaybeMaketext::maybe_maketext_set_localizer_list(@<list of localizers>);

Sets the list of currently configured localizers. Intended for testing purposes.

=item @reason = Locale::MaybeMaketext::maybe_maketext_get_reasoning()

Returns the reasoning "why" a particular localizer was choise. Intended for debugging purposes.

=back

=head2 Utility Methods

Various C<Maketext> libraries support different 'utility modules' which help
expand the bracket notation used in Maketext. Of course, you do not necessarily
know which localization library will be used so it is advisable to keep to the
most commonly supported utility methods.

Here is a little list of which utility modules are available under which library:

* LM = Locale::Maketext

* LMU = Locale::Maketext::Utils

* CCLMU = Cpanel::CPAN::Locale::Maketext::Utils

 |-------------------------------------------|
 | Method            |  LM   |  LMU  | CCLMU |
 |-------------------|-------|-------|-------|
 | quant             |   Y   |   Y   |   Y   |
 | numf              |   Y   |   Y   |   Y   |
 | numerate          |   Y   |   Y   |   Y   |
 | sprintf           |   Y   |   Y   |   Y   |
 | language_tag      |   Y   |   Y   |   Y   |
 | encoding          |   Y   |   Y   |   Y   |
 | join              |   N   |   Y   |   Y   |
 | list_and          |   N   |   Y   |   Y   |
 | list_or           |   N   |   Y   |   Y   |
 | list_and_quoted   |   N   |   Y   |   Y   |
 | list_or_quoted    |   N   |   Y   |   Y   |
 | datetime          |   N   |   Y   |   Y   |
 | current_year      |   N   |   Y   |   Y   |
 | format_bytes      |   N   |   Y   |   Y   |
 | convert           |   N   |   Y   |   Y   |
 | boolean           |   N   |   Y   |   Y   |
 | is_defined        |   N   |   Y   |   Y   |
 | is_future         |   N   |   Y   |   Y   |
 | comment           |   N   |   Y   |   Y   |
 | asis              |   N   |   Y   |   Y   |
 | output            |   N   |   Y   |   Y   |
 |-------------------------------------------|

=head1 AUTHORS

=over 4

=item Richard Bairwell E<lt>rbairwell@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2023 Richard Bairwell E<lt>rbairwell@cpan.orgE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. The full text
of this license can be found in the F<LICENSE> file
included with this module.

See F<http://dev.perl.org/licenses/>

=cut
