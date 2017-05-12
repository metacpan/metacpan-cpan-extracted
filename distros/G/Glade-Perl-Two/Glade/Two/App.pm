package Glade::Two::App;
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
    use Exporter    qw( );
    use POSIX       qw( isdigit);
    use Gtk2;                             # For message_box
    use Cwd         qw( cwd chdir);
    use File::Basename;
    use Data::Dumper;
    use Text::Wrap  qw( wrap $columns); # in options, diag_print
    use Glade::Two::Run qw(:METHODS :VARS);
    use vars        qw( @ISA 
                        $AUTOLOAD
                        %fields
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE $VERSION $AUTHOR $DATE
                        @VARS @METHODS 
                     );
    # Tell interpreter who we are inheriting from
    @ISA          = qw( 
                        Exporter 
                        Glade::Two::Run
                       );

    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.01);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 06:02:01 GMT 2002 );

    # These vars are imported by all Glade-Perl modules for consistency
    @VARS         = qw(  
                   );
#                        $Glade_Perl
#                        $indent
    @METHODS      = qw( 
                   );
    # These symbols (globals and functions) are always exported
    @EXPORT       = qw( 
                   );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS);
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                   );
}

%fields = (
    # These are the data fields that you can set/get using the dynamic
    # calls provided by AUTOLOAD (and their initial values).
    # eg $class->FORMS($new_value);      sets the value of FORMS
    #    $current_value = $class->FORMS; gets the current value of FORMS
    'app'   => {
        'name'          => undef,
        'author'        => undef,
        'version'       => '0.01',
        'date'          => undef,
        'copying'       =>          # Copying policy to appear in generated source
            "# Unspecified copying policy, please contact the author
# ",
        'description'   => undef,   # Description for About box etc.
#        'pixmaps_directory' => undef,
        'logo'          => 'Logo.xpm', # Use specified logo for project
    },
    'data'  => {
        'directory' => undef,
    },
    'diag'  => {
        'verbose'       => undef,   # Show errors and main diagnostics
        'wrap_at'       => 0,       # Max diagnostic line length (approx)
        'autoflush'     => undef,   # Dont change the policy
        'indent'        => '    ',  # Diagnostics indent to lay out messages
        'benchmark'     => undef,   # Dont add time to the diagnostic messages
        'log'           => undef,   # Write diagnostics to STDOUT 
#        'log'           => "\&STDOUT",# Write diagnostics to STDOUT 
                                    # or Filename to write diagnostics to
        'LANG'          => ($ENV{'LANG'} || ''),
                                        # Which language we want the diagnostics
    },
    'run_options'   => {
        'name'          => __PACKAGE__,
        'version'       => $VERSION,    # Version of Glade-Perl used
        'author'        => $AUTHOR,
        'date'          => $DATE,
        'logo'          => 'glade2perl_logo.xpm', # Our logo
        'start_time'    => undef,       # Time that this run started
        'mru'           => undef,
        'prune'         => undef,
        'proto'   => {
            'site'          => undef,
            'user'          => undef,
            'project'       => undef,
            'params'        => undef,
            'app_defaults'  => undef,
            'base_defaults' => undef,
        },
        'xml'  => {
            'site'          => undef,
            'user'          => undef,
            'project'       => undef,
            'params'        => undef,
            'app_defaults'  => "Application defaults",
            'base_defaults' => __PACKAGE__." defaults",
            'set_by'        => 'DEFAULT',   # Who set the options
            'encoding'      => undef,       # Character encoding eg ('ISO-8859-1') 
        },
    },
    'glade' => {
        'name_from'     => undef,
        'file'          => undef,
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
        'onefile'   => {
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

my $option_hashes = " ".
join(" ",
    'app',
    'project',
    'proto',
    'run_options',
    'diag',
    'glade',
    'glade2perl',
    'glade2perl-1',
    'glade2perl-2',
    'glade_helper',
    'source',
    'xml',
    'doc',
    'dist',
    'data',
    'module',
    'helper',
    'test'
)." ";

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

=pod

=head1 NAME

Glade::App - Utility methods for Glade-Perl (and generated applications).

=head1 SYNOPSIS

 use vars qw(@ISA);
 use Glade::App qw(:METHODS :VARS);
 @ISA = qw( Glade::App);

 # 1) CLASS methods
 my $Object = Glade::App->new(%params);
 $Object->glade->file($supplied_path);
 $widget = $window->lookup_widget('clist1');

 # 2) OPTIONS handling
 $options = Glade::App->options(%params);
 $normalised_value = Glade::App->normalise('True');
 $new_hash_ref = Glade::App->merge_into_hash_from(
      $to_hash_ref,      # Hash to be updated
      $from_hash_ref,    # Input data to be merged
      'set accessors');  # Any value will add AUTOLOAD() accessors
                         # for these keys.
 $Object->save_app_options($mru_filename);
 $Object->save_options;

 my $string = Glade::App->string_from_file('/path/to/file');
 Glade::App->save_file_from_string('/path/to/file', $string);

 # 3) Diagnostic message printing
 $Object->start_log('log_filename');
 $Object->diag_print(2, "This is a diagnostics message");
 $Object->diag_print(2, $hashref, "Prefix to message");
 $Object->stop_log;

 # 4) I18N
 Glade::App->load_translations('MyApp', 'fr', '/usr/local/share/locale/',
     undef, $SOURCE_LANG, 'Merge with already loaded translations');
 sprintf(_("A message '%s'"), $value);
 sprintf(gettext($SOURCE_LANG, "A message '%s'"), $value);
 Glade::App->start_checking_gettext_strings($SOURCE_LANG);
 Glade::App->stop_checking_gettext_strings($SOURCE_LANG);
 Glade::App->write_missing_gettext_strings($SOURCE_LANG);

 # 5) UI methods
 my $image = Glade::App->create_image('new.xpm', ['dir1', 'dir2']);
 my $pixmap = Glade::App->create_pixmap($form, 'new.xpm', ['dir1', 'dir2']);

 Glade::App->show_skeleton_message(
    $me, \@_, __PACKAGE__, "$Glade::App::pixmaps_directory/Logo.xpm");
 Glade::App->message_box(
    $message,                               # Message to display
    $title,                                 # Dialog title string
    [_('Dismiss'), _("Quit")." Program"],   # Buttons to show
    1,                                      # Default button is 1st
    $pixmap,                                # pixmap filename
    [&dismiss, &quit],                      # Button click handlers
    $entry_needed);                         # Whether to show an entry
                                            # widget for user data

 # 6) General methods
 $path = $Object->full_Path($Object->glade->file, $dir);
 $path = Glade::App->relative_Path($relative_path, $directory);

 $Object->reload_any_altered_modules;

=head1 DESCRIPTION

Glade::App provides some utility methods that Glade-Perl modules and 
also the generated classes need to run. These methods can be inherited and 
called in any app that use()s Glade::App and quotes Glade::App
in its @ISA array.

Broadly, the utilities are of seven types.

 1) Class methods
 2) Options handling
 3) Diagnostic message printing
 4) I18N
 5) UI methods
 6) General methods

