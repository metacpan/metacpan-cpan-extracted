use inc::Module::Install;
name 'Jenkins-NotificationListener';
all_from 'lib/Jenkins/NotificationListener.pm';

requires 'Net::Jenkins' => 0.03;
requires 'Moose';
requires 'methods';
requires 'JSON';
requires 'JSON::XS';
requires 'AnyEvent::Socket';
requires 'YAML';
requires 'URI';

tests 't/*.t';
author_tests 'xt';

readme_markdown_from_pod 'lib/Jenkins/NotificationListener.pm';
readme_from_pod 'lib/Jenkins/NotificationListener.pm';

install_script 'scripts/jenkins-notification-listener.pl';

test_requires 'Test::More' => 0,
    'LWP::Simple' => 0,
    'File::Read' => 0,
    'Time::HiRes' => 0,
    ;

# auto_set_repository;
auto_include;
WriteAll;
