package Inline::Wrapper;
#
#   Inline::* module dynamic loader and useful wrapper routines
#
#   $Id: Wrapper.pm 14 2010-03-10 09:08:18Z infidel $
#
#   POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( carp croak );
use Data::Dumper;
use vars qw( $TRUE $FALSE $VERSION );
BEGIN { $INC{'Inline::Wrapper.pm'} ||= __FILE__ };  # recursive use check
use Inline::Wrapper::Module;                        # individual code modules

###
### VARS
###

$VERSION = '0.05';
*TRUE    = \1;
*FALSE   = \0;

my $DEFAULTS = {
    base_dir    => '.',                 # default search directory
    auto_reload => $FALSE,              # automatically reload module?
    language    => 'Lua',               # default language
};

my $LANGS = {
    Foo         => '.foo',              # built in to Inline's distro
    C           => '.c',
    Lua         => '.lua',
#    'C++'       => '.cpp',
#    Java        => '.java',
#    Python      => '.py',
#    Tcl         => '.tcl',
#    Ruby        => '.rb',
};

my $PARAMS = {
    base_dir    => sub { $_[0] },
    auto_reload => sub { $_[0] ? $TRUE : $FALSE },
    language    => sub {
                     defined( $_[0] ) and exists( $LANGS->{$_[0]} )
                         ? $_[0]
                         : ( carp sprintf( "Invalid language: %s; using %s",
                                           $_[0], $DEFAULTS->{language} )
                               and $DEFAULTS->{language} )
                   },
};

###
### CONSTRUCTOR
###

sub new
{
    my( $class, @args ) = @_;

    # Check parameters
    @args = %{ $args[0] } if( ref( $args[0] ) eq 'HASH' );
    croak "$class: \%args must be a hash; read the docs" if( @args & 1 );

    # Set up object
    my $self = {
        %$DEFAULTS,
#        modules     => {},
    };
    bless( $self, $class );

    # Initialize object instance
    @args = $self->_process_args( @args );
    $self->initialize( @args );

    return( $self );
}

sub initialize
{
    my( $self ) = @_;

    $self->{modules} = {};

    return;
}

###
### PUBLIC METHODS
###

# Load a code module named $modname from $base_dir with $lang_extension
sub load
{
    my( $self, $modname, @args ) = @_;

    # Check arguments
    croak "load() \$modname is a required param; read the docs"
        unless( $modname );
    @args = %{ $args[0] } if( ref( $args[0] ) eq 'HASH' );
    croak "load(): \%args must be a hash; read the docs"
        if( @args & 1 );
    my %args = @args;

    # Check for duplicate modules, return @function list if found
    # XXX: Possible bug; should probably issue reload if auto_reload
    #   ends up being set to true.
    if( my $temp_module = $self->_module( $modname ) )
    {
        my $temp_lang     = $args{language} || $self->language();
        my $temp_base_dir = $args{base_dir} || $self->base_dir();
        if( $temp_lang     eq $temp_module->language() &&
            $temp_base_dir eq $temp_module->base_dir() )
        {
            $temp_module->set_auto_reload( $args{auto_reload} )
                if( $args{auto_reload} );
            print "HONK!\n";
            return( $temp_module->_function_list() );   # RETURN
        }
    }

    # Create a new module object
    my $module = Inline::Wrapper::Module->new(
            module_name     => $modname,
            lang_ext        => $self->_lang_ext(),
            $self->_settings(),
            %args,
    );
    $self->_add_module( $modname, $module );

    # Actually attempt to load the inline module
    my @functions = $module->_load();

    return( @functions );
}

# Completely unload a loaded $modname, rendering its functions uncallable
sub unload
{
    my( $self, $modname ) = @_;

    carp "$modname not loaded" and return
        unless( ref( $self->_module( $modname ) ) );

    return( $self->_del_module( $modname ) && $modname );
}

# Run a $modname::$funcname function, passing it @args
sub run
{
    my( $self, $modname, $funcname, @args ) = @_;

    my $module    = $self->_module( $modname );
    my @retvals   = $module->_run( $funcname, @args );

    return( @retvals );
}

