use strict;
use warnings;

use autodie 'system';
use IPC::System::Simple (); # for autodie && prereqs

use Path::Tiny;

use Test::More;
use Test::Fatal;
use Test::Moose::More 0.004;

require 't/funcs.pm' unless eval { require funcs };

use Dist::Zilla::Plugin::Git::CheckFor::Fixups;

validate_class 'Dist::Zilla::Plugin::Git::CheckFor::Fixups' => (
    does => [
        'Dist::Zilla::Role::Git::Repo::More',
        'Dist::Zilla::Role::BeforeRelease',
    ],
);

sub _pm        { _ack('lib/DZT/Sample.pm' => undef, 'message')         }
sub _pm_fixup  { _ack('lib/DZT/Sample.pm' => undef, "fixup! message")  }
sub _pm_squash { _ack('lib/DZT/Sample.pm' => undef, "squash! message") }

our_test(
    'simple repo, from beginning, fixup',
    [ _pm_fixup ],
    qr/Aborting release; found squash or fixup commits:/,
);

our_test(
    'simple repo, from beginning, squash',
    [ _pm_squash ],
    qr/Aborting release; found squash or fixup commits:/,
);

our_test(
    'lives -- no squash or fixups',
    [  ],
    sub { ok !$_[0], $_[1] },
);

done_testing;  # <==========

sub our_tzil {
    my @additional = @_;

    #my ($tzil, $repo_root) = prep_for_testing(
    return prep_for_testing(
        repo_init => [
            sub { path(qw{ lib DZT })->mkpath },
            _ack('lib/DZT/Sample.pm' => 'package DZT::Sample; use Something; 1;'),
            @additional
        ],
        core_args   => { version => undef },
        plugin_list => [ qw(GatherDir Git::NextVersion Git::CheckFor::Fixups FakeRelease) ],
    );
}

sub our_test {
    my ($name, $cmds, $test) = @_;

    my $test_sub
        = ref $test && ref $test eq 'CODE'
        ? $test
        : sub { like($_[0], $test, $_[1]) }
        ;

    my ($tzil, $repo_root) = our_tzil(
        _pm,
        (ref $cmds? (@$cmds) : $cmds),
        _ack('lib/DZT/Sample.pm' => undef, "a longer message... Lorem ipsum..."),
        _pm,
        _pm
    );

    my $thrown = exception { $tzil->release };
    diag_log($tzil, $test_sub->($thrown, $name));
}
