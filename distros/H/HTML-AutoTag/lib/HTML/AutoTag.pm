package HTML::AutoTag;
use 5.006;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.08';

use HTML::Entities;
use Tie::Hash::Attribute;

our( $INDENT, $NEWLINE, $LEVEL, $ENCODE, $ENCODES, $SORTED );

sub new {
    my $self = shift;
    my $args = {@_};
    $ENCODE  = defined $args->{encode}  ? $args->{encode}  : exists $args->{encodes};
    $ENCODES = defined $args->{encodes} ? $args->{encodes} : '';
    $INDENT  = defined $args->{indent}  ? $args->{indent}  : '';
    $NEWLINE = defined $args->{indent}  ? "\n" : '';
    $LEVEL   = $args->{level} || 0;
    $SORTED  = $args->{sorted};
    bless {}, $self;
}

sub tag {
    my $self = shift;
    my %args = @_;
    my $attr = $args{attr};

    return '' unless defined $args{tag};

    my $attr_str;
    if (grep ref($_), values %$attr) {
        # complex attrs use a tied hash
        unless (grep /^-/, keys %$attr) {
            tie my %attr, 'Tie::Hash::Attribute', sorted => $SORTED;
            %attr = %$attr;
            $attr = \%attr;
        }
    } else {
        # simple attrs can bypass being tied
        $attr_str = '';
        my @keys = $SORTED ? sort keys %$attr : keys %$attr;
        for my $key (@keys) {
            $attr_str .= ' ' . Tie::Hash::Attribute::_key( $key ) . '="' . Tie::Hash::Attribute::_val( $attr->{$key} ) . '"';
        }
    }

    # emtpy tag
    unless (defined $args{cdata}) {
        return ( $INDENT x $LEVEL )
            . "<$args{tag}"
            . ( defined( $attr_str ) ? $attr_str : scalar( %$attr ) )
            . " />$NEWLINE"
        ;
    }

    my $cdata;
    my $no_post_indent;
    if (ref($args{cdata}) eq 'ARRAY') {

        if (ref($args{cdata}[0]) eq 'HASH') {

            $LEVEL++;
            $cdata = $NEWLINE;
            for (0 .. $#{ $args{cdata} }) {
                $cdata .= $self->tag( %{ $args{cdata}[$_] } );
            }
            $LEVEL--;

        } else {
            my $str = '';
            for (@{ $args{cdata} }) {
                $str .= $self->tag( tag => $args{tag}, attr => $attr, cdata => $_);
            }
            return $str;
        }

    } elsif (ref($args{cdata}) eq 'HASH') {
        $LEVEL++;
        $cdata = $NEWLINE . $self->tag( %{ $args{cdata} } );
        $LEVEL--;

    } else {
        $cdata = $ENCODE ? HTML::Entities::encode_entities( $args{cdata}, $ENCODES ) : $args{cdata};
        $no_post_indent = 1;
    }

    return ( $INDENT x $LEVEL )
        . "<$args{tag}" . ( defined( $attr_str ) ? $attr_str : scalar( %$attr ) )
        . ">$cdata"
        . ( $no_post_indent ? '' : ( $INDENT x $LEVEL ) )
        . "</$args{tag}>$NEWLINE"
    ;
}

1;

__END__
=head1 NAME

HTML::AutoTag - Just another HTML tag generator.

=head1 SYNOPSIS

  use HTML::AutoTag;

  my $auto = HTML::AutoTag->new( indent => '    ', encode => 1 );

  my %attr = ( style => { color => [qw(red green)] } );
  my @data = qw( one two three four five six seven eight );

  print $auto->tag(
      tag   => 'ol', 
      attr  => {qw( reversed reversed )},
      cdata => [
          map { tag => 'li', attr => \%attr, cdata => $_ }, @data
      ]
  );

=head1 DESCRIPTION

Generate nested HTML (HTML4, XHTML and HTML5) tags with custom indentation,
custom encoding and automatic attribute value rotation.

=head1 METHODS

=over 4

=item * C<new()>

Accepts the following arguments:

=over 8

=item * C<encode>

