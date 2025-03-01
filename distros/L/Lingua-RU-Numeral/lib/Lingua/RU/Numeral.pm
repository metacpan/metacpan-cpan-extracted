package Lingua::RU::Numeral;

use 5.010;
use strict;
use warnings;
use utf8;
# use open qw(:std :utf8);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	num2cardinal
	case_endings
	spelled_out_number
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.071';

########################
#  num2cardinal INPUT  #
########################
# SCALAR:
#~~~~~~~~
# 0.  $number -- число для обработки, e.g: 1234567890

#~~~~~~~~~~~
# HASH keys:
#~~~~~~~~~~~
# 1. 'case' key -- падеж:          числительное: Количественное     | Порядковое
#	(default)	n = nominative    - Именительный: есть кто? что?     | какой?
#					g = genitive      - Родительный:  нет кого? чего?    | какого?
#					d = dative        - Дательный:    рад кому? чему?    | какому?
#					a = accusative    - Винительный:  вижу кого? что?    | какой?
#					i = instrumental  - Творительный: оплачу кем? чем?   | каким?
#					p = prepositional - Предложный:   думаю о ком? о чём?| о каком?

# 2. 'gender' key -- род:
#	(default)	m = masculine (Мужской)
#					f = feminine  (Женский)
#					n = neuter    (Средний)

# 3. 'multi' key  -- единственное(undef|0|'singular') или множественное число (>0|'plural'). By default, 'singular'
# 4. 'object' key -- inanimate(неодушевлённый) или animate(одушевлённый) предмет. By default, 'inanimate'
# 5. 'prolog' key -- Preposition (prologue) of numeral
# 6. 'epilog' key -- Epilogue of numeral
# 7. 'alt' key
# 8. 'ucfirst' key

sub case_endings {
	$! = 22, return unless defined wantarray;
	my( $number, %cfg ) = @_;
	return unless defined $number;

	my( $i, $ns, @s ) = &num2cardinal( $number, %cfg );

	splice @s, $i, $ns - $i + 1, $number;

	return join(' ', @s);
}


sub spelled_out_number {
	$! = 22, return unless defined wantarray;
	my( $number, %cfg ) = @_;
	return unless defined $number;

	my( $i, $ns, @s ) = &num2cardinal( $number, %cfg );

	$s[$i] = '('.$s[$i];
	$s[$ns] = $s[$ns].')';
	splice @s, $i, 0, $number;

	return join(' ', @s);
}


sub _num_check {
	for( $_[0] ) {
		s/\D+//g;
		s/^0+/0/;
		s/^0(?!0)//;
	}
}


sub num2cardinal {
	$! = 22, return unless defined wantarray;
	my( $number, %cfg ) = @_;
	return unless defined $number;

	&_num_check( $number );

	# extreme index for:
	use constant VXN  => 5;	# numbers from 5 to <1000
	use constant TMMT => 6;	# тысячи | миллионы | миллиарды | триллионы

	my $gender = $cfg{'gender'} || 'masculine';
	$gender = $gender=~/^\s*(m|f|n)/i ? @{{'m'=>'masculine', 'f'=>'feminine', 'n'=>'neuter'}}{lc $1} : 'masculine';

	my $case = $cfg{'case'} || 'nominative';
	$case = $case=~/^\s*([ngdaip])/i ? $1 : 'n';

	my $multi = $cfg{'multi'} || 'singular';
	$multi = $multi=~/^\s*[p1-9]/i ? 'plural' : 'singular';

	my $object = $cfg{'object'} || 'inanimate';
	$object = $object=~/^\s*[a1-9]/i ? 'animate' : 'inanimate';

	# Preposition (prologue) of numeral
	my $prolog = &_ref_prolog( \%cfg, \$case );

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
		my $ii = &_add_prolog( $prolog, \@s );
		my $ns = $#s;

		# Add the epilog to numeral
		if( exists $epilog->{'root'} ) {
			my $j = 0;
			for my $root ( @{ $epilog->{'root'} } ) {
				push @s, $root.$epilog->{'ends'}[ $j++ ][0];
			}
		}

		$s[$ii] = ucfirst $s[$ii] if exists $cfg{'ucfirst'};

		return wantarray ? ( $ii, $ns, @s )  : join(' ', @s);
	}

	return "$number > 999_999_999_999_999 !" if length( $number ) > 15;

	# To get cardinal form DB (БД словоформ числительных)
	my( $bsw, $plural, $Power ) = &_cardinal_form_db( $case, $multi, $object, $gender, \%cfg );

	my @Dcml = @{ $bsw->{'dcml'} };
	my @Cent = @{ $bsw->{'cent'} };

	my @tmEnd;	# for ends --- для окончаний 'тысяч','миллион','миллиард','триллион'
	my @words;	# for ends --- для искомой структуры слов числительных
	my @s;	# Resulting string --- Результирующая строка
	my $ns;	# size of numeral string

	while( length( $number ) && $number ) {
		if( $number =~/^.$/ ) { # 0..9

			push @s, ( $multi =~/^plural/i && $number == 1 ) ?
				$plural->{1} :
				$bsw->{ $gender }{ ($case =~/^a/i && $object =~/^animate/i) ? 'animate' : 'unit'}[ $number ];

			# Add epilog to numeral
			if( exists $epilog->{'root'} ) {

				my $j = 0;
				for my $root ( @{ $epilog->{'root'} } ) {
					push @s, $root.$epilog->{'ends'}[ $j++ ][ $number < 5 ? $number : VXN ];
				}
				$ns = $j;

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
		}
		elsif( length( $number )%3 == 2 ) { # Десятки: 10 .. 99, 10_xxx .. 99_xxx, 10_xxx_xxx .. 99_xxx_xxx, etc.
			if( $number =~/^1/ ) { # 10... 19...
				$number =~s/^\d\d//;
				push @s, $words[$&];

				push @s, $Power->[$i].$tmEnd[0] if length $Power->[$i];
			}
			else { # 00, 20... 99...
				$number =~s/^\d//;
				push @s, $Dcml[$&] if $&;
			}
		}
		else { # length( $number )%3 == 1  # Единицы: 0..., 1,..., 9...
			$number =~s/^\d//;
			my $d = $&;
			if( $d ) {
				push @s, ( $multi =~/^plural/i && $d == 1 ) ? $plural->{1} : $words[$d];
			}

			if( $s[-1] !~/^(?:м|трил)/ ) { # ещё не добавлено миллион | миллиард | триллион
				my $w = ( $multi =~/^plural/i && $d == 1 ) ?
								$plural->{ $i < 2 ? 'eT' : 'eMT'} :
								$tmEnd[ $d < 5 ? $d : 0 ];

				push @s, $Power->[$i].$w;
			}

			last if $number =~/^0+$/;
		}
	}

	# Add prolog to numeral
	my $ii = &_add_prolog( $prolog, \@s );
	$ns = ( defined $ns ) ? $#s - $ns : $#s;

	$s[$ii] = ucfirst $s[$ii] if exists $cfg{'ucfirst'};

	# Add epilog to numeral
	if( exists $epilog->{'root'} ) {

		# Choice between
		my $k = $s[-1] =~/^(?:ты|ми|трил)/ ?
				TMMT :	# тысяча | миллион | миллиард | триллион
				VXN;	# other

		my $j = 0;
		for my $root ( @{ $epilog->{'root'} } ) {
			push @s, $root.$epilog->{'ends'}[ $j++ ][ $k ];
		}

	}

	return wantarray ? ( $ii, $ns, @s )  : join(' ', @s);
}


sub _cardinal_form_db {
	my( $case, $multi, $object, $gender, $cfg ) = @_;

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
				'','а', ('и') x 3 # , ('') x 5
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион' (0й - для 10..19; десятков: 10,20,...,90 и сотен: 100,200,...,900)
				'ов','', ('а') x 3 # , ('ов') x 5
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
				'','и', ('') x 3 # 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ов','а', ('ов') x 3 # 8
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
				'ам','е', ('ам') x 3 # 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ам','у', ('ам') x 3 # 8
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
				'','у', ('и') x 3 # , ('') x 5
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион' (0й - для 10..19 и десятков: 10,20,...,90)
				'ов','', ('а') x 3 # , ('ов') x 5
			],
		}, #--------------------------------------------
		'i' => { # instrumental (Творительный падеж) : кем? чем?
			'masculine' => { # Мужской род, default
				'unit' => [ # 0..19
					'','одним','двумя','тремя','четырьмя','пятью','шестью','семью','восемью','девятью','десятью', # or 'восьмью'  (see p.22)
'одиннадцатью','двенадцатью','тринадцатью','четырнадцатью','пятнадцатью','шестнадцатью','семнадцатью','восемнадцатью','девятнадцатью'
				],
			},
			'feminine' => { # Женский род
				'unit' => [ # 0..19
					'','одной' # остальные как для Мужского рода
				],
				'if1' => 'одною', # альтернативная форма
			},
			'dcml' => [ # 20, 30,...,90
'','','двадцатью','тридцатью','сорока','пятьюдесятью','шестьюдесятью','семьюдесятью','восемьюдесятью','девяноста' # or 'восьмьюдесятью' (see p.22)
			],
			'cent' => [ # 100..900
'','ста','двумястами','тремястами','четырьмястами','пятьюстами','шестьюстами','семьюстами','восемьюстами','девятьюстами' # or 'восьмьюстами' (see p.22)
			],
			'eT' => [ # окончания для 'тысяч'
				'ами','ей', ('ами') x 3
#				'ами','ью', ('ами') x 3 # разговорная форма (see 'i.T'=>'C')
#				'ами','ею', ('ами') x 3 # устаревшая форма (see 'i.T'=>'O')
			],
			'i.T' => { # формы окончания для 1 'тысяч'
				'C' => 'ью', # разговорная (colloquial form)
				'O' => 'ею', # устаревшая (obsolete form)
			},
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ами','ом', ('ами') x 3 # 8
			],
			'i.8' => {	# разговорные формы (see p.22)
				'unit' => 'восьмью',
				'dcml' => 'восьмьюдесятью',
				'cent' => 'восьмьюстами',
			},
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
				'ах','е', ('ах') x 3 # 8
			],
			'eMT' => [ # окончания для 'миллион','миллиард','триллион'
				'ах','е', ('ах') x 3 # 8
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
				if $case =~/^a/i && $object =~/^animate/i; # for accusative(Винительный падеж) + одушевлённый объект
		}

	}

	# Настраиваем альтернативные | разговорные | устаревшие формы, если заданы
	if( $case =~/^i/ and exists $cfg->{'alt'} ) {

		my $k = 'i.T';	# разговорная|устаревшая форма окончания для 'тысяч'
		if( defined( $cfg->{'alt'}{ $k } ) and $cfg->{'alt'}{ $k } =~/^(C|O)/i ) {
			$bsw{'i'}{'eT'}[1] = $bsw{'i'}{ $k }{uc $1};
		}

		$k = 'i.8';
		if( exists $cfg->{'alt'}{ $k } ) {
			for('dcml','cent') {	# 'восьмьюдесятью', 'восьмьюстами',
				$bsw{'i'}{$_}[8] = $bsw{'i'}{ $k }{$_};
			}

			my %gg;
			for my $g ('masculine','feminine', $gender ) {
				next if exists $gg{ $g };
				$gg{ $g } = undef;

				$bsw{'i'}{ $g }{'unit'}[8] = $bsw{'i'}{ $k }{'unit'};# 'восьмью'
			}
		}

		$bsw{'i'}{'feminine'}{'unit'}[1] = $bsw{'i'}{'feminine'}{'if1'} if exists $cfg->{'alt'}{'if1'};
	}

	# Корректируем окончания для accusative(Винительный падеж) + одушевлённый объект + множественное число
	if( $case =~/^a/i && $object =~/^animate/i && $multi =~/^plural/i ) {
		$plural{'a'}{1} = 'одних';
		$plural{'a'}{'eT'} = '';
		$plural{'a'}{'eMT'} = 'ов';
	}

	return( \%{ $bsw{ $case } }, \%{ $plural{ $case } }, ['','тысяч','миллион','миллиард','триллион'] );
}


# Add prolog to numeral, e.g. ['с','со=ст',...]
sub _add_prolog {
	my( $prolog, $s ) = @_;
	return 0 if ! @$prolog or (~~@$prolog < 2 and ( ! defined( $prolog->[0] ) or ! length( $prolog->[0] ) ) );

	# get element 0 in order (e.g. 'с') for any numeral
	my $p = ( !defined( $prolog->[0] ) or ! length( $prolog->[0] ) or $prolog->[0] =~/=/ ) ?
		undef :
		shift @$prolog;

	# get remaining elements
	my $i = 0;
	for( @$prolog ) {	# ['со=ст',...]
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

	if( defined $p ) {
		unshift @$s, $p;
		$i = 1;
	}

	return $i;
}


sub _ref_prolog {
	my( $cfg, $case ) = @_;
	my $prolog = $cfg->{'prolog'} // return [ ];

	if( ref($prolog) eq 'ARRAY') {
		return ~~@$prolog ? [ @$prolog ] : [ ];
	}
	elsif( ref($prolog) eq 'HASH') {
		my @p;
		for my $k (sort keys %$prolog ) {
			my $v = $prolog->{$k};
			$k =~s/^\s+|\s+$//g;
			next unless length $k or $v;

			if( length $v ) {
				push @p, "$k=$v";
			}
			else {
				unshift @p, $k;
			}
		}
		return ~~@p ? \@p : [ ];
	}
	elsif( ref(\$prolog) eq 'SCALAR') {
		$prolog =~s/^\s+|\s+$//g;

		# genitive - Родительный: кого? чего?
		if( $prolog =~/^(?:
				безо?|
				в(?:близи|виду|доль|замен|круг|место|не|низу|нутр[иь]|переди?|роде|овнутрь|озле|округ|следствие|ыше)|
				для|до|
				из(?:о?|\-за|нутри|\-подо?)|
				каса(?:ем|тельн)о|кроме|кругом|
				мимо|
				на(?:кануне|место|подобие|против|супротив|счет)|ниже|
				о(?:бок|бочь|коло|крест|круг|причь|то?|тносительно)|
				по(?:близости|верх|дле|зад[иь]|мимо|перек|се?реди(?:не)?|середь|сле|средством)|
				пр(?:евыше|отив)|путем|
				ради|
				с(?:верху?|выше|ередь|зади|илами|наружи|низу|переди|ред[иь]|упротив)|
				у
			)$/ix
		) {
			$$case = 'g'; # genitive
			return [ $prolog ];
		}

		# dative - Дательный: кому? чему?
		if( $prolog =~ /^(?:
				вдогон(?:ку|очку)?|вослед|вразрез|вслед|
				ко?|
				напере(?:кор|рез)|
				подобно|противно|
				соо(?:браз|тветствен)но|соразмерно
			)$/ix
		) {
			$$case = 'd'; # dative
			return [ $prolog ];
		}
		elsif( $prolog =~ /^благодаря$/i ) {
			$$case = 'd' if $$case !~/^[d]/;
			return [ $prolog ];
		}

		# accusative - Винительный: кого? что?
		if( $prolog =~ /^(?:
				(?:вы?|ис)ключая|про|сквозь|спустя|че?рез
			)$/ix
		) {
			$$case = 'a'; # accusative
			return [ $prolog ];
		}

		# instrumental - Творительный: кем? чем?
		if( $prolog =~ /^(?:
				кончая|надо?|начиная|передо?|по\-[зн]ад?
			)$/ix
		) {
			$$case = 'i'; # instrumental
			return [ $prolog ];
		}

		# prepositional - Предложный: о ком? о чём?
		if( $prolog =~ /^при$/i ) {
			$$case = 'p'; # prepositional
			return [ $prolog ];
		}

		# genitive (Родительный) || dative (Дательный, by default)
		if( $prolog =~ /^согласно$/i ) {
			$$case = 'd' if $$case !~/^[gd]/;
			return [ $prolog ];
		}

		# genitive (Родительный, by default) || instrumental (Творительный)
		if( $prolog =~ /^(?:про)?меж(?:ду)?$/i ) {
			$$case = 'g' if $$case !~/^[gi]/;
			return [ $prolog ];
		}

		# accusative (Винительный) || instrumental (Творительный, by default)
		if( $prolog =~ /^(?:за|подо?)$/i ) {
			$$case = 'i' if $$case !~/^[ai]/;
			return [ $prolog ];
		}

		# accusative (Винительный) || prepositional (Предложный)
		if( $prolog =~/^[вВB][ОоOo]?$/ ) {
			$prolog =~tr/BOo/ВОо/;
			$$case = 'a' if $$case !~/^[ap]/;
			return [ $prolog ];
		}
		elsif( $prolog =~ /^[oOоО][бБ]?[oOоО]?$/ ) {
			$$case = 'p' if $$case !~/^[ap]/;
			return ['о','об=од'];
		}
		elsif( $prolog =~ /^на$/i ) {
			$$case = 'a' if $$case !~/^[ap]/;
			return [ $prolog ];
		}

		# accusative (Винительный) || genitive (Родительный) || instrumental (Творительный, by default)
		if( $prolog =~/^[cCсС][ОоOo]?$/ ) {
			$$case = 'i' if $$case !~/^[agi]/;
			return ['с','со=ст'];
		}

		# accusative (Винительный) || dative (Дательный, by default) || prepositional (Предложный)
		if( $prolog =~ /^по$/i ) {
			$$case = 'd' if $$case !~/^[adp]/;
			return [ $prolog ];
		}

	}

	return [ ];
}


sub _ref_epilog {
	my( $case, $multi, $cfg, $object, $gender ) = @_;
	my $epilog = $cfg->{'epilog'} or return {};

	if( ref(\$epilog) eq 'SCALAR') {
		my %eRef;

		if( $epilog =~/^(?:RU[BR]|643|810|₽|(?i:рубль|ruble))$/ ) { # Российский рубль
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'рубл',
					'ends' => {
							'n' => ['ей','ь', ('я') x 3, ('ей') x 2 ],	# nominative - Именительный
							'g' => ['ей','я', ('ей') x 5 ],	# genitive - Родительный
							'd' => ['ям','ю', ('ям') x 4, 'ей' ],	# dative - Дательный
							'a' => ['ей','ь', ('я') x 3, ('ей') x 2 ],	# accusative - Винительный
							'i' => ['ей','ём', ('ями') x 4, 'ей' ],	# instrumental - Творительный
							'p' => ['ей','е', ('ях') x 4, 'ей' ],	# prepositional - Предложный
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}
		elsif( $epilog =~/^(?:BY[BRN]|Br|933|974)$/) { # Белорусский рубль
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => ['белорусск','рубл'],
					'ends' => {
							'n' => [['их','ий', ('их') x 5 ], ['ей','ь', ('я') x 3, ('ей') x 2 ]],	# nominative - Именительный
							'g' => [['их','ого', ('их') x 5 ], ['ей','я', ('ей') x 5 ]],	# genitive - Родительный
							'd' => [['им','ому', ('им') x 4, 'их'], ['ям','ю', ('ям') x 4, 'ей' ]],	# dative - Дательный
							'a' => [['их','ий', ('их') x 5 ], ['ей','ь', ('я') x 3, ('ей') x 2 ]],	# accusative - Винительный
							'i' => [['их','им', ('ими') x 4, 'их'], ['ей','ём', ('ями') x 4, 'ей']],	# instrumental - Творительный
							'p' => [['их','ом', ('их') x 5], ['ей','е', ('ях') x 4, 'ей']],	# prepositional - Предложный
					},
					'plural' => {'n'=>['ие','и'], 'g'=>['их','ей'], 'd'=>['им','ям'], 'a'=>['ие','и'], 'i'=>['ими','ями'], 'p'=>['их','ях']},
				);

		}
		elsif( $epilog =~/^(?:ru[br]|\-643|\-810|by[brn]|\-933|\-974|(?i:копейка|kopek))$/) { # Российская | Белорусская копейка
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'копе',
					'ends' => {
							'n' => ['ек','йка', ('йки') x 3, ('ек') x 2 ],
							'g' => ['ек','йки', ('ек') x 5 ],
							'd' => ['ек','йке', ('йкам') x 4, 'ек' ],
							'a' => ['ек','йку', ('йки') x 3, ('ек') x 2 ],
							'i' => ['ек','йкой', ('йками') x 4, 'ек' ],
							'p' => ['ек','йке', ('йках') x 4, 'ек' ],
					},
					'plural' => {'n'=>'йки', 'g'=>'ек', 'd'=>'йкам', 'a'=>'йки', 'i'=>'йками', 'p'=>'йках'},
				);

		}
		elsif( $epilog =~/^(?:USD|840|(?:US)?\$|(?i:доллар|dollar))$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'доллар',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'g' => ['ов','а', ('ов') x 5 ],
							'd' => ['ам','у', ('ам') x 4, 'ов' ],
							'a' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'i' => ['ов','ом', ('ами') x 4, 'ов' ],
							'p' => ['ов','е', ('ах') x 4, 'ов' ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:usd|\-840|(?i:цент|cent))$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'цент',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'g' => ['ов','а', ('ов') x 5 ],
							'd' => ['ам','у', ('ам') x 4, 'ов' ],
							'a' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'i' => ['ов','ом', ('ами') x 4, 'ов' ],
							'p' => ['ов','е', ('ах') x 4, 'ов' ],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:CNY|RMB|156|(?i:юань|yuan))$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'юан',
					'ends' => {
							'n' => ['ей','ь', ('я') x 3, ('ей') x 2 ],
							'g' => ['ей','я', ('ей') x 5 ],
							'd' => ['ям','ю', ('ям') x 5 ],
							'a' => ['ей','ь', ('я') x 3, ('ей') x 2 ],
							'i' => ['ей','ем', ('ями') x 4, 'ей' ],
							'p' => ['ях','е', ('ях') x 4, 'ей' ],
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}
		elsif( $epilog =~/^(?:cny|rmb|-156|(?i:фынь))$/) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'фын',
					'ends' => {
							'n' => ['ей','ь', ('я') x 3, ('ей') x 2 ],
							'g' => ['ей','я', ('ей') x 5 ],
							'd' => ['ям','ю', ('ям') x 5 ],
							'a' => ['ей','ь', ('я') x 3, ('ей') x 2 ],
							'i' => ['ей','ем', ('ями') x 4, 'ей' ],
							'p' => ['ях','е', ('ях') x 4, 'ей' ],
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}
		elsif( $epilog =~/^(?:year|год|лет)$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => '',
					'ends' => {
							'n' => ['лет','год', ('года') x 3, ('лет') x 2 ],
							'g' => ['лет','года', ('лет') x 5 ],
							'd' => ['лет','году', ('годам') x 4, 'лет' ],
							'a' => ['лет','год', ('года') x 3, ('лет') x 2 ],
							'i' => ['лет','годом', ('годами') x 4, 'лет' ],
							'p' => ['лет','годе', ('годах') x 4, 'лет' ],
					},
					'plural' => {'n'=>'годы', 'g'=>'лет', 'd'=>'годам', 'a'=>'годы', 'i'=>'годами', 'p'=>'годах'},
				);

		}
		elsif( $epilog =~/^(?:month|месяц)$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'месяц',
					'ends' => {
							'n' => ['ев','', ('а') x 3, ('ев') x 2 ],
							'g' => ['ев','а', ('ев') x 5 ],
							'd' => ['ам','у', ('ам') x 5 ],
							'a' => ['ев','', ('а') x 3, ('ев') x 2 ],
							'i' => ['ев','ем', ('ами') x 4, 'ев'],
							'p' => ['ев','е', ('ах') x 4, 'ев'],
					},
					'plural' => {'n'=>'ы', 'g'=>'ев', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:day|день)$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'д',
					'ends' => {
							'n' => ['ней','ень', ('ня') x 3, ('ней') x 2 ],
							'g' => ['ней','ня', ('ней') x 5 ],
							'd' => ['ням','ню', ('ням') x 5 ],
							'a' => ['ней','ень', ('ня') x 3, ('ней') x 2 ],
							'i' => ['ней','нём', ('нями') x 4, 'ней'],
							'p' => ['ней','не', ('нях') x 4, 'ней'],
					},
					'plural' => {'n'=>'ни', 'g'=>'ней', 'd'=>'ням', 'a'=>'ни', 'i'=>'нями', 'p'=>'нях'},
				);

		}
		elsif( $epilog =~/^(?:hour|час)$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'час',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'g' => ['ов','а', ('ов') x 5 ],
							'd' => ['ам','у', ('ам') x 5 ],
							'a' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'i' => ['ов','ом', ('ами') x 4, 'ов'],
							'p' => ['ов','е', ('ах') x 4, 'ов'],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:min|мин)/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'минут',
					'ends' => {
							'n' => ['','а', ('ы') x 3, ('') x 2 ],
							'g' => ['','ы', ('') x 5 ],
							'd' => ['','е', ('ам') x 4, ''],
							'a' => ['','у', ('ы') x 3, ('') x 2 ],
							'i' => ['','ой', ('ами') x 4, ''],
							'p' => ['','е', ('ах') x 4, ''],
					},
					'plural' => {'n'=>'ы', 'g'=>'', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:sec|сек)/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'секунд',
					'ends' => {
							'n' => ['','а', ('ы') x 3, ('') x 2 ],
							'g' => ['','ы', ('') x 5 ],
							'd' => ['','е', ('ам') x 4, ''],
							'a' => ['','у', ('ы') x 3, ('') x 2 ],
							'i' => ['','ой', ('ами') x 4, ''],
							'p' => ['','е', ('ах') x 4, ''],
					},
					'plural' => {'n'=>'ы', 'g'=>'', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:meter|метр)$/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'masculine',
					'root' => 'метр',
					'ends' => {
							'n' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'g' => ['ов','а', ('ов') x 5 ],
							'd' => ['ов','у', ('ам') x 4, 'ов'],
							'a' => ['ов','', ('а') x 3, ('ов') x 2 ],
							'i' => ['ов','ом', ('ами') x 4, 'ов'],
							'p' => ['ов','е', ('ах') x 4, 'ов'],
					},
					'plural' => {'n'=>'ы', 'g'=>'ов', 'd'=>'ам', 'a'=>'ы', 'i'=>'ами', 'p'=>'ах'},
				);

		}
		elsif( $epilog =~/^(?:stamp|печат)/i) {
			%eRef = (
					'object' => 'inanimate',
					'gender' => 'feminine',
					'root' => 'печат',
					'ends' => {
							'n' => ['ей','ь', ('и') x 3, ('ей') x 2 ],
							'g' => ['ей','и', ('ей') x 5 ],
							'd' => ['ей','и', ('ям') x 4, 'ей'],
							'a' => ['ей','ь', ('и') x 3, ('ей') x 2 ],
							'i' => ['ей','ью', ('ями') x 4, 'ей'],
							'p' => ['ей','и', ('ях') x 4, 'ей'],
					},
					'plural' => {'n'=>'и', 'g'=>'ей', 'd'=>'ям', 'a'=>'и', 'i'=>'ями', 'p'=>'ях'},
				);

		}

		if( %eRef ) {
			$$object = $eRef{'object'};
			$$gender = $eRef{'gender'};

			# To fix for plural '1' only
			if( $multi =~/^plural/i ) {
				if( ref( \$eRef{'plural'}{ $case } ) eq 'SCALAR') {
					$eRef{'ends'}{ $case }[1] = $eRef{'plural'}{ $case };
				}
				else { # if( ref( $eRef{'plural'}{ $case } ) eq 'ARRAY') # a lot of words in the epilogue
					my $i = 0;
					for( @{ $eRef{'plural'}{ $case } } ) {
						$eRef{'ends'}{ $case }[ $i++ ][1] = $_;
					}
				}
			}

			$epilog = {};

			if( ref( \$eRef{'root'} ) eq 'SCALAR') {
				$epilog->{'root'} = [ $eRef{'root'} ];
				$epilog->{'ends'}[0] = $eRef{'ends'}{ $case };
			}
			else { # if( ref( $eRef{'root'} ) eq 'ARRAY') # a lot of words in the epilogue
				$epilog->{'root'} = $eRef{'root'};
				$epilog->{'ends'} = $eRef{'ends'}{ $case };
			}
		}
		else {
			$epilog = {};
		}

	}
	elsif( ref($epilog) eq 'HASH' and exists $epilog->{'root'} and exists $epilog->{'ends'} ) {
		if( defined $epilog->{'object'} ) {
			$$object = $epilog->{'object'}=~/^\s*[a1-9]/i ? 'animate' : 'inanimate';
		}

		$$gender = @{{'m'=>'masculine', 'f'=>'feminine', 'n'=>'neuter'}}{lc $1}
			if defined( $epilog->{'gender'} ) && $epilog->{'gender'} =~/^\s*(m|f|n)/i;

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

  use Lingua::RU::Numeral qw( num2cardinal case_endings spelled_out_number );

or

  use Lingua::RU::Numeral qw(:all);

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

  say num2cardinal( 1000, 'epilog'=>'RUB');	# add 'рубль' (российский), using an alphabetic currency code
  say num2cardinal( 1000, 'epilog'=> 643 );	# the same, using a digital currency code
  say num2cardinal( 2000, 'epilog'=>'rub');	# add 'копейка' (российская)
  say num2cardinal( 2000, 'epilog'=> -643);	# the same
  say num2cardinal( 1000, 'epilog'=>'BYR');	# add 'белорусский рубль', using an alphabetic currency code

Will print the results:

  одна тысяча рублей
  одна тысяча рублей
  две тысячи копеек
  две тысячи копеек
  одна тысяча белорусских рублей


=item 9.

Using B<custom C<'epilog'> > which is configured manually (норвежская крона) with other default options:

  my $epilog = { # Nominative case (Именительный падеж)
               'object' => 'inanimate',
               'gender' => 'feminine',
               'root'   => ['норвежск','крон'],
               'ends'   => [ ['их','ая', ('их') x 5 ], ['','а', ('ы') x 3, ('') x 2] ],
              };

  say num2cardinal( $_,
                   'epilog' => $epilog
                  ) for 0..5, 10, 100, 1000;

Will print the result:

  ноль норвежских крон
  одна норвежская крона
  две норвежских кроны
  три норвежских кроны
  четыре норвежских кроны
  пять норвежских крон
  десять норвежских крон
  сто норвежских крон
  одна тысяча норвежских крон


=item 10.

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
               'root'   => ['печат'],
               'ends'   => [ ['ях','и', ('ях') x 5 ] ],
              };

  say num2cardinal( 11,
                   'case'   => 'prepositional',	# Предложный: о ком? о чём?
                   'prolog' => ['о','об=од'],
                   'epilog' => $epilog,
                  );

