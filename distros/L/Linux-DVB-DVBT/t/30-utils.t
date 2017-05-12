#!perl

use strict;
use warnings;
use Test::More ;

use Linux::DVB::DVBT::Utils ;


my @tests = (
	{
		'raw-title'	=> 'Wilfred',
		'raw-text'	=> 'New series. 1/13. Happiness: At the end of his tether, Ryan encounters his attractive neighbour\'s dog, Wilfred. Contains adult humour.  Also in HD. [AD,S]',

		'text'	=> 'Happiness: At the end of his tether, Ryan encounters his attractive neighbour\'s dog, Wilfred. Contains adult humour.',
		'title'	=> 'Wilfred',
		'subtitle'	=> 'Happiness',
		'episode'	=> 1,
		'episodes'	=> 13,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'Wilfred',
		'raw-text'	=> '2/13. Trust: Sitcom about a man who sees his neighbour\'s dog as a man in a canine costume. Ryan is torn between loyalty to Wilfred and Jenna. Contains adult humour.  Also in HD. [AD,S]',

		'text'	=> 'Trust: Sitcom about a man who sees his neighbour\'s dog as a man in a canine costume. Ryan is torn between loyalty to Wilfred and Jenna. Contains adult humour.',
		'title'	=> 'Wilfred',
		'subtitle'	=> 'Trust',
		'episode'	=> 2,
		'episodes'	=> 13,
		'new_program' => 0,
	},
	
	{
		'raw-title'	=> 'Numb3rs1',
		'raw-text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head. (1/18)',
		'text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head.',
		'title'	=> 'Numb3rs1',
		'subtitle'	=> 'Trust Metric',
		'episode'	=> 1,
		'episodes'	=> 18,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Numb3rs2',
		'raw-text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head. 1 / 18',
		'text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head.',
		'title'	=> 'Numb3rs2',
		'subtitle'	=> 'Trust Metric',
		'episode'	=> 1,
		'episodes'	=> 18,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Numb3rs3',
		'raw-text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head. Epi 1 of 18',
		'text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head.',
		'title'	=> 'Numb3rs3',
		'subtitle'	=> 'Trust Metric',
		'episode'	=> 1,
		'episodes'	=> 18,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Numb3rs4',
		'raw-text'	=> '1/18. Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head',
		'text'	=> 'Trust Metric: Colby escapes while being interrogated and Don and the team must find him. They receive fresh information about Colby that turns the investigation on its head',
		'title'	=> 'Numb3rs4',
		'subtitle'	=> 'Trust Metric',
		'episode'	=> 1,
		'episodes'	=> 18,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Vets1',
		'raw-text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging. (Part 16 of 26)',
		'text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging.',
		'title'	=> 'Vets1',
		'subtitle'	=> 'An obese parrot causes complications for vet Matt Brash',
		'episode'	=> 16,
		'episodes'	=> 26,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Vets2',
		'raw-text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging. Part 16 of 26',
		'text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging.',
		'title'	=> 'Vets2',
		'subtitle'	=> 'An obese parrot causes complications for vet Matt Brash',
		'episode'	=> 16,
		'episodes'	=> 26,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Vets3',
		'raw-text'	=> 'New  . An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging. Part 16 of 26',
		'text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging.',
		'title'	=> 'Vets3',
		'subtitle'	=> 'An obese parrot causes complications for vet Matt Brash',
		'episode'	=> 16,
		'episodes'	=> 26,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'Vets4',
		'raw-text'	=> 'ALL      neW episodes  !! An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging. Part 16 of 26',
		'text'	=> 'An obese parrot causes complications for vet Matt Brash. He must also help a cat deliver kittens by emergency caesarean and a swan recovers from a brutal mugging.',
		'title'	=> 'Vets4',
		'subtitle'	=> 'An obese parrot causes complications for vet Matt Brash',
		'episode'	=> 16,
		'episodes'	=> 26,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'Vets5',
		'raw-text'	=> 'The Gorilla Experiment: Penny feels left out when Bernadette shows an interest in science and asks Sheldon to educate her.',
		'text'	=> 'The Gorilla Experiment: Penny feels left out when Bernadette shows an interest in science and asks Sheldon to educate her.',
		'title'	=> 'Vets5',
		'subtitle'	=> 'The Gorilla Experiment',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Midsomer1',
		'raw-text'	=> 'Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'text'	=> 'Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'title'	=> 'Midsomer1',
		'subtitle'	=> 'Blood Wedding (Part 1)',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Midsomer2',
		'raw-text'	=> 'New. Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'text'	=> 'Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'title'	=> 'Midsomer2',
		'subtitle'	=> 'Blood Wedding (Part 1)',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'Midsomer3',
		'raw-text'	=> 'Brand new series! Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'text'	=> 'Blood Wedding (Part 1): Two weddings are due to take place - Cully\'s to Simon, and that of local baronet Ned Fitzroy. Then the maid of honour at Fitzroy\'s nuptials is found dead.',
		'title'	=> 'Midsomer3',
		'subtitle'	=> 'Blood Wedding (Part 1)',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'Julian Fellowes Investigates...',
		'raw-text'	=> '...a Most Mysterious Murder. The Case of xxxx. Epi 10 of 22',
		'text'	=> 'The Case of xxxx.',
		'title'	=> 'Julian Fellowes Investigates a Most Mysterious Murder',
		'subtitle'	=> 'The Case of xxxx',
		'episode'	=> 10,
		'episodes'	=> 22,
		'new_program' => 0,
	},

	{
		'raw-title'	=> 'Agatha Christies Marple',
		'raw-text'	=> '4:50 from Paddington: when Elizabeth McGillicuddy sees a woman on a train being strangled,',
		'text'	=> '4:50 from Paddington: when Elizabeth McGillicuddy sees a woman on a train being strangled,',
		'title'	=> 'Agatha Christies Marple',
		'subtitle'	=> '4:50 from Paddington',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'The Big Bang Theory',
		'raw-text'	=> 'Brand new series - The Herb Garden Germination: Sheldon and Amy experiment on their friends. ',
		'text'	=> 'The Herb Garden Germination: Sheldon and Amy experiment on their friends.',
		'title'	=> 'The Big Bang Theory',
		'subtitle'	=> 'The Herb Garden Germination',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 1,
	},
	{
		'raw-title'	=> 'New Tricks',
		'raw-text'	=> 'Only the Brave: Drama series. The team reinvestigates the murder of Eddie Chapman.',
		'text'	=> 'Only the Brave: The team reinvestigates the murder of Eddie Chapman.',
		'title'	=> 'New Tricks',
		'subtitle'	=> 'Only the Brave',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},

	{
		'raw-title'	=> '\x4e\x65\x77\x20\x54\x72\x69\x63\x6b\x73',
		'raw-text'	=> 'O\x01\x02nly the Brave: Drama series.\x0a The team reinvestigates the murder of Eddie Chapman.',
		'text'	=> 'Only the Brave: The team reinvestigates the murder of Eddie Chapman.',
		'title'	=> 'New Tricks',
		'subtitle'	=> 'Only the Brave',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> '\x0e\x05\x07\x02\x05\x02\x06\x06\x06\x07',
		'raw-text'	=> '\x7f\x02Only',
		'text'	=> 'unknown',
		'title'	=> 'unknown',
		'subtitle'	=> 'unknown',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},

# Depths: Crime drama. The body of an Arab diver is washed ashore on Coney Island, prompting fears of a terrorist plot.
# Lonelyville: Crime drama series. The discovery of a woman's body tied up with complex knots leads the detectives to a lonely writer researching the dating scene.
# Crime drama series. Goren and Eames hunt a killer whose fanatical beliefs may be the key to catching him.

	{
		'raw-title'	=> 'Law & Order: Criminal Intent',
		'raw-text'	=> 'Depths: Crime drama. The body of an Arab diver is washed ashore on Coney Island, prompting fears of a terrorist plot.',
		'text'	=> 'Depths: Crime drama. The body of an Arab diver is washed ashore on Coney Island, prompting fears of a terrorist plot.',
		'title'	=> 'Law & Order: Criminal Intent',
		'subtitle'	=> 'Depths',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Law & Order: Criminal Intent',
		'raw-text'	=> 'Lonelyville: Crime drama series. The discovery of a woman\'s body tied up with complex knots leads the detectives to a lonely writer researching the dating scene.',
		'text'	=> 'Lonelyville: The discovery of a woman\'s body tied up with complex knots leads the detectives to a lonely writer researching the dating scene.',
		'title'	=> 'Law & Order: Criminal Intent',
		'subtitle'	=> 'Lonelyville',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},
	{
		'raw-title'	=> 'Law & Order: Criminal Intent',
		'raw-text'	=> 'Crime drama series. Goren and Eames hunt a killer whose fanatical beliefs may be the key to catching him.',
		'text'	=> 'Goren and Eames hunt a killer whose fanatical beliefs may be the key to catching him.',
		'title'	=> 'Law & Order: Criminal Intent',
		'subtitle'	=> 'Goren and Eames hunt a killer whose fanatical beliefs may be the key to catching him',
		'episode'	=> 0,
		'episodes'	=> 0,
		'new_program' => 0,
	},

);

