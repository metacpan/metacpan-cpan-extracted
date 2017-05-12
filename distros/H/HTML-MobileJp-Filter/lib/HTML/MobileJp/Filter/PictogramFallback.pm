package HTML::MobileJp::Filter::PictogramFallback;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

has '+config' => (
    default => sub {{
        template => '', # sprintf format
        params   => [], # Encode::JP::Mobile::Charnames method names
    }},
);

use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Charnames;

sub filter {
    my ($self, $content) = @_;
    
    unless ($self->mobile_agent->is_non_mobile) {
        return;
    }
    
    $content =~ s{(\p{InMobileJPPictograms})}{
        my $char = Encode::JP::Mobile::Character->from_unicode(ord $1);
        my @param;
        for my $param (@{ $self->config->{params} }) {
            if ($self->can($param)) {
                push @param, $self->$param($char);
            } else {
                push @param, $char->$param();
            }
        }
        sprintf $self->config->{template}, @param;
    }ge;
    
    $content;
}

my %htmlspecialchars = ( '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' );
my $htmlspecialchars = join '', keys %htmlspecialchars;

sub fallback_name {
    my ($self, $char) = @_;
    my $fallback;
    $fallback ||= $char->fallback_name($_) for qw( I V E );
    $fallback || "";
}

sub fallback_name_htmlescape {
    my ($self, $char) = @_;
    my $fallback = $self->fallback_name($char);
    $fallback =~ s/([$htmlspecialchars])/$htmlspecialchars{$1}/ego;
    $fallback;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::PictogramFallback - PC の場合の絵文字の代替表現

=head1 SYNOPSIS

  - module: PictogramFallback
    config:
      template: <img src="/img/pictogram/%s.gif" />
      params:
        - unicode_hex

=head1 CONFIG AND DEFAULT VALUES

  template => '', # sprintf format
  params   => [], # Encode::JP::Mobile::Charnames method names

params で Encode::JP::Mobile::Charnames のメソッドとは別に特別に
使えるものは以下のとおりです。

=over 4

=item fallback_name
  
  - module: PictogramFallback
    config:
      template: %s
      params:
        - fallback_name

C<fallback_name('I')> か C<fallback_name('E')> か C<fallback_name('V')> を
返します。C<< (>３<) >> のように出ます。

=item fallback_name_htmlescape
  
  - module: PictogramFallback
    config:
      template: <img src="/img/pictogram/%s.gif" alt="%s" />
      params:
        - unicode_hex
        - fallback_name_htmlescape

C<< <img src="/img/pictogram/ECA2.gif" alt="(&amp;gt;３&amp;lt;)" /> >> のように出ます。

=back

=head1 SEE ALSO

L<Encode::JP::Mobile>, L<Encode::JP::Mobile::Charnames>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
