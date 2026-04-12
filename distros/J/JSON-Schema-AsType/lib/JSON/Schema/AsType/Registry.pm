package JSON::Schema::AsType::Registry;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Registry::VERSION = '1.0.0';
# ABSTRACT: Schema registry for JSON::Schema::AsType


use 5.42.0;
use warnings;

use feature 'signatures';

use Test::Deep::NoTest qw( eq_deeply );
use JSON::Pointer      ();
use JSON               qw( from_json );
use LWP::Simple        ();
use Module::Runtime    qw( use_module );
use Ref::Util          qw( is_hashref );

use Moose::Role;

has registry => (
    is      => 'ro',
    lazy    => 1,
    default => sub { +{} },
    traits  => ['Hash'],
    handles => {},
);

has fetch_remote => (
    is      => 'ro',
    default => 1,
);

sub all_schema_uris($self) {
    return sort keys $self->registry->%*;
}

sub register_schema {

    # TODO Use a type instead to coerce into canonical
    my ( $self, $uri, $schema ) = @_;

    $uri        = URI->new($uri)->canonical;

    if ( my $already = $self->registered_schema($uri) ) {
        my $s = $schema;
        $s = $s->schema if $s isa JSON::Schema::AsType;
        return $already if eq_deeply( $s, $already->schema );
        use DDP;
        p [ $s, $already->schema ]->@*;
        die "schema $uri already registered for a different schema\n";
    }

    unless ( $schema isa JSON::Schema::AsType ) {

        # TODO for Draft4
        $schema = $self->sub_schema( $schema, $uri );
    }

    $self->registry->{$uri} = $schema;
}

sub merge_register( $self, $other ) {
    for my ( $url, $schema ) ( $other->registry->%* ) {
        $self->register_schema( $url, $schema );
    }
}

sub registered_schema( $self, $uri ) {
    $uri = URI->new($uri)->canonical;
    return $self->registry->{$uri};
}

sub fetch {
    my ( $self, $url ) = @_;

    $DB::single = 1;

    $url = $self->resolve_uri( $url, $self->uri );

    # # is it one of the spec schemas?
    # if ( $url =~ qr[^https?://json-schema.org/draft-0?(\d+)/schema] ) {

    # 	# TODO get the metaschema
    # 	my $module = 'JSON::Schema::AsType::Draft' . $1
    # 	use_module($module)->metaschema;
    # }

    # urgh...
    $url->scheme("https")
      if $url->can('host')
      and $url->host eq 'json-schema.org';

    #    $url->fragment( $fragment =~ s[/+$][]r ) if $fragment;

    if ( my $schema = $self->registered_schema($url) ) {
        return $schema;
    }

    my $root_uri = $url->clone;
    $root_uri->fragment(undef);

    my $schema = $self->registered_schema($root_uri);

    if ($schema) {
        my $fragment = $url->fragment;

        #        $fragment =~ s#/+$##;
        $url->fragment(undef);
        my ( $s, $jp_url ) =
          $self->resolve_json_pointer( $schema->schema, $fragment, $url );
        unless ( $s or ref $s eq 'JSON::PP::Boolean' ) {
            die "reference #" . $fragment . ' not found';
        }

        return $self->register_schema( $jp_url => $s );
    }

    if (    $root_uri->host eq 'json-schema.org'
        and $root_uri->path eq '/v1' ) {

        # TODO
        return $self->new(
            schema => {},
            uri    => 'https://json-schema.org/v1'
        );
    }

    if (    $root_uri->host eq 'json-schema.org'
        and $root_uri->path =~ m#/draft(?:-0?|/)([\d-]+)/schema$# ) {
        my $module = 'JSON::Schema::AsType::Draft' . $1 =~ s/-/_/r;
        my $ms     = use_module($module)->_metaschema;
        $self->merge_register($ms);
        goto __SUB__;
    }

    die "fetching remote schemas disabled, can't retrieve $url\n"
      unless $self->fetch_remote;

    $schema = eval { from_json LWP::Simple::get($url) };

    die "couldn't get schema from '$url'\n" unless ref $schema eq 'HASH';

    return $self->register_schema(
        $url => $self->new( uri => $url, schema => $schema ) );
}

sub resolve_json_pointer( $self, $schema, $pointer, $url ) {

    $url = $self->resolve_uri( $self->_has_id($schema), $url )
      if $self->_has_id($schema);

    $pointer =~ s[^/][];

    my @path_entries = split '/', $pointer;
    push @path_entries, '' if $pointer =~ m#/.*/$#;
    for my $path (@path_entries) {
        $path = $self->_unescape_ref($path);

        $schema = is_hashref($schema) ? $schema->{$path} : $schema->[$path];

        die "reference " . $url . "#$pointer not found\n"
          unless defined $schema;

        $path = $self->_escape_ref($path);

        $url =
          $self->resolve_uri( $self->_has_id($schema) // "#./$path", $url );
    }

    return ( $schema, $url );

}

sub resolve_uri( $self, $uri, $base = undef ) {
    return _resolve_uri( $uri, $base // $self->uri );
}

sub _resolve_uri {
    my ( $uri, $base ) = @_;
    $uri  = URI->new($uri);
    $base = URI->new($base);

    return $uri unless $base;

    my $result;
    if ( $base isa 'URI::urn' ) {
        return URI->new($uri)->canonical if $uri !~ /^#/;
        $result = $base->clone;
        $result->fragment( $uri =~ s/^#//r );
        return $result;
    }

    $result = URI->new($uri)->abs($base)->canonical;

    # let's look at those fragments
    my $uri_doc = $uri->clone;
    $uri_doc->fragment(undef);
    my $base_doc = $base->clone;
    $base_doc->fragment(undef);

    if ( !"$uri_doc" or $uri_doc->eq($base_doc) ) {
        no warnings qw/ uninitialized /;
        my $fragment = $uri->fragment;

        if ( $fragment =~ m[^\.] ) {
            my $base_fragment = $base->fragment;
            $base_fragment .= '/' unless m[/$];

            my $path = URI->new($fragment);
            $path = $path->abs($base_fragment) if $base_fragment;
            $path = $path->canonical;

            $result->fragment($path) unless $path eq '/';
        }
        else {
            $result->fragment( $fragment || undef );
        }

    }
    else {
        # not the same documents? fragment stays the same
        no warnings 'uninitialized';
        $result->fragment( $uri->fragment || undef );
    }

    return $result;

}

sub _unescape_ref {
    my ( $self, $ref ) = @_;

    $ref =~ s/~0/~/g;
    $ref =~ s!~1!/!g;
    $ref =~ s!%25!%!g;

    $ref;
}

sub _escape_ref {
    my ( $self, $ref ) = @_;

    $ref =~ s/~/~0/g;
    $ref =~ s!/!~1!g;
    $ref =~ s!%!%25!g;

    $ref;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Registry - Schema registry for JSON::Schema::AsType

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
