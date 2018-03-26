package Dezi::Lucy::Indexer;
use Moose;
extends 'Dezi::Indexer';

use Dezi::Lucy::InvIndex;

use Lucy::Index::Indexer;
use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Plan::StringType;
use Lucy::Analysis::PolyAnalyzer;

use Carp;
use SWISH::3 qw( :constants );
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );
use Search::Tools::UTF8;
use Path::Class::File::Lockable;
use Sys::Hostname qw( hostname );
use Digest::MD5 ();

our $VERSION = '0.015';

has 'highlightable_fields' =>
    ( is => 'rw', isa => 'Bool', default => sub {0} );

my $BUILT_IN_PROPS = SWISH_DOC_PROP_MAP();

=head1 NAME

Dezi::Lucy::Indexer - Dezi::App Apache Lucy indexer

=head1 SYNOPSIS

 use Dezi::Lucy::Indexer;
 my $indexer = Dezi::Lucy::Indexer->new(
    config               => Dezi::Indexer::Config->new(),
    invindex             => Dezi::Lucy::InvIndex->new(),
    highlightable_fields => 0,
 );

=head1 DESCRIPTION

Dezi::Lucy::Indexer is an Apache Lucy based indexer
class based on L<SWISH::3>.

=head1 CONSTANTS

All the L<SWISH::3> constants are imported into this namespace,
including:

=over

=item SWISH_DOC_PROP_MAP

=item SWISH_INDEX_STEMMER_LANG

=item SWISH_INDEX_NAME

=item SWISH_INDEX_FORMAT

=back

=head1 METHODS

Only new and overridden methods are documented here. See
the L<Dezi::Indexer> documentation.

=head2 BUILD

Implements basic object set up. Called internally by new().

In addition to the attributes documented in Dezi::Indexer,
this class implements the following attributes:

=over

=item highlightable_fields

Value should be 0 or 1. Default is 0. Passed directly to the
constructor for Lucy::Plan::FullTextField objects as the value
for the C<highlightable> option.

=back

=cut

sub BUILD {
    my $self = shift;

    # coerce our invindex into our format subclass
    unless ( $self->invindex->isa('Dezi::Lucy::InvIndex') ) {
        $self->invindex(
            Dezi::Lucy::InvIndex->new( path => $self->invindex->path ) );
    }

    $self->_build_lucy_delegates();
}

