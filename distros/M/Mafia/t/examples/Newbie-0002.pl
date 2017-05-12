use Mafia;

player 'Banana Bob', cop, town;
player 'Dragon Phoenix', vanilla, townie;
player 'Gammie', mafia, goon;
player 'gslamm', vanilla, townie;
player 'Untrod Tripod', mafia, goon;
player 'Werebear', vanilla, townie;
player 'willows_weep', town, doctor;

day;
lynch 'Untrod Tripod';

night;
factionkill 'Gammie', 'willows_weep', 'shot';
copcheck 'Banana Bob', 'gslamm';

day;
lynch 'Gammie';

night;
