use 5.014;
use strict;
use warnings;
no warnings 'void';

use Carp ();
use Exporter::Tiny ();
use PadWalker ();
use Parse::Keyword ();
use Module::Runtime ();
use Scalar::Util ();
use Sub::Util ();

package Kavorka;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

our @ISA         = qw( Exporter::Tiny );
our @EXPORT      = qw( fun method );
our @EXPORT_OK   = qw( fun method after around before override augment classmethod objectmethod multi );
our %EXPORT_TAGS = (
	modifiers    => [qw( after around before )],
	allmodifiers => [qw( after around before override augment )],
);

our %IMPLEMENTATION = (
	after        => 'Kavorka::Sub::After',
	around       => 'Kavorka::Sub::Around',
	augment      => 'Kavorka::Sub::Augment',
	before       => 'Kavorka::Sub::Before',
	classmethod  => 'Kavorka::Sub::ClassMethod',
	f            => 'Kavorka::Sub::Fun',
	fun          => 'Kavorka::Sub::Fun',
	func         => 'Kavorka::Sub::Fun',
	function     => 'Kavorka::Sub::Fun',
	method       => 'Kavorka::Sub::Method',
	multi        => 'Kavorka::Multi',
	objectmethod => 'Kavorka::Sub::ObjectMethod',
	override     => 'Kavorka::Sub::Override',
);

our %INFO;

sub info
{
	my $me = shift;
	my $code = $_[0];
	$INFO{$code};
}

sub guess_implementation
{
	my $me = shift;
	$IMPLEMENTATION{$_[0]};
}

sub compose_implementation
{
	shift;
	require Moo::Role;
	Moo::Role->create_class_with_roles(@_);
}

sub _exporter_validate_opts
{
	my $class = shift;
	$^H{'Kavorka/package'} = $_[0]{into};
	$_[0]{replace} = 1 unless exists $_[0]{replace};
}

