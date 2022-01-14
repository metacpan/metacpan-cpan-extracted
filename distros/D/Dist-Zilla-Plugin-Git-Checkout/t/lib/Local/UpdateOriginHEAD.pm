package Local::UpdateOriginHEAD;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;

with 'Dist::Zilla::Role::Plugin';

use Git::Background 0.003;
use Path::Tiny;

use namespace::autoclean;

our $NOK;

around plugin_from_config => sub {
    my $orig         = shift @_;
    my $plugin_class = shift @_;

    my $instance = $plugin_class->$orig(@_);

    $NOK = undef;

    {
        local $@;    ##no critic (Variables::RequireInitializationForLocalVars)

        my $ok = eval {
            my $workspace = path( $instance->zilla->root )->child('ws');
            Git::Background->run( qw(remote set-head origin dev), { dir => $workspace } )->get;

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
