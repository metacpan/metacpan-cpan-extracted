package Exporter::Declare;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/reftype/;
use aliased 'Exporter::Declare::Meta';
use aliased 'Exporter::Declare::Specs';
use aliased 'Exporter::Declare::Export::Sub';
use aliased 'Exporter::Declare::Export::Variable';
use aliased 'Exporter::Declare::Export::Generator';

BEGIN { Meta->new(__PACKAGE__) }

our $VERSION  = '0.114';
our @CARP_NOT = qw/
    Exporter::Declare
    Exporter::Declare::Specs
    Exporter::Declare::Meta
    Exporter::Declare::Magic
    /;

default_exports(
    qw/
        import
        exports
        default_exports
        import_options
        import_arguments
        export_tag
        export
        gen_export
        default_export
        gen_default_export
        /
);

exports(
    qw/
        reexport
        export_to
        /
);

export_tag(
    magic => qw/
        !export
        !gen_export
        !default_export
        !gen_default_export
        /
);

sub import {
    my $class  = shift;
    my $caller = caller;

    $class->alter_import_args( $caller, \@_ )
        if $class->can('alter_import_args');

    my $specs = _parse_specs( $class, @_ );

    $class->before_import( $caller, $specs )
        if $class->can('before_import');

    $specs->export($caller);

    $class->after_import( $caller, $specs )
        if $class->can('after_import');
}

sub after_import {
    my $class = shift;
    my ( $caller, $specs ) = @_;
    Meta->new($caller);

    return unless my $args = $specs->config->{'magic'};
    $args = ['-default'] unless ref $args && ref $args eq 'ARRAY';

    croak "Exporter::Declare::Magic must be installed seperately for -magic to work"
        unless eval { require Exporter::Declare::Magic };

    warn "Exporter::Declare -magic is deprecated. Please use Exporter::Declare::Magic directly";

    export_to( 'Exporter::Declare::Magic', $caller, @$args );
}

sub _parse_specs {
    my $class = _find_export_class( \@_ );
    my (@args) = @_;

    # XXX This is ugly!
    unshift @args => '-default'
        if $class eq __PACKAGE__
        && grep { $_ eq '-magic' } @args;

    return Specs->new( $class, @args );
}

sub export_to {
    my $class = _find_export_class( \@_ );
    my ( $dest, @args ) = @_;
    my $specs = _parse_specs( $class, @args );
    $specs->export($dest);
    return $specs;
}

sub export_tag {
    my $class = _find_export_class( \@_ );
    my ( $tag, @list ) = @_;
    $class->export_meta->export_tags_push( $tag, @list );
}

sub exports {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    _export( $class, undef, $_ ) for @_;
    $meta->export_tags_get('all');
}

sub default_exports {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->export_tags_push( 'default', _export( $class, undef, $_ ) ) for @_;
    $meta->export_tags_get('default');
}

sub export {
    my $class = _find_export_class( \@_ );
    _export( $class, undef, @_ );
}

sub gen_export {
    my $class = _find_export_class( \@_ );
    _export( $class, Generator(), @_ );
}

sub default_export {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->export_tags_push( 'default', _export( $class, undef, @_ ) );
}

sub gen_default_export {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->export_tags_push( 'default', _export( $class, Generator(), @_ ) );
}

sub import_options {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->options_add($_) for @_;
}

sub import_arguments {
    my $class = _find_export_class( \@_ );
    my $meta  = $class->export_meta;
    $meta->arguments_add($_) for @_;
}

sub _parse_export_params {
    my ( $class, $expclass, $name, @param ) = @_;
    my $ref = ref( $param[-1] ) ? pop(@param) : undef;
    my $meta = $class->export_meta;

    ( $ref, $name ) = $meta->get_ref_from_package($name)
        unless $ref;

    ( my $type, $name ) = ( $name =~ m/^([\$\@\&\%]?)(.*)$/ );
    $type = "" if $type eq '&';

    my $fullname = "$type$name";

    return (
        class        => $class,
        export_class => $expclass || undef,
        name         => $name,
        ref          => $ref,
        type         => $type || "",
        fullname     => $fullname,
        args         => \@param,
    );
}

