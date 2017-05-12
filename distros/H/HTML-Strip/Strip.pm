package HTML::Strip;

require DynaLoader;
our @ISA = qw(DynaLoader);
our $VERSION = '2.10';
bootstrap HTML::Strip $VERSION;

use 5.008;
use warnings;
use strict;

use Carp;

my $_html_entities_p = eval { require HTML::Entities; 1 };

my %defaults = (
    striptags => [qw( title
                      style
                      script
                      applet )],
    emit_spaces	    => 1,
    decode_entities	=> 1,
    filter          => $_html_entities_p ? 'filter_entities' : undef,
    auto_reset      => 0,
    debug           => 0,
);

sub new {
    my $class = shift;
    my $obj = _create();
    bless $obj, $class;

    my %args = (%defaults, @_);
    while( my ($key, $value) = each %args ) {
        my $method = "set_${key}";
        if( $obj->can($method) ) {
            $obj->$method($value);
        } else {
            Carp::carp "Invalid setting '$key'";
        }
    }
    return $obj;
}

sub set_striptags {
    my ($self, @tags) = @_;
    if( ref($tags[0]) eq 'ARRAY' ) {
        $self->_set_striptags_ref( $tags[0] );
    } else {
        $self->_set_striptags_ref( \@tags );
    }
}

{
    # an inside-out object approach
    # for the 'filter' attribute
    my %filter_of;

    sub set_filter {
        my ($self, $filter) = @_;
        $filter_of{0+$self} = $filter;
    }

    sub filter {
        my $self = shift;
        return $filter_of{0+$self}
    }

    # XXX rename _xs_destroy() to DESTROY() in Strip.xs if removing this code
    sub DESTROY {
        my $self = shift;
        delete $filter_of{0+$self};
        $self->_xs_destroy;
    }
}

# $decoded_string = $self->filter_entities( $string )
sub filter_entities {
    my $self = shift;
    if( $self->decode_entities ) {
        return HTML::Entities::decode($_[0]);
    }
    return $_[0];
}

sub _do_filter {
    my $self = shift;
    my $filter = $self->filter;
    # no filter: return immediately
    return $_[0] unless defined $filter;

    if ( !ref $filter ) { # method name
        return $self->$filter( @_ );
    } else { # code ref
        return $filter->( @_ );
    }
}

sub parse {
    my ($self, $text) = @_;
    my $stripped = $self->_strip_html( $text );
    return $self->_do_filter( $stripped );
}

sub eof {
    my $self = shift;
    $self->_reset();
}

1;
__END__

=head1 NAME

HTML::Strip - Perl extension for stripping HTML markup from text.

=head1 SYNOPSIS

  use HTML::Strip;

  my $hs = HTML::Strip->new();

  my $clean_text = $hs->parse( $raw_html );
  $hs->eof;

=head1 DESCRIPTION

This module simply strips HTML-like markup from text rapidly and
brutally.  It could easily be used to strip XML or SGML markup
instead; but as removing HTML is a much more common problem, this
module lives in the HTML:: namespace.

It is written in XS, and thus about five times quicker than using
regular expressions for the same task.

It does I<not> do any syntax checking (if you want that, use
L<HTML::Parser>), instead it merely applies the following rules:

=over 4

=item 1

Anything that looks like a tag, or group of tags will be replaced with
a single space character.  Tags are considered to be anything that
starts with a C<E<lt>> and ends with a C<E<gt>>; with the caveat that a
C<E<gt>> character may appear in either of the following without
ending the tag:

=over 4

=item Quote

Quotes are considered to start with either a C<'> or a C<"> character,
and end with a matching character I<not> preceded by an even number or
escaping slashes (i.e. C<\"> does not end the quote but C<\\\\"> does).

=item Comment

If the tag starts with an exclamation mark, it is assumed to be a
declaration or a comment.   Within such tags, C<E<gt>> characters do not
end the tag if they appear within pairs of double dashes
(e.g. C<E<lt>!-- E<lt>a href="old.htm"E<gt>old pageE<lt>/aE<gt> --E<gt>>
would be stripped completely).  No parsing for quotes is performed
within comments, so for instance
C<E<lt>!-- comment with both ' quote types " --E<gt>>
would be entirely stripped.

=back

=item 2

Anything the appears within what we term I<strip tags> is stripped as
well.  By default, these tags are C<title>, C<script>, C<style> and
C<applet>.

=back

HTML::Strip maintains state between calls, so you can parse a document
in chunks should you wish.  If one chunk ends half-way through a tag,
quote, comment, or whatever; it will remember this, and expect the
next call to parse to start with the remains of said tag.

If this is not going to be the case, be sure to call $hs->eof()
between calls to $hs->parse().   Alternatively, you may
set C<auto_reset> to true on the constructor or any time
after with C<set_auto_reset>, so that the parser will always
operate in one-shot basis (resetting after each parsed chunk).

=head2 METHODS

=over

=item new()

Constructor.  Can optionally take a hash of settings (with keys
corresponsing to the C<set_> methods below).

For example, the following is a valid constructor:

 my $hs = HTML::Strip->new(
                           striptags   => [ 'script', 'iframe' ],
                           emit_spaces => 0
                          );

=item parse()

Takes a string as an argument, returns it stripped of HTML.

=item eof()

Resets the current state information, ready to parse a new block of HTML.

=item clear_striptags()

Clears the current set of strip tags.

=item add_striptag()

Adds the string passed as an argument to the current set of strip tags.

=item set_striptags()

Takes a reference to an array of strings, which replace the current
set of strip tags.

=item set_emit_spaces()

Takes a boolean value.  If set to false, HTML::Strip will not attempt
any conversion of tags into spaces.  Set to true by default.

=item set_decode_entities()

Takes a boolean value.  If set to false, HTML::Strip will decode HTML
entities.  Set to true by default.

=item filter_entities()

If HTML::Entities is available, this method behaves just
like invoking HTML::Entities::decode_entities, except that
it respects the current setting of 'decode_entities'.

=item set_filter()

Sets a filter to be applied after tags were stripped.
It may accept the name of a method (like 'filter_entities')
or a code ref.  By default, its value is 'filter_entities'
if HTML::Entities is available or C<undef> otherwise.

=item set_auto_reset()

Takes a boolean value.  If set to true, C<parse> resets after
each call (equivalent to calling C<eof>).  Otherwise, the
parser remembers its state from one call to C<parse> to
another, until you call C<eof> explicitly.  Set to false
by default.

=item set_debug()

Outputs extensive debugging information on internal state during the parse.
Not intended to be used by anyone except the module maintainer.

=item decode_entities()

=item filter()

=item auto_reset()

=item debug()

Readonly accessors for their respective settings.

=back

=head2 LIMITATIONS

=over 4

=item Whitespace

Despite only outputting one space character per group of tags, and
avoiding doing so when tags are bordered by spaces or the start or
end of strings, HTML::Strip can often output more than desired; such
as with the following HTML:

 <h1> HTML::Strip </h1> <p> <em> <strong> fast, and brutal </strong> </em> </p>

Which gives the following output:

C<E<nbsp>HTML::StripE<nbsp>E<nbsp>E<nbsp>E<nbsp>fast, and brutalE<nbsp>E<nbsp>E<nbsp>>

Thus, you may want to post-filter the output of HTML::Strip to remove
excess whitespace (for example, using C<tr/ / /s;>).
(This has been improved since previous releases, but is still an issue)

=item HTML Entities

HTML::Strip will only attempt decoding of HTML entities if
L<HTML::Entities> is installed.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Alex Bowley E<lt>kilinrax@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<HTML::Parser>, L<HTML::Entities>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
