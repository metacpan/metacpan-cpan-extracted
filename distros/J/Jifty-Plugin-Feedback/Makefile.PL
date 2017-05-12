use inc::Module::Install 0.85;
name('Jifty-Plugin-Feedback');
all_from('lib/Jifty/Plugin/Feedback.pm');

requires('Jifty' => 1.00506);

auto_install();
tests(qw( t/*/t/*.t ));

WriteAll;
