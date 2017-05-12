package ExtUtils::ModuleMaker::Defaults;
use strict;
use vars qw( $VERSION );
$VERSION = 0.56;

my $usage = <<ENDOFUSAGE;

There were problems with your data supplied to ExtUtils::ModuleMaker.
Please fix the problems listed above and try again.

ENDOFUSAGE

my %default_values = (
        LICENSE          => 'perl',
        VERSION          => '0.01',
        ABSTRACT         => 'Module abstract (<= 44 characters) goes here',
        AUTHOR           => 'A. U. Thor',
        CPANID           => 'MODAUTHOR',
        ORGANIZATION     => 'XYZ Corp.',
        WEBSITE          => 'http://a.galaxy.far.far.away/modules',
        EMAIL            => 'a.u.thor@a.galaxy.far.far.away',
        BUILD_SYSTEM     => 'ExtUtils::MakeMaker',
        COMPACT          => 0,
        VERBOSE          => 0,
        INTERACTIVE      => 0,
        NEED_POD         => 1,
        NEED_NEW_METHOD  => 1,
        CHANGES_IN_POD   => 0,
        PERMISSIONS      => 0755,
        SAVE_AS_DEFAULTS => 0,
        USAGE_MESSAGE    => $usage,
        FIRST_TEST_NUMBER                   => 1,
        TEST_NUMBER_FORMAT                  => "%03d",
        TEST_NAME                           => 'load',
        EXTRA_MODULES_SINGLE_TEST_FILE      => 0,
        TEST_NAME_DERIVED_FROM_MODULE_NAME  => 0,
        TEST_NAME_SEPARATOR                 => q{_},
        INCLUDE_MANIFEST_SKIP               => 0,
        INCLUDE_TODO                        => 1,
        INCLUDE_POD_COVERAGE_TEST           => 0,
        INCLUDE_POD_TEST                    => 0,
        INCLUDE_LICENSE                     => 1,
        INCLUDE_SCRIPTS_DIRECTORY           => 1,
        INCLUDE_FILE_IN_PM                  => 0,
        INCLUDE_ID_LINE                     => 0,
        INCLUDE_WARNINGS                    => 0,
);

sub default_values {
    my $self = shift;
    return { %default_values };
}

1;

#################### DOCUMENTATION #################### 

=head1 NAME

ExtUtils::ModuleMaker::Defaults - Default values for ExtUtils::ModuleMaker objects

=head1 METHODS

=head3 C<default_values()>

  Usage     : $self->default_values() within new(); within
              ExtUtils::ModuleMaker::Interactive::_prepare_author_defaults() 
              and _prepare_directives_defaults(); 
              within t/testlib/Testing/Defaults.pm
  Purpose   : Set the default values for ExtUtils::ModuleMaker object elements
  Returns   : Reference to a hash of default values
  Argument  : n/a
  Comment   : Can be overridden by establishing a Personal::Defaults file.
  Comment   : See ExtUtils::ModuleMaker::PBP for an example of subclassing 
              this method.

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>.

=cut

