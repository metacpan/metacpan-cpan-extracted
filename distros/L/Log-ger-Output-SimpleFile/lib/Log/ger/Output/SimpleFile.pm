package Log::ger::Output::SimpleFile;

our $DATE = '2017-07-14'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    my $fh;
    if (defined(my $path = $conf{path})) {
        open $fh, ">>", $path or die "Can't open log file '$path': $!";
    } elsif ($fh = $conf{handle}) {
    } else {
        die "Please specify 'path' or 'handle'";
    }

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    print $fh $_[1];
                    print $fh "\n" unless $_[1] =~ /\R\z/;
                    $fh->flush;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Send logs to file

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::SimpleFile - Send logs to file

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Output 'SimpleFile' => (
     path => '/path/to/file.log', # or handle => $fh
 );
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

This is a simple output to file. File will be opened with append mode.
Filehandle will be flushed after each log. No locking, rotation, or other fancy
features (see L<Log::ger::Output::File> for that).

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 path => filename

Specify filename to open. File will be opened in append mode.

=head2 handle => glob|obj

Alternatively, you can provide an already opened filehandle.

=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Output::File>

L<Log::ger::Output::FileWriteRotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