=head1 1) CLASS METHODS

The class methods provide an object constructor and data accessors.

=over 4

=cut

sub new {

=item new(%params)

Construct a Glade::App object

e.g. my $Object = Glade::App->new(%params);

=cut

    my $that  = shift;
    my %params = @_;
    my $class = ref($that) || $that;
    # Call our super-class constructor to get an object and reconsecrate it
    my $self = bless {}, $class;

    $self->merge_into_hash_from($self, \%fields, (__PACKAGE__." defaults"));
    $self->run_options->proto->base_defaults(\%fields);
    $self->merge_into_hash_from($self, \%params, ("$class app defaults"));
    $self->run_options->proto->app_defaults(\%params);

    return $self;
}

sub AUTOLOAD {

=item AUTOLOAD()

Accesses all class data

e.g. my $glade_filename = $Object->glade->file;
 or  $Object->glade->file('path/to/glade/file');

=cut
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

  } elsif ($name ne 'DESTROY'){
    die "Can't access method `$name' in class $class\n",
        "We were called from ",join(", ", caller),"\n\n";

  }
}

#===============================================================================
#=========== Options utilities                                      ============
#===============================================================================

=back

=head1 2) OPTIONS HANDLING METHODS

These methods will load, merge, reduce and save a hierarchical options
structure that is stored in one or more XML files and accessed with
AUTOLOAD methods.

