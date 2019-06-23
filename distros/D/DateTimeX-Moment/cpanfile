requires 'Class::Accessor::Lite';
requires 'Class::Inspector';
requires 'DateTime::Locale';
requires 'DateTime::Duration';
requires 'DateTime::TimeZone';
requires 'List::Util';
requires 'Scalar::Util';
requires 'Time::Moment', '0.38';
requires 'perl', '5.008001';

recommends 'DateTime';
recommends 'Data::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::Fatal';
    requires 'Test::More', '0.98';
    requires 'Test::Warnings', '0.005';
};

on develop => sub {
    requires 'feature';
};
