use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from https://dtai.cs.kuleuven.be/problog/tutorial/tutslides/02_more.html

"An example of a tuple-independent probabilistic database"

0.96::producesProduct(sony,walkman).
0.96::producesProduct(microsoft,mac_os_x).
0.96::producesProduct(ibm,personal_computer).
0.9::producesProduct(microsoft,mac_os).
0.9::producesProduct(adobe,adobe_indesign).
0.87::producesProduct(adobe,adobe_dreamweaver).

1.0::headquarteredIn(microsoft,redmond).
0.99::headquarteredIn(ibm,san_jose).
0.93::headquarteredIn(emirates_airlines,dubai).
0.93::headquarteredIn(honda,torrance).
0.93::headquarteredIn(horizon,seattle).
0.93::headquarteredIn(egyptair,cairo).
0.93::headquarteredIn(adobe,san_jose).

result(Product,Company) :-
    producesProduct(Company,Product),
    headquarteredIn(Company,san_jose).
query(result(_,_)).

=cut

prob_logic Database {

    pfacts {
        0.96 => producesProduct( 'Sony',      'Walkman' );
        0.96 => producesProduct( 'Microsoft', 'Mac OS X' );
        0.96 => producesProduct( 'IBM',       'Personal computer' );
        0.90 => producesProduct( 'Microsoft', 'Mac OS' );
        0.90 => producesProduct( 'Adobe',     'Adobe Indesign' );
        0.87 => producesProduct( 'Adobe',     'Adobe Dreamweaver' );

        1.00 => headquarteredIn( 'Microsoft',         'Redmond' );
        0.99 => headquarteredIn( 'IBM',               'San Jose' );
        0.93 => headquarteredIn( 'Emirates Airlines', 'Dubai' );
        0.93 => headquarteredIn( 'Honda',             'Torrance' );
        0.93 => headquarteredIn( 'Horizon',           'Seattle' );
        0.93 => headquarteredIn( 'Egyptair',          'Cairo' );
        0.93 => headquarteredIn( 'Adobe',             'San Jose' );
    }

    rule result( $product, $company ) {
        producesProduct( $company, $product );
        headquarteredIn( $company, 'San Jose' );
    }

    # Generator to format (product, company) as a single compound string tuple
    generator pair(3), sub ( $prod, $comp, $tuple ) {
        my $done = 0;
        return sub {
            return () if $done++;
            return [ $prod, $comp, "$prod ($comp)" ];
        };
    };

    rule result_tuple($tuple) {
        fresh my ( $product, $company );
        result( $product, $company );
        pair( $product, $company, $tuple );
    }
}

# query(result(_,_)).
# Note: query_dist expects one variable. So a generator that creates a single string from combining
# product and company is used to reduce two variables to one (see above).
query_dist Database::result_tuple(fresh my $item), max_worlds => 8192 ->my $tuple_dist;
say $tuple_dist;


