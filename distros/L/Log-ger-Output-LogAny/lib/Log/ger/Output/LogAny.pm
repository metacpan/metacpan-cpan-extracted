package Log::ger::Output::LogAny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-LogAny'; # DIST
our $VERSION = '0.009'; # VERSION

use strict;
use warnings;

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $pkg;
                if ($hook_args{target_type} eq 'package') {
                    $pkg = $hook_args{target_name};
                } elsif ($hook_args{target_type} eq 'object') {
                    $pkg = ref $hook_args{target_name};
                } else {
                    return [];
                }

                # use init_args as a per-target stash
                $hook_args{per_target_conf}{_la} ||= do {
                    require Log::Any;
                    Log::Any->get_logger(category => $pkg);
                };

                my $meth = $hook_args{str_level};
                my $outputter = sub {
                    my ($per_target_conf, $fmsg, $per_msg_conf) = @_;
                    $hook_args{per_target_conf}{_la}->$meth(
                        ref $fmsg eq 'ARRAY' ? @$fmsg : $fmsg);
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Send logs to Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::LogAny - Send logs to Log::Any

=head1 VERSION

version 0.009

=head1 SYNOPSIS

 use Log::ger::Output 'LogAny';
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

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
