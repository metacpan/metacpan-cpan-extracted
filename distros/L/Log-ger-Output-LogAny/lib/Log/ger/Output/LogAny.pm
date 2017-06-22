package Log::ger::Output::LogAny;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Log::Any ();
use Log::ger::Util;

my %Log_Any_Loggers;

sub PRIO_create_log_routine { 50 }

sub create_log_routine {
    my ($self, %args) = @_;

    return unless $args{target} eq 'package';
    my $pkg = $args{target_arg};

    {
        my $log = Log::Any->get_logger(category => $pkg);
        $Log_Any_Loggers{$pkg} = $log;
    }

    my $meth = $args{str_level}; # closure :(

    my $code = sub {
        my $ctx = shift;
        $Log_Any_Loggers{$pkg}->$meth(@_);
    };
    [$code];
};

sub import {
    my $self = shift;

    Log::ger::Util::add_plugin('create_log_routine', __PACKAGE__, 'replace');
}

1;
# ABSTRACT: Send log to Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::LogAny - Send log to Log::Any

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Log::ger::Output::LogAny;
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

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
