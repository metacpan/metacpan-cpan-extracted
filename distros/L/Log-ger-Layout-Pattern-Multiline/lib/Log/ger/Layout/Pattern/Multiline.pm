package Log::ger::Layout::Pattern::Multiline;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Layout-Pattern-Multiline'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Log::ger::Layout::Pattern ();

sub meta { +{
    v => 2,
} }

sub _layout {
    my $format = shift;
    my $msg = shift;
    #my ($per_target_conf, $lvlnum, $lvlname, $per_msg_conf) = @_;

    join(
        "\n",
        map {
            Log::ger::Layout::Pattern::_layout($format, [], [], $_, @_)
          }
            split(/\R/, $msg)
        );
}

sub get_hooks {
    my %plugin_conf = @_;

    $plugin_conf{format} or die "Please specify format";

    return {
        create_layouter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $layouter = sub {
                    _layout($plugin_conf{format}, @_);
                };
                [$layouter];
            }],
    };
}

1;
# ABSTRACT: Pattern layout (with multiline message split)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout::Pattern::Multiline - Pattern layout (with multiline message split)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Log::ger::Layout 'Pattern::Multiline', format => '%d (%F:%L)> %m';
 use Log::ger;

=head1 DESCRIPTION

This is just like L<Log::ger::Layout::Pattern> except that multiline log message
is split per-line so that a message like C<"line1\nline2\nline3"> (with C<<
"[%r] %m" >> format) is not laid out as:

 [0.003] line1
 line2
 line3

but as:

 [0.003] line1
 [0.003] line2
 [0.003] line3

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Layout::Pattern>

Modelled after L<Log::Log4perl::Layout::PatternLayout::Multiline>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
