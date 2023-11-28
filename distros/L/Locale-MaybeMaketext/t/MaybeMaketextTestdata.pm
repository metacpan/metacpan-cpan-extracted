package MaybeMaketextTestdata;
use v5.20.0;
use strict;
use warnings;
use vars;
use utf8;
use parent       qw/Exporter/;
use Carp         qw/carp croak/;
use feature      qw/signatures/;
use Data::Dumper qw/Dumper/;

# test hooks
use Test2::V0               qw/ok pass fail diag note skip plan done_testing todo/;
use Test2::Tools::Exception qw/dies lives/;
use Test2::Plugin::BailOnFail;
use Test2::Plugin::ExitSummary;
use Test2::Tools::Compare qw/is like/;
use Test2::Formatter::TAP;

# paths
use File::Basename();
use File::Spec();
use lib File::Spec->catdir(
    File::Basename::dirname( File::Spec->rel2abs(__FILE__) ),
    File::Spec->updir(),
    qw/lib/
);    # set path to our modules
use lib File::Spec->catdir(
    File::Basename::dirname( File::Spec->rel2abs(__FILE__) ),
    q/lib/
);    # set path to test modules

# our files
use Test2::Tools::Target 'Locale::MaybeMaketext';
use Locale::MaybeMaketext();
use Locale::MaybeMaketext::Tests::Simple();
use Locale::MaybeMaketext::Tests::NoMethods();

no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

# What do we want to export?
our %EXPORT_TAGS = (
    basics              => [qw/ok pass fail diag note skip plan done_testing todo/],
    compare             => [qw/is like/],
    exceptions_warnings => [qw/dies lives/],
    third_party_utils   => [qw/carp croak Dumper/],
    our_utils           => [
        qw/unload_mocks test_data_iterator isa_check isa_diagnose base_inc get_test_data_by_index fault_inc get_live_test_data/
    ],
);

# Export all the tags and the contents therein automatically.
our @EXPORT;    ## no critic (Modules::ProhibitAutomaticExportation)
for my $subs ( values(%EXPORT_TAGS) ) {
    push @EXPORT, @{$subs};
}
$EXPORT_TAGS{'all'} = [@EXPORT];
our @EXPORT_OK = @EXPORT;

# Where are our test files/folders?
my $base_root =
  File::Spec->catdir( File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), qw/lib/ );

# What are our test localizer loaders and their specifics?
my (@loaders) = (
    {
        'package'      => 'Cpanel::CPAN::Locale::Maketext::Utils',
        'mockfolder'   => 'DummyCCLMU',
        'faultmessage' => '"Can\'t locate %PATH% in @' . 'INC (you may need to install the %PKG% module)',
    },
    {
        'package'             => 'Locale::Maketext::Utils',
        'mockfolder'          => 'DummyLMU',
        'faultmessage'        => 'previous erroring on load',
        'use_undef_for_fault' => 1,
    },
    {
        'package'      => 'Locale::Maketext',
        'mockfolder'   => 'DummyLM',
        'faultmessage' => '"%PATH% did not return a true value at ',

    },
);

# Return the location of the faulty localization modules
sub fault_inc() {
    return File::Spec->catdir( $base_root, qw/Locale MaybeMaketext FaultyModules/ );
}

# Return the location of our test files.
sub base_inc() {
    return $base_root;
}

# Get a localization test module by index number.
sub get_test_data_by_index ( $index = 0 ) {
    my $max = $#loaders;
    if ( $index > $max ) { return undef; }    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    my %current = %{ $loaders[$index] };
    $current{'index'} = $index;
    return bless \%current, __PACKAGE__;
}

# Get an iterator of the test modules.
# Usage:
#  my $next = test_data_iterator();
# while ( my $package = $next->() ) {
#   echo $package->get_name();
# }
sub test_data_iterator () {
    my $index = 0;
    my $max   = $#loaders;

    return sub {
        if ( $index > $max ) { return undef; }    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
        $index++;
        return get_test_data_by_index( $index - 1 );
    }
}

# Get the current index.
sub get_index ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    return $self->{'index'};
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return the current test package name.
sub get_name ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    return $loaders[ $self->{'index'} ]->{'package'}
      || croak( sprintf( 'Missing package for index %s', $self->{'index'} ) );
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return the current test
# mock module location (building it up/caching it if necessary).
sub get_mock ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    if ( !defined( $loaders[ $self->{'index'} ]->{'mock'} ) ) {
        if ( !defined( $loaders[ $self->{'index'} ]->{'mockfolder'} ) ) {
            croak( sprintf( 'Missing mock folder for index %s', $self->{'index'} ) );
        }
        $loaders[ $self->{'index'} ]->{'mock'} =
          File::Spec->catdir( $base_root, qw/Locale MaybeMaketext/, $loaders[ $self->{'index'} ]->{'mockfolder'} );
    }
    return $loaders[ $self->{'index'} ]->{'mock'};
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return the current test
# fault message (building it up/caching it if necessary).
sub get_fault_message ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    if ( !defined( $loaders[ $self->{'index'} ]->{'fullfaultmessage'} ) ) {
        if ( !defined( $loaders[ $self->{'index'} ]->{'faultmessage'} ) ) {
            croak( sprintf( 'Missing faultmessage for index %s', $self->{'index'} ) );
        }
        my $faultmessage = $loaders[ $self->{'index'} ]->{'faultmessage'};
        my ( $package_name, $path ) = ( $self->get_name(), $self->get_path() );
        $faultmessage =~ s/%PKG%/$package_name/g;
        $faultmessage =~ s/%PATH%/$path/g;
        $faultmessage = sprintf( '- %s: Unable to set as parent localizer due to %s', $package_name, $faultmessage );
        $loaders[ $self->{'index'} ]->{'fullfaultmessage'} = $faultmessage;
    }

    return $loaders[ $self->{'index'} ]->{'fullfaultmessage'};
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return the current test
# full INC path.
sub get_inc ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    return ( $self->get_mock(), $base_root );
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return the current test
# "path to use in INC queries".
sub get_path ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    if ( !defined( $loaders[ $self->{'index'} ]->{'path'} ) ) {
        my $package_name = $self->get_name();
        $loaders[ $self->{'index'} ]->{'path'} = ( $package_name =~ tr{:}{\/}rs ) . '.pm';
    }
    return $loaders[ $self->{'index'} ]->{'path'};
}

# If in a test_data_iterator iterator or get_test_data_by_index, then return true (1) if
# the current test package requires the "INC" path to be set to undef for testing.
sub is_undef_needed_for_fault ($self) {
    if ( !defined( $self->{'index'} ) ) {
        croak('Missing index');
    }
    if ( defined( $loaders[ $self->{'index'} ]->{'use_undef_for_fault'} ) ) {
        return 1;
    }
    return 0;
}

# Unload any previously loaded Maketext libraries.
sub unload_mocks() {
    my $next = test_data_iterator();
    while ( my $package = $next->() ) {
        my $path = $package->get_path();
        if ( defined( $INC{$path} ) ) {
            delete $INC{$path};
            no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
            undef *{ $package->get_name() . '::get_handle' };
            undef *{ $package->get_name() . '::maketext' };
        }
    }
    return 1;
}

# Automatically import warnings, strict and signature settings to the calling module.
sub import {    ## no critic (Subroutines::RequireArgUnpacking)

    warnings::warnings->import();
    strict::strict->import();
    feature->import(qw/:5.20 signatures/);

    warnings::warnings->unimport(qw/experimental::signatures/);
    MaybeMaketextTestdata->export_to_level( 1, @_ );
    return;
}

# Check all the isas are correctly set - but actually report back which ones are missing.
sub isa_check ( $handle, $packages_ref, $reason ) {
    my %failures = ();
    my @packages = @{$packages_ref};
    for my $key (@packages) {
        if ( !$handle->isa($key) ) {
            $failures{$key} = 1;
        }
    }
    if (%failures) {
        my @diagnose = ();
        for my $key (@packages) {
            if ( $failures{$key} ) {
                push @diagnose, isa_diagnose( 'Failed ISA', $key );
            }
            else {
                push @diagnose, isa_diagnose( 'Passed ISA', $key );
            }
        }
        diag( join( "\n", @diagnose ) );
        fail(
            sprintf(
                '%s: Failed due to %s not having package(s)',
                $reason,
                ref($handle) || $handle
            )
        );
    }
    pass($reason);
    return 1;
}

# If a package isn't supported, try and diagnose why.
sub isa_diagnose ( $state, $package_name ) {
    my $path        = ( $package_name =~ tr{:}{\/}rs ) . '.pm';
    my $inc_results = (
        exists( $INC{$path} )
        ? (
            defined( $INC{$path} )
            ? (
                ref( $INC{$path} )
                ? 'loaded by hook'
                : sprintf( 'loaded by filesystem from "%s"', $INC{$path} )
              )
            : 'raised error/warning on load'
          )
        : 'not loaded'
    );
    return sprintf( '%s - %s : %s (%s)', $state, $package_name, $inc_results, $path );
}

1;

__END__

=encoding utf8

=head1 NAME

MaybeMaketextTestdata - Provides testing related data for Locale::MaybeMaketext

=cut
