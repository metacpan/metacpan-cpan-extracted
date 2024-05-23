# Contributions guidelines

## How to provide changes

Be sure, before creating a Pull Request, to:

1. To install and use `Perl::Tidy` in your code.
2. Run the tests under `t` and `xt`.
3. Make sure to add the comments `VERSION` and `ABSTRACT` in case of new packages.

Always create branches from the `master` branch.

## How to extend KernelReleases

You favorite Linux distribution might have available more information that you
want available. In order to have that, you must subclass
`Linux::Info::KernelRelease` superclass.

1. Create a new subdirectory under `t/samples/kernel` with the distribution
name.
1. In this new directory, create a file named `sys_osrelease` with the content
of `/proc/sys/kernel/osrelease` file.
1. Create another file named `version` with the content of `/proc/version`.
1. Under `lib/Linux/Info/KernelRelease` directory, create a new file with the
distribution name, using camel case.
1. In this file, make sure to inherit from the class
`Linux::Info::KernelRelease`.
1. Override the method `_set_proc_ver_regex`.
1. Add new getters for additional attributes with `Class::XSAccessor`.
1. Create a new test under `t` named `kernel-release-<DISTRO NAME>.t`.

## Adding a new Distribution

The process should look like the same for KernelReleases, but with one big
difference: you must decided if the information available will be fetched from
`/etc/os-release` or any other, distribution specific, file.

The `/etc/os-release` is becoming a standard between distributions and parsing
it will be easier because most of the job is already taken care by the classes
`Linux::Info::Distribution` and `Linux::Info::Distribution::OSRelease`.

For the second case, it will be more complex. You will need to inherit from
`Linux::Info::Distribution::Custom` and work on a regular expression that,
hopefully, will be enough to extract the information.

Also, you probably will need to take a look at `Linux::Info::DistributionFinder`
too.

In both cases, updating the class `Linux::Info::DistributionFactory` is
required.
