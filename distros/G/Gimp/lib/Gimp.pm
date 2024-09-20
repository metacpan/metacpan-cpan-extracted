package Gimp;

use strict;
use warnings;
our (
  $VERSION, @ISA, $AUTOLOAD, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, @EXPORT_FAIL,
  $interface_pkg, $interface_type, @PREFIXES,
  $function, $basename, $spawn_opts, $host,
);
use subs qw(init end lock unlock);

BEGIN {
   $VERSION = '2.38'; # going forward: 2.xx, or 2.xx_yy for dev
   eval {
      require XSLoader;
      XSLoader::load Gimp $VERSION;
   } or do {
      require DynaLoader;
      @ISA = qw(DynaLoader);
      bootstrap Gimp $VERSION;
   };
}

use Gimp::ColorDB;
use Carp qw(croak);

our @GUI_FUNCTIONS = qw(
   gimp_progress_init
   gimp_progress_update
   gimp_display_new
   gimp_display_delete
);

my @_procs = ('__', 'N_');
#my @_default = (@_procs, ':consts' ,':_auto2');
my @_default = (@_procs, ':consts');
my @POLLUTE_CLASSES;

sub import($;@) {
   no strict 'refs';
   my $pkg = shift;
   warn "$$-$pkg->import(@_)" if $Gimp::verbose >= 2;
   my $up = caller;
   my @export;

   # make sure we can call GIMP functions - start net conn if required
   my $net_init;
   map { $net_init = $1 if /net_init=(\S+)/; } @_;
   if ($interface_type eq "net" and not &Gimp::Net::initialized) {
      map { *{"Gimp::$_"} = \&{"Gimp::Constant::$_"} }
	 qw(RUN_INTERACTIVE RUN_NONINTERACTIVE);
      Gimp::Net::gimp_init(grep {defined} $net_init);
   }
   # do this here as not guaranteed access to GIMP before
   require Gimp::Constant;
   if (not defined &{$Gimp::Constant::EXPORT[-1]}) {
     warn "$$-Loading constants" if $Gimp::verbose >= 2;
     # now get constants from GIMP
     import Gimp::Constant;
   }

   @_=@_default unless @_;

   for(map { $_ eq ":DEFAULT" ? @_default : $_ } @_) {
      if ($_ eq ":auto") {
         push @export,@Gimp::Constant::EXPORT,@_procs;
         *{"$up\::AUTOLOAD"} = sub {
            croak "Cannot call '$AUTOLOAD' at this time" unless initialized();
            my ($class,$name) = $AUTOLOAD =~ /^(.*)::(.*?)$/;
            *{$AUTOLOAD} = sub { unshift @_, 'Gimp'; $AUTOLOAD = "Gimp::$name"; goto &AUTOLOAD };
            #*{$AUTOLOAD} = sub { Gimp->$name(@_) }; # old version
            goto &$AUTOLOAD;
         };
      } elsif ($_ eq ":pollute") {
	for my $class (@POLLUTE_CLASSES) {
	  push @{"$class\::ISA"}, "Gimp::$class";
	  push @{"$class\::PREFIXES"}, @{"Gimp::$class\::PREFIXES"};
	}
      } elsif ($_ eq ":consts") {
         push @export,@Gimp::Constant::EXPORT;
      } elsif ($_ eq ":param") {
         push @export,@Gimp::Constant::PARAMS;
      } elsif (/^interface=(\S+)$/) {
         croak __"interface=... tag is no longer supported\n";
      } elsif (/spawn_options=(\S+)/) {
         $spawn_opts = $1;
      } elsif (/net_init=(\S+)/) {
	 # already used above, no-op
      } elsif ($_ ne "") {
         push(@export,$_);
      } elsif ($_ eq "") {
         #nop #d#FIXME, Perl-Server requires this!
      } else {
         croak __"$_ is not a valid import tag for package $pkg";
      }
   }

   for(@export) {
      *{"$up\::$_"} = \&$_;
   }
}

# the monadic identity function
sub N_($) { shift }

my $gtk_init = 1;

sub gtk_init() {
   if ($gtk_init) {
      require Gtk2;
      Gtk2->init;
      Gtk2::Rc->parse (Gimp->gtkrc);
      $gtk_init = 0;
   }
}

# section on command-line handling/interface selection

($basename = $0) =~ s/^.*[\\\/]//;
$spawn_opts = "";
($function)=$0=~/([^\/\\]+)$/;

$Gimp::verbose=0 unless defined $Gimp::verbose;
# $Gimp::verbose=1;

$interface_type = "net";
if (@ARGV) {
   if ($ARGV[0] eq "-gimp") {
      $interface_type = "lib";
      # ignore other parameters completely
   } else {
      while(@ARGV) {
         $_=shift(@ARGV);
         if (/^-h$|^--?help$|^-\?$/) {
            $Gimp::help=1;
            print __<<EOF;
Usage: $basename [gimp-args...] [interface-args...] [script-args...]
       gimp-arguments are
           -h | -help | --help | -?   print some help
           -v | --verbose             verbose flag (ok more than once)
           --host|--tcp HOST[:PORT]   connect to HOST (optionally using PORT)
                                      (for more info, see Gimp::Net(3))
EOF
         } elsif (/^-v$|^--verbose$/) {
            $Gimp::verbose++;
         } elsif (/^--host$|^--tcp$/) {
            $host=shift(@ARGV);
         } else {
            unshift(@ARGV,$_);
            last;
         }
      }
   }
}

# section on error-handling

# section on callbacks

my %callback;

sub cbchain {
  map { @{$callback{$_} || []}; } @_;
}

