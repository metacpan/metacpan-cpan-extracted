use strictures 2;

package Method::Signatures::WithDocumentation;

# ABSTRACT: use Method::Signatures with Sub::Documentation together

use Attribute::Handlers;
use Sub::Documentation 'add_documentation';
use Moose;
use Data::Alias;
extends 'Method::Signatures';

our $VERSION = '1.000'; # VERSION

around parse_proto => sub {
    my ($orig, $self, @args) = @_;
    my $code = $self->$orig(@args);
    return $code unless $self->{function_name};
    my $signature = $self->{signature};
    my @parameters = @{ $signature->parameters };
    my @short_sig;
    foreach my $parameter (@parameters) {
        if ($parameter->is_yadayada) {
            push @short_sig => '...';
            next;
        }
        my @doc = ($parameter->type, $parameter->variable);
        push @doc => 'named' if $parameter->is_named;
        push @doc => 'aliased' if $parameter->is_ref_alias;
        push @doc => 'required' if $parameter->is_required;
        push @doc => 'optional' if not $parameter->is_required;
        push @doc => 'defaults to C<<< '.$parameter->default.' >>>' if $parameter->default;
        push @doc => 'but only when C<<< '.$parameter->default_when.' >>>' if $parameter->default_when;

        my $short_sig = $parameter->type . ' ';
        $short_sig .= "\\" if $parameter->is_ref_alias;
        $short_sig = $parameter->variable_name.' => '.$short_sig if $parameter->is_named;
        $short_sig .= $parameter->variable;
        $short_sig = "[ $short_sig ]" unless $parameter->is_required;

        add_documentation(
            package => $self->{into},
            glob_type => 'CODE',
            name => $self->{function_name},
            type => 'param_signature',
            documentation => \@doc,
        );
        push @short_sig => $short_sig;
    }
    add_documentation(
        package => $self->{into},
        glob_type => 'CODE',
        name => $self->{function_name},
        type => 'type',
        documentation => $self->{name},
    );
    add_documentation(
        package => $self->{into},
        glob_type => 'CODE',
        name => $self->{function_name},
        type => 'signature',
        documentation => join(', ', @short_sig),
    );
    return $code;
};

sub _add_attr_doc {
    my ($type, $package, $symbol, $referent, $data) = @_[0..3,5];
    $data = $data->[0] if ref($data) eq 'ARRAY' && @$data == 1;
    add_documentation(
        package       => $package,
        glob_type     => ref($referent),
        name          => *{$symbol}{NAME},
        type          => $type,
        documentation => $data,
    );
}


no warnings 'redefine'; ## no critic


sub UNIVERSAL::Name : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(name => @_);
}


sub UNIVERSAL::Purpose : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(purpose => @_);
}


sub UNIVERSAL::Pod : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(pod => @_);
}


sub UNIVERSAL::Param : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(param => @_);
}


sub UNIVERSAL::Author : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(author => @_);
}


sub UNIVERSAL::Returns : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(returns => @_);
}


sub UNIVERSAL::Throws : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(throws => @_);
}


sub UNIVERSAL::Example : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(example => @_);
}


sub UNIVERSAL::Since : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(since => @_);
}


sub UNIVERSAL::Deprecated : ATTR(CODE,BEGIN,RAWDATA) {
    _add_attr_doc(deprecated => @_);
}

1;

__END__

=pod

=head1 NAME

Method::Signatures::WithDocumentation - use Method::Signatures with Sub::Documentation together

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use Method::Signatures::WithDocumentation;
    
    method foo (Str $text) :Purpose(Does something with text) {
        ...
    }

=head1 DESCRIPTION

This module extends L<Method::Signatures> to grab out parameter definitions. It behaves also similiar to L<Sub::Documentation::Attributes>, but with an important fix to let it work together with L<Pod::Weaver::Section::AutoDoc>.

=head1 SUBROUTINE ATTRIBUTES

Each of the attributes (except C<Deprecated>) requires a non-interpolated string. B<Please note that all parantheses must be balanced>.

=head2 Name

Use another name instead of method/function for documentation.

=head2 Purpose

A brief description what the function/method does.

=head2 Pod

Free-text deeper description of whats going on.

=head2 Param

A description of a function/method param, suggested by the following format:

    method xxx ($foo, $bar) :Param($foo: This is foo) :Param($bar: This is bar) { ... }

Just the variable name (without modifiers like C<\>, C<:>, C<?> or C<!>) followed by a colon and the description.

=head2 Author

Name of the author of the method/function, if it differs from the module author and the name should be explicity printed in the documentation.

Maybe used more than once, one for each author.

=head2 Returns

A free text what will be returned.

=head2 Throws

A free text what will be thrown in case of whatever.

Maybe used more than once, one for each case.

=head2 Example

A verbatim text, like a synopsis at the beginning of each module documentation.

=head2 Since

An identifier since when the method/function is available. For example a date or a version number.

=head2 Deprecated

This attributes marks the method/function as deprecated. The reason is optional.

=head1 SEE ALSO

=for :list * L<Pod::Weaver::Section::AutoDoc>

=head1 FORMATTING TIPS

For some readers it might be confusing the read a subroutine definition with many attributes. There is no best practise at the moment, but I suggest this template:

    func foobar (Int $amount = 1) :
        Purpose(
            Prints out I<foo> and I<bar>
        )
        Example(
            foobar(2); # prints two foos and two bars
        )
        Param(
            $amount: how many foo and bar should be printed
        )
        Pod(
            This function is an example to show you a fancy way for its documentation
        )
        Returns(
            True on success
        )
        Throws(
            An error message if there is no output device
        )
        Since(
            1.000
        )
        Deprecated(
            Use L</foobar_v2> instead.
        )
        Author(
            John Doe
        )
    { ... }

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libmethod-signatures-withdocumentation-perl/issu
es

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
