requires 'perl', '5.008005';

requires 'Carp';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Slurper';
requires 'JSON::PP';
requires 'Scalar::Util';

recommends 'Cpanel::JSON::XS', '4.09';

on test => sub {
    requires 'FindBin';
    requires 'Test::More', '0.96';
    requires 'Test::Exception';
    requires 'Test::Pod';
    recommends 'Cpanel::JSON::XS', '4.09';
};
