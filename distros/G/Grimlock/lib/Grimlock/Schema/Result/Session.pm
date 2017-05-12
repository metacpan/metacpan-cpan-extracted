package Grimlock::Schema::Result::Session;
{
  $Grimlock::Schema::Result::Session::VERSION = '0.11';
}

use Grimlock::Schema::Candy -components => [
  qw(
      InflateColumn::DateTime
      TimeStamp
      Helper::Row::ToJSON
      )
];

primary_column sessionid => {
  data_type => 'char',
  is_nullable => 0,
  size => 72
};

column session_data => {
  data_type => 'text',
  is_nullable => 1
};

column expires => {
  data_type => 'int',
  is_nullable => 1
};

1;

