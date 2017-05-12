#!/usr/bin/perl

use strict;
use lib ('./blib','../blib','../lib','./lib');
use blib ('./blib','../blib','../lib','./lib');
use Lingua::Stem qw(:all);

my @do_tests=(1..4);

my $test_subs = { 
       1 => { -code => \&test1,              -desc => 'locale        ' },
       2 => { -code => \&test2,              -desc => 'stem          ' },
       3 => { -code => \&test_stem_in_place, -desc => 'stem_in_place ' },
       4 => { -code => \&test3,              -desc => 'exceptions    ' },
};
print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
my $n_failures = 0;
foreach my $test (@do_tests) {
	my $sub  = $test_subs->{$test}->{-code};
	my $desc = $test_subs->{$test}->{-desc};
	my $failure = '';
	eval { $failure = &$sub; };
	if ($@) {
		$failure = $@;
	}
	if ($failure ne '') {
		chomp $failure;
		print "not ok $test\n";
		print STDERR "    $desc - $failure\n";
		$n_failures++;
	} else {
		print "ok $test\n";
		print STDERR "    $desc - ok\n";

	}
}
print "END\n";
exit;

########################################
# Locale                               #
########################################
sub test1 {
	my $original_locale  = get_locale;

	my @test_locales = qw(En En-Us En-Uk En-Broken Da De Fr Gl It No Pt Sv);

	foreach my $test_locale (@test_locales,$test_locales[0]) {
		set_locale($test_locale);
		my $new_locale  = get_locale;
		if (lc($new_locale) ne lc($test_locale)) {
			return "unable to change locale to '$test_locale'";
		}
	}

	# Restore original locale
	set_locale($original_locale);
	my $new_locale = get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		return "unable to restore locale to '$original_locale'";
	}
	'';
}

