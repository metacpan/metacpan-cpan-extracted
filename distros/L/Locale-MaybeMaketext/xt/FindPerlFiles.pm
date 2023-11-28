package FindPerlFiles;
use v5.20.0;
use strict;
use warnings;
use vars;
use utf8;

use File::Find();
use File::Spec();
use Carp    qw/carp croak/;
use feature qw/signatures/;
no if $] >= 5.032, q|feature|, qw/indirect/;
no warnings qw/experimental::signatures/;

my %cached_folders;
my %cached_results;

sub get_lib_folder() {
    if ( !defined( $cached_folders{'lib'} ) ) {
        $cached_folders{'lib'} = File::Spec->catdir(
            File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), ( File::Spec->updir() ) x 1,
            qw/lib/
        );

    }
    return $cached_folders{'lib'};
}

sub get_test_folder() {
    if ( !defined( $cached_folders{'test'} ) ) {
        $cached_folders{'test'} = File::Spec->catdir(
            File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), ( File::Spec->updir() ) x 1,
            qw/t/
        );
    }
    return $cached_folders{'test'};
}

sub get_xtest_folder() {
    if ( !defined( $cached_folders{'xtest'} ) ) {
        $cached_folders{'xtest'} = File::Spec->catdir(
            File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), ( File::Spec->updir() ) x 1,
            qw/xt/
        );
    }
    return $cached_folders{'xtest'};
}

sub check_perl_files ( $subroutine, @paths ) {
    if ( !@paths ) {
        @paths = ( get_lib_folder(), get_test_folder(), get_xtest_folder() );
    }
    for my $path (@paths) {
        my @files  = find_perl_files($path);
        my $length = length($path);
        for my $current_file (@files) {
            if ( substr( $current_file, 0, $length ) ne $path ) {
                fail( sprintf( '%s is outside our source directory %s', $current_file, $path ) );
                next;
            }
            my $just_filename = substr( $current_file, $length + 1 );
            $subroutine->( $current_file, $just_filename );
        }
    }
    return 1;
}

sub check_perl_module_files ( $subroutine, @paths ) {
    if ( !@paths ) {
        @paths = ( get_lib_folder(), get_test_folder(), get_xtest_folder() );
    }
    for my $path (@paths) {
        my @files  = find_perl_module_files($path);
        my $length = length($path);
        for my $current_file (@files) {
            if ( substr( $current_file, 0, $length ) ne $path ) {
                fail( sprintf( '%s is outside our source directory %s', $current_file, $path ) );
                next;
            }
            my $just_filename = substr( $current_file, $length + 1 );
            $subroutine->( $current_file, $just_filename );
        }
    }
    return 1;
}

sub find_perl_files ($path) {
    if ( defined( $cached_results{$path} ) ) {
        return @{ $cached_results{$path} };
    }
    my @files;
    if ( !-d $path ) {
        croak( sprintf( 'Could not find directory at %s', $path ) );
    }
    File::Find::find(
        {
            'wanted' => sub {
                if ( -f $File::Find::name && check_if_file_is_perl($File::Find::name) ) {
                    push @files, $File::Find::name;
                }
                1;
            },
        },
        ($path)
    );
    $cached_results{$path} = \@files;
    return @{ $cached_results{$path} };
}

sub find_perl_module_files ($path) {
    if ( defined( $cached_results{ 'modules-' . $path } ) ) {
        return @{ $cached_results{ 'modules-' . $path } };
    }
    my @files;
    if ( !-d $path ) {
        croak( sprintf( 'Could not find directory at %s', $path ) );
    }
    File::Find::find(
        {
            'wanted' => sub {
                if ( -f $File::Find::name && $File::Find::name =~ /\.(?:pm)\z/i ) {
                    push @files, $File::Find::name;
                }
                1;
            },
        },
        ($path)
    );
    $cached_results{ 'modules-' . $path } = \@files;
    return @{ $cached_results{ 'modules-' . $path } };
}

sub check_if_file_is_perl ($filename) {

    # check common suffixes.
    if ( $filename =~ /\.(?:pl|pm|t)\z/i ) {
        return 1;
    }
    my ( $file_handle, $first_line );
    if ( !open( $file_handle, '<', $filename ) ) {
        carp( sprintf( 'Cannot open %s: %s . Skipping!', $filename, $! ) . "\n" );
        return 0;
    }
    $first_line = <$file_handle>;
    if ( !close $file_handle ) {
        croak( sprintf( 'Cannot close %s', $filename ) . "\n" );
    }
    if ( !$first_line ) {
        return 0;
    }

    # is it a batch file starting with --[*]-Perl-[*]-- ?
    if ( $filename =~ /\.bat\z/i ) {
        if ( $first_line =~ /--[*]-Perl-[*]--/ ) {
            return 1;
        }
    }

    # is the first line a she-bang mentioning perl anywhere?
    if ( $first_line =~ /\A#!.*perl/ ) {
        return 1;
    }
    return 0;
}

1;

=encoding utf8

=head1 NAME

FindPerlFiles - Helps find Perl files of certain types for testing purposes.

=cut
