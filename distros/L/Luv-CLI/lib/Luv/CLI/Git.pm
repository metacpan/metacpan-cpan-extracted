# PODNAME: Luv::CLI::Git
# ABSTRACT: git operations for fetching and updating library dependencies

use v5.38;
use Object::Pad;

use IPC::Run qw(run);

class Luv::CLI::Git;

method clone ( $url, $dest, $ref = undef ) {
    my @cmd = ( 'git', 'clone', $url, $dest );
    my ( $out, $err );
    IPC::Run::run( \@cmd, \undef, \$out, \$err )
        or die "git clone failed for '$url':\n$err";

    if ( defined $ref ) {
        $self->checkout( $dest, $ref );
    }

    return 1;
}

method checkout ( $dest, $ref ) {
    my @cmd = ( 'git', '-C', $dest, 'checkout', $ref );
    my ( $out, $err );
    IPC::Run::run( \@cmd, \undef, \$out, \$err )
        or die "git checkout '$ref' failed in '$dest':\n$err";

    return 1;
}

method pull ($dest) {
    my @cmd = ( 'git', '-C', $dest, 'pull' );
    my ( $out, $err );
    IPC::Run::run( \@cmd, \undef, \$out, \$err )
        or die "git pull failed in '$dest':\n$err";

    return 1;
}

method current_ref ($dest) {
    my @cmd = ( 'git', '-C', $dest, 'rev-parse', 'HEAD' );
    my ( $out, $err );
    IPC::Run::run( \@cmd, \undef, \$out, \$err )
        or die "git rev-parse failed in '$dest':\n$err";

    chomp $out;
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Git - git operations for fetching and updating library dependencies

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $git = Luv::CLI::Git->new;
    $git->clone('https://github.com/tesselode/baton', 'lib/baton');
    $git->pull('lib/baton');

=head1 DESCRIPTION

Thin wrapper around shelling out to the C<git> binary via L<IPC::Run>,
used to fetch and update vendored library dependencies.

=head1 NAME

Luv::CLI::Git - git operations for fetching and updating library dependencies

=head1 METHODS

=head2 clone($url, $dest, $ref)

Clones C<$url> into C<$dest>. If C<$ref> is given, checks it out after
cloning. Dies with git's stderr output on failure.

=head2 checkout($dest, $ref)

Checks out C<$ref> in the repository at C<$dest>. Dies on failure.

=head2 pull($dest)

Runs C<git pull> in the repository at C<$dest>. Dies on failure.

=head2 current_ref($dest)

Returns the current commit SHA of the repository at C<$dest>.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ogun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
