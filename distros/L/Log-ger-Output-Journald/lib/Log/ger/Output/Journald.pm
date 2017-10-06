package Log::ger::Output::Journald;

our $DATE = '2017-09-28'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

sub get_hooks {
    my %conf = @_;

    require Log::Journald;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $logger = sub {
                    my %log;
                    $log{PRIORITY} = $args{level};
                    if (ref $_[1] eq 'HASH') {
                        $log{$_} = $_[1]{$_} for keys %{$_[1]};
                    } else {
                        $log{MESSAGE} = $_[1];
                    }
                    Log::Journald::send(%log) or warn $!;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Send logs to journald

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Journald - Send logs to journald

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Output 'Journald' => (
 );
 use Log::ger;

 log_warn "blah ...";

=head1 DESCRIPTION

This output plugin sends logs to journald using L<Log::Journald>.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head1 SEE ALSO

L<Log::ger>

L<Log::Journald>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
