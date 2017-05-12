package HTML::WikiConverter::Confluence;
use base 'HTML::WikiConverter';

use warnings;
use strict;

use URI;
use File::Basename;
our $VERSION = '0.01';

=head1 NAME

HTML::WikiConverter::Confluence - Convert HTML to Confluence markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'Confluence' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into Confluence
markup. See L<HTML::WikiConverter> for additional usage details.
More information about Confluence itself can be found at
L<http://www.atlassian.com/software/confluence/>.

=cut

sub rules {
  my $self = shift;

  my %rules = (
    # Headings
    h1 => { start => 'h1. ', line_format => 'single', trim => 'both', block => 1 },
    h2 => { start => 'h2. ', line_format => 'single', trim => 'both', block => 1 },
    h3 => { start => 'h3. ', line_format => 'single', trim => 'both', block => 1 },
    h4 => { start => 'h4. ', line_format => 'single', trim => 'both', block => 1 },
    h5 => { start => 'h5. ', line_format => 'single', trim => 'both', block => 1 },
    h6 => { start => 'h6. ', line_format => 'single', trim => 'both', block => 1 },
    
    # Text effects: http://confluence.atlassian.com/display/CONF20/Working+with+Text+Effects
    strong => { start => '*', end => '*', line_format => 'single' },
    em => { start => '_', end => '_', line_format => 'single' },
    i => { alias => 'em' },
    b => { alias => 'strong' },
    cite => { start => '??', end => '??', line_format => 'single' },
    del => { start => '-', end => '-', line_format => 'single' },
    ins => { start => '+', end => '+', line_format => 'single' },
    sup => { start => '^', end => '^', line_format => 'single' },
    sub => { start => '~', end => '~', line_format => 'single' },
    tt => { start => '{{', end => '}}', line_format => 'single' },
    blockquote => { start => 'bq. ', line_format => 'single', block => 1 },
    # missing font color

    # Text breaks: http://confluence.atlassian.com/display/CONF20/Working+with+Text+Breaks
    br => { replace => "\\\\" },
    hr => { replace => "\n\n----\n\n" },

    # Linking to web pages: http://confluence.atlassian.com/display/CONF20/Linking+to+Web+Pages
    a => { replace => \&_link },

    p => { block => 1, trim => 'both', line_format => 'single' },

    # Working with images: http://confluence.atlassian.com/display/CONF20/Displaying+an+Image
    img => { replace => \&_image },

    # Working with lists: http://confluence.atlassian.com/display/CONF20/Working+with+Lists
    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    dl => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },

    # Working with tables: http://confluence.atlassian.com/display/CONF20/Working+with+Tables
    # TODO
  );

  return \%rules;
}

# Calculates the prefix that will be placed before each list item.
# Handles ordered, unordered, and definition list items.
sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );

  my $prefix = '';
  foreach my $parent ( @parent_lists ) {
    my $bullet = '';
    $bullet = '*' if $parent->tag eq 'ul';
    $bullet = '#' if $parent->tag eq 'ol';
    $bullet = ':' if $parent->tag eq 'dl';
    $bullet = ';' if $parent->tag eq 'dl' and $node->tag eq 'dt';
    $prefix = $bullet.$prefix;
  }

  return "\n$prefix ";
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = defined $node->attr('href') ? $node->attr('href') : '';
  my $text = $self->get_elem_contents($node);

  # Handle internal links
  if( my $title = $self->get_wiki_page( $url ) ) {
    # Need to update for Confluence...
  }

  # Treat them as external links
  return "[$url]" if $url eq $text;
  return "[$text|$url]";
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return '' unless $node->attr('src');
  return $node->attr('src');
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-confluence at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-Confluence>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::Confluence

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-Confluence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-Confluence>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-Confluence>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-Confluence>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__

    pre    => { line_prefix => $pre_prefix, block => 1 },

    table   => { start => \&_table_start, end => "|}", block => 1, line_format => 'blocks' },
    tr      => { start => \&_tr_start },
    td      => { start => \&_td_start, end => "\n", trim => 'both', line_format => 'blocks' },
    th      => { start => \&_td_start, end => "\n", trim => 'both', line_format => 'single' },
    caption => { start => \&_caption_start, end => "\n", line_format => 'single' },

    # Preserved elements, from MediaWiki's Sanitizer.php (http://tinyurl.com/dzj6o)
    div        => { preserve => 1, attributes => \@block_attrs },
    span       => { preserve => 1, attributes => \@block_attrs },
    font       => { preserve => 1, attributes => [ @common_attrs, qw/ size color face / ] },

