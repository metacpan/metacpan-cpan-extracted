package ExtUtils::ModuleMaker::Licenses::Standard;
#$Id$
use strict;
use warnings;

BEGIN {
    use base qw(Exporter);
    use vars qw( @EXPORT_OK $VERSION );
    $VERSION = 0.56;
    @EXPORT_OK   = qw(Get_Standard_License Verify_Standard_License);
#    $VERSION     : taken from lib/ExtUtils/ModuleMaker.pm
}

#################### DOCUMENTATION ####################

=head1 NAME

ExtUtils::ModuleMaker::Licenses::Standard - Open source software licenses

=head1 SYNOPSIS

  use ExtUtils::ModuleMaker::Licenses::Standard;
  blah blah blah

=head1 DESCRIPTION

This package holds subroutines imported and used by
ExtUtils::ModuleMaker to include license and copyright information in a
standard Perl module distribution.

=head1 BUGS

None known at this time.

=head1 AUTHOR/MAINTAINER

ExtUtils::ModuleMaker was originally written in 2001-02 by R. Geoffrey Avery
(modulemaker [at] PlatypiVentures [dot] com).  Since version 0.33 (July
2005) it has been maintained by James E. Keenan (jkeenan [at] cpan [dot]
org).

=head1 SUPPORT

Send email to jkeenan [at] cpan [dot] org.  Please include 'modulemaker'
in the subject line.

=head1 COPYRIGHT

Copyright (c) 2001-2002 R. Geoffrey Avery.
Revisions from v0.33 forward (c) 2005 James E. Keenan.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>, F<modulemaker>, perl(1).

=cut

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut

my %licenses = (
    perl            => { function => \&License_Perl,
                         fullname =>'Same terms as Perl itself',
                       },

    apache          => { function => \&License_Apache_1_1,
                         fullname => ''
                       },
    apache_1_1      => { function => \&License_Apache_1_1,
                         fullname => 'Apache Software License (1.1)'
                       },
    artistic        => { function => \&License_Artistic,
                         fullname => 'Artistic License'
                       },
    artistic_agg    => { function => \&License_Artistic_w_Aggregation,
                         fullname => 'Artistic License w/ Aggregation'
                       },
    r_bsd           => { function => \&License_r_BSD,
                         fullname => 'BSD License(Raw)'
                       },
    bsd             => { function => \&License_BSD,
                         fullname => 'BSD License'
                       },
    gpl             => { function => \&License_GPL_2,
                         fullname => ''
                       },
    gpl_2           => { function => \&License_GPL_2,
                         fullname => 'GPL - General Public License (2)'
                       },
    ibm             => { function => \&License_IBM_1_0,
                         fullname => ''
                       },
    ibm_1_0         => { function => \&License_IBM_1_0,
                         fullname => 'IBM Public License Version (1.0)'
                       },
    intel           => { function => \&License_Intel,
                         fullname => 'Intel (BSD+)'
                       },
    jabber          => { function => \&License_Jabber_1_0,
                         fullname => ''
                       },
    jabber_1_0      => { function => \&License_Jabber_1_0,
                         fullname => 'Jabber (1.0)'
                       },
    lgpl            => { function => \&License_LGPL_2_1,
                         fullname => ''
                       },
    lgpl_2_1        => { function => \&License_LGPL_2_1,
                         fullname => 'LGPL - GNU Lesser General Public License (2.1)'
                       },
    mit             => { function => \&License_MIT,
                         fullname => 'MIT License'
                       },
    mitre           => { function => \&License_MITRE,
                         fullname => 'CVW - MITRE Collaborative Virtual Workspace'
                       },#mitre includes gpl 2.0 and mozilla 1.0
    mozilla         => { function => \&License_Mozilla_1_1,
                         fullname => ''
                       },
    mozilla_1_1     => { function => \&License_Mozilla_1_1,
                         fullname => 'Mozilla Public License (1.1)'
                       },
    mozilla_1_0     => { function => \&License_Mozilla_1_0,
                         fullname => 'Mozilla Public License (1.0)'
                       },
    mpl             => { function => \&License_Mozilla_1_1,
                         fullname => ''
                       },
    mpl_1_1         => { function => \&License_Mozilla_1_1,
                         fullname => ''
                       },
    mpl_1_0         => { function => \&License_Mozilla_1_0,
                         fullname => ''
                       },
    nethack         => { function => \&License_Nethack,
                         fullname => 'Nethack General Public License'
                       },
    nokia           => { function => \&License_Nokia_1_0a,
                         fullname => ''
                       },
    nokos           => { function => \&License_Nokia_1_0a,
                         fullname => ''
                       },
    nokia_1_0a      => { function => \&License_Nokia_1_0a,
                         fullname => 'Nokia Open Source License(1.0a)'
                       },
    nokos_1_0a      => { function => \&License_Nokia_1_0a,
                         fullname => ''
                       },
    python          => { function => \&License_Python,
                         fullname => 'Python License'
                       },
    q               => { function => \&License_Q_1_0,
                         fullname => ''
                       },
    q_1_0           => { function => \&License_Q_1_0,
                         fullname => 'Q Public License (1.0)'
                       },
    ricoh           => { function => \&License_Ricoh_1_0,
                         fullname => ''
                       },
    ricoh_1_0       => { function => \&License_Ricoh_1_0,
                         fullname => 'Ricoh Source Code Public License (1.0)'
                       },
    sun             => { function => \&License_Sun,
                         fullname => ''
                       },
    sissl           => { function => \&License_Sun,
                         fullname => 'Sun Internet Standards Source License'
                       },
    sleepycat       => { function => \&License_Sleepycat,
                         fullname => 'The Sleepycat License'
                       },
    vovida          => { function => \&License_Vovida_1_0,
                         fullname => ''
                       },
    vovida_1_0      => { function => \&License_Vovida_1_0,
                         fullname => 'Vovida Software License (1.0)'
                       },
    zlib            => { function => \&License_ZLIB,
                         fullname => 'zlib/libpng License'
                       },
    libpng          => { function => \&License_ZLIB,
                         fullname => ''
                       },
#not yet installed
#             python_2_1_1    => { function => undef,
#                                 fullname => ''
#                               },
#             commonpublic    => { function => undef,
#                                 fullname => ''
#                               },
#             applepublic    => { function => undef,
#                                 fullname => ''
#                               },
#             xnet            => { function => undef,
#                                 fullname => ''
#                               },
#             sunpublic        => { function => undef,
#                                 fullname => ''
#                               },
#             eiffel            => { function => undef,
#                                 fullname => ''
#                               },
#             w3c            => { function => undef,
#                                 fullname => ''
#                               },
#             motosoto        => { function => undef,
#                                 fullname => ''
#                               },
#             opengroup        => { function => undef,
#                                 fullname => ''
#                               },
#             zopepublic        => { function => undef,
#                                 fullname => ''
#                               },
#             u_illinois_ncsa=> { function => undef,
#                                 fullname => ''
#                               },
            );

sub Get_Standard_License {
    my $choice = shift;

    $choice = lc ($choice);
    return ($licenses{$choice}{function}) if (exists $licenses{$choice});
    return;
}

sub Verify_Standard_License {
    my $choice = shift;
    return (exists $licenses{lc ($choice)});
}

sub interact {
    my $class = shift;
    return (bless (
        { map { ($licenses{$_}{fullname})
                     ? ($_ => $licenses{$_}{fullname})
                     : ()
              } keys (%licenses)
        }, ref ($class) || $class)
    );
}

################################################ subroutine header begin ##

=head2 License_Apache

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Apache_1_1 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Apache Software License (Version 1.1)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Apache Software License
Version 1.1

Copyright (c) ###year### ###organization###. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list
of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or other
materials provided with the distribution.

3. The end-user documentation included with the redistribution, if any, must
include the following acknowledgment:

     "This product includes software developed by the Apache Software
     Foundation (http://www.apache.org/)."

Alternately, this acknowledgment may appear in the software itself, if and
wherever such third-party acknowledgments normally appear.

4. The names "Apache" and "Apache Software Foundation" must not be used to
endorse or promote products derived from this software without prior written
permission. For written permission, please contact apache\@apache.org.

5. Products derived from this software may not be called "Apache", nor may
"Apache" appear in their name, without prior written permission of the Apache
Software Foundation.

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE APACHE
SOFTWARE FOUNDATION OR ITS CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.



This software consists of voluntary contributions made by many individuals on
behalf of the Apache Software Foundation. For more information on the Apache
Software Foundation, please see <http://www.apache.org/>.

Portions of this software are based upon public domain software originally written
at the National Center for Supercomputing Applications, University of Illinois,
Urbana-Champaign.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Artistic

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Artistic {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The Artistic License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The Artistic License

Preamble

The intent of this document is to state the conditions under which a Package
may be copied, such that the Copyright Holder maintains some semblance of
artistic control over the development of the package, while giving the users of the
package the right to use and distribute the Package in a more-or-less customary
fashion, plus the right to make reasonable modifications.

Definitions:

-    "Package" refers to the collection of files distributed by the Copyright
     Holder, and derivatives of that collection of files created through textual
     modification. 
-    "Standard Version" refers to such a Package if it has not been modified,
     or has been modified in accordance with the wishes of the Copyright
     Holder. 
-    "Copyright Holder" is whoever is named in the copyright or copyrights for
     the package. 
-    "You" is you, if you're thinking about copying or distributing this Package.
-    "Reasonable copying fee" is whatever you can justify on the basis of
     media cost, duplication charges, time of people involved, and so on. (You
     will not be required to justify it to the Copyright Holder, but only to the
     computing community at large as a market that must bear the fee.) 
-    "Freely Available" means that no fee is charged for the item itself, though
     there may be fees involved in handling the item. It also means that
     recipients of the item may redistribute it under the same conditions they
     received it. 

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you duplicate
all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications derived from
the Public Domain or from the Copyright Holder. A Package modified in such a
way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and when
you changed that file, and provided that you do at least ONE of the following:

     a) place your modifications in the Public Domain or otherwise
     make them Freely Available, such as by posting said modifications
     to Usenet or an equivalent medium, or placing the modifications on
     a major archive site such as ftp.uu.net, or by allowing the
     Copyright Holder to include your modifications in the Standard
     Version of the Package.

     b) use the modified Package only within your corporation or
     organization.

     c) rename any non-standard executables so the names do not
     conflict with standard executables, which must also be provided,
     and provide a separate manual page for each non-standard
     executable that clearly documents how it differs from the Standard
     Version.

     d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or executable
form, provided that you do at least ONE of the following:

     a) distribute a Standard Version of the executables and library
     files, together with instructions (in the manual page or equivalent)
     on where to get the Standard Version.

     b) accompany the distribution with the machine-readable source of
     the Package with your modifications.

     c) accompany any non-standard executables with their
     corresponding Standard Version executables, giving the
     non-standard executables non-standard names, and clearly
     documenting the differences in manual pages (or equivalent),
     together with instructions on where to get the Standard Version.

     d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this Package.
You may charge any fee you choose for support of this Package. You may not
charge a fee for this Package itself. However, you may distribute this Package in
aggregate with other (possibly commercial) programs as part of a larger
(possibly commercial) software distribution provided that you do not advertise
this Package as a product of your own.

6. The scripts and library files supplied as input to or produced as output from
the programs of this Package do not automatically fall under the copyright of this
Package, but belong to whomever generated them, and may be sold
commercially, and may be aggregated with this Package.

7. C or perl subroutines supplied by you and linked into this Package shall not
be considered part of this Package.

8. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

9. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

The End
EOFLICENSETEXT

    return (\%license);
}
#'

sub License_Artistic_w_Aggregation {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The Artistic License (with Aggregation clause)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The Artistic License

Preamble

The intent of this document is to state the conditions under which a Package
may be copied, such that the Copyright Holder maintains some semblance of
artistic control over the development of the package, while giving the users of the
package the right to use and distribute the Package in a more-or-less customary
fashion, plus the right to make reasonable modifications.

Definitions:

-    "Package" refers to the collection of files distributed by the Copyright
     Holder, and derivatives of that collection of files created through textual
     modification. 
-    "Standard Version" refers to such a Package if it has not been modified,
     or has been modified in accordance with the wishes of the Copyright
     Holder. 
-    "Copyright Holder" is whoever is named in the copyright or copyrights for
     the package. 
-    "You" is you, if you're thinking about copying or distributing this Package.
-    "Reasonable copying fee" is whatever you can justify on the basis of
     media cost, duplication charges, time of people involved, and so on. (You
     will not be required to justify it to the Copyright Holder, but only to the
     computing community at large as a market that must bear the fee.) 
-    "Freely Available" means that no fee is charged for the item itself, though
     there may be fees involved in handling the item. It also means that
     recipients of the item may redistribute it under the same conditions they
     received it. 

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you duplicate
all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications derived from
the Public Domain or from the Copyright Holder. A Package modified in such a
way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and when
you changed that file, and provided that you do at least ONE of the following:

     a) place your modifications in the Public Domain or otherwise
     make them Freely Available, such as by posting said modifications
     to Usenet or an equivalent medium, or placing the modifications on
     a major archive site such as ftp.uu.net, or by allowing the
     Copyright Holder to include your modifications in the Standard
     Version of the Package.

     b) use the modified Package only within your corporation or
     organization.

     c) rename any non-standard executables so the names do not
     conflict with standard executables, which must also be provided,
     and provide a separate manual page for each non-standard
     executable that clearly documents how it differs from the Standard
     Version.

     d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or executable
form, provided that you do at least ONE of the following:

     a) distribute a Standard Version of the executables and library
     files, together with instructions (in the manual page or equivalent)
     on where to get the Standard Version.

     b) accompany the distribution with the machine-readable source of
     the Package with your modifications.

     c) accompany any non-standard executables with their
     corresponding Standard Version executables, giving the
     non-standard executables non-standard names, and clearly
     documenting the differences in manual pages (or equivalent),
     together with instructions on where to get the Standard Version.

     d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this Package.
You may charge any fee you choose for support of this Package. You may not
charge a fee for this Package itself. However, you may distribute this Package in
aggregate with other (possibly commercial) programs as part of a larger
(possibly commercial) software distribution provided that you do not advertise
this Package as a product of your own.

6. The scripts and library files supplied as input to or produced as output from
the programs of this Package do not automatically fall under the copyright of this
Package, but belong to whomever generated them, and may be sold
commercially, and may be aggregated with this Package.

7. C or perl subroutines supplied by you and linked into this Package shall not
be considered part of this Package.

8. Aggregation of this Package with a commercial distribution is always permitted
provided that the use of this Package is embedded; that is, when no overt attempt
is made to make this Package's interfaces visible to the end user of the
commercial distribution. Such use shall not be construed as a distribution of
this Package.

9. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

The End
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_r_BSD

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_r_BSD {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The BSD License

     The following is a BSD license template. To generate
     your own license, change the values of OWNER,
     ORGANIZATION and YEAR from their original values as
     given here, and substitute your own.

     Note: The advertising clause in the license appearing
     on BSD Unix files was officially rescinded by the
     Director of the Office of Technology Licensing of the
     University of California on July 22 1999. He states that
     clause 3 is "hereby deleted in its entirety."

     Note the new BSD license is thus equivalent to the MIT
     License, except for the no-endorsement final clause.

<OWNER> = Regents of the University of California
<ORGANIZATION> = University of California, Berkeley
<YEAR> = 1998

In the original BSD license, the first occurrence of the phrase "COPYRIGHT
HOLDERS AND CONTRIBUTORS" in the disclaimer read "REGENTS AND
CONTRIBUTORS".

Here is the license template:

Copyright (c) <YEAR>, <OWNER>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

     Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer. 
     Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution. 
     Neither the name of the <ORGANIZATION> nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_BSD

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_BSD {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The BSD License


Copyright (c) ###year###, ###owner###
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

     Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer. 
     Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution. 
     Neither the name of the ###organization### nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_GPL

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_GPL_2 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The General Public License (GPL)
Version 2, June 1991

Copyright (C) 1989, 1991 Free Software Foundation, Inc. 675 Mass Ave,
Cambridge, MA 02139, USA. Everyone is permitted to copy and distribute
verbatim copies of this license document, but changing it is not allowed.

Preamble

The licenses for most software are designed to take away your freedom to share
and change it. By contrast, the GNU General Public License is intended to
guarantee your freedom to share and change free software--to make sure the
software is free for all its users. This General Public License applies to most of
the Free Software Foundation's software and to any other program whose
authors commit to using it. (Some other Free Software Foundation software is
covered by the GNU Library General Public License instead.) You can apply it to
your programs, too.

When we speak of free software, we are referring to freedom, not price. Our
General Public Licenses are designed to make sure that you have the freedom
to distribute copies of free software (and charge for this service if you wish), that
you receive source code or can get it if you want it, that you can change the
software or use pieces of it in new free programs; and that you know you can do
these things.

To protect your rights, we need to make restrictions that forbid anyone to deny
you these rights or to ask you to surrender the rights. These restrictions
translate to certain responsibilities for you if you distribute copies of the
software, or if you modify it.

For example, if you distribute copies of such a program, whether gratis or for a
fee, you must give the recipients all the rights that you have. You must make
sure that they, too, receive or can get the source code. And you must show
them these terms so they know their rights.

We protect your rights with two steps: (1) copyright the software, and (2) offer
you this license which gives you legal permission to copy, distribute and/or
modify the software.

Also, for each author's protection and ours, we want to make certain that
everyone understands that there is no warranty for this free software. If the
software is modified by someone else and passed on, we want its recipients to
know that what they have is not the original, so that any problems introduced by
others will not reflect on the original authors' reputations.

Finally, any free program is threatened constantly by software patents. We wish
to avoid the danger that redistributors of a free program will individually obtain
patent licenses, in effect making the program proprietary. To prevent this, we
have made it clear that any patent must be licensed for everyone's free use or
not licensed at all.

The precise terms and conditions for copying, distribution and modification
follow.

GNU GENERAL PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND
MODIFICATION

0. This License applies to any program or other work which contains a notice
placed by the copyright holder saying it may be distributed under the terms of
this General Public License. The "Program", below, refers to any such program
or work, and a "work based on the Program" means either the Program or any
derivative work under copyright law: that is to say, a work containing the
Program or a portion of it, either verbatim or with modifications and/or translated
into another language. (Hereinafter, translation is included without limitation in
the term "modification".) Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not covered by
this License; they are outside its scope. The act of running the Program is not
restricted, and the output from the Program is covered only if its contents
constitute a work based on the Program (independent of having been made by
running the Program). Whether that is true depends on what the Program does.

1. You may copy and distribute verbatim copies of the Program's source code as
you receive it, in any medium, provided that you conspicuously and appropriately
publish on each copy an appropriate copyright notice and disclaimer of warranty;
keep intact all the notices that refer to this License and to the absence of any
warranty; and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and you may at
your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion of it, thus
forming a work based on the Program, and copy and distribute such
modifications or work under the terms of Section 1 above, provided that you also
meet all of these conditions:

a) You must cause the modified files to carry prominent notices stating that you
changed the files and the date of any change.

b) You must cause any work that you distribute or publish, that in whole or in
part contains or is derived from the Program or any part thereof, to be licensed
as a whole at no charge to all third parties under the terms of this License.

c) If the modified program normally reads commands interactively when run, you
must cause it, when started running for such interactive use in the most ordinary
way, to print or display an announcement including an appropriate copyright
notice and a notice that there is no warranty (or else, saying that you provide a
warranty) and that users may redistribute the program under these conditions,
and telling the user how to view a copy of this License. (Exception: if the
Program itself is interactive but does not normally print such an announcement,
your work based on the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole. If identifiable
sections of that work are not derived from the Program, and can be reasonably
considered independent and separate works in themselves, then this License,
and its terms, do not apply to those sections when you distribute them as
separate works. But when you distribute the same sections as part of a whole
which is a work based on the Program, the distribution of the whole must be on
the terms of this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest your rights to
work written entirely by you; rather, the intent is to exercise the right to control
the distribution of derivative or collective works based on the Program.

In addition, mere aggregation of another work not based on the Program with the
Program (or with a work based on the Program) on a volume of a storage or
distribution medium does not bring the other work under the scope of this
License.

3. You may copy and distribute the Program (or a work based on it, under
Section 2) in object code or executable form under the terms of Sections 1 and 2
above provided that you also do one of the following:

a) Accompany it with the complete corresponding machine-readable source
code, which must be distributed under the terms of Sections 1 and 2 above on a
medium customarily used for software interchange; or,

b) Accompany it with a written offer, valid for at least three years, to give any
third party, for a charge no more than your cost of physically performing source
distribution, a complete machine-readable copy of the corresponding source
code, to be distributed under the terms of Sections 1 and 2 above on a medium
customarily used for software interchange; or,

c) Accompany it with the information you received as to the offer to distribute
corresponding source code. (This alternative is allowed only for noncommercial
distribution and only if you received the program in object code or executable
form with such an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for making
modifications to it. For an executable work, complete source code means all the
source code for all modules it contains, plus any associated interface definition
files, plus the scripts used to control compilation and installation of the
executable. However, as a special exception, the source code distributed need
not include anything that is normally distributed (in either source or binary form)
with the major components (compiler, kernel, and so on) of the operating system
on which the executable runs, unless that component itself accompanies the
executable.

If distribution of executable or object code is made by offering access to copy
from a designated place, then offering equivalent access to copy the source
code from the same place counts as distribution of the source code, even though
third parties are not compelled to copy the source along with the object code.

4. You may not copy, modify, sublicense, or distribute the Program except as
expressly provided under this License. Any attempt otherwise to copy, modify,
sublicense or distribute the Program is void, and will automatically terminate
your rights under this License. However, parties who have received copies, or
rights, from you under this License will not have their licenses terminated so long
as such parties remain in full compliance.

5. You are not required to accept this License, since you have not signed it.
However, nothing else grants you permission to modify or distribute the Program
or its derivative works. These actions are prohibited by law if you do not accept
this License. Therefore, by modifying or distributing the Program (or any work
based on the Program), you indicate your acceptance of this License to do so,
and all its terms and conditions for copying, distributing or modifying the
Program or works based on it.

6. Each time you redistribute the Program (or any work based on the Program),
the recipient automatically receives a license from the original licensor to copy,
distribute or modify the Program subject to these terms and conditions. You
may not impose any further restrictions on the recipients' exercise of the rights
granted herein. You are not responsible for enforcing compliance by third parties
to this License.

7. If, as a consequence of a court judgment or allegation of patent infringement
or for any other reason (not limited to patent issues), conditions are imposed on
you (whether by court order, agreement or otherwise) that contradict the
conditions of this License, they do not excuse you from the conditions of this
License. If you cannot distribute so as to satisfy simultaneously your obligations
under this License and any other pertinent obligations, then as a consequence
you may not distribute the Program at all. For example, if a patent license would
not permit royalty-free redistribution of the Program by all those who receive
copies directly or indirectly through you, then the only way you could satisfy
both it and this License would be to refrain entirely from distribution of the
Program.

If any portion of this section is held invalid or unenforceable under any particular
circumstance, the balance of the section is intended to apply and the section as
a whole is intended to apply in other circumstances.

It is not the purpose of this section to induce you to infringe any patents or other
property right claims or to contest validity of any such claims; this section has
the sole purpose of protecting the integrity of the free software distribution
system, which is implemented by public license practices. Many people have
made generous contributions to the wide range of software distributed through
that system in reliance on consistent application of that system; it is up to the
author/donor to decide if he or she is willing to distribute software through any
other system and a licensee cannot impose that choice.

This section is intended to make thoroughly clear what is believed to be a
consequence of the rest of this License.

8. If the distribution and/or use of the Program is restricted in certain countries
either by patents or by copyrighted interfaces, the original copyright holder who
places the Program under this License may add an explicit geographical
distribution limitation excluding those countries, so that distribution is permitted
only in or among countries not thus excluded. In such case, this License
incorporates the limitation as if written in the body of this License.

9. The Free Software Foundation may publish revised and/or new versions of the
General Public License from time to time. Such new versions will be similar in
spirit to the present version, but may differ in detail to address new problems or
concerns.

Each version is given a distinguishing version number. If the Program specifies a
version number of this License which applies to it and "any later version", you
have the option of following the terms and conditions either of that version or of
any later version published by the Free Software Foundation. If the Program does
not specify a version number of this License, you may choose any version ever
published by the Free Software Foundation.

10. If you wish to incorporate parts of the Program into other free programs
whose distribution conditions are different, write to the author to ask for
permission. For software which is copyrighted by the Free Software Foundation,
write to the Free Software Foundation; we sometimes make exceptions for this.
Our decision will be guided by the two goals of preserving the free status of all
derivatives of our free software and of promoting the sharing and reuse of
software generally.

NO WARRANTY

11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS
NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE
COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM
"AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED
TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY
WHO MAY MODIFY AND/OR REDISTRIBUTE THE PROGRAM AS
PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM
(INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY
OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_IBM

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_IBM_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	IBM Public License Version (1.0)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
IBM Public License Version (1.0)

THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF
THIS IBM PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION
OR DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT'S
ACCEPTANCE OF THIS AGREEMENT. 

1. DEFINITIONS 

"Contribution" means: 

  a.in the case of International Business Machines Corporation ("IBM"), the
     Original Program, and 
  b.in the case of each Contributor, 
        i.changes to the Program, and 
       ii.additions to the Program; 
     where such changes and/or additions to the Program originate from and
     are distributed by that particular Contributor. A Contribution 'originates'
     from a Contributor if it was added to the Program by such Contributor
     itself or anyone acting on such Contributor's behalf. Contributions do not
     include additions to the Program which: (i) are separate modules of
     software distributed in conjunction with the Program under their own
     license agreement, and (ii) are not derivative works of the Program. 

"Contributor" means IBM and any other entity that distributes the Program. 

"Licensed Patents " mean patent claims licensable by a Contributor which are
necessarily infringed by the use or sale of its Contribution alone or when
combined with the Program. 

"Original Program" means the original version of the software accompanying this
Agreement as released by IBM, including source code, object code and
documentation, if any. 

"Program" means the Original Program and Contributions. 

"Recipient" means anyone who receives the Program under this Agreement,
including all Contributors. 

2. GRANT OF RIGHTS 

  a.Subject to the terms of this Agreement, each Contributor hereby grants
     Recipient a non-exclusive, worldwide, royalty-free copyright license to
     reproduce, prepare derivative works of, publicly display, publicly perform,
     distribute and sublicense the Contribution of such Contributor, if any, and
     such derivative works, in source code and object code form. 
  b.Subject to the terms of this Agreement, each Contributor hereby grants
     Recipient a non-exclusive, worldwide, royalty-free patent license under
     Licensed Patents to make, use, sell, offer to sell, import and otherwise
     transfer the Contribution of such Contributor, if any, in source code and
     object code form. This patent license shall apply to the combination of the
     Contribution and the Program if, at the time the Contribution is added by
     the Contributor, such addition of the Contribution causes such
     combination to be covered by the Licensed Patents. The patent license
     shall not apply to any other combinations which include the Contribution.
     No hardware per se is licensed hereunder. 
  c.Recipient understands that although each Contributor grants the licenses
     to its Contributions set forth herein, no assurances are provided by any
     Contributor that the Program does not infringe the patent or other
     intellectual property rights of any other entity. Each Contributor disclaims
     any liability to Recipient for claims brought by any other entity based on
     infringement of intellectual property rights or otherwise. As a condition to
     exercising the rights and licenses granted hereunder, each Recipient
     hereby assumes sole responsibility to secure any other intellectual
     property rights needed, if any. For example, if a third party patent license
     is required to allow Recipient to distribute the Program, it is Recipient's
     responsibility to acquire that license before distributing the Program. 
  d.Each Contributor represents that to its knowledge it has sufficient
     copyright rights in its Contribution, if any, to grant the copyright license
     set forth in this Agreement. 

3. REQUIREMENTS 

A Contributor may choose to distribute the Program in object code form under its
own license agreement, provided that: 

  a.it complies with the terms and conditions of this Agreement; and 
  b.its license agreement: 
        i.effectively disclaims on behalf of all Contributors all warranties and
          conditions, express and implied, including warranties or conditions
          of title and non-infringement, and implied warranties or conditions
          of merchantability and fitness for a particular purpose; 
       ii.effectively excludes on behalf of all Contributors all liability for
          damages, including direct, indirect, special, incidental and
          consequential damages, such as lost profits; 
       iii.states that any provisions which differ from this Agreement are
          offered by that Contributor alone and not by any other party; and 
       iv.states that source code for the Program is available from such
          Contributor, and informs licensees how to obtain it in a reasonable
          manner on or through a medium customarily used for software
          exchange. 

When the Program is made available in source code form: 

  a.it must be made available under this Agreement; and 
  b.a copy of this Agreement must be included with each copy of the
     Program. 

Each Contributor must include the following in a conspicuous location in the
Program: 

     Copyright (C) 1996, 1999 International Business Machines
     Corporation and others. All Rights Reserved. 

In addition, each Contributor must identify itself as the originator of its
Contribution, if any, in a manner that reasonably allows subsequent Recipients
to identify the originator of the Contribution. 

4. COMMERCIAL DISTRIBUTION 

Commercial distributors of software may accept certain responsibilities with
respect to end users, business partners and the like. While this license is
intended to facilitate the commercial use of the Program, the Contributor who
includes the Program in a commercial product offering should do so in a manner
which does not create potential liability for other Contributors. Therefore, if a
Contributor includes the Program in a commercial product offering, such
Contributor ("Commercial Contributor") hereby agrees to defend and indemnify
every other Contributor ("Indemnified Contributor") against any losses, damages
and costs (collectively "Losses") arising from claims, lawsuits and other legal
actions brought by a third party against the Indemnified Contributor to the extent
caused by the acts or omissions of such Commercial Contributor in connection
with its distribution of the Program in a commercial product offering. The
obligations in this section do not apply to any claims or Losses relating to any
actual or alleged intellectual property infringement. In order to qualify, an
Indemnified Contributor must: a) promptly notify the Commercial Contributor in
writing of such claim, and b) allow the Commercial Contributor to control, and
cooperate with the Commercial Contributor in, the defense and any related
settlement negotiations. The Indemnified Contributor may participate in any such
claim at its own expense. 

