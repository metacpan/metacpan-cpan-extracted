package MyExport;

use base 'Import::Base';

our @EXPORT_OK = qw(joy);

our @IMPORT_MODULES = (
    'strict',
    'warnings',
    feature => [qw( :5.10 )],
    MyExport => [qw( joy )],
);

sub joy {
    return "wee";
}

1;
