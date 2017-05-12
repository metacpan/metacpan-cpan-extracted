package List::Comprehensions;
use warnings;
use Carp;

# for comp2
use Alias qw(attr);
use Array::RefElem qw(av_push);
use PadWalker qw(peek_my);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(comp1 comp2 P PF);

$VERSION = 0.13;

=head1 NAME

List::Comprehensions - allows for list comprehensions in Perl.

=head1 SYNOPSIS

    use List::Comprehensions;
    use warnings;
    
    my @res = ();

    @res = comp1 { [ @_ ] } [0..4], [0..4], [0..4];

    no warnings 'once';
    @res = comp2 { [$i, $j, $k] }
        i => [0..4],
        j => [0..4],
        k => [0..4];

    # if strict 'vars' is on, use lexicals. eg:
    use strict 'vars';
    
    my ($i, $j, $k);
    @res = comp2 { [$i, $j, $k] }
        i => [0..4],
        j => [0..4],
        k => [0..4];
    
    # each being less efficient but equivelant to

    @res = ();
    for $i ( 0..4 ) {
        for $j ( 0..4 ) {
            for $k ( 0..4 ) {
                push @res, [$i, $j, $k];
            }
        }
    }

=head1 FUNCTIONS

=over 4

=cut

sub min_length_of {
	my $min = scalar( @{$_[0]} );

	my ($i, $len);
	for $i ( 1..$#_ ) {
		$len = scalar( @{$_[$i]} );
		$min = $len if $len < $min;
	}

	return $min;
}

sub zipn_flat {
	my @ret = ();
	my $len = $#_;
	my $min = min_length_of @_;
	
	my ($n, $i);
	for $n ( 0..($min - 1) ) {
		for $i ( 0..$len ) {
			push @ret, $_[$i]->[$n];
		}
	}

	return \@ret;
}

=item B<PF($$;@)>

For parallel comprehensions. ( flat zips according to minimal length )
    eg: PF( [0..5], ['a'..'z'] )
    is: [ 0, 'a', 1,'b' ... 5,'f' ]

=cut

sub PF($$;@) {
	return zipn_flat(@_);
}

sub zipn {
	my @ret = ();
	my $len = $#_;
	my $min = min_length_of @_;
	
	my ($n, $i);
	for $n ( 0..($min - 1) ) {
		$ret[$n] = [];
		for $i ( 0..$len ) {
			push @{$ret[$n]}, $_[$i]->[$n];
		}
	}

	return \@ret;
}

=item B<P($$;@)>

For parallel comprehensions. ( zips according to minimal length )
    eg: P( [0..5], ['a'..'z'] )
    is: [ [0,'a'], [1,'b'] ... [5,'f'] ]

=cut

sub P(@) {
	return zipn(@_);
}

sub run {
	my $i = shift;
	my $arg;
	if( $i + 1 <= $#sets ) {
		for $arg ( @{$sets[$i]} ) {
			$args[$i] = $arg;
			run($i + 1);
		}
	} else {
		SET:
		for $arg ( @{$sets[$i]} ) {
			$args[$i] = $arg;

			for $guard ( @guards ) {
				&$guard(@args) or next SET;
			}
			
			push @return, &$code(@args);
		}
	}
}

=item B<comp1(&@)>

Anonymous comprehensions (slighly faster)
    comp1 sub { }, arg, [arg]
    arg: array ref | guard subs

=cut

sub comp1(&@) {
	local $code = shift;
	local @guards;
	local @sets;
	local @args;

	for my $a (@_) {
		if( ref($a) ) {
			if( ref($a) eq 'CODE' ) {
				push @guards, $a;
			}
			elsif( ref($a) eq 'ARRAY' ) {
				push @sets, $a;
			}
			else {
				croak "expected ARRAY or CODE ref";
			}
		} else {
			croak "expected ARRAY or CODE ref";
		}
	}

	local @return;
	run 0;
	return @return;
}

=item B<comp2(&@)>

Named comprehensions
    comp2 sub { }, arg, [arg]
    arg: [name => ] array ref | guard subs

=cut

sub comp2(&@) {
	local $code = shift;
	local @guards;
	local @sets;
	local @args;

	my @aliases;
	my %aliased;

	my $their_lexicals = peek_my(1);
	my %overridden_lexicals = ();

	while( my $arg = shift @_ ) {
		if( ref($arg) ) {
			if( ref($arg) eq 'CODE' ) {
				push @guards, $arg;
			}
			elsif( ref($arg) eq 'ARRAY' ) {
				push @args, 0;

				push @sets, $arg;
			}
			else {
				croak "expected ARRAY or CODE ref";
			}
		}
		else {
			if( ref($_[0]) eq 'ARRAY' ) {
				if( exists $their_lexicals->{"\$$arg"} ) {
					my $value = $their_lexicals->{"\$$arg"};
					$overridden_lexicals{"\$$arg"} = $$value;
					av_push(@args, $$value);
				}
				else {
					push @aliases, $arg;
					av_push(@args, $aliased{$aliases[-1]});
				}

				$args[-1] = 0;
				push @sets, shift();
			}
			else {
				croak "expected ARRAY or CODE ref";
			}
		}
	}

	my ($package) = caller ();
	$Alias::AttrPrefix = $package . "::";
	
	attr \%aliased;

	local @return;
	
	run 0;
	
	# restore lexicals
	while( my ($k, $v) = each %overridden_lexicals ) {
		${$their_lexicals->{$k}} = $v;
	}
	
	return @return;
}

=back

=head1 AUTHOR

Jeremy Cortner E<lt>F<jcortner@cvol.net>E<gt>

=head1 COPYRIGHT

Copyright (C) 2003, Jeremy Cortner

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;

