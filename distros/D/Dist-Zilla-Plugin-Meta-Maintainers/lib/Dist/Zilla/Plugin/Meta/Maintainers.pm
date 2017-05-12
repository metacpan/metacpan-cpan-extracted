package Dist::Zilla::Plugin::Meta::Maintainers;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Moose;

has maintainer => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

with 'Dist::Zilla::Role::MetaProvider';

sub mvp_multivalue_args {'maintainer'}

sub metadata {
    my $self = shift;
    if ( @{ $self->maintainer } ) {
        return { x_maintainers => $self->maintainer };
    }
    else {
        return {};
    }
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Generate an x_maintainers section in distribution metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Meta::Maintainers - Generate an x_maintainers section in distribution metadata

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  [Meta::Maintainers]
  maintainer = Dave Rolsky <autarch@urth.org>
  maintainer = Jane Schmane <jschmane@example.com>

=head1 DESCRIPTION

This plugin adds an C<x_maintainers> key in the distribution's metadata. This
will end up in the F<META.json> and F<META.yml> files, and may also be useful
for things like L<Pod::Weaver> plugins.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Meta-Maintainers> or via email to L<bug-dist-zilla-plugin-meta-maintainers@rt.cpan.org|mailto:bug-dist-zilla-plugin-meta-maintainers@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-Plugin-Meta-Maintainers can be found at L<https://github.com/houseabsolute/Dist-Zilla-Plugin-Meta-Maintainers>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
