package Javonet::Core::Handler::CommandHandler::LoadLibraryHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use File::Basename;
use Cwd qw(abs_path);
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
extends 'Javonet::Core::Handler::CommandHandler::AbstractCommandHandler';

# Track loaded libraries by absolute path
our %LOADED_LIBRARIES;

sub new {
    my $class = shift;
    my $self  = {
        required_parameters_count => 1,
        @_,    # optional extras
    };
    return bless $self, $class;
}

sub process {
    my ( $self, $command ) = @_;
    try {
        my $current_payload_ref = $command->{payload};
        my @cur_payload         = @$current_payload_ref;
        my $parameters_length   = @cur_payload;

        if ( $parameters_length != $self->{required_parameters_count} ) {
            die Exception->new("Exception: LoadLibrary parameters mismatch");
        }

        my $path_to_file = $command->{payload}[0];

        if ( !defined $path_to_file || $path_to_file eq '' ) {
            die Exception->new(
                "Cannot load module: Library path is required but was not provided"
            );
        }

        # ---------------------------------------------------------------------
        # Normalize file extension
        # If no extension is given, try "<file>.pm"
        # ---------------------------------------------------------------------
        my $normalized_path = $path_to_file;

        if ( $normalized_path !~ /\.[^\/\\]+$/ ) {    # no extension
            my $with_pm = $normalized_path . '.pm';
            if ( -e $with_pm ) {
                $normalized_path = $with_pm;
            }
        }

        # Resolve to absolute path if possible
        my $absolute_path =
            abs_path($normalized_path)
                // abs_path($path_to_file)
                // $normalized_path;

        # Check that the file exists
        if ( !-e $absolute_path ) {
            die Exception->new("Cannot load module: Library not found: $path_to_file");
        }

        # ---------------------------------------------------------------------
        # Load only once by absolute path
        # ---------------------------------------------------------------------
        if ( $LOADED_LIBRARIES{$absolute_path} ) {
            return 0;
        }

        my $path_to_file_dir = dirname($absolute_path);
        my $file_name        = basename($absolute_path);

        # Ensure directory is in @INC
        if ( !grep { $_ eq $path_to_file_dir } @INC ) {
            push @INC, $path_to_file_dir;
        }

        # ---------------------------------------------------------------------
        # Validate Perl module syntax before requiring
        # ---------------------------------------------------------------------
        #_validate_perl_syntax($absolute_path); #causes issues

        # ---------------------------------------------------------------------
        # Load the file
        # ---------------------------------------------------------------------
        eval {
            require $file_name;
            1;
        } or do {
            my $err = $@ || 'Unknown error';
            die Exception->new("Cannot load module: $absolute_path\n$err");
        };

        # Mark library as loaded
        $LOADED_LIBRARIES{$absolute_path} = 1;

        return 0;
    }
    catch ($e) {
        return Exception->new($e);
    }
}

sub get_loaded_libraries {
    my ($self) = @_;
    return [ keys %LOADED_LIBRARIES ];
}

# -------------------------------------------------------------------------
# Validate syntax using "perl -c <file>"
# -------------------------------------------------------------------------
sub _validate_perl_syntax {
    my ($absolute_path) = @_;

    my $perl = $^X || 'perl';

    my $pid = open my $fh, '-|', $perl, '-c', $absolute_path;
    if ( !defined $pid ) {
        # If perl cannot be spawned, we silently skip validation.
        return;
    }

    my $output = do { local $/; <$fh> // '' };
    close $fh;
    my $exit_code = $? >> 8;

    if ( $exit_code != 0 ) {
        die Exception->new(
            "Cannot load module: syntax check failed for $absolute_path\n$output"
        );
    }
}

no Moose;
1;