=over

=cut

sub options {
    my ($class, %params) = @_;
    my $me = $class."->options";

=item options(%params)

Loads and merges all app options.

e.g. Glade::App->options(%params);
     my options = $Object->options(%params);

=cut
    my ($self, $global, $type, $key, $defaults, $I18N_name, $log, $report);
    $global     = delete $params{'options_global'}    || "\$Glade_Perl";
    $defaults   = delete $params{'options_defaults'}  || \%Glade::Two::app_fields;
    $type       = delete $params{'options_key'}       || $defaults->{type} || 'glade2perl-2';
    $I18N_name  = delete $params{'options_I18N_name'} || $type || 'Glade-Perl';
    $report     = delete $params{'options_report'};

    unless (ref $class eq $class) {
        # This is first time through so construct object and load options
        @use_modules = ();
        
        $self = bless __PACKAGE__->new(%$defaults), $class;

        eval "$global = \$self";

        # Now set element $type to point to our options hash
        $self->{$type} = $self->{run_options};
        push @{$self->{$permitted_fields}{$type}}, $me;

        $self->load_all_options(%params);

        print "App defaults ", Dumper(\%fields) if $report;
        print "App defaults supplied ", Dumper($defaults) if $report;
        print "App params passed ", Dumper(\%params) if $report;
        eval "print \"\$report Initial state with app defaults and options loaded \", ".
            "Dumper($report),\"\n\n\"" if $report;

        # Merge in all options available
        foreach $key ('site', 'user', 'project', 'params') {
            eval "print \"".$self->{$type}->xml->{$key}.
                " options supplied \", "."Dumper($report),\"\n\n\"" if $report;
            $self->merge_into_hash_from($self, 
                $self->{$type}->proto->{$key},
                $self->{$type}->xml->{$key});
            eval "print \"\$report After \$key options from '".
                $self->{$type}->xml->{$key}."' merged \", ".
                "Dumper($report),\"\n\n\"" if $report;
        }

        $self->{$type}->start_time($class->get_time);
        $self->{$type}->name($class);
        $self->{$type}->version($VERSION);
        $self->{$type}->author($AUTHOR);
        $self->{$type}->date($DATE);


        # Load the diagnostics gettext translations
        $self->load_translations($I18N_name, $self->diag->LANG, undef, 
            undef, $DIAG_LANG, undef);
#        $self->load_translations($I18N_name, $self->diag->LANG, undef, 
#            '/home/dermot/Devel/$I18N_name/ppo/en.mo', $DIAG_LANG, undef);
#        $self->check_gettext_strings($DIAG_LANG);

        if ($self->diag->wrap_at == 0) {
            $columns = 1500;
        } else {
            $columns = $self->diag->wrap_at;
        }

    } else {
        $self = $class;
        $self->{$type}->xml->params(
            $params{$type}{'xml'}{'set_by'} ||
            $params{'options_set'} || 
            $self->{$type}->xml->set_by ||
            $me);
        $self->{$type}->proto->params($self->convert_old_options(\%params));
        $self->merge_into_hash_from($self, 
            $self->{$type}->proto->params,
            $self->{$type}->xml->params);
    }

    $self->diag_print (4, $self->{$type}->proto->params);
    $self->diag_print (5, $self->{$type}->xml);
    $self->diag_print (6, $self->{$type});
    $self->diag_print (7, $self);
    
    $self->{$type}->xml->set_by (
        $self->{$type}->proto->params->{$type}{xml}{set_by} || $me);

    return $self;
}

