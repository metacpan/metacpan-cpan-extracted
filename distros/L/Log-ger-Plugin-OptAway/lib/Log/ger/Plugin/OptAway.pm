package Log::ger::Plugin::OptAway;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger-Plugin-OptAway'; # DIST
our $VERSION = '0.008'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %plugin_conf = @_;

    return {
        after_install_routines => [
            __PACKAGE__, # key
            99,          # priority (after all the other plugins)
            sub {        # hook
                require B::CallChecker;
                require B::Generate;

                my %hook_args = @_;

                # we are only relevant when targetting package
                return [undef] unless ($hook_args{target_type}||'') eq 'package';

                #use DD; dd \%hook_args;
                for my $r (@{ $hook_args{routines} }) {
                    my ($code, $name, $lnum, $type) = @$r;
                    #print "D:got routine name=$name, lnum=",(defined $lnum ? $lnum : '-'), ", type=$type\n";
                    next unless $type =~ /\A(logger_|log_|level_checker_|is_)/;
                    my $fullname = "$hook_args{target_name}\::$name";

                    no warnings 'once'; # $Log::ger::Current_Level
                    my $should_opt_away;
                    if ($plugin_conf{all}) {
                        $should_opt_away = 1;
                    } elsif ($Log::ger::Current_Level < $r->[2]) {
                        $should_opt_away = 1;
                    }

                    if ($should_opt_away) {
                        #print "D:no-oping $fullname\n";
                        B::CallChecker::cv_set_call_checker(
                            \&{$fullname},
                            sub { B::SVOP->new("const",0,!1) },
                            \!1,
                        );
                    }
                }
                [1];
            }],
    };
}

1;
# ABSTRACT: Optimize away log statements

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::OptAway - Optimize away log statements

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use Log::ger::Plugin->set('OptAway');
 use Log::ger;

To demonstrate the effect of optimizing away:

 % perl -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 log_debug("bar\n");
 -e syntax OK

 % perl -MLog::ger::Plugin=OptAway -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 '???';
 -e syntax OK

To optimize away all levels:

 use Log::ger::Plugin 'OptAway', all=>1;

=head1 DESCRIPTION

This plugin replaces logging statements that are higher than the current level
(C<$Log::ger::Current_Level>) into a no-op statement using L<B::CallChecker>
magic at compile-time. The logging statements will become no-op and will have
zero run-time overhead.

By default, since C<$Current_Level> is pre-set at 30 (warn) then C<log_info()>,
C<log_debug()>, and C<log_trace()> calls will be turned into no-op.

If the configuration L</all> is set to true, however, logger routines for I<all>
levels will be turned into no-op.

Caveats:

=over

=item * must be done at compile-time

=item * only works when you are using procedural style

=item * once optimized away, subsequent logger reinitialization at run-time won't take effect

=back

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 all

Boolean. If set to true, will optimize away all levels, including multi-level
logger routines. This is an easy way to disable all logging.

By default, only levels above the current level (C<$Log::ger::Current_level>)
will be optimized away.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
