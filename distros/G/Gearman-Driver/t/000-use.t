use Test::More tests => 11;

BEGIN {
    use_ok('Gearman::Driver');
    use_ok('Gearman::Driver::Console');
    use_ok('Gearman::Driver::Console::Basic');
    use_ok('Gearman::Driver::Console::Client');
    use_ok('Gearman::Driver::Job');
    use_ok('Gearman::Driver::Job::Method');
    use_ok('Gearman::Driver::Loader');
    use_ok('Gearman::Driver::Observer');
    use_ok('Gearman::Driver::Worker');
    use_ok('Gearman::Driver::Worker::AttributeParser');
    use_ok('Gearman::Driver::Worker::Base');
}

diag("Testing Gearman::Driver $Gearman::Driver::VERSION");
