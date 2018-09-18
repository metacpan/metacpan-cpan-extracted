IxNetwork is the Perl module for the IxNetwork Low Level API that allows you to configure and run IxNetwork tests.

Installing
==========
| The master branch always contains the latest official release. It is only updated on new IxNetwork releases. Official releases are posted to `CPAN <https://metacpan.org/release/IxNetwork>`_.
| The dev branch contains improvements and fixes of the current release that will go into the next release version.


 * To install the official release
	    * with cpanm ``cpanm IxNetwork``
		* with the CPAN shell ``cpan IxNetwork``
		
 * To manually install the version in github: 
		* clone the repository
		* ``perl Build.PL``
		* ``perl Build``
		* ``perl Build install``


Documentation
=============
| For general language documentation of IxNetwork API see the `Low Level API Guide <http://downloads.ixiacom.com/library/user_guides/IxNetwork/8.50/EA_8.50_Rev_A/LowLevelApiGuide.zip>`_ and the `IxNetwork API Help <http://downloads.ixiacom.com/library/user_guides/ixnetwork/8.50/EA_8.50_Rev_A/IxNetwork_HTML5/IxNetwork.htm>`_.
| This will require a login to `Ixia Support <https://support.ixiacom.com/user-guide>`_ web page.


IxNetwork API server / Perl Support
==================================
IxNetwork API  8.50 library supports:

* Perl 5.18
* IxNetwork Windows API server 8.40+
* IxNetwork Web Edition (Linux API Server) 8.50+

Compatibility with older versions may continue to work but it is not actively supported.

Compatibility Policy
====================
IxNetwork Low Level API library is supported on the following operating systems:

* Microsoft Windows
* CentOS 7 on x64 platform

Related Projects
================
* IxNetwork API Tcl Bindings: https://github.com/ixiacom/ixnetwork-api-tcl
* IxNetwork API Python Bindings: https://github.com/ixiacom/ixnetwork-api-py
* IxNetwork API Ruby Bindings: https://github.com/ixiacom/ixnetwork-api-rb
