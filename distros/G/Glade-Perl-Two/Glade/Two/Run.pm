package Glade::Two::Run;
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
    use Exporter    qw(  );
    use POSIX       qw( isdigit );
    use Gtk2;                             # For message_box
    use Gtk2::Window;
    use Gtk2::HBox;
    use Gtk2::VBox;
    use Gtk2::HButtonBox;
    use Gtk2::Entry;
    use Gtk2::Button;
    use Gtk2::Image;
    use Gtk2::Label;
    use Gtk2::Tooltips
    eval "use Gtk2::Keysyms";
    use Cwd         qw( cwd getcwd chdir );
    use File::Basename;
    use Data::Dumper;
    use Text::Wrap  qw( wrap $columns ); # in options, diag_print
    use vars        qw( @ISA 
                        $AUTOLOAD
                        %fields %stubs
                        @EXPORT @EXPORT_OK %EXPORT_TAGS 
                        $PACKAGE $VERSION $AUTHOR $DATE
                        @VARS @METHODS 

                        $SAVE_MISSING
                        $MISSING_STRINGS
                        $C
                        $W
                        $WIDGET_INSTANCE
                        $CH
                        $WH
                        $MO_HEADER_INFO
                        $RUN_LANG
                        $SOURCE_LANG
                        $DIAG_LANG
                        
                        $Glade_Perl
                        $I18N
                        $indent
                        $tab

                        $all_forms
                        $widgets 
                        $work
                        $forms 
                        $pixmaps_directory

                        @use_modules
                        %stat
                        $NOFILE
                        $permitted_fields
                        $convert
                        $Gtk
                      );
    use subs qw (
                      );
    # Tell interpreter who we are inheriting from
    @ISA          = qw( 
                        Exporter 
                        );

    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.01);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 06:02:01 GMT 2002 );

    $widgets      = {};
    $all_forms    = {};
    $indent       = '';
    $pixmaps_directory = "pixmaps";
    $C      = '__C';
    $W      = '__W';
    $CH     = '__CH';
    $WH     = '__WH';
    $NOFILE             = '__NOFILE';
    $SAVE_MISSING       = '__SAVE_MISSING';
    $MISSING_STRINGS    = '__MISSING_STRINGS';
    $MO_HEADER_INFO     = '__MO_HEADER_INFO';
    $WIDGET_INSTANCE    = '__W';
    $RUN_LANG           = '__RUN_LANG';
    $SOURCE_LANG        = '__SOURCE_LANG';
    $DIAG_LANG          = '__DIAG_LANG';
    $permitted_fields   = '_permitted_fields';

    # These vars are imported by all Glade-Perl modules for consistency
    @VARS         = qw(  
                        $Glade_Perl
                        $I18N
                        $indent
                        $tab
                        @use_modules
                        $NOFILE
                        $SAVE_MISSING
                        $MISSING_STRINGS
                        $C
                        $W
                        $WIDGET_INSTANCE
                        $CH
                        $WH
                        $MO_HEADER_INFO
                        $RUN_LANG
                        $SOURCE_LANG
                        $DIAG_LANG
                        $permitted_fields
                        $convert
                        $Gtk
                    );
    @METHODS      = qw( 
                        _
                        S_
                        D_
                        start_checking_gettext_strings
                        create_image 
                        create_pixmap 
                        missing_handler 
                        message_box 
                        message_box_close 
                        show_skeleton_message 
                        &typeKey
                        &keyFormat
                        &QuoteXMLChars
                        &UnQuoteXMLChars
                        reload_any_altered_modules
                    );
    # These symbols (globals and functions) are always exported
    @EXPORT       = qw( 
                    );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS );
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
);


%stubs = (
);

my $option_hashes = " ".
join(" ",
    'app',
    'diag',
    'glade',
    'glade2perl',
    'glade2perl-1',
    'glade2perl-2',
    'glade_helper',
    'source',
    'xml',
    'dist',
    'helper',
    'test',
    'run_options',
)." ";

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

=pod

=head1 NAME

Glade::Two::Run - Utility methods for Glade-Perl (and generated applications).

=head1 SYNOPSIS

 use vars qw(@ISA);
 use Glade::Two::Run qw(:METHODS :VARS);
 @ISA = qw( Glade::Two::Run );

 # 1) CLASS methods
 my $Object = Glade::Two::Run->new(%params);
 $Object->glade->file($supplied_path);
 $widget = $window->lookup_widget('clist1');

 # 2) OPTIONS handling
 $options = Glade::Two::Run->options(%params);
 $normalised_value = Glade::Two::Run->normalise('True');
 $new_hash_ref = Glade::Two::Run->merge_into_hash_from(
      $to_hash_ref,      # Hash to be updated
      $from_hash_ref,    # Input data to be merged
      'set accessors');  # Any value will add AUTOLOAD() accessors
                         # for these keys.
 $Object->save_app_options($mru_filename);
 $Object->save_options;

 my $string = Glade::Two::Run->string_from_file('/path/to/file');
 Glade::Two::Run->save_file_from_string('/path/to/file', $string);

 # 3) Diagnostic message printing
 $Object->start_log('log_filename');
 $Object->diag_print(2, "This is a diagnostics message");
 $Object->diag_print(2, $hashref, "Prefix to message");
 $Object->stop_log;

 # 4) I18N
 Glade::Two::Run->load_translations('MyApp', 'fr', '/usr/local/share/locale/',
     undef, $SOURCE_LANG, 'Merge with already loaded translations');
 sprintf(_("A message '%s'"), $value);
 sprintf(gettext($SOURCE_LANG, "A message '%s'"), $value);
 Glade::Two::Run->start_checking_gettext_strings($SOURCE_LANG);
 Glade::Two::Run->stop_checking_gettext_strings($SOURCE_LANG);
 Glade::Two::Run->write_missing_gettext_strings($SOURCE_LANG);

 # 5) UI methods
 my $image = Glade::Two::Run->create_image('new.xpm', ['dir1', 'dir2']);
 my $pixmap = Glade::Two::Run->create_pixmap($form, 'new.xpm', ['dir1', 'dir2']);

 Glade::Two::Run->show_skeleton_message(
    $me, \@_, __PACKAGE__, "$Glade::Two::Run::pixmaps_directory/Logo.xpm");
 Glade::Two::Run->message_box(
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
 $path = Glade::Two::Run->relative_Path($relative_path, $directory);

 $Object->reload_any_altered_modules;

=head1 DESCRIPTION

Glade::Two::Run provides some utility methods that Glade-Perl modules and 
also the generated classes need to run. These methods can be inherited and 
called in any app that use()s Glade::Two::Run and quotes Glade::Two::Run
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

Construct a Glade::Two::Run object

e.g. my $Object = Glade::Two::Run->new(%params);

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

  if (exists $self->{$permitted_fields}->{$name} ) {
    # This allows dynamic data methods - see %fields above
    # eg $class->UI('new_value');
    # or $current_value = $class->UI;
    if (@_) {
      return $self->{$name} = shift;
    } else {
      return $self->{$name};
    }

  } elsif (exists $stubs{$name} ) {
    # This shows dynamic signal handler stub message_box - see %stubs above
    __PACKAGE__->show_skeleton_message(
      $AUTOLOAD."\n ("._("AUTOLOADED by")." ".__PACKAGE__.")", 
      (ref $self), @_, 
      __PACKAGE__, 
      'pixmaps/Logo.xpm');
    
  } elsif ($name ne 'DESTROY'){
    die "Can't access method `$name' in class $class\n",
        "We were called from ",join(", ", caller),"\n\n";

  }
}

