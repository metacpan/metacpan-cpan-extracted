package MyTest;
use base qw( Exporter );
use strict;
use warnings;
use 5.010;

use Carp;
use Clone::Any qw( clone );
use Data::Dumper::Concise;
use File::Slurp;
use File::Spec::Functions;
use Getopt::Long;
use IO::Socket::INET;
use JSON::PP;
use Module::Load;
use REST::Client;
use Try::Tiny;

use Test::Deep;
use Test::Exception;
use Test::More;

use File::Basename;
use lib dirname($0).'/lib'; # we keep testing-only modules in a lib under t!
use lib dirname($0).'/../lib'; # the module itself is under here

use TestServer;

my $port = TestServer_get_unused_port(); # port the test server will listen on

my @TestServerSubs = qw( TestServer_setup
                         TestServer_pid
                         TestServer_is_running
                         TestServer_is_listening
                         TestServer_rest
                         TestServer_test
                         TestServer_stop
                         TestServer_port
                         TestServer_url );

my @MyTestSubs = qw( chomper can_ok_abstract can_ok_mixins
                     dump_got_expected get_class
                     validate_contextual_accessor
                     validate_wrapper_method 
                     validate_expected_fields  );

our @EXPORT = ( @TestServerSubs,
                @MyTestSubs,
                # re-export things we're importing
                @Test::Deep::EXPORT,
                @Test::Exception::EXPORT,
                @Test::More::EXPORT,
                @Try::Tiny::EXPORT );

###########################################################################
#
# support for starting the test server
#

my $pid;
my $quit = 0;

sub TestServer_setup {

    try {
        # start the server
        $pid = TestServer->new($port)->background();
    };
    unless ($pid) { exit } # error or child fell through
    say "# started server on PID $pid";
}

sub TestServer_stop {
    if ( TestServer_is_listening() ) {
        my $result = TestServer_rest('GET' => '/quit');
        return $result;
    }
}

sub TestServer_pid {
    return $pid;
}

sub TestServer_is_running {
    return unless defined $pid && $pid =~ /^\d+$/;
    kill 0, $pid;
}

sub get_rest_client {
    my $rest = REST::Client->new;
    $rest->setHost(TestServer_url());
    $rest->setTimeout(5);
    return $rest;
}

sub TestServer_rest {
    my ($method, $request) = @_;
    state $rest = get_rest_client();
    my $result = $rest->$method($request)->responseContent();
    return $result;
}

sub TestServer_test {
    return TestServer_rest('GET' => '/test');
}

sub TestServer_url {
    return "http://localhost:$port";
}

sub TestServer_port {
    return $port;
}

sub TestServer_is_listening {
    return 0 unless TestServer_is_running();

    # cribbed from IO::Socket::PortState
    # I didn't want to add ANOTHER dependency
    my $sock = IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    );
    return !defined $sock ? 0 : 1;
}

sub TestServer_get_unused_port {
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => 'localhost',
        Proto     => 'tcp',
    );
    my $p = $sock->sockport;
    $sock->shutdown(2);
    return $p;
}

###########################################################################
#
# functions to make the testing easier
#

sub chomper {
    chomp(my $thing = Dumper( @_ ));
    return $thing;
}

sub dump_got_expected {
    my $out = '# got = ' . Dumper( $_[0] );
    $out .= 'expected = ' . Dumper( $_[1] );
    $out =~ s/\n/\n# /gsx;
    print $out;
}

sub can_ok_abstract {
    my $thing = shift;
    can_ok( $thing, @_, qw/ data issue lazy_loaded init unload_lazy
                            populate_scalar_data populate_date_data
                            populate_list_data populate_scalar_field
                            populate_list_field mk_contextual_ro_accessors
                            mk_deep_ro_accessor mk_lazy_ro_accessor
                            mk_data_ro_accessors mk_field_ro_accessors
                            make_subroutine / );
}

sub can_ok_mixins {
    my $thing = shift;
    can_ok( $thing, @_, qw/ jira factory JIRA_REST REST_CLIENT
                            _JIRA_REST_version_has_named_parameters
                            make_object make_date class_for obj_isa
                            name_for_user key_for_issue dump
                            cosmetic_copy find_link_name_and_direction
                            _get_known_args _check_required_args
                            _croakmsg _quoted_list / );
}


use JIRA::REST::Class::FactoryTypes qw( %TYPES );

sub get_class {
    my $type = shift;
    return exists $TYPES{$type} ? $TYPES{$type} : $type;
}

sub validate_contextual_accessor {
    my $obj        = shift;
    my $args       = shift;
    my $methodname = $args->{method};
    my $class      = get_class($args->{class});
    my $objectname = $args->{name} || ref $obj;
    my $method     = join '->', ref($obj), $methodname;
    my @data       = @{ $args->{data} };

    print "#\n# Checking the $objectname->$methodname accessor\n#\n";

    my $scalar = $obj->$methodname;

    is( ref $scalar, 'ARRAY',
        "$method in scalar context returns arrayref" );

    cmp_ok( @$scalar, '==', @data,
            "$method arrayref has correct number of items" );

    my @list = $obj->$methodname;

    cmp_ok( @list, '==', @data, "$method returns correct size list ".
                                "in list context");

    subtest "Checking object types returned by $method", sub {
        foreach my $item ( sort @list ) {
            isa_ok( $item, $class, "$item" );
        }
    };

    my $list = [ map { "$_" } sort @list ];
    is_deeply( $list, \@data,
               "$method returns the expected $methodname")
        or dump_got_expected($list, \@data);
}

sub validate_expected_fields {
    my $obj    = shift;
    my $expect = shift;
    my $isa    = ref $obj || q{};

    if ($obj->isa(get_class('abstract'))) {
        # common accessors for ALL JIRA::REST::Class::Abstract objects
        $expect->{factory}     = { class => 'factory' };
        $expect->{jira}        = { class => 'class' };
        $expect->{JIRA_REST}   = { class => 'JIRA::REST' };
        $expect->{REST_CLIENT} = { class => 'REST::Client' };
    }

    foreach my $field ( sort keys %$expect ) {
        my $value  = $expect->{$field};

        if (! ref $value) {
            # expected a scalar
            my $quoted = ($value =~ /^\d+$/) ? $value : qq{'$value'};
            is( $obj->$field, $value, "'$isa->$field' returns $quoted");
        }
        elsif (ref $value && ref($value) =~ /^JSON::PP::/) {
            # expecting a boolean
            my $quoted = $value ? 'true' : 'false';
            is( $obj->$field, $value, "'$isa->$field' returns $quoted");
        }
        else {
            # expecting an object
            my $class = get_class($value->{class});
            my $obj2  = $obj->$field;

            isa_ok( $obj2, $class,  $isa.'->'.$field);

            my $expect2 = $value->{expected};
            next unless $expect2 && ref $expect2 eq 'HASH';

            # check simple accessors on the object
            foreach my $field2 ( sort keys %$expect2 ) {
                my $value2 = $expect2->{$field2};
                my $quoted = ($value2 =~ /^\d+$/) ? $value2 : qq{'$value2'};
                is( $obj->$field->$field2, $value2,
                    "'$isa->$field->$field2' method returns $quoted");
            }
        }
    }
}

sub validate_wrapper_method {
    my ($sub, $expected, $name) = @_;

    my $results;
    try {
        $results = $sub->();
    }
    catch {
        $results = $_;
    };

    is_deeply( $results, $expected, $name );
}

1;
