package Exporter::Declare::Specs;
use strict;
use warnings;

use Carp qw/croak/;
our @CARP_NOT = qw/Exporter::Declare/;

sub new {
    my $class = shift;
    my ( $package, @args ) = @_;
    my $self = bless( [$package,{},{},[]], $class );
    @args = (':default') unless @args;
    $self->_process( "import list", @args );
    return $self;
}

sub package  { shift->[0] }
sub config   { shift->[1] }
sub exports  { shift->[2] }
sub excludes { shift->[3] }

sub export {
    my $self = shift;
    my ( $dest ) = @_;
    for my $item ( keys %{ $self->exports }) {
        my ( $export, $conf, $args ) = @{ $self->exports->{$item} };
        my ( $sigil, $name ) = ( $item =~ m/^([\&\%\$\@])(.*)$/ );
        $name = $conf->{as} || join(
            '',
            $conf->{prefix} || $self->config->{prefix} || '',
            $name,
            $conf->{suffix} || $self->config->{suffix} || '',
        );
        $export->inject( $dest, $name, @$args );
    }
}

sub add_export {
    my $self = shift;
    my ( $name, $value, $config ) = @_;
    my $type = ref $value eq 'CODE' ? 'Sub' : 'Variable';
    "Exporter::Declare::Export::$type"->new( $value, exported_by => scalar caller() );
    $self->exports->{$name} = [
        $value,
        $config || {},
        [],
    ];
}

sub arguments {
    my $self = shift;
    my $meta = $self->package->export_meta;
    return grep { $meta->is_argument($_) } keys %{$self->config};
}

sub options {
    my $self = shift;
    my $meta = $self->package->export_meta;
    return grep { $meta->is_option($_) } keys %{$self->config};
}

sub tags {
    my $self = shift;
    my $meta = $self->package->export_meta;
    return grep { $meta->is_tag($_) } keys %{$self->config};
}

sub _make_info {
    my $self = shift;
    my $config = $self->config;
    return { map { $_, $config->{$_} } @_ };
}

sub argument_info {
    my $self = shift;
    return $self->_make_info($self->arguments);
}

sub option_info {
    my $self = shift;
    return $self->_make_info($self->options);
}

sub tag_info {
    my $self = shift;
    my $all_tags = $self->package->export_meta->export_tags;
    return { map { $_, $all_tags->{$_} } $self->tags };
}


sub _process {
    my $self = shift;
    my ( $tag, @args ) = @_;
    my $argnum = 0;
    while ( my $item = shift( @args )) {
        croak "not sure what to do with $item ($tag argument: $argnum)"
            if ref $item;
        $argnum++;

        if ( $item =~ m/^(!?)[:-](.*)$/ ) {
            my ( $neg, $param ) = ( $1, $2 );
            if ( $self->package->export_meta->arguments_has( $param )) {
                $self->config->{$param} = shift( @args );
                $argnum++;
                next;
            }
            else {
                $self->config->{$param} = ref( $args[0] ) ? $args[0] : !$neg;
            }
        }

        if ( $item =~ m/^!(.*)$/ ) {
            $self->_exclude_item( $1 )
        }
        elsif ( my $type = ref( $args[0] )) {
            my $arg = shift( @args );
            $argnum++;
            if ( $type eq 'ARRAY' ) {
                $self->_include_item( $item, undef, $arg );
            }
            elsif ( $type eq 'HASH' ) {
                $self->_include_item( $item, $arg, undef );
            }
            else {
                croak "Not sure what to do with $item => $arg ($tag arguments: "
                . ($argnum - 1) . " and $argnum)";
            }
        }
        else {
            $self->_include_item( $item )
        }
    }
    delete $self->exports->{$_} for @{ $self->excludes };
}

sub _item_name { my $in = shift; $in =~ m/^[\&\$\%\@]/ ? $in : "\&$in" }

