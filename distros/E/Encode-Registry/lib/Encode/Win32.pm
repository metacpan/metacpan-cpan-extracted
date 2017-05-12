package Encode::Win32;
use Win32::API;

use strict;
BEGIN {
    if ($^O ne 'MSWin32')
    { die "__PACKAGE__ is a Win32 only package"; }
}

our $fdec = Win32::API->new('Kernel32', 'MultiByteToWideChar', [qw(N N P N P N)], 'N');
our $fenc = Win32::API->new('Kernel32', 'WideCharToMultiByte', [qw(N N P N P N P P)], 'N');


sub new
{
    my ($class, $enc) = @_;
    my ($self) = {'name' => $enc};

    return bless $self, ref $class || $class;
}

sub name
{ return $_[0]->{'name'}; }

sub encode
{
    my ($self, $str, $check) = @_;
    my ($instr) = pack('S*', unpack('U*', $str), 0);
    my ($spaces, $len, $res);

#    $len = $fenc->Call($self->{'name'}, 0, $instr, -1, 0, 0, 0, 0)
#        || return undef;

    $len = length($str) * 1.1;

    $spaces = ' ' x ($len + 2);
    $fenc->Call($self->{'name'}, 0, $instr, -1, $spaces, length($spaces), 0, 0)
        || return undef;

    $spaces =~ s/\000.*$//o;
    $res = pack('U0a*', $spaces);
    return $spaces;
}

sub decode
{
    my ($self, $str, $check) = @_;
    $str .= "\000";
    my ($spaces, $res, $len);

#    $len = $fdec->Call($self->{'name'}, 0, $str, length($str), 0, 0)
#        || return undef;

    $len = length($str) * 2.1;

    $spaces = ' ' x ($len + 2);
    $fdec->Call($self->{'name'}, 0, $str, length($str), $spaces, length($spaces))
        || return undef;
    $res = pack('U0U*', unpack('S*', $spaces));
    $res =~ s/\000.*$//o;
    undef $spaces;
    return $res;
}

sub new_sequence
{ return $_[0]; }

