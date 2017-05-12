## no critic
package HTML::PodCodeReformat;
BEGIN {
  $HTML::PodCodeReformat::VERSION = '0.20000';
}
## use critic

use strict;
use warnings;

use HTML::Parser 3.00 ();
use Carp qw(croak);

use constant MAX_INDENT => 99;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw/
    squash_blank_lines
    line_numbers
    _html_parser
    _inside_pre
    _filtered_html
/);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ > 1 ? { @_ } : $_[0] );
    $self->_html_parser( $self->_build_html_parser );
    return $self
}

sub _build_html_parser {
    my $self = shift;
    
    HTML::Parser->new(
        unbroken_text => 1,
        
        start_h   => [ sub { $self->_tag(@_) }, 'text, tagname, "+1"' ],
        end_h     => [ sub { $self->_tag(@_) }, 'text, tagname, "-1"' ],
        
        text_h    => [ sub { $self->_text(@_)             }, 'text' ],
        default_h => [ sub { $self->_append_to_output(@_) }, 'text' ]
    )
}

sub _tag {
    my ($self, $text, $tag, $incr) = @_;
    $self->_inside_pre( $incr + $self->_inside_pre )
        if $tag eq 'pre';
    $self->_append_to_output($text)
}

sub _text {
    my ($self, $text) = @_;
    $self->_append_to_output(
        $self->_inside_pre ? $self->_reformat_pre_text($text) : $text
    )
}

sub _append_to_output {
    my ($self, $text) = @_;
    $self->_filtered_html( $self->_filtered_html . $text )
}

sub _reformat_pre_text {
    my ($self, $text) = @_;
    
    my @lines = split /\n/, $text, -1;
    my $min_indent_width = MAX_INDENT;
    foreach ( @lines ) {
        next if /^\s*$/; # Skip verbatim paragraph breaks
                         # as well as space-only lines.
        my $indent_width = /^(\s+)/ ? length($1) : 0;
        $min_indent_width = $indent_width if $indent_width < $min_indent_width
    }
    
    # This test is not necessary, it's just a micro-optimization.
    if ( $min_indent_width ) {
        s/^\s{$min_indent_width}// foreach @lines
    }
    
    if ( $self->squash_blank_lines ) {
        s/^\s+$// foreach @lines
    }
    
    return $self->line_numbers
        ? '<ol>' . join( '', map { "<li>$_</li>" } @lines ) . '</ol>'
        : join "\n", @lines
}

sub reformat_pre {
    my ($self, $input) = @_;
    
    $self->_init_state;
    
    my $type = ref $input;
    if ( $type eq 'SCALAR' ) {
        $self->_html_parser->parse($$input);
        $self->_html_parser->eof
    } elsif ( $type eq '' || $type eq 'GLOB' ) {
        defined( $self->_html_parser->parse_file($input) ) or return
    } else {
        croak( 'Wrong input type: ', $input )
    }
    
    return $self->_filtered_html
}

sub _init_state {
    my $self = shift;
    $self->_filtered_html('');
    $self->_inside_pre(0)
}

1;

__END__

=head1 NAME

HTML::PodCodeReformat - Reformats HTML code blocks coming from Pod verbatim paragraphs

=head1 VERSION

version 0.20000

=head1 SYNOPSIS

    use HTML::PodCodeReformat;
    
    my $f = HTML::PodCodeReformat->new;
    my $fixed_html = $f->reformat_pre( *DATA );
    
    print $fixed_html; # It prints:
    
    #<!-- HTML produced by a Pod transformer -->
    #<html>
    #<h1>SYNOPSIS</h1>
    #<pre>
    #while (<>) {
    #    chomp;
    #    print;
    #}
    #</pre>
    #<h1>DESCRIPTION</h1>
    #<p>Remove trailing newline from every line.</p>
    #</html>
    
    __DATA__
    <!-- HTML produced by a Pod transformer -->
    <html>
    <h1>SYNOPSIS</h1>
    <pre>
        while (<>) {
            chomp;
            print;
        }
    </pre>
    <h1>DESCRIPTION</h1>
    <p>Remove trailing newline from every line.</p>
    </html>

=head1 DESCRIPTION

This module is mainly intended to strip the extra leading spaces which appear
in text lines inside C<< <pre>...</pre> >> blocks
(corresponding to Pod I<verbatim paragraphs>)
in an HTML-transformed pod (then it can optionally apply other transformations 
as well on such blocks).

L<perlpodspec> states that (leading) I<whitespace is significant in verbatim
paragraphs>, that is, they must be preserved in the final output (e.g. HTML).

This is an unfortunate mixture between syntax and semantics (which is really
unavoidable, given the freedom L<perlpodspec> leaves in choosing the verbatim
paragraphs indentation width), which leads to (at least) a couple of annoying
consequences:

=over 4

=item *

the code blocks are awful to see
(at least in HTML, where those leading spaces have no meaning);

=item *

the extra leading spaces can break the code (for example with non-I<free form>
code such as YAML, but it can even happen with plain Perl code - think of
I<heredocs>), so that, in the general case, the code cannot be taken verbatim
from the document (for example by copying and pasting it into a text editor) and
run without modifications.

=back

This module takes any document created by a Pod to HTML transformer and
eliminates the extra leading spaces in I<code blocks> (rendered in HTML as
C<< <pre>...</pre> >> blocks).

