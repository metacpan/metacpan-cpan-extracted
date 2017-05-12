package Lingua::LA::Stemmer;

use strict;
our $VERSION = '0.01';

our %que_words = map {$_=>1} qw( atque quoque neque itaque absque apsque abusque
adaeque adusque denique deque susque oblique peraeque plenisque
quandoque quisque quaeque cuiusque cuique quemque quamque quaque
quique quorumque quarumque quibusque quosque quasque quotusquisque
quousque ubique undique usque uterque utique utroque utribique torque
coque concoque contorque detorque decoque excoque extorque obtorque
optorque retorque recoque attorque incoque intorque praetorque );

our @noun_adj_suffix = qw( ibus ius ae am as em es ia is nt os ud um
us a e i o u );

our @verb_suffix = qw( iuntur beris erunt untur iunt mini ntur stis
bor ero mur mus ris sti tis tur unt bo ns nt ri m r s t );

our %verb_suffix_transform_dict = qw( iuntur i erunt i untur i iunt i
 unt i beris bi bor bi bo bi ero eri );

sub stem {
    my @words = ref($_[0]) ? @{$_[0]} : @_ ;
    my @stems;
    my $suffix;

  STEM:
    foreach my $word ( @words ){

	# converts jv to iu
	$word =~ tr/jv/iu/;

	# removes '-que'
	if( $word =~ /que$/o ){
	    if( $que_words{$word} ){
		push @stems, $word;
		next STEM;
	    }
	    else{
		$word =~ s/que$//o;
	    }
	}

	for $suffix ( @noun_adj_suffix ){
	    if( $word =~ /$suffix$/ ){
		if(length( $word ) - length ($suffix) >= 2){
		    $word =~ s/$suffix$//;
		    push @stems, $word;
		}
		else {
		    push @stems, $word;
		}
		next STEM;
	    }
	}

	for $suffix ( @verb_suffix ){
	    if( $word =~ /$suffix$/ ){
		if( $word =~ /$suffix$/ ){
		    foreach my $term (keys %verb_suffix_transform_dict){
			if( $word =~ s/$term$/$verb_suffix_transform_dict{$term}/ ){
			    last;
			}
		    }
		    if(length( $word ) - length ($suffix) >= 2){
			$word =~ s/$suffix$//;
			push @stems, $word;
		    }
		    else {
			push @stems, $word;
		    }
		    next STEM;
		}
	    }
	}
        push @stems, $word;
    }
    wantarray ? @stems : \@stems;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::LA::Stemmer - Stemmer for Latin

=head1 SYNOPSIS

 use Lingua::LA::Stemmer;

 Lingua::LA::Stemmer::stem(\@words);

 # or

 Lingua::LA::Stemmer::stem(@words);


=head1 DESCRIPTION

This is a coarse stemming package for latin language. Words are filtered according to the following steps.

=over 4

=item o converting 'j' or 'v' to 'i' or 'u'

=item o removing -que

=item o matching the end of word against the noun or adjective suffixes

=item o matching the end of word against the verb suffixes

=back

Of course, it's not perfect. Any suggestion is always welcomed to better this package.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