# Return the list of already-loaded modules
sub modules
{
    my( $self ) = @_;

    return( $self->_module_names() );
}

# Return the list of functions loaded from $modname
sub functions
{
    my( $self, $modname ) = @_;

    my $module = $self->_module( $modname );
    carp "Module '$modname' not loaded"
        and return()
            unless( ref( $module ) );

    return( $module->_function_list() );
}

###
### PRIVATE METHODS
###

sub _process_args
{
    my( $self, @args ) = @_;
    croak "_process_args() requires an even number of params" if( @args & 1 );
    my %args = @args;

    for( keys %args )
    {
        next unless( exists( $PARAMS->{lc $_} ) );      # not for us, pass on
        $self->{lc $_} = $PARAMS->{lc $_}->( $args{$_} );
        delete( $args{$_} );
    }

    return( %args );
}

sub _module_names
{
    my( $self ) = @_;

    return( keys( %{ $self->{modules} } ) );
}

sub _settings
{
    my( $self ) = @_;

    my %defaults = map { $_ => $self->{$_} } keys( %$DEFAULTS );

    return( %defaults );
}

###
### ACCESSORS
###

sub base_dir
{
    my( $self ) = @_;

    return( $self->{base_dir} );
}

sub set_base_dir
{
    my( $self, $base_dir ) = @_;

    # Validate
    $base_dir = $PARAMS->{base_dir}->( $base_dir );

    return( defined( $base_dir )
              ? $self->{base_dir} = $base_dir
              : $self->{base_dir} );
}

sub language
{
    my( $self ) = @_;

    return( $self->{language} );
}

sub set_language
{
    my( $self, $language ) = @_;

    # Validate
    $language = $PARAMS->{language}->( $language );

    return( defined( $language )
              ? $self->{language} = $language
              : $self->{language} );
}

sub add_language
{
    my( $self, $language, $lang_ext ) = @_;

    carp "add_language(): Language not set; read the docs"
        and return
            unless( $language );
    carp "add_language(): Language extension not set; read the docs"
        and return
            unless( $lang_ext );

    return( ( $LANGS->{$language} = $lang_ext ) ? $language : undef );
}

sub auto_reload
{
    my( $self ) = @_;

    return( $self->{auto_reload} );
}

sub set_auto_reload
{
    my( $self, $auto_reload ) = @_;

    # Validate
    $auto_reload = $PARAMS->{auto_reload}->( $auto_reload );

    return( defined( $auto_reload )
              ? $self->{auto_reload} = $auto_reload
              : $self->{auto_reload} );
}

### PRIVATE ACCESSORS

sub _module
{
    my( $self, $modname ) = @_;

    return( $self->{modules}->{$modname} );
}

sub _add_module
{
    my( $self, $modname, $module ) = @_;

    return( $self->{modules}->{$modname} = $module );
}

sub _del_module
{
    my( $self, $modname ) = @_;

    # Namespace is deleted by $module->DESTROY()
    return( delete( $self->{modules}->{$modname} ) );
}

###
### PRIVATE UTILITY ROUTINES
###

sub _lang_ext
{
    my( $self, $language ) = @_;

    $language ||= $self->{language};

    return( $LANGS->{$language} );
}

1;

__END__

=pod

=head1 NAME

Inline::Wrapper - Convenient module wrapper/loader routines for Inline.pm

=head1 SYNOPSIS

sample.pl:

 use Inline::Wrapper;

 my $inline = Inline::Wrapper->new(
    language    => 'C',
    base_dir    => '.',
 );

 my @symbols = $inline->load( 'answer' );

 my @retvals = $inline->run( 'answer', 'the_answer', 3, 56 );

 print "The answer is: ", $retvals[0], "\n";

 exit(0);

answer.c:

 int the_answer( int arg1, int arg2 ) {
     return ( arg1 * arg2 ) >> 2;
 }

=head1 DESCRIPTION

B<Inline::Wrapper> provides wrapper routines around L<Inline> to make
embedding functions from another language into a Perl application much
more convenient.

Instead of having to include the external code in a Perl source file after
the __END__ directive, B<Inline::Wrapper> allows you to have separate,
individually-configurable module repositories to more easily manage all
of your external application code.