sub lookup_widget {

=item lookup_widget($widgetname)

Accesses a window or a form's widget by name

e.g. my $widget = $window->lookup_widget('clist1');

  OR my $form = $window->FORM; # or use $form in signal handlers
     my $widget = $form->lookup_widget('clist1');

=cut

    my $self = shift;
    my $name = shift;
    my $hash = {};
    
    my $class = ref($self)
        or die "$self is not an object so we cannot lookup_widget '$name'\n",
            "We were called from ".join(", ", caller),"\n\n";
    
    if (exists $self->{$permitted_fields}->{FORM}) {
        $hash = $self->FORM;

    } elsif (exists $self->{TOPLEVEL}) {
        $hash = $self;
        
    } else {
        print "$self is not a window or form object so we cannot lookup_widget '$name'\n",
            "We were called from ".join(", ", caller),"\n\n";
    }

    if (exists $hash->{$name} ) {
        return $hash->{$name};

    } else {
        print "There is no widget `$name' in class $class\n",
            "We were called from ",join(", ", caller),"\n\n";
        return undef;
    }
}

sub fix_name {

=item fix_name($name)

Substitutes illegal characters in a perl name and returns it

e.g. my $name = Glade::Two::Run->fix_name($name);
OR   my $name = Glade::Two::Run->fix_name($name, 'TRANSLATE');

=cut

    my ($class, $name, $translate) = @_;
    my $illegals = '- ./+*!';
    my $replaced = 0;
    my $new_name = $name;
    if ($name =~ /[$illegals]/) {
        if ($translate) {
            my %ents=('-'=>'MINUS', ' '=>'SPACE', '.'=>'DOT', 
                    '/'=>'SLASH', '+'=>'PLUS', '*'=>'STAR', '!'=>'BANG');
            $replaced = $new_name =~ s/([$illegals])/_$ents{$1}_/g;

        } else {
            $replaced = $new_name =~ s/([$illegals])//g;

        }
        $Glade_Perl->diag_print (1, "warn  new name '%s' generated as ".
            "original name '%s' contained %s chars [$illegals]".
            "which are illegal in a Perl name.",
            $new_name, $name, $replaced);
    }
    return $new_name;
}
sub save_file_from_string {
    my ($class, $filename, $string) = @_;
    my $me = __PACKAGE__."->save_file_from_string";

=item save_file_from_string($filename, $string)

Write a string to a file.

e.g. Glade::Two::Run->save_file_from_string('/path/to/file', $string);

=cut
    $class->diag_print(5, $string, 'DONT_TRANSLATE');

    open OUTPUT, ">".($filename) or 
        die sprintf("error %s - can't open file '%s' for output", 
            $me, $filename);
    print OUTPUT $string || '';
    close OUTPUT or
        die sprintf("error %s - can't close file '%s'", 
            $me, $filename);
    $class->diag_print(3, "%s- %s string saved to %s", 
        $class->diag->indent, $me, $filename);
}

#===============================================================================
#=========== Diagnostics utilities                                  ============
#===============================================================================

=back

=head1 3) DIAGNOSTIC MESSAGE METHODS

These methods will start logging diagnostic messages, produce standardised 
I18N messages and then stop logging and close any open files.

=over

=cut

sub verbosity            { shift->diag->verbose }
sub Writing_to_File      { shift->source->write }
sub Building_UI_only     {!defined shift->source->write }

sub diagnostics { 
    ($_[1] || 1) <= (shift->diag->verbose);
}

sub diag_print {
    my $class = shift;
    my $level = shift;
    my $message = shift;

=item diag_print()

Prints diagnostics message (I18N translated) if verbosity is >= level specified

e.g. $Object->diag_print(2, "This is a diagnostics message");
     $Object->diag_print(2, $hashref, "Prefix to message");

=cut
    return unless $class->diagnostics($level);
    my $time='';
    if ($class->diag->benchmark) {
        my @times = times;
        $time = int( $times[0] + $times[1] );
    }
    unless (ref $message) {
        # Make up message from all remaining args
        $message = sprintf(D_($message, 2), @_) unless 
            $_[0] && $_[0] eq 'DONT_TRANSLATE';
        print STDOUT wrap($time, 
            $class->diag->indent.$class->diag->indent, "$message\n");

    } else {
        my $prefix = shift || '';
        print $class->diag->indent."- $prefix ", Dumper($message);
#        $class->diag_ref_print($level, $message, @_);
    }
}