Encode HTML entities. Boolean. Defaults to false, which produces no encoding.
If set to true without further specifying a value for C<encodes> (see below),
will encode all control chars, high bit chars and '<', '&', '>', ''' and '"'.

  encode => 1

=item * C<encodes>

Encode HTML entities. String. Set value to those characters you wish to
have encoded.

  encodes => '<=>' 

=item * C<indent>

Pretty print results. Defaults to undef which produces no indentation.
Set value to any number of spaces or tabs and newlines will also be appended.

  indent => '    '
  indent => "\t"

=item * C<level>

Indentation level to start at. Can be used in conjunction with C<indent>
to set indentation even deeper to match any existing HTML this code
may be injected into.

  level => 2

=item * C<sorted>

Sorts the attribute names of the tag alphabetically. This is mostly
useful for ensuring consistancy. The attributes (and potential sorting)
happen within L<Tie::Hash::Attribute>. You most likely will not
need this feature.

  sorted => 1

=back

=item * C<tag()>

Accepts three arguments:

=over 8

=item * C<tag>

The name of the tag. String.

  tag => 'table'

=item * C<cdata>

The value inbetween the tag. Types allowed are:

=over 12

=item * scalar - the string to be wrapped in tags

  cdata => 'hello world'

=item * hash ref - another tag with its own cdata and attributes

  cdata => { tag => 'td', attr => {}, cdata => 'value' }

=item * AoH - multiple tags as hash references.

  cdata => [
      { tag => 'td', attr => {}, cdata => 'value1' }
      { tag => 'td', attr => {}, cdata => 'value2' }
  ]

=back

=item * C<attr>

The attributes and values to write out for the tag. Hash reference.

  attr => { border => 1 }

=back

=back

=head1 REQUIRES

=over 4

=item * L<HTML::Entities>

Used to encode unsafe HTML entities.

=item * L<Tie::Hash::Attribute>

Used to create rotating attributes.

=back

=head1 EXAMPLES

The following will render a table with rotating attributes:

  my $auto = HTML::AutoTag->new( indent => "    " );
  my %tr_attr = ( class => [qw(odd even)] );
  
  print $auto->tag(
      tag => 'table',
      attr => { class => 'spreadsheet' },
      cdata => [
          {
              tag => 'tr',
              attr => \%tr_attr,
              cdata => {
                  tag => 'td',
                  attr => { style => { color => [qw(red green)] } },
                  cdata => [qw(one two three four five six)],
              },
          },
          {
              tag => 'tr',
              attr => \%tr_attr,
              cdata => {
                  tag => 'td',
                  attr => { style => { color => [qw(green red)] } },
                  cdata => [qw(seven eight nine ten eleven twelve)],
              },
          },
          {
              tag => 'tr',
              attr => \%tr_attr,
              cdata => {
                  tag => 'td',
                  attr => { style => { color => [qw(red green)] } },
                  cdata => [qw(thirteen fourteen fifteen sixteen seventeen eighteen)],
              },
          },
      ]
  );

The following will emulate CGI.pm's C<scrolling_list()> output:

  my $auto = HTML::AutoTag->new( indent => "    " );

  print $auto->tag(
      tag   => 'select',
      attr  => { name => 'widgets', size => 3, multiple => 'multiple' },
      cdata => [
          { tag => 'option', cdata => 'foo', attr => { value => 1, } },
          { tag => 'option', cdata => 'bar', attr => { value => 2, selected => 'selected' } },
          { tag => 'option', cdata => 'baz', attr => { value => 3, selected => 'selected' } },
      ]
  );

Or in a more programatic way:

  my $auto = HTML::AutoTag->new( indent => "    " );

  my @selected = (2, 3);
  my @options  = (
      [ 1, 'foo' ],
      [ 2, 'bar' ],
      [ 3, 'baz' ],
  );

  my $selected = [];
  for my $o (@options) {
     push @$selected, (grep $_ eq $o->[0], @selected) ? 'selected' : undef;
  }
  my %attr = ( value => [ map $_->[0], @options ], selected => $selected );

  print $auto->tag(
      tag   => 'select',
      attr  => { name => 'widgets', size => scalar @options, multiple => 'multiple' },
      cdata => [ map { tag => 'option', attr => \%attr, cdata => $_->[1] }, @options ],
  );

See tests in C<t/> from the distribution or github for more examples:
L<https://github.com/jeffa/HTML-AutoTag/tree/master/t>

=head1 INSPIRATION

This module was the unintentional result of efforts to refactor
L<DBIx::XHTML_Table> into L<DBIx::HTML> and L<Spreadsheet::HTML>. The need
to reimplement what CGI and HTML::Element (and a slew of others out there
on the CPAN) do was generated from slow performance time and maintaining
the rotating attributes feature (now in L<Tie::Hash::Attribute>).

Two existing modules inspired this one: Lincoln Stein's L<CGI> has
long been able to easily produce completely arbitrary HTML text by
turning any non-defined method call into a wrapper. Gisle Aas's
L<HTML::Tree> distribution has a wonderful method (HTML::Element::new_from_lol)
which this module draws most of its interface inspiration from.

=head1 BUGS AND LIMITATIONS

If you find a situtation in which this module cannot produce what you
need please feel free to report a bug. You may report any bugs or
feature requests to either:

=over 4

=item * Email: C<bug-html-autotag at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-AutoTag>

=back

=head1 GITHUB

The Github project is L<https://github.com/jeffa/HTML-AutoTag>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::AutoTag

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-AutoTag>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/HTML-AutoTag>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/HTML-AutoTag>

=item * Search CPAN L<http://search.cpan.org/dist/HTML-AutoTag/>

=back

=head1 SEE ALSO

=over 4

=item * L<HTML::Tagset>

HTML::AutoTag takes a liberal approach to HTML creation. It does
not validate the names of the tags or the names of attributes. It
does not enforce rules for organization of the tags. HTML::Tagset
provides "data tables useful in parsing HTML," they can also be
useful here in the valid formation of HTML, if that kind of thing
concerns you.

=item * L<http://www.w3.org/TR/html5/syntax.html>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut
