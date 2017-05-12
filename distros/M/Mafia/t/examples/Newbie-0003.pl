use Mafia;

player Bloojay => town, doctor;
player Kerplunk => vanilla, townie;
player max22 => town, cop;
player nard054 => vanilla, townie;
player QX => mafia, goon;
player Stimpy => vanilla, townie;
player Talitha => mafia, goon;

day;
lynch 'Stimpy';

night;
factionkill Talitha => 'Bloojay', 'shot';
copcheck max22 => 'Kerplunk';

day;
lynch 'nard054';

night;
