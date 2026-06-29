package Locale::CA;

use warnings;
use strict;
use Carp;
use Data::Section::Simple;
use I18N::LangTags::Detect;

=head1 NAME

Locale::CA - two letter codes for province identification in Canada and vice versa

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

my %_cache;

=head1 SYNOPSIS

    use Locale::CA;

    my $u = Locale::CA->new();

    # Returns the French names of the provinces if $LANG starts with 'fr' or
    #	the lang parameter is set to 'fr'
    print $u->{code2province}{'ON'}, "\n";	# prints ONTARIO
    print $u->{province2code}{'ONTARIO'}, "\n";	# prints ON

    my @province = $u->all_province_names();
    my @code = $u->all_province_codes();

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Locale::CA object.

Can be called both as a class method (Locale::CA->new()) and as an object method ($object->new()).

=cut

sub new {
	my $proto = shift;
	my $class;

	if(!defined($proto)) {
		$class = __PACKAGE__;
	} elsif(ref($proto)) {
		$class = ref($proto);
	} elsif(eval { $proto->isa(__PACKAGE__) }) {
		$class = $proto;
	} else {
		# Function-call style with a non-class first arg — treat as argument
		unshift @_, $proto;
		$class = __PACKAGE__;
	}

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} elsif(@_ == 1) {
		$params{'lang'} = shift;
	} else {
		Carp::croak(__PACKAGE__, ': Invalid arguments passed to new()');
	}

	my $lang;
	if(defined(my $explicit = $params{'lang'})) {
		$lang = lc($explicit);
		Carp::croak("lang can only be one of 'en' or 'fr', given $explicit")
			unless $lang eq 'en' || $lang eq 'fr';
	} else {
		my $detected = _get_language();
		if(defined($detected) && ($detected eq 'en' || $detected eq 'fr')) {
			$lang = $detected;
		} else {
			$lang = 'en';
		}
	}

	unless(exists $_cache{$lang}) {
		my $data = Data::Section::Simple::get_data_section("provinces_$lang");
		Carp::croak("Internal error: data section 'provinces_$lang' not found")
			unless defined $data;

		my(%c2p, %p2c);
		for(split /\n/, $data) {
			next unless /\S/;
			my($code, $province) = split /:/, $_, 2;
			next unless defined $code && defined $province;
			$c2p{$code} = $province;
			$p2c{$province} = $code;
		}
		$_cache{$lang} = { code2province => \%c2p, province2code => \%p2c };
	}

	my $self = {
		code2province => { %{$_cache{$lang}{code2province}} },
		province2code => { %{$_cache{$lang}{province2code}} },
	};

	return bless $self, $class;
}

# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
# https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html
sub _get_language {
	for my $tag (I18N::LangTags::Detect::detect()) {
		if ($tag =~ /^([a-z]{2})/i) {
			return lc $1;
		}
	}
	return 'en' if ($ENV{LANG} && $ENV{LANG} =~ /^C(?:\.|$)/);
	return;	# undef
}

=head2 all_province_codes

Returns an array (not arrayref) of all province codes in alphabetical form.

=cut

sub all_province_codes {
	my $self = shift;

	return(sort keys %{$self->{code2province}});
}

=head2 all_province_names

Returns an array (not arrayref) of all province names in alphabetical form

=cut

sub all_province_names {
	my $self = shift;

	return(sort keys %{$self->{province2code}});
}

=head2 $self->{code2province}

This is a hashref which has two-letter province names as the key and the long
name as the value.

=head2 $self->{province2code}

This is a hashref which has the long name as the key and the two-letter
province name as the value.

=head1 SEE ALSO

L<Locale::Country>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=over 4

=item * Province names are returned in upper-case (C<uc()>) format.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::CA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-CA>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-CA/>

=back

=head1 ACKNOWLEDGEMENTS

Based on L<Locale::US> - Copyright (c) 2002 - C<< $present >> Terrence Brannon.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Locale::CA

# Put the one you want to expand in code2province second
#	so it overwrites the other when it's loaded

__DATA__
@@ provinces_en
AB:ALBT.
AB:ALBERTA
BC:BRITISH COLUMBIA
MB:MANITOBA
NB:NEW BRUNSWICK
NL:NEWFOUNDLAND
NL:NEWFOUNDLAND AND LABRADOR
NT:NORTHWEST TERRITORIES
NS:NOVA SCOTIA
NU:NUNAVUT
ON:ONTARIO
PE:PRINCE EDWARD ISLAND
QC:QUEBEC
SK:SASKATCHEWAN
YT:YUKON
@@ provinces_fr
AB:ALBT.
AB:ALTA.
AB:ALBERTA
BC:COLOMBIE-BRITANNIQUE
MB:MANITOBA
NB:NOUVEAU-BRUNSWICK
NL:TERRE-NEUVE
NL:TERRE-NEUVE-ET-LABRADOR
NT:TERRITOIRES DU NORD-OUEST
NS:NOUVELLE-ÉCOSSE
NU:NUNAVUT
ON:ONTARIO
PE:ÎLE-DU-PRINCE-ÉDOUARD
QC:QUÉBEC
SK:SASKATCHEWAN
YT:YUKON
__END__
