package ExtUtils::MakeMaker::META_MERGE::GitHub;
use strict;
use warnings;

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

=head1 NAME

ExtUtils::MakeMaker::META_MERGE::GitHub - Perl package to generate ExtUtils::MakeMaker META_MERGE for GitHub repositories

=head1 SYNOPSIS

Run the included script then copy and paste into your Makefile.PL

  perl-ExtUtils-MakeMaker-META_MERGE-GitHub.pl

or

  perl-ExtUtils-MakeMaker-META_MERGE-GitHub.pl owner repository_name

Generate the META_MERGE then copy and paste into your Makefile.PL

  use ExtUtils::MakeMaker::META_MERGE::GitHub;
  use Data::Dumper qw{Dumper};
  my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"myowner", repo=>"myrepo");
  my %META_MERGE = $mm->META_MERGE;
  print Dumper(\%META_MERGE);

Plugin to your Makefile.PL

  use ExtUtils::MakeMaker;
  use ExtUtils::MakeMaker::META_MERGE::GitHub;
  my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"myowner", repo=>"myrepo");
  WriteMakefile(
                CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker::META_MERGE::GitHub' => 0},
                $mm->META_MERGE,
                ...
               );

=head1 DESCRIPTION

Generates the META_MERGE key and hash value for a normal GitHub repository.

=head1 CONSTRUCTOR

  my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(
             owner => "myowner",
             repo  => "myrepo"
           );

=head2 new

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {@_};
  bless $self, $class;
  return $self;
}

=head1 METHODS

=head2 META_MERGE

Returns then META_MERGE key and a hash reference value for a normal git hub repository.

=cut

sub META_MERGE {
  my $self = shift;
  return (
           META_MERGE => {
             'meta-spec' => {version => $self->version},
             'resources' => {
               homepage   => join('/', $self->base_url, $self->owner, $self->repo),
               bugtracker => {
                 web  => join('/', $self->base_url, $self->owner, $self->repo, 'issues'),
               },
               repository => {
                 type => $self->type,
                 url  => join('/', join(':', $self->base_ssh, $self->owner), $self->repo . '.git'),
                 web  => join('/', $self->base_url, $self->owner, $self->repo . '.git'),
               },
             },
           },
         );
}

=head1 PROPERTIES

=head2 login

=cut

sub login {
  my $self         = shift;
  $self->{'login'} = shift if @_;
  $self->{'login'} = 'git' unless defined $self->{'login'};
  return $self->{'login'};
}

=head2 host

=cut

sub host {
  my $self        = shift;
  $self->{'host'} = shift if @_;
  $self->{'host'} = 'github.com' unless defined $self->{'host'};
  return $self->{'host'};
}

=head2 owner

Sets and returns the GitHub account owner login.

=cut

sub owner {
  my $self         = shift;
  $self->{'owner'} = shift if @_;
  die("Error: $PACKAGE property owner is required") unless $self->{'owner'};
  return $self->{'owner'};
}

=head2 repo

Sets and returns the GitHub repository name.

=cut

sub repo {
  my $self        = shift;
  $self->{'repo'} = shift if @_;
  die("Error: $PACKAGE property repo is required") unless $self->{'repo'};
  return $self->{'repo'};
}

=head2 protocol

=cut

sub protocol {
  my $self            = shift;
  $self->{'protocol'} = shift if @_;
  $self->{'protocol'} = 'https' unless defined $self->{'protocol'};
  return $self->{'protocol'};

}

=head2 version

Meta-Spec Version

  Default: 2

=cut

sub version {
  my $self           = shift;
  $self->{'version'} = shift if @_;
  $self->{'version'} = 2 unless $self->{'version'};
  return $self->{'version'};

}

=head2 type

Resource Repository Type

  Default: git

=cut

sub type {
  my $self        = shift;
  $self->{'type'} = shift if @_;
  $self->{'type'} = 'git' unless $self->{'type'};
  return $self->{'type'};
}

=head2 base_url

Base URL for web client requests

  Default: https://github.com

=cut

sub base_url {
  my $self            = shift;
  $self->{'base_url'} = shift if @_;
  $self->{'base_url'} = sprintf('%s://%s', $self->protocol, $self->host) unless $self->{'base_url'};
  return $self->{'base_url'};
}

=head2 base_ssh

Base URL for ssh client requests

  Default: git@github.com

=cut

sub base_ssh {
  my $self            = shift;
  $self->{'base_ssh'} = shift if @_;
  $self->{'base_ssh'} = sprintf('%s@%s', $self->login, $self->host) unless $self->{'base_ssh'};
  return $self->{'base_ssh'};
}

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

L<https://github.com/metacpan/metacpan-web/issues/2408>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Michael R. Davis

MIT LICENSE

=cut

1;
