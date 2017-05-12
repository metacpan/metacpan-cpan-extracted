package TestFor::Gideon::Meta::Attribute::Trait::DBI::Inflate::DateTime;
use Test::Class::Moose;
use Test::MockObject;

with 'Test::Class::Moose::Role::AutoUse';

sub test_inflate {
    my $meta = Moose::Meta::Class->create_anon_class;

    $meta->add_attribute(
        test => (
            is     => 'rw',
            traits => ['Gideon::DBI::Inflate::DateTime'],
        )
    );

    my $dbh = Test::MockObject->new;
    $dbh->set_true('trace_msg');

    $dbh->{Driver}       = { Name        => 'Proxy' };
    $dbh->{proxy_client} = { application => 'DBI:mysql:' };

    my ($inflator) =
      map { $_->get_inflator($dbh) } $meta->get_attribute('test');

    my ($deflator) =
      map { $_->get_deflator($dbh) } $meta->get_attribute('test');

    my $timestamp = DateTime->new(
        year   => 2013,
        month  => 1,
        day    => 2,
        hour   => 11,
        minute => 22,
        second => 33
    );

    is $inflator->("2013-01-02 11:22:33"), $timestamp, 'Inflator Result';
    is $deflator->($timestamp), "2013-01-02 11:22:33", 'Deflator Result';
}

1;
