package HDML::LinkExtor;

use strict;
use vars qw($VERSION @ISA);
require HTML::Parser;
require HTML::LinkExtor;
@ISA = qw(HTML::Parser HTML::LinkExtor);
$VERSION = '0.02';

my %hdml_tagset_linkelements = (
    'a'      => ['dest'],
    'action' => ['dest'],
    'ce'     => ['dest'],
    'img'    => ['src'],
);

sub new {
    my ($class, $cb, $base) = @_;
    my $self = $class->SUPER::new(
	start_h     => ["_start_tag", "self, tagname, attr"],
	report_tags => [keys %hdml_tagset_linkelements],
    );

    $self->{extractlink_cb} = $cb;
    if ($base) {
	require URI;
	$self->{extractlink_base} = URI->new($base);
    }
    return $self;
}

sub _start_tag {
    my ($self, $tag, $attr) = @_;

    my $base  = $self->{extractlink_base};
    my $links = $hdml_tagset_linkelements{$tag};
       $links = [$links] unless ref $links;

    my @links;
    for my $a (@$links) {
	next unless exists $attr->{$a};
	next if $attr->{$a} =~ /^#.*/;
	my $method   = $attr->{method} ? uc($attr->{method}) : 'GET';
	my $postdata = $attr->{postdata};
	my $absbase  = $base ?
	    URI->new($attr->{$a}, $base)->abs($base) : $attr->{$a};
	push(@links, $a, $absbase, $method, $postdata);
    }
    return unless @links;
    $self->_found_link($tag, @links);
}

1;
__END__

=head1 NAME

HDML::LinkExtor - Extract links from an HDML document

=head1 SYNOPSIS

  use HTML::LinkExtor;
  $p = HTML::LinkExtor->new(\&cb, "http://www.perl.org/");
  sub cb {
      my($tag, %links) = @_;
      print "$tag @{[%links]}\n";
  }
  $p->parse_file("index.html");

=head1 DESCRIPTION

HDML::LinkExtor is an HDML parser that extracts links from an HDML document. The HDML::LinkExtor is a subclass of HTML::LinkExtor.

=head1 AUTHOR

milano <milano@cpan.org>

=head1 SEE ALSO

HTML::LinkExtor

=cut
