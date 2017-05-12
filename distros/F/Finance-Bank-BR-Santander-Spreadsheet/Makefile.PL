use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Finance::Bank::BR::Santander::Spreadsheet',
    VERSION_FROM => 'lib/Finance/Bank/BR/Santander/Spreadsheet.pm',
    AUTHOR => 'Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>',
    LICENSE => 'gpl_2',
    PREREQ_PM => {
        'Spreadsheet::ParseExcel::Simple' => 1.02,
        'DateTime::Format::Strptime'      => 1.5000,
    },
);
