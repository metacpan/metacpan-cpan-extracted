package JavaScript::V8x::TestMoreish;

use warnings;
use strict;

=head1 NAME

JavaScript::V8x::TestMoreish - Run and test JavaScript code in Perl using Test::More and v8

=head1 VERSION

Version 0.013

=cut

our $VERSION = '0.013';

=head1 SYNOPSIS

    use Test::More

    plan qw/no_plan/

    is( 1, 1 )

    use JavaScript::V8x::TestMoreish

    test_js( <<'_END_' )
    diag( "Hello, World." );
    areEqual( 1, 1 );
    areEqual( 1, 2 );
    like( "Hello, World.", /o, World/ )
	like( "Hello, World.", /Alice/ )
    _END_

=head1 DESCRIPTION

JavaScript::V8x::TestMoreish uses the Google V8 JavaScript engine (via L<JavaScript::V8>) to execute JavaScript code on demand in Perl. In addition, the customized context binds some functions that expose parts of Test::More to facillate testing.

An installation of C<libv8> (for L<JavaScript::V8>) is required.

You can interleave regular Test::More tests and JavaScript tests as usual.

=head1 JavaScript USAGE

=head2 diag( $message )

    "Print" $message as Test::More does with diag

=head2 areEqual( $got, $expected, $name )

    $got == $expected

=head2 like( $got, $match, $name )

    isValue( $got ) && isString( $got ) && $got.match( $match )

=head1 USAGE

=head2 test_js( $js )

Evaluate $js in a Test::More-ish context (see JavaScript USAGE for available functionality)

=cut

use Any::Moose;

use JavaScript::V8x::TestMoreish::JS;

use JavaScript::V8;
use Path::Abstract;
use Test::Builder();
use Sub::Exporter -setup => {
    exports => [
        test_js => sub { sub { local $Test::Builder::Level = $Test::Builder::Level + 2; return __test_js( @_ ) } },
        test_js_tester => sub { sub { return __test_js_tester( @_ ) } },
        test_js_bind => sub { sub { return __test_js_bind( @_ ) } },
        test_js_eval => sub { sub { local $Test::Builder::Level = $Test::Builder::Level + 2; return __test_js_eval( @_ ) } },
    ],
    groups => {
        default => [qw/ test_js test_js_tester test_js_bind test_js_eval /],
    },
};

my $__tester;
sub __test_js_tester { return $__tester ||= __PACKAGE__->new }
sub __test_js { return __test_js_tester->test( @_ ) } 
sub __test_js_bind { return __test_js_tester->bind( @_ ) }
sub __test_js_eval { return __test_js_tester->eval( @_ ) }


has context => qw/is ro lazy_build 1/;
sub _build_context {
    return JavaScript::V8::Context->new();
}

has builder => qw/is ro lazy_build 1/;
sub _build_builder {
    require Test::More;
    return Test::More->builder;
}

sub BUILD {
    my $self = shift;

    $self->bind(
        _TestMoreish_diag => sub { Test::More->builder->diag( @_ ) },
        _TestMoreish_ok => sub { Test::More->builder->ok( @_ ) },
    );

    $self->eval( JavaScript::V8x::TestMoreish::JS->TestMoreish );
    $self->eval( <<'_END_' );
if (! TestMoreish)
    var TestMoreish = _TestMoreish;
_END_
    $self->eval( join "\n", map { "function $_() { TestMoreish.$_.apply( TestMoreish, arguments ) }" } split m/\n+/, <<_END_ );
diag
areEqual
areNotEqual
areSame
areNotSame

isTrue
isFalse

isString
isValue
isObject
isNumber
isBoolean
isFunction

like

fail
_END_
}

sub bind {
    my $self = shift;

    while( @_ ) {
        $self->context->bind_function( shift, shift );
    }
}

sub eval {
    my $self = shift;

    # TODO TryCatch?
    local $@ = undef;
    $self->context->eval( @_ );
    die $@ if $@;
}

sub test {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 2;

    for ( @_ ) {
        if (m/\n/) {
            $self->eval( $_ );
        }
        else {
            my $path = Path::Abstract->new( $_ );
            my $file = $path->file;
            $self->eval( scalar $file->slurp );
        }
    }
}

=head1 SEE ALSO

L<JavaScript::V8>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-javascript-v8x-test at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-V8x-TestMoreish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::V8x::TestMoreish


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-V8x-TestMoreish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JavaScript-V8x-TestMoreish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JavaScript-V8x-TestMoreish>

=item * Search CPAN

L<http://search.cpan.org/dist/JavaScript-V8x-TestMoreish/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Krimen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JavaScript::V8x::TestMoreish