For example, a Contributor might include the Program in a commercial product
offering, Product X. That Contributor is then a Commercial Contributor. If that
Commercial Contributor then makes performance claims, or offers warranties
related to Product X, those performance claims and warranties are such
Commercial Contributor's responsibility alone. Under this section, the
Commercial Contributor would have to defend claims against the other
Contributors related to those performance claims and warranties, and if a court
requires any other Contributor to pay any damages as a result, the Commercial
Contributor must pay those damages. 

5. NO WARRANTY 

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE
PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES
OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING,
WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE,
NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. Each Recipient is solely responsible for determining the
appropriateness of using and distributing the Program and assumes all risks
associated with its exercise of rights under this Agreement, including but not
limited to the risks and costs of program errors, compliance with applicable
laws, damage to or loss of data, programs or equipment, and unavailability or
interruption of operations. 

6. DISCLAIMER OF LIABILITY 

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER
RECIPIENT NOR ANY CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING WITHOUT LIMITATION LOST
PROFITS), HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OR
DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS
GRANTED HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES. 

7. GENERAL 

If any provision of this Agreement is invalid or unenforceable under applicable
law, it shall not affect the validity or enforceability of the remainder of the terms of
this Agreement, and without further action by the parties hereto, such provision
shall be reformed to the minimum extent necessary to make such provision valid
and enforceable. 

If Recipient institutes patent litigation against a Contributor with respect to a
patent applicable to software (including a cross-claim or counterclaim in a
lawsuit), then any patent licenses granted by that Contributor to such Recipient
under this Agreement shall terminate as of the date such litigation is filed. In
addition, if Recipient institutes patent litigation against any entity (including a
cross-claim or counterclaim in a lawsuit) alleging that the Program itself
(excluding combinations of the Program with other software or hardware)
infringes such Recipient's patent(s), then such Recipient's rights granted under
Section 2(b) shall terminate as of the date such litigation is filed. 

All Recipient's rights under this Agreement shall terminate if it fails to comply
with any of the material terms or conditions of this Agreement and does not cure
such failure in a reasonable period of time after becoming aware of such
noncompliance. If all Recipient's rights under this Agreement terminate,
Recipient agrees to cease use and distribution of the Program as soon as
reasonably practicable. However, Recipient's obligations under this Agreement
and any licenses granted by Recipient relating to the Program shall continue and
survive. 

IBM may publish new versions (including revisions) of this Agreement from time
to time. Each new version of the Agreement will be given a distinguishing version
number. The Program (including Contributions) may always be distributed
subject to the version of the Agreement under which it was received. In addition,
after a new version of the Agreement is published, Contributor may elect to
distribute the Program (including its Contributions) under the new version. No
one other than IBM has the right to modify this Agreement. Except as expressly
stated in Sections 2(a) and 2(b) above, Recipient receives no rights or licenses
to the intellectual property of any Contributor under this Agreement, whether
expressly, by implication, estoppel or otherwise. All rights in the Program not
expressly granted under this Agreement are reserved. 

This Agreement is governed by the laws of the State of New York and the
intellectual property laws of the United States of America. No party to this
Agreement will bring a legal action under this Agreement more than one year
after the cause of action arose. Each party waives its rights to a jury trial in any
resulting litigation.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Intel

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Intel {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The Intel Open Source License for CDSA/CSSM Implementation
	(BSD License with Export Notice)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The Intel Open Source License for CDSA/CSSM Implementation
(BSD License with Export Notice)

Copyright (c) 1996-2000 Intel Corporation
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met: 

     Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer. 
     Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution. 
     Neither the name of the Intel Corporation nor the names of its contributors
     may be used to endorse or promote products derived from this software
     without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE INTEL OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

EXPORT LAWS: THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT
LAWS OF YOUR JURISDICTION. It is licensee's responsibility to comply with
any export regulations applicable in licensee's jurisdiction. Under CURRENT
(May 2000) U.S. export regulations this software is eligible for export from the
U.S. and can be downloaded by or otherwise exported or reexported worldwide
EXCEPT to U.S. embargoed destinations which include Cuba, Iraq, Libya, North
Korea, Iran, Syria, Sudan, Afghanistan and any other country to which the U.S.
has embargoed goods and services.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Jabber

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Jabber_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Jabber Open Source License (Version 1.0)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Jabber Open Source License (Version 1.0)

This Jabber Open Source License (the "License")
applies to Jabber Server and related software products
as well as any updates or maintenance releases of that
software ("Jabber Products") that are distributed by
Jabber.Com, Inc. ("Licensor").  Any Jabber Product
licensed pursuant to this License is a “Licensed
Product.”  Licensed Product, in its entirety, is protected
by U.S. copyright law.  This License identifies the terms
under which you may use, copy, distribute or modify
Licensed Product.  

                  Preamble

      This Preamble is intended to describe,
      in plain English, the nature and scope of
      this License.  However, this Preamble is
      not a part of this license.  The legal
      effect of this License is dependent only
      upon the terms of the License and not
      this Preamble.

      This License complies with the Open
      Source Definition and has been
      approved by Open Source Initiative. 
      Software distributed under this License
      may be marked as "OSI Certified Open
      Source Software."

      This License provides that:

         1.      You may use, sell or give away
            the Licensed Product, alone or
            as a component of an aggregate
            software distribution containing
            programs from several different
            sources.  No royalty or other fee
            is required.  

         2.      Both Source Code and
            executable versions of the
            Licensed Product, including
            Modifications made by previous
            Contributors, are available for
            your use.  (The terms "Licensed
            Product," "Modifications,"
            "Contributors" and "Source
            Code" are defined in the
            License.) 

         3.      You are allowed to make
            Modifications to the Licensed
            Product, and you can create
            Derivative Works from it. (The
            term "Derivative Works" is
            defined in the License.) 

         4.      By accepting the Licensed
            Product under the provisions of
            this License, you agree that any
            Modifications you make to the
            Licensed Product and then
            distribute are governed by the
            provisions of this License.  In
            particular, you must make the
            Source Code of your
            Modifications available to others.

         5.      You may use the Licensed
            Product for any purpose, but the
            Licensor is not providing you any
            warranty whatsoever, nor is the
            Licensor accepting any liability in
            the event that the Licensed
            Product doesn't work properly or
            causes you any injury or
            damages.

         6.      If you sublicense the Licensed
            Product or Derivative Works, you
            may charge fees for warranty or
            support, or for accepting
            indemnity or liability obligations
            to your customers.  You cannot
            charge for the Source Code.

         7.      If you assert any patent claims
            against the Licensor relating to
            the Licensed Product, or if you
            breach any terms of the License,
            your rights to the Licensed
            Product under this License
            automatically terminate.

      You may use this License to distribute
      your own Derivative Works, in which
      case the provisions of this License will
      apply to your Derivative Works just as
      they do to the original Licensed
      Product.  

      Alternatively, you may distribute your
      Derivative Works under any other
      OSI-approved Open Source license, or
      under a proprietary license of your
      choice.  If you use any license other
      than this License, however, you must
      continue to fulfill the requirements of this
      License (including the provisions relating
      to publishing the Source Code) for those
      portions of your Derivative Works that
      consist of the Licensed Product,
      including the files containing
      Modifications.

      New versions of this License may be
      published from time to time.  You may
      choose to  continue to use the license
      terms in this version of the License or
      those from the new version.  However,
      only the Licensor has the right to
      change the License terms as they apply
      to the Licensed Product.  

      This License relies on precise definitions
      for certain terms.  Those terms are
      defined when they are first used, and
      the definitions are repeated for your
      convenience in a Glossary at the end of
      the License.

               License Terms

1.      Grant of License From Licensor.  Licensor
hereby grants you a world-wide, royalty-free,
non-exclusive license, subject to third party intellectual
property claims, to do the following:  

   a.       Use, reproduce, modify, display, perform,
      sublicense and distribute Licensed Product or
      portions thereof (including Modifications as
      hereinafter defined), in both Source Code or as
      an executable program.  "Source Code" means
      the preferred form for making modifications to
      the Licensed Product, including all modules
      contained therein, plus any associated interface
      definition files, scripts used to control
      compilation and installation of an executable
      program, or a list of differential comparisons
      against the Source Code of the Licensed
      Product.  

   b.       Create Derivative Works (as that term is
      defined under U.S. copyright law) of Licensed
      Product by adding to or deleting from the
      substance or structure of said Licensed
      Product.

   c.       Under claims of patents now or hereafter owned
      or controlled by Licensor, to make, use, sell,
      offer for sale, have made, and/or otherwise
      dispose of Licensed Product or portions thereof,
      but solely to the extent that any such claim is
      necessary to enable you to make, use, sell,
      offer for sale, have made, and/or otherwise
      dispose of Licensed Product or portions thereof
      or Derivative Works thereof.  

2.      Grant of License to Modifications From
Contributor.  "Modifications" means any additions to or
deletions from the substance or structure of (i) a file
containing Licensed Product, or (ii) any new file that
contains any part of Licensed Product.  Hereinafter in
this License, the term "Licensed Product" shall
include all previous Modifications that you
receive from any Contributor.  By application of the
provisions in Section 4(a) below, each person or entity
who created or contributed to the creation of, and
distributed, a Modification (a "Contributor") hereby
grants you a world-wide, royalty-free, non-exclusive
license, subject to third party intellectual property
claims, to do the following:

   a.       Use, reproduce, modify, display, perform,
      sublicense and distribute any Modifications
      created by such Contributor or portions thereof,
      in both Source Code or as an executable
      program, either on an unmodified basis or as
      part of Derivative Works.

   b.       Under claims of patents now or hereafter owned
      or controlled by Contributor, to make, use, sell,
      offer for sale, have made, and/or otherwise
      dispose of Modifications or portions thereof, but
      solely to the extent that any such claim is
      necessary to enable you to make, use, sell,
      offer for sale, have made, and/or otherwise
      dispose of Modifications or portions thereof or
      Derivative Works thereof. 

3.      Exclusions From License Grant.  Nothing in this
License shall be deemed to grant any rights to
trademarks, copyrights, patents, trade secrets or any
other intellectual property of Licensor or any
Contributor except as expressly stated herein.  No
patent license is granted separate from the Licensed
Product, for code that you delete from the Licensed
Product, or for combinations of the Licensed Product
with other software or hardware.  No right is granted to
the trademarks of Licensor or any Contributor even if
such marks are included in the Licensed Product. 
Nothing in this License shall be interpreted to prohibit
Licensor from licensing under different terms from this
License any code that Licensor otherwise would have a
right to license.

4.      Your Obligations Regarding Distribution.  

   a.       Application of This License to Your
      Modifications.  As an express condition for
      your use of the Licensed Product, you hereby
      agree that any Modifications that you create or
      to which you contribute, and which you
      distribute, are governed by the terms of this
      License including, without limitation, Section 2. 
      Any Modifications that you create or to which
      you contribute may be distributed only under
      the terms of this License or a future version of
      this License released under Section 7.  You
      must include a copy of this License with every
      copy of the Modifications you distribute.  You
      agree not to offer or impose any terms on any
      Source Code or executable version of the
      Licensed Product or Modifications that alter or
      restrict the applicable version of this License or
      the recipients' rights hereunder.  However, you
      may include an additional document offering the
      additional rights described in Section 4(e).

   b.       Availability of Source Code.  You must make
      available, under the terms of this License, the
      Source Code of the Licensed Product and any
      Modifications that you distribute, either on the
      same media as you distribute any executable or
      other form of the Licensed Product, or via a
      mechanism generally accepted in the software
      development community for the electronic
      transfer of data (an "Electronic Distribution
      Mechanism").  The Source Code for any version
      of Licensed Product or Modifications that you
      distribute must remain available for at least
      twelve (12) months after the date it initially
      became available, or at least six (6) months
      after a subsequent version of said Licensed
      Product or Modifications has been made
      available.  You are responsible for ensuring that
      the Source Code version remains available
      even if the Electronic Distribution Mechanism is
      maintained by a third party.

   c.       Description of Modifications.  You must
      cause any Modifications that you create or to
      which you contribute, and which you distribute,
      to contain a file documenting the additions,
      changes or deletions you made to create or
      contribute to those Modifications, and the dates
      of any such additions, changes or deletions. 
      You must include a prominent statement that
      the Modifications are derived, directly or
      indirectly, from the Licensed Product and
      include the names of the Licensor and any
      Contributor to the Licensed Product in (i) the
      Source Code and (ii) in any notice displayed by
      a version of the Licensed Product you distribute
      or in related documentation in which you
      describe the origin or ownership of the Licensed
      Product.  You may not modify or delete any
      preexisting copyright notices in the Licensed
      Product.

   d.       Intellectual Property Matters.  

                                 i.            Third Party Claims.  If you have
            knowledge that a license to a third
            party's intellectual property right is
            required to exercise the rights granted
            by this License, you must include a text
            file with the Source Code distribution
            titled "LEGAL" that describes the claim
            and the party making the claim in
            sufficient detail that a recipient will know
            whom to contact.  If you obtain such
            knowledge after you make any
            Modifications available as described in
            Section 4(b), you shall promptly modify
            the LEGAL file in all copies you make
            available thereafter and shall take other
            steps (such as notifying appropriate
            mailing lists or newsgroups) reasonably
            calculated to inform those who received
            the Licensed Product from you that new
            knowledge has been obtained.

                               ii.            Contributor APIs.  If your Modifications
            include an application programming
            interface ("API") and you have
            knowledge of patent licenses that are
            reasonably necessary to implement that
            API, you must also include this
            information in the LEGAL file.

                              iii.            Representations.  You represent that,
            except as disclosed pursuant to 4(d)(i)
            above, you believe that any
            Modifications you distribute are your
            original creations and that you have
            sufficient rights to grant the rights
            conveyed by this License.  

   e.       Required Notices.  You must duplicate this
      License in any documentation you provide
      along with the Source Code of any Modifications
      you create or to which you contribute, and which
      you distribute, wherever you describe recipients'
      rights relating to Licensed Product.  You must
      duplicate the notice contained in Exhibit A (the
      "Notice") in each file of the Source Code of any
      copy you distribute of the Licensed Product.  If
      you created a Modification, you may add your
      name as a Contributor to the Notice.  If it is not
      possible to put the Notice in a particular Source
      Code file due to its structure, then you must
      include such Notice in a location (such as a
      relevant directory file) where a user would be
      likely to look for such a notice.  You may choose
      to offer, and charge a fee for, warranty, support,
      indemnity or liability obligations to one or more
      recipients of Licensed Product.  However, you
      may do so only on your own behalf, and not on
      behalf of the Licensor or any Contributor.  You
      must make it clear that any such warranty,
      support, indemnity or liability obligation is
      offered by you alone, and you hereby agree to
      indemnify the Licensor and every Contributor
      for any liability incurred by the Licensor or such
      Contributor as a result of warranty, support,
      indemnity or liability terms you offer.

   f.        Distribution of Executable Versions.  You
      may distribute Licensed Product as an
      executable program under a license of your
      choice that may contain terms different from this
      License provided (i) you have satisfied the
      requirements of Sections 4(a) through 4(e) for
      that distribution, (ii) you include a conspicuous
      notice in the executable version, related
      documentation and collateral materials stating
      that the Source Code version of the Licensed
      Product is available under the terms of this
      License, including a description of how and
      where you have fulfilled the obligations of
      Section 4(b), (iii) you retain all existing copyright
      notices in the Licensed Product, and (iv) you
      make it clear that any terms that differ from this
      License are offered by you alone, not by
      Licensor or any Contributor.  You hereby agree
      to indemnify the Licensor and every Contributor
      for any liability incurred by Licensor or such
      Contributor as a result of any terms you offer.  

   g.       Distribution of Derivative Works.  You may
      create Derivative Works (e.g., combinations of
      some or all of the Licensed Product with other
      code) and distribute the Derivative Works as
      products under any other license you select,
      with the proviso that the requirements of this
      License are fulfilled for those portions of the
      Derivative Works that consist of the Licensed
      Product or any Modifications thereto.  

5.      Inability to Comply Due to Statute or
Regulation.  If it is impossible for you to comply with
any of the terms of this License with respect to some or
all of the Licensed Product due to statute, judicial order,
or regulation, then you must (i) comply with the terms of
this License to the maximum extent possible, (ii) cite the
statute or regulation that prohibits you from adhering to
the License, and (iii) describe the limitations and the
code they affect.  Such description must be included in
the LEGAL file described in Section 4(d), and must be
included with all distributions of the Source Code. 
Except to the extent prohibited by statute or regulation,
such description must be sufficiently detailed for a
recipient of ordinary skill at computer programming to
be able to understand it.  

6.      Application of This License.  This License
applies to code to which Licensor or Contributor has
attached the Notice in Exhibit A, which is incorporated
herein by this reference.

7.      Versions of This License.

   a.       New Versions.  Licensor may publish from
      time to time revised and/or new versions of the
      License.  

   b.       Effect of New Versions.  Once Licensed
      Product has been published under a particular
      version of the License, you may always continue
      to use it under the terms of that version.  You
      may also choose to use such Licensed Product
      under the terms of any subsequent version of
      the License published by Licensor.  No one
      other than Licensor has the right to modify the
      terms applicable to Licensed Product created
      under this License.

   c.       Derivative Works of this License.  If you
      create or use a modified version of this License,
      which you may do only in order to apply it to
      software that is not already a Licensed Product
      under this License, you must rename your
      license so that it is not confusingly similar to this
      License, and must make it clear that your
      license contains terms that differ from this
      License.  In so naming your license, you may
      not use any trademark of Licensor or any
      Contributor.

8.      Disclaimer of Warranty.  LICENSED PRODUCT IS
PROVIDED UNDER THIS LICENSE ON AN “AS IS”
BASIS, WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESS OR IMPLIED, INCLUDING, WITHOUT
LIMITATION, WARRANTIES THAT THE LICENSED
PRODUCT IS FREE OF DEFECTS, MERCHANTABLE,
FIT FOR A PARTICULAR PURPOSE OR
NON-INFRINGING.  THE ENTIRE RISK AS TO THE
QUALITY AND PERFORMANCE OF THE LICENSED
PRODUCT IS WITH YOU.  SHOULD LICENSED
PRODUCT PROVE DEFECTIVE IN ANY RESPECT,
YOU (AND NOT THE LICENSOR OR ANY OTHER
CONTRIBUTOR) ASSUME THE COST OF ANY
NECESSARY SERVICING, REPAIR OR CORRECTION. 
THIS DISCLAIMER OF WARRANTY CONSTITUTES AN
ESSENTIAL PART OF THIS LICENSE.  NO USE OF
LICENSED PRODUCT IS AUTHORIZED HEREUNDER
EXCEPT UNDER THIS DISCLAIMER.

9.      Termination.  

   a.       Automatic Termination Upon Breach.  This
      license and the rights granted hereunder will
      terminate automatically if you fail to comply with
      the terms herein and fail to cure such breach
      within thirty (30) days of becoming aware of the
      breach.  All sublicenses to the Licensed Product
      that are properly granted shall survive any
      termination of this license.  Provisions that, by
      their nature, must remain in effect beyond the
      termination of this License, shall survive. 

   b.       Termination Upon Assertion of Patent
      Infringement.  If you initiate litigation by
      asserting a patent infringement claim (excluding
      declaratory judgment actions) against Licensor
      or a Contributor (Licensor or Contributor
      against whom you file such an action is referred
      to herein as “Respondent”) alleging that
      Licensed Product directly or indirectly infringes
      any patent, then any and all rights granted by
      such Respondent to you under Sections 1 or 2
      of this License shall terminate prospectively
      upon sixty (60) days notice from Respondent
      (the "Notice Period") unless within that Notice
      Period you either agree in writing (i) to pay
      Respondent a mutually agreeable reasonably
      royalty for your past or future use of Licensed
      Product made by such Respondent, or (ii)
      withdraw your litigation claim with respect to
      Licensed Product against such Respondent.  If
      within said Notice Period a reasonable royalty
      and payment arrangement are not mutually
      agreed upon in writing by the parties or the
      litigation claim is not withdrawn, the rights
      granted by Licensor to you under Sections 1
      and 2 automatically terminate at the expiration
      of said Notice Period. 

   c.       Reasonable Value of This License.  If you
      assert a patent infringement claim against
      Respondent alleging that Licensed Product
      directly or indirectly infringes any patent where
      such claim is resolved (such as by license or
      settlement) prior to the initiation of patent
      infringement litigation, then the reasonable
      value of the licenses granted by said
      Respondent under Sections 1 and 2 shall be
      taken into account in determining the amount or
      value of any payment or license.

   d.       No Retroactive Effect of Termination.  In the
      event of termination under Sections 9(a) or 9(b)
      above, all end user license agreements
      (excluding licenses to distributors and resellers)
      that have been validly granted by you or any
      distributor hereunder prior to termination shall
      survive termination.

10.  Limitation of Liability.  UNDER NO
CIRCUMSTANCES AND UNDER NO LEGAL THEORY,
WHETHER TORT (INCLUDING NEGLIGENCE),
CONTRACT, OR OTHERWISE, SHALL THE LICENSOR,
ANY CONTRIBUTOR, OR ANY DISTRIBUTOR OF
LICENSED PRODUCT, OR ANY SUPPLIER OF ANY OF
SUCH PARTIES, BE LIABLE TO ANY PERSON FOR
ANY INDIRECT, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES OF ANY CHARACTER
INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
LOSS OF GOODWILL, WORK STOPPAGE,
COMPUTER FAILURE OR MALFUNCTION, OR ANY
AND ALL OTHER COMMERCIAL DAMAGES OR
LOSSES, EVEN IF SUCH PARTY SHALL HAVE BEEN
INFORMED OF THE POSSIBILITY OF SUCH
DAMAGES.  THIS LIMITATION OF LIABILITY SHALL
NOT APPLY TO LIABILITY FOR DEATH OR
PERSONAL INJURY RESULTING FROM SUCH
PARTY’S NEGLIGENCE TO THE EXTENT APPLICABLE
LAW PROHIBITS SUCH LIMITATION.  SOME
JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR
LIMITATION OF INCIDENTAL OR CONSEQUENTIAL
DAMAGES, SO THIS EXCLUSION AND LIMITATION
MAY NOT APPLY TO YOU.  

11.  Responsibility for Claims.  As between Licensor
and Contributors, each party is responsible for claims
and damages arising, directly or indirectly, out of its
utilization of rights under this License.  You agree to
work with Licensor and Contributors to distribute such
responsibility on an equitable basis.  Nothing herein is
intended or shall be deemed to constitute any
admission of liability.

12.  U.S. Government End Users.  The Licensed
Product is a “commercial item,” as that term is defined
in 48 C.F.R. 2.101 (Oct. 1995), consisting of
“commercial computer software” and “commercial
computer software documentation,” as such terms are
used in 48 C.F.R. 12.212 (Sept. 1995).  Consistent with
48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through
227.7202-4 (June 1995), all U.S. Government End
Users acquire Licensed Product with only those rights
set forth herein.

13.  Miscellaneous.  This License represents the
complete agreement concerning the subject matter
hereof.  If any provision of this License is held to be
unenforceable, such provision shall be reformed only to
the extent necessary to make it enforceable.  This
License shall be governed by California law provisions
(except to the extent applicable law, if any, provides
otherwise), excluding its conflict-of-law provisions.  You
expressly agree that any litigation relating to this license
shall be subject to the jurisdiction of the Federal Courts
of the Northern District of California or the Superior
Court of the County of Santa Clara, California (as
appropriate), with venue lying in Santa Clara County,
California, with the losing party responsible for costs
including, without limitation, court costs and reasonable
attorneys’ fees and expenses.  The application of the
United Nations Convention on Contracts for the
International Sale of Goods is expressly excluded.  You
and Licensor expressly waive any rights to a jury trial in
any litigation concerning Licensed Product or this
License.  Any law or regulation that provides that the
language of a contract shall be construed against the
drafter shall not apply to this License.

14.  Definition of “You” in This License.  “You”
throughout this License, whether in upper or lower
case, means an individual or a legal entity exercising
rights under, and complying with all of the terms of, this
License or a future version of this License issued under
Section 7.  For legal entities, “you” includes any entity
that controls, is controlled by, or is under common
control with you.  For purposes of this definition,
“control” means (i) the power, direct or indirect, to
cause the direction or management of such entity,
whether by contract or otherwise, or (ii) ownership of
fifty percent (50%) or more of the outstanding shares,
or (iii) beneficial ownership of such entity.

15.  Glossary.  All defined terms in this License that are
used in more than one Section of this License are
repeated here, in alphabetical order, for the
convenience of the reader.  The Section of this License
in which each defined term is first used is shown in
parentheses.  

   Contributor:  Each person or entity who created or
   contributed to the creation of, and distributed, a
   Modification.  (See Section 2)

   Derivative Works: That term as used in this
   License is defined under U.S. copyright law.  (See
   Section 1(b))

   License:  This Jabber Open Source License.  (See
   first paragraph of License)

   Licensed Product:  Any Jabber Product licensed
   pursuant to this License.  The term "Licensed
   Product" includes all previous Modifications from
   any Contributor that you receive.  (See first
   paragraph of License and Section 2)

   Licensor:  Jabber.Com, Inc.  (See first paragraph
   of License)

   Modifications:  Any additions to or deletions from
   the substance or structure of (i) a file containing
   Licensed Product, or (ii) any new file that contains
   any part of Licensed Product.  (See Section 2)

   Notice:  The notice contained in Exhibit A.  (See
   Section 4(e))

   Source Code: The preferred form for making
   modifications to the Licensed Product, including all
   modules contained therein, plus any associated
   interface definition files, scripts used to control
   compilation and installation of an executable
   program, or a list of differential comparisons against
   the Source Code of the Licensed Product.  (See
   Section 1(a))

   You:  This term is defined in Section 14 of this
   License.

                 EXHIBIT A

      The Notice below must appear in each
      file of the Source Code of any copy you
      distribute of the Licensed Product or any
      Modifications thereto.  Contributors to
      any Modifications may add their own
      copyright notices to identify their own
      contributions.

License:

The contents of this file are subject to the Jabber Open
Source License Version 1.0 (the “License”).  You may
not copy or use this file, in either source code or
executable form, except in compliance with the License. 
You may obtain a copy of the License at
http://www.jabber.com/license/ or at
http://www.opensource.org/.

Software distributed under the License is distributed on
an “AS IS” basis, WITHOUT WARRANTY OF ANY KIND,
either express or implied.  See the License for the
specific language governing rights and limitations under
the License.

Copyrights:

Portions created by or assigned to Jabber.com, Inc. are
Copyright (c) 1999-2000 Jabber.com, Inc.  All Rights
Reserved.  Contact information for Jabber.com, Inc. is
available at http://www.jabber.com/. 

Portions Copyright (c) 1998-1999 Jeremie Miller. 

Acknowledgements

Special thanks to the Jabber Open Source Contributors
for their suggestions and support of Jabber.

Modifications:
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_LGPL

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_LGPL_2_1 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The GNU Lesser General Public License (LGPL)
	Version 2.1, February 1999

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The GNU Lesser General Public License (LGPL)
Version 2.1, February 1999

     (The master copy of this license lives
     on the GNU website.)

Copyright (C) 1991, 1999 Free Software Foundation, Inc. 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

[This is the first released version of the Lesser GPL. It also
counts as the successor of the GNU Library Public License,
version 2, hence the version number 2.1.]

Preamble

The licenses for most software are designed to take away
your freedom to share and change it. By contrast, the GNU
General Public Licenses are intended to guarantee your
freedom to share and change free software--to make sure the
software is free for all its users.

This license, the Lesser General Public License, applies to
some specially designated software packages--typically
libraries--of the Free Software Foundation and other authors
who decide to use it. You can use it too, but we suggest you
first think carefully about whether this license or the ordinary
General Public License is the better strategy to use in any
particular case, based on the explanations below.

When we speak of free software, we are referring to freedom
of use, not price. Our General Public Licenses are designed
to make sure that you have the freedom to distribute copies
of free software (and charge for this service if you wish); that
you receive source code or can get it if you want it; that you
can change the software and use pieces of it in new free
programs; and that you are informed that you can do these
things.

To protect your rights, we need to make restrictions that
forbid distributors to deny you these rights or to ask you to
surrender these rights. These restrictions translate to certain
responsibilities for you if you distribute copies of the library
or if you modify it.

For example, if you distribute copies of the library, whether
gratis or for a fee, you must give the recipients all the rights
that we gave you. You must make sure that they, too,
receive or can get the source code. If you link other code
with the library, you must provide complete object files to the
recipients, so that they can relink them with the library after
making changes to the library and recompiling it. And you
must show them these terms so they know their rights.

We protect your rights with a two-step method: (1) we
copyright the library, and (2) we offer you this license, which
gives you legal permission to copy, distribute and/or modify
the library.

To protect each distributor, we want to make it very clear
that there is no warranty for the free library. Also, if the
library is modified by someone else and passed on, the
recipients should know that what they have is not the original
version, so that the original author's reputation will not be
affected by problems that might be introduced by others.

Finally, software patents pose a constant threat to the
existence of any free program. We wish to make sure that a
company cannot effectively restrict the users of a free
program by obtaining a restrictive license from a patent
holder. Therefore, we insist that any patent license obtained
for a version of the library must be consistent with the full
freedom of use specified in this license.

Most GNU software, including some libraries, is covered by
the ordinary GNU General Public License. This license, the
GNU Lesser General Public License, applies to certain
designated libraries, and is quite different from the ordinary
General Public License. We use this license for certain
libraries in order to permit linking those libraries into non-free
programs.

When a program is linked with a library, whether statically or
using a shared library, the combination of the two is legally
speaking a combined work, a derivative of the original library.
The ordinary General Public License therefore permits such
linking only if the entire combination fits its criteria of
freedom. The Lesser General Public License permits more
lax criteria for linking other code with the library.

We call this license the "Lesser" General Public License
because it does Less to protect the user's freedom than the
ordinary General Public License. It also provides other free
software developers Less of an advantage over competing
non-free programs. These disadvantages are the reason we
use the ordinary General Public License for many libraries.
However, the Lesser license provides advantages in certain
special circumstances.

For example, on rare occasions, there may be a special
need to encourage the widest possible use of a certain
library, so that it becomes a de-facto standard. To achieve
this, non-free programs must be allowed to use the library. A
more frequent case is that a free library does the same job
as widely used non-free libraries. In this case, there is little
to gain by limiting the free library to free software only, so we
use the Lesser General Public License.

In other cases, permission to use a particular library in
non-free programs enables a greater number of people to use
a large body of free software. For example, permission to
use the GNU C Library in non-free programs enables many
more people to use the whole GNU operating system, as
well as its variant, the GNU/Linux operating system.

Although the Lesser General Public License is Less
protective of the users' freedom, it does ensure that the user
of a program that is linked with the Library has the freedom
and the wherewithal to run that program using a modified
version of the Library.

The precise terms and conditions for copying, distribution
and modification follow. Pay close attention to the difference
between a "work based on the library" and a "work that uses
the library". The former contains code derived from the
library, whereas the latter must be combined with the library
in order to run.

TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION
AND MODIFICATION

0. This License Agreement applies to any software library or
other program which contains a notice placed by the
copyright holder or other authorized party saying it may be
distributed under the terms of this Lesser General Public
License (also called "this License"). Each licensee is
addressed as "you".

A "library" means a collection of software functions and/or
data prepared so as to be conveniently linked with
application programs (which use some of those functions
and data) to form executables.

The "Library", below, refers to any such software library or
work which has been distributed under these terms. A "work
based on the Library" means either the Library or any
derivative work under copyright law: that is to say, a work
containing the Library or a portion of it, either verbatim or with
modifications and/or translated straightforwardly into another
language. (Hereinafter, translation is included without
limitation in the term "modification".)

"Source code" for a work means the preferred form of the
work for making modifications to it. For a library, complete
source code means all the source code for all modules it
contains, plus any associated interface definition files, plus
the scripts used to control compilation and installation of the
library.

Activities other than copying, distribution and modification
are not covered by this License; they are outside its scope.
The act of running a program using the Library is not
restricted, and output from such a program is covered only if
its contents constitute a work based on the Library
(independent of the use of the Library in a tool for writing it).
Whether that is true depends on what the Library does and
what the program that uses the Library does.

1. You may copy and distribute verbatim copies of the
Library's complete source code as you receive it, in any
medium, provided that you conspicuously and appropriately
publish on each copy an appropriate copyright notice and
disclaimer of warranty; keep intact all the notices that refer
to this License and to the absence of any warranty; and
distribute a copy of this License along with the Library.

You may charge a fee for the physical act of transferring a
copy, and you may at your option offer warranty protection in
exchange for a fee.

2. You may modify your copy or copies of the Library or any
portion of it, thus forming a work based on the Library, and
copy and distribute such modifications or work under the
terms of Section 1 above, provided that you also meet all of
these conditions:

     a) The modified work must itself be a software
     library.
     b) You must cause the files modified to carry
     prominent notices stating that you changed the
     files and the date of any change.
     c) You must cause the whole of the work to be
     licensed at no charge to all third parties under
     the terms of this License.
     d) If a facility in the modified Library refers to a
     function or a table of data to be supplied by an
     application program that uses the facility, other
     than as an argument passed when the facility
     is invoked, then you must make a good faith
     effort to ensure that, in the event an application
     does not supply such function or table, the
     facility still operates, and performs whatever
     part of its purpose remains meaningful.

     (For example, a function in a library to
     compute square roots has a purpose that is
     entirely well-defined independent of the
     application. Therefore, Subsection 2d requires
     that any application-supplied function or table
     used by this function must be optional: if the
     application does not supply it, the square root
     function must still compute square roots.)

     These requirements apply to the modified work
     as a whole. If identifiable sections of that work
     are not derived from the Library, and can be
     reasonably considered independent and
     separate works in themselves, then this
     License, and its terms, do not apply to those
     sections when you distribute them as separate
     works. But when you distribute the same
     sections as part of a whole which is a work
     based on the Library, the distribution of the
     whole must be on the terms of this License,
     whose permissions for other licensees extend
     to the entire whole, and thus to each and every
     part regardless of who wrote it.

     Thus, it is not the intent of this section to claim
     rights or contest your rights to work written
     entirely by you; rather, the intent is to exercise
     the right to control the distribution of derivative
     or collective works based on the Library.

     In addition, mere aggregation of another work
     not based on the Library with the Library (or
     with a work based on the Library) on a volume
     of a storage or distribution medium does not
     bring the other work under the scope of this
     License.