Will print the result:

  об одиннадцати печатях


=item 11.

Using C<'alt'> (alternate form) with other default options:

  say num2cardinal( 0 );
  say num2cardinal( 0, alt => { 0=>'TRUE'} );

Will print the results:

  ноль
  нуль


=item 12.

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


=item 13.

Usage for correct case endings only (without numeral written as a string):

  my $number = 1000;
  my %options = ('prolog' => 'за', 'epilog'=>'CNY');

  say case_endings( $number, %options);	# add 'юань' (Chinese yuan), using an alphabetic currency code

or in verbose form:

  my( $i, $ns, @s ) = &num2cardinal( $number, %options );
  splice @s, $i, $ns - $i + 1, $number;
  say join(' ', @s);

Will print the results:

  за 1000 юаней


=item 14.

To get the $number that is padded with Russian numeral in parentheses:

  say spelled_out_number( 100_000, case=>'accusative', 'prolog'=>'за', 'epilog'=>'CNY', 'ucfirst'=>1 );

Will print the results:

  за 100000 (Сто тысяч) юаней


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

This module provides functions that can be used to generate Russian verbiage for the natural numbers (unsigned integer) and 0 (zero).
The methods implemented in this module, are all focused on knowledge of Russian grammar.


=head1 DESCRIPTION

