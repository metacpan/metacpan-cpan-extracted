package Lingua::RU::Numeral;

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	num2cardinal
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.031';


########################
#  num2cardinal INPUT  #
########################
# SCALAR:
#~~~~~~~~
# 0.  $number -- число для обработки, e.g: 1234567890

#~~~~~~~~~~~
# HASH keys:
#~~~~~~~~~~~
# 1. 'gender' key -- род:
#	(default)	m = masculine (Мужской)
#					f = feminine  (Женский)
#					n = neuter    (Средний)

# 2. 'case' key -- падеж:          числительное: Количественное     | Порядковое
#	(default)	n = nominative    - Именительный: есть кто? что?     | какой?
#					g = genitive      - Родительный:  нет кого? чего?    | какого?
#					d = dative        - Дательный:    рад кому? чему?    | какому?
#					a = accusative    - Винительный:  вижу кого? что?    | какой?
#					i = instrumental  - Творительный: оплачу кем? чем?   | каким?
#					p = prepositional - Предложный:   думаю о ком? о чём?| о каком?

# 3. 'multi' key  -- единственное(undef|0|'singular') или множественное число (>0|'plural'). By default, 'singular'
# 4. 'object' key -- inanimate(неодушевлённый) или animate(одушевлённый) предмет. By default, 'inanimate'
# 5. 'prolog' key -- Preposition (prologue) of numeral
# 6. 'epilog' key -- Epilogue of numeral
# 7. 'alt' key
# 8. 'ucfirst' key

sub num2cardinal {
	my( $number, %cfg ) = @_;
	$number =~s/\D+//g;

	# extreme index for:
	use constant VXN => 5;	# numbers from 5 to <1000
	use constant THS => 6;	# тысячи
	use constant MMT => 7;	# миллионы | миллиарды | триллионы

	my $gender = $cfg{'gender'} || 'masculine';
	$gender = $gender=~/^\s*(m|f|n)/i ? @{{'m'=>'masculine', 'f'=>'feminine', 'n'=>'neuter'}}{lc $1} : 'masculine';

	my $case = $cfg{'case'} || 'nominative';
	$case = $case=~/^\s*([ngdaip])/i ? $1 : 'n';

	my $multi = $cfg{'multi'} || 'singular';
	$multi = $multi=~/^\s*[p1-9]/i ? 'plural' : 'singular';

	my $object = $cfg{'object'} || 'inanimate';
	$object = $object=~/^\s*[a1-9]/i ? 'animate' : 'inanimate';

	# Preposition (prologue) of numeral
	my $prolog = &_ref_prolog( \%cfg );

	# Epilogue of numeral
	my $epilog = &_ref_epilog( $case, $multi, \%cfg, \$object, \$gender );

	unless( $number ) {
		my $oy = exists( $cfg{'alt'}{0} ) ? 'у' : 'о';
		my $zero = ($case =~/^a/i && $object =~/^animate/i ) ?
			"н${oy}ля" :
			@{{'n'=>"н${oy}ль", 'g'=>"н${oy}ля", 'd'=>"н${oy}лю", 'a'=>"н${oy}ль", 'i'=>"н${oy}лём", 'p'=>"н${oy}ле"}}{ $case };

		# Add the numeral
		 my @s = ( $zero );

		# Add the prolog to numeral
		my $i = &_add_prolog( $prolog, \@s );

		# Add the epilog to numeral
		push @s, $epilog->{'root'}.$epilog->{'ends'}[0] if $epilog && exists( $epilog->{'root'} );

		$s[$i] = ucfirst $s[$i] if exists $cfg{'ucfirst'};

		return join ' ', @s;
	}

	return "$number > 999_999_999_999_999 !" if length( $number ) > 15;

	# To get cardinal form DB (БД словоформ числительных)
	my( $bsw, $plural, $Power ) = &_cardinal_form_db( $case, $multi, $object, $gender );

	my @Dcml = @{ $bsw->{'dcml'} };
	my @Cent = @{ $bsw->{'cent'} };

	my @tmEnd;	# for ends --- для окончаний 'тысяч','миллион','миллиард','триллион'
	my @words;	# for ends --- для искомой структуры слов числительных
	my @s;	# Resulting string --- Результирующая строка

	while( length $number ) {

		if( $number =~/^.$/ ) { # 0..9
			last unless $number;

			push @s, ( $multi =~/^plural/i && $number == 1 ) ?
				$plural->{1} :
				$bsw->{ $gender }{ ($case =~/^a/i && $object =~/^animate/i) ? 'animate' : 'unit'}[ $number ];

			# Add epilog to numeral
			if( $epilog && exists( $epilog->{'root'} ) ) {
				push @s, $epilog->{'root'}.$epilog->{'ends'}[ $number < 5 ? $number : VXN ];
				$epilog = {};	# epilog END
			}

			last;
		}

		my $i = int length( $number ) / 3;

		if( $i < 2 ) { # $number = 10 .. 99_999
			# Женский род, (т.к. может быть 'тысяч')
			@words = @{ $bsw->{'feminine'}{'unit'} };
			@tmEnd = @{ $bsw->{'eT'} }; # окончания для 'тысяч'
		}
		else { # Для >=100_000, 'миллион','миллиард','триллион'
			# Мужской род
			@words = @{ $bsw->{'masculine'}{'unit'} };
			@tmEnd = @{ $bsw->{'eMT'} }; # окончания
		}

		if( length( $number )%3 == 0 ) { # Сотни: 100 .. 999, 100_xxx .. 999_xxx, 100_xxx_xxx .. 999_xxx_xxx, etc.
			$number =~s/^\d//;
			push @s, $Cent[$&] if $&;
			next;
		}

		if( length( $number )%3 == 2 ) { # Десятки: 10 .. 99, 10_xxx .. 99_xxx, 10_xxx_xxx .. 99_xxx_xxx, etc.
			if( $number =~/^1/ ) { # 10... 19...
				$number =~s/^\d\d//;
				push @s, $words[$&] if $&;

				push @s, $Power->[$i].$tmEnd[0] if length $Power->[$i];
			}
			else { # 20... 99...
				$number =~s/^\d//;
				push @s, $Dcml[$&] if $&;
			}

			next;
		}

		if( length( $number )%3 == 1 ) { # Единицы: 0..., 1,..., 9...
			$number =~s/^\d//;
			my $d = $&;
			if( $d ) {
				push @s, ( $multi =~/^plural/i && $d == 1 ) ? $plural->{1} : $words[$d];
			}

			if( $s[-1] !~/^(?:м|трил)/ ) { # ещё не добавлено миллион | миллиард | триллион
				my $w = ( $multi =~/^plural/i && $d == 1 ) ?
								$plural->{ $i < 2 ? 'eT' : 'eMT'} :
								$tmEnd[ $d ];

				push @s, $Power->[$i].$w;
			}

			last if $number =~/^0+$/;
		}
	}

	# Add prolog to numeral
	my $i = &_add_prolog( $prolog, \@s );

	$s[$i] = ucfirst $s[$i] if exists $cfg{'ucfirst'};

	# Add epilog to numeral
	if( $epilog && exists( $epilog->{'root'} ) ) {

		# Choice between
		my $i = $s[-1] =~/^ты/ ? THS :	# тысяча
				$s[-1] =~/^(?:м|трил)/ ? MMT :	# миллион | миллиард | триллион
				VXN;	# other

		push @s, $epilog->{'root'}.$epilog->{'ends'}[ $i ];
	}


	return join ' ', @s;
}


