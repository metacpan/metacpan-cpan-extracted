package Email::MIME::Creator::ISO_2022_JP;

use strict;
use warnings;
use Email::MIME;
use Encode;
use Sub::Install 'reinstall_sub';

BEGIN {
  if ( $Encode::VERSION < 2.11 ) {
    require Encode::compat::MIME::Header::ISO_2022_JP;
  }
}

our $VERSION = '0.02';

sub import {
  my $class = shift;

  if (!$class->can('create_utf8')) {
    for my $method (qw(create header_str_set)) {
      reinstall_sub({
        as   => "${method}_utf8",
        into => $class,
        code => \&{"Email::MIME::${method}"},
      });
    }
  }
  for my $method (qw(create header_str_set)) {
    reinstall_sub({
      as   => $method,
      into => "Email::MIME",
      code => \&{"${class}\::${method}_iso_2022_jp"},
    });
  }

  unless (grep /^$class/, @Email::MIME::ISA) {
    push @Email::MIME::ISA, $class;
  }
}

sub unimport {
  my $class = shift;

  if ($class->can('create_utf8')) {
    for my $method (qw(create header_str_set)) {
      reinstall_sub({
        as   => $method,
        into => "Email::MIME",
        code => \&{"${class}\::${method}_utf8"},
      });
    }
  }
}

sub create_iso_2022_jp {
  my ($class, %args) = @_;

  if (exists $args{header_str}) {
    $args{attributes}{charset} ||= 'ISO-2022-JP';

    my @headers = @{ delete $args{header_str} };
    $args{header} ||= [];
    pop @headers if @headers % 2 == 1;
    while (my ($key, $value) = splice @headers, 0, 2) {
      push @{$args{header}},
        ( $key => Encode::encode('MIME-Header-ISO_2022_JP', $value) );
    }
  }
  if (exists $args{body_str}) {
    $args{attributes}{charset}  ||= 'ISO-2022-JP';
    $args{attributes}{encoding} ||= '7bit';
  }

  my $email = $class->create_utf8(%args);  # i.e. original create

  my $remove; $remove = sub {
    my ($email) = @_;

    my @parts = $email->parts;
    return if $email eq $parts[0]; # avoid recursion

    foreach my $part (@parts) {
      $part->header_set(Date => ());
      $part->header_set('MIME-Version' => ());
      $remove->($part);
    }
    $email->parts_set(\@parts);
  };
  $remove->($email);

  return $email;
}

sub header_str_set_iso_2022_jp {
  my ($self, $name, @vals) = @_;

  my @values = map { Encode::encode('MIME-Header-ISO_2022_JP', $_, 1)  } @vals;

  $self->header_set($name => @values);
}

1;

__END__

=encoding utf8

=head1 NAME

Email::MIME::Creator::ISO_2022_JP - Email::MIME mixin to create an iso-2022-jp mail

=head1 SYNOPSIS

  use Email::Sender::Simple 'sendmail';
  use Email::MIME;
  use Email::MIME::Creator::ISO_2022_JP;
  use utf8;
  
  my $email_jis = Email::MIME->create(
    header_str => [
      From    => 'foo@example.com',
      To      => 'bar@example.com',
      Subject => 'こんにちは',
    ],
    attributes => {
      content_type => 'text/plain',
      charset      => 'iso-2022-jp',
      encoding     => '7bit',
    },
    body_str => 'メールの本文はutf-8で',
  );
  
  sendmail($email_jis);  # in iso-2022-jp
  
  no Email::MIME::Creator::ISO_2022_JP;
  
  my $email_utf8 = Email::MIME->create(
    header_str => [
      From    => 'foo@example.com',
      To      => 'bar@example.com',
      Subject => 'こんにちは',
    ],
    attributes => {
      content_type => 'text/plain',
      charset      => 'utf-8',
      encoding     => '7bit',
    },
    body_str => 'メールの本文はutf-8で',
  );
  
  sendmail($email_utf8);  # in utf-8

=head1 DESCRIPTION

L<Email::MIME> is nice and handy. With C<header_str> and C<body_str> (since 1.900), you don't need to encode everything by yourself. Just pass flagged (C<decode>d) utf-8 strings, and you'll get what you want. However, it only works when you send utf-8 encoded emails. In Japan, there're still some email clients that only understand iso-2022-jp (jis) encoded emails, and its popularity persuaded the L<Encode> maintainer (who's also Japanese) to include its support (since version 2.11, with C<Encode::MIME::Header::ISO_2022_JP> written by Makamaka). I want it to be supported by L<Email::MIME>, but it's too specific and nonsense for the rest of the world. That's why I write this mixin instead of asking to add extra bit to L<Email::MIME>.

As of this writing, this mixin doesn't care the tangled issues in the Japanese cellular phone industry (thus not C<::Japanese>). If you need finer control, just use C<header>/C<body> and encoded string/octets, or send me a patch.

=head1 METHODS

=head2 create_iso_2022_jp, header_str_set_iso_2022_jp

Both work almost the same as L<Email::MIME>'s methods do, with one exception. If you pass utf-8 stings to C<header_str> attribute or C<header_str_set> method, they'll be encoded by C<Encode::MIME::Header::ISO_2022_JP>, instead of C<Encode::MIME::Header>.

=head2 import, unimport

Actually you don't need to use these directly. As shown in the SYNOPSIS, when this module is C<use>d, L<Email::MIME>'s original C<create> and C<header_str_set> are replaced with these methods internally. If you want to use the orignal methods again, unimport this module (with C<no> pragma, or C<unimport> method), and they'll be restored.

=head1 NOTE

As a bonus, this module eliminates C<Date> and C<MIME-Version> headers from each part in a multipart email.

=head1 SEE ALSO

L<Email::MIME>, L<Encode>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
