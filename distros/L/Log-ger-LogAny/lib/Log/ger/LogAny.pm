package Log::ger::LogAny;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Log::Any ();
use Log::ger ();

my %Log_Any_Loggers;

my $hook_log = sub {
    my %args = @_;

    my $pkg = $args{package};

    {
        my $log = Log::Any->get_logger(category => $pkg);
        $Log_Any_Loggers{$pkg} = $log;
    }

    my $meth = $args{str_level}; # closure :(

    my $code = sub {
        $Log_Any_Loggers{$pkg}->$meth(@_);
    };
    ["", $code];
};

my $hook_log_is = sub {
    my %args = @_;

    my $pkg = $args{package};

    {
        my $log = Log::Any->get_logger(category => $pkg);
        $Log_Any_Loggers{$pkg} = $log;
    }

    my $meth = "is_$args{str_level}"; # closure :(

    my $code = sub {
        $Log_Any_Loggers{$pkg}->$meth(@_);
    };
    ["", $code];
};

sub import {
    my $self = shift;

    unshift @Log::ger::Hooks_Create_Log_Routine, $hook_log
        unless grep { $_ == $hook_log } @Log::ger::Hooks_Create_Log_Routine;
    unshift @Log::ger::Hooks_Create_Log_Is_Routine, $hook_log_is
        unless grep { $_ == $hook_log_is } @Log::ger::Hooks_Create_Log_Is_Routine;
}

sub unimport {
    my $self = shift;

    @Log::ger::Hooks_Create_Log_Routine =
        grep { $_ != $hook_log } @Log::ger::Hooks_Create_Log_Routine;
    @Log::ger::Hooks_Create_Log_Is_Routine =
        grep { $_ != $hook_log_is } @Log::ger::Hooks_Create_Log_Is_Routine;
}

1;
# ABSTRACT: Send log to Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::LogAny - Send log to Log::Any

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::LogAny;
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

=head1 TODO

Can we use L<B::CallChecker> to replace log_XXX calls directly, avoiding extra
call level?

=head1 SEE ALSO

L<Log::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
