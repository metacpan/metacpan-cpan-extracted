use strict;
use warnings;
package Dist::Zilla::Plugin::Run::Clean;
# ABSTRACT: execute a command of the distribution on 'dzil clean'
# vim: set ts=8 sts=2 sw=2 tw=115 et :

our $VERSION = '0.050';

use Moose;
with
    'Dist::Zilla::Role::Plugin',
    'Dist::Zilla::Plugin::Run::Role::Runner';

use Moose::Util ();
use namespace::autoclean;

{
    use Dist::Zilla::Dist::Builder;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Dist::Builder');
    $meta->make_mutable;
    Moose::Util::add_method_modifier($meta, 'after',
        [
            clean => sub {
                my ($zilla, $dry_run) = @_;
                foreach my $plugin (grep $_->isa(__PACKAGE__), @{ $zilla->plugins })
                {
                    # Dist::Zilla really ought to have a -CleanerProvider hook...
                    $plugin->clean($dry_run);
                }
            },
        ],
    );
    $meta->make_immutable;
}

sub clean
{
    my ($self, $dry_run) = @_;

    # may need some subrefs for positional parameters?
    my $params = {};

    foreach my $run_cmd (@{$self->run}) {
        $self->_run_cmd($run_cmd, $params, $dry_run);
    }

    if (my @code = @{ $self->eval }) {
        my $code = join "\n", @code;
        $self->_eval_cmd($code, $params, $dry_run);
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Run::Clean - execute a command of the distribution on 'dzil clean'

=head1 VERSION

version 0.050

=head1 SYNOPSIS

In your F<dist.ini>:

    [Run::Clean]
    run = script/do_that.pl
    eval = unlink scratch.dat

=head1 DESCRIPTION

This plugin executes the specified command(s) when cleaning the distribution.

=head1 POSITIONAL PARAMETERS

See L<Dist::Zilla::Plugin::Run/CONVERSIONS>
for the list of common formatting variables available to all plugins.
(Some of them may not work properly, because the distribution is not built
when running the clean command. These are not tested yet - patches welcome!)

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Run>
(or L<bug-Dist-Zilla-Plugin-Run@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Run@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by L<Raudssus Social Software|https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