This module provides functions that can be used to generate Russian verbiage for the natural numbers (unsigned integer) and 0 (zero).
The methods implemented in this module, are all focused on knowledge of Russian grammar.

This module makes verbiage in "short scales" (1,000,000,000 is "один миллиард" rather than "одна тысяча миллионов").
For details see this Wikipedia russian article:

L<https://ru.wikipedia.org/wiki/Системы_наименования_чисел>


=head1 SUBROUTINES

Lingua::RU::Numeral provides these subroutines:

    num2cardinal( $number [, %facultative_options ] );
    case_endings( $number [, %facultative_options ] );
    spelled_out_number( $number [, %facultative_options ] );

=head2 num2cardinal( $number [, %facultative_options ] )

Convert a C<$number> (natural numbers or 0) to Russian text (string) made in a particular calling context (list, scalar or void),
using explicitly specified global C<%facultative_options>, otherwise - default options.

C<num2cardinal()> returns C<($i, $ns, @s)> if the currently executing subroutine expects to return a list value,
and Russian C<$text> if it is looking for a scalar value.
Here C<$i> — index of the B<first numeral> word in the array of words C<@s>;
C<$ns> — index of the B<last numeral> word in C<@s>;
C<@s> — the array of words that form the returned Russian text (string) in scalar context, e.g. C<join(' ',@s)>.

