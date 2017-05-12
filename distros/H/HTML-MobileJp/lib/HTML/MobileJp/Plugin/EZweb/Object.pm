package HTML::MobileJp::Plugin::EZweb::Object;
use strict;
use warnings;
use base 'Exporter';
use Params::Validate;
use HTML::Entities;

our @EXPORT = qw/ezweb_object/;

sub _escape { encode_entities( $_[0], q{<>&"'} ) }

sub _param {
    sprintf q{<param name="%s" value="%s" valuetype="data" />},
      _escape( $_[0] ), _escape( $_[1] );
}

sub ezweb_object {
    validate(
        @_,
        +{
            url    => 1,
            mime_type   => 1,
            copyright   => { regex => qr{^(?:yes|no)$} },
            standby     => 0,
            disposition => { regex => qr{^dev.+$} },
            size        => { regex => qr{^[0-9]+$} },
            title       => 1,
        }
    );
    my %args = @_;

    my @ret;
    push @ret, sprintf(
        q{<object data="%s" type="%s" copyright="%s" standby="%s">},
        _escape( $args{url} ),
        _escape( $args{mime_type} ),
        _escape( $args{copyright} ),
        _escape( $args{standby} )
    );
    push @ret, map { _param($_, $args{$_}) } qw/disposition size title/;
    push @ret, "</object>";

    join("\n", @ret) . "\n";
}

1;
__END__

=for stopwords mobile-jp html TODO CGI ezweb

=encoding utf8

=head1 NAME

HTML::MobileJp::Plugin::EZweb::Object - generate object object download HTML tag.

=head1 SYNOPSIS

    use HTML::MobileJp;
    ezweb_object(
        url         => 'http://aa.com/movie.amc',
        mime_type   => 'application/x-mpeg',
        copyright   => 'no',
        standby     => 'ダウンロード',
        disposition => 'devdl1q',
        size        => '119065',
        title       => 'サンプル動画',
    );
    # =>
    #   <object data="http://aa.com/movie.amc" type="application/x-mpeg" copyright="no" standby="ダウンロード">
    #   <param name="disposition" value="devdl1q" valuetype="data" />
    #   <param name="size" value="119065" valuetype="data" />
    #   <param name="title" value="サンプル動画" valuetype="data" />
    #   </object>

=head1 DESCRIPTION

generate object download HTML tag.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom aaaatttt gmail dotottto commmmmE<gt>

=head1 SEE ALSO

L<HTML::MobileJp>, L<http://www.au.kddi.com/ezfactory/tec/spec/wap_tag5.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
