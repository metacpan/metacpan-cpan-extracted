package Dist::Zilla::Plugin::LatestPrereqs;
BEGIN {
  $Dist::Zilla::Plugin::LatestPrereqs::VERSION = '0.4';
}

use Moose;
use CPAN;
use Module::CoreList;
with 'Dist::Zilla::Role::PrereqSource';

has 'skip_core_modules' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


sub register_prereqs {
  my ($self) = @_;
  my $zilla = $self->zilla;
  my $skip_core = $self->skip_core_modules;

  my $prereqs = $zilla->prereqs;
  my $cpan    = _startup_cpan();

  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};

  for my $phase (keys %$guts) {
    for my $type (keys %{$guts->{$phase}}) {
      my $prereqs = $guts->{$phase}{$type}->as_string_hash;

      for my $module (keys %$prereqs) {
        $self->log_debug("Check '$module', type '$type' phase '$phase'");
        ## allow for user defined required version
        next if $prereqs->{$module};

        if ($skip_core) {
          my $rel = Module::CoreList->first_release($module);
          if ($rel && $rel <= $]) {
            $self->log_debug("Skipping core module $module ($rel <= $])");
            next;
          }
        }

        ## fetch latest version
        $self->log_debug("Fetch latest version for '$module' from CPAN");
        my $info = $cpan->expand('Module', $module);
        unless ($info) {
          $self->log("Could not find info on Module '$module'");
          next;
        }
        next unless my $version = $info->cpan_version;

        ## register the latest version
        $self->log_debug("Update version of '$module' to '$version'");
        $zilla->register_prereqs(
          { type  => $type,
            phase => $phase,
          },
          $module => $version,
        );
      }
    }
  }
}

sub _startup_cpan {
  ## Hide output of CPAN
  $CPAN::Be_Silent++;

  return 'CPAN::Shell';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__


=head1 NAME

Dist::Zilla::Plugin::LatestPrereqs - adjust prereqs to use latest version available


=head1 VERSION

version 0.4

=head1 SYNOPSIS

At the B<BOTTOM> of your C<dist.ini> file:

    [LatestPrereqs]
    
    ## Optionally skip core modules
    [LatestPrereqs]
    skip_core_modules = 1
    

=head1 DESCRIPTION

This plugin will filter over all your declared or discovered
prerequisites, contact CPAN, and adjust the version to the latest one
available.

This will make sure that your module will be installed with the latest
version available on CPAN at the time you built your package.

The most common use for this techinique is for L<Task> modules. You can
rebuild your Task module on a regular basis to make sure it has the
latest versions of your dependencies.

Please note that this plugin only makes sure that the version of the
prereq is the latest at the time you build your package, not the latest
at the time the package is installed.

To do that it would require updates to the CPAN toolchain. Although I
would welcome that, this plugin implements the next best thing.


=head2 Core modules options

B<NOTE WELL:> this feature should be considered alpha. The interface
might change in future versions.

The option C<skip_core_modules> can be used to control the behaviour of
this plugin with core modules (as defined by the
L<Module::CoreList|Module::CoreList> API).

If set to 1, we will skip forcing the latest version on modules that are
part of the perl core, version equal or below to the one used to release
the module.

An example: you have two modules on your C<< [Prereqs] >> list,
C<Digest::SHA> part of the core since 5.009003, and C<HTTP::Tiny> part
of the core since 5.013009. With C<skip_core_modules=1>, the following
will happen:

=over 4

=item * If you release your module using perl 5.008009, both
C<Digest::SHA> and C<HTTP::Tiny> will be forced to the
lastest version.

=item * If you release your module using perl 5.012003, the
C<Digest::SHA> will not be forced to the lastest version, but
C<HTTP::Tiny> will.

=item * If you release your module using perl 5.014000, both
C<ExtUtils::MakeMaker> and C<HTTP::Tiny> will not be forced to the
lastest version.

=back

By default (0) all modules will get the latest version.

Idealy we would make this decision based on the perl version of the
person that will install your distribution, but for now that is not
easy to do.


=head1 EXTRA REQUIREMENTS

This plugin uses the L<CPAN> module, but hides the output, so make sure
you have your cpan shell properly configured before trying to use this.


=head1 BUGS

This modules abuses the internals of the L<CPAN::Meta::Prereqs> module.
This is a bug, but right now that module does not provide an API to
traverse its internals.

As soon as it does, I'll rewrite this module to use it.

Until then, this module might break with new releases of
L<CPAN::Meta::Prereqs>.


=head1 CREDITS

Marcel Gruenauer (hanekomu) described something like this in his
article "Repeatedly installing Task::* distributions":

L<http://hanekomu.at/blog/dev/20091005-1227-repeatedly_installing_task_distributions.html>

But the method he suggested does not work because it does not force the
latest version of the module to be installed.

A L<Dist::Zilla> plugin that implements what Marcel describes is also
available, see L<Dist::Zilla::Plugin::MakeMaker::SkipInstall>.

Mike Doherty added the first version of the skip core modules feature.


=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Plugin::MakeMaker::SkipInstall>.


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=begin make-pod-coverage-happy

=over 4

=item register_prereqs()

Loops over all the given prereqs and uses L<CPAN> to figure out which is
the latest version of the module.

=back

=end make-pod-coverage-happy

=cut