The following can be global C<%facultative_options>:

=over 3

=item * C<'case'> option — case of a numeral can take the following meanings (case names can be shorthand to one first letter):

=over 6

=item 1.
C<'n'|'nominative'> (I<Именительный падеж: есть кто? что? сколько?> is B<default>),

=item 2.
C<'g'|'genitive'> (I<Родительный падеж: нет кого? чего? скольких?>),

=item 3.
C<'d'|'dative'> (I<Дательный падеж: рад кому? чему? скольким?>),

=item 4.
C<'a'|'accusative'> (I<Винительный падеж: вижу кого? что? скольких? (одуш) сколько? (неодуш)>),

=item 5.
C<'i'|'instrumental'> (I<Творительный падеж: оплачу кем? чем? сколькими?>),

=item 6.
C<'p'|'prepositional'> (I<Предложный падеж: думаю о ком? о чём? о скольких?>).

=back

=item * C<'gender'> option — C<'m'|'masculine'> (I<Мужской род>, B<by default>) or C<'f'|'feminine'> (I<Женский род>)
or C<'n'|'neuter'> (I<Средний род>). Gender names can be shorthand to one first letter also.

=item * C<'multi'> option — word(s) in the plural (C<'1'|'plural'>, I<множественное число>) or C<'undef'|'0'|'singular'> (I<единственное число>, B<by default>).

=item * C<'object'> option — C<'i'|'inanimate'> (I<неодушевлённый предмет>, B<by default>) or C<'a'|'animate'> (I<одушевлённый предмет>) object.
Object names can be shorthand to one first letter also.

=item * C<'prolog'> option — PREPosition(s) of the numeral is the REF to ARRAY,
where 0th element ('PREP_0') — the preposition for all numerals, except for those indicated 
by subsequent array elements ('PREP_x') as C<['PREP_0','PREP_1=REGEX',...]>.

Here REGEX — the regular expression that is used to find a match at the beginning of a numeric string like:
C<numeral =~/^REGEX/>.
For example:

  'prolog' => ['о','об=од']

If C<'prolog'> is SCALAR value (e.g. C<< 'prolog'=>'о' >>) then it is used from internal B<reference list of prologs> (inner prolog).
In this case, the inner prolog controls B<case of the numeral> and overrides (suppresses or affirms its authority)
the global option C<'case'>.