=head1 FEATURES

B<Inline::Wrapper> provides the following features:

=over 4

=item * Support for all languages supported by L<Inline>.

=item * A single, unified interface for loading and running module functions.

=item * Loading of files containing pure source code, only in their
respective languages, so you can isolate maintenance and management of these
modules.

=item * Individually-configurable module directories.

=item * Automatic, run-time module reloading upon file modification time
detection.

=item * No more namespace pollution.  All module symbols are loaded into
their own individual, private namespaces, so they won't collide with your
code or each other.

=back

=head1 CONSTRUCTOR

=head2 new()

    my $wrapper = Inline::Wrapper->new(
          language        => 'C',
          base_dir        => 'src/code/C',
          auto_reload     => 1,
    );

Create a new B<Inline::Wrapper> object, with the appropriate attributes (if
specified).

B<ARGUMENTS:>

All arguments are of the hash form  Var => Value.  L</new()> will complain
and croak if they do not follow this form.

The arguments to L</new()> become the defaults used by L</load()>.  You can
individually configure loaded modules using L</load()>, as well.

=over 4

=item I<language>           [ default: B<'Lua'> ]

Optional.  Set to the default language for which you wish to load modules,
if not explicitly specified via L</load()>.

B<NOTE>: It defaults to Lua because that is what I wrote this module for.
Just pass in the argument if you don't like that.

B<ALSO NOTE:> Currently only a couple of "known" languages are hard-coded
into this module.  If you wish to use others, don't pass this argument, and
use the L</add_language()> method after the object has been instantiated.

=item I<auto_reload>        [ default: B<FALSE> ]

Optional.  Set to a TRUE value to default to automatically checking if
modules have been changed since the last L</load()>, and reload them if
necessary.

=item I<base_dir>           [ default: B<'.'> ]

Optional.  Set to the default base directory from which you wish to load all
modules.

=back

B<RETURNS>: blessed $object, or undef on failure.

=head1 METHODS

=head2 initialize()

    $obj->initialize();

Initialize arguments.  If you are subclassing, overload this, not L</new()>.

Generally only called from within L</new()>.

=head2 load()

    my @functions = $obj->load( $modname, %arguments );

The workhorse.  Loads the actual module referred to by I<$modname>,
imports its symbols into a private namespace, and makes them available to
call via L</run()>.

B<ARGUMENTS:>

I<$modname> is REQUIRED.  It corresponds to the base filename, without
extension, loaded from the I<base_dir>.  See the
L</Details of steps taken by load()> section, Step 3, for clarification
of how pathname resolution is done.  I<$modname> is also how you will refer
to this particular module from your program, so keep track of it.

This method accepts all of the same arguments as L</new()>.  Thus, you can
set the defaults via L</new()>, yet still individually configure module
components differently from the defaults, if desired.

Returns a list of @functions made available by loading I<$modname>, or warns
and returns an empty list if unsuccessful.

=head3 Details of steps taken by load()

Since this is the real guts of this module, here are the exact steps taken
when loading the module, doing pathname resolution, etc.

=over 4

=item 1. Checks to see if the specified module has already been loaded, and
if so, returns the list of functions loaded and available in that module
immediately.

=item 2. Creates a new L<Inline::Wrapper::Module> container object with any
supplied %arguments, or the defaults you specified with L</new()>.

=item 3. Constructs a path to the specified $modname, roughly as follows:

    join( $PATH_SEP, $base_dir , $modname . $lang_ext );

=over 4

=item I<$base_dir> is taken either from the default created with
L</new()>, or the explicitly supplied I<base_dir> argument to L</load()>.

=item I<$path_separator> is just the appropriate path separator for your OS.

=item I<$modname> is your supplied module name.  Note that this means that you
can supply your own subdirectories, as well; i.e. I<'foo'> is just as valid as
I<'foo/bar/baz'>.

=item I<$lang_ext> is taken from a data structure that defaults to
common filename extensions on a per-language basis.  Any of these can
be overridden via the L</add_language()> method.

=back

=item 4. Attempts to open the file at the path constructed above, and if
successful, slurps in the entire source file.

