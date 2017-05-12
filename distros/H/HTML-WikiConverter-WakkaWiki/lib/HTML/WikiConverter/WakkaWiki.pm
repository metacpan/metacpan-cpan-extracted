package HTML::WikiConverter::WakkaWiki;

use warnings;
use strict;

use base 'HTML::WikiConverter';
our $VERSION = '0.50';

=head1 NAME

HTML::WikiConverter::WakkaWiki - Convert HTML to WakkaWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'WakkaWiki' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into WakkaWiki
markup. See L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    b => { start => '**', end => '**' },
    strong => { alias => 'b' },
    i => { start => '//', end => '//' },
    em => { alias => 'i' },
    u => { start => '__', end => '__' },
    tt => { start => '##', end => '##' },
    code => { start => '%%', end => '%%' },

    p => { block => 1, trim => 'both', line_format => 'multi' },
    hr => { replace => "\n----\n" },
    a => { replace => \&_link },
    img => { preserve => 1, attributes => [ qw/ src alt width height / ], start => '""', end => '""', empty => 1 },

    ul => { line_format => 'multi', block => 1, line_prefix => "\t", start => \&_list_start },
    ol => { alias => 'ul' },
    li => { line_format => 'multi', start => \&_li_start, trim => 'leading' },
  );

  for( 1..5 ) {
    my $str = ( '=' ) x (7 - $_ );
    $rules{"h$_"} = { start => "$str ", end => " $str", block => 1, trim => 'both', line_format => 'single' };
  }
  $rules{h6} = { alias => 'h5' };

  return \%rules;
}

# This is a kludge that's only used to mark the start of an ordered
# list element; there's no WakkaWiki markup to start such a list.
my %li_count = ( );
sub _list_start {
  my( $self, $node ) = @_;
  return '' unless $node->tag eq 'ol';
  $li_count{$node->address} = 0;
  return '';
}

sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol/ );

  my $bullet = '-';
  if( $node->parent->tag eq 'ol' ) {
    $bullet = ++$li_count{$node->parent->address};
    $bullet .= ')';
  }

  return "\n$bullet ";
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';
  
  if( my $title = $self->get_wiki_page($url) ) {
    $title =~ s/_/ /g;
    # [[MiXed cAsE]] ==> <a href="http://site/wiki:mixed_case">MiXed cAsE</a>
    return $text if lc $title eq lc $text and $self->is_camel_case($text);
    return "[[$title|$text]]";
  } else {
    return $url if $url eq $text;
    return "[[$url $text]]";
  }
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-wakkawiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-WakkaWiki>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::WakkaWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-WakkaWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-WakkaWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-WakkaWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-WakkaWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
