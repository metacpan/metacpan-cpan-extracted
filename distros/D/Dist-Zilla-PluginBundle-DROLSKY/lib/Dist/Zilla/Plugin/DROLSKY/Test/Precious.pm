package Dist::Zilla::Plugin::DROLSKY::Test::Precious;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.19';

use Dist::Zilla::File::InMemory;

use Moose;

with 'Dist::Zilla::Role::FileGatherer';

my $test = <<'EOF';
use strict;
use warnings;

use Test::More;

use Capture::Tiny qw( capture );
use Encode qw( decode );
use FindBin qw( $Bin );

binmode $_, ':encoding(utf-8)'
    for map { Test::More->builder->$_ }
    qw( output failure_output todo_output );

chdir "$Bin/../.."
    or die "Cannot chdir to $Bin/../..: $!";

my ( $out, $err ) = capture { system(qw( precious lint -a )) };
$_ = decode( 'UTF-8', $_ ) for grep {defined} $out, $err;

is( $? >> 8, 0, 'precious lint -a exited with 0' )
    or diag($out);
is( $err, q{}, 'no output to stderr' );

done_testing();
EOF

sub gather_files {
    my $self = shift;

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name    => 'xt/author/precious.t',
            content => $test,
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates a test that runs precious

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::Test::Precious - Creates a test that runs precious

=head1 VERSION

version 1.19

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
