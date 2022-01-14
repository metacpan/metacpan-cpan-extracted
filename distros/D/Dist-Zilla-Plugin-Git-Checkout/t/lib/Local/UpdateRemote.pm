package Local::UpdateRemote;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;

with 'Dist::Zilla::Role::Plugin';

use Git::Background 0.003;
use MooseX::Types::Moose qw(Str);
use Path::Tiny;

use namespace::autoclean;

has repo => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

our $NOK;

around plugin_from_config => sub {
    my $orig         = shift @_;
    my $plugin_class = shift @_;

    my $instance = $plugin_class->$orig(@_);

    my $repo_path = $instance->repo;

    $NOK = undef;

    {
        local $@;    ##no critic (Variables::RequireInitializationForLocalVars)

        my $ok = eval {
            my $workspace = path($repo_path)->absolute->parent->child('update_ws');
            Git::Background->run( 'clone', $repo_path, $workspace->stringify )->get;
            my $git = Git::Background->new($workspace);

            my $file_c = path($workspace)->child('C');
            $file_c->spew('1087');

            $git->run( 'add', 'C' )->get;
            $git->run( 'commit', '-m', 'third commit' )->get;

            $git->run( 'tag', '-d', 'my-tag' )->get;
            $git->run( 'tag', 'my-tag' )->get;

            $git->run('push')->get;
            $git->run( 'push', '--tags', '-f' )->get;

            1;
        };

        if ( !$ok ) {
            $NOK = $@;
        }
    }

    return $instance;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

# vim: ts=4 sts=4 sw=4 et: syntax=perl
