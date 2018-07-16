package Dist::Zilla::Plugin::ATOOMIC::Contributors;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.00';

use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

my $mailmap = <<'EOF';
Nicolas R <atoomic@cpan.org> <devnull@localhost>
EOF

my %files = (
    '.mailmap' => $mailmap,
);

# These files need to actually exist on disk for the Pod::Weaver plugin to see
# them, so we can't simply add them as InMemory files via file injection.
sub before_build {
    my $self = shift;

    for my $file ( keys %files ) {
        next if -e $file;

        open my $fh, '>:encoding(UTF-8)', $file;
        print {$fh} $files{$file}
            or die "Cannot write to $files{$file}: $!";
        close $fh;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates a .mailmap to populate Contributors in docs

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ATOOMIC::Contributors - Creates a .mailmap to populate Contributors in docs

=head1 VERSION

version 1.00

=for Pod::Coverage .*

=head1 SUPPORT

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-ATOOMIC can be found at L<https://github.com/atoomic/Dist-Zilla-PluginBundle-ATOOMIC>.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Nicolas R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
