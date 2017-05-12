package Glade::PerlProject;
require 5.000; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Carp qw(cluck);
    $SIG{__DIE__}  = \&Carp::confess;
    $SIG{__WARN__} = \&Carp::cluck;
    use Data::Dumper;
    use File::Path     qw( mkpath );        # in use_Glade_Project
    use File::Basename qw( basename dirname );       # in use_Glade_Project
    use Cwd            qw( chdir cwd );     # in use_Glade_Project
    use Sys::Hostname  qw( hostname );      # in use_Glade_Project
    use Glade::PerlSource qw(:VARS :METHODS ); # Source writing vars and methods
    use Glade::PerlUI;
    use vars           qw( 
                            @ISA 
                            $PACKAGE $VERSION $AUTHOR $DATE
                            %app_fields
                            $new
                            $convert
                       );
    # Tell interpreter who we are inheriting from
    @ISA            = qw( 
                            Glade::PerlSource
                            Glade::PerlUI
                        );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.61);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Fri May  3 03:56:25 BST 2002);

%app_fields = (
    'type'  => 'glade2perl',
    'app'   => {
        'use_modules'   => undef,   # Existing signal handler modules
        'allow_gnome'   => undef,   # Dont allow gnome widgets
        'allow_gnome_db'=> undef,   # Dont allow gnome-db widgets
    },
    'run_options'   => {
        'name'          => __PACKAGE__,
        'version'       => $VERSION,
        'author'        => $AUTHOR,
        'date'          => $DATE,
        'my_gtk_perl'   => undef,   # Get the version number from Gtk-Perl
                                    # '0.6123'   we have CPAN release 0.6123 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
        'my_gnome_libs' => undef,   # Get the version number from gnome_libs
                                    # '1.0.8'    we have release 1.0.8 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
        'dont_show_UI'  => undef,   # Show UI and wait
    },
    'glade' => {
        'name_from'     => undef,
        'file'          => undef,
        'encoding'      => 'ISO-8859-1',    # Character encoding eg ('ISO-8859-1') 
        'project'       => undef,           # project proto
        'proto'         => undef,           # widget file proto
        'string'        => undef,
    },
    'source'    => {
        'indent'        => '    ',  # Source code indent per Gtk 'nesting'
        'tabwidth'      => 8,       # Replace each 8 spaces with a tab in sources
        'tab'           => '',
        'write'         => undef,   # Dont write source code
        'quick_gen'     => 0,       # 1 = Don't perform any checks
        'save_connect_id'=> 0,      # 1 = generate code to save signal_connect ids
        'hierarchy'     => '',      # Dont generate any hierarchy
                                    # widget... 
                                    #   eg $hier->{'vbox2'}{'table1'}...
                                    # class... startswith class
                                    #   eg $hier->{'GtkVBox'}{'vbox2'}{'GtkTable'}{'table1'}...
                                    # both...  widget and class
        'style'         => 'AUTOLOAD', # Generate code using OO AUTOLOAD code
                                    # Libglade generate libglade code
                                    # closures generate code using closures
                                    # Export   generate non-OO code
        'LANG'          => ($ENV{'LANG'} || ''), 
                                        # Which language we want the source to be in
    },
    'module'    => {
        'sigs'   => {
            'class'         => undef,
            'base'          => undef,
            'file'          => undef,
        },
        'ui'   => {
            'class'         => undef,
            'file'          => undef,
        },
        'app'   => {
            'class'         => undef,
            'base'          => undef,
            'file'          => undef,
        },
        'subapp'   => {
            'class'         => undef,
            'file'          => undef,
        },
        'libglade'   => {
            'class'         => undef,
            'file'          => undef,
        },
        'pot'   => {
            'class'         => undef,
            'file'          => undef,
        },
    },
    'test'  => {
        'name'          => undef,
        'directory'     => undef,
        'first_form'    => undef,
        'use_module'    => undef,
    },
    'dist'  => {
        'write'         => 'True',
        'directory'     => '',
        'Makefile_PL'   => 'Makefile.PL',
        'MANIFEST_SKIP' => 'MANIFEST.SKIP',
        'test_directory'=> 't',
        'test_pl'       => 'test.pl',
        'bin_directory' => 'bin',
        'bin'           => undef,   # name of bin (script) to generate
        'rpm'           => undef,   # Name of RPM to produce
        'spec'          => undef,   # Name of RPM spec file
        'type'          => undef,   # Type of distribution
        'compress'      => undef,   # How to compress the distribution
        'scripts'       => undef,   # Scripts that should be installed
        'docs'          => undef,   # Documentation that should be included
    },
    'doc'   => {
        'write'         => 'True',
        'directory'     => 'Documentation',
        'COPYING'       => 'COPYING',
        'Changelog'     => 'Changelog',
        'FAQ'           => 'FAQ',
        'INSTALL'       => 'INSTALL',
        'NEWS'          => 'NEWS',
        'README'        => 'README',
        'ROADMAP'       => 'ROADMAP',
        'TODO'          => 'TODO',
    },
    'helper' => {
        'editors'       => undef,       # Editor calls that are available
        'active_editor' => undef,       # Index of editor that we are using
    },
);

