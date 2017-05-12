use Mafia;

player fgdtdtdtdr => doctor, town;
player MeMe => vanilla, townie;
player PrettyPrincess => mafia, goon;
player rite => vanilla, townie;
player shadyforce => vanilla, townie;
player Stewie => mafia, goon;
player ZONEACE => town, cop;

day;
lynch 'fgdtdtdtdr';

night;
factionkill Stewie => MeMe => 'shot';
copcheck ZONEACE => 'rite';

day;
lynch 'ZONEACE';

night;
