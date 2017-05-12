package Games::CroqueMonster;

use warnings;
use strict;

use LWP::Simple;
use XML::Simple;
use Data::Dumper;

=head1 NAME

Games::CroqueMonster - An interface for the French web game CroqueMonster.

=head1 VERSION

Version 0.8.1-2

=cut

our $VERSION = '0.8.1-2';


=head1 SYNOPSIS

This module implements the 0.8.1 version of the CroqueMonster web game (http://www.croquemonster.com).

I decided to give version number of this module after the CroqueMonster API's own version number. I think it is easier for peoples to know what API version this module implements.

The number after the dash (-) is this module own version (0.8.1-1 means this is the first version of this module implementing the version 0.8.1 of CroqueMonster's API).

There is few required dependencies (all available from CPAN) : LWP::Simple and XML::Simple.

    use Games::CroqueMonster;

    my $cm = Games::CroqueMonster->new(agency_name => 'UglyBeasts');
    my $agency_info = $cm->agency();

So far the CroqueMonster's API only allow to retrieve informations, but maybe in some uncertain futur it will be possible to take actions with it...

Technically speaking, this module interacts with a webb service. So you cannot get a fully functionnal game with this module alone, only easily create interfaces for the game itself.

=head1 CONSTRUCTOR

=head2 new

This is the object constructor. It takes the following optionnal parameters :

	* api_key : your CroqueMonster API password
	* agency_name : the agency name
	* syndicate_name : the syndicate name

=cut

sub new {
	my ($class,%params) = @_;
	my $self = { _data => {%params} };
	bless($self,$class);
	return $self;
}

=head1 METHODS

=head1 Publicly available data access methods

=head2 agency

Implements: http://www.croquemonster.com/api/help#h2n3n1 (page in french)
Take one parameter : the name of the agency (this is not mandatory if constructor's agency_name parameter was filled).

	my $agency = $cm->agency('UglyBeasts') ;

On success, the returned hashref look like that :

	$VAR1 = {
		'agency' => {
			'failedA' => '0',
			'contractsD' => '0',
			'contractsA' => '9',
			'reputation' => '135',
			'failedC' => '0',
			'gold' => '490',
			'id' => '383869',
			'maxMonsters' => '7',
			'failedD' => '0',
			'scared' => '8',
			'portails' => '1',
			'failedB' => '0',
			'name' => 'UglyBeasts',
			'score' => '91',
			'description' => {'Here we are hiring only the ugliest and the more saddistics monsters !'},
			'contractsB' => '0',
			'days' => '2',
			'monsters' => '4',
			'level' => '3',
			'devoured' => '1',
			'mails' => '0',
			'contractsC' => '0',
			'cities' => '3'
		}
        };

The following keys are present only when you provide a valid "api_key" : 

	* gold
	* mails

On error it looks like that :

	$VAR1 = {
		'err' => {
				'error' => 'API access disabled',
				should_retry => 0,
			}
		};

Please see the ERRORS, section for a list of all error strings.

=cut

sub agency {
	my ($self,$agency) = @_;
	$agency = $self->{_data}->{agency_name} if( !defined($agency) && defined($self->{_data}->{agency_name}));
	my $param="name=$agency";
	$param .= "&pass=$self->{_data}->{api_key}" if( defined($self->{_data}->{api_key}) );
	my $content = get("http://www.croquemonster.com/api/agency.xml?$param");
	return _parse_data($content);
}

=head2 syndicate

Implements: http://www.croquemonster.com/api/help#h2n3n2 (in french)

Take one parameter : the name of the agency (this is not mandatory if constructor's agency_name parameter was filled).

	my $syndicate = $cm->syndicate('Tenebrae') ;

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'syndicate' => {
				'co2' => '2736',
				'co2bonus' => '105',
				'name' => 'ChupAngelic',
				'score' => '4374',
				'description' => "
					<p><img src=\"http://img128.imageshack.us/img128/9388/extrabanretouchetitreenvl0.jpg\" alt=\"Image\"/></p>
					<h1>Origines</h1>
					<p><strong>D-Tritus</strong> \x{2026} plan\x{e8}te hostile, peupl\x{e9}e en surnombre par des monstres de tout horizon. 
					[...]
					<p>27/04/08: Hordal was here...directeur du syndicat le temps de booster la mont\x{e9}e du tas d'ordures. Mission r\x{e9}ussie!</p>
					",
				'war' => [
					'1235',
					{
						'date' => '2008-01-28 08:31:50',
						'name' => 'Soul Society',
						'id' => '1'
					},
					[...]
					{
						'date' => '2008-09-08 21:15:57',
						'name' => 'One Piece',
						'id' => '2650'
					}
					],
				'days' => '381',
				'co2max' => '2631',
				'agency' => {
					'Kakarott13' => {
								'level' => '20',
								'reputation' => '99529',
								'score' => '102754',
								'id' => '41550'
							},
					[...]
					'hedu89' => {
								'level' => '29',
								'reputation' => '609505',
								'score' => '359193',
								'id' => '41692'
						}
					},
				'id' => '796',
				'influence' => '403'
			}
		};

The first value of the war array reference ( $VAR1->{syndicate}->{war}->[0] ) is the syndicate war score (points won during wars).

Please see ERRORS section for values returned on error.

=cut

sub syndicate {
	my $self = shift ;
	my $input = shift;
	my $content = get("http://www.croquemonster.com/api/syndicate.xml?name=$input");
	return  _parse_data($content, ForceArray => ['agency','war']);

}

=head2 items

Implements: http://www.croquemonster.com/api/help#h2n3n3

Return the list of all game's usable items. Those one can be used to improved your monsters.

Takes no parameters.

	my $items = $cm->items() ;

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'items' => {
			'item' => {
				'11' => {
					'name' => "R\x{e9}gime di\x{e9}t\x{e9}tique",
					'id' => '11',
					'image' => '/gfx/tech/icone_regime.gif'
					},
				[...]
				'5' => {
					'name' => "Insectes dress\x{e9}s",
					'id' => '5',
					'image' => '/gfx/tech/icone_insecte.gif'
					}
				}
			}
		};

Path representing the item image is relative to http://www.croquemonster.com.

Please see ERRORS section for values returned on error.

=cut

sub items {
	my $self = shift;
	my $content = get("http://www.croquemonster.com/api/items.xml");
	return  _parse_data($content, KeyAttr => {'item' => '+id'});
}

=head1 Private informations access methods

Those methods cannot be called without filling the api_key and agency_name constructor's parameters (well... you can call them but they will end in error).

=cut

=head2 monsters

Implements: http://www.croquemonster.com/api/help#h2n4n2

Takes no parameters.

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'monsters' => {
				'monster' => {
					'2195056' => {
							'fight' => '0',
							'fusions' => '0',
							'contractItems' => '',
							'endurance' => '2',
							'permanentItems' => '',
							'successes' => '1',
							'power' => '0',
							'ugliness' => '0',
							'id' => '2195056',
							'fatigue' => '1',
							'control' => '0',
							'failures' => '0',
							'contract' => '239582559',
							'bounty' => '0',
							'name' => 'UB0004',
							'greediness' => '1',
							'sadism' => '0',
							'firePrize' => '1440',
							'swfjs' => 'http://www.croquemonster.com/monster/drawSWF.js?face=Gfu2_cYikII05c7Wd:I7aIVqfmM8SSu7Pf_',
							'devoured' => '1'
							},
					[...]
					'2187820' => {
							'fight' => '0',
							'fusions' => '0',
							'contractItems' => '',
							'endurance' => '1',
							'permanentItems' => '15',
							'successes' => '2',
							'power' => '1',
							'ugliness' => '1',
							'id' => '2187820',
							'fatigue' => '0',
							'control' => '2',
							'failures' => '1',
							'contract' => '239582555',
							'bounty' => '0',
							'name' => 'UB0001',
							'greediness' => '0',
							'sadism' => '0',
							'firePrize' => '2640',
							'swfjs' => 'http://www.croquemonster.com/monster/drawSWF.js?face=Gfu2_d:aHLI05c7md:s7bIVqfmk8SSKgieq',
							'devoured' => '0'
							}
					},
				'id' => '383869',
				'agency' => 'UglyBeasts'
			}
		};

Please see ERRORS section for values returned on error.

=cut

sub monsters {
	my $self = shift;
	my $content = get("http://www.croquemonster.com/api/monsters.xml?name=$self->{_data}->{agency_name};pass=$self->{_data}->{api_key}
");
	return  _parse_data($content, KeyAttr => {'monster' => '+id'});
}

=head2 portals

Implements: http://www.croquemonster.com/api/help#h2n4n3

Takes no parameters.

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'portails' => {
				'portail' => {
					'1141215' => {
							'country' => 'Allemagne',
							'city' => 'Saarbruck',
							'level' => '1',
							'timezone' => '0',
							'defense' => '0',
							'id' => '1141215'
							},
					'1160353' => {
							'country' => 'Etats-Unis',
							'city' => 'Columbus',
							'level' => '1',
							'timezone' => '-6',
							'defense' => '0',
							'id' => '1160353'
							}
					},
				'id' => '383869',
				'agency' => 'UglyBeasts'
			}
		};

Please see ERRORS section for values returned on error.

=cut

sub portals {
	my $self = shift;
	my $content = get("http://www.croquemonster.com/api/portails.xml?name=$self->{_data}->{agency_name};pass=$self->{_data}->{api_key}");
	return  _parse_data($content, KeyAttr => {'portail' => '+id'});
}

=head2 contracts

Implements: http://www.croquemonster.com/api/help#h2n4n4

Takes no parameters.

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'contracts' => {
				'contract' => {
					'239582560' => {
							'country' => 'Allemagne',
							'difficulty' => '2',
							'timezone' => '0',
							'name' => 'Marine',
							'greediness' => '0',
							'age' => '4',
							'sex' => '1',
							'city' => 'Saarbruck',
							'sadism' => '0',
							'accepted' => 'false',
							'power' => '0',
							'id' => '239582560',
							'ugliness' => '0',
							'countdown' => '10275',
							'prize' => '135'
							},
					[...]
					'239582555' => {
							'country' => 'Allemagne',
							'difficulty' => '6',
							'timezone' => '1',
							'name' => 'Mathis',
							'greediness' => '0',
							'age' => '7',
							'sex' => '0',
							'city' => 'Mannheim',
							'sadism' => '0',
							'monster' => '2187820',
							'accepted' => 'true',
							'power' => '1',
							'id' => '239582555',
							'ugliness' => '0',
							'countdown' => '6675',
							'prize' => '570'
							}
					},
				'paradox' => {
					'level' => '1',
					'next' => '2008-09-13 07:31:52'
					},
				'id' => '383869',
				'agency' => 'UglyBeasts'
			}
		};


