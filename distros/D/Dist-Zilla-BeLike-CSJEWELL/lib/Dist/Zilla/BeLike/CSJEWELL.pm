package Dist::Zilla::BeLike::CSJEWELL;

use 5.008003;
use warnings;
use strict;

our $VERSION = '0.901';
$VERSION =~ s/_//sm;


# Documentation module only.

1;                                     # Magic true value required at end of module
__END__

=pod

=begin readme text

Dist::Zilla::BeLike::CSJEWELL version 0.901

=end readme

=for readme stop

=head1 NAME

Dist::Zilla::BeLike::CSJEWELL - Build a modern dist like CSJEWELL does it.

=head1 VERSION

This document describes Dist::Zilla::BeLike::CSJEWELL version 0.901.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will require a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	# After 'dzil setup'
	dzil configure_CSJEWELL
	
	# To create a module
	dzil new -P CSJEWELL Your::Module

=head1 DESCRIPTION

This sets up defaults for C<dzil new> to create a dist like CSJEWELL does 
it, including a dist.ini that does the release steps that CSJEWELL requires. 

=head1 CONFIGURATION AND ENVIRONMENT

The configuration questions are asked for in the C<dzil configure_CSJEWELL> command.

=for readme continue

=head1 DEPENDENCIES

This module depends on L<Dist::Zilla|Dist::Zilla> version 4.102221 or greater,
L<Dist::Zilla::Plugin::Mercurial|Dist::Zilla::Plugin::Mercurial>, 
L<Dist::Zilla::Plugin::Twitter|Dist::Zilla::Plugin::Twitter>, ...

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This module does not know how to automatically handle any Mercurial servers 
other than bitbucket.org, or any other VCS or DVCS server at the moment.

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-BeLike-CSJEWELL>
if you have an account there.

2) Email to E<lt>bug-Dist-Zilla-BeLike-CSJEWELL@rt.cpan.orgE<gt> if you do not.

=head1 AUTHOR

Curtis Jewell <CSJewell@cpan.org>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< CSJewell@cpan.org >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
