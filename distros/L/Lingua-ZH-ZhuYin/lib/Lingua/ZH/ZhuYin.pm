package Lingua::ZH::ZhuYin;

use warnings;
use strict;
use utf8;

=head1 NAME

Lingua::ZH::ZhuYin - The great new Lingua::ZH::ZhuYin!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
our $AUTOLOAD;
our %ok_field;
use Encode qw/decode/;
use List::Util qw/min max/;
use Lingua::ZH::ZhuYin::Dict;


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Lingua::ZH::ZhuYin;

    my $foo = Lingua::ZH::ZhuYin->new();
    my $zhuyin = $foo->zhuyin($phrase);
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 AUTOLOAD

=cut

for my $attr ( qw(dictfile) ) { $ok_field{$attr}++; } 

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return if $attr eq 'DESTROY';   

    if ($ok_field{$attr}) {
	$self->{lc $attr} = shift if @_;
	return $self->{lc $attr};
    } else {
	my $superior = "SUPER::$attr";
	$self->$superior(@_);
    } 
}

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = {
	dictfile => undef,
    };
    if(@_) {
	my %arg = @_;

	foreach (keys %arg) {
	    $self->{lc($_)} = $arg{$_};
	}
    }
    bless ($self, $class);
    return($self);
}

=head2 zhuyin

=cut

sub zhuyin {
    my $self = shift;
    my $word = shift;
    die "DictFile does not exist" unless $self->dictfile;
    my $utf8word = decode('utf8',$word);
    my @zhuyins = $self->guess_zhuyin($word);
    push @zhuyins , $utf8word if (! @zhuyins and length($utf8word) == 1);
    return '' if $zhuyins[0] eq '0';
    warn 'no zhuyin found: '.$word if ! @zhuyins;
    return \@zhuyins;
}

=head2 guess_zhuyin

=cut

sub guess_zhuyin {
    my $self = shift;
    my $word = shift;
    # perform guess zhuyin from ABCDE, ABCD E, ABC DE, AB CDE, A BCDE
    my @zhuyins;
    my $Dict = Lingua::ZH::ZhuYin::Dict->new($self->dictfile);
    for my $i (0..(length($word) - 1)) {
	@zhuyins = ();
	my $offset = length($word) - $i;
	my $pre_word = substr($word,0,$offset);
	my $post_word = '';
	$post_word = substr($word,$offset) if $i > 0;
	my $skip = 1;
	die "word error " unless $word eq $pre_word.$post_word;
	if ($pre_word and $pre_word ne "") {
	    my @pre_zhuyins = $Dict->queryZhuYin($pre_word);
	    $skip = 0 if @pre_zhuyins;
	    push @zhuyins, @pre_zhuyins;
	}
	if ($skip == 0 and $post_word and $post_word ne "") {
	    $skip = 1;
	    my @post_zhuyins = $Dict->queryZhuYin($post_word);
	    $skip = 0 if @post_zhuyins;
	    my @tmp_zhuyins = ();
	    foreach my $j (0..$#zhuyins) {
		foreach my $yin (@post_zhuyins) {
		    push @tmp_zhuyins, $zhuyins[$j] ."  ". $yin;
		}
	    }
	    @zhuyins = @tmp_zhuyins;
	}
	return @zhuyins if $skip == 0;
    }

    return if length($word) == 1;
    # preform A B C D E, if each term has unique zhuyin, then we done,
    # otherwise need further process
    my @array = ();
    my @ambig = ();
    @zhuyins = ();
    my $skip = 0;
    for my $i (0..(length($word) - 1)) {
	my $unichar = substr($word,$i,1);
	my @uni_zhuyins = $Dict->queryZhuYin($unichar);
	return '0' unless @uni_zhuyins;
	if (scalar @uni_zhuyins != 1) {
	    $array[$i] = 1;
	    push @ambig, $i;
	    $skip = 1;
	} else {
	    $array[$i] = 0;
	    $zhuyins[$i] = $uni_zhuyins[0];
	}
    }
    return @zhuyins if $skip == 0;

    # if B is amibiguos, we chcek AB, BC, ABC, BCD ...
    # otherwise, return the first one
    for my $amb (@ambig) {
	my $max_length = min (max (length($word) - $amb, $amb), 4); # at most check 4-gram
	my $not_found = 1;
	my $len = 2;
	while ($not_found && $len <= $max_length) {
	    my $pos_b = max (0, $amb - $len + 1);
	    my $pos_e = min (length($word), $amb);
	    for my $pos ($pos_b..$pos_e) {
		next if $not_found == 0;
		my @ngram_zhuyins = $Dict->queryZhuYin(substr($word,$pos,$len));
		if (scalar @ngram_zhuyins == 1) { # yatta !!!
		    my @zhuyin_array = split /  /,$ngram_zhuyins[0];
		    $zhuyins[$amb] = $zhuyin_array[$amb-$pos];
		    $not_found = 0;
		}
	    }
	    $len++;
	}
	if ($not_found) { # still not found
	    my $unichar = substr($word,$amb,1);
	    my @uni_zhuyins = $Dict->queryZhuYin($unichar);
	    $zhuyins[$amb] = $uni_zhuyins[0];
	}
    }
    return join "  ",@zhuyins;
}

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-zh-zhuyin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-ZH-ZhuYin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::ZH::ZhuYin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-ZH-ZhuYin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-ZH-ZhuYin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-ZH-ZhuYin>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-ZH-ZhuYin>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Cheng-Lung Sung, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Lingua::ZH::ZhuYin
