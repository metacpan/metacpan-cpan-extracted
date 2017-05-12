use Mafia;

player EnPaceRequiescat => mafia, goon;
player Fishbulb => vanilla, townie;
player 'Flying Dutchman' => vanilla, townie;
player 'Might Raven' => mafia, goon;
player Morpheus => doctor, town;
player Mr_Gnome_It_All => vanilla, townie;
player 'Vraak X' => town, cop;

day;
lynch 'Flying Dutchman';

night;
factionkill EnPaceRequiescat => 'Fishbulb', 'shot';
copcheck 'Vraak X' => 'Fishbulb';
protect Morpheus => 'Vraak X';

day;
lynch 'Mr_Gnome_It_All';

night;
