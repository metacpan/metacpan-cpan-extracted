require Getopt::Complete;
use Test::More tests => 1;
my $args = Getopt::Complete::Args->new(
    options => Getopt::Complete::Options->new('foo!' => undef),
    argv => ['--bar']
   );
ok(scalar(grep { /Unknown option: bar/ } $args->errors), "detected an error when a nonsense argumetn is used");

