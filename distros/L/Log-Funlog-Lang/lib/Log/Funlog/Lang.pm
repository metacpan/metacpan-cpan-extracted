package Log::Funlog::Lang;

=head1 NAME

Log::Funlog::Lang - Language pack for Log::Funlog

=head1 SYNOPSIS

 use Log::Funlog::Lang;
 my @res=Log::Funlog::Lang->new( language );
 my @texts=@{ $res[1] };
 my $language_given=$res[0];

=head1 DESCRIPTION

This is a perl module used by B<Log::Funlog> to obtain a list of funny things in the language of the user.

=head1 OPTIONS

B<Log::Funlog::Lang> try to determinate the language of the user by parsing LC_MESSAGES and LANG. If it doesn't find any infos in these environment variable, it use 'en'

If it occurs, you must specify the language by the widely used two letters (fr, en, ...)

=over

=item B<language>

Two-letters code specifying language to use.

Available languages are: fr, en

Default to 'en'.

=back

=head1 AUTHOR

Gabriel Guillon, from Chashew team

korsani-spam@free-spam.fr-spam

(remove you-know-what :)

=head1 LICENCE

As Perl itself.

Let me know if you have added some features, or removed some bugs ;)

=cut

BEGIN {
	use Exporter;
	@ISA=qw(Exporter);
	@EXPORT=qw();
	$VERSION='0.3';
}
use strict;
use Carp;
my @fun;
my %fun=(
	'fr' => ["-- this line will never be written --",
	"Pfiou... marre de logger, moi",
	"J'ai faim!",
	"Je veux faire pipi!",
	"Dis, t'as pensé à manger?",
	"Fait froid dans ce process, non?",
	"Fait quel temps, dehors?",
	"Aller, pastis time!",
	"Je crois que je suis malade...",
	"Dis, tu peux me choper un sandwich?",
	"On se fait une toile?",
	"Aller, décolle un peu de l'écran",
	"Tu fais quoi ce soir, toi?",
	"On va en boîte?",
	"Pousse-toi un peu, je vois rien",
	"Vivement les vacances...",
	"Mince, j'ai pas prévenu ma femme que je finissais tard...",
	"Il est chouette ton projet?",
	"Bon, il est bientôt fini, ce process??",
	"Je m'ennuie...",
	"Tu peux me mettre la télé?",
	"Y a quoi ce soir?",
	"J'irais bien faire un tour à Pigalle, moi.",
	"Et si je formattais le disque?",
	"J'me ferais bien le tour du monde...",
	"Je crois que je suis homosexuel...",
	"Bon, je m'en vais, j'ai des choses à faire.",
	"Et si je changeais de taf? OS, c'est mieux que script, non?",
	"J'ai froid!",
	"J'ai chaud!",
	"Tu me prend un café?",
	"T'es plutôt chien ou chat, toi?",
	"Je crois que je vais aller voir un psy...",
	"Tiens, 'longtemps que j'ai pas eu de news de ma soeur!",
	"Comment vont tes parents?",
	"Comment va Arthur, ton poisson rouge?",
	"Ton chien a fini de bouffer les rideaux?",
	"Ton chat pisse encore partout?",
	"Tu sais ce que fait ta fille, là?",
	"T'as pas encore claqué ton chef?",
	"Toi, tu t'es engueulé avec ta femme, ce matin...",
	"T'as les yeux en forme de contener. Soucis?",
	"Et si je partais en boucle infinie?",
	"T'es venu à pied?",
	"Et si je veux pas exécuter la prochaine commande?",
	"Tiens, je vais me transformer en virus...",
	"Ca t'en bouche un coin, un script qui parle, hein?",
	"Ah m...., j'ai oublié les clés à l'intérieur de la voiture...",
	"T'as pas autre chose à faire, là?",
	"Ca devient relou...",
	"T'as pensé à aller voir un psy?",
	"Toi, tu pense à changer de job..."
	],
	'en' => ["-- this line will never be written --",
	"(scratch scratch ...)",
	"TOOOOO!!!! A DONUT !!!"],
);
sub new {
	shift;
	my $LC_MESSAGES=lc(shift);
	if (! $LC_MESSAGES) {
		if (exists $ENV{'LC_MESSAGES'}) {
			$LC_MESSAGES=substr($ENV{'LC_MESSAGES'},0,2);
		} elsif (exists $ENV{'LANG'}) {
			$LC_MESSAGES=substr($ENV{'LANG'},0,2);
		} else {
			$LC_MESSAGES='en';
		}
	}
	$LC_MESSAGES=lc($LC_MESSAGES);
	if (! exists $fun{$LC_MESSAGES}) {
#		carp("You specified a not implemented language: $LC_MESSAGES\nDefaulting to 'en'");
		$LC_MESSAGES='en';
	}
	return ($LC_MESSAGES,\@{ $fun{$LC_MESSAGES} });
};
1;
