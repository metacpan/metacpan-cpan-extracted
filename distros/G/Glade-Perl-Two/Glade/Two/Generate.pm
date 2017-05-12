package Glade::Two::Generate;
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
    use Exporter            qw ();
    use Carp                qw(cluck);
        $SIG{__DIE__}  = \&Carp::confess;
        $SIG{__WARN__} = \&Carp::cluck;
    use Data::Dumper;
    use XML::Parser;
    use File::Path          qw( mkpath);           # in use_Glade_Project
    use File::Basename      qw( basename dirname); # in use_Glade_Project
    use Cwd                 qw( chdir cwd);        # in use_Glade_Project
    use Sys::Hostname       qw( hostname);         # in use_Glade_Project
    use Glade::Two::App     qw(:VARS :METHODS);
    use Glade::Two::Source  qw(:VARS :METHODS);    # Source writing vars and methods
    use Glade::Two::Gtk     qw( :VARS);
    use Glade::Two::Gnome;

    use Gtk2                qw( );                 # Everywhere
    use vars                qw(
                                @ISA 
                                $AUTOLOAD
                                $PACKAGE $VERSION $AUTHOR $DATE
                                @EXPORT @EXPORT_OK %EXPORT_TAGS 
                                @VARS @METHODS

                                $ALL $CHILD $WIDGET $NOTE
                                $DEPRECATED $CONVERT_TO
                                $OBSOLETE $BROKEN $REMOVED

                                %app_fields
                                %stubs
                                $new
                                $seq
                                $changes

                                $gnome_libs_depends
                                $gtk_perl_depends
                                $gtk_perl_cant_do
                           );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.01);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 06:02:01 GMT 2002 );

    # Tell interpreter who we are inheriting from
    @ISA            = qw( 
                            Exporter
                            Glade::Two::App
                            Glade::Two::Source
                            Glade::Two::Gtk 
                            Glade::Two::Gnome
                       );
    @METHODS =          qw( );
    @VARS =             qw(
                            $gnome_libs_depends
                            $gtk_perl_depends
                            $gtk_perl_cant_do
                           );

    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS);
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                   );
#===============================================================================
#=========== Constants and globals  
#===============================================================================
%stubs = ();

    $ALL        = '__ALL';
    $CHILD      = '__CHILD';
    $WIDGET     = '__WIDGET';
    $NOTE       = '__NOTE';         # Report note
    $DEPRECATED = '__DEPRECATED';   # Report and convert if poss
    $CONVERT_TO = '__CONVERT_TO',   # Convert widget
    $OBSOLETE   = '__OBSOLETE';     # Report and convert if poss
    $BROKEN     = '__BROKEN';       # Report and remove
    $REMOVED    = '__REMOVED';      # Report and remove

    $USES               = '__USES';
    $DATA               = '__DATA';
    $IGNORED_WIDGET    = '__IGNORED_WIDGET';
    $NO_SUCH_WIDGET     = '__NO_SUCH_WIDGET';
    $INTERNAL_CHILD     = '__INTERNAL_CHILD';
    $UNUSED_PROPERTIES  = '__UNUSED_PROPERTIES';
    $FIRST_PANE_FULL    = '__FIRST_PANE_FULL';
    $CONNECT_ID         = '__CONNECT_ID';
    $MISSING_METHODS    = '__MISSING_METHODS';
    $WIDGET_INSTANCE    = '__WIDGET_INSTANCE';
    $HANDLERS           = '__HANDLERS';
    
$gnome_libs_depends     = { 
    'MINIMUM REQUIREMENTS'  => '1.2.0',
    };

$gtk_perl_depends       = { 
    'MINIMUM REQUIREMENTS'  => '0.01',
    'LATEST_CPAN'           => '0.01',
    'LATEST_CVS'            => '20021116',
    
    '0.01'                  => '20021116',

    # Those below don't work yet even in the latest CVS version
    'GnomeDbGrid'           => '99999999',
    'GnomeDbList'           => '99999999',
    'GnomeDbCombo'          => '99999999',
    'GnomeDbReport'         => '99999999',
    'GnomeDbError'          => '99999999',
    'GnomeDbLogin'          => '99999999',
    'GnomeDbBrowser'        => '99999999',
    'GnomeDbErrorDlg'       => '99999999',
    'GnomeDbLoginDlg'       => '99999999',

    };

$gtk_perl_cant_do       = { 
    # Those below will NOT work in specific version mentioned
};

%app_fields = (
    'type'  => 'glade2perl-2',
    'widgets'   => {
        'underlineable' => " ".
            join(" ", (
                'GtkLabel', 
                'GtkButton', 
                'GtkMenuItem')
               )." ",
        'to_ignore'     => join (' ', 
            'Placeholder',
            'Custom',
           ),
        'ignored'       => 0,
        'missing'       => 0,
        'gnome'         => join( " ",
            'GnomeAbout',
            'GnomeApp',
            'GnomeAppBar',
            'GnomeCalculator',
            'GnomeColorPicker',
            'GnomeDateEdit',
            'GnomeDialog',
            'GnomeDock',
            'GnomeDockItem',
            'GnomeDruid',
            'GnomeDruidPageFinish',
            'GnomeDruidPageStandard',
            'GnomeDruidPageStart',
            'GnomeEntry',
            'GnomeFileEntry',
            'GnomeFontPicker',
            'GnomeHRef',
            'GnomeIconEntry',
            'GnomeIconList',
            'GnomeIconSelection',
            'GnomeLess',
            'GnomeMessageBox',
            'GnomeNumberEntry',
            'GnomePaperSelector',
            'GnomePixmap',
            'GnomePixmapEntry',
            'GnomePropertyBox',
            'GnomeSpell',
#            'GtkCalendar',          # In Gtk after CVS-19990914
            'GtkClock',
            'GtkDial',
            'GtkPixmapMenuItem',
           ),
        'gnome_db'      => join( " ",
            'GnomeDbGrid',
            'GnomeDbList',
            'GnomeDbCombo',
            'GnomeDbReport',
            'GnomeDbError',
            'GnomeDbLogin',
            'GnomeDbBrowser',
            'GnomeDbErrorDlg',
            'GnomeDbLoginDlg',
       ),
        'concept'       => '',
        'composite'     => join(' ',
            'Gnome::Entry',
            'Gnome::FileEntry',
            'Gnome::NumberEntry',
            'Gnome::PixmapEntry',
            'Gtk2::Combo',
           ),
        'dialogs'       => join(' ',
            'Gnome2::About',
            'Gnome2::App',
            'Gnome2::Dialog',
            'Gnome2::MessageBox',
            'Gnome2::PropertyBox',
            'Gtk2::ColorSelectionDialog',
            'Gtk2::Dialog',
            'Gtk2::FileSelection',
            'Gtk2::FontSelectionDialog',
            'Gtk2::InputDialog',
           ),
        'toplevel'      => join(' ',
            'Gnome2::About',
            'Gnome2::App',
            'Gnome2::Dialog',
            'Gnome2::MessageBox',
            'Gnome2::PropertyBox',
            'Gtk2::Dialog',
            'Gtk2::InputDialog',
            'Gtk2::Window',
           ),
        },
    'properties'    => {
        'unhandled'     => 0,
        'translatable_properties'   => " ".
            join(" ", ( 
                'label', 
                'title', 
                'text', 
                'format', 
                'copyright', 
                'comments',
                'preview_text', 
                'tooltip')
               )." ",
        'cxx'           => join(' ',
            'cxx_separate_class',
            'cxx_separate_file',
            'cxx_use_heap',
            'cxx_visibility',
           ),
        },
    'app'   => {
        'use_modules'   => undef,   # Existing signal handler modules
        'allow_gnome'   => undef,   # Dont allow gnome widgets
        'allow_gnome_db'=> undef,   # Dont allow gnome-db widgets
        'gtk2'          => undef,   # Don't use new gtk2
    },
    'run_options'   => {
        'name'          => __PACKAGE__,
        'version'       => $VERSION,
        'author'        => $AUTHOR,
        'date'          => $DATE,
        'my_gtk_perl'   => undef,   # Get the version number from Gtk2-Perl
                                    # '0.6123'   we have CPAN release 0.6123 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
        'my_gtk'        => undef,   # Get the version number from Gtk
                                    # '1.2.10'   we have release 1.2.10 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
        'my_gnome_libs' => undef,   # Get the version number from gnome_libs
                                    # '1.0.8'    we have release 1.0.8 (or equivalent)
                                    # '19990901' we have CVS version of 1st Sep 1999
        'dont_show_UI'  => undef,   # Show UI and wait
        'my_gnome_incs' => undef,   # Where the gnome include files are
        'prune' => "*". join("*", 
                $permitted_fields, 
                'proto',
                'project',
                'widgets',
                'properties',
                'run_options', 
                'module', 
                'generate',
                'prune',
               ).
            "*",
    },
    'glade' => {
        'name_from'     => undef,
        'file'          => undef,
        'filep'         => undef,
        'encoding'      => 'ISO-8859-1',    # Character encoding eg ('ISO-8859-1') 
        'version'       => undef,           # Version of Glade that made file
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
        'with_errors'   => undef,   # 1 = Write source code regardless of errors
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
        'gtk'       => {},
        'sigs'      => {
            'class'         => undef,
            'base'          => undef,
            'file'          => undef,
        },
        'ui'        => {
            'class'         => undef,
            'file'          => undef,
        },
        'app'       => {
            'class'         => undef,
            'base'          => undef,
            'file'          => undef,
        },
        'subapp'    => {
            'class'         => undef,
            'file'          => undef,
        },
        'libglade'  => {
            'class'         => undef,
            'file'          => undef,
        },
        'onefile'   => {
            'class'         => undef,
            'file'          => undef,
        },
        'pot'       => {
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

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

sub AUTOLOAD {
  my $self = shift;
  my $class = ref($self)
      or die "$self is not an object so we cannot '$AUTOLOAD'\n",
          "We were called from ".join(", ", caller),"\n\n";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;       # strip fully-qualified portion

  if (exists $self->{$permitted_fields}->{$name}) {
    # This allows dynamic data methods - see %fields above
    # eg $class->UI('new_value');
    # or $current_value = $class->UI;
    if (@_) {
      return $self->{$name} = shift;
    } else {
      return $self->{$name};
    }

  } elsif (exists $stubs{$name}) {
    # This shows dynamic signal handler stub message_box - see %stubs above
    __PACKAGE__->show_skeleton_message(
      $AUTOLOAD."\n ("._("AUTOLOADED by")." ".__PACKAGE__.")", 
      [$self, @_], 
      __PACKAGE__, 
      'pixmaps/Logo.xpm');
    
  } elsif ($name ne 'DESTROY'){
    die "Can't access method `$name' in class $class\n",
        "We were called from ",join(", ", caller),"\n\n";

  }
}

#===============================================================================
#=========== Generate the code
#===============================================================================
sub new_generator {
    my ($class, %params) = @_;
    my $me = (ref $class||$class)."->new";
    return bless $class->get_app_options(%params), $class;
}

sub generate {
    my ($class, %params) = @_;
    my $me = (ref $class||$class)."->generate";

    my ($encoding, $project, $tree);
    $Glade_Perl->diag->log($Glade_Perl->glade->file."2perl.log")
        if $Glade_Perl->diag->log eq '1';

    # Start diagnostics
    $Glade_Perl->start_log;

    $Glade_Perl->Write_to_File;
    $Glade_Perl->get_versions;

    $Glade_Perl->glade->encoding($Glade_Perl->glade->encoding || 'ISO-8859-1');
#print Dumper($Glade_Perl);
    my $xml = $class->string_from_file($Glade_Perl->glade->file);

    ($encoding, $tree) = 
        $class->tree_from_string($xml, $Glade_Perl->glade->encoding);

    $Glade_Perl->glade->encoding($encoding);
    if ($tree->[0] eq 'GTK-Interface') {
        $Glade_Perl->glade->version('064');

    } elsif ($tree->[0] eq 'glade-interface') {
        $Glade_Perl->glade->version('110');
        
    } else {
        $Glade_Perl->glade->version('110');
    }
    $Glade_Perl->diag_print (2, "%s- %s reported version %s",
        $indent, "Glade file ".$Glade_Perl->glade->file, $Glade_Perl->glade->version);
#print Dumper($Glade_Perl->glade);        
    $Glade_Perl->glade->proto(
        $class->proto_from_tree(
            $tree->[1], 
            0, 
            ' accelerator signal child',             # store in array
            ' property ',                        # store in hash
            ' widget child signal packing ',            # special
            $Glade_Perl->glade->encoding));

    ($encoding, $project) = $Glade_Perl->get_glade_project();
    $class->merge_into_hash_from( 
        $Glade_Perl, 
        $project,
        "Glade project file ".$Glade_Perl->glade->filep);
    $class->merge_into_hash_from( 
        $Glade_Perl, 
        $Glade_Perl->get_project_options($Glade_Perl),
        "Glade interface file ".$Glade_Perl->glade->file);

#print $class->string_from_proto('', '  ', 'Gtk-Interface', undef, $Glade_Perl->glade->proto);
#$Glade_Perl->diag_print(1, $Glade_Perl->glade->proto->{'project'});
#$Glade_Perl->diag_print(1, $Glade_Perl->glade->{'project'});
    # Recursively generate the UI
    $class->pre_generate_from_proto( $Glade_Perl);
    my $window = $class->generate_from_proto( 
        $Glade_Perl->glade->proto->{'name'}, 
        $Glade_Perl->glade->proto->{'form'}, 0);
    $class->post_generate_from_proto( $Glade_Perl);

    $Glade_Perl->diag_print(4, $Glade::Two::Gtk2::enums);
    $Glade_Perl->diag_print(4, $Glade::Two::Gnome::enums);
#print Dumper($Glade_Perl);
    $Glade_Perl->save_app_options($Glade_Perl->glade->file);
        
    $Glade_Perl->stop_log();

    return $window;
}

sub convert {
    # signal - name, handler, object, after
    # accelerator - key, modifiers, signal
    #   $key =~ s/^GDK_//
    # internal-child add attr ' internal-child="$internal-child"'
    # property name startswith 'cxx' add attr ' agent=glademm'
    # If in $translatable_properties
    #   unless has prop 'use_stock' add attr ' translatable="yes"'
    
}

sub reverse_changes {
    my ($class, $changes) = @_;
    my ($self, $key, $work);
    foreach $key (keys %{$changes}) {
        if (" $OBSOLETE $REMOVED $BROKEN $CONVERT_TO " =~ / $changes->{$key} /) {
            next;
            
        } elsif (" $CONVERT_TO " =~ / $key /) {
            next;

        } elsif (" $WIDGET " =~ / $key /) {
            $self->{$key} = $changes->{$key};
            
        } elsif (ref $changes->{$key} eq 'HASH') {
            if ($changes->{$key}{$CONVERT_TO}) {
                $self->{$changes->{$key}{$CONVERT_TO}} = 
                    {$CONVERT_TO => $key};
            }
            $work = $class->reverse_changes($changes->{$key});
            $self->{$key} = $work if keys %{$work}
                
        } else {
            $self->{$changes->{$key}} = $key;
        }
    }
    return $self;
}
#===============================================================================
#=========== Utilities to read XML and build the proto
#===============================================================================
sub get_glade_project {
    my ($class) =@_;
    my $me = (ref $class||$class)."->get_glade_project";
    my $project = {};
    my $file = $class->glade->filep;
    my ($encoding);
    if ($file && -r $file) {
        ($encoding, $project) = $class->simple_Proto_from_File(
            $class->glade->filep, 
            '', 'glade-project', 
            $class->glade->encoding);
        $class->glade->encoding($encoding);

    } else {
#        print "File '$file' could NOT be read\n";
        $project = {};
    }

    return ($encoding, {'glade'=>{'project'=>$project}});
}

sub get_app_options {
    my ($class, %params) = @_;
    my $me = (ref $class||$class)."->get_app_options";
#print Dumper(\@_);
    my $type = 'glade2perl-2';
    if (ref $Glade_Perl) {
        # We have already called options() at least once somehow
        $Glade_Perl->merge_into_hash_from(
            $Glade_Perl, 
            $class->convert_old_options(\%params), 
            $me);
        
    } else {
        $class->SUPER::options(%params,
            'options_I18N_name' => 'Glade-Perl-Two',
            'options_defaults'  => \%Glade::Two::Generate::app_fields,
            'options_key'       => $Glade::Two::Generate::app_fields{type},
            'options_global'    => "\$Glade_Perl",
#            'options_report'    => '$Glade_Perl->{app}{use_modules}',
       );
    }
    # Construct file names if Glade filename is not supplied
    if ($Glade_Perl->glade->file eq $NOFILE) {
        $Glade_Perl->glade->file($Glade_Perl->{$Glade_Perl->type}->mru) ;
        $Glade_Perl->glade->name_from("MRU Glade file in user options file");

    } elsif ($Glade_Perl->glade->file) {
        $Glade_Perl->glade->name_from("Specified as arg to $me");

    } else {
        $Glade_Perl->glade->file(
            $Glade_Perl->{$Glade_Perl->type}->proto->project->{glade}{file}
       );
        $Glade_Perl->glade->name_from("Specified in project options file");
    }
    $Glade_Perl->glade->filep(
        $Glade_Perl->glade->filep || $Glade_Perl->glade->file."p");
    
    # Find out what versions of software we have
    unless ($Glade_Perl->{$type}->my_gtk_perl &&
            ($Glade_Perl->{$type}->my_gtk_perl > $Gtk2::VERSION)) {
        $Glade_Perl->{$type}->my_gtk_perl($Gtk2::VERSION);
    }
    if ( $Glade_Perl->{$type}->dont_show_UI && !$Glade_Perl->source->write) {
        die "$me - Much as I like an easy life, please alter options ".
            "to, at least, show_UI or write_source\n    Run abandoned";
    }
    $indent = $Glade_Perl->source->indent; 
    $tab = (' ' x $Glade_Perl->source->tabwidth);
    $Glade_Perl->source->tab($tab);

    return $Glade_Perl;
}

sub get_project_options {
    my ($class, $proto) = @_;
    my $me = (ref $class || $class)."->get_project_options";
    my $type = 'glade2perl-2';
    
    $Glade_Perl->diag_print(6, $proto, "Input Proto project");
 
    my $proj_opt = bless {}, (ref $class || $class);

#print Dumper($proto->{app});
#print Dumper($Glade_Perl->{app});
#print Dumper($proj_opt->{app});
    $proj_opt->{app}{allow_gnome} = ($class->normalise(
        $proto->{'gnome_support'} &&
        $proto->{'gnome_support'} || 'False') == 1);
    $proj_opt->{app}{allow_gnome_db} =($class->normalise(
        $proto->{'gnome_db_support'} &&
        $proto->{'gnome_db_support'} || 'False') == 1);

    # Remove any spaces, dots or minuses in the project name
    $proj_opt->{app}{name}  ||= 
        $class->fix_name($proto->{glade}{project}{'name'});

    # Glade assumes that all directories are named relative to the Glade 
    # project (.glade) file (not <project><directory>) !
    $proj_opt->{glade}{file} = $class->full_Path(
        $Glade_Perl->glade->file, `pwd`);
    $proj_opt->{glade}{start_directory} = dirname($proj_opt->{glade}{file});
    $proj_opt->{glade}{filep} = $class->full_Path(
        $Glade_Perl->glade->filep, $proj_opt->{glade}{start_directory});

    $proj_opt->{glade}{directory} = $class->full_Path(
        $proto->{directory}, 
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
        ($proto->{source_directory} || './src'),     
        $proj_opt->{glade}{start_directory},
        $proj_opt->{glade}{start_directory});

    $proj_opt->{glade}{pixmaps_directory} = $class->full_Path(
        ($proto->{'pixmaps_directory'} || './pixmaps'),    
        $proj_opt->{glade}{start_directory},
        $proj_opt->{glade}{start_directory});

    if ($Glade_Perl->Writing_to_File) {
        unless (-d $proj_opt->{module}{directory}) { 
            # Source directory does not exist yet so create it
            $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s", 
                $indent, $proj_opt->{module}{directory}, $me);
            mkpath($proj_opt->{module}{directory});
        }

        unless (-d $proj_opt->{glade}{pixmaps_directory}) { 
            # Pixmaps directory does not exist yet so create it
            $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s",
                $indent, $proj_opt->{glade}{pixmaps_directory}, $me);
            mkpath($proj_opt->{glade}{pixmaps_directory});
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

    $proj_opt->{module}{onefile}{class}    = "$proj_opt->{app}{name}";
    $proj_opt->{module}{onefile}{file}     = "$src/$proj_opt->{module}{onefile}{class}ONEFILE.pm";

    $proj_opt->{module}{pot}{file}          = "$src/$proj_opt->{app}{name}.pot";

    $proj_opt->{app}{logo} = $class->full_Path(
        $Glade_Perl->app->logo, 
        $proj_opt->{glade}{'pixmaps_directory'}, 
        '');

    $proj_opt->{$type}{logo} = $class->full_Path(
        $Glade_Perl->{$type}->logo, 
        $proj_opt->{glade}{pixmaps_directory}, 
        '');

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

    $proj_opt->{doc}{directory} = $class->full_Path(
        $proj_opt->{doc}{directory} || 'Documentation', 
        $proj_opt->{glade}{directory});
    
    unless (-d $proj_opt->{doc}{directory}) { 
        # Source directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s", 
            $indent, $proj_opt->{doc}{directory}, $me);
        mkpath($proj_opt->{doc}{directory});
    }
    $proj_opt->{dist}{directory} = $class->full_Path(
        $proj_opt->{dist}{directory}, 
        $proj_opt->{glade}{directory});
    
    unless (-d $proj_opt->{dist}{directory}) { 
        # Source directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s", 
            $indent, $proj_opt->{dist}{directory}, $me);
        mkpath($proj_opt->{dist}{directory});
    }
    $proj_opt->{dist}{bin_directory} = $class->full_Path(
        ($proj_opt->{dist}{bin_directory} || './bin'),    
        $proj_opt->{dist}{directory},
        $proj_opt->{dist}{directory});
    unless (-d $proj_opt->{dist}{bin_directory}) { 
        # bin directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s",
            $indent, $proj_opt->{dist}{bin_directory}, $me);
        mkpath($proj_opt->{dist}{bin_directory});
    }
    $proj_opt->{dist}{bin} = $class->full_Path(
        ($proto->{glade}{project}{program_name} || 'run_'.$proj_opt->{app}{name}),
        $proj_opt->{dist}{bin_directory});

    $proj_opt->{dist}{test_directory} = $class->full_Path(
        ($proj_opt->{dist}{test_directory} || './t'),    
        $proj_opt->{dist}{directory},
        $proj_opt->{dist}{directory});
    unless (-d $proj_opt->{dist}{test_directory}) { 
        # bin directory does not exist yet so create it
        $Glade_Perl->diag_print (2, "%s- Creating directory '%s' in %s",
            $indent, $proj_opt->{dist}{test_directory}, $me);
        mkpath($proj_opt->{dist}{test_directory});
    }
    $proj_opt->{dist}{test_pl} = $class->full_Path(
        ($proj_opt->{dist}{test_pl} || './001_use_new.t'),    
        $proj_opt->{dist}{test_directory});

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
    $proj_opt->{app}{'use_modules'}  ||= $Glade_Perl->app->use_modules;

    $proj_opt->{app}{use_modules} =
        [split (/\n/, ($proj_opt->{app}{use_modules} || ''))]
            unless ref $proj_opt->{app}{use_modules} eq 'ARRAY';
#print Dumper($proto->{app});
#print Dumper($Glade_Perl->{app});
#print Dumper($proj_opt->{app});
    # Now change to the <project><directory> so that we can find modules
    chdir $proj_opt->{glade}{directory};

    $Glade_Perl->diag_print(6, $proj_opt);
    return $proj_opt;
}

