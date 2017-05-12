package Device::Blkid::E2fsprogs;

our $VERSION = '0.40';

use 5.008000;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'consts' => [
        qw(
          BLKID_DEV_FIND
          BLKID_DEV_CREATE
          BLKID_DEV_VERIFY
          BLKID_DEV_NORMAL
          )
    ],
    'funcs' => [
        qw(
          put_cache
          get_cache
          gc_cache
          dev_devname
          dev_iterate_begin
          dev_set_search
          dev_next
          dev_iterate_end
          devno_to_devname
          probe_all
          probe_all_new
          get_dev
          get_dev_size
          known_fstype
          verify
          get_tag_value
          get_devname
          tag_iterate_begin
          tag_next
          tag_iterate_end
          dev_has_tag
          find_dev_with_tag
          parse_tag_string
          parse_version_string
          get_library_version
          )
    ],
);
Exporter::export_ok_tags('consts');
Exporter::export_ok_tags('funcs');

use constant BLKID_DEV_FIND   => 0x0000;
use constant BLKID_DEV_CREATE => 0x0001;
use constant BLKID_DEV_VERIFY => 0x0002;
use constant BLKID_DEV_NORMAL => ( BLKID_DEV_CREATE | BLKID_DEV_VERIFY );

require XSLoader;
XSLoader::load( 'Device::Blkid::E2fsprogs', $VERSION );

1;
__END__

=head1 NAME

Device::Blkid::E2fsprogs - Perl interface to e2fsprogs-based libblkid (v1.33 - v1.41.4)

=head1 SYNOPSIS

  use Device::Blkid::E2fsprogs qw/ :funcs /;

  # Get a cache object, checking for exception
  my $cache_file = '/etc/blkid/blkid.tab';

  local $@;
  my $cache = eval { get_cache($cache_file) };
  if ($@) {
      die $@;
  }

  # Get the device associated with a given blkid LABEL
  my $type = 'LABEL';
  my $label = '/boot';

  # Using the cache
  my $devname = get_devname($type, $value, $cache);

  # Get a Device::Blkid::E2fsprogs::Device object
  my $device = get_dev($cache, $devname, $flags);

  # Get a device iterator, checking for exception
  local $@;
  my $dev_iter = eval { dev_iterate_begin($cache) };
  if ($@) {
      die $@;
  }

  # And now iterate over list of devices
  if ( $device = dev_next($dev_iter) ) {
      do_something_with_device($device);
  }

  # To explicitly force memory deallocation on an allocated object
  undef $cache; 

=head3 Important Note

This library is compatible with those versions of libblkid which were bundled with the
e2fsprogs package, i.e., those versions of the library numbered 1.xx. While this package
should be fully compliant with the newer util-linux-ng based versions of the libblkid
interface, it is not recommended that you use it; without modifications to the configuration
scripts, it will fail to install on such systems in any event.

If the target system is running the util-linux-ng versions of libblkid, indicated by a 2.x
version number, you would be advised to use Bastian Friedrich's L<Device::Blkid> module
rather than this one. Those versions of the library feature a larger and more complete interface
which this extension does not support. It is recommended that this extension be used only in
those cases where you are bound by some contraint to the e2fsprogs-based versions of the
libblkid library.

Finally, this extension has been implemented somewhat differently than Bastian's util-linux-ng
libblkid interface. He opted to keep much of his logic and processing in XSUB, mine is done
mostly in C; I have only used XSUB as glue.

=head1 DESCRIPTION

Libblkid provides a means of identifying block devices as to their content (such as filesystems)
as well as allowing for the extraction of additional meta information such as filesystem labels,
volume labels, serial numbers, device numbers, unique identifiers, etc. The libblkid library
maintains a mapping of all of this composite information and maintains its association with
a given block device on the system. UUID and label-based L<fstab(5)> file configurations have
become common in modern Linux distributions. Having the capability to abstract block devices
in this way and to maintain mappings between volumes and storage devices can make managing
multiple storage devices a much less daunting task.

This library provides for low level probing of block devices to access the various meta data
associated with the particular partition or volume as well as access to an on disk cache file
which contains mappings between this information and each block device on the system. Access
to this cache file is one way in which unpriviledged users who do not have read access to the
particular block device can gain access to this information. Users with the necessary access
can always opt to probe the block device directly for this information.