$convert = {
    'author'               => "\$new->{app}{author}              = \$old->{author}",
    'version'              => "\$new->{app}{version}             = \$old->{version}",
    'date'                 => "\$new->{app}{date}                = \$old->{date}",
    'copying'              => "\$new->{app}{copying}             = \$old->{copying}",
    'description'          => "\$new->{app}{description}         = \$old->{description}",
    'logo'                 => "\$new->{app}{logo}                = \$old->{logo}",
    'use_modules'          => "\$new->{app}{use_modules}         = \$old->{use_modules}",
    'allow_gnome'          => "\$new->{app}{allow_gnome}         = \$old->{allow_gnome}",
    'allow_gnome_db'       => "\$new->{app}{allow_gnome_db}      = \$old->{allow_gnome_db}",

    'glade_encoding'       => "\$new->{glade}{encoding}          = \$old->{glade_encoding}",
    'glade_filename'       => "\$new->{glade}{file}              = \$old->{glade_filename}",
    'xml'                  => "\$new->{glade}{string}            = \$old->{xml}",

    'start_time'           => "\$new->{glade2perl}{start_time}   = \$old->{start_time}",
    'project_options'      => "\$new->{glade2perl}{xml}{project} = \$old->{project_options}",
    'site_options'         => "\$new->{glade2perl}{xml}{site}    = \$old->{site_options}",
    'user_options'         => "\$new->{glade2perl}{xml}{user}    = \$old->{user_options}",
    'options_set'          => "\$new->{glade2perl}{xml}{set_by}  = \$old->{options_set}",
    'glade2perl_encoding'  => "\$new->{glade2perl}{xml}{encoding}= \$old->{glade2perl_encoding}",
    'glade2perl_version'   => "\$new->{glade2perl}{version}      = \$old->{glade2perl_version}",
    'glade2perl_logo'      => "\$new->{glade2perl}{logo}         = \$old->{glade2perl_logo}",
    'dont_show_UI'         => "\$new->{glade2perl}{dont_show_UI} = \$old->{dont_show_UI}",
    'my_perl_gtk'          => "\$new->{glade2perl}{my_gtk_perl}  = \$old->{my_perl_gtk}",
    'my_gnome_libs'        => "\$new->{glade2perl}{my_gnome_libs}= \$old->{my_gnome_libs}",

    'indent'               => "\$new->{source}{indent}           = \$old->{indent};".
                              "\$new->{diag}{indent}             = \$old->{indent};}",
    'tabwidth'             => "\$new->{source}{tabwidth}         = \$old->{tabwidth};".
                              "\$new->{diag}{tabwidth}           = \$new->{source}{tabwidth};}",
    'write_source'         => "\$new->{source}{write}            = \$old->{write_source}",
    'hierarchy'            => "\$new->{source}{hierarchy}        = \$old->{hierarchy}",
    'style'                => "\$new->{source}{style}            = \$old->{style}",
    'source_LANG'          => "\$new->{source}{LANG}             = \$old->{source_LANG}", 

    'verbose'              => "\$new->{diag}{verbose}            = \$old->{verbose}",
    'diag_wrap'            => "\$new->{diag}{wrap_at}            = \$old->{diag_wrap}",
    'autoflush'            => "\$new->{diag}{autoflush}          = \$old->{autoflush}",
    'benchmark'            => "\$new->{diag}{benchmark}          = \$old->{benchmark}",
    'log_file'             => "\$new->{diag}{log}                = \$old->{log_file}",
    'diag_LANG'            => "\$new->{diag}{LANG}               = \$old->{diag_LANG}",

    'dist_type'            => "\$new->{dist}{type}               = \$old->{dist_type}",
    'dist_compress'        => "\$new->{dist}{compress}           = \$old->{dist_compress}",
    'dist_scripts'         => "\$new->{dist}{scripts}            = \$old->{dist_scripts}",
    'dist_docs'            => "\$new->{dist}{docs}               = \$old->{dist_docs}",

    'editors'              => "\$new->{helper}{editors}          = \$old->{editors}",
    'active_editor'        => "\$new->{helper}{active_editor}    = \$old->{active_editor}",
};
}

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#=========== Project utilities                                      ============
#===============================================================================
sub Writing_Source_only  { shift->glade2perl->dont_show_UI }

