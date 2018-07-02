package Pod::Simple::Role::StripVerbatimIndent;
use Moo::Role;
use namespace::clean;

around strip_verbatim_indent => sub {
  my ($orig, $self) = (shift, shift);
  if (my $strip = $self->$orig(@_)) {
    return $strip;
  }
  return sub {
    my ($para) = @_;
    for my $line (@$para) {
      while( $line =~
        s/^([^\t]*)(\t+)/$1.(" " x ((length($2)<<3)-(length($1)&7)))/e
      ) {}
    }

    my $indent = (sort map $_ =~ /^( *)./mg, @$para)[0] || '';
    $_ =~ s/^\Q$indent//mg
      for @$para;
    return;
  }
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

=head1 SUPPORT

See L<MetaCPAN::Pod::XHTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::XHTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::XHTML> for the copyright and license.

=cut
