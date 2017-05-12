package Eixo::Base::Data;

use strict;
use Eixo::Base::Clase;

sub getDataBySections{
    my ($module) = @_;

    my $data = &getData($module);

    my $sections = {};
    my $section_name = undef;

    foreach my $l (split(/\n/, $data)){

        if($l =~ /^\s*\@\@(\w+)/){
            $section_name = $1;
        }
        else{
            $sections->{$section_name} .= "$l\n" if($section_name);
        }
    }

    $sections;
}

sub getData{
	my ($module) = @_;

	no strict 'refs';

	my $f = \*{$module . '::DATA'};

	return undef unless(defined($f));

	my $pos = tell($f);

	my $datos = join('', <$f>);

	seek($f, $pos, 0);

	return $datos;
}

1;
