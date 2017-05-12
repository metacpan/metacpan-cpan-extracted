package Linux::AtaSmart::Constants;
$Linux::AtaSmart::Constants::VERSION = '2.0.0';
# ABSTRACT: Constants for libatasmart

use v5.10.1;
use strict;
use warnings;
use base 'Exporter';

# from SkSmartOverall
use constant {
    OVERALL_GOOD                      => 0,
    OVERALL_BAD_ATTRIBUTE_IN_THE_PAST => 1,
    OVERALL_BAD_SECTOR                => 2,
    OVERALL_BAD_ATTRIBUTE_NOW         => 3,
    OVERALL_BAD_SECTOR_MANY           => 4,
    OVERALL_BAD_STATUS                => 5,
};

# from SkSmartSelfTest
use constant {
    TEST_SHORT      => 1,
    TEST_EXTENDED   => 2,
    TEST_CONVEYANCE => 3,
    TEST_ABORT      => 127,
};

our %EXPORT_TAGS = (
    status => [
        qw/OVERALL_GOOD OVERALL_BAD_ATTRIBUTE_IN_THE_PAST OVERALL_BAD_SECTOR
          OVERALL_BAD_ATTRIBUTE_NOW OVERALL_BAD_SECTOR_MANY OVERALL_BAD_STATUS/
    ],
    tests => [qw/TEST_SHORT TEST_EXTENDED TEST_CONVEYANCE TEST_ABORT/],
);
my %seen;
push @{$EXPORT_TAGS{all}}, grep { !$seen{$_}++ } @{$EXPORT_TAGS{$_}}
  foreach keys %EXPORT_TAGS;

Exporter::export_ok_tags(qw/all status tests/);

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Linux::AtaSmart::Constants - Constants for libatasmart

=head1 VERSION

version 2.0.0

=head1 EXPORTS

=over

=item :status

Constants that correspond to the values returned by C<get_overall>

=item :tests

Constants for C<self_test>

=item :all

All of the above

=back

Check the source for the actual constant names.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Linux-AtaSmart/issues>.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Linux-AtaSmart/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Linux::AtaSmart/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Linux-AtaSmart>
and may be cloned from L<git://github.com/ioanrogers/Linux-AtaSmart.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
