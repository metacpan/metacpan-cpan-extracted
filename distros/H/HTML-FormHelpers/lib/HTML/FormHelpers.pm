package HTML::FormHelpers;
{
  $HTML::FormHelpers::VERSION = '0.004';
}
# ABSTRACT: Useful routines for generating HTML form elements

use strict;
use warnings;
use Try::Tiny;
use Scalar::Util qw/ blessed /;
use parent 'Exporter';

our @EXPORT_OK = qw( process_attributes radio text select button hidden checkbox );
our %EXPORT_TAGS = ( all => [ qw(radio text select button hidden checkbox )] );


# NOTE: The first hashref we come across is assumed to be the 
#       attributes
sub process_attributes {
    for my $i (0..$#_) {
        if (ref $_[$i] eq 'HASH') {
            my $attrs = splice @_, $i, 1;
            return join " ", map { $_ . '="' . $attrs->{$_} . '"' } keys %{$attrs};
        }
    }
    return "";
}

sub process_args {
    my $obj;
    $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my $idx = try { $obj->can('id') && "[" . ($obj->id // "") . "]" } catch { "" };
    my $name = $_[0] . $idx;
    return ($obj,$name,$attributes);
}

sub radio {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $values, $sep) = @_;
    $sep ||= '';
    my ($i, @ret) = 0;
    my $on = do { try { $obj->$name }  } // @{$values}[0];
    while ($i < @$values) { 
        my ($val,$disp) = @{$values}[$i, $i+1];
        my $checked = $on eq $val ? 'checked="checked"' : "";
        push @ret, qq(<label><input type="radio" name="$fname" value="$val" $checked $attributes />$disp</label>);
    } continue { $i+=2 }
    return ref $sep eq 'ARRAY' ? @ret : join $sep,@ret;
}


sub text {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $value) = @_;
    my $val = do { try { $obj->$name } } // $value // "";
    return qq(<input type="text" name="$fname" value="$val" $attributes />);
}


sub select {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $options, $key, $value) = @_;
    my $str = $name ? qq(<select name="$fname" $attributes>) : "<select>";
    my $on = $obj && $name ? ($obj->$name // "") : "";
    for my $o (@$options) {
        my ($k, $v);
        if (ref $o eq 'HASH') {
            ($k,$v) = each %$o;
        } elsif ($key && $value) {
            $k  = do { try { $o->$key } catch { $o->{$key} } } // "";
            $v = do { try { $o->$value } catch { $o->{$value} } } // "";
        } else {
            $k = $v = $o;
        }
        $str .= qq(<option value="$k") . ($on eq $k ? " selected" : "") . qq(>$v</option>);
    }
    $str .= "</select>";
    return $str;
}


sub button {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $value) = @_;
    $value //= $name;
    return qq(<input type="button" name="$fname" value="$value" $attributes />);
}

sub hidden {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $value) = @_;
    return qq(<input type="hidden" name="$fname" value="$value" $attributes />);
}


sub checkbox {
    my ($obj, $fname, $attributes) = &process_args;
    my ($name, $checked) = @_;
    $checked = try { $obj->$name } catch { $checked // 1 };
    $attributes .= " checked" if $checked;
    return qq(<input type="checkbox" name="$fname" value="1" $attributes />);
}

1;

__END__

=pod

=head1 NAME

HTML::FormHelpers - Useful routines for generating HTML form elements

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use HTML::FormHelpers qw<:all>;

    print text('foo');   # generate HTML for an input tag

    my @options = qw( small medium large );
    print select('size', \@options);

=head1 DESCRIPTION

B<NOTE: This module is very alpha code.  I<Use at your own risk!>>

This module has some handy routines for creating HTML form elements.
Each helper routine may optionally pass an object as its first argument.
It is expected that this object will have an accessor with the same name
as the one specified as the second argument so that the form elements
can be initialized with the object's values by default.

=over

=item C<radio([OBJ], NAME, [VALUES], [SEPARATOR])>

Examples:

    radio('item', [ 'hat', 'shirt', 'shorts' ])
    radio($obj, 'size', [ 'small', 'medium', 'large' ])

=item C<text([OBJ], NAME, VALUE, [ ATTR ])>

Examples:

    text('title')
    text($person, 'name') %>
    text($person, 'dob', { size => 8 })

=item C<select([OBJ], NAME, OPTIONS, [KEY], [VALUE], [ ATTR ])>

Example:

    select('priority', [ 'low','medium','high' ])

=item C<checkbox([OBJ], NAME, CHECKED, [ ATTR ])>

Example:

=item C<button([OBJ], NAME, [VALUE], [ ATTR ])>

Example:

=item C<hidden([OBJ], NAME, VALUE, [ ATTR ] )>

Example:

=back

=head1 AUTHOR

Jonathan Scott Duff <duff@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Scott Duff.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
