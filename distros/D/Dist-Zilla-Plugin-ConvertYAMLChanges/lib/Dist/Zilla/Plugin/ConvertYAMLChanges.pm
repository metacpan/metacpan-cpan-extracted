package Dist::Zilla::Plugin::ConvertYAMLChanges;

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our $VERSION = '0.02'; # VERSION

use Moose;
#use experimental 'smartmatch';
use namespace::autoclean;

use CPAN::Changes;
use File::Slurp::Tiny qw(read_file);
use YAML::XS;

with (
    'Dist::Zilla::Role::FileMunger',
);

sub munge_file {
    my ($self, $file) = @_;

    my $fname = $file->name;

    unless ($fname =~ m!Changes!) {
        #$self->log_debug("Skipping: '$fname' not Changes file");
        return;
    }

    #$log->tracef("Processing file %s ...", $fname);
    $self->log("Processing file $fname ...");

    #use Data::Dump; dd $self->zilla->{distmeta};
    my $changes = CPAN::Changes->new(
        preamble => "Revision history for " . $self->zilla->{distmeta}{name},
    );
    for my $yaml (Load(~~read_file($fname))) {
        next unless ref($yaml) eq 'HASH' && defined $yaml->{version};

        my $chs0 = $yaml->{changes};
        my $chs;

        # try to guess the format of changes:
        if (ref($chs0) eq 'HASH') {
            # already categorized? pass unchanged
            $chs = $chs0;
        } elsif (ref($chs0) eq 'ARRAY') {
            for my $ch (@$chs0) {
                if (ref($ch) eq 'HASH') {
                    for (keys %$ch) {
                        $chs->{$_} //= [];
                        push @{ $chs->{$_} }, $ch->{$_};
                    }
                } elsif (!ref($ch)) {
                    $chs->{''} //= [];
                    push @{ $chs->{''} }, $ch;
                } else {
                    die "Sorry, can't figure out format of change $ch for $yaml->{version}";
                }
            }
        } else {
            die "Sorry, can't figure out format of changes for $yaml->{version}";
        }
        #use Data::Dump; dd $chs;
        $yaml->{changes} = $chs;
        $changes->add_release($yaml);
    }

    $self->log("Converted YAML to CPAN::Changes format: $fname");
    $file->content($changes->serialize);

    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Convert Changes from YAML to CPAN::Changes format

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ConvertYAMLChanges - Convert Changes from YAML to CPAN::Changes format

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::ConvertYAMLChanges (from Perl distribution Dist-Zilla-Plugin-ConvertYAMLChanges), released on 2014-05-17.

=head1 SYNOPSIS

In dist.ini:

 [ConvertYAMLChanges]

=head1 DESCRIPTION

This plugin converts Changes from YAML format (like that found in C<Mo> or other
INGY's distributions) to CPAN::Changes format. First written to aid Neil Bowers'
quest[1].

[1] http://blogs.perl.org/users/neilb/2013/10/fancy-writing-a-distzilla-plugin.html

=for Pod::Coverage ^(munge_file)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-ConvertYAMLChanges>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Dist-Zilla-Plugin-ConvertYAMLChanges>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-ConvertYAMLChanges>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
