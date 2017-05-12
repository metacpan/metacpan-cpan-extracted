use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaYAML::Minimal;

our $VERSION = '0.001001';

# ABSTRACT: Generate a reductionist YAML META file for compatibility only

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with around );
use Try::Tiny qw( try catch );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

with 'Dist::Zilla::Role::FileGatherer';

has filename => (
  is      => 'ro',
  isa     => 'Str',
  default => 'META.yml',
);

has version => (
  is      => 'ro',
  isa     => 'Num',
  default => '1.4',
);

around dump_config => config_dumper( __PACKAGE__, qw( filename version ) );

__PACKAGE__->meta->make_immutable;
no Moose;





sub gather_files {
  my ($self,) = @_;

  require Dist::Zilla::File::FromCode;
  require YAML::Tiny;
  require CPAN::Meta::Converter;
  CPAN::Meta::Converter->VERSION(2.101550);    # improved downconversion
  require CPAN::Meta::Validator;
  CPAN::Meta::Validator->VERSION(2.101550);    # improved downconversion

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code_return_type => 'text',
    code => sub {
      my $distmeta = $zilla->distmeta;

      my $validator = CPAN::Meta::Validator->new($distmeta);

      if ( not $validator->is_valid ) {
        my $msg = "Invalid META structure.  Errors found:\n";
        $msg .= join "\n", $validator->errors;
        $self->log_fatal($msg);
      }

      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert( version => $self->version );

      for my $key ( keys %{$output} ) {
        delete $output->{$key} if $key =~ /\Ax_/sx;
      }

      my $yaml = try {
        YAML::Tiny->new($output)->write_string; # text!
      }
      catch {
        $self->log_fatal('Could not create YAML string: ' . YAML::Tiny->errstr);
      };
      return $yaml;
    },
  });

  $self->add_file($file);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaYAML::Minimal - Generate a reductionist YAML META file for compatibility only

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

  [MetaYAML::Minimal]
  filename = META.yml ; default
  version  = 1.4      ; default

=head1 DESCRIPTION

Generally, if you're creating both C<META.json> and C<META.yml>, then you're doing so purely for compatibility reasons.

In such circumstances, using the same meta-data for both leads to a lot of cruft in C<META.yml>

This L<C<Dist::Zilla>|Dist::Zilla> extension is for such circumstances.

However, if you are I<only> shipping C<META.yml> and B<NOT> C<META.json>, then using this extension
would be harmful and cause loss of information.

Presently, this extension is a I<PROTOTYPE>, and just culls fields leading with C<x_> passed by C<Dist::Zilla>.

The final behavior may require enhancements to C<CPAN::Meta::Converter> and might be possibly superseded
by patches to C<MetaYAML> itself.

=for Pod::Coverage gather_files

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
