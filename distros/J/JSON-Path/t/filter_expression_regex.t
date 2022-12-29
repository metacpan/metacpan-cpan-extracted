=head1 PURPOSE

Test expressions that use regexes
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
            "level" : 100,
            "name" : "Market Analysis"
        },
        {
            "level" : 500,
            "name" : "[Something] ('/Else/') \"\@-3/2\\\\8/\""
        }
    ]
}@;

my @data;
@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /Market/)]');
is(@data, 2, 'Regex work. /Market/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /market/)]');
is(@data, 0, 'Nothing found, wrong case. /market/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /market/i)]');
is(@data, 2, 'Regex with i modifier works. /market/i');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /^market$/)]');
is(@data, 0, 'Regex with ^ and $ works. /^market$/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /market/i && @.level > 80 )]');
is(@data, 1, 'Regex works combined with other clausules (and)');

@data = evaluate_jsonpath($json, '$.Competency[?(@.level > 100 || @.name =~ /market/i)]');
is(@data, 3, 'Regex works combined with other clausules (or)');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /\[\w+\]/)]');
is(@data, 1, 'A bit more complex regex. /\[\w+\]/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /\w{9}|\w{15}/)]');
is(@data, 2, 'Another slightly complex regex. /\w{9}|\w{15}/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /\'\/Else\/\'/)]');
is(@data, 1, 'Can use \' and / inside regex. /\'\/Else\/\'/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /"\/Else\/"/)]');
is(@data, 0, 'Can use " and / inside regex. /"\/Else\/"/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /"@-\d\/\d\\\\.*"/)]');
is(@data, 1, 'Try more special characers inside regex. /"@-\d\/\d\\\\.*"/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /"-\d\/\d\\\\.*"/)]');
is(@data, 0, 'Similar but failing to match. /"-\d\/\d\\\\.*"/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /\] \(.*\'.*\/\d\\\\8\//)]');
is(@data, 1, 'More weird expression. /\] \(.*\'.*\/\d\\\\8\//');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /\(.*\)/)]');
is(@data, 1, 'Escaped parenthesis are parenthesis. /\(.*\)/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /(.*)/)]');
is(@data, 3, 'But not escaped parenthesis group stuff. /(.*)/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /^marketing|analysis$/i)]');
is(@data, 2, 'Simple expression not grouped. /^marketing|analysis$/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /^(marketing|analysis)$/i)]');
is(@data, 1, 'Simple expression now grouped. /^(marketing|analysis)$/');

@data = evaluate_jsonpath($json, '$.Competency[?(@.name =~ /^(?:marketing|analysis)$/i)]');
is(@data, 1, '?: has no effect. /^(?:marketing|analysis)$/');

done_testing();
