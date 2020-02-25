requires 'Exporter';
requires 'Getargs::Mixed', '1.06';
requires 'Scalar::Util', '1.50';
requires 'parent';
requires 'perl', '5.006';
requires 'strict';
requires 'warnings';

on configure => sub {
    requires 'Config';
    requires 'ExtUtils::MakeMaker';
    requires 'File::Spec';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Data::Dumper';
    requires 'Import::Into';
    requires 'Test::Fatal';
    requires 'Test::More';
    requires 'lib::relative', '0.002';
};

on develop => sub {
    requires 'App::RewriteVersion';
    requires 'Module::Metadata', '1.000016';
    requires 'Path::Class';
};
