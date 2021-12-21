package Local::Test::TempDir;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Carp qw(croak);
use Cwd qw(getcwd);
use File::Path 2.07 qw(remove_tree);
use File::Spec::Functions qw(catdir);

# Support Exporter < 5.57
require Exporter;
our @ISA       = qw(Exporter);    ## no critic (ClassHierarchies::ProhibitExplicitISA)
our @EXPORT_OK = qw(tempdir);

{
    my $temp_dir_base;

    sub _init {
        return if defined $temp_dir_base;

        my $root_dir = getcwd();
        croak "Cannot get cwd: $!" if !defined $root_dir;

        $temp_dir_base = catdir( $root_dir, 'tmp' );
        if ( !-d $temp_dir_base ) {
            mkdir $temp_dir_base or croak "Cannot create directory $temp_dir_base $!";
        }

        ( my $dirname = $0 ) =~ tr{:\\/.}{_};
        $temp_dir_base = catdir( $temp_dir_base, $dirname );
        if ( !-e $temp_dir_base ) {
            mkdir $temp_dir_base or croak "Cannot create directory $temp_dir_base $!";
        }
        elsif ( -l $temp_dir_base || !-d _ ) {
            croak "Not a directory $temp_dir_base";
        }
        else {
            remove_tree( $temp_dir_base, { safe => 0, keep_root => 1 } );
        }

        return;
    }

    my %counter;

    sub tempdir {
        my $label = defined( $_[0] ) ? $_[0] : 'default';
        $label =~ tr{a-zA-Z0-9_-}{_}cs;

        if ( exists $counter{$label} ) {
            $counter{$label}++;
        }
        else {
            $counter{$label} = '0';
        }

        $label = "${label}_$counter{$label}";

        _init();

        my $tempdir = catdir( $temp_dir_base, $label );
        mkdir $tempdir or croak "Cannot create directory: $!";

        return $tempdir;
    }
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
