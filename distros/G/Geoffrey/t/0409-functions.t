use Test::More tests => 14;

use strict;
use FindBin;
use warnings;
use Test::Exception;

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

require_ok('Geoffrey::Action::Function');
use_ok 'Geoffrey::Action::Function';

{

    package Test::Mock::Geoffrey::Converter::SQLite::Function;
    use parent 'Geoffrey::Role::ConverterType';
}
{

    package Test::Mock::Geoffrey::Converter::SQLite::Function2;
    use parent 'Geoffrey::Role::ConverterType';

    sub add {
        return 'SELECT 1';
    }

    sub list {
        return 'SELECT 1';
    }

    sub information {
        shift;
        return @_;
    }

}
{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';
    sub function { Test::Mock::Geoffrey::Converter::SQLite::Function->new; }
}
{

    package Test::Mock::Geoffrey::Converter::SQLite2;
    use parent 'Geoffrey::Role::Converter';
    sub function { Test::Mock::Geoffrey::Converter::SQLite::Function2->new; }
}
{

    package Test::Mock::Geoffrey::Converter::SQLite3;
    use parent 'Geoffrey::Role::Converter';
    sub function { Test::Mock::Geoffrey::Converter::SQLite::Function->new; }
}

my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::Function->new( converter => $converter );

isa_ok( $object, 'Geoffrey::Action::Function' );

throws_ok { $converter->foreign_key->alter(); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Not supportet thrown';

throws_ok { $object->add(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
    'Not supportet thrown';

throws_ok { $object->alter(); } 'Geoffrey::Exception::NotSupportedException::Action',
    'Not supportet thrown';

throws_ok { $object->drop(); } 'Geoffrey::Exception::NotSupportedException::Action',
    'Not supportet thrown';

throws_ok { $object->list(); } 'Geoffrey::Exception::NotSupportedException::ConverterType',
    'List function not supportet thrown';

throws_ok {
    Geoffrey::Action::Function->new( converter => Test::Mock::Geoffrey::Converter::SQLite->new() )
        ->add();
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Not supportet thrown';

throws_ok {
    Geoffrey::Action::Function->new( converter => Test::Mock::Geoffrey::Converter::SQLite->new() )
        ->list();
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'List function not supportet thrown';

throws_ok {
    Geoffrey::Action::Function->new(
        converter => Test::Mock::Geoffrey::Converter::SQLite2->new() )->add();
}
'Geoffrey::Exception::General::WrongRef', 'Not supportet thrown';

throws_ok {
    Geoffrey::Action::Function->new(
        converter => Test::Mock::Geoffrey::Converter::SQLite3->new() )->dryrun(1)->list();
}
'Geoffrey::Exception::NotSupportedException::ConverterType', 'List function not supportet thrown';
