package Log::ger::Output::Journald;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-Journald'; # DIST
our $VERSION = '0.003'; # VERSION

use strict 'subs', 'vars';
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    require Log::Journald;

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $fmsg, $per_msg_conf) = @_;

                    my %log;
                    my $level = defined $per_msg_conf->{level} ?
                        $per_msg_conf->{level} : $hook_args{level};
                    $log{PRIORITY} = $level;
                    if (ref $fmsg eq 'HASH') {
                        $log{$_} = $fmsg->{$_} for keys %{$fmsg};
                    } else {
                        $log{MESSAGE} = $fmsg;
                    }
                    Log::Journald::send(%log) or warn $!;
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Send logs to journald

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Journald - Send logs to journald

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Log::ger::Output 'Journald' => (
 );
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

This output plugin sends logs to journald using L<Log::Journald>.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 SEE ALSO

L<Log::ger>

L<Log::Journald>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
