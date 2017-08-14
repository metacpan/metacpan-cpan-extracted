use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Test::More qw(no_plan);
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use Data::Dumper;
use AnyEvent::Loop;
use Scalar::Util qw(looks_like_number);
use Carp qw(confess);
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }

my $string;
my $module='HTTP::MultiGet::Role';
require_ok($module);
my $class='SomeTestClass';
my $log=LoggerToString($class,$string);

my $self=$class->new;

isa_ok($self,$class);

# sorry, real world testing isn't all that easy here

{
  package 
    SomeTestClass;
  use Modern::Perl;
  use Moo;
  with 'HTTP::MultiGet::Role';
}
