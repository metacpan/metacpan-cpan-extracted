package Evo::Export::Meta;
use Evo 'Evo::Internal::Util; Carp croak; Module::Load load';

our @CARP_NOT = qw(Evo Evo::Export Evo::Internal::Util);

sub package($self) { $self->{package} }
sub symbols($self) { $self->{symbols} //= {} }

sub new ($me, $pkg, %opts) {
  $me = ref($me) if ref $me;
  bless {%opts, package => $pkg}, $me;
}

sub find_or_bind_to ($me, $pkg, %opts) {
  no strict 'refs';    ## no critic
  no warnings 'once';
  ${"${pkg}::EVO_EXPORT_META"} ||= $me->new($pkg, %opts);
}

# it's important to return same function for the same module
# we're storing it in the module, not in slot, to be able to easy destroy a module
sub request ($self, $name, $dpkg) {
  my $slot = $self->find_slot($name);
  my $fn;
  my $type = $slot->{type};
  if ($type eq 'code') {
    $fn = $slot->{code};
  }
  elsif ($type eq 'gen') {
    no warnings 'once';
    no strict 'refs';    ## no critic
    my $pkg = $self->package;
    my $cache = ${"${dpkg}::EVO_EXPORT_CACHE"} ||= {};
    return $cache->{$pkg}{$name} if $cache->{$pkg}{$name};
    return $cache->{$pkg}{$name} = $slot->{gen}->($self->package, $dpkg);
  }

  croak "Something wrong" unless $fn;
  return $fn;
}

# traverse to find gen via links, return Module, name, gen
sub find_slot ($self, $name) {
  croak qq{"${\$self->package}" doesn't export "$name"} unless my $slot = $self->symbols->{$name};
}

sub init_slot ($self, $name, $val) {
  my $pkg = $self->package;
  croak "$pkg already exports $name" if $self->symbols->{$name};
  $self->symbols->{$name} = $val;
}

sub export_from ($self, $name, $origpkg, $origname) {
  my $slot = $self->find_or_bind_to($origpkg)->find_slot($origname);
  $self->init_slot($name, $slot);
}

sub export_gen ($self, $name, $gen) {
  $self->init_slot($name, {gen => $gen, type => 'gen'});
}

sub export_code ($self, $name, $sub) {
  $self->init_slot($name, {type => 'code', code => $sub});
}

sub export ($self, $name_as) {
  my $pkg = $self->package;
  my ($name, $as) = split ':', $name_as;
  $as ||= $name;
  my $full = "${pkg}::$name";
  no strict 'refs';    ## no critic
  my $sub = *{$full}{CODE} or croak "Subroutine $full doesn't exists";
  $self->export_code($as, $sub);
}


sub export_proxy ($self, $origpkg, @xlist) {
  $origpkg = Evo::Internal::Util::resolve_package($self->package, $origpkg);
  load $origpkg;
  my @list = $self->find_or_bind_to($origpkg)->expand_wildcards(@xlist);

  foreach my $name_as (@list) {
    my ($origname, $name) = split ':', $name_as;
    $name ||= $origname;
    $self->export_from($name, $origpkg, $origname);
  }
}


sub expand_wildcards ($self, @list) {
  my %symbols = $self->symbols->%*;
  my (%minus, %res);
  foreach my $cur (@list) {
    if ($cur eq '*') {
      croak "${\$self->package} exports nothing" unless %symbols;
      $res{$_}++ for keys %symbols;
    }
    elsif ($cur =~ /^-(.+)/) {
      $minus{$1}++;
    }
    else {
      $res{$cur}++;
    }
  }
  return (sort grep { !$minus{$_} } keys %res);
}

sub install ($self, $dst, @xlist) {
  my @list = $self->expand_wildcards(@xlist);

  my $liststr = join '; ', @list;
  my $exporter = $self->package;

  my %patch;
  foreach my $name_as (@list) {
    my ($name, $as) = split ':', $name_as;
    $as ||= $name;
    my $fn = $self->request($name, $dst);
    $patch{$as} = $fn;
  }
  Evo::Internal::Util::monkey_patch $dst, %patch;
}

no warnings 'once';
*info = *symbols;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Export::Meta

=head1 VERSION

version 0.0403

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
