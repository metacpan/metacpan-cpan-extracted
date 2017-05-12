package Language::Prolog::Yaswi::Low;

our $VERSION = '0.21';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw( init
		  cleanup
		  toplevel
		  openquery
		  cutquery
		  nextsolution
		  swi2perl
		  testquery
		  getvar
		  getquery
		  getallvars
		  $converter );

use Carp;
use Language::Prolog::Types::Converter;

our $converter = Language::Prolog::Types::Converter->new();

# our @fids;

our ($qid, $query, @vars, @cells, %vars_cache);


sub getvar ($) {
    my $name=$_[0]->name();
    croak "no such variable '$name'"
	unless exists $vars_cache{$name};
    return swi2perl($vars_cache{$name});
}

sub getallvars {
    return map { swi2perl($_) } @cells[0..$#vars]
}

sub getquery () {
    swi2perl($query);
}

# require XSLoader;
# XSLoader::load('Language::Prolog::Yaswi::Low', $VERSION);

our $dl_load_flags;
$dl_load_flags = 0x1 unless defined $dl_load_flags;
sub dl_load_flags { $dl_load_flags }

require DynaLoader;
__PACKAGE__->bootstrap;

our @args;
@args = (PL_EXE(), '-q') unless @args;

sub init {
    @args=(PL_EXE(), @_);
    start();
}


1;
__END__

=head1 NAME

Language::Prolog::Yaswi::Low - Low level interface to SWI-Prolog

=head1 SYNOPSIS


  # don't use Language::Prolog::Yaswi::Low;
  use Language::Prolog::Yaswi; # instead ;-)

=head1 ABSTRACT


=head1 DESCRIPTION

Low level interface to SWI-Prolog.

=head2 SETTINGS

The variable C<$Language::Prolog::Yaswi::Low::dl_load_flags> can be
used to change the way the XS part of the module is loaded. The
default value (0x01) allows to use Prolog extensions written in C in
most architectures but it could introduce conflicts with other Perl
modules.

=head1 SEE ALSO

L<Language::Prolog::Yaswi>.


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006, 2008 by Salvador Fandiño (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

SWI-Prolog is distributed under the GPL license. Read the LICENSE file
from your SWI-Prolog distribution for details.

=cut
