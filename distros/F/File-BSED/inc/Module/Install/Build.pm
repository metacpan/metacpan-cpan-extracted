package Module::Install::Build;

use strict;
use Module::Install::Base;

use vars qw{$VERSION $ISCORE @ISA};
BEGIN {
	$VERSION = '0.67';
	$ISCORE  = 1;
	@ISA     = qw{Module::Install::Base};
}

sub Build { $_[0] }

sub write {
    my $self = shift;
    die "Build->write() takes no arguments\n" if @_;

    my %args;
    my $build;

    $args{dist_name}     = $self->name || $self->determine_NAME($self->{args});
    $args{license}       = $self->license;
    $args{test_files}    = $self->tests;
    $args{dist_version}  = $self->version || $self->determine_VERSION($self->{args});
    $args{dist_abstract} = $self->abstract;
    $args{dist_author}   = $self->author;
    $args{sign}          = $self->sign;
    $args{no_index}      = $self->no_index;

    foreach my $key (qw(build_requires requires recommends conflicts)) {
        my $val = eval "\$self->$key" or next;
        $args{$key} = { map @$_, @$val };
    }

    %args = map {($_, $args{$_})} grep {defined($args{$_})} keys %args;

    require Module::Build;
    $build = Module::Build->new(%args);
    $build->add_to_cleanup(split /\s+/, $self->clean_files);
    $build->create_build_script;
}

sub ACTION_reset {
    my ($self) = @_;
    die "XXX - Can't get this working yet";
    require File::Path;
    warn "Removing inc\n";
    rmpath('inc');
}

sub ACTION_dist {
    my ($self) = @_;
    die "XXX - Can't get this working yet";
}

# <ingy> DrMath: is there an OO way to add actions to Module::Build??
# <DrMath> ingy: yeah
# <DrMath> ingy: package MyBuilder; use w(Module::Build; @ISA = qw(w(Module::Build); sub ACTION_ingy
#           {...}
# <DrMath> ingy: then my $build = new MyBuilder( ...parameters... );
#           $build->write_build_script;

1;

__END__

=head1 NAME

Module::Install::Build - Extension Rules for Module::Build

=head1 VERSION

This document describes version 0.01 of Module::Install::Build, released
March 1, 2003.

=head1 SYNOPSIS

In your F<Makefile.PL>:

    use inc::Module::Install;
    &Build->write;

=head1 DESCRIPTION

This module is a wrapper around B<Module::Build>.

The C<&Build-E<gt>write> function will pass on keyword/value pair
functions to C<Module::Build::create_build_script>.

=head2 VERSION

B<Module::Build> requires either the C<VERSION> or C<VERSION_FROM>
parameter.  If this module can guess the package's C<NAME>, it will attempt
to parse the C<VERSION> from it.

If this module can't find a default for C<VERSION> it will ask you to
specify it manually.

=head1 MAKE TARGETS

B<Module::Build> provides you with many useful C<make> targets. A
C<make> B<target> is the word you specify after C<make>, like C<test>
for C<make test>. Some of the more useful targets are:

=over 4

=item * all

This is the default target. When you type C<make> it is the same as
entering C<make all>. This target builds all of your code and stages it
in the C<blib> directory.

=item * test

Run your distribution's test suite.

=item * install

Copy the contents of the C<blib> directory into the appropriate
directories in your Perl installation.

=item * dist

Create a distribution tarball, ready for uploading to CPAN or sharing
with a friend.

=item * clean distclean purge

Remove the files created by C<perl Makefile.PL> and C<make>.

=item * help

Same as typing C<perldoc Module::Build>.

=back

This module modifies the behaviour of some of these targets, depending
on your requirements, and also adds the following targets to your Makefile:

=over 4

=item * cpurge

Just like purge, except that it also deletes the files originally added
by this module itself.

=item * chelp

Short cut for typing C<perldoc Module::Install>.

=item * distsign

Short cut for typing C<cpansign -s>, for B<Module::Signature> users to
sign the distribution before release.

=back

=head1 SEE ALSO

L<Module::Install>, L<CPAN::MakeMaker>, L<CPAN::MakeMaker-Philosophy>

=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>

Based on original works by Brian Ingerson E<lt>INGY@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, 2003, 2004 by
Audrey Tang E<lt>autrijus@autrijus.orgE<gt>,
Brian Ingerson E<lt>ingy@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
