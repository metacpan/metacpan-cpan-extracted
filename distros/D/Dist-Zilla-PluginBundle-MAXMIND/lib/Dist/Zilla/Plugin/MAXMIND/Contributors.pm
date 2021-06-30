package Dist::Zilla::Plugin::MAXMIND::Contributors;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.84';

use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

my $mailmap = <<'EOF';
Dave Rolsky <drolsky@maxmind.com> <autarch@urth.org>
Greg Oschwald <goschwald@maxmind.com> Gregory Oschwald <goschwald@maxmind.com>
Greg Oschwald <goschwald@maxmind.com> <oschwald@gmail.com>
Mateu X Hunter <mhunter@maxmind.com> <hunter@missoula.org>
Olaf Alders <oalders@maxmind.com> <olaf@wundersolutions.com>
Ran Eilam <reilam@maxmind.com> <ran.eilam@gmail.com>
Ran Eilam <reilam@maxmind.com> <eilara@users.noreply.github.com>
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

Dist::Zilla::Plugin::MAXMIND::Contributors - Creates a .mailmap to populate Contributors in docs

=head1 VERSION

version 0.84

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
