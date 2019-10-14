package Log::ger::Output::FileWriteRotate;

our $DATE = '2019-09-10'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    require File::Write::Rotate;
    my $fwr = File::Write::Rotate->new(%conf);

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my ($ctx, $msg) = @_;
                    $fwr->write($msg, $msg =~ /\R\z/ ? "" : "\n");
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Log to File::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::FileWriteRotate - Log to File::Write::Rotate

=head1 VERSION

This document describes version 0.003 of Log::ger::Output::FileWriteRotate (from Perl distribution Log-ger-Output-FileWriteRotate), released on 2019-09-10.

=head1 SYNOPSIS

 use Log::ger::Output FileWriteRotate => (
     dir          => '/var/log',    # required
     prefix       => 'myapp',       # required
     #suffix      => '.log',        # default is ''
     size         => 25*1024*1024,  # default is 10MB, unless period is set
     histories    => 12,            # default is 10
     #buffer_size => 100,           # default is none
 );

=head1 DESCRIPTION

This plugin sends logs to L<File::Write::Rotate> (FWR) object. FWR allows
autorotation when logging, meaning you don't need an additional external process
to perform log rotation but FWR can perform the rotation itself.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

These configuration parameters are FWR's. See that module's documentation for
more details.

=head2 dir

=head2 prefix

=head2 suffix

=head2 size

=head2 histories

=head2 buffer_size

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-FileWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<File::Write::Rotate>

L<Log::ger::Output::SimpleFile>

L<Log::ger::Output::File>

L<Log::ger::Output::DirWriteRotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
