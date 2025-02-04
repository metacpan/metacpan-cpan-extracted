package ExtUtils::Typemaps::IntObj;
$ExtUtils::Typemaps::IntObj::VERSION = '0.003';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

my $output = <<'END';
	{
		sv_setref_uv($arg, %s, (UV)$var);
		SvREADONLY_on(SvRV($arg));
	}
END

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_INTOBJ', code => <<'END');
    {
		SV * sv = $arg;
		if (SvROK(sv) && sv_derived_from(sv, \"$ntype\"))
			$var = ($type)SvUV(SvRV(sv));
		else
			croak(\"%s: %s is not of type %s\", ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]}, \"$var\", \"$ntype\");
    }
END
	$self->add_inputmap(xstype => 'T_INTREF', code => <<'END');
    {
		SV * sv = $arg;
		if (SvROK(sv) && SvIOK(SvRV(sv)))
			$var = ($type)SvUV(SvRV(sv));
		else 
			croak(\"%s: %s is not a reference\", ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]}, \"$var\");
    }
END

	$self->add_outputmap(xstype => 'T_INTOBJ', code => sprintf $output, '\\"$ntype\\"');
	$self->add_outputmap(xstype => 'T_INTREF', code => sprintf $output, 'NULL');

	return $self;
}

1;

# ABSTRACT: Typemap for storing int-like handles as objects

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::IntObj - Typemap for storing int-like handles as objects

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In typemap

 Foo::Bar	T_INTOBJ

In your XS:

 typedef handle_t Foo__Bar;
 
 MODULE = Foo::Bar    PACKAGE = Foo::Bar    PREFIX = foobar_
 
 Foo::Bar foobar_new(SV* class, int argument)

 int foobar_baz(Foo::Bar self)

=head1 DESCRIPTION

C<ExtUtils::Typemaps::IntObj> is a typemap bundle that stores two typemaps: C<T_INTOBJ> and C<T_INTREF>.

C<T_INTOBJ> is a typemap for an XS object those state is a single immutable integer (e.g. some constant or handle). It stores the handle as a reference to an integer.

C<T_INTREF> is much the same as C<T_INTOBJ> but doesn't bless the reference.

=head1 INCLUSION

To use this typemap template you need to include it into your local typemap. The easiest way to do that is to use the L<typemap> script in L<App::typemap>. E.g.

 typemap --merge ExtUtils::Typemaps::IntObj

If you author using C<Dist::Zilla> you can use L<Dist::Zilla::Plugin::Typemap> instead.

Alternatively, you can include it at runtime by adding the following to your XS file:

 INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd -e "print embeddable_typemap('IntObj')"

That does require adding a build time dependency on this module.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
