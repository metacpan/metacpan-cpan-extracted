package Log::ger::Output::LogAny;

our $DATE = '2017-06-26'; # DATE
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $pkg;
                if ($args{target} eq 'package') {
                    $pkg = $args{target_arg};
                } elsif ($args{target} eq 'object') {
                    $pkg = ref $args{target_arg};
                } else {
                    return [];
                }

                # use init_args as a per-target stash
                $args{init_args}{_la} ||= do {
                    require Log::Any;
                    Log::Any->get_logger(category => $pkg);
                };

                my $meth = $args{str_level};
                my $logger = sub {
                    my $ctx = shift;
                    $args{init_args}{_la}->$meth(@_);
                };
                [$logger];
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

version 0.006

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
