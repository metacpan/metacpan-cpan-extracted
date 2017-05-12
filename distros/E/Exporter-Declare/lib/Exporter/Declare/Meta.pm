package Exporter::Declare::Meta;
use strict;
use warnings;

use Scalar::Util qw/blessed reftype/;
use Carp qw/croak/;
use aliased 'Exporter::Declare::Export::Sub';
use aliased 'Exporter::Declare::Export::Variable';
use aliased 'Exporter::Declare::Export::Alias';
use Meta::Builder;

accessor 'export_meta';

hash_metric exports => (
    add => sub {
        my $self = shift;
        my ( $data, $metric, $action, $item, $ref ) = @_;
        croak "Exports must be instances of 'Exporter::Declare::Export'"
            unless blessed($ref) && $ref->isa('Exporter::Declare::Export');

        my ( $type, $name ) = ( $item =~ m/^([\&\%\@\$])?(.*)$/ );
        $type ||= '&';
        my $fullname = "$type$name";

        $self->default_hash_add( $data, $metric, $action, $fullname, $ref );

        push @{$self->export_tags->{all}} => $fullname;
    },
    get => sub {
        my $self = shift;
        my ( $data, $metric, $action, $item ) = @_;

        croak "exports_get() does not accept a tag as an argument"
            if $item =~ m/^[:-]/;

        my ( $type, $name ) = ( $item =~ m/^([\&\%\@\$])?(.*)$/ );
        $type ||= '&';
        my $fullname = "$type$name";

        return $self->default_hash_get( $data, $metric, $action, $fullname )
            || croak $self->package . " does not export '$fullname'";
    },
    merge => sub {
        my $self = shift;
        my ( $data, $metric, $action, $merge ) = @_;
        my $newmerge = {};

        for my $item ( keys %$merge ) {
            my $value = $merge->{$item};
            next if $value->isa(Alias);
            next if $data->{$item};
            $newmerge->{$item} = $value;
        }
        $self->default_hash_merge( $data, $metric, $action, $newmerge );
    },
    list => sub {
        my $self = shift;
        my ($data) = @_;
        return keys %$data;
    },
);

hash_metric options => (
    add => sub {
        my $self = shift;
        my ( $data, $metric, $action, $item ) = @_;

        croak "'$item' is already a tag, you can't also make it an option."
            if $self->export_tags_has($item);
        croak "'$item' is already an argument, you can't also make it an option."
            if $self->arguments_has($item);

        $self->default_hash_add( $data, $metric, $action, $item, 1 );
    },
    list => sub {
        my $self = shift;
        my ($data) = @_;
        return keys %$data;
    },
);

hash_metric arguments => (
    add => sub {
        my $self = shift;
        my ( $data, $metric, $action, $item ) = @_;

        croak "'$item' is already a tag, you can't also make it an argument."
            if $self->export_tags_has($item);
        croak "'$item' is already an option, you can't also make it an argument."
            if $self->options_has($item);

        $self->default_hash_add( $data, $metric, $action, $item, 1 );
    },
    merge => sub {
        my $self = shift;
        my ( $data, $metric, $action, $merge ) = @_;
        my $newmerge = {%$merge};
        delete $newmerge->{suffix};
        delete $newmerge->{prefix};
        $self->default_hash_merge( $data, $metric, $action, $newmerge );
    },
    list => sub {
        my $self = shift;
        my ($data) = @_;
        return keys %$data;
    },
);

lists_metric export_tags => (
    push => sub {
        my $self = shift;
        my ( $data, $metric, $action, $item, @args ) = @_;

        croak "'$item' is a reserved tag, you cannot override it."
            if $item eq 'all';
        croak "'$item' is already an option, you can't also make it a tag."
            if $self->options_has($item);
        croak "'$item' is already an argument, you can't also make it a tag."
            if $self->arguments_has($item);

        $self->default_list_push( $data, $metric, $action, $item, @args );
    },
    merge => sub {
        my $self = shift;
        my ( $data, $metric, $action, $merge ) = @_;
        my $newmerge = {};
        my %aliases  = (
            map {
                my ($name) = (m/^&?(.*)$/);
                ( $name => 1, "&$name" => 1 )
            } @{$merge->{alias}}
        );

        for my $item ( keys %$merge ) {
            my $values = $merge->{$item};
            $newmerge->{$item} = [grep { !$aliases{$_} } @$values];
        }

        $self->default_list_merge( $data, $metric, $action, $newmerge );
    },
    list => sub {
        my $self = shift;
        my ($data) = @_;
        return keys %$data;
    },
);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        @_,
        export_tags => {all    => [], default => [], alias => []},
        arguments   => {prefix => 1,  suffix  => 1},
    );
    $self->add_alias;
    return $self;
}

