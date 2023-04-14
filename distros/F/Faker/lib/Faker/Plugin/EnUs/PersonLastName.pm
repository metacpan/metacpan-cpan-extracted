package Faker::Plugin::EnUs::PersonLastName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_last_name());
}

sub data_for_last_name {
  state $last_name = [
    'Abbott',
    'Abernathy',
    'Abshire',
    'Adams',
    'Altenwerth',
    'Anderson',
    'Ankunding',
    'Armstrong',
    'Auer',
    'Aufderhar',
    'Bahringer',
    'Bailey',
    'Balistreri',
    'Barrows',
    'Bartell',
    'Bartoletti',
    'Barton',
    'Bashirian',
    'Batz',
    'Bauch',
    'Baumbach',
    'Bayer',
    'Beahan',
    'Beatty',
    'Bechtelar',
    'Becker',
    'Bednar',
    'Beer',
    'Beier',
    'Berge',
    'Bergnaum',
    'Bergstrom',
    'Bernhard',
    'Bernier',
    'Bins',
    'Blanda',
    'Blick',
    'Block',
    'Bode',
    'Boehm',
    'Bogan',
    'Bogisich',
    'Borer',
    'Bosco',
    'Botsford',
    'Boyer',
    'Boyle',
    'Bradtke',
    'Brakus',
    'Braun',
    'Breitenberg',
    'Brekke',
    'Brown',
    'Bruen',
    'Buckridge',
    'Carroll',
    'Carter',
    'Cartwright',
    'Casper',
    'Cassin',
    'Champlin',
    'Christiansen',
    'Cole',
    'Collier',
    'Collins',
    'Conn',
    'Connelly',
    'Conroy',
    'Considine',
    'Corkery',
    'Cormier',
    'Corwin',
    'Cremin',
    'Crist',
    'Crona',
    'Cronin',
    'Crooks',
    'Cruickshank',
    'Cummerata',
    'Cummings',
    'Dach',
    "D'Amore",
    'Daniel',
    'Dare',
    'Daugherty',
    'Davis',
    'Deckow',
    'Denesik',
    'Dibbert',
    'Dickens',
    'Dicki',
    'Dickinson',
    'Dietrich',
    'Donnelly',
    'Dooley',
    'Douglas',
    'Doyle',
    'DuBuque',
    'Durgan',
    'Ebert',
    'Effertz',
    'Eichmann',
    'Emard',
    'Emmerich',
    'Erdman',
    'Ernser',
    'Fadel',
    'Fahey',
    'Farrell',
    'Fay',
    'Feeney',
    'Feest',
    'Feil',
    'Ferry',
    'Fisher',
    'Flatley',
    'Frami',
    'Franecki',
    'Friesen',
    'Fritsch',
    'Funk',
    'Gaylord',
    'Gerhold',
    'Gerlach',
    'Gibson',
    'Gislason',
    'Gleason',
    'Gleichner',
    'Glover',
    'Goldner',
    'Goodwin',
    'Gorczany',
    'Gottlieb',
    'Goyette',
    'Grady',
    'Graham',
    'Grant',
    'Green',
    'Greenfelder',
    'Greenholt',
    'Grimes',
    'Gulgowski',
    'Gusikowski',
    'Gutkowski',
    'Gutmann',
    'Haag',
    'Hackett',
    'Hagenes',
    'Hahn',
    'Haley',
    'Halvorson',
    'Hamill',
    'Hammes',
    'Hand',
    'Hane',
    'Hansen',
    'Harber',
    'Harris',
    'Hartmann',
    'Harvey',
    'Hauck',
    'Hayes',
    'Heaney',
    'Heathcote',
    'Hegmann',
    'Heidenreich',
    'Heller',
    'Herman',
    'Hermann',
    'Hermiston',
    'Herzog',
    'Hessel',
    'Hettinger',
    'Hickle',
    'Hilll',
    'Hills',
    'Hilpert',
    'Hintz',
    'Hirthe',
    'Hodkiewicz',
    'Hoeger',
    'Homenick',
    'Hoppe',
    'Howe',
    'Howell',
    'Hudson',
    'Huel',
    'Huels',
    'Hyatt',
    'Jacobi',
    'Jacobs',
    'Jacobson',
    'Jakubowski',
    'Jaskolski',
    'Jast',
    'Jenkins',
    'Jerde',
    'Jewess',
    'Johns',
    'Johnson',
    'Johnston',
    'Jones',
    'Kassulke',
    'Kautzer',
    'Keebler',
    'Keeling',
    'Kemmer',
    'Kerluke',
    'Kertzmann',
    'Kessler',
    'Kiehn',
    'Kihn',
    'Kilback',
    'King',
    'Kirlin',
    'Klein',
    'Kling',
    'Klocko',
    'Koch',
    'Koelpin',
    'Koepp',
    'Kohler',
    'Konopelski',
    'Koss',
    'Kovacek',
    'Kozey',
    'Krajcik',
    'Kreiger',
    'Kris',
    'Kshlerin',
    'Kub',
    'Kuhic',
    'Kuhlman',
    'Kuhn',
    'Kulas',
    'Kunde',
    'Kunze',
    'Kuphal',
    'Kutch',
    'Kuvalis',
    'Labadie',
    'Lakin',
    'Lang',
    'Langosh',
    'Langworth',
    'Larkin',
    'Larson',
    'Leannon',
    'Lebsack',
    'Ledner',
    'Leffler',
    'Legros',
    'Lehner',
    'Lemke',
    'Lesch',
    'Leuschke',
    'Lind',
    'Lindgren',
    'Littel',
    'Little',
    'Lockman',
    'Lowe',
    'Lubowitz',
    'Lueilwitz',
    'Luettgen',
    'Lynch',
    'Macejkovic',
    'Maggio',
    'Mann',
    'Mante',
    'Marks',
    'Marquardt',
    'Marvin',
    'Mayer',
    'Mayert',
    'McClure',
    'McCullough',
    'McDermott',
    'McGlynn',
    'McKenzie',
    'McLaughlin',
    'Medhurst',
    'Mertz',
    'Metz',
    'Miller',
    'Mills',
    'Mitchell',
    'Moen',
    'Mohr',
    'Monahan',
    'Moore',
    'Morar',
    'Morissette',
    'Mosciski',
    'Mraz',
    'Mueller',
    'Muller',
    'Murazik',
    'Murphy',
    'Murray',
    'Nader',
    'Nicolas',
    'Nienow',
    'Nikolaus',
    'Nitzsche',
    'Nolan',
    'Oberbrunner',
    "O'Connell",
    "O'Conner",
    "O'Hara",
    "O'Keefe",
    "O'Kon",
    'Okuneva',
    'Olson',
    'Ondricka',
    "O'Reilly",
    'Orn',
    'Ortiz',
    'Osinski',
    'Pacocha',
    'Padberg',
    'Pagac',
    'Parisian',
    'Parker',
    'Paucek',
    'Pfannerstill',
    'Pfeffer',
    'Pollich',
    'Pouros',
    'Powlowski',
    'Predovic',
    'Price',
    'Prohaska',
    'Prosacco',
    'Purdy',
    'Quigley',
    'Quitzon',
    'Rath',
    'Ratke',
    'Rau',
    'Raynor',
    'Reichel',
    'Reichert',
    'Reilly',
    'Reinger',
    'Rempel',
    'Renner',
    'Reynolds',
    'Rice',
    'Rippin',
    'Ritchie',
    'Robel',
    'Roberts',
    'Rodriguez',
    'Rogahn',
    'Rohan',
    'Rolfson',
    'Romaguera',
    'Roob',
    'Rosenbaum',
    'Rowe',
    'Ruecker',
    'Runolfsdottir',
    'Runolfsson',
    'Runte',
    'Russel',
    'Rutherford',
    'Ryan',
    'Sanford',
    'Satterfield',
    'Sauer',
    'Sawayn',
    'Schaden',
    'Schaefer',
    'Schamberger',
    'Schiller',
    'Schimmel',
    'Schinner',
    'Schmeler',
    'Schmidt',
    'Schmitt',
    'Schneider',
    'Schoen',
    'Schowalter',
    'Schroeder',
    'Schulist',
    'Schultz',
    'Schumm',
    'Schuppe',
    'Schuster',
    'Senger',
    'Shanahan',
    'Shields',
    'Simonis',
    'Sipes',
    'Skiles',
    'Smith',
    'Smitham',
    'Spencer',
    'Spinka',
    'Sporer',
    'Stamm',
    'Stanton',
    'Stark',
    'Stehr',
    'Steuber',
    'Stiedemann',
    'Stokes',
    'Stoltenberg',
    'Stracke',
    'Streich',
    'Stroman',
    'Strosin',
    'Swaniawski',
    'Swift',
    'Terry',
    'Thiel',
    'Thompson',
    'Tillman',
    'Torp',
    'Torphy',
    'Towne',
    'Toy',
    'Trantow',
    'Tremblay',
    'Treutel',
    'Tromp',
    'Turcotte',
    'Turner',
    'Ullrich',
    'Upton',
    'Vandervort',
    'Veum',
    'Volkman',
    'Von',
    'VonRueden',
    'Waelchi',
    'Walker',
    'Walsh',
    'Walter',
    'Ward',
    'Waters',
    'Watsica',
    'Weber',
    'Wehner',
    'Weimann',
    'Weissnat',
    'Welch',
    'West',
    'White',
    'Wiegand',
    'Wilderman',
    'Wilkinson',
    'Will',
    'Williamson',
    'Willms',
    'Windler',
    'Wintheiser',
    'Wisoky',
    'Wisozk',
    'Witting',
    'Wiza',
    'Wolf',
    'Wolff',
    'Wuckert',
    'Wunsch',
    'Wyman',
    'Yost',
    'Yundt',
    'Zboncak',
    'Zemlak',
    'Ziemann',
    'Zieme',
    'Zulauf',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::PersonLastName - Person Last Name

=cut

=head1 ABSTRACT

Person Last Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::PersonLastName;

  my $plugin = Faker::Plugin::EnUs::PersonLastName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonLastName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person last name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EnUs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake person last name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::PersonLastName;

  my $plugin = Faker::Plugin::EnUs::PersonLastName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonLastName")

  # my $result = $plugin->execute;

  # "Heaney";

  # my $result = $plugin->execute;

  # "Johnston";

  # my $result = $plugin->execute;

  # "Steuber";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::PersonLastName;

  my $plugin = Faker::Plugin::EnUs::PersonLastName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonLastName")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut