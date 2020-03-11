package Log::ger::Plugin::WithCarp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Plugin-WithWarn'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Carp ();
use Log::ger ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_;

                my $levels = \%Log::ger::Levels;

                return [{
                    logger_subs => [
                        (map { (["log_${_}_carp", $_, "default"], ["log_${_}_cluck", $_, "default"]) }
                             grep {$levels->{$_} == 30} keys %$levels),
                        (map { (["log_${_}_croak", $_, "default"], ["log_${_}_confess", $_, "default"]) }
                             grep {$levels->{$_} > 0 && $levels->{$_} <= 20} keys %$levels),
                    ],
                    level_checker_subs => [],
                    logger_methods => [
                        (map { (["${_}_carp", $_, "default"], ["${_}_cluck", $_, "default"]) }
                             grep {$levels->{$_} == 30} keys %$levels),
                        (map { (["${_}_croak", $_, "default"], ["${_}_confess", $_, "default"]) }
                             grep {$levels->{$_} > 0 && $levels->{$_} <= 20} keys %$levels),
                    ],
                    level_checker_methods  => [
                    ],
                }, 0];
            }],
        before_install_routines => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_;

                # wrap the logger
                for my $r (@{ $hook_args{routines} }) {
                    my ($code, $name, $numlevel, $type) = @$r;
                    if    ($type =~ /^log(ger)?_sub/    && $name =~ /\Alog_\w+_carp\z/   ) { $r->[0] = sub { $code->(@_);        Carp::carp   ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_method/ && $name =~ /\A\w+_carp\z/       ) { $r->[0] = sub { $code->(@_); shift; Carp::carp   ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_sub/    && $name =~ /\Alog_\w+_cluck\z/  ) { $r->[0] = sub { $code->(@_);        Carp::cluck  ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_method/ && $name =~ /\A\w+_cluck\z/      ) { $r->[0] = sub { $code->(@_); shift; Carp::cluck  ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_sub/    && $name =~ /\Alog_\w+_croak\z/  ) { $r->[0] = sub { $code->(@_);        Carp::croak  ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_method/ && $name =~ /\A\w+_croak\z/      ) { $r->[0] = sub { $code->(@_); shift; Carp::croak  ($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_sub/    && $name =~ /\Alog_\w+_confess\z/) { $r->[0] = sub { $code->(@_);        Carp::confess($hook_args{formatters}{default}(@_)."\n") } }
                    elsif ($type =~ /^log(ger)?_method/ && $name =~ /\A\w+_confess\z/    ) { $r->[0] = sub { $code->(@_); shift; Carp::confess($hook_args{formatters}{default}(@_)."\n") } }
                }
            },
        ],
    };
}

1;
# ABSTRACT: Add *_{carp,cluck,croak,confess} logging routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::WithCarp - Add *_{carp,cluck,croak,confess} logging routines

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Log::ger::Plugin 'WithCarp';
 use Log::ger;
 my $log = Log::ger->get_logger;

These subroutines will also become available:

 log_warn_carp    ("blah!"); # in addition to log, will also carp()
 log_warn_cluck   ("blah!"); # in addition to log, will also cluck()
 log_error_croak  ("blah!"); # in addition to log, will also croak()
 log_error_confess("blah!"); # in addition to log, will also confess()
 log_fatal_croak  ("blah!"); # in addition to log, will also croak()
 log_fatal_confess("blah!"); # in addition to log, will also confess()

These logging methods will also become available:

 $log->warn_carp    ("blah!"); # in addition to log, will also carp()
 $log->warn_cluck   ("blah!"); # in addition to log, will also cluck()
 $log->error_croak  ("blah!"); # in addition to log, will also croak()
 $log->error_confess("blah!"); # in addition to log, will also confess()
 $log->fatal_croak  ("blah!"); # in addition to log, will also croak()
 $log->fatal_confess("blah!"); # in addition to log, will also confess()

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Plugin::WithWarn>

L<Log::ger::Plugin::WithDie>

L<Log::ger::Plugin::Log4perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
