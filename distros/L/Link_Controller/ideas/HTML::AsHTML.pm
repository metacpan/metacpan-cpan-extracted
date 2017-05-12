package HTML::AsHTML;
$REVISION=q$Revision: 1.3 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

HTML::AsHTML - Return The same HTML document as was put in.

=head1 SYNPOSIS

 @ISA qw(HTML::AsHTML);
 sub start {
   my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
   foreach (linkelts($tag)) {
     $attr->{$tag} =~ #don't you wish you had a screen as wide as mine...................
       s#^http://www.tardis.ed.ac.uk/~mikedlr/climbing#http://www.tardis.ed.ac.uk/climb/#
   }
   $self->SUPER::start(@_)
 }


=head1 DESCRIPTION

The I<HTML::AsHTML> an HTML parser that tries to return exactly what
was parsed.  In the process, it will do certain fixes to the HTML,
(such as adding quotes to all values in start tags).  As such, when it
works on correct html, it's just a glorified way of doing a 'cat' and
not much use.  However, if you override some of the methods, this lets
you build a stream editor which acts only on certain HTML elements.

In the above example, we just pass on the HTML exactly as was, but,
whenever we detect a link, we try to change it to correct for the move
of the base page of my climbing archive.

=cut

require HTML::Parser;
@ISA = qw(HTML::Parser);

=head2 $p = HTML::LinkExtor->new....#FIXME

constructor

=cut

sub new
{
    my($class) = @_;
    my $self = $class->SUPER::new;
    $self;
}

sub start
{
    my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
    return unless exists $LINK_ELEMENT{$tag};

    my $base = $self->{extractlink_base};
    my $links = $LINK_ELEMENT{$tag};
    $links = [$links] unless ref $links;

    my @links;
    my $a;
    for $a (@$links) {
	next unless exists $attr->{$a};
	push(@links, $a, $base ? url($attr->{$a}, $base)->abs : $attr->{$a});
    }
    return unless @links;

    my $cb = $self->{extractlink_cb};
    if ($cb) {
	&$cb($tag, @links);
    } else {
	push(@{$self->{'links'}}, [$tag, @links]);
    }
}

=head2 @links = $p->links

Return links found in the document as an array.  Each array element
contains an anonymous array with the follwing values:

  [$tag, $attr => $url1, $attr2 => $url2,...]

Note that $p->links will always be empty if a callback routine was
provided when the L<HTML::LinkExtor> was created.

=cut

sub links
{
    my $self = shift;
    @{$self->{'links'}}
}

# We override the parse_file() method so that we can clear the links
# before we start with a new file.
sub parse_file
{
    my $self = shift;
    delete $self->{'links'};
    $self->SUPER::parse_file(@_);
}

=head1 EXAMPLE

This is an example showing how you can extract links as a document
is received using LWP:

  use LWP::UserAgent;
  use HTML::LinkExtor;
  use URI::URL;

  $url = "http://www.sn.no/";  # for instance
  $ua = new LWP::UserAgent;

  # Set up a callback that collect image links
  my @imgs = ();
  sub callback {
     my($tag, %attr) = @_;
     return if $tag ne 'img';  # we only look closer at <img ...>
     push(@imgs, values %attr);
  }

  # Make the parser.  Unfortunately, we don't know the base yet (it might
  # be diffent from $url)
  $p = HTML::LinkExtor->new(\&callback);

  # Request document and parse it as it arrives
  $res = $ua->request(HTTP::Request->new(GET => $url), sub {$p->parse($_[0])});

  # Expand all image URLs to absolute ones
  my $base = $res->base;
  @imgs = map { $_ = url($_, $base)->abs; } @imgs;

  # Print them out
  print join("\n", @imgs), "\n";

=head1 SEE ALSO

L<HTML::Parser>

=head1 AUTHOR

Gisle Aas E<lt>aas@sn.no>

=cut

1;
