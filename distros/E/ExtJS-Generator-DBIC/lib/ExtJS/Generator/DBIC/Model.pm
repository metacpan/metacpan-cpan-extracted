package ExtJS::Generator::DBIC::Model;
$ExtJS::Generator::DBIC::Model::VERSION = '0.004';
#ABSTRACT: ExtJS model producer


use Moo;
use Types::Standard qw( Str HashRef InstanceOf HasMethods CodeRef );
use Data::Dump::JavaScript qw( dump_javascript false true );
use Try::Tiny;
#use Text::Xslate;
#use List::Util qw( none );
use Path::Class;
use Fcntl qw( O_CREAT O_WRONLY O_EXCL O_TRUNC );
use Module::Load;
use namespace::clean;


has 'schemaname' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has 'schema' => (
    is  => 'lazy',
    isa => InstanceOf ['DBIx::Class::Schema'],
);

sub _build_schema {
    my $self = shift;
    load $self->schemaname;
    my $schema = $self->schemaname->connect;
    return $schema;
}


has 'appname' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has 'model_namespace' => (
    is  => 'lazy',
    isa => Str,
);

sub _build_model_namespace {
    my $self = shift;

    return $self->appname . '.model';
}


has 'model_baseclass' => (
    is  => 'lazy',
    isa => Str,
);

sub _build_model_baseclass {
    my $self = shift;

    return $self->appname . '.data.Model';
}

#sub sort_field_attrs {
#    my ($attrs, $fixed) = @_;
#    return [ @$fixed, sort grep { my $attr = $_; none { $_ eq $attr } @$fixed } @$attrs ];
#}

#has '_xslate' => (
#    is  => 'lazy',
#    isa => InstanceOf['Text::Xslate'],
#);
#
#sub _build__xslate {
#    my $self = shift;
#    return Text::Xslate->new(
#        function => {
#            'array::sort_field_attrs' => \&sort_field_attrs,
#        },
#    );
#}

#has 'model_template' => (
#    is  => 'lazy',
#    isa => Str,
#);

#sub _build_model_template {
#    return q/Ext.define('<: $classname :>', {
#    : for $attributes.keys().sort_field_attrs(["extend", "requires", "idProperty", "fields"]) -> $attr {
#    : if is_array_ref($attributes[$attr]) {
#    <: $attr :>: [
#    : for $attributes[$attr].sort() -> $subkey {
#    : if $attr == 'fields' {
#        {
#            : for $subkey.keys().sort_field_attrs(["name", "type"]) -> $field {
#            <: $field :>: '<: $subkey[$field] :>'<: if ! $~field.is_last { :>,<: } :>
#            : }
#        }<: if ! $~subkey.is_last { :>,<: } :>
#    : }
#    : else {
#        '<: $subkey :>'<: if ! $~subkey.is_last { :>,<: } :>
#    : }
#    : }
#    ]<: if ! $~attr.is_last { :>,<: } :>
#    : }
#    : else {
#    <: $attr :>: '<: $attributes[$attr] :>'<: if ! $~attr.is_last { :>,<: } :>
#    : }
#    : }
#});
#/;
#}


has 'model_args' => (
    is  => 'ro',
    isa => HashRef,
);

my %translate = (

    #
    # MySQL types
    #
    bigint     => 'int',
    double     => 'float',
    decimal    => 'float',
    float      => 'float',
    int        => 'int',
    integer    => 'int',
    mediumint  => 'int',
    smallint   => 'int',
    tinyint    => 'int',
    char       => 'string',
    varchar    => 'string',
    tinyblob   => 'auto',
    blob       => 'auto',
    mediumblob => 'auto',
    longblob   => 'auto',
    tinytext   => 'string',
    text       => 'string',
    longtext   => 'string',
    mediumtext => 'string',
    enum       => 'string',
    set        => 'string',
    date       => 'date',
    datetime   => 'date',
    time       => 'date',
    timestamp  => 'date',
    year       => 'date',

    #
    # PostgreSQL types
    #
    numeric             => 'float',
    'double precision'  => 'float',
    serial              => 'int',
    bigserial           => 'int',
    money               => 'float',
    character           => 'string',
    'character varying' => 'string',
    bytea               => 'auto',
    interval            => 'float',
    boolean             => 'boolean',
    point               => 'float',
    line                => 'float',
    lseg                => 'float',
    box                 => 'float',
    path                => 'float',
    polygon             => 'float',
    circle              => 'float',
    cidr                => 'string',
    inet                => 'string',
    macaddr             => 'string',
    bit                 => 'int',
    'bit varying'       => 'int',

    #
    # Oracle types
    #
    number   => 'float',
    varchar2 => 'string',
    long     => 'float',
);

