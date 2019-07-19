package Dist::Zilla::Plugin::Author::Plicease::Tests 2.37 {

  use 5.014;
  use Moose;
  use File::chdir;
  use File::Path qw( make_path );
  use Path::Tiny qw( path );
  use Sub::Exporter::ForMethods qw( method_installer );
  use Data::Section { installer => method_installer }, -setup;
  use Dist::Zilla::MintingProfile::Author::Plicease;

  # ABSTRACT: add author only release tests to xt/release


  with 'Dist::Zilla::Role::FileGatherer';
  with 'Dist::Zilla::Role::BeforeBuild';
  with 'Dist::Zilla::Role::InstallTool';
  with 'Dist::Zilla::Role::TestRunner';

  sub mvp_multivalue_args { qw( diag diag_preamble ) }
  
  has source => (
    is      =>'ro',
    isa     => 'Str',
  );
  
  has diag => (
    is      => 'ro',
    default => sub { [] },
  );
  
  has diag_preamble => (
    is      => 'ro',
    default => sub { [] },
  );
  
  has _diag_content => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
  );
  
  has test2_v0 => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
  );
  
  sub gather_files
  {
    my($self) = @_;
    
    require Dist::Zilla::File::InMemory;
  
    $self->add_file(
      Dist::Zilla::File::InMemory->new(
        name    => $_,
        content => ${ $self->section_data($_) },
      )
    ) for qw( xt/author/strict.t
              xt/author/eol.t
              xt/author/pod.t
              xt/author/no_tabs.t
              xt/author/pod_coverage.t
              xt/author/pod_spelling_common.t
              xt/author/pod_spelling_system.t
              xt/author/version.t
              xt/release/changes.t
              xt/release/fixme.t );
  }
  
  sub before_build
  {
    my($self) = @_;
  
    my $source = defined $self->source
    ? $self->zilla->root->child($self->source)
    : Dist::Zilla::MintingProfile::Author::Plicease->profile_dir->child("default/skel/xt/release");
  
    my $diag = $self->zilla->root->child("t/00_diag.t");
    my $content = $source->parent->parent->child('t', $self->test2_v0 ? '00_xdiag.t' : '00_diag.t' )->absolute->slurp;
    $content =~ s{## PREAMBLE ##}{join "\n", map { s/^\| //; $_ } @{ $self->diag_preamble }}e;
    $self->_diag_content($content);
  }
  
  # not really an installer, but we have to create a list
  # of the prereqs / suggested modules after the prereqs
  # have been calculated
  sub setup_installer
  {
    my($self) = @_;
    
    my %list;
    my $prereqs = $self->zilla->prereqs->as_string_hash;
    foreach my $phase (keys %$prereqs)
    {
      next if $phase eq 'develop';
      foreach my $type (keys %{ $prereqs->{$phase} })
      {
        foreach my $module (keys %{ $prereqs->{$phase}->{$type} })
        {
          next if $module =~ /^(perl|strict|warnings|base)$/;
          $list{$module}++;
        }
      }
    }
    
    if($list{'JSON::MaybeXS'})
    {
      $list{'JSON::PP'}++;
      $list{'JSON::XS'}++;
    }
    
    if(my($alien) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $self->zilla->plugins })
    {
      $list{$_}++ foreach keys %{ $alien->module_build_args->{alien_bin_requires} };
    }
    
    foreach my $lib (@{ $self->diag })
    {
      if($lib =~ /^-(.*)$/)
      {
        delete $list{$1};
      }
      elsif($lib =~ /^\+(.*)$/)
      {
        $list{$1}++;
      }
      else
      {
        $self->log_fatal('diagnostic override must be prefixed with + or -');
      }
    }
  
    my $code = '';
    
    $code = "BEGIN { eval q{ use EV; } }\n" if $list{EV};
    $code .= '$modules{$_} = $_ for qw(' . "\n";
    $code .= join "\n", map { "  $_" } sort keys %list;
    $code .= "\n);\n";
    $code .= "eval q{ require Test::Tester; };" if $list{'Test::Builder'} && $list{'Test::Tester'};
    
    my($file) = grep { $_->name eq 't/00_diag.t' } @{ $self->zilla->files };
  
    my $content = $self->_diag_content;
    $content =~ s{## GENERATE ##}{$code};
  
    if($file)
    {
      $file->content($content);
    }
    else
    {
      $file = Dist::Zilla::File::InMemory->new({
        name => 't/00_diag.t',
        content => $content
      });
      $self->add_file($file);
    }
  
    $self->zilla->root->child(qw( t 00_diag.t ))->spew($content);
  }
  
  sub test
  {
    my($self, $target) = @_;
    system 'prove', '-br', 'xt';
    $self->log_fatal('release test failure') unless $? == 0;
  }
  
  __PACKAGE__->meta->make_immutable;

}

1;


package Dist::Zilla::Plugin::Author::Plicease::Tests;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Tests - add author only release tests to xt/release

=head1 VERSION

version 2.37

=head1 SYNOPSIS

 [Author::Plicease::Tests]
 source = foo/bar/baz ; source of tests
 diag = +Acme::Override::INET
 diag = +IO::Socket::INET
 diag = +IO::SOCKET::IP
 diag = -EV

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__[ xt/author/strict.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Strict' 
    unless eval q{ use Test::Strict; 1 };
};
use Test::Strict;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

unshift @Test::Strict::MODULES_ENABLING_STRICT,
  'ozo',
  'Test2::Bundle::SIPS',
  'Test2::V0',
  'Test2::Bundle::Extended';