sub _build_lucy_delegates {
    my $self     = shift;
    my $s3config = $self->swish3->config;
    my $lang     = $s3config->get_index->get( SWISH_INDEX_STEMMER_LANG() )
        || 'none';
    $self->{_lang} = $lang;    # cache for finish()
    my $schema      = Lucy::Plan::Schema->new();
    my $analyzers   = {};
    my $case_folder = Lucy::Analysis::CaseFolder->new;
    my $tokenizer   = Lucy::Analysis::RegexTokenizer->new;
    my $multival_tokenizer
        = Lucy::Analysis::RegexTokenizer->new(
        pattern => '[^' . SWISH_TOKENPOS_BUMPER() . ']+' );

    # mimic StringType fields that require case and/or multival parsing.
    $analyzers->{store_lc} = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $multival_tokenizer, $case_folder ] );
    $analyzers->{store} = $multival_tokenizer;

    # stemming means we fold case and tokenize too.
    if ( $lang and $lang =~ m/^\w\w$/ ) {
        my $stemmer
            = Lucy::Analysis::SnowballStemmer->new( language => $lang );
        $analyzers->{fulltext_lc}
            = Lucy::Analysis::PolyAnalyzer->new( analyzers =>
                [ $multival_tokenizer, $case_folder, $tokenizer, $stemmer ] );
        $analyzers->{fulltext} = Lucy::Analysis::PolyAnalyzer->new(
            analyzers => [ $multival_tokenizer, $tokenizer, $stemmer ] );
    }
    else {
        $analyzers->{fulltext_lc}
            = Lucy::Analysis::PolyAnalyzer->new(
            analyzers => [ $multival_tokenizer, $case_folder, $tokenizer, ],
            );
        $analyzers->{fulltext} = Lucy::Analysis::PolyAnalyzer->new(
            analyzers => [ $multival_tokenizer, $tokenizer ] );
    }

    # cache our objects for later
    $self->{__lucy}->{analyzers} = $analyzers;
    $self->{__lucy}->{schema}    = $schema;

    # build the Lucy fields, which are a merger of MetaNames+PropertyNames
    my %fields;

    my $metanames     = $s3config->get_metanames;
    my $meta_keys     = $metanames->keys;
    my $properties    = $s3config->get_properties;
    my $property_keys = $properties->keys;

    # merge first by name so we pair correctly in _create_field_def()
    my %tmpfields;
    for my $name (@$meta_keys) {
        my $mn = $metanames->get($name);
        $tmpfields{$name}->{meta} = $mn;
    }
    for my $name (@$property_keys) {
        if ( exists $BUILT_IN_PROPS->{$name} ) {
            confess
                "$name is a built-in PropertyName and should not be defined in config";
        }
        my $pr = $properties->get($name);
        $tmpfields{$name}->{prop} = $pr;
    }

    # build out field definitions
    for my $n ( keys %tmpfields ) {
        my %fdef = $self->_create_field_def( $tmpfields{$n}->{meta},
            $tmpfields{$n}->{prop} );
        $fields{ $fdef{name} } = $fdef{def};
    }

    $self->{_fields} = \%fields;

    for my $name ( keys %fields ) {
        my $def = $fields{$name};
        my $key = $name;

        # if a field is purely an alias, skip it.
        if (    defined $def->{is_meta_alias}
            and defined $def->{is_prop_alias} )
        {
            $def->{store_as}->{ $def->{is_meta_alias} } = 1;
            $def->{store_as}->{ $def->{is_prop_alias} } = 1;
            next;
        }

        my $type = $self->_get_lucy_field_type($def) or next;

        $schema->spec_field( name => $name, type => $type );

        $def->{store_as}->{$name} = 1;
    }

    # build in the built-ins
    $self->debug and warn dump \%fields;

    for my $name ( keys %$BUILT_IN_PROPS ) {
        if ( exists $fields{$name} ) {
            my $def = $fields{$name};

            #carp "found $name in built-in props: " . dump($field);

            # in theory this should never happen.
            if ( !$def->{is_prop} ) {
                confess
                    "$name is a built-in PropertyName but not defined as a PropertyName in config";
            }
        }

        # default property
        else {
            $schema->spec_field(
                name => $name,
                type => Lucy::Plan::StringType->new( sortable => 1, )
            );
        }
    }

    #dump( \%fields );

    # TODO can pass lucy in? make 'lucy' attribute public?
    my $hostname = hostname() or confess "Can't get unique hostname";
    my $manager = Lucy::Index::IndexManager->new( host => $hostname );
    $self->{lucy} ||= Lucy::Index::Indexer->new(
        schema  => $schema,
        index   => $self->invindex->path . "",
        create  => 1,
        manager => $manager,
    );

}

sub _get_lucy_field_type {
    my ( $self, $def ) = @_;
    my ( $type, $key );
    my $analyzers = $self->{__lucy}->{analyzers};

    # MetaName==yes, PropertyName==no
    if ( $def->{is_meta} and !$def->{is_prop} ) {
        if ( defined $def->{is_meta_alias} ) {
            $key = $def->{is_meta_alias};
            $def->{store_as}->{$key} = 1;
            return;
        }

        #warn "spec meta $name";
        $type = Lucy::Plan::FullTextType->new(
            analyzer      => $analyzers->{fulltext_lc},
            stored        => 0,
            boost         => $def->{bias} || 1.0,
            highlightable => $self->highlightable_fields,
        );
    }

    # MetaName==yes, PropertyName==yes
    # this is the trickiest case, because the field
    # is both prop+meta and could be an alias for one
    # and a real for the other.
    # **NOTE** we must have already eliminated the case where
    # the field is an alias for both.
    elsif ( $def->{is_meta} and $def->{is_prop} ) {
        if ( defined $def->{is_meta_alias} ) {
            $key = $def->{is_meta_alias};
            $def->{store_as}->{$key} = 1;
        }
        elsif ( defined $def->{is_prop_alias} ) {
            $key = $def->{is_prop_alias};
            $def->{store_as}->{$key} = 1;
        }

        my $analyzer = $analyzers->{fulltext_lc};
        if ( !$def->{ignore_case} ) {
            $analyzer = $analyzers->{fulltext};
        }

        #warn "spec meta+prop $name";
        $type = Lucy::Plan::FullTextType->new(
            analyzer      => $analyzer,
            highlightable => $self->highlightable_fields,
            sortable      => $def->{sortable},
            boost         => $def->{bias} || 1.0,
        );
    }

    # MetaName==no, PropertyName==yes
    elsif (!$def->{is_meta}
        and $def->{is_prop} )
    {

        if ( defined $def->{is_prop_alias} ) {
            $key = $def->{is_prop_alias};
            $def->{store_as}->{$key} = 1;
            return;
        }

        #warn "spec prop !sort $name";
        my $analyzer_key = 'store';
        if ( $def->{ignore_case} ) {
            $analyzer_key = 'store_lc';
        }

        $type = Lucy::Plan::FullTextType->new(
            analyzer      => $analyzers->{$analyzer_key},
            highlightable => $self->highlightable_fields,
            sortable      => $def->{sortable},
            boost         => $def->{bias} || 1.0,
        );
    }

    $self->debug
        and warn
        sprintf( "field def %s => field type %s", dump($def), $type );

    return $type;

}

