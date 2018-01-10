package HTML::Lint::Error;

use warnings;
use strict;

use parent 'Exporter';

our @EXPORT_OK = qw( STRUCTURE HELPER FLUFF );
our %EXPORT_TAGS = ( types => [@EXPORT_OK] );

our %errors;

=head1 NAME

HTML::Lint::Error - Error object for the Lint functionality

=head1 SYNOPSIS

See L<HTML::Lint> for all the gory details.

=head1 EXPORTS

None.  It's all object-based.

=head1 METHODS

Almost everything is an accessor.

=head1 Error types: C<STRUCTURE>, C<HELPER>, C<FLUFF>

Each error has a type.  Note that these roughly, but not exactly, go
from most severe to least severe.

=over 4

=item * C<STRUCTURE>

For problems that relate to the structural validity of the code.
Examples: Unclosed <TABLE> tags, incorrect values for attributes, and
repeated attributes.

=item * C<HELPER>

Helpers are notes that will help you with your HTML, or that will help
the browser render the code better or faster.  Example: Missing HEIGHT
and WIDTH attributes in an IMG tag.

=item * C<FLUFF>

Fluff is for items that don't hurt your page, but don't help it either.
This is usually something like an unknown attribute on a tag.

=back

=cut

use constant CONFIG     => 1;
use constant STRUCTURE  => 2;
use constant HELPER     => 3;
use constant FLUFF      => 4;

=head2 new()

Create an object.  It's not very exciting.

=cut

sub new {
    my $class    = shift;

    my $file     = shift;
    my $line     = shift;
    my $column   = shift;
    my $errcode  = shift;
    my @errparms = @_;

    # Add an element that says what tag caused the error (B, TR, etc)
    # so that we can match 'em up down the road.
    my $self  = {
        _file    => $file,
        _line    => $line,
        _column  => $column,
        _errcode => $errcode,
        _errtext => undef,
        _type    => undef,
    };

    bless $self, $class;

    $self->_expand_error( $errcode, @errparms );

    return $self;
}

sub _expand_error {
    my $self = shift;

    my $errcode = shift;

    my $specs = $errors{$errcode};
    my $str;
    if ( $specs ) {
        ($str, $self->{_type}) = @{$specs};
    }
    else {
        $str = "Unknown code: $errcode";
    }

    if ( defined $str ) {
        while ( @_ ) {
            my $var = shift;
            my $val = shift;
            $str =~ s/\$\{$var\}/$val/g;
        }
    }

    $self->{_errtext} = $str;

    return;
}

=head2 is_type( $type1 [, $type2 ] )

