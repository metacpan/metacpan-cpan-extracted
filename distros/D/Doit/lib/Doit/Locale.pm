# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Locale;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.021';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(locale_enable_locale) }

sub locale_enable_locale {
    my($self, $locale) = @_;
    my %locale;
    if (ref $locale eq 'ARRAY') {
	%locale = map{($_,1)} @$locale;
    } else {
	%locale = ($locale => 1);
    }

    ######################################################################
    # Is locale already present?
    my $is_locale_present = sub {
	open my $fh, '-|', 'locale', '-a'
	    or error "Error while running 'locale -a': $!";
	while(<$fh>) {
	    chomp;
	    if ($locale{$_}) {
		return 1;
	    }
	}
	close $fh
	    or error "Error while running 'locale -a': $!";
	return 0;
    };

    if ($is_locale_present->()) {
	return 0; # no change
    }

    ######################################################################
    # locale-gen (e.g. Ubuntu 12.03)
    if (-x "/usr/sbin/locale-gen" && !-e "/etc/locale.gen") {
	$self->system('locale-gen', $locale->[0]);
	return 1;
    }

    ######################################################################
    # /etc/locale.gen (e.g. Debian and Debian-like)
    if (-e "/etc/locale.gen") {
	my $all_locales = '(' . join('|', map { quotemeta $_ } keys %locale) . ')';
	my $changes = $self->change_file("/etc/locale.gen",
					 {match  => qr{^#\s+$all_locales(\s|$)},
					  action => sub { $_[0] =~ s{^#\s+}{}; },
					 },
					);
	if (!$changes) {
	    error "Cannot find prepared locale '$locale' in /etc/locale.gen";
	}
	$self->system('locale-gen');
	return 1;
    }

    ######################################################################
    # localedef (e.g RedHat, CentOS)
    if (-x "/usr/bin/localedef" && -e "/etc/redhat-release") {
	# It also exists on Debian-based systems, but works differently there.
    TRY_LOCALE: {
	    my @errors;
	    for my $try_locale (sort keys %locale) {
		if (my($lang_country, $charset) = $try_locale =~ m{^(.*)\.(.*)$}) {
		    my $stderr;
		    eval { $self->open3({errref => \$stderr}, '/usr/bin/localedef', '-c', '-i', $lang_country, '-f', $charset, $try_locale) };
		    if (!$@) {
			last TRY_LOCALE;
		    }
		    # an error, but maybe successful?
		    if ($is_locale_present->()) {
			last TRY_LOCALE;
		    }
		    push @errors, "Can't add '$try_locale': $stderr";
		} else {
		    push @errors, "Can't parse '$try_locale' as lang_COUNTRY.charset";
		}
	    }
	    error "Can't install locale. Errors:\n" . join("\n", @errors);
	}
	return 1;
    }

    ######################################################################
    # not implemented elsewhere
    error "Don't know how to enable locales on this system";
}

1;

__END__
