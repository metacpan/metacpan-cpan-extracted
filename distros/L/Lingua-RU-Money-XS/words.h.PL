use 5.016000;
use utf8;
use Encode qw(encode);
use List::MoreUtils qw(zip);

open STDOUT, "> $ARGV[0]" or die "$ARGV[0]: $!";

sub utf2hex {
	return sprintf "\\x%*vx",'\x', encode('UTF-8', $_[0]);
}

my @enum = qw(SINGLE COUPLE SEVERAL);
my @decade = qw(UNIT THOUSAND MILLION BILLION TRILLION);
my @kopeck = qw(копейка копейки копеек);
my @ruble = map { { zip @enum, @{ $_ } } } (
	[ qw(рубль рубля рублей) ],
	[ qw(тысяча тысячи тысяч) ],
	[ qw(миллион миллиона миллионов) ],
	[ qw(миллиард миллиарда миллиардов) ],
	[ qw(триллион триллиона триллионов) ]
);

my $kopeck = { zip @enum, @kopeck };
my $ruble = { zip @decade, @ruble };
my $words = {
	munits => [ '', qw(один два три четыре пять шесть семь восемь девять десять
		одиннадцать двенадцать тринадцать четырнадцать пятнадцать шестнадцать
		семнадцать восемнадцать девятнадцать) ],
	funits => [ '', qw(одна две три четыре пять шесть семь восемь девять десять
		одиннадцать двенадцать тринадцать четырнадцать пятнадцать шестнадцать
		семнадцать восемнадцать девятнадцать) ],
	tens => [ '', '', qw(двадцать тридцать сорок пятьдесят шестьдесят семьдесят
		восемьдесят девяносто) ],
	hundreds => [ '', qw(сто двести триста четыреста пятьсот шестьсот семьсот
		восемьсот девятьсот) ],
};

printf "#define MONEY_MIN 0\n";
printf "#define MONEY_MAX %17.2f\n", 1e3 ** @decade;

# Generate enum with ending types
printf "enum {\n\t%s\n};\n", join ",\n\t", @enum;

# Generate enum with ruble decades
printf "enum {\n\t%s\n};\n", join ",\n\t", @decade;

# Generate the array with kopeck endings
printf "const char *kopeck[] = {\n\t%s\n};\n", join ",\n\t", map {
	sprintf "[%s] = \"%s\"", $_ => utf2hex $kopeck->{ $_ }
} @enum;

# Generate the array with ruble endings
printf "const char *ruble[][3] = {\n\t%s\n};\n", join ",\n\t", map {
	my $key = $_;
	sprintf "[%s] = {\n\t\t%s\n\t}", $key => join ",\n\t\t", map {
		sprintf "[%s] = \"%s \"", $_ => utf2hex $ruble->{ $key }->{ $_ }
	} @enum
} @decade;

# Generate arrays with number in words
printf join "", map {
	my $key = $_;
	sprintf "const char *%s[] = {\n\t\"%s\"\n};\n", $_ => join "\",\"", map {
		sprintf "%s ", utf2hex $_ if $_
	} @{ $words->{ $key } }
} keys %{ $words };
