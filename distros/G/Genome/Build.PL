#!/usr/bin/perl
# Use local perl, not some perl on an application server!

use Config;
use Module::Build;

BEGIN {
  unshift @INC, "$ENV{PWD}/blib/lib";
}

my $class = Module::Build->subclass (
    class => 'Pod::Builder',
    code => <<'EOS',

      sub ACTION_clean {
        # FIXME: is this safe?
        use File::Path qw/rmtree/;
        rmtree "./_build";
        rmtree "./blib";
        rmtree "./gmt-bindoc";
        rmtree "./genome-bindoc";
        unlink "./Build";
        unlink "./MYMETA.yml";
      }

      sub ACTION_ur_docs {
        use File::Copy qw/copy/;
        $ENV{ANSI_COLORS_DISABLED} = 1;
        eval {
          local @INC = @INC;
          unshift @INC, 'blib/lib';
          die $@ if $@;
          eval "use Genome::Model::Tools";
          die $@ if $@;

          foreach my $exec ('genome','gmt') {
            UR::Namespace::Command::Update::Pod->execute(
                class_name => 'Genome::Model::Tools',
                executable_name => $exec,
                targets => ['Genome::Model::Tools'],
                output_path => 'cmd-bindoc'
            );
          }
        };
        die "failed to extract pod: $!: $@" if ($@);
      }

      sub ACTION_docs {
        my $self = shift;
        $self->depends_on('code');
        $self->depends_on('ur_docs');
        $self->depends_on('manpages', 'html');
      }
       
      sub man1page_name {
        my ($self, $file) = @_;
        $file =~ s/.pod$//;
        return $self->SUPER::man1page_name($file);
      }

EOS
);

my $build = $class->new(
  module_name => 'Genome',
  license => 'lgpl',
  requires => {
    'perl' => 'v5.8.7',
    'Carp' => '',
    'File::Basename' => '',
    'File::Temp' => '',
    'IO::File' => '',
    'IO::String' => '',
    'Sys::Hostname' => '',
    'UR' => '0.29',
    'Getopt::Complete' => '',
  },
  cpan_client => 'cpanm',
  #test_files => [qw|t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t|],
  #tap_harness_args => { jobs => 8 },
  bindoc_dirs => ['cmd-bindoc'],
  script_files => [ 'bin/genome', 'bin/gmt' ]
);
$build->create_build_script;
