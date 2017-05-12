package INI_File;
BEGIN {
  $INI_File::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Tie a hash or an array to an INI file
$INI_File::VERSION = '0.001';
use Moo;
use Config::INI::Reader;
use Config::INI::Writer;
use Path::Class;
use Data::Dumper;

has filename => (
  is => 'ro',
  required => 1,
);

has abs_filename => (
  is => 'ro',
  lazy => 1,
  default => sub { file(shift->filename)->absolute },
);

sub BUILD {
  my ( $self ) = @_;
  $self->abs_filename;
}

sub data {
  my ( $self ) = @_;
  if (-f $self->abs_filename) {
    return $self->load_file;
  } else {
    return {};
  }
}

sub add_data {
  my ( $self, $key, $value ) = @_;
  print "add_data:".$key.":".Dumper($value)."\n" if $ENV{INI_FILE_TRACE};
  my $data = $self->data;
  $data->{$key} = $value;
  $self->save_file($data);
}

sub remove_data {
  my ( $self, $key ) = @_;
  print "remove_data:".$key."\n" if $ENV{INI_FILE_TRACE};
  my $data = $self->data;
  delete $data->{$key};
  $self->save_file($data);
}

sub load_file {
  my ( $self ) = @_;
  print __PACKAGE__.":load_file\n" if $ENV{INI_FILE_TRACE};
  return Config::INI::Reader->read_file($self->abs_filename);
}

sub save_file {
  my ( $self, $data ) = @_;
  print __PACKAGE__.":save_file:".Dumper($data) if $ENV{INI_FILE_TRACE};
  return Config::INI::Writer->write_file($data,$self->abs_filename);
}

sub TIEHASH {
  my ( $class, $filename, @args ) = @_;
  print __PACKAGE__.":TIEHASH:".$filename.(scalar @args ? ":".Dumper(@args) : "\n") if $ENV{INI_FILE_TRACE};
  $class->new(
    filename => $filename,
    @args,
  );
}

sub FETCH {
  my ( $self, $key ) = @_;
  print __PACKAGE__.":FETCH:".$key."\n" if $ENV{INI_FILE_TRACE};
  return $self->data->{$key};
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  print __PACKAGE__.":STORE:".$key.":".Dumper($value) if $ENV{INI_FILE_TRACE};
  $self->add_data($key,$value);
}

sub DELETE {
  my ( $self, $key ) = @_;
  print __PACKAGE__.":DELETE:".$key."\n" if $ENV{INI_FILE_TRACE};
  $self->remove_data($key)
}

sub EXISTS {
  my ( $self, $key ) = @_;
  print __PACKAGE__.":EXISTS:".$key."\n" if $ENV{INI_FILE_TRACE};
  return exists $self->data->{$key};
}

sub SCALAR {
  my ( $self ) = @_;
  print __PACKAGE__.":SCALAR\n" if $ENV{INI_FILE_TRACE};
  return scalar %{$self->data};
}

sub CLEAR {
  my ( $self ) = @_;
  print __PACKAGE__.":CLEAR\n" if $ENV{INI_FILE_TRACE};
  $self->save_file({});
}

sub EXTEND {}
sub STORESIZE {}

sub FIRSTKEY {
  my ( $self ) = @_;
  my ( $first ) = sort { $a cmp $b } keys %{$self->data};
  return defined $first ? ($first) : ();
}

sub NEXTKEY {
  my ( $self, $last ) = @_;
  my @sorted_keys = sort { $a cmp $b } keys %{$self->data};
  while (@sorted_keys) {
    my $key = shift @sorted_keys;
    if ($key eq $last) {
      if (@sorted_keys) {
        return (shift @sorted_keys);
      } else {
        return;
      }
    }
  }
}

sub UNTIE {}
sub DESTROY {}

1;

__END__

=pod

=head1 NAME

INI_File - Tie a hash or an array to an INI file

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use INI_File;

  tie( my %config, 'INI_File', 'config.ini' );

  # data directly stored in file
  $config{key} = {
    attribute => 'value',
  };
  # DON'T set $config{key}->{attribute} directly, it will not get saved

  # data is always read from file, not cached
  print $config{key}->{attribute};

=head1 DESCRIPTION

This module is allowing you to bind a perl hash to an INI file. The data is
always read directly from the file and also directly written to the file. This
means also that if you add several keys to the hash, that every key will let
the complete INI file be rewritten.

=encoding utf8

=head1 SUPPORT

IRC

  Join #sycontent on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-ini_file
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-ini_file/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
