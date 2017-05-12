use strictures 2;

package HTTP::Link;

# ABSTRACT: RFC5988 Web Linking

use Exporter qw(import);

use MIME::EcoEncode::Param qw(mime_eco_param mime_deco_param);

our $VERSION = '0.001';    # VERSION

our @EXPORT_OK = qw(
  httplink_new
  httplink_rel
  httplink_multi
  httplink_parse
  httplink_parse_hash
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

sub _encode {
    my $str  = shift;
    my $estr = '=' . $str;
    my $xstr = mime_eco_param( $estr, 'UTF-8?B', '', 2**31 );
    if ( $estr eq $xstr ) {
        return '="' . $str . '"';
    }
    else {
        return '*' . $xstr;
    }
}

sub httplink_new {
    unshift @_ => __PACKAGE__;
    goto &new;
}

sub httplink_rel {
    unshift @_ => __PACKAGE__;
    goto &rel;
}

sub httplink_multi {
    unshift @_ => __PACKAGE__;
    goto &multi;
}

sub httplink_parse {
    unshift @_ => __PACKAGE__;
    goto &parse;
}

sub httplink_parse_hash {
    unshift @_ => __PACKAGE__;
    goto &parse_hash;
}

sub new {
    my $self = shift;
    my ( $iri, %options ) = @_;
    my $str = "<$iri>";
    if ( my $relation = delete $options{relation} ) {
        if ( ref $relation eq 'ARRAY' ) {
            $str .= '; rel="' . join( ' ', @$relation ) . '"';
        }
        else {
            if ( my $extension = delete $options{extension} ) {
                $relation .= " $extension";
            }
            $str .= '; rel="' . $relation . '"';
        }
    }
    if ( my $anchor = delete $options{anchor} ) {
        $str .= '; anchor="' . $anchor . '"';
    }
    if ( my $hreflang = delete $options{hreflang} ) {
        $str .= '; hreflang="' . $hreflang . '"';
    }
    if ( my $media = delete $options{media} ) {
        $str .= '; media="' . $media . '"';
    }
    if ( my $title = delete $options{title} ) {
        $str .= '; title' . _encode($title);
    }
    if ( my $type = delete $options{type} ) {
        $str .= '; type="' . $type . '"';
    }
    return $str;
}

sub rel {
    my ( $self, $iri, $relation, $extension, %options ) = @_;
    return $self->new(
        $iri,
        %options,
        relation  => $relation,
        extension => $extension
    );
}

sub multi {
    my $self = shift;
    if ( @_ == 1 and ref $_[0] eq 'HASH' ) {
        return $self->multi( %{ $_[0] } );
    }
    my %map = @_;
    my @str;
    foreach my $iri ( keys %map ) {
        my $part = delete $map{$iri};
        push @str => $self->new( $iri, %$part );
    }
    return join ', ', sort @str;
}

my $ptoken = qr{[
    \!\#\$\%\&\'\(\)\*\+\-\.\/\d\:\<\=\>\?\@\[\]\^\_\`\{\|\}\~
    a-z
]+}xsi;
my $lparam = qr{ = (?: " [^"]*? " | $ptoken ) }sx;
my $split  = qr{ \s* = \s* (?<quot>"?) \s* (?<val> .* ) \s* \k<quot> \s* }sx;
my $re     = qr{
    < (?<iri> [^>]+ ) >
    (?:
        \s*
        ;[\s*;]*
        \s*
        (?:
            rel (?<relation> $lparam )
        |
            anchor (?<anchor> $lparam )
        |
            rev (?<rev> $lparam )
        |
            hreflang (?<hreflang> $lparam )
        |
            media (?<media> $lparam )
        |
            title (?<title> $lparam )
        |
            title\* (?<xtitle> $lparam )
        |
            type (?<type> $lparam )
        )
        \s*
    )*
    [\s*;]*
}sx;

sub parse {
    my ( $self, $str ) = @_;
    $str .= ',';
    pos($str) = 0;
    my @results;
    while ( $str =~ m{ \G \s* $re \s* ,+ }sxg ) {
        my %r = %+;
        my $r = {};
        foreach my $k (qw(iri relation rev anchor hreflang media title type)) {
            next unless defined $r{$k};
            my $v = $r{$k};
            $v =~ s{^$split$}{$+{val}}sxe;
            $r->{$k} = $v;
        }
        if (
            defined $r->{relation}
            and $r->{relation} =~ m{^
            ( [a-z] [a-z\d\.\-]* ) \s+ (.+)
        $}six
          )
        {
            $r->{relation}  = $1;
            $r->{extension} = $2;
        }
        if ( exists $r{xtitle} ) {
            my ( $decoded, $param, $charset, $lang, $value ) =
              mime_deco_param( $r{xtitle} );
            $r->{title} = $value;
        }
        push @results => $r;
    }
    return @results;
}

sub parse_hash {
    my ( $self, $str ) = @_;
    my @list = $self->parse($str);
    my %hash;
    foreach my $elem (@list) {
        my $iri = delete $elem->{iri};
        $hash{$iri} = $elem;
    }
    return %hash;
}

1;

__END__

=pod

=head1 NAME

HTTP::Link - RFC5988 Web Linking

=head1 VERSION

version 0.001

=head1 METHODS

=head2 new

Return a new Web Link as string

    my $link = HTTP::Link->new('/TheBook/Chapter/2',
        relation => 'next',
        title => 'next chapter',
    );
    # Result:
    # </TheBook/Chapter/2>; rel="next"; title="next chapter"

B<Arguments>:

=over 4

=item * C<$iri> An internationalized resource identifier. This is a target uri
reference.

=item * C<%options> Additional parameters (see below)

=back

B<Parameters> for C<%options>:

=over 4

=item * C<relation>

Possible relation types are:
I<alternate>, I<appendix>, I<bookmark>, I<chapter>, I<contents>, I<copyright>,
I<current>, I<describedby>, I<edit>, I<edit-media>, I<enclosure>, I<first>,
I<glossary>, I<help>, I<hub>, I<index>, I<last>, I<latest-version>, I<license>,
I<next>, I<next-archive>, I<payment>, I<prev>, I<predecessor-version>,
I<previous>, I<prev-archive>, I<related>, I<replies>, I<section>, I<self>,
I<service>, I<start>, I<stylesheet>, I<subsection>, I<successor-version>,
I<up>, I<version-history>, I<via>, I<working-copy>, I<working-copy-of> and
others (see IANA registry)

=item * C<extension>

An extension for a relation type.

=item * C<anchor>

An anchor for the context IRI.

=item * C<hreflang>

A hint indicating what the language of the destination's content is

=item * C<media>

Intended destination medium, like in a CSS media query.

=item * C<title>

A human-readable label. This will be encoded with L<MIME::EcoEncode>.

=item * C<type>

A hint indication the most possible MIME type of the destination's content.

=back

=head2 rel

Shortcut method for L</new> with a different signature:

    HTTP::Link->rel('/TheBook/Chapter/2',
        start => '/TheBook/Chapter/0'
    );
    # same as
    HTTP::Link->new('/TheBook/Chapter/2',
        relation => 'start',
        extension => '/TheBook/Chapter/0',
    );

B<Arguments>:

=over 4

=item * C<$iri>

See L</new>

=item * C<$relation>

Will appended to C<%options> by C< relation => $relation >>

=item * C<$extension>

Will appended to C<%options> by C< extension => $extension >>

=item * C<%options>

See L</new>

=back

=head2 multi

When more than one link should be provides, this method is useful. It accepts
a hash or a HashRef with a mapping of IRIs to options.

    HTTP::Link->multi(
        '/TheBook/Chapter/2' => {
            relation => 'previous'
        },
        '/TheBook/Chapter/4' => {
            relation => 'next'
        },
    );
    # Result:
    # </TheBook/Chapter/2>; rel="previous", </TheBook/Chapter/4>; rel="next"

=head2 parse

Parses a Link-header field a returns all founded links as a list of HashRefs.

    my @links = HTTP::Link->parse(<<EOT);
    </TheBook/Chapter/2>; rel="previous", </TheBook/Chapter/4>; rel="next"
    EOT
    # Result:
    @links = ({
        iri => '/TheBook/Chapter/2',
        relation => 'previous'
    },{
        iri => '/TheBook/Chapter/4',
        relation => 'next'
    });

=head2 parse_hash

Parses a Link-header field a returns all founded links as a HashRef with IRIs
as key:

    my %links = HTTP::Link->parse_hash(<<EOT);
    </TheBook/Chapter/2>; rel="previous", </TheBook/Chapter/4>; rel="next"
    EOT
    # Result:
    %links = (
        '/TheBook/Chapter/2' => {
            relation => 'previous'
        },
        '/TheBook/Chapter/4' => {
            relation => 'next'
        }
    );

=head1 FUNCTIONS

=head2 httplink_new

Wrapper for C<< HTTP::Link-> >>L</new>

=head2 httplink_rel

Wrapper for C<< HTTP::Link-> >>L</rel>

=head2 httplink_multi

Wrapper for C<< HTTP::Link-> >>L</multi>

=head2 httplink_parse

Wrapper for C<< HTTP::Link-> >>L</parse>

=head2 httplink_parse_hash

Wrapper for C<< HTTP::Link-> >>L</parse_hash>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libhttp-link-perl/issues

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