Please see ERRORS section for values returned on error.

=cut

sub contracts {
	my $self = shift;
	my $content = get("http://www.croquemonster.com/api/contracts.xml?name=$self->{_data}->{agency_name};pass=$self->{_data}->{api_key}");
	return  _parse_data($content, KeyAttr => {'contract' => '+id'});
}

=head2 inventory

Implements: http://www.croquemonster.com/api/help#h2n4n5

Takes no parameters.

On success, the returned hashref look like that (When you see [...] it just means that there was too many data and I cutted some) :

	$VAR1 = {
		'inventory' => {
				'factory' => {
					'next' => [
							{
							'name' => "Cr\x{e8}me \x{e0} acn\x{e9}",
							'id' => '2',
							'end' => '2008-10-28 08:33:50'
							},
							{
							'name' => "Cr\x{e8}me \x{e0} acn\x{e9}",
							'id' => '3',
							'end' => '2008-10-28 08:35:50'
							}
						],
					'name' => "Cr\x{e8}me \x{e0} acn\x{e9}",
					'id' => '1',
					'end' => '2008-10-28 08:31:50'
					},
				'resource' => {
					'1' => {
						'name' => 'Chaussette sale',
						'id' => '1',
						'qty' => '2'
						},
					'2' => {
						'name' => 'petite voiture',
						'id' => '2',
						'qty' => '1'
						}
					},
				'item' => {
					'1' => {
						'name' => "Cr\x{e8}me \x{e0} acn\x{e9}",
						'id' => '1',
						'qty' => '3'
						},
					'2' => {
						'name' => "Ombres port\x{e9}es",
						'id' => '2',
						'qty' => '3'
						}
					},
				'id' => 'ID agence',
				'agency' => 'NOM Agence'
			}
		};