Now internal B<reference list of prologs> contains the following preconfigured phrase structures, i.e. the inner prologs:

=over 6

=item *
for B<genitive> case (I<Родительный падеж>):

C<без>, C<безо>,
C<вблизи>, C<ввиду>, C<вдоль>, C<взамен>, C<вкруг>, C<вместо>, C<вне>, C<внизу>, C<внутри>, C<внутрь>, C<вперед>,
C<вследствие>, C<впереди>, C<вроде>, C<вовнутрь>, C<возле>, C<вокруг>, C<вследствие>, C<выше>,
C<для>, C<до>,
C<из>, C<изо>, C<из-за>, C<изнутри>, C<из-под>, C<из-подо>,
C<касаемо>, C<касательно>, C<кроме>, C<кругом>,
C<мимо>,
C<накануне>, C<наместо>, C<наподобие>, C<напротив>, C<насупротив>, C<насчет>, C<ниже>,
C<обок>, C<обочь>, C<около>, C<окрест>, C<округ>, C<опричь>, C<от>, C<ото>, C<относительно>,
C<поблизости>, C<поверх>, C<подле>, C<позади>, C<позадь>, C<помимо>, C<поперек>, C<посереди>, C<посередине>, C<после>,
C<посередь>, C<посреди>, C<посредине>, C<посредством>,
C<превыше>, C<против>, C<путем>,
C<ради>,
C<сверх>, C<сверху>, C<свыше>, C<середь>, C<сзади>, C<силами>, C<снаружи>, C<снизу>, C<спереди>, C<среди>, C<средь>, C<супротив>,
C<у> — equivalent to the corresponding word, specified as the only array element.

=item *
for B<dative> case (I<Дательный падеж>):

C<вдогон>, C<вдогонку>, C<вдогоночку>, C<вослед>, C<вразрез>, C<вслед>,
C<к>, C<ко>, C<наперекор>, C<наперерез>, C<подобно>, C<противно>, C<сообразно>, C<соответственно>,
C<соразмерно> — equivalent to the corresponding word, specified as the only array element.

=item *
for B<accusative> case (I<Винительный падеж>):

C<включая>, C<выключая>, C<исключая>, C<про>, C<сквозь>, C<спустя>, C<через>, C<чрез> — equivalent to the corresponding word,
specified as the only array element.

=item *
for B<instrumental> case (I<Творительный падеж>):

C<кончая>, C<над>, C<надо>, C<начиная>, C<перед>, C<передо>, C<по-за>, C<по-над> — equivalent to the corresponding word,
specified as the only array element.

=item *
for B<prepositional> case (I<Предложный падеж>):

C<при> — equivalent to C<['при']>.

=item *
for B<genitive> (I<Родительный>) and B<dative> cases (I<Дательный падеж>):

C<согласно> — equivalent to C<['согласно']>.

=item *
for B<genitive> (I<Родительный>) and B<instrumental> cases (I<Творительный падеж>):

C<меж>, C<между>, C<промеж>, C<промежду> — equivalent to the corresponding word, specified as the only array element.

=item *
for B<accusative> (I<Винительный>) and B<instrumental> cases (I<Творительный падеж>):

C<за>, C<под>, C<подо> — equivalent to the corresponding word, specified as the only array element.

=item *
for B<dative> (I<Дательный падеж>) and B<accusative> cases (I<Винительный падеж>):

C<благодаря> — equivalent to C<['благодаря']>.

=item *
for B<accusative> (I<Винительный>) and B<prepositional> cases (I<Предложный падеж>):

C<на> — equivalent to C<['на']>.

C<o>, C<oб>, C<oбо> — equivalent to C<['о','об=од']>.

C<в>, C<во> — equivalent to C<['в']> and C<['во']>, respectively.

=item *
for B<genitive> (I<Родительный>), B<accusative> (I<Винительный>), and B<instrumental> cases (I<Творительный падеж>):

C<c>, C<со> — equivalent to C<['с','со=ст']>.

=item *
for B<dative> (I<Дательный>), B<accusative> (I<Винительный>), and B<prepositional> cases (I<Предложный падеж>):

C<по> — equivalent to C<['по']>.

=back

B<WARNING!> Once again, the inner prolog controls B<case of the numeral> and overrides (suppresses or affirms its authority)
the global option C<'case'>.


=item * C<'epilog'> option — final word(s) (phrase(s)) of the numeral is SCALAR value (name) from internal B<reference list of epilogs>
or the REF to complex HASH to create a B<custom> phrase(s).

Internal B<reference list of epilogs> contains the following preconfigured phrase structures:

=over 6

=item * C<RUB|RUR|643|810|₽|рубль|ruble> — for Russian ruble (I<Российский рубль>);
C<rub|rur|-643|-810|byb|byr|byn|-933|-974|копейка|kopek> — for kopek (I<копейка>).

=item * C<CNY|RMB|156|юань|yuan> — Chinese yuan;
C<cny|rmb|-156|фынь> — for Chinese cent.

=item * C<USD|840|US$|$|доллар|dollar> — for United States dollar;
C<usd|-840|цент|cent> — for US cent.

=item * C<BYR|BYB|BYR|BYN|Br|933|974> — for Belarusian ruble (I<Белорусский рубль>).

=item * Time measures: C<'year|год|лет'>;
C<'month|месяц'>;
C<'day|день'>;
C<'hour|час'>;
C<'min|мин'> — for minute (I<минута>);
C<'sec|сек'> — for second (I<секунда>).

=item * Miscellaneous: C<'meter|метр'>;
C<'stamp|печать'>.

=back

