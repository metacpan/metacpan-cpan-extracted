package Email::MIME::MobileJP::Creator;
use strict;
use warnings;
use utf8;

use Email::MIME;
use Email::Address::JP::Mobile;
use Email::Address::Loose -override;
use Carp ();

sub new {
    my ($class, $to) = @_;
    Carp::croak("missing To") unless defined $to;

    my $mail = Email::MIME->create();
    my $carrier = Email::Address::JP::Mobile->new($to);
    my $self = bless { mail => $mail, carrier => $carrier }, $class;
    if ($to) {
        $self->header('To' => $to);
    }
    $self->mail->charset_set($carrier->send_encoding->mime_name);
    return $self;
}

sub mail { $_[0]->{mail} }
sub carrier { $_[0]->{carrier} }

sub subject {
    my $self = shift;
    $self->header('Subject' => @_);
}

sub body {
    my $self = shift;

    if (@_==0) {
        $self->carrier->send_encoding->decode($self->mail->body_raw());
    } else {
        $self->mail->body_set($self->carrier->send_encoding->encode(@_));
    }
}

sub header {
    my ($self, $k, $v) = @_;
    if (defined $v) {
        $self->mail->header_set($k, $self->carrier->mime_encoding->encode($v));
    } else {
        $self->carrier->mime_encoding->decode($self->mail->header_obj->header_raw($k));
    }
}

sub add_part {
    my ($self, $body, $attributes) = @_;
    my $part = Email::MIME->create(
        body       => $body,
        attributes => $attributes,
    );
    $self->mail->parts_add([$part]);
}

sub add_text_part {
    my ($self, $body, $attributes) = @_;

    my $encoding = $self->carrier->send_encoding();
    my $part = Email::MIME->create(
        body       => $encoding->encode($body),
        attributes => {
            content_type => 'text/plain',
            charset      => $encoding->mime_name(),
            encoding     => '7bit',
            %{ $attributes || +{} }
        },
    );
    $self->mail->parts_add([$part]);
}

sub finalize {
    my ($self) = @_;
    return $self->mail;
}

1;
__END__

=encoding utf8

=head1 NAME

Email::MIME::MobileJP::Creator - E-mail creator for Japanese mobile phones

=head1 METHODS

=over 4

=item C<< my $creator = Email::MIME::MobileJP::Creator->new($to: Str); >>

EmaiL::MIME::MobileJP::Creator のインスタンスをつくります。

I<Args:> $to: To ヘッダの中身

I<Return:> Email::MIME::MobileJP::Creator のインスタンス

=item C<< my $mail = $creator->mail(); >>

L<Email::MIME> のインスタンスをえます。直接こまかい操作をしたい場合によんでください。

=item C<< my $carrier = $creator->carrier(); >>

L<Email::Address::JP::Mobile> のインスタンスをえます。キャリヤ判定をおこないたい場合に利用してください。

=item C<< $creator->subject($subject :Str); >>

Subject ヘッダを設定します。

=item C<< $creator->body($body :Str); >>

本文を指定します。

=item C<< $creator->header($key => $value); >>

任意のヘッダを設定します。

=item C<< $creator->add_part($content => \%attr); >>

任意のコンテンツを添付します。使用法は以下のとおり。

    $creator->add_part(
        $content => {
            filename     => "report.pdf",
            content_type => "application/pdf",
            encoding     => "quoted−printable",
            name         => "2004−financials.pdf",
        },
    );

=item C<< $creator->add_text_part($content[, \%attr]); >>

text パートを追加します。$content は送信先にあった encoding で自動的に encode されます。
Content-Type をかえたい場合などは、add_part と同様に %attr を指定してください。

=item C<< my $mail = $creator->finalize(); >>

後処理をおこない、完成した Email::MIME のインスタンスをかえします。

=back


