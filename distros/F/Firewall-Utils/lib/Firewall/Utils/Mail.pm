package Firewall::Utils::Mail;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Mail::Sender;

has smtp => ( is => 'ro', isa => 'Str', required => 1, );

has from => ( is => 'ro', isa => 'Str', required => 1, );

has charset => ( is => 'ro', isa => 'Str', builder => '_buildCharset', );

has displayFormat => ( is => 'ro', isa => 'Str', default => 'text/html', );

sub _buildCharset {
  my $self = shift;
  my $charset;
  if ( not defined $ENV{LANG} ) {
    $charset = 'gb2312';
  }
  elsif ( $ENV{LANG} =~ /(?:utf8|utf-8)$/io ) {
    $charset = 'utf8';
  }
  elsif ( $ENV{LANG} =~ /\b(gb\w+)$/io ) {
    $charset = $1;
  }
  else {
    $charset = 'gb2312';
  }
  return $charset;
}

sub sendmail {

  #my ($self, $address, $cc, $subject, @body) = @_;
  my $self = shift;
  my %param;
  if ( ref $_[0] eq 'HASH' ) {
    %param = %{$_[0]};
  }
  else {
    %param = @_;
  }
  confess "ERROR: 缺少目标地址" if not defined $param{to};

=lala

  #base64编码有长度限制，在一对解码标识符之间的字符串允许长度约为170，所以需要把标题分段插入解码标识。
  #此分段依赖于base64编码的编码后每76个字符加一个回车的特性。
  if ( defined $param{subject} ) {
      $param{subject} =~s/(\s{1})/?=$1=?gb2312?b?/g;
  }

=cut

  #处理收件人中的重复项
  $param{to}
    = join( ',', keys {map { lc($_) => undef } grep { defined $_ and $_ !~ /^\s*$/ } split( /[,;]/, $param{to} )} );
  eval {
    my $sender = Mail::Sender->new;
    {
      # smtp => 'mail.baidu.com',
      smtp => $param{smtp} // $self->smtp,

      # from => 'monitor@baidu.com.cn', # from => 'monitor@baidu.com.cn',
      from => $param{from} // $self->from,
      to   => $param{to},
      cc   => $param{cc},

      # bcc => 'monitor@baidu.com.cn',
      on_errors => 'die',
    };
    $sender->Open( {
      subject  => $param{subject},
      ctype    => $param{ctype}    // $self->displayFormat . '; ' . $self->charset,
      encoding => $param{encoding} // "quoted-printable"
    } );

    # for (@body) { $sender->SendEnc($_) };
    $sender->SendEnc( $param{msg} );
    $sender->Close();
  };

  if ( !!$@ ) {
    $@ =~ s/\s+$//;
    confess($@);
  }
}

__PACKAGE__->meta->make_immutable;
1;