my %extjs_class_for_datatype = (
    boolean => 'Ext.data.field.Boolean',
    date    => 'Ext.data.field.Date',
    int     => 'Ext.data.field.Integer',
    float   => 'Ext.data.field.Number',
    string  => 'Ext.data.field.String',
);


sub extjs_model_name {
    my ( $self, $tablename ) = @_;
    $tablename = $tablename =~ m/^(?:\w+::)* (\w+)$/x ? $1 : $tablename;
    return $self->model_namespace . '.' . ucfirst($tablename);
}


sub extjs_model_alias {
    my ( $self, $modelname ) = @_;
    $modelname = $modelname =~ m/^(?:\w+\.)* (\w+\.\w+)$/x ? $1 : $modelname;
    return lc($modelname);
}


sub extjs_model_entityname {
    my ( $self, $extjs_model_name ) = @_;
    die 'ExtJS model name is required'
        if not defined $extjs_model_name;
    my $model_namespace = $self->model_namespace;
    my ($entityname) = $extjs_model_name =~ /^$model_namespace\.(.+)$/;
    return $entityname;
}


sub extjs_model {
    my ( $self, $rsrcname ) = @_;
    my $schema = $self->schema;

    my $rsrc         = $schema->source($rsrcname);
    my $extjsname    = $self->extjs_model_name($rsrcname);
    my $columns_info = $rsrc->columns_info;
    my %field_by_colname;
    my %requires;
    # same order the columns where added to the ResultSource
    foreach my $colname ( $rsrc->columns ) {
        my $field_params = { name => $colname };
        my $column_info = $columns_info->{$colname};

        # views might not have column infos
        if ( not %$column_info ) {
            $field_params->{data_type} = 'auto';
        }
        else {
            my $data_type = lc( $column_info->{data_type} );
            if ( exists $translate{$data_type} ) {
                my $extjs_data_type = $translate{$data_type};

                # determine if a numeric column is an int or a really a float
                if ( $extjs_data_type eq 'float' ) {
                    $extjs_data_type = 'int'
                        if exists $column_info->{size}
                        && $column_info->{size} !~ /,/;
                }
                $field_params->{type} = $extjs_data_type;
                # remember all ExtJS data types for requires
                $requires{$extjs_class_for_datatype{$extjs_data_type}} = 1;
            }

            $field_params->{defaultValue} = $column_info->{default_value}
                if exists $column_info->{default_value}
                && defined $column_info->{default_value};

            if ( exists $column_info->{is_nullable} ) {
                if ( $column_info->{is_nullable} && $field_params->{type} ne 'date' ) {
                    $field_params->{allowNull} = true();
                }
                # only required for foreign key columns -> smaller JS
                #else {
                #    $field_params->{allowBlank} = false();
                #}
            }
            # is_nullable defaults to false in DBIC, allowNull defaults also
            # to false in ExtJS 6, so we don't need to set it -> smaller JS
            # else {
            #     $field_params->{allowNull} = false();
            # }
            if ( exists $column_info->{is_auto_increment}
                && $column_info->{is_auto_increment} ) {
                $field_params->{persist} = false();
            }

            #use Data::Dumper::Concise;
            #warn Dumper($column_info)
            #    if $rsrcname eq 'Customer';

            # support for DBIx::Class::DynamicDefault
            if ( $rsrc->isa('DBIx::Class::DynamicDefault')
                 && (
                    (  exists $column_info->{dynamic_default_on_create}
                        && $column_info->{dynamic_default_on_create} eq 'get_timestamp' )
                    || (
                        exists $column_info->{dynamic_default_on_update}
                        && $column_info->{dynamic_default_on_update} eq 'get_timestamp'
                    )
                ) ) {
                $field_params->{persist} = false();
            }

            # support for DBIx::Class::TimeStamp
            if ( (  exists $column_info->{set_on_create}
                    && $column_info->{set_on_create} )
                || (
                    exists $column_info->{set_on_update}
                    && $column_info->{set_on_update}
                ) ) {
                $field_params->{persist} = false();
            }

            # support for DBIx::Class::UserStamp
            if ( (  exists $column_info->{store_user_on_create}
                    && $column_info->{store_user_on_create} )
                || (
                    exists $column_info->{store_user_on_update}
                    && $column_info->{store_user_on_update}
                ) ) {
                $field_params->{persist} = false();
            }

            # support for DBIx::Class::InflateColumn::Boolean
            if ( exists $column_info->{is_boolean}
                 && $column_info->{is_boolean} ) {
                 $field_params->{type} = 'bool';
             }
        }
        $field_by_colname{$colname} = $field_params;
    }

    #my @assocs;
    foreach my $relname ( sort $rsrc->relationships ) {
        my $relinfo = $rsrc->relationship_info($relname);

        # FIXME: handle complex relationship conditions, skip for now
        if ( ! (ref $relinfo->{cond} eq 'HASH') ) {
            warn "$extjsname:\t$relname: complex relationship condition, skipping";
            next;
        }

        if ( keys %{ $relinfo->{cond} } > 1 ) {
            warn
                "$extjsname:\t$relname: skipping because multi-cond rels aren't supported by ExtJS\n";
            next;
        }

        if ( keys %{ $relinfo->{cond} } > 1 ) {
            warn
                "$extjsname:\t$relname: multiple column relationship not supported by ExtJS\n";
            next;
        }

        #use Data::Dumper::Concise;
        #print $rsrcname . Dumper($relinfo)
        #    if $rsrcname eq 'Raduser';

        my ($rel_col) = keys %{ $relinfo->{cond} };
        my $our_col = $relinfo->{cond}->{$rel_col};
        $rel_col =~ s/^foreign\.//;
        $our_col =~ s/^self\.//;
        my $column_info = $columns_info->{$our_col};

        my $remote_rsrc = $schema->source($relinfo->{source});
        my $remote_relname;
        foreach my $relname ( $remote_rsrc->relationships ) {
            my $remote_relinfo = $remote_rsrc->relationship_info($relname);

            # FIXME: handle complex relationship conditions, skip for now
            if ( ! (ref $remote_relinfo->{cond} eq 'HASH') ) {
                warn "$extjsname:\t$relname: complex relationship condition, skipping";
                next;
            }
            my ($remote_rel_col) = keys %{ $remote_relinfo->{cond} };
            my $remote_our_col = $remote_relinfo->{cond}->{$remote_rel_col};
            $remote_rel_col =~ s/^foreign\.//;
            $remote_our_col =~ s/^self\.//;
            if ( $remote_relinfo->{source} eq $rsrc->result_class
                && $rel_col eq $remote_our_col
                && $our_col eq $remote_rel_col ) {
                $remote_relname = $relname;
                last;
            }
        }
        warn "$extjsname:\t$relname: can't find reverse relationship name\n"
            if not defined $remote_relname;

        my $attrs = $relinfo->{attrs};

        #my $extjs_rel = {
        #    name           => $relname,
        #    associationKey => $relname,
        #
        #    # class instead of source?
        #    model      => $self->extjs_model_name( $relinfo->{source} ),
        #    primaryKey => $rel_col,
        #    foreignKey => $our_col,
        #};

        # belongs_to
        #{
        #    attrs => {
        #        accessor                  => "filter",
        #        is_depends_on             => 1,
        #        is_foreign_key_constraint => 1,
        #        undef_on_null_fk          => 1
        #    },
        #    class => "My::Schema::Result::Another",
        #    cond  => {
        #        "foreign.id" => "self.another_id"
        #    },
        #    source => "My::Schema::Result::Another"
        #}

        # has_one
        #{
        #    attrs => {
        #        accessor       => "single",
        #        cascade_delete => 0,
        #        cascade_update => 1,
        #        is_depends_on  => 0,
        #        proxy          => [ "radusername_realm" ]
        #    },
        #    class => "NAC::Model::DBIC::Table::View_Raduser",
        #    cond  => {
        #        "foreign.id_raduser" => "self.id_raduser"
        #    },
        #    source => "NAC::Model::DBIC::Table::View_Raduser"
        #}
        if (
            $attrs->{is_foreign_key_constraint}
            && (   $attrs->{accessor} eq 'single'
                || $attrs->{accessor} eq 'filter' )
            ) {
            if ( exists $field_by_colname{$our_col}->{reference}) {
                warn "$extjsname:\t$relname: relationship for column '$our_col' would overwrite '"
                    . $field_by_colname{$our_col}->{reference}->{role}
                    . "', skipping\n";
                next;
            }
            # add reference to field definition
            $field_by_colname{$our_col}->{reference} = {
                type => $self->extjs_model_entityname(
                    $self->extjs_model_name( $relinfo->{source} ) ),
                role => $relname,
                (defined $remote_relname
                    ? (inverse => $remote_relname)
                    : ()
                ),
            };

            $field_by_colname{$our_col}->{allowBlank} = false()
                if exists $column_info->{is_nullable} 
                    and !$column_info->{is_nullable};

            $field_by_colname{$our_col}->{unique} = true()
                if $attrs->{accessor} eq 'single'
                && $attrs->{is_depends_on} == 0;

            #$extjs_rel->{type} = 'belongsTo';
        }

        #{
        #    attrs => {
        #        accessor       => "multi",
        #        cascade_copy   => 1,
        #        cascade_delete => 1,
        #        is_depends_on  => 0,
        #        join_type      => "LEFT"
        #    },
        #    class => "My::Schema::Result::Basic",
        #    cond  => {
        #        "foreign.another_id" => "self.id"
        #    },
        #    source => "My::Schema::Result::Basic"
        #}
        #elsif ( $attrs->{accessor} eq 'multi' ) {
        #    $extjs_rel->{type} = 'hasMany';
        #}
        #push @assocs, $extjs_rel;
    }
    my $model = {

        extend => $self->model_baseclass,
        alias => $self->extjs_model_alias($extjsname),
        requires => [ sort keys %requires ],
    };
    my @pk = $rsrc->primary_columns;
    if ( @pk == 1 ) {
        $model->{idProperty} = $pk[0];
    }
    else {
        warn
            "$extjsname:\tnot setting idProperty because number of primary key columns isn't one\n";
    }
    my @fields;

    # always keep the primary column as the first entry
    push @fields, delete $field_by_colname{ $model->{idProperty} }
        if exists $model->{idProperty};
    push @fields, map { $field_by_colname{$_} } sort keys %field_by_colname;
    $model->{fields} = \@fields;

    #$model->{associations} = \@assocs
    #    if @assocs;

    # override any generated config properties
    if ( $self->model_args ) {
        my %foo = ( %$model, %{ $self->model_args } );
        $model = \%foo;
    }

    return [ $extjsname, $model ];
}