sub load_all_options {
    my ($class, %params) = @_;
    my $me = (ref $class || $class)."->load_all_options";

    my $type = $class->{type} || $params{type};
    $class->{'run_options'}->xml->encoding(
        $params{'run_options'}{xml}{encoding} ||
        $params{'run_options'."_encoding"} ||
        $params{glade}{encoding} ||
        $params{glade_encoding} ||
        'ISO-8859-1'
       );

    # PARAMS supplied
    $class->{'run_options'}->xml->params(
        $params{'run_options'}{'xml'}{'set_by'} ||
        $params{'options_set'} || 
        $class->{'run_options'}->xml->set_by ||
        $me);
    $class->{'run_options'}->proto->params(
#        %params);
        $class->convert_old_options(\%params));

    # USER options file
    $class->{'run_options'}->xml->user(
        $class->{'run_options'}->proto->params->{'run_options'}{xml}{user} ||
        "$ENV{'HOME'}/.$type.xml");

    $class->{'run_options'}->get_options('user');
    $class->{'run_options'}->proto->user(
        $class->convert_old_options($class->{'run_options'}->proto->user, 
            $class->{'run_options'}->xml->user));

#print Dumper($class->{'run_options'}->proto);
    # PROJECT options file (from user mru if not specified in params)
#    if ($class->{'run_options'}->xml->project eq $NOFILE) {
         my $base = $class->{'run_options'}->proto->user->{'run_options'}{mru} || '';
         $base =~ s/(.+)\..*$/$1/;
         $base =~ s/(.+)\..*$/$1/;
         $base ? $base .= ".$type.xml" : $base = $NOFILE;
         $class->{'run_options'}->xml->project(
             $class->{'run_options'}->proto->params->{'run_options'}{xml}{project} ||
             $class->{'run_options'}->xml->project ||
             $base
         );
#    }
    unless ($class->{'run_options'}->xml->project eq $NOFILE) {
        $class->{'run_options'}->xml->project(
            $class->full_Path($class->{'run_options'}->xml->project, `pwd`));
    }
#print Dumper($class->{'run_options'}->proto->params);
#print Dumper($class->{'run_options'}->xml);exit
    $class->{'run_options'}->get_options('project');
    $class->{'run_options'}->proto->project(
        $class->convert_old_options($class->{'run_options'}->proto->project, $me));
    
    # SITE options file
    $class->{'run_options'}->xml->site(
        $class->{'run_options'}->proto->params->{'run_options'}{xml}{site} ||
        $class->{'run_options'}->proto->project->{'run_options'}{xml}{site} ||
        $class->{'run_options'}->proto->user->{'run_options'}{xml}{site} ||
        "/etc/$type.xml");

    $class->{'run_options'}->get_options('site');
    $class->{'run_options'}->proto->site(
        $class->convert_old_options($class->{'run_options'}->proto->site, 
            $class->{'run_options'}->xml->site));

    $class->diag_print (5, $class) if ref $class;
    return $class->{'run_options'};
}

sub get_options {
    my ($class, $type, $file) = @_;

    my $pwd = `pwd`;
    my ($encoding);
    $file ||= $class->xml->{$type} || $NOFILE;

    if ($file eq $NOFILE) {
        $class->xml->{$type} = $file;
        $class->proto->{$type} = {};
        return;
    }
    if ($file && -r $file) {
        ($encoding, $class->proto->{$type}) = $class->simple_Proto_from_File(
#        ($encoding, $class->proto->{$type}) = Glade::PerlXML->Proto_from_File(
            $class->xml->{$type}, 
            '', $option_hashes, 
            $class->xml->encoding);
        $class->xml->encoding($encoding);

    } else {
#        print "File '$file' could NOT be read\n";
        $class->proto->{$type} = {};
    }
}

sub simple_Proto_from_File {
    my ($class, $filename, $repeated, $special, $encoding) = @_;
    my $me = __PACKAGE__."->new_Proto_from_File";

    my $pos = -1;
    my $xml = $class->string_from_File($filename);
    return $class->simple_Proto_from_XML(\$xml, 0, \$pos, $repeated, $special, $encoding);
}

