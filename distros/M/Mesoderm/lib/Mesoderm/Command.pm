## Copyright (C) Graham Barr
## vim: ts=8:sw=2:expandtab:shiftround

package Mesoderm::Command;
{
  $Mesoderm::Command::VERSION = '0.140780';
}
use Moose;
with 'MooseX::Getopt';

use MooseX::Types::Path::Class qw(File);
use DBI;
use SQL::Translator;
use File::Temp;
use Path::Class;

# STUPID check in perltidy
sub File::Temp::print { print {shift} @_ }

has [qw(user pass)] => (
  traits => ['Getopt'],
  is     => 'rw',
  isa    => 'Str',
);

has [qw(dsn schema_class)] => (
  traits   => ['Getopt'],
  is       => 'rw',
  isa      => 'Str',
  required => 1,
);

has scaffold_class => (
  traits  => ['Getopt'],
  is      => 'rw',
  isa     => 'Str',
  default => 'Mesoderm',
);

has output => (
  traits  => ['Getopt'],
  is      => 'rw',
  isa     => File,
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $output_dir = Path::Class::dir("lib")->subdir(split(/::/, $self->schema_class));
    $output_dir->mkpath unless -d $output_dir;
    $output_dir->file("_scaffold.pm");
  },
);

has tidy => (
  traits  => ['Getopt'],
  is      => 'rw',
  isa     => 'Bool',
  default => 1,
);

sub execute {
  my ($self)         = @_;
  my $schema_class   = $self->schema_class;
  my $scaffold_class = $self->scaffold_class;

  Class::Load::load_class($scaffold_class);

  my $sqlt = SQL::Translator->new(
    parser      => 'DBI',
    parser_args => {
      dsn         => $self->dsn,
      db_user     => $self->user,
      db_password => $self->pass,
    },
  );
  
  $sqlt->parser->($sqlt);

  my $scaffold = $scaffold_class->new(
    schema       => $sqlt->schema,
    schema_class => $self->schema_class,
  );

  my $output = $self->output;

  print "Writing scaffold for $schema_class to $output\n";
  my $output_dir = Path::Class::file($output)->parent;
  $output_dir->mkpath;
  my $tmp_output = File::Temp->new(DIR => $output_dir);

  if ($self->tidy) {
    require Perl::Tidy;

    open(my $out_fh, ">", \my $buffer);
    $scaffold->produce($out_fh);

    Getopt::Long::Configure('default');
    Perl::Tidy::perltidy(
      source      => \$buffer,
      destination => $tmp_output,
      argv        => ['-npro', '-l', '120'],
    );
  }
  else {
    $scaffold->produce($tmp_output);
  }

  rename($tmp_output->filename, $output)
    and exit(0);

  die "Cannot create $output: $!\n";
}

1;
