package Pod::Simple::Role::XHTML::HTML5;
use Moo::Role;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use HTML::Entities qw(decode_entities encode_entities);
use URL::Encode qw(url_encode_utf8);

use namespace::clean;

sub BUILD {}
after BUILD => sub {
  my $self = shift;
  $self->html_doctype('<!DOCTYPE html>');
  $self->html_charset('UTF-8');
};

around html_header_tags => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig(@_)
    if @_;

  $self->{html_header_tags} ||= sprintf '<meta http-equiv="Content-Type" content="text/html; charset=%s">',
    $self->html_charset;
};

around build_index => sub {
  my $orig = shift;
  my $self = shift;

  my $index = $self->$orig(@_);

  $index =~ s{\A<ul id="index">}{<ul>};
  return "<nav>$index</nav>";
};

around emit => sub {
  my $orig = shift;
  my $self = shift;

  my $scratch = $self->{scratch};

  if ($scratch =~ /<html>/) {
    $scratch =~ s{(<link rel="stylesheet" href="[^"]*" type="text/css") />}{$1>};
    $self->{scratch} = $scratch;
  }

  $self->$orig(@_);
};

1;

=head1 NAME

Pod::Simple::Role::XHTML::HTML5 - Produce HTML5 content rather than XHTML

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::XHTML::HTML5';

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

L<Pod::Simple::XHTML> is the current state of the art formatter for producing
HTML from Pod. However, it is meant to produce XHTML, which is not the preferred
format to use at this time. When producing a full page including headers, the
self closing tags in the header will include a C<< /> >> on some tags. While
this is valid HTML, it is not the preferred format.

Using this role will remove the trailing C<< /> >> from the header tags, change
the default character set to UTF-8, include a C<< <!DOCTYPE html> >> doctype,
remove the C<id> from the index, and wrap the index with a C<< <nav> </nav> >>
element.

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut
