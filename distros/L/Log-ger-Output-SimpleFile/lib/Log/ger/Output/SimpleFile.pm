package Log::ger::Output::SimpleFile;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-SimpleFile'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    my $fh;
    if (defined(my $path = $plugin_conf{path})) {
        open $fh, ">>", $path or die "Can't open log file '$path': $!";
    } elsif ($fh = $plugin_conf{handle}) {
    } else {
        die "Please specify 'path' or 'handle'";
    }

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $fmsg, $per_msg_conf) = @_;
                    print $fh $fmsg . ($fmsg =~ /\R\z/ ? "" : "\n");
                    $fh->flush;
                };
                [$outputter];
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

version 0.004

=head1 SYNOPSIS

 use Log::ger::Output 'SimpleFile' => (
     path => '/path/to/file.log', # or handle => $fh
 );
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

This is a plugin to send outputs to a file. File will be opened with append
mode. Filehandle will be flushed after each log. No locking, rotation, or other
fancy features (see L<Log::ger::Output::File> and
L<Log::ger::Output::FileWriteRotate> for these features).

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 path => filename

Specify filename to open. File will be opened in append mode.

=head2 handle => glob|obj

Alternatively, you can provide an already opened filehandle.

=head1 SEE ALSO

L<Log::ger>

L<Log::ger::Output::File> is a similar output plugin with a few more options:
locking, autoflush, lazy (filehandle is opened when a log is actually produced).

L<Log::ger::Output::FileWriteRotate> offers autorotation feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