sub _create_field_def {
    my ( $self, $metaname, $propname ) = @_;
    if ( !$metaname and !$propname ) {
        confess "Must have one of metaname or propname objects";
    }
    my $name = $metaname ? $metaname->name : $propname->name;
    my %field_def = ();
    if ($metaname) {
        if ( $metaname->name ne $name ) {
            confess "Mismatched metaname for '$name': " . $metaname->name;
        }
        my $alias = $metaname->alias_for;
        $field_def{is_meta}           = 1;
        $field_def{is_meta_alias}     = $alias;
        $field_def{bias}              = $metaname->bias;
        $field_def{store_as}->{$name} = 1;

        # allow for aliases to built-ins
        if ( exists $BUILT_IN_PROPS->{$name} ) {
            $field_def{is_prop}  = 1;
            $field_def{sortable} = 1;
        }
    }
    if ($propname) {
        if ( $propname->name ne $name ) {
            confess "Mismatched propname for '$name'" . $propname->name;
        }
        my $prop_alias = $propname->alias_for;
        $field_def{is_prop}       = 1;
        $field_def{is_prop_alias} = $prop_alias;
        if ( $propname->sort ) {
            $field_def{sortable} = 1;
        }
        for my $attr (qw( ignore_case verbatim max )) {
            $field_def{$attr} = $propname->$attr;
        }
    }
    return ( name => $name, def => \%field_def );
}

sub _add_new_field {
    my ( $self, $metaname, $propname ) = @_;
    my $fields    = $self->{_fields};
    my %field_def = $self->_create_field_def( $metaname, $propname );
    my $name      = $field_def{name};
    my $def       = $field_def{def};
    $fields->{$name} ||= $def;
    $self->{__lucy}->{schema}->spec_field(
        name => $name,
        type => $self->_get_lucy_field_type($def),
    );
    return $def;
}

=head2 swish3_handler( I<swish3_data> )

Called by the SWISH::3::handler() function for every document being
indexed.

=cut

sub swish3_handler {
    my ( $self, $data ) = @_;
    my $config     = $data->config;
    my $conf_props = $config->get_properties;
    my $conf_metas = $config->get_metanames;

    # will hold all the parsed text, keyed by field name
    my %doc;
    my $docinfo = $data->doc;

    # Swish built-in fields first
    for my $propname ( keys %$BUILT_IN_PROPS ) {
        my $attr = $BUILT_IN_PROPS->{$propname};
        $doc{$propname} = [ $docinfo->$attr ];
    }

    # fields parsed from document
    my $props = $data->properties;
    my $metas = $data->metanames;

    # field def cache
    my $fields = $self->{_fields};

    # may need to add newly-discovered fields from $metas
    # that were added via UndefinedMetaTags e.g.
    for my $mname ( keys %$metas ) {
        if ( !exists $fields->{$mname} ) {

            #warn "New field: $mname\n";
            my $prop;
            if ( exists $props->{$mname} ) {
                $prop = $conf_props->get($mname);
            }
            $self->_add_new_field( $conf_metas->get($mname), $prop );
        }
    }

    #dump $fields;
    #dump $props;
    #dump $metas;
    for my $fname ( sort keys %$fields ) {
        my $field = $self->{_fields}->{$fname};
        next if $field->{is_prop_alias};
        next if $field->{is_meta_alias};

        my @keys = keys %{ $field->{store_as} };

        for my $key (@keys) {

            # prefer properties over metanames because
            # properties have verbatim flag, which affects
            # the stored whitespace.

            if ( $field->{is_prop} and !exists $BUILT_IN_PROPS->{$fname} ) {
                push( @{ $doc{$key} }, @{ $props->{$fname} } );
            }
            elsif ( $field->{is_meta} ) {
                push( @{ $doc{$key} }, @{ $metas->{$fname} } );
            }
            else {
                croak "field '$fname' is neither a PropertyName nor MetaName";
            }
        }
    }

    # serialize the doc with our tokenpos_bump char
    for my $k ( keys %doc ) {
        $doc{$k} = to_utf8( join( SWISH_TOKENPOS_BUMPER(), @{ $doc{$k} } ) );
    }

    $self->debug and carp dump \%doc;

    # make sure we delete any existing doc with same URI
    $self->{lucy}->delete_by_term(
        field => 'swishdocpath',
        term  => $doc{swishdocpath}
    );

    $self->{lucy}->add_doc( \%doc );
}

