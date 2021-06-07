package Log::ger::Format::HashArgs;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-18'; # DATE
our $DIST = 'Log-ger-Format-HashArgs'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    my $sub_name    = $plugin_conf{sub_name}    || "log";
    my $method_name = $plugin_conf{method_name} || "log";

    return {
        create_filter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $filter = sub {
                    my %log_args = @_;
                    # die "$logger_name(): Please specify 'level'" unless exists $log_args{level};
                    my $level = Log::ger::Util::numeric_level($log_args{level});
                    return 0 unless $level <= $Log::ger::Current_Level;
                    my $per_msg_conf = {level=>$level};
                    $per_msg_conf->{category} = $log_args{category}
                        if defined $log_args{category};
                    $per_msg_conf;
                };

                [$filter, 0, 'ml_hashargs'];
            },
        ],

        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $formatter = sub {
                    my %log_args = @_;
                    $log_args{message};
                };

                [$formatter, 0, 'ml_hashargs'];
            },
        ],

        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                return [{
                    log_subs    => [[$sub_name   , undef, 'ml_hashargs', undef, 'ml_hashargs']],
                    log_methods => [[$method_name, undef, 'ml_hashargs', undef, 'ml_hashargs']],
                }, $plugin_conf{exclusive}];
            },
        ],

    };
}

1;
# ABSTRACT: Log using hash arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::HashArgs - Log using hash arguments

=head1 VERSION

version 0.005

=head1 SYNOPSIS

To use for the current package:

 use Log::ger::Format 'HashArgs', (
     # sub_name    => 'log_it', # the default name is 'log'
     # method_name => 'log_it', # the default name is 'log'
     # exclusive => 1,          # optional, defaults to 0
 );
 use Log::ger::Output 'Screen';
 use Log::ger;

 log_it(level => 'info', message => 'an info message ...'); # won't be output to screen
 log_it(level => 'warn', message => 'a warning!');          # will be output

To set category:

 log_it(category=>..., level=>..., message=>...);

=head1 DESCRIPTION

This is a format plugin to log using a single log subroutine that is passed the
message as well as the level, using hash arguments.

Note: the multilevel log is slightly slower because of the extra argument and
additional string level -> numeric level conversion. See benchmarks in
L<Bencher::Scenarios::LogGer>.

Note: the individual separate C<log_LEVEL> subroutines (or C<LEVEL> methods) are
still installed, unless you specify configuration L</exclusive> to true.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 sub_name

Str. Logger subroutine name. Defaults to C<log> if not specified.

=head2 method_name

Str. Logger method name. Defaults to C<log> if not specified.

=head2 exclusive

Boolean. If set to true, will block the generation of the default C<log_LEVEL>
subroutines or C<LEVEL> methods (e.g. C<log_warn>, C<trace>, ...).

=head1 SEE ALSO

L<Log::ger::Like::LogDispatch> which uses this plugin. The interface provided by
this HashArgs plugin is similar to L<Log::Dispatch> interface.

L<Log::ger::Format::MultilevelLog>

L<Log::ger::Plugin::Hashref>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