sub callback {
  warn "$$-Gimp::callback(@_)" if $Gimp::verbose >= 2;
  my $type = shift;
  my @cb;
  if ($type eq "-run") {
    local $function = shift;
    @cb = cbchain(qw(run lib), $function);
    die __"required callback 'run' not found for $function\n" unless @cb;
    # returning list of last func's return values
    my @retvals;
    for (@cb) {
      @retvals = &$_;
    }
    warn "$$-Gimp::callback returning(@retvals)" if $Gimp::verbose >= 2;
    @retvals;
  } elsif ($type eq "-net") {
    @cb = cbchain(qw(run net));
    die __"required callback 'net' not found for $function\n" unless @cb;
    # returning list of last func's return values
    my @retvals;
    for (@cb) {
      @retvals = &$_;
    }
    warn "$$-Gimp::callback returning(@retvals)" if $Gimp::verbose >= 2;
    @retvals;
  } elsif ($type eq "-query") {
    @cb = cbchain(qw(query));
    die __"required callback 'query' not found for $function\n" unless @cb;
    for (@cb) { &$_ }
  } elsif ($type eq "-quit") {
    @cb = cbchain(qw(quit));
    for (@cb) { &$_ }
  } elsif ($type eq "-proc") {
    @cb = cbchain(qw(proc));
    for (@cb) { &$_ }
  }
}

sub register_callback($$) {
   push @{$callback{$_[0]}}, $_[1];
   warn "$$-register_callback(@_)" if $Gimp::verbose >= 2;
}

sub on_query(&) { register_callback "query", $_[0] }
sub on_net  (&) { register_callback "net"  , $_[0] }
sub on_lib  (&) { register_callback "lib"  , $_[0] }
sub on_run  (&) { register_callback "run"  , $_[0] }
sub on_quit  (&) { register_callback "quit"  , $_[0] }
sub on_proc  (&) { register_callback "proc"  , $_[0] }

sub main {
   no strict 'refs';
   &{"$interface_pkg\::gimp_main"};
}

# section on interface_pkg

if ($interface_type=~/^lib$/i) {
   $interface_pkg="Gimp::Lib";
} elsif ($interface_type=~/^net$/i) {
   $interface_pkg="Gimp::Net";
} else {
   croak __"interface '$interface_type' unsupported.";
}
warn "$$-Using interface '$interface_type'" if $Gimp::verbose >= 2;

eval "require $interface_pkg" or croak $@;
$interface_pkg->import;
warn "$$-Finished loading '$interface_pkg'" if $Gimp::verbose >= 2;

# create some common aliases
for(qw(gimp_procedural_db_proc_exists gimp_call_procedure initialized)) {
   no strict 'refs';
   *$_ = \&{"$interface_pkg\::$_"};
}

*end   = \&{"$interface_pkg\::gimp_end"};
*lock  = \&{"$interface_pkg\::lock"};
*unlock= \&{"$interface_pkg\::unlock"};

# section on AUTOLOAD

my %ignore_function = (DESTROY => 1);

@PREFIXES=("gimp_", "");

sub ignore_functions(@) {
   warn "$$-IGNORING(@_)" if $Gimp::verbose >= 2;
   @ignore_function{@_}++;
}