The B<custom C<'epilog'> > presents the REF to HASH with complex structure of SCALAR values and ARRAYs.
For example, I<год>, I<лет> (shorthand equivalent is C<$epilog = 'year'> for C<'nominative'> case (Именительного падежа):

  my $epilog = {
               'object' => 'inanimate', # неодушевлённый предмет
               'gender' => 'masculine', # Мужской род
               'root'   => [''],
               'ends'   => [['лет','год', ('года') x 3, ('лет') x 2 ]],
              };

or for I<секунда> (shorthand equivalent is C<$epilog = 'sec'> for C<'accusative'> case (Винительного падежа)):

  my $epilog = {
               'object' => 'inanimate',
               'gender' => 'feminine', # Женский род
               'root'   => ['секунд'],
               'ends'   => [['','у', ('ы') x 3, ('') x 2 ]],
              };

or for I<рубль> (shorthand equivalent is C<$epilog = 'RUB'> for C<'dative'> case (Дательного падежа)):

  my $epilog = {
               'object' => 'inanimate',
               'gender' => 'masculine', # Мужской род
               'root'   => ['рубл'],
               'ends'   => [['ям','ю', ('ям') x 4, 'ей']],
              };

Here are:

=over 6

=item * already known C<'object'> and C<'gender'> options. These options are recommended but not required.
B<WARNING!> These options take precedence over the global options(C<'object'>, C<'gender'>), i.e. override them.

=item * C<'root'> option means the C<'epilog'> root, i.e. common invariable part of the custom C<'epilog'> words
(or its absence in the form of "").

=item * C<'ends'> option means the C<'epilog'> word endings for seven (7) numerals: 0, 1, 2, 3, 4, 5, 1000 (thousand) respectively.
In fact, the seventh ending in each subarray also corresponds to a million (1_000_000), a billion (1_000_000_000),
and a trillion (1_000_000_000_000).

=back


=item * C<'alt'> option — REF to HASH of alternative (colloquial, obsolete) word forms.
Currently available for:

=over 6

=item * zero (0) (I<ноль>, by default; C<< 'alt' => {0=>1} >>, to obtain I<нуль>).

=item * C<'i.T'> key — Colloquial or Obsolete form for 'thousands' (I<тысяч>) in C<'instrumental'> case (I<Творительный падеж>):

  say num2cardinal( 1000, case => 'i', alt => {'i.T'=>'Colloquial'} ); # or 'i.T'=>'C'
  say num2cardinal( 1000, case => 'i', alt => {'i.T'=>'Obsolete'} ); # or 'i.T'=>'O'
  say num2cardinal( 1000, case => 'i'); # traditional established form

Will print the results:

  одной тысячью
  одной тысячею
  одной тысячей

=item * C<'i.8'> key — сolloquial form for I<'восьмью'>, I<'восьмьюдесятью'>, I<'восьмьюстами'> in C<'instrumental'> case (I<Творительный падеж>):

  say num2cardinal( $_, case => 'i', alt => {'i.8'=>'TRUE'} ) for 8000, 80, 800;

Will print the results:

  восьмью тысячами
  восьмьюдесятью
  восьмьюстами

Instead traditional established forms:

  восемью тысячами
  восемьюдесятью
  восемьюстами

=item * C<'if1'> key — alternate form for I<'одною'> in C<'instrumental'> case (I<Творительный падеж>) and C<'feminine'> gender:

  say num2cardinal( 1000, case => 'i', gender => 'feminine', alt => {'if1'=>'TRUE'} );
  say num2cardinal( 1000, case => 'i', gender => 'feminine', alt => {'if1'=>'TRUE', 'i.T'=>'O'} ); # alternate and obsolete form

  одною тысячей
  одною тысячею

=back

=item * C<'ucfirst'> option — returns the numeral with the first character capitalized (Upper case).
B<WARNING!> does not affect the C<'prolog'>.

=back


=head2 case_endings( $number [, %facultative_options ] )

This subroutine returns the C<'epilog'> corresponding to the numeral and case endings.

This subroutine is only intended to match C<'epilog'> case endings.
It does NOT convert a C<$number> (natural numbers or 0) to Russian text (string, i.e. a numeral).
Therefore, this subroutine makes sense when at least C<$number> and C<'epilog'> option are given.
All global C<%facultative_options>, are the same as C<num2cardinal()> subroutine.
In fact, this subroutine is a wrapper around the C<num2cardinal()> subroutine:

  say case_endings( 1000, 'epilog'=>'RUB');

Will print the results:

  1000 рублей


=head2 spelled_out_number( $number [, %facultative_options ] )

This subroutine returns the C<$number> that is padded with Russian numeral in parentheses (text string).
E.g.:

  say spelled_out_number( 1000, case=>'accusative', 'prolog'=>'за', 'epilog'=>'CNY', 'ucfirst'=>1 );

Will print the results:

  за 1000 (Одну тысячу) юаней


=head1 EXPORT

Lingua::RU::Numeral exports nothing by default.
Each of the subroutines can be exported on demand, as in

  use Lingua::RU::Numeral qw( num2cardinal );

and the tag C<all> exports them all:

  use Lingua::RU::Numeral qw( :all );


=head1 DEPENDENCIES

Lingua::RU::Numeral is known to run under perl 5.10.0 on Linux.

=head1 CAVEATS

The author of this module is not professional linguist. If you would like to help me correct numeral errors, please send me an email.

=head1 SEE ALSO

Igor' A. Mel'čuk. THE SURFACE SYNTAX OF RUSSIAN NUMERAL EXPRESSIONS. -Wien: Volume 16 of Wiener slawistischer Almanach,
Institut für Slavistik der Universität, -1985. — 514 p. ISSN 0258-6819.

Мельчук, И.А. Поверхностный синтаксис русских числовых выражений. -Wien: Volume 16 of Wiener slawistischer Almanach,
Institut für Slavistik der Universität, -1985. — 514 c. ISSN 0258-6819.

Сичинава, Д.В. Числительные // Материалы к корпусной грамматике русского языка. Выпуск III : Части речи и лексико-грамматические классы.
СПб.: Нестор-История, 2018. С. 193–257.

Сичинава, Д.В. Предлоги // Материалы к корпусной грамматике русского языка. Выпуск III : Части речи и лексико-грамматические классы.
СПб.: Нестор-История, 2018. С. 329–373.

L<Lingua::RU::Number> is a Perl module that offers some similar functionality.

=head1 AUTHOR

Alessandro N. Gorohovski, E<lt>an.gorohovski@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2025 by Alessandro N. Gorohovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
