package HTML::WikiConverter::Socialtext;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.03';

=head1 NAME

HTML::WikiConverter::Socialtext - Convert HTML to Socialtext markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'Socialtext');
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into Socialtext markup. See
L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    hr => { replace => "\n----\n" },
    br => { replace => "\n" },

    h1 => { start => '^ ',      block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => '^^ ',     block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => '^^^ ',    block => 1, trim => 'both', line_format => 'single' },
    h4 => { start => '^^^^ ',   block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => '^^^^^ ',  block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => '^^^^^^ ', block => 1, trim => 'both', line_format => 'single' },

    p      => { block => 1, line_format => 'multi' },
    b      => { start => '*', end => '*', line_format => 'single', trim => 'both' },
    strong => { alias => 'b' },
    i      => { start => '_', end => '_', line_format => 'single', trim => 'both' },
    em     => { alias => 'i' },
    u      => { start => '_', end => '_', line_format => 'single', trim => 'both' },
    strike => { start => '-', end => '-', line_format => 'single', trim => 'both' },
    s      => { alias => 'strike' },

    tt   => { start => '`', end => '`', trim => 'both', line_format => 'single' },
    code => { alias => 'tt' },
    pre  => { start => "\n.pre\n", end => "\n.pre\n", line_prefix => '', line_format => 'blocks' },

    a   => { replace => \&_link },
    img => { replace => \&_image },

    table => { block => 1, line_format => 'multi', trim => 'none' },
    tr    => { end => " |\n" },
    td    => { start => '| ', end => ' ' },
    th    => { alias => 'td' },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    li => { start => \&_li_start, trim => 'leading' },
    dl => { alias => 'ul' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },
  );

  return \%rules;
}

sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );
  my $depth = @parent_lists;

  my $bullet = '';
  $bullet = '*' if $node->parent->tag eq 'ul';
  $bullet = '>' if $node->parent->tag eq 'dl';
  $bullet = '#' if $node->parent->tag eq 'ol';

  my $prefix = ( $bullet ) x $depth;
  return "\n$prefix ";
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';
  $text =~ s/\[(.*)\]/$1/g;
  if ( $text =~ /image:/ ) { return $text };
  
  my $url_check;
  if ($url =~ /^index.cgi\?/) {
      $url_check = $url;
      $url_check =~ s/^index.cgi\?//g;
  }
  
  if( my $title = $url_check ) {
    my $title_clean = $self->_get_clean_name($title);
    my $text_clean = $self->_get_clean_name($text);
    return "[$text]" if $text_clean eq $title_clean;
    return "\"$text\"[$title]" if $text ne $title;
  } else {
    return $url if $text eq $url;
    return "\"$text\"<$url>";
  }
}

sub _get_clean_name {
    my ($self, $text) = @_;
    $text =~ s/[_\/\-']/ /g;
    $text =~ s/\%20/ /g;
    $text =~ s/(\w)/\l$1/g;
    return $text;
}

sub _image {
  my( $self, $node, $rules ) = @_;
  my $image_file = $node->attr('src');
  if ( $image_file !~ /http/) {
    $image_file =~ s/.*\/([^\/]+)$/$1/g;
    $image_file =~ s/\?action=.*$//g;
    return '{image: ' . $image_file . '} ' || '';
  } else {
    return $image_file;
  }
}

sub preprocess_node {
  my( $self, $node ) = @_;
  $self->strip_aname($node) if $node->tag eq 'a';
  return unless $node->tag;
  $self->caption2para($node) if $node->tag eq 'caption';
}



sub postprocess_output {
    my( $self, $outref ) = @_;
    # We need to deal with the weird rules we have for tables and bullets
    # with postprocessing
    $$outref =~ s/\|\n\*/\| \*/gs;
    $$outref =~ s/\|\n\#/\| \#/gs;
    $$outref =~ s/\n +\| +/ \| /gs;
    $$outref =~ s/\n +\|\n/ \|\n/gs;
}

=head1 AUTHOR

Kirsten L. Jones<< <synedra at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-kwiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-Socialtext>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::Socialtext

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-Socialtext>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-Socialtext>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-Socialtext>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-Socialtext>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Kirsten L. Jones, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
