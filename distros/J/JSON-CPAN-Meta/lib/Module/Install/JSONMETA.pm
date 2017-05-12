use strict;
use warnings;
package Module::Install::JSONMETA;
use Module::Install::Base;

BEGIN {
  our @ISA = qw(Module::Install::Base);
  our $ISCORE  = 1;
  our $VERSION = '7.001';
}

=head1 NAME

Module::Install::JSONMETA - (deprecated) write META.json instead of META.yml

=head1 ACHTUNG

B<Achtung!>  This library will soon be obsolete as EUMM moves to use the
official L<CPAN::Meta::Spec> JSON files.

=cut

our $json;
sub jsonmeta {
  my ($self) = @_;

  unless (eval { require JSON; JSON->VERSION(2); 1 }) {
    die "could not load JSON.pm version 2 or better; can't use jsonmeta\n"
      if $self->is_admin;
    return; # Not admin, just silently ignore.
  }

  $self->_hook_yaml_tiny;
  $self->_hook_admin_metadata;
  
}

sub _hook_yaml_tiny { 

  require YAML::Tiny;

  $json ||= JSON->new->ascii(1)->pretty;
  
  no warnings 'redefine';

  *YAML::Tiny::Dump = sub {
    my $data = shift;
    $data->{generated_by} &&= $data->{generated_by}
                            . ' using ' . __PACKAGE__
                            .  ' version '
                            .  __PACKAGE__->VERSION;
    $json->encode($data) . "\n"
  };

  *YAML::Tiny::Load = sub {
    $json->decode(shift);
  };

  *YAML::Tiny::LoadFile = sub {
    open FILE, "<", shift or die $!;
    local $/;
    my $data = <FILE>;
    close FILE;
    $json->decode($data);
  }
}

sub _hook_admin_metadata {
  my $mi = shift;

  return unless $mi->is_admin;

  no warnings 'redefine';
  *Module::Install::Admin::Metadata::read_meta = sub {
    my $self = shift;

    # Admin time only, so this should be okay to just die
    require YAML::Tiny;

    my @docs = YAML::Tiny::LoadFile('META.json');
    return $docs[0];
  };

  *Module::Install::Admin::Metadata::meta_generated_by_us = sub {
    my ($self, $req_version) = @_;

    my $meta = $self->read_meta;
    my $want  = ref($self->_top);

    $want .= " version " . $req_version
      if defined $req_version;

    $DB::single = 1;
    return $meta->{generated_by} =~ /^\Q$want\E/;
  };

  *Module::Install::Admin::Metadata::remove_meta = sub {
    my $self = shift;
    my $ver  = $self->_top->VERSION;

    return unless -f 'META.json';
    return unless $self->meta_generated_by_us($ver);
    unless (-w 'META.json') {
      warn "Can't remove META.json file. Not writable.\n";
      return;
    }
    warn "Removing auto-generated META.json\n";
    unless ( unlink 'META.json' ) {
      die "Couldn't unlink META.json:\n$!";
    }
    return;
  };

  *Module::Install::Admin::Metadata::write_meta = sub {
    my $self = shift;
    if ( -f "META.json" ) {
      return unless $self->meta_generated_by_us();
    } else {
      $self->clean_files('META.json');
    }
    print "Writing META.json\n";
    Module::Install::_write("META.json", $self->dump_meta);
    return;
  };
}

1;
