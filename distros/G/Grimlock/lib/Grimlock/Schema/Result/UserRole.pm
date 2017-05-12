package Grimlock::Schema::Result::UserRole;
{
  $Grimlock::Schema::Result::UserRole::VERSION = '0.11';
}

use Grimlock::Schema::Candy -components => [
  qw(
      InflateColumn::DateTime
      TimeStamp
      Helper::Row::ToJSON
      )
];

column userid => {
  data_type => 'int',
  is_nullable => 0,
};

column  roleid => {
  data_type => 'int',
  is_nullable => 0,
};

belongs_to 'user' => 'Grimlock::Schema::Result::User', 'userid',
{
  cascade_delete => 1,
  cascade_update => 1
};

belongs_to 'role' => 'Grimlock::Schema::Result::Role', 'roleid',
{ 
  cascade_delete => 1,
  cascade_update => 1
};

primary_key ("userid", "roleid");

1;