sub diag_ref_print {
    my ($class, $level, $message, $desc, $pad) = @_;

    return unless $class->diagnostics($level);
    my ($key, $val, $ref);
    my $padkey = $pad || 17;
    my $title = D_($desc || "");
    my @times = times;
    my $time='';
    $ref = ref $message;
    if ($class->diag->benchmark) {
        $time = int( $times[0] + $times[1] );
    }
    unless ($ref) {
         print STDOUT wrap($time, 
            $time.$class->diag->indent.$class->diag->indent, "$message\n");

    } elsif (($ref eq 'HASH') or ( $ref =~ /Glade::/)) {
        print STDOUT "$title $ref ",D_("contains"), ":\n";
        foreach $key (sort keys %$message) {
            my $ref = ref $message->{$key};
            if (ref $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->{$key}) {
                print STDOUT "        {'$key'}".
                    (' ' x ($padkey-length($key))).
                    " => '$message->{$key}'\n";
            } else {
                print STDOUT "        {'$key'}\n";
            }
            $val = (ref ) || $message->{$key} || 'undef';
        }

    } elsif ($ref eq 'ARRAY') {
        print STDOUT "$title $ref ", D_("contains"), ":\n";
		my $im_count = 0;
	    foreach $val (@$message) {
			$key = sprintf "[%d]", $im_count;
			$ref = ref $val;
            if ($ref) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = ", D_("is a reference to a"), " $ref\n";
            } elsif (defined $message->[$im_count]) {
                print STDOUT "        $key".(' ' x ($padkey-length($key))).
                    " = '$message->[$im_count]'\n";
            } else {
                print STDOUT "        $key\n";
            }
			$im_count++;
	   	}

    } else {
        # Unknown ref type
        print STDOUT wrap($time, $time.$class->diag->indent.$class->diag->indent, 
            D_("Unknown reference type"), " '$ref'\n");
    }
}

sub start_log {
    my ($class, $filename) = @_;
    my $me = (ref $class || $class)."->start_log";

=item start_log()

Opens the log files and starts writing diagnostics

e.g. $Object->start_log('log_filename');

=cut
    my $type = $class->type;
    # Check for log file names
    $filename ||=
        $class->diag->log ||
        $class->{$type}->proto->{params}{$type}{diag}{log} ||
        $class->{$type}->proto->{project}{$type}{diag}{log} ||
        $class->{$type}->proto->{user}{$type}{diag}{log} ||
        $class->{$type}->proto->{site}{$type}{diag}{log} ||
        "STDOUT";
    $filename = $class->normalise($filename);

    if ($class->diag->autoflush) {
        select STDOUT; 
        $|=1;
        }
    if ('*STDOUT*1*' =~ /\*$filename\*/) {
        $filename = '&STDOUT';
    } else {
        $class->diag->log($filename);
    }
    if ($class->diag->verbose == 0 ) { 
        $class->diag_print (2, "Redirecting output to /dev/null");
        open STDOUT, ">/dev/null"; 

    } elsif ($class->diag->log) {
        unless ('*&STDOUT*STDOUT*1*' =~ /\*$filename\*/) {
            # Set full paths
            $class->diag->log($class->full_Path($class->diag->log, `pwd`));
            $class->diag_print (3, "%s- Opening log file '%s'", 
                $class->diag->indent, $class->diag->log);
            open STDOUT, ">".$class->diag->log or
                die sprintf("error %s - can't open file '%s' for output", 
                    $me, $class->diag->log);
        }
        open STDERR, ">&1" or
            die sprintf("error %s - can't redirect STDERR to file '%s'",
                $me, $class->diag->log);
    }
    $class->diag_print (2, 
        "--------------------------------------------------------");
    $class->diag_print (2, 
        "%s  DIAGNOSTICS - %s (locale <%s> verbosity %s) ".
        "started by %s (version %s)", 
        $class->diag->indent, $class->{$type}->start_time,
        $class->diag->LANG, $class->diag->verbose, 
        $class->{$type}->name, $class->{$type}->version, 
    );
}

sub stop_log {
    my ($class, $type) = @_;
    my $me = (ref $class || $class)."->stop_log";

=item stop_log()

Loads site/user/project/params options

e.g. $Object->stop_log;

=cut
    $type ||= $class->type;
    if ($class->diag->log and $class->diagnostics(2)) {
        $class->diag_print (2, 
            "%s  RUN COMPLETED - %s diagnostics stopped by %s (version %s)",
            $class->diag->indent, $class->get_time, 
            $class->{$type}->name, $class->{$type}->version);
        $class->diag_print (2, 
            "-----------------------------------------------------------------------------");
        close(STDERR) || die "can't close stderr: $!"; 
        close(STDOUT) || die "can't close stdout: $!" ;
    }
}

#===============================================================================
#=========== Gettext Utilities                                              ====
#=========== 'borrowed' from the gettext dist and recoded to house style    ====
#===============================================================================

=back

=head1 4) INTERNATIONALISATION (I18N) METHODS

These methods will load translations, translate messages, check for any
missing translations and write a .pot file containing these missing messages.

=over

=cut

=item _()

Translate a string into our current language

e.g. sprintf(_("A message '%s'"), $value);

=cut
sub _ {gettext(@_)}

=item gettext()

Translate into a preloaded language (eg $SOURCE_LANG or $DIAG_LANG)

e.g. C<sprintf(gettext($SOURCE_LANG, "A message '%s'"), $value);>

=cut
sub gettext {
    defined $I18N->{$RUN_LANG}{$_[0]} ? $I18N->{$RUN_LANG}{$_[0]} : $_[0];
}

# These are defined within a no-warning block to avoid warnings about redefining
# They override the subs in Glade::Two::Run during your development
{   
    local $^W = 0;
    eval "sub x_ {_check_gettext('__', \@_);}";
}

# Translate string into source language
sub S_ { _check_gettext($SOURCE_LANG, @_)}

# Translate string into diagnostics language
sub D_ { _check_gettext($DIAG_LANG, @_)}

