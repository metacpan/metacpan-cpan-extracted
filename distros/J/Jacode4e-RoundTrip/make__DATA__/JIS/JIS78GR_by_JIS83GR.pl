######################################################################
#
# JIS78GR_by_JIS83GR.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

require 'JIS/JIS78GL_by_JIS83GL.pl';

my %JIS78GR_by_JIS83GR = ();
for my $jis83 (keys_of_JIS78GL_by_JIS83GL()) {
    $JIS78GR_by_JIS83GR{gr($jis83)} = gr(JIS78GL_by_JIS83GL($jis83));
}

sub gr {
    my($jis) = @_;
    my %gr = qw( 2 A 3 B 4 C 5 D 6 E 7 F );
    $jis =~ s/^([234567])(.)([234567])(.)$/$gr{$1}$2$gr{$3}$4/;
    return $jis;
}

sub JIS78GR_by_JIS83GR {
    my($jis83) = @_;
    return $JIS78GR_by_JIS83GR{$jis83};
}

sub keys_of_JIS78GR_by_JIS83GR {
    return keys %JIS78GR_by_JIS83GR;
}

sub values_of_JIS78GR_by_JIS83GR {
    return values %JIS78GR_by_JIS83GR;
}

1;

__END__
