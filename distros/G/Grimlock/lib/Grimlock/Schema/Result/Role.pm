package Grimlock::Schema::Result::Role;
{
  $Grimlock::Schema::Result::Role::VERSION = '0.11';
}

use Grimlock::Schema::Candy -components => [
  qw(
      InflateColumn::DateTime
      TimeStamp
      Helper::Row::ToJSON
      )
];

primary_column roleid => {
  data_type => 'int',
  is_auto_increment => 1,
  is_nullable => 0,
};

unique_column name => {
  data_type => 'varchar',
  size => '50',
  is_nullable => 0,
};

has_many 'user_roles' => 'Grimlock::Schema::Result::UserRole', {
  'foreign.roleid' => 'self.roleid',
};

1;
