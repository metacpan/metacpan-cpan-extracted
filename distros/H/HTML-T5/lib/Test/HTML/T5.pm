package Test::HTML::T5;

use 5.010001;
use warnings;
use strict;

use Test::Builder;
use Exporter;

use HTML::T5 ();

use parent 'Exporter';

our @EXPORT_OK = qw(
    html_tidy_ok
    html_fragment_tidy_ok
);

our @EXPORT = @EXPORT_OK;

=head1 NAME

Test::HTML::T5 - Test::More-style wrapper around HTML::T5

=head1 VERSION

Version 0.007

=cut

our $VERSION = '0.007';

my $TB = Test::Builder->new;

=head1 SYNOPSIS

    use Test::HTML::T5 tests => 4;

    my $table = build_display_table();
    html_tidy_ok( $table, 'Built display table properly' );

=head1 DESCRIPTION

This module provides a few convenience methods for testing exception
based code. It is built with L<Test::Builder> and plays happily with
L<Test::More> and friends.

If you are not already familiar with L<Test::More> now would be the time
to go take a look.

=head1 EXPORT

C<html_tidy_ok>

=cut

sub import
{
    my $self = shift;
    my $pack = caller;

    $TB->exported_to($pack);
    $TB->plan(@_);

    $self->export_to_level( 1, $self, @EXPORT );

    return;
}

=head2 html_tidy_ok( [$tidy, ] $html, $name )

Checks to see if C<$html> is a valid HTML document.

If you pass an HTML::T5 object, C<html_tidy_ok()> will use that for its
settings.

    my $tidy = HTML::T5->new( {config_file => 'path/to/config'} );
    $tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );
    html_tidy_ok( $tidy, $content, "Web page is OK, ignoring warnings and info' );

Otherwise, it will use the default rules.

    html_tidy_ok( $content, "Web page passes ALL tests" );

=cut

sub html_tidy_ok
{
    my $tidy = ( ref( $_[0] ) eq 'HTML::T5' ) ? shift : HTML::T5->new;
    my $html = shift;
    my $name = shift;

    my $ok = defined $html;
    if ( !$ok )
    {
        $TB->ok( 0, $name );
        $TB->diag('Error: html_tidy_ok() got undef');
    }
    else
    {
        $ok = _parse_and_complain( $tidy, $html, $name, 0 );
    }

    return $ok;
}

=head2 html_fragment_tidy_ok( [$tidy, ] $html, $name )

Works the same as C<html_tidy_ok>, but first wraps it up an HTML document.
This is useful for when want to validate self-contained snippets of HTML,
such as from templates or an HTML feed from a third party, and check
that it is valid.

=cut

sub html_fragment_tidy_ok
{
    my $tidy = ( ref( $_[0] ) eq 'HTML::T5' ) ? shift : HTML::T5->new;
    my $html = shift;
    my $name = shift;

    my $ok = defined $html;
    if ( !$ok )
    {
        $TB->ok( 0, $name );
        $TB->diag('Error: html_fragment_tidy_ok() got undef');
    }
    else
    {
        $html = <<"HTML";
<!DOCTYPE html>
<html>
    <head>
        <title> </title>
    </head>
    <body>
$html
    </body>
</html>
HTML

        $ok = _parse_and_complain( $tidy, $html, $name, 6 );
    }

    return $ok;
}

sub _parse_and_complain
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tidy   = shift;
    my $html   = shift;
    my $name   = shift;
    my $offset = shift;

    $tidy->clear_messages();
    $tidy->parse( undef, $html );

    my @messages  = $tidy->messages;
    my $nmessages = @messages;

    my $ok = !$nmessages;
    $TB->ok( $ok, $name );
    if ( !$ok )
    {
        if ($offset)
        {
            $_->{_line} -= $offset for @messages;
        }
        my $msg = 'Errors:';
        $msg .= " $name" if $name;
        $TB->diag($msg);
        $TB->diag( $_->as_string ) for @messages;
        my $s = $nmessages == 1 ? '' : 's';
        $TB->diag("$nmessages message$s on the page");
    }

    return $ok;
}

=head1 BUGS

All bugs and requests are now being handled through GitHub.

    https://github.com/petdance/html-lint/issues

DO NOT send bug reports to http://rt.cpan.org/.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2018 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

http://www.opensource.org/licenses/Artistic-2.0

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<andy@petdance.com>

=cut

1;
