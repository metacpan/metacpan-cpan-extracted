package Language::Indonesia;



use Exporter;
use Filter::Simple;
use strict;
our @ISA = 'Exporter';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Language::Indonesia ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# our %EXPORT_TAGS = ( 'all' => [ qw() ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );




our @EXPORT = qw(
cetak
potong
karakter
ordinal
enkripsi
heksadesimal
kecil_pertama
balikan
);

our $VERSION = '0.01';    # pre-alpha


sub cetak{
	return print @_;
}

sub format_cetakan{
	return printf @_;
}



# Functions for SCALARs or strings

sub potong{
	chop @_;
}

sub potongan{
	chomp @_;
}

sub karakter{
	chr $_[0];
}

sub ordinal{
	ord $_[0];
}

sub enkripsi{
	crypt $_[0], $_[1];
}

sub heksadesimal{
	hex $_[0];
}

sub oktal{
	oct $_[0];
}
sub kapital{
	uc @_;
}

sub kapital_pertama{
	ucfirst @_;
}

sub kecil{
	lc @_;
}

sub kecil_pertama{
	lcfirst $_[0];
}

sub panjang{
	length $_[0];
}

sub indeks{
	index $_[0], $_[1], $_[2];
}

sub pak{
	pack $_[0], $_[1];
}

sub balikan{
	reverse $_[0];
}

# "chop", ,  "pack",
#           "q/STRING/", "qq/STRING/", "reverse", "rindex", "sprintf", "substr", "tr///", "y///"

BEGIN{

# start filtering
FILTER{
	s/jika( *|\n*)*?\((.*?)\)/if ($2)/g;
	s/untuk( *|\n*)*?\(/for (/g;
	s/selagi( *|\n*)*?\(/while (/g;
	s/lakukan( *|\n*)*?\{/do {/g;

	}
}

1;

__END__


=head1 NAME

Language::Indonesia - Write Perl program in Bahasa Indonesia.

=head1 SYNOPSIS

  use Language::Indonesia;

=head1 DESCRIPTION

This module will help a lot of Indonesian programmers (most of them
aren't good enough in english) to write Perl program in Bahasa Indonesia.
This module also help introductory programmers to learn pseudo code

Convertion table:
    Indonesia          English
    =========          =======
    cetak              print
    format_cetakan     printf
    potongan           chomp
    potong             chop
    untuk              for
    selagi             while
    lakukan            do

etc..


=head1 MISC

Language::Indonesia is not completed yet, but I still keep improving this
module.

Bug reports, bugfix, addition, and correction are welcome.

=head1 AUTHOR

Daniel Sirait, E<lt>dns@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Sirait

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut


