=head1 PURPOSE

Test expressions that use AND (&&) and/or OR (||)
within the filter part of the path.

=cut

use Test2::V0;
use JSON::Path::Evaluator qw/evaluate_jsonpath/;

my $json = q@{
    "Competency" : [
        {
            "level" : 75,
            "name" : "Marketing"
        },
        {
            "level" : 500,
            "name" : "Something Else"
        }
    ]
}@;

my @data;

### AND test
@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.level<25)].name');
is(@data, 0, 'Nothing between 0 and 25');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level<25 && @.level>=0)].name');
is(@data, 0, 'Nothing between 25 and 0');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.level<100)].name');
is(@data, 1, 'One value between 0 and 100');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level<100 && @.level>=0)].name');
is(@data, 1, 'One value between 100 and 0');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.level<1000)].name');
is(@data, 2, 'Two values between 0 and 1000');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level<1000 && @.level>=0)].name');
is(@data, 2, 'Two values between 1000 and 0');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.name=="Marketing" && @.level<100)].name');
is(@data, 1, 'Got Marketing');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.name=="Marketing" && @.level<50)].name');
is(@data, 0, 'No Marketing');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>=0 && @.name=="Marketong" && @.level<100)].name');
is(@data, 0, 'No Marketong');

## OR test
@data = evaluate_jsonpath($json, '$.Competency[?(@.level>0 || @.level>1000)].name');
is(@data, 2, 'All values are more than zero OR more than 1000');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>0)].name');
is(@data, 2, 'The other way around');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>500)].name');
is(@data, 0, 'No value greater than 1000 or 500');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>200)].name');
is(@data, 1, 'One value greater than 1000 or 200');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>200 || @.level>50)].name');
is(@data, 2, 'Two values greater than 1000 or 200 or 50');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>200 || @.name=="Marketing")].name');
is(@data, 2, 'One value greater than 1000 or 200 and one Marketing');

## Mix AND and OR
@data = evaluate_jsonpath($json, '$.Competency[?(@.level==75 && @.name=="Marketing" || @.level==500 && @.name="Something Else")].name');
is(@data, 2, 'Got "Marketing" and "Something Else"');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level==500 && @.name=="Marketing" || @.level==75 && @.name="Something Else")].name');
is(@data, 0, 'Got Nothing');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name && @.level )]');
is(@data, 2, 'LHS Trimmed when necessary');

SKIP: {
    skip "Not working on AND/OR naive and quick implementation";
    @data = evaluate_jsonpath($json, '$.Competency[?(@.level>1000 || @.level>200 || @.name!="Ben && Jerry")].name');
    is(@data, 2, 'Data containing "&&" might break things');

    @data = evaluate_jsonpath($json, '$.Competency[?(@.name!="Ben || Jerry" && @.level>1000)].name');
    is(@data, 0, 'Data containing "||" might break things');


    @data = evaluate_jsonpath($json, '$.Competency[?(@.level==75 && ( @.name=="Marketing" || @.name="Something Else" ) && @.level==500)].name');
    is(@data, 0, 'Brackets not working as expected');

    @data = evaluate_jsonpath($json, '$.Competency[?(( @.name=="Marketing" || @.name="Something Else" ) && @.level==500)].name');
    is(@data, 1, 'Brackets not working as expected');

    @data = evaluate_jsonpath($json, '$.Competency[?(@.level==75 && ( @.name=="Marketing" || @.name="Something Else" ))].name');
    is(@data, 1, 'Brackets not working as expected');
};

done_testing();
