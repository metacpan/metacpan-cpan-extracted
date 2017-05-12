requires 'perl' => "5.006";
requires 'Future' => '0.29';
requires 'Devel::GlobalDestruction' => "0";
requires 'Scalar::Util' => 0;
requires 'Carp' => 0;
requires 'Try::Tiny' => 0;
requires "parent" => 0;

on "test", sub {
    requires 'Test::More' => 0;
    requires 'FindBin' => 0;
    requires 'Carp' => 0;
    requires 'Scalar::Util' => 0;
    requires 'Test::MockModule' => "0.05";
    requires 'Test::Identity' => 0;
    requires 'Test::Memory::Cycle' => 0;
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
