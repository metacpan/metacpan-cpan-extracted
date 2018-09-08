package Email::Address::UseXS;

use strict;
use warnings;

our $VERSION = '1.000';

=head1 NAME

Email::Address::UseXS - ensure that any code uses L<Email::Address::XS> instead of L<Email::Address>

=head1 DESCRIPTION

To use, simply add C<use Email::Address::UseXS;> in your code before
anything that tries to load in L<Email::Address>.

    use Email::Address::UseXS;
    print Email::Address->parse('user@example.com');

=head1 WHY?

L<Email::Address> is dangerous, badly-formed input can cause very slow regex expressions (taking minutes or more to run).
See L<https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7686> for details.

=cut

BEGIN {
    die 'Must load ' . __PACKAGE__ . ' before Email::Address'
        if Email::Address->can('parse');

    require Email::Address::XS;

    @Email::Address::ISA = 'Email::Address::XS';
    $INC{'Email/Address.pm'} = 1;
}

1;

__END__

=head1 AUTHOR

Greg Sabino Mullane C<< <TURNSTEP@cpan.org> >> and Tom Molesworth C<< <TEAM@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as Perl itself.

