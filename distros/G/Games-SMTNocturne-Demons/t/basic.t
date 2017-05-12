#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::Games::SMTNocturne::Demons;

set_fusion_options({ bosses => ['Forneus', 'Troll'] });

fusion_is('Uzume', 'Jack Frost', 'Forneus');
fusion_is('Uzume', 'Mou-Ryo',    undef);
fusion_is('Uzume', 'Inugami',    'Unicorn');
fusion_is('Uzume', 'Shikigami',  'Taraka');
fusion_is('Uzume', 'Isora',      'Minakata');
fusion_is('Uzume', 'Zhen',       'Baphomet');

fusion_is('Jack Frost', 'Uzume',      'Forneus');
fusion_is('Jack Frost', 'Mou-Ryo',    'Choronzon');
fusion_is('Jack Frost', 'Inugami',    'Angel');
fusion_is('Jack Frost', 'Shikigami',  'Lilim');
fusion_is('Jack Frost', 'Isora',      'Shiisaa');
fusion_is('Jack Frost', 'Zhen',       'Apsaras');

fusion_is('Mou-Ryo', 'Uzume',      undef);
fusion_is('Mou-Ryo', 'Jack Frost', 'Choronzon');
fusion_is('Mou-Ryo', 'Inugami',    'Bicorn');
fusion_is('Mou-Ryo', 'Shikigami',  'Bicorn');
fusion_is('Mou-Ryo', 'Isora',      'Nozuchi');
fusion_is('Mou-Ryo', 'Zhen',       'Inugami');

fusion_is('Inugami', 'Uzume',      'Unicorn');
fusion_is('Inugami', 'Jack Frost', 'Angel');
fusion_is('Inugami', 'Mou-Ryo',    'Bicorn');
fusion_is('Inugami', 'Shikigami',  'Taraka');
fusion_is('Inugami', 'Isora',      'Forneus');
fusion_is('Inugami', 'Zhen',       'Sudama');

fusion_is('Shikigami', 'Uzume',      'Taraka');
fusion_is('Shikigami', 'Jack Frost', 'Lilim');
fusion_is('Shikigami', 'Mou-Ryo',    'Bicorn');
fusion_is('Shikigami', 'Inugami',    'Taraka');
fusion_is('Shikigami', 'Isora',      'Taraka');
fusion_is('Shikigami', 'Zhen',       'Jack Frost');

fusion_is('Isora', 'Uzume',      'Minakata');
fusion_is('Isora', 'Jack Frost', 'Shiisaa');
fusion_is('Isora', 'Mou-Ryo',    'Nozuchi');
fusion_is('Isora', 'Inugami',    'Forneus');
fusion_is('Isora', 'Shikigami',  'Taraka');
fusion_is('Isora', 'Zhen',       'Inugami');

fusion_is('Zhen', 'Uzume',      'Baphomet');
fusion_is('Zhen', 'Jack Frost', 'Apsaras');
fusion_is('Zhen', 'Mou-Ryo',    'Inugami');
fusion_is('Zhen', 'Inugami',    'Sudama');
fusion_is('Zhen', 'Shikigami',  'Jack Frost');
fusion_is('Zhen', 'Isora',      'Inugami');

done_testing;
