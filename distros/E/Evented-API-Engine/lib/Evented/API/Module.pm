# Copyright (c) 2017, Mitchell Cooper
# Module represents an API module and provides an interface for managing one.
package Evented::API::Module;

use warnings;
use strict;
use 5.010;

use Evented::Object;
use parent 'Evented::Object';

use Scalar::Util qw(blessed weaken);
use List::Util qw(first);

our $VERSION = '4.11';

=head1 NAME

B<Evented::API::Module> - represents a module for use with
L<Evented::API::Engine>.

=head1 SYNOPSIS

    # Module metadata
    #
    # @name:        'My::Module'
    # @package:     'M::My::Module'
    # @description:
    #
    # @depends.modules+ 'Some::Other'
    # @depends.modules+ 'Another::Yet'
    #
    # @author.name:     'Mitchell Cooper'
    # @author.website:  'https://github.com/cooper'
    #
    package M::My::Module;
    
    use warnings;
    use strict;
    use 5.010;
    
    # Auto-exported variables
    our ($api, $mod);
    
    # Default initializer
    sub init {
        say 'Loading ', $mod->name;
        
        # indicates load success
        return 1;
    }
    
    # Default deinitializer
    sub void {
        say 'Bye!';
        
        # indicates unload success
        return 1;
    }
    
    # Package must return module object
    $mod;

=head1 DESCRIPTION

=head2 Module directory structure

Modules must be placed within one of the search directories specified in the
L<Evented:API::Engine> C<mod_inc> consturctor option or the C<dirs> option
of C<< ->load_module >> and similar Engine methods.

A module in its simplest form is a directory with the C<.module> extension
and a single C<.pm> file of the same name. Double-colon namespace separators
are condensed to directories, as with normal Perl packages. For instance, a
module called My::Backend's main package file could be located at either of the
following:

    $SEARCH_DIR/My/Backend.module/Backend.pm
    $SEARCH_DIR/My/Backend/Backend.module/Backend.pm

The directory with the C<.module> extension is called the module directory. In
addition to the Perl package file, it can house other data associated with the
module, such as JSON-encoded metadata, submodules, and documentation.

    $MODULE_DIR/Backend.pm              # package file
    $MODULE_DIR/Backend.json            # metadata file
    $MODULE_DIR/Backend.md              # documentation
    $MODULE_DIR/More.module/More.pm     # submodule package
    $MODULE_DIR/More.module/More.json   # submodule metadata
    
=head2 Module metadata

Module metadata is extracted from comments in primary package file.

Metadata is written to a C<.json> file within the module directory
(when developer mode is enabled). These metadata files should be included in
distributions, as they contains version and author information.

B<Syntax> for metadata comments is as follows:

    # @normal:      "A normal option with a Perl-encoded value"
    # @boolean      # a boolean option!
    # @list+        'A value to add to a list'
    # @list+        'Another value to add to the list'
    
B<Supported options>

    # @name:                'Some::Module'              # module name
    # @package:             'M::Some::Module'           # main package
    # @package+             'M::Some::Module::Blah'     # additional packages
    # @version:             '1.01'                      # module version
    # @depends.modules+     'Some::Mod::Dependency'     # module dependencies
    # @depends.modules+     'A::B', 'C::D'              # additional dependencies
    # @depends.bases+       'Some::Base::Dependency'    # base dependencies
    # @author.name:         'John Doe'                  # author name
    # @author.website:      'http://john.example.com'   # author URL
    # @no_bless                                         # don't bless
    # @preserve_sym                                     # don't erase symbols
    
These, I feel, require additional explanation:

=over

=item *

B<@version> - this obviously is a numerical module version. I'm mentioning it
here to tell you that you probably shouldn't bother using it, as the API Engine
offers automatic versioning (with developer mode enabled) if you simply omit
this option.

=item *

B<@depends.bases> - like C<@depends.modules>, except the C<Base::> prefix is
added. bases are modules which don't really offer any functionality on their
own but provide APIs for other modules to use.

=item *

B<@no_bless> - if true, the module object will not be blessed to the module's
primary package (which is the default behavior). this might be useful if your
module contains names conflicting with API Engine or uses autoloading.

=item *

B<@preserve_sym> - if true, the packages associated with the module will not be
deleted from the symbol table upon unload. this is worse for memory, but it
may be necessary for the "guts" of your program, particularly those parts which
deal with the loading and unloading of modules themselves.

=back

=head1 METHODS

=cut

sub new {
    my ($class, %opts) = @_;
    my $mod = bless \%opts, $class;
    Evented::API::Events::add_events($mod);
    return $mod;
}

=head2 $mod->name

B<Returns> module full name.

=head2 $mod->package

B<Returns> module's primary Perl package name.

=head2 $mod->packages

B<Returns> all packages associate with module.

=head2 $mod->api

B<Returns> associated L<API Engine | Evented::API::Engine>.

=head2 $mod->parent

B<Returns> parent module, if this is a submodule.

=head2 $mod->submodules

B<Returns> list of loaded submodules objects.

=cut

