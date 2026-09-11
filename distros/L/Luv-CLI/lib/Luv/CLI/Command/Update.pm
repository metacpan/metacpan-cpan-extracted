package Luv::CLI::Command::Update;

# ABSTRACT: refresh the local library registry cache

use v5.38;

use App::Cmd::Setup -command;
use File::HomeDir;

use Luv::CLI::Registry;

sub abstract {"Refreshes the local library registry cache."}

sub execute ( $self, $opt, $args ) {
    my $cache_path = File::HomeDir->my_home . '/.cache/luv/registry.json';
    my $registry   = Luv::CLI::Registry->new( cache_path => $cache_path );

    my $count = $registry->refresh;
    print "Registry updated: $count libraries indexed\n";
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Command::Update - refresh the local library registry cache

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    luv update

=head1 DESCRIPTION

Fetches the current awesome-love2d README, parses it, and overwrites
the local registry cache used by C<luv search> and C<luv add>.

=head1 NAME

Luv::CLI::Command::Update - refresh the local library registry cache

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