note "enabling strict = $_" for @Test::Strict::MODULES_ENABLING_STRICT;

all_perl_files_ok( grep { -e $_ } qw( bin lib t Makefile.PL ));


__[ xt/author/eol.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::EOL' 
    unless eval q{ use Test::EOL; 1 };
};
use Test::EOL;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_perl_files_ok(grep { -e $_ } qw( bin lib t Makefile.PL ));


__[ xt/author/no_tabs.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::NoTabs' 
    unless eval q{ use Test::NoTabs; 1 };
};
use Test::NoTabs;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_perl_files_ok( grep { -e $_ } qw( bin lib t Makefile.PL ));


__[ xt/author/pod.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod' 
    unless eval q{ use Test::Pod; 1 };
};
use Test::Pod;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_pod_files_ok( grep { -e $_ } qw( bin lib ));


__[ xt/release/changes.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::CPAN::Changes' 
    unless eval q{ use Test::CPAN::Changes; 1 };
};
use Test::CPAN::Changes;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

do {
  my $old = \&Test::Builder::carp;
  my $new = sub {
    my($self, @messages) = @_;
    return if $messages[0] =~ /^Date ".*" is not in the recommend format/;
    $old->($self, @messages);
  };
  no warnings 'redefine';
  *Test::Builder::carp = $new;
};

changes_file_ok;

done_testing;


__[ xt/release/fixme.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Fixme' 
    unless eval q{ use Test::Fixme 0.14; 1 };
};
use Test::Fixme 0.07;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

run_tests(
  match => qr/FIXME/,
  where => [ grep { -e $_ } qw( bin lib t Makefile.PL Build.PL )],
  warn  => 1,
);


__[ xt/author/pod_coverage.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires 5.010 or better'
    unless $] >= 5.010;
  plan skip_all => 'test requires Test::Pod::Coverage' 
    unless eval q{ use Test::Pod::Coverage; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
};
use Test::Pod::Coverage;
use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, File::Spec->updir, File::Spec->updir, 'author.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_coverage}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

my @private_classes;
my %private_methods;

push @{ $config->{pod_coverage}->{private} },
  'Alien::.*::Install::Files#Inline';

foreach my $private (@{ $config->{pod_coverage}->{private} })
{
  my($class,$method) = split /#/, $private;
  if(defined $class && $class ne '')
  {
    my $regex = eval 'qr{^' . $class . '$}';
    if(defined $method && $method ne '')
    {
      push @private_classes, { regex => $regex, method => $method };
    }
    else
    {
      push @private_classes, { regex => $regex, all => 1 };
    }
  }
  elsif(defined $method && $method ne '')
  {
    $private_methods{$_} = 1 for split /,/, $method;
  }
}

my @classes = all_modules;

plan tests => scalar @classes;

foreach my $class (@classes)
{
  SKIP: {
    my($is_private_class) = map { 1 } grep { $class =~ $_->{regex} && $_->{all} } @private_classes;
    skip "private class: $class", 1 if $is_private_class;
    
    my %methods = map {; $_ => 1 } map { split /,/, $_->{method} } grep { $class =~ $_->{regex} } @private_classes;
    $methods{$_} = 1 for keys %private_methods;
    
    my $also_private = eval 'qr{^' . join('|', keys %methods ) . '$}';
    
    pod_coverage_ok $class, { also_private => [$also_private] };
  };
}


__[ xt/author/pod_spelling_common.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod::Spelling::CommonMistakes' 
    unless eval q{ use Test::Pod::Spelling::CommonMistakes; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML qw( LoadFile ); 1 };
};
use Test::Pod::Spelling::CommonMistakes;
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, File::Spec->updir, File::Spec->updir, 'author.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_spelling_common}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

# TODO: test files in bin too.
all_pod_files_ok;


__[ xt/author/pod_spelling_system.t ]__
use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Spelling' 
    unless eval q{ use Test::Spelling; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
};
use Test::Spelling;
use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, File::Spec->updir, File::Spec->updir, 'author.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_spelling_system}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

add_stopwords(@{ $config->{pod_spelling_system}->{stopwords} });
add_stopwords(qw(
Plicease
stdout
stderr
stdin
subref
loopback
username
os
Ollis
Mojolicious
plicease
CPAN
reinstall
TODO
filename
filenames
login
callback
callbacks
standalone
VMS
hostname
hostnames
TCP
UDP
IP
API
MSWin32
OpenBSD
FreeBSD
NetBSD
unencrypted
WebSocket
WebSockets
timestamp
timestamps
poney
BackPAN
portably
RedHat
AIX
BSD
XS
FFI
perlish
optimizations
subdirectory
RESTful
SQLite
JavaScript
dir
plugins
munge
jQuery
namespace
PDF
PDFs
usernames
DBI
pluggable
APIs
SSL
JSON
YAML
uncommented
Solaris
OpenVMS
URI
URL
CGI
));
all_pod_files_spelling_ok;


__[ xt/author/version.t ]__
use strict;
use warnings;
use Test::More;
use FindBin ();
BEGIN {

  plan skip_all => "test requires Test::Version 2.00"
    unless eval q{
      use Test::Version 2.00 qw( version_all_ok ), { 
        has_version    => 1,
        filename_match => sub { $_[0] !~ m{/(ConfigData|Install/Files)\.pm$} },
      }; 
      1
    };

  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
}

use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, File::Spec->updir, File::Spec->updir, 'author.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

if($config->{version}->{dir})
{
  note "using dir " . $config->{version}->{dir}
}

version_all_ok($config->{version}->{dir} ? ($config->{version}->{dir}) : ());
done_testing;

