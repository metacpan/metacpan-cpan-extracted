package MPMinus::MainTools::TCD04; # $Id: TCD04.pm 122 2013-05-07 13:05:41Z minus $
use strict;

=head1 NAME

MPMinus::MainTools::TCD04 - TCD04 functions

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MPMinus::MainTools::TCD04;
    
    my $tcd04 = new MPMinus::MainTools::TCD04;
    
    my $code   = $tcd04->tcd04c('u');   # 1 char
    my $decode = $tcd04->tcd04d($code); # 1 word
    
    print $tcd04->tcd042string($tcd04->string2tcd04('hello world!'));

=head1 DESCRIPTION

TCD04 functions. Simple cryptografy's algorythm of D&D Corporation

=head1 METHODS

=over 8

=item B<tcd04c>

    my $code   = $tcd04->tcd04c('u');   # 1 char

=item B<tcd04d>

    my $decode = $tcd04->tcd04d($code); # 1 word

=item B<tcd042string>

    $tcd04->tcd042string($tcd04->string2tcd04('hello world!'));

=item B<string2tcd04>

    $tcd04->tcd042string($tcd04->string2tcd04('hello world!'));

=back

=head1 HISTORY

Version 1.00.0001 (08.01.2007)

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = 1.01;

sub new {
    my $class = shift;
    my $self = bless {},$class;
    return $self
}
sub string2tcd04 {
    my $self = shift;
    my $string = shift;
    return '' if length $string == 0;
    return join "",map {$_=$self->tcd04c($_)} split //,$string;
}
sub tcd042string {
    my $self = shift;
    my $string = shift;
    return '' if length $string == 0;
    my $ch2 ='';
    my $outstr = '';
    foreach (split //,$string) {
        $ch2.=$_;
        if (length($ch2) == 2) {
            $outstr.=$self->tcd04d($ch2);
            $ch2='';
        }
    }
    return $outstr;
}
sub tcd04c {
    my $self = shift;
    my $ch = shift;
    return '' if length $ch != 1;
    my $kod1 = ord($ch)>>4;
    my $kod2 = (ord($ch)&(2**4-1));
    return chr($kod1>0?int(rand 16)*15 + $kod1:0).chr($kod2>0?int(rand 16)*15 + $kod2:0);
}
sub tcd04d {
    my $self = shift;
    my $ch2 = shift;
    return '' if length $ch2 != 2;
    my ($kod1,$kod2) = map {(((ord($_)%15)==0)&&ord($_)>0)?15:ord($_)%15} split //,$ch2;
    return chr($kod1<<4|$kod2); #return sprintf "%X", $kod1<<4|$kod2;
}
1;