sub tree_from_string {
    my ($class, $xml, $encoding) = @_;
    my $me = (ref $class || $class)."->tree_from_string";
    my $xml_encoding;
    if ($xml =~ s/\<\?xml.*\s*encoding\=["'](.*?)['"]\s*\?\>\n*//) {
        $xml_encoding = $1;
    } else {
        $xml_encoding = $encoding;
    }
    print "    - Actual encoding found is '$xml_encoding'\n" 
        if $encoding ne $xml_encoding;
        
    my $tree = new XML::Parser(
        Style =>'Tree', 
        ProtocolEncoding => $xml_encoding,
        ErrorContext => 2)->parse($xml);
    return ($xml_encoding, $tree);
}

sub proto_from_tree {
    my ($class, $tree, $depth, $array, $hash, $special, $encoding) = @_;
    my $me = (ref $class||$class)."->proto_from_tree";

# FIXME make this general for all encodings
    if ($encoding && ($encoding eq 'ISO-8859-1')) {
        eval "use Unicode::String qw(utf8 latin1)";
        undef $encoding if $@;  # We can't use encodings correctly
    } else {
        undef $encoding;        # We don't recognise the encodings name
    }
    my ($tk, $i, $ilimit);
    my ($count, $np, $work, $type, $value, $attr_hash, $propkey);
    my $limit = scalar(@$tree);
    my $child;
    $np = $tree->[0] if keys %{$tree->[0]};
    for ($count = 3; $count < $limit; $count += 4) {
        $ilimit = scalar @{$tree->[$count+1]};
        $type       = $tree->[$count];
        $attr_hash  = $tree->[$count+1][0];
        $value      = $tree->[$count+1][2];
# FIXME make this general for all encodings
        if (defined $value && $encoding && ($encoding eq 'ISO-8859-1')) {
            $value = &utf8($value)->latin1;
        }
#        $value = $tree->[$count+1][2];
        if (" $array " =~ / $type /) {
            push @{$np->{$type}}, 
                $class->proto_from_tree(
                    $tree->[$count + 1], $depth+1, 
                    $array, $hash, $special, $encoding);
            
        } elsif (" $hash " =~ / $type /) {
            if ($ilimit <= 3)  {
                # We have a bottom level element (property) to add
                $propkey = $attr_hash->{'name'};
                $work =  $attr_hash,
                delete $work->{'name'};
                $work->{'value'} = $value;
#                delete $attr_hash->{'name'};
                $np->{$type}{$propkey} = $work;
#                push(@{$np->{'property'}}, $work);

            } else {
                # We have some sub element(s) 
                # so call ourself to expand nested xml
#                $np->{$type} =  $class->proto_from_tree(
                $work =  $class->proto_from_tree(
                    $tree->[$count + 1], $depth+1, 
                    $array, $hash, $special, $encoding);
                push @{$np->{'widget'}{'child'}}, $work;
            }

        } elsif (" $special " =~ / $type /) {
            # this is a special object (eg <widget>) that is stored
            # differently depending on whether it is toplevel or not
            # This is because the glade-2 structure is inconsistent.
            if ($depth) {
                # Usual type of widget so stored as hash
                $np->{$type} = $class->proto_from_tree(
                    $tree->[$count + 1], $depth+1, 
                    $array, $hash, $special, $encoding);

            } else {
                # Toplevel widget so push to 'form' super-element
                push @{$np->{'form'}}, {
                    $type => $class->proto_from_tree(
                        $tree->[$count + 1], $depth+1, 
                        $array, $hash, $special, $encoding)
                    };
            }
        } elsif ($ilimit == 1) {
            # this is an empty (nul string) element
            $np->{$type} = '';

        } else {
            print "We found a '$type' element - it has not been stored\n";
        }
    }
#    $depth--;
    return $np;
}

#===============================================================================
#=========== Utilities to construct the form from a Proto                   ====
#===============================================================================
sub pre_generate_from_proto {
    my ($class, $proto) = @_;
    my $me = (ref $class||$class)."->pre_generate_from_proto";

    $Glade_Perl->diag_print(7, $Glade_Perl->glade->proto);

    my ($module);
    my $options = $proto;
    $indent ||= ' ';
    $forms = {};
    $widgets = {};
    $current_form && eval "$current_form = {};";

    $Glade_Perl->diag_print (2, "%s- Constructing form(s) from Glade file '%s' - %s",
                $indent, $proto->glade->file, $proto->glade->name_from);
    $Glade::Two::Run::pixmaps_directory = $class->glade->pixmaps_directory;

    foreach $module (@{$proto->app->use_modules}) {
        if ($module && $module ne '') {
            eval "use $module;" or
                ($@ && 
                    die  "\n\nin $me\n\t".("while trying to eval").
                        " 'use $module'".
                         "\n\t".("FAILED with Eval error")." '$@'\n");
            push @use_modules, $module;
            $Glade_Perl->diag_print (2, 
                "%s- Use()ing existing module '%s' in %s",
                $indent, $module, $me);
        }
    }

    if ($options->app->allow_gnome) {
        $Glade_Perl->diag_print (6, "%s- Use()ing Gnome2 in %s", $indent, $me);
        eval "use Gnome2;";
        unless (Gnome::Stock->can('pixmap_widget')) {
            $Glade_Perl->diag_print (1, 
                "%s- You need either to build the Gtk2-Perl Gnome2 module or ".
                "uncheck the Glade 'Enable Gnome Support' project option",
                $options->diag->indent);
            $Glade_Perl->diag_print (1, 
                "%s- Continuing without Gnome2 for now although ".
                "the generate run will fail if there are any Gnome2 widgets ".
                "specified in your project",
                $options->diag->indent);
            $options->app->allow_gnome(0);
        }
        Gnome2->init(__PACKAGE__, $VERSION);
    } else {
        Gtk2->init;
    }
    unless ($proto->app->allow_gnome) {
        $proto->widgets->to_ignore(
            $proto->widgets->to_ignore." ".
            $proto->widgets->gnome);
    }
    unless ($proto->app->allow_gnome_db) {
        $proto->widgets->to_ignore(
            $proto->widgets->to_ignore." ".
            $proto->widgets->gnome_db);
    }
}

sub generate_from_proto {
    my ($class, $parentname, $proto, $depth, $awh, $ach) = @_;
    my $me = (ref $class || $class)."->generate_from_proto";
    my ($name, $childname, $window, $sig);
    my ($key, $dm, $expr, $object, $packing, $item, $sig_string, @sig_strings);
    $parentname ||= "Top level application";
    my ($wh, $ch);# = ($awh, $ach);
    $class->diag_print(7, $proto);
    if (ref $proto eq 'ARRAY') {
        foreach my $child (@{$proto}) {
            # Construct child widget
            $child->{'widget'}{name} = $child->{'widget'}{id};
            ($wh, $ch) = $class->process_widget(
                $parentname, $child, $depth+1, $awh, $ach);

            # Call ourself to recurse through child's children widgets
            $class->generate_from_proto(
                $child->{'widget'}{'name'}, 
                $child->{'widget'}{'child'}, $depth+1, $wh, $ch);
            $class->add_to_UI($depth+1,  "# ".S_("End of").
                " $child->{'widget'}{class} '$child->{'widget'}{'name'}'");
            $class->add_to_UI($depth+1,  "#");
        }
    }
    if ($depth == 1) {
        # We are a toplevel window so now connect all accel_labels
#        eval "print Dumper(\\\@{${current_form}\{Accel_Strings}})";
        eval "\@sig_strings = \@{${current_form}\{Accel_Strings}}";
        if (scalar(@sig_strings)) {
            $class->load_class("Gtk2::AccelLabel");
            # We have some accel_labels to connect
            $class->add_to_UI($depth,  "#");
            $class->add_to_UI($depth,  
                "# ".S_("Connect all accel_labels now that widgets are constructed"));
            foreach $sig_string (@sig_strings) {
                eval $sig_string;
            }
        }
        # Now connect all signals
#        eval "print Dumper(\\\@{${current_form}\{Signal_Strings}})";
        eval "\@sig_strings = \@{${current_form}\{Signal_Strings}}";
        if (scalar(@sig_strings)) {
            $class->load_class("Gtk2::GSignal");
            # We have some signals to connect
            $class->add_to_UI($depth,  "#");
            $class->add_to_UI($depth,  
                "# ".S_("Connect all signals now that widgets are constructed"));
            foreach $sig_string (@sig_strings) {
                eval $sig_string;
            }
        }
    }
    return ($wh, $ch);
}

sub load_class {
    my ($class, $module) = @_;
    my $expr = "use $module";
    $current_widget = $module;
    eval $expr ||
        $@ && $class->log_error($expr, $@);

    eval "${current_form}\{$USES}{'$module'}++";
}

sub add_placeholder_label {
    my ($class, $widget, $childname, $parentname, $depth) = @_;
    my $message = sprintf(S_("PH for \\\'%s\\\'"), $childname);

    $class->add_to_UI($depth, 
        "${current_form}\{'$childname'} = ".
            "new Gtk2::Label(_('$message'));");
#    $class->add_to_UI($depth, 
#        "${current_form}\{'$childname'}->set_line_wrap(1);");
    $class->add_to_UI($depth, 
        "${current_form}\{'$childname'}->show;");
    $class->add_to_UI($depth, 
        "${current_form}\{'$parentname'}->add(${current_form}\{'$childname'});");
}

sub process_widget {
    my ($class, $parentname, $proto, $depth, $awh, $ach) = @_;
    my $me = (ref $class || $class)."->process_widget";
    my ($wh, $ch);# = ($awh, $ach);
    $class->diag_print(8, $Glade_Perl);
    if ($class->my_gtk_perl_can_do($proto->{'widget'}{'class'})) {
        unless (" $Glade_Perl->{'widgets'}{'to_ignore'} " =~ / $proto->{'widget'}{'class'} /) {
            # This is a real widget subhash so recurse to expand
            ($wh, $ch) = $class->new_widget(
                $parentname, $proto, $depth, $awh, $ach);

#            $class->set_child_packing(
#                $parentname, $proto->{'widget'}{'name'}, $proto, $depth);
            if ($Glade_Perl->diagnostics) {
                # Check that we have used all widget properties
                $class->check_for_unused_properties($proto->{'widget'});
                $class->check_for_unused_packing_properties(
                    $proto->{'packing'}, $proto->{'widget'}{'name'});
            }

        } else {
            unless (" $Glade_Perl->{'widgets'}{'gnome'} " =~ / $proto->{'widget'}{'class'} /) {
                $Glade_Perl->diag_print(3, 
                    "warn  %s in %s ignored in %s", 
                    $proto->{'widget'}{'class'}, $parentname, $me);
            } else {
                $Glade_Perl->diag_print(1, "error %s in %s ignored in %s", 
                "$proto->{'widget'}{'class'} ($proto->{'widget'}{'name'}) and ".
                    "any child widgets", ($parentname || 'Glade project'), $me);
                undef $proto->{'widget'}{'child'};
            }
            $failures->{$IGNORED_WIDGET}{$proto->{'widget'}{'class'}}++;
            $class->add_placeholder_label($proto->{'widget'}{'class'}, 
                $proto->{'widget'}{'name'}, $parentname, $depth);
        }
    } else {
        undef $proto->{'widget'}{'child'};
            my $widget = $proto->{'widget'}{'class'};
            $widget =~ s/^Gtk/Gtk2::/;
#            $failures->{$widget}{$NO_SUCH_WIDGET}++;
        $class->add_placeholder_label($proto->{'widget'}{'class'}, 
            $proto->{'widget'}{'name'}, $parentname, $depth);
    }

    return ($wh, $ch);
}

sub new_widget {
    my ($class, $parentname, $proto, $depth, $awh, $ach) = @_;
    my $me = (ref $class || $class)."->new_widget";
    my ($wh, $ch) = ($awh, $ach);
    my ($name, $constructor, $expr);
    unless ($proto->{'widget'}{'name'}) {
        if (defined $proto->{'placeholder'}) {
            $Glade_Perl->{'widgets'}{'ignored'}++;
        } else {
            $Glade_Perl->diag_print (2, 
                "You have supplied a proto without a name to %s", $me);
            $Glade_Perl->diag_print (2, $proto);
        }
        return;
    } else {
        $name = $proto->{'widget'}{'name'};
    }
#print Dumper($proto);
    if ($depth == 1) {
        $name = $class->fix_name($name);
        $proto->{'widget'}{name} = $name;
        $proto->{'widget'}{id} = $name;
        if (keys %{$forms->{$name}}) {
            die "You have already defined a form called '$name'";
        }
        $forms->{$name} = {};
        # We are a toplevel window so create a new hash and 
        # set $current_form with its name
        # All these back-slashes are really necessary as this string
        # is passed through so many others
        $current_form_name = "$name-\\\\\\\$instance";
        $current_form = "\$forms->{'$name'}";
        $current_data = "\$data->{'$name'}\{$DATA}";
        $current_name = $name;
        $current_window = "\$forms->{'$name'}\{'$name'}";
        $first_form ||= $name;

        if ($Glade_Perl->source->hierarchy =~ /^(widget|both)/) {
            $wh = "\$forms->{'$name'}{$WH}";
        }
        if ($Glade_Perl->source->hierarchy =~ /^(class|both)/) {
            $ch = "\$forms->{'$name'}{$CH}";
        }

    } else {
        $wh = "$wh\{'$name'}" if $awh;
        $ch = "$ch\{'$proto->{'widget'}{class}'}{'$name'}" if $ach; 
    }
    $class->add_to_UI($depth,  "#");
    $class->add_to_UI($depth,  "# ".S_("Construct a").
        " $proto->{'widget'}{class} '$name'");
    if (defined $proto->{'internal-child'}) {
        # We have a special way to get at the widget (we hope)
        $failures->{$INTERNAL_CHILD}{$parentname}{$proto->{'internal-child'}}++;
    }
#    if (" GtkCList GtkCTree " =~ / $proto->{'widget'}{class} /) {
#        $proto->{'widget'}{class} = "GtkTreeView";
#    }
    my $widget_class = $proto->{'widget'}{class};
    if ($widget_class =~ s/^Gtk/Gtk2::/) {
        $class->load_class($widget_class);
    }
    $constructor = "new_$proto->{'widget'}{class}";
    if ($class->can($constructor)) {
        my $eval_class = __PACKAGE__;#ref $class || $class;
        # Construct the widget
        $expr =  "\$widgets->{'$name'} = ".
            "$eval_class->$constructor('$parentname', \$proto, $depth);";

        eval $expr ||
        $@ && $class->log_error($expr, $@);

    } else {
        $class->log_error("Construct a '$constructor'" ,
            sprintf("error I don't have a constructor called '%s' ".
            "- I guess that it isn't written yet :-)",
            (ref $class || $class)."->$constructor"));
        return;
    }
    if ($wh) {
        # Add to form widget hierarchy
        $class->add_to_UI($depth,  
            "$wh\{$WIDGET_INSTANCE} = $current_form\{'$name'};");
    }
    if ($ch) {
        # Add to form class hierarchy
        $class->add_to_UI($depth,  
            "$ch\{$WIDGET_INSTANCE} = $current_form\{'$name'};");
    }
    if ($Glade_Perl->source->hierarchy =~ /order/) {
        if ($depth > 1) {
            $class->add_to_UI($depth,  
                "push \@{$awh\{$C}}, $current_form\{'$name'};");
        }
    }
    foreach my $signal (@{$proto->{'widget'}{'signal'}}) {
        $class->new_signal($proto->{'widget'}{'name'}, $signal, $depth);
    }
    foreach my $accelerator (@{$proto->{'widget'}{'accelerator'}}) {
        $class->new_accelerator($proto->{'widget'}{'name'}, $accelerator, $depth);
    }
    
    return ($wh, $ch);
}

sub post_generate_from_proto {
    my ($class, $proto) = @_;
    my $me = (ref $class || $class)."->form_from_proto";

    my $save_module = $proto->test->use_module;
    my ($module);
    my $options = $proto;
    
#print Dumper($failures);
    # Now write the disk files
    if ($Glade_Perl->Writing_to_File) {
        # Load the source code gettext translations
        unless ($options->source->LANG) {
            $options->source->LANG($options->diag->LANG);
        }
        $class->load_translations('Glade-One-Perl', $options->source->LANG, 
            undef, undef, $SOURCE_LANG, undef);
#        $class->load_translations('Glade-One-Perl', $options->source->LANG, undef, 
#            '/home/dermot/Devel/Glade-Perl/ppo/en.mo', $SOURCE_LANG, undef);
#        $class->start_checking_gettext_strings($SOURCE_LANG);
        my $gen_type = " Style ".$options->source->style;
        if ($options->source->quick_gen) {
            $gen_type .= " with NO VALIDATION!";
        }
        $Glade_Perl->diag_print (2, "%s- Source code will be generated for ".
            "locale <%s>%s", 
            $indent, $options->source->LANG, $gen_type);

        $proto->app->logo(basename ($proto->app->logo));
        $module = $proto->module->directory unless $proto->module->directory eq '.';
        $module =~ s/.*\/(.*)$/$1/;
        $module .= "::" if $module;
        
        $proto->test->first_form($proto->test->first_form || $first_form);

#print Dumper($Glade_Perl->module->gtk);
        if ($options->source->style && $options->source->style eq "Libglade") {
            # Write source that will use libglade to show the UI
            $Glade_Perl->diag_print (2, "%s  Generating libglade type code", $indent);
            $class->write_LIBGLADE($proto, $forms);
            $options->run_options->dont_show_UI(1);
            $proto->test->use_module($save_module || 
                $module.$proto->test->use_module.
                $proto->module->libglade->class."LIBGLADE");
            $proto->test->first_form($proto->test->first_form);
                $Glade_Perl->diag_print (2, 
                    "%s- One of the ways to run the generated source", $indent);
            $Glade_Perl->diag_print (2, 
                "%s  Change directory to '%s' and then enter:",
                "$indent$indent", $proto->glade->directory);
            $Glade_Perl->diag_print (2,"%s", 
                "$indent$indent  perl -e 'use ".
                    $proto->test->use_module."; ".
                    $proto->test->first_form."->app_run'");

        } elsif ($options->source->style && $options->source->style eq "onefile") {
            # Generate UI, handlers and pixmap subs in one file
            $Glade_Perl->diag_print (2, "%s  Generating ONEFILE type code", $indent);
            $class->write_ONEFILE($proto, $forms);
            $options->run_options->dont_show_UI(1);
            $proto->test->use_module($save_module || 
                $module.$proto->test->use_module.
                $proto->module->onefile->class."ONEFILE");
            $proto->test->first_form($proto->test->first_form);
                $Glade_Perl->diag_print (2, 
                    "%s- One of the ways to run the generated source", $indent);
            $Glade_Perl->diag_print (2, 
                "%s  Change directory to '%s' and then enter:",
                "$indent$indent", $proto->glade->directory);
            $Glade_Perl->diag_print (2,"%s", 
                "$indent$indent  perl -e 'use ".
                    $proto->test->use_module."; ".
                    $proto->test->first_form."->app_run'");

            
        } else {
            $Glade_Perl->diag_print (4, "%s- Generating UI construction code", $indent);
            $class->write_UI($proto, $forms);

            $Glade_Perl->diag_print (4, "%s- Generating signal handler code", $indent);
            if ($options->source->style && $options->source->style =~ /split/i) {
                $class->write_split_SIGS($proto, $forms);
                $proto->test->use_module($save_module || 
                    $module.$proto->test->use_module.
                    $proto->module->app->class.
                    "_".$proto->test->first_form);
                $Glade_Perl->diag_print (2, 
                    "%s- Some of the ways to run the generated source", $indent);
                $Glade_Perl->diag_print (2, 
                    "%s  Change directory to '%s' and then enter one of :",
                    "$indent$indent", $proto->glade->directory);
                $Glade_Perl->diag_print (2,"%s", 
                    "$indent$indent  perl -e 'use ".
                        $proto->test->use_module."; ".
                        $proto->test->first_form."->app_run'");

            } else {
                $class->write_SIGS($proto, $forms);
                $proto->test->use_module($save_module || 
                    $module.$proto->test->use_module.
                    $proto->module->app->class);
                $Glade_Perl->diag_print (2, 
                    "%s- Some of the ways to run the generated source", $indent);
                $Glade_Perl->diag_print (2, 
                    "%s  Change directory to '%s' and then enter one of :",
                    "$indent$indent", $proto->glade->directory);
                $Glade_Perl->diag_print (2,"%s", 
                    "$indent$indent  perl -e 'use ".
                        $proto->test->use_module."; ".
                        $proto->test->first_form."->app_run'");
                $Glade_Perl->diag_print (4, "%s- Generating OO subclass code", $indent);
                $class->write_SUBCLASS($proto, $forms);
            }
            $Glade_Perl->diag_print (2, "%s",
                "$indent$indent  perl -e 'use ".
                    $module.$proto->module->subapp->class.
                    "; Sub".$Glade_Perl->test->first_form."->app_run'");
            $Glade_Perl->diag_print (2, "%s",
                "$indent$indent  ./".
                $class->relative_path(
                    $proto->dist->bin_directory, 
                    $proto->dist->bin)
               );
        }
    }

    $Glade_Perl->write_documentation;
    $Glade_Perl->write_distribution;

    $class->report_errors if keys %$failures;
#    $object->write_missing_gettext_strings($SOURCE_LANG);

#    $object->write_missing_gettext_strings($DIAG_LANG, "&STDOUT", "NO_HEADER");

    # And show UI if necessary
    unless ($Glade_Perl->Writing_Source_only) { 
#print Dumper($forms);
        $forms->{$first_form}{$first_form}->show;
        Gtk2->main; 
    }

    $Glade_Perl->test->directory($Glade_Perl->test->directory || 
        $class->full_Path($Glade_Perl->glade->directory, `pwd`));
    $Glade_Perl->test->name($Glade_Perl->test->name || $Glade_Perl->glade->{'name'});

    return $proto;
}

#===============================================================================
#=========== Diagnostic utilities                                   ============
#===============================================================================n_options
sub check_for_unused_properties {
    my ($class, $proto) = @_;
    my $me = (ref $class || $class)."->check_for_unused_properties";
    my $key;
    my ($object,$name);
#print "$proto->{'class'} '$proto->{'name'}' ", Dumper($proto->{'widget'}{'property'});
    foreach $key (keys %{$proto->{'property'}}) {
        if (defined $proto->{'property'}{$key}{'value'}) {
            $object = $proto->{'class'} || '';
            $name = $proto->{'name'} || '(no name)';
            if (" $Glade_Perl->{'properties'}{'cxx'} " =~ m/ $key /) {
                $Glade_Perl->diag_print (4, 
                    "warn  Intentionally ignored property for %s %s {'%s'}{'%s'} => '%s' seen by %s",
                    $key, $object, $name, $key, $proto->{'property'}{$key}{'value'}, $me);
            } elsif (!$Glade_Perl->source->quick_gen) {
                $Glade_Perl->diag_print (1, 
                    "error Unused widget property for %s {'%s'}{'%s'} => '%s' seen by %s",
                    $object, $name, $key, $proto->{'property'}{$key}{'value'}, $me);
                push(@{$failures->{$UNUSED_PROPERTIES}{$current_widget}}, 
                    "{'$name'}{'$key'} = '$proto->{'property'}{$key}{'value'}'");
                $Glade_Perl->properties->{'unhandled'}++;
            }
        }
    }
#print "$proto->{'class'} '$proto->{'name'}' ", Dumper($proto->{'widget'}{'property'});
    return $Glade_Perl->properties->unhandled;
}

sub check_for_unused_packing_properties {
    my ($class, $proto, $name) = @_;
    my $me = (ref $class || $class)."->check_for_unused_packing_properties";
    my $key;
    foreach $key (keys %{$proto->{'property'}}) {
        if (defined $proto->{'property'}{$key}{'value'}) {
            if (" $Glade_Perl->{'properties'}{'cxx'} " =~ m/ $key /) {
                $Glade_Perl->diag_print (4, 
                    "warn  Intentionally ignored property for %s {'%s'}{'%s'} => '%s' seen by %s",
                    $key, $name, $key, $proto->{'property'}{$key}{'value'}, $me);
            } elsif (!$Glade_Perl->source->quick_gen) {
                $Glade_Perl->diag_print (1, 
                    "error Unused packing property for {'%s'}{'%s'} => '%s' seen by %s",
                    $name, $key, $proto->{'property'}{$key}{'value'}, $me);
                push(@{$failures->{$UNUSED_PROPERTIES}{$current_widget}}, 
                    "{'$name'}{'$key'} = '$proto->{'property'}{$key}{'value'}'");
                $Glade_Perl->properties->{'unhandled'}++;
            }
        }
    }
#print "$proto->{'class'} '$proto->{'name'}' ", Dumper($proto->{'widget'}{'property'});
    return $Glade_Perl->properties->unhandled;
}

sub check_for_unpacked_widgets {
    my ($class) = @_;
    my $me = (ref $class || $class)."->check_for_unpacked_widgets";
    my $count = 0;
    my $key;
    foreach $key (keys %{$widgets}) {
        if (defined $widgets->{$key}) {
            # We have found an unpacked widget
            $count++;
            $Glade_Perl->diag_print (1, 
                "error Unpacked widget '%s' has not been packed ".
                "(nor correctly added to the UI file) from %s", 
                $key, $me);
        }
    }
    return $count;
}

sub unhandled_signals {
    my ($class) = @_;
    my $me = (ref $class || $class)."->unhandled_signals";
    my ($widget, $signal);
    my $count = 0;
# FIXME This is all tosh - what do we need here?    
# FIXME Should we produce stubs for these ? if so, do this in perl_sub etc

    foreach $widget (keys %{$need_handlers}) {
#        if (keys (%{$need_handlers->{$widget})) {
            foreach $signal (keys %{$need_handlers->{$widget}}) {
                # We have found an unhandled signal (eg from accelerator)
                $count++;
                $Glade_Perl->diag_print (1, "error Widget '%s' emits a ".
                    "signal '%s' that ".
                    "does not have a handler specified - in %s",
                    $widget, $need_handlers->{$widget}{$signal}, $me);
                    
            }
#        } else {
#            # Nothing to be done
#        }
    }
    return $count;
}

sub what_isa {
    my ($class, $object) = @_;
    my $isa = '';
    eval "\$isa = \$$object\::ISA[0]";
    if ($isa and ($isa ne "Gtk2::Widget")) {
        $isa .= $class->what_isa($isa);
    }
    return " - $isa" if $isa;
}

sub report_errors {
    my ($class) = @_;
    my $failure_messages = 0;
    my $failure_widgets = 0;
    my $cant_do_widgets = scalar(keys %{$failures->{$IGNORED_WIDGET}});
    my $isa;
    foreach my $widget (sort keys %$failures) {
        $isa = $class->what_isa($widget);
        $isa = " (ISA $isa)           failed methods " if $isa;
        next if " $INTERNAL_CHILD $UNUSED_PROPERTIES $IGNORED_WIDGET " =~ / $widget /;
        $Glade_Perl->diag_print (2, $failures->{$widget}, $widget.$isa);
        $failure_widgets++;
        $failure_messages += scalar(keys %{$failures->{$widget}});
    }
    # Look through $proto and report any unused attributes (still defined)
    if (!$Glade_Perl->source->quick_gen && $Glade_Perl->diagnostics(2)) {
        if ($Glade_Perl->widgets->ignored or $Glade_Perl->properties->unhandled or $class->check_for_unpacked_widgets or $failure_messages) {
            $Glade_Perl->diag_print (2, "%s", "-----------------------------------------------------------------------------");
            $Glade_Perl->diag_print (2, "%s  CONSISTENCY CHECKS", $indent);
            if ($Glade_Perl->properties->unhandled) {
                $Glade_Perl->diag_print (2, "%s- %s unused widget properties", $indent, $Glade_Perl->properties->unhandled);
            }
            if ($Glade_Perl->widgets->ignored) {
                $Glade_Perl->diag_print (2, "%s- %s widgets were ignored (one or more of '%s')", 
                    $indent, $Glade_Perl->widgets->ignored, $Glade_Perl->widgets->to_ignore);
            }
            if ($class->check_for_unpacked_widgets) {
                $Glade_Perl->diag_print (2, "%s- %s unpacked widgets",
                    $indent, $class->check_for_unpacked_widgets);
            }
            if ($Glade_Perl->diagnostics(4) && $class->unhandled_signals) {
                $Glade_Perl->diag_print (4, 
                    "$indent- ".$class->unhandled_signals." unhandled signals");
            }
            if ($failure_widgets) {
                $Glade_Perl->diag_print (2, "%s- %s Gtk2-Perl widgets had failure", $indent, 
                    $failure_widgets);
            }
            if ($cant_do_widgets) {
                $Glade_Perl->diag_print (2, "%s- %s Ignored Glade widgets", $indent, 
                    $cant_do_widgets);
            }
            if ($failure_messages) {
                $Glade_Perl->diag_print (2, "%s- %s failed Gtk2-Perl calls", $indent, 
                    $failure_messages);
            }
            $Glade_Perl->diag_print (2, "%s", "-----------------------------------------------------------------------------");
        }
        unless ($Glade_Perl->Writing_Source_only) { 
            $Glade_Perl->diag_print (2, "%s  UI MESSAGES - showing missing_handler calls that you triggered, ".
                "don't worry, %s will generate dynamic stubs for them all",
                $indent, $PACKAGE);
        }
    }
}

#===============================================================================
#=========== Project utilities                                      ============
#===============================================================================
sub Stop_Writing_to_File { shift->Write_to_File('-1') }

sub Write_to_File {
    my ($class) = @_;
    my $me = __PACKAGE__."::Write_to_File";
    my $filename = $class->source->write;
    if (fileno UI or fileno SIGS or fileno SUBCLASS or 
        $class->Building_UI_only) {
        # Files are already open or we are not writing source
        if ($class->Writing_to_File) {
            if ($filename eq '-1') {
                close UI;
                close SUBCLASS;
                close SIGS;
                $class->diag_print (2, "%s- Closing output file in %s",
                    $indent, $me);
                $class->source->write(undef);
            } else {
                $class->diag_print (2, "%s- Already writing to %s in %s",
                    $indent, $class->Writing_to_File, $me);
            }
        }

    } elsif ($filename && ($filename eq '1')) {
        $class->diag_print (3, "%s- Using default output files ".
            "in Glade <project><source_directory> in %s", 
            $indent, $me);

    } elsif ($filename && ($filename ne '-1')) {
        # We want to write source
        if ($filename eq 'STDOUT') {
            $class->source->write('>&STDOUT');
        }
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'UI  ', $filename, $me);
        open UI,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBS', $filename, $me);
        open SIGS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        $class->diag_print (2, "%s- Writing %s source to %s - in %s", 
            $indent, 'SUBCLASS', $filename, $me);
        open SUBCLASS,     ">$filename" or 
            die sprintf((
                "error %s - can't open file '%s' for output"),
                $me, $filename);
        UI->autoflush(1);
        SIGS->autoflush(1);
        SUBCLASS->autoflush(1);
    } else {
        # Nothing to do
    }
}

sub Writing_Source_only  { shift->run_options->dont_show_UI }

sub get_versions {
    my ($class) = @_;
    my $type = 'glade2perl-2';
    # We use the CPAN release date (or CVS date) for version checking
    my $cpan_date = $gtk_perl_depends->{$Gtk2::VERSION};

    # If we dont recognise the version number we use the latest CVS 
    # version that was available at our release date
    $cpan_date ||= $gtk_perl_depends->{'LATEST_CVS'};

    # If we have a version number rather than CVS date we look it up again
    $cpan_date = $gtk_perl_depends->{$cpan_date}
        if ($cpan_date < 19000000);

    if ($class->{$type}->my_gtk_perl && 
        ($class->{$type}->my_gtk_perl > $cpan_date)) {
        $Glade_Perl->diag_print (2, "%s- %s reported version %s".
            " but user overrode with version %s",
            $indent, "Gtk2-Perl", "$Gtk2::VERSION (CVS $cpan_date)",
            $class->{$type}->my_gtk_perl);

    } else {
        $class->{$type}->my_gtk_perl($cpan_date);
        $Glade_Perl->diag_print (2, "%s- %s reported version %s",
            $indent, "Gtk2-Perl", "$Gtk2::VERSION (CVS $cpan_date)");
    }
    unless ($class->my_gtk_perl_can_do('MINIMUM REQUIREMENTS')) {
        die "You need to upgrade your Gtk2-Perl";
    }

    if ($class->app->allow_gnome) {
#        my $gnome1_libs_version = `gnome-config --version`;
        my $gnome2_libs_version = `pkg-config libgnome-2.0 libgnomeui-2.0 libgnomeprint-2.0 libgnomeprintui-2.0 libgnomecanvas-2.0 --libs`;
        my $gnome_libs_version = $gnome2_libs_version;
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
        # Gnome include directories
        my $gnome_incs = `gnome-config --includedir`;
        chomp $gnome_incs;
        if ($class->{$type}->my_gnome_incs &&
            $class->{$type}->my_gnome_incs ne $gnome_incs) {
            $Glade_Perl->diag_print (2, "%s- %s reported include directory '%s'".
                " but user overrode with '%s'",
                $indent, "gnome-libs", $gnome_incs,
                $class->{$type}->my_gnome_incs);
        } else {
            $class->{$type}->my_gnome_incs($gnome_incs);
            $Glade_Perl->diag_print (2, "%s- %s reported include directory '%s'",
                $indent, "gnome-libs", $gnome_incs);
        }
    }

    if ($class->app->gtk2) {
#        my $gtk1_version = `gtk-config --version`;
        my $gtk2_version = `pkg-config --version gtk+-2.0`;
        my $gtk_version = $gtk2_version;
        chomp $gtk_version;
        $gtk_version =~ s/gtk-libs //;
        if ($class->{$type}->my_gtk && 
            ($class->{$type}->my_gtk gt $gtk_version)) {
            $Glade_Perl->diag_print (2, "%s- %s reported version %s".
                " but user overrode with version %s",
                $indent, "gtk", $gtk_version,
                $class->{$type}->my_gtk);
        } else {
            $class->{$type}->my_gtk($gtk_version);
            $Glade_Perl->diag_print (2, "%s- %s reported version %s",
                $indent, "gtk", $gtk_version);
        }
        unless ($class->my_gtk_can_do('MINIMUM REQUIREMENTS')) {
            die "You need to upgrade your gtk";
        }
        # Gnome include directories
        my $gtk_incs = `pkg-config gtk+-2.0 --cflags`;
        chomp $gtk_incs;
        if ($class->{$type}->my_gtk_incs &&
            $class->{$type}->my_gtk_incs ne $gtk_incs) {
            $Glade_Perl->diag_print (2, "%s- %s reported include dir '%s'".
                " but user overrode with '%s'",
                $indent, "gtk", $gtk_incs,
                $class->{$type}->my_gtk_incs);
        } else {
            $class->{$type}->my_gtk_incs($gtk_incs);
            $Glade_Perl->diag_print (2, "%s- %s reported include dir '%s'",
                $indent, "gtk", $gtk_incs);
        }
    }

    return $class;
}

#===============================================================================
#=========== Version utilities                                      ============
#===============================================================================
sub my_gtk_perl_can_do {
    my ($class, $action) = @_;
    my $depends = $gtk_perl_depends->{$action} || '';
    my $cant_do = $gtk_perl_cant_do->{$action} || '';
    unless ($depends or $cant_do) { 
        # There is no required/cant_do information for $action
        return 1;
    }
    my ($cpan, $cvs);
    my $check = $action;

    # Check that we have at least the minimum required
    $check = $gtk_perl_depends->{$depends} || $depends;
    if ($check and $check > $Glade_Perl->run_options->my_gtk_perl) {
        $cpan = $gtk_perl_depends->{'LATEST_CPAN'};
        $cpan = $gtk_perl_depends->{$cpan} if $gtk_perl_depends->{$cpan};
        if ($check > $cpan) {
            # We need a CVS version
            if ($check > $gtk_perl_depends->{'LATEST_CVS'}) {
                # The CVS version can't even do it yet
                $Glade_Perl->diag_print(1, 
                    "warn  Gtk2-Perl dated %s cannot do '%s' (properly)".
                    " and neither can the CVS version !!! - it has been ignored",
                    $Glade_Perl->run_options->my_gtk_perl, $action);
                    
            } else {
                # We need a new CVS version
                $Glade_Perl->diag_print(1, 
                    "warn  Gtk2-Perl dated %s cannot do '%s' (properly)".
                    " we need CVS module 'gnome-perl' after %s - it has been ignored",
                    $Glade_Perl->run_options->my_gtk_perl, $action, $check);
            }

        } else {
            # We need a new CPAN version
            $Glade_Perl->diag_print(1, 
                "warn  Gtk2-Perl version %s cannot do '%s' (properly)".
                " we need CPAN version %s or CVS module 'gnome-perl' after %s - it has been ignored",
                $Glade_Perl->run_options->my_gtk_perl, $action, 
                    $gtk_perl_depends->{$action}, $check);
        }
        return undef;
    }

    # Check that we dont have a cant_do version
    $check = $gtk_perl_depends->{$cant_do} || $cant_do;
    unless ($check and $check == $Glade_Perl->run_options->my_gtk_perl) {
        # We can do required $action in our version
        return 1;
    } else {
        # This version can't do it although earlier and later versions may
        $Glade_Perl->diag_print(1, 
            "warn  Gtk2-Perl dated %s cannot do '%s' (properly)".
            " although older and newer versions may - it has been ignored",
            $Glade_Perl->run_options->my_gtk_perl, $action);
        return undef;
    }
    return undef;
}

