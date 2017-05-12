use Test::Dependencies
	exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic Devel::DLMProf/],
	style   => 'light';
ok_dependencies();
