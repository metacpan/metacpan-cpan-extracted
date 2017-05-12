use warnings;
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
if ($ENV{DEVELOPER} && -r 'makepods') {
  system(q{make -f makepods}) and warn "Something went wrong building pods: $?\n";
}
WriteMakefile(
    NAME              => 'GRID::Machine',
    VERSION_FROM      => 'lib/GRID/Machine.pm', # finds $VERSION
    PREREQ_PM         => { 'Module::Which' => '0.0205', }, 
    'EXE_FILES'       => [ 'scripts/gmdb', # remote debugger. Not finished
                           'scripts/remotetest.pl' 
                         ],
    ($] >= 5.007 ?     ## Add these new keywords supported since 5.005
      (
         ABSTRACT_FROM  => 'lib/GRID/Machine.pod', # retrieve abstract from module
         AUTHOR         => 'Casiano Rodriguez-Leon <casiano@ull.es>',
      )
      : ()
    )
);

sub MY::postamble {

  my $DEVELOPER = ($ENV{DEVELOPER} || '');
  return '' unless $DEVELOPER;

  # To check tests in remote machines. See goal remotetest
  my $MACHINES = ($ENV{MACHINES} || '127.0.0.1 127.0.0.1');

  return targets(
    MACHINES     => $MACHINES,
  );

}

sub targets {
  my %var = @_;

  local $_ = <<'EOT';

doc:tt2/Machine.tt2 tt2/Message.tt2 tt2/REMOTE.tt2 tt2/Result.tt2 tt2/Process.tt2 tt2/Group.tt2
	cd tt2; tpage  Machine.tt2 > ../lib/GRID/Machine.pod
	cd tt2; tpage  Message.tt2 > ../lib/GRID/Machine/Message.pod
	cd tt2; tpage  REMOTE.tt2 > ../lib/GRID/Machine/REMOTE.pod
	cd tt2; tpage  Core.tt2 > ../lib/GRID/Machine/Core.pod
	cd tt2; tpage  Result.tt2 > ../lib/GRID/Machine/Result.pod
	cd tt2; tpage  IOHandle.tt2 > ../lib/GRID/Machine/IOHandle.pod
	cd tt2; tpage  perlparintro.tt2 > ../lib/GRID/Machine/perlparintro.pod
	cd tt2; tpage  remotedebugtut.tt2 > ../lib/GRID/Machine/remotedebugtut.pod
	cd tt2; tpage  Process.tt2 > ../lib/GRID/Machine/Process.pod
	cd tt2; tpage  Group.tt2 > ../lib/GRID/Machine/Group.pod

publicdist: rmdist dist
	chmod a+r GRID-Machine-*.tar.gz
	cp GRID-Machine-*.tar.gz /tmp/
	chmod a+r /tmp/GRID-Machine-*.tar.gz

rmdist:
	rm -fR GRID-Machine-*.tar.gz
	rm -fR /tmp/GRID-Machine-*.tar.gz

xdvi: doc
	pod2latex -full -prefile preamble.tex lib/GRID/Machine.pod
	latex Machine
	latex Machine
	makeindex Machine; latex Machine.tex 
	pod2latex -full -prefile preamble.tex lib/GRID/Machine/IOHandle.pod
	latex IOHandle
	latex IOHandle
	makeindex IOHandle; latex IOHandle.tex 
	pod2latex -full -prefile preamblegen.tex lib/GRID/Machine/perlparintro.pod
	#pod2latex -full lib/GRID/Machine/perlparintro.pod
	latex perlparintro
	latex perlparintro
	makeindex perlparintro; latex perlparintro.tex 
	pod2latex -full -prefile preamblegen.tex lib/GRID/Machine/remotedebugtut.pod
	#pod2latex -full lib/GRID/Machine/remotedebugtut.pod
	latex remotedebugtut
	latex remotedebugtut
	makeindex remotedebugtut; latex remotedebugtut.tex 
	pod2latex -full -prefile preamble.tex lib/GRID/Machine/Process.pod
	latex Process
	latex Process
	makeindex Process; latex Process.tex 
	pod2latex -full -prefile preamble.tex lib/GRID/Machine/Group.pod
	latex Group
	latex Group
	makeindex Group; latex Group.tex 

html: doc
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/Core.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/REMOTE.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/IOHandle.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/perlparintro.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/remotedebugtut.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/Process.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/GRID/Machine/Group.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc scripts/remotetest.pl

remotetest:
	perl scripts/remotetest.pl ${DISTVNAME}.tar.gz <<MACHINES>>

coverage:
	cover -delete
	make HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover

.PHONY: tags
tags:
	/usr/share/vim/vim71/tools/pltags.pl lib/GRID/Machine/*.pm lib/GRID/Machine.pm
	ctags -a --exclude=examples --exclude=t --exclude=doc --exclude=tt2

EOT

  # Replace variables
  # TODO: Check that all <<variables>> are present in @_
  for my $k (keys(%var)) {
	  my $r = $var{$k};
    s/<<$k>>/$r/ge;
  }

  return $_;
}

__END__

=head1 NAME 

Makefile.PL - Makefile generator for GRID::Machine. Developer notes

=head1 SYNOPSIS

=over 2

=item * When working as a developer place in etc/ a script to customize your
environment, then do s.t. like:

           source etc/casianoperl5lib

to set the appropriate environment variables. Some variables to set are:

  PATH                  to execute scripts
  PERL5LIB              to find any modules required
  DEVELOPER             used by many skip tests
  GRID_REMOTE_MACHINE   the remote machine used for testing (see C<t/*.t> files)
  MACHINES              a white space string containing the machines
                        for the 'remotetest' target

=item * To build the documentation, you need L<Template> installed. Issue the command:

  $ make -f makepods

and the C<.pod> files will be built from the templates in C<tt2/>

=item * To build the *.html files:

   $ make -f makepods html

=item * To build pdf files:

   make -f makepods pdf

=item * To delete generated docs (*.html, *.pdf, etc.)

   make -f makepods clean

=item * To run the tests on remote machines:

   make remotetest

(Set the environment variable C<GRID_REMOTE_MACHINE> to the remote machine. 

=item * To use L<Devel::Cover> to study test coverage:

   make coverage

=item * To produce tags:

   make tags

=back

=head1 DEPENDENCIES

To use this C<Makefile.PL> as developer is convenient to have installed:

=over 2

=item * Template toolkit

=item * Pod2LaTeX

=item * LaTeX

=item * mpod2html

=item * Devel::Cover

=back

=head1 AUTHOR
 
Casiano Rodriguez-Leon (casiano@ull.es)

=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2006-2009 Casiano Rodriguez-Leon (casiano@ull.es). All rights reserved.

These modules are free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 