sub _exclude_item {
    my $self = shift;
    my ( $item ) = @_;

    if ( $item =~ m/^[:-](.*)$/ ) {
        $self->_exclude_item( $_ )
            for $self->_export_tags_get( $1 );
        return;
    }

    push @{ $self->excludes } => _item_name($item);
}

sub _include_item {
    my $self = shift;
    my ( $item, $conf, $args ) = @_;
    $conf ||= {};
    $args ||= [];

    use Carp qw/confess/;
    confess $item if $item =~ m/^&?aaa_/;

    push @$args => @{ delete $conf->{'-args'} }
        if defined $conf->{'-args'};

    for my $key ( keys %$conf ) {
        next if $key =~ m/^[:-]/;
        push @$args => ( $key, delete $conf->{$key} );
    }

    if ( $item =~ m/^[:-](.*)$/ ) {
        my $name = $1;
        return if $self->package->export_meta->options_has( $name );
        for my $tagitem ( $self->_export_tags_get( $name ) ) {
            my ( $negate, $name ) = ( $tagitem =~ m/^(!)?(.*)$/ );
            if ( $negate ) {
                $self->_exclude_item( $name );
            }
            else {
                $self->_include_item( $tagitem, $conf, $args );
            }
        }
        return;
    }

    $item = _item_name($item);

    my $existing = $self->exports->{ $item };

    unless ( $existing ) {
        $existing = [ $self->_get_item( $item ), {}, []];
        $self->exports->{ $item } = $existing;
    }

    push @{ $existing->[2] } => @$args;
    for my $param (  keys %$conf ) {
        my ( $name ) = ( $param =~ m/^[-:](.*)$/ );
        $existing->[1]->{$name} = $conf->{$param};
    }
}

sub _get_item {
    my $self = shift;
    my ( $name ) = @_;
    $self->package->export_meta->exports_get( $name );
}

sub _export_tags_get {
    my $self = shift;
    my ( $name ) = @_;
    $self->package->export_meta->export_tags_get( $name );
}

1;

=head1 NAME

Exporter::Declare::Specs - Import argument parser for Exporter::Declare

=head1 DESCRIPTION

Import arguments can get complicated. All arguments are assumed to be exports
unless they have a - or : prefix. The prefix may denote a tag, a boolean
option, or an option that takes the next argument as a value. In addition
almost all these can be negated with the ! prefix.

This class takes care of parsing the import arguments and generating data
structures that can be used to find what the exporter needs to know.

=head1 METHODS

=over 4

=item $class->new( $package, @args )

Create a new instance and parse @args.

=item $specs->package()

Get the name of the package that should do the exporting.

=item $hashref = $specs->config()

Get the configuration hash, All specified options and tags are the keys. The
value will be true/false/undef for tags/boolean options. For options that take
arguments the value will be that argument. When a config hash is provided to a
tag it will be the value.

=item @names = $specs->arguments()

=item @names = $specs->options()

=item @names = $specs->tags()

Get the argument, option, or tag names that were specified for the import.

=item $hashref = $specs->argument_info()

Get the arguments that were specified for the import. The key is the name of the
argument and the value is what the user supplied during import.

=item $hashref = $specs->option_info()

Get the options that were specified for the import. The key is the name of the user 
supplied option and the value will evaluate to true.

=item $hashref = $specs->tag_info()

Get the values associated with the tags used during import. The key is the name of the tag
and the value is an array ref containing the values given to export_tag() for the associated
name.

=item $hashref = $specs->exports()

Get the exports hash. The keys are names of the exports. Values are an array
containing the export, item specific config hash, and arguments array. This is
generally not intended for direct consumption.

=item $arrayref = $specs->excludes()

Get the arrayref containing the names of all excluded exports.

=item $specs->export( $package )

Do the actual exporting. All exports will be injected into $package.

=item $specs->add_export( $name, $value )

=item $specs->add_export( $name, $value, \%config )

Add an export. Name is required, including sigil. Value is required, if it is a
sub it will be blessed as a ::Sub, otherwise blessed as a ::Variable.

    $specs->add_export( '&foo' => sub { return 'foo' });

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
