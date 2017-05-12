package HTML::MobileJp::Filter::DoCoMoCSS;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

has '+config' => (
    default => sub {{
        base_dir                => '',
        xml_declaration_replace => 1,
        xml_declaration         => <<'END'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
END
    ,
    }},
);

use Encode;
use HTML::DoCoMoCSS;

sub filter {
    my ($self, $content) = @_;
    
    unless ($self->mobile_agent->is_docomo) {
        return;
    }

    if ($self->config->{xml_declaration_replace}) {
        # instead of $doc->setEncoding etc..
        $content =~ s/.*(<html)/$self->config->{xml_declaration} . "\n$1"/msei;
    }
     
    my $inliner = HTML::DoCoMoCSS->new(base_dir => $self->config->{base_dir});
    $content = $inliner->apply($content);
    $content = Encode::decode_utf8($content);
}

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::DoCoMoCSS - DoCoMo の場合 <link> の CSS をインライン展開

=head1 SYNOPSIS

  - module: EntityReference
    config:
      base_dir: /path/to/documentroot

=head1 CONFIG AND DEFAULT VALUES

  base_dir                => '',
  xml_declaration_replace => 1,
  xml_declaration         => <<'END'
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
  END

XML 宣言や DTD がないと文字が全部実体参照になったりうまく parse できないので
ヘッダを付け替えることで HTML::DoCoMoCSS の中の XML::libXML に指示をしています。

TODO のHTML::MobileJp::Filter 側で XML オブジェクトを持つようになった際に
もっと良い方法で指定できるようになる予定です。

=head1 SEE ALSO

L<HTML::DoCoMoCSS>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
