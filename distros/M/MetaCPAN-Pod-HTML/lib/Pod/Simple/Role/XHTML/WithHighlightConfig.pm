package Pod::Simple::Role::XHTML::WithHighlightConfig;
use Moo::Role;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use HTML::Entities qw(encode_entities);

use namespace::clean;

with 'Pod::Simple::Role::WithHighlightConfig';

around start_highlight => sub {
  my ($orig, $self, $item, $config) = @_;
  $self->$orig($item, $config);
  $config ||= {};
  my $tag = '<pre';
  my @classes;
  if ($config->{line_numbers}) {
    push @classes, 'line-numbers';
    if ($config->{start_line}) {
      $tag .= ' data-start="' . encode_entities($config->{start_line}) . '"';
    }
  }
  if ($config->{highlight}) {
    $tag .= ' data-line="' . encode_entities($config->{highlight}) . '"';
  }
  if (@classes) {
    $tag .= ' class="' . join (' ', @classes) . '"';
  }
  $tag .= '><code';
  if ($config->{language}) {
    my $lang = lc $config->{language};
    $lang =~ s/\+/p/g;
    $lang =~ s/\W//g;
    $tag .= ' class="language-' . $lang . '"';
  }
  $tag .= '>';
  $self->{scratch} = $tag;
};

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::WithHighlightConfig - Allow configuring syntax highlighting hints in Pod

=head1 SYNOPSIS

  # using in Pod

  =head1 SYNOPSIS

  =for highlighter language=javascript

    var date = new Date();

  =for highlighter language=perl line_numbers=1 start_line=5

    my @array = map { $_ + 1 } (5..10);

  =for highlighter

    No language set

  =for highlighter perl

    use Class;
    my $var = Class->new;


  # using the role
  package My::Pod::Simple::Subclass;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::XHTML::WithHighlightConfig';

=head1 DESCRIPTION

This module allows adding syntax highlighter hints to a Pod document to be
rendered as XHTML.  Normally, verbatim blocks will be represented inside
C<< <pre><code>...</code></pre> >> tags.  The information will be represented
as class names and data attributes on those tags.

Configuration values effect all verbatim blocks until the next highlighter
configuration directive.

=head1 CONFIGURATION

The configuration must be specified in a C<=for highlighter> block, as a
whitespace separated list of settings.  Each setting must be in the form
C<< <key>=<value> >>.  Alternately, a bare option without an C<=> can be used
to specify the language setting.

=over 4

=item language

This is the language to highlight the verbatim blocks with.  It will be
represented as a C<language-$language> class on the C<< <code> >> tag.

=item line_numbers

A true or false value indicating if line numbers should be included.  If true,
it will be represented as a C<line-numbers> class on the C<< <pre> >> block.

=item start_line

A number for what to start numbering lines as rather than starting at 1.  Only
valid when the C<line_numbers> option is enabled.  It will be represented as a
C<data-start> attribute on the C<< <pre> >> block.

=item highlight

A comma separated list of lines or line ranges to highlight, such as C<5>,
C<4-10>, or C<1,4-6,10-14>.  It will be represented as a C<data-line> attribute
on the C<< <pre> >> block.

=back

=head1 SEE ALSO

=over 4

=item Modules Supporting the same configuration format

=over 4

=item *

L<TOBYINK::Pod::HTML> - Another Pod to HTML converter

=item *

L<App::sdview::Parser::Pod> - A terminal documentation viewer

=item *

L<Pod::Markdown::Githubert> - Pod to Markdown converter

=back

=item Users of HTML Attributes

=over 4

=item *

L<HTML5 code element|https://html.spec.whatwg.org/multipage/text-level-semantics.html#the-code-element>
- Semantics for highlighting encouraged by the HTML5 spec

=item *

L<Prism|https://prismjs.com/> - A javascript syntax highlighter supporting the
classes and attributes used by this module

=back

=back

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut
