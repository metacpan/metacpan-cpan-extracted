package HTML::Lint;

use warnings;
use strict;

use HTML::Lint::Error;
use HTML::Lint::Parser ();

use HTML::Entities ();

=head1 NAME

HTML::Lint - check for HTML errors in a string or file

=head1 VERSION

Version 2.32

=cut

our $VERSION = '2.32';

=head1 SYNOPSIS

    my $lint = HTML::Lint->new;
    $lint->only_types( HTML::Lint::Error::STRUCTURE );

    # Parse lines of data.
    $lint->newfile( $filename );
    while ( my $line = <> ) {
        $lint->parse( $line );
    }
    $lint->eof();

    # Or, parse an entire file at once.
    $lint->parse_file( $filename );

    # Fetch the errors that the linter found.
    my $error_count = $lint->errors;

    foreach my $error ( $lint->errors ) {
        print $error->as_string, "\n";
    }

HTML::Lint also comes with a wrapper program called F<weblint> that handles
linting from the command line:

    $ weblint http://www.cnn.com/
    http://www.cnn.com/ (395:83) <IMG SRC="spacer.gif"> tag has no HEIGHT and WIDTH attributes.
    http://www.cnn.com/ (395:83) <IMG SRC="goofus.gif"> does not have ALT text defined
    http://www.cnn.com/ (396:217) Unknown element <nobr>
    http://www.cnn.com/ (396:241) </nobr> with no opening <nobr>
    http://www.cnn.com/ (842:7) target attribute in <a> is repeated

And finally, you can also get L<Apache::HTML::Lint> that passes any
mod_perl-generated code through HTML::Lint and get it dumped into your
Apache F<error_log>.

    [Mon Jun  3 14:03:31 2002] [warn] /foo.pl (1:45) </p> with no opening <p>
    [Mon Jun  3 14:03:31 2002] [warn] /foo.pl (1:49) Unknown element <gronk>
    [Mon Jun  3 14:03:31 2002] [warn] /foo.pl (1:56) Unknown attribute "x" for tag <table>

=cut

=head1 METHODS

NOTE: Some of these methods mirror L<HTML::Parser>'s methods, but HTML::Lint
is not a subclass of HTML::Parser.

=head2 new()

Create an HTML::Lint object, which inherits from HTML::Parser.
You may pass the types of errors you want to check for in the
C<only_types> parm.

    my $lint = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );

If you want more than one, you must pass an arrayref:

    my $lint = HTML::Lint->new(
        only_types => [HTML::Lint::Error::STRUCTURE, HTML::Lint::Error::FLUFF] );

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {
        _errors => [],
        _types  => [],
    };
    bless $self, $class;

    if ( my $only = $args{only_types} ) {
        $self->only_types( ref $only eq 'ARRAY' ? @{$only} : $only );
        delete $args{only_types};
    }

    warn "Unknown argument $_\n" for keys %args;

    return $self;
}

=head2 $lint->parser()

Returns the parser object for this object, creating one if necessary.

=cut

sub parser {
    my $self = shift;

    if ( not $self->{_parser} ) {
        $self->{_parser} = HTML::Lint::Parser->new( sub { $self->gripe( @_ ) } );
        $self->{_parser}->ignore_elements( qw(script style) );
    }

    return $self->{_parser};
}

=head2 $lint->parse( $text )

=head2 $lint->parse( $code_ref )

Passes in a chunk of HTML to be linted, either as a piece of text,
or a code reference.
See L<HTML::Parser>'s C<parse_file> method for details.

=cut

sub parse {
    my $self = shift;

    my $rc = $self->parser->parse( @_ );

    $self->{_parse_called} = 1;

    return $rc;
}

=head2 $lint->parse_file( $file )

Analyzes HTML directly from a file. The C<$file> argument can be a filename,
an open file handle, or a reference to an open file handle.
See L<HTML::Parser>'s C<parse_file> method for details.

=cut

sub parse_file {
    my $self = shift;

    my $rc = $self->parser->parse_file( @_ );

    $self->{_parse_called} = 1;
    $self->eof;

    return $rc;
}

=head2 $lint->eof()

Signals the end of a block of text getting passed in.  This must be
called to make sure that all parsing is complete before looking at errors.