my @checks = (
	['title',		'Title unchanged'],
	['text',		'Text check'],
	['subtitle',	'Subtitle check'],
	['episode',		'Episode count check'],
	['episodes',	'Number of episodes check'],
	['new_program',	'"New program" flag check'],
) ;


plan tests => scalar(@tests) * (scalar(@checks) + 1) ;

	$Linux::DVB::DVBT::Utils::DEBUG = 0 ;
	
	foreach my $test_href (@tests)
	{
		my %results = (
			'text'		=> Linux::DVB::DVBT::Utils::text($test_href->{'raw-text'}),
			'title'		=> Linux::DVB::DVBT::Utils::text($test_href->{'raw-title'}),
			'subtitle'	=> '',
			'episode'	=> 0,
			'episodes'	=> 0,
			'new_program' => 0,
			'genre'		=> '',
		) ;
		
		my %flags ;
		Linux::DVB::DVBT::Utils::fix_title(\$results{title}, \$results{text}) ;
		Linux::DVB::DVBT::Utils::fix_synopsis(\$results{title}, \$results{text}, \$results{new_program}) ;

		Linux::DVB::DVBT::Utils::fix_episodes(\$results{title}, \$results{text}, \$results{episode}, \$results{episodes}) ;
		Linux::DVB::DVBT::Utils::fix_audio(\$results{title}, \$results{text}, \%flags) ;
		Linux::DVB::DVBT::Utils::subtitle(\$results{text}, \$results{subtitle}) ;
		
		## Process strings
		foreach my $field (qw/title subtitle text etext/)
		{
			# ensure filled with something
			if (!$results{$field})
			{
				$results{$field} = 'unknown' ;
			}
		}
		
		
		foreach my $aref (@checks)
		{
			my ($key, $msg) = @$aref ;
			$msg .= " - $test_href->{'raw-title'}" ;
			is($results{$key}, $test_href->{$key}, $msg) ;
		}
		
		## special test for subtitle
		$results{subtitle} = Linux::DVB::DVBT::Utils::subtitle($results{text}) ;
		foreach my $aref (['subtitle',	'Subtitle (old-api) check'])
		{
			my ($key, $msg) = @$aref ;
			$msg .= " - $test_href->{'raw-title'}" ;
			is($results{$key}, $test_href->{$key}, $msg) ;
		}
		
	}
	
__END__

