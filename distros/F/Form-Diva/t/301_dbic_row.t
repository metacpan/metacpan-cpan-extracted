use strict;
use warnings;

package DBIx::Class::Row;

sub new {
    my $class = shift;
    my $self  = {
        @_,
        data => {
            fname     => 'mocdbic',
            purpose   => 'testing',
            invisible => 'hide me'
        }
    };
    bless $self, $class;
    return $self;
}

sub get_inflated_columns {
    my $self = shift;
    return %{ $self->{data} };
}

package TestThing;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Form::Diva');

my $notdbic = {
    fname     => 'realhash',
    purpose   => 'comparison',
    invisible => 'hide me'
};

my $mocdbic = DBIx::Class::Row->new;

isa_ok( $mocdbic, 'DBIx::Class::Row',
    'moc dbic object looks like a dbix::class object' );
my %inflated = $mocdbic->get_inflated_columns();
is( $inflated{fname}, 'mocdbic',
    'moc object returns data for ->get_inflated_columns' );

my $rehashnotdbic = Form::Diva::_checkdatadbic($notdbic);
is( eq_hash( $rehashnotdbic, $notdbic ),
    1, "_checkdatadbic returns the original with a plain hashref" );

my $rehashdbic = Form::Diva::_checkdatadbic($mocdbic);
is( eq_hash(
        $rehashdbic,
        {   fname     => 'mocdbic',
            purpose   => 'testing',
            invisible => 'hide me'
        }
    ),
    1,
    "_checkdatadbic returns the data with a dbic row"
);

is( eq_hash( Form::Diva::_checkdatadbic( [qw / not valid data /] ), {} ),
    1, 'sending an array_ref to _checkdatadbic returns empty hashref' );

my $diva = Form::Diva->new(
    label_class => 'testclass',
    input_class => 'form-control',
    form_name   => 'diva1',
    form        => [ { n => 'fname' }, { name => 'purpose' }, ],
    hidden => [ { n => 'invisible' } ],
);

my $results_plain = $diva->generate($notdbic);

like( $results_plain->[1]{label},
    qr/for="formdiva_purpose"/, 'plain hash generates label for purpose' );
like(
    $results_plain->[0]{input},
    qr/ value="realhash"/,
    'plain hash generates value fname field'
);
like( $results_plain->[1]{input},
    qr/comparison"/,
    'plain hash generates input tag with value of purpose field' );

my $results_dbic = $diva->generate($mocdbic);
like( $results_dbic->[1]{label},
    qr/for="formdiva_purpose"/, 'dbic result generates label for purpose' );
like( $results_dbic->[0]{input},
    qr/value="mocdbic"/, 'dbic result generates value for fname field' );
like( $results_dbic->[1]{input},
    qr/testing"/,
    'dbic result generates input tag with value of purpose field' );
# following 2 tests from issue #2 (github).
# hidden fields did not set value when data was in a dbic_row object.
like(
    $diva->hidden($mocdbic),
    qr/value="hide me"/,
    "value of hidden field set when data is from dbic."
);
like( $diva->prefill($mocdbic)->[1]{input},
    qr/testing"/,
    'prefills input tag with value of purpose field when data is from dbic' );

note("Bug in prior versions -- datavalues did not work with dbic row data");
my $dv_dbic = $diva->datavalues($mocdbic) ;
is ( $dv_dbic->[0]{value}, 'mocdbic', "Test that datavalues method also worked with dbic data");
is ( $dv_dbic->[1]{id}, 'formdiva_purpose', "Test that datavalues method also worked with dbic data");
done_testing();
