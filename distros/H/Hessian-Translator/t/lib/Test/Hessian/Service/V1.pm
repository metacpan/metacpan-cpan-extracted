package  Test::Hessian::Service::V1;

use strict;
use warnings;

use parent 'Test::Hessian::Service';

use Test::More;
use Test::Deep;
use Test::Exception;

use Hessian::Client;
use YAML;
use DateTime;

my $test_service = 'http://hessian.caucho.com/test/test2';

sub prep02_check_webservice : Test(startup) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 1,
            service => $test_service
        }
    );
    eval {
        my $result = $client->methodNull();
    };
    if ( my $e = $@ ) {
        $self->SKIP_ALL("Problem connecting to test service.");
    }

}

sub test_reply_int_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_0();
    is( $result->{reply_data}, 0 );
}

sub test_reply_int_47 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_47();
    is( $result->{reply_data}, 47 );
}

sub test_reply_int_mx800 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyInt_m0x800";
    my $result   = $client->$function();
    is( $result->{reply_data}, -0x800 );
}

sub test_reply_long_mOx80000000 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_m0x80000000";
    my $result   = $client->$function();
    is($result->{reply_data}, -0x80000000, 'Parsed result from server');

}

sub test_reply_long_mOx80000001 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_m0x80000001";
    my $result   = $client->$function();
    is( $result->{reply_data}, -0x80000001 );
}

sub test_reply_long_Ox10 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyLong_0x10";
    my $result   = $client->$function();
    is( $result->{reply_data}, 0x10 );
}

sub test_reply_double_0_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_0_0";
    my $result   = $client->$function();
    is( $result->{reply_data}, 0.0 );
}

sub test_reply_double_m0_001 : Test(1) {    #{{{
    my $self = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_m0_001";
    my $result   = $client->$function();
    local $TODO = 'Fix rounding differences on 32/64 bit machines.';
    is($result->{reply_data}, -0.001, 'Parsed result from server.');
}

sub test_reply_double_127_0 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_127_0";
    my $result   = $client->$function();
    local $TODO = 'Fix rounding differences on 32/64 bit machines.';
    is( $result->{reply_data}, 127 );
}

sub test_reply_double_3_14159 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $function = "replyDouble_3_14159";
    my $result   = $client->$function();
    is( $result->{reply_data}, 3.14159 );
}

sub test_reply_int_m17 : Test(1) {    #{{{
    my $self   = shift;
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyInt_m17();
    is( $result->{reply_data}, -17 );
}

sub reply_object_16 : Test(1) {    #{{{
    my $self           = shift;
    my $hessian_client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $hessian_client->replyObject_16();
    cmp_deeply(
        $result,
        { hessian_version => '2.0', reply_data => array_each( ignore() ) },
        "Received expected datastructure."
    );
}

sub reply_object_2b : Test(1) {    #{{{
    my $self   = shift;
    my $client = get_client();
    my $result = $client->replyObject_2b();
    my $array  = $result->{reply_data};
    cmp_deeply( $array->[0], $array->[1],
        "Received a two element array of the same object." );
}

sub reply_date_0 : Test(1) {    #{{{
    my $self = shift;
    my $date = DateTime->new(
        year      => 1970,
        month     => 1,
        day       => 1,
        minute    => 0,
        hour      => 0,
        time_zone => 'UTC'
    );
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result = $client->replyDate_0();
    is( DateTime->compare( $result->{reply_data}, $date ), 0 );

}

sub reply_date_1 : Test(1) {    #{{{
    my $self = shift;
    local $TODO = "2hr Discrepency in time calculation.";
    my $date = DateTime->new(
        year       => 1998,
        month      => 8,
        day        => 5,
        second     => 31,
        minute     => 51,
        nanosecond => 0,
        hour       => 7,
        time_zone  => 'GMT'
    );
    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    my $result      = $client->replyDate_1();
    my $result_date = $result->{reply_data};
    is( DateTime->compare( $result_date, $date ), 0 );

}

sub reply_date_2 : Test(1) {    #{{{
    my $self = shift;
    local $TODO = "2hr Discrepency in time calculation.";
    my $date = DateTime->new(
        year      => 1998,
        month     => 8,
        day       => 5,
        minute    => 51,
        hour      => 7,
        time_zone => 'GMT'
    );
    my $client      = get_client();
    my $result      = $client->replyDate_2();
    my $result_date = $result->{reply_data};
    is( DateTime->compare( $result_date, $date ), 0 );

}

sub reply_untyped_fixed_list_7 : Test(1) {    #{{{
    my $self   = shift;
    my $client = get_client();
    my $result;
    lives_ok {
        $result = $client->replyUntypedFixedList_7();
    }
    "No problems communicating with service.";

}

sub get_client {    #{{{

    my $client = Hessian::Client->new(
        {
            version => 2,
            service => $test_service
        }
    );
    return $client;
}

"one, but we're not the same";

__END__


=head1 NAME

Communication::TestServlet2 - Test communication with a test service that runs
version 2

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


