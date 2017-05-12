package JBD::Core::List;
# ABSTRACT: list utilities
our $VERSION = '0.04'; # VERSION

# List utilities.
# @author Joel Dalley
# @version 2014/Feb/05

use JBD::Core::stern;
use JBD::Core::Exporter ':omni';
use Carp 'croak';

# @param array Input args.
# @return bool 1 if given a single scalar, or untrue.
sub is_unit(@) { @_ == 1 && !ref $_[0] }

# @param array Input args.
# @return bool 1 if given an array or arrayref, or untrue.
sub is_list(@) {
    @_ > 1 
    || ref $_[0] eq 'ARRAY' 
    || ref $_[0] eq 'HASH';
}

# @param array Input args.
# @return arrayref A reference to the input args.
sub _(@) {
    croak 'Missing required arguments' if !@_;
    croak "Not a unit or list: [@_]" 
          if !is_unit @_ && !is_list @_;
    return [$_[0]] if is_unit @_;
    @_ > 1 ? \@_ : $_[0];
}

# @param arrayref Returned value from another list sub.
# @return mixed The given ref, possibly dereferenced.
sub ret(@) { wantarray ? @{$_[0]} : shift }

# @param array an array
# @return array/ref a flat list
sub flatmap(@) {
    ret [map {
        if    (ref $_ eq 'ARRAY')  { flatmap(@$_) }
        elsif (ref $_ eq 'HASH')   { flatmap(%$_) }
        elsif (ref $_ eq 'SCALAR') { $$_ }
        else                       { $_ }
    } @{_ @_}];
}

# @param array An array.
# @return array/ref An array with unique elements.
sub uniq(@) { ret [keys %{{map {$_ => undef} @{_ @_}}}] }

# @param array An array.
# @return array/ref A shuffled array.
sub shuffle(@) {
    my $list = _ @_;
    my $i = @$list or return ();
    while (--$i) { 
        my $j = int rand $i + 1; 
        @$list[$i, $j] = @$list[$j, $i];
    }
    ret $list;
}

# @param array An even-sized array.
# @return array/ref A zip-ordered array (1st half, 2nd half).
sub zip(@) { 
    my $list = _ @_;
    push @$list, undef if @$list % 2;
    ret [@$list[map {$_, $_ + @$list/2} 0 .. (@$list/2 - 1)]];
}

# @param array An even-sized array.
# @return coderef An iterator of pairs from the array.
sub pairsof(@) {
    my $list = _ @_;
    push @$list, undef if @$list % 2;
    sub {@$list ? [shift @$list, shift @$list] : undef};
}

# @param coderef $it An iterator.
# @return array/ref Items collected by iterating $it.
sub collect($) {
    my $it = shift;
    my @collection;
    while ($_ = $it->()) { push @collection, $_ }
    ret \@collection;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::List - list utilities

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
