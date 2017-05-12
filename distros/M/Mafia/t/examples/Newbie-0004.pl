use Mafia;

player Sugar => town, doctor;
player tehgood => vanilla, townie;
player Yggdrasil => town, cop;
player Smoke_Bandit => vanilla, townie;
player Someone => mafia, goon;
player Just_nigel => vanilla, townie;
player Phoebus => mafia, goon;

day;
lynch 'tehgood';

night;
copcheck Yggdrasil => 'Sugar';
factionkill Someone => 'Sugar', 'shot';

day;
lynch 'Phoebus';

night;
copcheck Yggdrasil => 'Just_nigel';
factionkill Someone => 'Yggdrasil', 'shot';

day;
lynch 'Smoke_Bandit';

night;
