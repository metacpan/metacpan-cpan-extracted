package HTML::Link_Miner;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

HTML::Link_Miner - return links in a document along with information

=head1 SYNOPSIS

 require HTML::Link_Miner;
 $p = HTML::Link_Miner->new(\&cb, "http://www.sn.no/");

 #this is not correct
 sub cb {
     my($tag, %links) = @_;
     print "$tag @{[%links]}\n";
 }
 $p->parse_file("index.html");

=head1 DESCRIPTION

This is currently just an idea and is not implemented yet

HTML::Link_Miner is a link extractor.  The I<HTML::Link_Miner> is a
subclass of I<HTML::Parser>. This means that the document should be
given to the parser by calling the $p->parse() or $p->parse_file()
methods.

The difference between HTML::LinkExtor and this module is that we try
to find all of the useful information we can about each link from the
document.

With the HREF from C<< <A> >> tags we return the text between the
start and end tags.

#With the HREF from C<< <IMG> >> tags we return any C<ALT> text.

With other links, we return the attribute name

=head1 INTERFACE

call backs for each link type??

=cut

require HTML::Parser;
@ISA = qw(HTML::Parser);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use strict;
use HTML::Tagset ();

=over 4

=item $p = HTML::LinkExtor->new([$callback[, $base]])

The constructor takes two optional arguments. The first is a reference
to a callback routine. It will be called as links are found. If a
callback is not provided, then links are just accumulated internally
and can be retrieved by calling the $p->links() method.

The $base argument is an optional base URL used to absolutize all URLs found.
You need to have the I<URI> module installed if you provide $base.

The callback is called with the lowercase tag name as first argument,
and then all link attributes as separate key/value pairs.  All
non-link attributes are removed.

=cut

sub new
{
    my($class, $cb, $base) = @_;
    my $self = $class->SUPER::new(start_h => ["_start_tag",
					      "self,tagname,attr"]);
    $self->{extractlink_cb} = $cb;
    if ($base) {
	require URI;
	$self->{extractlink_base} = URI->new($base);
    }
    $self;
}

sub _start_tag
{
    my($self, $tag, $attr) = @_;
    return unless exists $HTML::Tagset::linkElements{$tag};

    my $base = $self->{extractlink_base};
    my $links = $HTML::Tagset::linkElements{$tag};
    $links = [$links] unless ref $links;

    my @links;
    my $a;
    for $a (@$links) {
	next unless exists $attr->{$a};
	push(@links, $a, $base ? URI->new($attr->{$a}, $base)->abs($base)
                               : $attr->{$a});
    }
    return unless @links;
    $self->_found_link($tag, @links);
}

sub _found_link
{
    my $self = shift;
    my $cb = $self->{extractlink_cb};
    if ($cb) {
	&$cb(@_);
    } else {
	push(@{$self->{'links'}}, [@_]);
    }
}

=item $p->links

Returns a list of all links found in the document.  The returned
values will be anonymous arrays with the follwing elements:

  [$tag, $attr => $url1, $attr2 => $url2,...]

The $p->links method will also truncate the internal link list.  This
means that if the method is called twice without any parsing
between them the second call will return an empty list.

Also note that $p->links will always be empty if a callback routine
was provided when the I<HTML::LinkExtor> was created.

=cut

sub links
{
    my $self = shift;
    exists($self->{'links'}) ? @{delete $self->{'links'}} : ();
}

# We override the parse_file() method so that we can clear the links
# before we start a new file.
sub parse_file
{
    my $self = shift;
    delete $self->{'links'};
    $self->SUPER::parse_file(@_);
}

=back

=head1 EXAMPLE

This is an example showing how you can extract links from a document
received using LWP:

  use LWP::UserAgent;
  use HTML::LinkExtor;
  use URI;

  $url = "http://www.sn.no/";  # for instance
  $ua = new LWP::UserAgent;

  # Set up a callback that collect image links
  my @imgs = ();
  sub callback {
     my($tag, %attr) = @_;
     return if $tag ne 'img';  # we only look closer at <img ...>
     push(@imgs, values %attr);
  }

  # Make the parser.  Unfortunately, we don't know the base yet
  # (it might be diffent from $url)
  $p = HTML::LinkExtor->new(\&callback);

  # Request document and parse it as it arrives
  $res = $ua->request(HTTP::Request->new(GET => $url),
                      sub {$p->parse($_[0])});

  # Expand all image URLs to absolute ones
  my $base = $res->base;
  @imgs = map { $_ = url($_, $base)->abs; } @imgs;

  # Print them out
  print join("\n", @imgs), "\n";

=head1 SEE ALSO

L<HTML::Parser>, L<HTML::Tagset>, L<LWP>, L<URI>

=head1 COPYRIGHT

Based on LinkExtor and Copyright 1996-2000 Gisle Aas.

Copyright 2001 Michael De La Rue

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