This Perl extension exposes the same functionality offered up by the C libblkid interface.
As was noted, it does not support the considerably larger set of calls which are a part of
the util-linux-ng versions of libblkid. To properly support usage of these versions, and its
considerably larger API, please see the L<Device::Blkid> package.

I have endeavored to provide a more Perlish interface to the library rather than just do
straight mappings or wrappers over the C functions. Most library calls will return an undef
on failure. Those which allocate and return data structures will throw an exception catchable
via the usual C<eval/if> construct. Furthermore, several of the original library calls which
relied on modifiable pointer arguments now return Perl hash representations of complex types
where this made sense. See the interface documentation below for details on each call.

Please refer to the F<README> file in the package archive for instructions should you encounter
any problems while using this software package.

=head2 INSTALLATION NOTES

It is worth noting that between versions 1.33 and 1.41.x, the entire period which libblkid
was shipping as a part of the e2fsprogs package, the number of calls present in the API
expanded from 17 in the original release of the library back in 2003 to 25 by the time it
was migrated over to the util-linux-ng package in early 2009. This extension supports dynamic
detection of the libblkid version on the target system from version 1.36 onward. In the event
that a proper determination of version cannot be obtained and the library is confirmed to in
fact be on the system, a default baseline version target of 1.33 will be generated which will
be compliant with all of the possible versions of libblkid which shipped with the e2fsprogs
package.

This extension has made use of a customized L<Devel::CheckLib> module in concert with the
F<Makefile.PL> in order to dynamically detect the version of libblkid currently installed
on the target system and to then generate a Perl XS interface which directly targets and matches
the interface of that libblkid version. This process is expected to work on all versions of
libblkid later than v1.35. On versions 1.33 through to 1.35, a default baseline target for the
v1.33 API is configured for build. Should you have any problems with this process, evident either
in running the F<Makefile.PL> or in running make against the resulting F<Makefile>, please see the
F<Makefile.PL> for hints on troubleshooting. If you wish to report any problems with this version
detection, please include any output from the installation process as well as a copy of your
F</usr/include/blkid/blkid.h> file. Finally, in cases where you are running version 1.34 or 1.35,
and where you require inclusion of the L</known_fstype()> function in your build, you will be
required to modify the F<Makefile.PL> to achieve this end.

For additional details regarding dynamic library version detection, please refer to the
F<README> file at the top level of this package.

=head2 DEPENDENCIES

L<E2fsprogs v1.33-v1.41.4|http://e2fsprogs.sourceforge.net/>

While this package is compatible with any version of libblkid from the e2fsprogs package, dynamic
version detection will only work on versions 1.36 and newer. In cases where the proper version
cannot be detected properly during configuration, a baseline build which targets version 1.33 of
libblkid will be configured which is compliant with anything which might be on the target system.

=head2 EXPORT

Nothing is exported by default, but constants and package functions are available as follows:

To export libblkid defined constants, implement the following use pragma:

  use Device::Blkid::E2fsprogs qw/ :consts /;

To export this package's functions into the namespace, implement the following use pragma:

  use Device::Blkid::E2fsprogs qw/ :funcs /;

=head2 CONSTANTS

=over 4

=item  C<BLKID_DEV_CREATE>

Create and empty device structure if not found in the cache.

=item C<BLKID_DEV_VERIFY>

Make sure the device structure corresponds with reality.

=item C<BLKID_DEV_FIND>

Just look up a device entry and return undef if not found.

=item C<BLKID_DEV_NORMAL>

Get a valid device structure, either from the cache or by probing the block device.

=back

=head2 FUNCTIONS

All function calls detailed below also list the version of libblkid in which they first appeared
as a part of the library. As has been noted above, all of these calls should also be valid in the
newer util-linux-ng versions of this interface which is reportedly completely backward compatible
with the older library.

=over 4

=item C<put_cache($cache)>

Write any changes to the blkid cache file and explicitly free associated resources. L</put_cache()>
should be called after you have been doing any work with a cache object. Note, the cache object is freed
by this call and as such must not be used by any subsequent operations. Further calls to L</put_cache()>
on an already deallocated cache structure result in a segfault from the libblkid library so take guard
against this.

