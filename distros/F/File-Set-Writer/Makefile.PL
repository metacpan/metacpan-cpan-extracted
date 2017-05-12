use inc::Module::Install;

name            'File-Set-Writer';
all_from        'lib/File/Set/Writer.pm';
license         'perl';

# Run-Time Requirements
requires        'Moo'                              => '0';
requires        'MooX::Types::MooseLike::Base'     => '0';
requires        'MooX::Types::MooseLike::Numeric'  => '0';

# Test Requirements
test_requires   'Test::More'    => '0.90'; # done_testing()

WriteAll;