# Internal utility to note any untranslated strings
sub _check_gettext {
    # If check_gettext_strings() has been called and there is no translation
    # we store the original string for later output by write_gettext_strings
    my ($key, $text, $depth) = @_;

    $depth ||= 1;
    if (defined $I18N->{$key}{$text}) {
        return $I18N->{$key}{$text};
    } else {
        if ($I18N->{$key}{$SAVE_MISSING}) {
            my $called_at = 
                basename((caller $depth)[1]). ":".(caller $depth)[2];
            unless ($I18N->{$key}{$MISSING_STRINGS}{$text} && 
                $I18N->{$key}{$MISSING_STRINGS}{$text} =~ / $called_at /) {
                $I18N->{$key}{$MISSING_STRINGS}{$text} .= " $called_at ";
            }
        }
        return $text;
    }
}

sub start_checking_gettext_strings {
    my ($class, $key, $file) = @_;

=item start_checking_gettext_strings()

Start checking and storing missing translations in language type

  eg. $class->start_checking_gettext_strings($SOURCE_LANG);


=cut
    $I18N->{($key || $RUN_LANG)}{$SAVE_MISSING} = ($file || "&STDOUT");
}

sub stop_checking_gettext_strings {
    my ($class, $key) = @_;

=item stop_checking_gettext_strings()

Stop checking for missing translations in language type

  eg. $class->stop_checking_gettext_strings($SOURCE_LANG);

=cut
    undef $I18N->{($key || $RUN_LANG)}{$SAVE_MISSING};
}

sub write_missing_gettext_strings {
    # Write out the strings that need to be translated in .pot format
    my ($class, $key, $file, $no_header, $copy_to) = @_;

=item write_missing_gettext_strings()

Write a .pot file containing any untranslated strings in language type

  eg. $object->write_missing_gettext_strings($SOURCE_LANG);

=cut
    my ($string, $called_at);
    my $me = __PACKAGE__."->write_translatable_strings";
    my $saved = $I18N->{$key}{$MISSING_STRINGS};
    $key  ||= $RUN_LANG;
    $file ||= $I18N->{$key}{$SAVE_MISSING};
    return unless keys %$saved;
    open POT, ">$file" or 
        die sprintf(("error %s - can't open file '%s' for output"),
                $me, $file);
    my $date = `date +"%Y-%m-%d %H:%M%z"`; chomp $date;
    my $year = `date +"%Y"`; chomp $year;
    # Print header
    print POT "# ".sprintf(S_("These are strings that had no gettext translation in '%s'"), $key)."\n";
    print POT "# ".sprintf(S_("Automatically generated by %s"),__PACKAGE__)."\n";
    print POT "# ".S_("Date")." ".`date`;
    print POT "# ".sprintf(S_("Run from class %s in file %s"), $class->PACKAGE, (caller 0)[1])."\n";
    unless ($no_header && $no_header eq "NO_HEADER") {
        print POT "
# SOME DESCRIPTIVE TITLE.
# Copyright (C) $year ORGANISATION
# ".$class->AUTHOR.",
#
# , fuzzy
msgid \"\"
msgstr \"\"
\"Project-Id-Version:  ".$class->PACKAGE." ".$class->VERSION."\\n\"
\"POT-Creation-Date: $date\\n\"
\"PO-Revision-Date:  YEAR-MO-DA HO:MI+ZONE\\n\"
\"Last-Translator:  ".$class->AUTHOR."\\n\"
\"Language-Team:  LANGUAGE \<LL".'@li.org'."\>\\n\"
\"MIME-Version:  1.0\\n\"
\"Content-Type: text/plain; charset=CHARSET\\n\"
\"Content-Transfer-Encoding:  ENCODING\\n\"

#: Generic replacement
msgid \"\%s\"
msgstr \"\%s\"

";  }

    # Print definition for each string
    foreach $string (%$saved) {
        next unless $string and $saved->{$string};
        print POT wrap("#", "#",$saved->{$string}), "\n";
        if ($string =~ s/\n/\\n\"\n\"/g) {$string = "\"\n\"".$string}
        print POT "msgid \"$string\"\n";
        if ($copy_to && $copy_to eq 'COPY_TO') {
            print POT "msgstr \"$string\"\n\n";
        } else {
            print POT "msgstr \"\"\n\n";
        }
    }
    close POT;
}

sub load_translations {
    my ($class, $domain, $language, $locale_dir, $file, $key, $merge) = @_;

=item load_translations()

Load a translation file (.mo) for later use as language type

  e.g. To load translations in current LANG from default locations
        $class->load_translations('MyApp');
  
  OR    $class->load_translations('MyApp', 'test', undef, 
            '/home/dermot/Devel/Glade-Perl/ppo/en.mo');

  OR    $class->load_translations('MyApp', 'fr', '/usr/local/share/locale/',
           undef, $DIAG_LANG, 'Merge with already loaded translations');

=cut
    my $catalog_filename = $file;
    $key ||= $RUN_LANG;
    $I18N->{$key} = {} unless $merge and $merge eq "MERGE";;

    $language ||= $ENV{"LANG"};
    return unless $language;
    $locale_dir ||= "/usr/local/share/locale";
    $domain     ||= "Glade-Perl";

    for $catalog_filename ( $file || 
        ("/usr/local/share/locale/$language/LC_MESSAGES/$domain.mo",
        "/usr/share/locale/$language/LC_MESSAGES/$domain.mo")) {
        if ($catalog_filename and (-f $catalog_filename)) {
            $class->load_mo($catalog_filename, $key);
            last;
        }
    }
}

sub load_mo {
    my ($class, $catalog, $key) = @_;

    my ($reverse, $buffer);
    my ($magic, $revision, $nstrings);
    my ($orig_tab_offset, $orig_length, $orig_pointer);
    my ($trans_length, $trans_pointer, $trans_tab_offset);

    # Slurp in the catalog
    my $save = $/;
    open CATALOG, $catalog or return;
    undef $/; 
    $buffer = <CATALOG>; 
    close CATALOG;
    $/ = $save;
    
    # Check magic order
    $magic = unpack ("I", $buffer);
    if (sprintf ("%x", $magic) eq "de120495") {
    	$reverse = 1;

    } elsif (sprintf ("%x", $magic) ne "950412de") {
    	print STDERR "'$catalog' "._("is not a catalog file")."\n";
        return;
    }

    $revision = &mo_format_value (4, $reverse, $buffer);
    $nstrings = &mo_format_value (8, $reverse, $buffer);
    $orig_tab_offset = &mo_format_value (12, $reverse, $buffer);
    $trans_tab_offset = &mo_format_value (16, $reverse, $buffer);

    while ($nstrings-- > 0) {
	    $orig_length = &mo_format_value ($orig_tab_offset, $reverse, $buffer);
	    $orig_pointer = &mo_format_value ($orig_tab_offset + 4, $reverse, $buffer);
	    $orig_tab_offset += 8;

	    $trans_length = &mo_format_value ($trans_tab_offset, $reverse, $buffer);
	    $trans_pointer = &mo_format_value ($trans_tab_offset + 4,$reverse, $buffer);
	    $trans_tab_offset += 8;

    	$I18N->{$key}{substr ($buffer, $orig_pointer, $orig_length)}
	        = substr ($buffer, $trans_pointer, $trans_length);
    }

    # Allow for translation of really empty strings
    $I18N->{$key}{$MO_HEADER_INFO} = $I18N->{$key}{''};
    $I18N->{$key}{''} = '';
}

sub mo_format_value {
    my ($string, $reverse, $buffer) = @_;

    unpack ("i",
	    $reverse
	    ? pack ("c4", reverse unpack ("c4", substr ($buffer, $string, 4)))
	    : substr ($buffer, $string, 4));
}

#===============================================================================
#=========== Widget hierarchy Utilities                                     ====
#===============================================================================
sub WH {
    my ($class, $new) = @_; 
    if ($new) {
        return $class->FORM->{$WH} = $new;
    } else {
      return $class->FORM->{$WH};
    }
}

sub CH {
    my ($class, $new) = @_;
    if ($new) {
      return $class->FORM->{$CH} = $new;
    } else {
      return $class->FORM->{$CH};
    }
}

sub W {
    my ($class, $proto, $new) = @_;
    if ($new) {
      return $proto->{$W} = $new;
    } else {
      return $proto->{$W};
    }
}

sub C {
    my ($class, $proto, @new) = @_;
    if ($#new) {
      return push @{$proto->{$C}}, @new;
    } else {
      return $proto->{$C};
    }
}

#===============================================================================
#=========== UI utilities
#===============================================================================

=back

=head1 5) UI METHODS