sub _fqname ($;$)
{
	my $name = shift;
	my ($package, $subname);
	
	$name =~ s{'}{::}g;
	
	if ($name =~ /::/)
	{
		($package, $subname) = $name =~ m{^(.+)::(\w+)$};
	}
	else
	{
		my $caller = @_ ? shift : $^H{'Kavorka/package'};
		($package, $subname) = ($caller, $name);
	}
	
	return wantarray ? ($package, $subname) : "$package\::$subname";
}


sub _exporter_fail
{
	my $me = shift;
	my ($name, $args, $globals) = @_;
	
	my $implementation =
		$args->{'implementation'}
		// $me->guess_implementation($name)
		// $me;
	
	my $into = $globals->{into};
	
	Module::Runtime::use_package_optimistically($implementation);
	
	{
		my $traits = $globals->{traits} // $args->{traits};
		$implementation = $me->compose_implementation($implementation, @$traits)
			if $traits;
	}
	
	$implementation->can('parse')
		or Carp::croak("No suitable implementation for keyword '$name'");
	
	# Workaround for RT#95786 which might be caused by a bug in the Perl
	# interpreter.
	# Also RT#98666 is why we can't just call undefer_all.
	require Sub::Defer;
	for (keys %Sub::Defer::DEFERRED) {
		no warnings;
		Sub::Defer::undefer_sub($_)
			if $Sub::Defer::DEFERRED{$_} && $Sub::Defer::DEFERRED{$_}[0] =~ /\AKavorkaX?\b/;
	}
	
	# Kavorka::Multi (for example) needs to know what Kavorka keywords are
	# currently in scope.
	$^H{'Kavorka'} .= "$name=$implementation ";
	
	# This is the code that gets called at run-time.
	#
	my $code = Sub::Util::set_subname(
		"$me\::$name",
		sub {
			unless (Scalar::Util::blessed($_[0]) and $_[0]->DOES('Kavorka::Sub'))
			{
				return $implementation->bypass_custom_parsing($name, $into, \@_);
			}

			my $subroutine = shift;
						
			# Post-parse clean-up
			$subroutine->_post_parse();
			
			# Store $subroutine for introspection
			$INFO{ $subroutine->body } = $subroutine;
			
			# Install sub
			my @r = wantarray
				? $subroutine->install_sub
				: scalar($subroutine->install_sub);
			
			# Workarounds for closure issues in Parse::Keyword
			if ($subroutine->is_anonymous)
			{
				my $orig = $r[0];
				my $caller_vars = PadWalker::peek_my(1);
				@r = Sub::Util::set_subname($subroutine->package."::__ANON__", sub {
					$subroutine->_poke_pads($caller_vars);
					goto $orig;
				});
				&Scalar::Util::set_prototype($r[0], $_) for grep defined, prototype($orig);
				$INFO{ $r[0] } = $subroutine;
				Scalar::Util::weaken($INFO{ $r[0] });
			}
			else
			{
				$subroutine->_poke_pads( PadWalker::peek_my(1) );
			}
			
			# Prevents a cycle between %INFO and $subroutine.
			Scalar::Util::weaken($subroutine->{body})
				unless Scalar::Util::isweak($subroutine->{body});
			
			wantarray ? @r : $r[0];
		},
	);
	
	# This joins up the code above with our custom parsing via
	# Parse::Keyword
	#
	Parse::Keyword::install_keyword_handler(
		$code => Sub::Util::set_subname(
			"$me\::parse_$name",
			sub {
				local $Carp::CarpLevel = $Carp::CarpLevel + 1;
				my $subroutine = $implementation->parse(keyword => $name);
				return (
					sub { ($subroutine, $args) },
					!! $subroutine->declared_name,
				);
			},
		),
	);
	
	# Symbol for Exporter::Tiny to export
	return ($name => $code);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords invocant invocants lexicals unintuitive yada globals

=head1 NAME

Kavorka - function signatures with the lure of the animal

=head1 SYNOPSIS

   use Kavorka;
   
   fun maxnum (Num @numbers) {
      my $max = shift @numbers;
      for (@numbers) {
         $max = $_ if $max < $_;
      }
      return $max;
   }
   
   my $biggest = maxnum(42, 3.14159, 666);

=head1 STATUS

Kavorka is still at a very early stage of development; there are likely
to be many bugs that still need to be shaken out. Certain syntax
features are a little odd and may need to be changed in incompatible
ways.

=head1 DESCRIPTION

Kavorka provides C<fun> and C<method> keywords for declaring functions
and methods. It uses Perl 5.14's keyword API, so should work more
reliably than source filters or L<Devel::Declare>-based modules.

The syntax provided by Kavorka is largely inspired by Perl 6, though
it has also been greatly influenced by L<Method::Signatures> and
L<Function::Parameters>.

For information using the keywords exported by Kavorka:

=over

=item *

L<Kavorka::Manual::Functions>

=item *

L<Kavorka::Manual::Methods>

=item *

L<Kavorka::Manual::MethodModifiers>

=item *

L<Kavorka::Manual::MultiSubs>

=back

=head2 Exports

=over

=item C<< -default >>

Exports C<fun> and C<method>.

=item C<< -modifiers >>

Exports C<before>, C<after>, and C<around>.

=item C<< -allmodifiers >>

Exports C<before>, C<after>, C<around>, C<augment>, and C<override>.

=item C<< -all >>

Exports C<fun>, C<method>, C<before>, C<after>, C<around>,
C<augment>, C<override>, C<classmethod>, C<objectmethod>,
and C<multi>.

=back

For example:

   # Everything except objectmethod and multi...
   use Kavorka qw( -default -allmodifiers classmethod );

You can rename imported functions:

   use Kavorka method => { -as => 'meth' };

You can provide alternative implementations:

   # use My::Sub::Method instead of Kavorka::Sub::Method
   use Kavorka method => { implementation => 'My::Sub::Method' };

Or add traits to the default implementation:

   use Kavorka method => { traits => ['My::Sub::Role::Foo'] };

See L<Exporter::Tiny> for more tips.

=head2 Function Introspection API

The coderef for any sub created by Kavorka can be passed to the
C<< Kavorka->info >> method. This returns a blessed object that
does the L<Kavorka::Sub> role.

   fun foo (:$x, :$y) { }
   
   my $info = Kavorka->info(\&foo);
   
   my $function_name = $info->qualified_name;
   my @named_params  = $info->signature->named_params;
   
   say $named_params[0]->named_names->[0];   # says 'x'

See L<Kavorka::Sub>, L<Kavorka::Signature> and
L<Kavorka::Parameter> for further details.

If you're using Moose, consider using L<MooseX::KavorkaInfo> to expose
Kavorka method signatures via the meta object protocol.

L<Kavorka::Manual::API> provides more details and examples using the
introspection API.

=head1 CAVEATS

=over

=item *

As noted in L<Kavorka::Manual::PrototypeAndAttributes>, subroutine
attributes don't work properly for anonymous functions.

=item *

This module is based on L<Parse::Keyword>, which has a chronically
broken implementation of closures. Kavorka uses L<PadWalker> to attempt
to work around the problem. This mostly seems to work, but you may
experience some problems in edge cases, especially for anonymous
functions and methods.

=item *

If importing Kavorka's method modifiers into Moo/Mouse/Moose classes,
pay attention to load order:

   use Moose;
   use Kavorka -all;   # ok

If you do it this way, Moose's C<before>, C<after>, and C<around>
keywords will stomp on top of Kavorka's...

   use Kavorka -all;
   use Moose;          # STOMP, STOMP, STOMP!  :-(

This can lead to delightfully hard to debug errors.

=back

=head1 BUGS

If seeing test failures on threaded Perl 5.21+, it may be a bug in
L<Devel::CallParser> 0.002.
Try installing L<Alt::Devel::CallParser::ButWorking>.

Please report any other bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Kavorka>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<Kavorka::Manual>.

B<< Inspirations: >>
L<http://perlcabal.org/syn/S06.html>,
L<Function::Parameters>,
L<Method::Signatures>.

L<http://en.wikipedia.org/wiki/The_Conversion_(Seinfeld)>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

