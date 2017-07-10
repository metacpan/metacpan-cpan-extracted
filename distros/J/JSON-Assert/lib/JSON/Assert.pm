## ----------------------------------------------------------------------------
# Copyright (C) 2014-2016 NZRS Ltd
## ----------------------------------------------------------------------------
package JSON::Assert;

use Moo;
use MooX::Types::MooseLike::Base 'Str';
use JSON::Path;
use Test::Deep::NoTest;

$JSON::Path::Safe = 0;

our $VERSION = '0.08';
our $VERBOSE = $ENV{JSON_ASSERT_VERBOSE} || 1;

has 'error' =>
    is => "rw",
    isa => Str,
    clearer => "_clear_error",
    ;

sub _self {
    my $args = shift;
    if ( ref $args->[0] eq __PACKAGE__ ) {
        return shift @$args;
    }
    elsif ( $args->[0] eq __PACKAGE__ ) {
        return do { shift @$args }->new();
    }
    return __PACKAGE__->new();
}

# assert_jpath_count
sub assert_jpath_count {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $count) = @_;

    my $jpath = _parse_jpath($jpath_str);

    my @values = $jpath->values($doc);

    my $found = 0;
    if (scalar @values != 1) {
        $found = scalar @values;   
    }
    elsif (ref $values[0] eq 'ARRAY') {
        $found = scalar @{$values[0]};
    }
    else {
        $found = 1;
    }

    print "assert_jpath_count: Found $found\n" if $VERBOSE;

    unless ( $found == $count ) {
        die "JPath '$jpath' has $found " . $self->_plural($found, 'value') . ", not $count as expected";
    }

    return 1;
}

