package Getopt::Yath::Option::PathList;
use strict;
use warnings;

our $VERSION = '2.000007';

use parent 'Getopt::Yath::Option::List';
use Getopt::Yath::HashBase;

sub normalize_value {
    my $self = shift;
    my (@input) = @_;

    my @out;
    for my $val (@input) {
        if ($val =~ m/\*/) {
            push @out => $self->SUPER::normalize_value($_) for glob($val);
        }
        else {
            push @out => $self->SUPER::normalize_value($val);
        }
    }

    return @out;
}

sub default_long_examples  {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => (qq{ '*.*'}, qq{='*.*'});
    return $list;
}

sub default_short_examples {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => (qq{ '*.*'}, qq{='*.*'});
    return $list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::PathList - Option that takes one or more paths, wild cards allowed.

=head1 DESCRIPTION

Option that lets you specify multiple files and/or paths including wildcards
that get expanded.

=head1 SYNOPSIS

    option changed => (
        type          => 'PathList',
        split_on      => ',',
        description   => "Specify one or more files as having been changed.",
        long_examples => [' path/to/file'],
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
