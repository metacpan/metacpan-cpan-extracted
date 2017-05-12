#---------------------------------------------------------------------
package HTML::Embellish;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 8, 2006
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Typographically enhance HTML trees
#---------------------------------------------------------------------

use 5.008; # Need good Unicode support; Perl 5.10 recommended but 5.8 may work
use warnings;
use strict;
use Carp qw(croak);

use Exporter 5.57 'import';     # exported import method

###open(LOG, '>:utf8', 'em.log');

#=====================================================================
# Package Global Variables:

our $VERSION = '1.002';
# This file is part of HTML-Embellish 1.002 (January 9, 2016)

our @EXPORT = qw(embellish);

my $mdash = chr(0x2014);
my $lsquo = chr(0x2018);
my $rsquo = chr(0x2019);
my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);
my $hellip = chr(0x2026);

my $notQuote = qq/[^\"$ldquo$rdquo]/;
my $balancedQuoteString = qr/(?: (?>[^ \t\n\r\pP]+)
                               | (?= [ \t\n\r\pP])$notQuote
                               | $ldquo (?>$notQuote*) $rdquo )*/x;

#=====================================================================
# Constants:
#---------------------------------------------------------------------

BEGIN
{
  my $i = 0;
  for (qw(textRefs fixQuotes fixDashes fixEllipses fixEllipseSpace fixHellip
          totalFields)) {
    ## no critic (ProhibitStringyEval)
    eval "sub $_ () { $i }";
    ++$i;
  }
} # end BEGIN

#=====================================================================
# Exported functions:
#---------------------------------------------------------------------
sub embellish
{
  my $html = shift @_;

  croak "First parameter of embellish must be an HTML::Element"
      unless ref $html and $html->can('content_refs_list');

  my $e = HTML::Embellish->new(@_);
  $e->process($html);
} # end embellish

#=====================================================================
# Class Methods:
#---------------------------------------------------------------------
sub new
{
  my $class = shift;
  croak "Odd number of parameters passed to HTML::Embellish->new" if @_ % 2;
  my %parms = @_;

  my $self = [ (undef) x totalFields ];
  bless $self, $class;

  my $def = (exists $parms{default} ? $parms{default} : 1);

  $self->[textRefs]    = undef;
  $self->[fixDashes]   = (exists $parms{dashes}   ? $parms{dashes}   : $def);
  $self->[fixEllipses] = (exists $parms{ellipses} ? $parms{ellipses} : $def);
  $self->[fixQuotes]   = (exists $parms{quotes}   ? $parms{quotes}   : $def);

  $self->[fixHellip]       = (exists $parms{hellip}
                              ? $parms{hellip} : $self->[fixEllipses]);
  $self->[fixEllipseSpace] = (exists $parms{space_ellipses}
                              ? $parms{space_ellipses} : $self->[fixEllipses]);

  return $self;
} # end new

#---------------------------------------------------------------------
# Convert quotes & apostrophes into curly quotes:
#
# Input:
#   self:  The HTML::Embellish object
#   refs:  Arrayref of stringrefs to the text of this paragraph

sub processTextRefs
{
  my ($self, $refs) = @_;

  local $_ = join('', map { $$_ } @$refs);
  utf8::upgrade($_);

  my $fixQuotes = $self->[fixQuotes];
  if ($fixQuotes) {
    s/\("/($ldquo/g;
    s/"\)/$rdquo)/g;

    s/^([\xA0\s]*)"/$1$ldquo/;
    s/(?<=[\s\pZ])"(?=[^\s\pZ])/$ldquo/g;
    s/(?<=\pP)"(?=\w)/$ldquo/g;
    s/(?<=[ \t\n\r])"(?=\xA0)/$ldquo/g;

    s/"[\xA0\s]*$/$rdquo/;
    s/(?<![\s\pZ])"(?=[\s\pZ])/$rdquo/g;
    s/(?<=\w)"(?=\pP)/$rdquo/g;
    s/(?<=\xA0)"(?=[ \t\n\r]|[\s\xA0]+$)/$rdquo/g;
    s/(?<=[,;.!?])"(?=[-$mdash])/$rdquo/go;

    s/'(?=
        (?: angmans?
          | aves?
          | ay
          | cause
          | cept
          | d
          | e[mr]?e?
          | fraidy?
          | gainst
          | igh\w*
          | im
          | m
          | n
          | nam
          | nothers?
          | nuff
          | onou?rs?
          | re?
          | rithmetic
          | s
          | scuse
          | spects?
          | t
          | til
          | tisn?
          | tw(?:asn?|ere?n?|ould\w*)
          | ud
          | uns?
          | y
        ) \b
        | \d\d\W?s
        | \d\d(?!\w)
       )
     /$rsquo/igx;

    s/'([ \xA0]?$rdquo)/$rsquo$1/go;

    s/`/$lsquo/g;
    s/^'/$lsquo/;
    s/(?<=[\s\pZ])'(?=[^\s\pZ])/$lsquo/g;
    s/(?<=\pP)(?<![.!?])'(?=\w)/$lsquo/g;
    s/(?<=[ \t\n\r])'(?=\xA0)/$lsquo/g;

    s/'/$rsquo/g;

    s/(?<!\PZ)"([\xA0\s]+$lsquo)/$ldquo$1/go;
    s/(${rsquo}[\xA0\s]+)"(?!\PZ)/$1$rdquo/go;

    if (/"/) {
      1 while s/^($balancedQuoteString (?![\"$ldquo$rdquo])[ \t\n\r\pP]) "
               /$1$ldquo/xo
          or  s/^($balancedQuoteString $ldquo $notQuote*) "/$1$rdquo/xo;
    } # end if straight quotes remaining in string

    #s/(?<=\p{IsPunct})"(?=\p{IsAlpha})/$ldquo/go;
    s/(?<=[[:punct:]])"(?=[[:alpha:]])/$ldquo/go;

    s/${ldquo}\s([$lsquo$rsquo])/$ldquo\xA0$1/go;
    s/${rsquo}\s$rdquo/$rsquo\xA0$rdquo/go;
  } # end if fixQuotes

  if ($self->[fixEllipses]) {
    s/( [\"$ldquo$lsquo] \.(?:\xA0\.)+ ) \s /$1\xA0/xog;
    s/\s (?= \. (?:\xA0[.,!?])+ [$rdquo$rsquo\xA0\"]* $)/\xA0/xo;
  }

  # Return the text to where it came from:
  #   This only works because the replacement text is always
  #   the same length as the original.
  foreach my $r (@$refs) {
    $$r = substr($_, 0, length($$r), '');
    if ($fixQuotes) {
      # Since the replacement text isn't the same length,
      # these can't be done on the string as a whole:
      $$r =~ s/(?<=[$ldquo$rdquo])(?=[$lsquo$rsquo])/\xA0/go;
      $$r =~ s/(?<=[$lsquo$rsquo])(?=[$ldquo$rdquo])/\xA0/go;
      $$r =~ s/(?<=[$ldquo$lsquo])\xA0(?=\.\xA0\.)//go;
    } # end if fixQuotes
  } # end foreach @$refs
} # end processTextRefs

#---------------------------------------------------------------------
# Recursively process an HTML::Element tree:

sub process
{
  my ($self, $elt) = @_;

  croak "HTML::Embellish->process must be passed an HTML::Element"
      unless ref $elt and $elt->can('content_refs_list');

  return if $elt->is_empty;

  my $parentRefs;
  my $isP = ($elt->tag =~ /^(?: p | h\d | d[dt] | div | blockquote | title )$/x);

  if ($isP and ($self->[fixQuotes] or $self->[fixEllipses])) {
    $parentRefs = $self->[textRefs];
    $self->[textRefs] = []
  } # end if need to collect text refs

  $elt->normalize_content;
  my @content = $elt->content_refs_list;

  if ($self->[fixQuotes] and $self->[textRefs] and @content) {
    # A " that opens a tag can be assumed to be a left quote
    ${$content[ 0]} =~ s/^"/$ldquo/ unless ref ${$content[ 0]};
    # A " that ends a tag can be assumed to be a right quote
    ${$content[-1]} =~ s/"$/$rdquo/ unless ref ${$content[-1]};
  }

  foreach my $r (@content) {
    if (ref $$r) { # element node
      my $tag = $$r->tag;
      next if $tag =~ /^(?: ~comment | script | style )$/x;

      if ($self->[textRefs] and $tag eq 'br') {
        my $break = "\n";
        push @{$self->[textRefs]}, \$break;
      }
      $self->process($$r);
    } else { # text node
      # Convert -- to em-dash:
      utf8::upgrade($$r);
      if ($self->[fixDashes]) {
        $$r =~ s/(?<!-)---?(?!-)/$mdash/g; # &mdash;
        $$r =~ s/(?<!-)----(?!-)/$mdash$mdash/g;
      } # end if fixDashes

      $$r =~ s/$hellip/.../go if $self->[fixHellip];

      # Fix ellipses:
      if ($self->[fixEllipses]) {
        $$r =~ s/(?<!\.)\.\.\.([.?!;:,])(?!\.)/.\xA0.\xA0.\xA0$1/g;
        $$r =~ s/(?<!\.)\.\.\.(?!\.)/.\xA0.\xA0./g;
        $$r =~ s/(?<= \.) [^\PZ\x{200B}] (?=[.,?!])/\xA0/gx;
        $$r =~ s/(?:(?<=\w)|\A) (\.\xA0\.\xA0\.|\.\.\.)(?=[ \xA0\n\"\'?!$rsquo$rdquo])(?![ \xA0\n]+\w)/\xA0$1/go;
      } # end if fixEllipses

      if ($self->[fixEllipseSpace]) {
        $$r =~ s/(?<=\w) (\.(?:\xA0\.)+) (?=\w)/ $1 /gx;
        $$r =~ s/(?<=\w[!?,;]) (\.(?:\xA0\.)+) (?=\w)/ $1 /gx;
        $$r =~ s/( [\"$ldquo$lsquo] \.(?:\xA0\.)+ ) (?=\w) /$1\xA0/xog;
        $$r =~ s/(?<=\w) (\.\xA0\.\xA0\.) (?![\xA0\w])/\xA0$1/gx;

        if ($self->[textRefs] and @{$self->[textRefs]}) {
          $$r =~ s/^(\.(?:\xA0\.)+) (?=\w)/ $1 /gx
              if ${$self->[textRefs][-1]} =~ /\w[!?,;]?$/;

          ${$self->[textRefs][-1]} =~ s/(?<=\w)\xA0(\.\xA0\.\xA0\.)$/ $1 /
              if $$r =~ /^\w/;
        }
      } # end if fixEllipseSpace

      push @{$self->[textRefs]}, $r if $self->[textRefs];
    } # end else text node
  } # end foreach $r

  if ($isP and $self->[textRefs]) {
###    print LOG (map { utf8::is_utf8($$_) . "{$$_}" } @{ $self->[textRefs] }), "\n";
    $self->processTextRefs($self->[textRefs]);
    push @$parentRefs, @{$self->[textRefs]} if $parentRefs;
    $self->[textRefs] = $parentRefs;
  } # end if this was a paragraph-like element
} # end process

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

HTML::Embellish - Typographically enhance HTML trees

=head1 VERSION

This document describes version 1.002 of
HTML::Embellish, released January 9, 2016.

=head1 SYNOPSIS

    use HTML::Embellish;
    use HTML::TreeBuilder;

    my $html = HTML::TreeBuilder->new_from_file(...);
    embellish($html);

=head1 DESCRIPTION

HTML::Embellish adds typographical enhancements to HTML text.  It
converts certain ASCII characters to Unicode characters.  It converts
quotation marks and apostrophes into curly quotes.  It converts
hyphens into em-dashes.  It inserts non-breaking spaces between the
periods of an ellipsis.  (It doesn't use the HORIZONTAL ELLIPSIS
character (U+2026), because I like more space in my ellipses.)

=head1 INTERFACE

=over

=item C<embellish($html, ...)>

This subroutine (exported by default) is the main entry point.  It's a
shortcut for C<< HTML::Embellish->new(...)->process($html) >>.

If you're going to process several trees with the same parameters, the
object-oriented interface will be slightly more efficient.

=item C<< $emb = HTML::Embellish->new(flag => value, ...) >>

This creates an HTML::Embellish object that will perform the specified
enhancements.  These are the (optional) flags that you can pass:

=over

=item C<dashes>

If true, converts sequences of hyphens into em-dashes.  Two or 3
hyphens become one em-dash.  Four hyphens become two em-dashes.  Any
other sequence of hyphens is not changed.

=item C<ellipses>

If true, inserts non-breaking spaces between the periods making up an
ellipsis.  Also converts the space before an ellipsis that appears to
end a sentence to a non-breaking space.

=item C<hellip>

If true, converts the &hellip; character to 3 periods.  (To insert
non-breaking spaces between them, also set C<ellipses> to true.)  This
defaults to the value of C<ellipses>.

=item C<space_ellipses>

If true, adds whitespace around ellipses when necessary.  This
defaults to the value of C<ellipses>.

=item C<quotes>

If true, converts quotation marks and apostrophes into curly quotes.

=item C<default>

This is the default value used for flags that you didn't specify.  It
defaults to 1 (enabled).  The main reason for using this flag is to
disable any enhancements that might be introduced in future versions
of HTML::Embellish.

=back

=item C<< $emb->process($html) >>

The C<process> method enhances the content of the HTML::Element you
pass in.  You can pass the root element to process the entire tree, or
any sub-element to process just that part of the tree.  The tree is
modified in-place; the return value is not meaningful.

=back

=head1 DIAGNOSTICS

=over

=item C<< First parameter of embellish must be an HTML::Element >>

You didn't pass a valid HTML::Element object to embellish.

=item C<< HTML::Embellish->process must be passed an HTML::Element >>

You didn't pass a valid HTML::Element object to embellish.

=item C<< Odd number of parameters passed to HTML::Embellish->new >>

C<< HTML::Embellish->new >> takes parameters in C<< KEY => VALUE >>
style, so there must always be an even number of them.

=back

=head1 CONFIGURATION AND ENVIRONMENT

HTML::Embellish requires no configuration files or environment variables.

=head1 DEPENDENCIES

Requires the L<HTML::Tree> distribution from CPAN (or some other module
that implements the L<HTML::Element> interface).  Versions of HTML::Tree
prior to 3.21 had some bugs involving Unicode characters and
non-breaking spaces.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

I've experienced occasional segfaults when using this module with Perl
5.8.8.  Since a pure-Perl module like this shouldn't be able to cause
a segfault, I believe the issue is with Perl 5.8.  I recommend using
Perl 5.10 if at all possible, as the files that segfaulted under 5.8.8
worked fine with 5.10.


=for Pod::Coverage
^parDepth$
^processTextRefs$
^textRefs$
^fixQuotes$
^fixDashes$
^fixEllipses$
^fixEllipseSpace$
^fixHellip$
^totalFields$

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-HTML-Embellish AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Embellish >>.

You can follow or contribute to HTML-Embellish's development at
L<< https://github.com/madsen/html-embellish >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
