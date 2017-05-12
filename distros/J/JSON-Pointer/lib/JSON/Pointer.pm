package JSON::Pointer;

use 5.008_001;
use strict;
use warnings;

use B;
use Carp qw(croak);
use Clone qw(clone);
use JSON qw(encode_json decode_json);
use JSON::Pointer::Context;
use JSON::Pointer::Exception qw(:all);
use JSON::Pointer::Syntax qw(is_array_numeric_index);
use URI::Escape qw(uri_unescape);

our $VERSION = '0.07';

sub traverse {
    my ($class, $document, $pointer, $opts) = @_;
    $opts = +{
        strict => 1,
        inclusive => 0,
        %{ $opts || +{} }
    };
    $pointer = uri_unescape($pointer);

    my @tokens  = JSON::Pointer::Syntax->tokenize($pointer);
    my $context = JSON::Pointer::Context->new(+{
        pointer => $pointer,
        tokens  => \@tokens,
        target  => $document,
        parent  => $document,
    });

    foreach my $token (@tokens) {
        $context->begin($token);

        my $parent = $context->parent;
        my $type   = ref $parent;

        if ($type eq "HASH") {
            unless (exists $parent->{$token}) {
                return _throw_or_return(ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE, $context, $opts->{strict});
            }

            $context->next($parent->{$token});
            next;
        }
        elsif ($type eq "ARRAY") {
            if ($token eq '-') {
                $token = $#{$parent} + 1;
            }

            my $max_index = $#{$parent};
            $max_index++ if $opts->{inclusive};

            if (is_array_numeric_index($token) && $token <= $max_index) {
                $context->next($parent->[$token]);
                next;
            }
            else {
                return _throw_or_return(ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE, $context, $opts->{strict});
            }
        }
        else {
            return _throw_or_return(ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE, $context, $opts->{strict});
        }
    }

    $context->result(1);
    return $context;
}

sub get {
    my ($class, $document, $pointer, $strict) = @_;
    $strict = 0 unless defined $strict;

    my $context;
    eval {
        $context = $class->traverse($document, $pointer, +{ strict => $strict });
    };
    if (my $e = $@) {
        croak $e;
    }

    return $context->result ? $context->target : undef;
}

sub get_relative {
    my ($class, $document, $current_pointer, $relative_pointer, $strict) = @_;
    $strict = 0 unless defined $strict;

    my @current_tokens = JSON::Pointer::Syntax->tokenize($current_pointer);

    my $context = JSON::Pointer::Context->new(+{
        pointer => $current_pointer,
        tokens  => \@current_tokens,
        target  => $document,
        parent  => $document,
    });

    my ($steps, $relative_pointer_suffix, $use_index) =
        ($relative_pointer =~ m{^(0|[1-9]?[0-9]+)([^#]*)(#?)$});
    $relative_pointer_suffix ||= "";

    unless (defined $steps) {
        return _throw_or_return(ERROR_INVALID_POINTER_SYNTAX, $context, +{ strict => $strict });
    }

    for (my $i = 0; $i < $steps; $i++) {
        if (@current_tokens == 0) {
            return _throw_or_return(ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE, $context, +{ strict => $strict });
        }
        pop(@current_tokens);
    }

    if ($use_index) {
        my @relative_tokens = JSON::Pointer::Syntax->tokenize($relative_pointer_suffix);
        return (@relative_tokens > 0) ? $relative_tokens[-1] : $current_tokens[-1];
    }

    my $absolute_pointer = JSON::Pointer::Syntax->as_pointer(@current_tokens) . $relative_pointer_suffix;

    eval {
        $context = $class->traverse($document, $absolute_pointer, +{ strict => $strict });
    };
    if (my $e = $@) {
        croak $e;
    }

    return $context->result ? $context->target : undef;
}

sub contains {
    my ($class, $document, $pointer) = @_;
    my $context = $class->traverse($document, $pointer, +{ strict => 0 });
    return $context->result;
}

sub add {
    my ($class, $document, $pointer, $value) = @_;

    my $patched_document = clone($document);

    my $context = $class->traverse($patched_document, $pointer, +{ strict => 0, inclusive => 1 });
    my $parent  = $context->parent;
    my $type    = ref $parent;

    if ($type eq "HASH") {
        if (!$context->result && @{$context->processed_tokens} < @{$context->tokens} - 1) {
            ### Parent isn't object
            JSON::Pointer::Exception->throw(
                code    => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
                context => $context,
            );
        }

        if (defined $context->last_token) {
            $parent->{$context->last_token} = $value;
        }
        else {
            ### pointer is empty string (whole document)
            $patched_document = $value;
        }

        return $patched_document;
    }
    elsif ($type eq "ARRAY") {
        unless ($context->result) {
            JSON::Pointer::Exception->throw(
                code    => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
                context => $context,
            );
        }

        if (defined $context->last_token) {
            my $parent_array_length = $#{$parent} + 1;
            my $target_index        = ($context->last_token eq "-") ? 
                $parent_array_length : $context->last_token;

            splice(@$parent, $target_index, 0, $value);
        }
        else {
            $patched_document = $value;
        }

        return $patched_document;
    }
    else {
        unless ($context->result) {
            JSON::Pointer::Exception->throw(
                code    => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
                context => $context,
            );
        }

        return $value;
    }
}

sub remove {
    my ($class, $document, $pointer) = @_;

    my $patched_document = clone($document);

    my $context = $class->traverse($patched_document, $pointer);
    my $parent  = $context->parent;
    my $type    = ref $parent;

    if ($type eq "HASH") {
        my $target_member = $context->last_token;
        if (defined $target_member) {
            my $removed = delete $parent->{$target_member};
            return wantarray ? ($patched_document, $removed) : $patched_document;
        }
        else {
            ### pointer is empty string (whole document)
            return wantarray ? (undef, $patched_document) : undef;
        }
    }
    elsif ($type eq "ARRAY") {
        my $target_index = $context->last_token;
        if (defined $target_index) {
            my $parent_array_length = $#{$parent} + 1;
            $target_index = $parent_array_length if ($target_index eq "-");
            my $removed = splice(@$parent, $target_index, 1);
            return wantarray ? ($patched_document, $removed) : $patched_document;
        }
        else {
            ### pointer is empty string (whole document)
            return wantarray ? (undef, $patched_document) : undef;
        }
    }
    else {
        unless ($context->result) {
            JSON::Pointer::Exception->throw(
                code    => ERROR_POINTER_REFERENCES_NON_EXISTENT_VALUE,
                context => $context,
            );
        }

        return wantarray ? (undef, $patched_document) : undef;
    }
}

sub replace {
    my ($class, $document, $pointer, $value) = @_;

    my $patched_document = clone($document);
    my $context = $class->traverse($patched_document, $pointer);
    my $parent  = $context->parent;
    my $type    = ref $parent;

    if ($type eq "HASH") {
        my $target_member = $context->last_token;
        if (defined $target_member) {
            my $replaced = $parent->{$context->last_token};
            $parent->{$context->last_token} = $value;
            return wantarray ? ($patched_document, $replaced) : $patched_document;
        }
        else {
            ### pointer is empty string (whole document)
            return wantarray ? ($value, $patched_document) : $value;
        }
    }
    else {
        my $target_index = $context->last_token;
        if (defined $target_index) {
            my $parent_array_length = $#{$parent} + 1;
            $target_index = $parent_array_length if ($target_index eq "-");
            my $replaced = $parent->[$target_index];
            $parent->[$target_index] = $value;
            return wantarray ? ($patched_document, $replaced) : $patched_document;
        }
        else {
            ### pointer is empty string (whole document)
            return wantarray ? ($value, $patched_document) : $value;
        }
    }
}

sub set {
    shift->replace(@_);
}

sub copy {
    my ($class, $document, $from_pointer, $to_pointer) = @_;
    my $context = $class->traverse($document, $from_pointer);
    return $class->add($document, $to_pointer, $context->target);
}

sub move {
    my ($class, $document, $from_pointer, $to_pointer) = @_;
    my ($patched_document, $removed) = $class->remove($document, $from_pointer);
    $class->add($patched_document, $to_pointer, $removed);
}

sub test {
    my ($class, $document, $pointer, $value) = @_;

    my $context = $class->traverse($document, $pointer, +{ strict => 0 });

    return 0 unless $context->result;

    my $target      = $context->target;
    my $target_type = ref $target;

    if ($target_type eq "HASH" || $target_type eq "ARRAY") {
        return encode_json($target) eq encode_json($value) ? 1 : 0;
    }
    elsif (defined $target) {
        if (JSON::is_bool($target)) {
            return JSON::is_bool($value) && $target == $value ? 1 : 0;
        }
        elsif (_is_iv_or_nv($target) && _is_iv_or_nv($value)) {
            return $target == $value ? 1 : 0;
        }
        elsif (_is_pv($target) && _is_pv($value)) {
            return $target eq $value ? 1 : 0;
        }
        else {
            return 0;
        }
    }
    else {
        ### null
        return !defined $value ? 1 : 0;
    }
}

sub _throw_or_return {
    my ($code, $context, $strict) = @_;

    if ($strict) {
        JSON::Pointer::Exception->throw(
            code    => $code,
            context => $context,
        );
    }
    else {
        $context->last_error($code);
        return $context;
    }
}

sub _is_iv_or_nv {
    my $value = shift;
    my $flags = B::svref_2object(\$value)->FLAGS;
    return ( ($flags & ( B::SVp_IOK | B::SVp_NOK )) && !($flags & B::SVp_POK) );
}

sub _is_pv {
    my $value = shift;
    my $flags = B::svref_2object(\$value)->FLAGS;
    return ( !($flags & ( B::SVp_IOK | B::SVp_NOK )) && ($flags & B::SVp_POK) );
}

1;

__END__

=head1 NAME

JSON::Pointer - A Perl implementation of JSON Pointer (RFC6901)

=head1 VERSION

This document describes JSON::Pointer version 0.07.

=head1 SYNOPSIS

  use JSON::Pointer;

  my $obj = {
    foo => 1,
    bar => [ { qux => "hello" }, 3 ],
    baz => { boo => [ 1, 3, 5, 7 ] }
  };

  JSON::Pointer->get($obj, "/foo");       ### $obj->{foo}
  JSON::Pointer->get($obj, "/bar/0");     ### $obj->{bar}[0]
  JSON::Pointer->get($obj, "/bar/0/qux"); ### $obj->{bar}[0]{qux}
  JSON::Pointer->get($obj, "/bar/1");     ### $obj->{bar}[1]
  JSON::Pointer->get($obj, "/baz/boo/2"); ### $obj->{baz}{boo}[2]

=head1 DESCRIPTION

This library is implemented JSON Pointer (L<http://tools.ietf.org/html/rfc6901>) and 
some useful operator from JSON Patch (L<http://tools.ietf.org/html/rfc6902>).

JSON Pointer is available to identify a specified value in JSON document, and it is simillar to XPath.
Please read the both of specifications for details.

=head1 METHODS

=head2 get($document :HashRef/ArrayRef/Scalar, $pointer :Str, $strict :Int) :Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=item $strict :Int

Strict mode. When this value equals true value, this method may throw exception on error.
When this value equals false value, this method return undef value on error.

=back

Get specified value identified by I<$pointer> from I<$document>.
For example,

  use JSON::Pointer;
  print JSON::Pointer->get({ foo => 1, bar => { "qux" => "hello" } }, "/bar/qux"); ### hello

=head2 get_relative($document :HashRef/ArrayRef/Scalar, $current_pointer :Str, $relative_pointer :Str, $strict :Int) :Scalar

B<This method is highly EXPERIMENTAL>. Because this method depends on L<http://tools.ietf.org/html/draft-luff-relative-json-pointer-00> draft spec.

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $current_pointer : Str

JSON Pointer string to identify specified current position in the document.

=item $relative_pointer : Str

JSON Relative Pointer string to identify specified value from current position in the document

=item $strict :Int

Strict mode. When this value equals true value, this method may throw exception on error.
When this value equals false value, this method return undef value on error.


=back

=head2 contains($document :HashRef/ArrayRef/Scalar, $pointer :Str) :Int

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to present by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=back

Return which the target location identified by I<$pointer> exists or not in the I<$document>.

  use JSON::Pointer;

  my $document = { foo => 1 };
  if (JSON::Pointer->contains($document, "/foo")) {
    print "/foo exists";
  }

=head2 add($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :HashRef/ArrayRef/Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=item $value :HashRef/ArrayRef/Scalar

The perl data structure that is able to be presented by JSON format.

=back

Add specified I<$value> on target location identified by I<$pointer> in the I<$document>.
For example, 

  use JSON::Pointer;

  my $document = +{ foo => 1, };
  my $value = +{ qux => "hello" };

  my $patched_document = JSON::Pointer->add($document, "/bar", $value);
  print $patched_document->{bar}{qux}; ### hello

=head2 remove($document, $pointer) :Array/Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=back

Remove target location identified by I<$pointer> in the I<$document>.

  use JSON::Pointer;

  my $document = { foo => 1 };
  my $patched_document = JSON::Pointer->remove($document, "/foo");
  unless (exists $patched_document->{foo}) {
    print "removed /foo";
  }

This method is contextial return value. When the return value of I<wantarray> equals true,
return I<$patched_document> and I<$removed_value>, or not return I<$patched_document> only.

=head2 replace($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Array/HashRef/ArrayRef/Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=item $value :HashRef/ArrayRef/Scalar

The perl data structure that is able to be presented by JSON format.

=back

Replace the value of target location specified by I<$pointer> to the I<$value> in the I<$document>.

  use JSON::Pointer;

  my $document = { foo => 1 };
  my $patched_document = JSON::Pointer->replace($document, "/foo", 2);
  print $patched_document->{foo}; ## 2

This method is contextial return value. When the return value of I<wantarray> equals true,
return I<$patched_document> and I<$replaced_value>, or not return I<$patched_document> only.

=head2 set($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Array/HashRef/ArrayRef/Scalar

This method is alias of replace method.

=head2 copy($document :HashRef/ArrayRef/Scalar, $from_pointer :Str, $to_pointer :Str) :HashRef/ArrayRef/Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $from_pointer :Str

JSON Pointer string to identify specified value in the document.

=item $to_pointer :Str

JSON Pointer string to identify specified value in the document.

=back

Copy the value identified by I<$from_pointer> to target location identified by I<$to_pointer>.
For example,

  use JSON::Pointer;

  my $document = +{ foo => [ { qux => "hello" } ], bar => [ 1 ] };
  my $patched_document = JSON::Pointer->copy($document, "/foo/0/qux", "/bar/-");
  print $patched_document->{bar}[1]; ## hello

Note that "-" notation means next of last element in the array.
In this example, "-" means 1.

=head2 move($document :HashRef/ArrayRef/Scalar, $from_pointer :Str, $to_pointer :Str) :HashRef/ArrayRef/Scalar

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $from_pointer :Str

JSON Pointer string to identify specified value in the document.

=item $to_pointer :Str

JSON Pointer string to identify specified value in the document.

=back

Move the value identified by I<$from_pointer> to target location identified by I<$to_pointer>.
For example,

  use JSON;
  use JSON::Pointer;

  my $document = +{ foo => [ { qux => "hello" } ], bar => [ 1 ] };
  my $patched_document = JSON::Pointer->move($document, "/foo/0/qux", "/bar/-");
  print encode_json($patched_document); ## {"bar":[1,"hello"],"foo":[{}]}

=head2 test($document :HashRef/ArrayRef/Scalar, $pointer :Str, $value :HashRef/ArrayRef/Scalar) :Int

=over

=item $document :HashRef/ArrayRef/Scalar

Target perl data structure that is able to be presented by JSON format.

=item $pointer :Str

JSON Pointer string to identify specified value in the document.

=item $value :HashRef/ArrayRef/Scalar

The perl data structure that is able to be presented by JSON format.

=back

Return which the value identified by I<$pointer> equals I<$value> or not in the I<$document>.
This method distinguish type of each values.

  use JSON::Pointer;

  my $document = { foo => 1 };

  print JSON::Pointer->test($document, "/foo", 1); ### 1
  print JSON::Pointer->test($document, "/foo", "1"); ### 0

=head2 traverse($document, $pointer, $opts) : JSON::Pointer::Context

This method is used as internal implementation only.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

=over

=item L<perl>

=item L<Mojo::JSON::Pointer>

Many codes in this module is inspired by the module.

=item L<http://tools.ietf.org/html/rfc6901>

=item L<http://tools.ietf.org/html/rfc6902>

=item L<http://tools.ietf.org/html/draft-luff-relative-json-pointer-00>

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Toru Yamaguchi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
