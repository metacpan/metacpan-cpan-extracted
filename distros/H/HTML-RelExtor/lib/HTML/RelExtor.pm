package HTML::RelExtor;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use HTML::Parser;
use URI;

use base qw(HTML::Parser);

sub new {
    my($class, %args) = @_;
    my $self = $class->SUPER::new(
	start_h     => [ "_start_tag", "self,tagname,attr" ],
	report_tags => [ qw(a link base) ],
    );
    if (my $base = delete $args{base}) {
	$self->{relextor_base} = $base;
    }
    $self;
}

sub _start_tag {
    my($self, $tag, $attr) = @_;

    # If there's <base href="...">, change the base URL
    if ($tag eq 'base' && exists $attr->{href}) {
	$self->{relextor_base} = $attr->{href};
	return;
    }

    # no 'rel' nor 'rev' attribute
    return unless exists $attr->{rel} or exists $attr->{rev};

    my $href = $attr->{href} or return;
    $href = URI->new_abs($href, $self->{relextor_base})->as_string
	if $self->{relextor_base};
    my $link = HTML::RelExtor::Link->new($tag, $href, $attr);
    if ($tag eq 'a') {
	$self->handler(text => sub {
			   my($self, $text) = @_;
			   $link->{text} = $text;
			   $self->handler(text => undef);
		       }, "self,dtext");
    }
    push @{$self->{links}}, $link;
}

sub links {
    my $self = shift;
    my %args = @_;
    my @links = $self->{links} ? @{$self->{links}} : ();

    if ($args{rel} && $args{rev}) {
        Carp::croak("You can't pass both rev and rel to the links()");
    }

    if ($args{rel}) {
        @links = grep $_->has_rel($args{rel}), @links;
    } elsif ($args{rev}) {
        @links = grep $_->has_rev($args{rev}), @links;
    }

    return @links;
}

sub parse_file {
    my $self = shift;
    delete $self->{links};
    $self->SUPER::parse_file(@_);
}

package HTML::RelExtor::Link;

sub new {
    my($class, $tag, $href, $attr) = @_;
    my @rel = grep length, split /\s+/, ($attr->{rel} || '');
    my @rev = grep length, split /\s+/, ($attr->{rev} || '');
    bless {
	tag  => $tag,
	href => $href,
	attr => $attr,
	rel  => \@rel,
	rev  => \@rev,
    }, $class;
}

sub tag {
    my $self = shift;
    $self->{tag};
}

sub href {
    my $self = shift;
    $self->{href};
}

sub attr {
    my $self = shift;
    $self->{attr};
}

sub rel {
    my $self = shift;
    @{$self->{rel}};
}

sub rev {
    my $self = shift;
    @{$self->{rev}};
}

sub has_rel {
    my($self, $tag) = @_;
    scalar grep { $_ eq $tag } $self->rel;
}

sub has_rev {
    my($self, $tag) = @_;
    scalar grep { $_ eq $tag } $self->rev;
}

sub text {
    my $self = shift;
    $self->{text};
}

1;
__END__

=head1 NAME

HTML::RelExtor - Extract "rel" and "rev" information from LINK and A tags.

=head1 SYNOPSIS

  use HTML::RelExtor;

  my $parser = HTML::RelExtor->new();
  $parser->parse($html);

  for my $link ($parser->links) {
      print $link->href, "\n" if $link->has_rel('nofollow');
  }

  my($canonical) = grep $_->has_rev('canonical'), $parser->links;
  if ($canonical) {
      $shorten_url = $canonical->href;
  }

=head1 DESCRIPTION

HTML::RelExtor is a HTML parser module to extract relationship information from C<A> and L<LINK> HTML tags.

=head1 METHODS

=over 4

=item new

  $parser = HTML::RelExtor->new();
  $parser = HTML::RelExtor->new(base => $base_uri);

Creates new HTML::RelExtor object.

=item parse

  $parser->parse($html);

Parses HTML content. See L<HTML::Parser> for other method signatures.

=item links

  my @links = $parser->links();
  my @links = $parser->links(rel => 'alternate');
  my @links = $parser->links(rev => 'canonical');

Returns list of link information with 'rel' or 'rev' attributes as a
HTML::RelExtor::Link object. When given I<rel> or I<rev> parameter,
returns only links that has the I<rel> or I<rev> value.

  # These are equivalent
  @links = $parser->links(rel => 'alternate');
  @links = grep $_->has_rel('alternate'), $parser->links;

=back

=head1 HTML::RelExtor::Link METHODS

=over 4

=item href

  my $href = $link->href;

Returns 'href' attribute of links.

=item tag

  my $tag = $link->tag;

Returns tag name of links in lowercase, either 'a' or 'link';

=item attr

  my $attr = $link->attr;

Returns a hash reference of attributes of the tag.

=item rel

  my @rel = $link->rel;

Returns list of 'rel' attributes. If a link contains C<< <a href="tag nofollow">blahblah</a> >>, C<rel()> method returns a list that contains C<tag> and C<nofollow>.

=item rev

  my @rev = $link->rev;

Returns list of 'rev' attributes.

=item has_rel

  if ($link->has_rel('nofollow')) { }

A handy shortcut method to find out if a link contains specific relationship.

=item has_rev

  if ($link->has_rev('canonical')) { }

A handy shortcut method to find out if a link contains specific reverse relationship.

=item text

  my $text = $link->text;

Returns text inside tags, only avaiable with A tags. It returns undef value when called with LINK tags.

=back

=head1 EXAMPLES

Collect A links tagged with C<< rel="friend" >> used in XFN (XHTML Friend Network).

  my $p = HTML::RelExtor->new();
  $p->parse($html);

  my @links = map { $_->href }
      grep { $_->tag eq 'a' && $_->has_rel('friend') } $p->links;

=head1 TODO

=over 4

=item *

Accept callback parameter when creating a new instance.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa at bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::LinkExtor>, L<HTML::Parser>

L<http://www.w3.org/TR/REC-html40/struct/links.html>

L<http://www.google.com/googleblog/2005/01/preventing-comment-spam.html>

L<http://developers.technorati.com/wiki/RelTag>

L<http://gmpg.org/xfn/11>

L<http://shiflett.org/blog/2009/apr/save-the-internet-with-rev-canonical>

=cut