sub my_gnome_libs_can_do {
    my ($class, $action) = @_;
    my $depends = $gnome_libs_depends->{$action};
    unless ($depends and $depends gt $Glade_Perl->run_options->my_gnome_libs) {
        # There is no specified version or ours is sufficient
        return 1;
    }
    if ($depends ge 19990914) {
        # We need a CVS version
        if ($depends gt 29990000) {
            # The CVS version can't even do it yet
            $Glade_Perl->diag_print(1, 
                "warn  gnome_libs version %s cannot do '%s' (properly)".
                " and neither can the CVS version !!!",
                $Glade_Perl->run_options->my_gnome_libs, $action);
        } else {
            # We need a new CVS version
            $Glade_Perl->diag_print(1, 
                "warn  gnome_libs version %s cannot do '%s' (properly)".
                " we need CVS module 'gnome-libs' after %s",
                $Glade_Perl->run_options->my_gnome_libs, $action, $depends);
        }
    } else {
        # We need a new released version
        $Glade_Perl->diag_print(1, 
            "warn  gnome_libs version %s cannot do '%s' (properly)".
            " we need version %s",
            $Glade_Perl->run_options->my_gnome_libs, $action, $depends);
    }
    return undef;
}

#===============================================================================
#=========== Utilities to construct UI                              ============
#===============================================================================
sub use_set_property {
    my ($class, $name, $proto, $property, $type, $depth, $method, $args, $default) = @_;
#    $method ||= "$property";
    unless ($method) {
        if (eval "\$widgets->{'$name'}->can('$property')") {
            $method = "$property";
        } else {
            $method = "set_$property";
        }
    }
#print Dumper(\@_);
    my $value  = $class->use_par($proto, $property,  $type|$MAYBE);
    if (defined $value) {
        if ($type & $STRING) {
#            if ((defined $default) and ($value ne $default)) {
#                $value =~ s/\n/\\n/g;    # To get through add_to_UI
                # Backslash escape any single quotes (unless they are already backslashed)
                $value =~ s/(?!\\)(.)'/$1\\'/g;
                $value =~ s/^'/\\'/g;
                $class->add_to_UI($depth, "\$widgets->{'$name'}->$method(_('$value')$args);");
#            }
        } else {
            unless (defined $default and $value == $default) {
                $class->add_to_UI($depth, "\$widgets->{'$name'}->$method('$value'$args);");
            }
        }
    }
}

sub use_set_flag {
    my ($class, $name, $proto, $property, $type, $depth, $flag, $default) = @_;
    $type ||= $BOOL;
    $flag ||= $property;
#print Dumper(\@_);
    my $value  = $class->use_par($proto, $property,  $type|$MAYBE);
    if (defined $value) {
        if (!(defined $default) or ($value != $default)) {
            $class->add_to_UI($depth, "${current_form}\{'$name'}->SET_FLAGS('$flag');");
        }
    }
}

sub use_par {
    my ($class, $proto, $key, $request, $default, $dont_undef) = @_;
    my $me = (ref $class || $class)."->use_par";

    my $type;
    my $self;
    $request ||= $MAYBE;
    if ($request&$NOT_WIDGET) {
        $self = $proto->{'property'}{$key}{'value'};
        delete $proto->{'property'}{$key} unless $dont_undef;
    } elsif ($request&$NOT_PROPERTY) {
        $self = $proto->{$key};
        delete $proto->{$key} unless $dont_undef;
    } else {
        if (defined $proto->{'widget'}{'property'}{$key}) {
            $self = $proto->{'widget'}{'property'}{$key}{'value'};
            delete $proto->{'widget'}{'property'}{$key} unless $dont_undef;
        }
    }
    unless (defined $self) {
        if (defined $default) {
            $self = $default;

        } elsif ($request & $MAYBE) {
            return undef;
            
        } else {
            # We have no value and no default to use so bail out here
            $Glade_Perl->diag_print (1, "error No value in supplied ".
                "%s and NO default was supplied in ".
                "%s called from %s line %s",
                "$proto->{'widget'}{'name'}\->{'$key'}", $me, (caller)[0], (caller)[2]);
            return undef;
        }
    }
    # We must have some sort of value to use by now
    unless ($request) {
        # Nothing to do, we are already $proto->{$key} so
        # just drop through to undef the supplied prot->{$key}
        
    } elsif ($request & $DEFAULT) {
        # Nothing to do, we are already $proto->{$key} (or default) so
        # just drop through to undef the supplied prot->{$key}
        
    } elsif ($request & $LOOKUP) {
        return '' unless $self;
        
        my $lookup;
        # make an effort to convert from Gtk to Gtk2-Perl constant/enum name
        if ($self =~ /^GNOME/) {
            $lookup = Glade::Two::Gnome->lookup($self);

        } else {
            $lookup = Glade::Two::Gtk->lookup($self);
        }
        unless ($lookup) {
            if (defined $default) {
                $Glade_Perl->diag_print(2, 
                    "warn  Unable to lookup '%s' using default of '%s'",
                    $self, $default);
                $self = $default;
            } else {
                $Glade_Perl->diag_print(1, 
                    "error Unable to lookup '%s' and no default",
                    $self);
            }
        } else {
            $self = $lookup;
        }
            
    } elsif ($request & $BOOL) {
        # Now convert whatever we have ended up with to a BOOL
        # undef becomes 0 (== false)
        $type = $self;
        $self = ('*true*y*yes*on*1*' =~ m/\*$self\*/i) ? '1' : '0';

    } elsif ($request & $KEYSYM) {
        $self =~ s/GDK_//;

    } 

    # Backslash escape any single quotes (unless they are already backslashed)
    $self =~ s/(?!\\)(.)'/$1\\'/g;
    $self =~ s/^'/\\'/g;
    return $self;
}

#===============================================================================
#=========== Utilities to build UI                                    ============
#===============================================================================
sub get_internal_child {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $accessor = {
        'color_selection'   => 'colorsel',
        'font_selection'    => 'fontsel',
        # All others are unchanged
    };
    my $type = $proto->{'internal-child'};
    return undef unless $type;
    my $refpar;
    eval "\$refpar = (ref ${current_form}\{'$parent'})||'UNDEFINED !!';";
    $type = $accessor->{$type} || $type;
    if ($type eq 'action_area') {
        $class->add_to_UI($depth, 
            "\$widgets->{'$name'} = ${current_window}->$type;");
        return 1;

        # Gtk|Gnome::Dialogs have widget tree that is not reflected by
        # the methods that access them. $dialog->action_area() points to
        # a child of $dialog->vbox() and not of $dialog. 
        # In any case, they cannot be used/accessed until something is 
        # added to them by the automagic ->new('title', 'Button_Ok',...).
        #
        # For Gnome::Dialog and derivatives we can use ->append_button() 
        # (which calls gnome_dialog_init_action_area)
        unless ($class->my_gtk_perl_can_do('gnome_dialog_append_button')) {
            # Force HButtonbox to construct its widget and add it to the VBox 
            # This will look wrong (above the separator)
            return undef;
        
        } else {
            # Append the buttons
            my $number_of_buttons = 
                $class->frig_Gnome_Dialog_buttons($parent, $proto, $depth);
            # Return the action_area now it exists
            $class->add_to_UI($depth, 
                "\$widgets->{'$name'} = ${current_window}->$type;");
        }
    }

#---------------------------------------
    if ($type eq 'notebook') {
        return undef;
        
#---------------------------------------
    } elsif (eval "${current_form}\{'$parent'}->can('$type')" || $Glade_Perl->source->quick_gen) {
        $class->add_to_UI($depth, 
            "\$widgets->{'$name'} = ${current_form}\{'$parent'}->$type;"
            );
#            , undef, undef, 'REALLY_DIE');

#---------------------------------------
    } elsif (" $Glade_Perl->{'widgets'}{'dialogs'} "=~ m/ $refpar /) {
        # We use a dialog->add_button to get a ref to our widget
        my $label  = $class->use_par($proto, 'label', $DEFAULT, '');
        $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
#FIXME Which accel key to use???
            "${current_form}\{'$parent'}->add_button(_('$label'), 69);");

#---------------------------------------
    } else {
        $Glade_Perl->diag_print (1, "error Don't know how to get a ref to %s ".
            "(type '%s')",
            "${current_form}\{'${name}'}", "$type in a $refpar");
        return undef;
    }

#    $class->add_to_UI($depth, 
#        "${current_form}\{'$name'} = \$widgets->{'$name'};");
    # Delete the $widget to show that it has been packed
#    delete $widgets->{$name};

    # we have constructed the widget so caller doesn't need to
    return 1;
}

sub string_to_arrayref {
    my ($class, $string) = @_;
    my ($work, @elements);
    foreach $work (split(/\|/, $string)) {
        $work =~ s/\s*//g; # Trim off any whitespace
        $work = Glade::Two::Gtk->lookup($work);
        push @elements, $work;
    }
    my $arrayref_string = "[]";
    $arrayref_string = "['".join("', '", @elements)."']" if scalar @elements;

    return $arrayref_string;
}