Really, L<Pod::Simple> already offers a sane solution to this problem (through
its C<strip_verbatim_indent> method), which has the advantage that it works with
any final format.

However it requires you to pass the leading string to strip, which, to work
across different pods, of course requires the indentation of verbatim paragraphs
to be consistent (which is very unlikely, if said pods come from many different
authors). Alternatively, an heuristic to remove the extra indentation can be
provided (through a code reference).

Though much more limited in scope, since it works only on HTML, this module
offers instead a ready-made simple but effective heuristic, which has proved to
work on 100% of the HTML-rendered pods tested so far (including a large CPAN
Search subset). For the details, please look at the L</ALGORITHM> section below.

Furthermore, since it works only on the final HTML (produced by B<any> Pod
transformer), it can more easily be integrated into existing workflows.

=head1 METHODS

=head2 C<new>

=over 4

=item *

C<< HTML::PodCodeReformat->new( %options ) >>

=item *

C<< HTML::PodCodeReformat->new( \%options ) >>

=back

It creates and returns a new C<HTML::PodCodeReformat> object. It accepts its
options either as a hash or a hashref.

It can take the following options:

=over 4

=item *

C<squash_blank_lines>

Boolean option which, when set to I<true>, causes every line composed solely of
spaces (C<\s>) in a C<pre> block, to be I<squashed> to an empty string
(the newline is left untouched).

When set to I<false> (which is the default) the I<blank lines> in a
C<pre> block will be treated as I<normal> lines, that is, they will be
stripped only of the extra leading whitespaces, as any other line.

=item *

C<line_numbers>

Boolean option which, when set to true, causes every line in a C<pre> text
to be wrapped in C<< <li>...</li> >> tags, and the whole text to be wrapped in
C<< <ol>...</ol> >> tags (so that a line number is prepended to every line in
the C<pre> text, when the HTML document is viewed in a browser).

In this case the original newlines in the C<pre> text are removed, to not add
extra empty lines when the HTML document is rendered.

It defaults to false.

=back

The above options can be read/set after the object construnction through their
corresponding methods as well.

=head2 C<reformat_pre>

=over 4

=item *

C<< reformat_pre( $filename ) >>

=item *

C<< reformat_pre( $filehandle ) >>

=item *

C<< reformat_pre( \$string ) >>

=back

Instance method which removes the I<extra> leading spaces from the
lines contained in every
C<< <pre>...</pre> >> block in the given HTML document (of course
preserving any I<real> indentation I<inside> code, as showed in the L</SYNOPSIS>
above), and returns a string containing the HTML code modified that way.

It can take the name of the HTML file, an already opened filehandle or a
reference to a string containing the HTML code.

It would work even on nested C<pre> blocks, though this situation has never
been encountered in I<real> pods.

If the options C<squash_blank_lines> and C<line_numbers> are set, the
corresponding transformations (described above) are applied as well (after
the extra leading spaces removal).

=head1 ALGORITHM

The adopted algorithm to remove the extra leading whitespaces is extremely
simple.

Skipping some minor details, it basically works
this way: given an HTML document, for each text block inside
C<< <pre>...</pre> >> tags, first the length of the shortest leading whitespace
string across all the lines in the block is calculated (ignoring empty lines),
then every line in the block is I<shifted to the left> by such amount.

=head1 LIMITATIONS

With the exception explained below in the L</Non-limitations> section, any
C<< <pre>...</pre> >> block which has I<extra> leading spaces will be
reformatted.
This will happen also if a given verbatim paragraph (most probably composed of
text, not code) is intended to stay indented (no pun intended) that way, such as
in, for example:

        This text
        should really stay
        8-spaces indented
        (but it will be shifted to the first column :-(

Currently there is no way to I<protect> a C<pre> block, but such requirement
should be really rare.

=head2 Non-limitations

=over 4

=item *

Really, L<perlpodspec> says that indenting only the first line it is sufficient
to qualify a verbatim paragraph. But this seems not to be used by any author
(at least not for I<real> code), and it's even not fully honoured by some Pod
parsers.

Furthermore, the only time I've found such a situation, it was I<text> (not
code) meant to really remain indented that way. Since you asked, it was the
following block:

                           columns
<------------------------------------------------------------>
<----------><------><---------------------------><----------->
 leftMargin  indent  text is formatted into here  rightMargin

from L<< Text::Format|Text::Format/DESCRIPTION >>.

That's why such blocks will be left unaltered, and that's why it's
more an advantage than a limitation (hopefully).

=item *

Working only on C<pre> tags may seem a limitation, but this is the way any
Pod to HTML transformer I'm aware of renders a Pod verbatim paragraph in HTML.

=back

=head1 AUTHOR

Emanuele Zeppieri, C<< <emazep@cpan.org> >>

=head1 BUGS

No known bugs.

Please report any bugs or feature requests to
C<bug-html-PodCodeReformat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-PodCodeReformat>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc HTML::PodCodeReformat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-PodCodeReformat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-PodCodeReformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-PodCodeReformat>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-PodCodeReformat/>

=back

=head1 SEE ALSO

=over 4

=item *

L<reformat-pre.pl>

=item *

L<perlpodspec>

=item *

L<Pod::Simple>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Emanuele Zeppieri.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation, or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut