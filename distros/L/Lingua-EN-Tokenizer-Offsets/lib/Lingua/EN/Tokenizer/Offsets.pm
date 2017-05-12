use strict;
use warnings;
package Lingua::EN::Tokenizer::Offsets;
{
  $Lingua::EN::Tokenizer::Offsets::VERSION = '0.03';
}
use utf8::all;
use Data::Dump qw/dump/;
use feature qw/say/;

use base 'Exporter';
our @EXPORT_OK = qw/
					initial_offsets
					token_offsets
					adjust_offsets
					get_tokens
					tokenize
					offsets2tokens
				/;


# ABSTRACT: Finds word (token) boundaries, and returns their offsets.


sub tokenize {
	my ($text) = @_;
	my $tokens = get_tokens($text);
	return join ' ',@$tokens;
}



sub token_offsets {
    my ($text) = @_;
    return [] unless defined $text;
    my $offsets = initial_offsets($text);
       $offsets = adjust_offsets($text,$offsets);
    return $offsets;
}



sub get_tokens {
    my ($text)  = @_;
    my $offsets = token_offsets($text);
    my $tokens  = offsets2tokens($text,$offsets);
    return $tokens;
}




sub adjust_offsets {
    my ($text,$offsets) = @_;
	$text = $$text if ref($text);
    my $size = @$offsets;
    for(my $i=0; $i<$size; $i++){
        my $start  = $offsets->[$i][0];
        my $end    = $offsets->[$i][1];
        my $length = $end - $start;
		if ($length <= 0){
			delete $offsets->[$i];
			next;
		}
        my $s = substr($text,$start,$length);
        if ($s =~ /^\s*$/){
            delete $offsets->[$i];
            next;
        }
        $s =~ /^(\s*).*?(\s*)$/s;
        if(defined($1)){ $start += length($1); }
        if(defined($2)){ $end   -= length($2); }
        $offsets->[$i] = [$start, $end];
    }
    my $new_offsets = [ grep { defined } @$offsets ];
    return $new_offsets;
}


