use 5.016;

package Test {

    use Scalar::Util qw/refaddr/;
    use List::Util qw/pairs/;
    use Moo;
    has root => ( is => 'ro' );

    sub get_reftable {
        my $class = shift;
        return $class->new->_get_reftable(@_);
    }

    sub _get_reftable {
        my ( $self, $json_object, $base_path ) = @_;

        $base_path   ||= '$';
        $json_object ||= $self->root;

        my @entries = ( $base_path => refaddr $json_object );

        if ( ref $json_object eq 'ARRAY' ) {
            for ( 0 .. $#{$json_object} ) {
                my $key = sprintf '%s[%d]', $base_path, $_;
                if ( ref $json_object->[$_] ) {
                    push @entries, $self->_get_reftable( $json_object->[$_], $key );
                }
                else {
                    push @entries, $key => refaddr \( $json_object->[$_] );
                }
            }
        }
        else {
            for my $index ( keys %{$json_object} ) {
                my $key = sprintf '%s.%s', $base_path, $index;
                if ( ref $json_object->{$index} ) {
                    push @entries, $self->_get_reftable( $json_object->{$index}, $key );
                }
                else {
                    push @entries, $key => refaddr \( $json_object->{$index} );
                }
            }
        }
        return @entries;
    }
}
use Data::Dumper;

my $obj = {
    alpha => [ 1, { quux => 'quuy', quuz => 'quua' } ],
    beta  => [ 1, 2, 3 ],
};
use JSON::Parse 'parse_json';
my $json='{
   "4" : {
      "value_raw" : "European",
      "value" : "European",
      "name" : "Ethnicity",
      "type" : "radio",
      "id" : 4
   },
   "1" : {
      "middle" : "",
      "first" : "James",
      "value" : "James Bowery",
      "last" : "Bowery",
      "name" : "Name",
      "type" : "name",
      "id" : 1
   },
   "3" : {
      "value_raw" : "Male",
      "value" : "Male",
      "name" : "Gender",
      "type" : "radio",
      "id" : 3
   },
   "2" : {
      "unix" : 1498176000,
      "time" : "",
      "date" : "06/23/2017",
      "value" : "06/23/2017",
      "name" : "Birthdate",
      "type" : "date-time",
      "id" : 2
   },
   "5" : {
      "value" : "jabowery@emailservice.com",
      "name" : "Email",
      "type" : "text",
      "id" : 5
   }
}';
$obj = parse_json($json);

# $
# $.alpha
# $.beta
# $.alpha[0]
# $.alpha[1]
# $.alpha[2]
# $.beta[0]
# $.beta[1]
# $.beta[2]
#

my %reftable = Test->get_reftable($obj);
print Dumper \%reftable;
