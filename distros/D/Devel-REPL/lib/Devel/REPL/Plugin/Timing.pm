use strict;
use warnings;
package Devel::REPL::Plugin::Timing;
# ABSTRACT: Display execution times

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Time::HiRes 'time';
use namespace::autoclean;

around 'eval' => sub {
    my $orig = shift;
    my ($self, $line) = @_;

    my @ret;
    my $start = time;

    if (wantarray) {
        @ret = $self->$orig($line);
    }
    else {
        $ret[0] = $self->$orig($line);
    }

    $self->print("Took " . (time - $start) . " seconds.\n");
    return @ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Timing - Display execution times

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

 # in your re.pl file:
 use Devel::REPL;
 my $repl = Devel::REPL->new;
 $repl->load_plugin('Timing');

 # after you run re.pl:
 $ sum map $_*100, 1..100000;
 Took 0.0830280780792236 seconds.
 500005000000

 $

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
