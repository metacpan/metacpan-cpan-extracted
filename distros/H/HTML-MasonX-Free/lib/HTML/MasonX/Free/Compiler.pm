use strict;
use warnings;
package HTML::MasonX::Free::Compiler 0.007;

# ABSTRACT: an HTML::Mason compiler that can reject more input
use parent 'HTML::Mason::Compiler::ToObject';

#pod =head1 OVERVIEW
#pod
#pod This is an alternate compiler for HTML::Mason.  It's meant to fill in for the
#pod default, L<HTML::Mason::Compiler::ToObject>.  (Don't trust things telling you
#pod that the default is HTML::Mason::Compiler.  If you're using Mason, you're
#pod almost certainly have ToObject doing the work.)
#pod
#pod By default, it I<should> behave just like the normal compiler, but more options
#pod can be provided to make it stricter.
#pod
#pod Right now, there's just one extra option, but there will be more.
#pod
#pod =attr allow_stray_content
#pod
#pod If false, any text outside of a block (like a method or doc block), other than
#pod blank lines, will be fatal.  Similar, any Perl lines other than comments will
#pod be fatal.
#pod
#pod =attr default_method_to_call
#pod
#pod If set, this is the name of a method that will be dropped in place whenever the
#pod user is trying to call a component without a method.  For example, if you set
#pod it to "main" then this:
#pod
#pod   <& /foo/bar &>
#pod
#pod ...will be treated like this:
#pod
#pod   <& /foo/bar:main  &>
#pod
#pod To keep this consistent with the top-level called performed by the mason
#pod interpreter, you should probably also use L<HTML::MasonX::Free::Component> as
#pod your component class.
#pod
#pod =cut

use namespace::autoclean;

use HTML::Mason::Exceptions(abbr => [qw(param_error)]);

use Params::Validate qw(:all);
Params::Validate::validation_options(on_fail => sub {param_error join '', @_});

BEGIN {
  __PACKAGE__->valid_params(
    allow_stray_content => {
      parse => 'boolean',
      type  => SCALAR,
      default => 1,
      descr => "Whether to allow content outside blocks, or die",
    },
    default_method_to_call => {
      parse => 'string',
      type  => SCALAR,
      optional => 1,
      descr => "A method to always call instead of calling a comp directly",
    },
  );
}

sub text {
  my ($self, %arg) = @_;
  if (
    $self->{current_compile}{in_main}
    and ! $self->{allow_stray_content}
    and $arg{text} =~ /\S/
  ) {
    $self->lexer->throw_syntax_error(
      "text outside of block: <<'END_TEXT'\n$arg{text}END_TEXT"
    );
  }
  $self->SUPER::text(%arg);
}

sub perl_line {
  my ($self, %arg) = @_;

  if (
    $self->{current_compile}{in_main}
    and ! $self->{allow_stray_content}
    and $arg{line} !~ /\A\s*#/
  ) {
    $self->lexer->throw_syntax_error(
      "perl outside of block: $arg{line}\n"
    );
  }
  $self->SUPER::perl_line(%arg);
}

# BEGIN DIRECT THEFT FROM HTML-Mason 1.50
sub component_call
{
    my $self = shift;
    my %p = @_;

    my ($prespace, $call, $postspace) = ($p{call} =~ /(\s*)(.*)(\s*)/s);
    if ( $call =~ m,^[\w/.],)
    {
        my $comma = index($call, ',');
        $comma = length $call if $comma == -1;
        (my $comp = substr($call, 0, $comma)) =~ s/\s+$//;
        if (defined $self->{default_method_to_call} and $comp !~ /:/) { ##
          $comp = "$comp:$self->{default_method_to_call}";              ##
        }                                                               ##
        $call = "'$comp'" . substr($call, $comma);
    }
    my $code = "\$m->comp( $prespace $call $postspace \n); ";
    eval { $self->postprocess_perl->(\$code) } if $self->postprocess_perl;
    compiler_error $@ if $@;

    $self->_add_body_code($code);

    $self->{current_compile}{last_body_code_type} = 'component_call';
}

sub component_content_call_end
{
    my $self = shift;
    my $c = $self->{current_compile};
    my %p = @_;

    $self->lexer->throw_syntax_error("Found component with content ending tag but no beginning tag")
        unless @{ $c->{comp_with_content_stack} };

    my $call = pop @{ $c->{comp_with_content_stack} };
    my $call_end = $p{call_end};
    for ($call_end) { s/^\s+//; s/\s+$//; }

    my $comp = undef;
    if ( $call =~ m,^[\w/.],)
    {
        my $comma = index($call, ',');
        $comma = length $call if $comma == -1;
        ($comp = substr($call, 0, $comma)) =~ s/\s+$//;
        if (defined $self->{default_method_to_call} and $comp !~ /:/) { ##
          $comp = "$comp:$self->{default_method_to_call}";              ##
        }                                                               ##
        $call = "'$comp'" . substr($call, $comma);
    }
    if ($call_end) {
        if ($call_end !~ m,^[\w/.],) {
            $self->lexer->throw_syntax_error("Cannot use an expression inside component with content ending tag; use a bare component name or </&> instead");
        }
        if (!defined($comp)) {
            $self->lexer->throw_syntax_error("Cannot match an expression as a component name; use </&> instead");
        }
        if ($call_end ne $comp) {
            $self->lexer->throw_syntax_error("Component name in ending tag ($call_end) does not match component name in beginning tag ($comp)");
        }
    }

    my $code = "} }, $call\n );\n";

    eval { $self->postprocess_perl->(\$code) } if $self->postprocess_perl;
    compiler_error $@ if $@;

    $self->_add_body_code($code);

    $c->{last_body_code_type} = 'component_content_call_end';
}
# END DIRECT THEFT FROM HTML-Mason 1.50

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::MasonX::Free::Compiler - an HTML::Mason compiler that can reject more input

=head1 VERSION

version 0.007

=head1 OVERVIEW

This is an alternate compiler for HTML::Mason.  It's meant to fill in for the
default, L<HTML::Mason::Compiler::ToObject>.  (Don't trust things telling you
that the default is HTML::Mason::Compiler.  If you're using Mason, you're
almost certainly have ToObject doing the work.)

By default, it I<should> behave just like the normal compiler, but more options
can be provided to make it stricter.

Right now, there's just one extra option, but there will be more.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 allow_stray_content

If false, any text outside of a block (like a method or doc block), other than
blank lines, will be fatal.  Similar, any Perl lines other than comments will
be fatal.

=head2 default_method_to_call

If set, this is the name of a method that will be dropped in place whenever the
user is trying to call a component without a method.  For example, if you set
it to "main" then this:

  <& /foo/bar &>

...will be treated like this:

  <& /foo/bar:main  &>

To keep this consistent with the top-level called performed by the mason
interpreter, you should probably also use L<HTML::MasonX::Free::Component> as
your component class.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
