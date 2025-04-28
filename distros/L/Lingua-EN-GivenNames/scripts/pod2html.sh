#!/bin/bash

pod2html.pl -i lib/Lingua/EN/GivenNames.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames.html
pod2html.pl -i lib/Lingua/EN/GivenNames/Database.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames/Database.html
pod2html.pl -i lib/Lingua/EN/GivenNames/Database/Create.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames/Database/Create.html
pod2html.pl -i lib/Lingua/EN/GivenNames/Database/Download.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames/Database/Download.html
pod2html.pl -i lib/Lingua/EN/GivenNames/Database/Import.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames/Database/Import.html
pod2html.pl -i lib/Lingua/EN/GivenNames/Database/Export.pm -o /dev/shm/html/Perl-modules/html/Lingua/EN/GivenNames/Database/Export.html
