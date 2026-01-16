package Getopt::Yath::Option::AutoPathList;
use strict;
use warnings;

our $VERSION = '2.000007';

use Getopt::Yath::Option::PathList;

use parent 'Getopt::Yath::Option::AutoList';
use Getopt::Yath::HashBase;

BEGIN {
    *normalize_value = Getopt::Yath::Option::PathList->can('normalize_value');
}

sub default_long_examples  {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => (qq{='*.*'});
    return $list;
}

sub default_short_examples {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => (qq{='*.*'});
    return $list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::AutoPathList - Like L<Getopt::Yath::Option::PathList> with autofill.

=head1 DESCRIPTION

Like L<Getopt::Yath::Option::PathList> with autofill.

=head1 SYNOPSIS

    option dev_libs => (
        type        => 'AutoPathList',
        short       => 'D',
        name        => 'dev-lib',

        autofill => sub { 'lib', 'blib/lib', 'blib/arch' },

        description => 'find the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.',

        long_examples  => ['', '=lib', '="lib/*"'],
        short_examples => ['', 'lib', '=lib', 'lib', '"lib/*"'],
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
