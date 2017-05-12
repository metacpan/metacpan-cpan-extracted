package Haineko::SMTPD::Milter::Nyaa;
use strict;
use warnings;
use parent 'Haineko::SMTPD::Milter';

sub body {
    my $class = shift;
    my $nekor = shift || return 1;  # (Haineko::SMTPD::Response) Object
    my $argvs = shift // return 1;  # (Ref->Scalar) Email body
    my $nyaaa = undef;

    return 1 unless ref $argvs;
    return 1 unless ref $argvs eq 'SCALAR';

    try {
        use Acme::Nyaa;
        $nyaaa  = Acme::Nyaa->new;
        $$argvs = $nyaaa->straycat( [ $$argvs ] );
        utf8::decode $$argvs unless utf8::is_utf8 $$argvs;
        return 1;
    } catch {
        return 0;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Milter::Nyaa - Haineko milter for rewriting email body using
Acme::Nyaa module.

=head1 DESCRIPTION

Haineko::SMTPD::Milter::Nyaa converts email body to text like which a cat talking
using Acme::Nyaa module.

=head1 SYNOPSIS

    use Haineko::SMTPD::Milter;
    my $r = Haineko::SMTPD::Response->new;
    my $e = '猫がかわいい。';

    Haineko::SMTPD::Milter->import( [ 'Nyaa' ]);
    Haineko::SMTPD::Milter::Nyaa->body( $r, \$e );

    print $e;   # 猫がかわいいニャー

=head2 C<B<body( I<Haineko::SMTPD::Response>, I< \EMAIL_BODY > )>>

C<body()> method is for writing email body using Acme::Nyaa.

=head3 Arguments

=head4 C<B<Haineko::SMTPD::Response>> object

If your milter program rejects a message, set 1 by ->error(1), set error message
by ->message( [ 'Error message' ]), and override SMTP status code by ->code(), 
override D.S.N value by ->dsn(). Default SMTP status codes is 554, dsn is 5.6.0
in this method.

=head4 C<B<EMAIL_BODY>>

Value defined in "body" field in HTTP POST JSON data.

=head1 SEE ALSO

https://www.milter.org/developers/api/

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

