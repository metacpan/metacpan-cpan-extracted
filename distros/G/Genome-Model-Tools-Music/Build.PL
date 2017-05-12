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
        rmtree "./cmd-bindoc";
        unlink "./Build";
        unlink "./MYMETA.yml";
      }

      sub ACTION_cmd_docs {
        use File::Copy qw/copy/;
        $ENV{ANSI_COLORS_DISABLED} = 1;
        eval {
          local @INC = @INC;
          unshift @INC, 'blib/lib';
          die $@ if $@;
          eval "use Genome::Model::Tools::Music";
          die $@ if $@;

          foreach my $exec ('genome','gmt') {
            UR::Namespace::Command::Update::Doc->execute(
                class_name => 'Genome::Model::Tools',
                targets => [ 'Genome::Model::Tools::Music' ],
                executable_name => $exec,
                output_path => 'cmd-bindoc',
                output_format => 'pod',
            );
          }
        };
        die "failed to extract pod: $!: $@" if ($@);
      }

      sub ACTION_docs {
        my $self = shift;
        $self->depends_on('code');
        $self->depends_on('cmd_docs');
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
  module_name => 'Genome::Model::Tools::Music',
  license => 'lgpl',
  dist_abstract => 'find mutations of significance in cancer',
  install_path => { 't' => $Config{vendorlib} . "/Genome/Model/Tools" },
  build_requires => {
    'Genome' => '0.06',
    'Text::CSV_XS' => '',
    'Regexp::Common' => '',
    'Statistics::Distributions' => '',
  },
  requires => {
    'Genome' => '0.06',
    'Text::CSV_XS' => '',
    'Regexp::Common' => '',
    'Statistics::Distributions' => '',
  },
  bindoc_dirs => ['cmd-bindoc'],
);

$build->add_build_element('R');
$build->create_build_script;
