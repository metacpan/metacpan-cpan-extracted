package Google::Checkout::General::ConfigReader;

=head1 NAME

Google::Checkout::General::ConfigReader

=head1 SYNOPSIS

=head1 DESCRIPTION

A simple parser to read and load the config file. This module
is used internally by C<Google::Checkout::General::GCO>, 
you probably won't be using it directly.

=over 4

=item new CONFIG_PATH => ...

Constructor. Takes a path to the configuration file.

=item path

Returns the path to the configuration file. 

=item get KEY

Given a key, returns the corresponding value. If KEY
is not found, C<undef> is returned.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

=cut

#--
#-- Config parser
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/is_gco_error/;

sub new
{
  my ($class, $args) = @_;

  my $path = $args->{config_path} || "$ENV{GCO_ROOT}/conf/GCOSystemGlobal.conf";

  return bless {config_path => $path,
                opened      => 0,
                content     => {} } => $class;
}

sub path 
{ 
  my ($self) = @_;

  return $self->{config_path};
}

sub get
{
  my ($self, $item) = @_;

  return undef unless defined $item;

  unless ($self->{opened})
  {
    my $content = $self->_parse_config;

    return $content if is_gco_error($content);

    $self->{opened} = 1;
    $self->{content} = $content;
  }

  return exists $self->{content}->{$item} ?
                $self->{content}->{$item} : undef;
}

sub _parse_config
{
  my ($self) = @_;

  my %content = ();

  open(CONF, $self->path) || return Google::Checkout::General::Error->new($!+0, $!);

  while(<CONF>)
  {
    #--
    #-- Remove newline
    #--
    s/\n//;

    #--
    #-- Trim spaces
    #--
    s/^\s+//;
    s/\s+$//;

    #--
    #-- Ignore lines starting with #
    #--
    next if /^#/;

    #--
    #-- If a line has this form <key> = <value>, count it
    #--
    next unless /(.+?)\s*=\s*(.+)/;

    $content{$1} = $2;
  }

  close(CONF);

  return \%content;
}

1;
