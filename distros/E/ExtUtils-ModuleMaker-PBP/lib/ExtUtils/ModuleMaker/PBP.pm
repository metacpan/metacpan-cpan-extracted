package ExtUtils::ModuleMaker::PBP;
use strict;
use warnings;
our ( $VERSION );
$VERSION = '0.09';
use base qw( ExtUtils::ModuleMaker );

=head1 NAME

ExtUtils::ModuleMaker::PBP - Create a Perl extension in the style of Damian Conway's Perl Best Practices

=head1 SYNOPSIS

    use ExtUtils::ModuleMaker::PBP;

    $mod = ExtUtils::ModuleMaker::PBP->new(
        NAME => 'Sample::Module'
    );

    $mod->complete_build();

    $mod->dump_keys(qw|
        ...  # key provided as argument to constructor
        ...  # same
    |);

    $mod->dump_keys_except(qw|
        ...  # key provided as argument to constructor
        ...  # same
    |);

    $license = $mod->get_license();

    $mod->make_selections_defaults();

=head1 VERSION

This document references version 0.09 of ExtUtils::ModuleMaker::PBP, released
to CPAN on April 5, 2006.

=head1 DESCRIPTION

ExtUtils::ModuleMaker::PBP subclasses Perl extension ExtUtils::ModuleMaker.
If you are not already familiar with ExtUtils::ModuleMaker, you should read
its documentation I<now>.  The documentation provided below is intended
primarily for future maintainers and extenders of ExtUtils::ModuleMaker::PBP.

