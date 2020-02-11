# How to package new releases of the module ?

## Git flow to respect.
All evolutions or bugs resolution should be documented in one ticket on
the bug tracker and on the POD documentation if the API changes. Each of
those tickets should be done in a distinct Git branch that starts from
the previous published version (the _master_ branch).
The release should also starts from it's own branch from _master_ into
which all other branchs will be merged inside it.

## Build of the release.
When our release branch is done, a commit should be added that updates
some data:

* Update the year in all headers copyrights (if needed).
* Update the version number in all those places:
    * In the `dist.ini` file.
    * In the `lib/Linux/LXC.pod` file.
    * In the `lib/Linux/LXC.pm` file.
* Add in the _Changes_ file the changelog of all modifications. The date
of the release should not be written by hand but should be replaced by
`{{$NEXT}}`.
* Ensure that extra tests passed (see section above for knowing how to
do it).
* Run the `dzil build` command that will create the new package of the
module.
* Run the `dzil release` command that will upload the module to the
CPAN. If you are releasing from outside your test environment, you will
probably have to delete the _RunExtraTests_ and _TestRelease_ options
from the _dist.ini_ file because integration tests will fail and thus,
avoiding the release to be uploaded. If you do so, please run a `dzil
test` command from your test virtual machine before the releasing!

# How to run integration (extra) tests?

Tests used in this module are messy because they need to create an LXC
container and manipulate it.
We recommend thus you to create a virtual machine with everything needed
for running them.

## How to create a VirtualBox image for running tests?
* Clone this repository somewhere on your computer.
* Download the last Debian version (today, the version 9.5).
* Install Debian in a new VirtualBox machine.
* Install the VirtualBox guest addition in the image for allowing you to
create a shared folder.
* Share your git repo of the projet with the virtual OS, say, in
/opt/perl-linux-lxc folder.
    * This command can be useful for mounting the folder: `mount -t vboxsf perl-virt-lxc /opt/perl-linux-lxc`.
* Install some external packages:
    * `apt install dh-dist-zilla make lxc`
    * Install the currently released version of Linux::LXC for
    installing all dependencies: `cpan Linux::LXC`.
    * Install Dist::Zilla and a lot of other needed modules :
    `cpan Dist::Zilla Dist::Zilla::Plugin::RunExtraTests Test::Pod
    Test::Pod::Coverage Pod::Coverage::TestPod Pod::Coverage::TrustPod Log::Any::Adapter`.

## What to test?
LXC version 3 is not backward compliant with 2 one. Thus, it is important to test that any modification of the plugin
will not add regression with LXC 2. This can be done by running all tests on a system that use LXC 2 and on a second one with LXC 3.

Debian 9.5 can be used as host for testing LXC 2, and Debian 10 as host for LXC 3.

## How to run the tests?
Extra tests are the most important because it's the ones that manipulate
concretely LXC containers.
For running it, launch the `dzil test` command in the root of the git
repository.
This command will run both unit and integration (extra) tests.
