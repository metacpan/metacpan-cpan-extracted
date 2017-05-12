use File::Spec;

my $data_dir = File::Spec->catdir( substr( __FILE__, 0, rindex( __FILE__, "config" ) ), 'data' );

return {
    'dev.foo.deployment.resources.dir' => "$data_dir/resources",
    'dev.foo.hostname'                 => 'app.pastdev.local',
    'dev.foo.overlay.dir'              => $data_dir,
    'dev.foo.sudo_username'            => 'foo',
    'dev.os'                           => 'linux',
    'dev.root.dir'                     => '/opt/pastdev',
    }
