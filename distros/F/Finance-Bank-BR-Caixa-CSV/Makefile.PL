use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Finance::Bank::BR::Caixa::CSV',
    VERSION_FROM => 'lib/Finance/Bank/BR/Caixa/CSV.pm',
    AUTHOR => 'Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>',
    LICENSE => 'gpl_2',
    PREREQ_PM => {
        'Text::CSV::Encoded'              => 0.25,
        'DateTime::Format::Strptime'      => 1.5000,
    },
);
