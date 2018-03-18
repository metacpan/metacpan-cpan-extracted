use Test::Most;
use Test::Deep;
use Path::Tiny;

use DracPerl::Factories::DellDefaultCommand;
use DracPerl::Factories::CommandCollection;

subtest "GetInv" => sub {
    ok my $model = DracPerl::Factories::DellDefaultCommand->create( 'getInv',
        { xml => _load_xml_for('getInv') } );

    cmp_deeply(
        $model,
        methods(
            controllers => [
                methods(
                    name             => 'PERC H700 Integrated',
                    id               => 'RAID.Slot.4-1',
                    firmware_version => '12.3.0-0032'
                )
            ],
            memories => [
                methods(
                    id          => 'DIMM.Socket.B4',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.B3',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.B2',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.B1',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.A4',
                    part_number => 'HMT31GR7BFR4A-H9',
                    model       => 'DDR3 DIMM',
                    size        => '8192 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.A3',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.A2',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
                methods(
                    id          => 'DIMM.Socket.A1',
                    part_number => 'M393B5273CH0-YH9',
                    model       => 'DDR3 DIMM',
                    size        => '4096 MB',
                    speed       => '1333 MHz',
                ),
            ],
            bios_version => "1.4.0",
            lcc_version  => '1.4.0.445',
            diag         => 'XXXX',
            os_drivers   => '6.3.0.23'
        ),
        "Object ok"
    );
};

done_testing();

sub _load_xml_for {
    my $name = shift;
    return path( 't/fixtures/xmls/' . $name . '.xml' )->slurp;
}