sub get_versions {
    my ($class) = @_;
    my $type = 'glade2perl';
    # We use the CPAN release date (or CVS date) for version checking
    my $cpan_date = $Glade::PerlUI::gtk_perl_depends->{$Gtk::VERSION};

    # If we dont recognise the version number we use the latest CVS 
    # version that was available at our release date
    $cpan_date ||= $Glade::PerlUI::gtk_perl_depends->{'LATEST_CVS'};

    # If we have a version number rather than CVS date we look it up again
    $cpan_date = $Glade::PerlUI::gtk_perl_depends->{$cpan_date}
        if ($cpan_date < 19000000);

    if ($class->{$type}->my_gtk_perl && 
        ($class->{$type}->my_gtk_perl > $cpan_date)) {
        $Glade_Perl->diag_print (2, "%s- %s reported version %s".
            " but user overrode with version %s",
            $indent, "Gtk-Perl", "$Gtk::VERSION (CVS $cpan_date)",
            $class->{$type}->my_gtk_perl);

    } else {
        $class->{$type}->my_gtk_perl($cpan_date);
        $Glade_Perl->diag_print (2, "%s- %s reported version %s",
            $indent, "Gtk-Perl", "$Gtk::VERSION (CVS $cpan_date)");
    }
    unless ($class->my_gtk_perl_can_do('MINIMUM REQUIREMENTS')) {
        die "You need to upgrade your Gtk-Perl";
    }

    if ($class->app->allow_gnome) {
        my $gnome_libs_version = `gnome-config --version`;
        chomp $gnome_libs_version;
        $gnome_libs_version =~ s/gnome-libs //;
        if ($class->{$type}->my_gnome_libs && 
            ($class->{$type}->my_gnome_libs gt $gnome_libs_version)) {
            $Glade_Perl->diag_print (2, "%s- %s reported version %s".
                " but user overrode with version %s",
                $indent, "gnome-libs", $gnome_libs_version,
                $class->{$type}->my_gnome_libs);
        } else {
            $class->{$type}->my_gnome_libs($gnome_libs_version);
            $Glade_Perl->diag_print (2, "%s- %s reported version %s",
                $indent, "gnome-libs", $gnome_libs_version);
        }
        unless ($class->my_gnome_libs_can_do('MINIMUM REQUIREMENTS')) {
            die "You need to upgrade your gnome-libs";
        }
    }

    return $class;
}

