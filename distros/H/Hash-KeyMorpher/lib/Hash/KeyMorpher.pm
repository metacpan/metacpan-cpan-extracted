package Hash::KeyMorpher;

=pod

=head1 NAME

Hash::KeyMorpher - Deep converter for naming conventions of hash keys

=head1 DESCRIPTION

Deeply change the nameing conventions for keys in hash structures, or simply change strings between naming conventions.
Converts to CamelCase, mixedCamel, delimited_string, UPPER, LOWER


=head1 SYNOPSYS

    use Hash::KeyMorpher; # import all, or
    use Hash::KeyMorpher qw (key_morph to_camel to_mixed  to_under to_delim); # import specific subs

    # To use the string converters:
    $res = to_camel('my_string'); # MyString
    $res = to_mixed('my_string'); # myString
    $res = to_under('myString');  # my_string
    $res = to_delim('myString','-');  # my-string

    # To morph keys in a hash, key_morph($hash,$method,$delim);
    # method is one of camel,mixed,under,delim,upper,lower
    $h1 = { 'level_one' => { 'LevelTwo' => 'foo' } };
    $mixed = key_morph($h1,'mixed');  # { 'levelOne' => { 'levelTwo' => 'foo' } };
    $delim = key_morph($h1,'delim','-');  # { 'level-one' => { 'level-two' => 'foo' } };
    
    # To morph acceccor keys
    $obj = Hash::Accessor->new(qw /CamelCase mixedCase delim_str UPPER lower/);
    $camel = key_morph($obj,'camel');
    
=head1 EXPORT

This module exports key_morph, to_camel, to_mixed, to_under and to_delim.
You will probably only need key_morph unless you really want the others.


=head1 FUNCTIONS

=head2 _split_words($str)

Splits a string into words, identifying boundaries using Capital Letters or Underscores etc.
This sub is not exported

=head2 key_morph($hash,$method,$delim)

$method can be one of (camel, mixed, delim, upper, lower).
$delim should be specified if using the delim method; by default its an empty string.

=head2 to_camel($str)

Convers string to CamelCase

=head2 to_mixed($str)

Convers string to mixedCamelCase

=head2 to_under($str)

Convers string to underscore_separated 

=head2 to_delim($str,$delim)

Convers string to custom delimited-string (delimited by second parameter)

=head2 to_upper($str)

Returns the uppercase version of the rejoined string (removes undescores etc)

=head2 to_lower($str)

Returns the lowercase version of the rejoined string (removes undescores etc)

=head1 AUTHOR AND SUPPORT

Copyright (c) Michael Holloway 2013 , E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Perl Arstistic License

=cut

use 5.010;
use warnings;
use strict;
our $VERSION = '0.09';

use base qw(Exporter);
our @EXPORT = qw(to_mixed to_camel to_under to_delim key_morph);

# warning, _split_words will return lower case! Should only be used internally which is why its not exported
sub _split_words {
    my ($inp) = @_;
    my @words = split( /(?<=[a-z])(?=[A-Z])|-|_/ , $inp);
    return lc($words[0]) if $#words==0;
    return map { lc } @words;
}

# string converters
sub to_upper { return uc join '', _split_words(shift); }
sub to_lower { return lc join '', _split_words(shift); }
sub to_mixed { return lcfirst to_camel(shift); }
sub to_camel { return join('', map{ ucfirst $_ } _split_words(shift)); }
sub to_under { return lc(join('_', map { $_ } _split_words($_[0]))); }
sub to_delim { return lc(join( defined $_[1]?$_[1]:'', map { $_ } _split_words($_[0]))); }

# recursively process hash
sub key_morph {
    my ($inp,$sub,$delim) = @_;
    my $disp = { upper => \&to_upper, lower => \&to_lower, mixed => \&to_mixed, camel => \&to_camel, under => \&to_under, delim => \&to_delim };
    return $inp unless defined $disp->{$sub};
    
    my $r = ref($inp);
    #print "$inp ($r)\n";
    return {map { $disp->{$sub}->($_,$delim) => key_morph($inp->{$_},$sub,$delim); } keys %$inp} if ($r eq 'HASH');
    return [ map key_morph($_,$sub,$delim), @$inp ] if ($r eq 'ARRAY');
    
    return $inp;
}

1;
