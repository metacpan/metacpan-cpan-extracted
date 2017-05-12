package Glade::PerlGenerate;
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
    use Exporter            qw(  );
    use File::Basename qw( basename dirname );       # in use_Glade_Project
    use Data::Dumper;
    use Glade::PerlProject;               # Project vars and methods
    use Glade::PerlSource   qw( :VARS :METHODS ); # Source writing vars and methods
    use Glade::PerlXML;                   # Source writing vars and methods
    use Glade::PerlUI       qw( :VARS );  # UI construction vars and methods
    use vars                qw( 
                            @ISA 
                            $PACKAGE $VERSION $AUTHOR $DATE
                          );
    # Tell interpreter who we are inheriting from
#                            Glade::PerlSource
    @ISA            =   qw(
                            Exporter
                            Glade::PerlSource
                            Glade::PerlProject
                            Glade::PerlXML
                            Glade::PerlUI
                        );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.61);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 03:21:11 GMT 2002);
}

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#==== Documentation ============================================================
#===============================================================================
=pod

=head1 NAME

Glade::PerlGenerate - Generate Perl source from a Glade XML project file.

=head1 SYNOPSIS

The simplest way to run Glade::PerlGenerate is to use the supplied script 
'glade2perl' that is also called by Glade when you hit the 'Build' button.

 glade2perl Project.glade 2

Otherwise you can control every aspect of the source generation by calling
the same methods that glade2perl calls:

 use Glade::PerlGenerate;

 Glade::PerlGenerate->Form_from_Glade_File(

   'author'        => 'Dermot Musgrove <dermot.musgrove@virgin.net>',
   'description'   => "This is an example of the Glade-Perl
source code generator",
   'verbose'       => 2,
   'indent'        => '    ',
   'tabwidth'      => 4,
   'diag_wrap'     => 0,
   'write_source'  => 'True',
   'dont_show_UI'  => 'True',
   'autoflush'     => 'True',
   'use_modules'   => 'Example::BusForm_mySUBS',
   'log_file'      => 'Test.log',
   'glade_filename'=> "Example/BusForm.glade"

 );

OR if you want to generate  the UI directly from an XML string

 Glade::PerlGenerate->Form_from_XML(

   'xml'           => $xml_string,
   'use_modules'   => ['Example::Project_mySUBS']

 );

=head1 DESCRIPTION

Glade::PerlGenerate reads a <GTK-Interface> definition from a Glade
file (or a string) using XML::Parser, converts it into a hash of hashes 
and works its way through this to show the UI using Gtk-Perl bindings. 
The module can also optionally generate Perl source code to show the UI 
and handle the signals. Any signal handlers that are specified in the 
project file but not visible at Generate time will be hijacked to show 
a 'missing_handler' message_box and a stub for it will be defined in the 
the UI class for dynamic AUTOLOAD()ing.

The stub will simply show a message_box to prove that the handler has been 
called and you can write your own with the same name in another module. You 
then quote this module to the next Generate run and Glade::PerlGenerate will 
use these handlers and not define stubs.

=cut

#===============================================================================
#=========== Utilities to run Generate phase                        ============
#===============================================================================
sub about_Form {
    my ($class) = @_;
    my $gtkversion     = 
        Gtk->major_version.".".Gtk->minor_version.".".Gtk->micro_version;
    my $name = $0;
    my $message = 
        "$PACKAGE (".
        D_("version").      ": $VERSION - $DATE)\n".
        D_("Written by").   ": $AUTHOR\n\n".
        "Gtk ".D_("version").": $gtkversion\n".
        "Gtk-Perl ".D_("version").":    $Gtk::VERSION\n\n".
        D_("run from file").":        $name";
    my $widget = $PACKAGE->message_box($message, 
        D_("About")." \u$PACKAGE", 
        [D_('Dismiss'), D_('Quit Program')], 1, 
        $Glade_Perl->run_options->logo, 'left' );
}

sub destroy_Form {
#    my ($class) = @_;
#    $class->get_toplevel->destroy;
    Gtk->main_quit; 
}

#===============================================================================
#=========== Utilities to construct the form from a Proto                   ====
#===============================================================================
sub options {
    my ($class, %params) = @_;

    $params{'glade_filename'}   ||= $Glade::PerlRun::NOFILE;
    $params{'project_options'}  ||= $Glade::PerlRun::NOFILE;
    $params{'user_options'}     ||= $Glade::PerlRun::NOFILE;

    $class->SUPER::options(%params);
}

sub Form_from_Glade_File {
    my ($class, %params) = @_;
    my $me = "$class->Form_from_Glade_File";

    $Glade::PerlRun::convert = $Glade::PerlProject::convert;
    if (ref $Glade_Perl) {
        # We have already called options() at least once somehow
        $Glade_Perl->merge_into_hash_from(
            $Glade_Perl, 
            $class->convert_old_options(\%params), 
            $me);
        
    } else {
        $class->SUPER::options(%params,
            'options_I18N_name' => 'Glade-Perl',
            'options_defaults'  => \%Glade::PerlProject::app_fields,
            'options_key'       => $Glade::PerlProject::app_fields{type},
            'options_global'    => "\$Glade_Perl",
#            'options_report'    => '$Glade_Perl->{source}{style}',
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
#print Dumper($Glade_Perl);
    $Glade_Perl->run_options->xml->project(
        $Glade_Perl->run_options->xml->project ||
        $Glade_Perl->glade->file."2perl.xml");
#    $Glade_Perl->diag_print (2, "%s- Reading project options from '%s' - %s",
#        $Glade_Perl->diag->indent, $Glade_Perl->{$Glade_Perl->type}->xml->project);

    $Glade_Perl->diag->log($Glade_Perl->glade->file."2perl.log")
        if $Glade_Perl->diag->log eq '1';

    # Start diagnostics
    $Glade_Perl->start_log;

    $Glade_Perl->Write_to_File;
    $Glade_Perl->get_versions;

    $Glade_Perl->glade->proto($class->Glade_Proto_from_File);
    my $window = $class->Form_from_Proto( $Glade_Perl, %params );

    $Glade_Perl->test->directory(
        $Glade_Perl->test->directory || 
        $class->full_Path(
            $Glade_Perl->glade->proto->{'project'}{'directory'}, 
            `pwd`)
        );
    $Glade_Perl->test->name(
        $Glade_Perl->test->name || 
        $Glade_Perl->glade->proto->{'project'}{'name'});


    $Glade_Perl->save_app_options($Glade_Perl->glade->file);
        
    $Glade_Perl->stop_log;

    return $window;
}

sub Glade_Proto_from_File {
    my ($class) = @_;
    my $me = "$class->Glade_Proto_from_File";

    # FIXME The line below is necessary until Damon sorts out Glade's XML.
    # Glade doesn't write an encoding declaration at the top of the file :(
    $Glade_Perl->glade->encoding($Glade_Perl->glade->encoding || 'ISO-8859-1');
    my ($encoding, $glade_proto) = $class->Proto_from_File( 
        $Glade_Perl->glade->file, 
        ' accelerator signal widget ', ' project child ', 
        $Glade_Perl->glade->encoding);

    $class->merge_into_hash_from( 
        $Glade_Perl, 
        $Glade_Perl->use_Glade_Project($glade_proto ),
        "Glade project ".$Glade_Perl->glade->file);

    $Glade_Perl->app->use_modules(
        [split (/\n/, ($Glade_Perl->app->use_modules || '' ))]) 
        unless ref $Glade_Perl->app->use_modules eq 'ARRAY';
    $current_form && eval "$current_form = {};";

    return $glade_proto;
}

sub Form_from_XML {
    my ($class, %params) = @_;
    my $me = "$class->Form_from_XML";

    my $save_options = $Glade_Perl;
    $Glade_Perl = bless {}, $class;

    # Set options
    $Glade::PerlRun::convert = $Glade::PerlProject::convert;
    $class->SUPER::options(%params);

    $Glade_Perl->diag->verbose(0);
    $Glade_Perl->source->write(undef);
    my ($encoding, $glade_proto) = $class->Proto_from_XML( 
        $Glade_Perl->glade->string, 
        ' accelerator signal widget ' , ' project child ', 
        $Glade_Perl->glade->encoding);
    my $form;

    $Glade_Perl->glade->proto($glade_proto);
    $Glade_Perl->glade->file('XML String');    
    if (($Glade_Perl->glade->proto->{'project'}->{'gnome_support'} || 'True') eq 'True') {
        $Glade_Perl->diag_print (6, 
            "%s- Use()ing Gnome in %s",
            $indent, $me);
        $Glade_Perl->app->allow_gnome(1);
        Gnome->init('Form_from_XML', '0.01');
    } else {
        Gtk->init;
    }
    my $window = $class->Widget_from_Proto(
        'No Parent', $Glade_Perl->glade->proto, 0, 'Form from string' );
    $forms->{$first_form}{$first_form}->show( );
    Gtk->main;
    $Glade_Perl = $save_options;
    return $window;
}

sub Form_from_Proto {
    my ($class, $proto, %params) = @_;
    my $me = "$class->Form_from_Proto";

    my ($module);
    my $depth = 0;
    my $options = $proto;
    $indent ||= ' ';
    $forms = {};
    $widgets = {};

#print Dumper($Glade_Perl->glade2perl->xml);
    $Glade_Perl->diag_print (2, "%s- Constructing form(s) from Glade file '%s' - %s",
                $indent, $proto->glade->file, $proto->glade->name_from);
    $Glade::PerlRun::pixmaps_directory = $Glade_Perl->glade->pixmaps_directory;
    foreach $module (@{$proto->app->use_modules}) {
        if ($module && $module ne '') {
#print "We are in directory '".`pwd`."'\n";
            eval "use $module;" or
                ($@ && 
                    die  "\n\nin $me\n\t".("while trying to eval").
                        " 'use $module'".
                         "\n\t".("FAILED with Eval error")." '$@'\n" );
            push @use_modules, $module;
            $Glade_Perl->diag_print (2, 
                "%s- Use()ing existing module '%s' in %s",
                $indent, $module, $me);
        }
    }
    if ($options->app->allow_gnome) {
        $Glade_Perl->diag_print (6, "%s- Use()ing Gnome in %s", $indent, $me);
        eval "use Gnome;";
        unless (Gnome::Stock->can('pixmap_widget')) {
            $Glade_Perl->diag_print (1, 
                "%s- You need either to build the Gtk-Perl Gnome module or ".
                "uncheck the Glade 'Enable Gnome Support' project option",
                $options->indent);
            $Glade_Perl->diag_print (1, 
                "%s- Continuing without Gnome for now although ".
                "the generate run will fail if there are any Gnome widgets".
                "specified in your project",
                $options->indent);
            $options->app->allow_gnome(0);
        }
        Gnome->init(__PACKAGE__, $VERSION);
    } else {
        Gtk->init;
    }

    # Recursively generate the UI
    my $app = "\$forms->{'test'}{'__HIERARCHY'}";
    my $window = $class->Widget_from_Proto( $proto->glade->proto->{'name'}, 
        $proto->glade->proto, $depth, $app );

    my $save_module = $proto->test->use_module;

#print Dumper($Glade_Perl->glade2perl->xml);
    # Now write the disk files
    if ($Glade_Perl->Writing_to_File) {
        # Load the source code gettext translations
        unless ($options->source->LANG) {
            $options->source->LANG($options->diag->LANG);
        }
        $class->load_translations('Glade-Perl', $options->source->LANG, 
            undef, undef, '__S', undef);
#        $class->load_translations('Glade-Perl', $options->source->LANG, undef, 
#            '/home/dermot/Devel/Glade-Perl/ppo/en.mo', '__S', undef);
#        $class->start_checking_gettext_strings("__S");
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
        }
    }

    $Glade_Perl->write_documentation;
    $Glade_Perl->write_distribution;

    # Look through $proto and report any unused attributes (still defined)
    if (!$Glade_Perl->source->quick_gen && $Glade_Perl->diagnostics(2)) {
        $Glade_Perl->diag_print (2, "%s", "-----------------------------------------------------------------------------");
        $Glade_Perl->diag_print (2, "%s  CONSISTENCY CHECKS", $indent);
        $Glade_Perl->diag_print (2, "%s- %s unused widget properties", $indent, $missing_widgets);
        if ($ignored_widgets) {
            $Glade_Perl->diag_print (2, "%s- %s widgets were ignored (one or more of '%s')", 
                $indent, $ignored_widgets, $ignore_widgets);
        } else {
            $Glade_Perl->diag_print (2, "%s- %s widgets were ignored", 
                $indent, $ignored_widgets);
        }
        $Glade_Perl->diag_print (2, "%s- %s unpacked widgets",
            $indent, $class->unpacked_widgets);
        if ($Glade_Perl->diagnostics(4)) {
            $Glade_Perl->diag_print (4, 
                "$indent- ".$class->unhandled_signals." unhandled signals");
        }
        $Glade_Perl->diag_print (2, "%s", "-----------------------------------------------------------------------------");
        unless ($Glade_Perl->Writing_Source_only) { 
            $Glade_Perl->diag_print (2, "%s  UI MESSAGES - showing missing_handler calls that you triggered, ".
                "don't worry, %s will generate dynamic stubs for them all",
                $indent, $PACKAGE);
        }
#        $object->write_missing_gettext_strings('__S');
    }
#    $object->write_missing_gettext_strings('__D', "&STDOUT", "NO_HEADER");

    # And show UI if necessary
    unless ($Glade_Perl->Writing_Source_only) { 
        $forms->{$first_form}{$first_form}->show;
        Gtk->main; 
    }
    return $proto;
}

#===============================================================================
#=========== Diagnostic utilities                                   ============
#===============================================================================
sub check_for_unused_elements {
    my ($class, $proto) = @_;
    my $me = "$class->check_for_unused_elements";
    my $typekey = $class->typeKey;
    my $key;
    my ($object,$name );
    foreach $key (sort keys %{$proto}) {
        if (defined $proto->{$key}) {
            unless (" class $typekey name " =~ m/ $key /) {
                unless (ref $proto->{$key}) {
                    # We have found an unused widget property
                    unless ($proto->{$typekey} eq 'project') {
                        $object = $proto->{'class'} || '';
                        $name = $proto->{'name'} || '(no name)';
                        if (" $cxx_properties " =~ m/ $key /) {
                            $Glade_Perl->diag_print (4, 
                                "warn  Intentionally ignored property for %s %s {'%s'}{'%s'} => '%s' seen by %s",
                                $proto->{$typekey}, $object, $name, $key, $proto->{$key}, $me);
                        } elsif (!$Glade_Perl->source->quick_gen) {
                            $Glade_Perl->diag_print (1, 
                                "error Unused widget property for %s %s {'%s'}{'%s'} => '%s' seen by %s",
                                $proto->{$typekey}, $object, $name, $key, $proto->{$key}, $me);
                            $missing_widgets++;
                        }
                    }
                }
            }
        }
    }
    return $missing_widgets;
}

sub unpacked_widgets {
    my ($class) = @_;
    my $me = "$class->unpacked_widgets";
    my $count = 0;
    my $key;
    foreach $key (sort keys %{$widgets}) {
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
    my $me = "$class->unhandled_signals";
    my ($widget, $signal);
    my $count = 0;
# FIXME This is all tosh - what do we need here?    
# FIXME Should we produce stubs for these ? if so, do this in perl_sub etc

    foreach $widget (sort keys %{$need_handlers}) {
#        if (keys (%{$need_handlers->{$widget})) {
            foreach $signal (sort keys %{$need_handlers->{$widget}}) {
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

1;

__END__

=head1 USER OPTIONS

These options can be specified to the
Glade::PerlGenerate->Form_from_Glade_File() and 
Glade::PerlGenerate->Form_from_XML()
methods or with the same name in the options XML files.

Boolean values can be specified as C<True|true|Yes|yes|1 or 
False|false|No|no|0|''|undef >

=head1 <app> options that describe your application

=over 4

=item <name>

Name to use for the generated packages. Any spaces, dots or minuses will
be removed from the name as these are not valid in perl package names.

=item <author>

The author's name to appear in generated sources. Backslash-escape any
@ signs so that they are passed through perl strings correctly.
The default is synthesised from some of the values returned by 
Perl's gethostbyname "localhost"

e.g. C<Dermot Musgrove <dermot.musgrove@virgin.net>

=item <version> - default is 0.01

Version number to use in generated sources.

e.g. C<0.53-pre1>

=item <date> - defaults to build time.

The date string to show in sources.

e.g. C<Christmas eve 2001>

=item <copying> - default is '# Unspecified copying policy, please contact the author\n# '

Copying text to include in generated sources. Make sure that they are specified
as perl # comments so that the generated source is valid.

=item <description> - default is 'No description'

A general description of the app to appear in sources and about_boxes

e.g C<This is a reference form that contains all the widgets that Glade 
knows about>

=item <logo> - default 'Logo.xpm'

Use the specified logo in about boxes or if any pixmap is missing

=item <use_modules> - default means don't use() any other modules

When specified as an arg this is an anonymous array of module names
to be use()d in the generated classes.

In an options file, a newline separated list of modules to be use()d by 
generated classes

e.g C<['Existing::mySUBS', 'Some::Other::Module']>

=item <allow_gnome> - Default is read from the Glade project file

Bool - whether or not to allow Gnome widgets in the generated source

=back





=head1 <glade> options that describe the glade file

=over 4

=item <file>

Name of Glade file to read

=item <encoding> - default 'ISO-8859-1'

Character encoding of Glade file 

eg C<ISO-8859-1>

=back





=head1 <glade2perl> options that control the glade2perl run

=over 4

=item <version>

Version of Glade::PerlGenerate that wrote this file.

=item <logo> - default 'glade2perl_logo.xpm'

Name of the Glade::PerlGenerate logo pixmap used.

=item <my_perl_gtk> - Default is to use Gtk-Perl's version number

Version number of my Gtk-Perl module. This overrides the number reported by
Gtk::Perl so that CVS fixes can be used.

C<0.6123>   I have CPAN version 0.6123

C<19991001> I have the gnome.org CVS version of 'gnome-perl' 
that I downloaded on Oct 1st 1999

=item <my_gnome_libs> - Default is to use gnome-libs version no

Version number of my gnome-libs. This overrides the number reported by
`gnome-libs-config --version` so that CVS fixes can be used.

C<1.0.58>   I have the released version 1.0.58 of 'gnome-libs'

C<19991001> I have the gnome.org CVS version of 'gnome-libs' 
that I downloaded on Oct 1st 1999

=item <dont_show_UI> - default is to show the UI and wait for user action

Bool - whether to show the UI during the Build. glade2perl sets this to 0
so that the UI is not shown.

=item <start_time>

Time that this run started

=item <xml> options that describe the options files

=over 4

=item <set_by> - default 'DEFAULT'

Who set the options last.

=item <site> - Default is /etc/glade2perl.xml

File name containing options for all projects on this site.
This option is only meaningful when set by Glade::PerlGenerate->options() or
Form_from_File() although it is logged in the project_options file 

=item <user> - Default is ~/.glade2perl.xml

File name containing options for all projects in this user. 
This option is only meaningful when set by Glade::PerlGenerate->options() or
Form_from_File() although it is logged in the project_options file 

=item <project> - Default means don't read or save a file

Filename of project options to read and save.
This option is only meaningful when set by Glade::PerlGenerate->options() or
Form_from_File() although it is logged in the project_options file 

=item <encoding> - default is <glade><encoding> option

Character encoding of glade2perl.xml options files.
This option is only meaningful when set by Glade::PerlGenerate->options() or
Form_from_File() although it is saved in the file itself.

eg C<ISO-8859-1>

=back

=back





=head1 <source> options that control the source code generated

=over 4

=item <indent> - default is 4 spaces

Indent to use for 'nested' source code

 e.g. '  ' (2 spaces)

=item <tabwidth> - default is 8

Number of spaces to replace with a tab in generated source code

e.g. C<4>

=item <write> - default is no source

Where to write the source code. glade2perl sets this to 1.

C<STDOUT>  Write sources to STDOUT but there will be nothing to run later

C<File.pm> Write sources to File.pm They will not run from here 
and you must cut-paste them

C<True> - write the sources to standard files.

C<undef>     Don't write source code

=item <hierarchy> - default means don't generate any hierarchy

C<...widget...> generates a widget hierarchy eg C<$form-E<gt>{'__WH'}{'vbox2'}{'table1'}... >

C<...class...>  generates a class hierarchy eg C<$form-E<gt>{'__CH'}{'GtkVBox'}{'vbox2'}{'GtkTable'}{'table1'}... >

C<...both...>   both widget and class hierarchies generated

C<...ordered...> generates an ordered hierarchy that reflects the order that child
widgets were added to the UI eg C<$form-E<gt>{'__WH'}{'vbox2'}{'table1'}{'__C'}[2]... >

e.g. C<widget_hierarchy>

=item <style> - default AUTOLOAD

C<AUTOLOAD> - OO class implements missing signal handlers with an AUTOLOAD sub

C<Libglade> - generate libglade code and signal handlers

C<split> - generates each class in its own .pm file.

=item <LANG> - default $ENV{'LANG'}

Which language do we want the source to be documented in?

e.g. C<pt_BR>

=back





=head1 <diag> options that control diagnostics output

=over 4

=item <verbose> - default is 2

Level of verbosity of diagnostics

 0  - Quiet/no diagnostics (glade2perl uses this)
 1  - Main project messages and errors only
 2  - also warnings
 4  - also project options and more diagnostics
 6  - also source code as it is generated
 8  - also lookups and conversions
 10 - everything (more than you want?)

=item <wrap_at> - default is 0 (no breaks)

Maximum diagnostics message line length (approximate)

 0   - no breaks (not easy to read on 80 column displays).
 80  - should display comfortably on 80 column display
 132 - Wrap diagnostics so that lines are about 132 characters long

=item <autoflush> - default is False (write at end of block)

Bool - whether to autoflush the file output. 
This is really to force errors to be
shown by my editor's shellout in the case of a failure.

=item <indent> - default is 4 spaces

Indent to use for diagnostic messages and wrapped lines

 e.g. '  ' (2 spaces)

=item <benchmark> - default means don't add time to the diagnostic messages

Bool - True will cause the time to prefix all diagnostics messages

=item <log> - Default is to use STDOUT

Write diagnostics and errors to filename if verbose > 0
glade2perl can set this to /path/to/glade/file.glade2perl.log

e.g. C</home/dermot/Devel/Test/Project1.glade2perl.log>

=item <LANG> - default $ENV{'LANG'}

Which language do we want the diagnostic messages in?

e.g. C<de>

=back





=head1 EXAMPLE OPTIONS FILES

=head2 This is a typical project options file 
~/Devel/Glade-Perl/Example/Reference/Existing/Reference.glade2perl.xml 

 <?xml version="1.0" encoding="ISO-8859-1"?>
 <glade2perl-Options>
   <app>
     <allow_gnome>1</allow_gnome>
     <date>Tue Apr 10 05:04:00 BST 2001</date>
     <description>No description</description>
     <logo>Logo.xpm</logo>
     <name>Reference</name>
     <use_modules>Reference_mySUBS</use_modules>
     <version>0.58</version>
   </app>

   <diag>
     <log>/home/dermot/Devel/Glade-Perl/Example/Reference/Project.glade2perl.log</log>
   </diag>

   <glade>
     <directory>/home/dermot/Devel/Glade-Perl/Example/Reference</directory>
     <file>/home/dermot/Devel/Glade-Perl/Example/Reference/Project.glade</file>
     <name_from>Specified as arg to Glade::PerlGenerate-&gt;Form_from_Glade_File</name_from>
     <pixmaps_directory>/home/dermot/Devel/Glade-Perl/Example/Reference/pixmaps</pixmaps_directory>
     <start_directory>/home/dermot/Devel/Glade-Perl/Example/Reference</start_directory>
   </glade>

   <glade2perl>
     <date>Thu Apr 26 13:32:49 BST 2001</date>
     <dont_show_UI>1</dont_show_UI>
     <logo>/home/dermot/Devel/Glade-Perl/Example/Reference/pixmaps/glade2perl_logo.xpm</logo>
     <my_gnome_libs>1.2.13</my_gnome_libs>
     <my_gtk_perl>20010601</my_gtk_perl>
     <package>Glade::PerlProject</package>
     <start_time>Tue Jun 12 11:59:49 BST 2001</start_time>
     <version>0.58</version>
     <xml>
       <params>Params supplied</params>
       <project>/home/dermot/Devel/Glade-Perl/Example/Reference/Project.glade2perl.xml</project>
       <set_by>Glade::PerlGenerate-&gt;use_Glade_Project</set_by>
     </xml>

   </glade2perl>

   <source>
     <style>sxplit</style>
   </source>

   <test>
     <directory>/home/dermot/Devel/Glade-Perl/Example/Reference</directory>
     <first_form>ReferenceForm</first_form>
     <name>Reference</name>
     <use_module>src::Reference</use_module>
   </test>

   <type>glade2perl</type>
 </glade2perl-Options>

=head2 This what I have in my user options file 
~/.glade2perl.xml 

 <?xml version="1.0" encoding="ISO-8859-1"?>
 <glade2perl-Options>
   <app>
    <author>Dermot Musgrove &lt;dermot.musgrove@virgin.net&gt;</author>
   </app>

   <diag>
     <LANG>en</LANG>
     <indent>  </indent>
     <verbose>2</verbose>
   </diag>

   <glade2perl>
     <author>Dermot Musgrove &lt;dermot.musgrove@virgin.net&gt;</author>
     <logo>/home/dermot/Devel/HTML-Site/pixmaps/glade2perl_logo.xpm</logo>
     <mru>/home/dermot/Devel/Glade-Perl/Example/Reference/Project.glade</mru>
     <name>Glade::PerlGenerate</name>
     <start_time>Tue Jun 12 11:59:49 BST 2001</start_time>
     <xml>
       <app_defaults>Application defaults</app_defaults>
       <base_defaults>Glade::PerlRun defaults</base_defaults>
       <encoding>ISO-8859-1</encoding>
       <params>DEFAULT</params>
       <site>/etc/glade2perl.xml</site>
       <user>/home/dermot/.glade2perl.xml</user>
     </xml>

   </glade2perl>

   <source>
     <LANG>en</LANG>
     <indent>  </indent>
     <tabwidth>4</tabwidth>
     <write>1</write>
   </source>

 </glade2perl-Options>

=head2 This what I have in my site options file 
/etc/glade2perl.xml 

 <?xml version="1.0" encoding="ISO-8859-1"?>
 <G2P-Options>
   <app>
     <copying># This library is released under the same conditions as Perl, that
 # is, either of the following:
 #
 # a) the GNU General Public License as published by the Free
 # Software Foundation; either version 1, or (at your option) any
 # later version.
 #
 # b) the Artistic License.
 #
 # If you use this library in a commercial enterprise, you are invited,
 # but not required, to pay what you feel is a reasonable fee to cpan.org
 # at http://www.perl.org or contact donors@perlmongers.org for details.
 # </copying>
   </app>
   <glade2perl>
     <my_gtk_perl>0.7007</my_gtk_perl>
   </glade2perl>
 </G2P-Options>





=head1 ERRORS and WARNINGS

The module will report several errors or warnings that warn of problems 
with the Glade file or other unexpected occurences. These are to help me 
cater for new widgets or widget properties and not because Glade creates 
inconsistent project files but they do point out errors in hand-edited XML.





=head1 FILES GENERATED

=over 4

=item projectUI.pm

A perl class/module (projectUI.pm) that contains
a class for each toplevel window/dialog, each with a standard 
method (new) that will construct the UI. 

=item projectSIGS.pm

A perl class/module (projectSIGS.pm) that contains
a class for each toplevel window/dialog, with skeleton 
signal handlers for any that were missing at build time. 

If the C<split> style is used, the typical filename will be
projectSIGS_class .pm (one file per class).

=item project.pm

A perl class/module (project.pm) that is a copy of projectSIGS.pm
for you to edit to become your "App".
You can generate the 
UI again and again without changing any of your signal handlers as it
is only written the first time through (if missing). If you add signal
definitions to your Glade project, skeletons for the handlers will be 
generated in the projectSIGS.pm file and you can cut-and-paste them
from there into the relevant class in the project.pm "App" module.

If the C<split> style is used, the typical filename will be
project_class .pm (one file per class).

=item Subproject.pm

A perl class/module (Subproject.pm) that subclasses project.pm
that you can edit to subclass your "App". 
You can generate the 
UI again and again without changing any of your signal handlers as
it is only written the first time through (if missing).

=item projectLIBGLADE.pm

An optional perl class/module (projectLIBGLADE.pm) that initialises
the Libglade bindings and has skeleton signal handlers
that you can edit to form your "App". 
You can generate the 
UI again and again without changing any of your signal handlers as
it is only written the first time through (if missing).

=back

=head1 SEE ALSO

Glade::Run(3) glade2perl(1)

Documentation that came with the module is in Directory 'Documentation' in 
files README, Changelog, FAQ, FAQ.i18n, TODO, NEWS, ROADMAP etc.

The test file for C<make test> is test.pl which is runnable and has
examples of user options.

A Perl script to generate source code from the Glade 'Build' button or menuitem
is in file 'Example/glade2perl' and is installed when you C<make install>. 
You can also call this script from the command line.

A module that subclasses the test example is in file Example/SubBus.pm. This
module will use (inherit or subclass) the generated perl classes and also use
the supplied signal handlers module (Example/BusForm_mySUBS.pm)

=cut

=head1 AUTHOR

Dermot Musgrove <dermot.musgrove@virgin.net>

=cut