sub _cardinal_form_db {
	my( $case, $multi, $object, $gender ) = @_;

	# База словоформ числительных (singular -- единственно число, default)
	my %bsw = (
		'n' => { # nominative (Именительный падеж) кто? что?, default
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','один','два','три','четыре','пять','шесть','семь','восемь','девять','десять',
'одиннадцать','двенадцать','тринадцать','четырнадцать','пятнадцать','шестнадцать','семнадцать','восемнадцать','девятнадцать'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одна','две' # остальные как для Мужского рода
				],
			},
			'neuter' => { # Средний род
				'unit' => [ # 0..19
					'','одно' # остальные как для Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90
				'','','двадцать','тридцать','сорок','пятьдесят','шестьдесят','семьдесят','восемьдесят','девяносто'
			],
			'cent' => [ # 100..900
				'','сто','двести','триста','четыреста','пятьсот','шестьсот','семьсот','восемьсот','девятьсот'
			],
			'eT' => [ # окончания для 'тысяч' (0й - для 10..19; десятков: 10,20,...,90 и сотен: 100,200,...,900)
				'','а', ('и') x 3, ('') x 5
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион' (0й - для 10..19; десятков: 10,20,...,90 и сотен: 100,200,...,900)
				'ов','', ('а') x 3, ('ов') x 5
			],
		}, #--------------------------------------------
		'g' => { # genitive (Родительный падеж): кого? чего?
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','одного','двух','трёх','четырёх','пяти','шести','семи','восьми','девяти','десяти',
'одиннадцати','двенадцати','тринадцати','четырнадцати','пятнадцати','шестнадцати','семнадцати','восемнадцати','девятнадцати'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одной' # остальные как для Мужского рода
				],
			},
			'neuter' => { # Средний род
				'unit' => [ # 0..19
					'' # всё как для Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90
				'','','двадцати','тридцати','сорока','пятидесяти','шестидесяти','семидесяти','восьмидесяти','девяноста'
			],
			'cent' => [ # 100..900
				'','ста','двухсот','трёхсот','четырёхсот','пятисот','шестисот','семисот','восьмисот','девятисот'
			],
			'eT' => [ # окончания для 'тысяч'
				'','и', ('') x 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ов','а', ('ов') x 8
			],
		}, #--------------------------------------------
		'd' => { # dative (Дательный падеж): кому? чему?
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','одному','двум','трём','четырём','пяти','шести','семи','восьми','девяти','десяти',
'одиннадцати','двенадцати','тринадцати','четырнадцати','пятнадцати','шестнадцати','семнадцати','восемнадцати','девятнадцати'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одной' # остальные как для Мужского рода
				],
			},
			'neuter' => { # Средний род
				'unit' => [ # 0..19
					'' # всё как для Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90 : как Родительный падеж
				'','','двадцати','тридцати','сорока','пятидесяти','шестидесяти','семидесяти','восьмидесяти','девяноста'
			],
			'cent' => [ # 100..900
				'','ста','двумстам','трёхстам','четырёхстам','пятистам','шестистам','семистам','восьмистам','девятистам'
			],
			'eT' => [ # окончания для 'тысяч'
				'ам','е', ('ам') x 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ам','у', ('ам') x 8
			],
		}, #--------------------------------------------
		'a' => { # accusative (Винительный падеж): animate (одушевлённый объект): кого? | inanimate (неодушевлённый объект): что?
			'masculine' => { # Мужской род, inanimate default
				'unit' => [ # 0..19 : неодушевлённый объект, как Именительный падеж
					'','один','два','три','четыре','пять','шесть','семь','восемь','девять','десять',
'одиннадцать','двенадцать','тринадцать','четырнадцать','пятнадцать','шестнадцать','семнадцать','восемнадцать','девятнадцать'
				],
				'animate' => [ # 0..19 : одушевлённый объект, как Родительный падеж (0..4), Именительный падеж (5..19)
					'','одного','двух','трёх','четырёх',  'пять','шесть','семь','восемь','девять','десять',
'одиннадцать','двенадцать','тринадцать','четырнадцать','пятнадцать','шестнадцать','семнадцать','восемнадцать','девятнадцать'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19 : неодушевлённый объект
					'','одну','две' # остальные как для Мужского рода
				],
				'animate' => [ # 0..19 : одушевлённый объект
					'','одну' # остальные как для одушевлённого Мужского рода
				],
			},
			'neuter' => { # Средний род
				'unit' => [ # 0..19 : неодушевлённый объект
					'','одно' # остальные как для Мужского рода
				],
				'animate' => [ # 0..19 : одушевлённый объект
					'','одно','два' # остальные как для одушевлённого Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90
				'','','двадцать','тридцать','сорок','пятьдесят','шестьдесят','семьдесят','восемьдесят','девяносто'
			],
			'cent' => [ # 100..900
				'','сто','двести','триста','четыреста','пятьсот','шестьсот','семьсот','восемьсот','девятьсот'
			],
			'eT' => [ # окончания для 'тысяч' (0й - для 10..19 и десятков: 10,20,...,90)
				'','у', ('и') x 3, ('') x 5
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион' (0й - для 10..19 и десятков: 10,20,...,90)
				'ов','', ('а') x 3, ('ов') x 5
			],
		}, #--------------------------------------------
		'i' => { # instrumental (Творительный падеж) : кем? чем?
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','одним','двумя','тремя','четырьмя','пятью','шестью','семью','восьмью','девятью','десятью',
'одиннадцатью','двенадцатью','тринадцатью','четырнадцатью','пятнадцатью','шестнадцатью','семнадцатью','восемнадцатью','девятнадцатью'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одной' # остальные как для Мужского рода
				],
				'alternative' => [ # 0..19
					'','одною' # остальные как для Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90
				'','','двадцатью','тридцатью','сорока','пятьюдесятью','шестьюдесятью','семьюдесятью','восьмьюдесятью','девяноста'
			],
			'cent' => [ # 100..900
				'','ста','двумястами','тремястами','четырьмястами','пятьюстами','шестьюстами','семьюстами','восьмьюстами','девятьюстами'
			],
			'eT' => [ # окончания для 'тысяч'
				'ами','ей', ('ами') x 8
#				'ами','ью', ('ами') x 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ами','ом', ('ами') x 8
			],
		}, #--------------------------------------------
		'p' => { # prepositional (Предложный падеж) : о ком? о чём?
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','одном','двух','трёх','четырёх','пяти','шести','семи','восьми','девяти','десяти',
'одиннадцати','двенадцати','тринадцати','четырнадцати','пятнадцати','шестнадцати','семнадцати','восемнадцати','девятнадцати'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одной' # остальные как для Мужского рода
				],
			},
			'dcml' => [ # 20, 30,...,90
				'','','двадцати','тридцати','сорока','пятидесяти','шестидесяти','семидесяти','восьмидесяти','девяноста'
			],
			'cent' => [ # 100..900
				'','ста','двухстах','трёхстах','четырёхстах','пятистах','шестистах','семистах','восьмистах','девятистах'
			],
			'eT' => [ # окончания для 'тысяч'
				'ах','е', ('ах') x 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ах','е', ('ах') x 8
			],
		},
	);

	my %plural = ( # множественное число
		'n' => { # nominative (Именительный падеж)
			1 => 'одни',
			'eT'  => 'и', # окончание для 'тысяч'
			'eMT' => 'ы', # окончания для 'миллион','миллиард','триллион'
		},
		'g' => { # genitive (Родительный падеж)
			1 => 'одних',
			'eT'  => '',
			'eMT' => 'ов',
		},
		'd' => { # dative (Дательный падеж)
			1 => 'одним',
			'eT'  => 'ам',
			'eMT' => 'ам',
		},
		'a' => { # accusative (Винительный падеж):
			1 => 'одни', # inanimate(неодушевлённый) объект. For animate(одушевлённый) -- see below
			'eT'  => 'и',
			'eMT' => 'ы',
		},
		'i' => {# instrumental (Творительный падеж)
			1 => 'одними',
			'eT'  => 'ами',
			'eMT' => 'ами',
		},
		'p' => { # prepositional (Предложный падеж)
			1 => 'одних',
			'eT'  => 'ах',
			'eMT' => 'ах',
		},
	);

	# Дозаполняем необходимые структуры, кроме 'masculine'
	my %gg = ('masculine' => undef );
	for my $g ('feminine', $gender ) {
		next if exists $gg{ $g };
		$gg{ $g } = undef;

		for(0..19) {
			# если НЕ определено
			$bsw{ $case }{ $g }{'unit'}[$_] //= $bsw{ $case }{'masculine'}{'unit'}[$_];

			$bsw{'a'}{ $g }{'animate'}[$_] //= $bsw{'a'}{'masculine'}{'animate'}[$_]
				if $case =~/^a/i && $object =~/^animate/i;
		}
	}

	# Корректируем окончания для accusative(Винительный падеж) + одушевлённый объект + множественное число
	if( $case =~/^a/i && $object =~/^animate/i && $multi =~/^plural/i ) {
		$plural{'a'}{1} = 'одних';
		$plural{'a'}{'eT'} = '';
		$plural{'a'}{'eMT'} = 'ов';
	}

	return( \%{ $bsw{ $case } }, \%{ $plural{ $case } }, ['','тысяч','миллион','миллиард','триллион'] );
}