sub simple_Proto_from_XML {
    my ($class, $xml, $depth, $pos, $repeated, $special, $encoding) = @_;
    my $me = __PACKAGE__."->simple_Proto_from_XML";

    # Loads hash from XML string using regexps (not XML::Parser).
    my ($self, $tag, $use_tag, $prev_contents, $work);
    my ($found_encoding, $new_pos);
    while (($new_pos = index($$xml, "<", $$pos)) > -1) {
        $prev_contents = substr($$xml, $$pos, $new_pos-$$pos);
        $$pos = $new_pos;
        $new_pos = index($$xml, ">", $$pos);
        $tag = substr($$xml, $$pos+1, $new_pos-$$pos-1);
        $$pos = $new_pos+1;
        if ($tag =~ /^\?/) {
            if ($tag =~ s/\?xml.*\s*encoding\=["'](.*?)['"]\?\n*//) {
                $found_encoding = $1;
            } else {
                $found_encoding = $encoding;
            }
            next;
        }
        if ($tag =~ s|^/||) {
            # We are an endtag so return the $prev_contents
#print "Found end tag </$tag>\n";
            if  (ref $self) {
#print Dumper($self);
                return $self;

            } else {
                return &UnQuoteXMLChars($prev_contents);
            }

        } else {
            # We are a starttag so recurse
            if ($tag =~ s|/$||) {
                # We are also an endtag (empty eg. <tagname /> so ignore
#print "Found empty tag <$tag />\n";
            } else {
                # Ignore tags starting with ? or !
                next if $tag =~ /^[\?\!]/;
                $work = $class->simple_Proto_from_XML(
                    $xml, $depth + 1, $pos, $repeated);
                if (" $repeated " =~ / $tag /) {
                    # Store as the next list item
                    push(@{$self->{list}}, $tag) ;
                } else {
                    # Store as key
                    $use_tag = $tag;
                }
                $self->{$use_tag} = $work;
#print "Found start tag <$tag>\n";
            }
        }
    }
#print Dumper($self);

    return ($found_encoding, values %$self);
}

sub convert_old_options {
    my ($class, $old, $file) = @_;
    my $me = __PACKAGE__."->convert_old_options";
    my $new = {};

    my $key;
    my $converted = 0;
    for $key (keys %$old) {
        # Normalise any True/False values to 1/0
        $old->{$key} = $class->normalise($old->{$key});
        if ($convert->{$key}) {
            eval $convert->{$key};
            die @! if @!;
            $converted++;
        } elsif (ref $old->{$key}) {
            $new->{$key} = $class->merge_into_hash_from(
                $new->{$key}, $old->{$key}, $file);
        } else {
            $new->{$key} = $old->{$key};
        }
    }

    if ($file and $converted and $class->diagnostics(2)) {
        if (-w $file) {
            # We can rewrite the options file
            print sprintf("$me has converted options in file %s\n",
                 $file);
            $class->write_options($new, $file);
        } else {
            print "$me cannot rewrite file '$file'\n".
                sprintf(
                "You may want to edit '$file' yourself to read: \n%s\n",
                $class->XML_from_Proto('', '  ', 'G2P-Options', $new));
        }
    }
    return $new;
}

sub normalise {
    my ($class, $value) = @_;

=item normalise($value)

Return a normalised value ie. convert 'True'|'Yes'|'y'|'On' to 1
and 'False'|'No'|'n'|'Off' to 0. 
The comparisons are case-insensitive.

e.g. my $normalised_value = Glade::App->normalise('True');

=cut
    if (defined $value) {
        if ($value =~ /^(true|y|yes|on)$/i) {
            return 1;
        } elsif ($value =~ /^(false|n|no|off)$/i) {
            return 0;
        } else {
            return $value;
        }
    }
}

