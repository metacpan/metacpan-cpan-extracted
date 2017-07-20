use Test2::V0 '-target' => 'JSON::Path::Evaluator';
use JSON::MaybeXS;

my $json = q({
   "store" : {
      "book" : [
         {
            "price" : 8.95,
            "title" : "Sayings of the Century",
            "author" : "Nigel Rees",
            "category" : "reference"
         },
         {
            "price" : 12.99,
            "title" : "Sword of Honour",
            "author" : "Evelyn Waugh",
            "category" : "fiction"
         },
         {
            "price" : 8.99,
            "isbn" : "0-553-21311-3",
            "title" : "Moby Dick",
            "author" : "Herman Melville",
            "category" : "fiction"
         },
         {
            "price" : 22.99,
            "isbn" : "0-395-19395-8",
            "title" : "The Lord of the Rings",
            "author" : "J. R. R. Tolkien",
            "category" : "fiction"
         }
      ]
   }
});
my $obj = decode_json($json);

my @expressions = (
    q{$..[?(@.price > 10)]} => [ q{$['store']['book']['1']}, q{$['store']['book']['3']}, ],
    q{$.store.book.0.price}                                => q{$['store']['book']['0']['price']},
    q{$.store.book[?($_->{author} eq "J. R. R. Tolkien")]} => q{$['store']['book']['3']},
    q{$.store.book[?($_->{category} eq "fiction")]} =>
        [ q{$['store']['book']['1']}, q{$['store']['book']['2']}, q{$['store']['book']['3']} ],
);
do_test(@expressions);
done_testing;

sub do_test {
    my @expressions = @_;
    while ( my $expression = shift @expressions ) {
        subtest $expression => sub {
            my $expected = shift @expressions;
            $expected = [$expected] unless ref $expected eq 'ARRAY';
            my @got;
            ok lives {
                @got = JSON::Path::Evaluator::evaluate_jsonpath( $json, $expression, want_path => 1 );
            }, q{evaluate_jsonpath did not die} or diag qq{Caught exception $@};
            is \@got, $expected, qq{"$expression" evaluated correctly};
        };
    }
}
