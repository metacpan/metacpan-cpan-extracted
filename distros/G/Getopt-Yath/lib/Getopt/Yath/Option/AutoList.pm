package Getopt::Yath::Option::AutoList;
use strict;
use warnings;

our $VERSION = '2.000007';

use parent 'Getopt::Yath::Option::List';
use Getopt::Yath::HashBase;

sub allows_arg        { 1 }
sub requires_arg      { 0 }
sub allows_autofill   { 1 }
sub requires_autofill { 1 }

sub inject_default_long_examples  { qq{='["json","list"]'} }
sub inject_default_short_examples { qq{='["json","list"]'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::AutoList - Options with a default list of values

=head1 DESCRIPTION

This is a combination of 'Auto' and 'List' types. The no-arg form C<--opt> will
add the default values(s) to the list. The C<--opt=VAL> form will add
additional values.

=head1 SYNOPSIS

    option do_things => (
        type => 'AutoList',
        autofill => sub { qw/foo bar baz/ },
    );

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