3. You may opt to apply the terms of the ordinary GNU
General Public License instead of this License to a given
copy of the Library. To do this, you must alter all the notices
that refer to this License, so that they refer to the ordinary
GNU General Public License, version 2, instead of to this
License. (If a newer version than version 2 of the ordinary
GNU General Public License has appeared, then you can
specify that version instead if you wish.) Do not make any
other change in these notices.

Once this change is made in a given copy, it is irreversible
for that copy, so the ordinary GNU General Public License
applies to all subsequent copies and derivative works made
from that copy.

This option is useful when you wish to copy part of the code
of the Library into a program that is not a library.

4. You may copy and distribute the Library (or a portion or
derivative of it, under Section 2) in object code or executable
form under the terms of Sections 1 and 2 above provided that
you accompany it with the complete corresponding
machine-readable source code, which must be distributed
under the terms of Sections 1 and 2 above on a medium
customarily used for software interchange.

If distribution of object code is made by offering access to
copy from a designated place, then offering equivalent
access to copy the source code from the same place
satisfies the requirement to distribute the source code, even
though third parties are not compelled to copy the source
along with the object code.

5. A program that contains no derivative of any portion of the
Library, but is designed to work with the Library by being
compiled or linked with it, is called a "work that uses the
Library". Such a work, in isolation, is not a derivative work of
the Library, and therefore falls outside the scope of this
License.

However, linking a "work that uses the Library" with the
Library creates an executable that is a derivative of the
Library (because it contains portions of the Library), rather
than a "work that uses the library". The executable is
therefore covered by this License. Section 6 states terms for
distribution of such executables.

When a "work that uses the Library" uses material from a
header file that is part of the Library, the object code for the
work may be a derivative work of the Library even though the
source code is not. Whether this is true is especially
significant if the work can be linked without the Library, or if
the work is itself a library. The threshold for this to be true is
not precisely defined by law.

If such an object file uses only numerical parameters, data
structure layouts and accessors, and small macros and
small inline functions (ten lines or less in length), then the
use of the object file is unrestricted, regardless of whether it
is legally a derivative work. (Executables containing this
object code plus portions of the Library will still fall under
Section 6.)

Otherwise, if the work is a derivative of the Library, you may
distribute the object code for the work under the terms of
Section 6. Any executables containing that work also fall
under Section 6, whether or not they are linked directly with
the Library itself.

6. As an exception to the Sections above, you may also
combine or link a "work that uses the Library" with the
Library to produce a work containing portions of the Library,
and distribute that work under terms of your choice, provided
that the terms permit modification of the work for the
customer's own use and reverse engineering for debugging
such modifications.

You must give prominent notice with each copy of the work
that the Library is used in it and that the Library and its use
are covered by this License. You must supply a copy of this
License. If the work during execution displays copyright
notices, you must include the copyright notice for the Library
among them, as well as a reference directing the user to the
copy of this License. Also, you must do one of these things:

     a) Accompany the work with the complete
     corresponding machine-readable source code
     for the Library including whatever changes were
     used in the work (which must be distributed
     under Sections 1 and 2 above); and, if the work
     is an executable linked with the Library, with
     the complete machine-readable "work that
     uses the Library", as object code and/or
     source code, so that the user can modify the
     Library and then relink to produce a modified
     executable containing the modified Library. (It
     is understood that the user who changes the
     contents of definitions files in the Library will
     not necessarily be able to recompile the
     application to use the modified definitions.)

     b) Use a suitable shared library mechanism for
     linking with the Library. A suitable mechanism
     is one that (1) uses at run time a copy of the
     library already present on the user's computer
     system, rather than copying library functions
     into the executable, and (2) will operate
     properly with a modified version of the library, if
     the user installs one, as long as the modified
     version is interface-compatible with the version
     that the work was made with.

     c) Accompany the work with a written offer,
     valid for at least three years, to give the same
     user the materials specified in Subsection 6a,
     above, for a charge no more than the cost of
     performing this distribution.

     d) If distribution of the work is made by offering
     access to copy from a designated place, offer
     equivalent access to copy the above specified
     materials from the same place.

     e) Verify that the user has already received a
     copy of these materials or that you have
     already sent this user a copy.

For an executable, the required form of the "work that uses
the Library" must include any data and utility programs
needed for reproducing the executable from it. However, as a
special exception, the materials to be distributed need not
include anything that is normally distributed (in either source
or binary form) with the major components (compiler, kernel,
and so on) of the operating system on which the executable
runs, unless that component itself accompanies the
executable.

It may happen that this requirement contradicts the license
restrictions of other proprietary libraries that do not normally
accompany the operating system. Such a contradiction
means you cannot use both them and the Library together in
an executable that you distribute.

7. You may place library facilities that are a work based on
the Library side-by-side in a single library together with other
library facilities not covered by this License, and distribute
such a combined library, provided that the separate
distribution of the work based on the Library and of the other
library facilities is otherwise permitted, and provided that you
do these two things:

     a) Accompany the combined library with a
     copy of the same work based on the Library,
     uncombined with any other library facilities.
     This must be distributed under the terms of the
     Sections above.

     b) Give prominent notice with the combined
     library of the fact that part of it is a work based
     on the Library, and explaining where to find the
     accompanying uncombined form of the same
     work.

8. You may not copy, modify, sublicense, link with, or
distribute the Library except as expressly provided under this
License. Any attempt otherwise to copy, modify, sublicense,
link with, or distribute the Library is void, and will
automatically terminate your rights under this License.
However, parties who have received copies, or rights, from
you under this License will not have their licenses terminated
so long as such parties remain in full compliance.

9. You are not required to accept this License, since you
have not signed it. However, nothing else grants you
permission to modify or distribute the Library or its derivative
works. These actions are prohibited by law if you do not
accept this License. Therefore, by modifying or distributing
the Library (or any work based on the Library), you indicate
your acceptance of this License to do so, and all its terms
and conditions for copying, distributing or modifying the
Library or works based on it.

10. Each time you redistribute the Library (or any work
based on the Library), the recipient automatically receives a
license from the original licensor to copy, distribute, link with
or modify the Library subject to these terms and conditions.
You may not impose any further restrictions on the
recipients' exercise of the rights granted herein. You are not
responsible for enforcing compliance by third parties with this
License.

11. If, as a consequence of a court judgment or allegation of
patent infringement or for any other reason (not limited to
patent issues), conditions are imposed on you (whether by
court order, agreement or otherwise) that contradict the
conditions of this License, they do not excuse you from the
conditions of this License. If you cannot distribute so as to
satisfy simultaneously your obligations under this License
and any other pertinent obligations, then as a consequence
you may not distribute the Library at all. For example, if a
patent license would not permit royalty-free redistribution of
the Library by all those who receive copies directly or
indirectly through you, then the only way you could satisfy
both it and this License would be to refrain entirely from
distribution of the Library.

If any portion of this section is held invalid or unenforceable
under any particular circumstance, the balance of the
section is intended to apply, and the section as a whole is
intended to apply in other circumstances.

It is not the purpose of this section to induce you to infringe
any patents or other property right claims or to contest
validity of any such claims; this section has the sole purpose
of protecting the integrity of the free software distribution
system which is implemented by public license practices.
Many people have made generous contributions to the wide
range of software distributed through that system in reliance
on consistent application of that system; it is up to the
author/donor to decide if he or she is willing to distribute
software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is
believed to be a consequence of the rest of this License.

12. If the distribution and/or use of the Library is restricted in
certain countries either by patents or by copyrighted
interfaces, the original copyright holder who places the
Library under this License may add an explicit geographical
distribution limitation excluding those countries, so that
distribution is permitted only in or among countries not thus
excluded. In such case, this License incorporates the
limitation as if written in the body of this License.

13. The Free Software Foundation may publish revised
and/or new versions of the Lesser General Public License
from time to time. Such new versions will be similar in spirit
to the present version, but may differ in detail to address new
problems or concerns.

Each version is given a distinguishing version number. If the
Library specifies a version number of this License which
applies to it and "any later version", you have the option of
following the terms and conditions either of that version or of
any later version published by the Free Software Foundation.
If the Library does not specify a license version number, you
may choose any version ever published by the Free Software
Foundation.

14. If you wish to incorporate parts of the Library into other
free programs whose distribution conditions are incompatible
with these, write to the author to ask for permission. For
software which is copyrighted by the Free Software
Foundation, write to the Free Software Foundation; we
sometimes make exceptions for this. Our decision will be
guided by the two goals of preserving the free status of all
derivatives of our free software and of promoting the sharing
and reuse of software generally.

NO WARRANTY

15. BECAUSE THE LIBRARY IS LICENSED FREE OF
CHARGE, THERE IS NO WARRANTY FOR THE LIBRARY,
TO THE EXTENT PERMITTED BY APPLICABLE LAW.
EXCEPT WHEN OTHERWISE STATED IN WRITING THE
COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE LIBRARY "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE
QUALITY AND PERFORMANCE OF THE LIBRARY IS WITH
YOU. SHOULD THE LIBRARY PROVE DEFECTIVE, YOU
ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

