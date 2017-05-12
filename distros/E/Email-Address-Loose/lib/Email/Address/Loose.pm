package Email::Address::Loose;
use strict;
use warnings;
our $VERSION = '0.10';

use base 'Email::Address::Loose::EmailAddress';

sub import {
    my ($class, @args) = @_;
    if (grep { $_ eq '-override' } @args) {
        $class->globally_override;
    }
}

my $Email_Address_parse;

sub globally_override {
    my $class = shift;

    no warnings 'redefine';
    unless ($Email_Address_parse) {
        $Email_Address_parse = \&Email::Address::parse;
        *Email::Address::parse = \&Email::Address::Loose::EmailAddress::parse;
    }

    1;
}

sub globally_unoverride {
    my $class = shift;

    no warnings 'redefine';
    if ($Email_Address_parse) {
        *Email::Address::parse = $Email_Address_parse;
        undef $Email_Address_parse;

        Email::Address->purge_cache;
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Email::Address::Loose - Make Email::Address->parse() loose

=head1 SYNOPSIS

  my $address = 'read..rfc822.@docomo.ne.jp'; # Email::Addess can't find
  
  use Email::Address::Loose;
  my ($email) = Email::Address::Loose->parse($address); # find!

  use Email::Address;
  use Email::Address::Loose -override;
  my ($email) = Email::Address->parse($address); # find!
  
=head1 DESCRIPTION

Email::Address::Loose is a L<Email::Address>, but C<parse()> is "loose" same as
L<Email::Valid::Loose>.

This module is for web developers in Japan.

This module is needed because email address by the Japanese mobile carrier was
not RFC compliant. Fortunately, this evil spec was changed in April 2009(docomo),
October 2009(kddi). However email address that taken before 2009 is still available.
So this module is still needed.

ドコモやauがドットを連続で使ったり@マークの直前にドットを置くなど
RFC外のメールアドレスを許可していましたが、Email::Addressではそれをメールアドレスと
認識しません。このモジュールはそれらを許可するようにします。
現在はそのようなアドレスは新規に取れないようですが、以前に取ったものは使い続け
られているようなので、このモジュールを使っておいた方がいいでしょう。

=head1 USAGE

  my ($email) = Email::Address::Loose->parse('docomo..taro.@docomo.ne.jp');
  print $email->address; # => "docomo..taro.@docomo.ne.jp"
  print $email;          # => "docomo..taro.@docomo.ne.jp" (as_string)
  print $email->user;    # => "docomo..taro."
  print $email->host;    # => "docomo.ne.jp"

Same as L<Email::Address>.

=head1 IMPORT OPTION

=over 4

=item -override

  use Email::Address;
  use Email::Address::Loose -override;
   
  my ($email) = Email::Address->parse('docomo..taro.@docomo.ne.jp');
  print $email->address; # => "docomo..taro.@docomo.ne.jp"

Call C<globally_override()>(see below) at compile time.

=back

=head1 ORIGINAL METHODS

=over 4

=item globally_override()

  Email::Address::Loose->globally_override;

Changes C<< Email::Address->parse() >> into C<< Email::Address::Loose->parse() >>.

=item globally_unoverride()

  Email::Address::Loose->globally_unoverride;

Restores override-ed C<< Email::Address->parse() >>.

=back

=head1 SEE ALSO

L<Email::Address>, L<Email::Valid::Loose> - this module based on these.

L<Email::Address::JP::Mobile> - will help you too.

#mobilejp on irc.freenode.net (I've joined as "tomi-ru")

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
