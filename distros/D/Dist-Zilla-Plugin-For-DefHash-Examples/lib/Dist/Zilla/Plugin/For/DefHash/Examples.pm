package Dist::Zilla::Plugin::For::DefHash::Examples;

our $DATE = '2016-07-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::FileMunger',
);

use File::Find;
use File::Slurper qw(read_text);
use Hash::DefHash;
use JSON::MaybeXS;

sub munge_files {
    no strict 'refs';

    my $self = shift;

    find sub {
        return unless -f && /\.json\z/;
        my $ct = read_text $_;
        my $hash;
        eval { $hash = decode_json($ct) };
        $self->log_fatal(["File %s doesn't contain a valid JSON: %s", "$File::Find::dir/$_", $@])
            if $@;
        my $defhash;
        eval { $defhash = defhash($hash) };
        if (/\Aerror-/) {
            $self->log_fatal(["Hash in file %s is a valid defhash but its name indicates it should be an invalid defhash", "$File::Find::dir/$_"])
                unless $@;
        } else {
            $self->log_fatal(["Hash in file %s is not a valid defhash: %s", "$File::Find::dir/$_", $@])
                if $@;
        }
    }, "share/examples";
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin for building DefHash-Examples distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::For::DefHash::Examples - Plugin for building DefHash-Examples distribution

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::For::DefHash::Examples (from Perl distribution Dist-Zilla-Plugin-For-DefHash-Examples), released on 2016-07-11.

=head1 SYNOPSIS

In F<dist.ini>:

 [For::DefHash::Examples]

=head1 DESCRIPTION

This plugin is to be used when building C<DefHash-Examples> distribution (see
L<DefHash::Examples>). Currently it does the following:

=over

=item * For C<share/examples/*.json>, check that the file contains valid JSON and valid defhash (or invalid defhash, if filename begins with 'error-')

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-For-DefHash-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-For-DefHash-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-For-DefHash-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash>

L<DefHash::Examples>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
