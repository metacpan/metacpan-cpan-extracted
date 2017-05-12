package Language::MzScheme::Env;
@_p_Scheme_Env::ISA = __PACKAGE__;

use vars '%Objects';
use strict;
use constant S => 'Language::MzScheme';

my $SIGILS = '!?$~+.@^%&';
my @SIGILS = split(//, $SIGILS);

=head1 NAME

Language::MzScheme::Env - MzScheme runtime environment

=head1 SYNOPSIS

    use Language::MzScheme;
    my $env = Language::MzScheme->new;
    # ...

=head1 DESCRIPTION

None at this moment.

=head1 METHODS

All methods below, except C<new>, returns an B<Language::MzScheme::Object>
instance.

=head2 new

Constructs and returns a new environment object.  Calling this method is 
identical to C<Language::MzScheme-E<gt>new>.

=cut

sub new {
    my $env = S->basic_env;
    $env->_init_perl_wrappers;
    return $env;
}

=head2 lookup($name)

Given a global MzScheme variable name C<$name>, returns the current value.

=cut

sub lookup {
    my ($self, $name) = @_;

    return $name if UNIVERSAL::isa($name, S.'::Object') and $name->isa('CODE');

    my $sym = S->intern_symbol($name);
    my $obj = S->lookup_global($sym, $self);
    $Objects{S->REFADDR($obj)} ||= $self;
    return $obj;
}

=head2 define($name, $code, $sigil)

Defines a new MzScheme primitive C<$name> from C<$code>, with the
calling context C<$sigil>, and returns it.

If C<$sigil> is omitted, look at the end of C<$name> for a sigil
character; if not found, uses the auto context.  See L</CONTEXTS>
for a list of sigils and their meanings.

If C<$code> is omitted, defines a package with the name C<$name>
and import all its symbols.  Otherwise, pass it and the sigil to
the C<lambda> method, and bind the returned lambda to C<$name>.

=cut

sub define {
    my ($self, $name, $code, $sigil) = @_;

    $sigil ||= substr($name, -1) if $name =~ /[$SIGILS]$/o;

    if (!defined($code)) {
        no strict 'refs';
        foreach my $sym (grep !/^[^a-z]|\W/, sort keys %{"$name\::"}) {
            my $code = *{${"$name\::"}{$sym}}{CODE} or next;
            $sym =~ tr/_/-/;
            $self->define("$name\::$sym", $code);
        }
        $code = $name;
    }
    elsif (ref($code) eq 'CODE') {
        foreach my $s (@SIGILS) {
            my $obj = $self->lambda($code, $sigil);
            S->add_global($name.$s, $obj, $self);
        }
    }

    my $obj = $self->lambda($code, $sigil);
    S->add_global($name, $obj, $self);
    return $self->lookup($name);
}

=head2 lambda($code, $sigil)

Builds and returns a MzScheme procedure, as a wrapper for C<$code>.

If C<$code> is a Perl code reference, returns a lambda that takes any
number of parameters, under the context specified by C<$sigil>:

    (func ...)          ; ==> $code->(...)

Otherwise, treat C<$code> as a class name or an object, and returns a
lambda that takes a mandatory I<method> argument, followed by any
number of parameters.

    (obj 'method ...)   ; ==> $obj->$method(...)

Generally, you should only set C<$sigil> for code references, and let
the user specity the context with the method name:

    (obj 'set! ...)     ; void context
    (obj 'isa? ...)     ; boolean context

=cut

sub lambda {
    my ($self, $code, $sigil) = @_;
    my $name = "$code";
    $name .= ":$sigil" if $sigil;

    my $obj = (ref($code) eq 'CODE')
        ? S->make_perl_prim_w_arity($code, "$name", 0, -1, $sigil)
        : S->make_perl_object_w_arity($code, "$name", 1, -1, $sigil);

    $Objects{S->REFADDR($obj)} ||= $self;
    return $obj;
}

=head2 eval($expr)

Evaluates a MzScheme expression, passed as an object or a string,
and returns the result.

=cut

sub eval {
    my $self = shift;

    my $obj = do {
        package Language::MzScheme::Env::__eval;
        UNIVERSAL::isa($_[0], "Language::MzScheme::Object")
            ? Language::MzScheme::mzscheme_do_eval($_[0], $self)
            : Language::MzScheme::mzscheme_do_eval_string_all($_[0], $self, 1);
    };

    $Objects{S->REFADDR($obj)} ||= $self if ref($obj);
    return $obj;
}

=head2 apply($name, @args)

Applies a MzScheme procedure, passed as an object or a global name,
to C<@args>, and returns the result.

=cut

sub apply {
    my ($self, $name) = splice(@_, 0, 2);
    @_ = map S->from_perl_scalar($_), @_;
    my $obj = S->do_apply($self->lookup($name), 0+@_, \@_);
    $Objects{S->REFADDR($obj)} ||= $self if ref($obj);
    return $obj;
}

=head2 val($scalar)

Return a MzScheme object that represents the content of C<$scalar>,
which may be a simple scalar or a reference.

=cut

sub val {
    my $self = shift;
    my $obj = S->from_perl_scalar($_[0]);
    $Objects{S->REFADDR($obj)} ||= $self if ref($obj);
    return $obj;
}

=head2 sym($string)

Returns a MzScheme symbol object named C<$string>.

=cut

sub sym {
    my $self = shift;
    my $obj = S->intern_symbol("$_[0]");
    $Objects{S->REFADDR($obj)} ||= $self if ref($obj);
    return $obj;
}

=head1 CONTEXTS

There are 10 different sigils, each representing a way to interpret
values returned by a Perl function or method.

If no sigils are specified, then B<auto-context> is assumed: it will
call the perl code with Perl's list context, and look at the number
of values returned.  If there is exactly one return value, receive it
as a scalar; otherwise, returns a MzScheme list that contains all
return values.

    ; list context calls
    (perl-func "string")    ; auto-context
    (perl-func@ "string")   ; a list
    (perl-func^ "string")   ; a vector
    (perl-func% "string")   ; a hash-table
    (perl-func& "string")   ; an association-list

    ; scalar context calls
    (perl-func$ "string")   ; a scalar of an appropriate type
    (perl-func~ "string")   ; a string
    (perl-func+ "string")   ; a number
    (perl-func. "string")   ; a character
    (perl-func? "string")   ; a boolean (#t or #f)

    ; void context calls
    (perl-func! "string")   ; always #<void>

=cut

foreach my $sym (qw(
    perl_do perl_eval perl_require perl_use
)) {
    no strict 'refs';
    my $proc = $sym;
    $proc =~ tr/_/-/;
    *$sym = sub {
        my $self = shift;
        $self->apply($proc, @_);
    };
}

sub _init_perl_wrappers {
    my $self = shift;
    my $env_pkg = __PACKAGE__.'::__eval'; #(0+$self);

    no strict 'refs';
    *{"$env_pkg\::mz_eval"} = sub { $self->eval(@_) };
    *{"$env_pkg\::mz_apply"} = sub { $self->apply(@_) };
    *{"$env_pkg\::mz_lambda"} = sub { $self->lambda(@_) };
    *{"$env_pkg\::mz_define"} = sub { $self->define(@_) };
    *{"$env_pkg\::mz_lookup"} = sub { $self->lookup(@_) };

    # XXX current-command-line-arguments?
    $self->define('perl-do', $self->_wrap_do($env_pkg));
    $self->define('perl-eval', $self->_wrap_eval($env_pkg));
    $self->define('perl-use', $self->_wrap_use($env_pkg));
    $self->define('perl-require', $self->_wrap_require($env_pkg));
}

sub _wrap_require {
    my ($self, $env_pkg) = @_;
    return sub {        
        my $pkg = shift;
        $pkg =~ s{::}{/}g;
        $pkg .= ".pm" if index($pkg, '.') == -1;
        local $@;
        eval "package $env_pkg; require \$pkg;";
        die $@ if $@;
        $pkg =~ s{/}{::}g;
        $pkg =~ s{\.pm$}{}i;
        $self->define($pkg);
        return $pkg;
    };
}

sub _wrap_use {
    my ($self, $env_pkg) = @_;
    return sub {        
        no strict 'refs';
        my $pkg = shift;
        my %seen = map ( ( $_ => 1 ), keys %{"$env_pkg\::"} );

        local $@;
        my @args;
        my $eval = "package $env_pkg;\nuse $pkg ".(
            @_ ? do {
                @args = map { $_->isa('ARRAY') ? @$_ : $_ } @_;
                '@args;';
            } : ';'
        );
        eval $eval;
        die $@ if $@;

        foreach my $sym (grep !/^[^a-z]|\W/, sort keys %{"$env_pkg\::"}) {
            next if $seen{$sym};
            my $code = *{${"$pkg\::"}{$sym}}{CODE} or next;
            $self->define($sym, $code);
        }

        $self->define($pkg);
        return $pkg;
    };
}

sub _wrap_do {
    my ($self, $env_pkg) = @_;
    return sub {
        my $file = shift;
        local $@;
        return eval "package $env_pkg;\ndo \$file;";
    }
}

sub _wrap_eval {
    my ($self, $env_pkg) = @_;
    return sub {
        local $@;
        return eval "package $env_pkg;\n@_;";
    }
}

1;

__END__

=head1 SEE ALSO

L<Language::MzScheme>, L<Language::MzScheme::Object>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
