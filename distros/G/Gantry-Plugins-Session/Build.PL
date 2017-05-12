use strict;
use Module::Build;
use File::Find;

print( '*' x 80, "\n" );
print( "Gantry::Plugins::Session\n" );
print( '*' x 80, "\n" );

my $subclass = Module::Build->subclass(
    class   => 'My::Builder',
    code    => &_custom_code(),
);

# collect web files
my( %web_dirs, @web_dirs );
my $template_path;

find( \&wanted, 'root' );

sub wanted {

    my $dir = $File::Find::dir;
    $dir =~ s![^/]*/!!;

    next if $dir =~ /\.svn/;

    ++$web_dirs{ $dir };
}

push( @web_dirs, '/*.*' );
foreach my $k ( sort { $a cmp $b } keys %web_dirs ) {
    print "[web dir] $k\n";
    push( @web_dirs, ( $k . '/*.*' ) );
}
    
my $build = $subclass->new(
    web_files => \@web_dirs,
    build_web_directory => 'root',
    install_web_directories =>  { 
        'default' => '/home/httpd/html/gantry',
        'prod'    => '/home/httpd/html/gantry',
        'dev'     => '/home/httpd/html/gantry',
    },
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    dist_author        => 'Kevin L. Esteb <kesteb@wsipc.org>',
    dist_abstract      => 'Plugin for cookie based session management',
    module_name        => 'Gantry::Plugins::Session',
    requires           => {
        'Gantry'                    => '3.52',
        'Gantry::Plugins::Cache'    => 0,
        'Crypt::CBC'                => 0,
    },
    build_requires      => {
        'Test::More'          => 0,
        'Test::Exception'     => 0,
    },
    create_makefile_pl  => 'passthrough',
    script_files        => [ glob('bin/*') ],
    test_files          => [
        't/*.t',
    ],
);

my $default_template_path = $build->{ properties }
                                    { install_web_directories }
                                    { default };

eval {
    require Gantry::Init;
    $template_path = Gantry::Init->base_root();
};

$build->notes( install_web_directory => $template_path );

if ( not -d $template_path ) {
    my $make_path = $ENV{'GANTRY_TEMPLATE_PATH'} || $build->y_n(
        "$template_path does not exist, should I make it?",
        'y'
    );

    if ( $make_path ) {
        eval {  
            File::Path::mkpath( $template_path );
        };
        if ( $@ ) {
            $@ =~ s/ at .+?$//;
            print "Error: unable to create directory $template_path @_\n";
            $build->notes( install_web_directory => '__skip__' );
        }
    }
    else {
        $build->notes( install_web_directory => '__skip__' );
    }
}

$build->create_build_script;

sub _custom_code {

    return( q{

    sub ACTION_code {
        my $self = shift;

        $self->SUPER::ACTION_code();
        $self->add_build_element( 'web' );
        $self->process_web_files( 'web' );

    }

    sub ACTION_install {
        my $self = shift;
        
        my $p = $self->{properties};        
        my $install_base = $self->install_destination('lib') 
            || $p->{install_sets}{site}{lib};
        my $initf = "$install_base/$p->{dist_name}/Init.pm";
        $self->SUPER::ACTION_install();
        my $tmpl_dir = $self->notes( 'install_web_directory' );
            
        if( $tmpl_dir && $tmpl_dir ne '__skip__' ) {

            my $blib_tmpl_dir = File::Spec->catdir(
                $self->blib, 'web', $p->{build_web_directory} 
            );  
            
            eval {
                require File::Copy::Recursive;
                import File::Copy::Recursive 'dircopy';

                $num = dircopy($blib_tmpl_dir, $tmpl_dir) || 0;
            };
            if ( $@ ) {
                print "\nError coping templates:\n";
                print $@ . "\n";
            }
            else {
                print "\n$num Gantry templates copied to $tmpl_dir\n";
            }
        }
        else {
            print "SKIPPING WEB CONTENT INSTALL\n";
        }
        
        print "\n";

    } # end ACTION_install

    sub process_web_files {
        my $self = shift;
        my $files = $self->find_web_files;
        return unless @$files;
        
        my $tmpl_dir = File::Spec->catdir($self->blib, 'web');
        File::Path::mkpath( $tmpl_dir );
        
        foreach my $file (@$files) {
            my $result = $self->copy_if_modified($file, $tmpl_dir) 
                or next;
            #$self->fix_shebang_line($result);
        }
    }

    sub find_web_files {
        my $self = shift;
        my $p = $self->{properties};
        my $b_tmpl_dir = $p->{build_web_directory};
        $b_tmpl_dir =~ s/\/$//g;

        if (my $files = $p->{web_files}) {
            if (  UNIVERSAL::isa($files, 'HASH') ) {
                my @files = [keys %$files];
                return( \@files );
            }
            
            my @files;
            foreach my $glob ( @$files ) {
                $glob = "$b_tmpl_dir/$glob";
                push( @files, glob( $glob ) );
            }       
            return( \@files );
            return( [ map $self->localize_file_path($_), @files ] );
            return( \@localized );
        } 
    }

    sub web_files {
        my $self = shift;
        for ($self->{properties}{web_files}) {
            $_ = shift if @_;
            return unless $_;
            
            # Always coerce into a hash
            return $_ if UNIVERSAL::isa($_, 'HASH');
            return $_ = {$_ => 1} unless ref();
            return { map {$_,1} @$_ };
        }
    }
    
    } ); # end return

} # end _custom_code
