package HTML::MobileJp::Filter::PictogramFallback::TypeCast;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

has '+config' => (
    default => sub {{
        emoticon_yaml => '', # /path/to/typecast/conf/emoticon.yaml
        template      => '', # sprintf format
    }},
);

has emoticon_map => (
    is      => 'rw',
    isa     => 'Maybe[HashRef]',
    default => sub { {} },
);

use Encode;
use Encode::JP::Mobile ':props';
use YAML;

sub init {
    my $self = shift;
    my $yaml = YAML::LoadFile($self->config->{emoticon_yaml})
        or die "can't open file: ". $self->config->{emoticon_yaml};
    
    $self->emoticon_map($yaml->{docomo});
}

sub filter {
    my ($self, $html) = @_;
    
    unless ($self->mobile_agent->is_non_mobile) {
        return;
    }
    
    $html = Encode::encode('x-utf8-docomo', $html, sub { encode_utf8 chr shift} );
    $html = Encode::decode('utf-8', $html);

    $html =~ s{(\p{InMobileJPPictograms})}{
        my $char = $1;
        my $code = sprintf '%X', ord $char;
        
        if (my $name = $self->emoticon_map->{$code}) {
            sprintf $self->config->{template}, $name, $char;
        } else {
            $char;
        }

    }ge;
    
    $html;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::PictogramFallback::TypeCast - PC の場合絵文字を TypeCast の絵文字画像に

=head1 SYNOPSIS

  - module: PictogramFallback::TypeCast
    config:
      emoticon_yaml: /path/to/emoticon.yaml
      template: <img src="/img/emoticon/%s.gif" />

=head1 CONFIG AND DEFAULT VALUES

  emoticon_yaml => '', # /path/to/typecast/conf/emoticon.yaml
  template      => '', # sprintf format

=head1 DESCRIPTION

TypeCast の絵文字画像（DoCoMo 相当）にない絵文字はそのままです。
TypeCast にない絵文字について文字で表現するようにしたい場合は
L<PictogramFallback|HTML::MobileJp::Filter::PictogramFallback> と
組み合わせて以下のようにする方法があります。

  - module: PictogramFallback::TypeCast
    config:
      emoticon_yaml: /path/to/emoticon.yaml
      template: <img src="/img/emoticon/%s.gif" />
  
  - module: PictogramFallback
    config:
      template: %s
      params:
        - fallback_name_htmlescape

=head1 SEE ALSO

L<http://code.google.com/p/typecastmobile/>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
