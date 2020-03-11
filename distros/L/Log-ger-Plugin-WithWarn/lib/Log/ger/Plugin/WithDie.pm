package Log::ger::Plugin::WithDie;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Plugin-WithWarn'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_routine_names => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $levels = \%Log::ger::Levels;

                return [{
                    logger_subs => [
                        (map { ["log_${_}_die", $_, "default"] }
                             grep {$levels->{$_} > 0 && $levels->{$_} <= 20} keys %$levels),
                    ],
                    level_checker_subs => [],
                    logger_methods => [
                        (map { ["${_}_die", $_, "default"] }
                             grep {$levels->{$_} > 0 && $levels->{$_} <= 20} keys %$levels),
                    ],
                    level_checker_methods  => [
                    ],
                }, 0];
            }],
        before_install_routines => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                # wrap the logger
                for my $r (@{ $args{routines} }) {
                    my ($code, $name, $numlevel, $type) = @$r;
                    if ($type =~ /^log(ger)?_sub/ && $name =~ /\Alog_\w+_die\z/) {
                        $r->[0] = sub {
                            $code->(@_);
                            die $args{formatters}{default}(@_)."\n";
                        };
                    } elsif ($type =~ /^log(ger)?_method/ && $name =~ /\A\w+_die\z/) {
                        $r->[0] = sub {
                            $code->(@_);
                            shift;
                            die $args{formatters}{default}(@_)."\n";
                        };
                    }
                }
            },
        ],
    };
}

1;
# ABSTRACT: Add *_die logging routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::WithDie - Add *_die logging routines

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Log::ger::Plugin 'WithDie';
 use Log::ger;
 my $log = Log::ger->get_logger;

These subroutines will also become available:

 log_error_die("blah!"); # in addition to log, will also die()
 log_fatal_die("blah!"); # in addition to log, will also die()

These logging methods will also become available:

 $log->error_die("blah!"); # in addition to log, will also die()
 $log->fatal_die("blah!"); # in addition to log, will also die()

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Plugin::WithWarn>

L<Log::ger::Plugin::WithCarp>

L<Log::ger::Plugin::Log4perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