Tells if any of I<$type1>, I<$type2>... match the error's type.
Returns the type that matched.

    if ( $err->is_type( HTML::Lint::Error::STRUCTURE ) ) {....

=cut

sub is_type {
    my $self = shift;

    for my $matcher ( @_ ) {
        return $matcher if $matcher eq $self->type;
    }

    return;
}

=head2 where()

Returns a formatted string that describes where in the file the
error has occurred.

For example,

    (14:23)

for line 14, column 23.

The terrible thing about this function is that it's both a plain
ol' formatting function as in

    my $str = where( 14, 23 );

AND it's an object method, as in:

    my $str = $error->where();

I don't know what I was thinking when I set it up this way, but
it's bad practice.

=cut

sub where {
    my $line;
    my $col;

    if ( not ref $_[0] ) {
        $line = shift;
        $col = shift;
    }
    else {
        my $self = shift;
        $line = $self->line;
        $col = $self->column;
    }
    $col ||= 0;
    return sprintf( '(%s:%s)', $line, $col + 1 );
}

=head2 as_string()

Returns a nicely-formatted string for printing out to stdout or some similar user thing.

=cut

sub as_string {
    my $self = shift;

    return sprintf( '%s %s %s', $self->file, $self->where, $self->errtext );
}

=head2 file()

Returns the filename of the error, as set by the caller.

=head2 line()

Returns the line number of the error.

=head2 column()

Returns the column number, starting from 0

=head2 errcode()

Returns the HTML::Lint error code.  Don't rely on this, because it will probably go away.

=head2 errtext()

Descriptive text of the error

=head2 type()

Type of the error

=cut

sub file        { my $self = shift; return $self->{_file}    || '' }
sub line        { my $self = shift; return $self->{_line}    || '' }
sub column      { my $self = shift; return $self->{_column}  || '' }
sub errcode     { my $self = shift; return $self->{_errcode} || '' }
sub errtext     { my $self = shift; return $self->{_errtext} || '' }
sub type        { my $self = shift; return $self->{_type}    || '' }


=head1 POSSIBLE ERRORS

Each possible error in HTML::Lint has a code.  These codes are used
to identify each error for when you need to turn off error checking
for a specific error.

=cut

%errors = ( ## no critic ( ValuesAndExpressions::RequireInterpolationOfMetachars )
    'api-parse-not-called'     => ['The parse() method has not been called on this file.', CONFIG],
    'api-eof-not-called'       => ['The eof() method has not been called on this file.', CONFIG],
    'config-unknown-directive' => ['Unknown directive "${directive}"', CONFIG],
    'config-unknown-value'     => ['Unknown value "${value}" for ${directive} directive', CONFIG],

    'elem-empty-but-closed'    => ['<${tag}> is not a container -- </${tag}> is not allowed', STRUCTURE],
    'elem-img-alt-missing'     => ['<img src="${src}"> does not have ALT text defined', HELPER],
    'elem-img-sizes-missing'   => ['<img src="${src}"> tag has no HEIGHT and WIDTH attributes', HELPER],
    'elem-input-alt-missing'   => ['<input name="${name}" type="image"> does not have non-blank ALT text defined', HELPER],
    'elem-nonrepeatable'       => ['<${tag}> is not repeatable, but already appeared at ${where}', STRUCTURE],
    'elem-unclosed'            => ['<${tag}> at ${where} is never closed', STRUCTURE],
    'elem-unknown'             => ['Unknown element <${tag}>', STRUCTURE],
    'elem-unopened'            => ['</${tag}> with no opening <${tag}>', STRUCTURE],

    'doc-tag-required'         => ['<${tag}> tag is required', STRUCTURE],

    'attr-repeated'            => ['${attr} attribute in <${tag}> is repeated', STRUCTURE],
    'attr-unknown'             => ['Unknown attribute "${attr}" for tag <${tag}>', FLUFF],
    'attr-unclosed-entity'     => ['Entity ${entity} is missing its closing semicolon', STRUCTURE],
    'attr-unknown-entity'      => ['Entity ${entity} is unknown', STRUCTURE],
    'attr-use-entity'          => ['Character "${char}" should be written as ${entity}', STRUCTURE],

    'text-unclosed-entity'     => ['Entity ${entity} is missing its closing semicolon', STRUCTURE],
    'text-unknown-entity'      => ['Entity ${entity} is unknown', STRUCTURE],
    'text-use-entity'          => ['Character "${char}" should be written as ${entity}', STRUCTURE],
);

=head2 api-parse-not-called

You called the C<errors()> method before calling C<parse()> and C<eof()>.

=head2 api-eof-not-called

You called the C<errors()> method before calling C<eof()>.

=head2 config-unknown-directive

Unknown directive "DIRECTIVE"

You specified a directive in a comment for HTML::Lint that it didn't recognize.

=head2 config-unknown-value

Unknown value "VALUE" for DIRECTIVE directive

Directive values can only be "on", "off", "yes", "no", "true", "false", "0" and "1".

=head2 elem-unknown

HTML::Lint doesn't know recognize the tag.

=head2 elem-unopened

C<< </tag> >> with no opening C<< <tag> >>.

=head2 elem-unclosed

C<< <tag> >> at WHERE is never closed.

=head2 elem-empty-but-closed

C<< <tag> >> is not a container -- C<< </tag> >> is not allowed.

=head2 elem-img-alt-missing

C<< <img src="FILENAME.PNG"> >> does not have ALT text defined.

=head2 elem-img-sizes-missing

C<< <img src="FILENAME.PNG"> >> tag has no HEIGHT and WIDTH attributes.

=head2 elem-nonrepeatable

C<< <tag> >> is not repeatable, but already appeared at WHERE.

=head2 doc-tag-required

C<< <tag> >> tag is required.

=head2 attr-repeated

ATTR attribute in C<< <tag> >> is repeated.

=head2 attr-unknown

Unknown attribute "ATTR" for tag C<< <tag> >>.

=head2 text-unclosed-entity

Entity ENTITY is missing its closing semicolon

=head2 text-unknown-entity

Entity ENTITY is unknown

=head2 text-use-entity

Character "CHAR" should be written as ENTITY

=head1 COPYRIGHT & LICENSE

Copyright 2005-2018 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License v2.0.

http://www.opensource.org/licenses/Artistic-2.0

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<andy at petdance.com>

=cut

1; # happy

__DATA__
Errors that haven't been done yet.

#elem-head-only                 <${tag}> can only appear in the <HEAD> element
#elem-non-head-element          <${tag}> cannot appear in the <HEAD> element
#elem-obsolete                  <${tag}> is obsolete
#elem-nested-element            <${tag}> cannot be nested -- one is already opened at ${where}
#elem-wrong-context             Illegal context for <${tag}> -- must appear in <${othertag}> tag.
#elem-heading-in-anchor         <A> should be inside <${tag}>, not <${tag}> inside <A>

#elem-head-missing              No <HEAD> element found
#elem-head-missing-title        No <TITLE> in <HEAD> element
#elem-img-sizes-incorrect       <IMG> tag's HEIGHT and WIDTH attributes are incorrect.  They should be ${correct}.
#attr-missing                   <${tag}> is missing a "${attr}" attribute

#comment-unclosed               Unclosed comment
#comment-markup                 Markup embedded in a comment can confuse some browsers

#text-literal-metacharacter     Metacharacter $char should be represented as "$otherchar"
#text-title-length              The HTML spec recommends that that <TITLE> be no more than 64 characters
#text-markup                    Tag <${tag}> found in the <TITLE>, which will not be rendered properly.

#elem-physical-markup           <${tag}> is physical font markup.  Use logical (such as <${othertag}>) instead.
#elem-leading-whitespace        <${tag}> should not have whitespace between "<" and "${tag}>"
#'must-follow' => [ ENABLED, MC_ERROR, '<$argv[0]> must immediately follow <$argv[1]>', ],
# 'empty-container' => [ ENABLED, MC_WARNING, 'empty container element <$argv[0]>.', ],
# 'directory-index' => [ ENABLED, MC_WARNING, 'directory $argv[0] does not have an index file ($argv[1])', ],
# 'attribute-delimiter' => [ ENABLED, MC_WARNING, 'use of \' for attribute value delimiter is not supported by all browsers (attribute $argv[0] of tag $argv[1])', ],
# 'container-whitespace' => [ DISABLED, MC_WARNING, '$argv[0] whitespace in content of container element $argv[1]', ],
# 'bad-text-context' => [ ENABLED, MC_ERROR, 'illegal context, <$argv[0]>, for text; should be in $argv[1].', ],
# 'attribute-format' => [ ENABLED, MC_ERROR, 'illegal value for $argv[0] attribute of $argv[1] ($argv[2])', ],
# 'quote-attribute-value' => [ ENABLED, MC_ERROR, 'value for attribute $argv[0] ($argv[1]) of element $argv[2] should be quoted (i.e. $argv[0]="$argv[1]")', ],
# 'meta-in-pre' => [ ENABLED, MC_ERROR, 'you should use "$argv[0]" in place of "$argv[1]", even in a PRE element.', ],
#  'implied-element' => [ ENABLED, MC_WARNING, 'saw <$argv[0]> element, but no <$argv[1]> element', ],
#  'button-usemap' => [ ENABLED, MC_ERROR, 'illegal to associate an image map with IMG inside a BUTTON', ],
