package Log::ger::Output::Syslog;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-Syslog'; # DIST
our $VERSION = '0.005'; # VERSION

use strict 'subs', 'vars';
use warnings;

use Log::ger::Util;

our %level_map = (
    # Log::ger default level => syslog level
    # => emerg
    # => alert
    fatal => 'crit',
    error => 'err',
    warn  => 'warning',
    # => notice
    info  => 'info',
    debug => 'debug',
    trace => 'debug',
);

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    my $ident = delete($plugin_conf{ident});
    defined($ident) or die "Please specify ident";

    my $facility = delete($plugin_conf{facility}) || 'user';
    $facility =~ /\A(auth|authpriv|cron|daemon|ftp|kern|local[0-7]|lpr|mail|news|syslog|user|uucp)\z/
        or die "Invalid value for facility, please choose ".
        "auth|authpriv|cron|daemon|ftp|kern|local[0-7]|lpr|mail|news|syslog|user|uucp";

    my $logopt = delete($plugin_conf{logopt});
    $logopt = "pid" unless defined $logopt;

    keys %plugin_conf and
        die "Unknown configuration: ".join(", ", sort keys %plugin_conf);

    require Sys::Syslog;
    Sys::Syslog::openlog($ident, $logopt, $facility) or die;

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $fmsg, $per_msg_conf) = @_;

                    my $num_level = $per_msg_conf ? $per_msg_conf->{level} : undef; $num_level = $hook_args{level} if !defined $num_level;
                    my $str_level = Log::ger::Util::string_level($num_level);
                    $level_map{$str_level} or die "Don't know how to map ".
                        "Log::ger level '$str_level' to syslog level";

                    Sys::Syslog::syslog(
                        &{"Sys::Syslog::LOG_".uc($level_map{$str_level})},
                        $fmsg,
                    );
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Send logs to syslog

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Syslog - Send logs to syslog

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Log::ger::Output 'Syslog' => (
     ident    => 'myprog', # required
     facility => 'daemon', # optional, default 'user'
 );
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

This output plugin sends logs to syslog using L<Sys::Syslog>.
It accepts all C<syslog(3)> facilities.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 ident

=head2 facility

=head2 logopt

=head1 SEE ALSO

L<Log::ger>

L<Sys::Syslog>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
