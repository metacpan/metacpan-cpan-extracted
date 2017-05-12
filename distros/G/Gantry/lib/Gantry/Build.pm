package Gantry::Build;
use strict;

use base 'Module::Build';
use File::Find;
use File::Copy::Recursive qw( dircopy );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    my $p     = $self->{ properties };

    print( '*' x 80, "\n" );
    print( "$self->{module_name}\n" );
    print( '*' x 80, "\n" );

    # collect web files 
    my( %web_dirs, @web_files );

    my $wanted = sub {
        my $dir = $File::Find::dir;
        my $file = $_;

        # XXX unix specific directory work
        $dir =~ s![^/]*/!!;  # remove extraneous leading slashes

        return if $dir =~ /\.svn/;

        push( @web_files, "$File::Find::dir/$file" )
            if -f $file and ( $file !~ /^\.\.?$/o );

        ++$web_dirs{ $dir };
    };

    find( $wanted, $p->{ build_web_directory } );

    foreach my $k ( sort { $a cmp $b } keys %web_dirs ) {
        print "[web dir] $k\n";
    }

    $p->{ web_files } = \@web_files;

    # decide where to install web content
    print "\n";
    print "-" x 80;
    print "Web Directory\n";
    print "-" x 80;
    print "\n\n";

    print "This application has accompanying web files (like templates).\n";
    print "Please choose a web servable directory for them:\n";

    my $prompt;
    my $count = 0;
    my ( %dir_hash, @choices );

    foreach my $k ( sort{ $a cmp $b }
        keys %{ $p->{ install_web_directories } } ) {

        $prompt .= (
            sprintf( "%-7s: ", $k )
            . $p->{ install_web_directories }{ $k } . "\n" );

        push( @choices, $k );
    }

    $prompt .= "Web Directory [" . join( ',', @choices ) . "]?";

    my $choice = $self->prompt( $prompt );

    my $tmpl_dir;
    my $SKIP_TEXT = '__skip__';
    # XXX unix specific slash test
    if ( $choice =~ /\// ) {
        $tmpl_dir = $choice;
    }
    elsif ( ! defined $p->{ install_web_directories }{ $choice } ) {
        $tmpl_dir = $SKIP_TEXT;
    }
    else {
        $tmpl_dir = $p->{ install_web_directories }{ $choice }
    }

    # XXX unix specific slash cleanup
    $tmpl_dir =~ s/\/$//g;

    if ( ! -d $tmpl_dir ) {
        my $create = $self->prompt(  
            "Directory doesn't exist. Create it during install [yes]?"
        );
        $p->{ create_web_dir } = $create;
    }

    $p->{ web_dir } = $tmpl_dir;

    return bless $self, $class;
}

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code();

    $self->add_build_element( 'web' );

    $self->_process_web_files( 'web' );

}

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install();
    my $p = $self->{properties};

    my $tmpl_dir = $p->{web_dir};

    if( $tmpl_dir && $tmpl_dir ne '__skip__' ) {

        if ( not -d $tmpl_dir and $p->{ create_web_dir } =~ /^n/i ) {
            exit;
        }

        eval {
            File::Path::mkpath( $tmpl_dir );
        };
        if ( $@ ) {
            print "Error: unable to create directory $tmpl_dir\n";
            $@ =~ s/ at .+?$//;
            die( "$@\n" );
        }

        my $blib_tmpl_dir = File::Spec->catdir(
            $self->blib, 'web', $p->{build_web_directory} 
        );

        my $num;
        eval {
            $num = dircopy($blib_tmpl_dir, $tmpl_dir);
        };
        if ( $@ ) {
            print "Error coping templates:\n";
            print $@ . "\n";
        }
        else {
            print "Web content copied: $num\n";
        }
    }
    else {
        print "SKIPPING WEB CONTENT INSTALL\n";
    }
    print "-" x 80;
    print "\n";

} # end ACTION_install

sub _process_web_files {
    my $self    = shift;
    my $p       = $self->{properties};
    my $files   = $p->{web_files};
    
    return unless @$files;

    my $tmpl_dir = File::Spec->catdir($self->blib, 'web');
    File::Path::mkpath( $tmpl_dir );

    foreach my $file (@$files) {
        my $result = $self->copy_if_modified("$file", $tmpl_dir);
    }
}

1;

=head1 NAME

Gantry::Build - a Module::Build subclass for Gantry apps

=head1 SYNOPSIS

Sample Build.PL:

    use strict;
    use Gantry::Build;

    my $build = Gantry::Build->new(
        build_web_directory => 'html',
        install_web_directories =>  {
            # XXX unix specific paths
            'dev'   => '/home/httpd/html/Contact',
            'qual'  => '/home/httpd/html/Contact',
            'prod'  => '/home/httpd/html/Contact',
        },
        create_makefile_pl => 'passthrough',
        license            => 'perl',
        module_name        => 'Contact',
        requires           => {
            'perl'      => '5',
            'Gantry'    => '3.0',
            'HTML::Prototype' => '0',
        },
        create_makefile_pl  => 'passthrough',

        # XXX unix specific paths
        script_files        => [ glob('bin/*') ],
        'recursive_test_files' => 1,

        # XXX unix specific paths
        install_path        => { script => '/usr/local/bin' },
    );

    $build->create_build_script;

=head1 DESCRIPTION

Use this module instead of Module::Build (which it subclasses).  Use
any or all of the Module::Build constructor keys as needed.  Include these
keys to make the module sing:

=over 4

=item build_web_directory

Usually C<html>.  This is the top level directory of your web content.
Put your content in subdirectories of this dir.  Example: if you
are in the build directory (the one where Build.PL lives), your templates
should live in C<html/templates>.

=item install_web_directories

This is a hash reference.  The keys are what installing users will type,
values are where the content from C<build_web_directory> subdirectories
will go.

=back

=head1 METHODS

Except new, these methods are all internal or for use by Module::Build.
They are documented to keep POD tests happy.

=over 4

=item new

Just like Module::Build->new, but takes the extra parameters shown in the
DESCRIPTION above.

=item ACTION_code

Standard Module::Build routine.

=item ACTION_install

Standard Module::Build routine.

=back

=head1 AUTHOR

Phil Crow E<lt>philcrow2000@yahoo.comE<gt>

Tim Keefer E<lt>tkeefer@gmail.comE<gt>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005-6 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
