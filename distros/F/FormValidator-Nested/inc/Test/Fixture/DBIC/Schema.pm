#line 1
package Test::Fixture::DBIC::Schema;
use strict;
use warnings;
our $VERSION = '0.02';
use base 'Exporter';
our @EXPORT = qw/construct_fixture/;
use Params::Validate ':all';
use Kwalify ();
use Carp;

sub construct_fixture {
    validate(
        @_ => +{
            schema  => +{ isa => 'DBIx::Class::Schema' },
            fixture => 1,
        }
    );
    my %args = @_;

    my $fixture = _validate_fixture(_load_fixture($args{fixture}));
    _delete_all($args{schema});
    return _insert($args{schema}, $fixture);
}

sub _load_fixture {
    my $stuff = shift;

    if (ref $stuff) {
        if (ref $stuff eq 'ARRAY') {
            return $stuff;
        } else {
            croak "invalid fixture stuff. should be ARRAY: $stuff";
        }
    } else {
        require YAML::Syck;
        return YAML::Syck::LoadFile($stuff);
    }
}

sub _validate_fixture {
    my $stuff = shift;

    Kwalify::validate(
        {
            type     => 'seq',
            sequence => [
                {
                    type    => 'map',
                    mapping => {
                        schema => { type => 'str', required => 1 },
                        name   => { type => 'str', required => 1 },
                        data   => { type => 'any', required => 1 },
                    },
                }
            ]
        },
        $stuff
    );

    $stuff;
}

sub _delete_all {
    my $schema = shift;

    $schema->resultset($_)->delete for $schema->sources;
}

sub _insert {
    my ($schema, $fixture) = @_;

    my $result = {};
    for my $row ( @{ $fixture } ) {
        $schema->resultset( $row->{schema} )->create( $row->{data} );
        $result->{ $row->{name} } = $schema->resultset( $row->{schema} )->find( $row->{data} );
    }
    return $result;
}

1;
__END__

=encoding utf8

#line 155