sub name       { shift->{name}{full}            }   # full name
sub package    { shift->{package}[0]            }   # main package
sub packages   { @{ shift->{package} }          }   # all packages
sub api        { shift->{api}                   }
sub parent     { shift->{parent}                }
sub submodules { @{ shift->{submodules} || [] } }

=head2 $mod->Log($msg)

Used for logging associated with module. Use L<API Engine | Evented:API::Engine>
C<< ->Log() >> for messages not associated with a specific module.

B<Parameters>

=over

=item *

B<$msg> - text to log.

=back

=head2 $mod->Debug($msg)

Used for debug logging associated with module.
Use L<API Engine | Evented:API::Engine> C<< ->Debug() >> for messages not
associated with a specific module.

B<Parameters>

=over

=item *

B<$msg> - text to log.

=back

=cut

sub Log {
    my $mod = shift;
    $mod->api->Log($mod->name, "@_");
}

sub Debug {
    my $mod = shift;
    $mod->api->Debug($mod->name, "@_");
}

# compat
sub _log;
*_log = \&Log;

=head2 $mod->get_symbol($sym)

Fetches the value of a symbol in module's main package.

B<Parameters>

=over

=item *

B<$sym> - string symbol; such as C<@list>, C<%hash>, or C<$scalar>.

=back

B<Returns>

The data in its native type (NOT a reference), or the zero value for that type
if no symbol table entry exists.

=cut

sub get_symbol {
    my ($mod, $symbol) = @_;
    return Evented::Object::Hax::get_symbol($mod->package, $symbol);
}

sub _do_init {
    my $mod = shift;
    my $api = $mod->api;

    # fire module initialize.
    $api->Log($mod->name, 'Initializing');
    $api->{indent}++;
        my $init_fire = $mod->prepare('init')->fire('return_check');
    $api->{indent}--;

    # init was stopped. cancel the load.
    if (my $stopper = $init_fire->stopper) {
        $mod->Log('init stopped: '.$init_fire->stop);
        $mod->Log("Load FAILED: Initialization canceled by '$stopper'");

        $api->_abort_module_load($mod);

        # fire unload so that bases can undo whatever was done up
        # to the fail point of init.
        bless $mod, 'Evented::API::Module';
        $mod->fire('unload');

        return;
    }

    # init was successful
    return 1;
}

sub _do_void {
    my ($mod, $unloading_submodule) = @_;
    my $api = $mod->api;

    # fire module void.
    # consider: should this have return_check like init?
    $mod->Log('Voiding');
    my $void_fire = $mod->fire('void');

    # init was stopped. cancel the unload.
    my $stopper = $void_fire->stopper;
    if (!$unloading_submodule && $stopper) {
        $mod->Log("void stopped: ".$void_fire->stop);
        $mod->Log("Can't unload: canceled by '$stopper'");
        return;
    }

    # if this is a submodule, it isn't allowed to refuse to unload.
    elsif ($stopper) {
        $mod->Log(
            "Warning! This submodule has requested to remain ".
            'loaded, but submodules MUST be unloaded with their parent'
        );
    }

    # void was successful
    return 1;

}

##################
### SUBMODULES ###
##################

=head2 $mod->load_submodule($submod_name)

Loads a submodule.

This is generally used within the module initializer.

B<Parameters>

=over

=item *

B<$submod_name> - name of the submodule, without the parent module name prefix.
for instance if the full submodule name is C<My::Module::Sub>, this is simply
C<Sub>.

=back

B<Returns>

Submodule object on success, false otherwise.

=cut

