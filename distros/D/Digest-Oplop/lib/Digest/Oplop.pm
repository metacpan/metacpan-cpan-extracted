package Digest::Oplop;

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);
use Encode qw(encode_utf8);
use English '-no_match_vars';

use constant PASSWORD_LENGTH => 8;

use base 'Exporter';
our @EXPORT_OK = qw(oplop);

our $VERSION = '0.01';

sub oplop {
    my ( $master_password, $label ) = @_;
    my $password = md5_base64( encode_utf8( $master_password . $label ) );

    ## DIgest::MD5 has no alternative to base64.urlsafe_b64encode, but
    ## this statement realize their implemention description

    $password =~ tr[+/][-_];

    if ( $password =~ /(\d+)/ ) {
        if ( $LAST_MATCH_START[0] > PASSWORD_LENGTH - 1 ) {
            $password = $1 . $password;
        }
    }
    else {
        $password = "1$password";
    }
    return substr $password, 0, PASSWORD_LENGTH;
}
1;

__END__

=head1 NAME

Digest::Oplop - Generate account passwords based on a nickname and a master password

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Digest::Oplop qw(oplop);
  my $password = oplop($master_password,$label);

=head1 DESCRIPTION

This module implements the Oplop hashing algorithm created by Brett
Cannon L<http://code.google.com/p/oplop/>. Oplop makes it easy to create
unique passwords for every account you have. By using some math, Oplop
only requires of you to remember account nicknames and a master password
to create a very safe and secure password just for you.

Oplop combines the account nickname and master password to generate a
eight character long hash, that should meet the most common criteria
for passwords used on web sites.

=head1 EXPORT

Nothing is exported by default, but the function L<oplop> can be if
requested.

=head1 SUBROUTINES

=head2 oplop

This function takes two mandatory arguments, the master password and the
label and returns the hashed password. Please refer to the SYNOPSIS for
an example.

=head1 AUTHOR

Mario Domgoergen C<< <mdom@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-digest-oplop at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Digest-
Oplop>. I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 CAVEAT

The Python implementation is considered the canonical implementation
of the algorithm, and although this library pass the oplop testsuite,
there might be some cornercases where both implementations differ.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::Oplop

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Digest-Oplop>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-Oplop>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-Oplop>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-Oplop/>

=back

=head1 SEE ALSO

=over 4

=item * How it works

L<http://code.google.com/p/oplop/wiki/HowItWorks>

=item * Threat Model

L<http://code.google.com/p/oplop/wiki/ThreatModel>

=item * FAQ

L<http://code.google.com/p/oplop/wiki/FAQ>

=item * Why choose oplop?

L<http://code.google.com/p/oplop/wiki/WhyChooseOplop>

=item * Implementations

L<http://code.google.com/p/oplop/wiki/Implementations>

=back

=head1 ACKNOWLEDGEMENTS

L<http://code.google.com/p/oplop/>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mario Domgoergen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information

