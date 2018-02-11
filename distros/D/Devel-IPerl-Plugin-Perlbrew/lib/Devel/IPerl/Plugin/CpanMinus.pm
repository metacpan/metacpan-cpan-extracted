package Devel::IPerl::Plugin::CpanMinus;

use strict;
use warnings;

our $VERSION = '0.01';

sub register {
  my ($class, $iperl) = @_;

  my $options = {
    cpanm             => [],
    cpanm_info        => [cmd => 'info'],
    cpanm_installdeps => [installdeps => 1],
  };

  $iperl->load_plugin('Perlbrew') unless $iperl->can('perlbrew');

  for my $name (qw{cpanm cpanm_info cpanm_installdeps}) {
    $iperl->helper($name => sub {
      my ($ip, $ret, %env) = (shift, -1);
      eval 'require App::cpanminus::fatscript; 1;';
      return $ret if $@;
      return $ret if 0 == @_; # nothing to do?
      my @filtered = @_;
      my $cpanm = App::cpanminus::script->new(
        @{$options->{$name}},
        argv => [@filtered]);
      $cpanm->parse_options();
      $cpanm->{interactive} = 0;
      delete $cpanm->{action}
        if exists $cpanm->{action} and $cpanm->{action} =~ m/upgrade/;
      return $cpanm->doit;
    });
  }
  return 1;
}

1;

=pod

=head1 NAME

Devel::IPerl::Plugin::CpanMinus - cpanm client

=head1 DESCRIPTION

This plugin enables users to curate L<local::lib> as set up in
L<Devel::IPerl::Plugin::Perlbrew>.

Once users have access to L<Devel::IPerl::Plugin::Perlbrew> they wish to have
the ability to curate the libraries they
L<create|Devel::IPerl::Plugin::Perlbrew#perlbrew_lib_create>. While this is easy
to achieve at the command line, the notebook is an excellent place to document
this workflow as well.

=head1 SYNOPSIS

  IPerl->load_plugin('CpanMinus') unless IPerl->can('cpanm');
  # create and use a library
  IPerl->perlbrew_lib_create('cpanm-test');
  IPerl->perlbrew('cpanm-test');
  # install dependencies for notebook
  IPerl->cpanm_installdeps('.');
  # install a specific module
  IPerl->cpanm('Test::Pod');

=head1 IPerl Interface Method

=head2 register

Called by C<<< IPerl->load_plugin('CpanMinus') >>>.

=head1 REGISTERED METHODS

These all take as arguments any arguments that are accepted by the command line
client L<cpanm>.

=head2 cpanm

  # install a specific module
  IPerl->cpanm('Test::Pod');

Use L<cpanm> to install the given module.

=head2 cpanm_info

  IPerl->cpanm_info('Test::Pod');

Displays the distribution information in "AUTHOR/Dist-Name-ver.tar.gz" format.

=head2 cpanm_installdeps

  # install dependencies as listed in cpanfile in current directory
  IPerl->cpanm_installdeps('.');
  # install dependencies for a module
  IPerl->cpanm_installdeps('-n', '--quiet', 'Test::Pod');

=cut
