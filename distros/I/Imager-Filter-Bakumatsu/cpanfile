requires 'File::ShareDir', '1';
requires 'Imager';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};

on test => sub {
    requires 'File::Compare';
    requires 'File::Temp';
};

on develop => sub {
    requires 'Test::Pod::Coverage', '1.00';
};
