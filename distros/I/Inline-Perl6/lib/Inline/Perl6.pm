package Inline::Perl6;

use 5.018000;
use strict;
use warnings;

use File::Spec;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Inline::Perl6 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.08';

my ($helper_path) = grep { -e } map {File::Spec->catfile($_, qw(Inline Perl6 Helper.pm))} @INC
    or die "Could not find Inline/Perl6/Helper.pm in \@INC (@INC)";

__PACKAGE__->bootstrap($VERSION);

setup_library_location($DynaLoader::dl_shared_objects[-1], $helper_path);

my $destroy_in_end;
my $initialized;
sub import {
    my ($class, $oo) = @_;
    unless ($oo and $oo eq 'OO') {
        $destroy_in_end = 1;
        initialize() unless $initialized++;
    }
}

sub p6_run {
    my ($code) = @_;
    return v6::run($code);
}

sub run {
    my ($self, $code) = @_;
    return v6::run($code);
}

sub call {
    return v6::call(@_);
}

sub destroy {
    v6::uninit();
    p6_destroy();
}

sub new {
    initialize();
    return bless {};
}

sub DESTROY {
    destroy();
}

sub use {
    my ($self, $module) = @_;

    $self->run("use $module;");
}

sub invoke {
    my ($self, $class, $method, @args) = @_;

    return v6::invoke($class, $method, @args);
}

sub END {
    destroy() if $destroy_in_end;
}

1;
__END__

=head1 NAME

Inline::Perl6 - use the real Perl 6 from Perl 5 code

=head1 SYNOPSIS

  use Inline::Perl6;

  v6::run("say 'Hello from Perl 6'");
  v6::call("say", "Hello again from Perl 6");
  my $obj = v6::invoke("Some::Perl6::Class", "new", "First arg");
  $obj->some_method(1, 2);

  # or object oriented:

  use Inline::Perl6 'OO';

  my $p6 = Inline::Perl6->new;
  $p6->run("use Test; ok(1);");
  $p6->run("use Test; ok(2); done-testing();");

  $p6->use('Foo');
  my $foo = $p6->invoke('Foo', 'new');
  my $baz = $foo->bar('baz');

=head1 DESCRIPTION

This module embeds a MoarVM based Rakudo Perl 6 and allows you to run Perl 6
code, load Perl 6 modules, use methods of Perl 6 objects and much more.
Please look at https://github.com/niner/Inline-Perl5 for more information
about usage.

=head1 INSTALLATION

This module requires an up to date Rakudo with an enabled MoarVM backend.
The perl6 executable needs to be in your PATH when you run Makefile.PL.
You need to install the Inline::Perl5 Perl 6 module which this module is
based on. You may do this using the "panda" or "zef" Perl 6 module installer:

  panda install Inline::Perl5
  perl Makefile.PL
  make
  make test
  make install

Please note that if you have multiple perl installations (e.g. with perlbrew),
you have to use the exact same perl for installing Inline::Perl5 and
Inline::Perl6.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://github.com/niner/Inline-Perl5> for more documentation.

L<http://github.com/niner/Inline-Perl6> for the latest version.

=head1 AUTHOR

Stefan Seifert, E<lt>nine@detonation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Stefan Seifert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
