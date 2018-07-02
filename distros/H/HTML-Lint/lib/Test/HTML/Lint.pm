package Test::HTML::Lint;

use warnings;
use strict;

use Test::Builder;
use Exporter;

use HTML::Lint;

use vars qw( @ISA $VERSION @EXPORT );

@ISA = qw( HTML::Parser Exporter );

=head1 NAME

Test::HTML::Lint - Test::More-style wrapper around HTML::Lint

=head1 VERSION

Version 2.32

=cut

$VERSION = '2.32';

my $Tester = Test::Builder->new;

=head1 SYNOPSIS

    use Test::HTML::Lint tests => 4;

    my $table = build_display_table();
    html_ok( $table, 'Built display table properly' );

=head1 DESCRIPTION

This module provides a few convenience methods for testing exception
based code. It is built with L<Test::Builder> and plays happily with
L<Test::More> and friends.

If you are not already familiar with L<Test::More> now would be the time
to go take a look.

=head1 EXPORT

C<html_ok>

=cut

@EXPORT = qw(
    html_ok
    html_fragment_ok
);

sub import {
    my $self = shift;
    my $pack = caller;

    $Tester->exported_to($pack);
    $Tester->plan(@_);

    $self->export_to_level(1, $self, @EXPORT);

    return;
}

=head2 html_ok( [$lint, ] $html, $name )

Checks to see if C<$html> is a valid HTML document, including checks
for having C<< <html> >>, C<< <head> >>, C<< <title>> >> and
C<< <body> >> tags.

If you're checking something that is only a fragment of an HTML document,
use C<html_fragment_ok()>.

If you pass an HTML::Lint object, C<html_ok()> will use that for its
settings.

    my $lint = new HTML::Lint( only_types => STRUCTURE );
    html_ok( $lint, $content, "Web page passes structural tests only" );

Otherwise, it will use the default rules.

    html_ok( $content, "Web page passes ALL tests" );

Note that if you pass in your own HTML::Lint object, C<html_ok()>
will clear its errors before using it.

=cut

sub html_ok {
    my $lint;

    if ( ref($_[0]) eq 'HTML::Lint' ) {
        $lint = shift;
        $lint->newfile();
        $lint->clear_errors();
    }
    else {
        $lint = HTML::Lint->new;
    }
    my $html = shift;
    my $name = shift;

    my $ok = defined $html;
    if ( !$ok ) {
        $Tester->ok( 0, $name );
    }
    else {
        $lint->parse( $html );
        $lint->eof();
        my $nerr = scalar $lint->errors;
        $ok = !$nerr;
        $Tester->ok( $ok, $name );
        if ( !$ok ) {
            my $msg = 'Errors:';
            $msg .= " $name" if $name;
            $Tester->diag( $msg );
            $Tester->diag( $_->as_string ) for $lint->errors;
        }
    }

    return $ok;
}


=head2 html_fragment_ok( [$lint, ] $html, $name )

Checks that C<$fragment> is valid HTML, but not necessarily a valid
HTML document.

For example, this is a valid fragment, but not a valid HTML document:

    <body>
        <p>Lorem ipsum</p>
    </body>

because it doesn't contain C<< <html> >> and C<< <head> >> tags.  If you
want to check that it is a valid document, use C<html_ok()>.

If you pass an HTML::Lint object, C<html_fragment_ok()> will use that for its
settings.

    my $lint = new HTML::Lint( only_types => STRUCTURE );
    html_fragment_ok( $lint, $content, 'Web page passes structural tests only' );

Otherwise, it will use the default rules.

    html_fragment_ok( $content, 'Fragment passes ALL tests' );

Note that if you pass in your own HTML::Lint object, C<html_fragment_ok()>
will clear its errors before using it.

=cut

sub html_fragment_ok {
    my $lint;

    if ( ref($_[0]) eq 'HTML::Lint' ) {
        $lint = shift;
        $lint->newfile();
        $lint->clear_errors();
    }
    else {
        $lint = HTML::Lint->new;
    }
    my $html = shift;
    my $name = shift;

    my $ok = defined $html;
    if ( !$ok ) {
        $Tester->ok( 0, $name );
    }
    else {
        $lint->parse( $html );
        $lint->eof();

        # Ignore doc-level errors.
        my @errors = grep { $_->errcode ne 'doc-tag-required' } $lint->errors;

        my $nerr = @errors;
        $ok = !$nerr;
        $Tester->ok( $ok, $name );
        if ( !$ok ) {
            my $msg = 'Errors:';
            $msg .= " $name" if $name;
            $Tester->diag( $msg );
            $Tester->diag( $_->as_string ) for @errors;
        }
    }

    return $ok;
}


=head1 BUGS

All bugs and requests are now being handled through GitHub.

    https://github.com/petdance/html-lint/issues

DO NOT send bug reports to http://rt.cpan.org/.


=head1 TO DO

There needs to be a C<html_table_ok()> to check that the HTML is a
self-contained, well-formed table, and then a comparable one for
C<html_page_ok()>.

If you think this module should do something that it doesn't do at the
moment please let me know.

=head1 ACKNOWLEDGEMENTS

Thanks to chromatic and Michael G Schwern for the excellent Test::Builder,
without which this module wouldn't be possible.

Thanks to Adrian Howard for writing Test::Exception, from which most of
this module is taken.

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
