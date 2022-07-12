package Pod::Simple::Role::StripVerbatimIndent;
use Moo::Role;

our $VERSION = '0.003001';
$VERSION =~ tr/_//d;

use Scalar::Util qw(weaken);

use namespace::clean;

requires 'expand_verbatim_tabs';

my $gen_strip_verbatim_indent = sub {
  my $self = shift;
  weaken $self;
  sub {
    my ($para) = @_;

    if (my $tab_width = $self->expand_verbatim_tabs) {
      # ugly to be modifying this, but we need the initial tabs expanded first
      for my $line (@$para) {
        1 while $line =~ s{\A( *)(\t+)}{
          my $expand = $tab_width * length($2) - length($1) % $tab_width;
          $1 . (" " x $expand);
        }e;
      }
    }

    my @indents = map /\A([ \t]+)/, @$para;
    my $longest_indent = shift @indents;

    for my $indent (@indents) {
      if (length $indent < length $longest_indent) {
        ($longest_indent, $indent) = ($indent, $longest_indent);
      }

      chop $longest_indent
        while index($indent, $longest_indent) != 0;

      last
        if $longest_indent eq '';
    }

    return $longest_indent;
  };
};

sub BUILD {}

after BUILD => sub {
  my $self = shift;
  $self->expand_verbatim_tabs(0);
  $self->strip_verbatim_indent($self->$gen_strip_verbatim_indent);
};

1;

=encoding UTF-8

=head1 NAME

Pod::Simple::Role::StripVerbatimIndent - Strip indentation from verbatim sections sanely

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::StripVerbatimIndent;

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

Strips the indentation from verbatim blocks, while not corrupting tab indents.

The shortest indentation in the verbatim block (excluding empty lines) will be
stripped from all lines.

By default, using this role will disable tab expansion. It can be re-enabled
using L<< expand_verbatim_tabs|Pod::Simple/$parser->expand_verbatim_tabs( I<n> ) >>

=head1 SUPPORT

See L<MetaCPAN::Pod::XHTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::XHTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::XHTML> for the copyright and license.

=cut