16. IN NO EVENT UNLESS REQUIRED BY APPLICABLE
LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT
HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
AND/OR REDISTRIBUTE THE LIBRARY AS PERMITTED
ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING
ANY GENERAL, SPECIAL, INCIDENTAL OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE
OR INABILITY TO USE THE LIBRARY (INCLUDING BUT
NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE
LIBRARY TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN
ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_MIT

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_MIT {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The MIT License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The MIT License

Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_MITRE

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_MITRE {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	MITRE Collaborative Virtual Workspace License (CVW License)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
MITRE Collaborative Virtual Workspace License (CVW License)

   Collaborative Virtual Workspace License (CVW)
                  License Agreement

General

  1.Redistribution of the CVW software or derived works must
     reproduce MITRE's copyright designation and this License
     in the documentation and/or other materials provided with
     the distribution. 

          Copyright © 1994-1999. The MITRE Corporation
          (http://www.mitre.org/). All Rights Reserved.

  2.The terms "MITRE" and "The MITRE Corporation" are
     trademarks of The MITRE Corporation and must not be used
     to endorse or promote products derived from this software
     or in redistribution of this software in any form. 
  3.The terms "CVW" and "Collaborative Virtual Workspace"
     are trademarks of The MITRE Corporation and must not be
     used to endorse or promote products derived from this
     software without the prior written permission of MITRE. For
     written permission, please contact corpc\@mitre.org. 
  4.UNITED STATES GOVERNMENT RIGHTS: This software
     was produced for the U.S. Government under Contract No.
     F19628-99-C-0001, and is subject to the Rights in
     Noncommercial Computer Software and Noncommercial
     Computer Software Documentation Clause (DFARS)
     252.227-7014 (JUN 1995). The Licensee agrees that the
     US Government will not be charged any license fee and/or
     royalties related to this software. 
  5.Downloaders of the CVW software may choose to have their
     access to and use of the CVW software governed under
     either the GNU General Public License (Version 2) or the
     Mozilla License (Version 1.0). In either case, if you transmit
     source code improvements or modifications to MITRE, you
     agree to assign to MITRE copyright to such improvements or
     modifications, which MITRE will then make available from
     MITRE's web site. 
  6.If you choose to use the Mozilla License (Version 1.0),
     please note that because the software in this module was
     developed using, at least in part, Government funds, the
     Government has certain rights in the module which apply
     instead of the Government rights in Section 10 of the Mozilla
     License. These Government rights DO NOT affect your right
     to use the module on an Open Source basis as set forth in
     the Mozilla License. The statement of Government rights
     which replaces Section 10 of the Mozilla License is stated in
     Section 4 above. 

Licenses

     GNU General Public License

     Mozilla Public License



          GNU GENERAL PUBLIC LICENSE

                   Version 2, June 1991 



Copyright (C) 1989, 1991 Free Software Foundation, Inc.  

59 Temple Place - Suite 330, Boston, MA  02111-1307, USA



Everyone is permitted to copy and distribute verbatim copies

of this license document, but changing it is not allowed.

Preamble

The licenses for most software are designed to take away your
freedom to share and change it. By contrast, the GNU General
Public License is intended to guarantee your freedom to share
and change free software--to make sure the software is free for all
its users. This General Public License applies to most of the Free
Software Foundation's software and to any other program whose
authors commit to using it. (Some other Free Software Foundation
software is covered by the GNU Library General Public License
instead.) You can apply it to your programs, too. 

When we speak of free software, we are referring to freedom, not
price. Our General Public Licenses are designed to make sure
that you have the freedom to distribute copies of free software
(and charge for this service if you wish), that you receive source
code or can get it if you want it, that you can change the software
or use pieces of it in new free programs; and that you know you
can do these things. 

To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the
rights. These restrictions translate to certain responsibilities for
you if you distribute copies of the software, or if you modify it. 

For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have. You must make sure that they, too, receive or can get
the source code. And you must show them these terms so they
know their rights. 

We protect your rights with two steps: (1) copyright the software,
and (2) offer you this license which gives you legal permission to
copy, distribute and/or modify the software. 

Also, for each author's protection and ours, we want to make
certain that everyone understands that there is no warranty for this
free software. If the software is modified by someone else and
passed on, we want its recipients to know that what they have is
not the original, so that any problems introduced by others will not
reflect on the original authors' reputations. 

Finally, any free program is threatened constantly by software
patents. We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making
the program proprietary. To prevent this, we have made it clear
that any patent must be licensed for everyone's free use or not
licensed at all. 

The precise terms and conditions for copying, distribution and
modification follow. 

TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION
AND MODIFICATION

0. This License applies to any program or other work which
contains a notice placed by the copyright holder saying it may be
distributed under the terms of this General Public License. The
"Program", below, refers to any such program or work, and a
"work based on the Program" means either the Program or any
derivative work under copyright law: that is to say, a work
containing the Program or a portion of it, either verbatim or with
modifications and/or translated into another language.
(Hereinafter, translation is included without limitation in the term
"modification".) Each licensee is addressed as "you". 

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope. The act of
running the Program is not restricted, and the output from the
Program is covered only if its contents constitute a work based on
the Program (independent of having been made by running the
Program). Whether that is true depends on what the Program
does. 

1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an
appropriate copyright notice and disclaimer of warranty; keep
intact all the notices that refer to this License and to the absence
of any warranty; and give any other recipients of the Program a
copy of this License along with the Program. 

You may charge a fee for the physical act of transferring a copy,
and you may at your option offer warranty protection in exchange
for a fee. 

2. You may modify your copy or copies of the Program or any
portion of it, thus forming a work based on the Program, and copy
and distribute such modifications or work under the terms of
Section 1 above, provided that you also meet all of these
conditions: 

     a) You must cause the modified files to carry prominent
     notices stating that you changed the files and the date of any
     change. 
     b) You must cause any work that you distribute or publish,
     that in whole or in part contains or is derived from the
     Program or any part thereof, to be licensed as a whole at no
     charge to all third parties under the terms of this License. 
     c) If the modified program normally reads commands
     interactively when run, you must cause it, when started
     running for such interactive use in the most ordinary way, to
     print or display an announcement including an appropriate
     copyright notice and a notice that there is no warranty (or
     else, saying that you provide a warranty) and that users may
     redistribute the program under these conditions, and telling
     the user how to view a copy of this License. (Exception: if the
     Program itself is interactive but does not normally print such
     an announcement, your work based on the Program is not
     required to print an announcement.) 

These requirements apply to the modified work as a whole. If
identifiable sections of that work are not derived from the
Program, and can be reasonably considered independent and
separate works in themselves, then this License, and its terms, do
not apply to those sections when you distribute them as separate
works. But when you distribute the same sections as part of a
whole which is a work based on the Program, the distribution of
the whole must be on the terms of this License, whose
permissions for other licensees extend to the entire whole, and
thus to each and every part regardless of who wrote it. 

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program. 

In addition, mere aggregation of another work not based on the
Program with the Program (or with a work based on the Program)
on a volume of a storage or distribution medium does not bring the
other work under the scope of this License. 

3. You may copy and distribute the Program (or a work based on
it, under Section 2) in object code or executable form under the
terms of Sections 1 and 2 above provided that you also do one of
the following: 

     a) Accompany it with the complete corresponding
     machine-readable source code, which must be distributed
     under the terms of Sections 1 and 2 above on a medium
     customarily used for software interchange; or, 
     b) Accompany it with a written offer, valid for at least three
     years, to give any third party, for a charge no more than your
     cost of physically performing source distribution, a complete
     machine-readable copy of the corresponding source code,
     to be distributed under the terms of Sections 1 and 2 above
     on a medium customarily used for software interchange; or, 
     c) Accompany it with the information you received as to the
     offer to distribute corresponding source code. (This
     alternative is allowed only for noncommercial distribution
     and only if you received the program in object code or
     executable form with such an offer, in accord with
     Subsection b above.) 

The source code for a work means the preferred form of the work
for making modifications to it. For an executable work, complete
source code means all the source code for all modules it contains,
plus any associated interface definition files, plus the scripts used
to control compilation and installation of the executable. However,
as a special exception, the source code distributed need not
include anything that is normally distributed (in either source or
binary form) with the major components (compiler, kernel, and so
on) of the operating system on which the executable runs, unless
that component itself accompanies the executable. 

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code. 

4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License. Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this
License. However, parties who have received copies, or rights,
from you under this License will not have their licenses terminated
so long as such parties remain in full compliance. 

5. You are not required to accept this License, since you have not
signed it. However, nothing else grants you permission to modify
or distribute the Program or its derivative works. These actions
are prohibited by law if you do not accept this License. Therefore,
by modifying or distributing the Program (or any work based on
the Program), you indicate your acceptance of this License to do
so, and all its terms and conditions for copying, distributing or
modifying the Program or works based on it. 

6. Each time you redistribute the Program (or any work based on
the Program), the recipient automatically receives a license from
the original licensor to copy, distribute or modify the Program
subject to these terms and conditions. You may not impose any
further restrictions on the recipients' exercise of the rights granted
herein. You are not responsible for enforcing compliance by third
parties to this License. 

7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order,
agreement or otherwise) that contradict the conditions of this
License, they do not excuse you from the conditions of this
License. If you cannot distribute so as to satisfy simultaneously
your obligations under this License and any other pertinent
obligations, then as a consequence you may not distribute the
Program at all. For example, if a patent license would not permit
royalty-free redistribution of the Program by all those who receive
copies directly or indirectly through you, then the only way you
could satisfy both it and this License would be to refrain entirely
from distribution of the Program. 

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended
to apply and the section as a whole is intended to apply in other
circumstances. 

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices. Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee
cannot impose that choice. 

This section is intended to make thoroughly clear what is believed
to be a consequence of the rest of this License. 

8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this
License may add an explicit geographical distribution limitation
excluding those countries, so that distribution is permitted only in
or among countries not thus excluded. In such case, this License
incorporates the limitation as if written in the body of this License. 

9. The Free Software Foundation may publish revised and/or new
versions of the General Public License from time to time. Such
new versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns. 

Each version is given a distinguishing version number. If the
Program specifies a version number of this License which applies
to it and "any later version", you have the option of following the
terms and conditions either of that version or of any later version
published by the Free Software Foundation. If the Program does
not specify a version number of this License, you may choose any
version ever published by the Free Software Foundation. 

10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the
author to ask for permission. For software which is copyrighted by
the Free Software Foundation, write to the Free Software
Foundation; we sometimes make exceptions for this. Our decision
will be guided by the two goals of preserving the free status of all
derivatives of our free software and of promoting the sharing and
reuse of software generally. 

NO WARRANTY

11. BECAUSE THE PROGRAM IS LICENSED FREE OF
CHARGE, THERE IS NO WARRANTY FOR THE PROGRAM, TO
THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE
PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD
THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE
COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION. 

12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW
OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER,
OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL,
SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OR INABILITY TO USE THE
PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA
OR DATA BEING RENDERED INACCURATE OR LOSSES
SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF
THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY
HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES. 

END OF TERMS AND CONDITIONS

How to Apply These Terms to Your New Programs

If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make
it free software which everyone can redistribute and change under
these terms. 

To do so, attach the following notices to the program. It is safest to
attach them to the start of each source file to most effectively
convey the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found. 


one line to give the program's name and an idea of what it does.

Copyright (C) yyyy  name of author



This program is free software; you can redistribute it and/or

modify it under the terms of the GNU General Public License

as published by the Free Software Foundation; either version 2

of the License, or (at your option) any later version.



This program is distributed in the hope that it will be useful,

but WITHOUT ANY WARRANTY; without even the implied warranty of

MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

GNU General Public License for more details.



You should have received a copy of the GNU General Public License

along with this program; if not, write to the Free Software

Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Also add information on how to contact you by electronic and
paper mail. 

If the program is interactive, make it output a short notice like this
when it starts in an interactive mode: 


Gnomovision version 69, Copyright (C) yyyy name of author

Gnomovision comes with ABSOLUTELY NO WARRANTY; for details

type `show w'.  This is free software, and you are welcome

to redistribute it under certain conditions; type `show c' 

for details.

The hypothetical commands `show w' and `show c' should show the
appropriate parts of the General Public License. Of course, the
commands you use may be called something other than `show w'
and `show c'; they could even be mouse-clicks or menu
items--whatever suits your program. 

You should also get your employer (if you work as a programmer)
or your school, if any, to sign a "copyright disclaimer" for the
program, if necessary. Here is a sample; alter the names: 


Yoyodyne, Inc., hereby disclaims all copyright