########################################
# Stem                                 #
########################################
sub test2 {
	my $original_locale  = get_locale;

	my $test_locales = {
	        'Da' => {
                  -words => [qw(abiezriternes aftenafgrødeofferets bortskaffer)],
                 -expect => [qw(abiezrit      aftenafgrødeof       bortskaf)],
				  },
	        'De' => {
                  -words => [qw( infrastrukturelle Verfall gesellschaftlichen Organisation DDR
                                  führte verhärteten isolationistischen Politik reformerische
                                  Anforderungen Mitte Jahre Krisenpotential
                            )],
                 -expect => [qw(infrastrukturell Verfall gesellschaftlich Organisation DDR
                              führen verhärten isolationistisch Politik reformerisch
                              Anforderung Mitte Jahr Krisenpotential
                            )],
				  },
	        'En' => { 
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
	        'En-Us' => { 
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
	        'En-Uk' => {
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
	        'Fr' => {
                  -words => [qw(fouillait fouilleront fouillent fouillez fortunées fortuné froidement)],
                 -expect => [qw(fouill    fouill      fouill     fouill  fortun    fortun  froid)],
				  },
#	        'It' => {
#                  -words => [qw(programma   programmi   programmare   programmazione
#                                gatto       gatta       gatti         gatte
#                                abbandonare abbandonato abbandonavamo abbandonai
#                            )],
#                 -expect => [qw(programm  programm  programm    programm
#                                gatt      gatt      gatt        gatt
#                                abbandon  abbandon  abbandon    abbandon
#                                )],
#				  },
	        'Pt' => {
                  -words => [qw(bons chilena pezinho existencialista beberiam)],
                 -expect => [qw(bom chilen pe exist beb)],
				  },
	        'Gl' => {
                  -words => [qw(bons chilena cazola preconceituoso chegou)],
                 -expect => [qw(bon chilen caz preconceit cheg)],
				  },
	        'No' => {
                  -words => [qw(administrasjonsdepartementet datainnsamlingsmetode)],
                 -expect => [qw(administrasjonsdepartement   datainnsamlingsmetod)],
				  },
	        'Sv' => {
                  -words => [qw(bedröfvelsens)],
                 -expect => [qw(bedröfv)],
				  },
	};
	my @locales = sort keys %$test_locales;
	foreach my $locale_name (@locales) {
		my $test_locale = $test_locales->{$locale_name};
		set_locale($locale_name);
		my $new_locale  = get_locale;
		if (lc($new_locale) ne lc($locale_name)) {
			return "unable to change locale to '$locale_name'";
		}
		my $words  = $test_locale->{-words};
		my $expect = $test_locale->{-expect};
		my $stemmed = stem(@$words);
		if ($#$stemmed != $#$expect) {
			return "different number of words returned than expected";
		}
		my @errors = ();
		for (my $count=0;$count<=$#$stemmed;$count++) {
			my $expected = $expect->[$count];
			my $found    = $stemmed->[$count];
			if ($found ne $expected) {
				push (@errors,"expected '$expected', got '$found' for locale '$locale_name'");
			}
		}
		if ($#errors > -1) {
			my $result = join ('; ',@errors);
			return $result;
		}
	}

	# Restore original locale
	set_locale($original_locale);
	my $new_locale = get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		return "unable to restore locale to '$original_locale'";
	}
	'';
}


########################################
# Stem in place                        #
########################################
sub test_stem_in_place {
	my $original_locale  = get_locale;

	my $test_locales = {
#	        'Da' => {
#                  -words => [qw(abiezriternes aftenafgrødeofferets bortskaffer)],
#                 -expect => [qw(abiezrit      aftenafgrødeof       bortskaf)],
#				  },
#	        'De' => {
#                  -words => [qw( infrastrukturelle Verfall gesellschaftlichen Organisation DDR
#                                  führte verhärteten isolationistischen Politik reformerische
#                                  Anforderungen Mitte Jahre Krisenpotential
#                            )],
#                 -expect => [qw(infrastrukturell Verfall gesellschaftlich Organisation DDR
#                              führen verhärten isolationistisch Politik reformerisch
#                              Anforderung Mitte Jahr Krisenpotential
#                            )],
#				  },
	        'En' => { 
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
	        'En-Us' => { 
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
	        'En-Uk' => {
                  -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                 -expect => [qw(the lazi red dog quickli run over the gurgl brook)],
				  },
#	        'Fr' => {
#                  -words => [qw(fouillait fouilleront fouillent fouillez fortunées fortuné froidement)],
#                 -expect => [qw(fouill    fouill      fouill     fouill  fortun    fortun  froid)],
#				  },
#	        'It' => {
#                  -words => [qw(programma   programmi   programmare   programmazione
#                                gatto       gatta       gatti         gatte
#                                abbandonare abbandonato abbandonavamo abbandonai
#                            )],
#                 -expect => [qw(programm  programm  programm    programm
#                                gatt      gatt      gatt        gatt
#                                abbandon  abbandon  abbandon    abbandon
#                                )],
#				  },
#	        'Pt' => {
#                  -words => [qw(bons chilena pezinho existencialista beberiam)],
#                 -expect => [qw(bom chilen pe exist beb)],
#				  },
#	        'Gl' => {
#                  -words => [qw(bons chilena cazola preconceituoso chegou)],
#                 -expect => [qw(bon chilen caz preconceit cheg)],
#				  },
#        'No' => {
#                  -words => [qw(administrasjonsdepartementet datainnsamlingsmetode)],
#                 -expect => [qw(administrasjonsdepartement   datainnsamlingsmetod)],
#				  },
#	        'Sv' => {
#                  -words => [qw(bedröfvelsens)],
#                 -expect => [qw(bedröfv)],
#				  },
	};
	my @locales = sort keys %$test_locales;
	foreach my $locale_name (@locales) {
		my $test_locale = $test_locales->{$locale_name};
		set_locale($locale_name);
		my $new_locale  = get_locale;
		if (lc($new_locale) ne lc($locale_name)) {
			return "unable to change locale to '$locale_name'";
		}
		my $words  = $test_locale->{-words};
		my $expect = $test_locale->{-expect};
		my $stemmed = stem(@$words);
        my @test_words = @$words;
        stem_in_place(@test_words);

		if ($#test_words != $#$expect) {
			return "different number of words returned than expected";
		}
		my @errors = ();
		for (my $count=0;$count<=$#$stemmed;$count++) {
			my $expected = $stemmed->[$count];
			my $found    = $test_words[$count];

			if ($found ne $expected) {
				push (@errors,"expected '$expected', got '$found' for locale '$locale_name'");
			}
		}
		if ($#errors > -1) {
			my $result = join ('; ',@errors);
			return $result;
		}
	}

	# Restore original locale
	set_locale($original_locale);
	my $new_locale = get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		return "unable to restore locale to '$original_locale'";
	}
	'';
}

########################################
# Exceptions                           #
########################################
sub test3 {
	my $original_locale  = get_locale;

	my $test_locales = {
                   'En' => { 
                      -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                     -expect => [qw(the lazi red cat quickli run over the gurgl brook)],
                     -except => { 'dogs' => 'cat' },
                      },
                'En-Us' => { 
                      -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                     -expect => [qw(the lazi red dog quickli run over the gurgl stream)],
                     -except => { 'brook' => 'stream' },
                      },
                'En-Uk' => {
                      -words => [qw(The lazy red dogs quickly run over the gurgling brook)],
                     -expect => [qw(the lazi akai dog quickli run over the gurgl brook)],
                     -except => { 'red' => 'akai' },
                      },
				};
	my @errors = ();
	foreach my $locale_name (sort keys %$test_locales) {
		my $test_locale = $test_locales->{$locale_name};
		set_locale($locale_name);
		my $new_locale  = get_locale;
		if (lc($new_locale) ne lc($locale_name)) {
			push(@errors,"unable to change locale to '$test_locale'");
			next;
		}
		my $words  = $test_locale->{-words};
		my $expect = $test_locale->{-expect};
		my $except = $test_locale->{-except};
		add_exceptions ($except);
		my $exceptions = get_exceptions;
		while (my ($key,$value) = each %$exceptions) {
			if (not exists $except->{$key}) {
				push (@errors,"exception '$key' => '$value' returned unexpectedly for locale '$locale_name'");
			} elsif ($except->{$key} ne $value) {
				push (@errors,"exception '$key' => '$value' returned unexpectedly for locale '$locale_name'");
			}
		}
		while (my ($key,$value) = each %$except) {
			if (not exists $exceptions->{$key}) {
				push (@errors,"exception '$key' => '$value' not returned for locale '$locale_name'");
			} elsif ($value ne $exceptions->{$key}) {
				push (@errors,"exception '$key' => '$value' not returned for locale '$locale_name'");
			}
		}
		my $stemmed = stem(@$words);
		if ($#$stemmed != $#$expect) {
			push(@errors, "different number of words returned than expected for locale '$locale_name'");
		}
		for (my $count=0;$count<=$#$stemmed;$count++) {
			my $expected = $expect->[$count];
			my $found    = $stemmed->[$count];
			if ($found ne $expected) {
				push (@errors,"expected '$expected', got '$found' for locale '$locale_name'");
			}
		}
		delete_exceptions(keys %$exceptions);
		$exceptions = get_exceptions;
		my @e_list = keys %$exceptions;
		if ($#e_list > -1) {
			push (@errors,"failed to delete exceptions: ".join(' ',@e_list));
		}
	}

	# Restore original locale
	set_locale($original_locale);
	my $new_locale = get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		push (@errors,"unable to restore locale to '$original_locale'");
	}

	# Send the results back
	join (', ',@errors);
}