sub merge_into_hash_from {
    my ($class, $to_hash, $from_hash, $autoload) = @_;
    my $me = $class."->merge_into_hash_from";

=item merge_into_hash_from($to_hash, $from_hash, $autoload)

Recursively merge a hash into an existing one - overwriting any keys with 
a defined value. It will also optionally set accessors for the keys to be
used via AUTOLOAD().

e.g. $new_hash_ref = Glade::App->merge_into_hash_from(
         $to_hash_ref,      # Hash to be updated
         $from_hash_ref,    # Input data to be merged
         'set accessors');  # Any value will add AUTOLOAD() accessors
                            # for these keys.

=cut
    my ($key, $value);
    $autoload ||= '';
    foreach $key (keys %$from_hash) {
        next if $key eq $permitted_fields;
        if (ref $from_hash->{$key} eq 'HASH') {
            $to_hash->{$key} ||= bless {}, ref $to_hash;
            $class->merge_into_hash_from(
                $to_hash->{$key},
                $from_hash->{$key},
                $autoload);

        } else {
            # Check that we are not overwriting a hash with a scalar
            unless (ref $to_hash->{$key}) {
                $to_hash->{$key} = $class->normalise($from_hash->{$key});
            }
        }
        $to_hash->{$permitted_fields}{$key}++ if $autoload;
    }
    return $to_hash;
}

sub save_app_options {
    my ($class, $mru, %defaults) = @_;
    my $me = $class."->save_app_options";

=item save_app_options($mru, %defaults)

Updates mru and saves all app/user options. This will save the mru file
in the user options file (if one is named in 
$class->{$class->type}->xml->user).

e.g. Glade::App->save_app_options($mru_filename);

=cut
    %defaults = %{$class->{$class->type}->proto->app_defaults} 
        unless keys %defaults;
    
    # Store new mru file name and start_time
    $class->{$class->type}->proto->user->{$class->type}{mru} = $mru;
    $class->{$class->type}->proto->user->{$class->type}{start_time} = 
        ($class->{$class->type}->start_time);
    undef $class->{$class->type}{mru};

    # Save project options
    $class->diag_print(6, $class, "Options to be saved");
    $class->save_options(
        undef, 
        %Glade::App::fields, 
        %defaults
   );

    if ($class->{$class->type}->xml->user) {
        # Save new user options
        $class->write_options(
            $class->reduce_hash(
                $class->{$class->type}->proto->user,
                {},
                {},
                {},
                {},
                $class->{$class->type}->prune
               ), 
            $class->{$class->type}->xml->user);
    }
}

sub save_options {
    my ($class, $filename, %app_defaults) = @_;
    my $me = __PACKAGE__."->save_options";

=item save_options($filename, %app_defaults)

Reduce and save the supplied options to the file specified.

e.g. $Object->save_options;

=cut
    my $type = $class->type;
    %app_defaults = %{$class->{$class->type}->proto->app_defaults}
        unless keys %app_defaults;
    
    if ($filename) {
        $class->{$type}->xml->{project} = ($filename);
    } else {
        $filename = $class->{$type}->xml->{project};
    }

    if ($filename eq $NOFILE) {
        $class->diag_print(2, "%s- Not saving %s project options", 
            $indent, $type);
        return;
    }
    $class->diag_print(4, $class, "Project options");

    my $options = $class->reduce_hash(
        $class,
        $class->{$type}->proto->user,
        $class->{$type}->proto->site,
        \%app_defaults,
        \%__PACKAGE__::fields,
        $class->{$type}->prune,
        $__PACKAGE__::hash_types,
   );

    if (ref $options) {
        bless $options, ref $class;
        $options->{'type'} = $type;
        $options->{$type}{start_time} = ($class->{$type}->start_time);
        $class->write_options($options, $filename);
    } else {
        $class->diag_print(2, "%s- No project options need saving", 
            $indent);
    }
}

sub write_options {
    my ($class, $options, $filename) = @_;
    my $me = __PACKAGE__."->write_options";

=item write_options($options, $filename)

Write an options hash to XML file.

e.g. my options = $Object->write_options($hash_ref, '/path/to/file');

=cut
    my $type = $class->type;
    my $xml;

    if ($class->{$type}->xml->encoding) {
        $xml = "<?xml version=\"1.0\" encoding=\"".
            $class->{$type}->xml->encoding."\"?>\n";
    } else {
        $xml = "<?xml version=\"1.0\"?>\n";
    }
    $xml .= $class->XML_from_Proto('', '  ', "$type-Options", $options);
    
    if ($filename eq $NOFILE) {
        $class->diag_print(2, "%s- Not saving %s options", $indent, $type);
        $class->diag_print(2, "%s", "$indent- XML would have been\n'$xml'\n"); 
        return;
    }
    $class->diag_print(5, $xml, 'DONT_TRANSLATE');

    $class->save_file_from_string($filename, $xml);

    $class->diag_print(2, "%s- %s options saved to %s", 
        $class->diag->indent, $type, $filename);
}