my %proc2deprecated = (
  # needed to get the Perl-Server up and running
  gimp_procedural_db_query => 0,
  gimp_procedural_db_proc_exists => 0,
  gimp_enums_get_type_names => 0,
  gimp_enums_list_type => 0,
  gimp_install_procedure => 0,
);
my $deprecations_loaded = 0;
sub deprecated {
  warn "$$-deprecated(@_)" if $Gimp::verbose >= 2;
  my $proc = shift;
  unless ($deprecations_loaded or defined $proc2deprecated{$proc}) {
    $deprecations_loaded = 1;
    map { s#-#_#g; $proc2deprecated{$_}++ }
      Gimp->procedural_db_query('.*', '.*deprecated.*', ('.*') x 5);
  }
  $proc2deprecated{$proc} = !!$proc2deprecated{$proc};
}

sub recroak { $_[0] =~ /\n$/ ? die shift : croak shift; }
sub exception_strip {
  my ($file, $e) = @_;
  $file =~ s#\..*##;
  $e =~ s# at $file\S+ line \d+\.\n\Z##;
  $e;
}
sub AUTOLOAD {
  my $autoload_copy = $AUTOLOAD; # needed as if autoload inside, not restored
  warn "$$-AUTOLOAD $autoload_copy(@_)" if $Gimp::verbose >= 2;
  no strict 'refs';
  goto &$autoload_copy if defined &$autoload_copy; # happens if :auto, not if method call
  my ($class,$name) = $autoload_copy =~ /^(.*)::(.*?)$/;
  for(@{"$class\::PREFIXES"}) {
    my $sub = $_.$name;
    if (exists $ignore_function{$sub}) {
      *{$autoload_copy} = sub { () };
      goto &$autoload_copy;
    } elsif (UNIVERSAL::can('Gimp::Util',$sub)) {
      my $ref = \&{"Gimp::Util::$sub"};
      *{$autoload_copy} = sub {
	shift unless ref $_[0];
	my @r = eval { &$ref };
	recroak exception_strip(__FILE__, $@) if $@; wantarray ? @r : $r[0];
      };
      goto &$autoload_copy;
    } elsif (UNIVERSAL::can($interface_pkg,$sub)) {
      my $ref = \&{"$interface_pkg\::$sub"};
      *{$autoload_copy} = sub {
	shift unless ref $_[0];
	my @r = eval { &$ref };
	recroak exception_strip(__FILE__, $@) if $@; wantarray ? @r : $r[0];
      };
      goto &$autoload_copy;
    } elsif (not deprecated($sub) and gimp_procedural_db_proc_exists($sub)) {
      *{$autoload_copy} = sub {
	warn "$$-gimp_call_procedure{0}(@_)" if $Gimp::verbose >= 2;
	shift unless ref $_[0];
	unshift @_, $sub;
	warn "$$-gimp_call_procedure{1}(@_)" if $Gimp::verbose >= 2;
	my @r = eval { gimp_call_procedure (@_) };
	recroak exception_strip(__FILE__, $@) if $@; wantarray ? @r : $r[0];
      };
      goto &$autoload_copy;
    }
  }
  croak __"function/macro \"$name\" not found in $class";
}

# section on classes

sub _pseudoclass {
  my ($class, @prefixes)= @_;
  unshift @prefixes,"";
  no strict 'refs';
  *{"Gimp::$class\::AUTOLOAD"} = \&AUTOLOAD;
  push @{"Gimp::$class\::PREFIXES"}, @prefixes;
  push @{"Gimp::$class\::ISA"}, 'Gimp::Base';
  push @POLLUTE_CLASSES, $class;
  @{"Gimp::$class\::PREFIXES"}; # to suppress only-once warning
}

my @plugin_prefixes = qw(plug_in_ perl_fu_ script_fu_);
my @image_prefixes = (qw(gimp_image_ gimp_), @plugin_prefixes);
my @item_prefixes = (qw(gimp_item_), @image_prefixes);
my @drawable_prefixes = (qw(gimp_drawable_), @item_prefixes);

_pseudoclass qw(Item		), @item_prefixes;
_pseudoclass qw(Layer		gimp_layer_ gimp_floating_sel_), @drawable_prefixes;
_pseudoclass qw(Image		), @image_prefixes;
_pseudoclass qw(Drawable	), @drawable_prefixes;
_pseudoclass qw(Selection	gimp_selection_);
_pseudoclass qw(Vectors		gimp_vectors_);
_pseudoclass qw(Channel		gimp_channel_), @drawable_prefixes;
_pseudoclass qw(Display		gimp_display_ gimp_);
_pseudoclass qw(Plugin		), @plugin_prefixes;
_pseudoclass qw(Gradient	gimp_gradient_);
_pseudoclass qw(Gradients	gimp_gradients_);
_pseudoclass qw(Edit		gimp_edit_);
_pseudoclass qw(Progress	gimp_progress_);
_pseudoclass qw(Parasite	);

push @Gimp::Drawable::ISA, qw(Gimp::Item);
push @Gimp::Vectors::ISA, qw(Gimp::Item);
push @Gimp::Channel::ISA, qw(Gimp::Drawable);
push @Gimp::Layer::ISA, qw(Gimp::Drawable);

# "C"-Classes
_pseudoclass qw(GimpDrawable	gimp_gdrawable_);
_pseudoclass qw(PixelRgn	gimp_pixel_rgn_);
_pseudoclass qw(Tile		gimp_tile_);

# Classes without GIMP-Object
_pseudoclass qw(Palette		gimp_palette_);
_pseudoclass qw(Context         gimp_context_);
_pseudoclass qw(Brushes		gimp_brush_ gimp_brushes_);
_pseudoclass qw(Brush		gimp_brush_);
_pseudoclass qw(Edit		gimp_edit_);
_pseudoclass qw(Patterns	gimp_patterns_);
_pseudoclass qw(Pattern	        gimp_pattern_);

{
package Gimp::PixelRgn;
use vars qw(@CARP_NOT); # package scope
@CARP_NOT = qw(Gimp);

sub new($$$$$$$$) {
   shift;
   my $self = eval { Gimp::PixelRgn->init(@_); };
   die "Args=(@_): ".$@ if $@;
   $self;
}
}

{
package Gimp::Parasite;
sub is_type($$)		{ $_[0]->[0] eq $_[1] }
sub is_persistent($)	{ $_[0]->[1] & &Gimp::PARASITE_PERSISTENT }
sub is_error($)		{ !defined $_[0]->[0] }
sub has_flag($$)	{ $_[0]->[1] & $_[1] }
sub copy($)		{ [@{$_[0]}] }
sub name($)		{ $_[0]->[0] }
sub flags($)		{ $_[0]->[1] }
sub data($)		{ $_[0]->[2] }
sub compare($$)		{ $_[0]->[0] eq $_[1]->[0] and
			  $_[0]->[1] eq $_[1]->[1] and
			  $_[0]->[2] eq $_[1]->[2] }
sub new($$$$)		{ shift; [@_] }
use overload '""' => sub { ref($_[0])."->new([@{[ join ', ', @{$_[0]} ]}])"; };
sub id			{ goto &name; }
}

{
package Gimp::Base;
use overload '""' => sub { ref($_[0]).'->existing('.${$_[0]}.')'; };
sub existing($$) {
  my $id = $_[1];
  my $self = bless \$id, $_[0];
  Gimp::croak "$id not valid $_[0]" unless $self->is_valid;
  $self;
}
sub become($$) {
  warn "$$-".__PACKAGE__."::become(@_)" if $Gimp::verbose >= 2;
  my ($self, $class) = @_;
  my $old_class = ref $self;
  bless $self, $class;
  unless ($self->is_valid) {
    warn "$$-$self->is_valid false" if $Gimp::verbose >= 2;
    bless $self, $old_class;
    Gimp::croak "$_[0] not valid $class"
  }
  $self;
}
sub id { ${+shift} }
}

sub Gimp::Channel::is_valid { shift->is_channel }
sub Gimp::Drawable::is_valid { shift->is_drawable }
sub Gimp::Layer::is_valid { shift->is_layer }
sub Gimp::Selection::is_valid { shift->is_selection }
sub Gimp::Vectors::is_valid { shift->is_vectors }

1;
__END__
=head1 NAME

Gimp - Write GIMP extensions/plug-ins/load- and save-handlers in Perl

=head1 SYNOPSIS

  use Gimp;
  use Gimp::Fu;		# easy scripting environment

  podregister {
    # your code
    my $image = new Gimp::Image (600, 300, RGB);
    my $bg = $image->layer_new(
      600,300,RGB_IMAGE,"Background",100,LAYER_MODE_NORMAL_LEGACY
    );
    $image->insert_layer($bg, 1, 0);
    $image->edit_fill($bg, FILL_FOREGROUND);
    eval { Gimp::Display->new($image); };
    $image;
  };

  exit main;
  __END__
  =head1 NAME

  example_function - Short description of the function

  =head1 SYNOPSIS

  <Image>/File/Create/Patterns/Example...

  =head1 DESCRIPTION

  Longer description of the function...

=head1 DESCRIPTION

Gimp-Perl is a module for writing plug-ins, extensions, standalone
scripts, and file-handlers for the GNU Image Manipulation Program (GIMP).
It can be used to automate repetitive tasks, achieve a precision hard
to get through manual use of GIMP, interface to a web server, or other
tasks that involve GIMP.

It is developed on Linux, and should work with similar OSes.
This is a release of Gimp-Perl for gimp-2.8. It is not compatible with
version 2.6 or below of GIMP.

To jump straight into how to write GIMP plugins, see L<Gimp::Fu>:
it is recommended for scripts not requiring custom interfaces
or specialized execution. If you B<do> need a custom interface, see
C<examples/example-no-fu> - although L<Gimp::Fu> does also offer custom
widgets, see the same script using Gimp::Fu in C<examples/fade-alpha>.
Lots of other examples are in the C<examples/> directory of your gimp-perl
source tree, some of which will be installed in your plug-ins directory
if you are running from a package.

Using the C<Help/Procedure Browser> is a good way to learn GIMP's
Procedural Database (PDB). For referencing functions you already know of,
the included script L<gimpdoc> is useful. B<Be warned Gimp-Perl does
not allow use of deprecated GIMP procedures>. You'll thank me in time.

Some highlights:

=over 4

=item *

Access to GIMP's Procedural Database (PDB) for manipulation of
most objects.

=item *

Program with either a fully object-oriented syntax, or a (deprecated)
plain PDB (scheme-like) interface.

=item *

Scripts that use Gimp::Fu can be accessed seamlessly either from
GIMP's menus, other scripting interfaces like Script-Fu, or from the
command line (execute the plugin with the C<--help> flag for more
information).

In the latter case, Gimp::Fu can either connect to a GIMP already running,
or start up its own.

=item *

Access the pixel-data functions using L<PDL> (see L<Gimp::PixelRgn>)
giving the same level of control as a C plug-in, with a data language
wrapper.

=item *

Over 50 example scripts to give you a good starting point, or use out
of the box.

=back

=head1 IMPORT TAGS

Place these in your C<use Gimp qw(...)> command to have added features
available to your plug-in.

=head2 :consts

All constants found by querying GIMP (BG_IMAGE_FILL, RUN_NONINTERACTIVE,
LAYER_MODE_NORMAL_LEGACY, PDB_INT32 etc.).

=head2 :param

Import constants for plugin parameter types (PDB_INT32, PDB_STRING
etc.) only.

=head2 net_init=I<options>

This is how to use Gimp-Perl in "net mode". Previous versions of this
package required a call to Gimp::init. This is no longer necessary. The
technical reason for this change is that when C<Gimp.pm> loads, it must
connect to GIMP to load its constants, like C<PDB_INT32>.

Possible options include C<spawn/gui> or C<unix/path/to/socket>. See
L<Gimp::Net/ENVIRONMENT> for other possibilities. If this is not
specified, C<Gimp> will try various options, falling back to C<spawn>
which starts a new GIMP instance.

It is important that C<Gimp> be able to connect to an instance of GIMP
one way or another: otherwise, it will not be able to load the various
constants on which modules rely. The connection is made when
C<Gimp::import> is called, after C<Gimp> has been compiled - so don't
put C<use Gimp ();>

=head2 spawn_options=I<options>

Set default spawn options to I<options>, see L<Gimp::Net>.

=head2 :DEFAULT

The default set: C<':consts', 'N_', '__'>. (C<'__'> is used for i18n
purposes).

=head2 ''

Over-ride (don't import) the defaults.

=head2 :auto (DEPRECATED)

Import constants as above, as well as all libgimp and PDB functions
automagically into the caller's namespace.  This will overwrite your
AUTOLOAD function, if you have one. The AUTOLOAD function that gets
installed can only be used with PDB functions whose first argument is
a reference (including objects):

 use Gimp qw(:auto);
 Gimp->displays_flush; # fine
 my $name = $layer->get_name; # also fine
 gimp_quit(0); # will lose its parameter, due to Perl's OO implementation!
 Gimp->quit(0); # works correctly
 gimp_image_undo_disable($image); # as does this, by a coincidence

This tag is deprecated, and you will be far better off using Gimp-Perl
solely in OO mode.

=head2 :pollute (DEPRECATED)

In previous version of C<gimp-perl>, you could refer to GIMP classes
as either e.g. Gimp::Image, B<and> as Image. Now in order to not pollute
the namespace, the second option will be available only when this option
is specified.

=head1 ARCHITECTURE

There are two modes of operation: the perl is called by GIMP (as a
plugin/filter) ("B<plugin mode>"), or GIMP is called by perl (which uses the
Gimp::Net functionality) - either connecting to an existing GIMP process
("B<net mode>"), or starting its own one ("B<batch mode>").

=head2 Plugin

There are four "entry points" into GIMP plugins: B<init>, B<query>,
B<run>, and B<quit>. Gimp-Perl provides hooks for the last 3; the first
is implicitly done as the script executes, then either query or run,
then quit on exit.

The perl script is written as a plug-in, probably using C<Gimp::Fu>.
GIMP, on start-up, runs all the plug-ins in its plugins directory at
startup (including all the perl scripts) in "query" mode.

Any plugin will register itself as a GIMP "procedure" in the PDB, during
its run in "query" mode.

When such a procedure is called, either from the menu system or a
scripting interface, the plugin will be run in "run" mode, and GIMP will
supply it with the appropriate arguments.

=head2 From outside GIMP

The script will use C<Gimp> as above, and use GIMP functions as it
wishes. If you are using GIMP interactively, you need to run the Perl
Server (under "Filters/Perl") to allow your script to connect. Otherwise,
the script will start its own GIMP, in "batch mode".  Either way,
your script, when it uses GIMP procedures (and Gimp-Perl functions),
will actually be communicating with the Perl server running under GIMP.

The architecture may be visualised like this:

 perlscript <-> Gimp::Net <-> Perl-Server <-> Gimp::Lib <-> GIMP

This has certain consequences; native GIMP objects like images and layers
obviously persist between Perl method calls, but C<libgimp> entities such
as C<GimpDrawable>, with the perl interface L<Gimp::PixelRgn>, require
special handling. Currently they do not work when used over C<Gimp::Net>.

=head1 OUTLINE OF A GIMP PLUG-IN

All plug-ins (running in "plugin mode") I<must> finish with a call to
C<Gimp::main>.

The return code should be immediately handed out to exit:

 exit Gimp::main;

It used to be the case that before the call to C<Gimp::main>, I<no>
other PDB function could be called. This is no longer the case (see
L</"net_init=I<options>">), but there is no point in doing so outside of a
"run" hook (unless you have the privilege and joy of writing test modules
for Gimp-Perl!).

In a C<Gimp::Fu>-script, it will actually call C<Gimp::Fu::main> instead
of C<Gimp::main>:

 exit main; # Gimp::Fu::main is exported by default when using Gimp::Fu

This is similar to Gtk, Tk or similar modules, where you have to call the
main eventloop.

Although you call C<exit> with the result of C<main>, the main function
might not actually return. This depends on both the version of GIMP and
the version of the Gimp-Perl module that is in use.  Do not depend on
C<main> to return at all, but still call C<exit> immediately.

=head2 CALLBACKS

The C<Gimp> module provides routines to be optionally filled in by a
plug-in writer.  This does not apply if using C<Gimp::Fu>, as these are
done automatically. These are specifically how your program can fit into
the model of query, run and quit hooks.

The additional C<on_proc> is how to supply code that will be run every
time a GIMP PDB call is made. This is mainly useful for updating the
progress bar on a plugin.

=head3 Gimp::on_query

Do any activities that must be performed at GIMP startup, when the
plugin is queried.  Should typically have at least one call to
C<Gimp-E<gt>install_procedure>.

=head3 Gimp::on_net

Run when the plugin is executed from the command line, either in "net
mode" via the Perl-Server, or "batch mode".

=head3 Gimp::on_lib

Run only when called from within GIMP, i.e. in "plugin mode".

=head3 Gimp::on_run

Run when anything calls it (network or lib).

=head3 Gimp::on_quit

Run when plugin terminates - allows a plugin (or extension, see below)
to clean up after itself before it actually exits.

=head3 Gimp::on_proc

Run each time a PDB call is made. Currently only operates in "lib mode".

=head1 OUTLINE OF A GIMP EXTENSION

A GIMP extension is a special type of plugin. Once started, it stays
running all the time. Typically during its run-initialisation (not on
query) it will install temporary procedures. A module, L<Gimp::Extension>,
has been provided to make it easy to write extensions.

If it has no parameters, then rather than being run when called, either
from a menu or a scripting interface, it is run at GIMP startup.

An extension can receive and act on messages from GIMP, unlike a plugin,
which can only initiate requests and get responses. This does mean the
extension needs to fit in with GIMP's event loop (the L<Glib> event loop
in fact - use this by using L<Gtk2>). This is easy. In its C<run> hook,
the extension simply needs to run C<Gimp-E<gt>extension_ack> after it
has initialised itself (including installing any temporary
procedures). Then, if it wants to just respond to GIMP events:

  # to deal only with GIMP events:
  Gimp->extension_ack;
  Gimp->extension_process(0) while 1;

or also other event sources (including a GUI, or L<Glib::IO>):

  # to deal with other events:
  Gimp::gtk_init;
  Gimp->extension_ack; # GIMP locks until this is done
  Gimp->extension_enable; # adds a Glib handler for GIMP messages
  my $tcp = IO::Socket::INET->new(
    Type => SOCK_STREAM, LocalPort => $port, Listen => 5, ReuseAddr => 1,
    ($host ? (LocalAddr => $host) : ()),
  ) or die __"unable to create listening tcp socket: $!\n";
  Glib::IO->add_watch(fileno($tcp), 'in', sub {
    warn "$$-setup_listen_tcp WATCHER(@_)" if $Gimp::verbose;
    my ($fd, $condition, $fh) = @_;
    my $h = $fh->accept or die __"unable to accept tcp connection: $!\n";
    my ($port,$host) = ($h->peerport, $h->peerhost);
    new_connection($h);
    slog __"accepted tcp connection from $host:$port";
    &Glib::SOURCE_CONTINUE;
  }, $tcp);
  Gtk2->main; # won't return if GIMP quits, but
	      # GIMP will call your quit callback

A working, albeit trivial, example is provided in
C<examples/example-extension>. A summarised example:

  use Gimp;
  Gimp::register_callback extension_gp_test => sub {
    # do some relevant initialisation here
    Gimp->install_temp_proc(
      "perl_fu_temp_demo", "help", "blurb", "id", "id", "2014-04-11",
      "<Toolbox>/Xtns/Perl/Test/Temp Proc demo", undef,
      &Gimp::TEMPORARY,
      [ [ &Gimp::PDB_INT32, 'run_mode', 'Run-mode', 0 ], ],
      [],
    );
    Gimp->extension_ack;
    Gimp->extension_process(0) while 1;
  };
  Gimp::register_callback perl_fu_temp_demo => sub {
    my ($run_mode) = @_;
    # here could bring up UI if $run_mode == RUN_INTERACTIVE
  };
  Gimp::on_query {
     Gimp->install_procedure(
	"extension_gp_test", "help", "blurb", "id", "id", "2014-04-11",
	undef, undef,
	&Gimp::EXTENSION,
	[], [],
     );
  };
  exit Gimp::main;

A more substantial, working, example can be seen in the Perl Server
extension that enables "net mode": C<examples/Perl-Server>.

=head1 AVAILABLE GIMP FUNCTIONS

There are two different flavours of GIMP functions: those from
the Procedural Database (the B<PDB>), and functions from B<libgimp>
(the C-language interface library).

You can get a listing and description of every PDB function by starting
GIMP's C<Help/Procedure Browser> extension. Perl requires you to change
"-" (dashes) to "_" (underscores).

=head1 OBJECT-ORIENTED SYNTAX

Gimp-Perl uses some tricks to map the procedural PDB functions onto full
classes, with methods. These effectively implement object-oriented C,
not coincidentally in the style of Glib Objects. GIMP plans to move to
fully supporting Glib Objects, which may mean some (or no) changes to
the Gimp-Perl programming interface. The OO interface may well become
stricter than the current quite thin mapping. This is why the C<:auto>
method of accessing GIMP functions is deprecated.

Therefore, the guidance is that if you can do it as an object method, do
- and use the shortest method name that works; no C<gimp_>, no
C<gimp_layer_>, etc. The key indication is whether the first argument
is an object of the classes given below, and the GIMP function call:
C<gimp_image_*> is always either an image object method, or a class
method. If the first two arguments are an image and a drawable, call the
method on the drawable, with the exception of C<gimp_image_insert_layer>,
which we can tell from the prefix is an image method.

If you can't, use a deeper class than just C<Gimp>: C<Gimp::Context>, etc.
Otherwise, you have to use C<Gimp-E<gt>>, and that's fine.

=head2 AVAILABLE CLASSES

Classes for which objects are created:

  Gimp::Base # purely virtual
    +-Gimp::Color
    +-Gimp::Image
    +-Gimp::Selection
    +-Gimp::Display
    +-Gimp::Parasite
    +-Gimp::Item
        +-Gimp::Vectors
        +-Gimp::Drawable
          +-Gimp::Layer
          +-Gimp::Channel

Classes for which non-PDB objects are created (see L<Gimp::PixelRgn>):

  Gimp::GimpDrawable
  Gimp::PixelRgn
  Gimp::Tile

Classes for which objects are not created:

  Gimp
  Gimp::Brush
  Gimp::Brushes
  Gimp::Context
  Gimp::Edit
  Gimp::Gradient
  Gimp::Gradients
  Gimp::Palette
  Gimp::Pattern
  Gimp::Patterns
  Gimp::Plugin
  Gimp::Progress

=head3 Gimp::Base

Methods:

=head4 $object->become($class)

Allows an object of one class to change its class to another, but with
the same ID. If a method call of C<is_valid> returns false, an exception
will be thrown. It is intended for use in plugins, e.g. where GIMP passes
a C<Gimp::Drawable>, but you need a C<Gimp::Layer>:

  my ($image, $drawable, $color) = @_;
  $drawable->become('Gimp::Layer'); # now can call layer methods on it

Returns C<$object>.

=head4 $class->existing($id)

Allows you to instantiate a Gimp-Perl object with the given C<$class>
and C<$id>. The same check as above is done, throwing an exception
if failed.

=head4 $object->id

Returns the underlying GIMP identifier, an integer.

=head4 $object->is_valid

Returns true if the object is a valid object of the relevant class.
Subclasses use appropriate GIMP functions: e.g. Gimp::Layer uses
C<gimp_item_is_layer>.

=head4 stringify

It also provides a "stringify" overload method, so debugging output can
be more readable.

=head3 Gimp::Parasite

Self-explanatory methods:

=head4 $parasite = Gimp::Parasite-E<gt>new($name, $flags, $data)

C<$name> and C<$data> are perl strings, C<flags> is the numerical flag value.

=head4 $parasite-E<gt>name

=head4 $parasite-E<gt>flags

=head4 $parasite-E<gt>data

=head4 $parasite-E<gt>has_flag($flag)

=head4 $parasite-E<gt>is_type($type)

=head4 $parasite-E<gt>is_persistent

=head4 $parasite-E<gt>is_error

=head4 $different_parasite = $parasite-E<gt>copy

=head4 $parasite-E<gt>compare($other_parasite)

=head2 SPECIAL METHODS

Some methods behave differently from how you'd expect, or methods uniquely
implemented in Perl (that is, not in the PDB). All of these must be
invoked using the method syntax (C<Gimp-E<gt>> or C<$object-E<gt>>).

=head3 Gimp->install_procedure

Takes as parameters C<(name, blurb, help, author, copyright, date,
menu_path, image_types, type, params[, return_vals])>.

Mostly the same as gimp_install_procedure from the C library. The
parameters and return values for the functions are each specified as an
array ref containing array-refs with three elements,
C<[PARAM_TYPE, "NAME", "DESCRIPTION"]>, e.g.:

  Gimp::on_query {
     Gimp->install_procedure(
	$Gimp::Net::PERLSERVERPROC, "Gimp-Perl scripts net server",
	"Allow scripting GIMP with Perl providing Gimp::Net server",
	"Marc Lehmann <pcg\@goof.com>", "Marc Lehmann", "1999-12-02",
	N_"<Image>/Filters/Languages/_Perl/_Server", undef,
	$Gimp::Net::PERLSERVERTYPE,
	[
	 [&Gimp::PDB_INT32, "run_mode", "Interactive, [non-interactive]"],
	 [&Gimp::PDB_INT32, "flags", "internal flags (must be 0)"],
	 [&Gimp::PDB_INT32, "extra", "multi-purpose"],
	 [&Gimp::PDB_INT32, "verbose", "Gimp verbose var"],
	],
	[],
     );
  };

This will remove the full menu path (up to the last C</>) and call
C<gimp_plugin_menu_register> with it behind the scenes.

=head3 Gimp::Progress->init(message,[display])

=head3 Gimp::Progress->update(percentage)

Initializes or updates a progress bar. In networked modules these are a no-op.

=head3 Gimp::Image-E<gt>list

=head3 $image-E<gt>get_layers

=head3 $image-E<gt>get_channels

These functions return what you would expect: an array of images, layers or
channels. The reason why this is documented is that the usual way to return
C<PDB_INT32ARRAY>s would be to return a B<reference> to an B<array of
integers>, rather than blessed objects:

  perl -MGimp -e '@x = Gimp::Image->list; print "@x\n"'
  # returns: Gimp::Image->existing(7) Gimp::Image->existing(6)

=head3 $drawable-E<gt>bounds, $gdrawable-E<gt>bounds

Returns an array (x,y,w,h) containing the upper left corner and the
size of currently selected parts of the drawable, just as needed by
C<Gimp::PixelRgn-E<gt>new> and similar functions. Exist for objects of
both C<Gimp::Drawable> and C<Gimp::GimpDrawable>.

=head2 NORMAL METHODS

If you call a method, C<Gimp> tries to find a GIMP function by
prepending a number of prefixes until it finds a valid function:

 $image = Gimp->image_new(...); # calls gimp_image_new(...)
 $image = Gimp::Image->new(...); # calls gimp_image_new as well
 $image = new Gimp::Image(...); # the same in green
 Gimp::Palette->set_foreground(...); # calls gimp_palette_set_foreground(..)
 $image->histogram(...); # calls gimp_histogram($image,...), since
			 # gimp_image_histogram does not exist

Return values from functions are automatically blessed to their
corresponding classes, e.g.:

 $image = new Gimp::Image(...);	# $image is now blessed to Gimp::Image
 $image->height;		# calls gimp_image_height($image)
 $image->flatten;		# likewise gimp_flatten($image)

The object argument (C<$image> in the above examples) is prepended to the
argument list - this is how Perl does OO.

Another shortcut: many functions want a (redundant) image argument, like

 $image->shear ($layer, ...)

Since all you want is to shear the C<$layer>, not the C<$image>, this is
confusing as well. In cases like this, Gimp-Perl allows you to write:

 $layer->shear (...)

And automatically infers the additional IMAGE-type argument.

Because method call lookup also search the C<plug_in_>, C<perl_fu_> and
C<script_fu_> namespaces, any plugin can automatically become a method
for an image or drawable (see below).

As the (currently) last goodie, if the first argument is of type INT32, its
name is "run_mode" and there are no other ambiguities, you can omit it, i.e.
these five calls are equivalent:

 plug_in_gauss_rle(RUN_NONINTERACTIVE, $image, $layer, 8, 1, 1);
 plug_in_gauss_rle($image, $layer, 8, 1, 1);
 plug_in_gauss_rle($layer, 8, 1, 1);
 $layer->plug_in_gauss_rle(8, 1, 1);
 $layer->gauss_rle(8, 1, 1);

You can call all sorts of sensible and not-so-sensible functions,
so this feature can be abused:

 patterns_list Gimp::Image;	# will call gimp_patterns_list
 quit Gimp::Plugin;		# will quit the Gimp, not an Plugin.

there is no image involved here whatsoever...

The 'gimpdoc' script will also return OO variants when functions
are described.  For example:

  gimpdoc image_new

has a section:

  SOME SYNTAX ALTERNATIVES
       $image = Gimp->image_new (width,height,type)
       $image = new Gimp::Image (width,height,type)
       $image = image_new Gimp::Display (width,height,type)

=head1 SPECIAL FUNCTIONS

In this section, you can find descriptions of special functions, functions
that have unexpected calling conventions/semantics or are otherwise
interesting. All of these functions must either be imported explicitly
or called using a namespace override (C<Gimp::>), not as methods
(C<Gimp-E<gt>>).

=head2 Gimp::main()

Should be called immediately when perl is initialized. Arguments are not
supported. Initializations can later be done in the init function.

=head2 Gimp::gtk_init()

Initialize Gtk in a similar way GIMP itself did. This automatically
parses GIMP's gtkrc and sets a variety of default settings, including
visual, colormap, gamma, and shared memory.

=head2 Gimp::set_rgb_db(filespec)

Use the given rgb database instead of the default one. The format is
the same as the one used by the X11 Consortiums rgb database (you might
have a copy in /usr/lib/X11/rgb.txt). You can view the default database
with C<perldoc -m Gimp::ColorDB>, at the end of the file; the default
database is similar, but not identical to the X11 default C<rgb.txt>.

=head2 Gimp::initialized()

this function returns true whenever it is safe to call GIMP functions. This is
usually only the case after gimp_main has been called.

=head2 Gimp::register_callback(gimp_function_name, perl_function)

Using this function you can override the standard Gimp-Perl behaviour of
calling a perl subroutine of the same name as the GIMP function.

The first argument is the name of a registered gimp function that you want
to overwrite ('perl_fu_make_something'), and the second argument can be
either a name of the corresponding perl sub (C<'Elsewhere::make_something'>)
or a code reference (C<\&my_make>).

=head2 Gimp::canonicalize_colour

Take in a color specifier in a variety of different formats, and return
a valid GIMP color specifier (a C<GimpRGB>), consisting of 3 or 4 numbers
in the range between 0 and 1.0. Can also be called as
C</Gimp::canonicalize_color>.

For example:

 $color = canonicalize_colour ("#ff00bb"); # html format
 $color = canonicalize_colour ([255,255,34]); # RGB
 $color = canonicalize_colour ([255,255,34,255]); # RGBA
 $color = canonicalize_colour ([1.0,1.0,0.32]); # actual GimpRGB
 $color = canonicalize_colour ('red'); # uses the color database

Note that bounds checking is somewhat lax; this assumes relatively
good input.

=head2 gimp_tile_*, gimp_pixel_rgn_*, gimp_drawable_get

With these functions you can access the raw pixel data of drawables. They
are documented in L<Gimp::PixelRgn>.

=head2 server_eval(string)

This evaluates the given string in array context and returns the
results. It's similar to C<eval>, but with two important differences: the
evaluating always takes place on the server side/server machine (which
might be the same as the local one) and compilation/runtime errors are
reported as runtime errors (i.e. throwing an exception).

=head1 PROCEDURAL SYNTAX (DEPRECATED)

To call PDB functions or libgimp functions, you I<can>
(but shouldn't) treat them like normal procedural perl (this requires
the use of the C<:auto> import tag - see L</":auto (DEPRECATED)">):

 gimp_item_set_name($layer, 'bob'); # $layer is an object (i.e. ref) - works
 gimp_palette_set_foreground([20,5,7]); # works because of array ref
 gimp_palette_set_background("cornsilk"); # colour turned into array ref!

=head1 DEBUGGING AIDS

How to debug your scripts:

=over 4

=item $Gimp::verbose

If set to true, will make Gimp-Perl say what it's doing on STDERR.
If you want it to be set during loading C<Gimp.pm>, make sure to do so
in a prior C<BEGIN> block:

 BEGIN { $Gimp::verbose = 1; }
 use Gimp;

Currently three levels of verbosity are supported:

  0: silence
  1: some info - generally things done only once
  2: all the info

=item GLib debugging

GIMP makes use of GLib. Environment variables including
C<G_DEBUG>, and setting C<G_SLICE> to
C<always-malloc>, control some behaviour. See
L<https://developer.gnome.org/glib/unstable/glib-running.html>
for details. Additionally, the behaviour of C<malloc> can
be controlled with other environment variables as shown at
L<http://man7.org/linux/man-pages/man3/mallopt.3.html>, especially
setting C<MALLOC_CHECK_> (note trailing underscore) to 3.

=back

=head1 SUPPORTED GIMP DATA TYPES

GIMP supports different data types like colors, regions, strings. In
C, these are represented as (C<GIMP_PDB_> omitted for brevity - in
Gimp-Perl, they are constants starting C<PDB_>):

=over 4

=item INT32, INT16, INT8, FLOAT, STRING

normal Perl scalars. Anything except STRING will be mapped
to a Perl-number.

=item INT32ARRAY, INT16ARRAY, INT8ARRAY, FLOATARRAY, STRINGARRAY, COLORARRAY

array refs containing scalars of the same type, i.e. [1, 2, 3, 4]. Gimp-Perl
implicitly swallows or generates a preceeding integer argument because the
preceding argument usually (this is a de-facto standard) contains the number
of elements.

=item COLOR

on input, either an array ref with 3 or 4 elements (i.e. [0.1,0.4,0.9]
or [233,40,40]), a X11-like string ("#rrggbb") or a colour name
("papayawhip") (see L</"Gimp::set_rgb_db(filespec)">).

=item DISPLAY, IMAGE, LAYER, CHANNEL, DRAWABLE, SELECTION, VECTORS, ITEM

these will be mapped to corresponding objects (IMAGE => Gimp::Image). In
verbose output you will see small integers (the image/layer/etc..-ID)

=item PARASITE

represented as a C<Gimp::Parasite> object (see above).

=item STATUS

Not yet supported, except implicitly - this is how exceptions (from
"die") get returned in "net mode".

=back

=head1 AUTHOR

Marc Lehmann <pcg@goof.com> (pre-2.0)

Seth Burgess <sjburge@gimp.org> (2.0+)

Kevin Cozens (2.2+)

Ed J (with oversight and guidance from Kevin Cozens) (2.3)

Ed J (2.3000_01+)

=head1 SEE ALSO

perl(1), gimp(1), L<Gimp::Fu>, L<Gimp::PixelRgn>, L<Gimp::UI>,
L<Gimp::Util>, L<Gimp::Data>, L<Gimp::Net>, and L<Gimp::Lib>.
