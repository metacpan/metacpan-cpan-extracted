use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib 't';
use MySchema;
use Hyle;
use Plack::Test;
use HTTP::Request::Common qw();
use HTTP::Request;


# add skip all unless YAML module installed

unless (eval "use YAML (); 1") {
    plan skip_all => "need YAML module installed to test another serializer";
    done_testing();
    exit;
}

my $dbfile =':memory:';
my $schema = MySchema->connect("dbi:SQLite:dbname=$dbfile","","");

my $hyle = Hyle->new(
    schema => $schema,
    
    # add custom serializer
    serializers => {
        'text/yaml' => sub {
            return ("text/yaml", YAML::Dump(@_));
        },
    },

);

{
    my $dbh = $schema->storage->dbh;
    $dbh->do("CREATE TABLE A (a int not null)");
    $dbh->do("INSERT INTO A VALUES (1)");
}

my $test = Plack::Test->create($hyle->to_app);


# YAML Response
lives_ok(sub {
   my $request = HTTP::Request->new(GET => 'A/1');

   $request->header(Accept => "text/yaml");
   my $res = $test->request($request);

   #diag($res->decoded_content);
   ok($res->is_success,"response is succesful");
   cmp_ok($res->code,'==', 200, "response code 200 OK");

   cmp_ok($res->headers->header("Content-Type"), "eq", "text/yaml", "content type header in response - ok");

    my $ret;
   
   lives_ok(sub {
       $ret = YAML::Load($res->decoded_content());
   }, "can deserialize the body");

   cmp_ok(ref($ret),'eq','ARRAY',"response isa ARRAYREF");
   ok(@$ret == 1, "only one result returned");

   ok($ret->[0]{a} == 1, "returned content matches input");

}, "can decode YAML response");


done_testing();
