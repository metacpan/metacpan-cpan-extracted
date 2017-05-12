# $Id: Simple.pm,v 1.5 2007/07/13 00:00:14 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL/Simple.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/07/13 00:00:14 $
package Getopt::LL::Simple;
use strict;
use warnings;
use Getopt::LL::Short qw(getoptions);
use version; our $VERSION = qv('1.0.0');
use 5.006_001;

sub import {
    my ($pkg, @rules) = @_;
    my $caller = caller;

    my $options_ref;
    if (scalar @rules && ref $rules[-1] eq 'HASH') {
        $options_ref = pop @rules;
    }

    my $options
        = getoptions(\@rules, $options_ref);

    no strict 'refs'; ## no critic
    %{ $caller . q{::} . 'ARGV' } = %{ $options };

    return;
}

1;
__END__

=for stopwords expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL::Simple - Specify arguments on the use-line.

= VERSION

This document describes Getopt::LL version %%VERSION%%

= SYNOPSIS

    use Getopt::LL::Simple qw(
        -f=s         
        --verbose|-v    
        --debug|-d=d    
        --use-foo=f
    );

    if ($ARGV{'--verbose'}) {
        print "in verbose mode\n";
    }

    if ($ARGV{'--debug'}) {
        print "debug level is: $ARGV{'--debug'}\n";
    }

= DESCRIPTION

Let's you specify program command-line arguments on the "use-line".

= SUBROUTINES/METHODS

{Getopt::LL::Simple} has no subroutines or methods.

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

== Getopt::LL

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


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround

