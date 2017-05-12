# $Id: Short.pm,v 1.6 2007/07/13 00:00:14 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL/Short.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.6 $
# $Date: 2007/07/13 00:00:14 $
package Getopt::LL::Short;
use strict;
use warnings;
use base 'Getopt::LL';
use version; our $VERSION = qv('1.0.0');
use 5.006_001;
{

    use Getopt::LL::SimpleExporter qw(getoptions);

    my %RULE_ABBREVATION = (
        's' => 'string',
        'd' => 'digit',
        'f' => 'flag',
    );

    sub parse_short_rule {
        my ($rule) = @_;

        if (index ($rule, q{=}) != -1) {
            my ($arg_name, $rule_type) = split m/=/xms, $rule, 2;
            return ($arg_name, $RULE_ABBREVATION{$rule_type});
        }

        # Default rule is flag.
        return ($rule, 'flag');
    }

   sub getoptions {
       my ($rules_ref, $options_ref, $argv_ref) = @_;
       $rules_ref ||= [ ];

        my %converted_rules;
        for my $rule (@{$rules_ref}) {
            my ($arg_name, $rule_ref) = parse_short_rule($rule);
            $converted_rules{$arg_name} = $rule_ref;
        }

       return Getopt::LL::getoptions(
           \%converted_rules, $options_ref, $argv_ref
       );

   }

}
1;

__END__

=for stopwords expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL::Short - Abbreviated Getopt::LL rules.

= VERSION

This document describes Getopt::LL version %%VERSION%%

= SYNOPSIS

    use Getopt:LL::Short qw(getoptions);

    my $options = getoptions([
        '-t=s',             # a string
        '--use-foo=f',      # a flag
        '--verbose|-v',     # also a flag
        '--debug=d|-d',     # a digit
    });

= DESCRIPTION

This is a subclass of Getopt::LL that allows for abbreviated rules.

= SUBROUTINES/METHODS


== CONSTRUCTOR

== CLASS METHODS 

=== {getoptions(\@rules, \%options, \@opt_argv)}

Parses and gets arguments based on the rules in \@rules.
Uses @ARGV if \@opt_arg is not specified.

Returns hash with the arguments it found.
@ARGV is replaced with the arguments that does not start with '-' or '--'.

=== {parse_short_rule($rule)}

Each abbreviated rule is sent to this function to convert them into
normal Getopt::LL rules. i.e:
    '--filename=s'
is converted to
     --filename  => 'string'

This function returns the argument name and the rule type. 

    my ($arg_name, $rule_type) = parse_short_rule($rule);



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
