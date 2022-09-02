=head1 PURPOSE

Test filter expressions with nested objects/hashrefs.

=cut

use Test2::V0;
use JSON::Path::Evaluator qw/evaluate_jsonpath/;

my $json = q@{
    "Competency" : [
      {
        "C1":
          {
              "level" : 75,
              "name" : "Marketing"
          },
        "C2":
          {
              "level" : 500,
              "name" : "Something Else"
          }
      },
      {
        "C1":
          {
              "level" : 60,
              "name" : "Perl",
              "absurdily": {
                "nested": {
                  "data": {
                    "structure": {
                      "arrays_here":
                      [
                        [[1]], [[2]], [[3],[ { "goal": "coins" }]]
                      ]
                    }
                  }
                }
              }
          },
        "C2":
          {
              "level" : 100,
              "name" : "JavaScript"
          },
        "C3":
          {
              "name" : "Python",
              "absurdily": {
                "nested": {
                  "data": {
                    "structure": {
                      "arrays_here":
                      [
                        [[1]], [[2]], [[3],[ { "goal": "treasure" }]]
                      ]
                    }
                  }
                }
              }
          }
      }
    ]
}@;

my @data;

@data = evaluate_jsonpath($json, '$.Competency[*][*]');
is(@data, 5, 'Everything found using [*][*]');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="Marketing")].name');
ok(@data == 1 && $data[0] eq 'Marketing', 'Marketing found using [*][?(@.name=="Marketing")] filter');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="JavaScript")].name');
ok(@data == 1 && $data[0] eq 'JavaScript', 'JavaScript found using filter [*][?(@.name=="JavaScript")]');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="JavaScript" && @.level > 50)].name');
ok(@data == 1 && $data[0] eq 'JavaScript', 'JavaScript found adding @.level > 50) condition');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="JavaScript" && @.level < 50)]');
is(@data, 0, 'JavaScript not found with condition @.level > 50');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="Java")]');
is(@data, 0, 'Java not found with filter [*][?(@.name=="Java")]');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.level >= 75)]');
is(@data, 3, 'Everything with level >= 75 found');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.level < 75)]');
is(@data, 1, 'Everything with level < 75 found');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.name=="Python")].absurdily.nested.data.structure.arrays_here[2][1][0].goal');
ok(@data == 1 && $data[0] eq 'treasure', 'Found absurdily nested data filtering by Python');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.absurdily.nested.data.structure.arrays_here[2][1][0].goal=="treasure")].name');
ok(@data == 1 && $data[0] eq 'Python', 'Found Python filtering with absurdily nested data');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.absurdily.nested.data.structure.arrays_here[2][1][0].goal)].name');
is(@data, 2, 'Found Python and Perl filtering with absurdily nested data');

@data = evaluate_jsonpath($json, '$.Competency[*][?(@.absurdily.nested.data.structure.arrays_here[2][1][0].goal && @.level > 55)].name');
ok(@data == 1 && $data[0] eq 'Perl', 'Found Perl filtering with absurdily nested data');

done_testing();
