package Maypole::Constants;
use strict;
use base 'Exporter';
use constant OK       => 0;
use constant DECLINED => -1;
use constant ERROR    => 500;
our @EXPORT = qw(OK DECLINED ERROR);
our $VERSION = "1." . sprintf "%04d", q$Rev: 483 $ =~ /: (\d+)/;

1;

=head1 NAME

Maypole::Constants - Maypole predefined constants

=head1 SYNOPSIS

    use Maypole::Constants;

    sub authenticate {
        if (valid_user()) {
            return OK;
        } else {
            return DECLINED
        }
    }

=head1 DESCRIPTION

This class defines constants for use with Maypole

=head2 CONSTANTS

=head3 OK

=head3 DECLINED

=head3 ERROR

=head1 SEE ALSO

L<Maypole>

=head1 MAINTAINER

Aaron Trevena, c<teejay@droogs.org>

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