sub initial_offsets {
	my ($text) = @_;
	$text = $$text if ref($text);
	my $end;
	my $text_end = length($text);
	my $offsets = [[0,$text_end]];

	# token patterns
	my @patterns = (
		qr{([^\p{IsAlnum}\s\.\'\`\,\-’])},
		qr{(?<!\p{IsN})(,)(?!\d)},
		qr{(?<=\p{IsN})(,)(?!\d)},
		qr{(?<!\p{IsN})(,)(?=\d)},
		qr{(?<!\p{isAlpha})(['`’])(?!\p{isAlpha})},
		qr{(?<!\p{isAlpha})(['`’])(?=\p{isAlpha})},
		qr{(?<=\p{isAlpha})(['`’])(?!\p{isAlpha})},
		qr{(?<=\p{isAlpha})()['`’](?=\p{isAlpha})},
		qr{(?:^|\s)(\S+)(?:$|\s)},
		qr{(?:^|[^\.])(\.\.+)(?:$|[^\.])},

		qr{(?<=\p{isAlpha})['`]()(?=\p{isAlpha})},

	);

	for my $pat (@patterns){
		my $size = @$offsets;
    	for(my $i=0; $i<$size; $i++){
			my $start  = $offsets->[$i][0];
			my $length = $offsets->[$i][1]-$start;
			my $s = substr($text,$start,$length);

			my $split_points = [];

			if($s =~ /^$pat(?!$)/g){
   				my $first = $-[1];
                push @$split_points,[$start+$first,$start+$first];
				my $second = $+[1];
                push @$split_points,[$start+$second,$start+$second] if $first != $second;
			}
			while($s =~ /(?<!^)$pat(?!$)/g){
   				my $first = $-[1];
                push @$split_points,[$start+$first,$start+$first];
				my $second = $+[1];
                push @$split_points,[$start+$second,$start+$second] if $first != $second;
			}
			if($s =~ /(?<!^)$pat$/g){
				my $first = $-[1];
                push @$split_points,[$start+$first,$start+$first];
				my $second = $+[1];
                push @$split_points,[$start+$second,$start+$second] if $first != $second;
			}

			_split_tokens($offsets,$i,[ sort { $a->[0] <=> $b->[0] } @$split_points ]) if @$split_points;
		}
	}
	return _nonbp($text,$offsets);
}

sub _split_tokens {
    my ($offsets,$i,$split_points) = @_;
    my ($end,$start) = @{shift @$split_points};
    my $last = $offsets->[$i][1];
    $offsets->[$i][1] = $end;
    while(my $p = shift @$split_points){
        push @$offsets, [$start,$p->[0]] unless $start == $p->[0];
        $start = $p->[1];
    }
    push @$offsets, [$start, $last];
}



sub offsets2tokens {
    my ($text, $offsets) = @_;
	$text = $$text if ref($text);
    my $tokens = [];
    foreach my $o ( sort {$a->[0] <=> $b->[0]} @$offsets) {
        my $start = $o->[0];
        my $length = $o->[1]-$o->[0];
        push @$tokens, substr($text,$start,$length);
    }
    return $tokens;
}


sub _load_prefixes {
	my ($prefixref) = @_;
	$INC{'Lingua/EN/Tokenizer/Offsets.pm'} =~ m{\.pm$};
	my $prefixfile = "$`/nonbreaking_prefix.en";
	
	open my $prefix, '<', $prefixfile or die "Could not open file '$prefixfile'!";
	while (<$prefix>) {
		next if /^#/ or /^\s*$/;
		my $item = $_;
		chomp($item);
		if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) { $prefixref->{$1} = 2; } 
		else { $prefixref->{$item} = 1; }
	}
	close($prefix);
}

sub _nonbp {
    my ($text,$offsets) = @_;
	$text = $$text if ref($text);
	my $nonbpref = {};
	_load_prefixes($nonbpref);
	my $new_offsets = adjust_offsets($text,$offsets);
    $new_offsets = [ sort { $a->[0] <=> $b->[0] } @$new_offsets ];
    my $size = @$new_offsets;
	my $extra = [];
    for(my $i=0; $i<$size-1; $i++){
        my $start  = $new_offsets->[$i][0];
        my $end    = $new_offsets->[$i][1];
        my $length = $end-$start;
        my $s = substr($text,$start,$length);
        my $j=$i+1;
		my $t = substr($text,$new_offsets->[$j][0], $new_offsets->[$j][1]-$new_offsets->[$j][0]);

		if($s =~ /^(\S+)\.\s?$/){
			my $pre = $1;
			unless (
					($pre =~ /\./ 		and $pre =~ /\p{IsAlpha}/)
				or	($nonbpref->{$pre} 	and $nonbpref->{$pre}==1)
				or	($t =~ /^[\p{IsLower}]/)
				or	(
						$nonbpref->{$pre}
					and	$nonbpref->{$pre}==2
					and $t =~ /^\d+/)
			){
				$s =~ /^(.*[^\s\.])\.\s*?$/;
				next unless defined($+[1]);
				push @$extra, [$start+$+[1],$end];
				$new_offsets->[$i][1] = $start+$+[1];
			}
		}
	}
	return [ sort { $a->[0] <=> $b->[0] } (@$new_offsets,@$extra) ];
}
			
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::EN::Tokenizer::Offsets - Finds word (token) boundaries, and returns their offsets.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Lingua::EN::Tokenizer::Offsets qw/token_offsets get_tokens/;
     
    my $str <<END
    Hey! Mr. Tambourine Man, play a song for me.
    I'm not sleepy and there is no place I’m going to.
    END

    my $offsets = token_offsets($str);     ## Get the offsets.
    foreach my $o (@$offsets) {
        my $start  = $o->[0];
        my $length = $o->[1]-$o->[0];

        my $token = substr($text,$start,$length)  ## Get a token.
        # ...
    }

    ### or

    my $tokens = get_tokens($str);     
    foreach my $token (@$tokens) {
        ## do something with $token
    }

=head1 METHODS

=head2 tokenize($text)

Returns a tokenized version of $text (space-separated tokens).

$text can be a scalar or a scalar reference.

=head2 get_offsets($text)

Returns a reference to an array containin pairs of character
offsets, corresponding to the start and end positions of tokens
from $text.

$text can be a scalar or a scalar reference.

=head2 get_tokens($text)

Splits $text it into tokens, returning an array reference.

$text can be a scalar or a scalar reference.

=head2 adjust_offsets($text,$offsets)

Minor adjusts to offsets (leading/trailing whitespace, etc)

$text can be a scalar or a scalar reference.

=head2 initial_offsets($text)

First naive delimitation of tokens.

$text can be a scalar or a scalar reference.

=head2 offsets2tokens($text,$offsets)

Given a list of token boundaries offsets and a text, returns an array with the text split into tokens.

$text can be a scalar or a scalar reference.

=head1 ACKNOWLEDGEMENTS

Based on the original tokenizer written by Josh Schroeder and provided by Europarl L<http://www.statmt.org/europarl/>.

=head1 SEE ALSO

L<Lingua::EN::Sentence::Offsets>, L<Lingua::FreeLing3::Tokenizer>

=head1 AUTHOR

André Santos <andrefs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andre Santos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
