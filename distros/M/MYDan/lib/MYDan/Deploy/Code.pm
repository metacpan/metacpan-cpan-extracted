package MYDan::Deploy::Code;
use strict;
use warnings;
use Carp;

use Data::Dumper;

sub new
{
    my ( $class, $path, $code ) = splice @_;

    confess "no code" unless $code;
    confess "no code" if ref $code ne 'HASH';

    for my $name ( keys %$code )
    {

        $code->{$name} = do "$path/$name";
        confess "load code $name error: $@" if $@;

        confess "$path/$name not CODE" if ref $code->{$name} ne 'CODE';
    }

    bless $code, ref $class || $class;
}

sub run
{
    my ( $this, $name,  %param ) = @_;
    &{$this->{$name}}( %param );
    
}
1;
