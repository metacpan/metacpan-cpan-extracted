#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Stripper;


{    
    my $stripper = new MKDoc::XML::Stripper;
    $stripper->load_def ('mkdoc16');

    # check that a few values are really there
    ok ($stripper->{area}->{'href'});
    ok ($stripper->{dfn}->{'lang'});
    ok ($stripper->{h3}->{'id'});
    ok ($stripper->{h6}->{'xml:lang'});
    ok ($stripper->{img}->{'lang'});
    ok ($stripper->{legend}->{'class'});
    ok ($stripper->{object}->{'dir'});
    ok ($stripper->{span}->{'dir'});
    ok ($stripper->{th}->{'id'});
}


1;


__END__