The default value settings and methods described below supersede the
similarly named methods in ExtUtils::ModuleMaker.  When used as described
herein, they will create a CPAN-ready Perl distribution the content of
whose files reflects programming practices recommended by Damian Conway in
his book I<Perl Best Practices> (O'Reilly, 2005)
L<http://www.oreilly.com/catalog/perlbp/>.

=head1 USAGE

The easiest way to get started with ExtUtils::ModuleMaker::PBP is to use the
F<mmkrpbp> utility included in this distribution.  F<mmkrpbp> is basically a
clone of the F<modulemaker> utility included with F<ExtUtils::ModuleMaker>.
To get started with F<mmkrpbp>, simply go to the command-prompt and enter:

    %    mmkrpbp

Then, answer the questions at each prompt.  In many cases, you will simply
have to type a single letter or number to make your selections.  Please see
the documentation for F<mmkrpbp> and F<modulemaker>.

=head1 DEFAULT VALUES

The following default values for ExtUtils::ModuleMaker::PBP differ from
those set in F<ExtUtils/ModuleMaker/Defaults.pm>.

=over 4

=item *

Default to compact top directory.  E.g., F<Alpha-Beta-Gamma> instead of
F<Alpha/Beta/Gamma>.

    $self->{COMPACT} = 1;

=item *

Default to placing C<use_ok> tests for multiple modules in a single F<t/*.t>
file rather than one F<t*.t> file for each module.

    $self->{EXTRA_MODULES_SINGLE_TEST_FILE} = 1;

=item *

Count of F<t/*.t> files begins at 0 rather than 1.

    $self->{FIRST_TEST_NUMBER}  = 0;

=item *

In name of test file, test number is formatted as 2-digit rather than 3-digit.

    $self->{TEST_NUMBER_FORMAT} = "%02d";

=item *

In name of test file, use a dot (C<.>) rather than an underscore (C<_>) to
separate the numerical and lexical parts of the name.

    $defaults_ref->{TEST_NAME_SEPARATOR}            = q{.};

=item *

Do not include a Todo file in the top level of the distribution.

    $defaults_ref->{INCLUDE_TODO}                   = 0;

=item *

Include F<t/pod_coverage.t> in the distribution.

    $defaults_ref->{INCLUDE_POD_COVERAGE_TEST}      = 1;

=item *

Include F<t/pod.t> in the distribution.

    $defaults_ref->{INCLUDE_POD_TEST}               = 1;

=item *

Do not include directory F<scripts/> in the distribution.

    $defaults_ref->{INCLUDE_SCRIPTS_DIRECTORY}      = 0;

=back

=cut

sub default_values {
    my $self = shift;
    my $defaults_ref = $self->SUPER::default_values();
    $defaults_ref->{COMPACT}                        = 1;
    $defaults_ref->{FIRST_TEST_NUMBER}              = 0;
    $defaults_ref->{TEST_NUMBER_FORMAT}             = "%02d";
    $defaults_ref->{EXTRA_MODULES_SINGLE_TEST_FILE} = 1;
    $defaults_ref->{TEST_NAME_SEPARATOR}            = q{.};
    $defaults_ref->{INCLUDE_TODO}                   = 0;
    $defaults_ref->{INCLUDE_POD_COVERAGE_TEST}      = 1;
    $defaults_ref->{INCLUDE_POD_TEST}               = 1;
    $defaults_ref->{INCLUDE_SCRIPTS_DIRECTORY}      = 0;
    return $defaults_ref;;
}

=head1 METHODS

=head2 Methods Called within C<complete_build()>

=head3 C<text_Buildfile()>

  Usage     : $self->text_Buildfile() within complete_build()
  Purpose   : Composes text for a Buildfile for Module::Build
  Returns   : String holding text for Buildfile
  Argument  : n/a
  Throws    : n/a
  Comment   : References EU::MM object attributes
              NAME, LICENSE, AUTHOR, EMAIL and FILE

=cut

sub text_Buildfile {
    my $self = shift;

    my $add_to_cleanup    = $self->{NAME} . q{-*};
    my $text_of_Buildfile = <<END_OF_BUILDFILE;
use strict;
use warnings;
use Module::Build;

my \$builder = Module::Build->new(
    module_name         => '$self->{NAME}',
    license             => '$self->{LICENSE}',
    dist_author         => '$self->{AUTHOR} <$self->{EMAIL}>',
    dist_version_from   => '$self->{FILE}',
    requires            => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add-to-cleanup      => [ '$add_to_cleanup' ],
    );

\$builder->create_build_script();
END_OF_BUILDFILE
    return $text_of_Buildfile;
}

=head3 C<text_Changes()>

  Usage     : $self->text_Changes($only_in_pod) within complete_build;
              block_pod()
  Purpose   : Composes text for Changes file
  Returns   : String holding text for Changes file
  Argument  : $only_in_pod:  True value to get only a HISTORY section for POD
                             False value to get whole Changes file
  Throws    : n/a
  Comment   : Accesses EU::MM object attributes
              NAME, VERSION, timestamp, eumm_version

=cut

sub text_Changes {
    my ( $self, $only_in_pod ) = @_;
    my $text_of_Changes;

    my $text_of_Changes_core = <<END_OF_CHANGES;
$self->{VERSION} $self->{timestamp}
    - Initial release.  Created by ExtUtils::ModuleMaker $self->{eumm_version}.

END_OF_CHANGES

    unless ($only_in_pod) {
        $text_of_Changes = <<EOF;
Revision history for $self->{NAME}

$text_of_Changes_core
EOF
    }
    else {
        $text_of_Changes = $text_of_Changes_core;
    }

    return $text_of_Changes;
}

=head3 C<text_Makefile()>

  Usage     : $self->text_Makefile() within complete_build()
  Purpose   : Build Makefile
  Returns   : String holding text of Makefile
  Argument  : n/a
  Throws    : n/a
  Comment   : References EU::MM object attributes
              NAME, AUTHOR, EMAIL and FILE

=cut

sub text_Makefile {
    my $self = shift;
    my $Makefile_format = q~
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => '%s',
    AUTHOR          => '%s <%s>',
    VERSION_FROM    => '%s',
    ABSTRACT_FROM   => '%s',
    PL_FILES        => {},
    PREREQ_PM    => {
        'Test::More'    => 0,
        'version'       => 0,
    },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => '%s-*' },
);
~;
    my $text_of_Makefile = sprintf $Makefile_format,
        map { my $s = $_; $s =~ s{'}{\\'}g; $s; }
            $self->{NAME},
            $self->{AUTHOR},
            $self->{EMAIL},
            $self->{FILE},
            $self->{FILE},
            $self->{FILE};
    return $text_of_Makefile;
}

=head3 C<text_README()>

  Usage     : $self->text_README() within complete_build()
  Purpose   : Build README
  Returns   : String holding text of README
  Argument  : n/a
  Throws    : n/a
  Comment   : References EU::MM object attributes
              NAME, VERSION, COPYRIGHT_YEAR and AUTHOR

=cut

sub text_README {
    my $self = shift;

    my $README_top = <<"END_OF_TOP";
$self->{NAME} version $self->{VERSION}

[ REPLACE THIS...

  The README is used to introduce the module and provide instructions on
  how to install the module, any machine dependencies it may have (for
  example C compilers and installed libraries) and any other information
  that should be understood before the module is installed.

  A README file is required for CPAN modules since CPAN extracts the
  README file from a module distribution so that people browsing the
  archive can use it get an idea of the modules uses. It is usually a
  good idea to provide version information here so that people can
  decide whether fixes for the module are worth downloading.
]


INSTALLATION

To install this module, run the following commands:

END_OF_TOP

    my $makemaker_instructions = <<'END_OF_MAKE';
    perl Makefile.PL
    make
    make test
    make install
END_OF_MAKE

    my $mb_instructions = <<'END_OF_BUILD';
    perl Build.PL
    ./Build
    ./Build test
    ./Build install
END_OF_BUILD

    my $README_middle = <<'END_OF_MIDDLE';

Alternatively, to install with Module::Build, you can use the
following commands:

END_OF_MIDDLE

    my $README_bottom = <<"END_OF_README";


DEPENDENCIES

None.


COPYRIGHT AND LICENSE

Copyright (C) $self->{COPYRIGHT_YEAR}, $self->{AUTHOR}

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
END_OF_README

    return  $README_top .
            $makemaker_instructions .
            $README_middle .
            $mb_instructions .
            $README_bottom;
}

=head3 C<text_pm_file()>

  Usage     : $self->text_pm_file($module) within generate_pm_file()
  Purpose   : Composes a string holding all elements for a pm file
  Returns   : String holding text for a *.pm file
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Comment   : References EU::MM object attributes
              NAME, AUTHOR, EMAIL and COPYRIGHT_YEAR

=cut

sub text_pm_file {
    my $self = shift;
    my $module = shift;

    my $rt_name = $self->{NAME};
    $rt_name =~ s{::}{-}g;

    my $text_of_pm_file = <<"END_OF_PM_FILE";
package $self->{NAME};

use version; \$VERSION = qv('$self->{VERSION}');

use warnings;
use strict;
use Carp;

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
#  use Regexp::Autoflags;


# Module implementation here


1; # Magic true value required at end of module

 ====head1 NAME

$self->{NAME} - [One line description of module's purpose here]


 ====head1 VERSION

This document describes $self->{NAME} version 0.0.1


 ====head1 SYNOPSIS

    use $self->{NAME};

 ====for author_to_fill_in
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.

 ====head1 DESCRIPTION

 ====for author_to_fill_in
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


 ====head1 INTERFACE

 ====for author_to_fill_in
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


 ====head1 DIAGNOSTICS

 ====for author_to_fill_in
    List every single error and warning message that the module can
    generate (even the ones that will ''never happen''), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

 ====over

 ====item C<< Error message here, perhaps with \%s placeholders >>

[Description of error here]

 ====item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

 ====back


 ====head1 CONFIGURATION AND ENVIRONMENT

 ====for author_to_fill_in
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

$self->{NAME} requires no configuration files or environment variables.


 ====head1 DEPENDENCIES

 ====for author_to_fill_in
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


 ====head1 INCOMPATIBILITIES

 ====for author_to_fill_in
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


 ====head1 BUGS AND LIMITATIONS

 ====for author_to_fill_in
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-$rt_name\@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


 ====head1 AUTHOR

$self->{AUTHOR}  C<< $self->{EMAIL} >>


 ====head1 LICENSE AND COPYRIGHT

Copyright (c) $self->{COPYRIGHT_YEAR}, $self->{AUTHOR} C<< $self->{EMAIL} >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.


 ====head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
END_OF_PM_FILE

    $text_of_pm_file =~ s/\n ====/\n=/g;
    return ($module, $text_of_pm_file);
}

=head1 PREREQUISITES

ExtUtils::ModuleMaker, version 0.40 or later.
L<http://search.cpan.org/dist/ExtUtils-ModuleMaker/>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ExtUtils-ModuleMaker-PBP@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James E Keenan:  jkeenan [at] cpan [dot] org

=head1 LICENSE AND COPYRIGHT

Standard text of files created by ExtUtils::ModuleMaker::PBP copyright (c)
2005 Damian Conway.  Adapted from Module::Starter::PBP and used by permission.
Code building these files copyright (c) 2005 James E Keenan.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>, F<modulemaker>, F<mmkrpbp>.

=cut

1;
# The preceding line will help the module return a true value
