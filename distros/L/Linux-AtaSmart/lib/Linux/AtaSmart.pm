package Linux::AtaSmart;
$Linux::AtaSmart::VERSION = '2.0.0';
# ABSTRACT: XS wrapper around libatasmart

use v5.10.1;
use Moo;
use Carp;
use XSLoader;
use namespace::clean;

XSLoader::load;

has _device => (is => 'ro', required => 1,);

has _disk => (
    is      => 'ro',
    default => sub {
        my $disk = __disk_open($_[0]->_device);
        __smart_is_available($disk);
        return $disk;
    },
);

has _smart_data => (is => 'rwp', predicate => 1);

sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, '_device' if @args % 2 == 1;

    return {@args};
}

sub DEMOLISH {
    __disk_free($_[0]->_disk);
}

before [
    qw/get_temperature get_bad get_overall get_power_cycle get_power_on/] =>
  sub {
    my $self = shift;
    unless ($self->_has_smart_data) {
        __get_smart_data($self->_disk);
        $self->_set__smart_data(1);
    }
  };


sub get_size { __get_size($_[0]->_disk) }


sub check_sleep_mode { __check_sleep_mode($_[0]->_disk) }


sub dump { __disk_dump($_[0]->_disk) }


sub smart_status { __smart_status($_[0]->_disk) }


sub get_temperature {
    my $self = shift;

    my $mkelvin = __get_temperature($self->_disk);
    return undef if $mkelvin == 0;

    # millikelvin to celsius
    my $celsius = ($mkelvin - 273150) / 1000;
    return $celsius;
}


sub get_bad { __get_bad($_[0]->_disk) }


sub get_overall { __get_overall($_[0]->_disk) }


sub get_power_cycle { __get_power_cycle($_[0]->_disk) || undef }


sub get_power_on {
    my $self = shift;

    my $ms = __get_power_on($self->_disk);

    return if $ms == 0;

    require Time::Seconds;
    return Time::Seconds->new($ms / 1000);
}


sub self_test {
    my ($self, $test_type) = @_;
    _c_self_test($self->_disk, $test_type);
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Linux::AtaSmart - XS wrapper around libatasmart

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

  use v5.10.1;
  use Linux::AtaSmart;
  use Linux::AtaSmart::Constants qw/:all/;

  my $atasmart = Linux::AtaSmart->new('/dev/sda');

  if (!$atasmart->smart_is_available) {
      die "Drive not SMART capable";
  }

  say 'Disk size in bytes: ', $atasmart->get_size;
  say 'Awake: ' .  ($atasmart->check_sleep_mode ? 'YES'  : 'NO');
  say 'Status: ' . ($atasmart->smart_status     ? 'GOOD' : 'BAD');
  say 'Bad Sectors: ' . $atasmart->get_bad;
  say 'Temperature °C: ' . $atasmart->get_temperature // "n/a";
  say "Power Cycles: " . $atasmart->get_power_cycle // "n/a";
  say "Powered On: " . $atasmart->get_power_on->pretty // "n/a";

  my $status = $atasmart->get_overall;
  if ($status != OVERALL_GOOD) {
      say "STATUS NOT GOOD!";
  }

  # all of the above and more
  $atasmart->dump;

  $atasmart->self_test(TEST_SHORT);

=head1 DESCRIPTION

This is an XS wrapper around the Linux-only library, L<libatasmart|http://0pointer.de/blog/projects/being-smart.html>.
To read SMART info from a drive you will need to run as root, or have CAP_RAW_IO
(which you will most likely have to set on your F<perl> binary).
B<HAVING GROUP WRITE PERMISSIONS IS NOT ENOUGH!>

=head1 METHODS

=head2 C<new(disk_device)>

Creates a new C<Linux::AtaSmart> object. Requires one argument, a string identifying
the disk to examine, e.g. F</dev/sda>, F</dev/disk/by-label/HOME>

Will C<croak> if there is any error, or the device does not support SMART.

=head2 C<get_size>

Returns the disk capacity in bytes.

=head2 C<check_sleep_mode>

Boolean, true if awake, false if sleeping. Reading SMART data will wake up the disk,
so check this first if you care.

=head2 C<dump>

Prints all the available SMART info for the disk to F<STDOUT>.

=head2 C<smart_status>

Boolean, true is GOOD, false is BAD.

=head2 C<get_temperature>

Returns current disk temperature in celsius, or C<undef> if not supported.

The C library actually uses millikelvins, complain if you'd prefer that.

=head2 C<get_bad>

Returns the number of bad sectors on the disk.

=head2 C<get_overall>

Returns an integer corresponding to the overall status of the drive.
See L<Linux::AtaSmart::Constants>.

=head2 C<get_power_cycle>

Returns number of times the disk has been power cycled.

=head2 C<get_power_on>

Returns the total time this disk has been powered-on as a L<Time::Seconds> object.
The C library actually uses milliseconds, complain if you'd prefer that.

=head2 C<self_test(TEST_TYPE)>

Starts a test of TEST_TYPE. See L<Linux::AtaSmart::Constants>.

=for Pod::Coverage BUILDARGS DEMOLISH

=head1 ALTERNATIVES

You may already have L<udisks|http://www.freedesktop.org/wiki/Software/udisks>
installed, which you can query via L<Net::DBus>.

=head1 INSTALLATION

You will need your system's C<libatasmart> development package installed.
On Debian-like systems, this is C<libatasmart-dev>. On Fedora it is
C<libatasmart-devel>.

=head1 DIFFERENCES FROM THE C API

=over

=item

Removed the C<sk_disk_> and C<sk_disk_smart_> prefixes for brevity.

=item

The C<SkDisk> item is handled inside this module, you don't need to pass it to every method.
You should create a new object to examine a different disk.

=item

Results are returned directly by the methods, you don't have to pass references to be filled.

=item

You don't have to manually call C<sk_disk_smart_read_data> or C<sk_disk_smart_parse_data>.
This will be handled automatically by those methods that require it.

=back

=head1 ERRORS

All errors will throw exceptions via C<croak>

=head1 SEE ALSO

=over

=item

L<libatasmart|http://0pointer.de/blog/projects/being-smart.html>

=item

L<Linux::AtaSmart::Constants>

=back

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
