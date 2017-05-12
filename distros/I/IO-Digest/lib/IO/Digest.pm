package IO::Digest;
use 5.008;
use strict;
use warnings;
use PerlIO::via::dynamic '0.10';
our $VERSION = '0.11';

=head1 NAME

IO::Digest - Calculate digests while reading or writing

=head1 SYNOPSIS

 use IO::Digest;

 # Get a Digest::MD5 object that takes input while $fh being written or read
 my $fh;
 my $iod = IO::Digest->new ($fh, 'MD5');

 print $fh "fooo";
 print $iod->hexdigest

=head1 DESCRIPTION

This module allows you to calculate digests while reading or writing
file handles.  This avoids the case you need to reread the same
content to compute the digests after written a file.

=cut

use Digest ();

sub new {
    my $class = shift;
    my $fh = shift;
    my $digest = Digest->new (@_);
    my $add = sub { $digest->add($_[1]) };
    my %map = (translate => $add, untranslate => $add);
    PerlIO::via::dynamic->new ( use_read => 1, %map )->via ($fh);
    return $digest;
}

=head1 TEST COVERAGE

 ----------------------------------- ------ ------ ------ ------ ------ ------
 File                                  stmt branch   cond    sub   time  total
 ----------------------------------- ------ ------ ------ ------ ------ ------
 blib/lib/IO/Digest.pm                100.0    n/a    n/a  100.0  100.0  100.0
 Total                                100.0    n/a    n/a  100.0  100.0  100.0
 ----------------------------------- ------ ------ ------ ------ ------ ------

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
