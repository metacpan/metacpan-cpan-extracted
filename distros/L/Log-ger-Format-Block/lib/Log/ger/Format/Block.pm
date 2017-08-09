package Log::ger::Format::Block;

our $DATE = '2017-08-01'; # DATE
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use Sub::Metadata qw(mutate_sub_prototype);

sub get_hooks {
    my %conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                [sub { my $code = shift; $code->(@_) }];
            }],

        before_install_routines => [
            __PACKAGE__, 50,
            sub {
                no strict 'refs';

                my %args = @_;
                for my $r (@{ $args{routines} }) {
                    my ($coderef, $name, $lnum, $type) = @$r;
                    next unless $type =~ /\Alog_/;
                    # avoid prototype mismatch warning when redefining
                    if ($args{target} eq 'package' ||
                            $args{target} eq 'object') {
                        if (defined ${"$args{target_arg}\::"}{$name}) {
                            delete ${"$args{target_arg}\::"}{$name};
                        }
                    }
                    mutate_sub_prototype($coderef, '&');
                }
                [1];
            }],
    };
}

1;
# ABSTRACT: Use formatting using block instead of sprintf-style

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::Block - Use formatting using block instead of sprintf-style

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Log::ger::Format 'Block';
 use Log::ger;

After that, you can use your logging routine a la L<Log::Contextual> in the
importing package:

 # the following block won't run if debug is off
 log_debug { "the new count in the database is " . $rs->count };

=head1 DESCRIPTION

Caveat: you have to do this in the compile-time phase (like shown in Synopsis).

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger>

L<Log::Contextual>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
