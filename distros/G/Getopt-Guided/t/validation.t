use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( dies is imported_ok like ok plan subtest );
BEGIN { MODULE->import( 'getopts' ) }

plan 3;

imported_ok 'getopts';

subtest 'Validate $spec parameter' => sub {
  plan tests => 6;

  local @ARGV = ();
  my %opts;
  like dies { getopts undef, %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    'Undefined value is not allowed';
  like dies { getopts '', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    'Empty value is not allowed';
  like dies { getopts 'a:-b', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    "'-' character is not allowed";
  like dies { getopts ':a:b', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    "Leading ':' character is not allowed";
  like dies { getopts 'aba:', %opts }, qr/\A\$spec parameter contains option 'a' multiple times/,
    'Same option character is not allowed';
  ok getopts( 'a:b', %opts ), 'Succeeded'
};

subtest 'Validate $opts parameter' => sub {
  plan tests => 1;

  local @ARGV = ();
  my %opts = ( a => 'foo' );
  like dies { getopts 'a:b', %opts }, qr/\A\%\$opts parameter isn't an empty hash/, 'Result %opts hash has to be empty'
}
