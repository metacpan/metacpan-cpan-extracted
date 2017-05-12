use Test::More tests => 6;

use IMDB::Persons;
use Data::Dumper;

my %person_info = (
	code           	=> '0000129',
	id	           	=> '0000129',
	name           	=> qq{Tom Cruise},
	mini_bio       	=> qq{If you had told 14 year old Franciscan seminary student Thomas Cruise Mapother IV that one day in the not too distant future he would be considered one of the top 100 movie stars of all time, he would have probably grinned and told you that his ambition was to become a priest. Nonetheless, this sensitive...},
	date_of_birth  	=> qq{3 July 1962},
	place_of_birth 	=> qq{Syracuse, New York, USA}, 
	photo          	=> '/images/M/MV5BMTI4MzUyMTI1N15BMl5BanBnXkFtZTcwOTg3NTYyMQ@@._V1._SX100_SY140_.jpg',
	film			=> {
	            'title' => 'Mission: Impossible III',
				'role' 	=> 'Ethan Hunt',
				'year' 	=> '2006',
				'code' 	=> '0317919'				
	},
	genres			=> ['Documentary', 'News', 'Talk-Show', 'Comedy'],
	plot_keywords	=> ['Number In Title', 'TV Special', 'Awards Show', 'Non Fiction'],
);

my %pars = (crit => $person_info{name}, cache => 0, debug => 0);
my $p = new IMDB::Persons(%pars);

is($p->code, $person_info{code}, 'code');
is($p->name, $person_info{name}, 'name');
is($p->date_of_birth, $person_info{date_of_birth}, 'date_of_birth');
is($p->place_of_birth, $person_info{place_of_birth}, 'place_of_birth');
is($p->mini_bio, $person_info{mini_bio}, 'mini_bio');
like($p->photo, qr#\.jpg#i, 'photo');

# FIXME: Temporary disabled
#my $list = $p->filmography();
#my $f = 0;
#for my $movie(@{$list->{'Actor'}}) {
#	if($movie->{title} eq $person_info{film}->{title}) {
#		is($movie->{code}, $person_info{film}->{code}, 'movie code');
#		is($movie->{year}, $person_info{film}->{year}, 'movie code');
#		is($movie->{role}, $person_info{film}->{role}, 'movie code');
#		$f = 1;
#		last;
#	}
#}	

#is($f, 1, 'filmography');
