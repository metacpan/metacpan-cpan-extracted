#!/usr/bin/perl
use utf8;

use Test::Spec;

use Karel::Parser::Czech;

my $CLASS = 'Karel::Parser::Czech';

describe $CLASS => sub {

    it 'instantiates' => sub {
        my $parser = $CLASS->new;
        isa_ok $parser, $CLASS;
    };

    describe 'errors' => sub {


        my ($command, $E, $expected_exception);
        shared_examples_for 'failure' => sub {
            it 'fails' => sub {
                my $parser = $CLASS->new;
                trap { $parser->parse($command) };
                $E = $trap->die;
                isa_ok $E, "$CLASS\::Exception";
                cmp_deeply $E, noclass($expected_exception);
            };
        };

        my @valid = do { no warnings 'qw';
                         qw( dokud když opakuj vlevo krok polož zvedni
                             stůj alpha # space )
                       };

        describe 'unfinished command' => sub {
            before all => sub {
                $command = <<'__EOF__';
příkaz chyba
dokud je zeď
  krok
__EOF__
                $expected_exception= { last_completed => 'krok',
                                       pos => [3, 8],
                                       expected => bag(@valid, 'hotovo'),
                                   };
            };
            it_should_behave_like 'failure';
        };

        describe 'missing end' => sub {
            before all => sub {
                $command = << '__EOF__';
příkaz chyba
dokud je zeď
  krok
hotovo
__EOF__
                $expected_exception
                    = { last_completed => re(qr/dokud .* hotovo/xs),
                        pos => [4, 8],
                        expected => bag(@valid, 'konec'),
                      };
            };
            it_should_behave_like 'failure';
        };

        describe 'handles an unknown word' => sub {
            before all => sub {
                $command = << '__EOF__';
příkaz chyba krok dokud je zeďx
krok hotovo konec
__EOF__
                $expected_exception= { last_completed => 'krok',
                                       pos => [ 1, 1 + index $command, 'x' ],
                                       expected => bag(do { no warnings 'qw'; qw( # space ) }),
                                   };
            };
            it_should_behave_like 'failure';
        };
    };
};

runtests();