sub reduce_hash {
    my ($class, 
        $all_options, $user_options, $site_options, 
        $app_defaults, $base_defaults,
        $prune, $hash_types) = @_;
    my $me = __PACKAGE__."->reduce_hash";

=item reduce_hash($all_options, $user_options, $site_options, 
$app_defaults, $base_defaults, $prune, $hash_types)

Removes any options that are equivalent to site/user/project options
or that are specified to be pruned. We will descend into any hash types
specified.

e.g. my options = $Object->reduce_hash(
    $options_to_reduce, 
    $user_options, 
    $site_options, 
    $app_defaults,
    $base_defaults
    '*work*proto*', 
    '*My::Class*');

=cut
    my ($key, $default, $from, $return, $reftype);
    my $verbose = 5;
    $user_options  ||= {};
    $site_options  ||= {};
    $app_defaults  ||= {};
    $base_defaults ||= {};
    $prune ||= "*".
        join("*", 
            $permitted_fields, 
            &typeKey, 
            'project',
            'widgets',
            'properties',
            'run_options', 
            'PARTYPE',
            'module', 
            'tab', 
            'proto',
            'gtk_style', 
            'generate',
            'prune',
           ).
        "*";
    $hash_types ||= "*".join("*",
        (ref $class || $class), 
        'Glade::Two::App', 
        'Glade::Two', 
        'Glade::Two::Run', 
        'Glade::Two::Generate', 
   )."*";

    $class->diag_print($verbose, "Prune     is '$prune'");
    $class->diag_print($verbose, "Hashtypes is '$hash_types'");
    foreach $key (keys %{$all_options}) {
        $reftype = ref $all_options->{$key};
        $class->diag_print($verbose+1, "%s- Reducing %s object '%s'",
            $class->diag->indent, $reftype, $key) if $reftype;
        if ($reftype and "*ARRAY*" =~ /\*$reftype\*/) {
            $class->diag_print($verbose, "--------------------------------");
            $all_options->{$key} = join("\n", @{$all_options->{$key}});
            $class->diag_print($verbose, 
                "%s- Joining '%s' object {'%s'} into newline-separated string '%s'", 
                $class->diag->indent, $reftype, $key, $all_options->{$key});
        }            
        if (!defined $all_options->{$key}) {
            $class->diag_print ($verbose, 
                "%s- Removing option '%s' (%s)", 
                $class->diag->indent, $key, 'no value defined');

        } elsif ($prune =~ /\*$key\*/) {
            # Ignore the specified keys
            $class->diag_print ($verbose, 
                "%s- Removing option '%s' (%s)", 
                $class->diag->indent, $key, 'pruned');

        } elsif ($reftype and "*HASH*$hash_types*" =~ /\*$reftype\*/) {
            $class->diag_print($verbose, "--------------------------------");
            $class->diag_print($verbose, "%s- Descending into '%s' object {'%s'}", 
                $class->diag->indent, $reftype, $key);
            $class->diag_print($verbose+1, $all_options->{$key}, 
                $class->diag->indent."- {'$key'} which is a ");
            $class->diag_print($verbose+1, $all_options->{$key}, 
                "Project option element {'$key'}");
            $class->diag_print($verbose+1, $user_options->{$key}, 
                "User options element {'$key'}") if $user_options->{$key};
            $class->diag_print($verbose+1, $site_options->{$key}, 
                "Site options element {'$key'}") if $site_options->{$key};
            $class->diag_print($verbose+1, $app_defaults->{$key}, 
                "App defaults element {'$key'}") if $app_defaults->{$key};
            $class->diag_print($verbose+1, $base_defaults->{$key}, 
                __PACKAGE__." defaults element {'$key'}") if $base_defaults->{$key};
            $return->{$key} = $class->reduce_hash(
                $all_options->{$key},
                $user_options->{$key}, 
                $site_options->{$key}, 
                $app_defaults->{$key}, 
                $base_defaults->{$key}, 
                $prune, $hash_types);
            unless (keys %{$return->{$key}}) {
                delete $return->{$key};
                $class->diag_print($verbose, "%s- Losing empty hash {'%s'}",
                    $class->diag->indent, $key);
            } else {
                $class->diag_print($verbose, $return->{$key}, 
                    "$me reduced {'$key'} so that");
            }

        } else {
            if (defined $user_options->{$key}) {
                $default = $user_options->{$key};
                $from = "user options file";

            } elsif (defined $site_options->{$key}) {
                $default = $site_options->{$key};
                $from = "site options file";

            } elsif (defined $app_defaults->{$key}) {
                $default = $app_defaults->{$key};
                $from = (ref $all_options)." app defaults";

            } elsif (defined $base_defaults->{$key}) {
                $default = $base_defaults->{$key};
                $from = __PACKAGE__." defaults";

            } else {
                $default = '__NO_DEFAULT_OPTION_AVAILABLE__';
                $from = "no default";
            }
            if ($all_options->{$key} eq $class->normalise($default)) {
                $class->diag_print ($verbose, 
                    "%s- Removing {'%s'} => '$all_options->{$key}' (equals default in %s)", 
                    $class->diag->indent, $key, $from);
            } elsif (!$all_options->{$key} and $default eq '__NO_DEFAULT_OPTION_AVAILABLE__') {
                $class->diag_print ($verbose, 
                    "%s- Removing option '%s' (no default and no value)", 
                    $class->diag->indent, $key, $from);
            } else {
                $return->{$key} = $all_options->{$key};
            }
        }
    }
    return $return;
}

