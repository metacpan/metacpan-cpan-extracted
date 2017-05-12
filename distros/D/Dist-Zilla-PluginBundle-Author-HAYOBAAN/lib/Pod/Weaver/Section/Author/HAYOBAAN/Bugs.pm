package Pod::Weaver::Section::Author::HAYOBAAN::Bugs;
use strict;
use warnings;

# ABSTRACT: Improved version of Pod::Weaver::Section::Bugs, adds proper links to the BUGS pod section
our $VERSION = '0.012'; # VERSION

use Moose;
use namespace::autoclean;
with 'Pod::Weaver::Role::Section';

#pod =head1 OVERVIEW
#pod
#pod Just like the original L<Section::Bugs|Pod::Weaver::Section::Bugs>
#pod plugin, this section plugin will produce a hunk of Pod giving bug
#pod reporting information for the document. However, instead of a
#pod text-only link, this plugin will create a proper, clickable, link.
#pod
#pod =head1 USAGE
#pod
#pod Add the following line to your F<weaver.ini>:
#pod
#pod     [Author::HAYOBAAN::Bugs]
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * The original L<Section::Bugs|Pod::Weaver::Section::Bugs> plugin.
#pod
#pod =cut

#pod =attr header
#pod
#pod The title of the header to be added.
#pod
#pod Default: C<BUGS>
#pod
#pod =cut

has header => (
  is      => 'ro',
  isa     => 'Str',
  default => 'BUGS',
);

#pod =for Pod::Coverage weave_section
#pod
#pod =cut

sub weave_section {
    my ($self, $document, $input) = @_;

    return unless exists $input->{distmeta}{resources}{bugtracker};

    my $bugtracker = $input->{distmeta}{resources}{bugtracker};
    my ($web,$mailto) = @{$bugtracker}{qw/web mailto/};
    return unless defined $web || defined $mailto;

    my $text = "Please report any bugs or feature requests ";

    if (defined $web) {
        $text .= "on the bugtracker\nL<website|$web>";
        $text .= defined $mailto ? "\n or " : ".\n";
    }

    if (defined $mailto) {
        $text .= "by L<email|mailto:$mailto>.\n";
    }

    $text .= <<'HERE';

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.
HERE

    push @{ $document->children },
        Pod::Elemental::Element::Nested->new({
            command  => 'head1',
            content  => $self->header,
            children => [
                Pod::Elemental::Element::Pod5::Ordinary->new({ content => $text }),
            ],
        });

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Author::HAYOBAAN::Bugs - Improved version of Pod::Weaver::Section::Bugs, adds proper links to the BUGS pod section

=head1 VERSION

version 0.012

=head1 OVERVIEW

Just like the original L<Section::Bugs|Pod::Weaver::Section::Bugs>
plugin, this section plugin will produce a hunk of Pod giving bug
reporting information for the document. However, instead of a
text-only link, this plugin will create a proper, clickable, link.

=head1 USAGE

Add the following line to your F<weaver.ini>:

    [Author::HAYOBAAN::Bugs]

=head1 ATTRIBUTES

=head2 header

The title of the header to be added.

Default: C<BUGS>

=for Pod::Coverage weave_section

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/Dist-Zilla-PluginBundle-Author-HAYOBAAN/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over 4

=item *

The original L<Section::Bugs|Pod::Weaver::Section::Bugs> plugin.

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
