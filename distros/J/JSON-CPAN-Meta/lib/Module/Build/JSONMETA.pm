use strict;
use warnings;
package Module::Build::JSONMETA;
BEGIN {
our $VERSION = '7.001';
}

=head1 NAME

Module::Build::JSONMETA - (depreacted) write META.json instead of META.yml

=head1 SYNOPSIS

B<Achtung!>  This library will soon be obsolete as Module::Build moves to use
the official L<CPAN::Meta::Spec> JSON files.

This interface may be changed in the future if someone with more Module::Build
expertise steps forward.

  ----- in Build.PL -----

  use Module::Build;
  use Module::Build::JSONMETA;

  my $class = Module::Build->subclass(
    code => Module::Build::JSONMETA->code,
  );

  my $build = $class->new( ... );

  $build->create_build_script;

=cut

my $CODE;
BEGIN {
  $CODE = <<'END_CODE';
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->metafile('META.json') if $self->metafile eq 'META.yml';
  return $self;
}

sub write_metafile {
  my ($self) = @_;
  my $data = {};
  $self->prepare_metadata($data);

  $data->{generated_by} = GENERATED_BY;

  require JSON;
  JSON->VERSION(2);
  my $json = JSON->new->ascii(1)->pretty->encode($data);

  my $metafile = $self->metafile;

  open my $fh, '>', $metafile or die "can't open $metafile for writing: $!";
  print {$fh} "$json\n"       or die "can't print metadata to $metafile: $!";
  close $fh                   or die "error closing $metafile: $!";

  $self->{wrote_metadata} = 1;
  $self->_add_to_manifest('MANIFEST', $metafile);
}
END_CODE

  my $generated_by = join ' version ', __PACKAGE__, __PACKAGE__->VERSION;
  $CODE =~ s/GENERATED_BY/q{$generated_by}/;
}

sub code { $CODE }

1;