Any parameters (and there shouldn't be any) are passed through to
HTML::Parser's eof() method.

=cut

sub eof {   ## no critic ( Subroutines::ProhibitBuiltinHomonyms )
    my $self = shift;

    my $rc;
    my $parser = $self->parser;
    if ( $parser ) {
        $rc = $parser->eof(@_);
        delete $self->{_parser};
        $self->{_eof_called} = 1;
    }

    return $rc;
}

=head2 $lint->errors()

In list context, C<errors> returns all of the errors found in the
parsed text.  Each error is an object of the type L<HTML::Lint::Error>.

In scalar context, it returns the number of errors found.

=cut

sub errors {
    my $self = shift;

    if ( !$self->{_parse_called} ) {
        $self->gripe( 'api-parse-not-called' );
    }
    elsif ( !$self->{_eof_called} ) {
        $self->gripe( 'api-eof-not-called' );
    }

    if ( wantarray ) {
        return @{$self->{_errors}};
    }
    else {
        return scalar @{$self->{_errors}};
    }
}

=head2 $lint->clear_errors()

Clears the list of errors, in case you want to print and clear, print and clear.

=cut

sub clear_errors {
    my $self = shift;

    $self->{_errors} = [];

    return;
}

=head2 $lint->only_types( $type1[, $type2...] )

Specifies to only want errors of a certain type.

    $lint->only_types( HTML::Lint::Error::STRUCTURE );

Calling this without parameters makes the object return all possible
errors.

The error types are C<STRUCTURE>, C<HELPER> and C<FLUFF>.
See L<HTML::Lint::Error> for details on these types.

=cut

sub only_types {
    my $self = shift;

    $self->{_types} = [@_];

    return;
}

=head2 $lint->gripe( $errcode, [$key1=>$val1, ...] )

Adds an error message, in the form of an L<HTML::Lint::Error> object,
to the list of error messages for the current object.  The file,
line and column are automatically passed to the L<HTML::Lint::Error>
constructor, as well as whatever other key value pairs are passed.

For example:

    $lint->gripe( 'attr-repeated', tag => $tag, attr => $attr );

Usually, the user of the object won't call this directly, but just
in case, here you go.

=cut

sub gripe {
    my $self = shift;

    my $error = HTML::Lint::Error->new(
        $self->{_file}, $self->parser->{_line}, $self->parser->{_column}, @_ );

    my @keeps = @{$self->{_types}};
    if ( !@keeps || $error->is_type(@keeps) ) {
        push( @{$self->{_errors}}, $error );
    }

    return;
}


=head2 $lint->newfile( $filename )

Call C<newfile()> whenever you switch to another file in a batch
of linting.  Otherwise, the object thinks everything is from the
same file.  Note that the list of errors is NOT cleared.

Note that I<$filename> does NOT need to match what's put into C<parse()>
or C<parse_file()>.  It can be a description, a URL, or whatever.

You should call C<newfile()> even if you are only validating one file. If
you do not call C<newfile()> then your errors will not have a filename
attached to them.

=cut

sub newfile {
    my $self = shift;
    my $file = shift;

    delete $self->{_parser};
    delete $self->{_parse_called};
    delete $self->{_eof_called};
    $self->{_file} = $file;
    $self->{_line} = 0;
    $self->{_column} = 0;
    $self->{_first_seen} = {};

    return $self->{_file};
} # newfile

1;

=head1 MODIFYING HTML::LINT'S BEHAVIOR

Sometimes you'll have HTML that for some reason cannot conform to
HTML::Lint's expectations.  For those instances, you can use HTML
comments to modify HTML::Lint's behavior.

Say you have an image where for whatever reason you can't get
dimensions for the image.  This HTML snippet:

    <img src="logo.png" height="120" width="50" alt="Company logo">
    <img src="that.png">

causes this error:

    foo.html (14:20) <img src="that.png"> tag has no HEIGHT and WIDTH attributes

But if for some reason you can't get those dimensions when you build
the page, you can at least stop HTML::Lint complaining about it.

    <img src="this.png" height="120" width="50" alt="Company logo">
    <!-- html-lint elem-img-sizes-missing: off, elem-img-alt-missing: off -->
    <img src="that.png">
    <!-- html-lint elem-img-sizes-missing: on, elem-img-alt-missing: off -->

If you want to turn off all HTML::Lint warnings for a block of code, use

    <!-- html-lint all: off -->

And turn them back on with

    <!-- html-lint all: on -->

You don't have to use "on" and "off".  For "on", you can use "true"
or "1".  For "off", you can use "0" or "false".

For a list of possible errors and their codes, see L<HTML::Lint::Error>,
or run F<perldoc HTML::Lint::Error>.

=head1 BUGS, WISHES AND CORRESPONDENCE

All bugs and requests are now being handled through GitHub.

    https://github.com/petdance/html-lint/issues

DO NOT send bug reports to http://rt.cpan.org/ or http://code.google.com/

=head1 TODO

=over 4

=item * Check for attributes that require values

=item * <TABLE>s that have no rows.

=item * Form fields that aren't in a FORM

=item * DIVs with nothing in them.

=item * HEIGHT= that have percents in them.

=item * Check for goofy stuff like:

    <b><li></b><b>Hello Reader - Spanish Level 1 (K-3)</b>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2005-2018 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License v2.0.

http://www.opensource.org/licenses/Artistic-2.0

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, andy at petdance.com

=cut

1;
