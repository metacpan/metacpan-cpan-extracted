use strict;
use warnings;
package Devel::REPL::Plugin::OutputCache;
# ABSTRACT: Remember past results, _ is most recent

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;

has output_cache => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    lazy    => 1,
);

has warned_about_underscore => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
);

around 'eval' => sub {
    my $orig = shift;
    my ($self, $line) = @_;

    my $has_underscore = *_{CODE};
    if ($has_underscore && !$self->warned_about_underscore) {
        warn "OutputCache: Sub _ already defined.";
        $self->warned_about_underscore(1);
    }
    else {
        # if _ is removed, then we should warn about it again if it comes back
        $self->warned_about_underscore(0);
    }

    # this needs to be a postfix conditional for 'local' to work
    local *_ = sub () { $self->output_cache->[-1] } unless $has_underscore;

    my @ret;
    if (wantarray) {
        @ret = $self->$orig($line);
    }
    else {
        $ret[0] = $self->$orig($line);
    }

    push @{ $self->output_cache }, @ret > 1 ? \@ret : $ret[0];
    return wantarray ? @ret : $ret[0];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::OutputCache - Remember past results, _ is most recent

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

    > 21 / 7
    3
    > _ * _
    9
    > sub { die "later" }
    sub { die "later" }
    > _->()
    Runtime error: later

=head1 DESCRIPTION

Re-using results is very useful when working in a REPL. With C<OutputCache> you
get C<_>, which holds the past result. The benefit is that you can build up
your result instead of having to type it in all at once, or store it in
intermediate variables. C<OutputCache> also provides
C<< $_REPL->output_cache >>, an array reference of all results in this session.

L<Devel::REPL> already has a similar plugin, L<Devel::REPL::Plugin::History>.
There are some key differences though:

=over 4

=item Input vs Output

C<History> remembers input. C<OutputCache> remembers output.

=item Munging vs Pure Perl

C<History> performs regular expressions on your input. C<OutputCache> provides
the C<_> sub as a hook to get the most recent result, and
C<< $_REPL->output_cache >> for any other results.

=item Principle of Least Surprise

C<History> will replace exclamation points in any part of the input. This is
problematic if you accidentally include one in a string, or in a C<not>
expression. C<OutputCache> uses a regular (if oddly named) subroutine so Perl
does the parsing -- no surprises.

=back

=head1 CAVEATS

The C<_> sub is shared across all packages. This means that if a module is
using the C<_> sub, then there is a conflict and you should not use this
plugin. For example, L<Jifty> uses the C<_> sub for localization. L<Jifty> is the
only known user.

=head1 SEE ALSO

C<Devel::REPL>, C<Devel::REPL::Plugin::History>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Shawn M Moore

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
