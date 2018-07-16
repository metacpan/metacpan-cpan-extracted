package Dist::Zilla::Plugin::ATOOMIC::License;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.00';

use Module::Runtime qw( use_module );
use String::RewritePrefix;

use Moose;

with 'Dist::Zilla::Role::LicenseProvider';

sub provide_license {
    my $self = shift;
    my $args = shift;

    my $year      = $args->{copyright_year};
    my $this_year = (localtime)[5] + 1900;
    my $years     = $year == $this_year ? $year : "$year - $this_year";

    my $license_class = String::RewritePrefix->rewrite(
        {
            '=' => q{},
            q{} => 'Software::License::'
        },
        $self->zilla()->_license_class() // 'Artistic_2_0',
    );

    use_module($license_class);

    return $license_class->new(
        {
            holder => $args->{copyright_holder} || 'David Rolsky',
            year => $years,
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Sets up default license and copyright holder

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ATOOMIC::License - Sets up default license and copyright holder

=head1 VERSION

version 1.00

=for Pod::Coverage .*

=head1 SUPPORT

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-ATOOMIC can be found at L<https://github.com/atoomic/Dist-Zilla-PluginBundle-ATOOMIC>.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Nicolas R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
