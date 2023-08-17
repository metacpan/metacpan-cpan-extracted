package Loverl::Create::Directory;

# ABSTRACT: Creates the project directory

use v5.36;

use Cwd;
use Moose;

use Loverl::Create::File_Content;

use constant { true => 1, false => 0 };

has "dir_name" => ( is => "rw", isa => "Str", default => "new-project" );

my %file_content = Loverl::Create::File_Content::file_content();

sub dir() {
    my $dir = getcwd();
    return $dir;
}

sub project_dir ($self) {
    my $project_dir = dir() . "/" . $self->dir_name;
    return $project_dir;
}

sub project_subdir ( $self, $dir_name ) {
    my $project_subdir = project_dir($self) . "/" . $dir_name;
    return $project_subdir;
}

sub create_file ($self) {
    my $FILE;

    foreach my $key ( keys %file_content ) {
        open( $FILE, ">>", project_dir($self) . "/$key" )
          or die( "Cannot open file: " . $! );
        my $value = $file_content{$key};
        print( $FILE $value );
        close($FILE) or die( "Cannot close file: " . $! );
    }
}

sub create_dir ( $self, $isVerbose ) {
    if ( -e $self->dir_name ) {
        print( project_dir($self) . "/" . " already exists as a file.\n" );
    }
    else {
        if ( -d $self->dir_name ) {
            print( project_dir($self) . "/" . " already exists.\n" );
        }
        else {
            mkdir( project_dir($self) )
              or die( "Can't create directory. " . $! );
            mkdir( project_subdir( $self, "assets" ) )
              or die( "Can't create directory. " . $! );
            mkdir( project_subdir( $self, "libraries" ) )
              or die( "Can't create directory. " . $! );
            create_file($self);
            print( "+ " . project_dir($self) . "/" . "\n" )
              if $isVerbose eq false;
            verbose_logging($self) if $isVerbose eq true;
        }
    }
}

sub verbose_logging ($self) {
    print( "+ " . project_dir($self) . "/" . "\n" );
    print( "+ " . project_dir($self) . "/assets/" . "\n" );
    print( "+ " . project_dir($self) . "/libraries/" . "\n" );
    foreach my $key ( keys %file_content ) {
        print( "+ " . project_dir($self) . "/$key" . "\n" );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Loverl::Create::Directory - Creates the project directory

=head1 VERSION

version 0.005

=head1 DESCRIPTION

The Directory module creates the project folder.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
