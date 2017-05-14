use strict;
package Envy::UI;
use integer;
use base 'Exporter';
use vars qw(@EXPORT_OK @Reserved);
@EXPORT_OK = qw(cmd_2re alength);

# envies should not use these names...
@Reserved = qw(show paths load reload un unload list help);

sub cmd_2re {
    my $cmd = shift;
    $cmd ||= '*';
    $cmd =~ tr [\[\]\{\}\(\)\|\$\#\?] //d;
    $cmd =~ s/\./'\.'/eg;
    $cmd =~ s/\*/'.*'/eg;
    $cmd
}

sub alength {
    my $l=0;
    for (@_) { $l = length if length > $l }
    $l;
}

sub Envy::DB::all_matching {
    my ($db, $match) = @_;
    my ($mo, $ld) = $db->status2();
    my %ok;
    for my $k (keys %$mo) {
	if ($k =~ /$match/i and $k !~ /^\./ and $mo->{$k} !~ /\.priv/) {
	    $ok{$k} = $mo->{$k};
	}
    }
    (\%ok, $ld)
}

sub Envy::DB::try_match {
    my ($db, $cmd) = @_;
    my ($mo, $ld) = $db->status2();
    my @mo;
    foreach (sort keys %$mo){
	next if /^\./;
	next if $mo->{$_} =~ /\.priv/; # hide .priv directory files
	push @mo, $_;
    }
    my @exact = sort grep /^$cmd$/i, @mo;
    return (\@exact, $ld)
	if @exact == 1;
    @mo = grep /$cmd/i, @mo;
    $db->check_fuzzy($mo[0])
	if @mo == 1;
    (\@mo, $ld);
}

1;
