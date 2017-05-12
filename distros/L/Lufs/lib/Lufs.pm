package Lufs;

use base 'Lufs::Glue';
use Lufs::C;

use strict;
use warnings;
our $VERSION = 0.21;

use vars qw/$AUTOLOAD/;

sub new {
    my $cls = shift;
    my $self = {};
    bless $self => $cls;
    $Lufs::C::object = $self;
}

sub _init {
    my $self = shift;
    my $opt = pop;
    my ($f, $class) = ($opt->{host}, $opt->{host});
    $f =~ s{\.}{/}g;$f .= '.pm';
    $class =~ s{\.}{::}g;
    eval "require '$f'";
    if ($@) { warn "cannot load class: $@"; return 0 }
    eval 'push @'.$class."::ISA, 'Lufs::Glue'";
    $self->{fs} = bless {} => $class;
	$opt->{logfile} ||= '/tmp/perlfs.log';
	open(STDERR, ">> $opt->{logfile}") if $opt->{logfile};
	$Lufs::Glue::trace = 1 if $opt->{logfile};
    $self->{fs}->init($opt);
}

sub AUTOLOAD {
    my $self = shift;
    my $method = (split/::/,$AUTOLOAD)[-1];
    $method eq 'DESTROY' && return;
	if ($self->{fs}->can($method)) {
		return $self->{fs}->$method(@_);
	}
	else {
		print STDERR "$method not implemented\n";
	}
	return 0;
}

1;
__END__

=head1 NAME

Lufs - Perl plug for lufs

=head1 DESCRIPTION

  The C code is a lufs module with an embedded perl interpreter.
  All filesystem calls are redirected to Lufs::C, which in turn gives them to your subclass.

  currently, these filesystems are included:

  Lufs::Local
  Lufs::Ram
  Lufs::Http
  Lufs::Svn
  Lufs::Mux
  Lufs::Rot13
  Lufs::Sql
  Lufs::NetHood

  lufsmount -o logfile=/tmp/perlfslog perlfs://Lufs.Local/ /mnt/foo
  lufsmount perlfs://Lufs.Ram/ /mnt/bar
  lufsmount perlfs://Lufs.Rot13/mnt/bar /mnt/baz
  lufsmount -o uri=svn://datamoeras.org/perlufs perlfs://Lufs::Svn/
  lufsmount -o uri=http://datamoeras.org perlfs://Lufs::Http/
  lufsd none /mnt/join -o 'fs=perlfs,host=Lufs.Mux,root=/,dirs=/mnt/box1;/mnt/box2;/mnt/box3'
  
  # or, if you have autofs:
  cd /mnt/perl/Lufs.Local/
  cd /mnt/svn/perlufs
  
=head1 SEE ALSO

L<Lufs::Howto>, L<http://datamoeras.org/perlufs>, L<http://lufs.sf.net>, L<lufsmount(1)>

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