# Add prolog to numeral, e.g. ['с','со=с',...]
sub _add_prolog {
	my( $prolog, $s ) = @_;
	return 0 if ! @$prolog or ! @$s or (~~@$prolog < 2 and ( ! defined( $prolog->[0] ) or ! length( $prolog->[0] ) ) );

	my $p = shift @$prolog;	# get 1st element (e.g. 'с') for any numeral

	my $i = 0;
	for( @$prolog ) {	# ['со=с',...]
		next unless $_;

		my( $k, $m ) = split '=';
		next unless $k && $m;

		if( $s->[0] =~/^$m/ ) {
			unshift @$s, $k;
			undef $p;
			$i = 1;
			last;
		}
	}

	if( defined( $p ) && length $p ) {
		unshift @$s, $p;
		$i = 1;
	}

	return $i;
}


sub _ref_prolog {
	my( $cfg ) = @_;
	my $prolog = $cfg->{'prolog'} // return [ ];

	if( ref($prolog) eq 'ARRAY') {
		return ~~@$prolog ? [ @$prolog ] : [ ];
	}

	if( ref($prolog) eq 'HASH') {
		my @p;
		for my $k (sort keys %$prolog ) {
			if( defined( $prolog->{$k} ) && length( $prolog->{$k} ) ) {
				push @p, "$k=". $prolog->{$k};
			}
			else {
				unshift @p, $k;
			}
		}
		return ~~@p ? \@p : [ ];
	}

	if( ref(\$prolog) eq 'SCALAR') {
		return ['о','об=од'] if $prolog =~/^[oOоО]$/;
		return ['с','со=с'] if $prolog =~/^[cCсС]$/;
		return ['в'] if $prolog =~/^[BвВ]$/;
	}

	return [ ];
}


