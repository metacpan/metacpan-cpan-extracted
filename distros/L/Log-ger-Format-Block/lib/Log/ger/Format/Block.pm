package Log::ger::Format::Block;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger-Format-Block'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

use Sub::Metadata qw(mutate_sub_prototype);

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_;

                my $formatter = sub { my $code = shift; $code->(@_) };
                [$formatter];
            }],

        before_install_routines => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                no strict 'refs';

                my %hook_args = @_;

                for my $r (@{ $hook_args{routines} }) {
                    my ($coderef, $name, $lnum, $type) = @$r;
                    next unless $type =~ /\Alog(ger)?_/;
                    # avoid prototype mismatch warning when redefining
                    if ($hook_args{target_type} eq 'package' ||
                            $hook_args{target_type} eq 'object') {
                        if (defined ${"$hook_args{target_name}\::"}{$name}) {
                            delete ${"$hook_args{target_name}\::"}{$name};
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

version 0.006

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

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