These methods will provide some useful UI methods to load pixmaps and 
images and show message boxes of various types.

=over

=cut

sub create_pixmap {
    my ($class, $widget, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_pixmap";

=item create_pixmap()

Create a gdk_pixmap and return it

e.g. my $pixmap = Glade::Two::Run->create_pixmap(
    $form, 'new.xpm', ['dir1', 'dir2']);

=cut

    # First look for a sub
    if (ref $filename eq 'CODE') {
        return new Gtk2::Pixmap(
            Gtk2::Gdk::Pixmap->create_from_xpm_d(
                $work->{'window'}, $work->{'style'}, &filename ));
    } else {
        my $found_filename = $class->find_file_in_dirs(
            $filename, 
            @{$pixmap_dirs}, $Glade::Two::Run::pixmaps_directory, getcwd);

        return Gtk::Pixmap->create_from_xpm($found_filename);
    }
}

sub create_image {
    my ($class, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_image";

=item create_image()

Create and load a gdk_imlibimage and return it

e.g. my $image = Glade::Two::Run->create_image(
    'new.xpm', ['dir1', 'dir2']);

=cut
    my $found_filename = $class->find_file_in_dirs(
        $filename, 
        @{$pixmap_dirs}, $Glade::Two::Run::pixmaps_directory, getcwd);
    return Gtk2::Image->new_from_file($found_filename);
}

sub create_pixbuf {
    my ($class, $filename, $pixmap_dirs) = @_;
    my $me = "$class->create_pixbuf";

=item create_image()

Create and load a gdk_pixbuf and return it

e.g. my $image = Glade::Two::Run->create_pixbuf(
    'new.xpm', ['dir1', 'dir2']);

=cut
    my $found_filename = $class->find_file_in_dirs(
        $filename, 
        @{$pixmap_dirs}, $Glade::Two::Run::pixmaps_directory, getcwd);
    return Gtk2::Gdk::Pixbuf->new_from_file($found_filename);
}

sub find_file_in_dirs {
    my ($class, $filename, @dirs) = @_;
    my $me = "$class->find_file_in_dirs";
    my ($work, $testfile, $found_filename, $dir);
    if (-f $filename) {
        $found_filename = $filename;

    } else {
        foreach $dir (@dirs) {
            # Make up full path name and test
            $testfile = $class->full_Path($filename, $dir);
        	if (-f $testfile) {
                $found_filename = $testfile;
                last;
        	}
        }
    }
    if ($found_filename) {
        return $found_filename;
    } else {
        print STDERR sprintf(_(
            "error file '%s' does not exist in %s\n"),
            $filename, $me);
        return undef;
    }
}

sub missing_handler {
    my ($class, $dataref, $eventref) = @_;
    my ($widgetname, $signal, $handler, $pixmap) = @$dataref;
    my $me = __PACKAGE__."->missing_handler";

#=item missing_handler()
#
#This method pops up a message while the source code is being generated
#if there is no signal handler to call.
#It shows a pixmap (logo) and buttons to dismiss the box or quit the app
#
# $widgetname the widget that triggered the event
# $signal    the signal that was triggered
# $handler   the name of the signal handler that is missing
# $pixmap    pixmap to show
#
#e.g. Glade::Two::Run->missing_handler(
#        $widgetname, 
#        $signal, 
#        $handler, 
#        $pixmap);
#
#=cut
    print STDOUT sprintf(_("%s- %s - called with args ('%s')"),
        $indent, $me, join("', '", @_)), "\n";
    my $message = sprintf("\n"._("%s has been called because\n".
                    "a signal (%s) was caused by widget (%s).\n".
                    "When Glade::Two::Generate writes the Perl source to a file \n".
                    "a skeleton signal handler sub called '%s'\n".
                    "will be generated in the ProjectSIGS class file. You can write a sub with\n".
                    "the same name in another module and it will automatically be called instead.\n"),
                    $me, $signal, $widgetname, $handler) ;
    my $widget = __PACKAGE__->message_box($message, 
        _("Missing handler")." '$handler' "._("called"), 
        [_("Dismiss"), _("Quit")." Glade::Two::Generate"], 1, $pixmap);
    
    # Stop the signal before it triggers the missing one
#FIXME    $class->signal_stop_emission($signal);
#    $class->signal_emit_stop($signal);
    return $widget;
}

sub show_skeleton_message {
    my ($class, $caller, $data, $package, $pixmap) = @_;
#print Dumper(\@_);
=item show_skeleton_message($class, $caller, $data, $package, $pixmap)

This method pops up a message_box to prove that a stub has been called.
It shows a pixmap (logo) and buttons to dismiss the box or quit the app

 $caller    where we were called
 $data      the args that were supplied to the caller
 $package
 $pixmap    pixmap to show

e.g. Glade::Two::Run->show_skeleton_message(
    $me, \@_, __PACKAGE__, "$Glade::Two::Run::pixmaps_directory/Logo.xpm");

=cut
    $pixmap  ||= "$Glade::Two::Run::pixmaps_directory/Logo.xpm";
    $package ||= (caller);
    $data    ||= ['unknown args'];

    my $args = (ref $data->[0]);
    if (ref $data->[1] and ref $data->[1] eq 'ARRAY') {
        $args .= ", ['".join("', '", @{$data->[1]})."']".
        (ref $data->[2] && ', '.(ref $data->[2]).')');
    }
    $class->message_box(sprintf(_("
A signal handler has just been triggered.

%s 
was called with parameters (%s)

Until the sub is written, I will show you 
this box to prove that I have been called
"), 
    $caller, 
    $args),
    $caller, 
    [_('Dismiss'), _("Quit")." Program"], 
    1, 
    $pixmap);
}

sub message_box {
    my ($class, $text, $title, $buttons, $default, 
        $pixmapfile, $just, $handlers, $entry) = @_;

=item message_box()

Show a message box with optional pixmap and entry widget.
After the dialog is closed, the data entered will be in
global $Glade::Two::Run::data.

e.g. Glade::Two::Run->message_box(
    $message,           # Message to display
    $title,             # Dialog title string
    [_('Dismiss'), _("Quit")." Program"],   
                        # Buttons to show
    1,                  # Default button is 1st
    $pixmap,            # pixmap filename
    [&dismiss, &quit],  # Button click handlers
    $entry_needed);     # Whether to show an entry
                        # widget for user data

=cut
#use Data::Dumper;print Dumper(\@_);
    my ($i, $ilimit);
    my $justify = $just || 'center';
    my $mbno = 1;
    # Get a unique toplevel widget structure
    while (defined $widgets->{"MessageBox-$mbno"}) {$mbno++;}
    #
    # Create a GtkDialog called MessageBox
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE} = new Gtk2::Window('toplevel');
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->set_title($title);
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->set_position('mouse');
#    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->set_policy('1', '1', '0');
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->set_border_width('6');
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->modal('1');
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->realize;
#print Dumper($widgets);
#    $widgets->{"MessageBox-$mbno"}{'tooltips'} = new Gtk2::Tooltips;
        #
        # Create a GtkVBox called MessageBox-vbox1
#use Data::Dumper;print Dumper($widgets);
        $widgets->{"MessageBox-$mbno"}{'vbox1'} = new Gtk2::VBox(0, 0);
        $widgets->{"MessageBox-$mbno"}{'vbox1'}->set_border_width(0);
        $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->add($widgets->{"MessageBox-$mbno"}{'vbox1'});
        $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->show();
            #
            # Create a GtkHBox called MessageBox-hbox1
            $widgets->{"MessageBox-$mbno"}{'hbox1'} = new Gtk2::HBox('0', '0');
            $widgets->{"MessageBox-$mbno"}{'hbox1'}->set_border_width('0');
            $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'hbox1'});
            $widgets->{"MessageBox-$mbno"}{'hbox1'}->show();

    		if ($pixmapfile) { 
                #
                # Create a GtkPixmap called pixmap1
    			$widgets->{"MessageBox-$mbno"}{'pixmap1'} = $class->create_image($pixmapfile);
    			if ($widgets->{"MessageBox-$mbno"}{'pixmap1'}) {
                    $widgets->{"MessageBox-$mbno"}{'pixmap1'}->set_alignment('0.5', '0.5');
#    	            $widgets->{"MessageBox-$mbno"}{'pixmap1'}->set_padding('0', '0');
        	        $widgets->{"MessageBox-$mbno"}{'hbox1'}->add($widgets->{"MessageBox-$mbno"}{'pixmap1'});
            	    $widgets->{"MessageBox-$mbno"}{'pixmap1'}->show();
#    	            $widgets->{"MessageBox-$mbno"}{'hbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'pixmap1'}, '0', '0', '0', 'start');
    			}
    		}

                #
                # Create a GtkLabel called MessageBox-label1
                $widgets->{"MessageBox-$mbno"}{'label1'} = new Gtk2::Label($text);
                $widgets->{"MessageBox-$mbno"}{'label1'}->set_justify($justify);
                $widgets->{"MessageBox-$mbno"}{'label1'}->set_alignment('0.5', '0.5');
#                $widgets->{"MessageBox-$mbno"}{'label1'}->set_padding('0', '0');
                $widgets->{"MessageBox-$mbno"}{'hbox1'}->add($widgets->{"MessageBox-$mbno"}{'label1'});
                $widgets->{"MessageBox-$mbno"}{'label1'}->show();
#    	        $widgets->{"MessageBox-$mbno"}{'hbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'label1'}, '1', '1', '10', 'start');
#        	$widgets->{"MessageBox-$mbno"}{'vbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'hbox1'}, '1', '1', '0', 'start');
            #
            # Create a GtkHBox called MessageBox-action_area1
            $widgets->{"MessageBox-$mbno"}{'action_area1'} = new Gtk2::HBox('1', '5');
            $widgets->{"MessageBox-$mbno"}{'action_area1'}->set_border_width('10');
            $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'action_area1'});
            $widgets->{"MessageBox-$mbno"}{'action_area1'}->show();
                if ($entry) {
                    #
                    # Create a GtkEntry called MessageBox-entry
                    $widgets->{"MessageBox-$mbno"}{'entry'} = new Gtk2::Entry;
                    $widgets->{"MessageBox-$mbno"}{'vbox1'}->add($widgets->{"MessageBox-$mbno"}{'entry'});
					$widgets->{"MessageBox-$mbno"}{'entry'}->show( );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_usize('160', '0' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->can_focus('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_text('' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_max_length('0' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_visibility('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->set_editable('1' );
					$widgets->{"MessageBox-$mbno"}{'entry'}->grab_focus();
                }
                #
                # Create a GtkHButtonBox called MessageBox-hbuttonbox1
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'} = new Gtk2::HButtonBox;
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->set_layout('default_style');
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->set_spacing('10');
                $widgets->{"MessageBox-$mbno"}{'action_area1'}->add($widgets->{"MessageBox-$mbno"}{'hbuttonbox1'});
                $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->show();
    			#
    			# Now add all the buttons that were requested (and check for default)
    			$ilimit = scalar(@$buttons);
    			for ($i = 0; $i < $ilimit; $i++) {
                    #
                    # Create a GtkButton called MessageBox-button2
                    $widgets->{"MessageBox-$mbno"}{'button'.$i} = new_with_label Gtk2::Button($buttons->[$i]);
#                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->can_focus('1');
    				if ($handlers->[$i]) {
    					$widgets->{"MessageBox-$mbno"}{'button'.$i}->signal_connect('clicked', $handlers->[$i], [$mbno, $buttons->[$i]]);
    				} else {
    					$widgets->{"MessageBox-$mbno"}{'button'.$i}->signal_connect('clicked', __PACKAGE__."::message_box_close", [$mbno, $buttons->[$i]]);
    				}
                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->set_border_width('0');
                    $widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}->add($widgets->{"MessageBox-$mbno"}{'button'.$i});
    				if ($i == ($default-1)) {
                        $widgets->{"MessageBox-$mbno"}{'button'.$i}->SET_FLAGS('can-default');
#                        $widgets->{"MessageBox-$mbno"}{'button'.$i}->can_default('1');
    	                $widgets->{"MessageBox-$mbno"}{'button'.$i}->grab_default();
    				}
                    $widgets->{"MessageBox-$mbno"}{'button'.$i}->show();
                }
#    			$widgets->{"MessageBox-$mbno"}{'action_area1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'hbuttonbox1'}, '1', '1', '0', 'start');
#    	    $widgets->{"MessageBox-$mbno"}{'vbox1'}->set_child_packing($widgets->{"MessageBox-$mbno"}{'action_area1'}, '0', '1', '0', 'end');
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->show_all();
#print Dumper($widgets);
    return $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE};
}

