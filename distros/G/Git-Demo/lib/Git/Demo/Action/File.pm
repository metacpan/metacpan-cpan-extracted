package Git::Demo::Action::File;
use strict;
use warnings;
use File::Spec::Functions;
use File::Util;
use File::Copy;
use File::Basename;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;

    bless $self, $class;
    return $self;
}

sub run{
    my( $self, $character, $event ) = @_;
    my $logger = $self->{logger};
    if( $event->action() eq 'touch' ){
        return $self->_touch( $character, $event );
    }elsif( $event->action() eq 'append' ){
        return $self->_append( $character, $event );
    }elsif( $event->action() eq 'copy' ){
        return $self->_copy( $character, $event );
    }elsif( $event->action() eq 'move' ){
        return $self->_move( $character, $event );
    }else{
        die( "Unknown action: " . $event->action() );
    }
}


sub _touch{
    my( $self, $character, $event ) = @_;
    my $logger = $self->{logger};
    foreach my $arg( @{ $event->args() } ){
        my $path = catfile( $character->dir(), $arg );
        $logger->debug( "touching: $path" );
        if( ! open( FH, ">", $path ) ){
            die( "Could not open file ($path): $!" );
        }
        close FH;
    }
    return;
}

# Can accept absolute, or relative paths for the source
# The target path will always be relative to the characters own directory
sub _copy{
    my( $self, $character, $event ) = @_;
    my $logger = $self->{logger};

    my @args = @{ $event->args() };
    if( scalar( @args ) < 2 ){
        die( "need at least two paths for a copy" );
    }

    # The last will be the target
    my $target_rel = pop( @args );
    my $target_abs = catdir( $character->dir(), $target_rel );
    my $num_files = scalar( @args );

    # If there are more than one file to copy, the target must be a directory
    if( $num_files > 1 && -f $target_abs ){
        die( "Cannot copy multiple files to one target file" );
    }

    if( $num_files > 1 && ! -d $target_abs ){
        my $f = File::Util->new();
        if( ! $f->make_dir( $target_abs ) ){
            die( "Could not create dir ($target_abs): $!" );
        }
    }

    foreach my $path( @args ){
        my $source_path;
        if( file_name_is_absolute( $path ) ){
            $source_path = $path;
        }else{
            $source_path = catfile( $character->dir(), $path );
        }
        my $target_path = undef;
        if( $num_files > 1 ){
            $target_path = catfile( $target_abs, fileparse( $source_path ) );
        }else{
            $target_path = $target_abs;
        }
        if( -f $source_path ){
            $self->output( $character, "Copying from/to\n\t$source_path\n\t$target_path" );
            if( ! copy( $source_path, $target_path ) ){
                die( "Could not copy from $source_path to $target_path: $!" );
            }
        }else{
            $logger->warn( "File does not exist: $source_path\n" );
        }
    }
    return;
}


# Can accept absolute, or relative paths for the source
# The target path will always be relative to the characters own directory
sub _move{
    my( $self, $character, $event ) = @_;
    my $logger = $self->{logger};

    my @args = @{ $event->args() };
    if( scalar( @args ) != 2 ){
        die( "need at exactly two paths for a move" );
    }

    my $source_abs;
    if( file_name_is_absolute( $args[0] ) ){
        $source_abs = $args[0];
    }else{
        $source_abs = catdir( $character->dir(), $args[0] );
    }
    my $target_abs = catdir( $character->dir(), $args[1] );

    if( ! -f $source_abs ){
        die( "Source file ($source_abs) does not exit" );
    }

    $self->output( $character, "Moving from/to\n\t$args[0]\n\t$args[1]" );
    if( ! rename( $source_abs, $target_abs ) ){
        die( "Could not move from $source_abs to $target_abs: $!" );
    }
    return;
}


sub _append{
    my( $self, $character, $event ) = @_;
    my $logger = $self->{logger};
    my @args = @{ $event->args() };
    if( scalar( @args ) != 2 ){
        die( "Incorrect number of arguments" );
    }
    my $path = catfile( $character->dir(), $args[0] );
    my $text = $args[1];

    # Some text replacements
    my $name = $character->name();
    my $date = '' . localtime();
    $text =~ s/\[% NAME %\]/$name/g;
    $text =~ s/\[% DATE %\]/$date/g;

    $self->output( $character, "appending to: $path" );

    if( ! open( FH, ">>", $path ) ){
        die( "Could not open file ($path): $!" );
    }
    print FH $text . "\n";
    close FH;
    return;
}

sub output{
    my( $self, $character, $text ) = @_;
    my $logger = $self->{logger};

    $logger->info( sprintf( "File (%s): %s\n", $character->name(), $text ) );
}

1;