sub extjs_models {
    my $self = shift;

    my $schema = $self->schema;

    my %output;
    foreach my $rsrcname ( $schema->sources ) {
        my $extjs_model = $self->extjs_model($rsrcname);

        $output{ $extjs_model->[0] } = $extjs_model;
    }

    return \%output;
}


sub extjs_model_to_file {
    my ( $self, $rsrcname, $dirname ) = @_;

    my $dir = Path::Class::Dir->new($dirname);
    $dir->open
        or die "$!: " . $dirname;

    my ( $extjs_model_name, $extjs_model_code ) =
        @{ $self->extjs_model($rsrcname) };

    my @namespaces = split( /\./, $extjs_model_name );
    die "model class '"
        . $namespaces[0]
        . "' doesn't match appname '"
        . $self->appname . "'"
        if $namespaces[0] ne $self->appname;

    my $modeldir = $dir->subdir( @namespaces[ 1 .. $#namespaces - 1 ] );
    $modeldir->mkpath;

    my $filename = $namespaces[-1] . '.js';
    my $file     = $modeldir->file($filename);
    my $fh       = $file->open( O_CREAT | O_WRONLY | O_EXCL )
    #my $fh       = $file->open( O_TRUNC | O_WRONLY | O_EXCL )
        or die "$!: $file";

    #$extjs_model_code->{classname} = $extjs_model_name;
    #my $template_vars = {
    #    classname => $extjs_model_name,
    #    attributes => $extjs_model_code,
    #};
    my $json =
        #$self->_xslate->render_string($self->model_template, $template_vars);
        "Ext.define('$extjs_model_name', "
        . dump_javascript($extjs_model_code)
        . ');';
        #. $self->_json->encode($extjs_model_code)

    $fh->write($json . "\n");
}


sub extjs_basemodel_to_file {
    my ( $self, $dirname ) = @_;

    my $dir = Path::Class::Dir->new($dirname);
    $dir->open
        or die "$!: " . $dirname;

    my @namespaces = split( /\./, $self->model_baseclass );
    die "model base class '"
        . $namespaces[0]
        . "' doesn't match appname '"
        . $self->appname . "'"
        if $namespaces[0] ne $self->appname;

    my $basemodeldir = $dir->subdir( @namespaces[ 1 .. $#namespaces - 1 ] );
    $basemodeldir->mkpath;

    my $filename = $namespaces[-1] . '.js';
    my $file     = $basemodeldir->file($filename);
    my $fh       = $file->open( O_CREAT | O_WRONLY | O_EXCL )
    #my $fh       = $file->open( O_TRUNC | O_WRONLY | O_EXCL )
        or die "$!: $file";

    my $extjs_basemodel_code = {
        extend => 'Ext.data.Model',
        schema => {
            namespace => $self->model_namespace,
        },
    };

    my $json =
          "Ext.define('" . $self->model_baseclass . "', "
        . dump_javascript($extjs_basemodel_code) . ');';

    $fh->write($json . "\n");
    $fh->close
        or die "$!: " . $dirname;
}


sub extjs_all_to_file {
    my ( $self, $dirname ) = @_;

    # to check if the path exists and not fail for each source
    my $dh = Path::Class::Dir->new($dirname)->open
        or die "$!: $dirname";
    $dh->close
        or die "$!: $dirname";;

    my $schema = $self->schema;

    try {
        $self->extjs_basemodel_to_file($dirname);
    }
    catch {
        # ignore fails
    };

    $self->extjs_model_to_file( $_, $dirname ) for sort $schema->sources;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtJS::Generator::DBIC::Model - ExtJS model producer

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use ExtJS::Generator::DBIC::Model;

    my $generator = ExtJS::Generator::DBIC::Model->new(
        schemaname => 'My::DBIC::Schema',
        appname    => 'MyApp',

        # defaults to $appname.model
        model_namespace => 'MyApp.model',

        # defaults to $appname.data.Model
        model_baseclass => 'MyApp.data.Model',

        #model_args => {
        #    schema => 'schemaalias',
        #},
    );

    my $extjs_model_for_foo = $generator->extjs_model('Foo');

    my @extjs_models = $generator->extjs_models;

    $generator->extjs_model_to_file( 'Foo', '/my/dir/' );

    $generator->extjs_all_to_file( '/my/dir/' );

=head1 DESCRIPTION

Creates ExtJS model classes.

At the moment only version 6 of the ExtJS framework is supported.

=head1 ATTRIBUTES

=over

=item schemaname

The name of the L<DBIx::Class::Schema> which should be used to generate the
ExtJS model classes.

=item schema

A L<DBIx::Class::Schema> instance, automatically instantiated from the
L<schemaname> if not specified.

=item appname

The ExtJS app name used as base namespace for all generated classes.

=item model_namespace

The ExtJS model namespace, defaults to $appname.model.

=item model_baseclass

The ExtJS model baseclass name from which all generated model classes should
be extended.

=item model_args

Hashref which takes arbitrary ExtJS model attributes which are added to each
generated ExtJS model class..

=back

=head1 METHODS

=over

=item extjs_model_name

Returns the ExtJS model name for a table.
Should be overridden in a subclass if the default naming doesn't suit you.
E.g. MyApp::Schema::Result::ARTist -> MyApp.model.Artist

=item extjs_model_alias

Returns the ExtJS model alias for an ExtJS model returned from
L</extjs_model_name>.
Should be overridden in a subclass if the default naming doesn't suit you.
E.g. MyApp.model.Artist -> 'model.artist'

=item extjs_model_entityname

Returns the ExtJS model entityName for a full ExtJS classname.
E.g. MyApp.model.Foo -> Foo

=item extjs_model

This method returns an arrayref containing the parameters that can be
serialized to JavaScript and then passed to Ext.define for one
DBIx::Class::ResultSource.

=item extjs_models

This method returns the generated ExtJS model classes as hashref indexed by
their ExtJS names.

=item extjs_model_to_file

This method takes a single DBIx::Class::ResultSource name and a directory name
and outputs the generated ExtJS model class to a file according to ExtJS
naming standards.
An error is thrown if the directory doesn't exist or if the file already
exists.

=item extjs_basemodel_to_file

This method takes a directory name and outputs the generated ExtJS base model
class to a file according to ExtJS naming standards.

=item extjs_all_to_file

This method takes a root directory name and outputs all generated ExtJS
classes to a file per class according to ExtJS naming standards.

=back

=head1 SEE ALSO

F<http://docs.sencha.com/extjs/6.0/6.0.0-classic/#!/api/Ext.data.Model> for
ExtJS model documentation.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
