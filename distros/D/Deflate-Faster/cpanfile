requires 'perl', '5.010';
requires 'XSLoader';
requires 'Exporter';
requires 'Carp';

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
    recommends 'ExtUtils::PkgConfig';
    recommends 'Alien::libdeflate', '0.03';
};

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'File::Temp';
};
