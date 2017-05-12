package Haiku::SysInfo;
use strict;

BEGIN {
  our $VERSION = '0.001';
  use XSLoader;
  XSLoader::load('Haiku::SysInfo' => $VERSION);
}

sub new {
  my $class = shift;
  my @info = _sysinfo();

  return bless \@info, $class;
}

sub cpu_count {
  return $_[0][3];
}

sub cpu_type {
  return $_[0][4];
}

sub cpu_revision {
  return $_[0][5];
}

sub cpu_clock_speed {
  return $_[0][6];
}

sub bus_clock_speed {
  return $_[0][7];
}

sub platform_type {
  return $_[0][8];
}

sub max_pages {
  return $_[0][9];
}

sub used_pages {
  return $_[0][10];
}

sub kernel_name {
  return $_[0][11];
}

sub kernel_build_date {
  return $_[0][12];
}

sub kernel_build_time {
  return $_[0][13];
}

sub kernel_version {
  return $_[0][14];
}

1;

=head1 NAME

Haiku::SysInfo - basic system information under Haiku-OS

=head1 SYNOPSIS

  use Haiku::SysInfo;

  my $info = Haiku::SysInfo->new;

  my $cpu_count = $info->cpu_count;
  ...

=head1 DESCRIPTION

Retrieve basic system information about a Haiku-OS system.

=head1 METHODS

=over

=item new()

Create a new Haiku::SysInfo object

=item cpu_count()

Return the number of CPUs.

=item cpu_type()

Return the cpu type as a number.  See the C<enum cpu_types> in
F<OS.h>.  You may find cpu_brand_string() more useful.  eg.  this
returns 69738 (0x1106a) on my Intel Core i7.

=item cpu_revision

Return the CPU revision.

=item cpu_clock_speed

Return the CPU clock speed in Hz.

=item bus_clock_speed

Return the bus clock speed in Hz.  This is zero on my box.

=item platform_type

Return the platform type.  See C<enum platform_types> in F<OS.h>.
This is 2 for x86.

=item max_pages

Total number of memory pages.  This is 130800 for my 512MB VM.

=item used_pages

Number of used memory pages.  This was 21678 while running make
install for perl.

=item kernel_name

The name of the running kernel.  This is C<kernel_x86> for my x86
kernel.

=item kernel_build_date

=item kernel_build_time

The kernel build date and time.  This is "Jun 18 2011" and "08:26:42"
for my system.

=item kernel_version

The kernel version.  This is "1" for my system.

=item cpu_brand_string

Returns the CPU brand string as returned by CPUID.  This is "Intel(R)
Core(TM) i7 CPU 950 @ 3.07GHz" for my system.

=back

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 LICENSE

Haiku::SysInfo is licensed under the same terms as Perl itself.

=cut
