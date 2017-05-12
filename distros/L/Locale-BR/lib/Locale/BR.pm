package Locale::BR;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT_OK = qw(code2state state2code all_state_codes all_state_names);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

=encoding utf8

=head1 NAME

Locale::BR - Identify Brazilian states by two-letter codes and vice-versa

=cut

our $VERSION = '0.02';

my %code_for_state  = ();
my %state_for_code  = ();

=head1 SYNOPSIS

    use Locale::BR  qw( :all );

    my $state = code2state('RJ');    # 'Rio de Janeiro'
    my $code  = state2code('Amapá'); # 'AM'
    
    my @states = all_state_names();
    my @codes  = all_state_codes();

=head1 EXPORT

This modules exports nothing by default, so you'll have to use the ':all' 
export tag in order to import the subroutines to your namespace. Or you can 
explicitly name any of the following subroutines:

=head2 code2state

Takes a state code and returns a string containing the name of the state. If 
the code is not a valid state code, returns C<undef>.

This subroutine is case insensitive. For instance, 'mg', 'Mg', 'MG' and even 
'mG' will all return 'Minas Gerais'.

=cut

sub code2state {
    my $code = uc shift;
    
    return $state_for_code{$code};
}

=head2 state2code

Takes a state name and returns a string containing its respective code. If the 
name is not a valid state name, returns C<undef>.

This subroutine is case insensitive and understands state names with and 
without accentuation. For instance, 'Amapá', 'amapá', 'Amapa' and 'amapa' will 
all return 'AP'.

=cut

sub state2code {
    my $state = uc shift;
    
    return $code_for_state{$state};
}

=head2 all_state_names

Returns an alphabetically ordered list of all Brazilian state names.

=cut

sub all_state_names {
    return sort values %state_for_code;
}

=head2 all_state_codes

Returns an alphabetically ordered list of all Brazilian state codes.

=cut

sub all_state_codes {
    return sort keys %state_for_code;
}

=head1 SEE ALSO

L<< Locale::Country >>

L<< Locale::US >>


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-locale-br at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-BR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::BR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-BR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Locale-BR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-BR>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-BR/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

{
    # initialization code
    local $_;
    
    while (<DATA>) {
        next unless /\S/;
        chomp;
        my ($code, $state, $state_alt) = split /:/;

        $state_for_code{$code} = $state;
        
        $code_for_state{uc $state}     = $code;
        if ($state_alt) {
            $code_for_state{uc $state_alt} = $code;
        }
    }
    close DATA;
}


42; # End of Locale::BR

__DATA__
AC:Acre
AL:Alagoas
AP:Amapá:Amapa
AM:Amazonas
BA:Bahia
CE:Ceará:Ceara
DF:Distrito Federal
ES:Espírito Santo:Espirito Santo
GO:Goiás:Goias
MA:Maranhão:Maranhao
MT:Mato Grosso
MS:Mato Grosso do Sul
MG:Minas Gerais
PA:Pará:Para
PB:Paraíba:Paraiba
PR:Paraná:Parana
PE:Pernambuco
PI:Piauí:Piaui
RJ:Rio de Janeiro
RN:Rio Grande do Norte
RS:Rio Grande do Sul
RO:Rondônia:Rondonia
RR:Roraima
SC:Santa Catarina
SP:São Paulo:Sao Paulo
SE:Sergipe
TO:Tocantins