C<v1.33>

=item C<get_cache($filename)>

Given a path to a cache file, return a blkid cache object reference. This reference is of type
C<Device::Blkid::E2fsprogs::Cache>. This call, as with other calls which allocate an object type,
throws an exception on failure.

C<v1.33>

=item C<gc_cache($cache)>

Calling this performs a garbage cleanup on the specified cache by removing all non-existant devices.

C<v1.40>

=item C<dev_devname($device)>

Given a blkid device object, returns a string representation of the device (e.g., /dev/sda3), or undef
on fail. Device object arguments must be of type C<Device::Blkid::E2fsprogs::Device>.

C<v1.33>

=item C<dev_iterate_begin($cache)>

Returns a device iterator object on the specified device cache. Device iterator objects are of type
C<Device::Blkid::E2fsprogs::DevIter>. As in the case of other calls which return allocated object
types, this call throws an exception on fail.

C<v1.33>

=item C<dev_set_search($dev_iter, $type, $value)>

This function places a search filter on the specified device iterator based upon the criteria passed
in on the final two arguments of the function. After this function has been called on the given iterator
with a type and value argument, the iterator will only return onjects which match the specified criteria.
Please note, the C<$type> argument can also contain any valid blkid entity category, such as a LABEL or
UUID tag. A successful call returns a copy of the device iterator object being used, undef on fail.

  # Set iterator to filter and match only on ext4 file systems
  dev_set_search($dev_iter, 'TYPE', 'ext4');

C<v1.38>

=item C<dev_next($dev_iter)>

Returns the next device object in the iteration. Check for undef as an end of list sentinal.

C<v1.33>

=item C<dev_iterate_end($dev_iter)>

Frees the allocated iterator object from memory, although this is redundant; simply undef'ing the object to
remove references to it or allowing it to go out of scope will also free the memory as well. Note, this call
may be removed in a future version.

C<v1.33>

=item C<devno_to_devname($devno)>

Given a device number, returns the associated device name (e.g., /dev/sda1) or undef if no match found.

  my $devno   = ( $major_devnum << 8 ) + minor_devnum;
  my $devname = devno_to_devname($devno); 

C<v1.33>

=item C<probe_all($cache)>

Given a valid cache object, probes the underlying block devices on the system. Returns the cache object
instance on success, undef on fail.

C<v1.33>

=item C<probe_all_new($cache)>

Given a valid cache object, probes for new block devices on the system. Returns the cache object instance
on success, or undef in fail state.

C<v1.38>

=item C<get_dev($cache, $devname, $flags)>

Returns a device object based upon the input criteria. Please refer to the constants sections to see what
flags may be passed in to determine behaviour. Device objects are of type C<Device::Blkid::E2fsprogs::Device>.
Throws exception on any failure to allocate the device object.

C<v1.33>

=item C<get_dev_size($devname)>

Given a device name, returns the size of the block device in bytes. Note, this underlying library call
works with a file descriptor to the block device in question so you must have read access to the device
being probed, usually as root or a member of the disk group, otherwise this call will fail and throw
an exception. This call will also return undef should the actual libblkid call fail for any reason which
does not generate an exception (i.e. a non-file descriptor related issue).

  local $@;
  my $devsize = eval { get_dev_size('/dev/sda1') };
  if ($@) {
      # Handle exception here, fd related problem
  }

C<v1.33>

=item C<known_fstype($fstype)>

Determines if a file system type is known to libblkid. If the file system is known, it returns the input
file system argument string, otherwise undef.

C<v1.34>

=item C<verify($cache, $device)>

Attempts to verify that the device object is a valid blkid device. Returns the instance of the current device
object on success, otherwise undef is returned to indicate failure.

C<v1.36>

=item C<get_tag_value($cache, $tagname, $devname)>

Given a valid C<$cache> object, $tagname and $devname, this function returns the value to which the tag refers.

  my $tagname = 'LABEL';
  my $devname = '/dev/sda4';

  my $tag_value = get_tag_value($cache, $tagname, $devname);

C<v1.33>

=item C<get_devname($cache, $token, $value)>

Similar to the last call, given a valid C<$cache> object and C<$token> and C<$value> parameters, will return the
device name of the specified block device (e.g., /dev/sda1).

  my $token = 'UUID';
  my $value = '2b5c78cb-acc5-4ffa-83b6-deb099bb22cf';

  my $devname = get_devname($cache, $token, $value);

C<v1.33>

=item C<tag_iterate_begin($device)>

Returns a tag iterater object on a valid device type, of type C<Device::Blkid::E2fsprogs::TagIter>. Any
failure to allocate an iterator object results in a thrown exception.

C<v1.33>

=item C<tag_next($tag_iter)>

Returns a hash reference containing the next available tag pairing from the list, or undef is returned
on failure.

  { type => "UUID", value => '83f076b3-7abd-4c32-83df-026e57373900' }

C<v1.33>

=item C<tag_iterate_end($tag_iter)>

Frees the memory allocated for the tag iterator object. This is redundant as the memory can be freed by
removing references to the object, undef'ing it or allowing it to leave scope. Note, this call may be
removed in a future version of this extension.

C<v1.33>

=item C<dev_has_tag($device, $type, $value)>

Determines if the given device contains the specified tag. If it does, the device instance is returned,
otherwise undef.

C<v1.38>

=item C<find_dev_with_tag($cache, $type, $value)>

Given a tag type and value, crawls the blkid cache for a match and returns an instance of the device if
found, undef on failure.

=item C<parse_tag_string($tag_pair)>

Given an tag pair input value in C<type=value> format, returns a hash reference containing the two
constituent values as they are associated with the input keys. Returns undef in the event of a failure.

  { type => 'LABEL', value => '/boot' }

C<v1.33>

=item C<parse_version_string($ver_string)>

Given a standard dotted-decimal style version string, returns a raw integer-like representation of the
string, sans decimals.

C<v1.36>

=item C<get_library_version()>

Returns a hash reference containing the libblkid library version and release date as well as a raw integer
representation of the standard dotted-decimal formatted version string (see L</parse_version_string()> above).
Returns undef on failure.

  { version => '1.41.4', date => '27-Jan-2009', raw => '1414' }  

C<v1.36>

=back

=head1 SEE ALSO

L<E2fsprogs project home page|http://e2fsprogs.sourceforge.net/>

L<blkid(8)>

L<PerlXS|http://perldoc.perl.org/perlxs.html>

L<Device::Blkid> - You should probably use this unless otherwise constrained.

L<Devel::CheckLib>

This package project is also hosted on Github at
git://github.com/raymroz/Device--Blkid--E2fsprogs.git

=head1 AUTHOR

Raymond Mroz, E<lt>mroz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Raymond Mroz

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version
of Perl 5 you may have available.

=head1 TODO

Eliminating redundant calls and implement a more Perlish feel.

Implement L</devno_to_devname()> with a variadic parameter list so that it will accept
both a devno and major/minor parameter list.

Test scripts; handle multiple version targets so that additional unit tests can be written
to target additional library calls.

=head1 CREDITS

I would like to thank Bastian Friedrich for his L<Device::Blkid>. Given the scant supply
of documentation available on libblkid, especially the older, e2fsprogs-based versions,
his POD proved quite helpful as a source of documentation on the library and saved me a
load of time while running my test C calls. Thanks!

Thanks to David Cantrell, David Golden and Yasuhiro Matsumoto for L<Devel::CheckLib>. I
hacked it up a little bit to manage my dynamic version checks and build, hope you don't mind.

Thanks to Tom Erskine for your insight and experience in all things Perl.

Thanks to Larry McInnis for the hardware on which I installed several dated versions of
Fedora Core on which I developed and tested this extension.

=head1 BUGS

What's a bug? :)

No known bugs at this time. That said, this module is largely written in C and does contain
a number of memory allocations. While these allocations are done inside of libblkid itself,
I do make every attempt to free the memory explicitly when I am done with it. That said, leaks
are always a possibility. Please report any issues which you might have as is detailed above.

=head1 DIRECTION

This is an early release of this module. This extension and its interface are subject to change
at any time. Please refer to all package documentation before reporting any problems.

=Cut