sub message_box_close {
    my ($class, $dataref) = @_;
    my ($mbno, $button_label) = @$dataref;
    # Close this message_box and tidy up
    $widgets->{"MessageBox-$mbno"}{$WIDGET_INSTANCE}->destroy;
    undef $widgets->{"MessageBox-$mbno"};
    my $quit_string = _("Quit")." Program*"._("Quit")." Glade::Two::Generate*";
    if (_("*$quit_string*Quit Generate*Quit UI Build*Close Form*") =~ m/\*$button_label\*/) {
        Gtk2->quit;
    }
    return $dataref;
}

sub destroy_all_forms {
    my $class = shift;
    my $hashref = shift || $__PACKAGE__::all_forms;
    my $myform;
    foreach $myform (keys %$hashref) {
        $hashref->{$myform}->get_toplevel->destroy;
        undef $hashref->{$myform};
    }
}

#===============================================================================
#=========== Utilities 					                    	    ============
#===============================================================================

=back

=head1 6) GENERAL METHODS

These are some general purpose methods that are useful to Glade::Two::Generate
and generated apps.

=over

=cut

sub get_time {
    # FIXME check that this is portable and always works
    #   why does it give BST interactively but UTC from Glade??
    #        $key = sprintf(" (%+03d00)", (localtime)[8]);
    #        $key = (localtime).$key;
    my $time = `date`;
    chomp $time;
    return $time
}