sub internal_pack_widget {
    my ($class, $parentname, $childname, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->internal_pack_widget";
#    return if $proto->{'internal-child'};
    my $refpar;
    # When we add/pack/append we do it to ${current_form}->{$parentname} 
    # rather than $widgets->{$parentname} so that we are sure that everything 
    # is packed in the right order and we can check for duplicate names
    my $refwid = (ref $widgets->{$childname});
    my $child_type;
    my $postpone_show;
    if ($current_form && eval "exists ${current_form}\{'$childname'}") {
        die sprintf(("\nerror %s - There is already a widget called ".
            "'%s' constructed and packed - I will not overwrite it !"),
            $me, $childname);
    }
    if ($proto->{'internal-child'}) {
        if ($widgets->{$childname}) {
            # Nothing to pack just tidy up
            delete $failures->{$INTERNAL_CHILD}{$parentname}{$proto->{'internal-child'}};
        }
    } elsif (" $Glade_Perl->{'widgets'}{'dialogs'} $Glade_Perl->{'widgets'}{'toplevel'} " =~ m/ $refwid /) {
        # We are a window so don't have a parent to pack into
        $Glade_Perl->diag_print (4, "%s- Constructing a toplevel component ".
            "(window/dialog) '%s'", $indent, $childname);
#        $child_type = $widgets->{$childname}->type;
#        if (' toplevel dialog '=~ m/ $child_type /) {
            # Add a default delete_event signal connection
            $class->load_class("Gtk2::Tooltips;");
            $class->add_to_UI($depth, 
                "${current_form}\{'tooltips'} = new Gtk2::Tooltips;");
            $class->load_class("Gtk2::AccelGroup;");
            $class->add_to_UI($depth, 
                "${current_form}\{'accelgroup'} = new Gtk2::AccelGroup;");
            $class->add_to_UI($depth, 
                "\$widgets->{'$childname'}->add_accel_group(${current_form}\{'accelgroup'});");
#                "${current_form}\{'accelgroup'}->attach(\$widgets->{'$childname'});");
#        } else {
#            die "\nerror F$me   $indent- This is a $child_type type Window".
#                " - what should I do?";
#        }
        $postpone_show = 1;

    } else {
        # We probably have a parent to pack into somehow
        eval "\$refpar = (ref ${current_form}\{'$parentname'})||'UNDEFINED !!';";
        $Glade_Perl->diag_print(5, "Adding %s to %s", $refwid, $refpar);
        unless (eval "exists ${current_form}\{'$parentname'}") {
            if ($Glade_Perl->source->quick_gen or 'Gtk2::Menu' eq $refwid) {
                # We are a popup menu so we don't have a root window
#            $class->add_to_UI($depth, "${first_form}->popup_enable;");
                $class->add_to_UI($depth,   
                    "${current_form}\{'tooltips'} = new Gtk2::Tooltips;");
                $class->add_to_UI($depth,   
                    "${current_form}\{'accelgroup'} = new Gtk2::AccelGroup;");
                $class->add_to_UI($depth, 
                    "${current_form}\{'accelgroup'}->attach(\$widgets->{'$childname'});");
                $postpone_show = 1;
            } else {
                die sprintf(("\nerror %s - Unable to find a widget called '%s' - ".
                    "I can not pack widget '%s' into a non-existant widget!"),
                    $me, $parentname, $childname);
            }
        }
        if ($postpone_show) {
            # Do nothing
            
#---------------------------------------
        } elsif (' Gtk2::ImageMenuItem ' =~ m/ $refpar / && 
            ' Gtk2::Image ' =~ m/ $refwid / ) {
#            $class->use_par($proto->{'packing'}, 'type', $NOT_WIDGET|$MAYBE)) {
#print "We have a $refpar to pack into\n";
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_image(".
                    "\$widgets->{'$childname'});");
#            $class->add_to_UI($depth, 
#                "\$widgets->{'$childname'} = ".
#                    "${current_form}\{'$parentname'}->get_image();");
                    
#---------------------------------------
        } elsif (" $Glade_Perl->{'widgets'}{'composite'} " =~ m/ $refpar /) {
            # We do not need to do anything for this widget
#            $class->use_par($proto->{'packing'}, 'type', $NOT_WIDGET|$MAYBE)) {
            
#---------------------------------------
        } elsif (' Gtk2::HPaned Gtk2::VPaned ' =~ m/ $refpar /) {
            my $resize = $class->use_par($proto->{'packing'}, 'resize', $BOOL|$NOT_WIDGET, 'False');
            my $shrink = $class->use_par($proto->{'packing'}, 'shrink', $BOOL|$NOT_WIDGET, 'True');
            if (eval "${current_form}\{$FIRST_PANE_FULL}{'$parentname'}") {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->pack2(".
                        "\$widgets->{'$childname'}, $resize, $shrink);");
            } else {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->pack1(".
                        "\$widgets->{'$childname'}, $resize, $shrink);");
#                print "${current_form}\{$FIRST_PANE_FULL}{'$parentname'} = 1;\n";
                eval "${current_form}\{$FIRST_PANE_FULL}{'$parentname'} = 1;";
            }
            
#---------------------------------------
        } elsif (eval "${current_form}\{'$parentname'}->can(".
            "'pack_start')") {# and !defined $proto->{'child_name'}) {
            # We have a '$refpar' widget '$parentname' that can pack_start
            my $ignore = $class->use_par($proto, 'child_name', $DEFAULT, '');
            my $pack_type = $class->use_par($proto->{'packing'}, 'pack_type', $LOOKUP|$NOT_WIDGET, 'start');
            my $expand  = $class->use_par($proto->{'packing'}, 'expand',    $BOOL|$NOT_WIDGET, 'False');
            my $fill    = $class->use_par($proto->{'packing'}, 'fill',      $BOOL|$NOT_WIDGET, 'False');
            my $padding = $class->use_par($proto->{'packing'}, 'padding',   $DEFAULT|$NOT_WIDGET, 0);
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->pack_$pack_type(".
                    "\$widgets->{'$childname'}, $expand, $fill, $padding);");

#---------------------------------------
        } elsif (eval "${current_form}\{'$parentname'}->can(".
            "'set_child_packing')") {# and !defined $proto->{'child_name'}) {
            # We have a '$refpar' widget '$parentname' that can query_child_packing
            my $ignore = $class->use_par($proto, 'child_name', $DEFAULT, '');
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->add(".
                    "\$widgets->{'$childname'});");

#---------------------------------------
        } elsif ((' Gtk2::Frame ' =~ m/ $refpar /) &&
            $class->use_par($proto->{'packing'}, 'type', $NOT_WIDGET|$MAYBE)) {
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_label_widget(".
                    "\$widgets->{'$childname'});");

#---------------------------------------
        } elsif (' Gtk2::CList ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '');
            # We are a CList column widget (title widget)
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_column_widget(".
                    ($Glade::Two::Gtk2::CList_column || '0').
                    ", \$widgets->{'$childname'});");
            $Glade::Two::Gtk2::CList_column++;

#---------------------------------------
        } elsif (' Gtk2::CTree ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '');
            # We are a CTree column widget (title widget)
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_column_widget(".
                    ($Glade::Two::Gtk::CTree_column || '0').
                    ", \$widgets->{'$childname'});");
            $Glade::Two::Gtk::CTree_column++;

#---------------------------------------
        } elsif (' Gtk2::Layout Gtk2::Fixed ' =~ m/ $refpar /) {
#            $Glade_Perl->diag_print(2, $proto);
            my $x      = $class->use_par($proto->{'packing'}, 'x', $NOT_WIDGET);
            my $y      = $class->use_par($proto->{'packing'}, 'y', $NOT_WIDGET);
#            my $width  = $class->use_par($proto, 'width');
#            my $height = $class->use_par($proto, 'height');
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->put(".
                    "\$widgets->{'$childname'}, $x, $y);");

#---------------------------------------
        } elsif (' Gtk2::MenuBar Gtk2::Menu ' =~ m/ $refpar /) {
            # We are a menuitem
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->append(".
                    "\$widgets->{'$childname'});");

#---------------------------------------
        } elsif (' Gtk2::MenuItem Gtk2::PixmapMenuItem ' =~ m/ $refpar /) {
            # We are a menu for a meuitem
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_submenu(".
                    "\$widgets->{'$childname'});");
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk2::OptionMenu ' =~ m/ $refpar /) {
            # We are a menu for an optionmenu
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->set_menu(".
                    "\$widgets->{'$childname'});");
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk2::Notebook ' =~ m/ $refpar /) {
#print $childname," ",Dumper($proto->{'packing'});
            $child_type = $class->use_par($proto->{'packing'}, 'type', $MAYBE|$NOT_WIDGET);
            if ($child_type eq 'tab') {
                # We are a notebook tab widget (eg label) so we can add the 
                # previous notebook page with ourself as the  label
                unless ($Glade::Two::Gtk2::nb->{$parentname}{'panes'}[$Glade::Two::Gtk2::nb->{$parentname}{'tab'}]) {
                    $Glade_Perl->diag_print (1, "warn  There is no widget on the ".
                        "notebook page linked to notebook tab '%s' - ".
                        "a Placeholder label was used instead",
                        $childname);
                    my $message = sprintf(S_("This is a message generated by %s\n\n".
                                "No widget was specified for the page linked to\n".
                                "notebook tab \"%s\"\n\n".
                                "You should probably use Glade to create one"),
                                $PACKAGE, $childname);
                    $class->add_to_UI($depth, 
                        "${current_form}\{'Placeholder_label'} = ".
                            "new Gtk2::Label('$message');");
                    $class->add_to_UI($depth, 
                        "${current_form}\{'Placeholder_label'}->show;");
                    $Glade::Two::Gtk2::nb->{$parentname}{'panes'}[$Glade::Two::Gtk2::nb->{$parentname}{'tab'}] = 
                        'Placeholder_label';
                }
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->append_page(".
                        "${current_form}\{'$Glade::Two::Gtk2::nb->{$parentname}{'panes'}[$Glade::Two::Gtk2::nb->{$parentname}{'tab'}]'}, ".
                        "\$widgets->{'$childname'});");
                $Glade::Two::Gtk2::nb->{$parentname}{'tab'}++;

            } else {
                # We are a notebook page so just store for adding later 
                # when we get the tab widget
                push @{$Glade::Two::Gtk2::nb->{$parentname}{'panes'}}, $childname;
                $Glade::Two::Gtk2::nb->{$parentname}{'pane'}++;
                # Set some tab and menu properties
                my $menu_label = $class->use_par($proto->{'packing'}, 'menu_label', 
                    $STRING|$NOT_WIDGET, $depth);
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->set_menu_label_text(".
                        "\$widgets->{'$childname'}, _('$menu_label'));");
                my $tab_pack = $class->use_par($proto->{'packing'},'tab_pack', $LOOKUP|$NOT_WIDGET, 'start');
                my $tab_expand = $class->use_par($proto->{'packing'},'tab_expand', $BOOL|$NOT_WIDGET, 0);
                my $tab_fill = $class->use_par($proto->{'packing'},'tab_fill', $BOOL|$NOT_WIDGET, 0);
                
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->set_tab_label_packing(".
                        "\$widgets->{'$childname'}, $tab_expand, $tab_fill, '$tab_pack');");
#print Dumper($proto->{'packing'});
            }

#---------------------------------------
        } elsif (' Gtk2::ScrolledWindow ' =~ m/ $refpar /) {
#            if (' Gtk2::CList Gtk2::CTree Gtk2::Text Gnome::IconList Gnome::Canvas ' =~ m/ $refwid /) {
            if (' Gtk2::CList Gtk2::CTree Gtk2::Text Gtk2::TextView ' =~ m/ $refwid /) {
                # These widgets handle their own scrolling 
                # so for instance Ctree/CList column labels stay fixed
                # Gtk will flag 'Gtk-WARNING **: GtkContainerClass::add not implemented for `GtkTreeView'
                # or 'Gtk-WARNING **: gtk_scrolled_window_add(): cannot add non scrollable widget use gtk_scrolled_window_add_with_viewport() instead'
                # just ignore it - CList, CTree and Text are deprecated widgets now anyway :(
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->add(".
                        "\$widgets->{'$childname'});");

            } else {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->add_with_viewport(".
                        "\$widgets->{'$childname'});");
            }
            
#---------------------------------------
        } elsif (' Gtk2::Table ' =~ m/ $refpar /) {
            # We are adding to a table so do the child packing
            my $left_attach =   $class->use_par($proto->{'packing'}, 'left_attach', $NOT_WIDGET  );
            my $right_attach =  $class->use_par($proto->{'packing'}, 'right_attach', $NOT_WIDGET );
            my $top_attach =    $class->use_par($proto->{'packing'}, 'top_attach', $NOT_WIDGET   );
            my $bottom_attach = $class->use_par($proto->{'packing'}, 'bottom_attach', $NOT_WIDGET);

            my $x_options = $class->use_par($proto->{'packing'}, 'x_options', $NOT_WIDGET, 'fill|expand');
            my $y_options = $class->use_par($proto->{'packing'}, 'y_options', $NOT_WIDGET, 'fill|expand');

            my $xpad =    $class->use_par($proto->{'packing'}, 'xpad', $NOT_WIDGET|$DEFAULT, 0);
            my $ypad =    $class->use_par($proto->{'packing'}, 'ypad', $NOT_WIDGET|$DEFAULT, 0);

            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->attach(".
                    "\$widgets->{'$childname'}, ".
                    "$left_attach, $right_attach, $top_attach, $bottom_attach, ".
                    $class->string_to_arrayref($x_options).", ".
                    $class->string_to_arrayref($y_options).", ".
                    "$xpad, $ypad);");
            
#---------------------------------------
        } elsif (' Gtk2::Toolbar ' =~ m/ $refpar /) {
# FIXME - toolbar buttons with a removed label don't have a child_name
#   but can have a sub-widget. allow for this
#   test all possibilities
            # Untested possibilities
            # 4 Other type of widget
            my $tooltip =  $class->use_par($proto, 'tooltip',  $DEFAULT, '');
            if (eval "$current_form\{'$parentname'}{'tooltips'}" && 
                !$tooltip &&
                (' Gtk2::VSeparator Gtk2::HSeparator Gtk2::Combo Gtk2::Label ' !~ / $refwid /)) {
                $Glade_Perl->diag_print (1, 
                    "warn  Toolbar '%s' is expecting ".
                    "a tooltip but you have not set one for %s '%s'",
                    $parentname, $refwid, $childname);
            }            
#print Dumper($proto);
            my $new_group = $class->use_par($proto->{'packing'}, 'new_group', $BOOL|$MAYBE|$NOT_WIDGET);
            if ($new_group) {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->append_space();");
            }
            # We must have a widget already constructed
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->append_widget(".
                    "\$widgets->{'$childname'}, _('$tooltip'), '');");
            
#---------------------------------------
        } elsif (" Gnome::App "=~ m/ $refpar /) {
            my $type = $class->use_par($proto, 'child_name', $DEFAULT, '');
            if (' Gnome::AppBar ' =~ m/ $refwid /) {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'});");
            
            } elsif (' GnomeApp:appbar ' =~ m/ $type /) {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'});");
            
            } elsif (' Gnome::Dock ' =~ m/ $refwid /) {
# FIXME why have I commented this out? Is it because Gnome::Dock should not
# be constructed within a Gnome::App - add Gnome::DockItems by using method
# Gnome::App::add_docked() or Gnome::App::add_dock_item() instead?
#                $class->add_to_UI($depth, 
#                    "${current_form}\{'$parentname'}->set_contents(".
#                        "\$widgets->{'$childname'});");

            } elsif (' Gtk2::MenuBar ' =~ m/ $refwid /) {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->set_menus(".
                        "\$widgets->{'$childname'});");

            } else {
                $Glade_Perl->diag_print (1, 
                    "error Don't know how to pack %s %s (type '%s') - what should I do?",
                    $refwid, "${current_form}\{'${childname}'}{'child_name'}", $type);
            }
                        
#---------------------------------------
        } elsif (" Gnome::Dock "=~ m/ $refpar /) {
            # We are a Gnome::DockItem
            my $placement= $class->use_par($proto, 'placement', $LOOKUP, 'top');
            my $band     = $class->use_par($proto, 'band',      $DEFAULT, 0);
            my $position = $class->use_par($proto, 'position',  $DEFAULT, 0);
            my $offset   = $class->use_par($proto, 'offset',    $DEFAULT, 0);
            my $in_new_band = $class->use_par($proto, 'in_new_band', $DEFAULT, 0);

            # 'Usage: Gnome::Dock::add_item(dock, item, placement, band_num, position, offset, in_new_band)
            # Actually should be Gnome::App->add_docked() or
            # Gnome::App->add_dock_item() if this widget is in a Gnome::App
# I quote Damon 20000301 on glade-devel list
# I think it was OK to treat dock items as children of the dock.
# A GnomeDock could be used in other places besides a GnomeApp (though
# I don't think Glade supports that completely at the moment).
# I also had to think about GnomeDockBands, but I decided to skip those
# in the output since they are created and destroyed automatically
# and can't be manipulated independantly.
# 
# I think you're right in that libglade shouldn't create a GnomeDock inside
# a GnomeApp, and should be adding the dock items via the GnomeApp's
# GnomeDockLayout, e.g. using gnome_app_add_docked() or gnome_app_add_dock_item().

            if (" Gnome::DockItem " =~/ $refwid /) {
                $class->add_to_UI($depth, 
                    "${current_form}\{'$parentname'}->add_item(".
                        "\$widgets->{'$childname'}, '$placement', $band, ".
                        "$position, $offset, $in_new_band);");
            } else {
                # We are not a dock_item - just using set_contents
                undef $proto->{'child_name'};
                $class->add_to_UI($depth, 
                    "${current_window}->set_contents(".
                        "\$widgets->{'$childname'});");
            }
            
#---------------------------------------
        } elsif (" Gnome::Druid "=~ m/ $refpar /) {
            # We are a Gnome::DruidPage of some sort
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->append_page(".
                    "\$widgets->{'$childname'});");
            if (' Gnome::DruidPageStart ' =~ / $refwid /) {
                $class->add_to_UI($depth, "${current_form}\{'$parentname'}->".
                    "set_page(\$widgets->{'$childname'});");
            }
            
#---------------------------------------
        } elsif (" Gtk2::List "=~ m/ $refpar /) {
            # We are a Gnome::DruidPage of some sort
            $class->add_to_UI($depth, 
                "${current_form}\{'$parentname'}->add(\$widgets->{'$childname'});");
#                "${current_form}\{'$parentname'}->append_items([\$widgets->{'$childname'}]);");
            
#---------------------------------------
        } else {
            # We are not a special case
            $class->add_to_UI($depth, "${current_form}\{'$parentname'}->add(".
                "\$widgets->{'$childname'});");
        }
    }
    unless (!$class->use_par($proto, 'visible', $BOOL, 'True') || $postpone_show) {
        $class->add_to_UI($depth, "\$widgets->{'$childname'}->show;");
    }
    $class->add_to_UI($depth, 
        "${current_form}\{'$childname'} = \$widgets->{'$childname'};");
    $class->set_child_packing($parentname, $childname, $proto, $depth);
#    delete $widgets->{$childname};
    return;
}

sub set_child_packing {
    my ($class, $parentname, $childname, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_child_packing";
    return unless $proto->{'packing'} and keys %{$proto->{'packing'}{'property'}};
    if (eval "${current_form}\{'$parentname'}->can('set_child_packing')") {
        my $refpar;
        eval "\$refpar = ref ${current_form}\{'$parentname'}";
        my $new_group = $class->use_par($proto->{'packing'}, 'new_group', $NOT_WIDGET|$BOOL,  'False');
        $new_group && $class->add_to_UI($depth,  
            "${current_form}\{'$parentname'}->append_space();");

        my $expand =    $class->use_par($proto->{'packing'}, 'expand',    $NOT_WIDGET|$BOOL,  'False');
        my $fill =      $class->use_par($proto->{'packing'}, 'fill',      $NOT_WIDGET|$BOOL,  'False' );
        my $padding =   $class->use_par($proto->{'packing'}, 'padding',   $NOT_WIDGET|$DEFAULT,  0);
        my $pack_type = $class->use_par($proto->{'packing'}, 'pack_type', $NOT_WIDGET|$LOOKUP, 'start');
        if (defined $expand or defined $fill or defined $padding or defined $pack_type) {
            $class->add_to_UI($depth,  
                "${current_form}\{'$parentname'}->set_child_packing(".
                    "${current_form}\{'$childname'}, ".
                    ($expand||0).", ".($fill||0).", ".($padding||0)." , '".
                    ($pack_type||'start')."');");
        }
    } else {
        $Glade_Perl->diag_print(1, "error packing information found but ".
            "${current_form}\{'$parentname'} cannot set_child_packing() ".
            "what is wrong?");
        $Glade_Perl->diag_print(1, $proto->{'packing'}, 
            "Packing information found for '$childname'");
#print Dumper($proto);
    }
}

sub set_tooltip {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_tooltip";
    my $tooltip = $class->use_par($proto, 'tooltip', $DEFAULT, '');
    
# FIXME What do we do if tooltip is '' - set or not ?
    if ($tooltip ne '') {
        $class->add_to_UI($depth, "${current_form}\{'tooltips'}->set_tip(".
            "${current_form}\{'$parentname'}, _('$tooltip'));");

    } elsif (!defined $proto->{'widget'}{'name'}) {
        $Glade_Perl->diag_print (1, 
            "error Could not set tooltip for unnamed %s", $proto->{'widget'}{'class'});

    } else {
        $Glade_Perl->diag_print(6, 
            "warn  No tooltip specified for widget '%s'", $proto->{'widget'}{'name'});
#        $class->add_to_UI($depth, "${current_form}\{'tooltips'}->set_tip(".
#            "${current_form}\{'$parentname'}, _('$parentname'));");
    }    
}

sub set_container_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_container_properties";
#    $class->use_set_property($name, $proto, 'border_width', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'border_width', $MAYBE, $depth, 'set_border_width');
#    my $border_width  = $class->use_par($proto, 'border_width');
#    if (defined $border_width && eval "$current_form\{'$name'}->can('border_width')") {
#        $class->add_to_UI($depth, "$current_form\{'$name'}->set_border_width(".
#            "$border_width);");
#    }
}

sub xset_range_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_range_properties";
# FIXME - call this from range type widgets
# For use by HScale, VScale, HScrollbar, VScrollbar
#    my $name = $proto->{name};
    my $value     = $class->use_par($proto, 'value',     $DEFAULT, 0);
    my $lower     = $class->use_par($proto, 'lower',     $DEFAULT, 0);
    my $upper     = $class->use_par($proto, 'upper',     $DEFAULT, 0);
    my $step      = $class->use_par($proto, 'step',      $DEFAULT, 0);
    my $page      = $class->use_par($proto, 'page',      $DEFAULT, 0);
    my $page_size = $class->use_par($proto, 'page_size', $DEFAULT, 0);
    my $policy    = $class->use_par($proto, 'policy',    $LOOKUP);

    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy');");
}

sub set_misc_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_alignment";
    # For use by Arrow, Image, Label, (TipsQuery), Pixmap
    # Cater for all the usual properties (defaults not stored in XML file)
#    return unless ($proto->{'xalign'} || $proto->{'yalign'} || $proto->{'xpad'} || $proto->{'ypad'});
    my $xalign = $class->use_par($proto, 'xalign');
    my $yalign = $class->use_par($proto, 'yalign');
    my $xpad   = $class->use_par($proto, 'xpad');
    my $ypad   = $class->use_par($proto, 'ypad');

    if (defined $xalign || defined $yalign) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_alignment(".
            ($xalign||'0').", ".($yalign||'0').");");
    }
    if (defined $xpad || defined $ypad) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_padding(".
            ($xpad||'0').", ".($ypad||'0').");");
    }
#    if ($class->use_par($proto, 'visible', $BOOL|$MAYBE)) {
#        $class->add_to_UI($depth, "\$widgets->{'$name'}->show;");
#    }

#    if (defined $xalign || defined $yalign) {
#        $class->add_to_UI($depth, "${current_form}\{'$name'}->set_alignment(".
#            ($xalign||'0').", ".($yalign||'0').");");
#    }
#    if (defined $xpad || defined $ypad) {
#        $class->add_to_UI($depth, "${current_form}\{'$name'}->set_padding(".
#            ($xpad||'0').", ".($ypad||'0').");");
#    }
# FIXME - handle padding (width & height) properly
#    $class->set_widget_properties($parent, $name, $proto, $depth);
}

sub set_widget_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_widget_properties";
    # For use by all widgets

    my $width_request = $class->use_par($proto,'width_request', $MAYBE);
    my $height_request = $class->use_par($proto,'height_request', $MAYBE);
    ($width_request || $height_request) &&
        $class->add_to_UI($depth, "${current_form}\{'$name'}->set_size_request(".
            ($width_request || 0).", ".($height_request || 0).");");

    $class->use_set_property($name, $proto, 'sensitive', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'extension_events', $LOOKUP, $depth);

    $class->use_set_flag($name, $proto, 'can_default', $BOOL, $depth, 'can-default');
    $class->use_set_flag($name, $proto, 'can_focus', $BOOL, $depth, 'can-focus');
    $class->use_set_flag($name, $proto, 'has_default', $BOOL, $depth, 'has-default');
    $class->use_set_flag($name, $proto, 'has_focus', $BOOL, $depth, 'has-focus');

    my $events = $class->use_par($proto, 'events', $MAYBE);

    if ( $events) {
        $class->add_to_UI($depth, "${current_form}\{'$name'}->set_events(".
            $class->string_to_arrayref($events).");");
    }
}

sub set_label_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_label_properties";
    $class->use_set_property($name, $proto, 'use_markup', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'use_underline', $BOOL, $depth, 
        'get_child->set_use_underline');
    $class->use_set_property($name, $proto, 'selectable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'justify', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'wrap', $BOOL, $depth, 
        'set_line_wrap');

    $class->use_set_property($name, $proto, 'label', $STRING, $depth, 'set_text');

    $class->set_misc_properties($parent, $name, $proto, $depth);
}

sub set_button_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_button_properties";
    $class->use_set_property($name, $proto, 'label', $STRING, $depth);
    $class->use_set_property($name, $proto, 'relief', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'use_stock', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'use_underline', $BOOL, $depth);
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_sensitive(".
            $class->use_par($proto, 'sensitive', $BOOL, 'True').");");
    $class->set_label_properties($parent, $name, $proto, $depth);
}

sub set_window_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->set_window_properties";
# For use by Window, (ColorSelectionDialog, Dialog (InputDialog), FileSelection)
#    my $title = $class->use_par($proto,'title', $DEFAULT, '');
#    my $destroy_with_parent = $class->use_par($proto,'destroy_with_parent', $BOOL|$MAYBE);

    $class->use_set_property($name, $proto, 'window_position', $LOOKUP, $depth, 'set_position');
    $class->use_set_property($name, $proto, 'resizable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'modal', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'destroy_with_parent', $BOOL, $depth);

    my $icon = $class->use_par($proto, 'icon', $MAYBE);
    if (defined $icon) {
        $class->load_class("Gtk2::Gdk::Pixbuf");
        my $image_widget_name = "${current_form}\{'$name-image'}";
        $class->add_to_UI($depth, 
            "$image_widget_name = \$class->create_pixbuf(".
            "\"$icon\", [\"\$Glade::Two::Run::pixmaps_directory\"]);");
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_icon(".
            "$image_widget_name);");
        
    }

    my $width  = $class->use_par($proto, 'width');
    my $height = $class->use_par($proto, 'height');
    if ( (defined $width) || (defined $height)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_size_request(".
            ($width||'0').", ".($height||'0').");");
    }
    my $default_width  = $class->use_par($proto, 'default_width');
    my $default_height = $class->use_par($proto, 'default_height');
    if ( (defined $default_width) || (defined $default_height)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_default_size(".
            ($default_width||'0').", ".($default_height||'0').");");
    }
    my $x = $class->use_par($proto, 'x');
    my $y = $class->use_par($proto, 'y');
    if ( (defined $x) || (defined $y)) {
        $Glade_Perl->diag_print(1, "warn  Toplevel window uposition has been set ".
            "but breaks the window manager's placement policy, and is almost ".
            "certainly a bad idea. (Havoc Pennington)");
        $class->add_to_UI($depth, "\$widgets->{'$name'}->move(".
            ($x||'0').", ".($y||'0').");");
    }

    my $wmclass_name  = $class->use_par($proto, 'wmclass_name',  $DEFAULT, '');
    my $wmclass_class = $class->use_par($proto, 'wmclass_class', $DEFAULT, '');
    if ($wmclass_name || $wmclass_class) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_wmclass(".
            "'$wmclass_name', '$wmclass_class');");
    }
    $class->add_to_UI($depth,  "\$widgets->{'$name'}->realize();");
#use Data::Dumper;print Dumper($Glade_Perl->source);
    unless ($Glade_Perl->source->quick_gen) {
    	$widgets->{$name}->signal_connect("destroy" => sub{Gtk2->quit});
	    $widgets->{$name}->signal_connect("delete_event" => sub{Gtk2->quit});
    }
#    my $visible = $class->use_par($proto,'visible', $BOOL|$MAYBE);
#    $visible && $class->add_to_UI($depth, "\$widgets->{'$name'}->show;", 'TO_FILE_ONLY');

    $class->pack_widget($parent, $name, $proto, $depth);
}

sub pack_widget {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->pack_widget";
    $class->internal_pack_widget($parent, $name, $proto, $depth);
    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth);
    # Delete the $widget to show that it has been packed
    delete $widgets->{$name};
}

