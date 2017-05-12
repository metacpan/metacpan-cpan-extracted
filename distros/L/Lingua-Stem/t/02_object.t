#!/usr/bin/perl -w

use strict;
use lib './blib';
use Lingua::Stem;

my @do_tests=(1..3);

my $test_subs = { 
       1 => { -code => \&test1, -desc => 'locale        ' },
       2 => { -code => \&test2, -desc => 'stem          ' },
       3 => { -code => \&test3, -desc => 'exceptions    ' },
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
	my $stemmer = Lingua::Stem->new;
	my $original_locale  = $stemmer->get_locale;

	my @test_locales = ('En','En-Us','En-Uk', 'En-Broken');
	my @errors = ();
	foreach my $test_locale (@test_locales,$test_locales[0]) {
		$stemmer->set_locale($test_locale);
		my $new_locale  = $stemmer->get_locale;
		if (lc($new_locale) ne lc($test_locale)) {
			push (@errors,"unable to change locale to '$test_locale'");
		}
	}

	# Restore original locale
	$stemmer->set_locale($original_locale);
	my $new_locale = $stemmer->get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		push (@errors,"unable to restore locale to '$original_locale'");
	}
	# Send the results back
	join (', ',@errors);
}

########################################
# Stem                                 #
########################################
sub test2 {
	my $stemmer = Lingua::Stem->new;
	my $original_locale  = $stemmer->get_locale;

	my $test_locales = {
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
	};
	my @locales = sort keys %$test_locales;
	my @errors  = ();
	foreach my $locale_name (@locales) {
		my $test_locale = $test_locales->{$locale_name};
		$stemmer->set_locale($locale_name);
		my $new_locale  = $stemmer->get_locale;
		if (lc($new_locale) ne lc($locale_name)) {
			push (@errors,"unable to change locale to '$locale_name'");
		}
		my $words  = $test_locale->{-words};
		my $expect = $test_locale->{-expect};
		my $stemmed = $stemmer->stem(@$words);
		if ($#$stemmed != $#$expect) {
			push (@errors,"different number of words returned than expected");
		}
		for (my $count=0;$count<=$#$stemmed;$count++) {
			my $expected = $expect->[$count];
			my $found    = $stemmed->[$count];
			if ($found ne $expected) {
				push (@errors,"expected '$expected', got '$found' for locale '$locale_name'");
			}
		}
	}

	# Restore original locale
	$stemmer->set_locale($original_locale);
	my $new_locale = $stemmer->get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		push(@errors, "unable to restore locale to '$original_locale'");
	}
	join(', ',@errors);
}

########################################
# Exceptions                           #
########################################
sub test3 {
	my $stemmer = Lingua::Stem->new;
	my $original_locale  = $stemmer->get_locale;

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
		$stemmer->set_locale($locale_name);
		my $new_locale  = $stemmer->get_locale;
		if (lc($new_locale) ne lc($locale_name)) {
			push(@errors,"unable to change locale to '$test_locale'");
			next;
		}
		my $words  = $test_locale->{-words};
		my $expect = $test_locale->{-expect};
		my $except = $test_locale->{-except};
		$stemmer->add_exceptions ($except);
		my $exceptions = $stemmer->get_exceptions;
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
		my $stemmed = $stemmer->stem(@$words);
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
		$stemmer->delete_exceptions(keys %$exceptions);
		$exceptions = $stemmer->get_exceptions;
		my @e_list = keys %$exceptions;
		if ($#e_list > -1) {
			push (@errors,"failed to delete exceptions: ".join(' ',@e_list));
		}
	}

	# Restore original locale
	$stemmer->set_locale($original_locale);
	my $new_locale = $stemmer->get_locale;
	if (lc($new_locale) ne lc($original_locale)) {
		push (@errors,"unable to restore locale to '$original_locale'");
	}

	# Send the results back
	join (', ',@errors);
}
