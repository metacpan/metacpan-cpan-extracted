package Dist::Zilla::App::Command::gh;
# ABSTRACT: Use the GitHub plugins from the command-line

use strict;
use warnings;

our $VERSION = '0.43';

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod     # create a new GitHub repository for your dist
#pod     $ dzil gh create [<repository>]
#pod
#pod     # update GitHub repo information
#pod     $ dzil gh update
#pod
#pod =cut

sub abstract    { 'use the GitHub plugins from the command-line' }
sub description { 'Use the GitHub plugins from the command-line' }
sub usage_desc  { '%c %o [ update | create [<repository>] ]' }

sub opt_spec {
    [ 'profile|p=s',  'name of the profile to use',
        { default => 'default' }  ],

    [ 'provider|P=s', 'name of the profile provider to use',
        { default => 'Default' }  ],
}

sub execute {
    my ($self, $opt, $arg) = @_;

    my $zilla = $self->zilla;

    $_->gather_files for
        @{ $zilla->plugins_with(-FileGatherer) };

    if ($arg->[0] eq 'create') {
        require Dist::Zilla::Dist::Minter;

        my $minter = Dist::Zilla::Dist::Minter->_new_from_profile(
            [ $opt->provider, $opt->profile ], {
                chrome => $self->app->chrome,
                name   => $zilla->name,
            },
        );

        my $create = _find_plug($minter, 'GitHub::Create');
        my $root   = `pwd`; chomp $root;
        my $repo   = $arg->[1];

        $create->after_mint({
            mint_root => $root,
            repo      => $repo,
            descr     => $zilla->abstract
        });
    } elsif ($arg->[0] eq 'update') {
        _find_plug($zilla, 'GitHub::Update')->after_release;
    }
}

sub _find_plug {
    my ($self, $name) = @_;

    foreach (@{ $self->plugins }) {
        return $_ if $_->plugin_name =~ /$name/;
    }
}

1; # End of Dist::Zilla::App::Command::gh

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::gh - Use the GitHub plugins from the command-line

=head1 VERSION

version 0.43

=head1 SYNOPSIS

    # create a new GitHub repository for your dist
    $ dzil gh create [<repository>]

    # update GitHub repo information
    $ dzil gh update

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GitHub>
(or L<bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org>).

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