sub XML_from_Proto {
    # usage my $xmlstring = 
    #   XML::UTIL->XML_from_Proto($prefix, '  ', $tag, $protohashref);
    # This proc will compose XML from a proto hash in 
    #   Proto_from_XML's return format
    my ($class, $prefix, $tab, $tag, $proto) = @_;
	my $me = "$class->XML_from_Proto";
	my ($key, $val, $xml, $limit);
	my $typekey = &typeKey;
    my $prune = "*$typekey*$permitted_fields*";
	my $contents = '';
	my $newprefix = "$tab$prefix";

	# make up the start tag 
	foreach $key (sort keys %$proto) {
		unless ($prune =~ /\*$key\*/) {
			if (ref $proto->{$key} eq 'ARRAY') {
                print "error- Key '$key' is an ARRAY !!! and has been ignored\n";
                next;
			} elsif (ref $proto->{$key}) {
				# call ourself to expand nested xml
				$contents .= "\n".
                    $class->XML_from_Proto(
                        $newprefix, $tab, 
                        ($proto->{$key}{$typekey} || $key), 
                        $proto->{$key}, $prune).
                    "\n";
			} else {
				# this is a vanilla string so trim and add to output
				if (defined $proto->{$key}) {
                    $contents .= "\n$newprefix<$key>".
                        &QuoteXMLChars($proto->{$key})."</$key>";
				} else {
					$contents .= "\n$newprefix<$key></$key>";
#					$contents .= "\n$newprefix<$key />";
				}
			}
		}
	}

	# make up the string to return
	if ($contents eq '') {
		if ($tag ne '') {
			$xml .= "\n$prefix<$tag />";
		}
	} else {
		if ($tag ne '') {
			$xml .= "$prefix<$tag>$contents\n$prefix</$tag>";
		} else {
			$xml .= "\n$contents\n";
		}
	}
	return $xml
}
	
=back

=head1 SEE ALSO

Glade::Two::Generate(3) glade2perl-2(1)

=head1 AUTHOR

Dermot Musgrove <dermot.musgrove@virgin.net>

=cut

1;

__END__

