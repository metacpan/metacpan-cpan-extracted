package Haineko::SMTPD::RFC5321;
use strict;
use warnings;
use Haineko::SMTPD::RFC5322;

sub is8bit {
    my $class = shift;
    my $argvs = shift || return 0;  # (String) Any text

    return 1 unless $$argvs =~ m/\A[\x00-\x7f]+\z/;
    return 0;
}

sub check_ehlo {
    my $class = shift;
    my $argvs = shift || return 0;  # (String) The value of EHLO/HELO
    my $valid = Haineko::SMTPD::RFC5322->is_domainpart( $argvs );
    my $octet = [];

    return 1 if $valid;
    $argvs =~ y/[] //d;
    $octet = [ split( /[.]/, $argvs ) ];

    for my $e ( @$octet ) {
        # Check each octet
        last unless $e =~ m/\A\d+\z/;
        last if $e < 0;
        last if $e > 255;
        $valid++;
    }

    return 1 if $valid == 4;
    return 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::RFC5321 - Tools related RFC-5321

=head1 SYNOPSIS

    use Haineko::SMTPD::RFC5321;
    my $x = Haineko::SMTPD::RFC5321->is8bit( \$string );
    my $y = Haineko::SMTPD::RFC5321->check_ehlo( $ehlo_hostname );

=head1 CLASS METHODS

=head2 C<B<is8bit( I<\$string> )>>

C<is8bit()> returns whether C<$string> contains non-ascii character or not.

    my $x = 'Stray cat';
    my $y = '野良猫';
    my $z = 'villast köttur';

    print Haineko::SMTPD::RFC5321->is8bit( \$x );  # 0
    print Haineko::SMTPD::RFC5321->is8bit( \$y );  # 1
    print Haineko::SMTPD::RFC5321->is8bit( \$z );  # 1


=head2 C<B<check_ehlo( I<EHLO-HOSTNAME>) >>

C<check_ehlo()> checks whether specified hostname is valid as C<EHLO-HOSTNAME>
or not.

    print Haineko::SMTPD::RFC5321->check_ehlo('[127.0.0.1]');      # 1(OK)
    print Haineko::SMTPD::RFC5321->check_ehlo('cat.example.jp');   # 1(OK)
    print Haineko::SMTPD::RFC5321->check_ehlo('');                 # 0(NG)
    print Haineko::SMTPD::RFC5321->check_ehlo('cat@example.jp');   # 0(NG)

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
