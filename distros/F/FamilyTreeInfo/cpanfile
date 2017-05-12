requires 'perl', '5.008005';
requires 'DBI';
requires 'Digest::MD4';
requires 'Digest::MD5';
requires 'Digest::Perl::MD4';
requires 'Encode';
requires 'File::Temp';
requires 'Gedcom', '1.15';
requires 'Config::General', '2.58';

requires 'Class::Std', '0.013';
requires 'Class::Std::Fast::Storable', '0.0.8';
requires 'IO::Stringy', '2.110';
requires 'List::MoreUtils', '0.413';
requires 'OLE::Storage_Lite', '0.19';

requires 'Sub::Exporter', '0.987';
requires 'PadWalker', '2.1';


requires 'Set::Scalar', '1.29';
requires 'version', '0.9912';

requires 'Gedcom::Comparison', '1.15';
requires 'Gedcom::Event', '1.15';
requires 'Gedcom::Family', '1.15';
requires 'Gedcom::Grammar', '1.15';
requires 'Gedcom::Individual', '1.15';
requires 'Gedcom::Item', '1.15';
requires 'Gedcom::Record', '1.15';
requires 'Jcode';
requires 'List::Util';
requires 'Params::Validate';
requires 'Parse::RecDescent';
requires 'Scalar::Util';
requires 'Time::Local';
requires 'Unicode::Map';
requires 'experimental', '0.016';
requires 'Log::Log4perl', '1.46';
requires 'Plack', '1.0037';
requires 'CGI::Emulate::PSGI', '0.21';
requires 'CGI::Compile', '0.19';
requires 'Spreadsheet::Read', '0.62';
requires 'Spreadsheet::XLSX', '0.13';
requires 'Spreadsheet::ParseExcel';
requires 'DateTime';
requires 'Excel::Writer::XLSX';
requires 'Spreadsheet::WriteExcel';
requires 'Plack', '1.0039';

on test => sub {
    requires 'Test::More';
    requires 'Test::Run';
    requires 'Test::Run::CmdLine';
    requires 'Test::Trap';
};

# Зависимости фазы сборки, спасибо Владимиру Леттиеву из Pragmaticperl
# http://pragmaticperl.com/issues/10/pragmaticperl-10-%D1%87%D1%82%D0%BE-%D1%82%D0%B0%D0%BA%D0%BE%D0%B5-cpanfile.html
on build => sub {
    requires 'Test::Pod',           '1.48';
};
