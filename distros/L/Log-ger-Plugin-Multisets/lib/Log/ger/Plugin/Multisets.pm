package Log::ger::Plugin::Multisets;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-04'; # DATE
our $DIST = 'Log-ger-Plugin-Multisets'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub get_hooks {
    my %conf = @_;

    die "Please specify at least one of ".
        "log_sub_prefixes|is_sub_prefixes|log_method_prefixes|is_method_prefixes"
        unless
        $conf{log_sub_prefixes} ||
        $conf{is_sub_prefixes} ||
        $conf{log_method_prefixes} ||
        $conf{is_method_prefixes};

    return {
        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_;

                my $levels = [keys %Log::ger::Levels];

                my $routine_names = {};
                for my $key0 (qw(log_sub is_sub log_method is_method)) {
                    my $routine_names_key = "${key0}s";
                    my $conf_key = "${key0}_prefixes";
                    $routine_names->{$routine_names_key} = [];
                    next unless $conf{$conf_key};
                    for my $prefix (keys %{ $conf{$conf_key} }) {
                        my $init_args = $conf{$conf_key}{$prefix};
                        push @{ $routine_names->{$routine_names_key} }, map
                            { ["${prefix}$_", $_, undef, $init_args] }
                            @$levels;
                    }
                }

                [$routine_names, 1];
            }],
    };
}

1;
# ABSTRACT: Create multiple sets of logger routines, each set with its own init arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::Multisets - Create multiple sets of logger routines, each set with its own init arguments

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Instead of having to resort to OO style to log to different categories:

 use Log::ger ();

 my $access_log = Log::ger->get_logger(category => 'access');
 my $error_log  = Log::ger->get_logger(category => 'error');

 $access_log->info ("goes to access log");
 $access_log->warn ("goes to access log");
 $error_log ->warn ("goes to error log");
 $error_log ->debug("goes to error log");
 ...

you can instead:

 use Log::ger::Plugin Multisets => (
     log_sub_prefixes => {
         # prefix  => init args
         log_      => {category=>'error' }, # or undef, to use the default init args (including category)
         access_   => {category=>'access'},
     },
     is_sub_prefixes => {
         # prefix   => category
         is_        => {category=>'error' },
         access_is_ => {category=>'access'},
     },
 );
 use Log::ger;

 access_info "goes to access log";
 access_warn "goes to access log";
 log_warn    "goes to error log";
 log_debug   "goes to error log";
 ...

=head1 DESCRIPTION

This plugin lets you create multiple sets of logger subroutines, each set with
its own init arguments. This can be used e.g. when you want to log to different
categories without resorting to OO style.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 log_sub_prefixes

Hash.

=head2 is_sub_prefixes

Hash.

=head2 log_method_prefixes

Hash.

=head2 is_method_prefixes

Hash.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