Please see ERRORS section for values returned on error.

=cut

sub inventory {
	my $self = shift;
	my $content = get("http://www.croquemonster.com/api/inventory.xml?name=$self->{_data}->{agency_name};pass=$self->{_data}->{api_key}");
	return  _parse_data($content, KeyAttr => {'resource' => '+id','item' => '+id','factory' => '+id', 'next' => '+id'});
}

sub _parse_data {
	my $content = shift ;
	my %parse_options = @_;
	my $xml_data = XML::Simple::XMLin( $content , KeepRoot => 1,%parse_options);
	if(exists($xml_data->{locked}) ){
		$xml_data = {
					'err' => {
							'error' => 'Timezone opened',
							'should_retry' => 1,
						}
					};
	}elsif(defined($xml_data->{err}) ){
		$xml_data->{err}->{should_retry} = 0;
	}
	return $xml_data;
}

=head1 ERRORS

When a call end up in error, a hash reference is returned. This hashref look like this :

	$VAR1 = {
		'err' => {
				'error' => '<error string>',
				'should_retry' => 0|1
			}
		};

The error string can be :

	* Unknown user : the agency name does not exist.
	* Unknown syndicate : the syndicate name does not exist
	* API access disabled : user have not activates the API key (it is done on the web account).
	* Bad password : API key is not correct.
	* Timezone opened : every hours, a timezone is opened and the website block all users for few seconds. You should wait a little an retry.

For all those errors the 'should_retry' parameter is set to 0 (false), but for "Timezone opened" wich is a temporary error and the application should wait a little and retry.

=head1 AUTHOR

Arnaud Dupuis, C<< <a.dupuis at infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-croquemonster at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-CroqueMonster>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::CroqueMonster


You can also look for information at:

=over 4

=item * Infinity Perl (author website)

L<http://www.infinityperl.org>

=item * CroqueMonster's API

L<http://www.croquemonster.com/api/help>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-CroqueMonster>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-CroqueMonster>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-CroqueMonster>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-CroqueMonster>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Arnaud Dupuis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Games::CroqueMonster
