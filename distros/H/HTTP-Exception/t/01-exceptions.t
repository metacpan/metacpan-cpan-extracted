use strict;

use Test::Exception;
use Test::More;
use HTTP::Exception;
use HTTP::Status;

my @exception_class_classes = Exception::Class::Classes();
my %exception_class_classes;
@exception_class_classes{@exception_class_classes} = undef;

################################################################################
# HTTP::Exception Tests
ok  exists $exception_class_classes{'HTTP::Exception'}, 'HTTP::Exception acts as loader and exception';
throws_ok sub { HTTP::Exception->throw(200) },  'HTTP::Exception::200';
throws_ok sub { HTTP::Exception->throw },       qr/HTTP::Exception->throw needs a HTTP-Statuscode to throw/;
throws_ok sub { HTTP::Exception->throw(1) },    qr/Unknown HTTP-Statuscode:/;

eval { HTTP::Exception->throw };
my $e0 = HTTP::Exception->caught;
ok (!defined $e0, 'HTTP::Exception is not caught when no Errorcode is given');

eval { HTTP::Exception->throw(1) };
my $e00 = HTTP::Exception->caught;
ok (!defined $e00, 'HTTP::Exception is not caught when wrong Errorcode is given');

my $e2 = HTTP::Exception->new(200);
__PACKAGE__->_run_tests_for_exception_object($e2);

delete $exception_class_classes{'HTTP::Exception'}; # got a special treatment



################################################################################
# HTTP::Exception::... Tests
for my $exception_name (keys %exception_class_classes) {
    # testing whether throw works
    throws_ok sub { $exception_name->throw }, $exception_name;

    # testing whether new works
    my $e = $exception_name->new;
    isa_ok  $e, $exception_name;
    __PACKAGE__->_run_tests_for_exception_object($e);

    # testing whether catching via HTTP::Exception works
    eval { $exception_name->throw() };
    my $e1 = HTTP::Exception->caught;
    isa_ok  $e1, $exception_name;
    __PACKAGE__->_run_tests_for_exception_object($e1);

    # testing catch via HTTP::Exception::NXX classes
    # maybe using another tests' result is not so good, but anyways
    my $error_code_range = $e1->code;
    $error_code_range =~ s/\d{2}$/XX/;
    eval { $exception_name->throw() };
    my $e2 = "HTTP::Exception::$error_code_range"->caught;
    __PACKAGE__->_run_tests_for_exception_object($e2);

    # testing whether catching via HTTP::Exception::... works
    eval { $exception_name->throw() };
    my $e3 = $exception_name->caught;
    isa_ok  $e3, $exception_name;
    __PACKAGE__->_run_tests_for_exception_object($e3);
}



################################################################################
# tests sub
sub _run_tests_for_exception_object {
    my $class = shift;
    my $e = shift;

    like    $e->code,
            qr/\d+/,
            'code is a number ('. $e->code .')';

    is      $e->status_message,
            HTTP::Status::status_message($e->code),
            'status_message is same as HTTP::Status';

    is      $e->as_string,
            HTTP::Status::status_message($e->code),
            'to_string as well';

    is      (($e->Fields)[0],
            'status_message',
            'field status_message found');

    can_ok  $e,
            qw(code status_message as_string);

    ok      !$e->can('_make_exceptions'),
            '_make_exceptions is not imported from Loader';


    SKIP: {
        # yes, ugly, I know
        skip q(can't reliably determine expected Errorcode), 2 unless (ref($e) =~ /(\d+)$/);

        is  $e->code,
            $1,
            'Errorcode in Classname and expected HTTP-Errorcode match';
    };

}

done_testing;