# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   IO::File::AtomicChange t::Utils
                   POSIX Filter::Util::Call
                 )],
    style   => 'heavy';
ok_dependencies();

# hmmmmm: Failed test 'Filter::Util::Call is not a run-time dependency'