sub load_submodule {
    my ($mod, $mod_name) = @_;
    $mod->Log("Loading submodule $mod_name");

    # call ->load_module with the search dir set to the
    # parent module's main directory.
    $mod->api->{indent}++;
        my $ret = $mod->api->load_module($mod_name, [ $mod->{dir} ], 1);
    $mod->api->{indent}--;

    # add weakly to submodules list. hold weak reference to parent module.
    if ($ret) {
        my $a = $mod->{submodules} ||= [];
        push @$a, $ret;
        weaken($a->[$#$a]);
        weaken($ret->{parent} = $mod);
    }

    return $ret;
}

=head2 $mod->unload_submodule($submod)

Unloads a submodule.

You do not have to call this in the parent module deinitializer. Only use this
method if you want to dynamically unload a submodule for some reason without
unloading the parent module.

B<Parameters>

=over

=item *

B<$submod> - submodule object or name, without the parent module name prefix.
for instance if the full submodule name is C<My::Module::Sub>, this is simply
C<Sub>.

=back

=cut

sub unload_submodule {
    my ($mod, $submod, $reloading) = @_;
    my $submod_name = $submod->name;
    $mod->Log("Unloading submodule $submod_name");

    # unload
    $mod->api->{indent}++;

        # ($mod, $unload_dependents, $force, $unloading_submodule, $reloading)
        #
        # do not force, as that might unload the parent
        # but do say we are unloading a submodule so it can be unloaded
        # independently (which usually wouldn't be allowed)
        #
        $mod->api->unload_module($submod, undef, undef, 1, $reloading);

    $mod->api->{indent}--;

    # remove from submodules
    if (my $submods = $mod->{submodules}) {
        @$submods = grep { $_ != $submod } @$submods;
    }
    delete $submod->{parent};

    return 1;
}

=head2 $mod->add_companion_submodule($mod_name, $submod_name)

Registers a submodule (provided by this module) as a companion of another
top-level module.

Companion submodules are submodules which are automatically loaded and unloaded
as needed in conjunction with other top-level modules.

This is generally called from within the parent module initializer.

B<Parameters>

=over

=item *

B<$mod_name> - name of another top-level module to register the submodule as
a companion.

=item *

B<$submod_name> - name of the submodule to register a companion, without the
parent module name prefix. for instance if the full submodule name is
C<My::Module::Sub>, this is simply C<Sub>.

=back

=cut

sub add_companion_submodule {
    my ($mod, $mod_name, $submod_name) = @_;
    $mod->api->_add_companion_submodule_wait($mod, $mod_name, $submod_name);
}

####################
### DATA STORAGE ###
####################

=head2 $mod->store($key, $value)

Stores a piece of data associated with module.

B<Parameters>

=over

=item *

B<$key> - name for fetching data later.

=item *

B<$value> - value to store.

=back

=cut

# store a piece of data specific to this module.
sub store {
    my ($mod, $key, $value) = @_;
    $mod->{store}{$key} = $value;
}

=head2 $mod->retrieve($key, $default_value)

Retrieves a piece of data associated with module.

B<Parameters>

=over

=item *

B<$key> - name associated with data to fetch.

=back

B<Returns>

Fetched data, undef if not found.

=cut

# fetch a piece of data specific to this module.
sub retrieve {
    my ($mod, $key, $default_value) = @_;
    return $mod->{store}{$key} //= $default_value;
}

=head2 $mod->list_store_add($key, $value)

Adds an entry to a list of data associated with module.

=over

=item *

B<$key> - name for fetching data later.

=item *

B<$value> - value to add.

=back

=cut

# adds the item to a list store.
# if the store doesn't exist, creates it.
sub list_store_add {
    my ($mod, $key, $value) = @_;
    push @{ $mod->{store}{$key} ||= [] }, $value;
}

=head2 $mod->list_store_remove_matches($key, $code, $max)

Removes entries satisfying a code from a list of data associated with module.

B<Parameters>

=over

=item *

B<$key> - name of list.

=item *

B<$code> - code reference passed each entry which should return true for
matches.

=item *

B<$max> - I<optional>, maximum number of entries to remove.

=back

B<Returns>

Number of items removed, false if none matched.

=cut

# remove a single item matching.
# $max = stop searching when removed this many (optional)
sub list_store_remove_matches {
    my ($mod, $key, $sub, $max) = @_;
    my @before  = @{ $mod->{store}{$key} or return };
    my ($removed, @after) = 0;
    while (my $item = shift @before) {

        # it matches. add the remaining.
        if ($sub->($item)) {
            last if $max && $removed == $max;
            next;
        }

        # no match. add and continue.
        push @after, $item;

    }

    # add the rest, store.
    push @after, @before;
    $mod->{store}{$key} = \@after;

    return $removed;
}

=head2 $mod->list_store_items($key)

Fetches all values in a list associated with module.

=over

=item *

B<$key> - name of the list to retrieve.

=back

B<Returns>

List of fetch values, or empty list if none were found.

=cut

# returns all the items in a list store.
# if the store doesn't exist, this is
# still safe and returns an empty list.
sub list_store_items {
    my ($mod, $key) = @_;
    return @{ $mod->{store}{$key} || [] };
}

####################
### DEPENDENCIES ###
####################

=head2 $mod->dependencies

B<Returns> top-level module dependencies.

=cut

# returns the modules that this depends on.
sub dependencies {
    return @{ shift->{dependencies} || [] };
}

=head2 $mod->companions

For companion submodules,
B<Returns> modules that this submodule depends on.

=cut

# returns the modules that this companion submodule depends on.
sub companions {
    return @{ shift->{companions} || [] };
}

=head2 $mod->dependents

B<Returns> top-level modules that depend on this module.

=cut

# returns the top-level modules that depend on this.
sub dependents {
    my $mod = shift;
    my @mods;
    foreach my $m (@{ $mod->api->{loaded} }) {
        next unless first { $_ == $mod } $m->dependencies;
        push @mods, $m;
    }
    return @mods;
}

=head2 $mod->dependent_companions

B<Returns> companion submodules that depend on this module.

=cut

# returns the companion submodules that depend on this.
sub dependent_companions {
    my $mod = shift;
    my @mods;
    foreach my $m (@{ $mod->api->{loaded} }) {
        next unless first { $_ == $mod } $m->companions;
        push @mods, $m;
    }
    return @mods;
}

=head1 AUTHOR

L<Mitchell Cooper|https://github.com/cooper> <cooper@cpan.org>

Copyright E<copy> 2017. Released under New BSD license.

Comments, complaints, and recommendations are accepted. Bugs may be reported on
L<GitHub|https://github.com/cooper/evented-api-engine/issues>.

=cut

1;
