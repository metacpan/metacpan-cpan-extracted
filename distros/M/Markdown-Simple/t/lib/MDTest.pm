package MDTest;
use strict;
use warnings;
use Markdown::Simple ();
use Test::More;
use Exporter qw/import/;
our @EXPORT = qw/md_is md_like md_unlike strip_is strip_like/;

# Convenience wrappers so tests read tighter.

sub md_is ($$;$$) {
    my ( $src, $want, $name, $opts ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( Markdown::Simple::markdown_to_html( $src, (defined $opts ? $opts : ()) ),
        $want, $name );
}

sub md_like ($$;$$) {
    my ( $src, $re, $name, $opts ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like( Markdown::Simple::markdown_to_html( $src, (defined $opts ? $opts : ()) ),
        $re, $name );
}

sub md_unlike ($$;$$) {
    my ( $src, $re, $name, $opts ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    unlike( Markdown::Simple::markdown_to_html( $src, (defined $opts ? $opts : ()) ),
        $re, $name );
}

sub strip_is ($$;$) {
    my ( $src, $want, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( Markdown::Simple::strip_markdown($src), $want, $name );
}

sub strip_like ($$;$) {
    my ( $src, $re, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like( Markdown::Simple::strip_markdown($src), $re, $name );
}

1;
