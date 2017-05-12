use strictures 2;

package HTTP::Headers::Fancy;

use Exporter qw(import);
use Scalar::Util qw(blessed);

# ABSTRACT: Fancy naming schema of HTTP headers

our $VERSION = '1.001';    # VERSION

our @EXPORT_OK = qw(
  decode_key
  encode_key
  decode_hash
  encode_hash
  split_field_hash
  split_field_list
  build_field_hash
  build_field_list
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

sub _self {
    my @args = @_;
    if ( blessed $args[0] and $args[0]->isa(__PACKAGE__) ) {
        return @args;
    }
    elsif ( defined $args[0] and not ref $args[0] and $args[0] eq __PACKAGE__ )
    {
        return @args;
    }
    else {
        return ( __PACKAGE__, @args );
    }
}

sub _encode_hash_deeply {
    my ( $self, @args ) = _self(@_);
    if ( ref $args[0] ) {
        return { $self->_encode_hash_deeply( %{ $args[0] } ) };
    }
    my %hash = $self->encode_hash(@args);
    foreach my $key ( keys %hash ) {
        if ( ref $hash{$key} ) {
            $hash{$key} = $self->build( $hash{$key} );
        }
    }
    return %hash;
}

sub decode_key {
    my ( $self, $k ) = _self(@_);
    $k =~ s{^([^-]+)}{ucfirst(lc($1))}se;
    $k =~ s{-+([^-]+)}{ucfirst(lc($1))}sge;
    $k =~ s{^X([A-Z])}{-$1}s;
    return ucfirst($k);
}

sub decode_hash {
    my ( $self, @args ) = _self(@_);
    my %headers = @args == 1 ? %{ $args[0] } : @args;
    foreach my $old ( keys %headers ) {
        my $new = decode_key($old);
        if ( $old ne $new ) {
            $headers{$new} = delete $headers{$old};
        }
    }
    wantarray ? %headers : \%headers;
}

sub encode_key {
    my ( $self, $k ) = _self(@_);
    $k =~ s{_}{-}sg;
    $k =~ s{-+}{-}sg;
    $k =~ s{^-(.)}{'X'.uc($1)}se;
    $k =~ s{([^-])([A-Z])}{$1-$2}s while $k =~ m{([^-])([A-Z])}s;
    return lc($k);
}

sub encode_hash {
    my ( $self, @args ) = _self(@_);
    my %headers = @args == 1 ? %{ $args[0] } : @args;
    foreach my $old ( keys %headers ) {
        delete $headers{$old} unless defined $headers{$old};
        my $new = encode_key($old);
        if ( $old ne $new ) {
            $headers{$new} = delete $headers{$old};
        }
    }
    wantarray ? %headers : \%headers;
}

sub prettify_key {
    my ( $self, $k ) = _self(@_);
    $k = lc $k;
    $k =~ s{-+}{-}g;
    $k =~ s{(-)(.)}{$1.ucfirst($2)}eg;
    return ucfirst $k;
}

sub split_field_hash {
    my ( $self, $value, @rest ) = _self(@_);
    return () unless defined $value;
    if ( ref $value eq 'HASH' ) {
        foreach my $key (@rest) {
            $value->{$key} = { $self->split_field_hash( $value->{$key} ) };
        }
        return $value;
    }
    pos($value) = 0;
    my %data;
    $value .= ',';
    while ( $value =~
m{ \G \s* (?<key> [^=,]+? ) \s* (?: \s* = \s* (?: (?: " (?<value> [^"]*? ) " ) | (?<value> [^,]*? ) ) )? \s* ,+ \s* }gsx
      )
    {
        $data{ decode_key( $+{key} ) } = $+{value};
    }
    return %data;
}

sub split_field_list {
    my ( $self, $value, @rest ) = _self(@_);
    return () unless defined $value;
    if ( ref $value eq 'HASH' ) {
        foreach my $key (@rest) {
            $value->{$key} = [ $self->split_field_list( $value->{$key} ) ];
        }
        return $value;
    }
    pos($value) = 0;
    my @data;
    $value .= ',';
    while ( $value =~
        m{ \G \s* (?<weak> W/ )? " (?<value> [^"]*? ) " \s* ,+ \s* }gsix )
    {
        my $value = $+{value};
        push @data => $+{weak} ? \$value : $value;
    }
    return @data;
}

sub build_field_hash {
    my ( $self, @args ) = _self(@_);
    if ( ref $args[0] eq 'HASH' ) {
        return $self->build_field_hash( %{ $args[0] } );
    }
    my %data = @args;
    return join ', ', sort map {
        $self->encode_key($_)
          . (
            defined( $data{$_} )
            ? '='
              . (
                ( $data{$_} =~ m{[=,]} )
                ? '"' . $data{$_} . '"'
                : $data{$_}
              )
            : ''
          )
    } keys %data;
}

sub build_field_list {
    my ( $self, @args ) = _self(@_);
    if ( ref $args[0] eq 'ARRAY' ) {
        return $self->build_field_list( @{ $args[0] } );
    }
    return join ', ', map { ref($_) ? 'W/"' . $$_ . '"' : qq{"$_"} } @args;
}

sub new {
    my $class = shift // __PACKAGE__;
    return bless {@_} => ref $class || $class;
}

sub encode {
    my $self = shift;
    return unless @_;
    if ( @_ > 1 ) {
        return $self->_encode_hash_deeply(@_);
    }
    elsif ( ref $_[0] eq 'HASH' ) {
        return $self->_encode_hash_deeply( $_[0] );
    }
    else {
        return $self->encode_key( $_[0] );
    }
}

sub decode {
    my $self = shift;
    return unless @_;
    if ( @_ > 1 ) {
        return $self->decode_hash(@_);
    }
    elsif ( ref $_[0] eq 'HASH' ) {
        return $self->decode_hash( $_[0] );
    }
    else {
        return $self->decode_key( $_[0] );
    }
}

sub split {
    my $self = shift;
    return unless @_;
    my $val = shift;
    if ( $val =~ m{^ \s* ( W/ ) ? " }six ) {
        return $self->split_field_list($val);
    }
    elsif ( not ref $val ) {
        return $self->split_field_hash($val);
    }
    elsif ( ref $val eq 'HASH' ) {
        foreach my $key (@_) {
            next unless $val->{$key};
            if ( $val->{$key} =~ m{^ \s* ( W/ )? " }six ) {
                $val->{$key} = [ $self->split_field_list( $val->{$key} ) ];
            }
            else {
                $val->{$key} = { $self->split_field_hash( $val->{$key} ) };
            }
        }
        return $val;
    }
}

sub build {
    my $self = shift;
    if ( ref $_[0] eq 'HASH' ) {
        return $self->build_field_hash(@_);
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {
        return $self->build_field_list(@_);
    }
    else {
        return $self->build_field_hash(@_);
    }
}

sub etags {
    my $self = shift;
    return $self->build_field_list(@_);
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::Fancy - Fancy naming schema of HTTP headers

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    my %fancy = decode_hash('content-type' => ..., 'x-foo-bar-baf-baz' => ...);
    my $content_type = $fancy{ContentType};
    my $x_foo_bar_baf_baz = $fancy{-FooBarBafBaz};

    my %headers = encode_hash(ContentType => ..., -foo_bar => ...);
    # %headers = ('content-type' => ..., 'x-foo-bar' => ...);

=head1 DESCRIPTION

This module provides method for renaming HTTP header keys to a lightier, easier-to-use format.

=head1 METHODS

=head2 new

Creates a new instance of ourself. No options are supported.

    my $fancy = HTTP::Headers::Fancy->new;

=head2 encode

Wrapper for L</encode_hash> or L</encode_key>, depending on what is given.

    $fancy->encode(%hash)    # encode_hash(%hash);
    $fancy->encode($hashref) # encode_hash($hashref);
    $fancy->encode($scalar)  # encode_key($scalar);

=head2 decode

Wrapper for L</decode_hash> or L</decode_key>, depending on what is given

    $fancy->decode(%hash)    # decode_hash(%hash);
    $fancy->decode($hashref) # decode_hash($hashref);
    $fancy->decode($scalar)  # decode_key($scalar);

=head2 split

Wrapper for L</split_field_list> or L</split_field_hash>, depending on what is given

    $fancy->split(q{"a", "b", "c"}) # split_field_list(...)
    $fancy->split(q{W/"a", ...})    # split_field_list(...)
    $fancy->split(q{no-cache})      # split_field_hash(...)

Or deflate a HashRef directly:

    $headers = $fancy->decode(...);
    $fancy->split($headers, qw(CacheControl Etag));
    $headers->{CacheControl}->{NoCache};
    $headers->{Etag}->[0];

=head2 build

Wrapper for L</build_field_hash> or L</build_field_list>

    $fancy->build(NoCache => undef) # build_field_hash(...)
    $fancy->build({ ... }) # build_field_hash(...)
    $fancy->build([ ... ]) # build_field_list(...)

=head2 etags

Wrapper for L</build_field_list>

    $fancy->build('a', \'b', 'c') # build_field_list(...)

=head1 FUNCTIONS

=head2 decode_key

Decode original HTTP header name

    my $new = decode_key($old);

The header field name will be separated by the dash ('-') sign into pieces. Every piece will be lowercased and the first character uppercased. The pieces will be concatenated.

    # Original  ->  Fancy
    # Accept        Accept
    # accept        Accept
    # aCCEPT        Accept
    # Acc-Ept       AccEpt
    # Content-Type  ContentType
    # a-b-c         ABC
    # abc           Abc
    # a-bc          ABc
    # ab-c          AbC

Experimental headers starting with C<X-> will be accessable by a preleading dash sign:

    # Original  ->  Fancy
    # x-abc         -Abc

=head2 decode_hash

Decode a hash (or HashRef) of HTTP headers and rename the keys

    my %new_hash = decode_hash(%old_hash);
    my $new_hashref = decode_hash($old_hashref);

=head2 encode_key

Encode fancy key name to a valid HTTP header key name

    my $new = encode_key($old);

Any uppercase (if not at beginning) will be prepended with a dash sign. Underscores will be replaced by a dash-sign too. The result will be lowercased.

    # Fancy -> Original
    # FooBar   foo-bar
    # foo_bar  foo-bar
    # FoOoOoF  fo-oo-oo-f

Experimental headers starting with C<X-> are also createable with a preleading dash sign:

    # Fancy -> Original
    # -foo     x-foo

=head2 encode_hash

Encode a hash (or HashRef) of HTTP headers and rename the keys

Removes also a keypair if a value in undefined.

    my %new_hash = encode_hash(%old_hash);
    my $new_hashref = encode_hash($old_hashref);

=head2 prettify_key

Reformats a key with all lowercase and each part uppercase first.

    my $pretty_key = prettify_key('foo-bar');

Examples:

    # Unpretty  ->  Pretty
    # foo-bar       Foo-Bar
    # x-fooof       X-Fooof
    # ABC-DEF       Abc-Def

Since a HTTP header parser ignores the case, this is just for a nice human-readable output.

=head2 split_field_hash

Split a HTTP header field into a hash with decoding of keys

    my %cc = split_field('no-cache, s-maxage=5');
    # %cc = (NoCache => undef, SMaxage => 5);

Or deflate fields in a hashref directly:

    # First, get a fancy hashref of header fields;
    my $headers = decode_hash(...);
    # Second deflate the CacheControl field
    split_field_hash($headers, qw( CacheControl ));
    # Then access the fancy way
    $headers->{CacheControl}->{SMaxage};

The first argument has to be a hashref, all other argument a list of fields to be deflated by I<split_field_hash>

=head2 split_field_list

Split a field into pieces

    my @list = split_field('"a", "b", "c"');
    # @list = qw( a b c );

Weak values are stored as ScalarRef

    my @list = split_field('"a", W/"b"', W/"c"');
    # @list = ('a', \'b', \'c');

Or deflate fields in a hashref directly:

    # First, get a fancy hashref of header fields;
    my $headers = decode_hash(...);
    # Second deflate the Etag field
    split_field_list($headers, qw( Etag ));
    # Then access the fancy way
    $headers->{Etag}->[0];

The first argument has to be a hashref, all other argument a list of fields to be deflated by I<split_field_list>

=head2 build_field_hash

The opposite method of L</split_field_hash> with encoding of keys.

    my $field_value = build_field_hash(NoCache => undef, MaxAge => 3600);
    # $field_value = 'no-cache,maxage=3600'

An HashRef as first argument is interpreted as hash

    build_field_hash({ NoCache => undef })

=head2 build_field_list

Build a list from pieces

    my $field_value = build_field_list(qw( a b c ));
    # $field_value = '"a", "b", "c"'

ScalarRefs evaluates to a weak value

    my $field_value = build_field_list('a', \'b', \'c');
    # $field_value = '"a", W/"b", W/"c"';

An ArrayRef as first argument is interpreted as list

    build_field_list([ 'a', 'b', ... ])

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libhttp-headers-fancy-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