=head2 finish

Calls commit() on the internal Lucy::Indexer object,
writes the C<swish.xml> header file and calls the superclass finish()
method.

=cut

my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );

around finish => sub {
    my $super_method = shift;
    my $self         = shift;

    return 0 if $self->{_is_finished};

    my $doc_count = $self->_finish_lucy();
    $super_method->( $self, @_ );
    $self->{_is_finished} = 1;

    return $doc_count;
};

sub _finish_lucy {
    my $self = shift;

    # get a lock on our header file till
    # this entire transaction is complete.
    # Note that we trust the Lucy locking feature
    # to have prevented any other process
    # from getting a lock on the invindex itself,
    # but we want to make sure nothing interrupts
    # us from writing our own header after calling ->commit().
    my $invindex  = $self->invindex;
    my $header    = $invindex->header_file->stringify;
    my $lock_file = Path::Class::File::Lockable->new($header);
    if ( $lock_file->locked ) {
        croak "Lock file found on $header -- cannot commit indexing changes";
    }
    $lock_file->lock;

    # commit our changes
    $self->{lucy}->commit();

    # get total doc count
    my $polyreader = Lucy::Index::PolyReader->open( index => "$invindex", );
    my $doc_count = $polyreader->doc_count();

    # write header
    # the current config should contain any existing header + runtime config
    my $idx_cfg = $self->swish3->config->get_index;

    # poor man's uuid
    my $uuid = Digest::MD5::md5_hex(
        time() . join( "", @chars[ map { rand @chars } ( 1 .. 24 ) ] ) );

    $idx_cfg->set( SWISH_INDEX_NAME(),         "$invindex" );
    $idx_cfg->set( SWISH_INDEX_FORMAT(),       'Lucy' );
    $idx_cfg->set( SWISH_INDEX_STEMMER_LANG(), $self->{_lang} );
    $idx_cfg->set( 'DeziVersion',              $invindex->version );
    $idx_cfg->set( "DocCount",                 $doc_count );
    $idx_cfg->set( "UUID",                     $uuid );

    $self->swish3->config->write($header);

    # transaction complete
    $lock_file->unlock;

    $self->debug and carp "wrote $header with uuid $uuid";
    $self->debug and carp "$doc_count docs indexed";
    $self->swish3(undef);    # invalidate this indexer

    return $doc_count;
}

=head2 get_lucy

Returns the internal Lucy::Index::Indexer object.

=cut

sub get_lucy {
    return shift->{lucy};
}

=head2 abort

Sets the internal Lucy::Index::Indexer to undef,
which should release any locks on the index.
Also flags the Dezi::Lucy::Indexer object
as stale.

=cut

sub abort {
    my $self = shift;
    $self->{lucy}         = undef;
    $self->{_is_finished} = 1;
    $self->swish3(undef);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head2 MetaNames and PropertyNames

Some implementation notes about MetaNames and PropertyNames.
See also L<http://dezi.org/2014/07/18/metanames-and-propertynames/>.

=over

=item

A field defined as either a MetaName, PropertyName or both, can be searched.

=item

Fields are matched against tag names in your XML/HTML documents. See also the TagAlias, UndefinedMetaTags, UndefinedXMLAttributes, and XMLClassAttributes directives.

=item

You can alias field names with MetaNamesAlias and PropertyNamesAlias.

=item

MetaNames are tokenized and case-insensitive and (optionally, with FuzzyIndexingMode) stemmed.

=item

PropertyNames are stored, case-sensitive strings.

=item

If a field is defined as both a MetaName and PropertyName, then it will be tokenized.

=item

If a field is defined only as a MetaName, it will be parsed but not stored. That means you can search on the field but when you try and retrieve the field's value from the results, it will cause a fatal error.

=item

If a field is defined only as a PropertyName, it will be parsed and stored, but it will not be tokenized. That means the field's contents are stored without being split up into words.

=item

You can control the parsing and storage of PropertyName-only fields with the following additional directives:

=over

=item PropertyNamesCompareCase

case sensitive search

=item PropertyNamesIgnoreCase

case insensitive search (default)

=item PropertyNamesNoStripChars

preserve whitespace

=back

=item

There are two default MetaNames defined: swishdefault and swishtitle.

=item

There are two default PropertyNames defined: swishtitle and swishdescription.

=item

The libswish3 XML and HTML parsers will automatically treat a <title> tag as swishtitle. Likewise they will treat <body> tag as swishdescription.

=item

Things get complicated quickly when defining fields. Experiment with small test cases to arrive at the configuration that works best with your application.

=back

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::App

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