interest in the program `Gnomovision'

(which makes passes at compilers) written 

by James Hacker.



signature of Ty Coon, 1 April 1989

Ty Coon, President of Vice

This General Public License does not permit incorporating your
program into proprietary programs. If your program is a subroutine
library, you may consider it more useful to permit linking
proprietary applications with the library. If this is what you want to
do, use the GNU Library General Public License instead of this
License. 



              MOZILLA PUBLIC LICENSE

                       Version 1.0

1. Definitions.

1.1. "Contributor" means each entity that creates or contributes to
the creation of Modifications.

1.2. "Contributor Version" means the combination of the Original
Code, prior Modifications used by a Contributor, and the
Modifications made by that particular Contributor.

1.3. "Covered Code" means the Original Code or Modifications or
the combination of the Original Code and Modifications, in each
case including portions thereof.

1.4. "Electronic Distribution Mechanism" means a mechanism
generally accepted in the software development community for the
electronic transfer of data.

1.5. "Executable" means Covered Code in any form other than
Source Code.

1.6. "Initial Developer" means the individual or entity identified as
the Initial Developer in the Source Code notice required by Exhibit
A.

1.7. "Larger Work" means a work which combines Covered Code
or portions thereof with code not governed by the terms of this
License.

1.8. "License" means this document.

1.9. "Modifications" means any addition to or deletion from the
substance or structure of either the Original Code or any previous
Modifications. When Covered Code is released as a series of
files, a Modification is:

A. Any addition to or deletion from the contents of a file containing
Original Code or previous Modifications.

B. Any new file that contains any part of the Original Code or
previous Modifications.

1.10. "Original Code" means Source Code of computer software
code which is described in the Source Code notice required by
Exhibit A as Original Code, and which, at the time of its release
under this License is not already Covered Code governed by this
License.

1.11. "Source Code" means the preferred form of the Covered
Code for making modifications to it, including all modules it
contains, plus any associated interface definition files, scripts
used to control compilation and installation of an Executable, or a
list of source code differential comparisons against either the
Original Code or another well known, available Covered Code of
the Contributor's choice. The Source Code can be in a
compressed or archival form, provided the appropriate
decompression or de-archiving software is widely available for no
charge.

1.12. "You" means an individual or a legal entity exercising rights
under, and complying with all of the terms of, this License or a
future version of this License issued under Section 6.1. For legal
entities, "You" includes any entity which controls, is controlled by,
or is under common control with You. For purposes of this
definition, "control" means (a) the power, direct or indirect, to
cause the direction or management of such entity, whether by
contract or otherwise, or (b) ownership of fifty percent (50%) or
more of the outstanding shares or beneficial ownership of such
entity.

2. Source Code License.

2.1. The Initial Developer Grant.

The Initial Developer hereby grants You a world-wide, royalty-free,
non-exclusive license, subject to third party intellectual property
claims:

(a) to use, reproduce, modify, display, perform, sublicense and
distribute the Original Code (or portions thereof) with or without
Modifications, or as part of a Larger Work; and

(b) under patents now or hereafter owned or controlled by Initial

Developer, to make, have made, use and sell ("Utilize") the
Original Code (or portions thereof), but solely to the extent that any
such patent is reasonably necessary to enable You to Utilize the
Original Code (or portions thereof) and not to any greater extent
that may be necessary to Utilize further Modifications or
combinations.

2.2. Contributor Grant.

Each Contributor hereby grants You a world-wide, royalty-free,
non-exclusive license, subject to third party intellectual property
claims:

(a) to use, reproduce, modify, display, perform, sublicense and
distribute the Modifications created by such Contributor (or
portions thereof) either on an unmodified basis, with other
Modifications, as Covered Code or as part of a Larger Work; and

(b) under patents now or hereafter owned or controlled by
Contributor, to Utilize the Contributor Version (or portions thereof),
but solely to the extent that any such patent is reasonably
necessary to enable You to Utilize the Contributor Version (or
portions thereof), and not to any greater extent that may be
necessary to Utilize further Modifications or combinations.

3. Distribution Obligations.

3.1. Application of License.

The Modifications which You create or to which You contribute are
governed by the terms of this License, including without limitation
Section 2.2. The Source Code version of Covered Code may be
distributed only under the terms of this License or a future version
of this License released under Section 6.1, and You must include
a copy of this License with every copy of the Source Code You
distribute. You may not offer or impose any terms on any Source
Code version that alters or restricts the applicable version of this
License or the recipients' rights hereunder. However, You may
include an additional document offering the additional rights
described in Section 3.5.

3.2. Availability of Source Code.

Any Modification which You create or to which You contribute must
be made available in Source Code form under the terms of this
License either on the same media as an Executable version or via
an accepted Electronic Distribution Mechanism to anyone to
whom you made an Executable version available; and if made
available via Electronic Distribution Mechanism, must remain
available for at least twelve (12) months after the date it initially
became available, or at least six (6) months after a subsequent
version of that particular Modification has been made available to
such recipients. You are responsible for ensuring that the Source
Code version remains available even if the Electronic Distribution
Mechanism is maintained by a third party.

3.3. Description of Modifications.

You must cause all Covered Code to which you contribute to
contain a file documenting the changes You made to create that
Covered Code and the date of any change. You must include a
prominent statement that the Modification is derived, directly or
indirectly, from Original Code provided by the Initial Developer and
including the name of the Initial Developer in (a) the Source Code,
and (b) in any notice in an Executable version or related
documentation in which You describe the origin or ownership of
the Covered Code.

3.4. Intellectual Property Matters 

(a) Third Party Claims.

If You have knowledge that a party claims an intellectual property
right in particular functionality or code (or its utilization under this
License), you must include a text file with the source code
distribution titled "LEGAL" which describes the claim and the party
making the claim in sufficient detail that a recipient will know whom
to contact. If you obtain such knowledge after You make Your
Modification available as described in Section 3.2, You shall
promptly modify the LEGAL file in all copies You make available
thereafter and shall take other steps (such as notifying appropriate
mailing lists or newsgroups) reasonably calculated to inform those
who received the Covered Code that new knowledge has been
obtained.

(b) Contributor APIs.

If Your Modification is an application programming interface and
You own or control patents which are reasonably necessary to
implement that API, you must also include this information in the
LEGAL file.

3.5. Required Notices.

You must duplicate the notice in Exhibit A in each file of the
Source Code, and this License in any documentation for the
Source Code, where You describe recipients' rights relating to
Covered Code. If You created one or more Modification(s), You
may add your name as a Contributor to the notice described in
Exhibit A. If it is not possible to put such notice in a particular
Source Code file due to its structure, then you must include such
notice in a location (such as a relevant directory file) where a user
would be likely to look for such a notice. You may choose to offer,
and to charge a fee for, warranty, support, indemnity or liability
obligations to one or more recipients of Covered Code. However,
You may do so only on Your own behalf, and not on behalf of the
Initial Developer or any Contributor. You must make it absolutely
clear than any such warranty, support, indemnity or liability
obligation is offered by You alone, and You hereby agree to
indemnify the Initial Developer and every Contributor for any
liability incurred by the Initial Developer or such Contributor as a
result of warranty, support, indemnity or liability terms You offer.

3.6. Distribution of Executable Versions.

You may distribute Covered Code in Executable form only if the
requirements of Section 3.1-3.5 have been met for that Covered
Code, and if You include a notice stating that the Source Code
version of the Covered Code is available under the terms of this
License, including a description of how and where You have
fulfilled the obligations of Section 3.2. The notice must be
conspicuously included in any notice in an Executable version,
related documentation or collateral in which You describe
recipients' rights relating to the Covered Code. You may distribute
the Executable version of Covered Code under a license of Your
choice, which may contain terms different from this License,
provided that You are in compliance with the terms of this License
and that the license for the Executable version does not attempt to
limit or alter the recipient's rights in the Source Code version from
the rights set forth in this License. If You distribute the Executable
version under a different license You must make it absolutely clear
that any terms which differ from this License are offered by You
alone, not by the Initial Developer or any Contributor. You hereby
agree to indemnify the Initial Developer and every Contributor for
any liability incurred by the Initial Developer or such Contributor as
a result of any such terms You offer.

3.7. Larger Works.

You may create a Larger Work by combining Covered Code with
other code not governed by the terms of this License and
distribute the Larger Work as a single product. In such a case, You
must make sure the requirements of this License are fulfilled for
the Covered Code.

4. Inability to Comply Due to Statute or Regulation.

If it is impossible for You to comply with any of the terms of this
License with respect to some or all of the Covered Code due to
statute or regulation then You must: (a) comply with the terms of
this License to the maximum extent possible; and (b) describe the
limitations and the code they affect. Such description must be
included in the LEGAL file described in Section 3.4 and must be
included with all distributions of the Source Code. Except to the
extent prohibited by statute or regulation, such description must be
sufficiently detailed for a recipient of ordinary skill to be able to
understand it.

5. Application of this License.

This License applies to code to which the Initial Developer has
attached the notice in Exhibit A, and to related Covered Code.

6. Versions of the License.

6.1. New Versions.

Netscape Communications Corporation ("Netscape") may publish
revised and/or new versions of the License from time to time.
Each version will be given a distinguishing version number.

6.2. Effect of New Versions.

Once Covered Code has been published under a particular
version of the License, You may always continue to use it under
the terms of that version. You may also choose to use such
Covered Code under the terms of any subsequent version of the
License published by Netscape. No one other than Netscape has
the right to modify the terms applicable to Covered Code created
under this License.

6.3. Derivative Works.

If you create or use a modified version of this License (which you
may only do in order to apply it to code which is not already
Covered Code governed by this License), you must (a) rename
Your license so that the phrases "Mozilla", "MOZILLAPL",
"MOZPL", "Netscape", "NPL" or any confusingly similar phrase do
not appear anywhere in your license and (b) otherwise make it
clear that your version of the license contains terms which differ
from the Mozilla Public License and Netscape Public License.
(Filling in the name of the Initial Developer, Original Code or
Contributor in the notice described in Exhibit A shall not of
themselves be deemed to be modifications of this License.)

7. DISCLAIMER OF WARRANTY.

COVERED CODE IS PROVIDED UNDER THIS LICENSE ON
AN "AS IS" BASIS, WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING, WITHOUT
LIMITATION, WARRANTIES THAT THE COVERED CODE IS
FREE OF DEFECTS, MERCHANTABLE, FIT FOR A
PARTICULAR PURPOSE OR NON-INFRINGING. THE ENTIRE
RISK AS TO THE QUALITY AND PERFORMANCE OF THE
COVERED CODE IS WITH YOU. SHOULD ANY COVERED
CODE PROVE DEFECTIVE IN ANY RESPECT, YOU (NOT THE
INITIAL DEVELOPER OR ANY OTHER CONTRIBUTOR)
ASSUME THE COST OF ANY NECESSARY SERVICING,
REPAIR OR CORRECTION. THIS DISCLAIMER OF WARRANTY
CONSTITUTES AN ESSENTIAL PART OF THIS LICENSE. NO
USE OF ANY COVERED CODE IS AUTHORIZED HEREUNDER
EXCEPT UNDER THIS DISCLAIMER.

8. TERMINATION.

This License and the rights granted hereunder will terminate
automatically if You fail to comply with terms herein and fail to cure
such breach within 30 days of becoming aware of the breach. All
sublicenses to the Covered Code which are properly granted shall
survive any termination of this License. Provisions which, by their
nature, must remain in effect beyond the termination of this
License shall survive.

9. LIMITATION OF LIABILITY.

UNDER NO CIRCUMSTANCES AND UNDER NO LEGAL
THEORY, WHETHER TORT (INCLUDING NEGLIGENCE),
CONTRACT, OR OTHERWISE, SHALL THE INITIAL
DEVELOPER, ANY OTHER CONTRIBUTOR, OR ANY
DISTRIBUTOR OF COVERED CODE, OR ANY SUPPLIER OF
ANY OF SUCH PARTIES, BE LIABLE TO YOU OR ANY OTHER
PERSON FOR ANY INDIRECT, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES OF ANY CHARACTER
INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF
GOODWILL, WORK STOPPAGE, COMPUTER FAILURE OR
MALFUNCTION, OR ANY AND ALL OTHER COMMERCIAL
DAMAGES OR LOSSES, EVEN IF SUCH PARTY SHALL HAVE
BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGES.
THIS LIMITATION OF LIABILITY SHALL NOT APPLY TO
LIABILITY FOR DEATH OR PERSONAL INJURY RESULTING
FROM SUCH PARTY'S NEGLIGENCE TO THE EXTENT
APPLICABLE LAW PROHIBITS SUCH LIMITATION. SOME
JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR
LIMITATION OF INCIDENTAL OR CONSEQUENTIAL
DAMAGES, SO THAT EXCLUSION AND LIMITATION MAY NOT
APPLY TO YOU.

10. U.S. GOVERNMENT END USERS.

The Covered Code is a "commercial item," as that term is defined
in 48 C.F.R. 2.101 (Oct. 1995), consisting of "commercial
computer software" and "commercial computer software
documentation," as such terms are used in 48 C.F.R. 12.212
(Sept. 1995). Consistent with 48 C.F.R. 12.212 and 48 C.F.R.
227.7202-1 through 227.7202-4 (June 1995), all U.S. Government
End Users acquire Covered Code with only those rights set forth
herein.

11. MISCELLANEOUS.

This License represents the complete agreement concerning
subject matter hereof. If any provision of this License is held to be
unenforceable, such provision shall be reformed only to the extent
necessary to make it enforceable. This License shall be governed
by California law provisions (except to the extent applicable law, if
any, provides otherwise), excluding its conflict-of-law provisions.
With respect to disputes in which at least one party is a citizen of,
or an entity chartered or registered to do business in, the United
States of America: (a) unless otherwise agreed in writing, all
disputes relating to this License (excepting any dispute relating to
intellectual property rights) shall be subject to final and binding
arbitration, with the losing party paying all costs of arbitration; (b)
any arbitration relating to this Agreement shall be held in Santa
Clara County, California, under the auspices of
JAMS/EndDispute; and (c) any litigation relating to this Agreement
shall be subject to the jurisdiction of the Federal Courts of the
Northern District of California, with venue lying in Santa Clara
County, California, with the losing party responsible for costs,
including without limitation, court costs and reasonable attorneys
fees and expenses. The application of the United Nations
Convention on Contracts for the International Sale of Goods is
expressly excluded. Any law or regulation which provides that the
language of a contract shall be construed against the drafter shall
not apply to this License.

12. RESPONSIBILITY FOR CLAIMS.

Except in cases where another Contributor has failed to comply
with Section 3.4, You are responsible for damages arising, directly
or indirectly, out of Your utilization of rights under this License,
based on the number of copies of Covered Code you made
available, the revenues you received from utilizing such rights, and
other relevant factors. You agree to work with affected parties to
distribute responsibility on an equitable basis.

EXHIBIT A.

``The contents of this file are subject to the Mozilla Public License
Version 1.0 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS
IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
or implied. See the License for the specific language governing
rights and limitations under the License.

The Original Code is Collaborative Virtual Workspace (CVW).

The Initial Developer of the Original Code is The MITRE
Corporation.

Portions created by The MITRE Corporation
(http://www.mitre.org/) are Copyright © 1994-1999. All Rights
Reserved.

Contributor(s): ______________________________________.''
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Mozilla_1_0

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Mozilla_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Mozilla Public License (Version 1.0)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Mozilla Public License (Version 1.0)

1. Definitions. 

     1.1. "Contributor" means each entity that creates or
     contributes to the creation of Modifications. 

     1.2. "Contributor Version" means the combination of
     the Original Code, prior Modifications used by a
     Contributor, and the Modifications made by that
     particular Contributor. 

     1.3. "Covered Code" means the Original Code or
     Modifications or the combination of the Original Code
     and Modifications, in each case including portions
     thereof. 

     1.4. "Electronic Distribution Mechanism" means a
     mechanism generally accepted in the software
     development community for the electronic transfer of
     data. 

     1.5. "Executable" means Covered Code in any form
     other than Source Code. 

     1.6. "Initial Developer" means the individual or entity
     identified as the Initial Developer in the Source Code
     notice required by Exhibit A. 

     1.7. "Larger Work" means a work which combines
     Covered Code or portions thereof with code not
     governed by the terms of this License. 

     1.8. "License" means this document. 

     1.9. "Modifications" means any addition to or deletion
     from the substance or structure of either the Original
     Code or any previous Modifications. When Covered
     Code is released as a series of files, a Modification is: 

          A. Any addition to or deletion from the contents
          of a file containing Original Code or previous
          Modifications. 

          B. Any new file that contains any part of the
          Original Code or previous Modifications. 

     1.10. "Original Code" means Source Code of
     computer software code which is described in the
     Source Code notice required by Exhibit A as Original
     Code, and which, at the time of its release under this
     License is not already Covered Code governed by this
     License. 

     1.11. "Source Code" means the preferred form of the
     Covered Code for making modifications to it, including
     all modules it contains, plus any associated interface
     definition files, scripts used to control compilation and
     installation of an Executable, or a list of source code
     differential comparisons against either the Original
     Code or another well known, available Covered Code of
     the Contributor's choice. The Source Code can be in a
     compressed or archival form, provided the appropriate
     decompression or de-archiving software is widely
     available for no charge. 

     1.12. "You" means an individual or a legal entity
     exercising rights under, and complying with all of the
     terms of, this License or a future version of this License
     issued under Section 6.1. For legal entities, "You"
     includes any entity which controls, is controlled by, or
     is under common control with You. For purposes of this
     definition, "control" means (a) the power, direct or
     indirect, to cause the direction or management of such
     entity, whether by contract or otherwise, or (b)
     ownership of fifty percent (50%) or more of the
     outstanding shares or beneficial ownership of such
     entity. 

2. Source Code License. 

     2.1. The Initial Developer Grant. 
     The Initial Developer hereby grants You a world-wide,
     royalty-free, non-exclusive license, subject to third
     party intellectual property claims: 

          (a) to use, reproduce, modify, display, perform,
          sublicense and distribute the Original Code (or
          portions thereof) with or without Modifications, or
          as part of a Larger Work; and 

          (b) under patents now or hereafter owned or
          controlled by Initial Developer, to make, have
          made, use and sell ("Utilize") the Original Code
          (or portions thereof), but solely to the extent that
          any such patent is reasonably necessary to
          enable You to Utilize the Original Code (or
          portions thereof) and not to any greater extent
          that may be necessary to Utilize further
          Modifications or combinations. 

     2.2. Contributor Grant. 
     Each Contributor hereby grants You a world-wide,
     royalty-free, non-exclusive license, subject to third
     party intellectual property claims: 

          (a) to use, reproduce, modify, display, perform,
          sublicense and distribute the Modifications
          created by such Contributor (or portions thereof)
          either on an unmodified basis, with other
          Modifications, as Covered Code or as part of a
          Larger Work; and 

          (b) under patents now or hereafter owned or
          controlled by Contributor, to Utilize the
          Contributor Version (or portions thereof), but
          solely to the extent that any such patent is
          reasonably necessary to enable You to Utilize
          the Contributor Version (or portions thereof), and
          not to any greater extent that may be necessary
          to Utilize further Modifications or combinations. 

3. Distribution Obligations. 

     3.1. Application of License. 
     The Modifications which You create or to which You
     contribute are governed by the terms of this License,
     including without limitation Section 2.2. The Source
     Code version of Covered Code may be distributed only
     under the terms of this License or a future version of
     this License released under Section 6.1, and You must
     include a copy of this License with every copy of the
     Source Code You distribute. You may not offer or
     impose any terms on any Source Code version that
     alters or restricts the applicable version of this License
     or the recipients' rights hereunder. However, You may
     include an additional document offering the additional
     rights described in Section 3.5. 

     3.2. Availability of Source Code. 
     Any Modification which You create or to which You
     contribute must be made available in Source Code form
     under the terms of this License either on the same
     media as an Executable version or via an accepted
     Electronic Distribution Mechanism to anyone to whom
     you made an Executable version available; and if made
     available via Electronic Distribution Mechanism, must
     remain available for at least twelve (12) months after the
     date it initially became available, or at least six (6)
     months after a subsequent version of that particular
     Modification has been made available to such
     recipients. You are responsible for ensuring that the
     Source Code version remains available even if the
     Electronic Distribution Mechanism is maintained by a
     third party. 

     3.3. Description of Modifications. 
     You must cause all Covered Code to which you
     contribute to contain a file documenting the changes
     You made to create that Covered Code and the date of
     any change. You must include a prominent statement
     that the Modification is derived, directly or indirectly,
     from Original Code provided by the Initial Developer and
     including the name of the Initial Developer in (a) the
     Source Code, and (b) in any notice in an Executable
     version or related documentation in which You describe
     the origin or ownership of the Covered Code. 

     3.4. Intellectual Property Matters 

          (a) Third Party Claims. 
          If You have knowledge that a party claims an
          intellectual property right in particular
          functionality or code (or its utilization under this
          License), you must include a text file with the
          source code distribution titled "LEGAL" which
          describes the claim and the party making the
          claim in sufficient detail that a recipient will
          know whom to contact. If you obtain such
          knowledge after You make Your Modification
          available as described in Section 3.2, You shall
          promptly modify the LEGAL file in all copies You
          make available thereafter and shall take other
          steps (such as notifying appropriate mailing lists
          or newsgroups) reasonably calculated to inform
          those who received the Covered Code that new
          knowledge has been obtained. 

          (b) Contributor APIs. 
          If Your Modification is an application
          programming interface and You own or control
          patents which are reasonably necessary to
          implement that API, you must also include this
          information in the LEGAL file. 

     3.5. Required Notices. 
     You must duplicate the notice in Exhibit A in each file
     of the Source Code, and this License in any
     documentation for the Source Code, where You
     describe recipients' rights relating to Covered Code. If
     You created one or more Modification(s), You may add
     your name as a Contributor to the notice described in
     Exhibit A. If it is not possible to put such notice in a
     particular Source Code file due to its structure, then
     you must include such notice in a location (such as a
     relevant directory file) where a user would be likely to
     look for such a notice. You may choose to offer, and to
     charge a fee for, warranty, support, indemnity or liability
     obligations to one or more recipients of Covered Code.
     However, You may do so only on Your own behalf, and
     not on behalf of the Initial Developer or any Contributor.
     You must make it absolutely clear than any such
     warranty, support, indemnity or liability obligation is
     offered by You alone, and You hereby agree to
     indemnify the Initial Developer and every Contributor for
     any liability incurred by the Initial Developer or such
     Contributor as a result of warranty, support, indemnity
     or liability terms You offer. 

     3.6. Distribution of Executable Versions. 
     You may distribute Covered Code in Executable form
     only if the requirements of Section 3.1-3.5 have been
     met for that Covered Code, and if You include a notice
     stating that the Source Code version of the Covered
     Code is available under the terms of this License,
     including a description of how and where You have
     fulfilled the obligations of Section 3.2. The notice must
     be conspicuously included in any notice in an
     Executable version, related documentation or collateral
     in which You describe recipients' rights relating to the
     Covered Code. You may distribute the Executable
     version of Covered Code under a license of Your
     choice, which may contain terms different from this
     License, provided that You are in compliance with the
     terms of this License and that the license for the
     Executable version does not attempt to limit or alter the
     recipient's rights in the Source Code version from the
     rights set forth in this License. If You distribute the
     Executable version under a different license You must
     make it absolutely clear that any terms which differ
     from this License are offered by You alone, not by the
     Initial Developer or any Contributor. You hereby agree
     to indemnify the Initial Developer and every Contributor
     for any liability incurred by the Initial Developer or such
     Contributor as a result of any such terms You offer. 

     3.7. Larger Works. 
     You may create a Larger Work by combining Covered
     Code with other code not governed by the terms of this
     License and distribute the Larger Work as a single
     product. In such a case, You must make sure the
     requirements of this License are fulfilled for the Covered
     Code. 

4. Inability to Comply Due to Statute or Regulation. 

     If it is impossible for You to comply with any of the
     terms of this License with respect to some or all of the
     Covered Code due to statute or regulation then You
     must: (a) comply with the terms of this License to the
     maximum extent possible; and (b) describe the
     limitations and the code they affect. Such description
     must be included in the LEGAL file described in
     Section 3.4 and must be included with all distributions
     of the Source Code. Except to the extent prohibited by
     statute or regulation, such description must be
     sufficiently detailed for a recipient of ordinary skill to be
     able to understand it. 

5. Application of this License. 

     This License applies to code to which the Initial
     Developer has attached the notice in Exhibit A, and to
     related Covered Code. 

6. Versions of the License. 

     6.1. New Versions. 
     Netscape Communications Corporation ("Netscape")
     may publish revised and/or new versions of the License
     from time to time. Each version will be given a
     distinguishing version number. 

     6.2. Effect of New Versions. 
     Once Covered Code has been published under a
     particular version of the License, You may always
     continue to use it under the terms of that version. You
     may also choose to use such Covered Code under the
     terms of any subsequent version of the License
     published by Netscape. No one other than Netscape
     has the right to modify the terms applicable to Covered
     Code created under this License. 

     6.3. Derivative Works. 
     If you create or use a modified version of this License
     (which you may only do in order to apply it to code
     which is not already Covered Code governed by this
     License), you must (a) rename Your license so that the
     phrases "Mozilla", "MOZILLAPL", "MOZPL",
     "Netscape", "NPL" or any confusingly similar phrase do
     not appear anywhere in your license and (b) otherwise
     make it clear that your version of the license contains
     terms which differ from the Mozilla Public License and
     Netscape Public License. (Filling in the name of the
     Initial Developer, Original Code or Contributor in the
     notice described in Exhibit A shall not of themselves
     be deemed to be modifications of this License.) 

7. DISCLAIMER OF WARRANTY. 

     COVERED CODE IS PROVIDED UNDER THIS
     LICENSE ON AN "AS IS" BASIS, WITHOUT
     WARRANTY OF ANY KIND, EITHER EXPRESSED
     OR IMPLIED, INCLUDING, WITHOUT LIMITATION,
     WARRANTIES THAT THE COVERED CODE IS FREE
     OF DEFECTS, MERCHANTABLE, FIT FOR A
     PARTICULAR PURPOSE OR NON-INFRINGING. THE
     ENTIRE RISK AS TO THE QUALITY AND
     PERFORMANCE OF THE COVERED CODE IS WITH
     YOU. SHOULD ANY COVERED CODE PROVE
     DEFECTIVE IN ANY RESPECT, YOU (NOT THE
     INITIAL DEVELOPER OR ANY OTHER
     CONTRIBUTOR) ASSUME THE COST OF ANY
     NECESSARY SERVICING, REPAIR OR
     CORRECTION. THIS DISCLAIMER OF WARRANTY
     CONSTITUTES AN ESSENTIAL PART OF THIS
     LICENSE. NO USE OF ANY COVERED CODE IS
     AUTHORIZED HEREUNDER EXCEPT UNDER THIS
     DISCLAIMER. 

8. TERMINATION. 

     This License and the rights granted hereunder will
     terminate automatically if You fail to comply with terms
     herein and fail to cure such breach within 30 days of
     becoming aware of the breach. All sublicenses to the
     Covered Code which are properly granted shall survive
     any termination of this License. Provisions which, by
     their nature, must remain in effect beyond the
     termination of this License shall survive. 

9. LIMITATION OF LIABILITY. 

     UNDER NO CIRCUMSTANCES AND UNDER NO
     LEGAL THEORY, WHETHER TORT (INCLUDING
     NEGLIGENCE), CONTRACT, OR OTHERWISE,
     SHALL THE INITIAL DEVELOPER, ANY OTHER
     CONTRIBUTOR, OR ANY DISTRIBUTOR OF
     COVERED CODE, OR ANY SUPPLIER OF ANY OF
     SUCH PARTIES, BE LIABLE TO YOU OR ANY
     OTHER PERSON FOR ANY INDIRECT, SPECIAL,
     INCIDENTAL, OR CONSEQUENTIAL DAMAGES OF
     ANY CHARACTER INCLUDING, WITHOUT
     LIMITATION, DAMAGES FOR LOSS OF GOODWILL,
     WORK STOPPAGE, COMPUTER FAILURE OR
     MALFUNCTION, OR ANY AND ALL OTHER
     COMMERCIAL DAMAGES OR LOSSES, EVEN IF
     SUCH PARTY SHALL HAVE BEEN INFORMED OF
     THE POSSIBILITY OF SUCH DAMAGES. THIS
     LIMITATION OF LIABILITY SHALL NOT APPLY TO
     LIABILITY FOR DEATH OR PERSONAL INJURY
     RESULTING FROM SUCH PARTY'S NEGLIGENCE
     TO THE EXTENT APPLICABLE LAW PROHIBITS
     SUCH LIMITATION. SOME JURISDICTIONS DO NOT
     ALLOW THE EXCLUSION OR LIMITATION OF
     INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO
     THAT EXCLUSION AND LIMITATION MAY NOT
     APPLY TO YOU. 

10. U.S. GOVERNMENT END USERS. 

     The Covered Code is a "commercial item," as that term
     is defined in 48 C.F.R. 2.101 (Oct. 1995), consisting of
     "commercial computer software" and "commercial
     computer software documentation," as such terms are
     used in 48 C.F.R. 12.212 (Sept. 1995). Consistent with
     48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through
     227.7202-4 (June 1995), all U.S. Government End
     Users acquire Covered Code with only those rights set
     forth herein. 

11. MISCELLANEOUS. 

     This License represents the complete agreement
     concerning subject matter hereof. If any provision of
     this License is held to be unenforceable, such provision
     shall be reformed only to the extent necessary to make
     it enforceable. This License shall be governed by
     California law provisions (except to the extent
     applicable law, if any, provides otherwise), excluding its
     conflict-of-law provisions. With respect to disputes in
     which at least one party is a citizen of, or an entity
     chartered or registered to do business in, the United
     States of America: (a) unless otherwise agreed in
     writing, all disputes relating to this License (excepting
     any dispute relating to intellectual property rights) shall
     be subject to final and binding arbitration, with the
     losing party paying all costs of arbitration; (b) any
     arbitration relating to this Agreement shall be held in
     Santa Clara County, California, under the auspices of
     JAMS/EndDispute; and (c) any litigation relating to this
     Agreement shall be subject to the jurisdiction of the
     Federal Courts of the Northern District of California,
     with venue lying in Santa Clara County, California, with
     the losing party responsible for costs, including without
     limitation, court costs and reasonable attorneys fees
     and expenses. The application of the United Nations
     Convention on Contracts for the International Sale of
     Goods is expressly excluded. Any law or regulation
     which provides that the language of a contract shall be
     construed against the drafter shall not apply to this
     License. 

12. RESPONSIBILITY FOR CLAIMS. 

     Except in cases where another Contributor has failed to
     comply with Section 3.4, You are responsible for
     damages arising, directly or indirectly, out of Your
     utilization of rights under this License, based on the
     number of copies of Covered Code you made available,
     the revenues you received from utilizing such rights,
     and other relevant factors. You agree to work with
     affected parties to distribute responsibility on an
     equitable basis. 

EXHIBIT A. 

     "The contents of this file are subject to the Mozilla
     Public License Version 1.0 (the "License"); you may
     not use this file except in compliance with the License.
     You may obtain a copy of the License at
     http://www.mozilla.org/MPL/ 

     Software distributed under the License is distributed on
     an "AS IS" basis, WITHOUT WARRANTY OF ANY
     KIND, either express or implied. See the License for
     the specific language governing rights and limitations
     under the License. 

     The Original Code is
     ______________________________________. 

     The Initial Developer of the Original Code is
     ________________________. Portions created by
     ______________________ are Copyright (C) ______
     _______________________. All Rights Reserved. 

     Contributor(s):
     ______________________________________." 
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Mozilla_1_1

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Mozilla_1_1 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Mozilla Public License 1.1 (MPL 1.1)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Mozilla Public License 1.1 (MPL 1.1)

1. Definitions. 

     1.0.1. "Commercial Use" means distribution or
     otherwise making the Covered Code available to a third
     party. 

     1.1. ''Contributor'' means each entity that creates or
     contributes to the creation of Modifications. 

     1.2. ''Contributor Version'' means the combination of
     the Original Code, prior Modifications used by a
     Contributor, and the Modifications made by that
     particular Contributor. 

     1.3. ''Covered Code'' means the Original Code or
     Modifications or the combination of the Original Code
     and Modifications, in each case including portions
     thereof. 

     1.4. ''Electronic Distribution Mechanism'' means a
     mechanism generally accepted in the software
     development community for the electronic transfer of
     data. 

     1.5. ''Executable'' means Covered Code in any form
     other than Source Code. 

     1.6. ''Initial Developer'' means the individual or entity
     identified as the Initial Developer in the Source Code
     notice required by Exhibit A. 

     1.7. ''Larger Work'' means a work which combines
     Covered Code or portions thereof with code not
     governed by the terms of this License. 

     1.8. ''License'' means this document. 

     1.8.1. "Licensable" means having the right to grant,
     to the maximum extent possible, whether at the time
     of the initial grant or subsequently acquired, any and
     all of the rights conveyed herein. 

     1.9. ''Modifications'' means any addition to or deletion
     from the substance or structure of either the Original
     Code or any previous Modifications. When Covered
     Code is released as a series of files, a Modification is: 
          A. Any addition to or deletion from the contents
          of a file containing Original Code or previous
          Modifications. 

          B. Any new file that contains any part of the
          Original Code or previous Modifications. 
           
     1.10. ''Original Code'' means Source Code of
     computer software code which is described in the
     Source Code notice required by Exhibit A as Original
     Code, and which, at the time of its release under this
     License is not already Covered Code governed by this
     License. 

     1.10.1. "Patent Claims" means any patent claim(s),
     now owned or hereafter acquired, including without
     limitation,  method, process, and apparatus claims, in
     any patent Licensable by grantor. 

     1.11. ''Source Code'' means the preferred form of the
     Covered Code for making modifications to it, including
     all modules it contains, plus any associated interface
     definition files, scripts used to control compilation and
     installation of an Executable, or source code
     differential comparisons against either the Original
     Code or another well known, available Covered Code of
     the Contributor's choice. The Source Code can be in a
     compressed or archival form, provided the appropriate
     decompression or de-archiving software is widely
     available for no charge. 

     1.12. "You'' (or "Your")  means an individual or a legal
     entity exercising rights under, and complying with all of
     the terms of, this License or a future version of this
     License issued under Section 6.1. For legal entities,
     "You'' includes any entity which controls, is controlled
     by, or is under common control with You. For purposes
     of this definition, "control'' means (a) the power, direct
     or indirect, to cause the direction or management of
     such entity, whether by contract or otherwise, or (b)
     ownership of more than fifty percent (50%) of the
     outstanding shares or beneficial ownership of such
     entity.

2. Source Code License. 

     2.1. The Initial Developer Grant. 
     The Initial Developer hereby grants You a world-wide,
     royalty-free, non-exclusive license, subject to third
     party intellectual property claims: 
          (a)  under intellectual property rights (other than
          patent or trademark) Licensable by Initial
          Developer to use, reproduce, modify, display,
          perform, sublicense and distribute the Original
          Code (or portions thereof) with or without
          Modifications, and/or as part of a Larger Work;
          and 

          (b) under Patents Claims infringed by the
          making, using or selling of Original Code, to
          make, have made, use, practice, sell, and offer
          for sale, and/or otherwise dispose of the Original
          Code (or portions thereof). 
                     
          (c) the licenses granted in this Section 2.1(a)
          and (b) are effective on the date Initial Developer
          first distributes Original Code under the terms of
          this License. 

          (d) Notwithstanding Section 2.1(b) above, no
          patent license is granted: 1) for code that You
          delete from the Original Code; 2) separate from
          the Original Code;  or 3) for infringements
          caused by: i) the modification of the Original
          Code or ii) the combination of the Original Code
          with other software or devices. 
           
     2.2. Contributor Grant. 
     Subject to third party intellectual property claims, each
     Contributor hereby grants You a world-wide,
     royalty-free, non-exclusive license 
            
          (a)  under intellectual property rights (other than
          patent or trademark) Licensable by Contributor,
          to use, reproduce, modify, display, perform,
          sublicense and distribute the Modifications
          created by such Contributor (or portions thereof)
          either on an unmodified basis, with other
          Modifications, as Covered Code and/or as part
          of a Larger Work; and 

          (b) under Patent Claims infringed by the
          making, using, or selling of  Modifications made
          by that Contributor either alone and/or in
          combination with its Contributor Version (or
          portions of such combination), to make, use,
          sell, offer for sale, have made, and/or otherwise
          dispose of: 1) Modifications made by that
          Contributor (or portions thereof); and 2) the
          combination of  Modifications made by that
          Contributor with its Contributor Version (or
          portions of such combination). 

          (c) the licenses granted in Sections 2.2(a) and
          2.2(b) are effective on the date Contributor first
          makes Commercial Use of the Covered Code. 

          (d)    Notwithstanding Section 2.2(b) above, no
          patent license is granted: 1) for any code that
          Contributor has deleted from the Contributor
          Version; 2)  separate from the Contributor
          Version;  3)  for infringements caused by: i) third
          party modifications of Contributor Version or ii) 
          the combination of Modifications made by that
          Contributor with other software  (except as part
          of the Contributor Version) or other devices; or
          4) under Patent Claims infringed by Covered
          Code in the absence of Modifications made by
          that Contributor.


3. Distribution Obligations. 

     3.1. Application of License. 
     The Modifications which You create or to which You
     contribute are governed by the terms of this License,
     including without limitation Section 2.2. The Source
     Code version of Covered Code may be distributed only
     under the terms of this License or a future version of
     this License released under Section 6.1, and You must
     include a copy of this License with every copy of the
     Source Code You distribute. You may not offer or
     impose any terms on any Source Code version that
     alters or restricts the applicable version of this License
     or the recipients' rights hereunder. However, You may
     include an additional document offering the additional
     rights described in Section 3.5. 

     3.2. Availability of Source Code. 
     Any Modification which You create or to which You
     contribute must be made available in Source Code
     form under the terms of this License either on the
     same media as an Executable version or via an
     accepted Electronic Distribution Mechanism to anyone
     to whom you made an Executable version available;
     and if made available via Electronic Distribution
     Mechanism, must remain available for at least twelve
     (12) months after the date it initially became available,
     or at least six (6) months after a subsequent version of
     that particular Modification has been made available to
     such recipients. You are responsible for ensuring that
     the Source Code version remains available even if the
     Electronic Distribution Mechanism is maintained by a
     third party. 

     3.3. Description of Modifications. 
     You must cause all Covered Code to which You
     contribute to contain a file documenting the changes
     You made to create that Covered Code and the date of
     any change. You must include a prominent statement
     that the Modification is derived, directly or indirectly,
     from Original Code provided by the Initial Developer and
     including the name of the Initial Developer in (a) the
     Source Code, and (b) in any notice in an Executable
     version or related documentation in which You describe
     the origin or ownership of the Covered Code. 

     3.4. Intellectual Property Matters 
          (a) Third Party Claims. 
          If Contributor has knowledge that a license
          under a third party's intellectual property rights
          is required to exercise the rights granted by
          such Contributor under Sections 2.1 or 2.2,
          Contributor must include a text file with the
          Source Code distribution titled "LEGAL'' which
          describes the claim and the party making the
          claim in sufficient detail that a recipient will
          know whom to contact. If Contributor obtains
          such knowledge after the Modification is made
          available as described in Section 3.2,
          Contributor shall promptly modify the LEGAL file
          in all copies Contributor makes available
          thereafter and shall take other steps (such as
          notifying appropriate mailing lists or
          newsgroups) reasonably calculated to inform
          those who received the Covered Code that new
          knowledge has been obtained. 

          (b) Contributor APIs. 
          If Contributor's Modifications include an
          application programming interface and
          Contributor has knowledge of patent licenses
          which are reasonably necessary to implement
          that API, Contributor must also include this
          information in the LEGAL file. 
           
               (c)    Representations. 
          Contributor represents that, except as disclosed
          pursuant to Section 3.4(a) above, Contributor
          believes that Contributor's Modifications are
          Contributor's original creation(s) and/or
          Contributor has sufficient rights to grant the
          rights conveyed by this License.


     3.5. Required Notices. 
     You must duplicate the notice in Exhibit A in each file
     of the Source Code.  If it is not possible to put such
     notice in a particular Source Code file due to its
     structure, then You must include such notice in a
     location (such as a relevant directory) where a user
     would be likely to look for such a notice.  If You
     created one or more Modification(s) You may add your
     name as a Contributor to the notice described in
     Exhibit A.  You must also duplicate this License in
     any documentation for the Source Code where You
     describe recipients' rights or ownership rights relating
     to Covered Code.  You may choose to offer, and to
     charge a fee for, warranty, support, indemnity or
     liability obligations to one or more recipients of Covered
     Code. However, You may do so only on Your own
     behalf, and not on behalf of the Initial Developer or any
     Contributor. You must make it absolutely clear than
     any such warranty, support, indemnity or liability
     obligation is offered by You alone, and You hereby
     agree to indemnify the Initial Developer and every
     Contributor for any liability incurred by the Initial
     Developer or such Contributor as a result of warranty,
     support, indemnity or liability terms You offer. 

     3.6. Distribution of Executable Versions. 
     You may distribute Covered Code in Executable form
     only if the requirements of Section 3.1-3.5 have been
     met for that Covered Code, and if You include a notice
     stating that the Source Code version of the Covered
     Code is available under the terms of this License,
     including a description of how and where You have
     fulfilled the obligations of Section 3.2. The notice must
     be conspicuously included in any notice in an
     Executable version, related documentation or collateral
     in which You describe recipients' rights relating to the
     Covered Code. You may distribute the Executable
     version of Covered Code or ownership rights under a
     license of Your choice, which may contain terms
     different from this License, provided that You are in
     compliance with the terms of this License and that the
     license for the Executable version does not attempt to
     limit or alter the recipient's rights in the Source Code
     version from the rights set forth in this License. If You
     distribute the Executable version under a different
     license You must make it absolutely clear that any
     terms which differ from this License are offered by You
     alone, not by the Initial Developer or any Contributor.
     You hereby agree to indemnify the Initial Developer and
     every Contributor for any liability incurred by the Initial
     Developer or such Contributor as a result of any such
     terms You offer. 

     3.7. Larger Works. 
     You may create a Larger Work by combining Covered
     Code with other code not governed by the terms of this
     License and distribute the Larger Work as a single
     product. In such a case, You must make sure the
     requirements of this License are fulfilled for the Covered
     Code.

4. Inability to Comply Due to Statute or Regulation. 

     If it is impossible for You to comply with any of the
     terms of this License with respect to some or all of the
     Covered Code due to statute, judicial order, or
     regulation then You must: (a) comply with the terms of
     this License to the maximum extent possible; and (b)
     describe the limitations and the code they affect. Such
     description must be included in the LEGAL file
     described in Section 3.4 and must be included with all
     distributions of the Source Code. Except to the extent
     prohibited by statute or regulation, such description
     must be sufficiently detailed for a recipient of ordinary
     skill to be able to understand it.

5. Application of this License. 

     This License applies to code to which the Initial
     Developer has attached the notice in Exhibit A and to
     related Covered Code.

6. Versions of the License. 

     6.1. New Versions. 
     Netscape Communications Corporation (''Netscape'')
     may publish revised and/or new versions of the License
     from time to time. Each version will be given a
     distinguishing version number. 

     6.2. Effect of New Versions. 
     Once Covered Code has been published under a
     particular version of the License, You may always
     continue to use it under the terms of that version. You
     may also choose to use such Covered Code under the
     terms of any subsequent version of the License
     published by Netscape. No one other than Netscape
     has the right to modify the terms applicable to Covered
     Code created under this License. 

     6.3. Derivative Works. 
     If You create or use a modified version of this License
     (which you may only do in order to apply it to code
     which is not already Covered Code governed by this
     License), You must (a) rename Your license so that
     the phrases ''Mozilla'', ''MOZILLAPL'', ''MOZPL'',
     ''Netscape'', "MPL", ''NPL'' or any confusingly similar
     phrase do not appear in your license (except to note
     that your license differs from this License) and (b)
     otherwise make it clear that Your version of the license
     contains terms which differ from the Mozilla Public
     License and Netscape Public License. (Filling in the
     name of the Initial Developer, Original Code or
     Contributor in the notice described in Exhibit A shall
     not of themselves be deemed to be modifications of
     this License.)

7. DISCLAIMER OF WARRANTY. 

     COVERED CODE IS PROVIDED UNDER THIS
     LICENSE ON AN "AS IS'' BASIS, WITHOUT
     WARRANTY OF ANY KIND, EITHER EXPRESSED
     OR IMPLIED, INCLUDING, WITHOUT LIMITATION,
     WARRANTIES THAT THE COVERED CODE IS FREE
     OF DEFECTS, MERCHANTABLE, FIT FOR A
     PARTICULAR PURPOSE OR NON-INFRINGING. THE
     ENTIRE RISK AS TO THE QUALITY AND
     PERFORMANCE OF THE COVERED CODE IS WITH
     YOU. SHOULD ANY COVERED CODE PROVE
     DEFECTIVE IN ANY RESPECT, YOU (NOT THE
     INITIAL DEVELOPER OR ANY OTHER
     CONTRIBUTOR) ASSUME THE COST OF ANY
     NECESSARY SERVICING, REPAIR OR
     CORRECTION. THIS DISCLAIMER OF WARRANTY
     CONSTITUTES AN ESSENTIAL PART OF THIS
     LICENSE. NO USE OF ANY COVERED CODE IS
     AUTHORIZED HEREUNDER EXCEPT UNDER THIS
     DISCLAIMER.

8. TERMINATION. 

     8.1.  This License and the rights granted hereunder will
     terminate automatically if You fail to comply with terms
     herein and fail to cure such breach within 30 days of
     becoming aware of the breach. All sublicenses to the
     Covered Code which are properly granted shall survive
     any termination of this License. Provisions which, by
     their nature, must remain in effect beyond the
     termination of this License shall survive. 

     8.2.  If You initiate litigation by asserting a patent
     infringement claim (excluding declatory judgment
     actions) against Initial Developer or a Contributor (the
     Initial Developer or Contributor against whom You file
     such action is referred to as "Participant")  alleging
     that: 

     (a)  such Participant's Contributor Version directly or
     indirectly infringes any patent, then any and all rights
     granted by such Participant to You under Sections 2.1
     and/or 2.2 of this License shall, upon 60 days notice
     from Participant terminate prospectively, unless if
     within 60 days after receipt of notice You either: (i) 
     agree in writing to pay Participant a mutually agreeable
     reasonable royalty for Your past and future use of
     Modifications made by such Participant, or (ii)
     withdraw Your litigation claim with respect to the
     Contributor Version against such Participant.  If within
     60 days of notice, a reasonable royalty and payment
     arrangement are not mutually agreed upon in writing by
     the parties or the litigation claim is not withdrawn, the
     rights granted by Participant to You under Sections 2.1
     and/or 2.2 automatically terminate at the expiration of
     the 60 day notice period specified above. 

     (b)  any software, hardware, or device, other than such
     Participant's Contributor Version, directly or indirectly
     infringes any patent, then any rights granted to You by
     such Participant under Sections 2.1(b) and 2.2(b) are
     revoked effective as of the date You first made, used,
     sold, distributed, or had made, Modifications made by
     that Participant. 

     8.3.  If You assert a patent infringement claim against
     Participant alleging that such Participant's Contributor
     Version directly or indirectly infringes any patent where
     such claim is resolved (such as by license or
     settlement) prior to the initiation of patent infringement
     litigation, then the reasonable value of the licenses
     granted by such Participant under Sections 2.1 or 2.2
     shall be taken into account in determining the amount
     or value of any payment or license. 

     8.4.  In the event of termination under Sections 8.1 or
     8.2 above,  all end user license agreements (excluding
     distributors and resellers) which have been validly
     granted by You or any distributor hereunder prior to
     termination shall survive termination.

9. LIMITATION OF LIABILITY. 

     UNDER NO CIRCUMSTANCES AND UNDER NO
     LEGAL THEORY, WHETHER TORT (INCLUDING
     NEGLIGENCE), CONTRACT, OR OTHERWISE,
     SHALL YOU, THE INITIAL DEVELOPER, ANY OTHER
     CONTRIBUTOR, OR ANY DISTRIBUTOR OF
     COVERED CODE, OR ANY SUPPLIER OF ANY OF
     SUCH PARTIES, BE LIABLE TO ANY PERSON FOR
     ANY INDIRECT, SPECIAL, INCIDENTAL, OR
     CONSEQUENTIAL DAMAGES OF ANY CHARACTER
     INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
     LOSS OF GOODWILL, WORK STOPPAGE,
     COMPUTER FAILURE OR MALFUNCTION, OR ANY
     AND ALL OTHER COMMERCIAL DAMAGES OR
     LOSSES, EVEN IF SUCH PARTY SHALL HAVE
     BEEN INFORMED OF THE POSSIBILITY OF SUCH
     DAMAGES. THIS LIMITATION OF LIABILITY SHALL
     NOT APPLY TO LIABILITY FOR DEATH OR
     PERSONAL INJURY RESULTING FROM SUCH
     PARTY'S NEGLIGENCE TO THE EXTENT
     APPLICABLE LAW PROHIBITS SUCH LIMITATION.
     SOME JURISDICTIONS DO NOT ALLOW THE
     EXCLUSION OR LIMITATION OF INCIDENTAL OR
     CONSEQUENTIAL DAMAGES, SO THIS EXCLUSION
     AND LIMITATION MAY NOT APPLY TO YOU.

10. U.S. GOVERNMENT END USERS. 

     The Covered Code is a ''commercial item,'' as that term
     is defined in 48 C.F.R. 2.101 (Oct. 1995), consisting of
     ''commercial computer software'' and ''commercial
     computer software documentation,'' as such terms are
     used in 48 C.F.R. 12.212 (Sept. 1995). Consistent with
     48 C.F.R. 12.212 and 48 C.F.R. 227.7202-1 through
     227.7202-4 (June 1995), all U.S. Government End
     Users acquire Covered Code with only those rights set
     forth herein.

11. MISCELLANEOUS. 

     This License represents the complete agreement
     concerning subject matter hereof. If any provision of
     this License is held to be unenforceable, such
     provision shall be reformed only to the extent
     necessary to make it enforceable. This License shall
     be governed by California law provisions (except to the
     extent applicable law, if any, provides otherwise),
     excluding its conflict-of-law provisions. With respect to
     disputes in which at least one party is a citizen of, or
     an entity chartered or registered to do business in the
     United States of America, any litigation relating to this
     License shall be subject to the jurisdiction of the
     Federal Courts of the Northern District of California,
     with venue lying in Santa Clara County, California, with
     the losing party responsible for costs, including without
     limitation, court costs and reasonable attorneys' fees
     and expenses. The application of the United Nations
     Convention on Contracts for the International Sale of
     Goods is expressly excluded. Any law or regulation
     which provides that the language of a contract shall be
     construed against the drafter shall not apply to this
     License.

12. RESPONSIBILITY FOR CLAIMS. 

     As between Initial Developer and the Contributors,
     each party is responsible for claims and damages
     arising, directly or indirectly, out of its utilization of
     rights under this License and You agree to work with
     Initial Developer and Contributors to distribute such
     responsibility on an equitable basis. Nothing herein is
     intended or shall be deemed to constitute any
     admission of liability.

13. MULTIPLE-LICENSED CODE. 

     Initial Developer may designate portions of the Covered
     Code as “Multiple-Licensed”.  “Multiple-Licensed”
     means that the Initial Developer permits you to utilize
     portions of the Covered Code under Your choice of the
     NPL or the alternative licenses, if any, specified by the
     Initial Developer in the file described in Exhibit A.


EXHIBIT A -Mozilla Public License. 

     ``The contents of this file are subject to the Mozilla
     Public License Version 1.1 (the "License"); you may
     not use this file except in compliance with the License.
     You may obtain a copy of the License at 
     http://www.mozilla.org/MPL/ 

     Software distributed under the License is distributed on
     an "AS IS" basis, WITHOUT WARRANTY OF 
     ANY KIND, either express or implied. See the License
     for the specific language governing rights and 
     limitations under the License. 

     The Original Code is
     ______________________________________. 

     The Initial Developer of the Original Code is
     ________________________. Portions created by 
      ______________________ are Copyright (C) ______
     _______________________. All Rights 
     Reserved. 

     Contributor(s):
     ______________________________________. 

     Alternatively, the contents of this file may be used
     under the terms of the _____ license (the  “[___]
     License”), in which case the provisions of [______]
     License are applicable  instead of those above.  If you
     wish to allow use of your version of this file only under
     the terms of the [____] License and not to allow others
     to use your version of this file under the MPL, indicate
     your decision by deleting  the provisions above and
     replace  them with the notice and other provisions
     required by the [___] License.  If you do not delete the
     provisions above, a recipient may use your version of
     this file under either the MPL or the [___] License." 

     [NOTE: The text of this Exhibit A may differ slightly
     from the text of the notices in the Source Code files of
     the Original Code. You should use the text of this
     Exhibit A rather than the text found in the Original
     Code Source Code for Your Modifications.] 
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Nethack

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Nethack {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Nethack General Public License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Nethack General Public License

   Copyright (c) 1989 M. Stephenson 
  (Based on the BISON general public
   license, copyright 1988 Richard M.
                Stallman) 

Everyone is permitted to copy and distribute
verbatim copies of this license, but changing it is
not allowed. You can also use this wording to make
the terms for other programs.

The license agreements of most software
companies keep you at the mercy of those
companies. By contrast, our general public license
is intended to give everyone the right to share
NetHack. To make sure that you get the rights we
want you to have, we need to make restrictions that
forbid anyone to deny you these rights or to ask you
to surrender the rights. Hence this license
agreement.

Specifically, we want to make sure that you have
the right to give away copies of NetHack, that you
receive source code or else can get it if you want it,
that you can change NetHack or use pieces of it in
new free programs, and that you know you can do
these things.

To make sure that everyone has such rights, we
have to forbid you to deprive anyone else of these
rights. For example, if you distribute copies of
NetHack, you must give the recipients all the rights
that you have. You must make sure that they, too,
receive or can get the source code. And you must
tell them their rights.

Also, for our own protection, we must make certain
that everyone finds out that there is no warranty for
NetHack. If NetHack is modified by someone else
and passed on, we want its recipients to know that
what they have is not what we distributed.

Therefore we (Mike Stephenson and other holders
of NetHack copyrights) make the following terms
which say what you must do to be allowed to
distribute or change NetHack.

       COPYING POLICIES 

  1.You may copy and distribute verbatim copies
     of NetHack source code as you receive it, in
     any medium, provided that you keep intact
     the notices on all files that refer to copyrights,
     to this License Agreement, and to the
     absence of any warranty; and give any other
     recipients of the NetHack program a copy of
     this License Agreement along with the
     program. 
  2.You may modify your copy or copies of
     NetHack or any portion of it, and copy and
     distribute such modifications under the terms
     of Paragraph 1 above (including distributing
     this License Agreement), provided that you
     also do the following: 

     a) cause the modified files to carry prominent
     notices stating that you changed the files and
     the date of any change; and

     b) cause the whole of any work that you
     distribute or publish, that in whole or in part
     contains or is a derivative of NetHack or any
     part thereof, to be licensed at no charge to all
     third parties on terms identical to those
     contained in this License Agreement (except
     that you may choose to grant more extensive
     warranty protection to some or all third
     parties, at your option)

     c) You may charge a distribution fee for the
     physical act of transferring a copy, and you
     may at your option offer warranty protection in
     exchange for a fee.

  3.You may copy and distribute NetHack (or a
     portion or derivative of it, under Paragraph 2)
     in object code or executable form under the
     terms of Paragraphs 1 and 2 above provided
     that you also do one of the following: 

     a) accompany it with the complete
     machine-readable source code, which must
     be distributed under the terms of Paragraphs
     1 and 2 above; or,

     b) accompany it with full information as to
     how to obtain the complete
     machine-readable source code from an
     appropriate archive site. (This alternative is
     allowed only for noncommercial distribution.)

     For these purposes, complete source code
     means either the full source distribution as
     originally released over Usenet or updated
     copies of the files in this distribution used to
     create the object code or executable.

  4.You may not copy, sublicense, distribute or
     transfer NetHack except as expressly
     provided under this License Agreement. Any
     attempt otherwise to copy, sublicense,
     distribute or transfer NetHack is void and
     your rights to use the program under this
     License agreement shall be automatically
     terminated. However, parties who have
     received computer software programs from
     you with this License Agreement will not have
     their licenses terminated so long as such
     parties remain in full compliance. 

Stated plainly: You are permitted to modify
NetHack, or otherwise use parts of NetHack,
provided that you comply with the conditions
specified above; in particular, your modified
NetHack or program containing parts of NetHack
must remain freely available as provided in this
License Agreement. In other words, go ahead and
share NetHack, but don't try to stop anyone else
from sharing it farther.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Nokia

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Nokia_1_0a {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Nokia Open Source License (NOKOS License) Version 1.0a

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Nokia Open Source License (NOKOS License) Version 1.0a

1. DEFINITIONS. 

"Affiliates" of a party shall mean an entity 
a) which is directly or indirectly controlling such party; 
b) which is under the same direct or indirect ownership or
control as such party; or 
c) which is directly or indirectly owned or controlled by such
party. 
For these purposes, an entity shall be treated as being
controlled by another if that other entity has fifty percent
(50%) or more of the votes in such entity, is able to direct its
affairs and/or to control the composition of its board of
directors or equivalent body. 

"Commercial Use" shall mean distribution or otherwise
making the Covered Software available to a third party. 

"Contributor" shall mean each entity that creates or
contributes to the creation of Modifications. 

"Contributor Version" shall mean in case of any
Contributor the combination of the Original Software, prior
Modifications used by a Contributor, and the Modifications
made by that particular Contributor  and in case of Nokia in
addition the Original Software in any form, including the form
as Exceutable. 

"Covered Software" shall mean the Original Software or
Modifications or the combination of the Original Software and
Modifications, in each case including portions thereof. 

"Electronic Distribution Mechanism" shall mean a
mechanism generally accepted in the software development
community for the electronic transfer of data. 

"Executable" shall mean Covered Software in any form
other than Source Code. 

"Nokia" shall mean Nokia Corporation and its Affiliates. 

"Larger Work" shall mean a work, which combines Covered
Software or portions thereof with code not governed by the
terms of this License. 

"License" shall mean this document. 

"Licensable" shall mean having the right to grant, to the
maximum extent possible, whether at the time of the initial
grant or subsequently acquired, any and all of the rights
conveyed herein. 

"Modifications" shall mean any addition to or deletion from
the substance or structure of either the Original Software or
any previous Modifications. When Covered Software is
released as a series of files, a Modification is: 
a) Any addition to or deletion from the contents of a file
containing Original Software or previous Modifications. 
b) Any new file that contains any part of the Original
Software or previous Modifications. 

"Original Software" shall mean the Source Code of
computer software code which is described in the Source
Code notice required by Exhibit A as Original Software, and
which, at the time of its release under this License is not
already Covered Software governed by this License. 

"Patent Claims" shall mean any patent claim(s), now
owned or hereafter acquired, including without limitation,
method, process, and apparatus claims, in any patent
Licensable by grantor. 

"Source Code" shall mean the preferred form of the Covered
Software for making modifications to it, including all modules
it contains, plus any associated interface definition files,
scripts used to control compilation and installation of an
Executable, or source code differential comparisons against
either the Original Software or another well known, available
Covered Software of the Contributor's choice. The Source
Code can be in a compressed or archival form, provided the
appropriate decompression or de-archiving software is widely
available for no charge. 

"You" (or "Your") shall mean an individual or a legal entity
exercising rights under, and complying with all of the terms
of, this License or a future version of this License issued
under Section 6.1. For legal entities, "You" includes Affiliates
of such entity. 

2. SOURCE CODE LICENSE. 

2.1 Nokia Grant. 
Subject to the terms of this License, Nokia hereby grants
You a world-wide, royalty-free, non-exclusive license, subject
to third party intellectual property claims: 

a) under copyrights Licensable by Nokia to use, reproduce,
modify, display, perform, sublicense and distribute the
Original Software (or portions thereof) with or without
Modifications, and/or as part of a Larger Work; 

b) and under Patents Claims necessarily infringed by the
making, using or selling of Original Software, to make, have
made, use, practice, sell, and offer for sale, and/or otherwise
dispose of the Original Software (or portions thereof). 

c) The licenses granted in this Section 2.1(a) and (b) are
effective on the date Nokia first distributes Original Software
under the terms of this License. 

d) Notwithstanding Section 2.1(b) above, no patent license is
granted: 1) for code that You delete from the Original
Software; 2) separate from the Original Software; or 3) for
infringements caused by: i) the modification of the Original
Software or ii) the combination of the Original Software with
other software or devices. 

2.2 Contributor Grant. 
Subject to the terms of this License and subject to third
party intellectual property claims, each Contributor hereby
grants You a world-wide, royalty-free, non-exclusive license: 

a) under copyrights Licensable by Contributor, to use,
reproduce, modify, display, perform, sublicense and
distribute the Modifications created by such Contributor (or
portions thereof) either on an unmodified basis, with other
Modifications, as Covered Software and/or as part of a Larger
Work; and 

b) under Patent Claims necessarily infringed by the making,
using, or selling of Modifications made by that Contributor
either alone and/or in combination with its Contributor
Version (or portions of such combination), to make, use,
sell, offer for sale, have made, and/or otherwise dispose of:
1) Modifications made by that Contributor (or portions
thereof); and 2) the combination of Modifications made by
that Contributor with its Contributor Version (or portions of
such combination). 

c) The licenses granted in Sections 2.2(a) and 2.2(b) are
effective on the date Contributor first makes Commercial Use
of the Covered Software. 

d) Notwithstanding Section 2.2(b) above, no patent license is
granted: 1) for any code that Contributor has deleted from the
Contributor Version; 2) separate from the Contributor
Version; 3) for infringements caused by: i) third party
modifications of Contributor Version or ii) the combination of
Modifications made by that Contributor with other software
(except as part of the Contributor Version) or other devices;
or 4) under Patent Claims infringed by Covered Software in
the absence of Modifications made by that Contributor. 

3. DISTRIBUTION OBLIGATIONS. 

3.1 Application of License. 
The Modifications which You create or to which You
contribute are governed by the terms of this License,
including without limitation Section 2.2. The Source Code
version of Covered Software may be distributed only under
the terms of this License or a future version of this License
released under Section 6.1, and You must include a copy of
this License with every copy of the Source Code You
distribute. You may not offer or impose any terms on any
Source Code version that alters or restricts the applicable
version of this License or the recipients' rights hereunder.
However, You may include an additional document offering
the additional rights described in Section 3.5. 

3.2 Availability of Source Code. 
Any Modification which You create or to which You
contribute must be made available in Source Code form
under the terms of this License either on the same media as
an Executable version or via an accepted Electronic
Distribution Mechanism to anyone to whom you made an
Executable version available; and if made available via
Electronic Distribution Mechanism, must remain available for
at least twelve (12) months after the date it initially became
available, or at least six (6) months after a subsequent
version of that particular Modification has been made
available to such recipients. You are responsible for ensuring
that the Source Code version remains available even if the
Electronic Distribution Mechanism is maintained by a third
party. 

3.3 Description of Modifications. 
You must cause all Covered Software to which You
contribute to contain a file documenting the changes You
made to create that Covered Software and the date of any
change. You must include a prominent statement that the
Modification is derived, directly or indirectly, from Original
Software provided by Nokia and including the name of Nokia
in (a) the Source Code, and (b) in any notice in an
Executable version or related documentation in which You
describe the origin or ownership of the Covered Software. 

3.4  Intellectual Property Matters 

a) Third Party Claims. 
If Contributor has knowledge that a license under a third
party's intellectual property rights is required to exercise the
rights granted by such Contributor under Sections 2.1 or 2.2,
Contributor must include a text file with the Source Code
distribution titled "LEGAL'' which describes the claim and the
party making the claim in sufficient detail that a recipient will
know whom to contact. If Contributor obtains such
knowledge after the Modification is made available as
described in Section 3.2, Contributor shall promptly modify
the LEGAL file in all copies Contributor makes available
thereafter and shall take other steps (such as notifying
appropriate mailing lists or newsgroups) reasonably
calculated to inform those who received the Covered
Software that new knowledge has been obtained. 

b) Contributor APIs. 
If Contributor's Modifications include an application
programming interface and Contributor has knowledge of
patent licenses which are reasonably necessary to
implement that API, Contributor must also include this
information in the LEGAL file. 

c) Representations. 
Contributor represents that, except as disclosed pursuant to
Section 3.4(a) above, Contributor believes that Contributor's
Modifications are Contributor's original creation(s) and/or
Contributor has sufficient rights to grant the rights conveyed
by this License. 

3.5 Required Notices. 
You must duplicate the notice in Exhibit A in each file of the
Source Code. If it is not possible to put such notice in a
particular Source Code file due to its structure, then You
must include such notice in a location (such as a relevant
directory) where a user would be likely to look for such a
notice. If You created one or more Modification(s) You may
add your name as a Contributor to the notice described in
Exhibit A. You must also duplicate this License in any
documentation for the Source Code where You describe
recipients' rights or ownership rights relating to Covered
Software. You may choose to offer, and to charge a fee for,
warranty, support, indemnity or liability obligations to one or
more recipients of Covered Software. However, You may do
so only on Your own behalf, and not on behalf of Nokia or
any Contributor. You must make it absolutely clear that any
such warranty, support, indemnity or liability obligation is
offered by You alone, and You hereby agree to indemnify
Nokia and every Contributor for any liability incurred by Nokia
or such Contributor as a result of warranty, support,
indemnity or liability terms You offer. 

3.6 Distribution of Executable Versions. 
You may distribute Covered Software in Executable form
only if the requirements of Section 3.1-3.5 have been met for
that Covered Software, and if You include a notice stating
that the Source Code version of the Covered Software is
available under the terms of this License, including a
description of how and where You have fulfilled the
obligations of Section 3.2. The notice must be conspicuously
included in any notice in an Executable version, related
documentation or collateral in which You describe recipients'
rights relating to the Covered Software. You may distribute
the Executable version of Covered Software or ownership
rights under a license of Your choice, which may contain
terms different from this License, provided that You are in
compliance with the terms of this License and that the
license for the Executable version does not attempt to limit
or alter the recipient's rights in the Source Code version from
the rights set forth in this License. If You distribute the
Executable version under a different license You must make
it absolutely clear that any terms which differ from this
License are offered by You alone, not by Nokia or any
Contributor. You hereby agree to indemnify Nokia and every
Contributor for any liability incurred by Nokia or such
Contributor as a result of any such terms You offer. 

3.7 Larger Works. 
You may create a Larger Work by combining Covered
Software with other software not governed by the terms of
this License and distribute the Larger Work as a single
product. In such a case, You must make sure the
requirements of this License are fulfilled for the Covered
Software. 

4. INABILITY TO COMPLY DUE TO STATUTE OR
REGULATION. 

If it is impossible for You to comply with any of the terms of
this License with respect to some or all of the Covered
Software due to statute, judicial order, or regulation then You
must: (a) comply with the terms of this License to the
maximum extent possible; and (b) describe the limitations
and the code they affect. Such description must be included
in the LEGAL file described in Section 3.4 and must be
included with all distributions of the Source Code. 
Except to the extent prohibited by statute or regulation, such
description must be sufficiently detailed for a recipient of
ordinary skill to be able to understand it. 

5. APPLICATION OF THIS LICENSE. 

This License applies to code to which Nokia has attached
the notice in Exhibit A and to related Covered Software. 

6. VERSIONS OF THE LICENSE. 

6.1 New Versions. 
Nokia may publish revised and/or new versions of the
License from time to time. Each version will be given a
distinguishing version number. 

6.2 Effect of New Versions. 
Once Covered Software has been published under a
particular version of the License, You may always continue
to use it under the terms of that version. You may also
choose to use such Covered Software under the terms of any
subsequent version of the License published by Nokia. No
one other than Nokia has the right to modify the terms
applicable to Covered Software created under this License. 

7. DISCLAIMER OF WARRANTY. 

COVERED SOFTWARE IS PROVIDED UNDER THIS
LICENSE ON AN "AS IS'' BASIS, WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, WITHOUT LIMITATION, WARRANTIES THAT
THE COVERED SOFTWARE IS FREE OF DEFECTS,
MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE OR
NON-INFRINGING. THE ENTIRE RISK AS TO THE QUALITY
AND PERFORMANCE OF THE COVERED SOFTWARE IS
WITH YOU. SHOULD ANY COVERED SOFTWARE PROVE
DEFECTIVE IN ANY RESPECT, YOU (NOT NOKIA, ITS
LICENSORS OR AFFILIATES OR ANY OTHER
CONTRIBUTOR) ASSUME THE COST OF ANY
NECESSARY SERVICING, REPAIR OR CORRECTION.
THIS DISCLAIMER OF  WARRANTY CONSTITUTES AN
ESSENTIAL PART OF THIS LICENSE. NO USE OF ANY
COVERED SOFTWARE IS AUTHORIZED HEREUNDER
EXCEPT UNDER THIS DISCLAIMER. 

8. TERMINATION. 

8.1 This License and the rights granted hereunder will
terminate automatically if You fail to comply with terms
herein and fail to cure such breach within 30 days of
becoming aware of the breach. All sublicenses to the
Covered Software which are properly granted shall survive
any termination of this License. Provisions which, by their
nature, must remain in effect beyond the termination of this
License shall survive. 

8.2 If You initiate litigation by asserting a patent infringement
claim (excluding declatory judgment actions) against Nokia
or a Contributor (Nokia or Contributor against whom You file
such action is referred to as "Participant") alleging that: 

a) such Participant's Contributor Version directly or indirectly
infringes any patent, then any and all rights granted by such
Participant to You under Sections 2.1 and/or 2.2 of this
License shall, upon 60 days notice from Participant
terminate prospectively, unless if within 60 days after receipt
of notice You either: (i) agree in writing to pay Participant a
mutually agreeable reasonable royalty for Your past and
future use of Modifications made by such Participant, or (ii)
withdraw Your litigation claim with respect to the Contributor
Version against such Participant. If within 60 days of notice,
a reasonable royalty and payment arrangement are not
mutually agreed upon in writing by the parties or the litigation
claim is not withdrawn, the rights granted by Participant to
You under Sections 2.1 and/or 2.2 automatically terminate at
the expiration of the 60 day notice period specified above. 

b) any software, hardware, or device, other than such
Participant's Contributor Version, directly or indirectly
infringes any patent, then any rights granted to You by such
Participant under Sections 2.1(b) and 2.2(b) are revoked
effective as of the date You first made, used, sold,
distributed, or had made, Modifications made by that
Participant. 

8.3 If You assert a patent infringement claim against
Participant alleging that such Participant's Contributor
Version directly or indirectly infringes any patent where such
claim is resolved (such as by license or settlement) prior to
the initiation of patent infringement litigation, then the
reasonable value of the licenses granted by such Participant
under Sections 2.1 or 2.2 shall be taken into account in
determining the amount or value of any payment or license. 
8.4 In the event of termination under Sections 8.1 or 8.2
above, all end user license agreements (excluding
distributors and resellers) which have been validly granted by
You or any distributor hereunder prior to termination shall
survive termination. 

9. LIMITATION OF LIABILITY. 

UNDER NO CIRCUMSTANCES AND UNDER NO LEGAL
THEORY, WHETHER TORT (INCLUDING NEGLIGENCE),
CONTRACT, OR OTHERWISE, SHALL YOU, NOKIA, ANY
OTHER CONTRIBUTOR, OR ANY DISTRIBUTOR OF
COVERED SOFTWARE, OR ANY SUPPLIER OF ANY OF
SUCH PARTIES, BE LIABLE TO ANY PERSON FOR ANY
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES OF ANY CHARACTER INCLUDING, WITHOUT
LIMITATION, DAMAGES FOR LOSS OF GOODWILL,
WORK STOPPAGE, COMPUTER FAILURE OR
MALFUNCTION, OR ANY AND ALL OTHER COMMERCIAL
DAMAGES OR LOSSES, EVEN IF SUCH PARTY SHALL
HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH
DAMAGES. THIS LIMITATION OF LIABILITY SHALL NOT
APPLY TO LIABILITY FOR DEATH OR PERSONAL INJURY
RESULTING FROM SUCH PARTY'S NEGLIGENCE TO THE
EXTENT APPLICABLE LAW PROHIBITS SUCH
LIMITATION. SOME JURISDICTIONS DO NOT ALLOW THE
EXCLUSION OR LIMITATION OF INCIDENTAL OR
CONSEQUENTIAL DAMAGES, BUT MAY ALLOW
LIABILITY TO BE LIMITED; IN SUCH CASES, A PARTY's,
ITS EMPLOYEES, LICENSORS OR AFFILIATES' LIABILITY
SHALL BE LIMITED TO U.S. \$50. Nothing contained in this
License shall prejudice the statutory rights of any party
dealing as a consumer. 

10. MISCELLANEOUS. 

This License represents the complete agreement concerning
subject matter hereof. All rights in the Covered Software not
expressly granted under this License are reserved. Nothing
in this License shall grant You any rights to use any of the
trademarks of Nokia or any of its Affiliates, even if any of
such trademarks are included in any part of Covered
Software and/or documentation to it. 
This License is governed by the laws of Finland excluding its
conflict-of-law provisions. All disputes arising from or relating
to this Agreement shall be settled by a single arbitrator
appointed by the Central Chamber of Commerce of Finland.
The arbitration procedure shall take place in Helsinki, Finland
in the English language. If any part of this Agreement is
found void and unenforceable, it will not affect the validity of
the balance of the Agreement, which shall remain valid and
enforceable according to its terms. 

11. RESPONSIBILITY FOR CLAIMS. 

As between Nokia and the Contributors, each party is
responsible for claims and damages arising, directly or
indirectly, out of its utilization of rights under this License
and You agree to work with Nokia and Contributors to
distribute such responsibility on an equitable basis. Nothing
herein is intended or shall be deemed to constitute any
admission of liability. 
  

EXHIBIT A 

The contents of this file are subject to the NOKOS License
Version 1.0 (the "License"); you may not use this file except
in compliance with the License. 

Software distributed under the License is distributed on an
"AS IS" basis, WITHOUT WARRANTY OF  ANY KIND,
either express or implied. See the License for the specific
language governing rights and limitations under the License. 

The Original Software is 
______________________________________. 

Copyright © <year> Nokia and others. All Rights
Reserved. 

Contributor(s):
______________________________________. 
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Python

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Python {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Python License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Python License

     CNRI OPEN SOURCE LICENSE AGREEMENT

IMPORTANT: PLEASE READ THE FOLLOWING
AGREEMENT CAREFULLY.

BY CLICKING ON "ACCEPT" WHERE INDICATED BELOW,
OR BY COPYING, INSTALLING OR OTHERWISE USING
PYTHON 1.6, beta 1 SOFTWARE, YOU ARE DEEMED TO
HAVE AGREED TO THE TERMS AND CONDITIONS OF
THIS LICENSE AGREEMENT.

1. This LICENSE AGREEMENT is between the Corporation
for National Research Initiatives, having an office at 1895
Preston White Drive, Reston, VA 20191 ("CNRI"), and the
Individual or Organization ("Licensee") accessing and
otherwise using Python 1.6, beta 1 software in source or
binary form and its associated documentation, as released
at the www.python.org Internet site on August 4, 2000
("Python 1.6b1").

2. Subject to the terms and conditions of this License
Agreement, CNRI hereby grants Licensee a non-exclusive,
royalty-free, world-wide license to reproduce, analyze, test,
perform and/or display publicly, prepare derivative works,
distribute, and otherwise use Python 1.6b1 alone or in any
derivative version, provided, however, that CNRI’s License
Agreement is retained in Python 1.6b1, alone or in any
derivative version prepared by Licensee.

Alternately, in lieu of CNRI’s License Agreement, Licensee
may substitute the following text (omitting the quotes):
"Python 1.6, beta 1, is made available subject to the terms
and conditions in CNRI’s License Agreement. This
Agreement may be located on the Internet using the
following unique, persistent identifier (known as a handle):
1895.22/1011. This Agreement may also be obtained from a
proxy server on the Internet using the
URL:http://hdl.handle.net/1895.22/1011".

3. In the event Licensee prepares a derivative work that is
based on or incorporates Python 1.6b1or any part thereof,
and wants to make the derivative work available to the public
as provided herein, then Licensee hereby agrees to indicate
in any such work the nature of the modifications made to
Python 1.6b1.

4. CNRI is making Python 1.6b1 available to Licensee on an
"AS IS" basis. CNRI MAKES NO REPRESENTATIONS OR
WARRANTIES, EXPRESS OR IMPLIED. BY WAY OF
EXAMPLE, BUT NOT LIMITATION, CNRI MAKES NO AND
DISCLAIMS ANY REPRESENTATION OR WARRANTY OF
MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR
PURPOSE OR THAT THE USE OF PYTHON 1.6b1WILL
NOT INFRINGE ANY THIRD PARTY RIGHTS.

5. CNRI SHALL NOT BE LIABLE TO LICENSEE OR ANY
OTHER USERS OF THE SOFTWARE FOR ANY
INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES
OR LOSS AS A RESULT OF USING, MODIFYING OR
DISTRIBUTING PYTHON 1.6b1, OR ANY DERIVATIVE
THEREOF, EVEN IF ADVISED OF THE POSSIBILITY
THEREOF. 

6. This License Agreement will automatically terminate upon
a material breach of its terms and conditions.

7. This License Agreement shall be governed by and
interpreted in all respects by the law of the State of Virginia,
excluding conflict of law provisions. Nothing in this License
Agreement shall be deemed to create any relationship of
agency, partnership, or joint venture between CNRI and
Licensee. This License Agreement does not grant
permission to use CNRI trademarks or trade name in a
trademark sense to endorse or promote products or services
of Licensee, or any third party.

8. By clicking on the "ACCEPT" button where indicated, or
by copying, installing or otherwise using Python 1.6b1,
Licensee agrees to be bound by the terms and conditions of
this License Agreement.

                  ACCEPT
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Q

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Q_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The Q Public License
	Version 1.0

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The Q Public License
Version 1.0

Copyright (C) 1999 Trolltech AS, Norway.
Everyone is permitted to copy and distribute this license
document. 

The intent of this license is to establish freedom to share and
change the software regulated by this license under the open
source model.

This license applies to any software containing a notice
placed by the copyright holder saying that it may be
distributed under the terms of the Q Public License version
1.0. Such software is herein referred to as the Software. This
license covers modification and distribution of the Software,
use of third-party application programs based on the
Software, and development of free software which uses the
Software.

           Granted Rights

1. You are granted the non-exclusive rights set forth in this
license provided you agree to and comply with any and all
conditions in this license. Whole or partial distribution of the
Software, or software items that link with the Software, in
any form signifies acceptance of this license.

2. You may copy and distribute the Software in unmodified
form provided that the entire package, including - but not
restricted to - copyright, trademark notices and disclaimers,
as released by the initial developer of the Software, is
distributed.

3. You may make modifications to the Software and
distribute your modifications, in a form that is separate from
the Software, such as patches. The following restrictions
apply to modifications:

     a. Modifications must not alter or remove any
     copyright notices in the Software.

     b. When modifications to the Software are
     released under this license, a non-exclusive
     royalty-free right is granted to the initial
     developer of the Software to distribute your
     modification in future versions of the Software
     provided such versions remain available under
     these terms in addition to any other license(s)
     of the initial developer.

4. You may distribute machine-executable forms of the
Software or machine-executable forms of modified versions of
the Software, provided that you meet these restrictions:

     a. You must include this license document in
     the distribution.

     b. You must ensure that all recipients of the
     machine-executable forms are also able to
     receive the complete machine-readable source
     code to the distributed Software, including all
     modifications, without any charge beyond the
     costs of data transfer, and place prominent
     notices in the distribution explaining this.

     c. You must ensure that all modifications
     included in the machine-executable forms are
     available under the terms of this license.

5. You may use the original or modified versions of the
Software to compile, link and run application programs
legally developed by you or by others.

6. You may develop application programs, reusable
components and other software items that link with the
original or modified versions of the Software. These items,
when distributed, are subject to the following requirements:

     a. You must ensure that all recipients of
     machine-executable forms of these items are
     also able to receive and use the complete
     machine-readable source code to the items
     without any charge beyond the costs of data
     transfer.

     b. You must explicitly license all recipients of
     your items to use and re-distribute original and
     modified versions of the items in both
     machine-executable and source code forms.
     The recipients must be able to do so without
     any charges whatsoever, and they must be
     able to re-distribute to anyone they choose.

     c. If the items are not available to the general
     public, and the initial developer of the Software
     requests a copy of the items, then you must
     supply one.

      Limitations of Liability

In no event shall the initial developers or copyright holders be
liable for any damages whatsoever, including - but not
restricted to - lost revenue or profits or other direct, indirect,
special, incidental or consequential damages, even if they
have been advised of the possibility of such damages,
except to the extent invariable law, if any, provides
otherwise.

             No Warranty

The Software and this license document are provided AS IS
with NO WARRANTY OF ANY KIND, INCLUDING THE
WARRANTY OF DESIGN, MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

           Choice of Law

This license is governed by the Laws of Norway. Disputes
shall be settled by Oslo City Court.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Ricoh

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Ricoh_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Ricoh Source Code Public License (Version 1.0)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Ricoh Source Code Public License (Version 1.0)

1. Definitions. 

1.1. "Contributor" means each entity that creates or
contributes to the creation of Modifications. 

1.2. "Contributor Version" means the combination of the
Original Code, prior Modifications used by a Contributor, and
the Modifications made by that particular Contributor. 

1.3. "Electronic Distribution Mechanism" means a
website or any other mechanism generally accepted in the
software development community for the electronic transfer
of data. 

1.4. "Executable Code" means Governed Code in any form
other than Source Code. 

1.5. "Governed Code" means the Original Code or
Modifications or the combination of the Original Code and
Modifications, in each case including portions thereof. 

1.6. "Larger Work" means a work which combines
Governed Code or portions thereof with code not governed by
the terms of this License. 

1.7. "Licensable" means the right to grant, to the maximum
extent possible, whether at the time of the initial grant or
subsequently acquired, any and all of the rights conveyed
herein.

1.8. "License" means this document. 

1.9. "Modifications" means any addition to or deletion from
the substance or structure of either the Original Code or any
previous Modifications. When Governed Code is released as
a series of files, a Modification is: 

          (a) Any addition to or deletion from the
          contents of a file containing Original Code or
          previous Modifications. 

          (b) Any new file that contains any part of the
          Original Code or previous Modifications. 

1.10. "Original Code" means the "Platform for Information
Applications" Source Code as released under this License
by RSV. 

1.11 "Patent Claims" means any patent claim(s), now
owned or hereafter acquired, including without limitation,
method, process, and apparatus claims, in any patent
Licensable by the grantor of a license thereto. 

1.12. "RSV" means Ricoh Silicon Valley, Inc., a California
corporation with offices at 2882 Sand Hill Road, Suite 115,
Menlo Park, CA 94025-7022.

1.13. "Source Code" means the preferred form of the
Governed Code for making modifications to it, including all
modules it contains, plus any associated interface definition
files, scripts used to control compilation and installation of
Executable Code, or a list of source code differential
comparisons against either the Original Code or another well
known, available Governed Code of the Contributor's choice.
The Source Code can be in a compressed or archival form,
provided the appropriate decompression or de-archiving
software is widely available for no charge. 

1.14. "You" means an individual or a legal entity exercising
rights under, and complying with all of the terms of, this
License or a future version of this License issued under
Section 6.1. For legal entities, "You" includes any entity
which controls, is controlled by, or is under common control
with You. For purposes of this definition, "control" means (a)
the power, direct or indirect, to cause the direction or
management of such entity, whether by contract or
otherwise, or (b) ownership of fifty percent (50%) or more of
the outstanding shares or beneficial ownership of such
entity. 

2. Source Code License. 

2.1. Grant from RSV. RSV hereby grants You a worldwide,
royalty-free, non-exclusive license, subject to third party
intellectual property claims: 

          (a) to use, reproduce, modify, create derivative
          works of, display, perform, sublicense and
          distribute the Original Code (or portions
          thereof) with or without Modifications, or as
          part of a Larger Work; and 

          (b) under Patent Claims infringed by the
          making, using or selling of Original Code, to
          make, have made, use, practice, sell, and offer
          for sale, and/or otherwise dispose of the
          Original Code (or portions thereof). 

2.2. Contributor Grant. Each Contributor hereby grants You
a worldwide, royalty-free, non-exclusive license, subject to
third party intellectual property claims: 

          (a) to use, reproduce, modify, create derivative
          works of, display, perform, sublicense and
          distribute the Modifications created by such
          Contributor (or portions thereof) either on an
          unmodified basis, with other Modifications, as
          Governed Code or as part of a Larger Work;
          and 

          (b) under Patent Claims infringed by the
          making, using, or selling of Modifications made
          by that Contributor either alone and/or in
          combination with its Contributor Version (or
          portions of such combination), to make, use,
          sell, offer for sale, have made, and/or otherwise
          dispose of: (i) Modifications made by that
          Contributor (or portions thereof); and (ii) the
          combination of Modifications made by that
          Contributor with its Contributor Version (or
          portions of such combination). 

3. Distribution Obligations. 

3.1. Application of License. The Modifications which You
create or to which You contribute are governed by the terms
of this License, including without limitation Section 2.2. The
Source Code version of Governed Code may be distributed
only under the terms of this License or a future version of this
License released under Section 6.1, and You must include a
copy of this License with every copy of the Source Code You
distribute. You may not offer or impose any terms on any
Source Code version that alters or restricts the applicable
version of this License or the recipients' rights hereunder.
However, You may include an additional document offering
the additional rights described in Section 3.5. 

3.2. Availability of Source Code. Any Modification which
You create or to which You contribute must be made
available in Source Code form under the terms of this
License either on the same media as an Executable Code
version or via an Electronic Distribution Mechanism to
anyone to whom you made an Executable Code version
available; and if made available via an Electronic Distribution
Mechanism, must remain available for at least twelve (12)
months after the date it initially became available, or at least
six (6) months after a subsequent version of that particular
Modification has been made available to such recipients.
You are responsible for ensuring that the Source Code
version remains available even if the Electronic Distribution
Mechanism is maintained by a third party. 

3.3. Description of Modifications. You must cause all
Governed Code to which you contribute to contain a file
documenting the changes You made to create that Governed
Code and the date of any change. You must include a
prominent statement that the Modification is derived, directly
or indirectly, from Original Code provided by RSV and
including the name of RSV in (a) the Source Code, and (b) in
any notice in an Executable Code version or related
documentation in which You describe the origin or ownership
of the Governed Code. 

3.4. Intellectual Property Matters. 

3.4.1. Third Party Claims. If You have knowledge that a
party claims an intellectual property right in particular
functionality or code (or its utilization under this License),
you must include a text file with the source code distribution
titled "LEGAL" which describes the claim and the party
making the claim in sufficient detail that a recipient will know
whom to contact. If you obtain such knowledge after You
make Your Modification available as described in Section
3.2, You shall promptly modify the LEGAL file in all copies
You make available thereafter and shall take other steps
(such as notifying RSV and appropriate mailing lists or
newsgroups) reasonably calculated to inform those who
received the Governed Code that new knowledge has been
obtained. In the event that You are a Contributor, You
represent that, except as disclosed in the LEGAL file, your
Modifications are your original creations and, to the best of
your knowledge, no third party has any claim (including but
not limited to intellectual property claims) relating to your
Modifications. You represent that the LEGAL file includes
complete details of any license or other restriction
associated with any part of your Modifications. 

3.4.2. Contributor APIs. If Your Modification is an
application programming interface and You own or control
patents which are reasonably necessary to implement that
API, you must also include this information in the LEGAL
file. 

3.5. Required Notices. You must duplicate the notice in
Exhibit A in each file of the Source Code, and this License in
any documentation for the Source Code, where You describe
recipients' rights relating to Governed Code. If You created
one or more Modification(s), You may add your name as a
Contributor to the notice described in Exhibit A. If it is not
possible to put such notice in a particular Source Code file
due to its structure, then you must include such notice in a
location (such as a relevant directory file) where a user would
be likely to look for such a notice. You may choose to offer,
and to charge a fee for, warranty, support, indemnity or
liability obligations to one or more recipients of Governed
Code. However, You may do so only on Your own behalf,
and not on behalf of RSV or any Contributor. You must make
it absolutely clear than any such warranty, support,
indemnity or liability obligation is offered by You alone, and
You hereby agree to indemnify RSV and every Contributor for
any liability incurred by RSV or such Contributor as a result
of warranty, support, indemnity or liability terms You offer. 

3.6. Distribution of Executable Code Versions. You may
distribute Governed Code in Executable Code form only if the
requirements of Section 3.1-3.5 have been met for that
Governed Code, and if You include a prominent notice
stating that the Source Code version of the Governed Code is
available under the terms of this License, including a
description of how and where You have fulfilled the
obligations of Section 3.2. The notice must be conspicuously
included in any notice in an Executable Code version, related
documentation or collateral in which You describe recipients'
rights relating to the Governed Code. You may distribute the
Executable Code version of Governed Code under a license
of Your choice, which may contain terms different from this
License, provided that You are in compliance with the terms
of this License and that the license for the Executable Code
version does not attempt to limit or alter the recipient's rights
in the Source Code version from the rights set forth in this
License. If You distribute the Executable Code version under
a different license You must make it absolutely clear that
any terms which differ from this License are offered by You
alone, not by RSV or any Contributor. You hereby agree to
indemnify RSV and every Contributor for any liability incurred
by RSV or such Contributor as a result of any such terms
You offer. 

3.7. Larger Works. You may create a Larger Work by
combining Governed Code with other code not governed by
the terms of this License and distribute the Larger Work as a
single product. In such a case, You must make sure the
requirements of this License are fulfilled for the Governed
Code. 

4. Inability to Comply Due to Statute or Regulation. 

If it is impossible for You to comply with any of the terms of
this License with respect to some or all of the Governed
Code due to statute or regulation then You must: (a) comply
with the terms of this License to the maximum extent
possible; and (b) describe the limitations and the code they
affect. Such description must be included in the LEGAL file
described in Section 3.4 and must be included with all
distributions of the Source Code. Except to the extent
prohibited by statute or regulation, such description must be
sufficiently detailed for a recipient of ordinary skill to be able
to understand it. 

5. Trademark Usage. 

5.1. Advertising Materials. All advertising materials
mentioning features or use of the Governed Code must
display the following acknowledgement: "This product
includes software developed by Ricoh Silicon Valley, Inc."

5.2. Endorsements. The names "Ricoh," "Ricoh Silicon
Valley," and "RSV" must not be used to endorse or promote
Contributor Versions or Larger Works without the prior
written permission of RSV.

5.3. Product Names. Contributor Versions and Larger
Works may not be called "Ricoh" nor may the word "Ricoh"
appear in their names without the prior written permission of
RSV.

6. Versions of the License. 

6.1. New Versions. RSV may publish revised and/or new
versions of the License from time to time. Each version will
be given a distinguishing version number. 

6.2. Effect of New Versions. Once Governed Code has
been published under a particular version of the License, You
may always continue to use it under the terms of that
version. You may also choose to use such Governed Code
under the terms of any subsequent version of the License
published by RSV. No one other than RSV has the right to
modify the terms applicable to Governed Code created under
this License. 

7. Disclaimer of Warranty. 

GOVERNED CODE IS PROVIDED UNDER THIS LICENSE
ON AN "AS IS" BASIS, WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
WITHOUT LIMITATION, WARRANTIES THAT THE
GOVERNED CODE IS FREE OF DEFECTS,
MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE OR
NON-INFRINGING. THE ENTIRE RISK AS TO THE QUALITY
AND PERFORMANCE OF THE GOVERNED CODE IS
WITH YOU. SHOULD ANY GOVERNED CODE PROVE
DEFECTIVE IN ANY RESPECT, YOU (NOT RSV OR ANY
OTHER CONTRIBUTOR) ASSUME THE COST OF ANY
NECESSARY SERVICING, REPAIR OR CORRECTION.
THIS DISCLAIMER OF WARRANTY CONSTITUTES AN
ESSENTIAL PART OF THIS LICENSE. NO USE OF ANY
GOVERNED CODE IS AUTHORIZED HEREUNDER
EXCEPT UNDER THIS DISCLAIMER. 

8. Termination. 

8.1. This License and the rights granted hereunder will
terminate automatically if You fail to comply with terms
herein and fail to cure such breach within 30 days of
becoming aware of the breach. All sublicenses to the
Governed Code which are properly granted shall survive any
termination of this License. Provisions which, by their nature,
must remain in effect beyond the termination of this License
shall survive.

8.2. If You initiate patent infringement litigation against RSV
or a Contributor (RSV or the Contributor against whom You
file such action is referred to as "Participant") alleging that: 

          (a) such Participant's Original Code or
          Contributor Version directly or indirectly
          infringes any patent, then any and all rights
          granted by such Participant to You under
          Sections 2.1 and/or 2.2 of this License shall,
          upon 60 days notice from Participant terminate
          prospectively, unless if within 60 days after
          receipt of notice You either: (i) agree in writing
          to pay Participant a mutually agreeable
          reasonable royalty for Your past and future use
          of the Original Code or the Modifications made
          by such Participant, or (ii) withdraw Your
          litigation claim with respect to the Original
          Code or the Contributor Version against such
          Participant. If within 60 days of notice, a
          reasonable royalty and payment arrangement
          are not mutually agreed upon in writing by the
          parties or the litigation claim is not withdrawn,
          the rights granted by Participant to You under
          Sections 2.1 and/or 2.2 automatically
          terminate at the expiration of the 60 day notice
          period specified above. 

          (b) any software, hardware, or device provided
          to You by the Participant, other than such
          Participant's Original Code or Contributor
          Version, directly or indirectly infringes any
          patent, then any rights granted to You by such
          Participant under Sections 2.1(b) and 2.2(b)
          are revoked effective as of the date You first
          made, used, sold, distributed, or had made,
          Original Code or the Modifications made by
          that Participant. 

8.3. If You assert a patent infringement claim against
Participant alleging that such Participant's Original Code or
Contributor Version directly or indirectly infringes any patent
where such claim is resolved (such as by license or
settlement) prior to the initiation of patent infringement
litigation, then the reasonable value of the licenses granted
by such Participant under Sections 2.1 or 2.2 shall be taken
into account in determining the amount or value of any
payment or license. 

8.4. In the event of termination under Sections 8.1 or 8.2
above, all end user license agreements (excluding
distributors and resellers) which have been validly granted by
You or any distributor hereunder prior to termination shall
survive termination. 

9. Limitation of Liability. 

UNDER NO CIRCUMSTANCES AND UNDER NO LEGAL
THEORY, WHETHER TORT (INCLUDING NEGLIGENCE),
CONTRACT, OR OTHERWISE, SHALL RSV, ANY
CONTRIBUTOR, OR ANY DISTRIBUTOR OF GOVERNED
CODE, OR ANY SUPPLIER OF ANY OF SUCH PARTIES,
BE LIABLE TO YOU OR ANY OTHER PERSON FOR ANY
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES OF ANY CHARACTER
INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS
OF GOODWILL, WORK STOPPAGE, COMPUTER
FAILURE OR MALFUNCTION, OR ANY AND ALL OTHER
COMMERCIAL DAMAGES OR LOSSES, EVEN IF SUCH
PARTY SHALL HAVE BEEN INFORMED OF THE
POSSIBILITY OF SUCH DAMAGES. THIS LIMITATION OF
LIABILITY SHALL NOT APPLY TO LIABILITY FOR DEATH
OR PERSONAL INJURY RESULTING FROM SUCH
PARTY'S NEGLIGENCE TO THE EXTENT APPLICABLE
LAW PROHIBITS SUCH LIMITATION. SOME
JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR
LIMITATION OF INCIDENTAL OR CONSEQUENTIAL
DAMAGES, SO THAT EXCLUSION AND LIMITATION MAY
NOT APPLY TO YOU. TO THE EXTENT THAT ANY
EXCLUSION OF DAMAGES ABOVE IS NOT VALID, YOU
AGREE THAT IN NO EVENT WILL RSV’S LIABILITY
UNDER OR RELATED TO THIS AGREEMENT EXCEED
FIVE THOUSAND DOLLARS (\$5,000). THE GOVERNED
CODE IS NOT INTENDED FOR USE IN CONNECTION
WITH ANY NUCLEAR, AVIATION, MASS TRANSIT OR
MEDICAL APPLICATION OR ANY OTHER INHERENTLY
DANGEROUS APPLICATION THAT COULD RESULT IN
DEATH, PERSONAL INJURY, CATASTROPHIC DAMAGE
OR MASS DESTRUCTION, AND YOU AGREE THAT
NEITHER RSV NOR ANY CONTRIBUTOR SHALL HAVE
ANY LIABILITY OF ANY NATURE AS A RESULT OF ANY
SUCH USE OF THE GOVERNED CODE. 

10. U.S. Government End Users. 

The Governed Code is a "commercial item," as that term is
defined in 48 C.F.R. 2.101 (Oct. 1995), consisting of
"commercial computer software" and "commercial computer
software documentation," as such terms are used in 48
C.F.R. 12.212 (Sept. 1995). Consistent with 48 C.F.R.
12.212 and 48 C.F.R. 227.7202-1 through 227.7202-4 (June
1995), all U.S. Government End Users acquire Governed
Code with only those rights set forth herein. 

11. Miscellaneous. 

This License represents the complete agreement concerning
subject matter hereof. If any provision of this License is held
to be unenforceable, such provision shall be reformed only to
the extent necessary to make it enforceable. This License
shall be governed by California law provisions (except to the
extent applicable law, if any, provides otherwise), excluding
its conflict-of-law provisions. The parties submit to personal
jurisdiction in California and further agree that any cause of
action arising under or related to this Agreement shall be
brought in the Federal Courts of the Northern District of
California, with venue lying in Santa Clara County, California.
The losing party shall be responsible for costs, including
without limitation, court costs and reasonable attorneys’ fees
and expenses. Notwithstanding anything to the contrary
herein, RSV may seek injunctive relief related to a breach of
this Agreement in any court of competent jurisdiction. The
application of the United Nations Convention on Contracts for
the International Sale of Goods is expressly excluded. Any
law or regulation which provides that the language of a
contract shall be construed against the drafter shall not
apply to this License. 

12. Responsibility for Claims. 

Except in cases where another Contributor has failed to
comply with Section 3.4, You are responsible for damages
arising, directly or indirectly, out of Your utilization of rights
under this License, based on the number of copies of
Governed Code you made available, the revenues you
received from utilizing such rights, and other relevant factors.
You agree to work with affected parties to distribute
responsibility on an equitable basis. 

                      

                  EXHIBIT A

"The contents of this file are subject to the Ricoh Source
Code Public License Version 1.0 (the "License"); you may
not use this file except in compliance with the License. You
may obtain a copy of the License at
http://www.risource.org/RPL

Software distributed under the License is distributed on an
"AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either
express or implied. See the License for the specific language
governing rights and limitations under the License. 

This code was initially developed by Ricoh Silicon Valley,
Inc. Portions created by Ricoh Silicon Valley, Inc. are
Copyright (C) 1995-1999. All Rights Reserved.

Contributor(s):
______________________________________." 
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Sun

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Sun {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Sun Internet Standards Source License (SISSL)

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Sun Internet Standards Source License (SISSL)

1.0 DEFINITIONS 

1.1 "Commercial Use" means distribution or otherwise making the
Original Code available to a third party. 

1.2 "Contributor Version" means the combination of the Original
Code, and the Modifications made by that particular Contributor. 

1.3 "Electronic Distribution Mechanism" means a mechanism
generally accepted in the software development community for the
electronic transfer of data. 

1.4 "Executable" means Original Code in any form other than
Source Code. 

1.5 "Initial Developer" means the individual or entity identified as
the Initial Developer in the Source Code notice required by Exhibit
A. 

1.6 "Larger Work" means a work which combines Original Code or
portions thereof with code not governed by the terms of this License.

1.7 "License" means this document. 

1.8 "Licensable" means having the right to grant, to the maximum
extent possible, whether at the time of the initial grant or
subsequently acquired, any and all of the rights conveyed herein. 

1.9 "Modifications" means any addition to or deletion from the
substance or structure of either the Original Code or any previous
Modifications. A Modification is: 

     A. Any addition to or deletion from the contents of a file
     containing Original Code or previous Modifications. 

     B. Any new file that contains any part of the Original Code or
     previous Modifications.

1.10 "Original Code" means Source Code of computer software
code which is described in the Source Code notice required by
Exhibit A as Original Code. 

1.11 "Patent Claims" means any patent claim(s), now owned or
hereafter acquired, including without limitation, method, process,
and apparatus claims, in any patent Licensable by grantor. 

1.12 "Source Code" means the preferred form of the Original Code
for making modifications to it, including all modules it contains, plus
any associated interface definition files, or scripts used to control
compilation and installation of an Executable. 

1.13 "Standards" means the standards identified in Exhibit B. 

1.14 "You" (or "Your") means an individual or a legal entity
exercising rights under, and complying with all of the terms of, this
License or a future version of this License issued under Section 6.1.
For legal entities, "You'' includes any entity which controls, is
controlled by, or is under common control with You. For purposes of
this definition, "control'' means (a) the power, direct or indirect, to
cause the direction or management of such entity, whether by
contract or otherwise, or (b) ownership of more than fifty percent
(50%) of the outstanding shares or beneficial ownership of such
entity. 

2.0 SOURCE CODE LICENSE 

2.1 The Initial Developer Grant 
The Initial Developer hereby grants You a world-wide, royalty-free,
non-exclusive license, subject to third party intellectual property
claims:  

     (a) under intellectual property rights (other than patent or
     trademark) Licensable by Initial Developer to use, reproduce,
     modify, display, perform, sublicense and distribute the
     Original Code (or portions thereof) with or without
     Modifications, and/or as part of a Larger Work; and 

     (b) under Patents Claims infringed by the making, using or
     selling of Original Code, to make, have made, use, practice,
     sell, and offer for sale, and/or otherwise dispose of the
     Original Code (or portions thereof). 

     (c) the licenses granted in this Section 2.1(a) and (b) are
     effective on the date Initial Developer first distributes Original
     Code under the terms of this License. 

     (d) Notwithstanding Section 2.1(b) above, no patent license
     is granted: 1) for code that You delete from the Original
     Code; 2) separate from the Original Code; or 3) for
     infringements caused by: i) the modification of the Original
     Code or ii) the combination of the Original Code with other
     software or devices, including but not limited to
     Modifications. 

3.0 DISTRIBUTION OBLIGATIONS 

3.1 Application of License. 
The Source Code version of Original Code may be distributed only
under the terms of this License or a future version of this License
released under Section 6.1, and You must include a copy of this
License with every copy of the Source Code You distribute. You
may not offer or impose any terms on any Source Code version that
alters or restricts the applicable version of this License or the
recipients' rights hereunder. Your license for shipment of the
Contributor Version is conditioned upon Your full compliance with
this Section. The Modifications which You create must comply with
all requirements set out by the Standards body in effect one
hundred twenty (120) days before You ship the Contributor Version.
In the event that the Modifications do not meet such requirements,
You agree to publish either (i) any deviation from the Standards
protocol resulting from implementation of Your Modifications and a
reference implementation of Your Modifications or (ii) Your
Modifications in Source Code form, and to make any such deviation
and reference implementation or Modifications available to all third
parties under the same terms as this license on a royalty free basis
within thirty (30) days of Your first customer shipment of Your
Modifications. 

3.2 Required Notices. 
You must duplicate the notice in Exhibit A in each file of the
Source Code. If it is not possible to put such notice in a particular
Source Code file due to its structure, then You must include such
notice in a location (such as a relevant directory) where a user
would be likely to look for such a notice. If You created one or more
Modification(s) You may add Your name as a Contributor to the
notice described in Exhibit A. You must also duplicate this License
in any documentation for the Source Code where You describe
recipients' rights or ownership rights relating to Initial Code. You
may choose to offer, and to charge a fee for, warranty, support,
indemnity or liability obligations to one or more recipients of Your
version of the Code. However, You may do so only on Your own
behalf, and not on behalf of the Initial Developer. You must make it
absolutely clear than any such warranty, support, indemnity or
liability obligation is offered by You alone, and You hereby agree to
indemnify the Initial Developer for any liability incurred by the Initial
Developer as a result of warranty, support, indemnity or liability
terms You offer. 

3.3 Distribution of Executable Versions. 
You may distribute Original Code in Executable and Source form
only if the requirements of Sections 3.1 and 3.2 have been met for
that Original Code, and if You include a notice stating that the
Source Code version of the Original Code is available under the
terms of this License. The notice must be conspicuously included in
any notice in an Executable or Source versions, related
documentation or collateral in which You describe recipients' rights
relating to the Original Code. You may distribute the Executable and
Source versions of Your version of the Code or ownership rights
under a license of Your choice, which may contain terms different
from this License, provided that You are in compliance with the
terms of this License. If You distribute the Executable and Source
versions under a different license You must make it absolutely clear
that any terms which differ from this License are offered by You
alone, not by the Initial Developer. You hereby agree to indemnify
the Initial Developer for any liability incurred by the Initial Developer
as a result of any such terms You offer. 

3.4 Larger Works. 
You may create a Larger Work by combining Original Code with
other code not governed by the terms of this License and distribute
the Larger Work as a single product. In such a case, You must
make sure the requirements of this License are fulfilled for the
Original Code. 

4.0 INABILITY TO COMPLY DUE TO STATUTE OR REGULATION

If it is impossible for You to comply with any of the terms of this
License with respect to some or all of the Original Code due to
statute, judicial order, or regulation then You must: (a) comply with
the terms of this License to the maximum extent possible; and (b)
describe the limitations and the code they affect. Such description
must be included in the LEGAL file described in Section 3.2 and
must be included with all distributions of the Source Code. Except
to the extent prohibited by statute or regulation, such description
must be sufficiently detailed for a recipient of ordinary skill to be
able to understand it. 

5.0 APPLICATION OF THIS LICENSE 

This License applies to code to which the Initial Developer has
attached the notice in Exhibit A and to related Modifications as set
out in Section 3.1. 

6.0 VERSIONS OF THE LICENSE 

6.1 New Versions. 
Sun may publish revised and/or new versions of the License from
time to time. Each version will be given a distinguishing version
number. 

6.2 Effect of New Versions. 
Once Original Code has been published under a particular version of
the License, You may always continue to use it under the terms of
that version. You may also choose to use such Original Code under
the terms of any subsequent version of the License published by
Sun. No one other than Sun has the right to modify the terms
applicable to Original Code. 

7.0 DISCLAIMER OF WARRANTY 

ORIGINAL CODE IS PROVIDED UNDER THIS LICENSE ON AN
"AS IS" BASIS, WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, WITHOUT LIMITATION,
WARRANTIES THAT THE ORIGINAL CODE IS FREE OF
DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR
PURPOSE OR NON-INFRINGING. THE ENTIRE RISK AS TO THE
QUALITY AND PERFORMANCE OF THE ORIGINAL CODE IS
WITH YOU. SHOULD ANY ORIGINAL CODE PROVE DEFECTIVE
IN ANY RESPECT, YOU (NOT THE INITIAL DEVELOPER)
ASSUME THE COST OF ANY NECESSARY SERVICING, REPAIR
OR CORRECTION. THIS DISCLAIMER OF WARRANTY
CONSTITUTES AN ESSENTIAL PART OF THIS LICENSE. NO USE
OF ANY ORIGINAL CODE IS AUTHORIZED HEREUNDER EXCEPT
UNDER THIS DISCLAIMER. 

8.0 TERMINATION 

8.1 This License and the rights granted hereunder will terminate
automatically if You fail to comply with terms herein and fail to cure
such breach within 30 days of becoming aware of the breach. All
sublicenses to the Original Code which are properly granted shall
survive any termination of this License. Provisions which, by their
nature, must remain in effect beyond the termination of this License
shall survive. 

8.2 In the event of termination under Section 8.1 above, all end user
license agreements (excluding distributors and resellers) which have
been validly granted by You or any distributor hereunder prior to
termination shall survive termination. 

9.0 LIMIT OF LIABILITY 

UNDER NO CIRCUMSTANCES AND UNDER NO LEGAL THEORY,
WHETHER TORT (INCLUDING NEGLIGENCE), CONTRACT, OR
OTHERWISE, SHALL YOU, THE INITIAL DEVELOPER, ANY
OTHER CONTRIBUTOR, OR ANY DISTRIBUTOR OF ORIGINAL
CODE, OR ANY SUPPLIER OF ANY OF SUCH PARTIES, BE
LIABLE TO ANY PERSON FOR ANY INDIRECT, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES OF ANY
CHARACTER INCLUDING, WITHOUT LIMITATION, DAMAGES
FOR LOSS OF GOODWILL, WORK STOPPAGE, COMPUTER
FAILURE OR MALFUNCTION, OR ANY AND ALL OTHER
COMMERCIAL DAMAGES OR LOSSES, EVEN IF SUCH PARTY
SHALL HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH
DAMAGES. THIS LIMITATION OF LIABILITY SHALL NOT APPLY
TO LIABILITY FOR DEATH OR PERSONAL INJURY RESULTING
FROM SUCH PARTY'S NEGLIGENCE TO THE EXTENT
APPLICABLE LAW PROHIBITS SUCH LIMITATION. SOME
JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR
LIMITATION OF INCIDENTAL OR CONSEQUENTIAL DAMAGES,
SO THIS EXCLUSION AND LIMITATION MAY NOT APPLY TO
YOU. 

10.0 U.S. GOVERNMENT END USERS 

U.S. Government: If this Software is being acquired by or on behalf
of the U.S. Government or by a U.S. Government prime contractor
or subcontractor (at any tier), then the Government's rights in the
Software and accompanying documentation shall be only as set
forth in this license; this is in accordance with 48 C.F.R. 227.7201
through 227.7202-4 (for Department of Defense (DoD) acquisitions)
and with 48 C.F.R. 2.101 and 12.212 (for non-DoD acquisitions). 

11.0 MISCELLANEOUS 

This License represents the complete agreement concerning
subject matter hereof. If any provision of this License is held to be
unenforceable, such provision shall be reformed only to the extent
necessary to make it enforceable. This License shall be governed
by California law provisions (except to the extent applicable law, if
any, provides otherwise), excluding its conflict-of-law provisions.
With respect to disputes in which at least one party is a citizen of,
or an entity chartered or registered to do business in the United
States of America, any litigation relating to this License shall be
subject to the jurisdiction of the Federal Courts of the Northern
District of California, with venue lying in Santa Clara County,
California, with the losing party responsible for costs, including
without limitation, court costs and reasonable attorneys' fees and
expenses. The application of the United Nations Convention on
Contracts for the International Sale of Goods is expressly excluded.
Any law or regulation which provides that the language of a contract
shall be construed against the drafter shall not apply to this
License. 

EXHIBIT A - Sun Standards License 

"The contents of this file are subject to the Sun Standards

License Version 1.1 (the "License");

You may not use this file except in compliance with the 

License. You may obtain a copy of the

License at _______________________________.



Software distributed under the License is distributed on 

an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either 

express or implied. See the License for the specific

language governing rights and limitations under the License.



The Original Code is ______________________________________.



The Initial Developer of the Original Code is: 

Sun Microsystems, Inc..



Portions created by: _______________________________________



are Copyright (C): _______________________________________



All Rights Reserved.



Contributor(s): _______________________________________


EXHIBIT B - Standards 

The Standard is defined as the following: 

OpenOffice.org XML File Format Specification, located at
http://xml.openoffice.org 

OpenOffice.org Application Programming Interface Specification,
located at 
http://api.openoffice.org
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Sleepycat

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Sleepycat {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The Sleepycat License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The Sleepycat License

Copyright (c) 1990-1999 Sleepycat Software. All
rights reserved.

Redistribution and use in source and binary forms,
with or without modification, are permitted provided
that the following conditions are met:

     Redistributions of source code must retain
     the above copyright notice, this list of
     conditions and the following disclaimer. 
     Redistributions in binary form must
     reproduce the above copyright notice, this list
     of conditions and the following disclaimer in
     the documentation and/or other materials
     provided with the distribution. 
     Redistributions in any form must be
     accompanied by information on how to
     obtain complete source code for the DB
     software and any accompanying software
     that uses the DB software. The source code
     must either be included in the distribution or
     be available for no more than the cost of
     distribution plus a nominal fee, and must be
     freely redistributable under reasonable
     conditions. For an executable file, complete
     source code means the source code for all
     modules it contains. It does not include
     source code for modules or files that typically
     accompany the major components of the
     operating system on which the executable file
     runs. 

THIS SOFTWARE IS PROVIDED BY
SLEEPYCAT SOFTWARE ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT, ARE DISCLAIMED. IN NO
EVENT SHALL SLEEPYCAT SOFTWARE BE
LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF
USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.



Copyright (c) 1990, 1993, 1994, 1995 The
Regents of the University of California. All rights
reserved.

Redistribution and use in source and binary forms,
with or without modification, are permitted provided
that the following conditions are met:

     Redistributions of source code must retain
     the above copyright notice, this list of
     conditions and the following disclaimer. 
     Redistributions in binary form must
     reproduce the above copyright notice, this list
     of conditions and the following disclaimer in
     the documentation and/or other materials
     provided with the distribution. 
     Neither the name of the University nor the
     names of its contributors may be used to
     endorse or promote products derived from
     this software without specific prior written
     permission. 

THIS SOFTWARE IS PROVIDED BY THE
REGENTS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE
REGENTS OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.



Copyright (c) 1995, 1996 The President and
Fellows of Harvard University. All rights reserved.

Redistribution and use in source and binary forms,
with or without modification, are permitted provided
that the following conditions are met:

     Redistributions of source code must retain
     the above copyright notice, this list of
     conditions and the following disclaimer. 
     Redistributions in binary form must
     reproduce the above copyright notice, this list
     of conditions and the following disclaimer in
     the documentation and/or other materials
     provided with the distribution. 
     Neither the name of the University nor the
     names of its contributors may be used to
     endorse or promote products derived from
     this software without specific prior written
     permission. 

THIS SOFTWARE IS PROVIDED BY HARVARD
AND ITS CONTRIBUTORS ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL
HARVARD OR ITS CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Vovida

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Vovida_1_0 {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	Vovida Software License v. 1.0

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Vovida Software License v. 1.0

This license applies to all software incorporated in the
"Vovida Open Communication Application Library" except for
those portions incorporating third party software specifically
identified as being licensed under separate license.

The Vovida Software License, Version 1.0
Copyright (c) 2000 Vovida Networks, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

1. Redistributions of source code must retain the above
copyright notice, this list of conditions and the following
disclaimer.

2. Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

3. The names "VOCAL", "Vovida Open Communication
Application Library", and "Vovida Open Communication
Application Library (VOCAL)" must not be used to endorse
or promote products derived from this software without prior
written permission. For written permission, please contact
vocal\@vovida.org.

4. Products derived from this software may not be called
"VOCAL", nor may "VOCAL" appear in their name, without
prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY
EXPRESSED OR IMPLIED WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, TITLE AND NON-INFRINGEMENT ARE
DISCLAIMED. IN NO EVENT SHALL VOVIDA NETWORKS,
INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
DAMAGES IN EXCESS OF \$1,000, NOR FOR ANY
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.



This software consists of voluntary contributions made by
Vovida Networks, Inc. and many individuals on behalf of
Vovida Networks, Inc. For more information on Vovida
Networks, Inc., please see http://www.vovida.org.

All third party licenses and copyright notices and other
required legends also need to be complied with as well.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_ZLIB

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_ZLIB {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software licensed under the...

	The zlib/libpng License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
The zlib/libpng License

Copyright (c) <year> <copyright holders>

This software is provided 'as-is', without any express or
implied warranty. In no event will the authors be held liable
for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it
and redistribute it freely, subject to the following restrictions:

     1. The origin of this software must not be
     misrepresented; you must not claim that you
     wrote the original software. If you use this
     software in a product, an acknowledgment in
     the product documentation would be
     appreciated but is not required.

     2. Altered source versions must be plainly
     marked as such, and must not be
     misrepresented as being the original software.

     3. This notice may not be removed or altered
     from any source distribution.
EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 License_Perl

 Purpose   : Get the copyright pod text and LICENSE file text for this license

=cut

################################################## subroutine header end ##

sub License_Perl {
    my %license;

    my $gpl         = License_GPL_2 ();
    my $artistic    = License_Artistic_w_Aggregation ();

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    $license{LICENSETEXT} = <<EOFLICENSETEXT;
Terms of Perl itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

---------------------------------------------------------------------------

$gpl->{LICENSETEXT}

---------------------------------------------------------------------------

$artistic->{LICENSETEXT}

EOFLICENSETEXT

    return (\%license);
}

################################################ subroutine header begin ##

=head2 Custom_Licenses

 Purpose   : Get the copyright pod text and LICENSE file text for some
			 custom license provided by the programmer

=cut

################################################## subroutine header end ##

sub Custom_Licenses {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

    return (\%license);
}


1; #this line is important and will help the module return a true value
__END__


