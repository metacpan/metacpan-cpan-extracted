#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Games::SMTNocturne::Demons;

set_fusion_options({ bosses => ['Raphael'] });
fusion_is('Dominion', 'Uriel', 'Raphael');

set_fusion_options({ bosses => ['Gabriel'] });
fusion_is('Throne', 'Raphael', 'Gabriel');

set_fusion_options({ sacrifice => 'Raphael' });
fusion_is('Uriel', 'Gabriel', 'Michael');
set_fusion_options({ sacrifice => 'Uriel' });
fusion_is('Raphael', 'Gabriel', 'Michael');
set_fusion_options({ sacrifice => 'Gabriel' });
fusion_is('Uriel', 'Raphael', 'Michael');

set_fusion_options({ bosses => ['Metatron'], sacrifice => 'Abaddon' });
fusion_is('Michael', 'Principality', 'Metatron');
set_fusion_options({ bosses => ['Metatron'], sacrifice => 'Abaddon' });
fusion_is('Michael', 'Uriel', 'Metatron');

set_fusion_options({ sacrifice => 'Surt' });
fusion_is('Ose', 'Naga', 'Gurr');

set_fusion_options({ bosses => ['Girimehkala'], sacrifice => 'Arahabaki' });
fusion_is('Kelpie', 'Kali', 'Girimehkala');

set_fusion_options({ bosses => ['Samael'], sacrifice => 'Pazuzu' });
fusion_is('Nyx', 'Jinn', 'Samael');

set_fusion_options({ sacrifice => 'Uzume' });
fusion_is('Yatagarasu', 'Mikazuchi', 'Amaterasu');

set_fusion_options({ bosses => ['Ongyo-Ki'], sacrifice => 'Fuu-Ki' });
fusion_is('Kin-Ki', 'Sui-Ki', 'Ongyo-Ki');
set_fusion_options({ bosses => ['Ongyo-Ki'], sacrifice => 'Kin-Ki' });
fusion_is('Fuu-Ki', 'Sui-Ki', 'Ongyo-Ki');
set_fusion_options({ bosses => ['Ongyo-Ki'], sacrifice => 'Sui-Ki' });
fusion_is('Kin-Ki', 'Fuu-Ki', 'Ongyo-Ki');

set_fusion_options({});
fusion_is('Rangda', 'Barong', 'Shiva');

set_fusion_options({ bosses => ['Sakahagi'] });
fusion_is('Phantom', 'Aquans', 'Sakahagi');
set_fusion_options({ bosses => ['Sakahagi'] });
fusion_is('Shadow', 'Erthys', 'Sakahagi');
set_fusion_options({ bosses => ['Sakahagi'] });
fusion_is('Shadow', 'Aeros', 'Sakahagi');
set_fusion_options({ bosses => ['Sakahagi'] });
fusion_is('Shadow', 'Flaemis', 'Sakahagi');

set_fusion_options({ bosses => ['Matador'], deathstone => 1, kagutsuchi => 2 });
fusion_is('Yaka', 'Incubus', 'Matador');

set_fusion_options({ bosses => ['Daisoujou'], deathstone => 1, kagutsuchi => 7 });
fusion_is('Yurlungur', 'Mothman', 'Daisoujou');

set_fusion_options({ bosses => ['Hell Biker'], deathstone => 1, kagutsuchi => 4 });
fusion_is('Shikigami', 'Zhen', 'Hell Biker');

set_fusion_options({ bosses => ['White Rider'], deathstone => 1, kagutsuchi => 0 });
fusion_is('Kurama', 'Pazuzu', 'White Rider');

set_fusion_options({ bosses => ['Red Rider'], deathstone => 1, kagutsuchi => 0 });
fusion_is('Badb Catha', 'Succubus', 'Red Rider');

set_fusion_options({ bosses => ['Black Rider'], deathstone => 1, kagutsuchi => 0 });
fusion_is('Beelzebub', 'Koppa', 'Black Rider');

set_fusion_options({ bosses => ['Pale Rider'], deathstone => 1, kagutsuchi => 0 });
fusion_is('Horus', 'Gurr', 'Pale Rider');

set_fusion_options({ bosses => ['The Harlot'], deathstone => 1, kagutsuchi => 4 });
fusion_is('Shiva', 'Girimehkala', 'The Harlot');

set_fusion_options({ bosses => ['Trumpeter'], deathstone => 1, kagutsuchi => 8 });
fusion_is('Dionysus', 'Tao Tie', 'Trumpeter');

done_testing;
