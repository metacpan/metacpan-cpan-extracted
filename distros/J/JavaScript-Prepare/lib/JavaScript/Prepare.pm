package JavaScript::Prepare;

use Modern::Perl;

use File::Basename;
use FileHandle;
use JavaScript::Minifier::XS    qw( minify );

use version;
our $VERSION = qv( 0.1 );


sub new {
    my $class = shift;
    my %args  = @_;
    
    my $self = {
            strip => 0,
        };
    bless $self, $class;
    
    $self->{'strip'} = 1
        if defined $args{'strip'};
    
    return $self;
}

sub process {
    my $self = shift;
    my @args = @_;
    
    my $minified = '';
    foreach my $arg ( @args ) {
        given ( $arg ) {
            when ( -f $arg ) {
                $minified .= $self->process_file( $arg );
            }
            when ( -d $arg ) {
                $minified .= $self->process_directory( $arg );
            }
            default {
                return '';
            }
        }
    }
    
    return $minified;
}

sub process_string {
    my $self = shift;
    my $js   = shift;
    
    $js =~ s{^ \s* console.log(.*?); \s* $}{}gmx
        if $self->{'strip'};
    
    my $minified = minify($js);
    
    return "${minified}\n"
        if defined $minified && length $minified;
    return '';
}

sub process_file {
    my $self = shift;
    my $file = shift;
    
    my $content = $self->read_file( $file );
    return '' unless $content;
    
    my $control_file = $content =~ m{^# control file};
    
    if ( $control_file ) {
        return $self->process_control_file( $file );
    }
    else {
        return $self->process_string( $content );
    }
}
sub process_control_file {
    my $self = shift;
    my $file = shift;
    
    my $dir     = dirname $file;
    my $content = $self->read_file( $file );
    my @lines   = split m{\n}, $content;
    
    my $minified = '';
    foreach my $line ( @lines ) {
        # 
        $line =~ m{
            ^ 
                ( \S+ )?            # $1: a filename
                \s* (?: \# .* )?    # optional comment
            $
        }x;
        
        $minified .= $self->process_file( "$dir/$1" )
            if defined $1;
    }
    
    return $minified;
}
sub read_file {
    my $self = shift;
    my $file = shift;
    
    my $handle = FileHandle->new( $file )
        or return;
    
    my $content = do {
        local $/;
        <$handle>
    };
    
    return $content;
}

sub process_directory {
    my $self      = shift;
    my $directory = shift;
    
    my @files = $self->get_files_in_directory( $directory );
    my $minified;
    
    foreach my $file ( @files ) {
        $minified .= $self->process_file( $file );
    }
    
    return $minified;
}
sub get_files_in_directory {
    my $self      = shift;
    my $directory = shift;
    
    opendir my $handle, $directory
        or return;
    
    my @files;
    my @directories;
    while ( my $entry = readdir $handle ) {
        next if $entry =~ m{^\.};
        
        my $target = "$directory/$entry";
        
        push( @files, $target ) if -f $target;
        push( @directories, $target ) if -d $target;
    }
    closedir $handle;
    
    foreach my $dir ( @directories ) {
        my @subfiles;
        
        foreach my $file ( $self->get_files_in_directory( $dir ) ) {
            push @subfiles, $file;
        }
        
        @files = ( @subfiles, @files );
    }
    
    return @files;
}

1;
