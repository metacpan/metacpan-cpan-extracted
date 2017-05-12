# $Id: SimpleExporter.pm,v 1.5 2007/07/13 00:00:14 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL/SimpleExporter.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/07/13 00:00:14 $
package Getopt::LL::SimpleExporter;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.0');
use 5.006_001;

my %EXPORTS_FOR_PACKAGE = ();

sub import {
    my @exports = @_;
    my $caller = caller;
    
    $EXPORTS_FOR_PACKAGE{$caller} = {map { $_ => 1} @exports};

    no strict 'refs'; ## no critic;
    *{ $caller . q{::} . 'import'    } = \&simple_export;
    @{ $caller . q{::} . 'EXPORT_OK' } = @exports;

    return;
}

sub simple_export {
    my ($class, @tags) = @_;
        my $caller = caller;

        no strict 'refs'; ## no critic
        while (@tags) {
            my $export_attr = shift @tags;
            my %exports     = %{ $EXPORTS_FOR_PACKAGE{$class} };

            if (!exists $exports{$export_attr}) {
                require Carp;
                Carp->import('croak');
                croak("$class does not export $export_attr"); ## no critic
            }

            my $sub = *{ "$class\::$export_attr" }{CODE}; ## no critic
            *{ $caller . q{::} . $export_attr } = $sub;
        }

        return;
}

1;

__END__

=for stopwords expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL::SimpleExporter - Simple way of exporting subroutines.

= VERSION

This document describes Getopt::LL version %%VERSION%%

= SYNOPSIS
    use MyClass qw(hello);

    hello();

    package MyClass;
    use Getopt::LL::SimpleExporter qw(hello);

    sub hello {
        print 'hello world', "\n";
    };

            
= DESCRIPTION

Simple way of exporting subroutines to the callers namespace.
No need for @EXPORT_OK variables and so on, just specify which subroutines
you want exported on the use line.

= SUBROUTINES/METHODS

== PRIVATE SUBROUTINES

== {import}

This subroutine is automatically run when you use this module and will
alias the {import} function in your package to the {simple_export} function in
this package.

== {simple_export}

This function is renamed to import and installed into your namespace when you
use this module. It is responsible for exporting the functions you specify on
the use line to the packages that uses your module.

= DIAGNOSTICS


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES


== * version

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-getopt-ll@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

= SEE ALSO

== Exporter

= AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc

# Local variables:
# vim: ts=4

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
