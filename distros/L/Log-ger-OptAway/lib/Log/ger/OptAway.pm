package Log::ger::OptAway;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub PRIO_after_install_log_routine { 99 }

sub after_install_log_routine {
    require B::CallChecker;
    require B::Generate;

    my ($self, %args) = @_;
    return [undef] unless $args{target} eq 'package';

    my $fullname = "$args{target_arg}\::log_$args{str_level}";
    if ($Log::ger::Current_Level < $args{level}) {
        #print "D:no-oping $fullname\n";
        B::CallChecker::cv_set_call_checker(
            \&{$fullname},
            sub { B::SVOP->new("const",0,!1) },
            \!1,
        );
    }
    [undef];
}

sub import {
    my $self = shift;

    my $caller = caller(0);

    Log::ger::Util::add_plugin('after_install_log_routine', __PACKAGE__);
}

1;
# ABSTRACT: Optimize away higher-level log statements

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::OptAway - Optimize away higher-level log statements

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Log::ger::OptAway;
 use Log::ger;

Calling C<use Log::ger::OptAway> will affect subsequent packages that C<use
Log::ger>. If you want to affect all packages, run:

 Log::ger::resetup_importers();

To demonstrate the effect of optimizing away:

 % perl -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 log_debug("bar\n");
 -e syntax OK

 % perl -MLog::ger::OptAway -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 '???';
 -e syntax OK

=head1 DESCRIPTION

This plugin replaces logging statements that are higher than the current level
(C<$Log::ger::Current_Level>) into a no-op statement using L<B::CallChecker>
magic at compile-time. The logging statements will become no-op and will have
zero run-time overhead.

By default, since C<$Current_Level> is pre-set at 3 (warn) then C<log_info()>,
C<log_debug()>, and C<log_trace()> calls will be turned into no-op.

=for Pod::Coverage ^(.+)$

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
