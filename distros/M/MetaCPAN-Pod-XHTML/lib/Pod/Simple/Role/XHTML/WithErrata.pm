package Pod::Simple::Role::XHTML::WithErrata;
use Moo::Role;

our $VERSION = '0.003002';
$VERSION =~ tr/_//d;

use HTML::Entities qw(encode_entities);

use namespace::clean;

around _gen_errata => sub {
  return;    # override the default errata formatting
};

around end_Document => sub {
  my $orig = shift;
  my $self = shift;
  $self->_emit_custom_errata
    if $self->{errata};
  $self->$orig(@_);
};

sub _emit_custom_errata {
  my $self = shift;

  my $tag = sub {
    my $name       = shift;
    my $attributes = '';
    if ( ref( $_[0] ) ) {
      my $attr = shift;
      while ( my ( $k, $v ) = each %$attr ) {
        $attributes .= qq{ $k="} . encode_entities($v) . '"';
      }
    }
    my @body = map { /^</ ? $_ : encode_entities($_) } @_;
    return join( '', "<$name$attributes>", @body, "</$name>" );
  };

  my @errors = map {
    my $line  = $_;
    my $error = $self->{'errata'}->{$line};
    (
      $tag->( 'dt', "Around line $line:" ),
      $tag->( 'dd', map { $tag->( 'p', $_ ) } @$error ),
    );
  } sort { $a <=> $b } keys %{ $self->{'errata'} };

  my $error_count = keys %{ $self->{'errata'} };
  my $s = $error_count == 1 ? '' : 's';

  $self->{'scratch'} = $tag->(
    'div',
    { class => "pod-errors" },
    $tag->( 'p', "$error_count POD Error$s" ),
    $tag->(
      'div',
      { class => "pod-errors-detail" },
      $tag->(
        'p',
        'The following errors were encountered while parsing the POD:'
      ),
      $tag->( 'dl', @errors ),
    ),
  );
  $self->emit;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Pod::Simple::Role::XHTML::WithErrata - Include errata in HTML output

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::XHTML::WithErrata';

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

Adds a section to the end of the generated HTML listing Pod errors.

Example output:

  <div class="pod-errors">
    <p>1 POD Error</p>
    <div class="pod-errors-detail">
      <p>The following errors were encountered while parsing the POD:</p>
      <dl>
        <dt>Around line 219:</dt>
        <dd><p>Non-ASCII character seen before =encoding in 'Queensrÿche'. Assuming UTF-8</p></dd>
      </dl>
    </div>
  </div>

=head1 SUPPORT

See L<MetaCPAN::Pod::XHTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::XHTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::XHTML> for the copyright and license.

=cut
