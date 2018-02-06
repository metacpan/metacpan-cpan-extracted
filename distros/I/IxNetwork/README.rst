IxNetwork is the Perl package for the IxNetwork Low Level API that allows you to configure and run IxNetwork tests.

Installing
==========
| The master branch always contains the latest official release. It is only updated on new IxNetwork releases. Official releases are posted to `CPAN <###########>`_.
| The dev branch contains improvements and fixes of the current release that will go into the next release version.


 * To install the official release
	    * with cpanm ``cpanm IxNetwork``

		If it does not have permission to install modules to the current perl, cpanm
		will automatically set up and install to a local::lib in your home directory.
		See the local::lib documentation (https://metacpan.org/pod/local::lib) for
		details on enabling it in your environment.
		
		* with the CPAN shell ``cpan IxNetwork``
		
 * To manually install the version in github: 
		* clone the repository
		* perl Build.PL
		* perl Build
		* perl Build install


Documentation
=============
| For general language documentation of IxNetwork API see `IxNetwork API Docs <http://downloads.ixiacom.com/library/user_guides/IxNetwork/8.40/EA_8.40_Rev_A/LowLevelApiGuide.zip>`_.
| This will require a login to `Ixia Support <https://support.ixiacom.com/user-guide>`_ web page.


IxNetwork API server / Perl Support
==================================
IxNetwork API package 8.40 supports IxNetwork API server 8.40+ and Perl 5.18.

Compatibility Policy
====================
| IxNetwork supported IxNetwork API server version and Perl versions are mentioned in the above "Support" section.
| Compatibility with older versions may work but will not be actively supported.

Related Projects
================
* IxNetwork API Tcl Bindings: https://github.com/ixiacom/ixnetwork-api-tcl
* IxNetwork API Python Bindings: https://github.com/ixiacom/ixnetwork-api-py
* IxNetwork API Ruby Bindings: https://github.com/ixiacom/ixnetwork-api-rb