sub xnew_from_child_name {
    my ($class, $parent, $name, $proto, $depth) = @_;

    my $type = $class->use_par($proto, 'child_name');
    return undef unless $type;
    if ($type eq 'GnomeEntry:entry') {
        $type = 'gtk_entry';
#        $type =~ s/.*:(.*)/gtk_$1/;

    } elsif ($type eq 'GnomePixmapEntry:file-entry') {
        $type = 'gnome_file_entry';

    } elsif (' Toolbar:button GnomeDock:contents GnomeDruidPageStandard:vbox Dialog:action_area Dialog:vbox ' =~ m/ $type /) {
        # Keep the full child_name for later use

    } else {
        # Just use the bit after the colon
        $type =~ s/.*:(.*)/$1/;

    }
#---------------------------------------
    if ($type eq 'action_area') {
        # Gtk|Gnome::Dialog have widget tree that is not reflected by
        # the methods that access them. $dialog->action_area() points to
        # a child of $dialog->vbox() and not of $dialog. 
        # In any case, they cannot be used/accessed until something is 
        # added to them by the automagic ->new('title', 'Button_Ok',...).
        #
        # For Gnome::Dialog and derivatives we can use ->append_button() 
        # (which calls gnome_dialog_init_action_area)
        unless ($class->my_gtk_perl_can_do('gnome_dialog_append_button')) {
            # Force HButtonbox to construct its widget and add it to the VBox 
            # This will look wrong (above the separator)
            return undef;
        
        } else {
            # Append the buttons
            my $number_of_buttons = 
                $class->frig_Gnome_Dialog_buttons($parent, $proto, $depth);
            # Return the action_area now it exists
            $class->add_to_UI($depth, 
                "\$widgets->{'$name'} = ${current_window}->$type;");
        }
        
#---------------------------------------
    } elsif (' Dialog:action_area Dialog:vbox ' =~ / $type /) {
        $type =~ s/.*:(.*)/$1/;
        # Return the action_area now it exists
        $class->add_to_UI($depth, 
            "\$widgets->{'$name'} = ${current_window}->$type;");

#---------------------------------------
    } elsif (' GnomeDock:contents ' =~ / $type /) {
        return undef;
        # FIXME This doesn't make sense to me, get_client_area wants a DockItem
#            $class->add_to_UI($depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;");
#            $class->add_to_UI($depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;");

#---------------------------------------
    } elsif (' GnomeDruidPageStandard:vbox ' =~ / $type /) {
        $class->add_to_UI($depth, 
            "\$widgets->{'$name'} = ${current_form}\{'$parent'}->vbox;");

#---------------------------------------
    } elsif ($Glade_Perl->source->quick_gen || eval "${current_form}\{'$parent'}->can('$type')") {
        my $label   = $class->use_par($proto, 'label', $DEFAULT, '');
        $class->add_to_UI($depth, 
            "\$widgets->{'$name'} = ".
                "${current_form}\{'$parent'}->$type;");

        if ($label) {
            if ($Glade_Perl->source->quick_gen) {
                $class->add_to_UI($depth, 
                    "\$widgets->{'$name'}->child->set_text(_('$label'));", 
                    'TO_FILE_ONLY');

            } elsif ($widgets->{$name}->can('child')) {
                my $childref = ref $widgets->{$name}->child;
            
                if ($childref eq 'Gtk2::Label') {
                    $class->add_to_UI($depth, 
                        "\$widgets->{'$name'}->child->set_text(_('$label'));", 
                        'TO_FILE_ONLY');
                } else {
                    $Glade_Perl->diag_print (1, "error We have a label ".
                        "('%s') to set but the child of %s ".
                        "isn't a label (actually it's a %s)",
                        $label, "${current_form}\{'$name'}", $childref);
                }
            } else {
                $Glade_Perl->diag_print (1, "error We have a label ('%s') to ".
                    "set but %s doesn't have a ->child() accessor",
                    $label, "${current_form}\{'${name}'}");
            }
        }

#---------------------------------------
    } elsif ($type eq 'notebook') {
        return undef;
        
#---------------------------------------
    } else {
        $Glade_Perl->diag_print (1, "error Don't know how to get a ref to %s ".
            "(type '%s')",
            "${current_form}\{'${name}'}{'child_name'}", $type);
        return undef;
    }

# FINDME This is to remove
#    $class->add_to_UI($depth, 
#        "${current_form}\{'$name'} = \$widgets->{'$name'};");
    # Delete the $widget to show that it has been packed
#    delete $widgets->{$name};

    # Deal with all the other widget properties that might be set
#    $class->set_widget_properties($parent, $name, $proto, $depth);
#    $class->set_container_properties($parent, $name, $proto, $depth);
#    $class->set_tooltip($name, $proto, $depth);

    # we have constructed the widget so caller doesn't need to
    return 1;
}

sub new_signal {
    my ($class, $parentname, $proto, $depth) = @_;
    my $classname = ref $class || $class;
    my $me = (ref $class || $class)."->new_signal";
    my ($call, $expr, $when, $changes);
#    $class = ref $class || $class;
# FIXME to handle object - look at Glade generated code (signal_connect_object)
#print Dumper($proto);
    if ($proto->{'handler'}) {
        my $signal  = $class->use_par($proto, 'name', $NOT_PROPERTY);
        my $handler = $class->use_par($proto, 'handler', $NOT_PROPERTY);
        my $object  = $class->use_par($proto, 'object', $NOT_PROPERTY|$DEFAULT, '');
        my $after   = $class->use_par($proto, 'after', $NOT_PROPERTY|$BOOL, 'False');

#        # Triple escape any double-quotes so that they get passed through
#        $changes  = $data =~ s/(?!\\)(.)"/$1\\\\\\"/g;
#        $changes += $data =~ s/^"/\\\\\\"/g;
#        if ($changes) {
#            $Glade_Perl->diag_print (1, "warn signal handler data ('%s') ".
#                "contains %s double-quote(s) which has(ve) been ".
#                "escaped so that they are preserved. ",
#                $handler, $changes);
#        }
#FIXME Maybe this is not right - use signal_connect_object instead?
        $call = 'signal_connect';
#        if ($object) {
#            $call .= '_object';
#        }
        if ($after)  {
            $when = 'after_';
#            $call .= '_after'
        } else {
            $when = '';
#            $call .= 'signal_connect'
        }
        $handler = $class->fix_name($handler, 'TRANSLATE');

        # We can check dynamically below
        # Flag that we are done
        delete $need_handlers->{$parentname}{$signal};
        # We must log the sub name for dynamic stub handlers
        unless ( ($Glade::Two::Source::subs =~ m/ $handler /) or    
            (defined $handlers->{$handler}) or 
            ($Glade_Perl->Building_UI_only)) {
            $subs .= "$handler\n$indent".(' ' x 19);
            eval "$current_form\{$HANDLERS}{'$handler'} = 'signal'";
        }
        if ($class->can($handler) || 
            eval "$current_name->can('$handler')"
           ) {
            # Handler already available - no need to generate a stub
            eval "delete $current_form\{$HANDLERS}{'$handler'}";
            # Just connect the signal handler as best we can
            unless ($Glade_Perl->Writing_Source_only) {
                $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                    "\"\\${current_form}\{'$parentname'}->$call( ".
                    "'$signal', ".
                    "'$current_name\::$handler', ".
                    "['$object', 'name of form instance']);\"";
#print "$expr\n";
                eval $expr
            }
        } else {
            # First we'll connect a default handler to hijack the signal 
            # for us to use during the Build run
            $Glade_Perl->diag_print (4, "warn  Missing signal handler '%s' ".
                "connected to widget '%s' needs to be written",
                $handler, $object);
            unless ($Glade_Perl->Writing_Source_only) {
                $expr = 
                "${current_form}\{'$parentname'}->$call(".
                    "'$signal', \\\&".
                    (ref $class||$class)."::missing_handler, ".
                "['$parentname', '$signal', '$handler', '".$Glade_Perl->app->logo."']);";
                eval $expr;
#                print "$expr - $@\n";
            }
        }
        # Now write a signal_connect for generated code
        # All these back-slashes are really necessary as these strings
        # are passed through so many others (evals and so on)
        my $id_string = "";
        if ($Glade_Perl->source->save_connect_id) {
            $id_string = 
                "\\\\\\${current_form}\{$CONNECT_ID}{'$object'}{'$when$signal'} = ";
        }
        $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
            "\"".(ref $class||$class)."->add_to_UI(1, \\\"".$id_string.
            "\\\\\\${current_form}\{'$parentname'}->$call(".
            "'$signal', \\\\\\\"\\\\\\\$class\\\\\\\\\::$handler\\\\\\\", ".
            "['$object', \\\\\\\"$current_form_name\\\\\\\"]);\\\", 'TO_FILE_ONLY');\"";
        eval $expr
            
    } else {
        # This is a signal that we will cause
    }
}

sub new_accelerator {
    my ($class, $parentname, $proto, $depth, $gnome_frig) = @_;
    my $me = (ref $class || $class)."->new_accelerator";
#print Dumper($proto);
    my $mods = '[]';
#    my $accel_flags = "'GTK_ACCEL_VISIBLE|GTK_ACCEL_LOCKED'";
    my $accel_flags = "['visible', 'locked']";
#   my $key       = $class->use_par($proto, 'key', $NOT_WIDGET|$LOOKUP);
    my $key       = $class->use_par($proto, 'key', $NOT_PROPERTY|$KEYSYM);
    my $modifiers = $class->use_par($proto, 'modifiers', $NOT_PROPERTY|$DEFAULT, 0);
    my $signal    = $class->use_par($proto, 'signal', $NOT_PROPERTY);
    unless (defined $need_handlers->{$parentname}{$signal}) {
        $need_handlers->{$parentname}{$signal} = undef;
    }

# FIXME move this to use_par
#--------------------------------------
    # Turn GDK values into array of $LOOKUPs
    unless ($modifiers eq 0) {
        $modifiers =~ s/ *//g;
        $modifiers =~ s/GDK_//g;
        $mods = "['".lc(join ("', '", split(/\|/, $modifiers)))."']";
    }
#--------------------------------------

    if ($gnome_frig) {
        $class->add_to_UI($depth, 
            "${current_window}\->set_accelerator(".
                "$gnome_frig, $key, $mods);");
    
    } elsif ($Glade_Perl->source->quick_gen) {
        # Do no checks
        
    } elsif (eval "${current_form}\{'$parentname'}->can('$signal')") {
        $class->add_to_UI($depth, 
            "${current_form}\{'$parentname'}->add_accelerator(".
            "'$signal', ${current_form}\{'accelgroup'}, ".
            "Gtk2::Gdk->keyval_from_name('$key') || ".  # The keyval when run
            Gtk2::Gdk->keyval_from_name($key).          # Our keyval now
            " , $mods, $accel_flags".
            ");");

    } else {
        $Glade_Perl->diag_print (1, "error Widget '%s' can't emit signal ".
            "'%s' as requested - what's wrong?",
            $parentname, $signal);
    }
}

