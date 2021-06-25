package My::Module::Build;

use strict;
use warnings;

use Module::Build;
our @ISA = qw{ Module::Build };

use Carp;

__PACKAGE__->add_property( my_pl_files => [] );

sub ACTION_authortest {
##  my ( $self, @args ) = @_;
    my ( $self ) = @_;		# Arguments not used

    local $ENV{AUTHOR_TESTING} = 1;

    $self->depends_on( 'build' );
    $self->test_files( qw{ t xt/author } );
    $self->depends_on( 'test' );

    return;
}

sub ACTION_code {
    my ( $self, @args ) = @_;
    $self->depends_on( 'move_perl_files' );
    return $self->SUPER::ACTION_code();
}

sub ACTION_constant_files {
##  my ( $self, @args ) = @_;
    my ( $self ) = @_;		# Arguments not used
    $self->up_to_date(
	'Constant.PL',
	[ qw{ constant-c.inc constant-h.inc constant-xs.inc } ],
    ) and return;
    $self->do_system( $self->perl(), 'Constant.PL' );
    return;
}

sub ACTION_move_perl_files {
##  my ( $self, @args ) = @_;
    my ( $self ) = @_;		# Arguments not used
    $self->depends_on( 'constant_files' );
    my $touch;
    foreach my $file ( @{ $self->my_pl_files() || [] } ) {
	$self->copy_if_modified( from => $file, to => "lib/Mac/$file" )
	    or next;
	print "$file -> lib/Mac/$file\n";
	$touch = 1;
    }
    if ( $touch ) {
	# Unlinking the .o file seems to be necessary to prevent
	# Module::Build::Base::link_c() from including
	# lib/Mac/Pasteboard.o twice if Pasteboard.xs is touched without
	# a ./Build realclean. The problem seems to be that link_c()
	# gathers up all the .o files under the reasonable assumption
	# that they are needed for the link, but then adds the .o file
	# it is trying to build on the reasonable-but-wrong assumption
	# that it has not yet been created.
	# I unlink the .c as well for good measure.
	unlink map { "lib/Mac/Pasteboard.$_" } qw{ o c };
	# On principal. I have not had trouble with this, but I suspect
	# it is because I have been focussed on the refactor, in which
	# case this file will never be present because lib/Mac/pbl.c is
	# not present.
	unlink 'lib/Mac/pbl.o';
    }
    return;
}

sub harness_switches {
    my ( $self ) = @_;
    my @res = $self->SUPER::harness_switches();
    foreach ( @res ) {
	'-MDevel::Cover' eq $_
	    or next;
	$_ .= '=-db,cover_db,-ignore,inc/';
    }
    return @res;
}

1;

__END__

=head1 NAME

My::Module::Build - Extend Module::Build for PPIx::Regexp

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build authortest # supplied by this module
 ./Build install

=head1 DESCRIPTION

This extension of L<Module::Build|Module::Build> adds the following
action to those provided by L<Module::Build|Module::Build>:

  authortest

=head1 ACTIONS

This module provides the following action:

=over

=item authortest

This action runs not only those tests which appear in the F<t>
directory, but those that appear in the F<xt> directory. The F<xt> tests
are provided for information only, since some of them (notably
F<xt/critic.t> and F<xt/pod_spelling.t>) are very sensitive to the
configuration under which they run.

Some of the F<xt> tests require modules that are not named as
requirements. These should disable themselves if the required modules
are not present.

This test is sensitive to the C<verbose=1> argument, but not to the
C<--test_files> argument.

=back

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-Mac-Pasteboard/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