sub is_jpath_count {
    my $self = _self(\@_);
    my ($doc, $jpath, $count) = @_;

    $self->_clear_error();
    eval { $self->assert_jpath_count($doc, $jpath, $count) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

# assert_jpath_value_match
sub assert_jpath_value_match {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    my $jpath = _parse_jpath($jpath_str);
    
    # firstly, check that the node actually exists
    my @values = $jpath->values($doc);

    my $found = 0;
    if (scalar @values != 1) {
        $found = scalar @values;   
    }
    elsif (ref $values[0] eq 'ARRAY') {
        $found = scalar @{$values[0]};
    }
    else {
        $found = 1;
    }

    print "assert_jpath_value_match: Found $found\n" if $VERBOSE;
    unless ( $found == 1 ) {
        die "JPath '$jpath' matched $found values when we expected to match one";
    }

    # check the value is what we expect
    my $value = $values[0];
    print "assert_jpath_value_match: This value's value : " . $value . "\n" if $VERBOSE;
    return 1 if (ref($value) eq ref($match) && ref($value) eq 'HASH' && scalar(keys(%$value)) == 0 && scalar(keys(%$match)) == 0);
    unless ( $value =~ $match ) {
        die "JPath '$jpath' doesn't match '$match' as expected, instead it is '" . $value . "'";
    }

    return 1;
}

sub does_jpath_value_match {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_jpath_value_match($doc, $jpath_str, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

# assert_jpath_values_match
sub assert_jpath_values_match {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    my $jpath = _parse_jpath($jpath_str);

    # firstly, check that the node actually exists
    my @values = $jpath->values($doc);

    my $values;
    if (scalar @values != 1) {
        $values = \@values;   
    }
    elsif (ref $values[0] eq 'ARRAY') {
        $values = $values[0];
    }
    else {
        $values = \@values;
    }
    
    print 'assert_jpath_values_match: Found ' . (scalar @$values) . "\n" if $VERBOSE;
    unless ( @$values ) {
        die "JPath '$jpath' matched no nodes when we expected to match at least one";
    }

    # check the values are what we expect
    my $i = 0;
    foreach my $value ( @$values ) {
	print "assert_jpath_value_match: This keys's value : " . $value . "\n" if $VERBOSE;
        if (ref($value) eq ref($match) && ref($value) eq 'HASH' && scalar(keys(%$value)) == 0 && scalar(keys(%$match)) == 0){
          $i++;
          next;
        }
        unless ( $value =~ $match ) {
            die "Item $i of JPath '$jpath' doesn't match '$match' as expected, instead it is '" . $value . "'";
        }
        $i++;
    }

    return 1;
}

sub do_jpath_values_match {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_jpath_values_match($doc, $jpath_str, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}

sub assert_json_contains {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    my $jpath = _parse_jpath($jpath_str);
    my @values = $jpath->values($doc);

    if (ref $match eq 'HASH') {
        if (! eq_deeply($values[0], superhashof($match))) {
            use Data::Dumper;
            if ($VERBOSE)  {
                print "wanted: " . Dumper($match) . ", got: " . Dumper ($values[0]) . "\n";
            }

        }
    }
    elsif (ref $match eq 'ARRAY') {
        if (ref $match->[0] eq 'HASH') {
            my @new_wanted = map { superhashof($_) } @$match;

            die "JPath '$jpath_str' doesn't match wanted data structure"
                unless eq_deeply(@values, \@new_wanted);
        }

        die "JPath '$jpath_str' doesn't match wanted data structure"
            unless eq_deeply($values[0], $match);
    }
    else {
        die "JPath '$jpath_str' doesn't match wanted data structure"
            unless $values[0] eq $match;
    }

   return 1; 
}

sub does_jpath_contains {
    my $self = _self(\@_);
    my ($doc, $jpath_str, $match) = @_;

    $self->_clear_error();
    eval { $self->assert_json_contains($doc, $jpath_str, $match) };
    if ( $@ ) {
        $self->error($@);
        return;
    }
    return 1;
}


# private functions
sub _plural {
    my ($class, $number, $single, $plural) = @_;

    return $number == 1 ? $single : defined $plural ? $plural : "${single}s";
}

sub _parse_jpath {
    my ($jpath_str) = @_;

    my $jpath = JSON::Path->new($jpath_str);
    if ($@) {
        die "Error evaluating json path ($jpath_str): $@";
    }

   return $jpath;
}
    

1;
__END__

=head1 NAME

JSON::Assert - Asserts JSONPaths into a JSON data structure for correct values/matches

=head1 SYNOPSIS

    use JSON;
    use JSON::Assert;

    my $json = '{ "foo": { "bar": "text" } }';

    # create a JSON::Assert object
    my $json_assert = JSON::Assert->new();

    # assert that there is:
    # - only one <bar> key in the document
    $json_assert->assert_jpath_count($json, '$..bar', 1);
    # - the value of bar is 'text'
    $json_assert->assert_jpath_value_match($json, '$..bar', 'text');
    # - the value of bar matches /^tex/
    $json_assert->assert_jpath_value_match($json, '$..bar', qr{^tex});

=head1 DESCRIPTION

This module allows you to test JPaths into a JSON data structure to check that their
number or values are what you expect.

To test the number of keys you expect to find, use the C<assert_jpath_count()>
method. To test the value of a key, use the
C<assert_jpath_value_match()>. This method can test against strings or regexes.

You can also text a value against a number of keys by using the
C<assert_jpath_values_match()> method. This can check your value against any
number of keys.

Each of these assert methods throws an exception if they are false. Therefore,
there are equivalent methods which do not die, but instead return a truth
value. They are does_jpath_count(), does_jpath_value_match() and
do_jpath_values_match().


=head1 SUBROUTINES

Please note that all subroutines listed here that start with C<assert_*> throw
an error if the assertion is not true. You'd expect this.

Also note that there are a corresponding number of other methods for each
C<assert_*> method which either return true or false and do not throw an
error. Please be sure to use the correct version for what you need.

=over 4

=item assert_jpath_count($doc, $jpath, $count)

Checks that there are C<$count> keys in the C<$doc> that are returned by the
C<$jpath>. Throws an error if this is untrue.

=item is_jpath_count($doc, $jpath, $count)

Calls the above method but catches any error and instead returns a truth value.

=item assert_jpath_value_match($doc, $jpath, $match)

Checks that C<$jpath> returns only one key and that the value matches
C<$match>.

=item does_jpath_value_match($doc, $jpath, $match)

Calls the above method but catches any error and instead returns a truth value.

=item assert_jpath_values_match($doc, $jpath, $match)

Checks that C<$jpath> returns keys and that all the matched values matches
C<$match>.

=item do_jpath_values_match($doc, $jpath, $match)

Calls the above method but catches any error and instead returns a truth value.

=item assert_json_contains($doc, $jpath, $match)

Checks that C<$jpath> contains the data structure contained within $match.

=item does_jpath_contains($doc, $jpath, $match)

Calls the above method but catches any error and instead returns a truth value.

=back

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<Test::JSON::Assert>, L<JSON::Compare>

Based on:

L<Test::XML::Assert>, L<XML::Compare>

=head1 AUTHOR

Andrew Ruthven

=over 4

=item Work

E<lt>puck at catalyst dot net dot nzE<gt>, http://www.catalyst.net.nz/

=item Personal

E<lt>andrew at etc dot gen dot nz<gt>, http://www.etc.gen.nz/

=back

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by NZRS Ltd., http://www.nzrs.net.nz/

Part od the work was carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2014-2015, NZRS Limited.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: f
# tab-width: 8
# cperl-continued-statement-offset: 4
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 4
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -4
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