sub _export {
    _add_export( _parse_export_params(@_) );
}

sub _add_export {
    my %params = @_;
    my $meta   = $params{class}->export_meta;
    $params{export_class} ||=
          reftype( $params{ref} ) eq 'CODE'
        ? Sub()
        : Variable();

    $params{export_class}->new(
        $params{ref},
        exported_by => $params{class},
        (
            $params{type} ? ( type => 'variable' )
            : ( type => 'sub' )
        ),
        (
            $params{extra_exporter_props} ? %{$params{extra_exporter_props}}
            : ()
        ),
    );

    $meta->exports_add( $params{fullname}, $params{ref} );

    return $params{fullname};
}

sub _is_exporter_class {
    my ($name) = @_;

    return 0 unless $name;

    # This is to work around a bug in older versions of UNIVERSAL::can which
    # would issue a warning about $name->can() when $name was not a valid
    # package.
    # This will first verify that $name is a namespace, if not it will return false.
    # If the namespace defines 'export_meta' we know it is an exporter.
    # If there is no @ISA array in the namespace we simply return false,
    # otherwise we fall back to $name->can().
    {
        no strict 'refs';
        no warnings 'once';
        return 0 unless keys %{"$name\::"};
        return 1 if defined *{"$name\::export_meta"}{CODE};
        return 0 unless @{"$name\::ISA"};
    }

    return eval { $name->can('export_meta'); 1 };
}

sub _find_export_class {
    my $args = shift;

    return shift(@$args)
        if @$args && _is_exporter_class(@$args);

    return caller(1);
}

sub reexport {
    my $from = pop;
    my $class = shift || caller;
    $class->export_meta->reexport($from);
}

1;

=head1 NAME

Exporter::Declare - Exporting done right

=head1 DESCRIPTION

Exporter::Declare is a meta-driven exporting tool. Exporter::Declare tries to
adopt all the good features of other exporting tools, while throwing away
horrible interfaces. Exporter::Declare also provides hooks that allow you to add
options and arguments for import. Finally, Exporter::Declare's meta-driven
system allows for top-notch introspection.

=head1 FEATURES

=over 4

=item Declarative exporting (like L<Moose> for exporting)

=item Meta-driven for introspection

=item Customizable import() method

=item Export groups (tags)

=item Export generators for subs and variables

=item Clear and concise OO API

=item Exports are blessed, allowing for more introspection

=item Import syntax based off of L<Sub::Exporter>

=item Packages export aliases

=back

=head1 SYNOPSIS

=head2 EXPORTER

    package Some::Exporter;
    use Exporter::Declare;

    default_exports qw/ do_the_thing /;
    exports qw/ subA subB $SCALAR @ARRAY %HASH /;

    # Create a couple tags (import lists)
    export_tag subs => qw/ subA subB do_the_thing /;
    export_tag vars => qw/ $SCALAR @ARRAY %HASH /;

    # These are simple boolean options, pass '-optionA' to enable it.
    import_options   qw/ optionA optionB /;

    # These are options which slurp in the next argument as their value, pass
    # '-optionC' => 'foo' to give it a value.
    import_arguments qw/ optionC optionD /;

    export anon_export => sub { ... };
    export '@anon_var' => [...];

    default_export a_default => sub { 'default!' }

    our $X = "x";
    default_export '$X';

    my $iterator = 'a';
    gen_export unique_class_id => sub {
        my $current = $iterator++;
        return sub { $current };
    };

    gen_default_export '$my_letter' => sub {
        my $letter = $iterator++;
        return \$letter;
    };

    # You can create a function to mangle the arguments before they are
    # parsed into a Exporter::Declare::Spec object.
    sub alter_import_args {
       my ($class, $importer, $args) = @_;

       # fiddle with args before importing routines are called
       @$args = grep { !/^skip_/ } @$args
    }

    # There is no need to fiddle with import() or do any wrapping.
    # the $specs data structure means you generally do not need to parse
    # arguments yourself (but you can if you want using alter_import_args())

    # Change the spec object before export occurs
    sub before_import {
        my $class = shift;
        my ( $importer, $specs ) = @_;

        if ($specs->config->{optionA}) {
            # Modify $spec attributes accordingly
        }
    }

    # Use spec object after export occurs
    sub after_import {
        my $class = shift;
        my ( $importer, $specs ) = @_;

        do_option_a() if $specs->config->{optionA};

        do_option_c( $specs->config->{optionC} )
            if $specs->config->{optionC};

        print "-subs tag was used\n"
            if $specs->config->{subs};

        print "exported 'subA'\n"
            if $specs->exports->{subA};
    }

    ...