sub new_from_exporter {
    my $class      = shift;
    my ($exporter) = @_;
    my $self       = $class->new($exporter);
    my %seen;
    my ($exports)    = $self->get_ref_from_package('@EXPORT');
    my ($export_oks) = $self->get_ref_from_package('@EXPORT_OK');
    my ($tags)       = $self->get_ref_from_package('%EXPORT_TAGS');
    $self->exports_add(@$_) for map {
        my ( $ref, $name ) = $self->get_ref_from_package($_);

        if ( $name =~ m/^\&/ ) {
            Sub->new( $ref, exported_by => $exporter );
        }
        else {
            Variable->new( $ref, exported_by => $exporter );
        }
        [$name, $ref];
    } grep { !$seen{$_}++ } @$exports, @$export_oks;
    $self->export_tags_push( 'default', @$exports )
        if @$exports;
    $self->export_tags_push( $_, $tags->{$_} ) for keys %$tags;
    return $self;
}

sub add_alias {
    my $self    = shift;
    my $package = $self->package;
    my ($alias) = ( $package =~ m/([^:]+)$/ );
    $self->exports_add( $alias, Alias->new( sub { $package }, exported_by => $package ) );
    $self->export_tags_push( 'alias', $alias );
}

sub is_tag {
    my $self = shift;
    my ($name) = @_;
    return exists $self->export_tags->{$name} ? 1 : 0;
}

sub is_argument {
    my $self = shift;
    my ($name) = @_;
    return exists $self->arguments->{$name} ? 1 : 0;
}

sub is_option {
    my $self = shift;
    my ($name) = @_;
    return exists $self->options->{$name} ? 1 : 0;
}

sub get_ref_from_package {
    my $self = shift;
    my ($item) = @_;
    use Carp qw/confess/;
    confess unless $item;
    my ( $type, $name ) = ( $item =~ m/^([\&\@\%\$]?)(.*)$/ );
    $type ||= '&';
    my $fullname = "$type$name";
    my $ref      = $self->package . '::' . $name;

    no strict 'refs';
    return ( \&{$ref}, $fullname ) if !$type || $type eq '&';
    return ( \${$ref}, $fullname ) if $type eq '$';
    return ( \@{$ref}, $fullname ) if $type eq '@';
    return ( \%{$ref}, $fullname ) if $type eq '%';
    croak "'$item' cannot be exported";
}

sub reexport {
    my $self = shift;
    my ($exporter) = @_;
    my $meta =
          $exporter->can('export_meta')
        ? $exporter->export_meta()
        : __PACKAGE__->new_from_exporter($exporter);
    $self->merge($meta);
}

1;

=head1 NAME

Exporter::Declare::Meta - The meta object which stores meta-data for all
exporters.

=head1 DESCRIPTION

All classes that use Exporter::Declare have an associated Meta object. Meta
objects track available exports, tags, and options.

=head1 METHODS

=over 4

=item $class->new( $package )

Created a meta object for the specified package. Also injects the export_meta()
sub into the package namespace that returns the generated meta object.

=item $class->new_from_exporter( $package )

Create a meta object for a package that already uses Exporter.pm. This will not
turn the class into an Exporter::Declare package, but it will create a meta
object and export_meta() method on it. This si primarily used for reexport
purposes.

=item $package = $meta->package()

Get the name of the package with which the meta object is associated.

=item $meta->add_alias()

Usually called at construction to add a package alias function to the exports.

=item $meta->add_export( $name, $ref )

Add an export, name should be the item name with sigil (assumed to be sub if
there is no sigil). $ref should be a ref blessed as an
L<Exporter::Declare::Export> subclass.

=item $meta->get_export( $name )

Retrieve the L<Exporter::Declare::Export> object by name. Name should be the
item name with sigil, assumed to be sub when sigil is missing.

=item $meta->export_tags_push( $name, @items )

Add @items to the specified tag. Tag will be created if it does not already
exist. $name should be the tag name B<WITHOUT> -/: prefix.

=item @list = $meta->export_tags_get( $name )

Get the list of items associated with the specified tag.  $name should be the
tag name B<WITHOUT> -/: prefix.

=item @list = $meta->export_tags_list()

Get a list of all export tags.

=item $bool = $meta->is_tag( $name )

Check if a tag with the given name exists.  $name should be the tag name
B<WITHOUT> -/: prefix.

=item $meta->options_add( $name )

Add import options by name. These will be boolean options that take no
arguments.

=item my @list = $meta->options_list()

=item $meta->arguments_add( $name )

Add import options that slurp in the next argument as a value.

=item $bool = $meta->is_option( $name )

Check if the specified name is an option.

=item $bool = $meta->is_argument( $name )

Check if the specified name is an option that takes an argument.

=item $meta->add_parser( $name, sub { ... })

Add a parser sub that should be associated with exports via L<Devel::Declare>

=item $meta->get_parser( $name )

Get a parser by name.

=item $ref = $meta->get_ref_from_package( $item )

Returns a reference to a specific package variable or sub.

=item $meta->reexport( $package )

Re-export the exports in the provided package. Package may be an
L<Exporter::Declare> based package or an L<Exporter> based package.

=item $meta->merge( $meta2 )

Merge-in the exports and tags of the second meta object.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