=item 5. Attempts to bind() (compile and set symbols) it with the
L<Inline>->bind() method into a private namespace.

=item 6. If step 5 was successful, set the load time, and return the list
of loaded, available functions provided by the module.

=item 7. If step 5 failed, warn and return an empty list.

=back

=head2 unload()

    $obj->unload( $modname );

Completely unload the module identified by I<$modname>, and render its
functions uncallable.

This will actually go destroy the L<Inline::Wrapper::Module> object, as
well as the code module's corresponding private namespace.

Returns I<$modname> (TRUE) upon success, carps and returns undef on failure.

=head2 run()

    my @retvals = $obj->run( $modname, $function, @arguments );

Run the named I<$function> that you loaded from I<$modname>, with the
specified I<@arguments> (if any).

B<NOTE:> If the I<auto_reload> option is TRUE, run() will also attempt to
reload the source script from disk before running the function, if the
ctime of the file has changed since the last run.

Assuming a successful compilation (you are checking for errors, right?),
this will execute the function provided by the loaded module.  Call syntax
and everything is up to the function provided.  This simply executes the sub
that L<Inline> loaded as-is, but in its own private namespace to keep your
app clean.

Returns I<@retvals>, consisting of the actual return values provided by
the module function itself.  Whatever the function returns, that's what
you get.

=head2 modules()

    my @modules = $obj->modules();

Returns a list of loaded module names, or the empty list if no modules
have been (successfully) loaded.

=head2 functions()

    my @functions = $obj->functions( $modname );

Returns a list of loaded I<@functions>, which were made available by loading
I<$modname>.

=head1 ACCESSORS

Various accessors that allow you to inspect or change the default settings
after creating the object.

=head2 base_dir()

    my $base_dir = $obj->base_dir();

Returns the default I<base_dir> attribute from the object.

=head2 set_base_dir()

    $obj->set_base_dir( '/some/path' );

Sets the default I<base_dir> attribute of the object, and returns whatever
it ended up being set to.

B<NOTE:> Only affects modules loaded I<after> this setting was made.

=head2 auto_reload()

    my $bool = $obj->auto_reload();

Returns a $boolean as to whether or not the default I<auto_reload> setting
is enabled for new modules.

=head2 set_auto_reload()

    $obj->set_auto_reload( 1 );

Sets the default I<auto_reload> attribute of the object, and returns
whatever it ended up being set to.

B<NOTE:> Only affects modules loaded I<after> this setting was made.

=head2 language()

    my $lang = $obj->language();

Returns the default I<language> attribute of the object.

=head2 set_language()

    $obj->set_language( 'C' );

Sets the default I<language> attribute of the object, and returns whatever
it ended up being set to.

B<NOTE:> Only affects modules loaded I<after> this setting was made.

B<ALSO NOTE:> This checks for "valid" languages via a pretty naive method.
Currently only a couple are hard-coded.  However, you can add your own
languages via the L</add_language()> method.

=head2 add_language()

    $obj->add_language( 'Lojban' => '.xkcd' );

Adds a language to the "known languages" table, allowing you to later use
L</set_language()>.

This can also be used to set a new file extension for an existing language.

REQUIRES a I<$language> name (e.g. 'Python') and a filename I<$extension>
(e.g. '.py'), which will be used in pathname resolution, as described under
L</load()>.

Returns TRUE if successful, carps and returns FALSE otherwise.

=head1 SEE ALSO

L<Inline::Wrapper::Module>

The L<Inline> documentation.

The L<Inline-FAQ> list.

The examples/ directory of this module's distribution.

=head1 ACKNOWLEDGEMENTS

Thank you, kennethk and ikegami for your assistance on perlmonks.

L<http://perlmonks.org/index.pl?node_id=732598>

=head1 AUTHOR

Please kindly read through this documentation and the B<examples/>
thoroughly, before emailing me with questions.  Your answer is likely
in here.

Also, please make sure that your issue is actually with B<Inline::Wrapper>
and not with L<Inline> itself.

Jason McManus (INFIDEL) -- C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

=cut

### Thank you, drive through. ###