sub full_Path {
    my ($class, $rel_path, $directory, $default) = @_;
    my $me = "$class->full_Path";
#shift;print Dumper(\@_);
=item full_Path()

Turn a relative path name into an absolute path

e.g. my $path = Glade::Two::Run->full_Path($relative_path, $directory);

=cut
    my $basename;
    my $slash = '/';
    my $updir = '/\.\./';
    # set to $default if not defined
    my $fullname = $rel_path || $default || '';
    # add $base unless we are absolute already
    if ($fullname !~ /^$slash/ && defined $directory) {
        # We are supposed to be relative to a directory so use Cwd->chdir to
        # change to specified directory and Cwd->getcwd to get full path names
        my $save_dir = getcwd;
        chdir($directory);
#print "cd to ".getcwd."\n";
        my $fulldir = getcwd;
#print "getcwd thinks it is '$fulldir'\n";
        $fullname = "$fulldir$slash$fullname"; 
        # Now change directory to where we were on entry
        chdir($save_dir);
#print "and back to ".getcwd."\n";
    } else {
        # Get the real path (not symlinks)
        my $dirname = dirname($fullname);
        my $basename = basename($fullname);
        my $save_dir = getcwd;
        chdir($dirname);
#print "cd2 to ".getcwd."\n";
        my $fulldir = getcwd;
#print "getcwd2 thinks it is '$fulldir'\n";
        $fullname = "$fulldir$slash$basename"; 
        # Now change directory to where we were on entry
        chdir($save_dir);
#print "and back2 to ".getcwd."\n";
    }    
    # Remove double //s and /./s
    $fullname =~ s/$slash\.?$slash/$slash/g;
    # Remove /../ relative directories
    while ($fullname =~ /$updir/) {
        $fullname =~ s/(.+)(?!$updir)$slash.+?$updir/$1$slash/;
    }
    # Remove trailing /s
    $fullname =~ s/$slash$//;
#print "Converted to '$fullname'\n\n------------------------------------\n";
    return $fullname;
}

