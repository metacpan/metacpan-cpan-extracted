use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use String::Cushion;
use syntax 'qi';
use Test::DZil;
use Dist::Zilla::Plugin::NextRelease::Grouped;

$SIG{'__WARN__'} = sub {
    # Travis has an uninitialized warning in CPAN::Changes on 5.10
    if($] < 5.012000 && caller eq 'CPAN::Changes') {
        diag 'Caught warning: ' . shift;
    }
    else {
        warn shift;
    }
};

{
    package Dist::Zilla::Plugin::UploadToCPAN::Mock;

    use Moose;
    use namespace::autoclean;
    with qw/Dist::Zilla::Role::Releaser/;

    sub cpanid { 'SOMEONESNAME' };
    sub release { }

    __PACKAGE__->meta->make_immutable;
}

subtest simple => sub {
    my $changes = changer({ Empty => [] }, { 'Documentation' => ['A change']});

    my $ini = make_ini({ groups => 'Api, Empty, Documentation' });
    my $tzil = make_tzil($ini, $changes);

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    common_tests($tzil);
    like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';

};
subtest auto_order => sub {
    my $changes = changer({ Empty => [] }, { 'Documentation' => ['A change']}, { 'Api' => ['Added some api']});

    my $ini = make_ini({ groups => 'Documentation, Api, Empty', auto_order => 1 });
    my $tzil = make_tzil($ini, $changes);

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    common_tests($tzil);
    like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';
    like $tzil->slurp_file('build/Changes'), qr{\[Api\].*\[Documentation\]}ms, 'Auto ordered';
};
subtest auto_order_off => sub {
    my $changes = changer({ Empty => [] }, { 'Documentation' => ['A change']}, { 'Api' => ['Added some api']}, { 'Custom Group' => ['Custom, with a change']});

    my $ini = make_ini({ groups => 'Empty, Documentation, Api', auto_order => 0 });
    my $tzil = make_tzil($ini, $changes);

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    common_tests($tzil);
    like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';
    like $tzil->slurp_file('build/Changes'), qr{\[Custom Group\].*\[Documentation\].*\[Api\]}ms, 'Ordered as given, with custom group first';
};

subtest trial => sub {
    my $changes = changer({ 'Documentation' => ['A change']});
    my $ini = make_ini({ groups => 'Api, Empty, Documentation', format_note => '%{THIS IS TRIAL}T', auto_order => 0 });
    local $ENV{'TRIAL'} = 1;
    my $tzil = make_tzil($ini, $changes);

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    common_tests($tzil);
    like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';
    like $tzil->slurp_file('build/Changes'), qr{THIS IS TRIAL}, 'Trial release';
};

subtest pause_user => sub {
    my $changes = changer({ 'Documentation' => ['A change']});
    my $ini = make_ini(
        { groups => 'Api, Documentation, Empty', format_note => 'released by %P', format_date => '%{yyyy-MM-dd HH:mm:ss VVV}d', auto_order => 0 },
        [ '%PAUSE' => { username => 'SOMEONESNAME', password => 'obladi'} ],
    );
    my $tzil = make_tzil($ini, $changes);

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    common_tests($tzil);
    like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';
    like $tzil->slurp_file('source/Changes'), qr{released by SOMEONESNAME}, 'Pause user in source Changes';
    like $tzil->slurp_file('build/Changes'), qr{released by SOMEONESNAME}, 'Pause user in build Changes';
};

done_testing;

sub common_tests {
    my $tzil = shift;
    my $version = $tzil->version;
    unlike $tzil->slurp_file('source/lib/DZT/NextReleaseGrouped.pm'), qr{$version}, 'Version changed in .pm';
    like $tzil->slurp_file('build/Changes'), qr{$version}, 'Version change in built Changes';
    like $tzil->slurp_file('source/Changes'), qr{$version}, 'Version change in source Changes';
    unlike $tzil->slurp_file('build/Changes'), qr{\[Empty\]}, 'Empty groups removed in built Changes';
}

sub make_ini {
    my $grouped_args = shift;
    return simple_ini({ version => undef },
          ['NextRelease::Grouped', $grouped_args ], qw/
            RewriteVersion
            GatherDir
            UploadToCPAN::Mock
            BumpVersionAfterRelease
        /,
            @_
    );
}

sub make_tzil {
    my $ini = shift;
    my $changes = shift;

    return Builder->from_config(
        {   dist_root => 't/corpus' },
        {
            add_files => {
                'source/Changes' => $changes,
                'source/dist.ini' => $ini,
            },
        },
    );
}

sub changer {

    my $added_groups = cushion 0, 0, join ("\n\n" => map {
        my $data = $_;
        my $group = (keys %{ $data })[0];
        my @changes = @{ $data->{ $group } };

        join "\n" => (" [$group]", @changes);
    } @_);

    return cushion 0, 1, qqi{
        Revision history for {{@{[ '$dist->name' ]}}}

        {{@{['$NEXT']}}}
        $added_groups

        0.0001  1999-02-04T10:42:19Z UTC
         - First release
    };
}


