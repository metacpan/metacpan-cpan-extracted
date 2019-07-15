package Fake::Our;
######################################################################
#
# Fake::Our - Fake 'our' support for perl 5.00503
#
# http://search.cpan.org/dist/Fake-Our/
#
# Copyright (c) 2014, 2015, 2017, 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.16';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

sub import {

    # provides Fake::Our environment to both perl 5.00503 and 5.006(or later)
    if ($^H & 0x00000400) { # is strict qw(vars) enabled?
        strict::->unimport(qw(vars));
    }

    if ($] < 5.006) {
        no strict 'refs';

        # fake 'our'
        *{caller() . '::our'} = sub { @_ };
#       *{caller() . '::our'} = sub : lvalue { @_ }; # perl 5.00503 can't :lvalue
    }
}

1;

__END__

=pod

=head1 NAME

Fake::Our - Fake 'our' support for perl 5.00503

=head1 SYNOPSIS

  use Fake::Our;

=head1 DESCRIPTION

Fake::Our provides fake 'our' support on perl 5.00503. This is a module to help
writing portable programs and modules across recent and old versions of Perl.
Using this module is deprecated, since it gives your script "no strict qw(vars)".
Moreover, this module is incomplete and limited.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 BUGS

Fake::Our can't lvalue our, like:

  our($var) = 'lvalue';
  our(@var) = qw(lvalue1 lvalue2 lvalue3);
  our(%var) = qw(key1 lvalue1 key2 lvalue2 key3 lvalue3);

=head1 SEE ALSO

=over 4

=item * L<our|http://perldoc.perl.org/functions/our.html> - Perl Programming Documentation

=item * L<Re: Problems with 'our' definition with perl 5.00503|http://www.perlmonks.org/?node_id=471212> - PerlMonks

=item * L<Migrating scripts back to Perl 5.005_03|http://www.perlmonks.org/?node_id=289351> - PerlMonks

=item * L<Goodnight, Perl 5.005|http://www.oreillynet.com/onlamp/blog/2007/11/goodnight_perl_5005.html> - ONLamp.com

=item * L<Perl 5.005_03 binaries|http://guest.engelschall.com/~sb/download/win32/> - engelschall.com

=item * L<Welcome to CP5.5.3AN|http://cp5.5.3an.barnyard.co.uk/> - cp5.5.3an.barnyard.co.uk

=item * L<Strict::Perl|http://search.cpan.org/dist/Strict-Perl/> - CPAN

=item * L<japerl|http://search.cpan.org/dist/japerl/> - CPAN

=item * L<ina|http://search.cpan.org/~ina/> - CPAN

=item * L<A Complete History of CPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - The BackPAN

=back

=cut

