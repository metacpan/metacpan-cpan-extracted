use Test::More tests => 10;

use FindBin;
use strict;
use warnings;
use Data::Dumper;
use Test::Exception;
use Geoffrey::Converter::SQLite;

require_ok('Geoffrey::Action::Constraint::Default');
use_ok 'Geoffrey::Action::Constraint::Default';

my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::Constraint::Default->new( converter => $converter );

can_ok( 'Geoffrey::Action::Constraint::Default', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::Constraint::Default' );

throws_ok { $object->alter(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $object->drop(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';

throws_ok { $object->list_from_schema(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'List sequences from schema';

{

    package Test::Mock::Geoffrey::Converter::SQLite::Sequence;
    use parent 'Geoffrey::Role::ConverterType';
}

{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';

    sub new {
        my $class = shift;
        return bless $class->SUPER::new(@_), $class;
    }

    sub sequence {
        return Test::Mock::Geoffrey::Converter::SQLite::Sequence->new;
    }
}

my $default =
  Geoffrey::Action::Constraint::Default->new(
    converter => Test::Mock::Geoffrey::Converter::SQLite->new );

throws_ok {
    $default->add( { table => '"name"' } );
}
'Geoffrey::Exception::NotSupportedException::Sequence', 'Not supportet thrown';

throws_ok { $default->alter(); } 'Geoffrey::Exception::NotSupportedException::Action',
  'Not supportet thrown';

throws_ok { $default->drop(); }
'Geoffrey::Exception::NotSupportedException::ConverterType',
  'Not supportet thrown';
