package Log::ger::Output::DirWriteRotate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-09'; # DATE
our $DIST = 'Log-ger-Output-DirWriteRotate'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 1,
} }

sub get_hooks {
    my %plugin_conf = @_;

    require Dir::Write::Rotate;
    my $dwr = Dir::Write::Rotate->new(%plugin_conf);

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $fmsg, $per_msg_conf) = @_;
                    $dwr->write($fmsg);
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Log to Dir::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::DirWriteRotate - Log to Dir::Write::Rotate

=head1 VERSION

This document describes version 0.003 of Log::ger::Output::DirWriteRotate (from Perl distribution Log-ger-Output-DirWriteRotate), released on 2020-03-09.

=head1 SYNOPSIS

 use Log::ger::Output DirWriteRotate => (
     path               => 'somedir.log',            # required
     filename_pattern   => '%Y-%m-%d-%H%M%S.pid-%{pid}.%{ext}', # optional
     filename_sub       => sub { ... },              # optional
     max_size           => undef,                    # optional
     max_files          => undef,                    # optional
     max_age            => undef,                    # optional
     rotate_probability => 0.25,                     # optional
 );

=head1 DESCRIPTION

This output sends logs to Dir::Write::Rotate object.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

These configuration parameters are Dir::Write::Rotate's.

=head2 path

=head2 filename_pattern

=head2 filename_sub

=head2 max_size

=head2 max_files

=head2 max_age

=head2 rotate_probability

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-DirWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-DirWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-DirWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Dir::Write::Rotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
