package Log::ger::Plugin::Log4perl;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Like-Log4perl'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                my $formatter = sub {
                    return
                        join("", map { ref $_ eq 'CODE' ? ($_->()) : ($_) } @_);
                };
                return [$formatter, 0, 'log4perl'];
            },
        ],

        create_routine_names => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;

                my $levels = [keys %Log::ger::Levels];

                return [{
                    logger_subs => [
                        (map { [uc($_), $_, "log4perl"] } @$levels),
                        ["LOGDIE"    , "fatal", "log4perl"],
                        ["LOGWARN"   , "warn" , "log4perl"],
                        ["LOGCARP"   , "warn" , "log4perl"],
                        ["LOGCLUCK"  , "warn" , "log4perl"],
                        ["LOGCROAK"  , "fatal", "log4perl"],
                        ["LOGCONFESS", "fatal", "log4perl"],
                    ],
                    level_checker_subs     => [],
                    logger_methods => [
                        (map { ["$_", $_, "log4perl"] } @$levels),
                        ["logdie"    , "fatal", "log4perl"],
                        ["logwarn"   , "warn" , "log4perl"],
                        ["logcarp"   , "warn" , "log4perl"],
                        ["logcluck"  , "warn" , "log4perl"],
                        ["logcroak"  , "fatal", "log4perl"],
                        ["logconfess", "fatal", "log4perl"],
                        ["error_die" , "error", "log4perl"],
                        ["error_warn", "error", "log4perl"],
                    ],
                    level_checker_methods  => [
                        map { ["is_$_", $_] } @$levels,
                    ],
                }, 0];
            }],
        before_install_routines => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;

                # wrap the logdie, et al
                for my $r (@{ $hook_args{routines} }) {
                    my ($code, $name, $numlevel, $type) = @$r;
                    if ($name =~ /\A(logdie|error_die)\z/) {
                        $r->[0] = sub { $code->(@_); shift; die  $hook_args{formatters}{log4perl}(@_) };
                    } elsif ($name eq 'LOGDIE') {
                        $r->[0] = sub { $code->(@_);        die  $hook_args{formatters}{log4perl}(@_) };
                    } elsif ($name =~ /\A(logwarn|error_warn)\z/) {
                        $r->[0] = sub { $code->(@_); shift; warn $hook_args{formatters}{log4perl}(@_) };
                    } elsif ($name eq 'LOGWARN') {
                        $r->[0] = sub { $code->(@_);        warn $hook_args{formatters}{log4perl}(@_) };
                    } elsif ($name eq 'logcarp') {
                        require Carp;
                        $r->[0] = sub { $code->(@_); shift; Carp::carp($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'LOGCARP') {
                        require Carp;
                        $r->[0] = sub { $code->(@_);        Carp::carp($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'logcluck') {
                        require Carp;
                        $r->[0] = sub { $code->(@_); shift; Carp::cluck($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'LOGCLUCK') {
                        require Carp;
                        $r->[0] = sub { $code->(@_);        Carp::cluck($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'logcroak') {
                        require Carp;
                        $r->[0] = sub { $code->(@_); shift; Carp::croak($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'LOGCROAK') {
                        require Carp;
                        $r->[0] = sub { $code->(@_);        Carp::croak($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'logconfess') {
                        require Carp;
                        $r->[0] = sub { $code->(@_); shift; Carp::confess($hook_args{formatters}{log4perl}(@_)) };
                    } elsif ($name eq 'LOGCONFESS') {
                        require Carp;
                        $r->[0] = sub { $code->(@_);        Carp::confess($hook_args{formatters}{log4perl}(@_)) };
                    }
                }
                [];
            },
        ],
    };
}

1;
# ABSTRACT: Plugin to mimic Log::Log4perl (log.+())

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::Log4perl - Plugin to mimic Log::Log4perl (log.+())

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Use from L<Log::ger::Like::Log4perl>.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Plugin::Log4perl_Multi>

L<Log::ger::Like::Log4perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
