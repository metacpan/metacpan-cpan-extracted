package Dist::Zooky::DistIni;
$Dist::Zooky::DistIni::VERSION = '0.22';
# ABSTRACT: Generates a Dist::Zilla dist.ini file

use strict;
use warnings;
use Class::Load ();
use Moose;
use Module::Load::Conditional qw[check_install];
use Module::Pluggable search_path => 'Dist::Zooky::DistIni', except => 'Dist::Zooky::DistIni::Prereqs';
use Dist::Zooky::DistIni::Prereqs;

with 'Dist::Zilla::Role::TextTemplate';

has 'type' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'metadata' => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
);

has 'bundle' => (
  is => 'ro',
  isa => 'Str',
);

my $temphead =
q|name = {{ $name }}
version = {{ $version }}
{{ $OUT .= join "\n", map { "author = $_" } @authors; }}
{{ $OUT .= join "\n", map { "license = $_" } @licenses; }}
{{ ( my $holder = $authors[0] ) =~ s/\s*\<.+?\>\s*//g; "copyright_holder = $holder"; }}

|;

my $tempstd =
q|[GatherDir]
[PruneCruft]
[ManifestSkip]
[MetaYAML]
[MetaJSON]
[License]

{{ -e 'README' ? ';[Readme]' : '[Readme]'; }}

[ExecDir]
{{ $OUT = "dir = scripts" if -d 'scripts' }}

[ExtraTests]
[ShareDir]

{{ $OUT .= +( $type eq 'ModBuild' ? '[ModuleBuild]' : '[MakeMaker]' ) }}

[Manifest]
[TestRelease]
[ConfirmRelease]
[UploadToCPAN]|;

sub write {
  my $self = shift;
  my $file = shift || 'dist.ini';
  my %stash;
  $stash{type} = $self->type;
  $stash{$_} = $self->metadata->{prereqs}->{$_}->{requires}
    for qw(configure build runtime);
  $stash{$_} = $self->metadata->{$_} for qw(author license version name);
  $stash{"${_}s"} = delete $stash{$_} for qw(author license);
  my $template = $temphead . ( $self->bundle ? q|[@| . $self->bundle . qq|]| : $tempstd ) . "\n";
  my $content = $self->fill_in_string(
    $template,
    \%stash,
  );

  foreach my $plugin ( $self->plugins ) {
     Class::Load::load_class( $plugin );
     my $add = $plugin->new( type => $self->type, metadata => $self->metadata )->content;
     next unless $add;
     $content = join "\n", $content, $add;
  }

  my $prereqs = Dist::Zooky::DistIni::Prereqs->new( type => $self->type, metadata => $self->metadata )->content;
  $content = join("\n", $content, $prereqs) if $prereqs;

  open my $ini, '>', $file or die "Could not open '$file': $!\n";
  print $ini $content;
  close $ini;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[And Dist::Zooky too!];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::DistIni - Generates a Dist::Zilla dist.ini file

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  my $meta = {
    type => 'MakeMaker',
    name => 'Foo-Bar',
    version => '0.02',
    author => [ 'Duck Dodgers', 'Ivor Biggun' ],
    license => [ 'Perl_5' ],
    prereqs => {
      'runtime' => {
        'requires' => { 'Moo::Cow' => '0.19' },
      },
    }
  };

  my $distini = Dist::Zooky::DistIni->new( metadata => $meta );
  $distini->write();

=head1 DESCRIPTION

Dist::Zooky::DistIni takes meta data and writes a L<Dist::Zilla> C<dist.ini> file.

=head2 ATTRIBUTES

These attributes are passed to DistIni plugins.

=over

=item C<type>

A required attribute, the type of distribution, C<MakeMaker> for L<ExtUtils::MakeMaker> or
L<Module::Install> ( yeah, I know ) based distributions, or C<ModBuild> for L<Module::Build>
based distributions.

=item C<metadata>

A required attribute. This is a C<HASHREF> of meta data.

=back

=head2 METHODS

=over

=item C<write>

Writes a C<dist.ini> file with the provides C<metadata>. Takes an optional parameter, which is the filename
to write to, the default being C<dist.ini>.

=back

=head1 NAME

Dist::Zooky::DistIni - Generates a Dist::Zilla dist.ini file

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