sub relative_path {
    my ($class, $basepath, $path, $root) = @_;
    my $me = __PACKAGE__."::relative_path";

=item relative_Path($basepath, $path, $root)

Turn an absolute path name into a relative path

e.g. my $path = Glade::Two::Run->relative_Path($relative_path, $directory);

=cut
    return $path if $path =~ /:/;
    my $rel;
    # This loop is based on code from Nicolai Langfeldt <janl@ifi.uio.no>.
    # First we calculate common initial path components length ($li).
    my $li = 1;
    while (1) {
        my $i = index($path, '/', $li);
        last if $i < 0 ||
                $i != index($basepath, '/', $li) ||
                substr($path,$li,$i-$li) ne substr($basepath,$li,$i-$li);
        $li=$i+1;
    }
    # then we nuke it from both paths
    substr($path, 0,$li) = '';
    substr($basepath,0,$li) = '';

    $rel = "";

    # Add one "../" for each path component left in the base path
    $path = ('../' x $basepath =~ tr|/|/|) . $path;
    $path = "./" if $path eq "";
    $rel = $path;

    return $rel;
}

sub string_from_file {&string_from_File(@_);}
sub string_from_File {
    my ($class, $filename) = @_;
    my $me = __PACKAGE__."->string_from_File";

=item string_from_File()

Reads (slurps) a file into a string

e.g. my $string = Glade::Two::Run->string_from_file('/path/to/file');

=cut
    my $save = $/;
    undef $/;
    open INFILE, $filename or 
        die sprintf((
            "error %s - can't open file '%s' for input"),
            $me, $filename);    
    undef $/;
    my $string = <INFILE>;
    close INFILE;
    $/ = $save;

    return $string;
}

sub typeKey     { return ' type'; }
#sub keyFormat  { if (shift) {return '%04u-%s' } else {return '%04u' } }
sub keyFormat   { return '%04u' } 

sub QuoteXMLChars {
    my $text = shift;
    # Suggested by Eric Bohlman <ebohlman@netcom.com> on perl-xml mailling list
    my %ents=('&'=>'amp','<'=>'lt','>'=>'gt',"'"=>'apos','"'=>'quot');
    $text =~ s/([&<>'"])/&$ents{$1};/g;
    # Uncomment the line below if you don't want to use European characters in 
    # your project options
#    $text =~ s/([\x80-\xFF])/&XmlUtf8Encode(ord($1))/ge;
    return $text;
}

sub UnQuoteXMLChars {
    my $text = shift;
    my %ents=('&lt;'=>'<','&gt;'=>'>','&apos;'=>"'",'&quot;'=>'"', '&amp;'=>'&');
    $text =~ s/(&lt;|&gt;|&apos;|&quot;|&amp;)/$ents{$1}/g;
    return $text;
}

sub XmlUtf8Encode {
    # This was ripped from XML::DOM - thanks to
    # Enno Derksen (official maintainer), enno@att.com
    # and Clark Cooper, coopercl@sch.ge.com
    my $n = shift;
    my $me = "XmlUtf8Encode";
    if ($n < 0x80)    { 
        return chr ($n);

    } elsif ($n < 0x800) {
        return pack ("CC", (($n >> 6) | 0xc0), 
                    (($n & 0x3f) | 0x80));

    } elsif ($n < 0x10000) {
        return pack ("CCC", (($n >> 12) | 0xe0), 
                    ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));

    } elsif ($n < 0x110000) {
        return pack ("CCCC", (($n >> 18) | 0xf0), 
                    ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), 
                      (($n & 0x3f) | 0x80));
    }
    __PACKAGE__->diag_print(1, 
        "error Number is too large for Unicode [%s] in %s ", $n, $me);
    return "#";
}

sub reload_any_altered_modules {
    my ($class) = @_;
    my $me = __PACKAGE__."->reload_any_altered_modules";

=item reload_any_altered_modules()

Check all loaded modules and reload any that have been altered since the
app started. This saves restarting the app for every change to the signal
handlers or support modules. 

It is impossible to reload the UI module (called something like ProjectUI.pm)
while the app is running without crashing it so don't run glade2perl and then
call this method.
Similarly, any modules that construct objects in their 
own namespace will cause unpredictable failures.

I usually call this in a button's signal handler so that I can edit the
modules and easily reload the edited versions of modules.

e.g. Glade::Two::Run->reload_any_altered_modules;

=cut
    my $stat = \%stat;
    my $reloaded = 0;
    my ($prefix, $msg);
    if (ref $class) {
        $prefix = ($class->{diag}{indent} || $indent);
    } else {
        $prefix = $indent;
    }
    $prefix .= "- $me";
    while(my($key,$file) = each %INC) {
        local $^W = 0;
        my $mtime = (stat $file)[9];
        # warn and skip the files with relative paths which can't be
        # located by applying @INC;
        unless (defined $mtime and $mtime) {
            print "$prefix - Can't locate $file\n",next 
        }
        unless(defined $stat->{$file}) {
            # First time through so log process start time
            $stat->{$file} = $^T;
        }

        if($mtime > $stat->{$file}) {
            delete $INC{$key};
            require $key;
            $reloaded++;
            print "$prefix - Reloading $key in process $$\n";
        }
        # Log actual stat/checked time
        $stat->{$file} = $mtime;
    }
    return "Reloaded $reloaded module(s) in process $$";
}

=back

=head1 SEE ALSO

Glade::Two::Generate(3) glade2perl-2(1)

=head1 AUTHOR

Dermot Musgrove <dermot.musgrove@virgin.net>

=cut

1;

__END__