sub use_Glade_Project {
    my ($class, $glade_proto) = @_;
    my $me = (ref $class || $class)."->use_Glade_Project";
    my $type = 'glade2perl';
    
    $Glade_Perl->diag_print(6, $glade_proto->{'project'}, "Input Proto project");

    my $proj_opt = bless {}, (ref $class || $class);

    $proj_opt->{app}{allow_gnome} = ($class->normalise(
        $glade_proto->{'project'}{'gnome_support'} || 'True') == 1);
    $proj_opt->{app}{allow_gnome_db} =($class->normalise(
        $glade_proto->{'project'}{'gnome_db_support'} || 'False') == 1);

    # Remove any spaces, dots or minuses in the project name
    # These are invalid in perl package name
    $glade_proto ->{'project'}{'name'} = 
        $class->fix_name($glade_proto ->{'project'}{'name'});
#    my $replaced = $glade_proto ->{'project'}{'name'} =~ s/[ -\.]//g;
#    if ($replaced) {
#        $Glade_Perl->diag_print(2, "%s- %s Space(s), minus(es) or dot(s) ".
#            "removed from project name - it is now '%s'",
#            $indent, $replaced, $glade_proto->{'project'}{'name'});
#    }
    $proj_opt->{app}{name}  = $glade_proto->{'project'}{'name'};
    $proj_opt->{app}{program}  = $glade_proto->{'project'}{'program_name'};

    # Glade assumes that all directories are named relative to the Glade 
    # project (.glade) file (not <project><directory>) !
    $proj_opt->{glade}{file} = $class->full_Path(
        $Glade_Perl->glade->file, `pwd`);
    $proj_opt->{glade}{start_directory} = dirname($proj_opt->{glade}{file});

    $proj_opt->{glade}{directory} = $class->full_Path(
        $glade_proto->{project}{directory}, 
        $proj_opt->{glade}{start_directory},
        $proj_opt->{glade}{start_directory});

    $proj_opt->{diag}{log} = $class->full_Path(
        $Glade_Perl->diag->log,
        $proj_opt->{glade}{start_directory}
        ) if $Glade_Perl->diag->log and $Glade_Perl->diag->log ne $NOFILE;

    $proj_opt->{$type}{xml}{project} = $class->full_Path(
        $Glade_Perl->{$type}->xml->project,
        `pwd`,
#        $proj_opt->{glade}{directory},
        ) unless $Glade_Perl->{$type}->xml->project eq $NOFILE;

    $proj_opt->{module}{directory} = $class->full_Path(
        ($glade_proto->{project}{source_directory} || './src'),     
        $proj_opt->{glade}{start_directory},
        $proj_opt->{glade}{start_directory} );

    $proj_opt->{glade}{pixmaps_directory} = $class->full_Path(
        ($glade_proto->{'project'}{'pixmaps_directory'} || './pixmaps'),    
        $proj_opt->{glade}{start_directory},
        $proj_opt->{glade}{start_directory} );

    if ($Glade_Perl->Writing_to_File) {
        unless (-d $proj_opt->{module}{directory}) { 
            # Source directory does not exist yet so create it
            $Glade_Perl->diag_print (2, "%s- Creating source_directory '%s' in %s", 
                $indent, $proj_opt->{module}{directory}, $me);
            mkpath($proj_opt->{module}{directory} );
        }

        unless (-d $proj_opt->{glade}{pixmaps_directory}) { 
            # Pixmaps directory does not exist yet so create it
            $Glade_Perl->diag_print (2, "%s- Creating pixmaps_directory '%s' in %s",
                $indent, $proj_opt->{glade}{pixmaps_directory}, $me);
            mkpath($proj_opt->{glade}{pixmaps_directory} );
        }
    }
    
    my $src = $proj_opt->{module}{directory};
    
    $proj_opt->{module}{sigs}{class}        = "$proj_opt->{app}{name}SIGS";
    $proj_opt->{module}{sigs}{base}         = "$src/$proj_opt->{module}{sigs}{class}";
    $proj_opt->{module}{sigs}{file}         = "$proj_opt->{module}{sigs}{base}.pm";

    $proj_opt->{module}{ui}{class}          = "$proj_opt->{app}{name}UI";
    $proj_opt->{module}{ui}{base}           = "$src/$proj_opt->{module}{ui}{class}";
    $proj_opt->{module}{ui}{file}           = "$proj_opt->{module}{ui}{base}.pm";

    $proj_opt->{module}{app}{class}         = "$proj_opt->{app}{name}";
    $proj_opt->{module}{app}{base}          = "$src/$proj_opt->{module}{app}{class}";
    $proj_opt->{module}{app}{file}          = "$proj_opt->{module}{app}{base}.pm";

    $proj_opt->{module}{subapp}{class}      = "Sub$proj_opt->{module}{app}{class}";
    $proj_opt->{module}{subapp}{file}       = "$src/$proj_opt->{module}{subapp}{class}.pm";

    $proj_opt->{module}{libglade}{class}    = "$proj_opt->{app}{name}";
    $proj_opt->{module}{libglade}{file}     = "$src/$proj_opt->{module}{libglade}{class}LIBGLADE.pm";

    $proj_opt->{module}{pot}{file}          = "$src/$proj_opt->{app}{name}.pot";

    $proj_opt->{app}{logo} = $class->full_Path(
        $Glade_Perl->app->logo, 
        $proj_opt->{glade}{'pixmaps_directory'}, 
        '' );

    $proj_opt->{$type}{logo} = $class->full_Path(
        $Glade_Perl->{$type}->logo, 
        $proj_opt->{glade}{pixmaps_directory}, 
        '' );

    unless (-r $proj_opt->{$type}{logo}) {             
        $Glade_Perl->diag_print (2, "%s- Writing our own logo to '%s' in %s",
            $indent, $proj_opt->{$type}{logo}, $me);
        open LOGO, ">$proj_opt->{$type}{logo}" or 
            die sprintf("error %s - can't open file '%s' for output", 
                $me, $proj_opt->{$type}{logo});
        print LOGO $class->our_logo;
        close LOGO or
        die sprintf("error %s - can't close file '%s'", 
            $me, $proj_opt->{$type}{logo});
    }
    
    unless (-r $proj_opt->{app}{logo}) {             
        $Glade_Perl->diag_print (2, "%s- Writing our own logo to '%s' in %s",
            $indent, $proj_opt->{app}{logo}, $me);
        open LOGO, ">$proj_opt->{app}{logo}" or 
            die sprintf("error %s - can't open file '%s' for output", 
                $me, $proj_opt->{app}{logo});
        print LOGO $class->our_logo;
        close LOGO or
        die sprintf("error %s - can't close file '%s'", 
            $me, $proj_opt->{app}{logo});
    }
    
    unless ($proj_opt->{app}{logo} && -r $proj_opt->{app}{logo}) {
        $proj_opt->{app}{logo} = $proj_opt->{$type}{logo};
    }            

    $proj_opt->{dist}{directory} = $class->full_Path(
        $proj_opt->{dist}{directory}, $proj_opt->{glade}{directory});
    
    unless (-d $proj_opt->{dist}{directory}) { 
        # Source directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating distribution '%s' in %s", 
            $indent, $proj_opt->{dist}{directory}, $me);
        mkpath($proj_opt->{dist}{directory} );
    }
    $proj_opt->{dist}{bin_directory} = $class->full_Path(
        ($proj_opt->{dist}{bin_directory} || './bin'),    
        $proj_opt->{dist}{directory},
        $proj_opt->{dist}{directory} );
    unless (-d $proj_opt->{dist}{bin_directory}) { 
        # bin directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s",
            $indent, $proj_opt->{dist}{bin_directory}, $me);
        mkpath($proj_opt->{dist}{bin_directory} );
    }
    $proj_opt->{dist}{bin} = $class->full_Path(
        ($glade_proto->{project}{program_name} || 'run_'.$proj_opt->app->name),
        $proj_opt->{dist}{bin_directory} );

    $proj_opt->{dist}{test_directory} = $class->full_Path(
        ($proj_opt->{dist}{test_directory} || './t'),    
        $proj_opt->{dist}{directory},
        $proj_opt->{dist}{directory} );
    unless (-d $proj_opt->{dist}{test_directory}) { 
        # bin directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s",
            $indent, $proj_opt->{dist}{test_directory}, $me);
        mkpath($proj_opt->{dist}{test_directory} );
    }
    $proj_opt->{dist}{test_pl} = $class->full_Path(
        ($proj_opt->{dist}{test_pl} || './01.t'),    
        $proj_opt->{dist}{test_directory} );

    if ($Glade_Perl->app->author) {
        $proj_opt->{app}{author} = $Glade_Perl->app->author;
    } else {
        my $host = hostname;
        my $pwuid = [(getpwuid($<))];
        my $user = $pwuid->[0];
        my $fullname = $pwuid->[6];
        my $hostname = [split(" ", $host)];
        $proj_opt->{app}{'author'} = "$fullname <$user\@$hostname->[0]>";
    }
    # Remove trailing spaces and ensure only one leading '#'
    $Glade_Perl->{app}{copying} =~ s/ *$//;
    if ($Glade_Perl->app->copying !~ /^#/) {
        $Glade_Perl->app->copying("#".$Glade_Perl->app->copying);
    }
    # escape any quotes
    $proj_opt->{app}{'author'} =~ s/\"/\\\"/g;
    $proj_opt->{app}{'author'} =~ s/\'/\\\'/g;

    $proj_opt->{app}{'version'}      ||= $Glade_Perl->app->version;
    $proj_opt->{app}{'date'}         ||= $Glade_Perl->app->date || $Glade_Perl->{$type}->start_time;
    $proj_opt->{app}{'copying'}      ||= $Glade_Perl->app->copying;
    $proj_opt->{app}{'description'}  ||= $Glade_Perl->app->description || 'No description';
    $proj_opt->{$type}->{xml}->{set_by}=($me);

    # Now change to the <project><directory> so that we can find modules
    chdir $proj_opt->{glade}{directory};

    $Glade_Perl->diag_print(6, $proj_opt);
    return $proj_opt;
}

1;

__END__
