package Email::MIME::MobileJP::Template;
use strict;
use warnings;
use utf8;

use Tiffany;
use Email::MIME::MobileJP::Creator;

sub new {
    my ( $class, $name, $args ) = @_;
    my $tiffany = Tiffany->load( $name, $args );
    return bless { tiffany => $tiffany }, $class;
}

sub render {
    my ( $self, $to, $tmpl, @args ) = @_;
    Carp::croak('Usage: $tmpl->render($to, $tmpl[, @args])') unless defined $tmpl;

    my $creator = Email::MIME::MobileJP::Creator->new($to);

    my @lines = split /\n/, $self->{tiffany}->render( $tmpl, @args );
    while ( @lines > 0 && $lines[0] =~ /^([A-Z][A-Za-z_-]+)\s*:\s*(.+?)$/ ) {
        my ( $key, $val ) = ( $1, $2 );
        $creator->header($key, $val);
        shift @lines;
    }
    if ( @lines > 0 && $lines[0] =~ /^\s*$/ ) {
        shift @lines;
    }
    $creator->body( join( "\n", @lines) );

    return $creator->finalize();
}

1;
__END__

=encoding utf8

=head1 NAME

Email::MIME::MobileJP::Template - 日本語でメールを送信するときに楽するライブラリ

=head1 SYNOPSIS

    use Email::MIME::MobileJP::Template;
    use Email::Sender::Simple;

    my $estj = Email::MIME::MobileJP::Template->new(
        'Text::Xslate' => {
            syntax => 'TTerse',
            path   => ['./email_tmpl/'],
        },
    );
    my $email = $estj->render('foo.eml', {token => $token});
    Email::Sender::Simple->send($email);

=head1 DESCRIPTION

日本語でメールを送信するときにつかうライブラリです。テンプレートファイルを元に、任意のテンプレートエンジンを使用し、メールを作成します。

テンプレートファイルには

    Subject: [% name %]様へお特な情報のご案内

    おとくですよ！
    http://example.com[% path_info %]

のようにかくことができます。

最初のヘッダ行はなくてもかまいません。

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