sub xnew_style {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->new_style";
    my ($state, $color, $value, $element, $lc_state);
    my ($red, $green, $blue);
    $class->add_to_UI($depth, "$current_form\{'$parentname-style'} = ".
        "new Gtk2::Style;");
#    $class->add_to_UI($depth, "$current_form\{'$parentname-style'} = ".
#       "$current_form\{'$parentname'}->style;");
    my $style_font = $class->use_par($proto, 'style_font', $DEFAULT, '');
    if ($style_font) {
        $class->add_to_UI($depth, "$current_form\{'$parentname-style'}".
            "->font(Gtk2::Gdk::Font->load('$style_font'));");
    }
    foreach $state ("NORMAL", "ACTIVE", "PRELIGHT", "SELECTED", "INSENSITIVE") {
        $lc_state = lc($state);
        foreach $color ('fg', 'bg', 'text', 'base') {
            $element = "$color-$state";
            if ($proto->{$element}) {
                $value = $class->use_par($proto, $element, $DEFAULT, '');
                $Glade_Perl->diag_print(6, "%s- We have a style element ".
                    "'%s' which is '%s'", $indent, $element, $value);
                ($red, $green, $blue) = split(',', $value);
                # Yes I really mean multiply by 257 (0x101)
                # We scale these so that 0x00 -> 0x0000
                #                        0x0c -> 0x0c0c
                #                        0xff -> 0xffff
                # This spreads the values 0x00 - 0xff throughout the possible 
                # Gdk values of 0x0000 - 0xffff rather than 0x00 - 0xff00
                $red   *= 257;
                $green *= 257;
                $blue  *= 257;
                $class->add_to_UI($depth, "$current_form\{'$parentname-$color-$lc_state'} ".
                    "= $current_form\{'$parentname-style'}->$color('$lc_state');");
                $class->add_to_UI($depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->red($red);");
                $class->add_to_UI($depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->green($green);");                
                $class->add_to_UI($depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->blue($blue);");                
                $class->add_to_UI($depth, "$current_form\{'$parentname-style'}".
                    "->$color('$lc_state', $current_form\{'$parentname-$color-$lc_state'});");
            }
        }
        $element = "bg_pixmap-${state}";
        if ($proto->{$element}) {
        	$class->add_to_UI($depth, "($current_form\{'$parentname-bg_pixmap-$lc_state'}, ".
                "$current_form\{'$parentname-bg_mask-$lc_state'}) = ".
                    "Gtk2::Gdk::Pixmap->create_from_xpm($current_window->get_toplevel->window, ".
                        "$current_form\{'$parentname-style'}, '$proto->{$element}');");
            $class->add_to_UI($depth, "$current_form\{'$parentname-style'}".
                "->bg_pixmap('$lc_state', $current_form\{'$parentname-bg_pixmap-$lc_state'});");
        }
    }
    if (eval "$current_form\{'$parentname'}->can('child')") {
        $class->add_to_UI($depth, "$current_form\{'$parentname'}->child->set_style(".
            "$current_form\{'$parentname-style'});");
    }
    $class->add_to_UI($depth, "$current_form\{'$parentname'}->set_style(".
            "$current_form\{'$parentname-style'});");
}

#===============================================================================
#=========== Glade-2 subs to create a new project
#===============================================================================
sub create_project {
    my ($class, %params) = @_;
    my $me = (ref $class||$class)."->create_project";
    # Make up basic Project.glade2perl proto in $Glade_Perl
    # Make up basic Project.glade proto in $Glade_Perl->glade->proto
    # Write to $Glade_Perl->glade->file
    # Now generate
}

sub create_glade_file {
    my ($class) = @_;
    my $me = (ref $class||$class)."->create_glade_file";
    return "<?xml version=\"1.0\"?>
<GTK-Interface>

<project>
  <name>".$class->app->name."</name>
  <program_name>".$class->app->name."</program_name>
  <directory></directory>
  <source_directory>".$class->app->source_directory."</source_directory>
  <pixmaps_directory>pixmaps</pixmaps_directory>
  <language>Perl</language>
  <gnome_support>".
  ($class->app->allow_gnome ? 'True' : 'False').
  "</gnome_support>
  <gettext_support>True</gettext_support>
  <output_translatable_strings>True</output_translatable_strings>
  <translatable_strings_file>Translations</translatable_strings_file>
</project>

<widget>
  <class>GtkWindow</class>
  <name>".$class->test->first_form."</name>
  <title>".$class->app->description."</title>
  <type>GTK_WINDOW_TOPLEVEL</type>
  <position>GTK_WIN_POS_NONE</position>
  <modal>False</modal>
  <allow_shrink>False</allow_shrink>
  <allow_grow>True</allow_grow>
  <auto_shrink>False</auto_shrink>
</widget>

</GTK-Interface>
";
}

sub test_string {
    return 
'<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="window1">
  <property name = "visible">True</property>
  <property name="title" translatable="yes">window1</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>

  <child>
    <widget class="GtkVBox" id="vbox1">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child>
        <widget class="GtkProgressBar" id="progressbar1">
          <property name="visible">True</property>
          <property name="orientation">GTK_PROGRESS_LEFT_TO_RIGHT</property>
          <property name="fraction">0.42</property>
          <property name="pulse_step">0.1</property>
          <property name="activity_mode">False</property>
          <property name="show_text">False</property>
          <property name="text_xalign">0.5</property>
          <property name="text_yalign">0.5</property>
        </widget>
        <packing>
          <property name="padding">0</property>
          <property name="expand">False</property>
          <property name="fill">False</property>
        </packing>
      </child>

      <child>
        <widget class="GtkButton" id="button1">
          <property name="visible">True</property>
          <property name="can_focus">True</property>
          <property name="label" translatable="yes">Click here to close this window and carry out the other tests</property>
          <property name="use_underline">True</property>
          <property name="relief">GTK_RELIEF_NORMAL</property>
          <signal name="clicked" handler="destroy_Form" last_modification_time="Fri, 24 May 2002 14:07:26 GMT"/>
          <accelerator key="Q" modifiers="GDK_CONTROL_MASK" signal="clicked"/>
        </widget>
        <packing>
          <property name="padding">0</property>
          <property name="expand">True</property>
          <property name="fill">True</property>
        </packing>
      </child>

      <child>
        <placeholder/>
      </child>
    </widget>
  </child>
</widget>

<widget class="GtkFileSelection" id="Gtk_Fileselection1">
  <property name="border_width">10</property>
  <property name="visible">True</property>
  <property name="title" translatable="yes">Select File</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="show_fileops">True</property>

  <child internal-child="cancel_button">
    <widget class="GtkButton" id="button85">
      <property name="visible">True</property>
      <property name="can_default">True</property>
      <property name="can_focus">True</property>
      <property name="relief">GTK_RELIEF_NORMAL</property>
    </widget>
  </child>

  <child internal-child="ok_button">
    <widget class="GtkButton" id="button86">
      <property name="visible">True</property>
      <property name="can_default">True</property>
      <property name="can_focus">True</property>
      <property name="relief">GTK_RELIEF_NORMAL</property>
    </widget>
  </child>
</widget>

</glade-interface>
';
}

sub our_logo {
return '/* XPM */
static char *Logo[] = {
/* width height num_colors chars_per_pixel */
"    66    97      256            2",
/* colors */
".. c #000008",
".# c #008808",
".a c #880400",
".b c #004400",
".c c #000088",
".d c #808480",
".e c #08c010",
".f c #480000",
".g c #082090",
".h c #08e410",
".i c #886898",
".j c #c00410",
".k c #002400",
".l c #80cc98",
".m c #000048",
".n c #30e430",
".o c #0044e0",
".p c #0008c8",
".q c #c81810",
".r c #00f408",
".s c #280000",
".t c #e80408",
".u c #c0c8c8",
".v c #0024d8",
".w c #d8e0e0",
".x c #001400",
".y c #0834d8",
".z c #489448",
".A c #982018",
".B c #00a400",
".C c #38c830",
".D c #484440",
".E c #e8e8e8",
".F c #a00408",
".G c #0014d0",
".H c #001490",
".I c #784c80",
".J c #18f410",
".K c #000028",
".L c #0860f8",
".M c #20e410",
".N c #e01010",
".O c #e8f8f0",
".P c #a0a4a0",
".Q c #08d408",
".R c #c81010",
".S c #102070",
".T c #606460",
".U c #1834d8",
".V c #2840d0",
".W c #20a410",
".X c #2028f0",
".Y c #2018f0",
".Z c #202428",
".0 c #0014e8",
".1 c #200450",
".2 c #288420",
".3 c #001450",
".4 c #0008b0",
".5 c #100000",
".6 c #a81410",
".7 c #0824f0",
".8 c #402c48",
".9 c #0854f8",
"#. c #00fc00",
"## c #0834f8",
"#a c #881410",
"#b c #20d410",
"#c c #006400",
"#d c #f8fcf8",
"#e c #009408",
"#f c #000068",
"#g c #f80400",
"#h c #505450",
"#i c #28e428",
"#j c #c01428",
"#k c #680000",
"#l c #001828",
"#m c #38d430",
"#n c #0014b0",
"#o c #20f028",
"#p c #08ec28",
"#q c #a88cb0",
"#r c #0008e8",
"#s c #e81c20",
"#t c #c0a4c0",
"#u c #f00c08",
"#v c #20b420",
"#w c #1848d8",
"#x c #f0d0f0",
"#y c #003800",
"#z c #20d828",
"#A c #08ec08",
"#B c #30f820",
"#C c #f8ecf0",
"#D c #100028",
"#E c #d81010",
"#F c #a084b8",
"#G c #101410",
"#H c #083cf8",
"#I c #000800",
"#J c #0018d0",
"#K c #c02028",
"#L c #c8d4c8",
"#M c #b80808",
"#N c #082cf8",
"#O c #50dc58",
"#P c #900400",
"#Q c #000c88",
"#R c #d80808",
"#S c #001ce8",
"#T c #681810",
"#U c #20c410",
"#V c #00b800",
"#W c #203428",
"#X c #100ca8",
"#Y c #10fc10",
"#Z c #38dc38",
"#0 c #48e440",
"#1 c #108810",
"#2 c #909490",
"#3 c #281810",
"#4 c #c8fce0",
"#5 c #20ec28",
"#6 c #10f410",
"#7 c #100c08",
"#8 c #b81418",
"#9 c #0818b0",
"a. c #102418",
"a# c #40ac40",
"aa c #b0fcd8",
"ab c #706c88",
"ac c #4064f8",
"ad c #7884a0",
"ae c #204418",
"af c #b8c4c8",
"ag c #382450",
"ah c #782c30",
"ai c #2860f8",
"aj c #007400",
"ak c #90a0e8",
"al c #5884a0",
"am c #202cc0",
"an c #b02018",
"ao c #481818",
"ap c #209820",
"aq c #607468",
"ar c #585858",
"as c #b8bcb8",
"at c #205c38",
"au c #005400",
"av c #889cd0",
"aw c #286c38",
"ax c #b0b4b0",
"ay c #2854f8",
"az c #483c40",
"aA c #303840",
"aB c #48c450",
"aC c #807878",
"aD c #1030a0",
"aE c #381c40",
"aF c #603c68",
"aG c #584c60",
"aH c #30b440",
"aI c #b8dcd0",
"aJ c #706480",
"aK c #2870f8",
"aL c #787890",
"aM c #c0d4f0",
"aN c #18b428",
"aO c #203050",
"aP c #a8aca8",
"aQ c #989498",
"aR c #787878",
"aS c #300000",
"aT c #304838",
"aU c #389428",
"aV c #a0b4d0",
"aW c #b03020",
"aX c #a898a8",
"aY c #583868",
"aZ c #001070",
"a0 c #20c828",
"a1 c #281830",
"a2 c #104820",
"a3 c #103420",
"a4 c #107408",
"a5 c #c8bcd0",
"a6 c #c82428",
"a7 c #58bc58",
"a8 c #186cf8",
"a9 c #10c828",
"b. c #d0c8d8",
"b# c #18a410",
"ba c #686868",
"bb c #28a828",
"bc c #109810",
"bd c #780000",
"be c #30b428",
"bf c #701408",
"bg c #401838",
"bh c #a098b0",
"bi c #902c28",
"bj c #908890",
"bk c #1008c8",
"bl c #d81c10",
"bm c #181820",
"bn c #d0d4d0",
"bo c #10b810",
"bp c #383838",
"bq c #d8f8e0",
"br c #d8d4e0",
"bs c #38e440",
"bt c #1834f8",
"bu c #605870",
"bv c #981408",
"bw c #082030",
"bx c #200428",
"by c #30f838",
"bz c #500000",
"bA c #1854f8",
"bB c #d81020",
"bC c #c090c0",
"bD c #f81c18",
"bE c #484848",
"bF c #08dc10",
"bG c #282c28",
"bH c #405c48",
"bI c #2838a0",
"bJ c #887890",
"bK c #6878b0",
"bL c #0044f8",
"bM c #1044f8",
"bN c #187828",
"bO c #0824b8",
"bP c #1060f8",
"bQ c #2044f8",
"bR c #d01c28",
"bS c #102428",
"bT c #385848",
"bU c #300830",
"bV c #08c808",
"bW c #000c48",
"bX c #002cd8",
"bY c #d0e8d8",
"bZ c #083cd8",
"b0 c #001890",
"b1 c #18fc10",
"b2 c #18ec10",
"b3 c #a0a8a0",
"b4 c #081c48",
"b5 c #18dc10",
"b6 c #006c00",
"b7 c #000c70",
"b8 c #20fc28",
"b9 c #f0dcf0",
/* pixels */
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#C#d#C#d#d#d#d#d#d#C#d#d#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#d...P#d#d.ObWbW#l#I#I#d.O#d#d#d#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#dbE..#7bhadaOb4.K#I#I..aL.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#dbq#d.w.d..#I.......K...K.c.c#f.K...5aGax#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#d.w#I..........#I.K.Kb7.p#r.4.m....#D.5bj#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.P...............K.K#f.G#r#r.7ac.7.G#f.K.K..bE#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O.O.O#G....a........K.m#f#J.pbtay.v#N#N.p.c#f.K.K...d#d#C#d#d#d.E#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#LbG..........#I.K.m.4.p#SbM#H#####H.vbL.G##.y#f#f.K..#I.d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d.E#d.E.O...x#I..#7...3#f.c.p#S#r#r#r.0.p.p.G#N#Na8.p#H#r.v#n.m.K.....K#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d.O.O#2..#I.........K.m#X.4.X.X#r#r.G.4.4#f.4.4bt.Uai#r#Nbt#J#Q.m.K....aza5#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#C#d#d#dbq#d.u...5.......K.m.c#X.c.m.m#f#f.m.K.K.........K.K.K#f.4.vbZ###S#r.4.m.K....#I#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d.O#d#d#2bp..........#f.c.p.c.m.....K.K.....................K.m.3#Q.4.7.X.X#f.m......aR#C#d#C#d.O#C#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d.O#db3.5......#I.m#f.4.p.p.c.K...............K.m.m...............K.K.K#Q#N####.G.c#f.K....bua5#C#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d.O#L#I....#I...m#Q.G#S.p.4.m.............K.m#Q#Qb7.K.K.K..............#f.7#####r#S.4#f.K.K#D..#d#d#C#d.O#d#d#d#d#d#d",
"#d#d#d#d#d#d#daq.......K.maZ.H#n.Xbt.Y#f.m...........m#f.p#r#r##.y#J.0.p#QbW...5.......K.H#n##a8.7##.G.4#f......#C#d#d.O#d#d#d#d#d#d",
"#d#d#d#d.O#d#L.........m.4.4#nbZbt#r.G.K#I.......K#f.4.4###N#HbAbL##bQ#H.vb7.K...5.....K.m#9#H##bL#H#N###J.mbW...Tbj#C#d#d#d#d#d#d#d",
"#C#d#d#daPaq...K.K.K.m.p#S#N#N##bt#f.m.........K.4#r.7##bL.9.LbLbL#HbL#HbM.p.4#f.K......#f#9.0bL.9###H#9ai.G.pb7......aC#C#C#d#d#d#d",
"#d.E#daP.....K#f#f#Q.G#N#HbL#N#H#N#f.m.........m#r.7#H.9.9.9#HbL#H#r.7#Sai#SbX#n#f#I#I...m#9.o.9bL.9.LbL.9bA#H.0#f.m#l..aL#d#d#d#d#d",
"#dbm#daP.....3#Q#Q.G#N#N#HbL#NbL.y#f.K.........m#S.7bL.9.obL#N#H#N.p.0.0.7aiay.p.4.K...K.cbObLbZbZ.9#H.9bLbLbL###J.4.K.K.K.P#C#d#d#d",
"#d.......5.5.m.V.v#H##bL#H#N###H#w.m.K.......K.m#J#N#HbLbL##bt#r.c.m.m#Q.4acbM#r#r.p.p.G#r#N##bLbX.9.0bLbL.v#H#H.7.0.4bI.K..aG#d#C#d",
".O#I.s.5.saS..#f#nbt#H##bL#HbL.L.9#n#f.K.......m#S#N#HbL#H#H#N.p.m...K.K.c#J#S#H##.0ai.y###HbP###HbL#H#HbL.o.9aK.G.4b7b0.K..ba#d#d#d",
"#d......bda6bz.K#f.c#9#N#H#HbLbL#H#S.4.K.......K#S.7#H.9.9#N#N#f.K.........m.c.v#N#SbL#H.ybLa8.7bL##bLbLbLbP.9#H#X.m#I#y#y..#h#d#d#d",
"#C#I#I#Ibd.R#P.5.K#f#f.v###H.o#H###N.G.m.K.....K.p.0#N.9bL.9.0#f.K...........m#Q.p#N##bL.L.o#HbLbA#HbLbL##bL.vbZ.m.K#yaBa7..ar#d#C#d",
"#d.x..#I.a#E.t.Fbz.....m.vbt#HbM#HbL#H.4.m.......m#f#w#JbAbL.G.p.m...........K.m#f#rbM#HbLbLbL#HbLbL#N.UbQ.c#f#laub#b8b2.b#I.T#d#d#d",
"bq#l.....a#R#g#R.FaS...K#Q#n#r.0##bL##.4#Q.........Kb0#nai#H.7#r.4.K...........m.c#r.X.ybP##.9.7#N#H.G#n#Q.m.K#cby#6.r#6.k..#h#d#d.O",
".O.x.....a.t#g.t.N#M.a.5...Kb7.4.7#NbA#N#N#f.......K.K.K#f.p.p.7bk.m.....K.....c.p###N#HbL#H.0#N.4#9#f.K#I#yb6#A#.#.#.#p.k..ar#d#d#d",
"#d.x....#P.t#g.t.t#g.t.a.5.....Kb7#N#S#H#H.4bW#I...........K.K.m.K..........b7#J#N#H#HbL#Nbt#n.c.K..#Iau.Bb1.r#.#6#.#.#p.k..bu#d#d#d",
".O.x....#P.t#g#g.t#g#g#RaS.......K#X.p#H#H#J.K.K..#I.............K.....K.K.m#n#N#H##bLbX.v.U#f.K#I.x.x#U#6#.#..r#6#Y#.#A.k..bJ#C#d#d",
".O.k.....a#R#g#g#g#g#g#u#8.a.s.5.....m#9#n.y.G.G#Q.m.....K.......K...Kb7.p.0#N.y.ybO#w#Q.K.K.x.xb6#m.J#.#.#..r#..r#.#..M.xaE#x#d#d#d",
"bq.k....#P.t#g#g#g#g#g.t.N.jaS.5.5...K#f.c#N##.X.p.c#f#f#f.K.....K.m#Q#9.0#S.7.0.4.g#Q.m..#I#y#c#V.J#.#..r#.#..r#.#.#.#p.xaY#C#C#d#d",
".O.k#I..#P#R#g#u#g#g#g#g#g#g#jbd.saoaS.5...m.X.X#H##bA#H#rbk.c.c.4bXbL#H#N#S.4bW.K.K..#Iau.#.Mb2#Y#.#..r#.#.#.#..r#.#.#A.x.i#C#C#d#d",
".Oa3#I#I.a.t#g#u#g#g#g#u#g#g#R#j.fahbz.s.s.K#9.0#H#HbLbL.0#r.Y.p.G##bLbL.v.p.m........#y#5#Y#.#.#.#.#.#Y#.#.#..r#Y#.#.#o..#C#C#d#C#d",
"bqa3....bd.N#g#g#g#g#g.t#g#g#g#gblbz#ka6#8aS.K.m#n.v#N#NbL#H#H#HbMbL.0.4#f.m#D..#I#ybc#i#6.r#.#.#6#.#.#A#Y.n#c#6#A.rb5#c..ab#C#C#d#d",
"bqa...#Ibd.t#g#u#g#g#R.R#g#g#g#g.N#P#P#M#j.aaS...m.c#JbA#H#H##.7b0#Q#Q.c.K.KbW#I#y#U#5.Jb2b1.r#..r.r#.#5aNb6#y.h.r#.#b#y.Kb.#d#d#d#d",
".ObS#I#I.a.t#g#g#g.jbd.s#k.6#u#g#g#g.t.a#P.NbB.j.f.5.m.H#J#N.7.p#Q.K.K#D....#y.Bby#..r#..r#..r#.#.b8.B.k.x.x#y.J#.#.bo#y..#C#d#d#d#d",
"#dbS#I..#P.t.t#g#g.6.f...5.5#kbdbl.t.t#E.Fbz.R.N#E#P.5.K#f.4#9aD.K.5....#c.Bb8.r#.#.#.#.#.#.#.#.#A#Z.x..#I.b#Z#.#.#.bc.x.5#d#d#d#d#d",
"#d.x....#P.t#g#g.tbvaS.......5.sbvbB.t.t#E#kbd#8.N.jbz.s.K#faZal#l..#I.k.e#o.r#.#.#.#.#.#.#.#.#.#5au..#I#Iau#i#.#.#.bc.x.5#d#d#d#d#d",
".O......#P.t#g#g.tbz.5...........5.f.a.t#g.NaSaS#P#R.N.6.5#D...k.x#ca9#o#6#..J.nbF#6#.#..r#.#.b8au.x.K...x#5#.#.#.#..#.x..#d#d#d#d#d",
"#d.......a.N#g#g#gaS.5...........s.5aS#M.t#u.abzbzbd#R.Nbf...xb#.B#5#6.r#6#5#e.2au.h#.#.#.#..hbs.k#I....aub1.r#.#.#.aj.x..#C#C#d#d#d",
"#d.......a.N#g#g#g.s............#I...5.5.fbda6.qaS.s#k#8#8.5.x#U.J#.#.#.#Ub6.x.x.b.r#.#.#..r#1.k....#I#c.B#..r#Y.r#Y#y...K#C#C#d#d#d",
"#d.......a.N#g#g#g#k.5.5.........x........aS.F.6#T.saS.abl...x#0.h#.#.#6.W.k#I.x.W#..r#..r#6.x.......x#zb8#.#..r#6b2.x...1#C#C#d#d#d",
".O.x.5..bd#j#g#g#g.t.t#EaS.5.................5.5bdanbd#P#8.....b#5#.#..J#y#I#I.xa4#A#.#.#i.b....#I#I.k.r#Y#.#.#.#Abe#I..bC#d#d#d#d#d",
"#d.......abB#g#g#g#g#g#sbd.f.5..................bd.R.j#R.R.5#I.k.Q#.#.#6.x.x...xaubo.Q#A.W.x....#I.x#e#.#6#.#.#.#A.W#I..#x#d#d#d#d#d",
"#d.......fbd.t#g#g#g#g#g.N#j.s.5...5........#I#I#k.R.t#g#8.5..#yaj.r#.b2.x#I...xae.x.##m#I.....K.x.##Y#..r#.#.#.#A.W#I#I#d#d#d#d#d#d",
"bq#I.5...s.f#g#u#g#g#g#g.t#j.s........#I....#I..#k#R#g#gan..#I.x#e.r.rb2.x#I..#IbT#I.x#y#I.......##5#.#..r#.#.#..h.#.x..#d#d#d#d#d#d",
"bY...5.5#T.a#g#g#g#g#g#g#u#j.5..............#I..bd#E#g#gan.5#I.x.##A#..J.x.....xbT.x#I.x#I.....xbs.h#..r#.#.#.#.#oap#I#I#C#d#d#d#d#d",
"bq#I.....F#R#g#g#g#g#g#g.N#8.5........aSaS.s....#k#K.t#ubvaS.5.x#m#Y#.#6.x#I#I.xae......#I#I.xau#.#.#.#.#.#.#.#..naj#I..#d#d#d#d#d#d",
"#4.k....#P#R#g#g#g#g#g#g#R.6.5.5......bd.a.a.s..aSbd#R#g#a.5...xbo#Y#.#6.x#I#I#Ia...........#ybs#.#.#.#.#.#.#.#.#Z.b#I..#d#d#d#d#d#d",
"aaat.5.s#kbd#g#g#g#g#g#g.t.6.5.....5.s.R#u.N#M.F.F#M#g#gbf.....x#c#6#.#Y.x..#I.....5........#yaHby#..r#.#.#.#..Jaj.x....#d#d#d#d#d#d",
"aaa2.5.s#kbd#g#g#g#g#g#g#R.6.5.....5.s#R#g#g#g.t.t.t#g#gbf....#Iau#p#.#A.x.......5.......5...k#y#z#p#A#.#.#.#.b2.b.x...K#d#d#d#d#d#d",
"bq#y..#I#P#R#u.t#g#g#g#g#Rbv..#I....aS.t#g#g#g#g.t#g#g#g#a.5...xau#o#.b2#I...K......#I.........x.k.k#m.r.r#.#.b2.k#I#D#D#d#d#d#d#d#d",
".Oa3#I.x#M.t#g#g.t#g#g#g.j#a.........f.t#g#g#g#g#g#g#g#g.a.5...k#e#.#..J.x........#I...5....#I#I.x.x.b#o.h#.#.#Y#y#I.Kbx#d#d#d#d#d#d",
"#4.k...5bB#g#g#g.t#g#g#g#R#a.......5#k#u#g#g#g#g#g#g#u#g.a.....b#i.r#.#A#I.......x#y.b#1.x.x#I......#I.bb6a9.h.h.k...5#q#d#d#d#d#d#d",
"bq.x.5...j#g#g#g#g#g#g#g.t.F.......sbd#u#g#g#g#g#g#g#g#g.a.5#Iaj#z#.#..r.x.....x.b#5#o#Y#V#e.x......#I..#7.k.##m.k.x#G.E#C#d#d#d#d#d",
"bY#I....#M#u#g#g#g#g#g#g.t#8.5.....s.a.t#g#g#g#g#g#g#g#g.a..#Ibb#o.r#.#A.x#I...xbb#..r#.#A#5#y.x..#I#I.5...k#y.n.k.xbS#d#d#d#d#d#d#d",
"bq.k..#Ibdbl.t#g#g#g#u.t#u#8.5.....sbd.t#g#g#g#g#g#g#g#g.a..#I#ObF#.#.#A.x.....k#m#.#.#.#.#.#p#5b6.k.....x#V.J.M.x.x.D.O#G#C#d#d#d#d",
"#4aw...x#kbl.t#g#g#g.t.t.t.F.5.....5.a.N#g#g#g#g#g#g.t#g.a.5#Ia0#o#.#.#6.x#I...b#z#.#.#.#.#.#..r#z.#.x.x.kb1.r.h.x#I..bT..#d.O#d#C#d",
"#4.l.x.5#P.j#g#g#g#g#g#g.N#M.5.....5bd.t#g#g#g#g#g#g#g#g.a.5#I#ib2#.#..M#I..#I#y#z#Y.r#Y#.#.#.#.#.b8.e.B#6#.#..M.x...x..aQ#d#d#d#d#d",
"#4bq#G..#k#K#g#g#g#g#g#g#u.j.s.....5bd#g#g#g#g#g#g#g#g#g.a..#I#Zb2#.#A.n.x#I...b#Z.r#Y#6#.#.#.#.#..r#Y.r#.#.#.#Z.x#I.x..#d#d#C#d#C#d",
"#d.E#7...saS.F#R#g#g.t#g#g.N.6#k.f.sbd.t#g#g#g#g#g#g#g#g.a..#I.n.M#.b8be.......ba0#.#.#6#.#.#.#.#.#.#.#.#.#A#o.k......#I.K#C#d#d#d#d",
"#C#da5aO....bz.F#R#g#g#g#g#g#E#MbdaSbd.t#g#g#g#g#g#g#g#gbd.5#Ibs.M#.b2aj....#Iaua9#.#.#..r#.#.#.#..r#Y#..r#iap#I..#7.x..#F#d#d#d#d#d",
"#d#C.Obq.....5aSaS.6#j#g#g#g#g#g.N.R#R#g#g#g#g#g#g#g#g#g#T.5#I#m#A#..h#y....#I#c#i#.#.#.#.#.#.#.#.#.#..nbc.k.x......aR.u#C#d#d#d#d#d",
"#d#d#d.Oadba.....5.s#k.N#g#g.t.t#g.t.t#g#g#g#g#g#g#g#g#g.f.5..#Zb2#.b5bc#I..#y#A#.#.#.#.#.#.#.#..h.r#v.k.x.x#I..aL.w#d#d#d#d#d#d#d#d",
"#C#d.O.O#d#C.Z#I...5aS.j.t.t#g.t#g#g#g#g#g#g#g#g#g#g#g#gaS..#I#Z#p#.#ZaB.k.kbc#Y#.#.#.#.#.#.#.#..hbs#y.k.x.......E#d.O#d#d#d#d#d#d#d",
"#d#C#d#d#d.O#da..x.....s#8bB.t#g#g#g#g#g#g#g#g#g#g#g.t.N.s..#I#i#p.r.##y#z#o#..r#.#.#.#.#.#.b2.n#1.k.x.....8#C#C#d#d#d#d#d#d#d#d#d#d",
"#d#d.O#d#d#d.O.OaI#I#I.5bz.F#g#g#g#g#g#g#g#g#g#g#g#g.t#R.5...x#5#A#.bFbV#Y#.#.#.#.#.#.#.#6#A.B#c.x#I....#D#x#C#C#dbq#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d.Obqbq......#kbR#g#g#g#g#g#g.t#g#g#g.t#8.5...x#zb8#.#.#.#.#..r#.#.#.#..J#map.x.x....azb.#C#d#d#d#d.O#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d.ObqaR..#IaS.f.N#g#g#g#g#g#g#g#g#g.t.6.5..#I#z#A#.#.#.#.#.#.#.#.#..r#z#1.x#I#I#I..b9#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
".O#d#d#d#d#d#d#d#d#d#d#CaT...k#IaSbB.t#g#g#g#g#g#g#g#Ebv.5..#I#z#o.r.r.r#.#.#.#..r.M#v.x.x......#C#C#d#d#d#d.O.O#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d.wbE..#I..#k#M#g#g#g#g#g#g#g.t.A.5..#I#z#o.r#.#.#.#.#6#.#Yb6#y.x.....P#L#d#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d.O#d#d#d#d.O#d#d#dbhbw...5.f#M.t#g#g#g#g#g.t.A.5..#I#5.r#..r#..r.r#B#c#y...x..araQ#d#d#d#d.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.d...5.5.f.N#g#g#g#g#R.6.5#I.x#Y#.#.#..r#6.e.k#I.......w#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d..#I...5#K#u#g#g#g#R.F.5.x.b.r.r#.#.#6a0b6.x..#G.ZbE#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#d#d.....sa6.jbD#RbB.a#I.xb6#.#..M#v.b.x.x..aG#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C.E.T.5.fbv#M#s#j.a...x.##.#Y#Z.k#I....bU.E#C.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#db9..#7.s.fbd.f...xaU#1au.k#I...i#t#d#d#C#C.O#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#dbG...5.5aS.s...xa2.x.x#I....#C#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O.w.x..........#Iag#D.Ka5#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.ObG...x....#Ibw.K#DaG#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#d#C#C......#lbwabas#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#d#C#CbqaT....b.#d#C#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#db9#C#dbqbY..aG#d#C#C#C#d.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#C#d.O#d#C#d#d#d#d#d#C#d#d#d#C#d#d#d#d#d#d#d#C#d#d#d#d#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#d#d#d#d#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d",
"#d.O#d#d#d#d#d#d.E#d#d#d.P#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#dbj.u#d",
"#d#d#d#daA.d......#d#dbm..aC#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.u#G........#I#h#d#d#d#d#d#d#d#d#d#d#d#d#h....#2#d",
"#d#d.u#G#d#C#dba#d#d#Cba#IaR#d.O#d#d#d#d#d#d#C#L#C#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#daR.T#G.ZaR......as.O#d#d#d#d#d#d#d#d#d#d.Eas..aR#d",
"#d#d#IaR#d#d#d#d#d#d#daR..aC#d#d#d#d#d#d#d.u...D#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d..ba#d#d.Z#IaR#d#d#d#d#d#d#d#d#d#d#d#d#d#Iba#d",
"#C#L...d#d#d#d#d#d#d#d.d..aR#d#d#C.d.u.O#dbp....#h.d#d#d#d#d#d#d.d.u#d#d#d#d#C#d#d#d#d..aC#d#daR..as#d#d#d.das#d#d#d#d#d.d#d#d..aR#d",
"#d.d..aR#d#d#dbm....#daC...d#d#daR.....u#d#d#d#dbG#I..#I#C.O.DaRaA#7.E#d#d#d#d#d#d#d#d..aR#d.D#W#d#d#dbpaR..#I.u..#I#h....#d#d...D#d",
"#d#2....#d#d#d#d.D..as.d..aR#d#d#dar..#I.u#d.D..#d#d....aC#I..#das.O#d#d....#I#7ax#d#d..aR#d#d#d#d#d..#d#dbG#d#d.d..aq#d#d#C#d....#d",
"#dax....#d#d#d#CaR#I#daR..aR#d.wbE........#d..#I#d#dba#I#d..#7as.u#d#d#d......aR#d#d#d...d#d#d#C#d#C..#das#d#d#d.d...d.E#d#d#d..#I#d",
"#d#d..#I...D#d#dbp#d#daR...d#2..#d#C#d....#d....#d#dbG#h#C....#h#d#d#d#d.E#d#d#d#d#d#d...d#d#d#d#C#d#I..az#d#d#d.d...d#d#d#C#d.x..#d",
"#d#d.P#7#I...DbEba#d#daR..aR.......daRbp..aR.....D.daz#d#daR......#7#d#d#d#d#d#d#d#d#d...P#d#C#d#d#d.d..#I..#3#daC..ba#d#d#d#C....#d",
"#d#d#d#das.Tax#d#C#d#das#d#C.O.u.d#C#d.Ebn.O#CaxaC.E#d.O#d#d.O.Taq.O#d#d#d#d#d#d#d#d#d#C#d#d#d#d#d#d#dasba#d#d#d#C#C.E#d#d#d#d#C#d#d",
"#d#d#d#d#d#d#d#d#d.O#d#d#d#d#d#C#C#d#d#d#C#d#d.O#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d.O#d#d#d#d#d#d#C#d.E#d#d#d#d#d#d#d#d#d#d#d#d",
"#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#d#C#d#d#d#d#d.E#d#d#d.O#d#d#d#d#d#d#d#d#d#d#d.O#d#d#d#d#d#d#d#d#d.E#d#C#d#d#d#d#d#C#d.E#d"
'}

sub xconvert_glade2_proto_to_glade1 {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = (ref $class || $class)."->convert_glade1_proto_to_glade2";
    my $xml = Glade::PerlRun->string_from_file($proto);
    my ($encoding, $tree) = Glade::PerlXML->tree_from_string($xml, 'ISO-8859-1');
#    my $depth = 0;
    my $protop = old_glade1_proto_from_tree(
            $tree->[1], $depth, 
            '  ', 
            ' project ', 
            'ISO-8859-1');
    return ($protop, $proto);
}

sub convert_proto_to_glade1 {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = (ref $class||$class)."->convert_glade2_proto_to_glade1";
    my ($key, $val, $limit, $protop, $propkey, $value, $work, $seqkey);
    my $prune = "*$Glade::PerlRun::permitted_fields*";
    my $proto2 = {};
    my $contents = '';
    my $child;
    # make up the start tag 
    foreach $key ('widget', sort keys %{$proto}) {
        next unless keys %{$proto->{$key}};
        unless ($prune =~ /\*$key\*/) {
            if (ref $proto->{$key} eq 'ARRAY') {
print "expanding array '$key'\n";
print Dumper($proto->{$key});
                foreach $child (@{$proto->{$key}}) {
                    $contents .= "\n" if $key eq 'child';
                    # Expand each sub tree in array
                    ($protop, $proto2->{$key}) = 
                        $class->convert_proto_to_glade1(
                            $key,
                            $child, 
                            $depth);
                }

            } elsif (ref $proto->{$key} eq 'HASH') {
                if (' widget ' =~ / $key /) {
print "expanding widget hash '$proto->{$key}{'id'}'\n";
print Dumper($proto->{$key});
                    $Glade_Perl->widgets->{'converted'}++;
                    # Make up widget starttag
                    $seqkey = "~widget-".sprintf("%04d", ++$seq);
                    foreach $propkey (%{$proto->{$key}{'property'}}) {
                       $work->{$propkey} = $proto->{$key}{'property'}{$propkey}{'value'};
                    }
print "New widget $seqkey ", Dumper($proto2);
                    $work->{'class'} = $proto->{$key}{'class'};
                    $work->{'name'} = $proto->{$key}{'id'};
#                    delete $work->{'id'};
                    # Move packing information
                    if (keys %{$proto->{$key}{'packing'}}) {
                        foreach $propkey (keys %{$proto->{$key}{'packing'}}) {
print "Packing $propkey is '$proto->{$key}{'packing'}{$propkey}{'value'}'\n";
                            $work->{'child'}{$propkey} = $proto->{$key}{'packing'}{$propkey}{'value'};
                        }
#                        $work->{'child'} = $proto->{$key}{'packing'};
                        delete $proto->{$key}{'packing'};
                    }
#                    ($protop, $work->{$seqkey}) = 
#                        $class->convert_glade2_proto_to_glade1(
#                            $key,
#                            $proto->{$key}{'child'},
#                            $depth+1);
#                    push @{$proto2}, $work;
                    $proto->{$seqkey} = $work;
                    
                } elsif (' property ' =~ / $key /) {
print "expanding property hash \n";
print Dumper($proto->{$key});
                    foreach $propkey (keys %{$proto->{$key}}) {
                        $proto2->{$propkey} = $proto->{$key}{$propkey}{'value'};
                    }
                    delete $proto->{$key};
                    
                } else {
print "expanding simple hash '$key'\n";
print Dumper($proto->{$key});
                    # call ourself to expand nested xml
                    ($protop, $proto2->{$key}) = 
                        $class->glade1_proto_from_glade2_proto(
                            $key,
                            $proto->{$key}, 
                            $depth);
                }

            } else {
                # We are simple element so store as attributes
print "foreach key in '".ref $proto->{$key}."' '$key'\n", Dumper($proto);
                foreach $propkey (keys %{$proto}) {
print "Propkey2 '$propkey' => '$proto->{$propkey}'\n";
                    unless (' value ' =~ / $propkey /) {
                        $proto2->{$propkey} = $proto->{$propkey}{'value'};
#                        $starttag .= " $propkey=\"$proto->{$propkey}\"";
                    }
                }
                if (defined $value && $value ne '') {
                    $value = &Glade::PerlRun::QuoteXMLChars($value);
print "Value '$value'\n";
                }
            }
        }
        delete $proto->{$key};
#print "Deleting key '$key'\n";
    }

    # make up the string to return
    if (defined $contents && $contents eq '') {
        if ($key && $key eq 'child') {
#            $xml .= "$prefix<$stag>\n".
#                "$newprefix<placeholder />\n".
#                "$prefix</$etag>";

        } elsif ($key && $key ne '') {
#            $xml .= "$prefix<$stag />";
        }

    } else {
        if (defined $key && $key ne '' && $key ne 'form') {
#            $xml .= "$prefix<$stag>$contents\n$prefix</$etag>";
        } else {
#            $xml .= "$contents";
        }
    }
    return $protop, $proto2;
}
    
sub string_from_proto {
    my ($class, $prefix, $tab, $stag, $etag, $proto) = @_;
    my $me = (ref $class||$class)."->string_from_proto";
    my ($key, $val, $limit, $starttag, $propkey, $value);
    my $prune = "*$Glade::PerlRun::permitted_fields*";
    my $child;
    my $xml = '';
    my $contents = '';
    my $newprefix = '';
    $newprefix = "$tab$prefix" if defined $stag;
    unless (defined $etag) {
        # We are the file level so add toplevel widgets in order
        foreach $child (@{$proto->{'widget'}{'child'}}) {
            $contents .= "\n".$class->string_from_proto(
                $newprefix, $tab, '', '', $child, $prune);
        }
        return "<$stag>$contents\n</$stag>\n";
    }
    $etag ||= $stag;
    # make up the start tag 
    foreach $key ('property', 'signal', 'accelerator', 'requires', 
        'child', 'widget', 'packing', sort keys %$proto) {
        unless ($prune =~ /\*$key\*/) {
            if ($etag && ' signal accelerator requires ' =~ / $etag /) {
                # We are simple element (no value) so store as attributes
                $starttag = $stag;
                # Store 'name' as first attribute
                foreach $propkey ('name', 'signal') {
                    if ($proto->{'property'}{$propkey}) {
                        $starttag .= " $propkey=\"$proto->{'property'}{$propkey}{'value'}\"";
                        delete $proto->{$propkey};
                    }
                }
                # Add all other attributes
                foreach $propkey (keys %{$proto->{'property'}}) {
                    unless (' name signal ' =~ / $propkey /) {
                        $starttag .= " $propkey=\"$proto->{'property'}{$propkey}{'value'}\"";
                    }
                }
                $value = $proto->{'value'};
                if (defined $value && $value ne '') {
                    $value = &Glade::PerlRun::QuoteXMLChars($value);
                    $contents .= "$prefix<$starttag>$value</$etag>";
                } else {
                    $contents .= "$prefix<$starttag />";
                }
                delete $proto->{$key};
                undef $stag;
                undef $etag;

            } elsif (ref $proto->{$key} eq 'ARRAY') {
                foreach $child (@{$proto->{$key}}) {
                    $contents .= "\n" if $key eq 'child';
                    # Expand each sub element in array
                    $contents .= "\n".
                        $class->string_from_proto(
                            $newprefix, 
                            $tab, 
                            $key, 
                            $key,
                            $child, 
                            $prune);
                }

            } elsif (ref $proto->{$key} eq 'HASH') {
                if (' property ' =~ / $key /) {
                    foreach $child (sort keys %{$proto->{$key}}) {
                        # Expand each sub element in hash
                        $starttag = $key;
                        foreach $propkey ('name') {
                            $starttag .= " $propkey=\"$child\"";
                        }
                        # Add all attributes (except value) to starttag
                        foreach $propkey (sort keys %{$proto->{$key}{$child}}) {
                            unless (' value ' =~ / $propkey /) {
                                $starttag .= " $propkey=\"$proto->{$key}{$child}{$propkey}\"";
                                delete $proto->{$key}{$child};
                            }
                        }
                        # Store <starttag>value</endtag> or <starttag />
                        $value = $proto->{$key}{$child}{'value'};
                        if (defined $value && $value ne '') {
                            $value = &Glade::PerlRun::QuoteXMLChars($value);
                            $contents .= "\n$newprefix<$starttag>$value</$key>";
                        } else {
                            $contents .= "\n$newprefix<$starttag />";
                        }
                    }
#                    undef $stag;
                    delete $proto->{$key};

                } else {
                    if (' widget ' =~ / $key /) {
                        # Make up widget starttag
                        $starttag = "$key class=\"$proto->{$key}{class}\" id=\"$proto->{$key}{'name'}\"";
                        delete $proto->{$key}{class};
                        delete $proto->{$key}{name};
                    } else {
                        $starttag = $key;
                    }
                    # call ourself to expand nested xml
                    $contents .= "\n".
                        $class->string_from_proto(
                            $newprefix, 
                            $tab, 
                            $starttag, 
                            $key,
                            $proto->{$key}, 
                            $prune);
                }
            }
        }
        delete $proto->{$key};
    }

    # make up the string to return
    if (defined $contents && $contents eq '') {
        if ($stag eq 'child') {
            $xml .= "$prefix<$stag>\n".
                "$newprefix<placeholder />\n".
                "$prefix</$etag>";

        } elsif ($stag ne '') {
            $xml .= "$prefix<$stag />";
        }

    } else {
        if (defined $stag && $stag ne '' && $stag ne 'form') {
            $xml .= "$prefix<$stag>$contents\n$prefix</$etag>";
        } else {
            $xml .= "$contents";
        }
    }
    return $xml;
}
    
    my $gtk2_changes = {
        'glade'     => {
            'project'           => $REMOVED,
        },
        'gtk-2.0'   => {
            $ALL                => {
                $CHILD              => {
                    'pack'              =>'pack_type',
                    'child_ipad_x'      => 'child_internal_pad_x',
                    'child_ipad_y'      => 'child_internal_pad_y',
                },
                'child_min_width'   => $OBSOLETE,
                'child_min_height'  => $OBSOLETE,
                'child_ipad_x'      => $OBSOLETE,
                'child_ipad_y'      => $OBSOLETE,
                'width'             => 'width-request',
                'height'            => 'height-request',
            },
            'GtkButton'          => {
                'label'             => '&add_use_underline($proto)',
            },
            'GtkCList'          => {
                $WIDGET             => $DEPRECATED,
                $CONVERT_TO         => 'GtkTreeView',
                $CHILD              => {
                    'child_name'        => $OBSOLETE,
                },
                'columns'           => 'n-columns',
            },
            'GtkCTree'          => {
                $WIDGET             => $DEPRECATED,
                $CONVERT_TO         => 'GtkTreeView',
                $CHILD              => {
                    'child_name'        => $OBSOLETE,
                },
                'columns'           => 'n-columns',
            },
            'GtkClock'          => {
                $WIDGET             => $REMOVED,
            },
            'GtkColorSelection' => {
                'policy'            => $OBSOLETE,
            },
            'GtkColorSelectionDialog' => {
                'policy'            => $OBSOLETE,
            },
            'GtkCombo'          => {
                'use_arrows'        => 'enable_arrow_keys',
                'use_arrows_always' => 'enable_arrows_always',
                'ok_if_empty'       => 'allow_empty',
            },
            'GtkDial'           => {
                $WIDGET             => $REMOVED,
            },
            'GtkEntry'          => {
                'text_max_length'   => 'max-length',
                'text_visible'      => 'visibility',
            },
            'GtkFileSelection' => {
                'show_file_op_buttons' => 'show-fileops',
            },
            'GtkFrame'          => {
                'shadow_type'       => 'shadow',
            },
            'GtkGammaCurve'     => {
                'curve_type'        => $OBSOLETE,
                'max_x'             => $OBSOLETE,
                'max_y'             => $OBSOLETE,
                'min_'             => $OBSOLETE,
                'min_y'             => $OBSOLETE,
            },
            'GtkHPaned'         => {
                'handle_size'       => $OBSOLETE,
                'gutter_size'       => $OBSOLETE,
            },
            'GtkVPaned'         => {
                'handle_size'       => $OBSOLETE,
                'gutter_size'       => $OBSOLETE,
            },
            'GtkHScale'         => {
                'policy'            => $OBSOLETE,
            },
            'GtkVScale'         => {
                'policy'            => $OBSOLETE,
            },
            'GtkHScrollbar'     => {
                'policy'            => $OBSOLETE,
            },
            'GtkVScrollbar'     => {
                'policy'            => $OBSOLETE,
            },
            'GtkHRuler'         => {
                'metric'            => $OBSOLETE,
            },
            'GtkVRuler'         => {
                'metric'            => $OBSOLETE,
            },
            'GtkHandleBox'      => {
                'shadow_type'       => 'shadow',
            },
            'GtkImage'          => {
                'image_width'       => $OBSOLETE,
                'image_height'      => $OBSOLETE,
                'image_visual'      => $OBSOLETE,
                'image_type'        => $OBSOLETE,
            },
            'GtkLabel'          => {
                'default_focus_target' => 'mnemonic_widget',
                'focus_target'      => 'mnemonic_widget',
            },
            'GtkLayout'         => {
                'area_width'        => 'width',
                'area_height'       => 'height',
            },
            'GtkList'           => {
                $WIDGET             => $BROKEN,
            },
            'GtkMenuBar'        => {
                'shadow_type'       => $OBSOLETE,
            },
            'GtkMenuItem'       => {
                'right_justify'     => $OBSOLETE,
            },
            'GtkNotebook'       => {
                'popup_enable'      => 'enable-popup',
            },
            'GtkOptionMenu'     => {
                'initial_choice'    => 'history',
            },
            'GtkPacker'         => {
                $WIDGET             => $REMOVED,
            },
            'GtkPixmap'         => {
                $WIDGET             => $DEPRECATED,
                $CONVERT_TO         => 'GtkImage',
            },
            'GtkPixmapMenuItem' => {
                $WIDGET             => $REMOVED,
            },
            'GtkRange'          => {
                'policy'            => 'update-policy',
            },
            'GtkSpinButton'     => {
                'snap'              => 'snap_to_ticks',
            },
            'GtkTable'          => {
                $CHILD              => {
                    'xpad'              => 'x_padding',
                    'ypad'              => 'y_padding',
                },
                'rows'              => 'n-rows',
                'columns'           => 'n-columns',
            },
            'GtkText'           => {
                $WIDGET             => $BROKEN,
            },
            'GtkToolbar'        => {
                'space_size'        => $OBSOLETE,
                'space_style'       => $OBSOLETE,
                'relief'            => $OBSOLETE,
                'tooltips'          => $OBSOLETE,
                'type'              => 'toolbar-style',
            },
            'GtkTree'           => {
                $WIDGET             => $BROKEN,
            },
            'GtkTreeItem'       => {
                $WIDGET             => $BROKEN,
            },
            'GtkWindow'         => {
                'auto_shrink'       => $OBSOLETE,
                'position'          => 'window-position',
            },
            'GnomeCalculator'   => {
                $WIDGET             => $REMOVED,
            },
            'GnomeDialog'       => {
                $WIDGET             => $DEPRECATED,
            },
            'GnomeDruidPageStandard' => {
                'title_color'       => 'title_foreground',
                'background_color'  => 'background',
                'logo_background_color' => 'logo_background',
                'logo_image'        => 'logo',
            },
            'GnomeEntry'        => {
                'max_saved'         => $OBSOLETE,
            },
            'GnomeFileEntry'    => {
                'max_saved'         => $OBSOLETE,
                'directory'         => 'directory_entry',
                'title'             => 'browse_dialog_title',
            },
            'GnomeFontPicker'   => {
                'use_font_size'     => 'label-font-size',
                'use_font'           => 'use-font-in-label',
            },
            'GnomeIconEntry'    => {
                'max_saved'         => $OBSOLETE,
                'title'             => 'browse_dialog_title',
            },
            'GnomeLess'         => {
                $WIDGET             => $REMOVED,
            },
            'GnomeNumberEntry'  => {
                $WIDGET             => $REMOVED,
            },
            'GnomePixmap'       => {
                $WIDGET             => $DEPRECATED,
            },
            'GnomePixMapEntry'  => {
                'title'             => 'browse_dialog_title',
            },
            'GnomePropertyBox'  => {
                'auto_shrink'       => $OBSOLETE,
            },
            'GnomeSpell'        => {
                $WIDGET             => $REMOVED,
            },
        },
    };
}

1;

__END__