sub _ref_epilog {
	my( $case, $multi, $cfg, $object, $gender ) = @_;
	my $epilog = $cfg->{'epilog'} or return {};

	if( ref(\$epilog) eq 'SCALAR') {
		my %eRef;

		if( $epilog =~/^(?:RUB|643)$/ ) { # Российский рубль
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'рубл',
					'ends' => {
							'n' => ['ей','ь', ('я') x 3, ('ей') x 3 ],	# nominative - Именительный
							'g' => ['ей','я', ('ей') x 6 ],	# genitive - Родительный
							'd' => ['ям','ю', ('ям') x 4, ('ей') x 2 ],	# dative - Дательный
							'a' => ['ей','ь', ('я') x 3, ('ей') x 3 ],	# accusative - Винительный
							'i' => ['ей','ём', ('ями') x 4, ('ей') x 2 ],	# instrumental - Творительный
							'p' => ['ей','е', ('ях') x 4, ('ей') x 2 ],	# prepositional - Предложный
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}
		elsif( $epilog =~/^(?:rub|\-643)$/) { # Российская копейка
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'копе',
					'ends' => {
							'n' => ['ек','йка', ('йки') x 3, ('ек') x 3 ],
							'g' => ['ек','йки', ('ек') x 6 ],
							'd' => ['ек','йке', ('йкам') x 4, ('ек') x 2 ],
							'a' => ['ек','йку', ('йки') x 3, ('ек') x 3 ],
							'i' => ['ек','йкой', ('йками') x 4, ('ек') x 2 ],
							'p' => ['ек','йке', ('йках') x 4, ('ек') x 2 ],
					},
					'plural' => {'n'=>'йки', 'g'=>'ек', 'd'=>'йкам', 'a'=>'йки', 'i'=>'йками', 'p'=>'йках'},
				);

		}
		elsif( $epilog =~/^(?:USD|840)$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'доллар',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'g' => ['ов','а', ('ов') x 6 ],
							'd' => ['ам','у', ('ам') x 4, ('ов') x 2 ],
							'a' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'i' => ['ов','ом', ('ами') x 4, ('ов') x 2 ],
							'p' => ['ах','е', ('ах') x 6 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:usd|\-840)$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'цент',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'g' => ['ов','а', ('ов') x 6 ],
							'd' => ['ам','у', ('ам') x 6 ],
							'a' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'i' => ['ами','ом', ('ами') x 6 ],
							'p' => ['ах','е', ('ах') x 6 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:CNY|156)$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'юан',
					'ends' => {
							'n' => ['ей','ь', ('я') x 3, ('ей') x 3 ],
							'g' => ['ей','я', ('ей') x 6 ],
							'd' => ['ям','ю', ('ям') x 6 ],
							'a' => ['ей','ь', ('я') x 3, ('ей') x 3 ],
							'i' => ['ей','ем', ('ями') x 4, ('ей') x 2 ],
							'p' => ['ях','е', ('ях') x 4, ('ей') x 2 ],
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}
#		elsif( $epilog =~/^(?:cny|-156)$/) {
#			%eRef = ('root'=>'фын', 'ends'=>['ей','ь', ('я') x 3, ('ей') x 5 ] );
#		}
		elsif( $epilog =~/^year$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => '',
					'ends' => {
							'n' => ['лет','год', ('года') x 3, ('лет') x 3 ],
							'g' => ['лет','года', ('лет') x 6 ],
							'd' => ['лет','году', ('годам') x 4, ('лет') x 2 ],
							'a' => ['лет','год', ('года') x 3, ('лет') x 3 ],
							'i' => ['лет','годом', ('годами') x 4, ('лет') x 2 ],
							'p' => ['лет','годе', ('годах') x 4, ('лет') x 2 ],
					},
					'plural' => {'n'=>'годы', 'g'=>'лет', 'd'=>'годам', 'a'=>'годы', 'i'=>'годами', 'p'=>'годах'},
				);

		}
		elsif( $epilog =~/^month$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'месяц',
					'ends' => {
							'n' => ['ев','', ('а') x 3, ('ев') x 3 ],
							'g' => ['ев','а', ('ев') x 6 ],
							'd' => ['ам','у', ('ам') x 6 ],
							'a' => ['ев','', ('а') x 3, ('ев') x 3 ],
							'i' => ['ев','ем', ('ами') x 4, ('ев') x 2 ],
							'p' => ['ев','е', ('ах') x 4, ('ев') x 2 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ев', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^day$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'д',
					'ends' => {
							'n' => ['ней','ень', ('ня') x 3, ('ней') x 3 ],
							'g' => ['ней','ня', ('ней') x 6 ],
							'd' => ['ням','ню', ('ням') x 6 ],
							'a' => ['ней','ень', ('ня') x 3, ('ней') x 3 ],
							'i' => ['ней','нём', ('нями') x 4, ('ней') x 2 ],
							'p' => ['ней','не', ('нях') x 4, ('ней') x 2 ],
					},
					'plural' => {'n'=>'ни', 'g'=>'ней', 'd'=>'ням', 'a'=>'ни', 'i'=>'нями', 'p'=>'нях'},
				);

		}
		elsif( $epilog =~/^hour$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'час',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'g' => ['ов','а', ('ов') x 6 ],
							'd' => ['ам','у', ('ам') x 6 ],
							'a' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'i' => ['ов','ом', ('ами') x 4, ('ов') x 2 ],
							'p' => ['ов','е', ('ах') x 4, ('ов') x 2 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^min\.$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'минут',
					'ends' => {
							'n' => ['','а', ('ы') x 3, ('') x 3 ],
							'g' => ['','ы', ('') x 6 ],
							'd' => ['','е', ('ам') x 4, ('') x 2 ],
							'a' => ['','у', ('ы') x 3, ('') x 3 ],
							'i' => ['','ой', ('ами') x 4, ('') x 2 ],
							'p' => ['','е', ('ах') x 4, ('') x 2 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^sec\.$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'секунд',
					'ends' => {
							'n' => ['','а', ('ы') x 3, ('') x 3 ],
							'g' => ['','ы', ('') x 6 ],
							'd' => ['','е', ('ам') x 4, ('') x 2 ],
							'a' => ['','у', ('ы') x 3, ('') x 3 ],
							'i' => ['','ой', ('ами') x 4, ('') x 2 ],
							'p' => ['','е', ('ах') x 4, ('') x 2 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^meter$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'метр',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'g' => ['ов','а', ('ов') x 6 ],
							'd' => ['ов','у', ('ам') x 4, ('ов') x 2 ],
							'a' => ['ов','', ('а') x 3, ('ов') x 3 ],
							'i' => ['ов','ом', ('ами') x 4, ('ов') x 2 ],
							'p' => ['ов','е', ('ах') x 4, ('ов') x 2 ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^stamp$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'печат',
					'ends' => {
							'n' => ['ей','ь', ('и') x 3, ('ей') x 3 ],
							'g' => ['ей','и', ('ей') x 6 ],
							'd' => ['ей','и', ('ям') x 4, ('ей') x 2 ],
							'a' => ['ей','ь', ('и') x 3, ('ей') x 3 ],
							'i' => ['ей','ью', ('ями') x 4, ('ей') x 2 ],
							'p' => ['ей','и', ('ях') x 4, ('ей') x 2 ],
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}

		if( %eRef ) {
			$$object = $eRef{'object'};
			$$gender = $eRef{'gender'};

			# To fix for plural '1' only 
			$eRef{'ends'}{ $case }[1] = $eRef{'plural'}{ $case } if $multi =~/^plural/i;

			$epilog = {};
			$epilog->{'root'} = $eRef{'root'};
			$epilog->{'ends'} = $eRef{'ends'}{ $case };
		}
		else {
			$epilog = {};
		}

	}
	elsif( ref($epilog) eq 'HASH' && exists( $epilog->{'root'} ) && exists( $epilog->{'ends'} ) ) {
		if( exists $epilog->{'object'} ) {
			$$object = $epilog->{'object'}=~/^\s*[a1-9]/i ? 'animate' : 'inanimate';
		}

		$$gender = @{{'m'=>'masculine', 'f'=>'feminine', 'n'=>'neuter'}}{lc $1}
			if exists( $epilog->{'gender'} ) && $epilog->{'gender'} =~/^\s*(m|f|n)/i;
	}
	else {
		$epilog = {};
	}

	return $epilog;
}

1;

__END__

=head1 NAME

Lingua::RU::Numeral - Perl extension for generate Russian wording of numerals from the natural numbers and 0 (zero).

=encoding utf8

=head1 SYNOPSIS

Activate the module:

  use Lingua::RU::Numeral qw( num2cardinal );

Usage examples:

=over 3

=item 1.

Using with default options, i.e. C<'nominative'> case (I<Именительный падеж>),
C<'masculine'> gender (I<Мужской род>), numeral in C<'singular'> (I<единственное число>),
C<'inanimate'> object (I<неодушевлённый предмет>):

  say num2cardinal('930651342187216');

Will print the result:

  девятьсот тридцать триллионов шестьсот пятьдесят один миллиард триста сорок два миллиона сто восемьдесят семь тысяч двести шестнадцать

=item 2.

Using C<'feminine'> gender (I<Женский род>), and with other default options:

  say num2cardinal('101101102101101', 'gender'=>'feminine');

Will print the result:

  сто один триллион сто один миллиард сто два миллиона сто одна тысяча сто одна

=item 3.

Using C<'neuter'> gender (I<Средний род>), and with other default options:

  say num2cardinal('101101102101101', 'gender'=>'neuter');

Will print the result:

  сто один триллион сто один миллиард сто два миллиона сто одна тысяча сто одно

=item 4.

Using C<'genitive'> case (I<Родительный падеж>), and with other default options:

  say num2cardinal( 1000003, 'case'=>'genitive');

or abbreviated form

  say num2cardinal( 1000003, 'case'=>'g');

Will print the result:

  одного миллиона трёх


=item 5.

Using C<'accusative'> case (I<Винительный падеж>), C<'feminine'> gender (I<Женский род>, abbreviated form),
C<'animate'> object (I<одушевлённый предмет>), and with other default option, i.e. C<'singular'> (I<единственное число>):

  say num2cardinal( 2, 'case'=>'accusative', 'gender'=>'f', 'object'=>'animate');

Will print the result:

  двух


=item 6.

Using C<'accusative'> case (I<Винительный падеж>, abbreviated form), C<'plural'> (I<множественное число>),
C<'inanimate'> object (I<неодушевлённый предмет>, by default), and with other default options:

  say num2cardinal( 1000, 'case'=>'a', 'multi'=>'plural');

Will print the result:

  одни тысячи


=item 7.

Using C<'accusative'> case (I<Винительный падеж>, abbreviated form), C<'plural'> (I<множественное число>, abbreviated form),
C<'animate'> object (I<одушевлённый предмет>), and with other default options:

  say num2cardinal( 1000, 'case'=>'a', 'multi'=>'p', 'object'=>'animate');

Will print the result:

  одних тысяч


=item 8.

Using reference C<'epilog'> with other default options:

  say num2cardinal( 1000, 'epilog'=>'RUB');	# add Российский 'рубль', using an alphabetic currency code
  say num2cardinal( 1000, 'epilog'=> 643 );	# the same, using a digital currency code
  say num2cardinal( 2000, 'epilog'=>'rub');	# add Российская 'копейка'
  say num2cardinal( 2000, 'epilog'=> -643);	# the same

Will print the results:

  одна тысяча рублей
  одна тысяча рублей
  две тысячи копеек
  две тысячи копеек


=item 9.

Using C<'prolog'> and C<'epilog'> with other explicit and implicit options:

  say num2cardinal( 11,
                   'case'   => 'p',	# Предложный: о ком? о чём?
                   'prolog' => 'о',
                   'epilog' => 'stamp',
                  );

OR the same with details:

  my $epilog = {
               'object' => 'inanimate',
               'gender' => 'feminine',
               'root'   => 'печат',
               'ends'   => ['ях','и', ('ях') x 8 ],
              };

  say num2cardinal( 11,
                   'case'   => 'prepositional',	# Предложный: о ком? о чём?
                   'prolog' => ['о','об=од'],
                   'epilog' => $epilog,
                  );

Will print the result:

  об одиннадцати печатях


=item 10.

Using C<'alt'> (alternate form) with other default options:

  say num2cardinal( 0 );
  say num2cardinal( 0, alt => { 0=>'TRUE'} );

Will print the results:

  ноль
  нуль


=item 11.

Using C<'ucfirst'> with other explicit and implicit options:

  say num2cardinal( 11, 'ucfirst' => 'TRUE');
  say num2cardinal( 11, case => 'p', prolog => 'о' );
  say num2cardinal( 11, case => 'p', prolog => 'о', 'ucfirst' => 1 );
  say num2cardinal( 11, case => 'p', prolog => 'о', epilog => 'RUB', 'ucfirst' => 1 );

Will print the results:

  Одиннадцать
  об одиннадцати
  об Одиннадцати
  об Одиннадцати рублях


=back

=head1 LIMITATIONS

C<num2cardinal()> subroutine generates Russian cardinal numbers for the natural numbers and 0 (zero), i.e.
from 0 to 999_999_999_999_999, e.g.:

  say num2cardinal( 0 );
  say num2cardinal( 0, 'case' => 'instrumental');
  say num2cardinal('999999999999999');
  say num2cardinal('1000000000000000');

Will print the results:

  ноль
  нолём
  девятьсот девяносто девять триллионов девятьсот девяносто девять миллиардов девятьсот девяносто девять миллионов девятьсот девяносто девять тысяч девятьсот девяносто девять
  1000000000000000 > 999_999_999_999_999 !

The target Cyrillic character set (returns) is B<UTF-8> (C<use utf8>).

This module have reason only for perl 5.10 and higher.


=head1 ABSTRACT

This module provides function that can be used to generate Russian verbiage for the natural numbers (unsigned integer) and 0 (zero).
The methods implemented in this module, are all focused on knowledge of Russian grammar.


=head1 DESCRIPTION

This module provides function that can be used to generate Russian verbiage for the natural numbers (unsigned integer) and 0 (zero).
The methods implemented in this module, are all focused on knowledge of Russian grammar.

This module makes verbiage in "short scales" (1,000,000,000 is "один миллиард" rather than "одна тысяча миллионов").
For details see this Wikipedia russian article:

L<https://ru.wikipedia.org/wiki/Системы_наименования_чисел>


=head1 SUBROUTINES

Lingua::RU::Numeral provides this subroutine:

    num2cardinal( $number [, %facultative_options ] );


=head2 num2cardinal( $number [, %facultative_options ] )

Convert a C<$number> (natural numbers or 0) to Russian text (string), using explicitly specified C<%facultative_options>,
otherwise - default options. The following can be  C<%facultative_options>:

=over 3

=item * C<'case'> option — case of a numeral can take the following meanings (case names can be abbreviated to one first letter):

=over 6

=item 1.
C<'n'|'nominative'> (I<Именительный падеж: есть кто? что?> is B<default>),

=item 2.
C<'g'|'genitive'> (I<Родительный падеж: нет кого? чего?>),

=item 3.
C<'d'|'dative'> (I<Дательный падеж: рад кому? чему?>),

=item 4.
C<'a'|'accusative'> (I<Винительный падеж: вижу кого? что?>),

=item 5.
C<'i'|'instrumental'> (I<Творительный падеж: оплачу кем? чем?>),

=item 6.
C<'p'|'prepositional'> (I<Предложный падеж: думаю о ком? о чём?>).

=back

=item * C<'gender'> option — C<'m'|'masculine'> (I<Мужской род>, B<by default>) or C<'f'|'feminine'> (I<Женский род>)
or C<'n'|'neuter'> (I<Средний род>). Gender names can be abbreviated to one first letter also.

=item * C<'multi'> option — word(s) in the plural (C<'1'|'plural'>, I<множественное число>) or C<'undef'|'0'|'singular'> (I<единственное число>, B<by default>).

=item * C<'object'> option — C<'inanimate'> (I<неодушевлённый предмет>, B<by default>) or C<'animate'> (I<одушевлённый предмет>) object.
Object names can be abbreviated to one first letter also.

=item * C<'prolog'> option — PREPosition(s) of the numeral is the REF to ARRAY,
where 0th element ('PREP_0') — the preposition for all numerals, except for those indicated by 
subsequent array elements ('PREP_x') as C<['PREP_0','PREP_1=REGEX',...]>.

Here REGEX — the regular expression that is used to find a match at the beginning of a numeric string like:
C<numeral =~/^REGEX/>.
For example:

  'prolog' => ['о','об=од']

If C<'prolog'> is SCALAR value (e.g. C<< 'prolog'=>'о' >>) then it is used from internal B<reference list of prologs>.
Now internal B<reference list of prologs> contains the following preconfigured phrase structures:

=over 6

=item * C<'o'> — equivalent to C<['о','об=од']>

=item * C<'c'> — equivalent to C<['с','со=с']>

=item * C<'в'> — equivalent to C<['в']>

=back

=item * C<'epilog'> option — final word (phrase) of the numeral is SCALAR value (name) from internal B<reference list of epilogs>
or the REF to HASH to create a B<custom> phrase.

Internal B<reference list of epilogs> contains the following preconfigured phrase structures:

=over 6

=item * C<'RUB'|643> — for Russian ruble (I<Российский рубль>);
C<'rub'|-643> — for Russian kopek (I<Российская копейка>).

=item * C<'CNY'|156> — Chinese yuan.

=item * C<'USD'|840> — for United States dollar;
C<'usd'|-840> — for US cent.

=item * Time measures:  C<'year'> — for I<год>, I<лет>;
C<'month'> — I<месяц>;
C<'day'> — I<день>;
C<'hour'> — I<час>;
C<'min.'> — minute (I<минута>);
C<'sec.'> — second (I<секунда>).

=item * C<'meter'> — I<метр>.

=item * C<'stamp'> — I<печать>.

=back

The B<custom C<'epilog'> > presents the REF to HASH with complex structure of SCALAR values and ARRAY.
For example, I<год>, I<лет> (abbreviation equivalent is C<$epilog = 'year'> for C<'nominative'> case (Именительного падежа):

  my $epilog = {
               'object' => 'inanimate', # неодушевлённый предмет
               'gender' => 'masculine', # Мужской род
               'root'   => '',
               'ends'   => ['лет','год', ('года') x 3, ('лет') x 3 ],
              };

or for I<секунда> (abbreviation equivalent is C<$epilog = 'sec.'> for C<'accusative'> case (Винительного падежа)):

  my $epilog = {
               'object' => 'inanimate',
               'gender' => 'feminine', # Женский род
               'root'   => 'секунд',
               'ends'   => ['','у', ('ы') x 3, ('') x 3 ],
              };

or for I<рубль> (abbreviation equivalent is C<$epilog = 'RUB'> for C<'genitive'> case (Родительного падежа)):

  my $epilog = {
               'object' => 'inanimate',
               'gender' => 'masculine', # Мужской род
               'root'   => 'рубл',
               'ends'   => ['ям','ю', ('ям') x 4, ('ей') x 2 ],
              };

Here are:

=over 6

=item * already known C<'object'> and C<'gender'> options. These options are recommended but not required.
B<WARNING!> These options take precedence over the global options(C<'object'>, C<'gender'>), i.e. override them.

=item * C<'root'> option means the C<'epilog'> root, i.e. common invariable part of the custom C<'epilog'> words
(or its absence in the form of "").

=item * C<'ends'> option means the C<'epilog'> word endings for numerals: 0, 1, 2, 3, 4, 5,
1000 (thousand), 1_000_000 (million) respectively.

=back


=item * C<'alt'> option — REF to HASH of alternative word forms.
Currently available for zero only (I<ноль>, by default; C<< 'alt' => {0=>1} >>, to obtain I<нуль>).

=item * C<'ucfirst'> option — Returns the numeral with the first character capitalized (upper case).
B<WARNING!> does not affect the C<'prolog'>.

=back


=head1 EXPORT

Lingua::RU::Numeral exports nothing by default.
Each of the subroutines can be exported on demand, as in

  use Lingua::RU::Numeral qw( num2cardinal );

and the tag C<all> exports them all:

  use Lingua::RU::Numeral qw( :all );


=head1 DEPENDENCIES

Lingua::RU::Numeral is known to run under perl 5.10.0 on Linux.


=head1 SEE ALSO

Igor' A. Mel'čuk. THE SURFACE SYNTAX OF RUSSIAN NUMERAL EXPRESSIONS. -Wien: Volume 16 of Wiener slawistischer Almanach,
Institut für Slavistik der Universität, -1985. — 514 p. ISSN 0258-6819.

Мельчук, И.А. Поверхностный синтаксис русских числовых выражений. -Wien: Volume 16 of Wiener slawistischer Almanach,
Institut für Slavistik der Universität, -1985. — 514 c. ISSN 0258-6819.

L<Lingua::RU::Number> is a Perl module that offers some similar functionality.

=head1 AUTHOR

Alessandro N. Gorohovski, E<lt>an.gorohovski@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2023 by Alessandro N. Gorohovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