=head2 IMPORTER

    package Some::Importer;
    use Some::Exporter qw/ subA $SCALAR !%HASH /,
                        -default => { -prefix => 'my_' },
                        qw/ -optionA !-optionB /,
                        subB => { -as => 'sub_b' };

    subA();
    print $SCALAR;
    sub_b();
    my_do_the_thing();

    ...

=head1 IMPORT INTERFACE

Importing from a package that uses Exporter::Declare will be familiar to anyone
who has imported from modules before. Arguments are all assumed to be export
names, unless prefixed with C<-> or C<:> In which case they may be a tag or an
option. Exports without a sigil are assumed to be code exports, variable
exports must be listed with their sigil.

Items prefixed with the C<!> symbol are forcefully excluded, regardless of any
listed item that may normally include them. Tags can also be excluded, this
will effectively exclude everything in the tag.

Tags are simply lists of exports, the exporting class may define any number of
tags. Exporter::Declare also has the concept of options, they have the same
syntax as tags. Options may be boolean or argument based. Boolean options are
actually 3 value, undef, false C<!>, or true. Argument based options will grab
the next value in the arguments list as their own, regardless of what type of
value it is.

When you use the module, or call import(), all the arguments are transformed
into an L<Exporter::Declare::Specs> object. Arguments are parsed for you into a
list of imports, and a configuration hash in which tags/options are keys. Tags
are listed in the config hash as true, false, or undef depending on if they
were included, negated, or unlisted. Boolean options will be treated in the
same way as tags. Options that take arguments will have the argument as their
value.

=head2 SELECTING ITEMS TO IMPORT

Exports can be subs, or package variables (scalar, hash, array). For subs
simply ask for the sub by name, you may optionally prefix the subs name with
the sub sigil C<&>. For variables list the variable name along with its sigil
C<$, %, or @>.

    use Some::Exporter qw/ somesub $somescalar %somehash @somearray /;

=head2 TAGS

Every exporter automatically has the following 3 tags, in addition they may
define any number of custom tags. Tags can be specified by their name prefixed
by either C<-> or C<:>.

=over 4

=item -all

This tag may be used to import everything the exporter provides.

=item -default

This tag is used to import the default items exported. This will be used when
no argument is provided to import.

=item -alias

Every package has an alias that it can export. This is the last segment of the
packages namespace. IE C<My::Long::Package::Name::Foo> could export the C<Foo()>
function. These alias functions simply return the full package name as a
string, in this case C<'My::Long::Package::Name::Foo'>. This is similar to
L<aliased>.

The -alias tag is a shortcut so that you do not need to think about what the
alias name would be when adding it to the import arguments.

    use My::Long::Package::Name::Foo -alias;

    my $foo = Foo()->new(...);

=back

=head2 RENAMING IMPORTED ITEMS

You can prefix, suffix, or completely rename the items you import. Whenever an
item is followed by a hash in the import list, that hash will be used for
configuration. Configuration items always start with a dash C<->.

The 3 available configuration options that effect import names are C<-prefix>,
C<-suffix>, and C<-as>. If C<-as> is seen it will be used as is. If prefix or
suffix are seen they will be attached to the original name (unless -as is
present in which case they are ignored).

    use Some::Exporter subA => { -as => 'DoThing' },
                       subB => { -prefix => 'my_', -suffix => '_ok' };

The example above will import C<subA()> under the name C<DoThing()>. It will
also import C<subB()> under the name C<my_subB_ok()>.

You may als specify a prefix and/or suffix for tags. The following example will
import all the default exports with 'my_' prefixed to each name.

    use Some::Exporter -default => { -prefix => 'my_' };

=head2 OPTIONS

Some exporters will recognise options. Options look just like tags, and are
specified the same way. What options do, and how they effect things is
exporter-dependant.

    use Some::Exporter qw/ -optionA -optionB /;

=head2 ARGUMENTS

Some options require an argument. These options are just like other
tags/options except that the next item in the argument list is slurped in as
the option value.

    use Some::Exporter -ArgOption    => 'Value, not an export',
                       -ArgTakesHash => { ... };

Once again available options are exporter specific.

=head2 PROVIDING ARGUMENTS FOR GENERATED ITEMS

Some items are generated at import time. These items may accept arguments.
There are 3 ways to provide arguments, and they may all be mixed (though that
is not recommended).

As a hash

    use Some::Exporter generated => { key => 'val', ... };

As an array

    use Some::Exporter generated => [ 'Arg1', 'Arg2', ... ];

As an array in a config hash

    use Some::Exporter generated => { -as => 'my_gen', -args => [ 'arg1', ... ]};

You can use all three at once, but this is really a bad idea, documented for completeness:

    use Some::Exporter generated => { -as => 'my_gen, key => 'value', -args => [ 'arg1', 'arg2' ]}
                       generated => [ 'arg3', 'arg4' ];

The example above will work fine, all the arguments will make it into the
generator. The only valid reason for this to work is that you may provide
arguments such as C<-prefix> to a tag that brings in generator(), while also
desiring to give arguments to generator() independently.

=head1 PRIMARY EXPORT API

With the exception of import(), all the following work equally well as
functions or class methods.

=over 4

=item import( @args )

The import() class method. This turns the @args list into an
L<Exporter::Declare::Specs> object.

=item exports( @add_items )

Add items to be exported.

=item @list = exports()

Retrieve list of exports.

=item default_exports( @add_items )

Add items to be exported, and add them to the -default tag.

=item @list = default_exports()

List of exports in the -default tag

=item import_options(@add_items)

Specify boolean options that should be accepted at import time.

=item import_arguments(@add_items)

Specify options that should be accepted at import that take arguments.

=item export_tag( $name, @add_items );

Define an export tag, or add items to an existing tag.

=back

=head1 EXTENDED EXPORT API

These all work fine in function or method form, however the syntax sugar will
only work in function form.

=over 4

=item reexport( $package )

Make this exporter inherit all the exports and tags of $package. Works for
Exporter::Declare or Exporter.pm based exporters. Re-Exporting of
L<Sub::Exporter> based classes is not currently supported.

=item export_to( $package, @args )

Export to the specified class.

=item export( $name )

=item export( $name, $ref )

export is a keyword that lets you export any 1 item at a time. The item can be
exported by name, or name + ref. When a ref is provided, the export is created,
but there is no corresponding variable/sub in the packages namespace.

=item default_export( $name )

=item default_export( $name, $ref )

=item gen_export( $name )

=item gen_export( $name, $ref )

=item gen_default_export( $name )

=item gen_default_export( $name, $ref )

These all act just like export(), except that they add subrefs as generators,
and/or add exports to the -default tag.

=back

=head1 MAGIC

Please use L<Exporter::Declare::Magic> directly from now on.

=head2 DEPRECATED USAGE OF MAGIC

    use Exporter::Declare '-magic';

This adds L<Devel::Declare> magic to several functions. It also allows you to
easily create or use parsers on your own exports. See
L<Exporter::Declare::Magic> for more details.

You can also provide import arguments to L<Devel::Declare::Magic>

    # Arguments to -magic must be in an arrayref, not a hashref.
    use Exporter::Declare -magic => [ '-default', '!export', -prefix => 'magic_' ];

=head1 INTERNAL API

Exporter/Declare.pm does not have much logic to speak of. Rather
Exporter::Declare is sugar on top of class meta data stored in
L<Exporter::Declare::Meta> objects. Arguments are parsed via
L<Exporter::Declare::Specs>, and also turned into objects. Even exports are
blessed references to the exported item itself, and handle the injection on
their own (See L<Exporter::Declare::Export>).

=head1 META CLASS

All exporters have a meta class, the only way to get the meta object is to call
the export_meta() method on the class/object that is an exporter. Any class
that uses Exporter::Declare gets this method, and a meta-object.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
